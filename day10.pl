#!/usr/bin/env perl
use strict;
use warnings;

use feature qw/ say state /;

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/10/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# '7-F7-
# .FJ|7
# SJLL7
# |F--J
# LJ.LJ';
# my $input =
# '.F----7F7F7F7F-7....
# .|F--7||||||||FJ....
# .||.FJ||||||||L7....
# FJL7L7LJLJ||LJ.L-7..
# L--J.L7...LJS7F-7L7.
# ....F-J..F7FJ|L7L7L7
# ....L7.F7||L7|.L7L7|
# .....|FJLJ|FJ|F7|.LJ
# ....FJL-7.||.||||...
# ....L---J.LJ.LJLJ...';
# my $input =
# 'FF7FSF7F7F7F7F7F---7
# L|LJ||||||||||||F--J
# FL-7LJLJ||||||LJL-77
# F--JF--7||LJLJ7F7FJ-
# L---JF-JLJ.||-FJLJJ7
# |F|F-JF---7F7-L7L|7|
# |FFJF7L7F-JF7|JL---7
# 7-L-JL7||F7|L7F-7F7|
# L.L7LFJ|||||FJL7||LJ
# L7JLJL-JLJLJL--JLJ.L';

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


sub tensor_data_2d ($) { return [ map [ split '' ], split /\n/, $_[0] ] }
sub tensor_data_3d ($) { return [ map [ map [ $_ ], split '' ], split /\n/, $_[0] ] }
sub untensor_data_2d { return join "\n", map { join '', @{$_} } @{$_[0]} }
sub tensor_flatten { return ($_[0] > 0 and ref $_[1] eq 'ARRAY') ? map tensor_flatten($_[0]-1, $_), @{$_[1]} : $_[1] }



sub tensor_positions ($) {
	my ($tensor) = @_;
	my @res;

	for my $y (0 .. $#$tensor) {
		for my $x (0 .. $#{$tensor->[0]}) {
			$res[$y][$x] = [ [$x,$y] ];
		}
	}

	return \@res;
}

