--[[
    Spawns and equips a sword for each player on spawn.

    The sword is an unanchored assembly driven by AlignPosition + AlignOrientation
    constraints targeting a control part attached to the character's right hand.
    Network ownership is given to the owning client so their physics feel is immediate.
]]

local Players = game:GetService("Players")
local WeaponConfig = require(game.ReplicatedStorage.Shared.Weapon.WeaponConfig)

local config = WeaponConfig.get("default")

local function buildSword(): Model
    local model = Instance.new("Model")
    model.Name = "Sword"

    -- Hilt
    local hilt = Instance.new("Part")
    hilt.Name = "Hilt"
    hilt.Size = Vector3.new(0.2, 0.8, 0.2)
    hilt.BrickColor = BrickColor.new("Dark orange")
    hilt.Material = Enum.Material.SmoothPlastic
    hilt.CastShadow = true
    hilt.Parent = model

    -- Crossguard
    local guard = Instance.new("Part")
    guard.Name = "Crossguard"
    guard.Size = Vector3.new(0.8, 0.15, 0.15)
    guard.BrickColor = BrickColor.new("Medium stone grey")
    guard.Material = Enum.Material.Metal
    guard.CastShadow = true
    guard.Parent = model

    local guardWeld = Instance.new("WeldConstraint")
    guardWeld.Part0 = hilt
    guardWeld.Part1 = guard
    guardWeld.Parent = hilt

    -- Blade
    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.Size = Vector3.new(0.1, 2.4, 0.05)
    blade.BrickColor = BrickColor.new("Bright blue") -- placeholder colour, easy to see
    blade.Material = Enum.Material.Metal
    blade.CastShadow = true
    blade.Parent = model

    local bladeWeld = Instance.new("WeldConstraint")
    bladeWeld.Part0 = hilt
    bladeWeld.Part1 = blade
    bladeWeld.Parent = hilt

    -- CustomPhysicalProperties so mass is controlled by WeaponConfig
    local props = PhysicalProperties.new(
        config.mass / (hilt.Size.X * hilt.Size.Y * hilt.Size.Z), -- density from mass
        0.3, -- friction
        0.1, -- elasticity
        0.5,
        0.5
    )
    hilt.CustomPhysicalProperties = props

    model.PrimaryPart = hilt
    return model
end

local function buildControlPart(hand: BasePart): Part
    -- An unanchored, massless, invisible part welded to the hand.
    -- AlignPosition/Orientation on the hilt will chase this part.
    local ctrl = Instance.new("Part")
    ctrl.Name = "WeaponControl"
    ctrl.Size = Vector3.new(0.1, 0.1, 0.1)
    ctrl.Transparency = 1
    ctrl.CanCollide = false
    ctrl.Massless = true
    ctrl.CastShadow = false
    ctrl.Parent = hand.Parent -- put in character

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hand
    weld.Part1 = ctrl
    weld.Parent = ctrl

    return ctrl
end

local function equipSword(character: Model)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart
    if not humanoidRootPart then
        return
    end

    -- Use RightHand (R15) or Right Arm (R6)
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not hand then
        return
    end

    local ctrl = buildControlPart(hand :: BasePart)
    -- Offset the control part so sword sits naturally in the grip
    ctrl.CFrame = (hand :: BasePart).CFrame * CFrame.new(0, -0.4, 0)

    local sword = buildSword()
    sword.Parent = workspace

    local hilt = sword.PrimaryPart :: BasePart
    hilt.CFrame = ctrl.CFrame

    -- AlignPosition: pulls the hilt toward the control part
    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    local hiltAttachPos = Instance.new("Attachment")
    hiltAttachPos.Parent = hilt
    alignPos.Attachment0 = hiltAttachPos
    alignPos.Position = ctrl.Position
    alignPos.MaxForce = config.maxForce
    alignPos.Responsiveness = config.responsiveness
    alignPos.RigidityEnabled = false
    alignPos.Parent = hilt

    -- AlignOrientation: rotates the hilt to match the control part
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    local hiltAttachOri = Instance.new("Attachment")
    hiltAttachOri.Parent = hilt
    alignOri.Attachment0 = hiltAttachOri
    alignOri.CFrame = ctrl.CFrame
    alignOri.MaxTorque = config.maxTorque
    alignOri.Responsiveness = config.responsiveness
    alignOri.RigidityEnabled = false
    alignOri.Parent = hilt

    -- Give network ownership to the player so weapon physics are client-authoritative
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        hilt:SetNetworkOwner(player)
    end

    -- Clean up sword when character is removed
    character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(game) then
            sword:Destroy()
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            equipSword(character)
        end)
    end)
end)

-- Handle players already in game
for _, player in Players:GetPlayers() do
    if player.Character then
        task.defer(function()
            equipSword(player.Character)
        end)
    end
end
