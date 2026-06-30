# ROADMAP

## Vision

A simplified, single-player **Half Sword** clone in Roblox that captures the one thing that
makes the original special: **you control the weapon with your mouse, and physics decides
what happens.** We ship in small, test-gated steps and keep the *feel* front and center.

See [`research/half-sword-mechanics.md`](research/half-sword-mechanics.md) for the mechanics
study and the Roblox port plan.

## Milestones

| Milestone | Epic | Goal |
| --- | --- | --- |
| **v0.1 — Core control feel** | **Epic 1** (this doc) | Player moves, controls camera, and swings/thrusts a weapon with the mouse. No enemies, no damage. |
| v0.2 — It can hit things | Epic 2 | Physics-based hit detection + a damageable training dummy. |
| v0.3 — Something fights back | Epic 3 | Basic enemy + simple AI + camera lock-on. |
| v0.4 — Defense & consequence | Epic 4 | Physical blocking/parrying, ragdoll-on-death, light gore. |
| v0.5 — A loop | Epic 5 | Arena round loop, restart, basic progression, polish. |

Only **Epic 1** is fully specified below. Later epics are deliberately left as one-liners
until we get there — we'll detail each one in a planning session when its time comes (and
re-confirm scope with Alisher and Dariy).

---

# EPIC 1 — Core locomotion, camera & physics weapon control

**Outcome:** a player spawns into an empty arena and can move with weight, look around with
a third/first-person camera, and **swing and thrust a sword by moving the mouse**, with the
blade carrying believable momentum. This is the whole milestone.

**Build order:** #1 → #2 → #3 → #4 → #5 → #6 → #7. Each is one issue, one branch, one PR.

Every issue below follows the rules in [`../CLAUDE.md`](../CLAUDE.md): write the automated
tests first and get them **green**, then hand to Dariy for the manual checklist, then turn
his comments into fixes + regression tests.

---

## Issue #1 — Project skeleton, Rojo wiring & green CI

**Goal:** a clean, buildable, Git-backed project where an empty test passes in CI, proving
the whole pipeline works before we write any game code.

**Scope**
- `default.project.json` mapping `src/client → StarterPlayerScripts`,
  `src/server → ServerScriptService`, `src/shared → ReplicatedStorage/Shared`.
- `rokit.toml`, `wally.toml`, `selene.toml`, `stylua.toml`.
- Tier-1 test runner: `lune run test` discovers and runs `*.spec.luau`.
- `.github/workflows/ci.yml` runs `stylua --check`, `selene`, `lune run test`.
- One trivial passing spec (e.g. a `shared/Version` module returns the version string).

**Automated tests (green gate)**
- `Version.spec.luau` passes under `lune run test`.
- CI is green on the PR.

**Acceptance criteria**
- `rojo build -o game.rbxlx` succeeds.
- `rojo serve` + Studio Rojo plugin connects and syncs a saved file.
- CI green; `stylua --check` and `selene` clean.

**Dariy's manual checklist**
- [ ] Open the built place / connect Rojo in Studio — it loads with no errors.
- [ ] Confirm the green check on the PR.

---

## Issue #2 — Character movement (weighty WASD + stance + jump)

**Goal:** the player moves with WASD in a way that feels deliberate and weighty, can hold
**Shift** for a combat stance (slower, "ready"), and **Space** to jump.

**Scope**
- `shared/Movement/MovementIntent.luau` — **pure** function: raw input → movement intent
  (direction, speed multiplier, stance flag). No Instances.
- `shared/Movement/StanceMachine.luau` — **pure** state machine: normal ⇄ stance.
- `client/MovementController.luau` — reads input, calls the pure modules, drives the
  `Humanoid` (WalkSpeed, jump), applies acceleration/deceleration for weight.

**Automated tests (green gate, Tier 1)**
- Input mapping: WASD combinations → correct normalized direction.
- Stance machine: Shift down → stance; release → normal; idempotent transitions.
- Speed: stance applies the slower multiplier; diagonal isn't faster than straight.

**Acceptance criteria**
- Movement feels weighty (tunable accel/decel constants, documented).
- Shift visibly slows movement and sets a stance flag other systems can read.
- Space jumps; no double-jump.

