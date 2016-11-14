#
# Test the Utils role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use lib 't/lib';
use TestCmd;

my @attributes = ( qw(
    destination_path
    resource_old
    resource_new
    _compare
    _kept
    _removed
    _added
));
my @methods    = ( qw(
    _build_old_resource
    _build_new_resource
    _build_compare
    write_resource
    get_all_files
    update_resource
));

my $cmd = TestCmd->new;
map has_attribute_ok( $cmd, $_ ), @attributes;
map can_ok( $cmd, $_ ), @methods;

my $repo_path = path( qw(t test-repo) );
my $dest_path = path( qw(t test-dst) );

done_testing();
