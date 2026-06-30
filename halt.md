# HALT — 2026-06-30

**Working on:** Issue #5 follow-up — sword drop + character body proportions
**Branch:** main
**Status:** tests GREEN, retro logged, all commits pushed

**Where we are:**
Sword drop is working — client-side Touched detection fires DropSword RemoteEvent, server disables weld, arms return to idle. The slim body feature (`CharacterSetup.server.luau`) was written and pushed but Dariy confirmed **the body proportions do not visually change in-game** — needs investigation next session.

**Next step (start here):**
Debug why `humanoid:GetAppliedDescription()` + `humanoid:ApplyDescription()` isn't reshaping the character. Two likely causes:
1. `GetAppliedDescription()` might not exist in this Studio version (wrap in pcall — check the Output window for the "GetAppliedDescription failed" warn).
2. The character might be using the default R15 block rig which has no meshes to deform — `BodyTypeScale` only works with Rthro-style mesh characters. Fix: switch to `player:LoadCharacterWithHumanoidDescription(desc)` instead of patching after spawn, using `Players:GetHumanoidDescriptionFromUserId(player.UserId)` to get the base appearance first.

**Watch out for:**
- `LoadCharacterWithHumanoidDescription` requires `Players.CharacterAutoLoads = false` — don't forget to handle respawn manually (connect `Humanoid.Died` → wait `Players.RespawnTime` → reload).
- Check the Output window in Studio for the "CharacterSetup: GetAppliedDescription failed" warning — if it shows, that confirms the API doesn't exist and we need the LoadCharacterWithHumanoidDescription path.
- Drop knobs in WeaponController.client.luau: `INSTANT_DROP_SPEED = 25`, `SUSTAIN_TIME = 1.5` — Dariy hasn't tuned these yet.