sub tensor_stack (@) {
	my (@tensors) = @_;
	my $first = $tensors[0];
	my @res;

	for my $y (0 .. $#$first) {
		for my $x (0 .. $#{$first->[0]}) {
			$res[$y][$x] = [ map @{$_->[$y][$x]}, @tensors ];
		}
	}

	return \@res;
}
sub tensor_self_stack_orthagonal ($) {
	my ($tensor) = @_;
	my @res;
	my @offsets = ([0,0],[1,0],[0,1],[-1,0],[0,-1]);
	for my $y (0 .. $#$tensor) {
		for my $x (0 .. $#{$tensor->[0]}) {
			$res[$y][$x] = [ map @{ ($y+$_->[1] >= 0 and $x+$_->[0] >= 0) ? ($tensor->[$y+$_->[1]][$x+$_->[0]] // [ undef ]) : [ undef ] }, @offsets ];
		}
	}

	return \@res;
}

sub tensor_stack_position ($) { tensor_stack tensor_positions $_[0], $_[0] }

sub kernel_1x1 (&$) {
	my ($fun, $arr) = @_;
	my @inp = map [ @$_ ], @$arr;
	my @res = map [], @$arr;

	for my $y (0 .. $#inp) {
		for my $x (0 .. $#{$inp[0]}) {
			$res[$y][$x] = $fun->($inp[$y][$x]);
		}
	}

	return [ map [ @{$_}[0 .. $#$_] ], @res[0 .. $#res] ];
}

sub collapse_kernel_1x1 (&$) {
	my ($grepper, $arr) = @_;
	my @inp = map [ @$_ ], @$arr;
	my @res;

	for my $y (0 .. $#inp) {
		for my $x (0 .. $#{$inp[0]}) {
			push @res, $grepper->($inp[$y][$x]);
		}
	}

	return @res;
}

my ($start_x, $start_y) = @{(
	collapse_kernel_1x1 { $_[0][1] eq 'S' ? $_[0][0] : () }
	tensor_stack_position
	tensor_data_3d $input
)[0]};

# say "start: $start_x, $start_y";

my $expanded_map = 
	kernel_1x1 {
		my ($c,$v,$c_right,$c_down,$c_left,$c_up) = @{$_[0]};

		if ($v eq 'S') {
			$v = '-' if ($c_right and $c_left);
			$v = '|' if ($c_down and $c_up);
			$v = 'F' if ($c_right and $c_down);
			$v = 'L' if ($c_right and $c_up);
			$v = '7' if ($c_left and $c_down);
			$v = 'J' if ($c_left and $c_up);
		}

		[ $c,$v,$c_right,$c_down,$c_left,$c_up ]
	}
	kernel_1x1 {
		my ($p,$v,$v_right,$v_down,$v_left,$v_up) = @{$_[0]};

		my $connect_right = ($v =~ /[\-FLS]/ and defined ($v_right) and $v_right =~ /[\-J7S]/) ? [$p->[0]+1, $p->[1]] : undef;
		my $connect_down = ($v =~ /[|F7S]/ and defined ($v_down) and $v_down =~ /[|JLS]/) ? [$p->[0], $p->[1]+1] : undef;
		my $connect_left = ($v =~ /[\-J7S]/ and defined ($v_left) and $v_left =~ /[\-FLS]/) ? [$p->[0]-1, $p->[1]] : undef;
		my $connect_up = ($v =~ /[|JLS]/ and defined ($v_up) and $v_up =~ /[|F7S]/) ? [$p->[0], $p->[1]-1] : undef;

		[ -1, $v, $connect_right, $connect_down, $connect_left, $connect_up ]
	}
	tensor_stack_position
	tensor_self_stack_orthagonal
	tensor_data_3d $input;

my @ps = ([$start_x, $start_y, 0]);
while (@ps) {
	my @new_ps;
	foreach my $p (@ps) {
		$expanded_map->[$p->[1]][$p->[0]][0] = $p->[2];
		push @new_ps,
			map [ @$_, $p->[2] + 1 ],
			grep $expanded_map->[$_->[1]][$_->[0]][0] == -1,
			grep defined,
			@{$expanded_map->[$p->[1]][$p->[0]]}[2 .. 5];
	}
	@ps = @new_ps;
}
# say "step map:\n",
# 	untensor_data_2d
# 	kernel_1x1 { $_[0][0] == -1 ? sprintf '% 5s', $_[0][1] : sprintf '% 5d', $_[0][0] }
# 	$expanded_map;

say "solution part 1:\n",
	(sort { $a <=> $b }
		collapse_kernel_1x1 { $_[0][0] != -1 ? $_[0][0] : () }
		$expanded_map)[-1];

$expanded_map =
	kernel_1x1 { my ($count, $char) = @{$_[0]}; [ ($count == -1 ? '.' : $char) ] }
	$expanded_map;

# say "step map:\n",
# 	untensor_data_2d
# 	kernel_1x1 { $_[0][0] }
# 	$expanded_map;

for my $y (0 .. $#$expanded_map) {
	my $inside = 0;
	my $half_state = 0;
	my $half_state_direction;
	for my $x (0 .. $#{$expanded_map->[0]}) {
		$expanded_map->[$y][$x][0] = 'I' if ($inside and $expanded_map->[$y][$x][0] eq '.');
		if ($expanded_map->[$y][$x][0] eq '|') {
			$inside = !$inside;
		} elsif ($expanded_map->[$y][$x][0] eq 'F') {
			$half_state = 1;
			$half_state_direction = 'J';
		} elsif ($expanded_map->[$y][$x][0] eq 'L') {
			$half_state = 1;
			$half_state_direction = '7';
		} elsif ($half_state and $expanded_map->[$y][$x][0] =~ /[J7]/) {
			$half_state = 0;
			if ($expanded_map->[$y][$x][0] eq $half_state_direction) {
				$inside = !$inside;
			}
		}
	}
}

# say "step map:\n",
# 	untensor_data_2d
# 	kernel_1x1 { $_[0][0] eq 'I' ? 'I' : '.' }
# 	$expanded_map;

say "solution part 2:\n",
	sum
	collapse_kernel_1x1 { $_[0][0] eq 'I' ? 1 : () }
	$expanded_map;


