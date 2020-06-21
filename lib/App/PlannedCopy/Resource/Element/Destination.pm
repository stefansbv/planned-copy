package App::PlannedCopy::Resource::Element::Destination;

# ABSTRACT: The destination resource element object

use utf8;
use Moose;
use App::PlannedCopy::Types;
use namespace::autoclean;

with qw{App::PlannedCopy::Role::Resource::Element};

has '_perm' => (
    is       => 'ro',
    isa      => 'Octal',
    required => 1,
    default  => sub {'0644'},
    init_arg => 'perm',
);

has '_verb' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    init_arg => 'verb',
);

has '_abs_path' => (
    is       => 'ro',
    isa      => 'Path::Tiny',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->_full_path->absolute;
    },
);

has '_abs_path_bak' => (
    is       => 'ro',
    isa      => 'Path::Tiny',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->_full_path_bak->absolute;
    },
);

has '_parent_dir' => (
    is       => 'ro',
    isa      => 'Path::Tiny',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return $self->_abs_path->parent;
    },
);

has '_user_isnot_default' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 0,
    init_arg => undef,
    default => sub {
        return 0;
    },
);

has '_user' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    init_arg => 'user',
    default  => sub {
        return 0;
    },
    trigger => sub {
        my ( $self, $new, $old ) = @_;
        $self->_user_isnot_default(1);          # reset attribute
    },
);

sub verb_is {
    my ($self, $verb_action) = @_;
    return 1 if $self->_verb eq $verb_action;
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

=head1 Synopsis

=head1 Description

A destination resource element object.

=head1 Attributes

=head2 _perm

Returns an Octal custom type representing the required permissions of
the file.

=head2 _verb

Returns an action verb string.  The only currently known verb is
C<unpack> and is used to extract the files from archives.

=head2 _abs_path

The absolute path of the C<_full_path> as returned by the C<absolute>
instance method of the L<Path::Tiny> object.

=head2 _parent_dir

The parent dir of the C<_abs_path> as returned by the C<parent>
instance method of the L<Path::Tiny> object.

=head2 _user_isnot_default

Attribute flag for user is default.

=head2 _user

Return true if the user attribute was not explicitly set for a
resource.

=head2 _location

The C<_location> attribute value is set to the host name attribute of the
resource file on build time.

=head1 Instance Methods

=head2 verb_is

Return true if the L<_verb> attribute equals to the C<$verb_action>
parameter.

=head2 is_local

Return true if the L<_location> attribute values is C<local>.

=cut
