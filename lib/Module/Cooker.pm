package Module::Cooker;

our $VERSION = 'v0.1_5';

#use 5.008_008;

use strict;
use warnings FATAL => 'all';

use Data::Dumper;

use Carp;
use Cwd ();
use Try::Tiny;

use version 0.77;

use ExtUtils::Manifest qw( mkmanifest );
use Storable (qw( dclone ));

use File::Path 2.07 qw( make_path );
use File::Spec::Functions qw( catdir catfile );
use File::Which;

use POSIX qw( strftime );

use Template;

my $profile_name_rx = qr/[A-Z_a-z][A-Z_a-z0-9.-]*/;

# the following regex is ripped from Module::Runtime
# suggested by Perl Monk tobyink (http://www.perlmonks.org/?node_id=757127)
my $module_name_rx = qr/[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*/;

my $defaults = {
    minperl   => '',
    author    => 'A. Uthor',
    email     => 'author@example.com',
    profile   => 'default',
    package   => 'My::MC::Module',
    version   => 'v0.1_1',
    extravars => {},
    localdirs => [],
    nosubs    => 0,

#    nolinks => 1, # future use?
};

my @boolean_params = (
    'nosubs',

#    'nolinks', # future use?
);

sub new {
    my $class    = shift;
    my %incoming = @_;

    my $self = bless _validate_incoming( \%incoming ), $class;

    # be lazy and automatically generate accessors.
    # Perl Monk GrandFather should appreciate this. :)
    foreach my $attribute ( keys( %{$self} ) ) {
        next if $attribute =~ /^_/;
        next if $self->can($attribute);

        no strict 'refs';

        # auto-generated accessors should go in this package, not a
        # sub-class. the sub-class can always override like
        # normal if need be.
        *{ __PACKAGE__ . "::$attribute" } = sub {
            my $self = shift;

            croak "Can't set read-only attribute: $attribute" if @_;

            return $self->{$attribute};
        };
    }

    # this needs to be set at the time of instance creation because
    # if a subsequent chdir occurs the method won't be able to
    # resolve a relative path in %INC. this is specifically needed
    # for the test suite to work properly in a tmp dir.
    $self->{_basename_dir} = $self->_basename_dir;

    $self->{_made_dist_dir} = 0;
    $self->{_templates}     = {};
    $self->{_template_dirs} = [];

    return $self;
}

# NOTE: email addresses are not validated since it might be desirable to
# use an anti-SPAM pattern. i.e. "author at example dot com". suggestions
# as to how to add some form of minimal checking are welcome.
sub _validate_incoming {
    my $incoming = shift;

    my $args = {};
    for ( keys( %{$defaults} ) ) {
        $args->{$_} = delete( $incoming->{$_} ) || $defaults->{$_};
    }
    croak 'Unknown parameter(s): ' . join( ', ', keys( %{$incoming} ) )
      if keys( %{$incoming} );

    croak "Parameter 'package' must be supplied"
      unless $args->{package};
    croak "Invalid package name: $args->{package}"
      unless $args->{package} =~ /\A$module_name_rx\z/o;

    croak "Illegal profile name: $args->{profile}"
      unless $args->{profile} =~ /\A$profile_name_rx\z/o;

    # ensure that boolean params have boolean values
    for (@boolean_params) {
        my $orig = $args->{$_};
        $args->{$_} = !!$args->{$_} || 0;
        croak "Boolean param $_ must be '0' or '1': $orig ne $args->{$_}"
          unless $args->{$_} eq $orig;
    }

    try {
        version->parse( $args->{version} );
    }
    catch {
        croak $_;
    };

    croak "Param 'extravars' must be a hashref"
      unless ( ref( $args->{extravars} ) || '' ) eq 'HASH';

    croak "Param 'localdirs' must be an arrayref"
      unless ( ref( $args->{localdirs} ) || '' ) eq 'ARRAY';

    return $args;
}

# used to build path to where the main package module will be placed
# in the distribution dir.
sub _lib_path {
    my $self = shift;

    my @parts = split( /::/, $self->{package} );
    pop(@parts);    # remove basename

    unshift( @parts, 'lib' );

    return join( '/', @parts );
}

# used to find the location of THIS module. assumes that all support
# dirs will be under a directory named after this module (without
# the '.pm')
# NOTE! this is a class method that doesn't check the 'cached' value.
# YOU WILL BE SURPRISED if there has been an intervening chdir operation!
# see the public 'basename_dir' method for normal use.
sub _basename_dir {
    my $package = __PACKAGE__;

    $package =~ s/::/\//g;
    my $packpath = $INC{ join( '.', $package, 'pm' ) };
    $packpath =~ s/\.pm$//;

    my $realpath = Cwd::realpath($packpath);

    return $realpath;
}

# create the dist dir in the cwd
sub _make_dist_dir {
    my $self = shift;

    # croak if a fatal error occurs, better to die here than later
    try {
        make_path( $self->dist_name ) or die $!;
        $self->{_made_dist_dir} = 1;
    }
    catch {
        die "Can not make distribution dir: $_";
    };

    return;
}

# builds a hash that will be passed to Template
sub _package_info {
    my $self = shift;

    my $module_path = catfile( $self->_lib_path, $self->module_name );

    my $package = {
        name       => $self->{package},
        dist_name  => $self->dist_name,
        libpath    => $self->_lib_path,
        module     => $self->module_name,
        modulepath => $module_path,
        version    => $self->{version},
        minperl    => $self->{minperl},
        timestamp  => strftime( '%Y-%m-%d %T', localtime() ),
        year       => strftime( '%Y', localtime() ),
    };

    return $package;
}

# builds a hash that will be passed to Template
sub _author_info {
    my $self = shift;

    my $author = {
        name  => $self->{author},
        email => $self->{email},
    };

    return $author;
}

sub _include_path {
    my $self = shift;

    return $self->{_include_path} if $self->{_include_path};
}

sub _process_template {
    my $self = shift;
    my %args = @_;

    # Template will automatically create missing dirs, but doing this
    # allows for bailing out if the main dist dir already exists.
    # having the test here ensures catching such a condition at a
    # common point that is less likely to be skipped over.
    if ( !$self->{_made_dist_dir} ) {
        my $direxists = !!( -d $self->dist_name );
        die "Distribution directory already exists: " . $self->dist_name
          if -d $self->dist_name;

        # dist dir does not exist. this also sets _made_dist_dir
        $self->_make_dist_dir;
    }

    die "Template name missing!" unless $args{template};

    my $outfile;
    if ( $args{template} =~ /^Module\.pm$/ ) {    # gets speical treatment
        $outfile = catfile( $self->_lib_path, $self->module_name );
    } else {
        $outfile = $args{template};
    }

# need to add logic to add paths for INCLUDE directives to INCLIDE_PATH

    # this is a seperate stucture to all for a future method to let
    # users specify additional config options similar to how
    # extravars work.
    my $tt_config = {
        TRIM         => 0,
        PRE_CHOMP    => 0,
        POST_CHOMP   => 0,
        INCLUDE_PATH => \@{ $self->profile_dirs },
        OUTPUT_PATH  => $self->dist_name,
    };
    my $t = Template->new($tt_config);

    my $vars = $self->template_data;

    $t->process( $args{template}, $vars, $outfile ) || die $t->error . "\n";

    return;
}

sub _gather_profile {
    my $self = shift;
    my %args = @_;

    my $dir    = $args{abs_path};
    my $subdir = $args{subdir_path};

    die "Can't find dir: $dir\n" unless -d $dir;

    opendir( my $dh, $dir ) or die "can't opendir $dir: $!";
    my @files = readdir($dh);
    closedir $dh;

    my $std_dir = $self->std_profiles_dir;
    my $src_type = ( $dir =~ /^(?:\Q$std_dir\E)/ ) ? 'standard' : 'local';

    for my $fname (@files) {
        next if $fname =~ m{^\.{1,2}\z};

        my $fpath = File::Spec->catfile( $dir, $fname );

        # $fpath = readlink($fpath) if -l $fpath;

        # don't follow symlinks for now.
        # use nolinks param to control this later if desired.
        next if -l $fpath;

        if ( -d $fpath ) {
            if ( $self->{nosubs} ) {
                warn "Skipping profile sub-directory: $fpath\n";
                next;
            }

            my $subpath = $subdir ? catdir( $subdir, $fname ) : $fname;

            try {
                push( @{ $self->{_template_dirs} }, $subpath );

                # trust perl's deep recursion detection
                $self->_gather_profile(
                    abs_path    => $fpath,
                    subdir_path => $subpath
                );
            }
            catch {
                die $_;
            };

            next;
        }

        next unless -f $fpath;

        my $template = $subdir ? catfile( $subdir, $fname ) : $fname;
#        $self->{_templates}{$template} = catfile( $dir, $subdir )
        $self->{_templates}{$template} = $src_type
          unless $self->{_templates}{$template};
    }

    return;
}

# future use? considering an option to pass Template through perltidy
sub _perltidy_cmd {
    my $tidy = which('perltidy');

    return $tidy;
}

# override the default accessor generation to ensure a copy is made
sub extravars {
    my $self = shift;

    croak "Can't set read-only attribute: extravars" if @_;

    my $tmp       = $self->{extravars};
    my $extravars = dclone($tmp);

    return wantarray ? %{$extravars} : $extravars;
}

# override the default accessor generation to ensure a copy is made
sub localdirs {
    my $self = shift;

    croak "Can't set read-only attribute: localdirs" if @_;

    my @localdirs = @{ $self->{localdirs} };

    return wantarray ? @localdirs : \@localdirs;
}

# return a list of dirs that actually contain the requested profile
sub profile_dirs {
    my $self = shift;

    croak "Can't set read-only method: profile_dirs" if @_;

    my @searchdirs = $self->localdirs;
    push( @searchdirs, catdir( $self->std_profiles_dir ) );

    my @profile_dirs;
    for (@searchdirs) {
        my $profile_dir = catdir( $_, $self->profile );
        push( @profile_dirs, $profile_dir ) if -d $profile_dir;
    }

    return wantarray ? @profile_dirs : \@profile_dirs;
}

sub basename_dir {
    my $self = shift;

    croak "Can't set read-only method: basename_dir" if @_;

    return $self->{_basename_dir};
}

# builds path to where standard templates located
sub std_profiles_dir {
    my $self = shift;

#    my $dir = catdir( $self->basename_dir, 'profiles', $self->{profile} );
    my $dir = catdir( $self->basename_dir, 'profiles' );

    -d $dir ? return $dir : return;
}

# builds list of final attribute values
sub summary {
    my $self = shift;

    croak "Can't set read-only method: summary" if @_;

    my $tmp = {};
    for ( keys( %{$self} ) ) {
        next if /^_/;    # we only want the attributes, not internals
        $tmp->{$_} = $self->{$_};
    }

    my $summary = dclone($tmp);

    # sorry, Will, but i think this is handy. :)
    return wantarray ? %{$summary} : $summary;
}

# simple transform: i.e. Foo::Bar -> Foo-Bar
sub dist_name {
    my $self = shift;

    croak "Can't set read-only method: dist_name" if @_;

    my $dname = $self->{package};
    $dname =~ s/::/-/g;

    return $dname;
}

# generates main module name. i.e. Foo::Bar -> Bar.pm
sub module_name {
    my $self = shift;

    croak "Can't set read-only method: module_name" if @_;

    my @parts = split( /::/, $self->{package} );

    return join( '.', pop(@parts), 'pm' );
}

sub template_data {
    my $self = shift;

    croak "Can't set read-only method: template_data" if @_;

    my $tmp = {
        author    => $self->_author_info,
        package   => $self->_package_info,
        modcooker => {
            version => $VERSION,
            perlver => $],
        },
        extra => $self->{extravars},
    };

    my $tdata = dclone($tmp);

    return wantarray ? %{$tdata} : $tdata;
}

