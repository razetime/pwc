#!/usr/bin/perl
#
# Challenge 1: "Generate a longest sequence of the following "English Pokemon"
#     names where each name starts with the last letter of the previous name:
# 
#         audino bagon baltoy banette bidoof braviary bronzor carracosta
#         charmeleon cresselia croagunk darmanitan deino emboar emolga
#         exeggcute gabite girafarig gulpin haxorus heatmor heatran ivysaur
#         jellicent jumpluff kangaskhan kricketune landorus ledyba loudred
#         lumineon lunatone machamp magnezone mamoswine nosepass petilil
#         pidgeotto pikachu pinsir poliwrath poochyena porygon2 porygonz
#         registeel relicanth remoraid rufflet sableye scolipede scrafty
#         seaking sealeo silcoon simisear snivy snorlax spoink starly
#         tirtouga trapinch treecko tyrogue vigoroth vulpix wailord
#         wartortle whismur wingull yamask"
# 
# My notes: Clearly defined, nice, potentially tricky, let's do it.
# 
# optimization v4: instead of extracting the last letter of each word,
#		   precalculate %lw: word->last letter of word        14.8s
# optimization v3: instead of cloning the used set to modify it,
#		   modify it, pass it, and then change it back        21.1s
# optimization v2: instead of recalculating the "used set" each time,
#		   pass it around, modifying it as we go              28.8s
# optimization v1: baseline code before starting to optimize:         32.6s.
#

use v5.10;	# to get "say"
use strict;
use warnings;
use Function::Parameters;
#use Data::Dumper;

my $debug = @ARGV>0;

my @words = qw(audino bagon baltoy banette bidoof braviary bronzor carracosta
	charmeleon cresselia croagunk darmanitan deino emboar emolga
	exeggcute gabite girafarig gulpin haxorus heatmor heatran ivysaur
	jellicent jumpluff kangaskhan kricketune landorus ledyba loudred
	lumineon lunatone machamp magnezone mamoswine nosepass petilil
	pidgeotto pikachu pinsir poliwrath poochyena porygon2 porygonz
	registeel relicanth remoraid rufflet sableye scolipede scrafty
	seaking sealeo silcoon simisear snivy snorlax spoink starly
	tirtouga trapinch treecko tyrogue vigoroth vulpix wailord
	wartortle whismur wingull yamask);
#@words = qw(hello ollie excellent thanks shelter runaround set to);

my %sw;	# hash from letter to list of words starting with that letter.

my %lw; # mapping from word to last letter of word (precompute it:-))

foreach my $word (@words)
{
	$word =~ /^(.)/;
	my $letter = $1;
	$sw{$letter} //= [];
	push @{$sw{$letter}}, $word;

	$word =~ /(.)$/;
	$lw{$word} = $1;
}

#die Dumper \%sw;
#die Dumper \%lw;

my @longseq = ();	# longest sequence found so far..

# search for sequences starting with each word in turn..
foreach my $sw (@words)
{
	findseq( $sw, {}, () );
}

my $longest = @longseq;

print "\nlongest sequence is length $longest: @longseq\n";
exit 0;


#
# findseq( $currw, $used, @seq );
#	Find all sequences of words from $currw onwards,
#	given that we've already visited words in @seq,
#	(the same info, as a set, is in %$used)
#	and update the global @longseq if any sequences
#	we find are longer than that.
#
fun findseq( $currw, $used, @seq )
{
	push @seq, $currw;		  # extend @seq sequence

	$used->{$currw}++;		  # update $used set

	my $lastletter = $lw{$currw};	  # find the last letter of currw

	my $nextw = $sw{$lastletter};     # all words starting with lastletter
	if( defined $nextw )              # if there are any, try each word
	{
		foreach my $nextword (@$nextw)
		{
			findseq( $nextword, $used, @seq )
				unless $used->{$nextword};
		}
	} else				  # @seq is finished
	{
		#print "found sequence @seq\n";
		my $len = @seq;
		if( $len > @longseq )
		{
			print "longest seq so far (len $len): @seq\n" if $debug;
			@longseq = @seq;
		}
	}
	delete $used->{$currw};
}
