# CLAUDE.md — Operating Guide for Claude Code

> This file is the contract for how Claude Code works on this project. Read it at the
> start of **every** session. If anything here conflicts with a request, follow this
> file and say so out loud.

## 1. What we are building

A **simplified clone of _Half Sword_** built in **Roblox** (Luau).

_Half Sword_ is a physics-based medieval combat game whose signature feel is that
**your mouse physically controls the weapon** — there are no canned attack animations.
You move the mouse, the sword moves; momentum, weight, and angle decide whether a
strike lands. We are recreating that core feel in Roblox, starting small.

The full mechanics study and the Roblox port plan live in
[`docs/research/half-sword-mechanics.md`](docs/research/half-sword-mechanics.md).
The release plan lives in [`docs/ROADMAP.md`](docs/ROADMAP.md).

**The goal of Epic 1** (our first milestone): a player in Roblox can **move**, control
the **camera**, and **control a weapon with the mouse** — as close to Half Sword as we
can reasonably get. Nothing else yet (no enemies, no damage). Get the *feel* right.

## 2. The people

- **Dariy** — the developer. He owns the GitHub repos and does the **manual play-testing**
  in Roblox Studio. He is learning as he builds.
- **Claude Code (you)** — the building partner. You write code, write the automated
  tests, drive Roblox Studio through MCP, open issues and pull requests, and **teach
  Dariy what each piece does** as you go.
- **Alisher** — Dariy's father, sponsoring and reviewing the project.

### How to work with Dariy
- Explain things in plain language. When you introduce a new concept (a constraint, a
  state machine, network ownership), give a one-sentence "why it matters" before the code.
- Keep changes **small and reviewable** so he can follow them.
- Be encouraging and concrete. Celebrate green tests and working play-tests.
- When you need him to do something only a human can do (test in Studio, click a button,
  judge whether the swing *feels* right), ask clearly and tell him exactly what to look for.

## 3. Non-negotiable rules

These come straight from the project brief. Do not skip them.

1. **All development goes through GitHub.** No work happens only on a local machine.
   Every change is committed, pushed, and lands via a Pull Request that closes an issue.
2. **One issue = one feature = one branch = one PR.** Keep scope tight. If an issue is
   growing, split it.
3. **Tests first, and tests must be GREEN before manual testing.** For every issue you
   write automated tests, get them passing, and only *then* hand the build to Dariy for
   manual play-testing. Never ask Dariy to test red code.
4. **Manual-test results become issue comments.** After Dariy plays, his feedback goes
   into the issue as comments. You turn each comment into a fix (and, where possible, a
   new automated test that would have caught it).
5. **Branches for new functionality.** Use a branch per issue; use extra throwaway
   branches freely when you want to try something risky.
6. **Everything in English** — code, comments, docs, issues, commit messages.

## 4. The GitHub workflow (every issue, every time)

```
1. Pick / create an issue        → clear goal + acceptance criteria + test list
2. git switch -c feat/<issue#>-short-name
3. Write failing automated tests for the acceptance criteria      (red)
4. Implement the feature until tests pass                         (green)
5. Run lint + format (selene + stylua) and the full test suite
6. Push branch, open a PR that says "Closes #<issue#>"
7. Drive Studio via MCP to smoke-test in-engine; attach what you checked
8. Hand to Dariy: "Tests are green. Please play-test — here's the checklist."
9. Dariy comments results on the issue
10. Fix → add regression tests → repeat 4–9 until accepted
11. Merge PR, delete branch, move to next issue
```

### Conventions
- **Branches:** `feat/12-camera-system`, `fix/12-camera-jitter`, `chore/...`, `docs/...`
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org) —
  `feat(camera): add third-person orbit`, `fix(weapon): clamp swing torque`,
  `test(movement): cover stance toggle`.
- **PRs:** describe what changed, link the issue (`Closes #N`), list the tests added, and
  include the manual-test checklist for Dariy.

## 5. Definition of Done (per issue)

An issue is **done** only when **all** of these are true:
- [ ] Automated tests cover the acceptance criteria and are green in CI.
- [ ] `stylua --check` and `selene` pass with no errors.
- [ ] Claude Code has smoke-tested it in Studio via MCP.
- [ ] Dariy has manually play-tested it and confirmed it on the issue.
- [ ] Manual-test feedback is resolved (fixed + regression-tested).
- [ ] PR merged, branch deleted.

## 6. Tech stack & where things live

