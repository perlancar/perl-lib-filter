use File::Temp qw(tempfile);
use IPC::System::Options qw(system);
use Test::Exception;
use Test::More 0.98;

sub _test_lib {
    my $which = shift;
    my %args = @_;

    my $name = $args{name} || "args: " . join(" ", @{$args{args}});
    subtest $name => sub {
        for my $ent (
            (map {+{module=>$_, ok=>1}} @{$args{require_ok} || []}),
            (map {+{module=>$_, ok=>0}} @{$args{require_nok} || []}),
        ) {
            my @system_args = (
                $^X,
                (map {"-I$_"} @{ $args{extra_libs} || []}),
                "-Mlib::$which". (@{$args{args}} ? "=".
                                      join(",",@{$args{args}}):""),
                "-e",
                "use $ent->{module}",
            );
            note "system: ", explain @system_args;
            system({shell=>0, log=>1}, @system_args);
            my $child_err = $?;
            if ($ent->{ok}) {
                ok(!$child_err, "require $ent->{module} ok")
                    or diag "child_err=$child_err";
            } else {
                ok( $child_err, "require $ent->{module} nok");
            }
        }
    };
}

sub test_lib_filter {
    _test_lib('filter', @_);
}

sub test_lib_allow {
    _test_lib('allow', @_);
}

sub test_lib_disallow {
    _test_lib('disallow', @_);
}

1;
