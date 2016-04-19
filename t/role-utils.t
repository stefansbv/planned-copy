#
# Test the Utils role
#

use Test::Most;
use Test::Moose;

use Path::Tiny;
use MooseX::ClassCompositor;

use App::PlannedCopy::Role::Utils;

my @attributes = ( qw() );

my @methods = (
    qw(
        is_selfsame
        copy_file
        set_perm
        set_owner
        handle_exception
        exception_to_issue
        no_resource_message
        quote_string
        compare
        get_project_files
        check_res_user
        check_user
        )
);

my $instance;
my $class = MooseX::ClassCompositor->new( { class_basename => 'Test', } )
    ->class_for( 'App::PlannedCopy::Role::Utils', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
    project => 'test',
)}                           'Test creation of an instance';

my $repo_path = path( qw(t test-repo) );
my $dest_path = path( qw(t test-dst) );

# Copy
ok my $src1 = path($repo_path, qw(check nonexistent.file) ),
    'source file path';
ok my $dst1 = path($dest_path, qw(check nonexistent.file)), 'destination dir';
throws_ok { $instance->copy_file( $src1, $dst1 ) }
    qr/No such file or directory/, 'no such file or directory caught okay';

ok my $src2 = path($repo_path, qw(check filename1) ), 'source file path';
ok my $dst2 = path($dest_path, qw(check filename1) ), 'destination file path';
is $src2->is_file, 1, 'src is a file';
lives_ok { $instance->copy_file($src2, $dst2) } 'file copy';
is $dst2->is_file, 1, 'dst is a file';

# Selfsame
lives_ok { $instance->is_selfsame( $src1, $dst1 ) } 'is selfsame 1';
is $instance->is_selfsame( $src1, $dst1 ), 0, 'not the same';
lives_ok { $instance->is_selfsame($src2, $dst2  ) } 'is selfsame 2';

# Set perm
throws_ok { $instance->set_perm( $dst1, 0644 ) }
    qr/works only with files/, 'works only with files caught';
lives_ok { $instance->set_perm( $dst2, 0644 ) } 'file set perm';

done_testing();
