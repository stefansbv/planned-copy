#
# Test the Counters role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use lib 't/lib';
use TestCmd;

BEGIN {
    delete $ENV{PLCP_REPO_PATH};
    delete $ENV{PLCP_SYS_CONFIG};
    delete $ENV{PLCP_USR_CONFIG};
}

if ( $^O eq 'MSWin32' ) {
    $ENV{COLUMNS} = 80;
    $ENV{LINES}   = 25;
}

local $ENV{PLCP_REPO_PATH}  = path(qw(t test-repo));
local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
local $ENV{PLCP_USR_CONFIG} = path(qw(t user.conf));

my @attributes = (
    qw(
       count_proc
       count_resu
       count_inst
       count_diff
       count_skip
       count_proj
       count_dirs
       count_same
      )
);
my @methods    = ();

my $project = 'resource';
my $cmd = TestCmd->new( project => $project );
map has_attribute_ok( $cmd, $_ ), @attributes;
map can_ok( $cmd, $_ ), @methods;

done_testing();
