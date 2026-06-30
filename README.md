# Half Sword — Roblox clone

A simplified, single-player clone of **Half Sword** built in **Roblox** (Luau). The goal is
to reproduce the original's signature idea: **you control the weapon with your mouse, and
physics decides what happens.**

Built by **Dariy** with **Claude Code** as the building partner, using a strict
test-first, GitHub-driven workflow.

## Start here

| Doc | What it's for |
| --- | --- |
| [`CLAUDE.md`](CLAUDE.md) | The operating contract Claude Code reads every session: roles, rules, workflow, stack. |
| [`docs/SETUP.md`](docs/SETUP.md) | One-time setup from zero: Git, Rojo, Studio MCP, tests, CI — plus the first-session kickoff prompt. |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Release plan, and **Epic 1** broken into seven test-gated GitHub issues. |
| [`docs/research/half-sword-mechanics.md`](docs/research/half-sword-mechanics.md) | How Half Sword works and how each mechanic maps onto Roblox. |

## The rules in one breath

All work goes through GitHub (issue → branch → PR). Automated tests are written first and
must be **green before Dariy play-tests**. His feedback becomes issue comments, then fixes
and regression tests. One issue = one feature = one PR. Everything in English.

## Current milestone

**v0.1 — Epic 1:** player moves, controls the camera, and swings/thrusts a weapon with the
mouse. No enemies, no damage yet — get the *feel* right first.
