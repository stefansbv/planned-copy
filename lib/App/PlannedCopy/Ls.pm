package App::PlannedCopy::Ls;

# ABSTRACT: Print items like *nix ls does

use 5.0100;
use utf8;
use Moose;
use Term::ReadKey;
use Term::ANSIColor;
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
    traits  => ['Array'],
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_items    => 'elements',
        count_items  => 'count',
        sorted_items => 'sort',
    },
);

has 'spaces_no' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 2 },
);

has 'cols_no' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my $self     = shift;
        my @items    = $self->all_items;
        my $max_flen = $self->get_maxlen( \@items );
        die "Error calculating max item lenght!"
            unless defined $max_flen
            and $max_flen > 0;
        my $cols_no  = int( $self->term_size / $max_flen );
        my $items_no = $self->count_items;
        return $items_no < $cols_no ? $items_no : $cols_no;
    },
);

sub items_per_col {
    my ( $self, $cols_no ) = @_;
    die "Wron parameter for 'items_per_col'"
        unless defined $cols_no and $cols_no > 0;
    return int( $self->count_items / $cols_no );
}

sub build_printf_template {
    my ($self, $cols, $colidx) = @_;

    # Build the template for printf
    my $templ = q{};
    for my $c ( 0 .. $colidx ) {
        my $w = $self->get_maxlen($cols->[$c]);
        $templ .= q{%-} . $w . q{s};
        $templ .= q{ } x $self->spaces_no unless $c == $colidx;
    }
    return $templ;
}

sub column_printer {
    my $self = shift;

    if ( $self->count_items == 0 ) {
        say "II No items to display!";
        return;
    }
    my $cols_no       = $self->cols_no;
    my $items_in_cols = $self->distribute_items($cols_no);

    # Check width and try to optimize
    my $diff = $self->get_diff($items_in_cols);
    if ( $diff < 0 ) {
        my $new_diff = $diff + $cols_no - 1; # 1 space
        if ( $new_diff > 0 ) {
            $self->spaces_no(1);             # adjust spaces
        }
        else {
            # Ajust columns number and redistribute items
            $cols_no -= 1;
            $items_in_cols = $self->distribute_items($cols_no);
        }
    }
    elsif ( $diff > 20 ) {
        $cols_no += 1;                       # add a column
        $items_in_cols = $self->distribute_items($cols_no);
        my $diff = $self->get_diff($items_in_cols);
        if ( $diff < 0 ) {
            # Fall back
            $cols_no -= 1;                   # remove a column
            $items_in_cols = $self->distribute_items($cols_no);
        }
    }

    # Print by row
    my $col_idx = $cols_no - 1;
    my $row_idx = scalar @{$items_in_cols->[0]} - 1;

    my $templ = $self->build_printf_template($items_in_cols, $col_idx);
    for my $r ( 0 .. $row_idx ) {
        my @row = ();
        for my $c ( 0 .. $col_idx ) {
            push @row, $items_in_cols->[$c][$r] // '';
        }
        printf "$templ\n", @row;
    }

    return;
}

sub get_diff {
    my ( $self, $items_in_cols ) = @_;

    my @maxwidths;    # the max width for each col
    my $cols_no = 0;
    foreach my $col ( @{$items_in_cols} ) {
        $cols_no++;
        push @maxwidths, $self->get_maxlen($col);
    }

    my $maxwidth;                            # the sum of the widths
    map { $maxwidth += $_ } @maxwidths;
    $maxwidth = $maxwidth + ( $cols_no - 1 ) * $self->spaces_no;

    return $self->term_size - $maxwidth;
}

sub distribute_items {
    my ($self, $cols_no) = @_;

    my @items = $self->sorted_items;

    my $items_surplus = int( $self->count_items % $cols_no );

    my @cols;
    for ( my $c = 0; $c < $cols_no; $c++ ) {

        # Add the surplus items to the first columns
        my $surplus       = $items_surplus > 0 ? 1 : 0;
        my $items_per_col = $self->items_per_col($cols_no) + $surplus;
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
