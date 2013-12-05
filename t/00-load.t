#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;

diag("Testing Module::Cooker $Module::Cooker::VERSION, Perl $], $^X");

BEGIN {
    use_ok('Module::Cooker') || BAIL_OUT('Can not load module!');
}

new_ok('Module::Cooker') || BAIL_OUT('Can not create basic instance!');

plan tests => 2;

exit;

__END__
