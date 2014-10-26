# -*- perl -*-
#
# Test the Resource::Element::Source object independently
#
use Test::More tests => 6;
use Path::Tiny;
use File::HomeDir;

use App::ConfigManager::Resource::Element::Source;

my $args = {
    source => {
        name => 'lircd.conf',
        path => 'lirc',
    }
};

# Test with the test config files

local $ENV{APP_CM_SYS_CONFIG} = path( qw(t system.conf) );
local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok my $src
    = App::ConfigManager::Resource::Element::Source->new( $args->{source} ),
    'constructor';

isa_ok $src, 'App::ConfigManager::Resource::Element::Source';

is $src->_name, path('lircd.conf'), 'destination name';
is $src->_path, path('lirc'),       'destination path';
is $src->_abs_path, path('t/repo/lirc/lircd.conf'), 'source absolute path';
is $src->_parent_dir, path('t/repo/lirc'), 'source absolute path parent';

# end