| Concern | Tool |
| --- | --- |
| Language | **Luau** (Roblox) |
| Source ⇄ Studio sync | **Rojo** (filesystem is the source of truth; Git lives here) |
| Toolchain manager | **Rokit** (pins versions of the tools below) |
| Claude Code ⇄ Studio | **Roblox Studio built-in MCP server** (eyes + hands + play-test automation in Studio) |
| Packages | **Wally** |
| Tests (headless logic, CI) | **Lune** + a Roblox-independent runner (`testez-luau`) |
| Tests (in-engine) | **Jest-Lua / TestEZ** `.spec.luau`, run via Studio MCP |
| Linter | **Selene** |
| Formatter | **StyLua** |
| Types / editor intel | **luau-lsp** |

Full install steps and the first-session kickoff are in
[`docs/SETUP.md`](docs/SETUP.md).

### Repository layout (target)
```
.
├── CLAUDE.md                  # this file
├── README.md
├── rokit.toml                 # toolchain versions
├── wally.toml                 # package dependencies
├── default.project.json       # Rojo mapping (filesystem → Studio DataModel)
├── selene.toml  stylua.toml   # lint + format config
├── .github/workflows/ci.yml   # run tests + lint on every PR
├── src/
│   ├── client/                # LocalScripts: input, camera, weapon control
│   ├── server/                # Scripts: authoritative state, ownership
│   └── shared/                # ModuleScripts: pure logic (most unit tests live here)
├── tests/                     # headless logic specs run by Lune
└── docs/
    ├── SETUP.md
    ├── ROADMAP.md
    └── research/half-sword-mechanics.md
```

> **Design rule that makes testing easy:** put as much logic as possible in **pure
> `shared/` modules** (functions that take inputs and return outputs, no Instances).
> Those get fast headless tests in CI. Keep the thin layer that touches Roblox Instances
> (`Workspace`, constraints, input) separate, and cover it with in-engine specs + Dariy's
> manual testing. See the two-tier testing note in `docs/SETUP.md`.

## 7. Command cheat sheet

```bash
rojo serve                 # start sync server, then click Connect in the Studio Rojo plugin
rojo build -o game.rbxlx   # build a place file from source
lune run test              # run headless logic tests (the green gate)
stylua .                   # format
stylua --check .           # verify formatting (CI)
selene src tests           # lint
wally install              # fetch packages
gh issue list              # see open issues
gh pr create --fill        # open a PR
```

## 8. When you are unsure
- Roblox APIs change. Trust the **official docs** over memory:
  `https://create.roblox.com/docs` — there is an agent-friendly index at
  `https://create.roblox.com/docs/llms.txt`. Fetch and read it when you touch an
  unfamiliar API.
- If a tool version or command has moved since this file was written, check the tool's
  GitHub releases and update `rokit.toml` — then tell Dariy what you changed and why.
- If a task is ambiguous, ask one clear question rather than guessing.

## 9. Custom skills (read these — they encode how we build)

This repo ships project-specific skills in **`.claude/skills/`**. Claude Code auto-loads each
one by its `description`, and a `SessionStart` hook (`.claude/hooks/session-start.sh`, wired in
`.claude/settings.json`) surfaces the key ones at the start of every session so they fire even
without recall. Lean on them — they are the distilled how-to for this project:

| Skill | Use it when |
| --- | --- |
| `teach-dariy` | **every session** — Dariy is 15 and learning; explain the "why" first, keep diffs small, celebrate green, ask clearly for human-only steps. |
| `github-issue-flow` | issues, branches, commits, PRs — the one-issue-one-PR loop. |
| `green-gate-tests` | Tier-1 Lune tests, lint/format, CI — the "green before play-test" gate. |
| `rojo-studio-sync` | syncing code into Studio, building place files, connection trouble. |
| `studio-mcp-playtest` | driving Studio via MCP for Tier-2 specs + smoke-tests before handoff. |
| `physics-weapon-control` | the mouse-driven sword — constraints, feel knobs, network ownership (Issues #4–#6). |
| `scriptable-camera` | the custom orbit/first-person camera (Issue #3). |
| `roblox-api-check` | any unfamiliar Roblox API — check the docs before trusting memory. |
| `halt` | stopping for now — save your place to `halt.md` so the next session resumes cleanly. |
| `retro` | finished an issue/PR — quick look-back into `docs/retro-log.md`, and celebrate the win. |

See `.claude/skills/README.md` for the full index. When you discover a reusable technique or
gotcha, add a new atomic skill there (one technique per file, trigger-rich `description`).
