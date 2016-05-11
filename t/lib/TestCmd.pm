package TestCmd;

use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw( App::PlannedCopy::Role::Printable
         App::PlannedCopy::Role::Utils );

__PACKAGE__->meta->make_immutable;

1;
