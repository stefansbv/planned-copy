package App::ConfigManager::Command::Install;

# ABSTRACT: Install the configuration files

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

command_long_description q[Install the configuration files of the selected <project>.];

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
        ' to install', ( $self->verbose ? ' (verbose)' : '' ), ':', "\n";

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
                $self->install_file($rec);
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

sub install_file {
    my ( $self, $res ) = @_;

    return if $self->dryrun;

    my $src_path = $res->src->_abs_path;
    my $dst_path = $res->dst->_abs_path;
    my $parent_dir = $res->dst->_parent_dir;
    unless ( $parent_dir->is_dir ) {
        unless ( $parent_dir->mkpath ) {
            Exception::IO::PathNotFound->throw(
                message  => 'Failed to create the destination path.',
                pathname => $parent_dir,
            );
        }
    }

    # Copy and set perm
    $self->copy_file($src_path, $dst_path);
    $self->set_perm($dst_path, $res->dst->_perm);

    return;
}

sub print_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc;
    say ' - installed: ', $self->dryrun ? '0 (dry-run)' : $self->count_inst;
    say ' - skipped  : ',
        $self->dryrun ? "$cnt_proc (dry-run)" : $self->count_skip;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;
