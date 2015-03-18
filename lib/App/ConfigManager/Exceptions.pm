package App::ConfigManager::Exceptions;

# ABSTRACT: Config Manager Exceptions

use strict;
use warnings;

use Exception::Base (
    verbosity => 3,
    'Exception::Config',
    'Exception::Config::Error' => {
        isa               => 'Exception::Config',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg )],
    },
    'Exception::Config::NoConfig' => {
        isa               => 'Exception::Config',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg )],
    },
    'Exception::Config::YAML' => {
        isa               => 'Exception::Config',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    },
    'Exception::IO',
    'Exception::IO::Git' => {
        isa               => 'Exception::IO',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    },
    'Exception::IO::SystemCmd' => {
        isa               => 'Exception::IO',
        has               => [qw( usermsg logmsg )],
        string_attributes => [qw( usermsg logmsg )],
    },
    'Exception::IO::PathNotDefined' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::PathNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::FileNotFound' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
    'Exception::IO::PermissionDenied' => {
        isa               => 'Exception::IO',
        has               => [qw( pathname )],
        string_attributes => [qw( message pathname )],
    },
);

1;
