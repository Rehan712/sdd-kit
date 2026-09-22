from pathlib import Path
p=Path('scripts/verification-lib.sh');s=p.read_text()
s=s.replace('  local spec="$1" roots="$2" out="$3" repo tmp\n', '  local spec="$1" roots="$2" out="$3" repo tmp index=0 cache="${4:-}"\n')
s=s.replace('''    cat "$tmp" >> "$out"
  done < "$roots"
  vf_hash "$out"
)''','''    cat "$tmp" >> "$out"
    if [[ -n "$cache" ]]; then
      mkdir -p "$cache" || return 3
      cp "$tmp" "$cache/input-$index.nul" || return 3
    fi
    index=$((index+1))
  done < "$roots"
  vf_hash "$out"
)

# Invocation-local snapshots are bounded by the caller's fresh before/after
# whole-source comparison. Never persist/reuse this cache across invocations.
vf_root_input() {
  local roots="$1" cache="$2" wanted="$3" repo index=0
  while IFS= read -r -d '' repo; do
    if [[ "$repo" == "$wanted" ]]; then printf '%s/input-%s.nul\\n' "$cache" "$index"; return 0; fi
    index=$((index+1))
  done < "$roots"
  return 3
}''',1)
s=s.replace('''  [[ "$1" == -- ]] || return 2; shift
  local tmp dir cap='' cached=0 rc=0 argv
''','''  local invocation_inputs=''
  if [[ "$1" == --inputs ]]; then [[ $# -ge 3 ]] || return 2; invocation_inputs="$2"; shift 2; fi
  [[ "$1" == -- ]] || return 2; shift
  local tmp dir cap='' cached=0 rc=0 argv
''',1)
s=s.replace('''  vf_snapshot "$spec" "$repo" "$repo" "$tmp/inputs" >/dev/null || { rm -rf "$tmp"; return 3; }
  # Reuse only''','''  if [[ -n "$invocation_inputs" ]]; then
    cp "$invocation_inputs" "$tmp/inputs" || { rm -rf "$tmp"; return 3; }
  else
    vf_snapshot "$spec" "$repo" "$repo" "$tmp/inputs" >/dev/null || { rm -rf "$tmp"; return 3; }
  fi
  # Reuse only''',1)
s=s.replace('source="$(vf_gate_snapshot "$spec" "$tmp/roots.nul" "$tmp/inputs.nul")"', 'source="$(vf_gate_snapshot "$spec" "$tmp/roots.nul" "$tmp/inputs.nul" "$tmp/root-inputs")"')
for kind in ['"task:$task"', '"checker:$command"', 'gate_check', 'checkpoint']:
 s=s.replace(kind+' -- ',kind+' --inputs "$(vf_root_input "$tmp/roots.nul" "$tmp/root-inputs" "$repo")" -- ')
a=s.index('vf_floor_validate()');b=s.index('vf_manual_current()',a)
part=s[a:b].replace('source v f=() repo','source v f=() repo manifest')
part=part.replace('vf_gate_snapshot "$spec" "$tmp/roots" "$tmp/inputs"', 'vf_gate_snapshot "$spec" "$tmp/roots" "$tmp/inputs" "$tmp/root-inputs"')
part=part.replace('''    vf_snapshot "$spec" "$repo" "$repo" "$tmp/repo-inputs" >/dev/null || return 3
    vf_capture_check "$spec" "${f[4]}" "$tmp/repo-inputs" current || return 3''','''    manifest="$(vf_root_input "$tmp/roots" "$tmp/root-inputs" "$repo")" || return 3
    vf_capture_check "$spec" "${f[4]}" "$manifest" current || return 3''')
part=part.replace('''  printf '%s\\n' "$source"
)''','''  [[ "$source" == "$(vf_gate_snapshot "$spec" "$tmp/roots" "$tmp/after")" ]] || { echo 'floor inputs changed during validation' >&2; return 3; }
  printf '%s\\n' "$source"
)''',1)
s=s[:a]+part+s[b:]
p.write_text(s)
