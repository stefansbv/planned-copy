package App::PlannedCopy::Resource::Element;

# ABSTRACT: Parse a resource.yml config file

use 5.010001;
use List::Util qw(max);
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

has '_issue_weight_map' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub {
        return {
            info  => 1,
            warn  => 2,
            error => 3,
        };
    },
    handles => {
        get_weight   => 'get',
        weight_pairs => 'kv',
    },
);

has 'issues_category' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    init_arg => undef,
    default  => sub {
        return '';
    },
);

has '_issue' => (
    traits   => ['Array'],
    is       => 'rw',
    isa      => 'ArrayRef[App::PlannedCopy::Issue]',
    required => 1,
    default  => sub { [] },
    handles  => {
        all_issues    => 'elements',
        add_issue     => 'push',
        get_issue     => 'get',
        count_issues  => 'count',
        has_no_issues => 'is_empty',
    },
    trigger => sub {
        my ( $self, $new, $old ) = @_;
        $self->_new_issue_category;          # compute new dominant category
    },
);

sub has_action {
    my ($self, $action) = @_;
    foreach my $issue ( $self->all_issues ) {
        return 1 if $issue->action eq $action;
    }
    return 0;
}

sub _new_issue_category {
    my $self = shift;
    my @issues;
    foreach my $issue ( $self->all_issues ) {
        push @issues, $self->get_weight( $issue->category );
    }
    my $weight = max @issues;
    for my $pair ( $self->weight_pairs ) {
        $self->issues_category( $pair->[0] ) if $weight == $pair->[1];
    }
    return;
}

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

An hash reference containing a destination section of the resource
file.

=head3 _issue

An array reference containing C<App::PlannedCopy::Issue> objects.  It
is used by the printer methods to display the issues related to each
resource item.

The objects are created and added to this array by the methods from
the C<App::PlannedCopy::Role::Validate::Common> role.  This methods
are invoked by the specific C<validate_element> method of the current
command.

When the C<handle_exception> method is invoked by the current command,
the cathed exceptions are also added as C<App::PlannedCopy::Issue>
objects.

=head3 _issue_weight_map

Maps issue names with a weight integer.

=head3 issues_category

Holds the issue category with the greatest weight acording to the
C<_issue_weight_map>.  It is used by the printer methods to assign
colors to the resource items.

=head2 Instance Methods

=head3 src

Returns the L<App::PlannedCopy::Resource::Element::Source> instance.

=head3 dst

Returns the L<App::PlannedCopy::Resource::Element::Destination>
instance.

=head3 _new_issue_category

A method invoked by a C<_issue> trigger when a new issue is added.
Sets the new C<issues_category> for current resource element.

=cut
