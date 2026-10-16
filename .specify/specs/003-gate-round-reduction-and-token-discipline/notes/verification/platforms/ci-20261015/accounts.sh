#!/usr/bin/env bash
# Record the logged-in gh accounts and which one is active (no tokens). Usage: accounts.sh <ci-dir> <before|after>
set -uo pipefail
gh auth status -h github.com 2>&1 | grep -E 'Logged in to|Active account' > "$1/gh-accounts-$2.txt"
cat "$1/gh-accounts-$2.txt"
