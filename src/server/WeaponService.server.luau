--[[
    Spawns a simple sword (gray stick) for each player on spawn.

    The stick is an unanchored Part driven by AlignPosition + AlignOrientation
    (TwoAttachment mode) so it physically chases the hand attachment each frame.
    Network ownership → owning client for immediate feel.
]]

local Players = game:GetService("Players")
local WeaponConfig = require(game.ReplicatedStorage.Shared.Weapon.WeaponConfig)

local config = WeaponConfig.get("default")

local function equipSword(character: Model, player: Player)
    -- Wait for the right hand (R15) or right arm (R6)
    local hand = character:WaitForChild("RightHand", 5) or character:WaitForChild("Right Arm", 5)
    if not hand then
        return
    end
    hand = hand :: BasePart

    -- Attachment on the hand — this is what the stick will chase.
    -- Offset downward so the grip sits in the palm, blade points away.
    local handAttach = Instance.new("Attachment")
    handAttach.Name = "WeaponGrip"
    handAttach.Position = Vector3.new(0, -0.3, 0)
    handAttach.Parent = hand

    -- The stick itself — gray, no character collision
    local stick = Instance.new("Part")
    stick.Name = "Sword"
    stick.Size = Vector3.new(0.15, 1.8, 0.15)
    stick.BrickColor = BrickColor.new("Medium stone grey")
    stick.Material = Enum.Material.SmoothPlastic
    stick.Anchored = false
    stick.CanCollide = false
    stick.CastShadow = true
    stick.Parent = workspace

    -- Place it at the hand to start
    stick.CFrame = hand.CFrame * CFrame.new(0, -0.3, 0)

    -- Attachment on the stick — sits at the top (grip end)
    local stickAttach = Instance.new("Attachment")
    stickAttach.Name = "Grip"
    stickAttach.Position = Vector3.new(0, 0.7, 0) -- upper portion = grip
    stickAttach.Parent = stick

    -- AlignPosition pulls the stick grip toward the hand grip attachment
    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = stickAttach
    alignPos.Attachment1 = handAttach
    alignPos.MaxForce = config.maxForce
    alignPos.Responsiveness = config.responsiveness
    alignPos.RigidityEnabled = false
    alignPos.Parent = stick

    -- AlignOrientation matches the stick rotation to the hand
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
    alignOri.Attachment0 = stickAttach
    alignOri.Attachment1 = handAttach
    alignOri.MaxTorque = config.maxTorque
    alignOri.Responsiveness = config.responsiveness
    alignOri.RigidityEnabled = false
    alignOri.Parent = stick

    -- Client owns the sword physics so there's no server round-trip lag
    stick:SetNetworkOwner(player)

    -- Clean up when character leaves
    character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(game) then
            stick:Destroy()
        end
    end)
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
