--[[
    Spawns a gray stick and welds it rigidly to the right hand.
    WeaponController (LocalScript) creates a local IKControl that swings the arm;
    the sword follows for free because of the WeldConstraint.

    Drop mechanic:
    Roblox fires Touched events on the machine that SIMULATES the physics.
    The character assembly (including the welded sword) is client-network-owned,
    so Touched fires on the CLIENT, not the server. WeaponController handles the
    collision detection and fires DropSword here when a drop is triggered.
    This script just disables the weld in response.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent so the client can signal a drop to the server
local weaponEvents = Instance.new("Folder")
weaponEvents.Name = "WeaponEvents"
weaponEvents.Parent = ReplicatedStorage

local dropSwordRemote = Instance.new("RemoteEvent")
dropSwordRemote.Name = "DropSword"
dropSwordRemote.Parent = weaponEvents

-- One weld per player so OnServerEvent can find and disable it
local swordWelds: { [Player]: WeldConstraint } = {}

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
    sword.CanCollide = true -- CanCollide=true so Touched fires on the client
    sword.Anchored = false
    sword.CFrame = hand.CFrame * CFrame.new(0, -1.1, 0)
    sword.Parent = character

    -- Explicitly give the player network ownership of the sword so that Touched
    -- events fire in their LocalScript (WeaponController). Without this, Roblox
    -- may keep the sword server-owned even though it is welded to the character.
    sword:SetNetworkOwner(player)

    local weld = Instance.new("WeldConstraint")
    weld.Name = "SwordWeld"
    weld.Part0 = hand
    weld.Part1 = sword
    weld.Parent = sword

    swordWelds[player] = weld
end

-- Client fires this when it detects a drop condition (fast hit or sustained pressure)
dropSwordRemote.OnServerEvent:Connect(function(player: Player)
    local weld = swordWelds[player]
    if weld and weld.Enabled then
        weld.Enabled = false
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            equipSword(character, player)
        end)
    end)
    player.CharacterRemoving:Connect(function()
        swordWelds[player] = nil
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    swordWelds[player] = nil
end)

for _, player in Players:GetPlayers() do
    if player.Character then
        task.defer(function()
            equipSword(player.Character, player)
        end)
    end
end
