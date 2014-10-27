package App::ConfigManager::Command::Sync;

# ABSTRACT: Synchronize the configuration files

use 5.010001;
use utf8;
use Path::Tiny;
use Try::Tiny;
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::ConfigManager);

with qw(App::ConfigManager::Role::Printable
        App::ConfigManager::Role::Utils);

use App::ConfigManager::Resource;

command_long_description q[Synchronize the configuration files.  Switch destination with source and copy the files back to the repository.];

parameter 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Project name.],
);

sub execute {
    my ( $self ) = @_;

    my $file = $self->config->resource_file( $self->project );
    my $res  = App::ConfigManager::Resource->new( resource_file => $file);
    my $iter = $res->resource_iter;

    say 'Job: ', $res->count, ' file', ( $res->count != 1 ? 's' : '' ),
        ' to check and synchronize', ( $self->verbose ? ' (verbose)' : '' ),
        ':', "\n";

    $self->no_resource_message($self->project) if $res->count == 0;

    while ( $iter->has_next ) {
        $self->set_error_level('info');
        my $rec  = $iter->next;
        my $cont = try { $self->validate_element($rec) }
        catch {
            if ( my $e = Exception::Base->catch($_) ) {
                $self->set_error_level('error');
                if ( $e->isa('Exception::IO') ) {
                    $self->item_printer($rec);
                    say "  [EE] ", $e->message, ' ', $e->pathname
                        if $self->verbose;
                    $self->inc_count_skip;
                }
            }
            return undef;       # required
        };

        if ($cont) {
            try {
                $self->synchronize($rec);
                $self->item_printer($rec);
                $self->inc_count_inst;
            }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    $self->set_error_level('error');
                    if ( $e->isa('Exception::IO') ) {
                        $self->item_printer($rec);
                        say "  [EE] ", $e->message, ' ', $e->pathname
                            if $self->verbose;
                        $self->inc_count_skip;
                    }
                }
            };
        }
        $self->inc_count_proc;
    }

    $self->print_summary;

    return;
}

sub synchronize {
    my ( $self, $res ) = @_;

    my $src_path = $res->dst->_abs_path;
    my $dst_path = $res->src->_abs_path;

    # Compare files
    if ( $self->is_selfsame( $src_path, $dst_path ) ) {
        $self->set_error_level('skip');
        return;
    }

    $self->set_error_level('warn');

    return if $self->dryrun;

    # Copy and set perm
    $self->copy_file($src_path, $dst_path);
    $self->set_perm($dst_path, 0644);

    return;
}

sub print_summary {
    my $self = shift;

    my $cnt_proc = $self->count_proc // 0;
    say "\nSummary:";
    say " - processed   : ", $cnt_proc;
    say " - synchronized: ", $self->dryrun ? '0 (dry-run)' : $self->count_inst;
    say " - skipped     : ", $self->dryrun ? "$cnt_proc (dry-run)" : $cnt_proc;
    say "";

    return;
}

__PACKAGE__->meta->make_immutable;

1;
