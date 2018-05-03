use strict;
use warnings;
use Test::More;

use SQL::Relationship;

my $sep = ':';

my $single = SQL::Relationship->new(
    src_table           => 'friend',
    src_columns         => ['user_id'],
    dest_table          => 'user',
    dest_columns        => ['id'],
    has_many            => 0,
    value_key_separator => $sep,
);

my $multi = SQL::Relationship->new(
    src_table           => 'friend',
    src_columns         => [ 'a', 'b' ],
    dest_table          => 'user',
    dest_columns        => [ 'c', 'd' ],
    has_many            => 0,
    value_key_separator => $sep,
);

subtest 'value_key_from_src' => sub {
    is $single->value_key_from_src( { user_id => 123 } ), 123;
    is $multi->value_key_from_src( { a => 'foo', b => 'bar' } ), 'foo:bar';
};

subtest 'value_key_from_dest' => sub {
    is $single->value_key_from_dest( { id => 123 } ), 123;
    is $multi->value_key_from_dest( { c => 'foo', d => 'bar' } ), 'foo:bar';
};

done_testing;
