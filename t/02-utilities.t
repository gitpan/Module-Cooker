#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Try::Tiny;

require_ok('Module::Cooker');

# this test script verifies that some low-level validations and
# other fundamental operations work as expected. if any of them fail
# it is probably best to BAIL_OUT of the test suite since no further
# testing would be possible.

my $mc = new_ok('Module::Cooker');

my $basename_dir = $mc->_basename_dir;
my @parts = split( /\//, $basename_dir );
ok( $parts[-1] eq 'Cooker', 'basename_dir has "Cooker" as last part' );

done_testing();

exit;
