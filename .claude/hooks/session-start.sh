#!/usr/bin/env bash
# Half Sword — SessionStart hook.
# Surfaces the project's custom skills + the non-negotiable rules at every session start so
# they fire WITHOUT relying on Claude recalling them. Non-blocking: prints additionalContext
# JSON and exits 0. Never gates. Modeled on ~/fieldcraft/hooks/session-start.sh.

INPUT=$(cat 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -z "$CWD" ] && CWD=$(pwd)

# Resolve repo root from this script's location (.claude/hooks/session-start.sh → repo root).
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$SCRIPT_DIR/../.." && pwd)
SKILLS="$REPO/.claude/skills"

LINES=""
add() { LINES="${LINES}$1\n"; }

add "🗡️  Half Sword (Roblox) — session start"
add ""

# Self-check: are the custom skills actually present?
COUNT=$(find "$SKILLS" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -gt 0 ]; then
  add "▸ ${COUNT} custom skills loaded from .claude/skills/ — they auto-fire by description, but keep these salient:"
else
  add "▸ ⚠ No skills found under .claude/skills/ — check the repo is intact before relying on them."
fi
add "   • teach-dariy — Dariy is 15 and learning: explain the 'why' first, small diffs, celebrate green, ask clearly for human-only steps."
add "   • github-issue-flow — one issue = one branch = one PR. Everything goes through GitHub."
add "   • green-gate-tests — tests first, GREEN before Dariy play-tests. Never hand him red code."
add "   • physics-weapon-control — the swing emerges from constraints, never an animation. That's the whole game."
add "   • roblox-api-check — fetch create.roblox.com/docs before trusting memory on any API."
add ""

# halt.md — resume pointer if a previous session left one.
if [ -f "$REPO/halt.md" ]; then
  add "▸ HALT exists: $REPO/halt.md — read it first, verify the state it claims, continue from Next steps, then archive it."
fi

# Handoff pointer on a fresh/near-empty repo.
if [ -f "$REPO/docs/HANDOFF.md" ] && [ ! -f "$REPO/rokit.toml" ]; then
  add "▸ Project not yet scaffolded (no rokit.toml). Read docs/HANDOFF.md — it's your first-session playbook."
fi

CONTEXT=$(printf '%b' "$LINES")
ESCAPED=$(printf '%s' "$CONTEXT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null)
if [ -n "$ESCAPED" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$ESCAPED"
else
  printf '%b' "$LINES"
fi
exit 0
