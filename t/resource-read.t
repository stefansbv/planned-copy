# -*- perl -*-
#
# Read the test data from t/resource.t
#
use Test::More tests => 16;
use Path::Tiny;
use File::HomeDir;

use App::ConfigManager::Resource::Read;
use App::ConfigManager::Resource::Element::Destination;

ok my $reader = App::ConfigManager::Resource::Read->new(
    resource_file => 't/resource.yml'
), 'read a test resource file';

# Record #1

my $res1 = $reader->contents->[0];
ok my $dst1 = App::ConfigManager::Resource::Element::Destination->new(
    $res1->{destination} ), 'constructor';

isa_ok $dst1, 'App::ConfigManager::Resource::Element::Destination';

is $dst1->_name, path('.config'), 'destination name';
is $dst1->_path, path('dst/bin'),  'destination path';
is $dst1->_perm, '0644', 'destination perm';

# Record #3

my $res3 = $reader->contents->[2];
ok my $dst3 = App::ConfigManager::Resource::Element::Destination->new(
    $res3->{destination} ), 'constructor';

isa_ok $dst3, 'App::ConfigManager::Resource::Element::Destination';

is $dst3->_name, path('config.pro'), 'destination name';
is $dst3->_path, '{ undef }',  'destination path';
is $dst3->_perm, '0644', 'destination perm';

# Record #4

my $res4 = $reader->contents->[3];
ok my $dst4 = App::ConfigManager::Resource::Element::Destination->new(
    $res4->{destination} ), 'constructor';

isa_ok $dst4, 'App::ConfigManager::Resource::Element::Destination';

is $dst4->_name, path('config3'), 'destination name';
is $dst4->_path, path( File::HomeDir->my_home ),  'destination path';
is $dst4->_perm, '0644', 'destination perm';

# end
