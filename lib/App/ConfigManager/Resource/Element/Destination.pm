package App::ConfigManager::Resource::Element::Destination;

# ABSTRACT: The destination resource element object

use Moose;
use App::ConfigManager::Types;
use namespace::autoclean;

with qw{App::ConfigManager::Role::Resource::Element};

has '_perm' => (
    is       => 'ro',
    isa      => 'Octal',
    required => 1,
    default  => sub {'0644'},
    init_arg => 'perm',
);

has '_abs_path' => (
    is       => 'ro',
    isa      => 'Path::Tiny',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->_full_path->absolute;
    },
);

has '_parent_dir' => (
    is       => 'ro',
    isa      => 'Path::Tiny',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->_abs_path->parent;
    },
);

__PACKAGE__->meta->make_immutable;

1;
