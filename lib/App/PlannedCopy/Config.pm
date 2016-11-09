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

use constant RESOURCE_FILE => 'resource.yml';

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
        return $self->get( key => 'core.diff-tool' )
            || ( ( $self->current_user eq 'root' ) ? 'diff' : 'kompare' );
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
    return path( $self->repo_path, $project, RESOURCE_FILE )->stringify;
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

=head2 Constants

=head2 RESOURCE_FILE

Returns the name of the resource file.

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

TODO: POD
