package App::PlannedCopy::Role::Remote;

# ABSTRACT: Role for remote functions

use 5.0100;
use utf8;
use Moose::Role;
use Path::Tiny;
use Net::SFTP::Foreign;

has 'remote_host' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->host if $self->host;
        return $self->resource->resource_host;
    },
);

has 'sftp' => (
    is      => 'ro',
    isa     => 'Maybe[Net::SFTP::Foreign]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $host = $self->remote_host // 'localhost';
        return if $host eq 'localhost';
        my $user = $self->user;
        my $pass = $self->pass;
        my $sftp = Net::SFTP::Foreign->new(
            $host,
            backend  => 'Net_SSH2',
            username => $user,
            password => $pass,
        );
        say "[sftp] Connecting as ", $user ? "'$user'" : "'default'" if $self->verbose;
        $sftp->error
            and die "Unable to establish SFTP connection: " . $sftp->error . "\n";

        $sftp->setcwd('/') or die "Unable to change cwd: " . $sftp->error . "\n";
        say "[sftp] CWD is ", $sftp->cwd if $self->verbose;

        return $sftp;
    },
);

no Moose::Role;

1;
