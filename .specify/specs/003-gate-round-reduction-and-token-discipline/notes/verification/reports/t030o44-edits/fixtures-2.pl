#!/usr/bin/perl
# fixtures-2.pl <tests/test-gate-contracts.sh> <refuse-diags.tsv>: make every refusal row of the manifest table in
# report_manifest_locale_cases (the R2-F2 read/refuse table) assert its own exact diagnostic (T030o44). The table
# asserted only the generic "prior-review manifest could not be parsed", so a refusal T030o44 added (a finding with
# no readable Severity) stood in for the guard a row was written to judge: seven T030o43 matrix rows survived on
# that ground (t030o44-o43matrix-shard{0,1}.log). Each row gains a third column, the diagnostic (empty for read
# rows), placed before the shape because a shape may hold a `|`; the loop reads it and asserts it through printf
# %b, as it writes the shape. The diagnostics are refuse-diags.tsv, collected on the repaired kernel in a scratch
# copy, each the message of the guard its row names.
use strict; use warnings;
my ($file, $tsv) = @ARGV;
open my $t, '<', $tsv or die "read $tsv"; my %d; while (<$t>) { chomp; my ($l, $m) = split /\t/, $_, 2; $d{$l} = $m; } close $t;
open my $h, '<', $file or die "read $file"; my @l = <$h>; close $h;
my ($loop) = grep { $l[$_] eq "  while IFS='|' read -r label want shape; do\n" } 0 .. $#l;
die "loop line not found once\n" unless defined $loop && 1 == grep { $_ eq "  while IFS='|' read -r label want shape; do\n" } @l;
$l[$loop] = "  while IFS='|' read -r label want diag shape; do\n";
my $i = $loop; $i++ until $l[$i] =~ /^      assert_contains "\$OUT" 'prior-review manifest could not be parsed' \\$/;
die "unexpected assertion shape at " . ($i + 2) . "\n" unless $l[$i + 1] =~ /was not refused by name \(T030o43 review 2\)"$/;
splice @l, $i + 2, 0, "      assert_contains \"\$OUT\" \"\$(printf '%b' \"\$diag\")\" \\\n",
  "        \"AC-012: a manifest spelled \$label was not refused by its own diagnostic (T030o44)\"\n";
my $s = $i; $s++ until $l[$s] eq "  done <<'SHAPES'\n";
my ($read, $refuse) = (0, 0);
for (my $j = $s + 1; $l[$j] ne "SHAPES\n"; $j++) {
  if ($l[$j] =~ /^([a-z0-9-]+)\|read\|/) { $l[$j] =~ s/^([a-z0-9-]+)\|read\|/$1|read||/; $read++; next; }
  if ($l[$j] =~ /^([a-z0-9-]+)\|refuse\|/) {
    my $label = $1; die "no diagnostic for $label\n" unless exists $d{$label};
    $l[$j] =~ s/^([a-z0-9-]+)\|refuse\|/$1|refuse|$d{$label}|/; $refuse++; delete $d{$label}; next;
  }
  die "unexpected row: $l[$j]";
}
die "diagnostics left unused: " . join(',', sort keys %d) . "\n" if %d;
open $h, '>', $file or die "write $file"; print $h @l; close $h;
print "converted $read read row(s) and $refuse refuse row(s) of $file\n";
