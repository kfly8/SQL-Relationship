use strict;
use warnings;
use Test::More;
use Data::Dumper;

use SQL::Relationship;

my $EXPECTED = [ 'friend', ['user_id'], 'user', ['id'] ];
my @TEST_CASES = (
    [ 'friend.user_id' => 'user.id' ] => $EXPECTED,
    [ 'friend', 'user_id', 'user', 'id' ] => $EXPECTED,
    [ 'friend.user_id', 'user',    'id' ]      => $EXPECTED,
    [ 'friend',         'user_id', 'user.id' ] => $EXPECTED,
    [ 'friend',         'user_id', 'user.id' ] => $EXPECTED,
    [ 'friend', ['user_id'], 'user', ['id'] ] => $EXPECTED,
    [ 'friend', ['user_id'], 'user', 'id' ] => $EXPECTED,
    [ 'friend', 'user_id', 'user', ['id'] ] => $EXPECTED,
    [ 'friend', [ 'a', 'b' ], 'user', [ 'c', 'd' ] ] => [ 'friend', [ 'a', 'b' ], 'user', [ 'c', 'd' ] ],

    [ 'friend.user_id' => 'user.id' ] => $EXPECTED,
);

while (@TEST_CASES) {
    my ( $args, $expected ) = splice @TEST_CASES, 0, 2;

    subtest "make_one: @{[ddf($args)]}" => sub {
        my $r = SQL::Relationship->make_one(@$args);

        isa_ok $r, 'SQL::Relationship';
        is $r->src_table,           $expected->[0];
        is_deeply $r->src_columns,  $expected->[1];
        is $r->dest_table,          $expected->[2];
        is_deeply $r->dest_columns, $expected->[3];
        is $r->has_many,            0;

    };

    subtest "make_many: @{[ddf($args)]}" => sub {
        my $r = SQL::Relationship->make_many(@$args);

        isa_ok $r, 'SQL::Relationship';
        is $r->src_table,           $expected->[0];
        is_deeply $r->src_columns,  $expected->[1];
        is $r->dest_table,          $expected->[2];
        is_deeply $r->dest_columns, $expected->[3];
        is $r->has_many,            1;
    };
}

subtest 'options' => sub {
    my $r = SQL::Relationship->make_one(
        'friend.user_id' => 'user.id',
        fetcher          => sub {'fetcher'},
        relayer          => sub {'relayer'},
    );

    isa_ok $r, 'SQL::Relationship';
    is $r->src_table, 'friend';
    is_deeply $r->src_columns, ['user_id'];
    is $r->dest_table, 'user';
    is_deeply $r->dest_columns, ['id'];

    is $r->fetcher->(), 'fetcher';
    is $r->relayer->(), 'relayer';
};

sub ddf {
    my $value = shift;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 0;
    Data::Dumper::Dumper($value);
}

done_testing;
