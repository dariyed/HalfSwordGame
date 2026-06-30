---
name: physics-weapon-control
description: How to make the sword follow the mouse with weight in Roblox using AlignPosition + AlignOrientation mover constraints and network ownership. Use whenever working on the weapon, swing, thrust, "the blade feels floaty/stiff/laggy", momentum, constraint tuning, or Issues #4/#5/#6 of Epic 1.
---

# Physics weapon control (the heart of Half Sword)

The signature feel: **move the mouse → the blade moves, and physics decides the rest.**
The swing must *emerge* from forces on a real physics part — never from a canned animation.
If you fake it with an animation, it won't feel like Half Sword. This is the project's whole point.

## The recipe

The weapon is an **unanchored** Part/Model attached to the hand, driven by two mover
constraints toward a goal the mouse defines each frame:

| Constraint | What it does | What you write each frame |
| --- | --- | --- |
| `AlignPosition` (OneAttachment) | applies **force** to pull the blade attachment to a point | `.Position` = mouse-derived target |
| `AlignOrientation` (OneAttachment) | applies **torque** to rotate the blade to an angle | `.CFrame` = swing orientation |

```
LMB held → each RenderStepped frame:
  goalPos, goalCFrame = SwingMath.fromMouse(mouseDelta / screenRay, character)
  alignPosition.Position = goalPos
  alignOrientation.CFrame = goalCFrame
LMB released → relax (drop forces, let it hang)
```

## The "feel" knobs (this is what Dariy judges)

Leave **`RigidityEnabled = false`** — rigidity kills the weight. Tune feel with:
`MaxForce` / `MaxTorque`, `MaxVelocity` / `MaxAngularVelocity`, `Responsiveness`.

- **Lower values** = heavier, laggier, more momentum → closer to Half Sword.
- **Higher values** = snappier, arcade-y, "laser pointer" → wrong for this game.

When Dariy says "too floaty" raise force/responsiveness a little; "too stiff/snappy" lower them.
Change **one knob at a time** and have him feel the difference. Keep all knobs in one config
module so he can experiment without touching logic.

## Network ownership (or it will feel laggy)

Drive the weapon on the **client that owns the character**, and on the **server** set network
ownership of the whole weapon assembly to that player:
`weaponPrimaryPart:SetNetworkOwner(player)`. Physics then runs locally → immediate feel.
Keep the server authoritative for anything that will later matter for damage (Epic 2+).

## Thrust mode (Issue #6)

Alt + LMB → switch the goal model: **lock orientation forward** and map mouse-forward to a
thrust vector along the character's look direction. Releasing Alt returns to normal swing.

## What is Tier-1 testable (no engine — write these first)

- `SwingMath`: mouse delta / screen ray → goal `CFrame` (assert within tolerance)
- swing classification: left→right / right→left / overhead / thrust
- goal stays within the configured reach radius (no teleporting the blade across the map)
- sensitivity scaling + clamps

The blade *actually* following with weight is Tier-2 (Studio MCP) + Dariy's manual feel test.

## Verify before claiming

Roblox constraint APIs drift. Before asserting how `AlignPosition`/`AlignOrientation` behave,
fetch the official docs (see the `roblox-api-check` skill). Don't trust memory on Mode,
`Responsiveness` ranges, or `MaxForce` units.

See also: `scriptable-camera`, `green-gate-tests`, `roblox-api-check`.
