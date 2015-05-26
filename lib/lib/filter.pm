package lib::filter;

# DATE
# VERSION

#use 5.010001;
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

my $hook;
my $orig_inc;

sub import {
    my ($class, %opts) = @_;

    $opts{allow_core}    = 1 if !defined($opts{allow_core});
    $opts{allow_noncore} = 1 if !defined($opts{allow_noncore});

    if ($opts{extra_inc}) {
        unshift @INC, split(/:/, $opts{extra_inc});
    }

    $orig_inc ||= [@INC];

    my $core_inc = [@Config{qw(privlibexp archlibexp)}];
    my $noncore_inc = [grep {$_ ne $Config{privlibexp} &&
                                 $_ ne $Config{archlibexp}} @$orig_inc];
    my %allow;
    if ($opts{allow}) {
        for (split /\s*;\s*/, $opts{allow}) {
            $allow{$_} = "allow";
        }
    }
    if ($opts{allow_list}) {
        open my($fh), "<", $opts{allow_list}
            or die "Can't open allow_list file '$opts{allow_list}': $!";
        while (my $line = <$fh>) {
            $line =~ s/^\s+//;
            $line =~ /^(\w+(?:::\w+)*)/ or next;
            $allow{$1} ||= "allow_list";
        }
    }

    my %disallow;
    if ($opts{disallow}) {
        for (split /\s*;\s*/, $opts{disallow}) {
            $disallow{$_} = "disallow";
        }
    }
    if ($opts{disallow_list}) {
        open my($fh), "<", $opts{disallow_list}
            or die "Can't open disallow_list file '$opts{disallow_list}': $!";
        while (my $line = <$fh>) {
            $line =~ s/^\s+//;
            $line =~ /^(\w+(?:::\w+)*)/ or next;
            $disallow{$1} ||= "disallow_list";
        }
    }

    $hook = sub {
        my ($self, $file) = @_;

        my $path;
      FILTER:
        {
            my $mod = $file; $mod =~ s/\.pm$//; $mod =~ s!/!::!g;
            if ($opts{disallow_re} && $mod =~ /$opts{disallow_re}/) {
                die "Module '$mod' is disallowed (disallow_re)";
            }
            if ($disallow{$mod}) {
                die "Module '$mod' is disallowed ($disallow{$mod})";
            }
            if ($opts{allow_re} && $mod =~ /$opts{allow_re}/) {
                $path = module_path($file, $orig_inc);
                last FILTER if $path;
                die "Module '$mod' is allowed (allow_re) but can't locate $file in \@INC (\@INC contains: ".join(" ", @INC);
            }
            if ($allow{$mod}) {
                $path = module_path($file, $orig_inc);
                last FILTER if $path;
                die "Module '$mod' is allowed ($allow{$mod}) but can't locate $file in \@INC (\@INC contains: ".join(" ", @INC);
            }

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
            my $mod = $_;
            if ("$mod" eq "$hook") {
                0;
            } elsif ($opts{allow_core} && grep {$mod eq $_} @$core_inc) {
                1;
            } elsif ($opts{allow_noncore} && grep {$mod eq $_} @$noncore_inc) {
                1;
            } else {
                0;
            }
        } @$orig_inc,
    );
    #use DD; dd $orig_inc;
    #use DD; dd \@INC;
}

sub unimport {
    return unless $hook;
    @INC = grep { "$_" ne "$hook" } @INC;
}

1;
# ABSTRACT: Only allow some specified modules to be locateable/loadable

=for Pod::Coverage .+

=head1 SYNOPSIS

 # equivalent to -Mlib::none
 % perl -Mlib::filter=allow_core,0,allow_noncore,0 yourscript.pl

 # equivalent to -Mlib::core::only
 % perl -Mlib::filter=allow_noncore,0 yourscript.pl

 # only allow a specific set of modules
 % perl -Mlib::filter=allow_core,0,allow_noncore,0,allow,'strict;warnings;List::Util' yourscript.pl

 # allow core modules plus some more modules
 % perl -Mlib::filter=allow_noncore,0,allow,'List::MoreUtils;List::MoreUtils::PP;List::MoreUtils::XS' yourscript.pl

 # allow core modules plus additional modules by pattern
 % perl -Mlib::filter=allow_noncore,0,allow_re,'^DateTime::.*' yourscript.pl

 # allow core modules plus additional modules listed in a file
 % perl -Mlib::filter=allow_noncore,0,allow_list,'/tmp/allow.txt' yourscript.pl

 # allow core modules plus additional modules found in some dirs
 % perl -Mlib::filter=allow_noncore,0,extra_path,'.:proj/lib' yourscript.pl

 # disallow some modules (for testing/simulating the non-availability of a
 # module, pretending that a module does not exist)
 % perl -Mlib::filter=disallow,'YAML::XS,JSON::XS' yourscript.pl

 # idem, but the list of disallowed modules are retrieved from a file
 % perl -Mlib::filter=disallow_list,/tmp/disallow.txt yourscript.pl


=head1 DESCRIPTION

This pragma installs a hook in C<@INC> to allow only some modules from being
found/loadable. This pragma is useful for testing, e.g. fatpacked script and is
more flexible than L<lib::none> and L<lib::core::only>.

lib::none is absolutely ruthless: your fatpacked script must fatpack all modules
(including things like L<strict>, L<warnings>) as lib::none empties C<@INC> and
removes perl's ability to load any more modules.

lib::core::only only puts core paths in C<@INC> so your fatpacked script must
contain all non-core modules. But this is also too restrictive in some cases
because we cannot fatpack XS modules and want to let the script load those from
filesystem.

lib::filter makes it possible for you to, e.g. only allow core modules, plus
some other modules (like some XS modules).

To use this pragma:

 use lib::filter %opts;

Known options:

=over

=item * disallow => str

Add a semicolon-separated list of modules to disallow.

=item * disallow_re => str

Add modules matching regex pattern to disallow.

=item * disallow_list => filename

Read a file containing list of modules to disallow (one module per line).

=item * allow => str

Add a semicolon-separated list of module names to allow.

=item * allow_re => str

Allow modules matching regex pattern.

=item * allow_list => filename

Read a file containing list of modules to allow (one module per line).

=item * allow_core => bool (default: 1)

Allow core modules.

=item * allow_noncore => bool (default: 1)

Allow non-core modules.

=item * extra_inc => str

Add additional path to search modules in. String must be colon-separated paths.

=back

How a module is filtered: first, it is checked against the
disallow/disallow_re/disallow_list. If it matches one of those options then the
module is disallowed. Otherwise it is checked against the
allow/allow_re/allow_list. If it matches one of those options and the module's
path is found in the directories in @INC, then the module is allowed. Finally,
allow_core/allow_noncore is checked. When allow_core is set to false, core
directories are excluded. Likewise, when allow_noncore is set to false, non-core
directories are excluded.


=head1 SEE ALSO

L<lib::none>

L<lib::core::only>

=cut
