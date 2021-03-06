package App::PlannedCopy::Ls;

# ABSTRACT: Print items like *nix ls does

use 5.0100;
use utf8;
use Moose;
use Term::ReadKey;
use namespace::autoclean;

STDOUT->autoflush(1);

has 'term_size' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($wdt) = GetTerminalSize();  # adjust output f(wdt)
        return $wdt;
    },
);

has 'items' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        all_items    => 'elements',
        items_count  => 'count',
        sorted_items => 'sort',
    },
);

has 'spaces_num' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 2 },
);

has column_count => (
    is      => 'rw',
    isa     => 'Int',
    traits  => ['Counter'],
    lazy    => 1,
    default => sub {
        my $self     = shift;
        my @items    = $self->all_items;
        my $max_flen = $self->get_maxlen( \@items );
        die "Error calculating max item lenght!"
            unless defined $max_flen
            and $max_flen > 0;
        my $cols_no  = int( $self->term_size / $max_flen );
        my $items_no = $self->items_count;
        return $items_no < $cols_no ? $items_no : $cols_no;
    },
    handles => {
        inc_cols => 'inc',
        dec_cols => 'dec',
    },
);

sub items_per_col {
    my ( $self, $column_count ) = @_;
    die "Wron parameter for 'items_per_col'"
        unless defined $column_count and $column_count > 0;
    return int( $self->items_count / $column_count );
}

sub build_printf_template {
    my ($self, $cols, $colidx) = @_;
    my $templ = q{};
    for my $c ( 0 .. $colidx ) {
        my $w = $self->get_maxlen($cols->[$c]);
        $templ .= q{%-} . $w . q{s};
        $templ .= q{ } x $self->spaces_num unless $c == $colidx;
    }
    return $templ;
}

sub column_printer {
    my $self = shift;

    if ( $self->items_count == 0 ) {
        say "II No items to display!";
        return;
    }

    my $items_in_cols = $self->distribute_items;

    # Check width and try to optimize
    if ( $self->items_count > $self->column_count ) {

        my $diff = $self->get_width_diff($items_in_cols);
        if ( $diff < 0 ) {
            my $new_diff = $diff + $self->column_count - 1;    # 1 space
            if ( $new_diff > 0 ) {
                $self->spaces_num(1);         # adjust spaces
            }
            else {
                # Ajust columns number and redistribute items
                $self->dec_cols;
                $items_in_cols = $self->distribute_items;
            }
        }
        elsif ( $diff > 20 ) {
            $self->inc_cols;                 # add a column
            $items_in_cols = $self->distribute_items;
            my $diff = $self->get_width_diff($items_in_cols);
            if ( $diff < 0 ) {

                # Fall back
                $self->dec_cols;             # remove a column
                $items_in_cols = $self->distribute_items;
            }
        }
    }

    $self->print_by_row($items_in_cols);

    return;
}

sub print_by_row {
    my ( $self, $items_in_cols ) = @_;
    my $col_idx = $self->column_count - 1;
    my $row_idx = scalar @{ $items_in_cols->[0] } - 1;
    my $templ   = $self->build_printf_template( $items_in_cols, $col_idx );
    for my $r ( 0 .. $row_idx ) {
        my @row = ();
        for my $c ( 0 .. $col_idx ) {
            push @row, $items_in_cols->[$c][$r] // '';
        }
        printf "$templ\n", @row;
    }
    return;
}

sub get_width_diff {
    my ( $self, $items_in_cols ) = @_;

    my @maxwidths;    # the max width for each col
    my $column_count = 0;
    foreach my $col ( @{$items_in_cols} ) {
        $column_count++;
        push @maxwidths, $self->get_maxlen($col);
    }

    my $maxwidth;                            # the sum of the widths
    map { $maxwidth += $_ } @maxwidths;
    $maxwidth = $maxwidth + ( $column_count - 1 ) * $self->spaces_num;

    return $self->term_size - $maxwidth;
}

sub distribute_items {
    my $self = shift;

    my $column_count  = $self->column_count;
    my @items = $self->sorted_items;

    my $items_surplus = int( $self->items_count % $column_count );

    my @cols;
    for ( my $c = 0; $c < $column_count; $c++ ) {

        # Add the surplus items to the first columns
        my $surplus       = $items_surplus > 0 ? 1 : 0;
        my $items_per_col = $self->items_per_col($column_count) + $surplus;
        $items_surplus--;

        for ( my $i = 0; $i < $items_per_col; $i++ ) {
            $cols[$c][$i] = shift @items;
        }
    }
    return \@cols;
}

sub get_maxlen {
    my ($self, $strings) = @_;
    die "The parameter for 'get_maxlen' have to be an array ref!"
        unless ref $strings eq 'ARRAY';
    die "Empty array ref parameter for 'get_maxlen'"
        if scalar @{$strings} == 0;
    my $max = 0;
    for my $item ( @{$strings} ) {
        my $len = length $item;
        $max = $len if $len > $max;
    }
    return $max;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

    my $list = App::PlannedCopy::Ls->new( items => \@items );
    $list->column_printer;

=head1 Description

An original experimental algorithm for printing items in columns like the *nix ls
utility does.

=head1 Interface

=head2 Attributes

=head3 term_size

Holds and returns the terminal size in chars.

=head3 items

Holds an array reference of the items to be printed.

=head3 spaces_num

The number of spaces between the columns.  Default is 2.

=head3 column_count

A r/w attribute for the column count.  The Initial value is calculated
by dividing the C<term_size> with the length of the biggest item in the
list.

=head2 Instance Methods

=head3 items_per_col

Return the number of item per column, calculated using the formula:

    int(items_count / $column_count)

=head3 build_printf_template

Builds the template for printf.

=head3 column_printer

Distributes the items in columns, checks if the strings fit the
screen, if not redistributes them than prints to the screen using the
C<print_by_row> method.

=head3 print_by_row

Gets the AoA of items and prints them row by row, using a custom
C<printf> template.

=head3 get_width_diff

Returns the difference between the terminal width and the width of the
longest string to be printed.

It is used to check if the current distribution of the items fits.

=head3 distribute_items

Returns an AoA with the items distributes in columns.  The columns
with lower indexes can get more items than those with higher indexes
if the number of items does not divide exactly to the number of
columns.

=head3 get_maxlen

Returns the maximum length of the string items in the array reference
given as parameter.

=cut
