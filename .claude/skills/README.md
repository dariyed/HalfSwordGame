# Custom skills — Half Sword (Roblox)

Project-specific skills that support development. Each is a `<name>/SKILL.md` with a
trigger-rich `description` so Claude Code auto-loads it at the relevant moment. They are also
surfaced at session start by `../hooks/session-start.sh` and referenced from `../../CLAUDE.md`.

| Skill | Fires when you're working on… |
| --- | --- |
| [`teach-dariy`](teach-dariy/SKILL.md) | every session — how to explain, hand off, and celebrate with a 15-yo learner |
| [`github-issue-flow`](github-issue-flow/SKILL.md) | issues, branches, commits, PRs — the one-issue-one-PR loop |
| [`green-gate-tests`](green-gate-tests/SKILL.md) | Tier-1 Lune tests, lint/format, CI — the "green before play-test" gate |
| [`rojo-studio-sync`](rojo-studio-sync/SKILL.md) | syncing code into Studio, building place files, connection trouble |
| [`studio-mcp-playtest`](studio-mcp-playtest/SKILL.md) | driving Studio via MCP for Tier-2 specs + smoke-tests |
| [`physics-weapon-control`](physics-weapon-control/SKILL.md) | the mouse-driven sword: AlignPosition/AlignOrientation, feel knobs, ownership (Issues #4–#6) |
| [`scriptable-camera`](scriptable-camera/SKILL.md) | the custom orbit/first-person camera (Issue #3) |
| [`roblox-api-check`](roblox-api-check/SKILL.md) | any unfamiliar Roblox API — check docs before trusting memory |
| [`halt`](halt/SKILL.md) | stopping for now — save your place to `halt.md` so next session resumes cleanly |
| [`retro`](retro/SKILL.md) | finished an issue/PR — quick look-back (went well / was hard / learned / win) into `docs/retro-log.md` |

## How they were made

Researched from the project's own brief (`docs/research/half-sword-mechanics.md`, `docs/SETUP.md`,
`docs/ROADMAP.md`) and the Fieldcraft skill protocols, then written as atomic, single-technique
recipes. To add or change one, keep it to one technique, give the `description` real trigger
phrases, and link related skills under `See also`.
