package App::PlannedCopy::Resource::Element::Source;

# ABSTRACT: The source resource element object

use 5.010001;
use utf8;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Path::Tiny;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Resource::Element);

has '_type' => (
    is       => 'ro',
    isa      => enum( [qw(archive file)] ),
    required => 0,
    init_arg => 'type',
    default  => sub {'file'},
);

has '_abs_path' => (
    is      => 'ro',
    isa     => 'Maybe[Path::Tiny]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        unless ( $self->config->repo_path ) {
            Exception::Config::Error->throw(
                usermsg => "No 'repo_path' is set!",
                logmsg  => "Config error.\n",
            );
        }
        unless ( $self->_full_path ) {
            die "Exception here!\n";
        }
        my $path =  path( $self->config->repo_path, $self->_full_path );
        return $path;
    },
);

has '_parent_dir' => (
    is       => 'ro',
    isa      => 'Maybe[Path::Tiny]',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->_abs_path->parent if $self->_abs_path;
        return;
    },
);

sub type_is {
    my ($self, $type_name) = @_;
    return 1 if $self->_type eq $type_name;
    return;
}

__PACKAGE__->meta->make_immutable;

1;
