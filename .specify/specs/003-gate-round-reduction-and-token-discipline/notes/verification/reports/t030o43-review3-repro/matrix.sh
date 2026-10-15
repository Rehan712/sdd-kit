K="$1"; export TMPDIR=/private/tmp/rev3-t030o43/tmp; d="$(mktemp -d "$TMPDIR/mx.XXXXXX")"
printf -- '---\nspec: x\n---\n\n- AC-001 — one\302\240criterion\n' > "$d/spec.md"
bash -c '. "$1/scripts/verification-lib.sh"; vf_ac_catalog "$2" "$2/acs"' _ "$K" "$d" || echo "catalog rc=$?"
text="$(tr '\0' '\n' < "$d/acs" | sed -n 2p)"; dig="$(tr '\0' '\n' < "$d/acs" | sed -n 3p)"
printf 'catalog text: '; printf '%s\n' "$text" | LC_ALL=C sed -n l
for cell in "one$(printf '\302\240')criterion" "one criterion"; do
  printf '| AC-001 | %s; sha256:%s | CAP-1; review: x | %s | PASS |\n' "$cell" "$dig" aaaa > "$d/block"
  bash -c '. "$1/scripts/verification-lib.sh"; vf_matrix_parse "$2/block" "$2/m"' _ "$K" "$d"
  got="$(tr '\0' '\n' < "$d/m" | sed -n 2p)"
  [[ "$got" == "$text; sha256:$dig" ]] && r=EQUAL || r=DIFFER
  printf 'cell written %-28s -> parsed %s -> %s\n' "$(printf '%s' "$cell" | LC_ALL=C sed -n l)" "$(printf '%s' "${got%%;*}" | LC_ALL=C sed -n l)" "$r"
done
rm -rf "$d"
