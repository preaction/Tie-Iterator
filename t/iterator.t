
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Tie::Iterator qw( list imap igrep isort );

subtest 'while iterator' => sub {
    my $i = 0;
    my $iter = sub {
        return if $i > 5;
        return ++$i;
    };
    tie my @iter, 'Tie::Iterator', $iter;
    while ( my $x = shift @iter ) {
        diag "x: $x -> i: $i";
    }
    is $i, 6, 'iterator incremented';
};

subtest 'for iterator' => sub {
    my $i = 0;
    my $iter = sub {
        return if $i >= 50;
        return ++$i;
    };
    tie my @iter, 'Tie::Iterator', $iter;
    for my $x ( @iter ) {
        diag "x: $x -> i: $i";
    }
    is $i, 50, 'iterator incremented';
};

subtest 'infinite iterator' => sub {
    my $i = 0;
    my $iter = sub {
        return ++$i;
    };
    tie my @iter, 'Tie::Iterator', $iter;
    for my $x ( @iter ) {
        diag "x: $x -> i: $i";
        last if $x >= 6;
    }
    is $i, 6, 'iterator incremented';
};

subtest 'map iterator' => sub {
    local $TODO = 'Does not work';
    my $i = 0;
    my $iter = sub {
        return if $i >= 5;
        return ++$i;
    };
    tie my @iter, 'Tie::Iterator', $iter;
    my @x = imap { $_ * 2 } @iter;
    cmp_deeply \@x, [ 2, 4, 6, 8, 10 ];
};

subtest 'file iterator' => sub {
    my $i = 0;
    my $iter = sub {
        return if $i >= 5;
        return ++$i;
    };
    tie *foo, 'Tie::Iterator', $iter;
    while ( my $x = <foo> ) {
        diag "x: $x -> i: $i";
    }
    is $i, 5;
};

done_testing;
