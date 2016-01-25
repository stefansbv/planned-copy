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

sub get_error_str {
    my $self       = shift;
    my $errorlevel = $self->get_error_level;
    return
          $errorlevel eq 'error' ? '[EE]'
        : $errorlevel eq 'warn'  ? '[WW]'
        : $errorlevel eq 'info'  ? '[II]'
        : $errorlevel eq 'done'  ? ''
        : $errorlevel eq 'none'  ? ''
        :                          '';
}

sub get_color {
    my $self       = shift;
    my $errorlevel = $self->get_error_level;
    return
          $errorlevel eq 'error' ? 'red2'
        : $errorlevel eq 'warn'  ? 'yellow1'
        : $errorlevel eq 'info'  ? 'blue2'
        : $errorlevel eq 'done'  ? 'green2'
        : $errorlevel eq 'none'  ? 'reset'
        :                          'reset';
}

sub item_printer {
    my ( $self, $rec ) = @_;
    my $color = $self->get_color;
    $self->printer($color, $rec->src->_name, $rec->dst->short_path);
    return;
}

sub exception_printer {
    my ($self, $e) = @_;
    if ( $e->isa('Exception::IO::PathNotDefined') ) {
        $self->print_exeception_message( $e->message, $e->pathname )
            if $self->verbose;
    }
    elsif ( $e->isa('Exception::IO::PathNotFound') ) {
        $self->print_exeception_message($e->message, $e->pathname);
    }
    elsif ( $e->isa('Exception::IO::FileNotFound') ) {
        $self->print_exeception_message( $e->message, $e->pathname )
            if $self->verbose;
    }
    elsif ( $e->isa('Exception::IO::PermissionDenied') ) {
        $self->print_exeception_message($e->message, $e->pathname)
            if $self->verbose;
    }
    elsif ( $e->isa('Exception::IO::SystemCmd') ) {
        $self->print_exeception_message($e->usermsg, $e->logmsg);
    }
    elsif ( $e->isa('Exception::IO::WrongUser') ) {
        $self->print_exeception_message( $e->message, $e->username )
            if $self->verbose;
    }
    elsif ( $e->isa('Exception::IO::WrongPerms') ) {
        $self->print_exeception_message( $e->message, $e->perm )
            if $self->verbose;
    }
    else {
        # Unknown exception
        say "!Unknown exception!: ", $e;
    }

    return;
}

sub print_exeception_message {
    my ( $self, $message, $details ) = @_;
    my $color = $self->get_color;
    my $erstr = $self->get_error_str;
    print fg($color, "  $erstr ");
    print $message, ' ', $details;
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
    my $color = $self->get_color;
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

TODO

=head1 Description

=head1 Interface

=head2 Attributes

=head2 Instance Methods

=head3 points

Returns a string of dot chars used for displaying the ...

=head3 printer

A colorized print for items, consisting of a line that starts with the
name of the source file, followed by a number of dot chars, followed
by the name of the destination file.

=head3 get_error_str

Returns a string that identifies the exception type using a dispatch
table.

=head3 get_color

A dispatch table that binds the C<error_level> with a color.

=head3 item_printer

Prints an item to the terminal using the C<printer> method.

=head3 exception_printer

Uses the C<print_exeception_message> method to print exceptions.

=head3 print_exeception_message

A colorized print for exception messages, consisting of a string
returned by the C<get_error_str> method and the exception message and
details.

=head3 project_changes_list_printer

A colorized print for items added, kept and removed from the resource
file.

=head3 project_list_printer

A colorized print for the directories under the C<repo_path> dir.

=head3 difference_printer

Prints a list of items to the terminal using the C<printer> method.

=cut


