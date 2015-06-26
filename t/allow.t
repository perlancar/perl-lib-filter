#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
BEGIN { require "testlib.pl" };
use lib::allow ();

test_lib_allow(
    name => "basics",
    args => ["Foo"],
    extra_libs => ["$Bin/lib"],
    require_ok => ["Foo"],
    require_nok => ["Bar"],
);

done_testing;
