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

sub run {
    my ( $self ) = @_;
    if ( $self->action eq 'clone' ) {
        try {
            $self->clone_repo;
        }
        catch {
            if ( my $e = Exception::Base->catch($_) ) {
                if ( $e->isa('Exception::IO::Git') ) {
                    say "[EE] ", $e->message;
                }
            }
            else {
                die "[EE] Unknown exception: ", $_;
            }
        };
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
                say "[EE] ", $e->message;
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

    print "Cloning '$uri'\n   into '$path'...\n";
    if ( $self->dryrun ) {
        print "dry-run!\n";
        return;
    }
    my $to_path = path($path)->parent;
    if ( chdir $to_path ) {
        try { git::clone $uri->as_string }
        catch {
            Exception::IO::Git->throw(
                message  => 'Git clone failed.',
                logmsg   => $_,              # doesn't show !?!
            );
        };
        print "done.\n";
    }
    else {
        say "[EE] Can't cd to $to_path: $!\n";
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The repo command.  It is used to clone the repository into the
C<repo_path>.

=head1 Interface

=head2 Attributes

=head3 action

A required parameter attribute that holds the action to be taken.  The
only available option is currently C<clone>.

=head2 Instance Methods

=head3 run

The method to be called when the C<repo> command is run.

Invokes to only implemented method C<clone_repo>.

=head3 clone_repo

Uses the L<Git::Sub> module's clone method to clone the C<configs>
repository.

# git clone ssh://[Git users]@[IP address or hostname]/[Git repository path]

=cut
