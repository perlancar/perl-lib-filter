#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
BEGIN { require "testlib.pl" };
use lib::disallow ();

test_lib_disallow(
    name => "basics",
    args => ['Exporter'],
    require_nok => ["Exporter"],
    require_ok => ["utf8"],
);

done_testing;
