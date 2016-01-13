package App::PlannedCopy::Role::Validate::Check;

# ABSTRACT: Role for resource element validation - for the check command

use 5.0100;
use utf8;
use Moose::Role;

with qw(App::PlannedCopy::Role::Validate::Common);

use App::PlannedCopy::Exceptions;

sub validate_element {
    my ($self, $res) = @_;

    $self->src_isfile($res);
    $self->dst_file_defined($res);
    $self->dst_path_exists($res);
    $self->dst_isfile($res);
    $self->dst_file_readable($res);

    return 1;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Description

=head1 Interface

=cut
