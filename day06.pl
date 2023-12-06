#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/6/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# 'Time:      7  15   30
# Distance:  9  40  200';

sub sum { my $s = 0; foreach my $n (@_) { $s += $n } $s }
sub product { my $p = 1; foreach my $n (@_) { $p *= $n } $p }
sub min { (sort { $a <=> $b } @_)[0] }
sub max { (sort { $a <=> $b } @_)[-1] }
sub reduce (&$@) { my ($fun, $reduced, @values) = @_; for (@values) { $reduced = $fun->($reduced, $_) } $reduced }
sub pairs { map [ $_[$_*2], $_[$_*2+1] ], 0 .. int($#_ / 2) }
sub zip { map { $_[0][$_], $_[1][$_] } 0 .. $#{$_[0]} }

sub build_quadratic_equation { my ($a,$b,$c) = @_; return sub { $a * ($_[0] ** 2) + $_[0] * $b + $c } }
sub quadratic_formula { my ($n1,$n2,$n3) = @_; sort { $a <=> $b } (-$n2 + ($n2**2 - 4 * $n1 * $n3) ** 0.5) / (2*$n1), (-$n2 - ($n2**2 - 4 * $n1 * $n3) ** 0.5) / (2*$n1) }

my %times_to_distances = zip (map [ @$_[1 .. $#$_ ] ], map [ split /\s+/ ], split /\n/, $input);

say "solution to part 1:\n",
	product
	map scalar(@$_),
	map { my ($time, $low_root, $high_root) = @$_; [ grep { $_ > $low_root and $_ < $high_root } 0 .. $time ] }
	map [ $_, quadratic_formula(-1, $_, -$times_to_distances{$_}) ],
	sort { $a <=> $b }
	keys %times_to_distances;

my ($time, $distance) = map s/\s+//gr, map @$_[1 .. $#$_], map [ split /\s+/, $_, 2 ], split /\n/, $input;

say "solution to part 2:\n",
	product
	map scalar(@$_),
	map { my ($time, $low_root, $high_root) = @$_; [ grep { $_ > $low_root and $_ < $high_root } 0 .. $time ] }
	map [ $_, quadratic_formula(-1, $_, -$distance) ],
	sort { $a <=> $b }
	$time;

