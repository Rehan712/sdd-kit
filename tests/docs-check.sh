#!/usr/bin/env bash
# tests/docs-check.sh — the docs site's check: scan a built site for assets
# served from a third-party host (the site must cost and track nothing, spec
# 004 REQ-008).
#
# Usage: bash tests/docs-check.sh                         # full check
#        bash tests/docs-check.sh --assets-only <site-dir>
# Exit: 0 every check passed
#       1 a check failed
#       2 cannot run: bad usage, zensical missing, or no HTML to scan
# Every message goes to stderr and starts `docs-check: `.

set -u
unset CDPATH BASH_ENV ENV
export LC_ALL=C

SITE_HOST='rehan712.github.io'

# scan_assets <dir> — report every asset URL in <dir>'s *.html and *.css whose
# host is not SITE_HOST; return 1 if any, exit 2 when there is no HTML.
# <a href> is a hyperlink, not an asset, and is never reported.
# shortcut: line-based scan of tags and CSS; requests made by JavaScript are
# not seen (AC-004's network log covers them); move to a headless-browser
# check if the theme starts loading remote assets by script.
scan_assets() {
  local dir="$1" file match url host rc=0
  local tag='<(script|link|img|iframe|source|embed|object|video|audio)[[:space:]]([^>]*[[:space:]])?(src|href|data)=["'\'']?(https?:)?//[^"'\'' >]*'
  local css='(@import[[:space:]]*|url\([[:space:]]*)["'\'']?(https?:)?//[^"'\'') ;]*'
  if [[ ! -d "$dir" ]] || [[ -z "$(find "$dir" -type f -name '*.html' | head -n 1)" ]]; then
    echo "docs-check: no HTML to scan in $dir" >&2
    exit 2
  fi
  while IFS= read -r file; do
    case "$file" in
      *.html) match="$(grep -Eio "$tag" "$file")";;
      *) match="$(grep -Eio "$css" "$file")";;
    esac
    while IFS= read -r url; do
      [[ -n "$url" ]] || continue
      host="$(printf '%s' "$url" | grep -Eio '(https?:)?//[^"'\'') >]*$' \
        | sed -E 's#^(https?:)?//##; s#[/?\#:].*$##' | tr 'A-Z' 'a-z')"
      [[ "$host" != "$SITE_HOST" ]] || continue
      echo "docs-check: third-party asset in $file: $url" >&2
      rc=1
    done <<< "$match"
  done < <(find "$dir" -type f \( -name '*.html' -o -name '*.css' \) | sort)
  return "$rc"
}

if [[ "${1:-}" == --assets-only && $# -eq 2 ]]; then
  scan_assets "$2"
  exit $?
fi
echo 'docs-check: usage: docs-check.sh [--assets-only <site-dir>]' >&2
exit 2
