#!/usr/bin/env bash
# spec-graph.sh — the task dependency graph of tasks.md, computed, not recalled.
#
# The orchestrator used to "build the DAG" in its head on every run; a model
# that misreads one marker starts a task early or batches two that collide.
# This script is the one authority: it derives the edges from tasks.md, proves
# the graph is acyclic, and names the next batch that is safe to start.
#
# Edges (a task waits for every task it depends on to be [x]):
#   1. Stage order is hard: a task depends on every task in an earlier stage.
#   2. Inside a stage tasks run in written order, except that two [P] tasks
#      never wait for each other.
#   3. Follow-ups (T###<class><n>) are ready as soon as they are opened. Every
#      other task in their stage and in later stages waits for them, and so
#      does every gate, wherever the follow-up sits — a gate never judges code
#      a follow-up is about to change.
#   4. `Depends on: T###[, T###…]` adds an edge. It never removes one. Only
#      the leading id list counts; ids in a trailing reason are prose.
# A batch is the ready tasks that cannot collide: a gate (*Agent:* task) runs
# alone; two tasks share a batch only when both declare *Files:* and no path
# of one equals or contains a path of the other (`lib`, `lib/` and `lib/...`
# all own the directory; [repo:] tags keep umbrella repos apart).
#
# Usage:
#   spec-graph.sh check <spec-dir>   # dangling/self deps, duplicate ids, cycles
#   spec-graph.sh next  <spec-dir>   # the batch to start now (empty = all done)
#   spec-graph.sh waves <spec-dir>   # every remaining batch, in order
#   spec-graph.sh --help
#
# next prints TSV: id  state  kind  stage  flags  subject
#   state: todo|doing   kind: task|followup|gate|ship   flags: P,hard,repo:x or -
# waves prints the same rows with the wave number as a first column.
#
# Exit: 0 = ok; 1 = no tasks.md, or the graph is invalid (nothing is printed
#       from an invalid graph); 2 = usage.

set -euo pipefail
export LC_ALL=C   # byte-wise parsing, the same on every host

HUB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
. "$HUB_DIR/scripts/lib.sh"

case "${1:-}" in --help|-h) usage_from_header "$0"; exit 0 ;; esac
MODE="${1:-}"
SPEC_DIR="${2:-}"
case "$MODE" in
  check|next|waves) ;;
  *) usage_from_header "$0" >&2; exit 2 ;;
