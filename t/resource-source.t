# -*- perl -*-
#
# Test the Resource::Element::Source object independently
#
use Test::Most;
use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Resource::Element::Source;

# Test with the test config files

local $ENV{APP_CM_SYS_CONFIG} = path( qw(t system.conf) );
local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

subtest 'minimum valid config' => sub {
    my $args = {
        source => {
            name => 'lircd.conf',
            path => 'lirc',
        }
    };

    ok my $src
        = App::PlannedCopy::Resource::Element::Source->new(
        $args->{source} ),
        'constructor';

    isa_ok $src, 'App::PlannedCopy::Resource::Element::Source';

    is $src->_name, path('lircd.conf'), 'source name';
    is $src->_path, path('lirc'),       'source path';
    is $src->_abs_path, path('t/repo/lirc/lircd.conf'),
        'source absolute path';
    is $src->_parent_dir, path('t/repo/lirc'), 'source absolute path parent';
};

subtest 'maximum valid config' => sub {
    my $args = {
        source => {
            name => 'lircd.conf',
            path => 'lirc',
            type => 'archive',
        }
    };

    ok my $src
        = App::PlannedCopy::Resource::Element::Source->new(
        $args->{source} ),
        'constructor';

    isa_ok $src, 'App::PlannedCopy::Resource::Element::Source';

    is $src->_name, path('lircd.conf'), 'source name';
    is $src->_path, path('lirc'),       'source path';
    is $src->_type, 'archive',          'source type';
    is $src->_abs_path, path('t/repo/lirc/lircd.conf'),
        'source absolute path';
    is $src->_parent_dir, path('t/repo/lirc'), 'source absolute path parent';
};

done_testing;

# end
