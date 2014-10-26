package App::ConfigManager::Role::Printable;

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

sub printer {
    my ( $self, $rec ) = @_;
    my $gap = 2 + 1;
    my $space  = q{ };
    my $points = '.' x
        (         $self->term_size
                - $rec->src->name_len
                - $rec->dst->path_len
                - $gap );
    my $errorlevel = $self->get_error_level;
  SWITCH: {
        $errorlevel eq 'error' && do {
            print color 'bright_red';
            last SWITCH;
        };
        $errorlevel eq 'warn' && do {
            print color 'bright_yellow';
            last SWITCH;
        };
        $errorlevel eq 'info' && do {
            print color 'green';
            last SWITCH;
        };
    }
    print $space
        , $rec->src->_name
        , $space
        , $points
        , $space
        , $rec->dst->short_path
        ;
    print color 'reset';
    print "\n";
    return;
}

sub array_printer {
    my ( $self, $errorlevel, @array ) = @_;
    my $gap = 2 + 1;
    my $space  = q{ };

  SWITCH: {
        $errorlevel eq 'removed' && do {
            print color 'bright_red';
            last SWITCH;
        };
        $errorlevel eq 'added' && do {
            print color 'bright_yellow';
            last SWITCH;
        };
        $errorlevel eq 'kept' && do {
            print color 'green';
            last SWITCH;
        };
    }
    foreach my $item (@array) {
        my $points = '.' x (
            $self->term_size - length($item) - length($errorlevel) - $gap
        );
        print $space ,
              $item,
              $space,
              $points,
              $space,
              $errorlevel;
        print "\n";
    }
    print color 'reset';
    return;
}

no Moose::Role;

1;
