package App::PlannedCopy::Command::Resource;

# ABSTRACT: Create/update a resource file

use 5.010001;
use utf8;
use Try::Tiny;
use Path::Tiny;
use Path::Iterator::Rule;
use List::Compare;
use MooseX::App::Command;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Resource::Utils
        App::PlannedCopy::Role::Printable);

command_long_description q[Create/update a resource file for the <project>.];

parameter 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Project name.],
);

has 'resource_file' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->config->resource_file( $self->project );
    },
);

has open_editor => (
    is       => 'ro',
    isa      => 'Bool',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->config->get(
            key => 'resource.open_editor',
            as  => 'bool',
        ) // 0;
    },
);

sub run {
    my ( $self ) = @_;

    my $project = $self->project;
    unless ( $self->is_project_path ) {
        die "\n[EE] No directory named '$project' found.\n     Check the spelling or use the 'list' command.\n\n";
    }

    my $proj = $self->project;
    say "Job: add/update the resource file for '$proj':\n";

    $self->update_resource;
    $self->print_summary;

    if ( $self->count_added > 0 && $self->open_editor ) {
        $self->shell( $self->editor . ' ' . $self->resource_file );
    }

    return;
}

sub print_summary {
    my $self = shift;
    say '';
    say 'Summary:';
    say ' - removed: ', $self->dryrun ? '0 (dry-run)' : $self->count_removed;
    say ' - kept   : ', $self->count_kept;
    say ' - added  : ', $self->dryrun ? '0 (dry-run)' : $self->count_added;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The implementation of the C<resu> command.  TODO: change the name.

=head1 Interface

=head2 Attributes

=head3 project

Required parameter attribute for the install command.  The name of the
project - a directory name under C<repo_path>.

=head3 resource_file

A read only attributes that holds the resource files absolute path.

=head2 Instance Methods

=head3 run

The method to be called when the C<resu> command is run.

Builds three lists, one for the deleted items, one for the kept items
and one for the added items.  Print this lists in order, and then
prints the summary.

=head3 print_summary

Prints the summary of the command execution.

=cut
