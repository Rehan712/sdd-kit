#!/usr/bin/env bash
# scout-guard.sh — PreToolUse(Bash) backstop for the read-only scout.
#
# agents/sdd-scout.md carries no Edit/Write tool, but it does carry Bash, and
# Bash can write. The persona forbids state changes; this hook makes the
# expensive ones fail instead of resting on a recon-tier model remembering a
# rule. Claude Code pipes the pending tool call to the hook as JSON on stdin:
# exit 2 blocks the call and hands stderr back to the agent, exit 0 lets it run.
#
# Only the `command` value is judged — the tool call's `description` is prose
# and never blocks anything. Blocked, in command position only (the start of
# the command, or after `;` `&&` `||` `| ` `$(` ` (` `-exec` a backtick or a
# newline) — so a *search* for the same words, `rg 'git commit'`, still runs:
#   - git commands that write (add, commit, push, reset, checkout, stash,
#     update-ref, config without --get/--list, ...)
#   - kit scripts that record state: spec-run / spec-gate / spec-task /
#     spec-pr / spec-worktree / spec-dispatch / spec-loop / spec-resume /
#     new-spec, and `spec-status.sh ... set`
#   - file mutation: rm, rmdir, mv, cp, touch, mkdir, dd, truncate, tee,
#     chmod, chown, ln, in-place sed / perl, `find -delete`, a download to a
#     file (`curl -o`, `wget`), and output redirected to a file (`> f`,
#     `>> f`; /dev/null and `2>&1` are fine)
#   - installs, publishes and deploys (npm/pnpm/yarn/bun, cargo, pip, uv,
#     poetry, cdk, sam, terraform, ..., `aws` verbs that write, and gh
#     commands that write, `gh api -X POST` included)
#
# A backstop, not a sandbox: it reads the payload with awk and grep (no jq —
# the kit's floor is bash + POSIX tools), so a write inside a quoted
# `bash -c "..."`, an interpreter one-liner (`python -c`, `node -e`), a
# variable or a script file gets through, and a test command the brief names
# may still write build output. Anything unrecognized is allowed; the
# persona's rules still apply.
#
# Usage: scout-guard.sh < pretooluse-payload.json
# Exit: 0 = allowed, 2 = blocked (reason on stderr).

set -u
export LC_ALL=C

payload="$(cat)"
[[ -n "$payload" ]] || exit 0

