package App::PlannedCopy::Role::Validate::Common;

# ABSTRACT: Role for resource element validation - common for all commands

use 5.0100;
use utf8;
use Fcntl qw(S_IRUSR S_IWUSR);
use Moose::Role;

use App::PlannedCopy::Exceptions;

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
    unless ( $res->src->_abs_path->stat->cando(S_IWUSR, 1) ) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for src path:',
            pathname => $res->dst->_path,
        );
    }
    return 1;
}

sub src_dir_readable {
    my ( $self, $res ) = @_;
    unless ( $res->src->_parent_dir->stat->cando(S_IRUSR, 1) ) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for src path:',
            pathname => $res->src->_parent_dir,
        );
    }
    return 1;
}

sub src_file_readable {
    my ( $self, $res ) = @_;
    unless ( $res->src->_abs_path->stat->cando(S_IRUSR, 1) ) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for src file:',
            pathname => $res->src->_abs_path,
        );
    }
    return 1;
}

sub src_file_writable {
    my ( $self, $res ) = @_;
    unless ( $res->src->_abs_path->stat->cando(S_IWUSR, 1) ) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for src path:',
            pathname => $res->dst->_path,
        );
    }
    return 1;
}

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

sub dst_file_readable {
    my ( $self, $res ) = @_;
    unless ( $res->dst->_abs_path->stat->cando( S_IRUSR, 1 ) ) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for dst path:',
            pathname => $res->dst->_abs_path,
        );
    }
    return 1;
}

sub dst_dir_readable {
    my ( $self, $res ) = @_;
    unless ( $res->dst->_parent_dir->stat->cando(S_IRUSR, 1) ) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Permision denied for dst path:',
            pathname => $res->dst->_parent_dir,
        );
    }
    return 1;
}

sub dst_path_writeable {
    my ( $self, $res ) = @_;
    unless ( $res->dst->_path->stat->cando( S_IWUSR, 1 ) ) {
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

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Name

=head1 Synopsis

=head1 Description

=head1 Interface

=cut
