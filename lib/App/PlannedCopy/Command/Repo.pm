package App::PlannedCopy::Command::Repo;

# ABSTRACT: Manage the repository

use 5.010001;
use utf8;
use Git::Sub qw(clone);
use Path::Tiny;
use Try::Tiny;
use MooseX::App::Command;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Printable);

use App::PlannedCopy::Exceptions;

command_long_description q[Manage the 'configs.git' repository.];

parameter 'action' => (
    is            => 'rw',
    isa           => enum( [qw(clone)] ),
    required      => 1,
    documentation => q[Action name (clone).],
);

sub execute {
    my ( $self ) = @_;

    if ( $self->action eq 'clone' ) {
        $self->clone_repo;
    }

    return;
}

sub clone_repo {
    my $self = shift;

    my ( $uri, $path );
    try {
        $uri  = $self->config->uri;
        $path = $self->config->repo_path;
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::Config::NoConfig') ) {
                say "[EE] ", $e->usermsg;
                say "[II] Run the 'config' comand to create the config file.";
            }
            return;
        }
    };

    unless ( $uri and $path ) {
        say "[II] URI and path are required.";
        say "[II] Run the 'config' comand to create the config file.";
        return;
    }

    if ( $self->dryrun ) {
        print "Cloning the repo '$uri' into '$path'...dry-run.\n";
        return;
    }

    my $to_path = path($path)->parent;
    if ( chdir $to_path ) {
        try { git::clone $uri->as_string };
    }
    else {
        say "[EE] Can't cd to $to_path: $!\n";
    }

    return;
}

# git clone ssh://[Git users]@[IP address or hostname]/[Git repository path]

__PACKAGE__->meta->make_immutable;

1;
