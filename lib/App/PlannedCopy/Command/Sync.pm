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
            ' to check and synchronize',
            ( $self->verbose ? ' (verbose)' : '' ),
            ':',
            "\n";
    }
    else {
        say 'Job: ', $res->count, ' file', ( $res->count != 1 ? 's' : '' ),
            ' to check and synchronize',
            ( $self->verbose ? ' (verbose)' : '' ),
            ':',
            "\n";
    }

    $self->no_resource_message($self->project) if $res->count == 0;

    while ( $iter->has_next ) {
        my $res  = $iter->next;
        if ($name) {

            # Skip until found; not efficient but simple to implement ;)
            next unless $res->dst->_name eq $name;
        }
        my $cont = try {
            $self->validate_element($res);

            # Check the user if is not root, and is explicitly set
            unless ( $self->config->current_user eq 'root' ) {
                $self->check_res_user($res) if !$res->dst->_user_is_default;
            }
            1;                               # required
        }
        catch {
            my $exc = $_;
            my $e = $self->handle_exception($exc, $res);
            $self->item_printer($res);
            $self->inc_count_skip;
            return undef;       # required
        };
        if ($cont) {
            try {
                $self->synchronize($res);
                $self->item_printer($res);
            }
            catch {
                my $exc = $_;
                $self->handle_exception($exc, $res);
                $self->item_printer($res);
                $self->inc_count_skip;
            };
        }
        $self->inc_count_proc;
    }

    $self->print_summary;

    return;
}

sub synchronize {
    my ( $self, $res ) = @_;

    return if $self->dryrun;

    my $src_path  = $res->src->_abs_path;
    my $dst_path  = $res->dst->_abs_path;
    my $copy_flag = $res->has_action('install');

    # Copy and set perm
    if ($copy_flag) {
        $self->copy_file( $dst_path, $src_path );
        $self->inc_count_inst;
    }
    else {
        $self->inc_count_skip;
    }
    $self->set_perm($src_path, 0644);
    $self->change_owner( $src_path, $self->repo_owner )
        if $self->config->current_user eq 'root';

    return;
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

Required parameter attribute for the install command.  The name of the
project - a directory name under C<repo_path>.

=head3 dst_name

Optional parameter attribute for the install command.  If provided
only this file is installed.

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
