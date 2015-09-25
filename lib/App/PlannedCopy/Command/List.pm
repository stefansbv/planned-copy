package App::PlannedCopy::Command::List;

# ABSTRACT: Print a list of the projects in the repository

use 5.010001;
use utf8;
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Printable);

sub execute {
    my ( $self ) = @_;

    say "Job: list projects:\n";
    $self->project_list_printer( @{ $self->get_projects } );

    $self->print_summary;

    return;
}

sub print_summary {
    my $self = shift;
    say '';
    say 'Summary:';
    say ' - directories: ', $self->count_proc;
    say ' - projects   : ', $self->count_inst;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

=head2 get_projects

Returns an array reference of the names of the subdirectories of
L<repo_path> that contains a resource file (L<resource.yml>).

=cut
