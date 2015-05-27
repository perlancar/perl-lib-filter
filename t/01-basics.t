#!perl

use 5.010;
use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::Exception;
use Test::More 0.98;
use FindBin '$Bin';
use lib "$Bin/lib";
use lib::filter ();

# Test::Builder will load these modules, we preload them here to avoid false
# positives/negatives
{
    require overload;
    require List::Util;
}

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

subtest "disallow" => sub {
    lib::filter->import(disallow => 'IPC::Cmd;List::Util');
    test_require_nok "IPC::Cmd";
    test_require_nok "List::Util";
    test_require_ok  "IO::Socket";
    lib::filter->unimport;
};

subtest "disallow_re" => sub {
    lib::filter->import(disallow_re => 'File::.+');
    test_require_nok "File::Copy";
    test_require_nok "File::Find";
    lib::filter->unimport;
};

subtest "disallow_list" => sub {
    my ($fh, $filename) = tempfile();
    print $fh "File::Copy\nFile::Find\n";
    close $fh;
    lib::filter->import(disallow_list => $filename);
    test_require_nok "File::Find";
    test_require_nok "File::Copy";
    lib::filter->unimport;
};

subtest "allow" => sub {
    lib::filter->import(allow_core=>0, allow_noncore=>0, allow => 'Benchmark;Scalar::Util');
    test_require_ok "Scalar::Util";
    test_require_ok "Benchmark";
    test_require_nok "IO::Socket";
    lib::filter->unimport;
};

subtest "allow_re" => sub {
    lib::filter->import(allow_core=>0, allow_noncore=>0, allow_re => 'Bench|Scalar');
    test_require_ok "Scalar::Util";
    test_require_ok "Benchmark";
    test_require_nok "IO::Socket";
    lib::filter->unimport;
};

subtest "allow_list" => sub {
    my ($fh, $filename) = tempfile();
    print $fh "Benchmark\nScalar::Util\n";
    close $fh;
    lib::filter->import(allow_core=>0, allow_noncore=>0, allow_list => $filename);
    test_require_ok "Scalar::Util";
    test_require_ok "Benchmark";
    test_require_nok "IO::Socket";
    lib::filter->unimport;
};

subtest "allow_core=0" => sub {
    lib::filter->import(allow_core=>0);
    # TODO we need to select modules which are only available in core dir
    # test_require_nok "Scalar::Util";
    test_require_ok  "Foo";
    lib::filter->unimport;
};

subtest "allow_noncore=0" => sub {
    lib::filter->import(allow_noncore=>0);
    test_require_ok  "Scalar::Util";
    test_require_nok "Foo";
    lib::filter->unimport;
};

subtest "ordering" => sub {
    # disallow before allow
    lib::filter->import(allow => 'Benchmark', disallow=>'Benchmark');
    test_require_nok "Benchmark";
    lib::filter->unimport;

    # XXX more tests
};

done_testing;
