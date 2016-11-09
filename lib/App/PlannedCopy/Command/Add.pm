package App::PlannedCopy::Command::Add;

# ABSTRACT: Add file(s) to a project and update the resource file

use 5.010001;
use utf8;
use MooseX::App::Command;
use Try::Tiny;
use Path::Tiny;
use App::PlannedCopy::Ls;
use namespace::autoclean;

extends qw(App::PlannedCopy);

use constant RESOURCE_FILE => 'resource.yml';

with qw(App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Resource::Utils
        App::PlannedCopy::Role::Printable);

parameter 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Project name.],
);

parameter 'files' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[The file(s) to be added to the project.],
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

sub run {
    my ( $self ) = @_;

    # $self->check_project_name;
    $self->check_dir_name;

    my $path_param = $self->files;

    my $file_list = [];
    my ( $file_path, $file_name );

    # The parameter has wildcards?
    if ( $path_param =~ m{[?*]} ) {
        say "param has wildcards!";

        if ( $path_param =~ m{^(.*)/([^/]*)$} ) {
            $file_path = $1;
            $file_name = $2;
        }
        die "Widcards are allowed only for the file name!\n"
            if $file_path =~ m{[?*]};

        say 'file_path: ', $file_path;
        say 'file_name: ', $file_name;

        # Go and build the file list
        $file_list = $self->gather_files($file_path, $file_name);
    }
    else {
        say "param has NO wildcards!";

        say "is file: ", path($path_param)->is_file ? 'yes' : 'no';
        say "is dir:  ", path($path_param)->is_dir  ? 'yes' : 'no';

        if ( path($path_param)->is_file ) {
            if ( $path_param =~ m{^(.*)/([^/]*)$} ) {
                $file_path = $1;
                $file_name = $2;
            }
            else {
                $file_path = '.';
                $file_name = $path_param;
            }

            die "The '$file_path' path does not exists!\n"
                unless path($file_path)->is_dir;

            say 'file_path: ', $file_path;
            say 'file_name: ', $file_name;

            # Add the file
            push @{$file_list}, $path_param;
        }
        if ( path($path_param)->is_dir ) {

            # Go and gather all files
            $file_path = $path_param;
            $file_list = $self->gather_files($path_param);
        }
    }

    # Sync (copy) the files into the repo
    # XXX Should copy files only if does not exist?!
    foreach my $file ( @{$file_list} ) {
        my $dst_path = path $self->project_path, path($file)->parent;
        unless ( $dst_path->is_dir ) {
            $self->make_path($dst_path);
        }
        my $src = path $file_path, $file;
        my $dst = path $self->project_path, $file;
        $self->copy_file( $src, $dst );
    }

    # Set the destination path and create/update the resource file
    $self->destination_path($file_path);
    $self->update_resource;

    $self->print_summary;

    return;
}

sub gather_files {
    my ( $self, $path, $wildcard ) = @_;

    die "The path was not provided for 'gather_files'!\n"
        unless $path;

    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    $rule->skip(
        $rule->new->file->empty,
        $rule->new->file->name( qr/~$/, '*.bak'),
        $rule->new->file->name(RESOURCE_FILE),
    );
    $rule->name($wildcard) if $wildcard;
    $rule->min_depth(1);

    my $next = $rule->iter( $path,
        { relative => 0, sorted => 1, follow_symlinks => 0 } );
    my $dirs = [];
    while ( defined( my $item = $next->() ) ) {
        my $file = path $item;
        push @{$dirs}, $file->relative($path)->stringify if $file->is_file;
    }
    return $dirs;
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

Add file(s) to a project and update the resource file.

plcp add <project> ./path/to/a/file  - add the 'file' file

plcp add <project> ./path/           - add a directory recursively

plcp add <project> ./path/*.conf     - add files using wildcards

plcp add <project> file1 file2 file3 - add a list of files (not yet!)

=head2 Constants

=head2 RESOURCE_FILE

Returns the name of the resource file.

=head1 Interface

=head2 Attributes

=head3 project

Required parameter attribute for the list command.  The name of the
project - a directory name under C<repo_path>.

=head2 Instance Methods

=head3 run

The method to be called when the C<add> command is run.

=head3 gather_files

Create and return a list of files to be added to the repo.  The C<*>
and C<?> wildcards can be used in the file names.

=head3 print_summary

Prints the summary of the command.

=cut
