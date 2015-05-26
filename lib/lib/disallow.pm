package lib::disallow;

# DATE
# VERSION

use strict;
use warnings;

require lib::filter;

sub import {
    my $pkg = shift;

    lib::filter->import(disallow=>join(';',@_));
}

sub unimport {
    lib::filter->unimport;
}

1;
# ABSTRACT: Disallow a list of modules from being locateable/loadable

=for Pod::Coverage .+

=head1 SYNOPSIS

 % perl -Mlib::disallow=YAML,YAML::Syck,YAML::XS yourscript.pl


=head1 DESCRIPTION

This pragma is a shortcut for L<lib::filter>. This:

 use lib::disallow qw(YAML YAML::Syck YAML::XS);

is equivalent to:

 use lib::filter disallow=>'YAML;YAML::Syck;YAML::XS';


=head1 SEE ALSO

L<lib::filter>

=cut
