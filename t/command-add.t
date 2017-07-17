#
# Test the add command
#
use Test::Most;
use Term::ExtendedColor qw(uncolor);
use Capture::Tiny 0.12 qw(capture_stdout);
use Path::Tiny;
use File::Copy::Recursive qw(dircopy);
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Add;

my $local_path   = path( qw(t test-repo) );
my $add_repo_dir = path( $local_path, 'add' );
my $dest_path    = path( qw(t test-dst add) );
my $path_orig    = path( qw(t test-repo add-orig) );

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

# Cleanup and init
path($add_repo_dir)->remove_tree( { safe => 0 } ); # force remove
dircopy($path_orig, $add_repo_dir);

# Config
ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

is $conf->repo_path, $local_path, 'test repo path from t/user.conf';

subtest 'Add a single file' => sub {

    is $conf->resource_file('add'),
        path( $add_repo_dir, 'resource.yml' ), 'nonexistent resource file';

    ok my $filename1 = path($dest_path, 'filename1'), 'the test file';
    ok $filename1->is_file, 'the file is a regular file';

    ok my $add = App::PlannedCopy::Command::Add->new(
        project => 'add',
        files   => $filename1->stringify,
        config  => $conf,
    ), 'command constructor';

    is $add->project, 'add', 'project name';

    like uncolor ( capture_stdout { $add->run } ),
        qr{add/filename\d},
        'run should work';
};

subtest 'Add 2 files using a wildcard' => sub {

    is $conf->resource_file('add'),
        path( $add_repo_dir, 'resource.yml' ), 'nonexistent resource file';

    ok my $files = "$dest_path/file.*", 'the test files';

    ok my $add = App::PlannedCopy::Command::Add->new(
        project => 'add',
        files   => $files,
        config  => $conf,
    ), 'command constructor';

    is $add->project, 'add', 'project name';

    like uncolor ( capture_stdout { $add->run } ),
        qr{add/filename\d},
        'run should work';
};

subtest 'Add a dir' => sub {

    is $conf->resource_file('add'),
        path( $add_repo_dir, 'resource.yml' ), 'nonexistent resource file';

    ok $dest_path->is_dir, 'source is a dir';

    ok my $add = App::PlannedCopy::Command::Add->new(
        project => 'add',
        files   => $dest_path->stringify,
        config  => $conf,
    ), 'command constructor';

    is $add->project, 'add', 'project name';

    like uncolor ( capture_stdout { $add->run } ),
        qr{add/filename\d},
        'run should work';
};


done_testing;
