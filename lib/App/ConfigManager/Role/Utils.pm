package App::ConfigManager::Role::Utils;

# ABSTRACT: Role for utility functions

use 5.0100;
use utf8;
use Moose::Role;
use Path::Tiny;
use Try::Tiny;

use App::ConfigManager::Exceptions;

sub is_selfsame {
    my ( $self, $src, $dst ) = @_;
    if ( $dst =~ m{undef}i ) {
        Exception::IO::PathNotDefined->throw(
            message  => 'The destination path is not defined.',
            pathname => $dst,
        );
    }
    if ( !$dst->is_file ) {
        Exception::IO::FileNotFound->throw(
            message  => 'The destination path does not exist.',
            pathname => $dst,
        );
    }
    my $digest_src;
    try {
        $digest_src = $src->digest('MD5');
    }
    catch {
        my $err = $_;
        if ( $err =~ m{permission}i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for source path:',
                pathname => $src,
            );            
        }
        else {
           die "Unknown error: $err";
        }
    };
    my $digest_dst;
    try {
        $digest_dst = $dst->digest('MD5');
    }
    catch {
        my $err = $_;
        if ( $err =~ m{permission}i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for destination path:',
                pathname => $src,
            );            
        }
        else {
           die "Unknown error: $err";
        }
    };
    return ( $digest_src eq $digest_dst ) ? 1 : 0;
}

sub copy_file {
    my ($self, $src, $dst) = @_;
    try   { $src->copy($dst) }
    catch {
        Exception::IO::SystemCmd->throw(
            usermsg => 'The copy command failed.',
            logmsg  => $_,
        );
    };
    return;
}

sub set_perm {
    my ($self, $file, $perm) = @_;
    die "The 'set_perm' method works only with files.\n" unless $file->is_file;
    try   { $file->chmod($perm) }
    catch {
        Exception::IO::SystemCmd->throw(
            usermsg => 'The perm command failed.',
            logmsg  => $_,
        );
    };
    return;
}

sub validate_element {
    my ($self, $res) = @_;

    # Check the source file
    my $src_path = $res->src->_abs_path;
    unless ( $src_path->is_file ) {
        Exception::IO::FileNotFound->throw(
            message  => 'The source file was not found.',
            pathname => $res->src->short_path,
        );
    }

    # Check the destination file.
    if ( $res->dst->_path =~ m/^{\s?undef\s?}/ ) {
        Exception::IO::PathNotFound->throw(
            message  => 'The destination path is not defined.',
            pathname => $res->dst->_path,
        );
    }

    return 1;
}

sub no_resource_message {
    my ($self, $proj) = @_;
    say "---";
    say "There is no resource file for the '$proj' project.\nRun the 'resu' command to create it.";
    say "---";
    return
}

no Moose::Role;

1;
