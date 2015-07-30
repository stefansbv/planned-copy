package App::PlannedCopy::Command::Repo;

# ABSTRACT: Manage the repository

use 5.010001;
use utf8;
use Git::Class;
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
        # continue... :)
        # TODO
    }

    my ($uri, $path);
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
    return unless $uri and $path;

    try   { $self->clone_repo($uri, $path) }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::IO::Git') ) {
                say "[EE] ", $e->usermsg;
                say "[EE] Reason: ", $e->logmsg;
            }
        }
    };

    return;
}

# git clone ssh://[Git users]@[IP address or hostname]/[Git repository path]
sub clone_repo {
    my ( $self, $uri, $path) = @_;

    if ($self->dryrun) {
        print "Cloning the repo '$uri' into '$path'...dry-run.\n";
        return;
    }

    my $git = Git::Class::Cmd->new( die_on_error => 1, verbose => $self->verbose );
    print "Cloning the repo into '$path'...\r";
    try   { $git->clone( $uri, $path ) }
    catch {
        say "";
        Exception::IO::Git->throw(
            usermsg => 'The git clone command failed.',
            logmsg  => $_,
        );
    };
    print "Cloning the repo into '$path'...done\n";

    return;
}


__PACKAGE__->meta->make_immutable;

1;
