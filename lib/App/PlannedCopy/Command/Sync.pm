package App::PlannedCopy::Command::Sync;

# ABSTRACT: Synchronize the configuration files

use 5.010001;
use utf8;
use Path::Tiny;
use Try::Tiny;
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Printable
        App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Validate::Sync
       );

use App::PlannedCopy::Resource;

command_long_description q[Synchronize the configuration files.  Switch destination with source and copy the files back to the repository.];

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

sub run {
    my ( $self ) = @_;

    my $file = $self->config->resource_file( $self->project );
    my $res  = App::PlannedCopy::Resource->new( resource_file => $file);
    my $iter = $res->resource_iter;

    my $name = $self->dst_name;
    if ($name) {
        say 'Job: 1 file',
            ' to check and synchronize', ( $self->verbose ? ' (verbose)' : '' ),
            ':',
            "\n";
    }
    else {
        say 'Job: ', $res->count, ' file', ( $res->count != 1 ? 's' : '' ),
            ' to check and synchronize', ( $self->verbose ? ' (verbose)' : '' ),
            ':',
            "\n";
    }

    $self->no_resource_message($self->project) if $res->count == 0;

    while ( $iter->has_next ) {
        my $res = $iter->next;
        if ($name) {

            # Skip until found; not efficient but simple to implement ;)
            next unless $res->dst->_name eq $name;
        }

        $self->prevalidate_element($res);

        my @i = $res->all_issues;

        if ( $res->has_action('skip') ) {
            $self->item_printer($res);
            $self->inc_count_skip;
        }
        else {

            # synchronize
            if ( $res->has_action('sync') ) {
                try {
                    $self->synchronize($res);
                    $self->item_printer($res)
                }
                catch {
                    $self->exceptions($_, $res);
                    $self->inc_count_skip;
                };
            }
        }
        $self->inc_count_proc;
    }
    $self->print_summary;

    return;
}

sub synchronize {
    my ( $self, $res ) = @_;
    return if $self->dryrun;
    my $src_path = $res->src->_abs_path;
    $self->copy_file( $res->dst->_abs_path, $src_path );
    $self->set_perm( $src_path, oct(644) );
    $self->inc_count_inst;
    $res->remove_issue_by_action($res, 'sync');
    $self->change_owner( $src_path, $self->repo_owner )
        if $self->config->current_user eq 'root';
    $res->issues_category('done');
    return 1;                                # require for the test
}

sub print_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;
    say "\nSummary:";
    say " - processed   : ", $cnt_proc, ' records';
    say ' - skipped     : ', $self->dryrun ? "$cnt_proc (dry-run)" : $self->count_skip;
    say " - synchronized: ", $self->dryrun ? '0 (dry-run)' : $self->count_inst;
    say "";
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The implementation of the C<sync> command.

=head1 Interface

=head2 Attributes

=head3 project

Required parameter attribute for the synchronize command.  The name of the
project - a directory name under C<repo_path>.

=head3 dst_name

Optional parameter attribute for the synchronize command.  If provided
only this file is synchronized.

=head2 Instance Methods

=head3 run

The method to be called when the C<sync> command is run.

Builds an iterator for the resource items and iterates over them.  If
the C<validate_element> method throws an exception, it is cached and
the item is skipped.  If there is no fatal exception thrown, then the
C<synchronize> method is called on the item.

=head3 synchronize

The inverse of the install command.  Copies a destination item (file)
to the source dir with the name from the resource file, changes the
owner to the C<repo_owner> and sets the perms to C<0640>.

=head3 print_summary

Prints the summary of the command execution.

=cut
