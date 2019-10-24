package App::PlannedCopy::Resource::Element::Source;

# ABSTRACT: The source resource element object

use utf8;
use Moose;
use Moose::Util::TypeConstraints;
use Path::Tiny;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Resource::Element);

has '_type' => (
    is       => 'ro',
    isa      => enum( [qw(archive file)] ),
    required => 0,
    init_arg => 'type',
    default  => sub {'file'},
);

has '_abs_path' => (
    is      => 'ro',
    isa     => 'Maybe[Path::Tiny]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        unless ( $self->config->repo_path ) {
            Exception::Config::Error->throw(
                message => "No 'local.path' is set!",
                logmsg  => "Config error.\n",
            );
        }
        unless ( $self->_full_path ) {
            die "Exception here!\n";
        }
        my $path =  path( $self->config->repo_path, $self->_full_path );
        return $path;
    },
);

has '_parent_dir' => (
    is       => 'ro',
    isa      => 'Maybe[Path::Tiny]',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->_abs_path->parent if $self->_abs_path;
        return;
    },
);

sub type_is {
    my ($self, $type_name) = @_;
    return 1 if $self->_type eq $type_name;
    return;
}

has '_location' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
	init_arg => 'location',
    default  => sub {'local'},
);

sub is_local {
	my $self = shift;
    return 1 if $self->_location eq 'local';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

=head1 Description

A source resource element object.

=head1 Attributes

=head2 _type

Returns a source type, the default is C<file> and the only other value,
currently supported is C<archive>.

=head2 _abs_path

The absolute path of the C<_full_path> as returned by the C<absolute>
instance method of the L<Path::Tiny> object.

=head2 _parent_dir

The parent dir of the C<_abs_path> as returned by the C<parent>
instance method of the L<Path::Tiny> object.

=head2 _location

The C<_location> attribute value is set to C<local> on build time for
all resource source elements.

=head1 Instance Methods

=head2 type_is

Return true if the L<_type> attribute equals to the C<$type_name>
parameter.

=head2 is_local

Return true if the L<_location> attribute values is C<local>.

=cut
