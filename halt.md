# HALT — 2026-06-30

**Working on:** Issue #5 follow-up — sword drop + character body proportions
**Branch:** main
**Status:** tests GREEN, retro logged, all commits pushed

**Where we are:**
Both features written and pushed but **neither is working in-game yet**:
- **Sword drop** — Dariy confirms sword does not drop. Likely cause: `sword.Touched` may not fire on the client either, because the sword (CanCollide=true) welded to the hand might be getting its network ownership overridden to the server by Roblox (weld Part0 is a character part, Part1 is a non-character part — ownership can split). Needs Output window investigation.
- **Body proportions** — character looks the same. `GetAppliedDescription` / `ApplyDescription` approach not working.

**Next step (start here):**
1. Open Studio Output window and play-test. Look for any errors from WeaponController or CharacterSetup.
2. For the drop: add a quick `print("Touched: " .. hit.Name)` inside `sword.Touched` in WeaponController to confirm if Touched is firing at all. If it never prints, the issue is network ownership — fix by adding `sword:SetNetworkOwner(player)` in WeaponService after creating the sword, so the client definitely owns it.
3. For the body: check Output for `"CharacterSetup: GetAppliedDescription failed"`. If present, switch to `player:LoadCharacterWithHumanoidDescription(Players:GetHumanoidDescriptionFromUserId(player.UserId))` with `Players.CharacterAutoLoads = false`.

**Watch out for:**
- `SetNetworkOwner` can only be called on the server and only on unanchored parts — the sword qualifies.
- `LoadCharacterWithHumanoidDescription` requires `Players.CharacterAutoLoads = false` — must handle respawn manually.
- WeaponEvents/DropSword RemoteEvent is created by WeaponService at startup — if WeaponController's `WaitForChild("WeaponEvents")` times out, there'll be a silent nil error. Check Output for that too.
