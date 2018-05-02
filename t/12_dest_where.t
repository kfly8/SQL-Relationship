use strict;
use warnings;
use Test::More;

use SQL::Relationship;

subtest "columns == 1" => sub {
    my $r = SQL::Relationship->make_one( 'friend', 'user_id' => 'user', 'id' );
    my $src_rows = [ { user_id => 123 }, { user_id => 456 } ];
    my $where = $r->dest_where($src_rows);
    is_deeply $where, { id => [ 123, 456 ] };
};

subtest "columns > 1" => sub {
    my $r = SQL::Relationship->make_one( 'friend', [ 'a', 'b' ] => 'user', [ 'c', 'd' ] );
    my $src_rows = [ { a => 100, b => 200 }, { a => 101, b => 201 } ];
    my $where = $r->dest_where($src_rows);
    is_deeply $where, { c => [ 100, 101 ], d => [ 200, 201 ] };
};

done_testing;
