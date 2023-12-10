#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say state /;

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/9/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# '0 3 6 9 12 15
# 1 3 6 10 15 21
# 10 13 16 21 30 45';

sub sum { my $s = 0; foreach my $n (@_) { $s += $n } $s }
sub product { my $p = 1; foreach my $n (@_) { $p *= $n } $p }
sub min { (sort { $a <=> $b } @_)[0] }
sub max { (sort { $a <=> $b } @_)[-1] }
sub reduce (&$@) { my ($fun, $reduced, @values) = @_; for (@values) { $reduced = $fun->($reduced, $_) } $reduced }
sub pairs { map [ $_[$_*2], $_[$_*2+1] ], 0 .. int($#_ / 2) }
sub zip { map { $_[0][$_], $_[1][$_] } 0 .. $#{$_[0]} }
sub indexed_map (&@) { my ($fun, @args) = @_; map $fun->($_, $args[$_]), 0 .. $#args }
sub reduce_until (&@) { my ($fun, @args) = @_; my $res; until ($res) { foreach (@args) { $res = $fun->($_); last if $res; } } }
sub all (&@) { my ($fun, @args) = @_; foreach (@args) { return 0 unless $fun->() } return 1 }
sub rolling (&@) { my ($fun, @args) = @_; return map $fun->($args[$_], $args[$_+1]), 0 .. $#args-1 }
sub rolling_delta { return rolling { $_[1] - $_[0] } @_ }
sub rolling_acc { my $sum = 0; return map { $sum += $_ } @_ }


sub equation_ranks {
	my @eq = @_;
	my @ranks;

	until (all { $_ == 0 } @eq) {
		push @ranks, [ @eq ];
		@eq = rolling_delta @eq;
	}
	push @ranks, [ @eq ];

	return @ranks;
}

sub step_ranks {
	my @ranks = @_;
	push @{$ranks[-1]}, 0;
	foreach my $i (reverse 0 .. $#ranks-1) {
		push @{$ranks[$i]}, $ranks[$i][-1] + $ranks[$i+1][-1];
	}
	return @ranks;
}


sub back_step_ranks {
	my @ranks = @_;
	unshift @{$ranks[-1]}, 0;
	foreach my $i (reverse 0 .. $#ranks-1) {
		unshift @{$ranks[$i]}, $ranks[$i][0] - $ranks[$i+1][0];
	}
	return @ranks;
}

say "solution to part 1:\n",
	sum
	map {
		my @eq = split ' ', $_;
		my @ranks = equation_ranks @eq;
		@ranks = step_ranks @ranks;
		# say "ranks:";
		# say join ',', @$_ foreach @ranks;
		$ranks[0][-1]
	}
	split /\n/,
	$input;

say "solution to part 2:\n",
	sum
	map {
		my @eq = split ' ', $_;
		my @ranks = equation_ranks @eq;
		@ranks = back_step_ranks @ranks;
		# say "ranks:";
		# say join ',', @$_ foreach @ranks;
		$ranks[0][0]
	}
	split /\n/,
	$input;

