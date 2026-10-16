#!/usr/bin/env python3
# Session 21 (2026-10-14): the round-18 repair as the user chose it (O-018 narrow further, the reviewer's M1; O-025
# refuse tables, the reviewer's M2; O-023 settle on either test, the reviewer's M3), applied to the kernel, the
# contract template and the two changed suites. The kernel edits are the reviewer's own MALL mutant, taken from its
# transcript (its mk.py), with its helper names given kernel names (vf_m1_odd -> vf_cm_open_tick, vf_m1_url ->
# vf_cm_url, vf_m2_delim -> vf_para_delim). Rows separated by `~` where a body holds a pipe.
# Usage: python3 -I <this> <root>   (root: the worktree, or a standalone copy of it)
# Refuses unless the four files hash as r18-edits/post-apply-3 and every anchor occurs exactly once; prints the new
# sha256 of each file.
import hashlib, os, sys
root = sys.argv[1]
pre = {
    'scripts/verification-lib.sh': '62a17f93cccccf681d8e9644dcada2ba7314e3f3b5f7d27e3414431ae2a95946',
    'templates/verification-contract.md': 'c728becd92cd7446778a6d06e6d07416ab015a8868dd82d092f522fc0d07d3c7',
    'tests/test-gate-contracts.sh': '25693ceb2cc79a643de38e702285aa181cc02e08c04acbe8f1ef81c2151a1474',
    'tests/test-spec-gate.sh': 'dd68ee3ec50bdb9fe0163ddff3755373751d8693371687c17c24d81d80533af8',
}
text = {}
for p, h in pre.items():
    b = open(os.path.join(root, p), 'rb').read()
    assert hashlib.sha256(b).hexdigest() == h, 'refusing: %s does not hash as post-apply-3' % p
    text[p] = b.decode('utf-8')

def once(p, old, new):
    n = text[p].count(old)
    assert n == 1, '%s: anchor count %d: %r' % (p, n, old[:90])
    text[p] = text[p].replace(old, new)

K = 'scripts/verification-lib.sh'
# M1: a backtick inside a bracket pair closed on its line, or inside a URL literal, outside every code span.
once(K, r'b = sprintf("%c", 96); re = "[]\\\\<" b "]"; vf_cm_out = vf_cm_auto = vf_cm_link = 0;',
        r'b = sprintf("%c", 96); re = "[][\\\\<:wW" b "]"; vf_cm_out = vf_cm_auto = vf_cm_link = 0;')
once(K, '    if (c == "]") {\n      c = substr(s, i + 1, 1)\n      if (c == "(" || c == "[") {',
        '    if (c == "[") {k = vf_cm_label(s, i); if (k > 0 && vf_cm_open_tick(substr(s, i + 1, k - i - 2))) vf_cm_link = 1; i++; continue}\n'
        '    if (c == ":") {if (substr(s, i, 3) == "://" && tolower(substr(s, 1, i - 1)) ~ /(https?|ftp)$/) vf_cm_url(s, i + 3); i++; continue}\n'
        '    if (c == "w" || c == "W") {if (tolower(substr(s, i, 4)) == "www.") vf_cm_url(s, i + 4); i++; continue}\n'
        '    if (c == "]") {\n      c = substr(s, i + 1, 1)\n      if (c == "(" || c == "[") {')
once(K, 'function vf_cm_scan(s, st,',
        r'''function vf_cm_open_tick(L,   b, n, i, j, r, k, c) {
  b = sprintf("%c", 96); n = length(L); i = 1
  while (i <= n) {
    c = substr(L, i, 1)
    if (c == "\\") {i += 2; continue}
    if (c != b) {i++; continue}
    j = i; while (j <= n && substr(L, j, 1) == b) j++
    r = j - i; k = vf_cm_close(L, j, r); if (!k) return 1; i = k
  }
  return 0
}
function vf_cm_url(s, j,   n, c) {
  n = length(s)
  while (j <= n && (c = substr(s, j, 1)) !~ /[ \t<]/) {if (c == sprintf("%c", 96)) {vf_cm_auto = 1; return}; j++}
}
function vf_cm_scan(s, st,''')
# M2: a line that may be a GFM table delimiter row.
once(K, '  else if (d) vf_narrow = "a link reference definition"\n',
        '  else if (d) vf_narrow = "a link reference definition"\n'
        '  else if (index(t, "|") && vf_para_delim(t)) vf_narrow = "a table delimiter row"\n')
once(K, 'function vf_para_refdef(s, t,',
        r'''function vf_para_delim(t,   u) {
  u = t; gsub(/[ \t]/, "", u)
  return index(u, "|") && u ~ /^\|?:?-+:?(\|:?-+:?)*\|?$/
}
function vf_para_refdef(s, t,''')
# M3: settle on either test.
once(K, '  return vf_settled_lead(t) && vf_settled_brackets(vf_settled_head(t))\n',
        '  return vf_settled_lead(t) && (vf_settled_brackets(vf_settled_head(t)) || vf_settled_brackets(t))\n')

