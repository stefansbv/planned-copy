package App::PlannedCopy::Command::Diff;

# ABSTRACT: Run a diff utility on the repo files and the installed versions

use 5.010001;
use utf8;
use Try::Tiny;
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

has 'prompting' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 1 },
);

has 'diff_cmd' => (
    is      => 'ro',
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

    say 'Job: ', $res->count, ' file', ( $res->count != 1 ? 's' : '' ),
        ' to diff', ( $self->verbose ? ' (verbose)' : '' ), ':', "\n";

    $self->no_resource_message( $self->project ) if $res->count == 0;

    while ( $iter->has_next ) {
        $self->set_error_level('info');
        my $rec = $iter->next;
        my $cont = try { $self->validate_element($rec) }
        catch {
            my $e = $self->handle_exception($_);
            $self->item_printer($rec);
            $self->exception_printer($e) if $e;
            $self->inc_count_skip;
            return undef;    # required
        };
        if ($cont) {
            try {
                $self->diff_files($rec);
                $self->item_printer($rec);
            }
            catch {
                my $e = $self->handle_exception($_);
                $self->exception_printer($e) if $e;
                $self->inc_count_skip;
            };
        }
        $self->inc_count_proc;
    }

    $self->print_summary;

    return;
}

sub diff_files {
    my ( $self, $rec ) = @_;

    # Skip archives
    if ( $rec->src->type_is('archive') ) {
        $self->set_error_level('none');
        $self->inc_count_skip;
        return;
    }

    my $src_path = $rec->src->_abs_path;
    my $dst_path = $rec->dst->_abs_path;

    if ( $self->is_selfsame( $src_path, $dst_path ) ) {
        $self->set_error_level('done');
    }
    else {
        if ( $self->prompting ) {
            $self->set_error_level('warn');
            my $cmd = $self->diff_cmd;
            say "# diff $src_path $dst_path";
            my $answer = prompt( "Run $cmd? (Y/n/q)", "y" );
            if ( $answer =~ m{[yY]} ) {
                $self->kompare( $src_path, $dst_path );
                $self->inc_count_resu;
            }
            elsif ( $answer =~ m{[qQ]} ) {
                $self->prompting(0);
            }
        }
    }
    $self->inc_count_inst;
    return;
}

sub print_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - checked  : ', $self->count_inst;
    say ' - skipped  : ', $self->count_skip;
    say ' - diff-ed  : ', $self->count_resu;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis

    use App::PlannedCopy;

    App::PlannedCopy->new_with_command->run;

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
