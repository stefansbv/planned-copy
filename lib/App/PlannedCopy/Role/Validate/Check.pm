package App::PlannedCopy::Role::Validate::Check;

# ABSTRACT: Role for resource element validation - for the check command

use 5.0100;
use utf8;
use Moose::Role;
use Try::Tiny;

with qw(App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Validate::Common);

use App::PlannedCopy::Exceptions;

has 'command' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        'check';
    },
);

sub validate_element {
    my ( $self, $res ) = @_;
    $self->is_dst_file_defined($res);
    $self->is_src_file_readable($res);
    if ( $res->src->type_is('archive') ) {
        $self->archive_is_unpacked($res);
    }
    else {
        $self->is_dst_file_readable($res);
        if ( $res->has_action('install') ) {
            # do nothing
        }
        elsif ( $res->has_action('skip') ) {
            # do nothing
        }
        else {
            $self->is_src_and_dst_different($res);
            $self->is_owner_different($res);
            $self->is_mode_different($res);
        }
    }
    return;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis

    with qw( App::PlannedCopy::Role::Validate::Check );
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

A role for resource element validation - for the check command.

=head1 Interface

=head2 Instance Methods

=head3 validate_element

Overridden method that calls all the necessary validation methods for
the C<check> command.

=cut
