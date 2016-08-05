package App::PlannedCopy::Role::Counters;

# ABSTRACT: Counters role for the application

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

has count_same => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_count_same => 'inc',
    },
);

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis

    with qw( App::PlannedCopy::Role::Counters );

    $self->inc_count_skip;

    say ' - skipped  : ', $self->count_skip, ' items';

=head1 Description

A common role which encapsulates the counter attributes and methods
required by the resource element module.

=head1 Interface

=head2 Attributes

=head3 count_proc

A counter attribute for the processed records.

=head3 count_resu

A counter attribute for the resouce elemnents.

=head3 count_inst

A counter attribute for the installed, checked or synchronized
records.

=head3 count_diff

A counter attribute for the diff-ed records.

=head3 count_skip

A counter attribute for the skipped records.

=head3 count_proj

A counter attribute for the projects.

=head3 count_dirs

A counter attribute for the directories.

=head3 count_same

A counter attribute for the records with no difference between the
source and destination files.

=cut
