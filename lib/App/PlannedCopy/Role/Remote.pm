package App::PlannedCopy::Role::Remote;

# ABSTRACT: Role for remote functions

use 5.0100;
use utf8;
use Moose::Role;
use Path::Tiny;
use Capture::Tiny ':all';
use Net::SFTP::Foreign;

has '_host' => (
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
        my $host = $self->_host;
        return if $host eq 'localhost';
        my $para = [];
        push @{$para}, '-v' if $self->debug;
        my $sftp;

        # silence sftp
        my ( undef, undef, undef ) = capture {
            $sftp = Net::SFTP::Foreign->new(
                $host,
                more => $para,
            );
        };
        say "[sftp] Connecting as ", $ENV{USER} if $self->verbose;
        $sftp->error
            and die "Unable to establish SFTP connection!\n     "
            . $sftp->error . "\n";

        $sftp->setcwd('/') or die "Unable to change cwd: " . $sftp->error . "\n";
        say "[sftp] CWD is ", $sftp->cwd if $self->verbose;

        return $sftp;
    },
);

no Moose::Role;

1;

__END__

=encoding utf8

=head1 SYNOPSIS

=head1 DESCRIPTION

A role that uses C<Net::SFTP::Foreign> to establish  a remote connection to a box.

=head2 ATTRIBUTES

=head3 _host

The host name is the host option on the command line if provided or
the host attribute from the resource file.

=head3 sftp

An attribute that holds an instance of C<Net::SFTP::Foreign>.

=head2 INSTANCE METHODS

=cut
