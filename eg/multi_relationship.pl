use strict;
use warnings;
use utf8;

use Test::More;
use SQL::Relationship;
use SQL::Maker;
use List::UtilsBy qw/partition_by/;
use DBI;
use DDP;

my $builder = SQL::Maker->new( driver => 'SQLite' );
my $dbh = DBI->connect('dbi:SQLite:dbname=test.db');

my $SCHEMA = {
    user => {
        id         => 1,
        name       => 2,
        user_score => has_one( 'user.id' => 'user_score.user_id' ),
        friends    => has_many( 'user.id' => 'friend.user_id' ),
    },
    user_score => {
        id      => 1,
        user_id => 2,
        score   => 3,
    },
    friend => {
        id              => 1,
        user_id         => 2,
        another_user_id => 3,
        user            => has_one( 'friend.user_id' => 'user.id' ),
        another_user    => has_one( 'friend.another_user_id' => 'user.id' ),
    },
};

sub setup {
    my $dbh = shift;

    $dbh->do('DROP TABLE IF EXISTS user');
    $dbh->do('DROP TABLE IF EXISTS user_score');
    $dbh->do('DROP TABLE IF EXISTS friend');

    $dbh->do(
        q!
CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255)
)!
    );

    $dbh->do(
        q!
CREATE TABLE user_score (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id INTEGER NOT NULL,
  score INTEGER
)!
    );

    $dbh->do(
        q!
CREATE TABLE friend (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id INTEGER NOT NULL,
  another_user_id INTEGER NOT NULL
)!
    );

    $dbh->do(q!INSERT INTO user (id, name) VALUES (1, 'foo')!);
    $dbh->do(q!INSERT INTO user (id, name) VALUES (2, 'bar')!);
    $dbh->do(q!INSERT INTO user (id, name) VALUES (3, 'baz')!);
    $dbh->do(q!INSERT INTO user (id, name) VALUES (4, 'hoge')!);
    $dbh->do(q!INSERT INTO user (id, name) VALUES (5, 'fuga')!);

    $dbh->do(q!INSERT INTO user_score (user_id, score) VALUES (1, 100)!);
    $dbh->do(q!INSERT INTO user_score (user_id, score) VALUES (2, 200)!);
    $dbh->do(q!INSERT INTO user_score (user_id, score) VALUES (3, 300)!);
    $dbh->do(q!INSERT INTO user_score (user_id, score) VALUES (4, 400)!);
    $dbh->do(q!INSERT INTO user_score (user_id, score) VALUES (5, 500)!);

    $dbh->do(q!INSERT INTO friend (id, user_id, another_user_id) VALUES (1, 1, 2)!);
    $dbh->do(q!INSERT INTO friend (id, user_id, another_user_id) VALUES (2, 2, 1)!);
    $dbh->do(q!INSERT INTO friend (id, user_id, another_user_id) VALUES (3, 1, 3)!);
    $dbh->do(q!INSERT INTO friend (id, user_id, another_user_id) VALUES (4, 3, 1)!);
    $dbh->do(q!INSERT INTO friend (id, user_id, another_user_id) VALUES (5, 1, 4)!);
    $dbh->do(q!INSERT INTO friend (id, user_id, another_user_id) VALUES (6, 4, 1)!);
}

sub relayer {
    my ( $relationship, $src_rows, $dest_rows ) = @_;

    my %dest_map = partition_by { $relationship->value_key_from_dest($_) } @$dest_rows;

    for my $src_row (@$src_rows) {
        my $dest_rows = $dest_map{ $relationship->value_key_from_src($src_row) };
        $src_row->{ $relationship->name } = $relationship->has_many ? $dest_rows // [] : $dest_rows->[0];
    }
    $src_rows;
}

sub has_one {
    SQL::Relationship->make_one( @_, relayer => \&relayer );
}

sub has_many {
    SQL::Relationship->make_many( @_, relayer => \&relayer );
}

# --------------------------------------------------------
# search recursive
# --------------------------------------------------------

sub search_recursive {
    my ( $table, $query, $where, $opt ) = @_;

    my ( $rows, $parsed ) = _search_recursive( $table, $query, $where, $opt );
    clean_rows( $rows, $parsed->{columns} );
    return $rows;
}

