use strict;
use warnings;
use Test::More;

use SQL::Relationship;

subtest 'new' => sub {
    my $r = SQL::Relationship->new(
        src_table    => 'friend',
        src_columns  => ['user_id'],
        dest_table   => 'user',
        dest_columns => ['id'],
        has_many     => 0,
    );

    isa_ok $r, 'SQL::Relationship';
    is $r->src_table,  'friend';
    is $r->dest_table, 'user';
    is_deeply $r->src_columns,  ['user_id'];
    is_deeply $r->dest_columns, ['id'];
    is $r->has_many, 0;
};

done_testing;
