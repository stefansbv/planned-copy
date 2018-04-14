package App::PlannedCopy::Command::Search;

# ABSTRACT: Search for a file in the repository

use 5.010001;
use utf8;
use Carp;
use Path::Tiny;
use Path::Iterator::Rule;
use Term::ExtendedColor qw(fg);
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Printable
        App::PlannedCopy::Role::Utils
       );

use App::PlannedCopy::Resource;

command_long_description q[Search the repository.];

parameter 'dst_name' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'file',
    documentation => q[Destination file name.],
);

has 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
);

has 'command' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        'search';
    },
);

sub run {
    my ($self) = @_;

    my $name = $self->dst_name;
    print "Job: search for '$name'\n\n";

    my $non_projects = [];

    foreach my $item ( $self->projects ) {
        my $path = $item->{path};
        my $resu = $item->{resource};
        my $disa = $item->{disabled};
        if ($disa == 1 || $resu != 1) {
            push @{$non_projects}, $path;
            next;
        }
        $self->project($path);               # set project
        $self->search_in_projects( 'batch' );
    }

    foreach my $path ( @{$non_projects} ) {
        $self->search_non_projects( $path, 'batch' );
    }

    $self->print_summary( 'batch' );

    return;
}

sub search_in_projects {
    my ( $self, $batch ) = @_;

    my $file = $self->config->resource_file( $self->project );
    my $resu = App::PlannedCopy::Resource->new( resource_file => $file );
    my $iter = $resu->resource_iter;
    my $cnt  = $resu->count;

    my $name = $self->dst_name;

    while ( $iter->has_next ) {
        my $res = $iter->next;
        if ( $res->dst->_name eq $name ) {
            print '[', fg('blue2', $self->project), "]\n";
            $self->item_printer($res);
            $self->inc_count_found;
        }
        $self->inc_count_proc;
    }

    return;
}

sub search_non_projects {
    my ( $self, $path, $batch ) = @_;

    my $files = $self->gather_files($path);

    my $name = $self->dst_name;

    foreach my $file_name ( @{$files} ) {
        if ( $file_name eq $name ) {
            print '[', fg('orange2', $path), "]\n";
            print " $file_name\n";
            $self->inc_count_found;
        }
        $self->inc_count_proc;
    }

    return;
}

sub gather_files {
    my ( $self, $path, $wildcard ) = @_;

    croak "The path was not provided for 'gather_files'!\n"
        unless $path;
    my $project_path = path $self->config->repo_path, $path;

    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    $rule->skip(
        $rule->new->file->empty,
        $rule->new->file->name( qr/~$/, '*.bak'),
        $rule->new->file->name($self->config->resource_file_name),
    );
    $rule->name($wildcard) if $wildcard; # not used (yet?)
    $rule->min_depth(1);

    my $next = $rule->iter( $project_path,
        { relative => 0, sorted => 1, follow_symlinks => 0 } );
    my $dirs = [];
    while ( defined( my $item = $next->() ) ) {
        my $file = path $item;
        push @{$dirs}, $file->relative($project_path)->stringify if $file->is_file;
    }
    return $dirs;
}

sub print_summary {
    my ( $self, $batch ) = @_;
    my $cnt_proc = $self->count_proc // 0;
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - found    : ', $self->count_found;
    say '';

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The implementation of the C<search> command.

=head1 Interface

=head2 Attributes

=head3 project

An attribute to hold the name of the project - a directory name under
C<repo_path>.

=head3 command

An attribute to hold the name of the command - used in the Printable
role.  For other command is defined in the coresponding Validate role.

=head2 Instance Methods

=head3 run

The method to be called when the C<search> command is run.

Builds an iterator for the resource items and iterates over them.  If
the C<validate_element> method throws an exception, it is cached and
the item is skipped.  If there is no fatal exception thrown, then the
C<search> method is called on the item.

=head3 search_in_projects

Builds an iterator for the resource items and iterates over them.  If
the destination name of an item matches the searched name, prints it
and increments the counter.

=head3 search_non_projects

Iterates over the project files and prints the name of the files that
match the name of the searched file.

=head3 gather_files

Uses L<Path::Iterator::Rule> to create and return an array reference
containing the list of the files in a directory.

=head3 print_summary

Prints the summary of the command execution.

=head3 store_summary

=cut
