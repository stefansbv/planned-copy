# -*- perl -*-

use Test::More tests => 8;

use_ok( 'App::ConfigManager' );
use_ok( 'App::ConfigManager::Config' );
use_ok( 'App::ConfigManager::Command::Check' );
use_ok( 'App::ConfigManager::Command::Config' );
use_ok( 'App::ConfigManager::Command::Repo' );
use_ok( 'App::ConfigManager::Command::Install' );
use_ok( 'App::ConfigManager::Command::List' );
use_ok( 'App::ConfigManager::Command::Sync' );

# end
