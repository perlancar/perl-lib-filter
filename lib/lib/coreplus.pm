## no critic: TestingAndDebugging::RequireUseStrict
package lib::coreplus;

#IFUNBUILT
use strict;
use warnings;
#END IFUNBUILT

use Module::CoreList;
use lib::filter ();

# AUTHORITY
# DATE
# DIST
# VERSION

sub import {
    my $pkg = shift;

    my $re = join('|', map {quotemeta} @_);
    $re = qr/\A($re)\z/;

    lib::filter->import(
        filter => sub {
            return 1 if Module::CoreList->is_core($_);
            return 1 if $_ =~ $re;
            0;
        },
    );
}

sub unimport {
    lib::filter->unimport;
}

1;
# ABSTRACT: Allow core modules plus a few others

=for Pod::Coverage .+

=head1 SYNOPSIS

 % perl -Mlib::coreplus=Clone,Data::Structure::Util yourscript.pl


=head1 DESCRIPTION

This pragma uses L<lib::filter>'s custom C<filter> to accomplish its function.

Rationale for this pragma: using C<lib::filter>'s C<allow_noncore=0>+C<allow>
doesn't work for non-core XS modules because C<allow_noncore=0> will remove
non-core directories from C<@INC>, while XS modules will still look for their
loadable objects in C<@INC> during loading.

So the alternative approach used by C<lib::coreplus> is to check the module
against C<< Module::CoreList->is_core >>. If the module is not a core module
according to C<is_core>, it is then checked against the list of additional
modules specified by the user. If both checks fail, the module is disallowed.
lib::coreplus does not remove directories from C<@INC> because it does not use
C<allow_noncore=0>.


=head1 SEE ALSO

L<lib::filter>

=cut
