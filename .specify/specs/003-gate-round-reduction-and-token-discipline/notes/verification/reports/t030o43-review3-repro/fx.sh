#!/usr/bin/env bash
# usage: fx.sh <scripts-kit-root> <snippet-file>   -- runs snippet with helpers from the copy, SCRIPTS from the kit
export TMPDIR=/private/tmp/rev3-t030o43/tmp
KITROOT="$1"; SNIP="$2"
SANDBOX="$(mktemp -d /private/tmp/rev3-t030o43/tmp/sb.XXXXXX)"; export SANDBOX
. /private/tmp/rev3-t030o43/kit/tests/helpers.sh
SCRIPTS="$KITROOT/scripts"
ANALYZE="$SCRIPTS/sdd-analyze.sh"
. "$SNIP"
rm -rf "$SANDBOX"
