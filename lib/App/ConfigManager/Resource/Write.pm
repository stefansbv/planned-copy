package App::ConfigManager::Resource::Write;

# ABSTRACT: Write a 'resource.yml' file

use 5.010001;
use utf8;
use Moose;
use MooseX::Types::Path::Tiny qw(Path);
use namespace::autoclean;

use Try::Tiny;
use YAML::Tiny 1.57;                         # errstr deprecated

has 'resource_file' => (
    is     => 'ro',
    isa    => Path,
    coerce => 1,
);

sub create_yaml {
    my ($self, $data) = @_;
    my $yaml = YAML::Tiny->new($data);
    my $file = $self->resource_file;
    unless ($file->parent->is_dir) {
        Exception::IO::PathNotFound->throw(
            message  => 'The parent dir was not found.',
            pathname => $file->parent->stringify,
        );
    }
    try   { $yaml->write($file->stringify) }
    catch {
        Exception::Config::YAML->throw(
            usermsg => "Failed to write resource file '$file'",
            logmsg  => $_,
        );
    };
    return;
}

__PACKAGE__->meta->make_immutable;

1;
