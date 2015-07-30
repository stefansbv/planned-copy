# -*- perl -*-

use Test::More tests => 8;

use_ok( 'App::PlannedCopy' );
use_ok( 'App::PlannedCopy::Config' );
use_ok( 'App::PlannedCopy::Command::Check' );
use_ok( 'App::PlannedCopy::Command::Config' );
use_ok( 'App::PlannedCopy::Command::Repo' );
use_ok( 'App::PlannedCopy::Command::Install' );
use_ok( 'App::PlannedCopy::Command::List' );
use_ok( 'App::PlannedCopy::Command::Sync' );

# end
