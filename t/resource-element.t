# -*- mode-cperl -*-
#
# Test the Resource::Element object container
#
use Test::More tests => 4;

use App::ConfigManager::Resource::Element;

my $args = {
    destination => {
        name => 'lircd.conf',
        path => '/etc/lirc',
        perm => '0644',
    },
    source => {
        name => 'lircd.conf',
        path => 'lirc',
    },
};

ok my $elem = App::ConfigManager::Resource::Element->new($args),
    'constructor';
isa_ok $elem, 'App::ConfigManager::Resource::Element';
isa_ok $elem->src, 'App::ConfigManager::Resource::Element::Source';
isa_ok $elem->dst, 'App::ConfigManager::Resource::Element::Destination';

# end
