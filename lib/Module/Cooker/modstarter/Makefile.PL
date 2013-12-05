use 5.008_008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker 6.59;

WriteMakefile(
    NAME             => '[% package.name %]',
    AUTHOR           => q{[% author.name %] <[% author.email %]>},
    VERSION_FROM     => '[% package.modulepath %]',
    ABSTRACT_FROM    => '[% package.modulepath %]',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '[% package.minperl %]',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.59,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => '[% package.dist_name %]-*' },
);
