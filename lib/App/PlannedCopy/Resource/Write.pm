package App::PlannedCopy::Resource::Write;

# ABSTRACT: Write a 'resource.yml' file

use 5.010001;
use utf8;
use Moose;
use MooseX::Types::Path::Tiny qw(Path);
use namespace::autoclean;

use Try::Tiny;
use YAML::Tiny 1.57;                         # errstr deprecated

use App::PlannedCopy::Exceptions;

has 'resource_file' => (
    is     => 'ro',
    isa    => Path,
    coerce => 1,
);

sub create_yaml {
    my ($self, $data) = @_;
    my $yaml = YAML::Tiny->new($data);
    my $file = $self->resource_file;
    unless ($file->parent->is_dir) {
        Exception::IO::PathNotFound->throw(
            message  => 'The parent dir was not found.',
            pathname => $file->parent->stringify,
        );
    }
    try   { $yaml->write($file->stringify) }
    catch {
        Exception::Config::YAML->throw(
            message => "Failed to write resource file '$file'",
            logmsg  => $_,
        );
    };
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

    my $rw = App::PlannedCopy::Resource::Write->new(
        resource_file => $resource_file
    );
    $rw->create_yaml( { resources => $data } );


=head1 Description

Write a L<resource.yml> file.

=head1 Interface

=head2 Attributes

=head3 resource_file

Holds the resource file path as a Path::Tiny object.

=head2 Instance Methods

=head3 create_yaml

Create a YAML file using the data provided.

=cut
