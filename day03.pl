#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({});
$ua->cookie_jar->set_cookie(0, 'session', $ENV{SESSION_COOKIE}, '/', 'adventofcode.com');
my $res = $ua->get('https://adventofcode.com/2023/day/3/input');
die "failed to request input: " . $res->decoded_content unless $res->is_success;
my $input = $res->decoded_content;

# my $input =
# '467..114..
# ...*......
# ..35..633.
# ......#...
# 617*......
# .....+.58.
# ..592.....
# ......755.
# ...$.*....
# .664.598..';

sub sum { my $s = 0; foreach my $n (@_) { $s += $n } $s }
sub product { my $p = 1; foreach my $n (@_) { $p *= $n } $p }
sub min { (sort { $a <=> $b } @_)[0] }
sub max { (sort { $a <=> $b } @_)[-1] }

# my %limits = (
# 	red => 12,
# 	green => 13,
# 	blue => 14,
# );


sub tensor_data_2d ($) { return [ map [ split '' ], split /\n/, $_[0] ] }
sub tensor_data_3d ($) { return [ map [ map [ $_ ], split '' ], split /\n/, $_[0] ] }
sub untensor_data_2d { return join "\n", map { join '', @{$_} } @{$_[0]} }
sub tensor_flatten { return ($_[0] > 0 and ref $_[1] eq 'ARRAY') ? map tensor_flatten($_[0]-1, $_), @{$_[1]} : $_[1] }

sub tensor_positions ($) {
	my ($tensor) = @_;
	my @res;

	for my $y (0 .. $#$tensor) {
		for my $x (0 .. $#{$tensor->[0]}) {
			$res[$y][$x] = [$x,$y];
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
sub tensor_stack_offset ($@) {
	my ($offset, @tensors) = @_;
	my $first = $tensors[0];
	my @res;

	for my $y (0 .. $#$first) {
		for my $x (0 .. $#{$first->[0]}) {
			$res[$y][$x] = [ map @{ ($y+$offset->[1]*$_ >= 0 and $x+$offset->[0]*$_ >= 0) ? ($tensors[$_][$y+$offset->[1]*$_][$x+$offset->[0]*$_] // []) : []}, 0 .. $#tensors ];
		}
	}

	return \@res;
}

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

sub grep_kernel_1x1 (&&$) {
	my ($grepper, $fun, $arr) = @_;
	my @inp = map [ @$_ ], @$arr;
	my @res = map [], @$arr;

	for my $y (0 .. $#inp) {
		for my $x (0 .. $#{$inp[0]}) {
			$res[$y][$x] = $grepper->($inp[$y][$x]) ? $fun->($inp[$y][$x]) : undef;
		}
	}

	return [ map [ @{$_}[0 .. $#$_] ], @res[0 .. $#res] ];
}

sub kernel_1x3 (&$) {
	my ($fun, $arr) = @_;
	my @inp = map [ undef, @$_, undef ], @$arr;
	my @res = map [], @$arr;

	for my $y (0 .. $#inp) {
		for my $x (0 .. $#{$inp[0]}-2) {
			$res[$y][$x] = $fun->($inp[$y][$x], $inp[$y][$x+1], $inp[$y][$x+2]);
		}
	}

	return [ map [ @{$_}[0 .. $#$_] ], @res[0 .. $#res] ];
}

sub kernel_3x3 (&$) {
	my ($fun, $str) = @_;
	my @inp = map [ ' ', (split ''), ' ' ], split /\n/, $str;
	unshift @inp, [ map ' ', @{$inp[0]} ];
	push @inp, [ map ' ', @{$inp[0]} ];
	my @res = map [ ' ', (map ' ', split ''), ' ' ], split /\n/, $str;
	unshift @res, [ map ' ', @{$res[0]} ];
	push @res, [ map ' ', @{$res[0]} ];

	for my $y (1 .. $#inp - 1) {
		for my $x (1 .. $#{$inp[0]} - 1) {
			$res[$y][$x] = $fun->(@{$inp[$y-1]}[$x - 1 .. $x + 1], @{$inp[$y+0]}[$x - 1 .. $x + 1], @{$inp[$y+1]}[$x - 1 .. $x + 1]);
		}
	}

	return join "\n", map { join '', @{$_}[1 .. $#$_-1] } @res[1 .. $#res-1];
}

sub kernel_1x1x2 (&@) {
	my ($fun, $str, $str2) = @_;
	my @inp = map [ split '' ], split /\n/, $str;
	my @inp2 = map [ split '' ], split /\n/, $str2;
	my @res = map [ map ' ', split '' ], split /\n/, $str;

	for my $y (0 .. $#inp) {
		for my $x (0 .. $#{$inp[0]}) {
			$res[$y][$x] = $fun->($inp[$y][$x], $inp2[$y][$x]);
		}
	}

	return join "\n", map { join '', @{$_}[0 .. $#$_] } @res[0 .. $#res];
}

say "solution part 1:\n",
	sum
	map s/[^\d]//gr,
	grep /[^\d]/,
	map { split /\s/ }
	map s/\s+/ /gr,
	map s/T//gr,
	kernel_1x1x2 { $_[0] =~ /\d/ ? "$_[0]$_[1]" : "  " } $input,
	kernel_3x3 { (join '', @_) =~ /([^\d\s\.])/ ? $1 : 'T' } $input;

my @bounding_boxes =
	map {
		my ($x,$y,$n) = @$_;
		[$x-1, $y-1, length($n)+2, 3, $n]
	}
	grep defined,
	tensor_flatten 2,
	grep_kernel_1x1 sub { defined $_[0][2] }, sub { $_[0] },
	tensor_stack
	tensor_positions tensor_data_3d $input,
	kernel_1x1 { [ $_[0] ] }
	kernel_1x1 { defined $_[0] ? $_[0] =~ s/\D.*\Z//gr : undef }
	kernel_1x1 { ($_[0][0] =~ /\A\d/ and (not defined $_[0][1] or $_[0][1] =~ /\D/)) ? $_[0][0] : undef }
	tensor_stack_offset [-1,0], (
		kernel_1x1 { [ join '', @{$_[0]} ] }
		tensor_stack_offset [1,0],
		tensor_data_3d $input,
		tensor_data_3d $input,
		tensor_data_3d $input,
		tensor_data_3d $input),
	tensor_data_3d $input;

say "solution part 2:\n",
	# Dumper
	sum
	map { product map $_->[4], @{$_->[1]} }
	grep @{$_->[1]} == 2,
	map {
		my ($x,$y) = @$_;
		my @boxes = grep { $_->[0] <= $x and $_->[1] <= $y and $_->[0] + $_->[2] > $x and $_->[1] + $_->[3] > $y } @bounding_boxes;
		[ $_, \@boxes ]
	}
	grep defined,
	tensor_flatten 2,
	grep_kernel_1x1 sub { defined $_[0][2] }, sub { $_[0] },
	tensor_stack
	tensor_positions tensor_data_3d $input,
	kernel_1x1 { $_[0][0] eq '*' ? $_[0] : [] }
	tensor_data_3d $input;




