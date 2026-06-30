--[[
    Spawns a gray stick and welds it rigidly to the right hand.
    WeaponController (LocalScript) creates a local IKControl that swings the arm;
    the sword follows for free because of the WeldConstraint.

    Drop mechanic — uses Touched / TouchEnded (requires CanCollide = true):
      • Fast-moving hit (AssemblyLinearVelocity ≥ INSTANT_DROP_SPEED): instant drop.
      • Sustained contact (sword pressed against something ≥ SUSTAIN_TIME s): drop.
    The WeldConstraint prevents the sword from being physically displaced while held,
    so CanCollide = true only causes collisions to be detected, not to move the sword.
    On drop the weld is disabled; the sword then falls as a free physics object.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- === Drop knobs ===
local INSTANT_DROP_SPEED = 25 -- studs/s: hit part velocity that triggers an instant drop
local SUSTAIN_TIME = 1.5 -- seconds of continuous contact before a pressure-drop

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
    sword.CanCollide = true -- needed for Touched events; weld stops it being displaced
    sword.Anchored = false
    sword.CFrame = hand.CFrame * CFrame.new(0, -1.1, 0)
    sword.Parent = character

    local weld = Instance.new("WeldConstraint")
    weld.Name = "SwordWeld" -- named so WeaponController can WaitForChild it
    weld.Part0 = hand
    weld.Part1 = sword
    weld.Parent = sword

    local function dropSword()
        if not weld.Enabled then
            return
        end
        weld.Enabled = false
    end

    -- Track which non-character parts are currently touching the sword
    local contacts: { [BasePart]: boolean } = {}
    local contactTimer = 0

    sword.Touched:Connect(function(hit)
        if not weld.Enabled then
            return
        end
        if hit:IsDescendantOf(character) then
            return
        end

        -- Instant drop: something fast struck the sword
        if hit.AssemblyLinearVelocity.Magnitude >= INSTANT_DROP_SPEED then
            dropSword()
            return
        end

        -- Start tracking contact for the sustained-pressure drop
        contacts[hit] = true
    end)

    sword.TouchEnded:Connect(function(hit)
        contacts[hit] = nil
    end)

    local conn: RBXScriptConnection
    conn = RunService.Heartbeat:Connect(function(dt)
        if not weld.Enabled or not character:IsDescendantOf(game) then
            conn:Disconnect()
            return
        end

        if next(contacts) ~= nil then
            contactTimer += dt
            if contactTimer >= SUSTAIN_TIME then
                dropSword()
            end
        else
            contactTimer = 0
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
