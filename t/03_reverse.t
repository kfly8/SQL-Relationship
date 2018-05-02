use strict;
use warnings;
use Test::More;

use SQL::Relationship;

subtest 'reverse' => sub {
    my $r = SQL::Relationship->new(
        src_table    => 'friend',
        src_columns  => ['user_id'],
        dest_table   => 'user',
        dest_columns => ['id'],
        has_many     => 0,
        fetcher      => sub {'fetcher'},
        relayer      => sub {'relayer'},
    );

    my $rev = $r->reverse;

    isa_ok $rev, 'SQL::Relationship';
    is $rev->src_table, 'user';
    is_deeply $rev->src_columns, ['id'];
    is $rev->dest_table, 'friend';
    is_deeply $rev->dest_columns, ['user_id'];
    ok $rev->has_many;

    is $rev->fetcher->(), 'fetcher';
    is $rev->relayer->(), 'relayer';
};

done_testing;