V = 'templates/verification-contract.md'
once(V, "link's destination or title, or a full reference link's label, that holds a\n"
        "backtick or does not end on its line; when it carries a form feed or vertical\n",
        "link's destination or title, or a full reference link's label, that holds a\n"
        "backtick or does not end on its line; a bracket pair closed on its line (a\n"
        "shortcut, collapsed or image reference's label) that holds a backtick run it\n"
        "does not close, or a URL literal (after `http://`, `https://`, `ftp://` or\n"
        "`www.`) whose text up to whitespace or `<` holds a backtick, since a GFM\n"
        "renderer binds both before any code span; when it may be a table delimiter\n"
        "row (hyphen cells, colons allowed, and at least one pipe), since a renderer\n"
        "shows a cell's first text where the label reader, which never splits a line\n"
        "at a pipe, does not look; when it carries a form feed or vertical\n")
once(V, "a code example inside a finding as a fence at the start of a line, and keeps\n"
        "link definitions outside every finding. The other canonical fields are\n",
        "a code example inside a finding as a fence at the start of a line, and keeps\n"
        "link definitions and tables outside every finding. Reports are trusted-author\n"
        "input, written by the kit's own gate agents: a rendering divergence this\n"
        "grammar neither reads nor refuses is a minor finding for a follow-up, not a\n"
        "blocker (REQ-011). The other canonical fields are\n")

G = 'tests/test-gate-contracts.sh'
once(G, "  # name; so are the stated consequences (`c <= d`, a fence indented under a\n"
        "  # list item, a definition line).\n",
        "  # name; so are the stated consequences (`c <= d`, a fence indented under a\n"
        "  # list item, a definition line). Round 18's members follow (O-018): a\n"
        "  # backtick inside a GFM URL literal, or inside a shortcut, collapsed or\n"
        "  # image reference's label, which marked binds before any code span, is\n"
        "  # refused by name; tables (O-025) follow below.\n")
