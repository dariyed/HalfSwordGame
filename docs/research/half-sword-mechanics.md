# Half Sword — Mechanics Study & Roblox Port Plan

The brief asks us to study how Half Sword works and write it down so that porting to
Roblox is obvious. This is that document. It focuses on the three things Epic 1 needs:
**weapon control, camera, and movement.** Defense and damage are summarised at the end for
later epics.

> Sources are the public Half Sword guides, the developer wiki, and the official Roblox
> physics docs (see citations). Half Sword entered Early Access on 30 January 2026.

---

## 1. The one idea that defines the game

Half Sword is a physics-based medieval combat simulator. Crucially, the player does not
press a button to trigger a pre-made slash or thrust — they **manipulate the weapon
directly with the mouse**, and the engine resolves the strike from the weapon's mass,
momentum, and collision angle. Most melee games pick an animation and run hit-detection;
Half Sword instead treats the weapon as a real physical object you steer in real time.

Practically: **move the mouse → the sword moves.** Whether a hit lands depends on
alignment, timing, and whether you swung with enough force; a blade that meets armor at a
poor angle just glances off. This is the feel Epic 1 must reproduce.

The character itself is driven by freeform "ragdoll" controls, mostly through directional
mouse movement, which is why fights look chaotic and weighty rather than crisp and
animated.

**Design consequence for us:** the swing should *emerge* from physics (forces/torques on a
weapon part), not from playing an animation. Get that right and the Half Sword feel
follows; fake it with animations and it won't feel like the original.

---

## 2. Weapon control (the core of Epic 1)

What the original does:

- **Hold Left Mouse Button = grip the weapon with your hand; move the mouse to swing.** The
  *direction you move the mouse* sets the swing's trajectory, so a wind-up to one side
  followed by a sweep to the other produces a real slash arc.
- **Thrust mode:** hold **Alt + LMB**, then push the mouse forward — the weapon becomes a
  thrusting "piston," good for slipping through gaps in armor. (Double-clicking LMB also
  thrusts but is unreliable.)
- **Physics matters:** weapons have weight and momentum; heavier weapons hit harder but
  swing slower, and hitting near the hilt gives poor leverage. Strikes need real
  follow-through to be effective.
- **Low mouse sensitivity is essential** — high sensitivity makes the arms spasm and the
  sword jitter so hits don't register; players drop to roughly 5–10% in-game sensitivity
  for weight and control. We should ship a sensible default and a sensitivity setting.

### How to port it to Roblox

The weapon is an **unanchored Part/Model** attached to the character's hand, driven by
**mover constraints** toward a goal the mouse defines:

- **`AlignPosition`** applies force to move an attachment toward a goal position. Use
  *OneAttachment* mode and set its `.Position` to the mouse-derived target so the blade is
  pulled where the mouse points.
- **`AlignOrientation`** applies torque to rotate an attachment toward a goal orientation.
  Use *OneAttachment* mode and set its `.CFrame` so the blade angles the way the swing
  should go.
