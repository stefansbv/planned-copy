package App::PlannedCopy::Issue;

# ABSTRACT: An resource item issue

use 5.010001;
use Moose;
use Types::Standard qw(Enum);
use MooseX::Enumeration;
use namespace::autoclean;

has 'category' => (
    traits  => ['Enumeration'],
    is      => 'rw',
    enum    => [qw/error info warn/],
);

has 'action' => (
    traits   => ['Enumeration'],
    is       => 'rw',
    enum     => [qw/install update chmod chown skip unpack none/],
    required => 1,
    default  => sub {'none'},
);

has 'message' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'details' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

    $res->add_issue(
        my $issue = App::PlannedCopy::Issue->new(
           message  => 'Not installed, path not found',
           details  => $parent_dir,
           category => 'info',
       ),
    );

=head1 Description

A class for resource element issues.

=head1 Interface

=head2 Attributes

=head3 category

The item category.  Can be C<error>, C<info> or C<warn>.

=head3 message

A message string.

=head3 details

A message details string.

=cut
