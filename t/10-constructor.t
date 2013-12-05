#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Try::Tiny;

require_ok('Module::Cooker');

my @good_pnames = (
    qw(
      foo
      _foo
      foo::bar
      foo::_bar
      foo::0bar
      foo_bar
      foo::bar_baz
      )
);

my @bad_pnames = (
    qw(
      foo.pm
      0foo
      foo!
      foo:bar
      foo::bar!
      foo::bar.pm
      foo::bar:baz
      foo::bar/baz
      foo/bar/baz
      )
);
push( @bad_pnames, 'foo bar', "foo\n" );

for my $good_pname (@good_pnames) {
    try {
        my $mc = Module::Cooker->new( package => $good_pname );
        pass("$good_pname is a valid package name")
    } catch {
        my $expect = qr/Invalid package name: $good_pname/;
        if ( $_ =~ /$expect/ ) {
            fail("$good_pname should be good but failed");
        } else {
            fail("Unexpected package name error: $_")
        }
    };
}

for my $bad_pname (@bad_pnames) {

    # we have to BAIL_OUT if any of these validate since it could
    # potentially cause major problems later with dir creation
    try {
        my $mc = Module::Cooker->new( package => $bad_pname );
        BAIL_OUT("$bad_pname was accepted as a valid package name")
    } catch {
        my $expect = qr/Invalid package name: $bad_pname/;
        BAIL_OUT "Unexpected package name error: $_"
          unless like($_, $expect, "$bad_pname was correctly rejected")
    };
}

#my $mc = new_ok('Module::Cooker');

done_testing();

exit;
