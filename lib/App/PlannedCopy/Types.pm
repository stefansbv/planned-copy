package App::PlannedCopy::Types;

# ABSTRACT: The PlannedCopy application custom attribute types

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'Octal', as 'Str', where { $_ =~ m/^0\d{3}$/ },
    message { "The string ($_) is not in octal format!" };

__PACKAGE__->meta->make_immutable;

1;

=head1 Synopsis

    App::PlannedCopy::Types qw(Octal);

=head1 Description

Custom types for the PlannedCopy app:

=over

=item Octal

A string with 0 (zero) as the first char, followed by 3 digits.

=back
