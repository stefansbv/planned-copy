package App::PlannedCopy::Role::Printable;

# ABSTRACT: Role for printing messages

use 5.0100;
use utf8;
use Moose::Role;
use Term::ReadKey;
use Term::ExtendedColor qw(fg);
use Perl6::Form;
use IO::Handle;

STDOUT->autoflush(1);

has 'term_size' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my ($wdt) = GetTerminalSize();  # adjust output f(wdt)
        return $wdt;
    },
);

has '_issue_category_color_map' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub {
        return {
            info  => 'yellow2',
            warn  => 'blue2',
            error => 'red2',
        };
    },
    handles => {
        get_color => 'get',
    },
);

sub points {
    my ($self, $msg_l, $msg_r) = @_;
    my $gap    = 2 + 2;
    my $points = '.' x (
        $self->term_size - length($msg_l) - length($msg_r) - $gap
    );
    return $points;
}

sub printer {
    my ($self, $color, $msg_l, $msg_r) = @_;
    my $points = $self->points($msg_l, $msg_r);
    my $space  = q{ };
        print $space,
            , fg($color, $msg_l),
            , $space,
            , $points,
            , $space,
            , fg($color, $msg_r),
            , "\n";
    return;
}

sub get_issue_header {
    my ($self, $categ) = @_;
    return
          $categ eq 'error' ? '[EE]'
        : $categ eq 'warn'  ? '[WW]'
        : $categ eq 'info'  ? '[II]'
        :                         '';
}

sub get_item_color {
    my ( $self, $res ) = @_;
    return $res->has_no_issues
        ? 'green2'
        : $self->get_color( $res->issues_category );
}

sub item_printer {
    my ( $self, $res ) = @_;
    die "Wrong parameter for 'item_printer', a resource object is expected!"
        unless $res->isa('App::PlannedCopy::Resource::Element');
    my $color = $self->get_item_color($res);
    $self->printer( $color, $res->src->_name, $res->dst->short_path );
    return unless $self->verbose;
    foreach my $issue ( $res->all_issues ) {
        my $issue_color = $self->get_color( $issue->category );
        $self->issue_printer( $issue, $issue_color );
    }
    return;
}

sub issue_printer {
    my ($self, $e) = @_;
    die "Wrong parameter for 'issue_printer', an Issue object is
        expected!"  unless $e->isa('App::PlannedCopy::Issue');
    if ( $e->isa('App::PlannedCopy::Issue') ) {
        $self->print_exeception_message($e);
    }
    return;
}

sub print_exeception_message {
    my ( $self, $e ) = @_;
    die "Wrong parameter for 'print_exeception_message', an Issue
        object is expected!"  unless
        $e->isa('App::PlannedCopy::Issue');
    my $color = $self->get_color( $e->category );
    my $categ = $self->get_issue_header( $e->category );
    print fg($color, "  $categ ");
    print $e->message, ' ', $e->details ? $e->details : '';
    print "\n";
    return;
}

sub project_changes_list_printer {
    my ( $self, $errorlevel, @array ) = @_;
    my $color
        = $errorlevel eq 'removed' ? 'yellow2'
        : $errorlevel eq 'added'   ? 'green2'
        : $errorlevel eq 'kept'    ? 'reset'
        :                            'reset';
    foreach my $item (@array) {
        $self->printer($color, $item, $errorlevel);
    }
    return;
}

sub project_list_printer {
    my ( $self, @items ) = @_;
    foreach my $item (@items) {
        my $path = $item->{path};
        my $resu = $item->{resource};
        my ($color, $mesg);
        if ($resu == 1) {
            $color = 'green2';
            $mesg  = 'resource';
        }
        else {
            $color = 'yellow2';
            $mesg  = 'no resource';
        }
        $self->printer($color, $path, $mesg);
    }
    return;
}

sub difference_printer {
    my ( $self, @items ) = @_;
    my $color = 'yellow2';
    foreach my $item (@items) {
        my $proj = $item->[0];
        my $resu = $item->[1];
        $self->printer($color, $proj, $resu);
    }
    return;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis

    with qw( App::PlannedCopy::Role::Printable );

    $self->item_printer( $res );

=head1 Description

A role for printing messages to the terminal.

=head1 Interface

=head2 Attributes

=item3 term_size

Returns the width of the terminal in characters.

=item3 _issue_category_color_map

Holds the mapping between a category and a color name.

=head2 Instance Methods

=head3 get_color

Returns the mapped color name for the category given as parameter.

=head3 points

Returns a string of dot chars used for displaying the C<...>.

=head3 printer

A colorized print for items, consisting of a line that starts with the
name of the source file, followed by a number of dot chars, followed
by the name of the destination file.

=item3 get_issue_header

Returns a string corresponding to an issue category.

=item3 get_item_color

Return C<green2> or another color as returned by the C<get_color>
method, if the item has issues.

=head3 item_printer

Prints a colorized line to the terminal, corresponding to a record in
the resource file, using the C<printer> method and if there are issues
attached to the record, print them also using the C<issue_printer>
method.

The source and the destination strings have an assigned color:

=over

=item blue2 if the destination is undefined

=item green2 if all ok

=item yellow if the record needs atention

=back

=item3 issue_printer

=item3 print_exeception_message

Prints a colorized line to the terminal, corresponding to an issue.

=item3 project_changes_list_printer

A colorized print for items added, kept and removed from the resource
file.

=item3 project_list_printer

A colorized print for the directories under the C<repo_path> dir.

=item3 difference_printer

Prints a list of items to the terminal using the C<printer> method.

=cut
