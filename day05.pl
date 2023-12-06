#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/5/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

sub sum { my $s = 0; foreach my $n (@_) { $s += $n } $s }
sub product { my $p = 1; foreach my $n (@_) { $p *= $n } $p }
sub min { (sort { $a <=> $b } @_)[0] }
sub max { (sort { $a <=> $b } @_)[-1] }
sub reduce (&$@) { my ($fun, $reduced, @values) = @_; for (@values) { $reduced = $fun->($reduced, $_) } $reduced }
sub pairs { map [ $_[$_*2], $_[$_*2+1] ], 0 .. int($#_ / 2) }

sub wide_kernel_3 (&@) {
	my ($fun, @arr) = @_;
	my @inp = (undef, @arr, undef);
	my @res;

	for my $x (0 .. $#inp-2) {
		push @res, $fun->($inp[$x], $inp[$x+1], $inp[$x+2]);
	}

	return @res;
}

my ($seed_list, @seed_maps) = split /\n\n/, $input;
die  "error: $seed_list" unless $seed_list =~ /\Aseeds: (\d+(?:\s+\d+)*)\Z/;
my @seeds = split /\s+/, $1;

say "solution part 1:\n",
	min
	map @$_,
	reduce {
		my ($current_seeds, $seed_mapper) = @_;
		[ map {
				my $seed = $_;
				reduce { $_[0] - $_[1][0] + $_[1][2] } $seed,
					grep { $_->[0] <= $seed and $_->[1] >= $seed }
					@$seed_mapper;
			} @$current_seeds ]
	} \@seeds,
	map {
		die "error: $_" unless /\A\S+ map:\n(.*)\Z/s;
		[
			map { die "error: $_" unless /\A(\d+) (\d+) (\d+)\Z/; [ $2, $2+$3-1, $1, $1+$3-1 ] }
			split /\n/, $1 ];
	}
	@seed_maps;


my @seeds_ranges = map { [ $_->[0], $_->[0] + $_->[1] - 1 ] } pairs @seeds;

say "solution part 2:\n",
	min
	map @$_,
	map @$_,
	reduce {
		my ($current_seeds_ranges, $seed_mapper) = @_;
		my $mapped = [ map {
				my $seed_range = $_;
				my $seeds_mapped = [
					wide_kernel_3 {
						my ($a,$b,$c) = @_;
						my @mapped_ranges;
						if (not defined $a and $b->[0] > $seed_range->[0]) {
							push @mapped_ranges, [ $seed_range->[0], $b->[0] ];
						}

						push @mapped_ranges, [ max($seed_range->[0], $b->[0]) - $b->[0] + $b->[2], min($seed_range->[1], $b->[1]) - $b->[0] + $b->[2] ];

						if (defined $c and $b->[1] < $c->[0] - 1) {
							push @mapped_ranges, [ $b->[1]+1, $c->[0]-1 ];
						} elsif (not defined $c and $b->[1] < $seed_range->[1]) {
							push @mapped_ranges, [ $b->[1]+1, $seed_range->[1] ];
						}
						@mapped_ranges
					}
					sort { $a->[0] <=> $b->[0] }
					grep { $_->[0] <= $seed_range->[1] and $_->[1] >= $seed_range->[0] }
					@$seed_mapper ];

				if (@$seeds_mapped < 1) {
					push @$seeds_mapped, $seed_range;
				}
				@$seeds_mapped
			} @$current_seeds_ranges ];
		$mapped
	} \@seeds_ranges,
	map {
		die "error: $_" unless /\A\S+ map:\n(.*)\Z/s;
		[
			map { die "error: $_" unless /\A(\d+) (\d+) (\d+)\Z/; [ $2, $2+$3-1, $1, $1+$3-1 ] }
			split /\n/, $1 ];
	}
	@seed_maps;