once(G, "ROWS\n  # O-019: a heading deeper than the Finding heading is one of its lines, so\n",
     r"""url-literal-tick|### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\nNote http://a.b/`<br>Severity: data-loss, tick: `.\n|an autolink outside a code span in finding G-042
https-literal-tick|### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\nNote https://a.b/x`<br>Severity: data-loss, tick: `.\n|an autolink outside a code span in finding G-042
www-literal-tick|### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\nNote www.a.b/x`<br>Severity: data-loss, tick: `.\n|an autolink outside a code span in finding G-042
ftp-literal-tick-pre|### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\nNote ftp://a.b/`<pre>Severity: data-loss</pre>`\n|an autolink outside a code span in finding G-042
shortcut-reference-tick|### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\nNote [a`b]<br>Severity: data-loss, tick: `.\n|a backtick inside a link destination, title or label in finding G-042
collapsed-reference-tick|### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\nNote [a`b][]<br>Severity: data-loss, tick: `.\n|a backtick inside a link destination, title or label in finding G-042
image-reference-tick|### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\nNote ![a`b]<br>Severity: data-loss, tick: `.\n|a backtick inside a link destination, title or label in finding G-042
ROWS
  # Round 18 (O-025): a GFM table inside a finding shows a cell's first text
  # where the label reader, which never splits a line at a pipe, does not look,
  # so a line that may be a table delimiter row is refused by name; pipes in
  # prose and in code spans, a URL literal and references with no backtick in
  # their labels still parse.
  while IFS='~' read -r tag body; do
    printf '# Prior review\n\n%b' "$body" > "$spec/notes/verification/reports/opponent-findings-review.md"
    tier_round_fixture 1 '' G-042:tier-binding:open:minor > "$report"
    for l in C en_US.UTF-8; do
      run_rc 3 record_line_vf "$l" "$report" "$spec"
      assert_contains "$OUT" 'a table delimiter row in finding G-042' "AC-012: a manifest tier in a table cell ($tag) was not refused by name under LANG=$l (round 18, O-025)"
    done
  done <<'ROWS'
table-cell~### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n| Step | Result |\n| - | - |\n| ran | **Severity:** data-loss |\n
table-in-list-item~### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n- Steps:\n\n  | Step | Result |\n  |:--|--:|\n  | ran | **Severity:** data-loss |\n
ROWS
  while IFS='~' read -r tag body; do
    printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n%b' "$body" > "$spec/notes/verification/reports/opponent-findings-review.md"
    tier_round_fixture 1 '' G-042:tier-binding:open:minor > "$report"
    for l in C en_US.UTF-8; do
      run_rc 0 record_line_vf "$l" "$report" "$spec"
      assert_not_contains "$OUT" 'report recovery' "AC-012: a manifest finding with $tag was refused under LANG=$l (round 18)"
    done
  done <<'ROWS'
url-literal~See https://x.example/a and `code` here.\n
link-text-code-span~See [the `x` doc](u) and `code`.\n
references~See [the doc][ref] and [x][] here.\n
pipes-in-prose~It reads a | b and `c | d` here.\n
ROWS
  # O-019: a heading deeper than the Finding heading is one of its lines, so
""")
once(G, 'a-blank-line-ends-run|### Finding G-042|\\n<b title="a\\n\\n- b">Severity: data-loss</b>\\n\\n\nROWS\n',
     r"""a-blank-line-ends-run|### Finding G-042|\n<b title="a\n\n- b">Severity: data-loss</b>\n\n
ROWS
  # Round 18 (O-018, O-025): inside a canonical finding, a backtick inside a
  # GFM URL literal or inside a reference link's label, which marked binds
  # before any code span, and a line that may be a table delimiter row are
  # refused by name; what the narrowing leaves still parses.
  while IFS='~' read -r tag body want; do
    record_round 1 CHALLENGED 1 0 '### Finding G-042' tier-binding new '- **Severity:** data-loss' "$body" > "$report"
    for l in C en_US.UTF-8; do
      run_rc 3 record_line_vf "$l" "$report" "$spec"
      assert_contains "$OUT" "$want" "AC-012: a canonical finding with $tag was not refused by name under LANG=$l (round 18)"
    done
  done <<'ROWS'
a-url-literal-tick~\nNote http://a.b/`<br>Severity: data-loss, tick: `.\n\n~an autolink outside a code span in finding G-042
a-https-literal-tick~\nNote https://a.b/x`<br>Severity: data-loss, tick: `.\n\n~an autolink outside a code span in finding G-042
a-www-literal-tick~\nNote www.a.b/x`<br>Severity: data-loss, tick: `.\n\n~an autolink outside a code span in finding G-042
a-ftp-literal-tick-pre~\nNote ftp://a.b/`<pre>Severity: data-loss</pre>`\n\n~an autolink outside a code span in finding G-042
a-shortcut-reference-tick~\nNote [a`b]<br>Severity: data-loss, tick: `.\n\n~a backtick inside a link destination, title or label in finding G-042
a-collapsed-reference-tick~\nNote [a`b][]<br>Severity: data-loss, tick: `.\n\n~a backtick inside a link destination, title or label in finding G-042
a-image-reference-tick~\nNote ![a`b]<br>Severity: data-loss, tick: `.\n\n~a backtick inside a link destination, title or label in finding G-042
a-table-cell~\n| Step | Result |\n| - | - |\n| ran | **Severity:** data-loss |\n\n~a table delimiter row in finding G-042
a-table-in-list-item~  - Steps:\n\n    | Step | Result |\n    |:--|--:|\n    | ran | **Severity:** data-loss |\n\n~a table delimiter row in finding G-042
ROWS
  while IFS='~' read -r tag body; do
    record_round 1 CHALLENGED 1 0 '### Finding G-042' tier-binding new '- **Severity:** data-loss' "$body" > "$report"
    for l in C en_US.UTF-8; do
      run_rc 0 record_line_vf "$l" "$report" "$spec"
      assert_not_contains "$OUT" 'report recovery' "AC-012: a canonical finding with $tag was refused under LANG=$l (round 18)"
    done
  done <<'ROWS'
a-url-literal~\nSee https://x.example/a and `code` here.\n\n
a-www-literal~\nSee www.example.com for the `rc` value.\n\n
a-link-text-code-span~\nSee [the `x` doc](u) and `code`.\n\n
a-references~\nSee [the doc][ref] and [x][] here.\n\n
a-pipes-in-prose~\nIt reads a | b and `c | d` here.\n\n
ROWS
""")
once(G, '  (( SECONDS - t0 < 60 )) || t_fail "AC-012: a 400-line run under a bracket quoted in a code span took $((SECONDS - t0)) s, not under 60 s (round 17, O-023)"\n',
     r"""  (( SECONDS - t0 < 60 )) || t_fail "AC-012: a 400-line run under a bracket quoted in a code span took $((SECONDS - t0)) s, not under 60 s (round 17, O-023)"
  # A candidate is settled when its head or its whole text balances (round 18,
  # O-023): a run of sub-bullets each led by a link, an image or a code span
  # holding a bracket keeps no later line re-read, so a 400-line Reproduced
  # field parses in seconds, where the round-18 tree took about 30 s at 100.
  record_round 1 CHALLENGED 1 0 '### Finding G-050' dup-binding new '- **Severity:** data-loss' |
    awk -v n=400 'index($0, "- **Reproduced:**") == 1 {print "- **Reproduced:** steps follow"; for (i = 0; i < n; i++) {k = i % 3; if (k == 0) printf "  - [step %d](https://x.example/%d) ran `vf_reports x` and saw *exit 0* with `rc=%d` here, fine\n", i, i, i; else if (k == 1) printf "  - ![badge %d](https://x.example/%d.png) step ran and saw *exit 0* with `rc=%d` here, fine\n", i, i, i; else printf "  - `[%d]` held and [the copy](https://x.example/%d) saw *exit 0* with `rc=%d` here, fine\n", i, i, i}; next} {print}' > "$report"
  t0=$SECONDS
  run_rc 0 record_line_vf C "$report" "$spec"
  assert_not_contains "$OUT" 'report recovery' 'AC-012: a 400-line run of link-, image- and code-span-led sub-bullets was refused (round 18, O-023)'
  (( SECONDS - t0 < 60 )) || t_fail "AC-012: a 400-line run of link-, image- and code-span-led sub-bullets took $((SECONDS - t0)) s, not under 60 s (round 18, O-023)"
""")

