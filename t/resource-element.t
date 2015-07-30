# -*- mode-cperl -*-
#
# Test the Resource::Element object container
#
use Test::More tests => 4;

use App::PlannedCopy::Resource::Element;

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

ok my $elem = App::PlannedCopy::Resource::Element->new($args),
    'constructor';
isa_ok $elem, 'App::PlannedCopy::Resource::Element';
isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

# end
