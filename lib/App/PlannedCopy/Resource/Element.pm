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

=head1 DESCRIPTION

Creates and returns L<App::PlannedCopy::Resource::Element> objects
which holds the source and destination data of a specific resource
element.

=head1 Attributes

=head2 _source

An hash reference containing a source section of the resource file.

=head2 _destination

An hash reference containing a destionation section of the resource
file.

=head1 Instance Methods

=head2 src

Returns the L<App::PlannedCopy::Resource::Element::Source> instance.

=head2 dst

Returns the L<App::PlannedCopy::Resource::Element::Destination>
instance.

=cut