sub _search_recursive {
    my ( $table, $query, $where, $opt ) = @_;

    my $parsed = parse_query( $table, $query );

    my $src_rows = search( $table, $parsed->{src_columns}, $where, $opt );
    for my $r ( @{ $parsed->{relationships} } ) {
        my $dest_where = $r->dest_where($src_rows);
        my $dest_query = $parsed->{related_query}->{ $r->name };
        my $dest_opt   = { columns => $r->dest_columns };
        my ( $dest_rows, $dest_parsed ) = _search_recursive( $r->dest_table, $dest_query, $dest_where, $dest_opt );
        $r->relate_dest( $src_rows, $dest_rows );
        clean_rows( $dest_rows, $dest_parsed->{columns} );
    }

    return ( $src_rows, $parsed );
}

sub search {
    my ( $table, $columns, $where, $opt ) = @_;
    $where //= {};
    $opt   //= {};

    $columns = [ @$columns, @{ $opt->{columns} || [] } ];
    my ( $sql, @binds ) = $builder->select( $table, $columns, $where, $opt );
    $dbh->selectall_arrayref( $sql, { Slice => {} }, @binds );
}

sub parse_query {
    my ( $table, $query ) = @_;

    my $schema = $SCHEMA->{$table};
    my ( @src_columns, @columns, @relationships, %related_query );

    my $i = 0;
    while ( $i < @$query ) {
        my $q = $query->[$i];
        my $s = $schema->{$q} or die "schema not found: $table.$q";

        if ( ref $s && $s->isa('SQL::Relationship') ) {
            push @columns       => $q;
            push @src_columns   => @{ $s->src_columns };
            push @relationships => $s;
            $related_query{ $s->name } = $query->[ ++$i ];
        }
        else {
            push @columns     => $q;
            push @src_columns => $q;
        }
        ++$i;
    }

    return {
        src_columns   => \@src_columns,
        columns       => \@columns,
        relationships => \@relationships,
        related_query => \%related_query,
    };
}

sub clean_rows {
    my ( $rows, $columns ) = @_;
    my %cmap = map { $_ => 1 } @$columns;
    for my $row (@$rows) {
        for my $key ( keys %$row ) {
            delete $row->{$key} if !$cmap{$key};
        }
    }
    return $rows;
}

# --------------------------------------------------------
# main
# --------------------------------------------------------

setup($dbh);

my $friends = search_recursive(
    friend => [
        'id',
        'user_id',
        'user'         => [ 'name', 'user_score' => ['score'] ],
        'another_user' => [ 'name', 'user_score' => ['score'] ],
    ],
    { user_id => 1 },
    { limit   => 2 },
);

is_deeply $friends,
    [
    {   id      => 1,
        user_id => 1,
        user    => {
            name       => 'foo',
            user_score => { score => 100, }
        },
        another_user => {
            name       => 'bar',
            user_score => { score => 200, }
        },
    },
    {   id      => 3,
        user_id => 1,
        user    => {
            name       => 'foo',
            user_score => { score => 100, }
        },
        another_user => {
            name       => 'baz',
            user_score => { score => 300, }
        },
    },
    ]
    or diag explain $friends;

my $users = search_recursive(
    user => [ 'id', 'name', 'friends' => [ 'another_user' => [ 'id', 'name', ] ] ],
    { name => [ 'foo', 'bar', 'fuga' ] },
    {},
);

is_deeply $users,
    [
    {   id      => 1,
        name    => 'foo',
        friends => [
            {   another_user => {
                    id   => 2,
                    name => 'bar',
                },
            },
            {   another_user => {
                    id   => 3,
                    name => 'baz',
                },
            },
            {   another_user => {
                    id   => 4,
                    name => 'hoge',
                },
            },
        ],
    },
    {   id      => 2,
        name    => 'bar',
        friends => [
            {   another_user => {
                    id   => 1,
                    name => 'foo',
                },
            },
        ],
    },
    {   id      => 5,
        name    => 'fuga',
        friends => [],
    }
    ];

done_testing;
