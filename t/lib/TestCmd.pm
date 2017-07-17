package TestCmd;

use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw( App::PlannedCopy::Role::Printable
         App::PlannedCopy::Role::Utils
         App::PlannedCopy::Role::Remote );

has [qw{remote_host user pass}] => (
    is  => 'ro',
    isa => 'Str',
);

has 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Project name.],
);

has 'resource_file' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->config->resource_file( $self->project );
    },
);

__PACKAGE__->meta->make_immutable;

1;