# the ultimate goal of this module
sub cook {
    my $self = shift;

    # clear our template list
    $self->{_templates}     = {};
    $self->{_template_dirs} = [];

    for ( @{ $self->profile_dirs } ) {
        my $dir = Cwd::realpath($_);
        $self->_gather_profile( abs_path => $dir, subdir_path => undef );
    }

#warn Dumper($self->{_templates});
    foreach ( keys( %{ $self->{_templates} } ) ) {
        $self->_process_template( template => $_ );
    }

    if ( !-f catfile( $self->dist_name, 'MANIFEST' ) ) {
        chdir $self->dist_name;
        mkmanifest();
        chdir '..';
    }

}

1;    # End of Module::Cooker
__END__

=head1 NAME

Module::Cooker - Module starter kit based on Template

=head1 VERSION

Version v0.1.4

=head1 SYNOPSIS

  
 use Module::Cooker;
  
 my $mc = Module::Cooker->new( %params );
 $mc->cook();
  

=head1 DESCRIPTION

You are probably more interested in the command line interface to this module:
L<modcooker|modcooker>

=head1 CONSTRUCTOR

=head2 new

Here are the default vaues for the attributes:

  
 my $defaults = {
     minperl   => '',
     author    => 'A. Uthor',
     email     => 'author@example.com',
     profile   => 'default',
     package   => 'My::MC::Module',
     version   => 'v0.1_1',
     extravars => {},
     localdirs => [],
     nosubs    => 0,
 };
  

