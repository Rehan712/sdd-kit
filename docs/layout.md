# What's in the box

```
sdd-kit/
├── constitution.md           # Cross-project engineering principles — edit to taste
├── registry.example.yml      # → registry.yml (machine-local, gitignored)
├── models.example.yml        # → models.yml (machine-local): model policy — which
│                             # model+effort runs each role; build/ holds the
│                             # stamped copies (generated, gitignored)
├── system-map.yml            # Repo topology + contracts (from system-map.example.yml;
│                             # gitignored here — commit it in your team's fork)
├── specs/                    # Umbrella specs — one dir per multi-repo feature
├── briefs/                   # Standing per-repo context — seeded by /sdd:onboard,
│                             # written by plan, refreshed by retro (Source: sha tracked)
├── skills/                   # CANONICAL skills: sdd-specify/plan/tasks/implement/
│                             # review/retro/onboard/go (autopilot)
├── agents/                   # Gates (opponent, reality-check), security-reviewer,
│                             # test-engineer, sdd-orchestrator, sdd-scout (read-only
│                             # recon), and 12 stack experts
│                             # (rust, javascript, python, aws, react, nextjs,
│                             # loopback4, expo-rn, bun-monorepo, aws-cdk-lambda-ts,
│                             # rust-aws-lambda, firebase-rtk-codegen)
├── templates/                # spec/plan/tasks/STATUS/ADR/brief/retro templates,
│                             # stack-routing.md (THE routing table), routing-template.md
│                             # (a project's own table), umbrella-guide.md,
│                             # official-skills.md (vendor skills the kit prefers)
│   ├── stack-overlays/       # per-stack conventions — one per expert above,
│   │                         # plus monorepo + troposphere (overlay-only)
│   ├── style-guides/         # rust.md, typescript.md — digests of the Google
│   │                         # style guides the Rust/TS overlays point at
│   └── examples/             # the golden example (001-api-key-expiry): a complete
│                             # spec→plan→tasks set the phase skills calibrate
│                             # against — CI keeps it passing sdd-analyze
├── knowledge/                # Cross-project lessons — grows via /sdd:retro
├── plugin/                   # The installer plugin (one skill: sdd-setup) for Claude
│                             # Code, Codex, Copilot, Cursor and Antigravity; listed by
│                             # .claude-plugin/ and .cursor-plugin/marketplace.json
├── scripts/                  # everything on the Scripts page
└── tests/                    # the kit's own test suite (tests/run.sh)
```
