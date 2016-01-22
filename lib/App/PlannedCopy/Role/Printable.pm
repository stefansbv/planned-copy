package App::PlannedCopy::Role::Printable;

# ABSTRACT: Role for printing messages

use 5.0100;
use utf8;
use Moose::Role;
use Term::ReadKey;
use Term::ExtendedColor qw(:all);
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

sub item_printer {
    my ( $self, $rec ) = @_;
    my $errorlevel = $self->get_error_level;
    my $color
        = $errorlevel eq 'error' ? 'red2'
        : $errorlevel eq 'warn'  ? 'yellow1'
        : $errorlevel eq 'info'  ? 'blue2'
        : $errorlevel eq 'done'  ? 'green2'
        : $errorlevel eq 'none'  ? 'reset'
        :                          'reset';
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
    else {
        # Unknown exception
        say "!Unknown exception!: ", $e;
    }

    return;
}

sub print_exeception_message {
    my ( $self, $message, $details ) = @_;
    print fg('red1', '  [EE] ');
    print $message, ' ', $details;
    print "\n";
    return;
}

sub list_printer {
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
    my $color = 'bright_yellow';
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

=head3 term_size

=head2 Instance Methods

=head3 difference_printer

=head3 exception_printer

=head3 item_printer

=head3 list_printer

=head3 points

=head3 print_exeception_message

=head3 printer

=head3 project_list_printer

=cut
