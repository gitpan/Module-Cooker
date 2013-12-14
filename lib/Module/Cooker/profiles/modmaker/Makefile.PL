

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => '[% package.name %]',
    VERSION_FROM => '[% package.modulepath %]', # finds \$VERSION
    AUTHOR       => '[% author.name %] ([% author.email %])',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
