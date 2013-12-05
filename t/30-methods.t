#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Try::Tiny;

require Module::Cooker;

my $mc = new_ok('Module::Cooker');

# the following should be read-only
for my $method (
    qw( profile_dirs basename_dir summary module_name dist_name template_data )
  ) {
    next unless can_ok( 'Module::Cooker', $method );
    ok( defined( $mc->$method() ), "accessor $method exists" );
    try {
        $mc->$method('');    # try to set a value
    }
    catch {
        my $expected = "read-only method: $method";
        like( $_, qr/$expected/, "$method is read-only" );
    };
}

done_testing();

exit;
