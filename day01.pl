#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/1/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# '1abc2
# pqr3stu8vwx
# a1b2c3d4e5f
# treb7uchet';
# my $input =
# 'two1nine
# eightwothree
# abcone2threexyz
# xtwone3four
# 4nineeightseven2
# zoneight234
# 7pqrstsixteen';

sub sum { my $s = 0; foreach (@_) { $s += $_ } $s }

say "solution part 1: ",
	sum
	map s/\A(\d)\Z/$1$1/gr,
	map s/\A(\d)\d+(\d)\Z/$1$2/gr,
	map s/[^\d]//gr,
	split /\n/, $input;

my %words = (
	zero => '0',
	one => '1',
	two => '2',
	three => '3',
	four => '4',
	five => '5',
	six => '6',
	seven => '7',
	eight => '8',
	nine => '9',
);

say "solution part 2: ",
	sum
	map s/\A(\d)\Z/$1$1/gr,
	map s/\A(\d)\d+(\d)\Z/$1$2/gr,
	map s/[^\d]//gr,
	map s/(one|two|three|four|five|six|seven|eight|nine)/$words{$1}/gr,
	map s/eigh(two|three)/eight$1/gr,
	map s/twone/twoone/gr,
	map s/(one|three|five|nine)ight/$1eight/gr,
	split /\n/, $input;




