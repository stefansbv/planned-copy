package App::PlannedCopy::Resource::Read;

# ABSTRACT: Read a 'resource.yml' file

use 5.010001;
use utf8;
use Moose;
use MooseX::Types::Path::Tiny qw(Path);
use YAML::Tiny 1.57;                         # errstr deprecated
use Try::Tiny;
use App::PlannedCopy::Exceptions;
use namespace::autoclean;

has 'resource_file' => (
    is     => 'ro',
    isa    => Path,
    coerce => 1,
);

has contents => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_contents'
);

sub _build_contents {
    my $self = shift;
    my $file = $self->resource_file;
    return [] unless $file->is_file;
    my $yaml = try { YAML::Tiny->read( $file->stringify ) }
    catch {
        Exception::Config::YAML->throw(
            usermsg => 'Failed to load the resource file.',
            logmsg  => $_,
        );
    };
    return $yaml->[0]{resources};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

    use App::PlannedCopy::Resource::Read;

    my $reader = App::PlannedCopy::Resource::Read->new(
        resource_file => $self->resource_file );

    my $contents = $reader->contents;

=head1 Description

Reads a L<resource.yml> file and returns it't contents as an array
reference.

=head1 Interface

=head2 Attributes

=head3 resource_file

Holds the resource file path as a Path::Tiny object.

=head3 contents

Returns an array reference with the content of the L<resource.yml> file.

=cut