=over 4

=item package

A string representing the name of the package/module. I.e. My::New::Module

=item minperl

A string representing the minimum version of Perl require to use the module.
I.e. 'v5.8.8' or '5.8.8' or even '5.008008'.  Default: '' (empty string)

=item author

A string with the author's name. Default: '' (empty string);

=item email

A string with the author's email. Default: '' (empty string);

=item profile

The profile from which the module should be built from. Default: 'default'

=item version

A string representing the version of the new module. Default: 'v0.1_1'

=item extravars

This option creates a hash ref that is eventually passed as part of the
data structure that L<Template> will use as substitution variables.
Any element in the hash ref can be accessed as C<extra.element_name> in
a template file.

=item localdirs

The directory (or directories if specified multiple times) to search in
addition to the standard distrubution profile directory for the profile named
by the '--profile' parameter. This is built as an array ref. Default: []

=item nosubs

Boolean flag indicating that subdirectories in the profile should NOT be
searched for template files. (Will probably be removed in the next
release.) Default: 0

=back

=head1 ACCESSORS

There is a read-only accessor provided for each of the parameters accepted
by C<new>.

You can also obtain a hash (or hashref) with the values for each parameter
by using the L</summary> method described below.

=head1 METHODS

=head2 cook

This is the method that does the real work of the module. Based upon the
parameters used to construct the object, it will search the profile
directory(ies) for the specified profile. It will then build a list of
files in the profile to be processed by L<Template>.

