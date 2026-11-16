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

# stub_zensical <mode> — write a fake zensical into $SANDBOX/bin; every mode
# logs its arguments and "builds" site/index.html + site/404.html in its cwd.
# A probe is a docs/index.md that names docs-check-no-such-page.md.
stub_zensical() {
  mkdir -p "$SANDBOX/bin"
  cat > "$SANDBOX/bin/zensical" <<STUB
#!/usr/bin/env bash
echo "\$*" >> "$SANDBOX/zensical-args"
mode='$1'
probe=false
grep -q docs-check-no-such-page.md docs/index.md && probe=true
if [ "\$mode" != accepts-all ] && \$probe; then
  [ "\$mode" = silent-fail ] || echo 'Error: docs-check-no-such-page.md' >&2
  exit 1
fi
mkdir -p site
echo '<html></html>' > site/index.html
[ "\$mode" = no-404 ] || echo '<html></html>' > site/404.html
exit 0
STUB
  chmod +x "$SANDBOX/bin/zensical"
}

# sandbox_kit — a self-contained kit: the check, a minimal config and one page.
sandbox_kit() {
  local kit="$SANDBOX/kit"
  mkdir -p "$kit/tests" "$kit/docs"
  cp "$CHECK" "$kit/tests/docs-check.sh"
  printf '[project]\nsite_name = "t"\n' > "$kit/zensical.toml"
  printf '# t\n' > "$kit/docs/index.md"
  KIT="$kit"
}

# run_check <mode> <expected rc> — run the sandbox kit's check against a stub.
run_check() {
  stub_zensical "$1"
  sandbox_kit
  PATH="$SANDBOX/bin:$PATH" run_rc "$2" bash "$KIT/tests/docs-check.sh"
}

# AC-008: positive control.
test_AC_008_check_passes_when_strict_mode_names_the_broken_link() {
  run_check good 0
  assert_contains "$OUT" 'docs-check: ok'
}

# AC-008 / FM-002: a strict build that accepts the probe is not strict.
test_AC_008_check_fails_when_strict_mode_accepts_a_broken_link() {
  run_check accepts-all 1
  assert_contains "$OUT" 'strict build accepted a broken link'
}

# AC-008 / FM-002: a failure that does not name the link proves nothing.
test_AC_008_check_fails_when_the_failure_does_not_name_the_link() {
  run_check silent-fail 1
  assert_contains "$OUT" 'strict build failed without naming the broken link'
}

# AC-008 / FM-007
test_AC_008_check_fails_without_a_404_page() {
  run_check no-404 1
  assert_contains "$OUT" 'site/404.html missing'
}

# AC-008 / FM-001: PATH holds only bash, sed, cp and mktemp.
test_AC_008_check_refuses_to_run_without_zensical() {
  local t
  sandbox_kit
  mkdir -p "$SANDBOX/minbin"
  for t in bash sed cp mktemp; do ln -s "$(command -v "$t")" "$SANDBOX/minbin/$t"; done
  run_rc 2 env PATH="$SANDBOX/minbin" bash "$KIT/tests/docs-check.sh"
  assert_contains "$OUT" 'zensical not found on PATH'
}

# INV-004: the check never cleans, so an installed kit keeps .cache/repos.
test_AC_008_check_never_cleans_the_kit_cache() {
  run_check good 0
  assert_contains "$(cat "$SANDBOX/zensical-args")" 'build --strict'
  assert_not_contains "$(cat "$SANDBOX/zensical-args")" '--clean'
  assert_not_contains "$(cat "$SANDBOX/zensical-args")" ' -c'
}

# AC-003 / FM-005: the nav and docs/*.md name the same pages, both ways; search
# is never switched off; no page hides in a subdirectory the nav check cannot see.
test_AC_003_every_page_is_in_the_nav_and_search_stays_on() {
  local toml="$KIT_DIR/zensical.toml" nav pages p list
  nav="$(sed -n '/^nav = \[/,/^\]/p' "$toml" | sed -n 's/^  "\(.*\.md\)",$/\1/p' | sort)"
  pages="$(kit_files docs '*.md' | tr '\0' '\n' | sed 's|.*/||' | sort)"
  [[ -n "$pages" ]] || { t_fail "no docs/*.md pages enumerated"; return; }
  for p in $pages; do
    printf '%s\n' "$nav" | grep -qxF "$p" || t_fail "docs/$p is not in the nav"
  done
  for p in $nav; do
    printf '%s\n' "$pages" | grep -qxF "$p" || t_fail "nav names $p but docs/$p does not exist"
  done
  assert_not_contains "$(cat "$toml")" 'plugins.search'
  assert_not_contains "$(cat "$toml")" 'enabled = false'
  list="$SANDBOX/source-paths"
  bash -c '. "$1/verification-lib.sh"; vf_source_paths "$2" "$3"' _ "$SCRIPTS" "$(cd "$KIT_DIR" && pwd -P)" "$list" || { t_fail "cannot enumerate $KIT_DIR"; return; }
  while IFS= read -r -d '' p; do
    case "$p" in docs/*/*.md) t_fail "page in a subdirectory the nav check cannot see: $p";; esac
  done < "$list"
}

# AC-006: pull requests build, only a push to main deploys.
test_AC_006_docs_build_on_pull_request_and_deploy_only_from_main() {
  local wf; wf="$(cat "$KIT_DIR/.github/workflows/docs.yml")"
  assert_contains "$wf" '  pull_request:'
  assert_contains "$wf" 'branches: [main]'
  assert_contains "$wf" 'run: bash tests/docs-check.sh'
  assert_contains "$wf" "    if: github.event_name == 'push' && github.ref == 'refs/heads/main'"
}

# AC-009: no secret, custom domain, tracker or web font.
test_AC_009_docs_need_no_secret_domain_or_tracker() {
  local wf toml; wf="$KIT_DIR/.github/workflows/docs.yml"; toml="$(cat "$KIT_DIR/zensical.toml")"
  [[ -n "$(grep 'runs-on:' "$wf")" ]] || t_fail "no runs-on in docs.yml"
  [[ -z "$(grep 'runs-on:' "$wf" | grep -v 'runs-on: ubuntu-latest$')" ]] || t_fail "a job runs off ubuntu-latest"
  assert_not_contains "$(cat "$wf")" 'secrets.'
  [[ ! -e "$KIT_DIR/docs/CNAME" ]] || t_fail "docs/CNAME exists"
  assert_contains "$toml" 'font = false'
  assert_not_contains "$toml" 'repo_url'
  assert_not_contains "$toml" 'analytics'
}

# AC-010: only the deploy job (the last one) holds the Pages write permissions.
test_AC_010_only_the_deploy_job_can_write_pages() {
  local wf="$KIT_DIR/.github/workflows/docs.yml" before after p
  before="$(sed '/^  deploy:/,$d' "$wf")"
  after="$(sed -n '/^  deploy:/,$p' "$wf")"
  assert_contains "$before" 'contents: read'
  for p in 'pages: write' 'id-token: write'; do
    assert_not_contains "$before" "$p"
    [[ "$(printf '%s\n' "$after" | grep -cF "$p")" -eq 1 ]] || t_fail "$p not exactly once from deploy: on"
  done
}

# AC-012: the kit's own CI never needs the docs toolchain.
test_AC_012_ci_suite_needs_no_docs_tooling() {
  local ci; ci="$(cat "$KIT_DIR/.github/workflows/ci.yml")"
  assert_not_contains "$ci" 'zensical'
  assert_not_contains "$ci" 'setup-python'
  assert_not_contains "$ci" 'pip'
}

t_run_all
