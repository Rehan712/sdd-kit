#!/usr/bin/env bash
# Session 20, for the record only (no verdict reads a rendering): marked 17.0.5 and markdown-it 12.3.2 (html enabled),
# as r18-repro.sh invokes them, render the bodies of r18-rows-probe.cases, so each row with a line inside its
# construct is shown to be a member: the tier is the first visible text of an item, a paragraph or a rendered line.
# Usage from the worktree root: bash <this> <scratch-dir> [<cases-file>] (default r18-rows-probe.cases)
set -uo pipefail
SP="${1:?scratch}"; WT="$PWD"; r=.specify/specs/003-gate-round-reduction-and-token-discipline/notes/verification/reports
X="$SP/r18-rows-render"; rm -rf "$X"; mkdir -p "$X"
MARKED=/Users/babar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/marked/lib/marked.esm.js
MDIT="/Applications/Cursor.app/Contents/Resources/app/node_modules/@vscode/vsce/node_modules/markdown-it"
printf '%s\n' "import { marked } from '$MARKED';" "import { readFileSync } from 'node:fs';" \
  "process.stdout.write(marked.parse(readFileSync(0, 'utf8')));" > "$X/render-marked.mjs"
printf '%s\n' "const md = require('$MDIT')({html: true});" "const fs = require('node:fs');" \
  "process.stdout.write(md.render(fs.readFileSync(0, 'utf8')));" > "$X/render-mdit.cjs"
fails=0
while IFS='|' read -r kind tag body diag; do
  [[ -n "$kind" && "$kind" != \#* ]] || continue
  [[ "$kind" == W ]] || body="- **Severity:** minor\n$body"
  printf '%s %s\n' "$kind" "$tag"
  for rn in marked mdit; do
    f=render-marked.mjs; [[ "$rn" == mdit ]] && f=render-mdit.cjs
    out="$(printf '%b' "$body" | ( cd "$X" && node "$f" ) 2>&1)"; rc=$?
    (( rc == 0 )) || fails=$((fails+1))
    printf '  | %-6s rc=%s %s\n' "$rn" "$rc" "$(printf '%s' "$out" | tr '\n\r' '~^' | LC_ALL=C cut -c1-400)"
  done
done < "${2:-$WT/$r/r18-rows-probe.cases}"
printf 'r18-rows-render failures=%s\n' "$fails"
(( fails == 0 ))
