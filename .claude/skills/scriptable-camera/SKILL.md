---
name: scriptable-camera
description: Build the custom Roblox camera — third-person orbit with mouse-look plus a first-person toggle (C), with pitch clamping and wall collision. Use for Issue #3, camera jitter/clipping, mouse-look, sensitivity, or "the camera flips over the top".
---

# Scriptable camera (Issue #3)

A custom camera controller: third-person orbit with mouse-look by default, **C** toggles
first-person, sensitivity **shared** with the weapon control so both feel consistent.
Lock-on is out of scope for Epic 1 (no enemies yet) — but design so a target can slot in
later (Epic 3).

## Shape

```
client/CameraController.luau (LocalScript):
  Camera.CameraType = Enum.CameraType.Scriptable
  on RenderStepped:
     yaw, pitch = CameraMath.accumulate(mouseDelta, sensitivity)   -- pure
     pitch = clamp(pitch, MIN, MAX)                                 -- no somersault
     cf = CameraMath.toCFrame(target, yaw, pitch, distance)        -- pure
     cf = collide(cf)                                              -- raycast so it won't clip walls
     Camera.CFrame = cf
  C key → toggle third/first; in first-person hide local head/parts
```

## Split pure from engine (so it's Tier-1 testable)

- `shared/Camera/CameraMath.luau` — **pure**: accumulate yaw/pitch from mouse delta, clamp
  pitch, compute camera CFrame from target + yaw/pitch + distance.
- `shared/Settings/Sensitivity.luau` — **pure**: scale + clamp sensitivity (shared with weapon).
- `client/CameraController.luau` — the thin layer: `Scriptable` camera, mouse capture, C toggle,
  wall-collision raycast.

## Tier-1 tests (write first)

- pitch clamps at min/max; yaw wraps correctly
- mode toggle state machine: C flips third ⇄ first; **starts in third**
- sensitivity scaling is monotonic and clamped to sane bounds

## Manual (Dariy)

Smoothness, up/down limited (no flip-over-top), C toggles both ways, no clipping through walls,
sensitivity feels right. Half Sword needs **low** sensitivity to feel weighty — ship a low
default and note that to him.

See also: `physics-weapon-control`, `green-gate-tests`.