**Dariy's manual checklist**
- [ ] WASD moves smoothly in all 8 directions.
- [ ] Holding Shift feels slower/"ready"; releasing returns to normal.
- [ ] Movement feels weighty, not instant/twitchy. (Tell Claude if it feels too floaty or
      too sluggish — that's a tuning comment.)
- [ ] Space jumps once.

---

## Issue #3 — Camera system (third-person orbit + first-person toggle)

**Goal:** a custom camera: third-person orbit with mouse-look by default, **C** toggles
first-person, shared sensitivity setting.

**Scope**
- `shared/Camera/CameraMath.luau` — **pure**: accumulate yaw/pitch from mouse delta,
  clamp pitch, compute camera CFrame from target + yaw/pitch + distance.
- `shared/Settings/Sensitivity.luau` — **pure**: scale + clamp sensitivity.
- `client/CameraController.luau` — `Scriptable` camera on `RenderStepped`, mouse capture,
  C-key mode toggle, wall collision so the camera doesn't clip.

**Automated tests (green gate, Tier 1)**
- Pitch clamps at min/max; yaw wraps correctly.
- Mode toggle state machine: C flips third ⇄ first; starts in third.
- Sensitivity scaling is monotonic and clamped to sane bounds.

**Acceptance criteria**
- Smooth third-person orbit; pitch can't flip over the top.
- C cleanly toggles first/third; local character parts hidden appropriately in first.
- Camera doesn't clip through walls/floor.

**Dariy's manual checklist**
- [ ] Mouse-look is smooth; up/down is limited (no somersault).
- [ ] C toggles first/third person both ways.
- [ ] No clipping through walls.
- [ ] Sensitivity feels right (note if too fast/slow).

---

## Issue #4 — Weapon rig (equip a sword as a physics object)

**Goal:** a sword is attached to the character's hand as an **unanchored physics part**
(not welded rigidly), ready to be driven by constraints. Network ownership set so the local
player's physics feels immediate.

**Scope**
- A simple sword model (blade + hilt) with a hand attachment and a control attachment.
- `server/WeaponService.luau` — spawns/equips the weapon, sets **network ownership** of the
  weapon assembly to the owning player.
- `shared/Weapon/WeaponConfig.luau` — **pure**: weapon stats (mass feel, max force/torque,
  responsiveness presets).

**Automated tests (green gate)**
- Tier 1: `WeaponConfig` returns valid, in-range constraint parameters for each preset.
- Tier 2 (Studio MCP): equipping creates the expected instances/constraints and assigns
  network ownership. Claude Code runs and reports this.

**Acceptance criteria**
- Sword appears in the player's hand on spawn, hangs as a physics object (it has weight).
- The owning client has network ownership of the weapon.

**Dariy's manual checklist**
- [ ] A sword is in my hand when I spawn.
- [ ] It doesn't look rigidly glued — it has some physical heft.

---

## Issue #5 — Mouse-driven weapon control (swing) ⭐ the heart of Epic 1

**Goal:** **move the mouse → the blade swings**, driven by `AlignPosition` +
`AlignOrientation` toward a mouse-derived goal, tuned to carry weight and momentum like
Half Sword.

**Scope**
- `shared/Weapon/SwingMath.luau` — **pure**: mouse delta / screen-ray → goal position &
  orientation (CFrame) for the blade, relative to the character; classify swing direction.
- `client/WeaponController.luau` — on LMB held, read mouse each frame, compute the goal via
  `SwingMath`, write `AlignPosition.Position` and `AlignOrientation.CFrame`; on release,
  relax. Tune `MaxForce`/`MaxTorque`/`Responsiveness` for heft (no `RigidityEnabled`).

**Automated tests (green gate, Tier 1)**
- `SwingMath`: a given mouse delta/screen point → expected goal CFrame (within tolerance).
- Swing classification: left→right, right→left, and overhead inputs are labeled correctly.
- Goal stays within the configured reach radius of the character (no teleporting the blade
  across the map).

**Acceptance criteria**
- Holding LMB and moving the mouse swings the blade in the matching direction.
- The blade carries momentum — it doesn't snap instantly to the cursor.
- Releasing LMB relaxes the weapon to rest.

**Dariy's manual checklist**
- [ ] Hold LMB, move mouse left↔right → blade slashes that way.
- [ ] Move mouse up then down → overhead-style swing.
- [ ] It feels *weighty*, like swinging a real sword, not like a laser pointer. (This is the
      key feel comment — describe what's off: too floaty? too stiff? too slow?)
- [ ] Lowering mouse sensitivity makes it more controllable.

---

## Issue #6 — Thrust mode (Alt + LMB)

**Goal:** holding **Alt + LMB** locks the weapon into a thrust; pushing the mouse forward
drives the point straight ahead.

**Scope**
- Extend `shared/Weapon/SwingMath.luau` (or a sibling `ThrustMath.luau`) — **pure**: in
  thrust mode, lock orientation forward and map mouse-forward to a thrust vector along the
  character's look direction.
- `client/WeaponController.luau` — detect Alt held; switch goal model to thrust; revert on
  release.

**Automated tests (green gate, Tier 1)**
- Thrust mode toggles only while Alt is held.
- Forward mouse motion → forward thrust vector; orientation stays locked within tolerance.

**Acceptance criteria**
- Alt+LMB enters thrust; the blade points forward and stabs on mouse-forward.
- Releasing Alt returns to normal swing control.

**Dariy's manual checklist**
- [ ] Hold Alt + LMB and push the mouse forward → the sword stabs straight ahead.
- [ ] Letting go of Alt goes back to normal swinging.

---

## Issue #7 — Integration & feel pass

**Goal:** everything works together and **feels right**. This issue is mostly tuning and is
manual-test-heavy by design.

**Scope**
- Make sure movement, camera, swing, and thrust coexist with no input conflicts.
- Centralize tunables (sensitivity, constraint forces, accel) into one config Dariy can
  tweak, and document each knob.
- Fix anything from the manual checklists of #2–#6.

**Automated tests (green gate)**
- No regressions: the full Tier-1 suite stays green.
- Add regression tests for every bug found during the feel pass.

**Acceptance criteria (= Epic 1 done)**
- The success criteria in the mechanics doc are met: spawn, weighty WASD + stance,
  third/first-person camera, mouse-driven swing **and** thrust with believable momentum.

**Dariy's manual checklist**
- [ ] Move + look + swing + thrust all at once with no weird conflicts.
- [ ] Overall it *feels like Half Sword's control idea*: my mouse is the sword.
- [ ] Tuning knobs are documented so I can experiment.

---

## How a planning session works (for future epics)

When Epic 1 is merged, hold a short planning session: pick the next epic, write its outcome
in one sentence, break it into issues using the same template (goal / scope / automated
tests / acceptance criteria / Dariy's manual checklist), and confirm scope before building.
Keep issues small enough that one PR closes one issue.
