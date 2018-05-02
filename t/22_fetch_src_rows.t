use strict;
use warnings;
use Test::More;

use SQL::Relationship;

my $r = SQL::Relationship->make_one(
    'friend.user_id' => 'user.id',
    fetcher          => sub {@_},
);
my $src_rows = [ { user_id => 123 }, { user_id => 456 } ];

subtest 'empty where, opt' => sub {
    my ( $relationship, $src_table, $src_columns, $where, $opt ) = $r->fetch_src_rows();
    is $relationship, $r;
    is $src_table,    'friend';
    is_deeply $src_columns, ['user_id'];
    is_deeply $where, {};
    is_deeply $opt,   {};
};

subtest 'where' => sub {
    my ( $relationship, $src_table, $src_columns, $where, $opt ) = $r->fetch_src_rows( { user_id => 1 } );
    is $relationship, $r;
    is $src_table,    'friend';
    is_deeply $src_columns, ['user_id'];
    is_deeply $where, { user_id => 1 };
    is_deeply $opt, {};
};

subtest 'opt / columns' => sub {
    my ( $relationship, $src_table, $src_columns, $where, $opt )
        = $r->fetch_src_rows( {}, { columns => ['foo'] } );
    is $relationship, $r;
    is $src_table,    'friend';
    is_deeply $src_columns, [ 'user_id', 'foo' ];
    is_deeply $where, {};
    is_deeply $opt, { columns => ['foo'] };
};

subtest 'opt / foo => bar ' => sub {
    my ( $relationship, $src_table, $src_columns, $where, $opt )
        = $r->fetch_src_rows( {}, { foo => 'bar' } );
    is $relationship, $r;
    is $src_table,    'friend';
    is_deeply $src_columns, ['user_id'];
    is_deeply $where, {};
    is_deeply $opt, { foo => 'bar' };
};

done_testing;
