package TestCmd;

use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw( App::PlannedCopy::Role::Printable
         App::PlannedCopy::Role::Utils
         App::PlannedCopy::Role::Remote );

has [qw{remote_host user pass}] => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;
