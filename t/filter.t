#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
BEGIN { require "testlib.pl" };

test_lib_filter(
    name => 'disallow',
    args => ["disallow", "IPC::Cmd;List::Util"],
    require_nok => ["IPC::Cmd", "List::Util"],
    require_ok  => ["IO::Socket"], # core
);

test_lib_filter(
    name => 'disallow_re',
    args => ['disallow_re', 'File::.+'],
    require_nok => ["File::Copy", "File::Find"], # core
    require_ok => ["IO::Socket"], # core
);

{
    my ($fh, $filename) = tempfile();
    print $fh "File::Copy\nFile::Find\n";
    close $fh;

    test_lib_filter(
        name => 'disallow_list',
        args => ['disallow_list' => $filename],
        require_nok => ["File::Find", "File::Copy"], # core
        require_ok => ["IO::Socket"], # core
    );
}

test_lib_filter(
    name => 'allow',
    # let's allow Scalar::Util and the modules it uses
    args => [allow_core=>0, allow_noncore=>0, allow=>'Scalar::Util;Exporter;List::Util;XSLoader'],
    require_ok => ["Scalar::Util"],
    require_nok => ["IO::Socket"], # core
);

test_lib_filter(
    name => 'allow_re',
    # let's allow Scalar::Util and the modules it uses, via regex
    args => [allow_core=>0, allow_noncore=>0, allow_re => '::Util|Exporter|XS'],
    require_ok => ["Scalar::Util"],
    require_nok => ["IO::Socket"], # core
);

{
    my ($fh, $filename) = tempfile();
    print $fh "Scalar::Util\nExporter\nList::Util\nXSLoader\n";
    close $fh;

    test_lib_filter(
        name => 'allow_list',
        args => [allow_core=>0, allow_noncore=>0, allow_list=>$filename],
        require_ok => ["Scalar::Util"],
        require_nok => ["IO::Socket"], # core
    );
}

test_lib_filter(
    name => "allow_core=0",
    extra_libs => ["$Bin/lib"],
    args => [allow_core=>0],

    # XXX we need to select modules which are only available in core dir and not
    # in non-core dir

    # require_nok => ["Scalar::Util"],

    require_ok => ["Foo"],
);

test_lib_filter(
    name => "allow_noncore=0",
    args => [allow_noncore=>0],
    extra_libs => ["$Bin/lib"],
    require_ok => ["Scalar::Util"],
    require_nok => ["Foo"],
);

test_lib_filter(
    name => "ordering (disallow before allow)",
    args => [allow => 'Exporter', disallow=>'Exporter'],
    require_nok => ["Exporter"],
);

# XXX more ordering tests

done_testing;
