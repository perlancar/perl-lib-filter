my %OLD_SIG;
BEGIN {
    # Test::Builder will load these modules, we preload them here to avoid false
    # positives/negatives
    require overload;
    require List::Util;

    # a very simple, no-modules-required version of Carp::Always/Devel::Confess,
    # to help debug problems when getting test failure reports
    @OLD_SIG{qw/__DIE__ __WARN__/} = @SIG{qw/__DIE__ __WARN__/};
    my $longmess = sub {
        my $i = 0;
        while (my @caller = caller($i)) {
            if ($i == 0) { print $_[0] }
            print " $caller[3] called" if $caller[3];
            print " at $caller[1] line $caller[2]\n";
            $i++;
        }
    };
    $SIG{__DIE__}  = sub { die &$longmess };
    $SIG{__WARN__} = sub { warn &$longmess };
}

END {
    @SIG{qw/__DIE__ __WARN__/} = @OLD_SIG{qw/__DIE__ __WARN__/};
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
