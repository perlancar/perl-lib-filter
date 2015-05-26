package lib::allow;

# DATE
# VERSION

use strict;
use warnings;

require lib::filter;

sub import {
    my $pkg = shift;

    lib::filter->import(allow_core=>0, allow_noncore=>0, allow=>join(';',@_));
}

sub unimport {
    lib::filter->unimport;
}

1;
# ABSTRACT: Only allow a list of modules to be locateable/loadable

=for Pod::Coverage .+

=head1 SYNOPSIS

 % perl -Mlib::allow=XSLoader,List::Util yourscript.pl


=head1 DESCRIPTION

This pragma is a shortcut for L<lib::filter>. This:

 use lib::allow qw(Foo Bar::Baz Qux);

is equivalent to:

 use lib::filter allow_core=>0, allow_noncore=>0, allow=>'Foo;Bar::Baz;Qux';


=head1 SEE ALSO

L<lib::filter>

=cut