S = 'tests/test-spec-gate.sh'
once(S, "  # Round 17's follow (O-018, O-024): a `<` that may open an autolink, a link\n"
        "  # destination holding a backtick, and a fence after a list marker.\n",
        "  # Round 17's follow (O-018, O-024): a `<` that may open an autolink, a link\n"
        "  # destination holding a backtick, and a fence after a list marker. Round\n"
        "  # 18's follow (O-018): a backtick inside a URL literal and inside a\n"
        "  # reference link's label, which marked binds before any code span.\n")
once(S, r"""             $'\n[x](u`v)<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-042' \
""",
     r"""             $'\n[x](u`v)<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-042' \
             $'\nNote http://a.b/`<br>Severity: data-loss, tick: `.|an autolink outside a code span in finding G-042' \
             $'\nNote [a`b]<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-042' \
""")
once(S, "  # O-019: a field line under a sub-heading of the manifest finding is read, so\n",
     r"""  # Round 18 (O-025): a table inside a finding shows a cell's first text the
  # label reader never reads, so a delimiter row is refused by name at completion.
  printf '# Prior review\n\n### Finding G-042\n- **Class:** tier-binding\n- **Severity:** minor\n\n| Step | Result |\n| - | - |\n| ran | **Severity:** data-loss |\n' > "$manifest"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$report"
    assert_contains "$OUT" 'a table delimiter row in finding G-042' \
      "AC-009: a CLEARED completion over a manifest tier in a table cell was not refused under LANG=$l (round 18, O-025)"
  done
  # O-019: a field line under a sub-heading of the manifest finding is read, so
""")
once(S, r"""             '- **Severity:** minor\n\nNote <1`@a.b><pre>Severity: data-loss</pre>`|an autolink outside a code span in finding G-050' \
""",
     r"""             '- **Severity:** minor\n\nNote <1`@a.b><pre>Severity: data-loss</pre>`|an autolink outside a code span in finding G-050' \
             '- **Severity:** minor\n\nNote www.a.b/x`<br>Severity: data-loss, tick: `.|an autolink outside a code span in finding G-050' \
             '- **Severity:** minor\n\nNote ![a`b]<br>Severity: data-loss, tick: `.|a backtick inside a link destination, title or label in finding G-050' \
""")
once(S, "  # A title and a late Timestamp let a CLEARED round seal over a blocking\n",
     r"""  # Round 18 (O-025): the same table after the fields of a canonical finding.
  tail=$'\n| Step | Result |\n| - | - |\n| ran | **Severity:** data-loss |\n'
  record_line_report "$res" 1 CLEARED 0 1 '### Finding G-050' tier-binding new '- **Severity:** minor' |
    TAIL="$tail" awk 'index($0, "### Held up") == 1 {printf "%s", ENVIRON["TAIL"]} {print}' > "$SANDBOX/record-lines-o025.md"
  for l in C en_US.UTF-8; do
    run_rc 3 in_locale "$l" bash "$cli" round "$spec" opponent --complete "$SANDBOX/record-lines-o025.md"
    assert_contains "$OUT" 'a table delimiter row in finding G-050' \
      "AC-009: a CLEARED completion over a tier in a table cell was not refused under LANG=$l (round 18, O-025)"
  done
  # A title and a late Timestamp let a CLEARED round seal over a blocking
""")

for p in pre:
    out = text[p].encode('utf-8')
    open(os.path.join(root, p), 'wb').write(out)
    print('%s  %s' % (hashlib.sha256(out).hexdigest(), p))
