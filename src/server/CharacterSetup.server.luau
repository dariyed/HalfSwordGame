--[[
    Applies slim / realistic body proportions to every player's character on spawn.
    Uses HumanoidDescription scales — the player's avatar appearance (skin, face,
    accessories, clothing) is preserved; only the rig proportions change.

    Scale reference:
      BodyTypeScale  0 = lean/athletic silhouette  1 = default blocky Roblox shape
      ProportionScale 1 = longer proportional limbs 0 = compact short limbs
      WidthScale      narrower = slimmer arms/torso
      DepthScale      smaller = thinner front-to-back
      HeadScale       smaller head looks less cartoonish
      HeightScale     > 1 = slightly taller
]]

local Players = game:GetService("Players")

local function applySlimBody(character: Model)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local ok, desc = pcall(function()
        return humanoid:GetAppliedDescription()
    end)
    if not ok or not desc then
        warn("CharacterSetup: GetAppliedDescription failed — skipping body reshape")
        return
    end

    desc.BodyTypeScale = 0 -- lean athletic build
    desc.ProportionScale = 1 -- realistic limb proportions
    desc.WidthScale = 0.85 -- narrower frame
    desc.DepthScale = 0.85 -- thinner front-to-back
    desc.HeadScale = 0.9 -- smaller, less cartoony head
    desc.HeightScale = 1.05 -- slightly taller

    humanoid:ApplyDescription(desc)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(applySlimBody)
    if player.Character then
        applySlimBody(player.Character)
    end
end)

for _, player in Players:GetPlayers() do
    if player.Character then
        applySlimBody(player.Character)
    end
end
