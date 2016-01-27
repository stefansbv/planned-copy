package App::PlannedCopy::Command::List;

# ABSTRACT: Print a list of the projects in the repository

use 5.010001;
use utf8;
use MooseX::App::Command;
use App::PlannedCopy::Ls;
use Try::Tiny;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Printable);

parameter 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => q[Project name.],
);

sub run {
    my ( $self ) = @_;

    if ( my $project = $self->project ) {
        say "Job: list files in '$project':\n";
        my @items;
        try {
            @items = @{ $self->get_project_files($project) };
        }
        catch {
            if ( my $e = Exception::Base->catch($_) ) {
                if ( $e->isa('Exception::IO::PathNotFound') ) {
                    $self->print_exeception_message($e->message, $e->pathname);
                }
                else {
                    die "Unexpected exception: $_";
                }
            }
        };
        return unless scalar @items;
        my $list = App::PlannedCopy::Ls->new( items => \@items );
        $list->column_printer;
        return;
    }
    else {
        say "Job: list projects:\n";
        $self->project_list_printer( $self->projects );
    }

    $self->print_summary;

    return;
}

sub print_summary {
    my $self = shift;
    say '';
    say 'Summary:';
    say ' - directories: ', $self->count_dirs;
    say ' - projects   : ', $self->count_proj;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The list command.

=head1 Interface

=head2 Attributes

=head3 project

Required parameter attribute for the list command.  The name of the
project - a directory name under C<repo_path>.

=head2 Instance Methods

=head3 run

The method to be called when the C<list> command is run.

Gets a list of file for the C<project> and prints it using the
C<App::PlannedCopy::Ls> module.

=head3 print_summary

Prints the summary of the command.

=cut
