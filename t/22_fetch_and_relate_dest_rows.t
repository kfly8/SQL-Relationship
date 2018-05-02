use strict;
use warnings;
use Test::More;

use SQL::Relationship;

my $r = SQL::Relationship->make_one(
    'friend.user_id' => 'user.id',
    fetcher          => sub {'foo'},
    relayer          => sub {@_},
);
my $src_rows = [ { user_id => 123 }, { user_id => 456 } ];

subtest 'fetch_and_relate_dest_rows' => sub {
    my ( $relationship, $got_rows, $fetch_result ) = $r->fetch_and_relate_dest_rows($src_rows);
    is $relationship, $r;
    is_deeply $got_rows, $src_rows;
    is $fetch_result,    'foo';
};

done_testing;
