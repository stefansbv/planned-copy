#
# Test the Utils role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use File::Copy::Recursive qw(dircopy);
use lib 't/lib';
use TestCmd;

my @attributes = ( qw() );
my @methods    = (
    qw(
        check_project_name
        check_res_user
        check_user
        compare
        copy_file
        exception_to_issue
        exceptions
        file_stat
        get_owner
        get_perms
        get_project_files
        handle_exception
        is_project
        is_project_path
        is_selfsame
        no_resource_message
        prevalidate_element
        remote_host
        quote_string
        set_owner
        set_perm
        sftp
      )
);

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

my $project   = 'check';
my $repo_path = path( qw(t test-repo install) );
my $dest_path = path(qw(t test-dst install));
my $dest_path_orig = path(qw(t test-dst install-orig));

# Cleanup
path($dest_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($dest_path_orig, $dest_path);

subtest 'Utils Role - local' => sub {

    my $cmd = TestCmd->new( project => $project );
    my $args = {};
    map has_attribute_ok( $cmd, $_ ), @attributes;
    map can_ok( $cmd, $_ ), @methods;

    is $cmd->remote_host, undef, 'local host';

    # Not installed, source does not exists

    $args = {
        destination => {
            name => 'nonexistent.file',
            path => 't/test-dst/install',
            perm => '0644',
        },
        source => {
            name => 'nonexistent.file',
            path => 'install',
        },
    };

    ok my $res1 = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $res1, 'App::PlannedCopy::Resource::Element', '$res1';

    ok my $src1 = path($repo_path, q(nonexistent.file) ),
        'source file path';
    ok my $dst1 = path($dest_path, q(nonexistent.file)), 'destination dir';

    is !$src1->is_file, 1, 'src is not a file';
    is !$dst1->is_file, 1, 'dst is not a file';

    # Copy
    throws_ok { $cmd->copy_file( 'install', $res1 ) }
    qr/No such file or directory/, 'no such file or directory caught okay';

    # Perms
    throws_ok { $cmd->get_perms($res1->dst) } qr/No such file or directory/,
        'no such file or directory caught okay';

    # Not installed, but source exists

    $args = {
        destination => {
            name => 'filename3',
            path => 't/test-dst/install',
            perm => '0644',
        },
        source => {
            name => 'filename3',
            path => 'install',
        },
    };

    ok my $res2 = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $res2, 'App::PlannedCopy::Resource::Element', '$res2';

    ok my $src2 = path( $repo_path, q(filename3) ), 'source file path';
    ok my $dst2 = path( $dest_path, q(filename3) ),
        'destination file path';

    is $src2->is_file, 1, 'src is a file';
    is !$dst2->is_file, 1, 'dst is not a file, yet';

    lives_ok { $cmd->copy_file( 'install', $res2 ) } 'file copy';

    is $dst2->is_file, 1, 'dst is a file';

    # Selfsame
    lives_ok { $cmd->is_selfsame( $res2->src, $res2->dst ) } 'is selfsame 1';
    is $cmd->is_selfsame( $res2->src, $res2->dst ), 1, 'is the same';
    lives_ok { $cmd->is_selfsame( $res2->src, $res2->dst ) } 'is selfsame 2';

    # Perms
    is $cmd->get_perms($res2->dst), '0644', 'the perms of the file';
    throws_ok { $cmd->set_perm( $dst1, oct(644) ) } qr/works only with files/,
        'works only with files caught';
    lives_ok { $cmd->set_perm( $dst2, oct(644) ) } 'file set perm';

    # Owner
    throws_ok { $cmd->get_owner($dst1) } qr/No such file or directory/,
        'no such file or directory caught okay';
    ok $cmd->get_owner($dst2), 'the owner of the file';

    # TODO: test set_owner (how?)
};

# Cleanup
path($dest_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($dest_path_orig, $dest_path);

subtest 'Utils Role - remote' => sub {
    my $cmd = TestCmd->new(
        project     => $project,
        remote_host => 'localhost',
    );
    my $args = {};
    map has_attribute_ok( $cmd, $_ ), @attributes;
    map can_ok( $cmd, $_ ), @methods;

    ok $cmd->remote_host, 'remote host';

    # Not installed, source does not exists
    $args = {
        destination => {
            name => 'nonexistent.file',
            path => 't/test-dst/install',
            perm => '0644',
        },
        source => {
            name => 'nonexistent.file',
            path => 'install',
        },
    };

    ok my $res1 = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $res1, 'App::PlannedCopy::Resource::Element', '$res1';

    ok my $src1 = path($repo_path, q(nonexistent.file) ),
        'source file path';
    ok my $dst1 = path($dest_path, q(nonexistent.file)), 'destination dir';

    is !$src1->is_file, 1, 'src is not a file';
    is !$dst1->is_file, 1, 'dst is not a file';

    # Copy
    throws_ok { $cmd->copy_file( 'install', $res1 ) }
    qr/No such file or directory/, 'no such file or directory caught okay';

    # Perms
    throws_ok { $cmd->get_perms($res1->dst) } qr/No such file or directory/,
        'no such file or directory caught okay';

    # Not installed, but source exists

    $args = {
        destination => {
            name => 'filename3',
            path => 't/test-dst/install',
            perm => '0644',
        },
        source => {
            name => 'filename3',
            path => 'install',
        },
    };

    ok my $res2 = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $res2, 'App::PlannedCopy::Resource::Element', '$res2';

    ok my $src2 = path( $repo_path, q(filename3) ), 'source file path';
    ok my $dst2 = path( $dest_path, q(filename3) ),
        'destination file path';

    is $src2->is_file, 1, 'src is a file';
    is !$dst2->is_file, 1, 'dst is not a file, yet';

    lives_ok { $cmd->copy_file( 'install', $res2 ) } 'file copy';

    is $dst2->is_file, 1, 'dst is a file';

    # Selfsame
    lives_ok { $cmd->is_selfsame( $res2->src, $res2->dst ) } 'is selfsame 1';
    is $cmd->is_selfsame( $res2->src, $res2->dst ), 1, 'is the same';
    lives_ok { $cmd->is_selfsame( $res2->src, $res2->dst ) } 'is selfsame 2';

    # Perms
    is $cmd->get_perms($res2->dst), '0644', 'the perms of the file';
    throws_ok { $cmd->set_perm( $dst1, oct(644) ) } qr/works only with files/,
        'works only with files caught';
    lives_ok { $cmd->set_perm( $dst2, oct(644) ) } 'file set perm';

    # Owner
    throws_ok { $cmd->get_owner($dst1) } qr/No such file or directory/,
        'no such file or directory caught okay';
    ok $cmd->get_owner($dst2), 'the owner of the file';

    # TODO: test set_owner (how?)
};


done_testing();
