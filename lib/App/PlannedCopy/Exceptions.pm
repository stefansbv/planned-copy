package App::PlannedCopy::Exceptions;

# ABSTRACT: PlannedCopy custom exceptions

use strict;
use warnings;

use Exception::Base (
    verbosity => 3,
    'Exception::Config',
    'Exception::Config::Error' => {
        isa               => 'Exception::Config',
        has               => [qw( logmsg )],
        string_attributes => [qw( message logmsg )],
    },
    'Exception::Config::NoConfig' => {
        isa               => 'Exception::Config',
        has               => [qw( logmsg )],
        string_attributes => [qw( message logmsg )],
    },
    'Exception::Config::YAML' => {
        isa               => 'Exception::Config',
        has               => [qw( logmsg )],
        string_attributes => [qw( message logmsg )],
    },
    'Exception::IO',
    'Exception::IO::Git' => {
        isa               => 'Exception::IO',
        has               => [qw( logmsg )],
        string_attributes => [qw( message logmsg )],
    },
    'Exception::IO::SystemCmd' => {
        isa               => 'Exception::IO',
        has               => [qw( logmsg )],
        string_attributes => [qw( message logmsg )],
    },
    'Exception::IO::Stat' => {
        isa               => 'Exception::IO',
        has               => [qw( logmsg )],
        string_attributes => [qw( message logmsg )],
    },
    'Exception::IO::PathNotDefined' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::SrcFileNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::DstFileNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::SrcPermissionDenied' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::DstPermissionDenied' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::WrongUser' => {
        isa               => 'Exception::IO',
        has               => [qw( username )],
        string_attributes => [qw( message username )],
    },
    'Exception::IO::WrongPerms' => {
        isa               => 'Exception::IO',
        has               => [qw( perm type )],
        string_attributes => [qw( message perm )],
    },
);

1;
