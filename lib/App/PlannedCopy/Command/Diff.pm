package App::PlannedCopy::Command::Diff;

# ABSTRACT: Run a diff utility on the repo files and the installed versions

use 5.010001;
use utf8;
use Try::Tiny;
use MIME::Types;
use IO::Prompt::Tiny qw(prompt);
use Capture::Tiny ':all';
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Printable
        App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Validate::Diff
       );

use App::PlannedCopy::Resource;

command_long_description q[Run a diff utility.  Defaults to kompare];

parameter 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Project name.],
);

parameter 'dst_name' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'file',
    documentation => q[Optional destination file name.],
);

has 'prompting' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 1 },
);

has 'diff_cmd' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        my $cmd  = $self->config->diff_tool;
        my ( $stdout, $stderr, $exit ) = capture { system( $cmd, '--version' ) };
        die "Can't execute '$cmd'!\n Error: $stderr"     if $stderr;
        die "Can't execute '$cmd'! Error: exitval=$exit" if $exit != 0;
        return $cmd;
    },
);

sub run {
    my ($self) = @_;

    my $file = $self->config->resource_file( $self->project );
    my $res  = App::PlannedCopy::Resource->new( resource_file => $file );
    my $iter = $res->resource_iter;
    my $name = $self->dst_name;
    if ($name) {
        say 'Job: 1 file',
            ' to diff', ( $self->verbose ? ' (verbose)' : '' ),
            ':',
            "\n";
    }
    else {
        say 'Job: ', $res->count, ' file', ( $res->count != 1 ? 's' : '' ),
            ' to diff', ( $self->verbose ? ' (verbose)' : '' ), ':', "\n";
    }

    $self->no_resource_message( $self->project ) if $res->count == 0;

    while ( $iter->has_next ) {
        my $res = $iter->next;
        if ($name) {

            # Skip until found; not efficient but simple to implement ;)
            next unless $res->dst->_name eq $name;
        }

        $self->prevalidate_element($res);

        if ( $res->has_no_issues ) {
            $self->item_printer($res) if $self->verbose;
            $self->inc_count_same;
        }
        else {
            if ( $res->has_action('skip') ) {
                $self->item_printer($res);
                $self->inc_count_skip;
            }
            else {

                # print
                $self->item_printer($res);

                # install
                if (   $res->has_action('install')
                    || $res->has_action('unpack') ) {
                    $self->inc_count_skip;
                }

                # update
                if ( $res->has_action('update') ) {
                    $self->diff_files($res);
                    $self->inc_count_diff;
                }
            }
        }
        $self->inc_count_proc;
    }

    $self->print_summary;

    return;
}

sub diff_files {
    my ( $self, $res ) = @_;

    my $src_path = $res->src->_abs_path;
    my $dst_path = $res->dst->_abs_path;

    my $binary = 0;
    my $mt = MIME::Types->new;
    if ( my $type = $mt->mimeTypeOf($src_path) ) {
        # say "Type of $src_path is $type";
        $binary = 1 if $type->isBinary;
    }

    if ( $res->src->type_is('archive') ) {
        return;
    }

    if ( $self->prompting ) {
        my $cmd    = $self->diff_cmd;
        my $answer = prompt( "       Run $cmd? (Y/n/q)", "y" );
        if ( $answer =~ m{[yY]} ) {
            $self->compare( $src_path, $dst_path, $binary );
        }
        elsif ( $answer =~ m{[qQ]} ) {
            $self->prompting(0);
        }
        $self->inc_count_resu;
    }
    return;
}

sub print_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - skipped  : ', $self->count_skip;
    say ' - same     : ', $self->count_same;
    say ' - different: ', $self->count_resu;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The diff command.

=head1 Interface

=head2 Attributes

=head3 project

Required parameter attribute for the diff command.  The name of the
project - a directory name under C<repo_path>.

=head3 prompting

An attribute used to stop prompting when the user responds with C<q>
to a prompt.

=head3 diff_cmd

An attribute that holds the diff tool command.  It runs the command
with the C<--version> option, to check if it's installed and dies if the
command throws an error.

The diff tool used, must have a C<--version> option or at least not
treat this option as an error.

=head2 Instance Methods

=head3 run

The method to be called when the C<diff> command is run.

Builds an iterator for the resource items and iterates over them.  If
the C<validate_element> method throws an exception, it is cached and
the item is skipped.  If there is no fatal exception thrown, then the
C<diff_file> method is called on the item.

=head3 diff_files

For items that are not archive files, compares the source and the
destination file and if are different than prompts the user for
running the diff tool.

=head3 extract_archive

Unpacks an archive file in the destination dir.  Can handle any type
of archive that the C<Archive::Any::Lite> module recognizes.

=head3 print_summary

Prints the summary of the command.

=cut