esac
[[ -n "$SPEC_DIR" && $# -eq 2 ]] || { usage_from_header "$0" >&2; exit 2; }
TASKS="$SPEC_DIR/tasks.md"
[[ -f "$TASKS" ]] || { echo "no tasks.md in $SPEC_DIR" >&2; exit 1; }

awk -v mode="$MODE" '
  function err(msg) { print "error: " msg > "/dev/stderr"; errors++ }
  # ids(line) — the leading id list after "Depends on:", space-separated.
  function ids(s,   out, t) {
    out = ""; sub(/^.*Depends on:\*?/, "", s)
    while (match(s, /^[ \t,]*(and[ \t]+)?T[0-9][0-9][0-9][a-z0-9]*/)) {
      t = substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1)
      sub(/^.*T/, "T", t); out = out " " t
    }
    return out
  }
  # collide(a, b) — true unless both tasks prove their paths are disjoint.
  function collide(a, b,   fa, fb, na, nb, i, j, x, y) {
    if (repo[a] != repo[b]) return 0
    na = split(files[a], fa, "\n"); nb = split(files[b], fb, "\n")
    if (na == 0 || nb == 0) return 1
    for (i = 1; i <= na; i++) for (j = 1; j <= nb; j++) {
      x = fa[i]; y = fb[j]
      if (x == y || index(y, x "/") == 1 || index(x, y "/") == 1) return 1
    }
    return 0
  }
  # batch() — fill pick[1..npick] with the ready tasks that cannot collide.
  function batch(   i, j, k, ok) {
    npick = 0
    for (i = 1; i <= n; i++) {
      if (done[i]) continue
      ok = 1
      for (j = 1; j <= n && ok; j++) if (dep[i, j] && !done[j]) ok = 0
      if (!ok) continue
      if (npick && (kind[i] == "gate" || kind[pick[1]] == "gate")) continue
      for (k = 1; k <= npick && ok; k++) if (collide(i, pick[k])) ok = 0
      if (ok) pick[++npick] = i
    }
  }
  function row(i,   f) {
    f = (par[i] ? ",P" : "") (hard[i] ? ",hard" : "") (repo[i] != "" ? ",repo:" repo[i] : "")
    return id[i] "\t" (doing[i] ? "doing" : "todo") "\t" kind[i] "\t" stage_name[stg[i]] "\t" (f == "" ? "-" : substr(f, 2)) "\t" subj[i]
  }

  /^##[^#]/ {
    s = $0; sub(/^##[ \t]*/, "", s); sub(/[ \t\r]+$/, "", s)
    stage_name[++stages] = s; cur = 0; next
  }
  /^- \[[ xX~]\] \*\*T[0-9][0-9][0-9][a-z0-9]*\*\*/ {
    cur = ++n
    match($0, /T[0-9][0-9][0-9][a-z0-9]*/); id[n] = substr($0, RSTART, RLENGTH)
    if (id[n] in idx) err("duplicate task id " id[n]); else idx[id[n]] = n
    done[n] = ($0 ~ /^- \[[xX]\]/); doing[n] = ($0 ~ /^- \[~\]/); stg[n] = stages
    rest = substr($0, RSTART + RLENGTH + 2)
    while (match(rest, /^[ \t]*\[[^]]*\]/)) {
      m = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH)
      sub(/^[ \t]*\[/, "", m); sub(/\]$/, "", m)
      if (m == "P") par[n] = 1
      else if (m == "hard") hard[n] = 1
      else if (m ~ /^repo:/) repo[n] = substr(m, 6)
    }
    sub(/^[ \t]*(\342\200\224|-)?[ \t]*/, "", rest); sub(/[ \t\r]+$/, "", rest); subj[n] = rest
    next
  }
  cur && /^[ \t]+- \*Files:\*/ {
    s = $0
    while (match(s, /`[^`]+`/)) {
      f = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
      sub(/(\/|\/?\.\.\.)$/, "", f)   # `lib/`, `lib/...` -> `lib`: the directory
      files[cur] = files[cur] (files[cur] == "" ? "" : "\n") f
    }
  }
  cur && /^[ \t]+- \*?Depends on:\*?/ { want[cur] = want[cur] ids($0) }
  cur && /\*Agent:\*/ { agent[cur] = 1 }
  cur && /\*Verify kind:\*/ { proof[cur] = 1 }

  END {
    for (i = 1; i <= n; i++) {
      if (id[i] ~ /^T[0-9][0-9][0-9]./) kind[i] = "followup"
      else if (agent[i] && !proof[i]) kind[i] = "gate"
      else if (stage_name[stg[i]] == "Ship" && !proof[i]) kind[i] = "ship"
      else kind[i] = "task"
    }
    for (i = 1; i <= n; i++) {
      if (kind[i] != "followup") for (j = 1; j <= n; j++) {
        if (j == i) continue
        if (stg[j] < stg[i]) dep[i, j] = 1
        else if (kind[j] == "followup" && (stg[j] == stg[i] || kind[i] == "gate")) dep[i, j] = 1
        else if (stg[j] == stg[i] && j < i && !(par[i] && par[j])) dep[i, j] = 1
      }
      m = split(want[i], w, " ")
      for (k = 1; k <= m; k++) {
        if (!(w[k] in idx)) err(id[i] " depends on " w[k] ", which is not a task")
        else if (idx[w[k]] == i) err(id[i] " depends on itself")
        else dep[i, idx[w[k]]] = 1
      }
    }
    # Kahn: peel tasks whose dependencies are all peeled; a remainder is a cycle.
    left = n
    do {
      peeled = 0
      for (i = 1; i <= n; i++) {
        if (gone[i]) continue
        ok = 1
        for (j = 1; j <= n && ok; j++) if (dep[i, j] && !gone[j]) ok = 0
        if (ok) { mark[i] = 1; peeled++ }
      }
      for (i = 1; i <= n; i++) if (mark[i] && !gone[i]) { gone[i] = 1; left-- }
    } while (peeled && left)
    if (left) {
      s = ""; for (i = 1; i <= n; i++) if (!gone[i]) s = s " " id[i]
      err("dependency cycle among:" s)
    }
    if (errors) exit 1

    if (mode == "check") {
      open = 0; for (i = 1; i <= n; i++) if (!done[i]) open++
      print "graph ok: " n " tasks, " open " open"
    } else if (mode == "next") {
      batch(); for (k = 1; k <= npick; k++) print row(pick[k])
    } else {
      for (wave = 1; ; wave++) {
        batch(); if (!npick) break
        for (k = 1; k <= npick; k++) { print wave "\t" row(pick[k]); done[pick[k]] = 1 }
      }
    }
  }
' "$TASKS"
