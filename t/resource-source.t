#
# Test the Resource::Element::Source object independently
#
use Test::Most;
use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Resource::Element::Source;

# Test with the test config files

my $repo_path = path( qw(t test-repo check) );

local $ENV{PLCP_SYS_CONFIG} = path( qw(t system.conf) );
local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

subtest 'minimum valid config' => sub {
    my $args = {
        source => {
            name => 'filename1',
            path => 'check',
        }
    };

    ok my $src
        = App::PlannedCopy::Resource::Element::Source->new(
        $args->{source} ), 'constructor';

    isa_ok $src, 'App::PlannedCopy::Resource::Element::Source';

    is $src->_name, path('filename1'), 'source name';
    is $src->_path, path('check'),     'source path';
    is $src->_abs_path, path( $repo_path, qw(filename1) ),
        'source absolute path';
    is $src->_parent_dir, $repo_path, 'source absolute path parent';
	is $src->_location, 'local', 'source location';
	is $src->is_local, 1, 'is local';
};

subtest 'maximum valid config' => sub {
    my $args = {
        source => {
            name => 'filename2',
            path => 'check',
            type => 'archive',
        }
    };

    ok my $src
        = App::PlannedCopy::Resource::Element::Source->new(
        $args->{source} ), 'constructor';

    isa_ok $src, 'App::PlannedCopy::Resource::Element::Source';

    is $src->_name, path('filename2'), 'source name';
    is $src->_path, path('check'),     'source path';
    is $src->_type, 'archive',         'source type';
    is $src->_abs_path, path( $repo_path, qw(filename2) ),
        'source absolute path';
    is $src->_parent_dir, $repo_path, 'source absolute path parent';
	is $src->_location, 'local', 'source location';
	is $src->is_local, 1, 'is local';
};

done_testing;
