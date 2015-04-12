package lib::filter;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Config;

# BEGIN snippet from Module::Path::More, with mods/simplification
my $SEPARATOR;
BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}
sub module_path {
    my ($file, $inc) = @_;

    foreach my $dir (@$inc) {
        next if !defined($dir);
        next if ref($dir);
        my $path = $dir . $SEPARATOR . $file;
        return $path if -f $path;
    }
    undef;
}
# END snippet from Module::Path::More

sub _open_handle {
    my $path = shift;
    open my($fh), "<", $path
        or die "Can't open $path: $!";
    $fh;
}

sub import {
    use experimental 'smartmatch';

    my ($class, %opts) = @_;

    $opts{allow_core} //= 1;
    $opts{allow_noncore} //= 1;

    state $orig_inc = [@INC];
    state $hook;

    my $core_inc = [@Config{qw(privlibexp archlibexp)}];
    my $noncore_inc = [grep {$_ ne $Config{privlibexp} &&
                                 $_ ne $Config{archlibexp}} @$orig_inc];

    $hook //= sub {
        my ($self, $file) = @_;

        my $path;
      FILTER:
        {
            my $inc;
            if ($opts{allow_noncore} && $opts{allow_core}) {
                $inc = $orig_inc;
            } elsif ($opts{allow_core}) {
                $inc = $core_inc;
            } elsif ($opts{allow_noncore}) {
                $inc = $noncore_inc;
            }
            $path = module_path($file, $inc) if $inc;
            last FILTER if $path;
        } # FILTER

        return unless $path;

        $INC{$file} = $path;
        return _open_handle($path);
    };

    @INC = (
        $hook,
        grep {
            if ("$_" eq "$hook") {
                0;
            } elsif ($opts{allow_core} && $_ ~~ @$core_inc) {
                1;
            } elsif ($opts{allow_noncore} && $_ ~~ @$noncore_inc) {
                1;
            } else {
                0;
            }
        } @$orig_inc,
    );
    #use DD; dd $orig_inc;
    #use DD; dd \@INC;
}

1;

=for Pod::Coverage .+

=head1 SYNOPSIS

 # equivalent to -Mlib::none
 % perl -Mlib::filter=allow_core,0,allow_noncore,0 yourscript.pl

 # equivalent to -Mlib::core::only
 % perl -Mlib::filter=allow_noncore,0 yourscript.pl

 # allow core modules plus some more modules
 % perl -Mlib::filter=allow_noncore,0,allow,'List::MoreUtils;List::MoreUtils::PP;List::MoreUtils::XS' yourscript.pl

 # allow additional modules by pattern
 % perl -Mlib::filter=allow_noncore,0,allow_re,'^DateTime::.*' yourscript.pl

 # allow additional modules listed in a file
 % perl -Mlib::filter=allow_noncore,0,allow_list,'^DateTime::.*' yourscript.pl

 # allow additional modules found in some dirs
 % perl -Mlib::filter=allow_noncore,0,extra_path,'.:proj/lib' yourscript.pl


=head1 DESCRIPTION

This pragma installs a hook in C<@INC> to allow only some modules from being
found/loadable. This pragma is useful for testing, e.g. fatpacked script and is
more flexible than L<lib::none> and L<lib::core::only>.

lib::none is absolutely ruthless: your fatpacked script must fatpack everything
(including things like L<strict>, L<warnings>) as it empties C<@INC> and remove
the ability of perl to load any module.

lib::core::only only puts core paths in C<@INC> so your fatpacked script must
contain all non-core modules. But this is also too restrictive in some cases
because we cannot fatpack XS modules.

lib::filter makes it possible for you to, e.g. only allow core modules, plus
some other modules (like some XS modules).

To use this pragma:

 use lib::filter %opts;

Known options:

=over

=item * allow_core => bool (default: 1)

=item * allow_noncore => bool (default: 1)

=item * allow => str

Add a semicolon-separated list of modules to allow.

=item * allow_re => str

Allow modules matching regex pattern.

=item * allow_list => filename

Read a file containing list of modules to allow (one module per line).

=item * extra_inc => str

Add additional path to search modules in. String must be colon-separated paths.

=back


=head1 SEE ALSO

L<lib::none>

L<lib::core::only>

=cut
