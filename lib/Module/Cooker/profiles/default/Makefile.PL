# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

[%- IF package.minperl %]
use [%- package.minperl %];
[% END -%]

use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker 6.59;

WriteMakefile(
    NAME               => '[% package.name %]',
    AUTHOR             => '[% author.name %] <[% author.email %]>',
    VERSION_FROM       => '[% package.modulepath %]',
    ABSTRACT_FROM      => '[% package.modulepath %]',
    LICENSE            => 'Perl',
    PL_FILES           => {},
[%- IF package.minperl %]
    MIN_PERL_VERSION   => '[% package.minperl %]',
[% END -%]
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.59,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        # NOTE the use of quotes around non-numeric strings!
        #'ABC'              => 0,
        #'Foo::Bar::Module' => 5.004001,
        #'Foo::Bar::Module' => '5.4_1',
        #'Foo::Bar::Module' => '5.4.1',
        #'Foo::Bar::Module' => 'v5.4_1',
        #'Foo::Bar::Module' => 'v5.4.1',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => '[% package.dist_name %]-*' },
);
