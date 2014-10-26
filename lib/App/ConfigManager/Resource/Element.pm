package App::ConfigManager::Resource::Element;

# ABSTRACT: Parse a resource.yml config file

use 5.010001;
use Moose;
use namespace::autoclean;

use App::ConfigManager::Resource::Element::Source;
use App::ConfigManager::Resource::Element::Destination;

has '_source' => (
    is       => 'ro',
    isa      => 'HashRef',
    init_arg => 'source',
);

has '_destination' => (
    is       => 'ro',
    isa      => 'HashRef',
    init_arg => 'destination',
);

sub src {
    my $self = shift;
    return App::ConfigManager::Resource::Element::Source->new(
        $self->_source );
}

sub dst {
    my $self = shift;
    return App::ConfigManager::Resource::Element::Destination->new(
        $self->_destination );
}

__PACKAGE__->meta->make_immutable;

1;
