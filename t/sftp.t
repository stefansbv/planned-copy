#
# Test the Config module
#
use Test2::V0;
use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Config;
use App::PlannedCopy::Util::SFTP;

my $dst = path(qw(/ tmp copyed.yml));
my $src = 't/new-resource.yml';

subtest 'Test SFTP utils' => sub {

    ok my $aps = App::PlannedCopy::Util::SFTP->new(
        host => 'localhost',
    ), 'constructor';
    isa_ok $aps, ['App::PlannedCopy::Util::SFTP'], 'sftp instance';

    ok my $sftp = $aps->sftp, 'get sftp';
    isa_ok $sftp, ['Net::SFTP::Foreign'], 'sftp instance';

    ok $aps->copy_file($src, $dst), 'copy file';
    ok my $filestat = $aps->file_stat($dst), 'file stat';
    isa_ok $filestat, ['Net::SFTP::Foreign::Attributes'], 'sftp attr instance';
    is $aps->get_perms($dst), '0644', 'the perms of the file'
};

done_testing;
