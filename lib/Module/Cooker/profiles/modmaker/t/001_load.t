# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( '[% package.name %]' ); }

my $object = [% package.name %]->new ();
isa_ok ($object, '[% package.name %]');


