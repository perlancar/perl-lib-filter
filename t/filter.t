#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
BEGIN { require "testlib.pl" };

test_lib_filter(
    name => 'disallow',
    args => ["disallow", "Foo;Bar"],
    extra_libs => ["$Bin/lib"],
    require_nok => ["Foo", "Bar"],
    require_ok  => ["Baz"],
);

test_lib_filter(
    name => 'disallow_re',
    args => ['disallow_re', 'Ba.'],
    extra_libs => ["$Bin/lib"],
    require_nok => ["Bar", "Baz"],
    require_ok => ["Foo"],
);

{
    my ($fh, $filename) = tempfile();
    print $fh "Foo\nBaz\n";
    close $fh;

    test_lib_filter(
        name => 'disallow_list',
        args => ['disallow_list' => $filename],
        extra_libs => ["$Bin/lib"],
        require_nok => ["Foo", "Baz"],
        require_ok => ["Bar"],
    );
}

test_lib_filter(
    name => 'allow',
    args => [allow_core=>0, allow_noncore=>0, allow=>'Foo'],
    extra_libs => ["$Bin/lib"],
    require_ok => ["Foo"],
    require_nok => ["Bar", "Baz"],
);

test_lib_filter(
    name => 'allow_re',
    args => [allow_core=>0, allow_noncore=>0, allow_re => 'Ba.'],
    extra_libs => ["$Bin/lib"],
    require_ok => ["Bar", "Baz"],
    require_nok => ["Foo"],
);

{
    my ($fh, $filename) = tempfile();
    print $fh "Foo\nBar\n";
    close $fh;

    test_lib_filter(
        name => 'allow_list',
        args => [allow_core=>0, allow_noncore=>0, allow_list=>$filename],
        extra_libs => ["$Bin/lib"],
        require_ok => ["Foo", "Bar"],
        require_nok => ["Baz"],
    );
}

test_lib_filter(
    name => "allow_core=0",
    extra_libs => ["$Bin/lib"],
    args => [allow_core=>0],

    # XXX we need to select modules which are only available in core dir and not
    # in non-core dir

    # require_nok => ["Exporter"],

    require_ok => ["Foo"],
);

test_lib_filter(
    name => "allow_noncore=0",
    args => [allow_noncore=>0],
    extra_libs => ["$Bin/lib"],
    require_ok => ["Exporter"], # core
    require_nok => ["Foo"],
);

test_lib_filter(
    name => "ordering (disallow before allow)",
    args => [allow => 'Foo', disallow=>'Foo'],
    extra_libs => ["$Bin/lib"],
    require_nok => ["Foo"],
);

# XXX more ordering tests

done_testing;
