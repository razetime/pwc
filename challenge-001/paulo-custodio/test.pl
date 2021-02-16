#!/usr/bin/perl

# run tests described in t/test-N.yaml

use strict;
use warnings;
use 5.030;
use Test::More;
use Path::Tiny;
use YAML::Tiny;

our $EXE = $^O =~ /MSWin32|msys/ ? ".exe" : "";

# hack so that output redirection works in msys
our $LUA = $^O eq "msys" ? "lua.exe" : "lua";

our %LANG = (
    ada     => 'adb',
    awk     => 'awk',
    basic   => 'bas',
    c       => 'c',
    cpp     => 'cpp',
    forth   => 'fs',
    lua     => 'lua',
    perl    => 'pl',
    python  => 'py',
);

# filter tests if languages given on command line
our %TESTS;
if (!@ARGV) {
    %TESTS = %LANG;
}
else {
    $TESTS{$_}=1 for @ARGV;
}

# to be used in eval{} in the tests
use vars qw( $prog $exec);

for my $lang (grep {-d} sort keys %LANG) {
    next unless $TESTS{$lang};
    for $prog (path($lang)->children(qr/\.$LANG{$lang}$/)) {
        $prog->basename =~ /^ch[-_](.*)\.$LANG{$lang}$/ or die $prog;
        my $task = $1;

        # compile if needed
        $exec = build($lang, $prog);

        for my $test (path("t")->children(qr/test-$task\.yaml$/)) {
            # execute each test from test-N.yaml
            my $yaml = YAML::Tiny->read($test);
            for my $doc (@$yaml) {
                for my $spec (@$doc) {
                    # run setup code
                    ok eval($spec->{setup}), $spec->{setup}
                        if defined($spec->{setup});
                    $@ and die $@;

                    # build test command line
                    my $cmd = "$exec ".value_or_eval($spec->{args});
                    chomp($cmd);

                    # input
                    if(defined($spec->{input})) {
                        path("in.txt")->spew(value_or_eval($spec->{input}));
                        $cmd .= " < in.txt";
                    }
                    if (defined($spec->{output})) {
                        $spec->{output} =~ s/^\|//mg;       # delete initial bar
                        path("out_exp.txt")->spew(value_or_eval($spec->{output}));
                        $cmd .= " > out.txt";
                    }

                    # run test
                    run($cmd);

                    # compare output
                    if (defined($spec->{output})) {
                        run("diff -w out_exp.txt out.txt");
                    }

                    # run cleaup code
                    if (Test::More->builder->is_passing) {
                        ok eval($spec->{cleanup}), $spec->{cleanup}
                            if defined($spec->{cleanup});
                        $@ and die $@;
                        unlink("in.txt", "out.txt", "out_exp.txt");
                    }
                    else {
                        die "tests failed\n";   # to give chance to examine output
                    }
                }
            }
        }
    }
}

done_testing;

# compile if needed, return executable line
sub build {
    my($lang, $prog) = @_;
    my $exe = ($prog =~ s/\.\w+/$EXE/r);
    my $prog_wo_ext = ($prog =~ s/\.\w+//r);
    my $prog_base = path($prog)->basename;
    for ($lang) {
        if (/ada/) {
            run("cd ada; gnatmake $prog_base"); # gnatmake builds only if needed
            return $exe;
        }
        if (/awk/) {
            return "gawk -f $prog --";
        }
        if (/basic/) {
            run("fbc $prog -o $prog_wo_ext") if (!-f $exe || -M $exe > -M $prog);
            return $exe;
        }
        if (/^c$/) {
            run("gcc $prog -o $prog_wo_ext") if (!-f $exe || -M $exe > -M $prog);
            return $exe;
        }
        if (/cpp/) {
            run("g++ $prog -o $prog_wo_ext") if (!-f $exe || -M $exe > -M $prog);
            return $exe;
        }
        if (/forth/) {
            return "gforth $prog";
        }
        if (/lua/) {
            return "$LUA $prog";
        }
        if (/perl/) {
            return "perl $prog";
        }
        if (/python/) {
            return "python $prog";
        }
        die "unsupported language $lang";
    }
}

sub run {
    my($cmd) = @_;
    ok 0==system($cmd), $cmd;
}

sub value_or_eval {
    my($str) = @_;
    $str //= "";
    my $value = ($str =~ /^eval\b/) ? eval($str) : $str;
    $@ and die "eval '$str' failed: $@";
    return $value;
}

1;
