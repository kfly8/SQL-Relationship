use strict;
use warnings;
use Test::More;

use SQL::Relationship;

my $r = SQL::Relationship->make_one( 'friend', 'user_id' => 'user', 'id', fetcher => sub {@_} );
my $src_rows = [ { user_id => 123 }, { user_id => 456 } ];

subtest 'empty where, opt' => sub {
    my ( $relationship, $dest_table, $dest_columns, $where, $opt ) = $r->fetch_dest($src_rows);
    is $relationship, $r;
    is $dest_table,   'user';
    is_deeply $dest_columns, ['id'];
    is_deeply $where, { id => [ 123, 456 ] };
    is_deeply $opt, {};
};

subtest 'where' => sub {
    my ( $relationship, $dest_table, $dest_columns, $where, $opt )
        = $r->fetch_dest( $src_rows, { foo => 'bar' } );
    is $relationship, $r;
    is $dest_table,   'user';
    is_deeply $dest_columns, ['id'];
    is_deeply $where, { id => [ 123, 456 ], foo => 'bar' };
    is_deeply $opt, {};
};

subtest 'opt / columns' => sub {
    my ( $relationship, $dest_table, $dest_columns, $where, $opt )
        = $r->fetch_dest( $src_rows, {}, { columns => ['foo'] } );
    is $relationship, $r;
    is $dest_table,   'user';
    is_deeply $dest_columns, [ 'id', 'foo' ];
    is_deeply $where, { id => [ 123, 456 ] };
    is_deeply $opt, { columns => ['foo'] };
};

subtest 'opt / foo => bar' => sub {
    my ( $relationship, $dest_table, $dest_columns, $where, $opt )
        = $r->fetch_dest( $src_rows, {}, { foo => 'bar' } );
    is $relationship, $r;
    is $dest_table,   'user';
    is_deeply $dest_columns, ['id'];
    is_deeply $where, { id => [ 123, 456 ] };
    is_deeply $opt, { foo => 'bar' };
};

done_testing;
