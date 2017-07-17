package App::PlannedCopy::Command::Add;

# ABSTRACT: Add file(s) to a project and update the resource file

use 5.010001;
use utf8;
use MooseX::App::Command;
use Path::Tiny;
use List::MoreUtils;
use namespace::autoclean;

extends qw(App::PlannedCopy);

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

has '_dst_path' => (
    is      => 'rw',
    isa     => 'Path::Tiny',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path( $self->files )->parent->absolute;
    },
);

sub run {
    my ( $self ) = @_;

    # $self->check_project_name;
    $self->check_dir_name;

    my $path_param = $self->files;

    # The parameter has wildcards?
    my ( $file_path, $file_name );
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
        my $file_list = $self->gather_files($file_path, $file_name);
        $self->copy_file_batch($file_list);
    }
    else {

        # Single file
        if ( path($path_param)->is_file ) {
            $self->copy_file_single($path_param);
        }

        # Dir
        if ( path($path_param)->is_dir ) {
            my $file_list = $self->gather_files($path_param);
            $self->copy_file_batch($file_list);
        }
    }

    # Set the destination path and create/update the resource file
    $self->destination_path( $self->_dst_path->stringify );
    $self->update_resource;

    $self->print_summary;

    return;
}

sub copy_file_single {
    my ( $self, $path ) = @_;
    my $project = $self->project;
    my $abs_path;
    if ( path($path)->is_absolute ) {
        $abs_path = path($path);
    }
    if ( path($path)->is_relative ) {
        $abs_path = path($path)->absolute;
    }
    my @chunks = split "/", $abs_path->parent->stringify;
    $chunks[0] = q{/} if $chunks[0] eq q{};  # add the root
    my @base = List::MoreUtils::before { $_ eq $project } @chunks;
    my @top  = List::MoreUtils::after  { $_ eq $project } @chunks;
    my $repo = path( $self->project_path, @top );
    unless ($repo->is_dir) {
        $self->make_path($repo);
    }
    $self->_dst_path( path( @base, $project ) ); # set the destination path!
    $self->copy_file_local( $abs_path, $repo );
    return;
}

sub copy_file_batch {
    my ( $self, $file_list ) = @_;
    foreach my $file ( @{$file_list} ) {
        $self->copy_file_single($file);
    }
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
        $rule->new->file->name( $self->config->resource_file_name ),
    );                            # XXX: Add option to include empty files?
    $rule->name($wildcard) if $wildcard;
    $rule->min_depth(1);

    my $next = $rule->iter( $path,
        { relative => 0, sorted => 1, follow_symlinks => 0 } );
    my $dirs = [];
    while ( defined( my $item = $next->() ) ) {
        my $file = path $item;
        push @{$dirs}, $file if $file->is_file;
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

=head1 Interface

=head2 Attributes

=head3 project

Required parameter attribute for the list command.  The name of the
project - a directory name under C<repo_path>.

=head2 Instance Methods

=head3 run

The method to be called when the C<add> command is run.

=head3 copy_file_batch

Execute 'copy_file_single' for a list of file.

=head3 copy_file_single

Copy a file back into the repository in the project path.  Creates the
sub-dirs under the project mimicking the source tree.

=head3 gather_files

Create and return a list of files to be added to the repo.  The C<*>
and C<?> wildcards can be used in the file names.

=head3 print_summary

Prints the summary of the command.

=cut
