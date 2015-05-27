#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
BEGIN { require "testlib.pl" };
use lib::disallow ();

subtest "basics" => sub {
    lib::disallow->import('List::Util');
    test_require_nok "List::Util";
    test_require_ok  "strict";
    lib::disallow->unimport;
};

done_testing;
