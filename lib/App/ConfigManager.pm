package App::ConfigManager;

# ABSTRACT: Yet Another Configuration Manager - application

use utf8;
use Moose;
use 5.0100;

use MooseX::App qw(Color Version);

use App::ConfigManager::Config;

with qw(App::ConfigManager::Role::Base);

app_namespace 'App::ConfigManager::Command';

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
    isa     => 'App::ConfigManager::Config',
    lazy    => 1,
    default => sub {
        App::ConfigManager::Config->new;
    }
);

__PACKAGE__->meta->make_immutable;

1;
