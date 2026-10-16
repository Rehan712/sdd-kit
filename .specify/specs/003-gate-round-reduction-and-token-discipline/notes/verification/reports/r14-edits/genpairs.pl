# genpairs.pl <file> <a,b,newfile>... : one @@OLD/@@NEW/@@END block per range, OLD = lines a..b of <file> exactly.
use strict; use warnings;
my $f = shift; open my $h, '<', $f or die "read $f"; my @l = <$h>; close $h;
for my $spec (@ARGV) {
  my ($a, $b, $nf) = split /,/, $spec, 3;
  my $old = join '', @l[$a-1 .. $b-1]; chomp $old;
  open my $n, '<', $nf or die "read $nf"; local $/; my $new = <$n>; close $n; $new =~ s/\n\z//;
  print "\@\@OLD\n$old\n\@\@NEW\n$new\n\@\@END\n";
}
