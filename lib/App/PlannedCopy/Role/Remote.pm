package App::PlannedCopy::Role::Remote;

# ABSTRACT: Role for remote functions

use 5.0100;
use utf8;
use Moose::Role;
use Path::Tiny;
use Net::SFTP::Foreign;

has 'sftp' => (
    is      => 'ro',
    isa     => 'Maybe[Net::SFTP::Foreign]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $host = $self->remote_host;
        return if $host eq 'localhost';
        my $user = $self->user;
        my $pass = $self->pass;
        my $sftp = Net::SFTP::Foreign->new(
            $host,
            backend  => 'Net_SSH2',
            username => $user,
            password => $pass,
        );
        say "Connecting as ", $user ? "'$user'" : "'default'";
        $sftp->error
            and die "Unable to establish SFTP connection: " . $sftp->error;

        $sftp->setcwd('/') or die "Unable to change cwd: " . $sftp->error;
        say "CWD is ", $sftp->cwd;

        return $sftp;
    },
);

no Moose::Role;

1;
