package SQL::Relationship::Test::Row;

sub new {
    my ( $class, $args ) = @_;
    bless $args => $class;
}

sub get_column {
    my ( $self, $column ) = @_;
    $self->{$column};
}

package main;
use strict;
use warnings;
use Test::More;

use SQL::Relationship;

subtest 'HASH' => sub {
    my $value = SQL::Relationship->column_value( { user_id => 123 }, 'user_id' );
    is $value, 123;
};

subtest 'blessed' => sub {
    my $row = SQL::Relationship::Test::Row->new( { user_id => 123 } );
    my $value = SQL::Relationship->column_value( $row, 'user_id' );
    is $value, 123;
};

subtest 'raw' => sub {
    my $value = SQL::Relationship->column_value( 123, 'user_id' );
    is $value, 123;
};

subtest 'exception' => sub {
    eval { SQL::Relationship->column_value( [], 'user_id' ); };
    like $@, qr/not supported row type: ARRAY/;
};

done_testing;
