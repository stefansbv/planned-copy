package App::PlannedCopy::Role::Resource::Element;

# ABSTRACT: Role for the resource element

use 5.0100;
use utf8;
use Moose::Role;
use MooseX::Types::Path::Tiny qw(Path);
use Path::Tiny;
use File::HomeDir;
use namespace::autoclean;
use Carp;

has '_name' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => 'name',
    required => 1,
);

has '_path' => (
    is       => 'ro',
    isa      => Path,
    init_arg => 'path',
    coerce   => 1,
);

has '_full_path' => (
    is       => 'ro',
    isa      => 'Path::Tiny',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return path( $self->_path, $self->_name );
    },
);

sub short_path {
    my $self = shift;
    my $path = $self->_full_path;
    my $home = File::HomeDir->my_home;
    $path = $path->relative($home) if $path->stringify =~ m{^$home};
    return $path;
}

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my $args = $self->$orig(@_);
    foreach my $arg ( keys %{$args} ) {
        $args->{$arg} = '{ undef }' unless defined( $args->{$arg} );
        if ( $args->{$arg} eq 'path' ) {

            # If destination directory is relative to HOME expand ~/
            # to $HOME/ like the bash shell does.
            my $path = $args->{$arg};
            if ( $path =~ s{^~/}{} ) {
                $args->{$arg} = path( File::HomeDir->my_home, $path );
            }
        }
    }
    return $args;
};

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis


=head1 Description

This role provides the base methods and attributes to construct a
resource element object.

=head1 Interface

=head2 Attributes

=head3 _name

The name of the file.  If the destination name differs from the source
name, the file is renamed, using the destination, name when is
installed.

=head3 _path

The path to the file excluding the file L<_name>.  If it is a source
path, than is a relative path of the L<_name> file in the repository.
If it is a destination path, than is the absolute path to the place
where the file is supposed to be installed.

=head3 _full_path

A Path::Tiny object built from the L<_path> and L<_name> attributes.

=head2 Instance Methods

=head3 short_path

Return a shorter path by removing the L</home/user/> string from the
start if is a path relative to the home dir of the current user,
othewise return the original L<_full_path>.

=head3 name_len

The length of the name string, required in the Printer role.

=head3 path_len

The length of the L<short_path> string, required in the Printer role.

=cut
