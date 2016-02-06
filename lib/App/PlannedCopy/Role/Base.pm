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

has count_diff => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_diff   => 'inc',
        reset_count_diff => 'reset',
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

has count_proj => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_proj => 'inc',
    },
);

has count_dirs => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_dirs => 'inc',
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

__END__

=encoding utf8

=head1 Synopsis

    with qw( App::PlannedCopy::Role::Base );

    $self->inc_count_skip;

    say ' - skipped  : ', $self->count_skip, ' items';

=head1 Description

A common role which encapsulates the counter and error_level
attributes and methods required by the resource element module.

=head1 Interface

=head2 Attributes

=head3 count_proc

A counter attribute for the processed records.

=head3 count_resu

A counter attribute for the resouce elemnents.

=head3 count_inst

A counter attribute for the installed, diffed, checked or synchronized
records.

=head3 count_skip

A counter attribute for the skipped records.

=head3 count_proj

A counter attribute for the projects.

=head3 count_dirs

A counter attribute for the directories.

=head3 error_level

An r/w attribute to hold the C<error_level> for the current record.
It is used to keep track of the state of the record.

TODO: rename and describe better.

=head2 Instance Methods

=head3 is_error_level

    $self->is_error_level('info');

Returns true if the current error level matches the name given as
parameter.

=head3 is_not_error_level

    $self->is_not_error_level('info');

Returns true if the current error level does not match the name given
as parameter.

=cut
