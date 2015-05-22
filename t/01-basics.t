#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

require lib::filter;

subtest "disallow" => sub {
    lib::filter->import(disallow => 'IPC::Cmd;List::Util');
    dies_ok  { require IPC::Cmd };
    dies_ok  { require List::Util };
    lives_ok { require IO::Socket };
    lib::filter->unimport;
};

# XXX test allow_core
# XXX test allow_noncore
# XXX test allow
# XXX test allow_re
# XXX test allow_list
# XXX test disallow_re
# XXX test disallow_list

done_testing;
