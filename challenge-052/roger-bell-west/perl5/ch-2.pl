#! /usr/bin/perl

# see eventual blog post for why this is relevant

use strict;
use warnings;

my $coins=8;

foreach my $a (0..$coins-1) {
  my @c=($a,$coins-1-$a);
  while ($c[0]>2 || $c[1]>2) {
    @c=sort @c;
    $c[1]-=2;
  }
  my $toplay=0;
  while ($c[0]>1 || $c[1]>1) {
    @c=sort @c;
    $c[1]--;
    $toplay=1-$toplay;
  }
  @c=sort @c;
  unless ($c[0]==0) {
    $toplay=1-$toplay;
  }
  print "$a: $toplay wins\n";
}
