#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/4/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# 'Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
# Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
# Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
# Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
# Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
# Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11';

sub sum { my $s = 0; foreach my $n (@_) { $s += $n } $s }
sub product { my $p = 1; foreach my $n (@_) { $p *= $n } $p }
sub min { (sort { $a <=> $b } @_)[0] }
sub max { (sort { $a <=> $b } @_)[-1] }


say "solution part 1:\n",
	sum
	map 2 ** (@$_ - 1),
	grep @$_,
	map {
		my ($w, $h) = @$_;
		[ grep exists $w->{$_}, keys %$h ]
	}
	map [ map { { map { $_ => 1 } sort grep /\d/, split /\s+/, $_ } } split /\|/ ],
	map s/Card \d+: //gr,
	split /\n/,
	$input;


my %wintable =
	map {
		my ($c, $w, $h) = @$_;
		$c => scalar(grep exists $w->{$_}, keys %$h)
	}
	map [ $_->[0], map { { map { $_ => 1 } sort grep /\d/, split /\s+/, $_ } } split /\|/, $_->[1] ],
	map [ /\ACard\s+(\d+): (.*)/g ],
	split /\n/,
	$input;
my %card_count = map { $_ => 1 } keys %wintable;

for my $i (1 .. keys %wintable) {
	for my $n (1 .. $wintable{$i}) {
		$card_count{$i + $n} += $card_count{$i};
	}
}

say "solution part 2:\n", sum values %card_count;


