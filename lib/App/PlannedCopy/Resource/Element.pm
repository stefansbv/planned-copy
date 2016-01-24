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

__END__

=encoding utf8

=head1 Synopsis

    use App::PlannedCopy::Resource::Element;

    my $rec = {
        destination => {
            name => 'some-file1',
            path => '/etc',
            perm => '0644',
            user => 'root',
        },
        source => {
            name => 'some-file1.sh',
            path => '',
        },
    };

    my $elem = App::PlannedCopy::Resource::Element->new($rec);

=head1 Description

Creates and returns L<App::PlannedCopy::Resource::Element> objects
which holds the source and destination data of a specific resource
element.

=head1 Interface

=head2 Attributes

=head3 _source

An hash reference containing a source section of the resource file.

=head3 _destination

An hash reference containing a destionation section of the resource
file.

=head2 Instance Methods

=head3 src

Returns the L<App::PlannedCopy::Resource::Element::Source> instance.

=head3 dst

Returns the L<App::PlannedCopy::Resource::Element::Destination>
instance.

=cut
