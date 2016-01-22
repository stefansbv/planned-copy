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

sub execute {
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
        $self->set_error_level('info');
        my $res  = $iter->next;
        if ($name) {

            # Skip until the desired element is found; not efficient
            # but simple to implement ;)
            next unless $res->dst->_name eq $name;
        }
        my $cont = try {
            $self->validate_element($res);

            # Check the user if is not root                         TODO!
            unless ( $self->config->current_user eq 'root' ) {
                $self->check_user;
            }
        }
        catch {
            my $e = $self->handle_exception($_);
            $self->item_printer($res);
            $self->exception_printer($e) if $e;
            $self->inc_count_skip;
            return undef;       # required
        };
        if ($cont) {
            try {
                $self->synchronize($res);
                $self->item_printer($res);
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

sub synchronize {
    my ( $self, $res ) = @_;

    return if $self->dryrun;

    my $src_path = $res->dst->_abs_path;
    my $dst_path = $res->src->_abs_path;

    # Compare files
    if ( $self->is_selfsame( $src_path, $dst_path ) ) {
        $self->set_error_level('none');
        $self->inc_count_skip;
        return;
    }

    $self->set_error_level('done');

    # Copy and set perm
    $self->copy_file($src_path, $dst_path);
    $self->set_perm($dst_path, 0644);
    $self->change_owner( $dst_path, $self->repo_owner )
        if $self->config->current_user eq 'root';
    $self->inc_count_inst;

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
