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
    default => sub {
        my $username = getpwuid($<);
        return ( $username eq 'root' ) ? 'global' : 'user';
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

sub execute {
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
