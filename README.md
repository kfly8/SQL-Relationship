[![Build Status](https://travis-ci.org/kfly8/SQL-Relationship.svg?branch=master)](https://travis-ci.org/kfly8/SQL-Relationship)
# NAME

SQL::Relationship - support create SQL for related tables

# SYNOPSIS

    use SQL::Relationship;

    my $relationship = SQL::Relationship->new(
        name         => 'user',
        src_table    => 'friend',
        src_columns  => ['user_id'],
        dest_table   => 'user',
        dest_columns => ['id'],
        has_many     => 0,
    );

    $relationship->dest_where([{ user_id => 123 }, { user_id => 456 }]);
    # => { id => [123, 456] }

    my $dbh = DBIx::Sunny->connect(...);
    my $builder = SQL::Maker->new();

    # Set fetcher
    $relationship->fetcher(sub {
        my ($relationship, $dest_table, $dest_columns, $where, $opt) = @_;

        my ($sql, @binds) = $builder->select($dest_table, $dest_columns, $where, $opt);
        $dbh->select_all($sql, @binds);
    });

    my $dest_rows = $relationship->fetch_dest_rows([ { user_id => 123 }, { user_id => 456 }]);
    # => fetch!
    #   SQL: SELECT id FROM user WHERE id IN (?)
    #   BINDS: [123, 456]

    # Set relayer
    $relationship->relayer(sub {
        my ($relationship, $src_rows, $fetch_dest_rows_result) = @_;

        my $dest_rows = $fetch_dest_rows_result;

        my $src_column  = $relationship->src_columns->[0]; # user_id
        my $dest_column = $relationship->dest_columns->[0]; # id

        my %dest_map = map { $_->$dest_column => $_ } @$dest_rows;

        for my $src_row (@$src_rows) {
            my $dest_row = $dest_map{$src_row->{$src_column}};
            $src_row->{relay}->{$relationship->name} = $dest_row;
        }
    )}

    $relationship->relate_dest_rows($src_rows, $dest_rows);
    # $friend->{relay}->{user} = { user_id => 123 }

# DESCRIPTION

SQL::Relationship is ...

# TODO

\- Document
\- good namespace
\- Default Fetcher like Aniki::Schema::Relationship::Fetcher

# SEE ALSO

[Aniki](https://metacpan.org/pod/Aniki)

# LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kenta, Kobayashi <kentafly88@gmail.com>
