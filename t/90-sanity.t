#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Try::Tiny;
use File::Temp;
use Cwd;

use Data::Dumper;

require Module::Cooker;

my $class = 'Module::Cooker';

my $mc = new_ok( $class )
  || BAIL_OUT('can not do sanity tests without an object!');

# cwd() returns a tainted value!
cwd() =~ /^(.+)$/o;
my $cwd = $1 or BAIL_OUT("cwd() failed to return a path!");

my $realtmp;

{    # inner scope for File::Temp to work in

    # all tests must be within this scope to prevent droping the tmp dir!
    my $tmpdir = File::Temp->newdir;

    # realpath() return a tainted value!
    Cwd::realpath($tmpdir) =~ /^(.+)$/o;
    $realtmp = $1 or BAIL_OUT("realpath() failed to return a path!");

    ok( -d $realtmp, 'tmpdir exists in scope' );
    diag("will chdir to $realtmp");

    chdir $realtmp or BAIL_OUT("Can not chdir to tmpdir $realtmp!");

    my $newcwd = cwd();
    ok( $newcwd eq $realtmp, "Chdir to $realtmp" );

    # now we can begin the real testing
    try {
        $mc->cook;
    }
    catch {
        fail "Dist build failed: $_";
    };

    # this should fail because the dist dir already exists
    $mc->{_made_dist_dir} = 0;
    try {
        $mc->cook;
        fail("overwrote existing distribution!");
    }
    catch {
        like(
            $_,
            qr/Distribution directory already exists/,
            "won't overwrite existing dist"
        ) or fail("Unexpected exception: $_");
    };

    # time to clean up, we hope!
    chdir $cwd or die "Can not restore original cwd: $!";
    my $final_cwd = cwd();
    ok( $cwd eq $final_cwd, "chdir back to original cwd: $cwd" );

    # the tmpdir and all files will disappear when we go out of this block
}

ok( !( -d $realtmp ), 'tmpdir does not exist out of scope' );

done_testing();

exit;
