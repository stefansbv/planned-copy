package App::PlannedCopy::Config;

# ABSTRACT: The configuration module

use 5.010001;
use utf8;
use English;
use Moose;
use File::HomeDir;
use Path::Tiny;
use Config::GitLike 1.11;
use URI;
use namespace::autoclean;

extends 'Config::GitLike';

use App::PlannedCopy::Exceptions;

has '+confname' => ( default => 'plannedcopyrc' );
has '+encoding' => ( default => 'UTF-8' );

sub dir_file { undef }

override global_file => sub {
    my $self = shift;
    return path $ENV{PLCP_SYS_CONFIG}
        || $self->SUPER::global_file(@_);
};

override user_file => sub {
    my $self = shift;
    return path $ENV{PLCP_USR_CONFIG}
        || $self->SUPER::user_file(@_);
};

has 'repo_path' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get( key => 'local.path' )
            || Exception::Config::Error->throw(
                message => 'No local.path is set in config!',
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
        return getpwuid($REAL_USER_ID);
    },
);

has 'diff_tool' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get( key => 'local.diff-tool' )
            || ( ( $self->current_user eq 'root' ) ? 'diff' : 'kompare' );
    },
);

sub resource_file {
    my ($self, $project) = @_;
    return unless $self->repo_path and $project;
    return path( $self->repo_path, $project, 'resource.yml' )->stringify;
}

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

=head3 confname

=head3 encoding

=head3 global_file

=head3 user_file

=head3 repo_path

=head3 repo_url

=head3 uri

=head3 current_user

=head3 diff_tool

=head2 Instance Methods

=head3 dir_file

=head3 resource_file

Returns a stringified representation of an L<Path::Tiny> object
representing a resource file path for a particular project.

=cut

TODO: POD
