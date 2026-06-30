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
