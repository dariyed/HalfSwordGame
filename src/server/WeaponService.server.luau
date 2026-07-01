--[[
    Spawns a gray sword and holds it at the RightHand via AlignPosition +
    AlignOrientation — mover constraints with limited MaxForce/MaxTorque.

    Physics-based grip:
      • AlignPosition pulls the sword center to a point 1.1 studs below the hand.
      • AlignOrientation matches the sword's rotation to the hand's rotation.
      • Because the force is capped, wall pressure physically bends the sword away.
      • WeaponController (client) watches the drift between sword and grip point.
        When drift > its threshold it fires DropSword; this script destroys the
        constraints so the sword falls free as a normal physics object.

    === Grip knobs ===
    GRIP_STRENGTH   higher = harder to dislodge (MaxForce / MaxTorque base)
    GRIP_RESPONSE   higher = snappier tracking, but more reaction force on character
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local weaponEvents = Instance.new("Folder")
weaponEvents.Name = "WeaponEvents"
weaponEvents.Parent = ReplicatedStorage

local dropSwordRemote = Instance.new("RemoteEvent")
dropSwordRemote.Name = "DropSword"
dropSwordRemote.Parent = weaponEvents

-- === Grip knobs ===
local GRIP_STRENGTH = 2000 -- N: force cap before sword bends away
local GRIP_RESPONSE = 20 -- responsiveness: how quickly constraints correct drift

type SwordRefs = {
    alignPos: AlignPosition,
    alignOri: AlignOrientation,
    gripAttach: Attachment,
    sword: Part,
}
local swordRefs: { [Player]: SwordRefs } = {}

local function equipSword(character: Model, player: Player)
    local hand = character:WaitForChild("RightHand", 5) :: BasePart?
    if not hand then
        warn("WeaponService: RightHand not found for", player.Name)
        return
    end

    local sword = Instance.new("Part")
    sword.Name = "Sword"
    sword.Size = Vector3.new(0.2, 2, 0.2)
    sword.BrickColor = BrickColor.new("Medium stone grey")
    sword.Material = Enum.Material.SmoothPlastic
    sword.CanCollide = true
    sword.Anchored = false
    sword.CFrame = hand.CFrame * CFrame.new(0, -1.1, 0)
    sword.Parent = character
    sword:SetNetworkOwner(player)

    -- Grip attachment on the hand: 1.1 studs below hand center (matching old offset)
    local gripAttach = Instance.new("Attachment")
    gripAttach.Name = "SwordGrip"
    gripAttach.Position = Vector3.new(0, -1.1, 0)
    gripAttach.Parent = hand

    -- Sword attachment at sword center (no offset)
    local swordAttach = Instance.new("Attachment")
    swordAttach.Name = "SwordRoot"
    swordAttach.Parent = sword

    -- AlignPosition: pulls sword toward grip point; can be overwhelmed by wall pressure
    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "SwordAlignPos"
    alignPos.MaxForce = GRIP_STRENGTH
    alignPos.Responsiveness = GRIP_RESPONSE
    alignPos.RigidityEnabled = false
    alignPos.Attachment0 = swordAttach
    alignPos.Attachment1 = gripAttach
    alignPos.Parent = sword

    -- AlignOrientation: keeps sword rotation matched to hand rotation
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Name = "SwordAlignOri"
    alignOri.MaxTorque = GRIP_STRENGTH * 0.5
    alignOri.Responsiveness = GRIP_RESPONSE
    alignOri.RigidityEnabled = false
    alignOri.Attachment0 = swordAttach
    alignOri.Attachment1 = gripAttach
    alignOri.Parent = sword

    swordRefs[player] = {
        alignPos = alignPos,
        alignOri = alignOri,
        gripAttach = gripAttach,
        sword = sword :: Part,
    }
end

-- Client fires this when drift > DROP_THRESHOLD
dropSwordRemote.OnServerEvent:Connect(function(player: Player)
    local refs = swordRefs[player]
    if not refs then
        return
    end
    refs.alignPos:Destroy()
    refs.alignOri:Destroy()
    refs.gripAttach:Destroy()
    refs.sword.Parent = workspace -- move to workspace so it persists after respawn
    swordRefs[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            equipSword(character, player)
        end)
    end)
    player.CharacterRemoving:Connect(function()
        swordRefs[player] = nil
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    swordRefs[player] = nil
end)

for _, player in Players:GetPlayers() do
    if player.Character then
        task.defer(function()
            equipSword(player.Character, player)
        end)
    end
end
