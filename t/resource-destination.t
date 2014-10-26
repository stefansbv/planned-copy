# -*- perl -*-
#
# Test the Resource::Element::Destination object independently
#
use Test::More tests => 7;
use Path::Tiny;

use App::ConfigManager::Resource::Element::Destination;

my $args = {
    destination => {
        name => 'lircd.conf',
        path => '/etc/lirc',
        perm => '0644',
    },
};

ok my $dst = App::ConfigManager::Resource::Element::Destination->new(
    $args->{destination} ), 'constructor';

isa_ok $dst, 'App::ConfigManager::Resource::Element::Destination';

is $dst->_name, path('lircd.conf'), 'destination name';
is $dst->_path, path('/etc/lirc'), 'destination path';
is $dst->_perm, '0644', 'destination perm';
is $dst->_abs_path, path('/etc/lirc/lircd.conf'), 'destination absolute path';
is $dst->_parent_dir, path('/etc/lirc'), 'destination absolute path parent';

# end
