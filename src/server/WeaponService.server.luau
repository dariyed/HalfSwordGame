--[[
    Spawns a sword and welds it to RightHand.

    WeldConstraint: zero lag, zero oscillation, zero spinning.
    The sword is part of the character assembly so it collides reliably.
    Drop: client fires DropSword → server destroys weld and moves sword to
    Workspace so it falls free as a normal physics object.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local weaponEvents = Instance.new("Folder")
weaponEvents.Name = "WeaponEvents"
weaponEvents.Parent = ReplicatedStorage

local dropSwordRemote = Instance.new("RemoteEvent")
dropSwordRemote.Name = "DropSword"
dropSwordRemote.Parent = weaponEvents

type SwordRefs = {
    weld: WeldConstraint,
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

    local weld = Instance.new("WeldConstraint")
    weld.Name = "SwordWeld"
    weld.Part0 = hand
    weld.Part1 = sword
    weld.Parent = sword

    swordRefs[player] = {
        weld = weld,
        sword = sword :: Part,
    }
end

dropSwordRemote.OnServerEvent:Connect(function(player: Player)
    local refs = swordRefs[player]
    if not refs then
        return
    end
    refs.weld:Destroy()
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
