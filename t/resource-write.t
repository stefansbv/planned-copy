#
# Write the test data
#
use Test::Most tests => 4;

use App::ConfigManager::Resource::Write;

my $file = 't/new-resource.yml';

unlink $file;                                # cleanup

ok my $rw = App::ConfigManager::Resource::Write->new(
    resource_file => $file
), 'write a test resource file';

is $rw->resource_file, $file, 'has resource file name';
is $rw->resource_file->is_file, undef, 'resource file does not exists';

my $data = {
    'resources' => [
        {   'source' => {
                'name' => 'config1',
                'path' => 'test/src/'
            },
            'destination' => {
                'name' => '.config',
                'path' => 'dst/bin',
                'perm' => '0644'
            }
        },
        {   'source' => {
                'name' => 'config2.sh',
                'path' => 'test/src/'
            },
            'destination' => {
                'name' => 'config2',
                'path' => 'test/dst/bin',
                'perm' => '0755'
            }
        },
    ]
};

lives_ok { $rw->create_yaml($data) } 'write resource file';

done_testing;
