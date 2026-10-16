#!/usr/bin/perl
# fixtures-1.pl <tests/test-gate-contracts.sh>: give each fixture manifest whose finding carries a Class alone a
# Severity line (T030o44, O-018: every manifest finding needs one readable Severity). Each listed line must be a
# printf of a manifest whose first Class line is followed by no Severity line; the first such Class line gains
# "- **Severity:** data-loss", the tier of the resolved report finding each of these fixtures pairs it with, so no
# fixture changes what it tests. In the three quoted-entry fixtures only the real (first) entry changes.
use strict; use warnings;
my ($file) = @ARGV;
my @lines = (1417, 1425, 1431, 1439, 1443, 1449, 1455, 1465, 1514, 1525, 1536, 1568, 1574);
open my $h, '<', $file or die "read $file"; my @l = <$h>; close $h;
for my $n (@lines) {
  my $t = $l[$n - 1];
  die "line $n is not a Class-only manifest printf:\n$t" unless $t =~ /^\s+printf '.*- \*\*Class:\*\* [a-z-]+\\n/ && $t !~ /\*\*Severity:\*\*/;
  $t =~ s/(- \*\*Class:\*\* [a-z-]+\\n)/$1- **Severity:** data-loss\\n/ or die "line $n: no substitution";
  $l[$n - 1] = $t;
}
open $h, '>', $file or die "write $file"; print $h @l; close $h;
print "edited " . scalar(@lines) . " line(s) of $file\n";
