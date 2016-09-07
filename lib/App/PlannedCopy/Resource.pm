package App::PlannedCopy::Resource;

# ABSTRACT: Build an iterable data structure from a resource.yml file

use 5.010001;
use utf8;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Iterator;
use MooseX::Types::Path::Tiny qw(Path);
use Try::Tiny;
use namespace::autoclean;

use App::PlannedCopy::Resource::Read;
use App::PlannedCopy::Resource::Element;

has count => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_counter => 'inc',
    },
);

has 'resource_file' => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
);

has 'reader' => (
    is      => 'ro',
    isa     => 'App::PlannedCopy::Resource::Read',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $reader = try {
            App::PlannedCopy::Resource::Read->new(
                resource_file => $self->resource_file );
        }
        catch {
            if ( my $e = Exception::Base->catch($_) ) {
                if ( $e->isa('Exception::IO') ) {
                    die "[EE] ", $e->message, ' : ', $e->pathname;
                }
                else {
                    die "[EE] Unknown exception: $_";
                }
            }
        };
        return $reader;
    },
);

sub get_resource_section {
    my ($self, $section) = @_;
    my $reader = $self->reader;
    my $item   = try { $reader->get_contents($section) }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::IO') ) {
                die "[EE] ", $e->message, ' : ', $e->pathname, "\n";
            }
            elsif ( $e->isa('Exception::Config::YAML') ) {
                die "[EE] ", $e->message, ' ', $e->logmsg, "\n";
            }
            else {
                die "[EE] Unknown exception: $_", "\n";
            }
        }
    };
    return $item;
}

has 'resource_scope' => (
    is      => 'ro',
    isa     => enum( [qw(user system)] ),
    lazy    => 1,
    default => sub {
        my $self  = shift;
        my $scope = $self->get_resource_section('scope');
        $scope    = 'user' unless $scope;
        return $scope;
    },
);

has _resource => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_resource',
);

sub _build_resource {
    my $self  = shift;
    my $resources = $self->get_resource_section('resources');
    $resources    = [] unless ref $resources;
    my $records   = [];
    foreach my $res ( @{ $resources } ) {
        push @{$records}, App::PlannedCopy::Resource::Element->new($res);
        $self->inc_counter;
    }
    return $records;
}

has 'resource_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_resource',
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

    use App::PlannedCopy::Resource;

    my $resource_file = 'resource.yml';
    my $res  = App::PlannedCopy::Resource->new( resource_file => $resource_file );
    my $iter = $res->resource_iter;
    while ( $iter->has_next ) {
        my $res = $iter->next;
        # Do something with $res ...
    }

=head1 Description

Build an iterable data structure from a L<resource.yml> file.  The
elements of the data structure are Resource::Element objects.

=head1 Interface

=head2 Attributes

=head3 _resource

An array reference containing the Resource::Element objects.

=head3 resource_file

A path string to a L<resource.yml> file.

=head3 resource_iter

A meta class attribute for the itertor.

=head3 count

A count attribute for the number of resource elements.

=head2 Instance Methods

=head3 get_resource_section

Returns a data-structure representing a section in the resource file.

=cut
