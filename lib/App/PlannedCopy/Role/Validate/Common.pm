package App::PlannedCopy::Role::Validate::Common;

# ABSTRACT: Role for resource element validation - common for all commands

use 5.0100;
use utf8;
use Fcntl qw(S_IRUSR S_IWUSR);
use Try::Tiny;
use Moose::Role;

use App::PlannedCopy::Exceptions;

#-- Src

sub src_parentdir_readable {
    my ( $self, $res ) = @_;
    my $readable = try { $res->src->_parent_dir->stat->cando(S_IRUSR, 1) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Read denied for src dir:',
                pathname => $res->dst->_path,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    unless ($readable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Read denied for src dir:',
            pathname => $res->src->_parent_dir,
        );
    }
    return 1;
}

sub src_file_readable {
    my ( $self, $res ) = @_;
    my $readable = try { $res->src->_abs_path->stat->cando(S_IRUSR, 1) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Read denied for src file:',
                pathname => $res->dst->_path,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            Exception::IO::FileNotFound->throw(
                message  => 'The source file was not found.',
                pathname => $res->src->short_path,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    unless ($readable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Read denied for src file:',
            pathname => $res->src->_abs_path,
        );
    }
    return 1;
}

sub src_isfile {
    my ( $self, $res ) = @_;
    unless ( $res->src->_abs_path->is_file ) {
        Exception::IO::FileNotFound->throw(
            message  => 'The source file was not found.',
            pathname => $res->src->short_path,
        );
    }
    return 1;
}

sub src_file_writeable {
    my ( $self, $res ) = @_;
    my $writeable = try { $res->src->_abs_path->stat->cando(S_IWUSR, 1) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Write denied for src file:',
                pathname => $res->dst->_path,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    unless ($writeable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Write denied for src path:',
            pathname => $res->dst->_path,
        );
    }
    return 1;
}

#-- Dst

sub dst_file_defined {
    my ( $self, $res ) = @_;
    if ( $res->dst->_path =~ m/^{\s?undef\s?}/ ) {
        Exception::IO::PathNotDefined->throw(
            message  => 'The destination path is not defined.',
            pathname => '',
        );
    }
    return 1;
}

sub dst_parentdir_readable {
    my ( $self, $res ) = @_;
    my $readable = try { $res->dst->_parent_dir->stat->cando(S_IRUSR, 1) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for dst path:',
                pathname => $res->dst->_path,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    unless ($readable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for dst path:',
            pathname => $res->dst->_parent_dir,
        );
    }
    return 1;
}

sub dst_file_readable {
    my ( $self, $res ) = @_;
    my $readable = try { $res->dst->_abs_path->stat->cando( S_IRUSR, 1 ) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for dst path:',
                pathname => $res->dst->_path,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            Exception::IO::FileNotFound->throw(
                message  => 'Not installed:',
                pathname => $res->src->short_path,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    unless ($readable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for dst path:',
            pathname => $res->dst->_path,
        );
    }
    return 1;
}

sub dst_path_writeable {
    my ( $self, $res ) = @_;
    my $writeable = try { $res->dst->_path->stat->cando( S_IWUSR, 1 ) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for dst path:',
                pathname => $res->dst->_path,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    unless ($writeable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for dst path:',
            pathname => $res->dst->_path,
        );
    }
    return 1;
}

sub dst_path_exists {
    my ( $self, $res ) = @_;
    unless ( $res->dst->_parent_dir->is_dir ) {
        Exception::IO::PathNotFound->throw(
            message  => 'Not installed, path not found',
            pathname => $res->dst->_parent_dir,
        );
    }
    return 1;
}

sub dst_isfile {
    my ( $self, $res ) = @_;
    unless ( $res->dst->_abs_path->is_file ) {
        Exception::IO::FileNotFound->throw(
            message  => 'Not installed:',
            pathname => $res->dst->_abs_path,
        );
    }
    return 1;
}

sub dst_file_mode {
    my ( $self, $res ) = @_;
    my $perms = $self->get_perms( $res->dst->_abs_path );
    unless ( $perms eq $res->dst->_perm ) {
        Exception::IO::WrongPerms->throw(
            message => 'Wrong permissions:',
            perm    => $perms,
        );
    }
    return 1;
}

sub get_perms {
    my ( $self, $file ) = @_;
    my $mode = try { $file->stat->mode }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for dst path:',
                pathname => $file,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    my $perms = sprintf "%04o", $mode & 07777;
    return $perms;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis

=head1 Description

=head1 Interface

=head2 dst_file_defined

=head2 dst_file_readable

Checks the source parent dir of a resource element to see if it's
readable, using the L<File::stat> function, and throws an
L<Exception::IO::PermissionDenied> exception if is not readable or the
error message contains the "Permission denied" string or dies with an
"Unknown stat ERROR: $err" error message.

=head2 dst_isfile

Checks the destination L<_abs_path> of a resource element and return
true or throws an L<Exception::IO::PermissionDenied> exception if the
is_file method of the L<Path::Tiny> instance object returns true or
respectively false.

=head2 dst_parentdir_readable

Checks the destination parent dir of a resource element to see if it's
readable, using the L<File::stat> function, and throws an
L<Exception::IO::PermissionDenied> exception if is not readable or the
error message contains the "Permission denied" string or dies with an
"Unknown stat ERROR: $err" error message.

=head2 dst_path_exists

=head2 dst_path_writeable

=head2 src_file_readable

=head2 src_file_writeable

=head2 src_isfile

Checks the source L<_abs_path> of a resource element and return true
or throws an L<Exception::IO::PermissionDenied> exception if the
is_file method of the L<Path::Tiny> instance object returns true or
respectively false.

=head2 src_parentdir_readable

=cut

TODO: POD

