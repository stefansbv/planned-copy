package App::PlannedCopy::Command::Config;

# ABSTRACT: Configure the application

use 5.010001;
use utf8;
use Try::Tiny;
use MooseX::App::Command;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends qw(App::PlannedCopy);

use App::PlannedCopy::Exceptions;

command_long_description q[Install the application configuration file.];

option 'remote_url' => (
    is            => 'rw',
    isa           => 'Str',
    cmd_flag      => 'url',
    documentation => q[The remote URL of the 'configs' repository.],
);

option 'diff_tool' => (
    is            => 'rw',
    isa           => 'Str',
    cmd_flag      => 'diff-tool',
    documentation => q[The diff tool name.  Defaults to 'kompare'.],
);

option 'local_path' => (
    is            => 'rw',
    isa           => 'Str',
    cmd_flag      => 'path',
    documentation => q[The local path to the 'configs' repository.],
);

parameter 'action' => (
    is            => 'rw',
    isa           => enum( [qw(set dump)] ),
    required      => 1,
    documentation => q[Action name ( set | dump ).],
);

has 'context' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return ( $self->config->current_user eq 'root' ) ? 'global' : 'user';
    },
);

has 'file' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $meth = $self->context . '_file';
        return $self->config->$meth;
    }
);

sub run {
    my ( $self ) = @_;

    # Set
    if ( $self->action eq 'set' ) {
        my $url       = $self->remote_url;
        my $path      = $self->local_path;
        my $diff_tool = $self->diff_tool;
        if ( $url or $path or $diff_tool) {
            $self->create_config($url, $path, $diff_tool);
        }
        else {
            say "[II] Run the 'set' command with the '--url' and/or '--path' options, to create/update the config file.";
        }
    }

    # Dump
    if ( $self->action eq 'dump' ) {
        my %conf = $self->config->dump;
        say "Current config:";
        say " none!" if scalar keys %conf == 0;
        while ( my ( $key, $value ) = each %conf ) {
            print " $key = $value\n";
        }
    }

    return;
}

sub create_config {
    my ($self, $url, $path, $diff_tool) = @_;
    if ($path) {
        say "Path = ", $path;
        $self->_set('local.path', $path);
    }
    if ($url) {
        say "URL  = ", $url;
        $self->_set('remote.url', $url);
    }
    if ($diff_tool) {
        say "Tool = ", $diff_tool;
        $self->_set('local.diff-tool', $diff_tool);
    }
    return;
}

sub _set {
    my ( $self, $key, $value ) = @_;

    die "Wrong number of arguments."
        if !defined $key || $key eq '' || !defined $value;

    print "Config write to ", $self->file, "...\r";

    try {
        $self->config->set(
            key      => $key,
            value    => $value,
            filename => $self->file,
        );
    }
    catch {
        # print "cConfig write to ", $self->file, "...failed\n";
        # say "[EE] Config: $_";
    };

    print "Config write to ", $self->file, "...done\n";

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

    use App::PlannedCopy;

    App::PlannedCopy->new_with_command->run;

=head1 Description


=head1 Interface

=head2 Attributes

=head3 remote_url

An attribute that holds the C<remote_url> configuration.  The remote
URL of the C<configs> repository.

=head3 diff_tool

An attribute that holds the C<diff_tool> configuration.  The diff tool
name.  Defaults to 'kompare'.

=head3 local_path

An attribute that holds the C<local_path> configuration.  The local
path to the C<configs> repository.

=head3 action

A required parameter attribute that holds the action to be taken.  The
available options are currently C<set> and C<dump>

=head3 context

Returns C<global> for the C<root> user or C<user> for normal users.

=head3 file

Returns the configuration file name for the current context.

=head2 Instance Methods

=head3 run

Executes one of the required actions.

=head3 create_config

Creates a set of configurations for C<path>, C<URL> and C<tool> if the
values are provided.

=head3 _set

Creates or modifies a key - value record in the configuration file.

=cut
