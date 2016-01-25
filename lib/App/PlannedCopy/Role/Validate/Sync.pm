package App::PlannedCopy::Role::Validate::Sync;

# ABSTRACT: Role for resource element validation - for the sync command

use 5.0100;
use utf8;
use Moose::Role;

with qw(App::PlannedCopy::Role::Validate::Common);

use App::PlannedCopy::Exceptions;

sub validate_element {
    my ($self, $res) = @_;

    $self->src_isfile($res);
    $self->src_file_writeable($res);
    $self->dst_file_defined($res);
    $self->dst_path_exists($res);
    $self->dst_file_readable($res);
    $self->dst_isfile($res);

    return 1;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis

    with qw( App::PlannedCopy::Role::Validate::Sync );
    my $cont = try { $self->validate_element($res) }
    catch {
        $self->handle_exception($_);
        ...
        return undef;    # required
    };
    if ($cont) {
        ...
    }

=head1 Description

A role for resource element validation - for the sync command.

=head1 Interface

=head2 Instance Methods

=head3 validate_element

Overridden method that calls all the necessary validation methods for
the C<sync> command.

=cut
