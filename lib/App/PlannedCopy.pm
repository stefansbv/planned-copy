package App::PlannedCopy;

# ABSTRACT: The PlannedCopy application main module

use 5.0100;
use utf8;
use Moose;
use Path::Tiny;
use Path::Iterator::Rule;
use IPC::System::Simple 1.17 qw(run);
use MooseX::App qw(Color Version);
use App::PlannedCopy::Config;
use App::PlannedCopy::Issue;
use App::PlannedCopy::Resource;

with qw(App::PlannedCopy::Role::Counters);

app_namespace 'App::PlannedCopy::Command';

option 'dryrun' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Simulate command execution.],
);

option 'verbose' => (
    is            => 'rw',
    isa           => 'Bool',
    cmd_aliases   => [qw(v)],
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
    isa      => 'Maybe[Str]',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $repo_path = $self->config->repo_path;
        my ($user) = $repo_path =~ m{^/home/(\w+)/}xmg;
        unless ($user) {
            # Ugly workaround for tests :(
            $user = 'plcp-test-user' if $repo_path =~ m{^t/}xmg;
        }
        return $user;
    },
);

has '_projects' => (
    isa      => 'ArrayRef[HashRef]',
    traits   => ['Array'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_projects',
    handles  => {
        get_project    => 'get',
        projects       => 'elements',
        find_project   => 'first',
        count_projects => 'count',
    },
);

sub _build_projects {
    my $self = shift;

    die
        "Not configured!\n  Please, use the config command to configure planned-copy.\n"
        unless defined $self->config->repo_path;

    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    $rule->min_depth(1);
    $rule->max_depth(1);

    my $next = $rule->iter( $self->config->repo_path );
    my @dirs;
    while ( defined( my $item = $next->() ) ) {
        my $path = path($item);
        if ( $path->is_dir ) {
            my $res_file = path( $path, 'resource.yml' );
            my $has_resu = $res_file->is_file ? 1 : 0;
            my $scope    = $has_resu ? $self->get_project_scope($res_file) : undef;
            $self->inc_count_proj if $has_resu;
            $self->inc_count_dirs;
            push @dirs, {
                path     => $path->basename,
                resource => $has_resu,
                scope    => $scope,
            };
        }
    }
    return \@dirs;
}

has editor => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return
            $self->config->get( key => 'core.editor' ) || $ENV{EDITOR};
    }
);

sub shell {
    my ($self, $cmd) = @_;
    local $SIG{__DIE__} = sub {
        ( my $msg = shift ) =~ s/\s+at\s+.+/\n/ms;
        die $msg;
    };
    run $cmd;
    return $self;
}

sub get_project_scope {
    my ( $self, $file ) = @_;
    die "The 'get_project_scope' method requires a resource file parameter.\n"
        unless $file->is_file;
    my $res = App::PlannedCopy::Resource->new( resource_file => $file );
    return $res->resource_scope;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

Planned Copy - a smarter copy application for your Linux box.

=head1 Interface

=head2 Attributes

=head3 dryrun

An attribute that holds the C<dryrun> comman line option.

=head3 verbose

An attribute that holds the C<verbose> comman line option.

=head3 config

Creates and returns an instance object of the
L<App::PlannedCopy::Config> class.

=head3 _projects

Holds an array reference of the names of the subdirectories of
L<repo_path> that contains a resource file (L<resource.yml>).

=head1 Known Problems

If the C<diff-tool> configuration is set to a tool with a GUI, and the
tool could not be run in a given environment, C<plcp> throws an
exception.

Checking if the C<DISPLAY> environment variable is defined is not
enough.

=cut
