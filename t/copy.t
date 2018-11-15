#
# Test the Config module
#
use Test2::V0;
use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Config;
use App::PlannedCopy::Util::Copy;

my $dst = path(qw(/ tmp copyed.yml));
my $src = path(qw(t new-resource.yml));

subtest 'Test Copy utils' => sub {

    ok my $uc = App::PlannedCopy::Util::Copy->new, 'constructor';
    isa_ok $uc, ['App::PlannedCopy::Util::Copy'], 'sftp instance';

    ok $uc->copy_file($src, $dst), 'copy file';
    ok my $filestat = $uc->file_stat($dst), 'file stat';

    is $uc->get_perms($dst), '0644', 'the perms of the file'
};

done_testing;
