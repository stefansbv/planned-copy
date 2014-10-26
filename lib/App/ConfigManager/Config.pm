package App::ConfigManager::Config;

# ABSTRACT: The configuration module

use 5.010001;
use utf8;

use Moose;
use File::HomeDir;
use Path::Tiny;
use Config::GitLike 1.11;
use URI;

extends 'Config::GitLike';

use App::ConfigManager::Exceptions;

has '+confname' => ( default => 'acmrc' );
has '+encoding' => ( default => 'UTF-8' );

sub dir_file { undef }

override global_file => sub {
    my $self = shift;
    return path $ENV{APP_CM_SYS_CONFIG}
        || $self->SUPER::global_file(@_);
};

override user_file => sub {
    my $self = shift;
    return path $ENV{APP_CM_USR_CONFIG}
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
                usermsg => 'No local.path is set in config!',
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
                usermsg => 'No remote.url is set in config!',
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

sub resource_file {
    my ($self, $project) = @_;
    return unless $self->repo_path and $project;
    return path( $self->repo_path, $project, 'resource.yml' )->stringify;
}

1;
