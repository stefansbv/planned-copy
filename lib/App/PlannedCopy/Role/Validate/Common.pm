package App::PlannedCopy::Role::Validate::Common;

# ABSTRACT: Role for resource element validation - common for all commands

use 5.0100;
use utf8;
use Fcntl qw(S_IRUSR S_IWUSR);
use Path::Tiny;
use Archive::Any::Lite;
use Try::Tiny;
use Moose::Role;

use App::PlannedCopy::Exceptions;

sub src_file_readable {
    my ( $self, $res ) = @_;
    my $readable = try { $res->src->_abs_path->stat->cando(S_IRUSR, 1) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Read denied for the source file:',
                pathname => $res->src->short_path,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            Exception::IO::FileNotFound->throw(
                message  => 'The source file was not found:',
                pathname => $res->src->short_path,
            );
        }
        else {
            die "Unhandled stat ERROR: $err";
        }
    };
    unless ($readable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Read denied for the source file:',
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
                message  => 'Write denied for the source file:',
                pathname => $res->src->short_path,
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
    unless ($writeable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Write denied for the source path:',
            pathname => $res->src->short_path,
        );
    }
    return 1;
}

sub dst_file_defined {
    my ( $self, $res ) = @_;
    if ( $res->dst->_path =~ m/^{\s?undef\s?}/ ) {
        Exception::IO::PathNotDefined->throw(
            message  => 'The destination path is not set',
            pathname => '',
        );
    }
    return 1;
}

sub dst_file_readable {
    my ( $self, $res ) = @_;

    # Handle archives
    if ( $res->src->type_is('archive') && $res->dst->verb_is('unpack') ) {
        return 1 if $self->archive_is_unpacked($res);
        return 0;
    }

    my $readable = try { $res->dst->_abs_path->stat->cando( S_IRUSR, 1 ) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Read permission denied:',
                pathname => $res->dst->short_path,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            if ( $self->command eq 'install' ) {
                $res->add_issue(
                    App::PlannedCopy::Issue->new(
                        message  => 'Not installed:',
                        details  => $res->src->short_path->stringify,
                        category => 'info',
                        action   => 'install',
                    ),
                );
            }
            else {
                Exception::IO::FileNotFound->throw(
                    message  => 'Not installed:',
                    pathname => $res->dst->short_path,
                );
            }
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    unless ($readable) {
        Exception::IO::PermissionDenied->throw(
            message  => 'Read permission denied:',
            pathname => $res->dst->short_path,
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

sub dst_file_mode {
    my ( $self, $res ) = @_;
    my $perms = $self->get_perms( $res->dst->_abs_path );
    if ( $perms ne $res->dst->_perm ) {
        if ( $self->command eq 'install' ) {
            $res->add_issue(
                App::PlannedCopy::Issue->new(
                    message  => 'Wrong permissions:',
                    details  => $perms,
                    category => 'info',
                    action   => 'chmod',
                ),
            );
        }
        else {
            Exception::IO::WrongPerms->throw(
                message => 'Wrong permissions:',
                perm    => $perms,
            );
        }
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
                message  => 'Permision denied for path:',
                pathname => $file,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            Exception::IO::FileNotFound->throw(
                message  => 'No such file or directory',
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

sub archive_is_unpacked {
    my ($self, $res) = @_;
    my $dst_path = $res->dst->_abs_path;
    my $src_path = $res->src->_abs_path;

    my $archive;
    {
        local $SIG{__WARN__} = sub {
            my $err = shift;
            die $err;
        };
        try {
            $archive = Archive::Any::Lite->new($src_path)
        }
        catch {
            my $err = $_;
            if ( $err =~ m/No handler available for/i ) {
                Exception::IO::FileNotArchive->throw(
                    message  => $err,
                    pathname => $src_path,
                );
            }
        };
    }
    return unless $archive;

    if ( $archive->is_impolite ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => 'The archive is impolite',
                category => 'info',
                action   => 'install',
            ),
        );
        return 1;       # don't know if is unpacked, but assume yes...
    }

    if ( $archive->is_naughty ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => 'The archive is naughty',
                category => 'info',
                action   => 'install',
            ),
        );
        return 1;       # don't know if is unpacked, but assume yes...
    }

    # Check if the top dir(s) exists in the destination path
    my $top_dirs_found = 0;
    my $top_dir_exists = 0;
    foreach my $file ( $archive->files ) {
        my $dir_name = $file =~ m{[^/]+/$} ? $file : '';
        if ($dir_name) {
            $top_dirs_found++;
            my $path = path($dst_path->parent, $dir_name);
            $top_dir_exists++ if $path->is_dir;
        }
    }
    if ( $top_dirs_found == $top_dir_exists ) {
        return 1;
    }
    elsif ( $top_dir_exists > 1 ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => 'Some of the destination dirs exists',
                category => 'info',
                action   => 'install',
            ),
        );
        return 1;
    }
    else {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => 'Not installed:',
                details  => $res->src->short_path->stringify,
                category => 'info',
                action   => 'install',
            ),
        );
        return 0;
    }
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis

    with qw(App::PlannedCopy::Role::Validate::Common);

    sub validate_element {
        my ($self, $res) = @_;

        $self->dst_file_defined($res);
        $self->dst_path_exists($res);
        $self->dst_isfile($res);
        $self->dst_file_readable($res);

        return 1;
    }

=head1 Description

A base role used by the roles implemented for every command.  This
roles must owerride C<validate_element> method.

=head1 Interface

=head2 Instance Methods

=head3 src_file_readable

Checks the source L<_abs_path> of a resource element using
C<File::stat> and thows an L<Exception::IO::PermissionDenied>
exception on a C<Permission denied> error or if the directory is not
readable.  Also throws an C<Exception::IO::FileNotFound> on a C<No
such file or directory> error or dies on other unhandled exceptions.

Returns true if the file is readable.

=head3 src_file_writeable

Checks source L<_abs_path> of a resource element using C<File::stat>
and thows an L<Exception::IO::PermissionDenied> exception on a
C<Permission denied> error or if the file is not writeable.

It is used only by the C<sync> command.

=head3 dst_file_defined

Checks the destination path of a resource element and returns true or
throws an L<Exception::IO::PathNotDefined> exception if is not defined
in the resource file, for example:

     ...
     -
        destination:
          path: ~
          ...


=head3 dst_file_readable

Checks the source parent dir of a resource element to see if it's
readable, using the L<File::stat> function, and throws an
L<Exception::IO::PermissionDenied> exception if is not readable or the
error message contains the "Permission denied" string or dies with an
"Unknown stat ERROR: $err" error message.

=head3 dst_path_exists

Returns true if the destination path is a directory or throws an
C<Exception::IO::PathNotFound> if it is not.

Used by the C<check>, C<diff> and C<sync> commands.

=head3 dst_file_mode

Returns true if the actual C<perms> of the destination file with match
the C<perms> defined in the resource file.  Otherwise throws an
C<Exception::IO::WrongPerms> exception.

=head3 get_perms

Return the C<perms> as an octal string of the file givven as parameter
or throws a C<Exception::IO::PermissionDenied> exception if the file
can't be read.

=cut
