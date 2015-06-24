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
    args => ["Exporter"],
    require_ok => ["Exporter"],
    require_nok => ["utf8"],
);

done_testing;
