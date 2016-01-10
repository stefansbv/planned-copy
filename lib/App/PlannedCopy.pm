package App::PlannedCopy;

# ABSTRACT: Planned copy - application

use 5.0100;
use utf8;
use Moose;
use MooseX::App qw(Color Version);
use App::PlannedCopy::Config;

with qw(App::PlannedCopy::Role::Base);

app_namespace 'App::PlannedCopy::Command';

option 'dryrun' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Simulate command execution.],
);

option 'verbose' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Verbose output.],
);

has config => (
    is      => 'ro',
    isa     => 'App::PlannedCopy::Config',
    lazy    => 1,
    default => sub {
        App::PlannedCopy::Config->new;
    }
);

has 'repo_owner' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $repo_path = $self->config->repo_path;
        my ($user) = $repo_path =~ m{^/home/(\w+)/}xmg;
        return $user;
    },
);

__PACKAGE__->meta->make_immutable;

1;
