--[[
    Spawns a gray stick for each player and parents it to their character.
    No weld — the client WeaponController drives it via AlignPosition/Orientation.
]]

local Players = game:GetService("Players")

local function equipSword(character: Model, player: Player)
    local hand = character:WaitForChild("RightHand", 5) :: BasePart
    if not hand then
        warn("WeaponService: RightHand not found for", player.Name)
        return
    end

    -- Attachment on the hand that the sword will chase
    local handAttach = Instance.new("Attachment")
    handAttach.Name = "WeaponGrip"
    handAttach.Position = Vector3.new(0, -0.1, 0)
    handAttach.Parent = hand

    -- The sword stick — parented to character so the client can WaitForChild it
    local sword = Instance.new("Part")
    sword.Name = "Sword"
    sword.Size = Vector3.new(0.2, 2, 0.2)
    sword.BrickColor = BrickColor.new("Medium stone grey")
    sword.Material = Enum.Material.SmoothPlastic
    sword.CanCollide = false
    sword.Anchored = false
    sword.CastShadow = true
    sword.CFrame = hand.CFrame * CFrame.new(0, -1.1, 0)
    sword.Parent = character

    -- Client owns the physics so swing response is immediate
    sword:SetNetworkOwner(player)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            equipSword(character, player)
        end)
    end)
end)

for _, player in Players:GetPlayers() do
    if player.Character then
        task.defer(function()
            equipSword(player.Character, player)
        end)
    end
end
