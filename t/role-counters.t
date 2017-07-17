#
# Test the Counters role
#
use Test::Most;
use Test::Moose;
use lib 't/lib';
use TestCmd;

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
