#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";
BEGIN { require "testlib.pl" };
use lib::allow ();

subtest "basics" => sub {
    lib::allow->import('List::Util');
    test_require_ok "List::Util";
    test_require_nok "strict";
    lib::allow->unimport;
};

done_testing;
