package App::PlannedCopy::Util::Copy;

# ABSTRACT: Copy utils

use 5.010001;
use utf8;
use English;
use Moose;
use Try::Tiny;
use Path::Tiny;
use namespace::autoclean;

use App::PlannedCopy::Exceptions;

sub file_stat {
    my ( $self, $path ) = @_;
    die "file_stat: path parameter missing\n" unless $path;
    return path($path)->absolute->stat;
}

sub file_perms {
    my ( $self, $res ) = @_;
    die "file_perms: resource source or destination parameter missing\n"
        unless $res;
    my $stat = $self->file_stat($res);
    return $stat->mode;
}

sub get_perms {
    my ( $self, $res ) = @_;
    my $mode = try { $self->file_perms($res) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for path:',
                pathname => $res->_name,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            Exception::IO::FileNotFound->throw(
                message  => 'No such file or directory',
                pathname => $res->_name,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    return sprintf "%04o", $mode & 07777;
}

sub copy_file {
    my ( $self, $src, $dst ) = @_;
    $src = path($src) unless $src->isa('Path::Tiny');
    $dst = path($dst) unless $dst->isa('Path::Tiny');
    try { $src->copy($dst) }
    catch {
        my $err    = $_;
        my $logmsg = '';
        if ( $err =~ m{Permission denied}i ) {
            $logmsg = 'Permission denied';
        }
        else {
            $logmsg = $err;
        }
        Exception::IO::SystemCmd->throw(
            message => 'The copy command failed.',
            logmsg  => $logmsg,
        );
    };
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
