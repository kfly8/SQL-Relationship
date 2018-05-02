package SQL::Relationship::Test::Collection;

sub new {
    my ( $class, $rows ) = @_;
    bless $rows => $class;
}

sub all { @{ $_[0] } }

package main;
use strict;
use warnings;
use Test::More;

use SQL::Relationship;

subtest 'rows' => sub {
    my $src_rows = [ { user_id => 123 }, { user_id => 456 } ];
    my $values = SQL::Relationship->src_values( $src_rows, 'user_id' );
    is_deeply $values, [ 123, 456 ];
};

subtest 'blessed rows' => sub {
    my $src_rows = SQL::Relationship::Test::Collection->new( [ { user_id => 123 }, { user_id => 456 } ] );
    my $values = SQL::Relationship->src_values( $src_rows, 'user_id' );
    is_deeply $values, [ 123, 456 ];
};

subtest 'empty' => sub {
    my $src_rows = [];
    my $values = SQL::Relationship->src_values( $src_rows, 'user_id' );
    is_deeply $values, [];
};

subtest 'undef value' => sub {
    my $src_rows = [ { user_id => undef } ];
    my $values = SQL::Relationship->src_values( $src_rows, 'user_id' );
    is_deeply $values, [];
};

done_testing;
