use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker 6.59;

WriteMakefile(
    NAME               => 'Module::Cooker',
    AUTHOR             => 'Jim Bacon <jim@nortx.com>',
    VERSION_FROM       => 'lib/Module/Cooker.pm',
    ABSTRACT_FROM      => 'lib/Module/Cooker.pm',
    LICENSE            => 'Perl',
    PL_FILES           => {},
    EXE_FILES           => [ 'bin/modcooker' ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.59,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'AppConfig'             => 0,
        'Carp'                  => 0,
        'Cwd'                   => 0,
        'Data::Dumper'          => 0,
        'ExtUtils::Manifest'    => 0,
        'File::Copy'            => 0,
        'File::HomeDir'         => 0,
        'File::Path'            => 0,
        'File::Spec::Functions' => 0,
        'File::Temp'            => 0,
        'File::Which'           => 0,
        'Getopt::Long'          => 0,
        'Pod::Usage'            => 0,
        'POSIX'                 => 0,
        'Storable'              => 0,
        'Template'              => 0,
        'Try::Tiny'             => 0,
        'version'               => '0.77',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
