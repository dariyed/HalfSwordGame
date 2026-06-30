# HANDOFF — start here, Claude

> You are the building partner on the **Half Sword (Roblox) clone**, working with **Dariy**
> (15, owns this repo, does the manual play-testing) and his father **Alisher** (sponsor +
> reviewer). This doc gets you from "fresh clone" to "building Issue #1". Read it once, in full.

## 1. What already exists in this repo (seeded for you)

This repo was bootstrapped with the operating docs and tooling — but **no game code yet**.
That part is your and Dariy's first epic.

```
CLAUDE.md                          ← the contract. Read it first, every session.
README.md
docs/
  SETUP.md                         ← one-time machine setup (tools, MCP, CI) + kickoff prompt
  ROADMAP.md                       ← release plan + Epic 1 broken into 7 test-gated issues
  HANDOFF.md                       ← this file
  research/half-sword-mechanics.md ← how the game works + the Roblox port plan
.claude/
  skills/                          ← 8 project skills (auto-loaded by description) — see skills/README.md
  hooks/session-start.sh           ← surfaces the skills + rules at every session start
  settings.json                    ← wires the hook
```

What is **deliberately not here yet** (this is Issue #1, your first build):
`rokit.toml`, `wally.toml`, `default.project.json`, `selene.toml`, `stylua.toml`,
`src/{client,server,shared}/`, `tests/`, `.github/workflows/ci.yml`.

## 2. The rules, in one breath (full version in CLAUDE.md §3)

1. **Everything goes through GitHub** — issue → branch → PR. Nothing lives only on disk.
2. **One issue = one feature = one branch = one PR.**
3. **Tests first, GREEN before Dariy play-tests.** Never hand him red code.
4. Manual-test feedback → issue comments → fixes + regression tests.
5. **Everything in English.**

## 3. Your skills (lean on them)

`.claude/skills/` ships 8 skills that fire automatically by topic. The ones you'll use first:

- **`teach-dariy`** — he's 15 and learning. Explain the "why" before the code, keep diffs
  small, celebrate green tests, and when you need a human-only step say exactly what to look for.
- **`github-issue-flow`** — the issue→branch→PR loop and commit/PR conventions.
- **`green-gate-tests`** — Tier-1 Lune tests + lint/format; the green gate before any play-test.
- **`rojo-studio-sync`**, **`studio-mcp-playtest`** — get code into Studio and smoke-test it.
- **`roblox-api-check`** — fetch `create.roblox.com/docs` before trusting memory on any API.

Run `cat .claude/skills/README.md` for the full table.

## 4. Prerequisites (confirm before building)

Setup is covered in `docs/SETUP.md`. Before your first build, confirm on this machine:

```bash
git --version
gh auth status          # must be logged in as Dariy — this is how you do GitHub ops
rokit --version         # toolchain manager (installs rojo/wally/stylua/selene/lune)
```

- **`gh auth status` not logged in?** Stop and have Dariy run `gh auth login`
  (GitHub.com → HTTPS → authenticate in browser). You cannot open issues/PRs without it.
- **Roblox Studio** installed + updated, with the **MCP server** enabled (SETUP.md §4) — this
  is your eyes/hands in-engine. Studio runs on **Windows/macOS only**.
- Missing tools? Follow `docs/SETUP.md` top to bottom; it's written for exactly this.

## 5. First session — do this

Paste-ready kickoff also lives in `docs/SETUP.md` §9. The plan:

1. **Audit the repo** and tell Dariy exactly what exists (it's what's listed in §1 above —
   confirm it, don't assume).
2. **Propose the skeleton** from CLAUDE.md §6 and, once Dariy approves, create it:
   `default.project.json` (src/client→StarterPlayerScripts, src/server→ServerScriptService,
   src/shared→ReplicatedStorage/Shared), `rokit.toml`, `wally.toml`, `selene.toml`,
   `stylua.toml`, `.github/workflows/ci.yml`.
3. **Stand up the Tier-1 runner** (`lune run test`) with one trivial passing spec
   (e.g. `shared/Version` returns the version string) — prove CI goes green before any game code.
4. **Open all of Epic 1 as GitHub issues**, verbatim from `docs/ROADMAP.md` (#1→#7), each with
   its acceptance criteria, automated-test list, and Dariy's manual checklist.
5. **Start Issue #1** (project skeleton & green CI): branch, implement, get CI green, open a PR
   that says `Closes #1`, then walk Dariy through how to verify it.

Teach as you go. Keep changes small. Follow every rule in CLAUDE.md. When unsure, check the
Roblox docs or ask Dariy one clear question — don't guess.

## 6. The very first thing to say to Dariy

> "I've read CLAUDE.md, the roadmap, and the mechanics doc. Here's what's already in the repo,
> here's what we'll build in Issue #1, and here's how the test-first GitHub loop will work.
> First, can you confirm `gh auth status` shows you logged in? Then I'll propose the skeleton."
