#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/7/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# '32T3K 765
# T55J5 684
# KK677 28
# KTJJT 220
# QQQJA 483';

sub sum { my $s = 0; foreach my $n (@_) { $s += $n } $s }
sub product { my $p = 1; foreach my $n (@_) { $p *= $n } $p }
sub min { (sort { $a <=> $b } @_)[0] }
sub max { (sort { $a <=> $b } @_)[-1] }
sub reduce (&$@) { my ($fun, $reduced, @values) = @_; for (@values) { $reduced = $fun->($reduced, $_) } $reduced }
sub pairs { map [ $_[$_*2], $_[$_*2+1] ], 0 .. int($#_ / 2) }
sub zip { map { $_[0][$_], $_[1][$_] } 0 .. $#{$_[0]} }
sub indexed_map (&@) { my ($fun, @args) = @_; map $fun->($_, $args[$_]), 0 .. $#args }


sub rate_hand {
	my $hand = join '', sort split '', $_[0];
	return 6 if $hand =~ /(.)\1\1\1\1/;
	return 5 if $hand =~ /(.)\1\1\1/;
	return 4 if $hand =~ /(.)\1\1(.)\2|(.)\3(.)\4\4/;
	return 3 if $hand =~ /(.)\1\1/;
	return 2 if $hand =~ /(.)\1.?(.)\2/;
	return 1 if $hand =~ /(.)\1/;
	return 0;
}

sub order_hand { $_[0] =~ y/AKQJT/FEDCB/r }

sub compare_hands {
	my ($left, $right) = @_;
	if (rate_hand($left) != rate_hand($right)) {
		return rate_hand($left) <=> rate_hand($right);
	} else {
		return order_hand($left) cmp order_hand($right);
	}
}

say "solution to part 1:\n",
	sum
	indexed_map { ($_[0] + 1) * (split ' ', $_[1])[1] }
	sort { compare_hands((split ' ', $a)[0], (split ' ', $b)[0]) }
	split /\n/,
	$input;


sub order_hand_joker { $_[0] =~ y/AKQJT/FED0B/r }

sub rate_hand_joker {
	my $hand = join '', grep $_ ne '0', sort split '', order_hand_joker($_[0]);
	my $j = length join '', grep $_ eq '0', split '', order_hand_joker($_[0]);
	if ($j == 5 or $j == 4) {
		return 6;
	} elsif ($j == 3) {
		return 6 if $hand =~ /(.)\1/;
		return 5;
	} elsif ($j == 2) {
		return 6 if $hand =~ /(.)\1\1/;
		return 5 if $hand =~ /(.)\1/;
		return 3;
	} elsif ($j == 1) {
		return 6 if $hand =~ /(.)\1\1\1/;
		return 5 if $hand =~ /(.)\1\1/;
		return 4 if $hand =~ /(.)\1(.)\2/;
		return 3 if $hand =~ /(.)\1/;
		return 1;
	} else {
		return rate_hand($_[0]);
	}
}

sub compare_hands_joker {
	my ($left, $right) = @_;
	if (rate_hand_joker($left) != rate_hand_joker($right)) {
		return rate_hand_joker($left) <=> rate_hand_joker($right);
	} else {
		return order_hand_joker($left) cmp order_hand_joker($right);
	}
}

say "solution to part 2:\n",
	sum
	indexed_map { ($_[0] + 1) * (split ' ', $_[1])[1] }
	sort { compare_hands_joker((split ' ', $a)[0], (split ' ', $b)[0]) }
	split /\n/,
	$input;

