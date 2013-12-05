#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;

use File::Temp;
use Cwd;

plan tests => 4;

# it is not possible to properly test this module if we can not reliably
# create and chdir to temp dirs.

# NOTE! the value from cwd is tainted!
cwd() =~ /^(.+)/o;
my $cwd = $1 or die $!;

diag("\noriginal cwd: $cwd");

my $realtmp;

{    # inner scope for File::Temp to work in
    # all tests must be within this scope to prevent droping the tmp dir!

    my $tmpdir = File::Temp->newdir;

    # NOTE! the value from realpath is tainted!
    Cwd::realpath($tmpdir) =~ /^(.+)$/o;
    die "Can't get realpath for $tmpdir" unless ( $realtmp = $1 );
    diag("will chdir to $realtmp");

    ok( -d $realtmp, 'tmpdir exists in scope' );
    chdir $realtmp or BAIL_OUT("Can't chdir to tmpdir $realtmp: $!");

    my $newcwd = cwd();
    ok( $newcwd eq $realtmp, "Chdir to $realtmp" );
    diag("New cwd: $newcwd");

    # have to get out of the tmpdir for it to be removed
    chdir $cwd or BAIL_OUT("Can not restore original cwd: $!");

    my $final_cwd = cwd();
    ok( $cwd eq $final_cwd, "chdir back to original cwd: $cwd" );

    # the tmpdir and all files should disappear when we exit this block
}

ok( !( -d $realtmp ), 'tmpdir no longer exists' );
diag("$realtmp was removed");

exit;
