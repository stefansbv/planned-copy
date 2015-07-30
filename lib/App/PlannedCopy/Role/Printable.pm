package App::PlannedCopy::Role::Printable;

# ABSTRACT: Role for printing messages

use 5.0100;
use utf8;
use Moose::Role;
use Term::ReadKey;
use Term::ANSIColor;
use IO::Handle;

STDOUT->autoflush(1);

has 'term_size' => (
    is      => 'ro',
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
    print color $color;
    print $space
        , $msg_l
        , $space
        , $points
        , $space
        , $msg_r
        ;
    print color 'reset';
    print "\n";
    return;
}

sub item_printer {
    my ( $self, $rec ) = @_;
    my $errorlevel = $self->get_error_level;
    my $color
        = $errorlevel eq 'error' ? 'bright_red'
        : $errorlevel eq 'warn'  ? 'bright_yellow'
        : $errorlevel eq 'info'  ? 'green'
        :                          'reset';
    $self->printer($color, $rec->src->_name, $rec->dst->short_path);
    return;
}

sub exception_printer {
    my ($self, $e) = @_;
    if ($self->verbose) {
        print color 'bright_red';
        print "  [EE] ";
        print color 'reset';
        print $e->message, ' ', $e->pathname;
        print "\n";
    }
    return;
}

sub list_printer {
    my ( $self, $errorlevel, @array ) = @_;
    my $color
        = $errorlevel eq 'removed' ? 'bright_red'
        : $errorlevel eq 'added'   ? 'bright_yellow'
        : $errorlevel eq 'kept'    ? 'green'
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
            $color = 'green';
            $mesg  = 'resource';
        }
        else {
            $color = 'bright_yellow';
            $mesg  = 'no resource';
        }
        $self->printer($color, $path, $mesg);
    }
    return;
}

no Moose::Role;

1;
