#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Data::Printer;
use Net::SFTP::Foreign;

my $pass = shift || usage();

my $host = 'ds';
my $user = $ENV{USER};                       # not needed?

say "Connecting as $user";

my $sftp = Net::SFTP::Foreign->new(
    $host,
    backend  => 'Net_SSH2',
    username => $user,          # defaults to $USER
    password => $pass,
);
$sftp->error
    and die "Unable to stablish SFTP connection: " . $sftp->error;

my $path = 'homes/stefan/';
my $name = 'filename';
my $file = "$path/$name";

$sftp->setcwd($path) or die "unable to change cwd: " . $sftp->error;
say $sftp->cwd;

# my $ls = $sftp->ls('.')
#         or die "unable to retrieve directory: ".$sftp->error;
# print "$_->{filename}\n" for (@$ls);

$sftp->put($name, $name, late_set_perm => 1) or die "put failed: " . $sftp->error;

say "\nFile is $name";
my $fstat = $sftp->stat($name);
p $fstat;
printf "Permissions are %04o\n", $fstat->perm & 07777;

$name = 'nonexistentfile';
say "\nFile is $name";
if ( my $fstat = $sftp->stat($name) ) {
    p $fstat;
    printf "Permissions are %04o\n", $fstat->perm & 07777;
}
else {
    say "Error: ", $sftp->error;
}

$name = 'rootowner';
say "\nFile is $name";
if ( my $fstat = $sftp->stat($name) ) {
    p $fstat;
    printf "Permissions are %04o\n", $fstat->perm & 07777;
}
else {
    say "Error: ", $sftp->error;
}

$name = 'video/buzdugan-4.tar.gz';
say "\nFile is $name";
if ( my $fstat = $sftp->stat($name) ) {
    p $fstat;
    printf "Permissions are %04o\n", $fstat->perm & 07777;
}
else {
    say "Error: ", $sftp->error;
}

sub usage {
    say "$0 <pass>";
    exit;
}
