package App::PlannedCopy;

# ABSTRACT: Planned copy - application

use 5.0100;
use utf8;
use Moose;
use Path::Tiny;
use Path::Iterator::Rule;
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
        "Not configured!\n  Please, use the config command to configure the planned-copy.\n"
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
            my $has_resu = path( $path, 'resource.yml')->is_file ? 1 : 0;
            $self->inc_count_proj if $has_resu;
            $self->inc_count_dirs;
            push @dirs, { path => $path->basename, resource => $has_resu };
        }
    }
    return \@dirs;
}

__PACKAGE__->meta->make_immutable;

1;

=head2 _projects

Returns an array reference of the names of the subdirectories of
L<repo_path> that contains a resource file (L<resource.yml>).

=cut
