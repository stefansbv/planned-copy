#
# Read the test data from t/resource.yml
#
use Test::Most;

use App::PlannedCopy::Resource::Read;

my $expected = [
    {   destination => {
            name => ".config",
            path => "dst/bin",
            perm => "0644",
        },
        source => {
            name => "config1",
            path => "test/src/",
        },
    },
    {   destination => {
            name => "config2",
            path => "test/dst/bin",
            perm => "0755",
        },
        source => {
            name => "config2.sh",
            path => "test/src/",
        },
    },
    {   destination => {
            name => "config.pro",
            path => undef,
            perm => "0644",
        },
        source => {
            name => "config.pro",
            path => "test/src/",
        },
    },
    {   destination => {
            name => "config3",
            path => "~/",
            perm => "0644",
        },
        source => {
            name => "config3",
            path => "test/src/",
        },
    },
    {   destination => {
            name => "file_not_exists",
            path => "test/dst",
            perm => "0644",
        },
        source => {
            name => "file_not_exists",
            path => "test/src/",
        },
    },
];

subtest 'Read resource' => sub {
    ok my $reader = App::PlannedCopy::Resource::Read->new(
        resource_file => 't/resource.yml' ), 'read a test resource file';

    is $reader->get_contents('scope'), 'user', 'get the scope';
    ok my $resources = $reader->get_contents('resources'),
        'get the resources';
    is ref $resources, 'ARRAY', 'resources array';

    cmp_deeply $resources, $expected, 'resources';
};

subtest 'Read resource - no scope' => sub {
    ok my $reader = App::PlannedCopy::Resource::Read->new(
        resource_file => 't/resource-min.yml' ), 'read another test resource file';

    is $reader->get_contents('scope'), undef, 'get the scope';
    ok my $resources = $reader->get_contents('resources'),
        'get the resources';
    is ref $resources, 'ARRAY', 'resources array';

    cmp_deeply $resources, $expected, 'resources';
};

done_testing;