# The command, still JSON-escaped: the string value of the first "command"
# key, up to its closing quote. Every other field (description, cwd, ...) is
# dropped here, so prose about `rm` cannot block a search.
cmd="$(printf '%s' "$payload" | awk '
  { s = s $0 "\n" }
  END {
    if (!match(s, /"command"[ \t]*:[ \t]*"/)) exit
    s = substr(s, RSTART + RLENGTH)
    match(s, /^([^"\\]|\\.)*/)
    printf "%s", substr(s, 1, RLENGTH)
  }')"
[[ -n "$cmd" ]] || exit 0

# Command position: a newline in the command is the two characters `\n` in
# the escaped value, which is what the `\\n` alternative matches.
POS='(^|;|&&|\|\||\|[[:space:]]|\$\(|[[:space:]]\(|-exec(dir)?[[:space:]]|\\n|`)[[:space:]]*'
# Wrappers and VAR=value prefixes that may precede the real command word.
PRE='((sudo|command|exec|time|nohup|env|xargs|npx|bunx)[[:space:]]+)*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
# End of a command word: `git merge` is a write, `git merge-base` is not.
END='([^[:alnum:]_-]|$)'

hit() { printf '%s' "$cmd" | grep -Eq -- "${POS}${PRE}$1"; }

deny() {
  echo "sdd-scout is read-only: $1 belongs to the invoker, not the scout. Do not work around this — finish the question with read-only commands and put what you could not do under UNKNOWN." >&2
  exit 2
}

GIT='git([[:space:]]+(-C|-c|--git-dir|--work-tree)([[:space:]]+|=)[^[:space:]]+)*[[:space:]]+'
hit "${GIT}(add|am|apply|checkout|cherry-pick|clean|commit|merge|mv|pull|push|rebase|reset|restore|revert|rm|switch|update-ref)${END}" \
  && deny 'a git command that writes'
if hit "${GIT}config${END}" && ! hit "${GIT}config[[:space:]]+([^;&|]*[[:space:]])?(--get[a-z-]*|--list|-l|--show-[a-z]+)${END}"; then
  deny 'git config'
fi
if hit "${GIT}stash${END}" && ! hit "${GIT}stash[[:space:]]+(list|show)${END}"; then
  deny 'git stash'
fi
if hit "${GIT}worktree${END}" && ! hit "${GIT}worktree[[:space:]]+list${END}"; then
  deny 'git worktree'
fi
hit "${GIT}(branch[[:space:]]+(-[dDmMcCf]|--(delete|move|copy|force))|tag[[:space:]]+-[adsf])${END}" \
  && deny 'changing a branch or tag'

# The optional interpreter and any path prefix: `bash "$S/spec-gate.sh"`.
SH='((bash|sh|zsh)[[:space:]]+)?[^[:space:];&|]*'
hit "${SH}(spec-(run|gate|task|pr|worktree|dispatch|loop|resume|resume-scheduler)|new-spec)\\.sh${END}" \
  && deny 'a kit script that records state'
hit "${SH}spec-status\\.sh[^;&|]*[[:space:]]set${END}" \
  && deny 'spec-status.sh set'

hit "(rm|rmdir|mv|cp|touch|mkdir|dd|truncate|tee|chmod|chown|ln)${END}" \
  && deny 'changing files'
hit "find[[:space:]]+([^;&|]*[[:space:]])?-delete${END}" \
  && deny 'find -delete'
hit "curl[[:space:]]+([^;&|]*[[:space:]])?(-[[:alpha:]]*[oO]|--output|--remote-name)${END}" \
  && deny 'a download to a file'
if hit "wget${END}" && ! hit "wget[[:space:]][^;&|]*-[[:alpha:]]*O[[:space:]]*-${END}"; then
  deny 'a download to a file'
fi
# Output redirected to a file. Quoted text is dropped first — a pattern like
# 'a => b' or "<div>" is not a redirect — then the harmless targets.
# shortcut: quotes are paired by a regex, so a string holding an escaped quote
# can hide or expose a `>`; upgrade to a real tokenizer if that ever bites.
bare="$(printf '%s' "$cmd" | sed -E "s/'[^']*'//g"';s/\\"([^\\]|\\[^"])*\\"//g;s/[0-9&]?>>?[[:space:]]*\/dev\/(null|stderr|stdout)//g;s/[0-9]?>&[0-9-]//g')"
case "$bare" in
  *'>'*) deny 'redirecting output to a file' ;;
esac
hit "(sed|perl)[[:space:]]+([^;&|]*[[:space:]])?(-[[:alpha:]]*i[[:alpha:]]*([.=][^[:space:]]*)?|--in-place[^[:space:]]*)[[:space:]]" \
  && deny 'an in-place edit'

hit "(npm|pnpm|yarn|bun)[[:space:]]+(install|i|ci|add|remove|rm|uninstall|publish|link|update|upgrade)${END}" \
  && deny 'installing or publishing packages'
hit "cargo[[:space:]]+(install|publish|add|remove|update|yank|lambda[[:space:]]+deploy)${END}" \
  && deny 'installing or publishing crates'
hit "(pip|pip3|poetry|uv|uv[[:space:]]+pip)[[:space:]]+(install|uninstall|add|remove|sync|update|publish)${END}" \
  && deny 'installing or publishing packages'
hit "(cdk|sam|sls|serverless|terraform|tofu|pulumi)[[:space:]]+(deploy|destroy|apply|import|up)${END}" \
  && deny 'a deploy'
hit "aws[[:space:]]+[^;&|]*[[:space:]](rm|mb|rb|mv|cp|sync|(create|delete|put|update|remove|terminate|start|stop|run|invoke|send|publish|deploy|attach|detach|modify|register|deregister|tag|untag)(-[a-z-]+)?)${END}" \
  && deny 'an AWS call that writes'
hit "gh[[:space:]]+(pr|issue|release|repo|workflow|run)[[:space:]]+(create|merge|close|reopen|comment|edit|delete|review|ready|rerun|cancel|run)${END}" \
  && deny 'a GitHub write'
hit "gh[[:space:]]+api[[:space:]][^;&|]*(-X|--method)[[:space:]=]*(POST|PUT|PATCH|DELETE)${END}" \
  && deny 'a GitHub write'

exit 0
