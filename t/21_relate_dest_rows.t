use strict;
use warnings;
use Test::More;

use SQL::Relationship;

my $r = SQL::Relationship->make_one( 'friend', 'user_id' => 'user', 'id', relayer => sub {@_} );
my $src_rows = [ { user_id => 123 }, { user_id => 456 } ];

subtest 'empty where, opt' => sub {
    my ( $relationship, $got_src_rows, @args ) = $r->relate_dest_rows( $src_rows, foo => 'bar' );
    is $relationship, $r;
    is $got_src_rows, $src_rows;
    is_deeply \@args, [ foo => 'bar' ];
};

done_testing;
