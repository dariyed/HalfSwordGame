# SETUP — Set up everything (do this once)

This guide takes Dariy's machine from zero to a working, Git-backed Roblox project that
Claude Code can build in and that Dariy can play-test in Studio. Work top to bottom.

Roblox Studio runs on **Windows** and **macOS** only. Steps note `[Win]` / `[Mac]` where
they differ.

---

## 0. Accounts & base software

- [ ] A **GitHub account** (Dariy already has repos — we'll use one of them).
- [ ] A **Roblox account** + **Roblox Studio** installed and updated to the latest version
      (the built-in MCP server we rely on needs a recent Studio).
- [ ] **Node.js LTS** (gives us `npx`, used by some tooling). https://nodejs.org
- [ ] **VS Code** (recommended editor). https://code.visualstudio.com
- [ ] **Claude Code** installed and signed in.

---

## 1. Git + GitHub

**Install Git**
- `[Win]` Install Git for Windows: https://git-scm.com/download/win
- `[Mac]` `xcode-select --install` (includes git), or `brew install git`.

Verify: `git --version`.

**Identify yourself**
```bash
git config --global user.name  "Dariy ..."
git config --global user.email "dariy@example.com"
```

**Install GitHub CLI** (lets Claude Code manage issues/PRs cleanly):
- `[Win]` `winget install --id GitHub.cli`
- `[Mac]` `brew install gh`

**Authenticate** (this is the "connect Claude Code to GitHub" step):
```bash
gh auth login        # choose GitHub.com → HTTPS → authenticate in browser
gh auth status       # confirm you're logged in
```

> First Claude Code task: **audit the existing repo.** Pick which of Dariy's repos this
> project will live in (or create a new one with `gh repo create`), clone it, and report
> what's already there before we add structure.

```bash
git clone https://github.com/<dariy>/<repo>.git
cd <repo>
```

---

## 2. Toolchain manager: Rokit

Rokit installs and version-pins all the Roblox tools (Rojo, StyLua, Selene, Lune, Wally)
so everyone gets identical versions.

- `[Mac]`:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
  ```
- `[Win]`: download and run the installer from
  https://github.com/rojo-rbx/rokit/releases (latest release).

Restart the terminal, then:
```bash
rokit --version
```

Add the project tools (run inside the repo; this writes `rokit.toml`):
```bash
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene
rokit add lune-org/lune
rokit install
```

> Claude Code: the exact owner/repo handles and latest versions can drift. If a
> `rokit add` fails, look up the tool's current GitHub release, use the correct handle,
> and pin the version in `rokit.toml`. Commit `rokit.toml`.

---

## 3. Rojo: sync code into Studio (this is "how to run code in Roblox")

Rojo maps files on disk to objects inside Studio. You edit `.luau` files; Studio updates
live. This is what lets us use Git + Claude Code and still test in the real engine.

**Create the project skeleton** (only if the repo doesn't already have one):
```bash
rojo init
```
This creates `default.project.json` and a `src/` folder. We'll reshape `src/` to match the
layout in `CLAUDE.md` (`client/`, `server/`, `shared/`).

**Install the Studio plugin:** in VS Code install the **"Rojo - Roblox Studio Sync"**
extension (`evaera.vscode-rojo`); it installs both the CLI helper and the Studio plugin.
(Alternatively get the plugin from the Roblox Creator Store / Rojo GitHub.)

**Connect:**
```bash
rojo serve        # starts the sync server
```
Then in Roblox Studio open a baseplate, find the **Rojo** toolbar button, and click
**Connect**. Save a `.luau` file → watch it appear in Studio within milliseconds.

**Build a place file when needed:**
```bash
rojo build -o game.rbxlx
```

**The daily loop for Dariy:** edit in VS Code (or let Claude Code edit) → save → switch to
Studio → press **Play** → test → report.

---

## 4. Connect Claude Code to Roblox Studio (built-in MCP server)

Modern Roblox Studio ships an **MCP server** that lets Claude Code act *inside* Studio:
read the data model, insert/modify instances, run Luau, and automate play-tests. This is
how you (Claude Code) smoke-test before handing builds to Dariy.

1. In Studio: **File → Studio Settings → Beta Features → enable "MCP Server"** (also
   exposed under **Assistant → MCP Servers → Enable Studio as MCP server**). It listens on
   `localhost:3004`.
2. Register it with Claude Code:
   ```bash
   claude mcp add roblox-studio --transport http http://localhost:3004/mcp
   ```
3. Keep Studio open with a place loaded — MCP operates on the **currently open place**, and
   changes happen live so Dariy can watch.

> Notes: the Studio built-in server is the recommended path (an older standalone
> `studio-rust-mcp-server` exists as a reference). Use the MCP server for *inspection,
> running code, and automated play-tests* — but the **filesystem (via Rojo + Git) stays the
> source of truth**. Don't let MCP edits drift away from the committed source.

---

## 5. Packages: Wally

```bash
# wally.toml (created by `wally init` or by hand)
[package]
name = "dariy/half-sword-roblox"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dev-dependencies]
# test framework for in-engine specs:
JestLua = "jsdotlua/[email protected]"   # verify latest version
```
```bash
wally install
```

---

## 6. Testing — two tiers (the "green before manual testing" gate)

We split tests so the gate is fast and reliable:

**Tier 1 — headless logic tests (the primary gate, runs in CI).**
Pure functions in `src/shared/` (swing-direction math, input→intent mapping, state
machines, camera math) are tested with **Lune** so they run in seconds with no engine.
Use the Roblox-independent **`testez-luau`** runner (or a tiny custom runner) so specs run
under Lune.

```bash
lune run test          # exits non-zero on any failure → blocks the PR
```
Wire a `lune/test.luau` entry that discovers `*.spec.luau` under `tests/` and `src/shared/`
and runs them. **These must be green before Dariy play-tests.**

**Tier 2 — in-engine specs (engine-dependent behavior).**
Things that touch Instances/physics (constraints actually moving a part, input events) get
`*.spec.luau` files run **inside Studio** via Jest-Lua/TestEZ. Claude Code triggers these
through the Studio MCP server and reports results before handoff. Treat anything Tier 2
can't fully verify as a **manual-test checklist item** for Dariy.

> Rule of thumb: if a function can be written to take inputs and return outputs without
> touching `Workspace`, put it in `shared/` and Tier-1 test it. The thin Instance layer on
> top is what Dariy and Tier-2 cover.

---

## 7. Lint & format

`stylua.toml` and `selene.toml` configure formatting and linting. Run:
```bash
stylua .            # auto-format
selene src tests    # static analysis
```

---

## 8. Continuous Integration

`.github/workflows/ci.yml` should, on every PR: install Rokit tools, then run
`stylua --check .`, `selene src tests`, and `lune run test`. A red CI blocks merge — this
is the automated enforcement of rule #3.

```yaml
name: CI
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: CompeyDev/setup-rokit@v0   # installs tools from rokit.toml (verify latest)
      - run: stylua --check .
      - run: selene src tests
      - run: lune run test
```
> Claude Code: confirm the current recommended Rokit setup action and pin it. Adjust if a
> better-maintained action exists.

---

## 9. First session — kickoff prompt for Claude Code

Paste this to Claude Code once the tools above are installed:

```
You are the building partner on the Half Sword Roblox clone. Read CLAUDE.md,
docs/ROADMAP.md, and docs/research/half-sword-mechanics.md in full before doing anything.

Then, for our first session:
1. Audit the current repo and tell me what already exists.
2. Propose (and, once I approve, create) the repository skeleton from CLAUDE.md:
   default.project.json with src/{client,server,shared}, rokit.toml, wally.toml,
   selene.toml, stylua.toml, and .github/workflows/ci.yml.
3. Set up the Tier-1 headless test runner (lune run test) with one trivial passing
   "hello world" spec so we can prove CI goes green.
4. Open GitHub issues for all of Epic 1 exactly as written in docs/ROADMAP.md, each with
   its acceptance criteria, automated-test list, and Dariy's manual-test checklist.
5. Start Issue #1 (project skeleton): branch, implement, get CI green, open a PR that
   closes it, then walk me through how to verify it.

Teach me what each piece does as you go. Keep changes small. Follow every rule in CLAUDE.md.
```
