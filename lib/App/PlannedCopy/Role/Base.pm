package App::PlannedCopy::Role::Base;

# ABSTRACT: Base role for the application

use Moose::Role;
use MooseX::App::Role;

has count_proc => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_proc => 'inc',
    },
);

has count_resu => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_resu   => 'inc',
        reset_count_resu => 'reset',
    },
);

has count_inst => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_inst => 'inc',
    },
);

has count_skip => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_skip => 'inc',
    },
);

has 'error_level' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    reader   => 'get_error_level',
    writer   => 'set_error_level',
    default  => sub {'info'},
);

has 'current_user' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => sub {
        return getpwuid($<);
    },
);

sub is_error_level {
    my ($self, $level) = @_;
    return $self->get_error_level eq $level;
}

sub is_not_error_level {
    my ($self, $level) = @_;
    return $self->get_error_level ne $level;
}

no Moose::Role;

1;
