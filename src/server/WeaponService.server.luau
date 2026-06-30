--[[
    Spawns a gray stick and welds it rigidly to the right hand.
    WeaponController (LocalScript) creates a local IKControl that swings the arm;
    the sword follows for free because of the WeldConstraint.

    Drop mechanic:
    While the sword is held, a Heartbeat loop uses GetPartsInPart (a geometric
    query — works without CanCollide) to detect when the sword overlaps
    non-character geometry.
      • Fast-moving hit (AssemblyLinearVelocity ≥ INSTANT_DROP_SPEED): instant drop.
      • Sustained overlap (sword pressed into something): drop after SUSTAIN_TIME s.
    On drop the WeldConstraint is disabled and CanCollide is enabled so the
    sword falls and rests on the ground as a physics object.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- === Drop knobs ===
local INSTANT_DROP_SPEED = 25 -- studs/s: overlapping part must be this fast to instant-drop
local SUSTAIN_TIME = 1.5 -- seconds of continuous overlap before a pressure-drop

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
    sword.CanCollide = false -- kept off while held; enabled on drop to avoid weld jitter
    sword.Anchored = false
    sword.CFrame = hand.CFrame * CFrame.new(0, -1.1, 0)
    sword.Parent = character

    local weld = Instance.new("WeldConstraint")
    weld.Name = "SwordWeld" -- named so WeaponController can WaitForChild it
    weld.Part0 = hand
    weld.Part1 = sword
    weld.Parent = sword

    -- Overlap params: exclude the character so self-hits never trigger a drop
    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = { character }
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local contactTimer = 0
    local checkTick = 0

    local conn: RBXScriptConnection
    conn = RunService.Heartbeat:Connect(function(dt)
        -- Stop checking once the sword is dropped or the character is gone
        if not weld.Enabled or not character:IsDescendantOf(game) then
            conn:Disconnect()
            return
        end

        -- Run the geometric query every 5 frames to keep cost low
        checkTick += 1
        if checkTick % 5 ~= 0 then
            return
        end

        local overlapping = workspace:GetPartsInPart(sword, overlapParams)

        local anyContact = false
        for _, part in overlapping do
            -- Instant drop: a fast-moving object punched through the sword
            if part.AssemblyLinearVelocity.Magnitude >= INSTANT_DROP_SPEED then
                weld.Enabled = false
                sword.CanCollide = true
                conn:Disconnect()
                return
            end
            anyContact = true
        end

        if anyContact then
            contactTimer += dt * 5 -- compensate for the ×5 frame skip
            if contactTimer >= SUSTAIN_TIME then
                weld.Enabled = false
                sword.CanCollide = true
                conn:Disconnect()
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
