#!/usr/bin/perl
# lit.pl <file> <pairs-file>: apply literal replacements, each of which must match exactly once.
# The pairs file holds blocks separated by lines "@@OLD", "@@NEW", "@@END".
use strict; use warnings;
my ($file, $pairs) = @ARGV;
local $/; open my $h, '<', $file or die "read $file"; my $t = <$h>; close $h;
open my $p, '<', $pairs or die "read $pairs"; my $spec = <$p>; close $p;
my @blocks = ($spec =~ /\@\@OLD\n(.*?)\n\@\@NEW\n(.*?)\n\@\@END\n/sg);
die "no blocks" unless @blocks;
my $i = 0;
while (@blocks) {
  my ($old, $new) = splice(@blocks, 0, 2); $i++;
  my $n = () = $t =~ /\Q$old\E/g;
  die "block $i matched $n times:\n$old\n" if $n != 1;
  $t =~ s/\Q$old\E/$new/;
}
open $h, '>', $file or die "write $file"; print $h $t; close $h;
print "applied $i block(s) to $file\n";
