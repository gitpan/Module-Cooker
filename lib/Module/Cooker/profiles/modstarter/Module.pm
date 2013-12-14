package [% package.name %];

use [% package.minperl %];
use strict;
use warnings FATAL => 'all';

=head1 NAME

[% package.name %] - The great new [% package.name %]!

=head1 VERSION

Version [% package.version %]

=cut

our $VERSION = '[% package.version %]';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use [% package.name %];

    my $foo = [% package.name %]->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Jim Bacon, C<< <jim at nortx.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-my-mc-module at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=[% package.dist_name %]>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc [% package.name %]


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% package.dist_name %]>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/[% package.dist_name %]>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/[% package.dist_name %]>

=item * Search CPAN

L<http://search.cpan.org/dist/[% package.dist_name %]/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright [% package.year %] [% author.name %].

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of [% package.name %]
