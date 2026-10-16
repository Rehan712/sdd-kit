#!/usr/bin/env bash
K="$1"; export TMPDIR=/private/tmp/rev3-t030o43/tmp
d="$(mktemp -d "$TMPDIR/st.XXXXXX")"; mkdir -p "$d/a" "$d/b"
waiver='- 2026-09-27T15:55:36Z — waiver: gate=opponent; round=4; after=3; by=someone; reason=a fixture reason'
for v in a b; do
  {
    printf -- '---\nspec: x\n---\n\n## Where things stand\n\nState.\n'
    [[ "$v" == a ]] && printf '\n````text\nan example the author never closed\n'
    printf '\n## Decisions log\n\n%s\n\n```\n- 2026-09-06 — quoted\n````\n\n## Open questions / blockers\n\n- none\n' "$waiver"
  } > "$d/$v/STATUS.md"
done
bash -c '. "$1/scripts/verification-lib.sh"; vf_semantic_file .specify/specs/x/STATUS.md "$2/a/STATUS.md" "$2/a.sem"; vf_semantic_file .specify/specs/x/STATUS.md "$2/b/STATUS.md" "$2/b.sem"' _ "$K" "$d"
cmp -s "$d/a.sem" "$d/b.sem" && echo "identity views: IDENTICAL" || echo "identity views: differ"
for v in a b; do bash -c '. "$1/scripts/verification-lib.sh"; vf_round_authorized "$2" opponent 4 2026-09-27T00:00:00Z' _ "$K" "$d/$v" > "$d/$v.out" 2>&1; echo "$v: vf_round_authorized rc=$? $(head -c 160 "$d/$v.out" | tr '\n' '|')"; done
rm -rf "$d"
