--[[
    Spawns a sword and anchors its HILT at the grip point via AlignPosition.

    Pivot mechanic:
      • AlignPosition keeps the hilt (top of sword) at the grip attachment —
        rigid, high MaxForce, so the hilt never drifts.
      • AlignOrientation is a weak spring (WRIST_TORQUE) — it tries to keep
        the sword aligned with the arm, but wall contact can overcome it and
        rotate the blade sideways around the hilt.
      • WeaponController measures the angle between the sword and vertical.
        When the blade is deflected past MAX_ANGLE the grip is lost.

    Tuning knobs
      WRIST_TORQUE   lower = bends easier; higher = stronger grip
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local weaponEvents = Instance.new("Folder")
weaponEvents.Name = "WeaponEvents"
weaponEvents.Parent = ReplicatedStorage

local dropSwordRemote = Instance.new("RemoteEvent")
dropSwordRemote.Name = "DropSword"
dropSwordRemote.Parent = weaponEvents

local WRIST_TORQUE = 25 -- N·stud: spring strength the wrist can apply

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
    -- Spawn center 2.1 studs below hand so hilt (+Y end, 1 stud above center)
    -- sits at the grip point (1.1 studs below hand).
    sword.CFrame = hand.CFrame * CFrame.new(0, -2.1, 0)
    sword.Parent = character
    sword:SetNetworkOwner(player)

    -- Grip attachment on hand: 1.1 studs below hand center
    local gripAttach = Instance.new("Attachment")
    gripAttach.Name = "SwordGrip"
    gripAttach.Position = Vector3.new(0, -1.1, 0)
    gripAttach.Parent = hand

    -- Hilt attachment at the TOP end of the sword (+Y = 1 stud above center)
    local swordAttach = Instance.new("Attachment")
    swordAttach.Name = "SwordHilt"
    swordAttach.Position = Vector3.new(0, 1, 0)
    swordAttach.Parent = sword

    -- Keeps hilt locked at grip point. Very high force so walls cannot
    -- displace the hilt — they can only rotate the blade around it.
    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "SwordAlignPos"
    alignPos.MaxForce = 8000
    alignPos.RigidityEnabled = true
    alignPos.Attachment0 = swordAttach
    alignPos.Attachment1 = gripAttach
    alignPos.Parent = sword

    -- Wrist spring: tries to keep blade aligned with the arm direction.
    -- Wall torque can overcome WRIST_TORQUE, rotating the blade.
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Name = "SwordAlignOri"
    alignOri.MaxTorque = WRIST_TORQUE
    alignOri.Responsiveness = 10
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

dropSwordRemote.OnServerEvent:Connect(function(player: Player)
    local refs = swordRefs[player]
    if not refs then
        return
    end
    refs.alignPos:Destroy()
    refs.alignOri:Destroy()
    refs.gripAttach:Destroy()
    refs.sword.Parent = workspace
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
