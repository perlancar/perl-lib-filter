my %OLD_SIG;
BEGIN {
    # Test::Builder will load these modules, we preload them here to avoid false
    # positives/negatives
    require overload;
    require List::Util;
}

use File::Temp qw(tempfile);
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

1;
