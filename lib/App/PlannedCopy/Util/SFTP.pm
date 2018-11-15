package App::PlannedCopy::Util::SFTP;

# ABSTRACT: SFTP utils

use 5.010001;
use utf8;
use English;
use Moose;
use Try::Tiny;
use Net::SFTP::Foreign;         # Net::SFTP::Foreign::Attributes
use namespace::autoclean;

use App::PlannedCopy::Exceptions;

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'user' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 0,
);

has 'pass' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 0,
);

has 'verbose' => (
    is       => 'ro',
    isa      => 'Bpool',
    required => 0,
);

has 'sftp' => (
    is      => 'ro',
    isa     => 'Maybe[Net::SFTP::Foreign]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $host = $self->host;
        my $user = $self->user;
        my $pass = $self->pass;
        my $sftp;
        try {
            $sftp = Net::SFTP::Foreign->new(
                $host,
                backend  => 'Net_SSH2',
                username => $user,
                password => $pass,
            );
            #$sftp->setcwd('/') or die "Unable to change cwd: " . $sftp->error . "\n";
        }
        catch {
            Exception::IO::SFTP->throw(
                message => 'The SFTP command failed.',
                logmsg  => $sftp->error,
            );
        };
        say "[sftp] Connecting as ", $user ? "'$user'" : "'default'" if $self->verbose;
        say "[sftp] CWD is ", $sftp->cwd if $self->verbose;
        return $sftp;
    },
);

sub copy_file {
    my ( $self, $src, $dst ) = @_;
    $self->sftp->setcwd( $dst->parent )
        or die "Unable to change cwd " . $self->sftp->error . "\n";
    $self->sftp->put( $src, $dst, late_set_perm => 1 )
        or die "put failed: " . $self->sftp->error . "\n";
    return 1;
}

sub file_stat {
    my ( $self, $path ) = @_;
    die "file_stat: path parameter missing\n" unless $path;
    my $attr = $self->sftp->stat($path);
    die "Remote stat command failed: " . $self->sftp->status unless $attr;
    return $attr;
}

sub file_perms {
    my ( $self, $res ) = @_;
    die "file_perms: resource source or destination parameter missing\n"
        unless $res;
    return $self->file_stat($res)->perm;
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

__PACKAGE__->meta->make_immutable;

1;
