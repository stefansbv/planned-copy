package App::PlannedCopy::Resource::Element;

# ABSTRACT: Parse a resource.yml config file

use 5.010001;
use Moose;
use namespace::autoclean;

use App::PlannedCopy::Resource::Element::Source;
use App::PlannedCopy::Resource::Element::Destination;

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
    return App::PlannedCopy::Resource::Element::Source->new(
        $self->_source );
}

sub dst {
    my $self = shift;
    return App::PlannedCopy::Resource::Element::Destination->new(
        $self->_destination );
}

__PACKAGE__->meta->make_immutable;

1;
