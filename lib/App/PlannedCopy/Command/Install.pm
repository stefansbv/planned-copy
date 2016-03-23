package App::PlannedCopy::Command::Install;

# ABSTRACT: Install the project items (files)

use 5.010001;
use utf8;
use Path::Tiny;
use Try::Tiny;
use Archive::Any::Lite;
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Printable
        App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Validate::Install
       );

use App::PlannedCopy::Resource;

command_long_description q[Install the configuration files of the selected <project>.];

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
            ' to check and install', ( $self->verbose ? ' (verbose)' : '' ),
            ':',
            "\n";
    }
    else {
        say 'Job: ', $res->count, ' file', ( $res->count != 1 ? 's' : '' ),
            ' to check and install', ( $self->verbose ? ' (verbose)' : '' ),
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
            $self->handle_exception($exc, $res);
            $self->item_printer($res);
            $self->inc_count_skip;
            return undef;       # required
        };
        if ($cont) {
            try {
                $self->install_file($res);
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

sub install_file {
    my ( $self, $res ) = @_;

    return if $self->dryrun;

    my $src_path  = $res->src->_abs_path;
    my $dst_path  = $res->dst->_abs_path;
    my $copy_flag = $res->has_action('install');
    my $mode_flag = $res->has_action('chmod');

    my $parent_dir = $res->dst->_parent_dir;
    if ( $copy_flag && !$parent_dir->is_dir ) {
        unless ( $parent_dir->mkpath ) {
            Exception::IO::PathNotFound->throw(
                message  => 'Failed to create the destination path.',
                pathname => $parent_dir,
            );
        }
    }

    # Copy and set perms
    if ($copy_flag) {
        $self->copy_file( $src_path, $dst_path );
        $self->inc_count_inst;
    }
    else {
        $self->inc_count_skip;
    }
    $self->set_perm( $dst_path, $res->dst->_perm ) if $mode_flag || $copy_flag;
    $self->change_owner( $dst_path, $res->dst->_user )
        if $self->config->current_user eq 'root'
        && !$res->dst->_user_is_default;

    # Unpack archives
    if ( $res->src->type_is('archive') && $res->dst->verb_is('unpack') ) {
        $self->extract_archive($res) unless $self->archive_is_unpacked($res);
    }

    return 1;                                # require for the test
}

sub extract_archive {
    my ( $self, $res ) = @_;
    my $archive_path = $res->dst->_abs_path;
    my $archive      = Archive::Any::Lite->new($archive_path);
    my $into_dir     = $archive_path->parent->stringify;
    my $archive_file = $archive_path->basename;
    my $extracted = try { $archive->extract($into_dir); }
        catch {
            Exception::IO::SystemCmd->throw(
            message => "Unpacking '$archive_file' failed",
            logmsg  => $_,
        );
        return undef;       # required
    };
    if ($extracted) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => 'Unpacked',
                details  => $archive_file,
                category => 'info',
            ),
        );
    }
    return;
}

sub print_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - skipped  : ', $self->dryrun ? "$cnt_proc (dry-run)" : $self->count_skip;
    say ' - installed: ', $self->dryrun ? '0 (dry-run)' : $self->count_inst;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The implementation of the C<install> command.

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

The method to be called when the C<install> command is run.

Builds an iterator for the resource items and iterates over them.  If
the C<validate_element> method throws an exception, it is cached and
the item is skipped.  If there is no fatal exception thrown, then the
C<install_file> method is called on the item.

=head3 install_file

Copies an item (file), changes the owner and the perms.  Unpacks
archive files.

=head3 extract_archive

Unpacks an archive file in the destination dir.  Can handle any type
of archive that the C<Archive::Any::Lite> module recognizes.

=head3 print_summary

Prints the summary of the command execution.

=cut