- **Tune for weight, don't snap.** Leave `RigidityEnabled = false` and control feel with
  `MaxForce`/`MaxTorque`, `MaxVelocity`/`MaxAngularVelocity`, and `Responsiveness`. Lower
  values = heavier, laggier, more momentum (which is exactly Half Sword's character).
  Higher values = snappier and more arcade. This is the main "feel" knob Dariy will judge.

Mouse → goal each frame (client-side):
- Read mouse movement with `UserInputService` (delta) and/or the world ray via
  `Camera:ScreenPointToRay` / `Mouse.Hit`.
- Convert that into a target position + orientation for the blade, relative to the
  character, and write it to the constraints.
- For thrust mode, switch the goal model: lock orientation forward and map mouse-forward to
  pushing the blade along the character's look vector.

Responsiveness/networking:
- Drive the weapon on the **client** that owns the character and give that client
  **network ownership** of the weapon assembly so the physics feels immediate. Keep the
  server authoritative for anything that will later matter for damage.

**Unit-testable pieces (Tier 1, no engine):**
- mouse delta / screen ray → goal `CFrame` math
- swing-direction classification (left-to-right vs right-to-left vs overhead vs thrust)
- sensitivity scaling and clamps

**Engine / manual pieces (Tier 2 + Dariy):**
- the blade actually following the mouse with believable weight
- swings carrying momentum instead of teleporting

---

## 3. Camera

What the original does:

- **First-person and third-person modes**, toggled in-game (the **C** key), each with
  trade-offs: first person for precise aiming, third person for spatial awareness and
  movement.
- **Lock-on (Tab)** points the camera at the current opponent.

### How to port it to Roblox

- Build a **custom camera controller** (`LocalScript`, `RunService.RenderStepped`,
  `Camera.CameraType = Enum.CameraType.Scriptable`).
- Third-person: an **orbit camera** around the character with mouse-look (yaw/pitch),
  pitch clamped, with collision so it doesn't clip through walls.
- First-person: snap to head, hide the local character's head/parts as needed; toggle with
  **C**.
- Sensitivity: shared setting with the weapon control so both feel consistent.
- **Lock-on is out of scope for Epic 1** (no enemies yet) — design the camera so a lock-on
  target can be slotted in later (Epic 3).

**Unit-testable pieces (Tier 1):** yaw/pitch accumulation + clamping, mode-toggle state
machine, sensitivity math.
**Manual:** smoothness, no clipping, comfortable feel.

---

## 4. Movement

What the original does:

- **WASD** to move; the character has **weight, momentum, and balance** that affect speed
  and recovery — movement is deliberate, not twitchy.
- **Shift** enters a combat **stance** (and helps dodge); **Space** is used for jumping and
  kicking; the controls are intentionally awkward to reflect the physical simulation.
- Full **ragdoll**: you get knocked down a lot and have to crunch your way back up.

### How to port it to Roblox

For Epic 1, keep movement **standard but weighty** — full active ragdoll locomotion is hard
and is not required to prove the concept. Recommended staged approach:

- **Start with `Humanoid` + tuned `WalkSpeed`** and a movement *intent* layer
  (input → desired velocity/state) so we can later swap the body model without rewriting
  input.
- Add a **stance toggle (Shift)** that changes movement (slower, "ready") and will later
  gate combat behavior. **Space = jump** for now (kick comes with combat, a later epic).
- Tune acceleration/deceleration so it feels heavy rather than instant.
- **Ragdoll/get-up is explicitly a later epic.** Note it in the roadmap; don't let it block
  Epic 1. (When we do it: `Humanoid:ChangeState`, ball-socket constraints on the rig,
  `PlatformStand`.)

**Unit-testable pieces (Tier 1):** input → movement-intent mapping, stance state machine,
acceleration curve math.
**Manual:** does moving feel weighty and controllable?

---

## 5. For later epics (not Epic 1)

- **Defense / blocking** is *physical* — there is no block button; you literally put your
  weapon in the path of theirs. Porting this reuses the same constraint-driven weapon
  control, so getting Epic 1 right sets it up.
- **Hit detection & damage** comes from physical impact (force/where it lands), not
  hitboxes — model it from collision velocity and contact point.
- **Enemy / AI dummy**, **ragdoll death & gore-lite**, **arena loop & progression**.

---

## 6. Epic 1 success criteria (from the brief)

> "A player in Roblox moves and controls the weapon and camera as closely as possible to
> the game we're cloning."

Concretely, when Epic 1 is done Dariy can: spawn into an empty arena, move with weighty
WASD + a stance toggle, look around with a third/first-person camera, and **swing and
thrust a sword by moving the mouse**, with the blade carrying believable weight and
momentum. No enemies, no damage — just the core control feel.

---

### Source notes
Mechanics and controls are drawn from public Half Sword guides and the developer wiki;
the Roblox implementation maps onto the official `AlignPosition` / `AlignOrientation`
mover-constraint docs. Half Sword is an Early Access game and still changing, so re-check
specifics if a detail matters; the *physics-first philosophy* is stable and is what we're
cloning.
