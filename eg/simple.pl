use strict;
use warnings;
use utf8;

use SQL::Relationship;
use SQL::Maker;
use DBI;

my $builder = SQL::Maker->new( driver => 'SQLite' );
my $dbh = DBI->connect('dbi:SQLite:dbname=test.db');

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

my $relationship = SQL::Relationship->new(
    src_table    => 'module',
    src_columns  => [qw/author_id/],
    dest_table   => 'author',
    dest_columns => [qw/id/],
    has_many     => 0,
    fetcher      => \&fetcher,
);

sub fetcher {
    my ( $relationship, $dest_table, $dest_columns, $where, $opt ) = @_;

    my ( $sql, @binds ) = $builder->select( $dest_table, $dest_columns, $where, $opt );
    $dbh->selectall_arrayref( $sql, { Slice => {} }, @binds );
}

use Test::More;
my $src_rows = $relationship->fetch_src_rows( { name => [ 'Aniki', 'TOML' ] }, { columns => ['name'] } );
my $dest_rows = $relationship->fetch_dest_rows( $src_rows, {}, { columns => ['name'] } );
is_deeply $src_rows, [ { author_id => 2, name => 'Aniki' }, { author_id => 2, name => 'TOML' } ];
is_deeply $dest_rows, [ { id => 2, name => 'karupanerura' } ];

done_testing;
