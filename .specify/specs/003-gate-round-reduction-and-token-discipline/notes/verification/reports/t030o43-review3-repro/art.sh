#!/usr/bin/env bash
K="$1"; label="$2"; evidence="$3"; export TMPDIR=/private/tmp/rev3-t030o43/tmp
d="$(mktemp -d "$TMPDIR/art.XXXXXX")"; mkdir -p "$d/shots"; : > "$d/shots/a.png"
printf -- '---\nspec: 001-legacy\n---\n\n# Spec\n\n- AC-001 — x\n' > "$d/spec.md"
printf -- '---\nspec: 001-legacy\n---\n\n## Backend\n\n- [x] **T001** — Legacy task\n  - *Acceptance:* legacy\n  - *Evidence:* %b\n' "$evidence" > "$d/tasks.md"
for l in C en_US.UTF-8; do
  args=(); for name in $(compgen -e); do case "$name" in LC_*) args+=(-u "$name");; esac; done
  out="$(env ${args[@]+"${args[@]}"} LANG="$l" bash "$K/scripts/spec-evidence.sh" "$d" 2>&1)"; rc=$?
  printf '[%s] %-12s rc=%s %s\n' "$label" "$l" "$rc" "$(printf '%s' "$out" | grep -E 'artifact|sound' | tr '\n' '|' | cut -c1-160)"
done
rm -rf "$d"
