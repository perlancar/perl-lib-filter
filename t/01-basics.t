#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

sub test_require_ok {
    my $mod = shift;
    my $mod_pm = do { local $_ = $mod; s!::!/!g; "$_.pm" };
    local %INC = %INC;
    delete $INC{$mod_pm};
    lives_ok { require $mod_pm };
}

sub test_require_nok {
    my $mod = shift;
    my $mod_pm = do { local $_ = $mod; s!::!/!g; "$_.pm" };
    local %INC = %INC;
    delete $INC{$mod_pm};
    dies_ok { require $mod_pm };
}

require lib::filter;

subtest "disallow" => sub {
    lib::filter->import(disallow => 'IPC::Cmd;List::Util');
    test_require_nok "IPC::Cmd";
    test_require_nok "List::Util";
    test_require_ok  "IO::Socket";
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
