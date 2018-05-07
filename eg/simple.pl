use strict;
use warnings;
use utf8;

use Test::More;
use SQL::Relationship;
use SQL::Maker;
use DBI;

my $builder = SQL::Maker->new( driver => 'SQLite' );
my $dbh = DBI->connect('dbi:SQLite:dbname=test.db');

sub setup {
    my $dbh = shift;

    $dbh->do('DROP TABLE module');
    $dbh->do('DROP TABLE author');
    $dbh->do( '
    CREATE TABLE module (
      id INTEGER PRIMARY KEY NOT NULL,
      name VARCHAR(255),
      author_id INTEGER,
      FOREIGN KEY (author_id) REFERENCES author(id)
    )' );

    $dbh->do( '
    CREATE TABLE author (
      id INTEGER PRIMARY KEY NOT NULL,
      name VARCHAR(255)
    );
    ' );

    $dbh->do(q!INSERT INTO author (id, name) VALUES (1, 'songmu')!);
    $dbh->do(q!INSERT INTO author (id, name) VALUES (2, 'karupanerura')!);

    $dbh->do(q!INSERT INTO module (id, name, author_id) VALUES (1, 'DBIx::Schema::DSL', 1)!);
    $dbh->do(q!INSERT INTO module (id, name, author_id) VALUES (2, 'Riji', 1)!);
    $dbh->do(q!INSERT INTO module (id, name, author_id) VALUES (3, 'Aniki', 2)!);
    $dbh->do(q!INSERT INTO module (id, name, author_id) VALUES (4, 'Time::Strptime', 2)!);
    $dbh->do(q!INSERT INTO module (id, name, author_id) VALUES (5, 'TOML', 2)!);
}

sub fetcher {
    my ( $relationship, $dest_table, $dest_columns, $where, $opt ) = @_;

    my ( $sql, @binds ) = $builder->select( $dest_table, $dest_columns, $where, $opt );
    $dbh->selectall_arrayref( $sql, { Slice => {} }, @binds );
}

sub relayer {
    my ( $relationship, $src_rows, $dest_rows ) = @_;

    my %dest_map = map { $relationship->value_key_from_dest($_) => $_ } @$dest_rows;

    for my $src_row (@$src_rows) {
        my $dest_row = $dest_map{ $relationship->value_key_from_src($src_row) };
        $src_row->{ $relationship->name } = $dest_row;
    }
    $src_rows;
}

my $relationship = SQL::Relationship->new(
    src_table    => 'module',
    src_columns  => [qw/author_id/],
    dest_table   => 'author',
    dest_columns => [qw/id/],
    has_many     => 0,
    fetcher      => \&fetcher,
    relayer      => \&relayer,
);

setup($dbh);

my $src_rows = $relationship->fetch_src( { name => [ 'Aniki', 'TOML' ] }, { columns => ['name'] } );
my $dest_rows = $relationship->fetch_dest( $src_rows, {}, { columns => ['name'] } );
is_deeply $src_rows, [ { author_id => 2, name => 'Aniki' }, { author_id => 2, name => 'TOML' } ];
is_deeply $dest_rows, [ { id => 2, name => 'karupanerura' } ];

my $expect = [
    { author_id => 2, name => 'Aniki', author => { id => 2, name => 'karupanerura' } },
    { author_id => 2, name => 'TOML',  author => { id => 2, name => 'karupanerura' } }
];

is_deeply $relationship->relate_dest( $src_rows, $dest_rows ), $expect;
is_deeply $relationship->fetch_and_relate_dest( $src_rows, {}, { columns => ['name'] } ), $expect;

done_testing;
