package App::PlannedCopy::Resource;

# ABSTRACT: Read a resource.yml config file

use 5.010001;
use utf8;
use Moose;
use MooseX::Iterator;
use YAML::Tiny;
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

has _resource => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_resource'
);

has 'resource_iter' => (
    metaclass    => 'Iterable',
    iterate_over => '_resource',
);

has 'resource_file' => (
    is  => 'rw',
    isa => 'Str',
);

sub _build_resource {
    my $self = shift;
    my $reader = App::PlannedCopy::Resource::Read->new(
        resource_file => $self->resource_file );
    my $contents = try { $reader->contents }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::IO') ) {
                say "[EE] ", $e->message, ' : ', $e->pathname;
            }
            elsif ( $e->isa('Exception::Config::YAML') ) {
                say "[EE] ", $e->usermsg, ' ', $e->logmsg;
            }
            else {
                say "[EE] Unknown exception: $_";
            }
        }
    };
    $contents = [] unless ref $contents; # recover
    my @records;
    foreach my $res ( @{ $contents } ) {
        push @records, App::PlannedCopy::Resource::Element->new($res);
        $self->inc_counter;
    }
    return \@records;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 DESCRIPTION

Build an iterable data structure from a L<resource.yml> file.  The
elements of the data structure are Resource::Element objects.

=head1 ATTRIBUTES

=head2 _resource

An array reference containing the Resource::Element objects.

=head2 resource_file

A path string to a L<resource.yml> file.

=head2 resource_iter

A meta class attribute for the itertor.

=head3 count

A count attribute for the number of resource elements.

=cut
