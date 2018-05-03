package SQL::Relationship;
use 5.014002;

use Mouse;
use Lingua::EN::Inflect ();

our $VERSION = "0.01";

has src_table    => ( is => 'ro', isa => 'Str',           required => 1 );
has src_columns  => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
has dest_table   => ( is => 'ro', isa => 'Str',           required => 1 );
has dest_columns => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
has has_many     => ( is => 'ro', isa => 'Bool',          required => 1 );

has fetcher => ( is => 'rw', isa => 'CodeRef' );
has relayer => ( is => 'rw', isa => 'CodeRef' );

has name                => ( is => 'ro', isa => 'Str', default => \&_guess_name );
has value_key_separator => ( is => 'ro', isa => 'Str', default => '__VALUE_KEY_SEPARATOR__' );

sub dest_where {
    my ( $self, $src_rows ) = @_;
    my %where;
    for ( 0 .. $#{ $self->src_columns } ) {
        my $src_column  = $self->src_columns->[$_];
        my $dest_column = $self->dest_columns->[$_];

        my $src_values = $self->src_values( $src_rows, $src_column );

        $where{$dest_column} = $src_values;
    }
    wantarray ? %where : \%where;
}

sub src_values {
    my ( $invocant, $src_rows, $src_column ) = @_;
    my @src_rows = blessed $src_rows && $src_rows->can('all') ? $src_rows->all : @$src_rows;
    my @values = grep defined, map { $invocant->column_value( $_, $src_column ); } @src_rows;
    wantarray ? @values : \@values;
}

sub column_value {
    shift;
    my ( $row, $column ) = @_;
    return $row->{$column}           if ref $row     && ref $row eq 'HASH';
    return $row->get_column($column) if blessed $row && $row->can('get_column');
    return $row                      if !ref $row;
    confess "not supported row type: @{[ref $row]}";
}

sub fetch_dest_rows {
    my ( $self, $src_rows, $where, $opt ) = @_;
    $where //= {};
    $opt   //= {};

    my $dest_where = { %$where, $self->dest_where($src_rows) };
    my $dest_columns = [ @{ $self->dest_columns }, @{ $opt->{columns} || [] } ];

    return $self->fetcher->( $self, $self->dest_table, $dest_columns, $dest_where, $opt );
}

sub relate_dest_rows {
    my ( $self, $src_rows ) = ( shift, shift );
    return $self->relayer->( $self, $src_rows, @_ );
}

sub fetch_and_relate_dest_rows {
    my ( $self, $src_rows, $where, $opt ) = @_;
    return $self->relate_dest_rows( $src_rows, $self->fetch_dest_rows( $src_rows, $where, $opt ) );
}

sub fetch_src_rows {
    my ( $self, $where, $opt ) = @_;
    $where //= {};
    $opt   //= {};

    my $src_columns = [ @{ $self->src_columns }, @{ $opt->{columns} || [] } ];
    return $self->fetcher->( $self, $self->src_table, $src_columns, $where, $opt );
}

sub value_key_from_dest {
    my ( $self, $dest_row ) = @_;
    $self->_value_key( $self->dest_columns, $dest_row );
}

sub value_key_from_src {
    my ( $self, $src_row ) = @_;
    $self->_value_key( $self->src_columns, $src_row );
}

sub _value_key {
    my ( $self, $columns, $row ) = @_;
    join $self->value_key_separator, map { $self->column_value( $row, $_ ) } @$columns;
}

sub make_one  { shift->_make( 0, @_ ) }
sub make_many { shift->_make( 1, @_ ) }

sub _make {
    my $class    = shift;
    my $has_many = shift;

    my ( $src_table,  $src_columns )  = $_[0] =~ m!\.! ? split /\./, shift : ( shift, shift );
    my ( $dest_table, $dest_columns ) = $_[0] =~ m!\.! ? split /\./, shift : ( shift, shift );
    $src_columns  = [$src_columns]  if !ref $src_columns;
    $dest_columns = [$dest_columns] if !ref $dest_columns;

    $class->new(
        src_table    => $src_table,
        src_columns  => $src_columns,
        dest_table   => $dest_table,
        dest_columns => $dest_columns,
        has_many     => $has_many,
        @_
    );
}

sub reverse {
    my $self = shift;

    $self->new(
        src_table    => $self->dest_table,
        src_columns  => $self->dest_columns,
        dest_table   => $self->src_table,
        dest_columns => $self->src_columns,
        has_many     => !$self->has_many,

        exists $self->{fetcher} ? ( fetcher => $self->fetcher ) : (),
        exists $self->{relayer} ? ( relayer => $self->relayer ) : (),
    );
}

# XXX: copy from Aniki::Schema::Relationship
our @WORD_SEPARATORS = ( '-', '_', ' ' );

sub _guess_name {
    my $self = shift;

    my @src_columns  = @{ $self->src_columns };
    my @dest_columns = @{ $self->dest_columns };
    my $src_table    = $self->src_table;
    my $dest_table   = $self->dest_table;

    my $prefix
        = ( @src_columns == 1 && $src_columns[0] =~ /^(.+)_\Q$dest_table/ ) ? $1 . '_'
        : ( @dest_columns == 1 && $dest_columns[0] =~ /^(.+)_\Q$src_table/ ) ? $1 . '_'
        :                                                                      '';

    my $name = $self->has_many ? _to_plural($dest_table) : $dest_table;
    return $prefix . $name;
}

sub _to_plural {
    my $words = shift;
    my $sep = join '|', map quotemeta, @WORD_SEPARATORS;
    return $words =~ s/(?<=$sep)(.+?)$/Lingua::EN::Inflect::PL($1)/er if $words =~ /$sep/;
    return Lingua::EN::Inflect::PL($words);
}

__PACKAGE__->meta->make_immutable;
__END__

=encoding utf-8

=head1 NAME

SQL::Relationship - support create SQL for related tables

=head1 SYNOPSIS

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


=head1 DESCRIPTION

SQL::Relationship is ...

=head1 TODO

- Document
- good namespace
- Default Fetcher like Aniki::Schema::Relationship::Fetcher

=head1 SEE ALSO

L<Aniki>

=head1 LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kenta, Kobayashi E<lt>kentafly88@gmail.comE<gt>

=cut

