#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/2/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# 'Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
# Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
# Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
# Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
# Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green';

sub sum { my $s = 0; foreach my $n (@_) { $s += $n } $s }
sub product { my $p = 1; foreach my $n (@_) { $p *= $n } $p }
sub min { (sort { $a <=> $b } @_)[0] }
sub max { (sort { $a <=> $b } @_)[-1] }

my %limits = (
	red => 12,
	green => 13,
	blue => 14,
);

say "solution part 1:\n",
	sum
	map s/\AGame (\d+):.*\Z/$1/r,
	grep $_ !~ /impossible/,
	map s/(\d+) (\w+)/$limits{$2} < $1 ? 'impossible' : 'possible'/ger,
	split /\n/, $input;

say "solution part 2:\n",
	sum
	map {
		product
			max (/\d+(?= red)/g),
			max (/\d+(?= green)/g),
			max (/\d+(?= blue)/g),
	}
	split /\n/, $input;





