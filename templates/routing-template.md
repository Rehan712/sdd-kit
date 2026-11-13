# Project routing — <project name>

<!--
Copy to <project>/.specify/routing.md and commit it. It names THIS project's
own planning, implementation and review skills and agents, per file signal.
The kit reads it before its own table (~/.sdd/templates/stack-routing.md
§Project routing) — through ~/.sdd/scripts/project-routing.sh, never by eye.

Check it:  ~/.sdd/scripts/project-routing.sh check <project>
Try it:    ~/.sdd/scripts/project-routing.sh match <project> implement apps/android/Foo.kt

Signal   comma-separated globs on repo-relative paths. `*` crosses `/`, so
         `*.kt` matches any depth; `apps/tv/` is the whole directory; a bare
         `*` is every file. Rows are tried top to bottom.
Cells    comma-separated names; leave empty for none. A name is, in order: a
         project agent (.claude/agents/<name>.md), a project skill
         (.claude/skills/<name>/SKILL.md or .agents/skills/<name>/SKILL.md),
         a kit agent, a kit skill. A plugin skill is written plugin:skill.
Plan       loaded by /sdd:plan when the spec touches the signal.
Implement  an agent IS the writer for matching tasks; a skill is loaded by
           the writer the kit routes to. One writer per row is enough.
Review     runs once per spec over the branch diff, before the opponent gate.
           Ship reviewers as agents with `tools:` limited to read-only ones —
           a skill hosted on a general agent is only told not to edit.

Delete the example rows. Column order is free; a column you do not use can go.
-->

| Signal | Plan | Implement | Review |
|---|---|---|---|
| `apps/android/**`, `*.kt`, `*.gradle*` | | `android-implementer` | `android-reviewer` |
| `apps/ios/**`, `*.swift` | | `ios-implementer` | `ios-reviewer` |
| `apps/tv/**` | | `bigscreen-implementer` | `bigscreen-reviewer` |
| `*` | `acme-architecture` | | |
