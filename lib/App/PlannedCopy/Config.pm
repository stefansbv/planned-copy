package App::PlannedCopy::Config;

# ABSTRACT: The configuration module

use 5.010001;
use utf8;
use English;
use Moose;
use Path::Tiny;
use Config::GitLike 1.11;
use URI;
use Hash::Merge::Simple qw/merge/;
use namespace::autoclean;

use constant ISMSW => $^O eq 'MSWin32';

extends 'Config::GitLike';

use App::PlannedCopy::Exceptions;

has '+confname' => ( default => 'plannedcopy.conf' );
has '+encoding' => ( default => 'UTF-8' );

sub user_dir {
    my $hd
        = ISMSW && "$]" < '5.016'
        ? $ENV{HOME} || $ENV{USERPROFILE}
        : ( glob('~') )[0];
    Exception::Config::Error->throw(
        message => 'Could not determine home directory',
        logmsg  => "System error.\n",
    ) if not $hd;
    return path $hd, '.plannedcopy';
}

sub system_dir { path '/etc'; }

sub system_file {
    my $self = shift;
    return path $ENV{PLCP_SYS_CONFIG}
        || $self->system_dir->path( $self->confname );
}

sub global_file { shift->system_file }

sub user_file {
    my $self = shift;
    return path $ENV{PLCP_USR_CONFIG}
        || path( $self->user_dir, $self->confname );
}

has 'repo_path' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $conf = $self->user_file;
        return $ENV{PLCP_REPO_PATH}
            || $self->get( key => 'local.path' )
            || Exception::Config::Error->throw(
                message => "No 'local.path' is set in config! ($conf)",
                logmsg  => "Config error.\n",
            );
    },
);

has 'repo_url' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get( key => 'remote.url' )
            || Exception::Config::Error->throw(
                message => 'No remote.url is set in config!',
                logmsg  => "Config error.\n",
            );
    },
);

has 'uri' => (
    is      => 'rw',
    isa     => 'URI',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return URI->new( $self->repo_url );
    },
);

has 'current_user' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => sub {
        if ( ISMSW ) {
            require Win32;
            return Win32::LoginName();
        }
        else {
            return ( getpwuid($REAL_USER_ID) )[0];
        }
        return;
    },
);

has 'diff_tool' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get( key => 'core.diff-tool' )
            || ( ( $self->current_user eq 'root' ) ? 'diff' : 'kompare' );
    },
);

has 'resource_file_name' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get( key => 'core.resource-file' ) || 'resource.yml';
    },
);

has 'resource_file_name_disabled' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->resource_file_name . '.off';
    },
);

# From Sqitch ;)
sub get_section {
    my ( $self, %p ) = @_;
    $self->load unless $self->is_loaded;
    my $section = lc $p{section} // '';
    my $data    = $self->data;
    return {
        map  {
            ( split /[.]/ => $self->initial_key("$section.$_") )[-1],
            $data->{"$section.$_"}
        }
        grep { s{^\Q$section.\E([^.]+)$}{$1} } keys %{$data}
    };
}

# Idem
sub initial_key {
    my $key = shift->original_key(shift);
    return ref $key ? $key->[0] : $key;
}

sub resource_file {
    my ($self, $project) = @_;
    return unless $self->repo_path and $project;
    return path( $self->repo_path, $project, $self->resource_file_name )->stringify;
}

has '_issue_category_color_map' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1, 
    default => sub {
        my $self  = shift;
        my $default = {
            info     => 'yellow2',
            warn     => 'blue2',
            error    => 'red2',
            done     => 'green2',
            none     => 'clear',
            disabled => 'grey50',
        };
        my $color = $self->get_section( section => 'color' );
        my $merged = merge $default, $color;
        return $merged;
    },
    handles => {
        get_color   => 'get',
        color_pairs => 'kv',
    },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

  my $config = App::PlannedCopy::Config->new;
  say scalar $config->dump;

=head1 Description

This class provides the interface to App::PlannedCopy configuration.
It inherits from L<Config::GitLike>.

=head1 Interface

=head2 Attributes

=head3 system_dir

Returns the path to the system configuration directory, which is
C<$Config{prefix}/etc/palnnedcopy/>.

=head3 user_dir

Returns the path to the user configuration directory, which is user's
home.

=head3 C<system_file>

Returns the path to the system configuration file. The value returned
will be the contents of the C<$PLCP_SYS_CONFIG> environment variable,
if it's defined, or else C<$Config{prefix}etc/plannedcopy/plannedcopyrc>.

=head3 confname

=head3 encoding

=head3 global_file

=head3 user_file

=head3 repo_path

=head3 repo_url

=head3 uri

=head3 current_user

=head3 diff_tool

=head3 resource_file_name

Returns the name of the resource file.

=head3 resource_file_name_disabled

Returns the name of the disabled resource file.

=head2 Instance Methods

=head3 ISMSW

=head3 dir_file

=head3 get_section

  my $core = $config->get_section(section => 'core');
  my $pg   = $config->get_section(section => 'engine.pg');

Returns a hash reference containing only the keys within the specified
section or subsection.

* Method borrowed entirely from Sqitch, including the documentation.

=head3 initial_key

  my $key = $config->initial_key($data_key);

Given the lowercase key from the loaded data, this method returns it in its
original case. This is like C<original_key>, only in the case where there are
multiple keys (for multivalue keys), only the first key is returned.

* Method borrowed entirely from Sqitch, including the documentation.

=head3 resource_file

Returns a stringified representation of an L<Path::Tiny> object
representing a resource file path for a particular project.

=cut
