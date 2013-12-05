#!perl -T
use 5.008_008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( '[% package.name %]' ) || print "Bail out!\n";
}

diag( "Testing [% package.name %] $[% package.name %]::VERSION, Perl $], $^X" );
