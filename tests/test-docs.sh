#!/usr/bin/env bash
# test-docs.sh — the docs site's checks. The asset scan runs against fixture
# sites written into $SANDBOX; the suite never needs Python or Zensical.

. "$(dirname -- "${BASH_SOURCE[0]}")/helpers.sh"

CHECK="$KIT_DIR/tests/docs-check.sh"

# AC-009 / FM-004: one fixture site per trigger exits 1 naming file and match;
# the own-host canonical link, a hyperlink and a data: CSS URL are clean.
test_AC_009_asset_scan_reports_third_party_hosts() {
  local site="$SANDBOX/site"
  mkdir -p "$site/a" "$site/b" "$site/c" "$site/d" "$site/ok"
  printf '<html><head><link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto"></head></html>\n' > "$site/a/index.html"
  printf '<html><body><script src=//cdn.example.com/x.js></script></body></html>\n' > "$site/b/index.html"
  printf "<html><body><IMG SRC='http://tracker.example.net/p.gif'></body></html>\n" > "$site/c/index.html"
  printf '<html></html>\n' > "$site/d/index.html"
  printf '@import url(https://fonts.example.org/f.css);\n' > "$site/d/theme.css"
  for d in a b c d; do
    run_rc 1 bash "$CHECK" --assets-only "$site/$d"
    assert_contains "$OUT" "third-party asset in $site/$d/" "FM-004 $d"
  done
  run_rc 1 bash "$CHECK" --assets-only "$site/a"
  assert_contains "$OUT" 'fonts.googleapis.com/css?family=Roboto'
  run_rc 1 bash "$CHECK" --assets-only "$site/b"
  assert_contains "$OUT" '//cdn.example.com/x.js'
  run_rc 1 bash "$CHECK" --assets-only "$site/c"
  assert_contains "$OUT" 'http://tracker.example.net/p.gif'
  run_rc 1 bash "$CHECK" --assets-only "$site/d"
  assert_contains "$OUT" 'https://fonts.example.org/f.css'
  printf '<html><head><link rel="canonical" href="https://rehan712.github.io/sdd-kit/"></head><body><a href="https://example.com/">x</a></body></html>\n' > "$site/ok/index.html"
  printf 'a{background:url("data:image/svg+xml;utf8,<svg xmlns='"'"'http://www.w3.org/2000/svg'"'"'/>")}\n' > "$site/ok/theme.css"
  run_rc 0 bash "$CHECK" --assets-only "$site/ok"
  assert_not_contains "$OUT" 'third-party asset'
}

# AC-009 / FM-003: nothing to scan never reads as clean.
test_AC_009_asset_scan_refuses_a_site_without_html() {
  mkdir -p "$SANDBOX/empty"
  run_rc 2 bash "$CHECK" --assets-only "$SANDBOX/empty"
  assert_contains "$OUT" 'no HTML to scan'
  run_rc 2 bash "$CHECK" --assets-only "$SANDBOX/missing"
  assert_contains "$OUT" 'no HTML to scan'
  run_rc 2 bash "$CHECK" --assets-only
  assert_contains "$OUT" 'usage'
}

t_run_all
