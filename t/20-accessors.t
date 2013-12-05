#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Try::Tiny;
use Data::Dumper;

require Module::Cooker;

my $mc = new_ok('Module::Cooker');

# all params that can be set in the constructor have a read-only accessor
# associated with them. also, only such elements in the instance object
# that do NOT begin with an "_" character are considered to be attributes.
# therefore we can "peek inside" for test purposes to verify an accessor
# exists and is read-only.

for my $attr ( keys( %{$mc} ) ) {
    next if $attr =~ /^_/;
    next unless can_ok( 'Module::Cooker', $attr );
    ok( defined( $mc->$attr() ), "accessor $attr exists" );
    try {
        $mc->$attr('');    # try to set a value
    }
    catch {
        my $expected = "read-only attribute: $attr";
        like( $_, qr/$expected/, "$attr is read-only" );
    };
}

# verify that poking around with the extravars and localdirs accessors
# doesn't alter the object internal values

my $extravars = $mc->extravars;
$extravars->{foo} = 'bar';
my $extravars2 = $mc->extravars;
ok(!exists($extravars2->{foo}), 'new key not propagated to parameter');

my $localdirs = $mc->localdirs;
push(@{$localdirs},'foo');
my $localdirs2 = $mc->localdirs;
ok(!grep(/foo/,@{$localdirs2}), 'new element not propagated to parameter');

done_testing();

exit;
