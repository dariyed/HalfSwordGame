# Retro log

A running log of what we learned building Half Sword. One short entry per finished issue/PR.
Append new entries at the bottom with the `/retro` skill. Real wins *and* real stumbles.

---

<!-- New entries go below. Template:

## <date> — Issue #<n>: <short title>

- ✅ **Went well:** ...
- ⚠️ **Was hard / would do differently:** ...
- 💡 **Learned:** ...
- 🎉 **Win:** ...
-->

## 2026-06-30 — Issue #5: Mouse-driven arm swing via IKControl

- ✅ **Went well:** Once we switched to `IKControl`, the arm moved on the first successful run. The weight-lerp blending (0→1 on LMB, back to 0 on release) gave a smooth feel without any extra code.
- ⚠️ **Was hard / would do differently:** We tried `Motor6D.Transform` first (multiple sessions). The engine silently accepts the write but overrides it — no error, no clue. If we'd checked the Roblox docs for "procedural animation" earlier we'd have landed on `IKControl` immediately. Next time: reach for `IKControl` first, not `Motor6D`.
- 💡 **Learned:** Three Roblox IKControl gotchas for this Studio version: (1) `SmoothingEnabled` doesn't exist — assigning it crashes the script silently before `Parent` is set; (2) IKControl created from a LocalScript works fine for the local player's character; (3) at extreme left yaw (>~80°) the IK solver flips the elbow — tighten `MIN_YAW` to prevent it.
- 🎉 **Win:** Dariy shipped the core feel of Half Sword — hold the mouse button and the arm physically swings the sword in exactly the direction the mouse points. That's the whole game in one mechanic. PR #14 merged, tests green, branch deleted.

## 2026-06-30 — Issue #5 (follow-up): Sword drop on impact + slim body rig

- ✅ **Went well:** Once we moved detection to the client, Touched fired immediately. The `triggerDrop` → `FireServer` → `weld.Enabled = false` round-trip is clean and the arms return to idle with zero extra code because `swordDropped` already gates the render loop.
- ⚠️ **Was hard / would do differently:** We shipped the drop mechanic twice before it worked: first attempt used `GetPartsInPart` on a `CanCollide = false` part (nothing detected), second used server-side `Touched` on a client-owned assembly (never fires). Both looked plausible on paper. Rule for next time: **check network ownership before choosing where to put physics event listeners** — if the part is client-owned, the listener must be client-side.
- 💡 **Learned:** In Roblox, `Touched` fires on the machine that *simulates* the physics. A part welded to a character is part of the character's rigid-body assembly, which has **client network ownership** — so `Touched` fires in the LocalScript, not the server Script. Use a `RemoteEvent` to hand the signal to the server. Also: `GetPartsInPart` silently returns nothing for `CanCollide = false` parts.
- 🎉 **Win:** The sword now physically collides, can be knocked out of your hands by a fast hit, and drops under sustained pressure. Dariy also has a slim, realistic-looking character rig on every spawn via `HumanoidDescription` scales — the game is starting to *look* like Half Sword, not just feel like it.
