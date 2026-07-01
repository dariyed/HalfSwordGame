--[[
    Loads every player's character with slim proportions baked in.

    LoadCharacterWithHumanoidDescription sets the description BEFORE the
    character appears, so there is no visual pop and no race condition.
    CharacterAutoLoads must be false so we control when spawning happens.

    Scale reference:
      BodyTypeScale  0 = lean/athletic   1 = default blocky Roblox shape
      ProportionScale 1 = realistic limb length
      WidthScale / DepthScale  < 1 = narrower/thinner
      HeadScale      < 1 = smaller, less cartoony
      HeightScale    > 1 = slightly taller
]]

local Players = game:GetService("Players")

Players.CharacterAutoLoads = false

local RESPAWN_DELAY = 3 -- seconds after death before respawning

local function spawnSlim(player: Player)
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(player.UserId)
    end)
    if not ok or not desc then
        warn("CharacterSetup: description fetch failed for", player.Name, "— using default spawn")
        player:LoadCharacter()
        return
    end

    desc.BodyTypeScale = 0
    desc.ProportionScale = 1
    desc.WidthScale = 0.85
    desc.DepthScale = 0.85
    desc.HeadScale = 0.9
    desc.HeightScale = 1.05

    player:LoadCharacterWithHumanoidDescription(desc)
end

Players.PlayerAdded:Connect(function(player)
    spawnSlim(player)

    -- Re-spawn with slim body after each death
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid") :: Humanoid
        humanoid.Died:Connect(function()
            task.delay(RESPAWN_DELAY, function()
                if player.Parent then
                    spawnSlim(player)
                end
            end)
        end)
    end)
end)

-- Handle players already in-game when the script starts (Studio play-test)
for _, player in Players:GetPlayers() do
    task.defer(function()
        spawnSlim(player)
    end)
end
