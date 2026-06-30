---
name: green-gate-tests
description: The automated green gate — write Tier-1 headless Luau tests first with Lune, plus stylua + selene, and only hand a green build to Dariy. Use whenever writing tests, "tests are red", designing a pure shared module, CI setup, lint/format, or before asking Dariy to play-test anything.
---

# The green gate (tests-first, never hand Dariy red code)

**Rule 3 of CLAUDE.md, non-negotiable:** write the automated tests first, get them GREEN,
and only *then* hand the build to Dariy for manual play-testing. Never ask him to test red code.

## Two tiers

| Tier | What | Runner | Speed |
| --- | --- | --- | --- |
| **Tier 1** (the gate) | pure logic in `src/shared/` — math, state machines, mappings | **Lune** + `testez-luau` | seconds, no engine, runs in CI |
| **Tier 2** | things that touch Instances/physics/input | Jest-Lua/TestEZ via **Studio MCP** | needs Studio |

> **Design rule that makes this work:** if a function can take inputs and return outputs
> without touching `Workspace`, put it in `shared/` and Tier-1 test it. Keep the thin layer
> that touches Roblox Instances separate (Tier-2 + Dariy cover that). Most of Epic 1's logic
> — swing math, camera math, input→intent, stance machine, sensitivity — is pure and belongs
> in Tier 1.

## Run the gate

```bash
lune run test          # discovers *.spec.luau, exits non-zero on any failure → blocks the PR
stylua --check .       # formatting gate (CI)
selene src tests       # lint gate (CI)
```

Write a `lune/test.luau` entry that discovers `*.spec.luau` under `tests/` and `src/shared/`.

## Writing a Tier-1 spec

1. Read the issue's **acceptance criteria** and **automated-test list** in `docs/ROADMAP.md`.
2. Write one `*.spec.luau` per behavior, each asserting one criterion. **Run it red first** —
   a test that can't fail proves nothing.
3. Implement the pure module until green.
4. `stylua .` then `selene src tests` until clean.
5. `lune run test` fully green → *now* you may hand to Dariy.

## When Dariy reports a bug (manual test)

His comment becomes: a fix **and**, wherever possible, a **new Tier-1 regression test** that
would have caught it. A feel bug that can't be unit-tested becomes a documented tuning knob +
a Tier-2/manual checklist item.

## Verify before claiming green

"Tests pass" means you **ran `lune run test` and saw it exit 0** in this session — not "should
pass". Paste the summary line when you hand off.

See also: `studio-mcp-playtest`, `github-issue-flow`, `physics-weapon-control`.