The processed files will be placed under a distribution directory created
in the current directly. A MANIFEST will be built at the completion of this
processing.

An exception will be thrown if the distribution directory already exists.

=head2 dist_name

  
 print $mc->dist_name . "\n";   # prints My-MC-Module
  

Read-only method that returns the name of the distrubution as derived from
the package name. This is the name that is used to create the top-level
directory for the distrubution. '::' sequences are transformed to '-' in
accordance with normal CPAN practice.

=head2 module_name

  
 print $mc->module_name . "\n";   # prints Module.pm
  

Read-only method that returns the name of main module in the distrubution.
This is derived by taking the final element of the package name and
appending '.pm' to it.

=head2 profile_dirs

Read-only method that returns a list of directories that contain a
sub-directory with the same name as the requested profile.

The method will return either an array or array reference depending upon
the calling context.

=head2 template_data

  
 my $template_data = $mc->template_data;
 my %template_data = $mc->template_data;
  
 print Dumper($template_data);
  
 $VAR1 = {
   'author' => {
     'name'  => 'A. Uthor'
     'email' => 'author@example.com',
   },
   'modcooker' => {
     'version' => '0.01'
     'perlver' => '5.010001',
   },
   'package' => {
     'name'       => 'My::MC::Module',
     'dist_name'  => 'My-MC-Module',
     'version'    => 'v0.1_1',
     'minperl'    => '',
     'libpath'    => 'lib/My/MC',
     'module'     => 'Module.pm'
     'modulepath' => 'lib/My/MC/Module.pm',
     'timestamp'  => '2013-11-28 16:40:23',
     'year'       => '2013'
   }
 };
  

Read-only method that returns a copy of the data that will be passed to
Template to be used for variable substitution. It should be noted that this
is a copy and changes made to the returned structure will not affect
what is actually passed on.

The method will return either a hash or hash reference depending upon the
calling context.

=head2 basename_dir

Read-only method that returns the absolute path to where the module is
located in the C<@INC> search path with the name of this module
(C<Cooker>) appended. This is used to located the module's standard
template directories.

=head2 std_profiles_dir

Read-only method that returns the absolute path to where the standard
profiles are located in the distribution.

=head2 summary

  
 my $summary = $mc->summary;
 my %summary = $mc->summary;
  
 print Dumper($summary);
  
 $VAR1 = {
   'nosubs'    => 0,
   'profile'   => 'default',
   'localdirs' => [],
   'version'   => 'v0.1_1',
   'author'    => 'A. Uthor',
   'extravars' => {},
   'package'   => 'My::MC::Module',
   'minperl'   => '',
   'email'     => 'author@example.com'
 };
  

Read-only method that returns a copy of the data stored in the internal
attributes after object construction. It should be noted that this
is a copy and changes made to the structure will not affect the object
itself.

The method will return either a hash or hash reference depending upon the
calling context.

=head1 AUTHOR

Jim Bacon, C<< <jim at nortx.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-cooker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Cooker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can also submit an issue via the GitHub repository listed below.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Cooker


You can also look for information at:

=over 4

=item * GitHub:

L<https://github.com/boftx/Module-Cooker>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Cooker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Cooker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Cooker>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Cooker/>

=back


=head1 ACKNOWLEDGEMENTS

This module draws heavily upon ideas found in L<Distribution::Cooker>,
L<ExtUtils::ModuleMaker> and L<Module::Starter>.

Special thanks goes to Perl Monk
L<tobyink|http://www.perlmonks.org/?node_id=757127> for the module name
regex pattern and the L<Perl Monks|http://www.perlmonks.org> who assisted
with peer review of the code, test suite, and documentation.

=head1 SEE ALSO

L<Template>,
L<Jose's Guide for Creating Perl modules|http://www.perlmonks.org/?node_id=431702>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jim Bacon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

