package App::PlannedCopy::Types;

# ABSTRACT: Config Manager types

use 5.010001;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'Octal', as 'Str', where { $_ =~ m/^0\d{3}$/ },
    message { "The string ($_) is not octal!" };

__PACKAGE__->meta->make_immutable;

1;
