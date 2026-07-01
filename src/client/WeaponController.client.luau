--[[
    Mouse-driven arm swing via IKControl — two-handed grip.

    Two IKControls share the same weight blend:
      • Right arm: moves toward the mouse-driven swing target.
      • Left arm:  grips the sword handle GRIP_OFFSET studs below the right hand.
    When LMB is released both arms return to the idle animation.

    The sword is welded to RightHand by WeaponService and follows for free.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)

-- RemoteEvent: client fires this to tell the server to disable the sword weld
local dropSwordRemote =
    game.ReplicatedStorage:WaitForChild("WeaponEvents"):WaitForChild("DropSword") :: RemoteEvent

-- === Feel knobs ===
local WEIGHT_SPEED = 0.15 -- lerp factor per frame: arm engage / release speed
local ARM_REACH = 1.8 -- studs from right shoulder to IK target (arm extended)
local GRIP_OFFSET = 0.7 -- studs below right hand where the left hand grips

local player = Players.LocalPlayer

local swingState: SwingMath.SwingState = { yaw = 0, pitch = math.rad(-25) }
local lmbDown = false
local currentWeight = 0

-- Module-level refs for cleanup on respawn
local ikTarget: Part? = nil
local ikTarget2: Part? = nil
local ikControl: IKControl? = nil
local ikControl2: IKControl? = nil

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = false
    end
end)

local function onCharacter(character: Model)
    local sword = character:WaitForChild("Sword", 10) :: BasePart?
    if not sword then
        warn("WeaponController: Sword not found")
        return
    end

    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    local rightUpperArm = character:WaitForChild("RightUpperArm", 10) :: BasePart?
    local rightHand = character:WaitForChild("RightHand", 10) :: BasePart?
    local leftUpperArm = character:WaitForChild("LeftUpperArm", 10) :: BasePart?
    local leftHand = character:WaitForChild("LeftHand", 10) :: BasePart?

    if not root or not rightUpperArm or not rightHand or not leftUpperArm or not leftHand then
        warn("WeaponController: arm parts not found — swing disabled")
        return
    end

    -- swordDropped: set true by client detection OR when server confirms weld is off.
    -- Once true, the render loop zeros IK weights and stops.
    local swordDropped = false

    -- Fallback: watch for the server disabling the weld (e.g. future server-side drop logic)
    local swordWeld = sword:WaitForChild("SwordWeld", 5) :: WeldConstraint?
    if swordWeld then
        swordWeld:GetPropertyChangedSignal("Enabled"):Connect(function()
            if not swordWeld.Enabled then
                swordDropped = true
            end
        end)
    end

    -- Drop detection runs on the CLIENT because Touched fires where physics are simulated.
    -- The character assembly is client-network-owned, so this is the right place.
    local INSTANT_DROP_SPEED = 25 -- studs/s: hit part velocity that instant-drops the sword
    local SUSTAIN_TIME = 0.5 -- seconds of continuous contact before a pressure-drop
    local contacts: { [BasePart]: boolean } = {}
    local contactTimer = 0

    local function triggerDrop()
        if swordDropped then
            return
        end
        swordDropped = true
        dropSwordRemote:FireServer()
    end

    local touchConn: RBXScriptConnection
    touchConn = sword.Touched:Connect(function(hit)
        if swordDropped then
            return
        end
        if hit:IsDescendantOf(character) then
            return
        end
        if hit.AssemblyLinearVelocity.Magnitude >= INSTANT_DROP_SPEED then
            triggerDrop()
            return
        end
        contacts[hit] = true
    end)

    sword.TouchEnded:Connect(function(hit)
        contacts[hit] = nil
    end)

    local contactConn: RBXScriptConnection
    contactConn = RunService.Heartbeat:Connect(function(dt)
        if swordDropped or not character:IsDescendantOf(game) then
            touchConn:Disconnect()
            contactConn:Disconnect()
            contacts = {}
            return
        end
        if next(contacts) ~= nil then
            contactTimer += dt
            if contactTimer >= SUSTAIN_TIME then
                triggerDrop()
            end
        else
            contactTimer = 0
        end
    end)

    -- Clean up from any previous life
    if ikTarget then
        ikTarget:Destroy()
    end
    if ikTarget2 then
        ikTarget2:Destroy()
    end
    if ikControl then
        ikControl:Destroy()
    end
    if ikControl2 then
        ikControl2:Destroy()
    end

    -- Right-arm target: moves in the mouse-driven swing direction
    local t = Instance.new("Part")
    t.Name = "SwingTarget"
    t.Size = Vector3.new(0.1, 0.1, 0.1)
    t.Anchored = true
    t.CanCollide = false
    t.CanTouch = false
    t.Transparency = 1
    t.CFrame = rightHand.CFrame
    t.Parent = workspace
    ikTarget = t

    local ik = Instance.new("IKControl")
    ik.Name = "SwingIK"
    ik.Type = Enum.IKControlType.Position
    ik.ChainRoot = rightUpperArm
    ik.EndEffector = rightHand
    ik.Target = t
    ik.Weight = 0
    ik.Parent = humanoid
    ikControl = ik

    -- Left-arm target: tracks a fixed grip point on the sword handle
    local t2 = Instance.new("Part")
    t2.Name = "SwingTarget2"
    t2.Size = Vector3.new(0.1, 0.1, 0.1)
    t2.Anchored = true
    t2.CanCollide = false
    t2.CanTouch = false
    t2.Transparency = 1
    t2.CFrame = leftHand.CFrame
    t2.Parent = workspace
    ikTarget2 = t2

    local ik2 = Instance.new("IKControl")
    ik2.Name = "SwingIK2"
    ik2.Type = Enum.IKControlType.Position
    ik2.ChainRoot = leftUpperArm
    ik2.EndEffector = leftHand
    ik2.Target = t2
    ik2.Weight = 0
    ik2.Parent = humanoid
    ikControl2 = ik2

    currentWeight = 0

    RunService:BindToRenderStep("WeaponSwing", Enum.RenderPriority.Last.Value, function()
        if not character:IsDescendantOf(game) or swordDropped then
            -- Character gone or sword knocked out — zero weights and stop
            ik.Weight = 0
            ik2.Weight = 0
            RunService:UnbindFromRenderStep("WeaponSwing")
            return
        end

        -- Accumulate mouse into swing state; drift to rest when LMB released
        if lmbDown then
            local delta = UserInputService:GetMouseDelta()
            swingState = SwingMath.accumulate(swingState, delta.X, delta.Y)
        else
            swingState = {
                yaw = swingState.yaw * 0.9,
                pitch = swingState.pitch * 0.9 + math.rad(-25) * 0.1,
            }
        end

        -- Shared weight: both IKControls engage / release together
        local targetWeight = lmbDown and 1 or 0
        currentWeight = currentWeight + (targetWeight - currentWeight) * WEIGHT_SPEED
        ik.Weight = currentWeight
        ik2.Weight = currentWeight

        -- ── Right arm: swing toward mouse direction ──────────────────────────
        local lx, ly, lz = SwingMath.localBladeDir(swingState)
        local worldDir = root.CFrame:VectorToWorldSpace(Vector3.new(lx, ly, lz))
        local shoulderPos = rightUpperArm.Position + Vector3.new(0, 0.3, 0)
        local swingPos = shoulderPos + worldDir * ARM_REACH
        t.CFrame = CFrame.new(rightHand.Position:Lerp(swingPos, currentWeight))

        -- ── Left arm: grip the sword handle below the right hand ─────────────
        -- The sword is welded to RightHand with its length along -YVector,
        -- so the second grip is GRIP_OFFSET studs down that axis.
        local gripPos = rightHand.Position - rightHand.CFrame.YVector * GRIP_OFFSET
        t2.CFrame = CFrame.new(leftHand.Position:Lerp(gripPos, currentWeight))
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(function(newCharacter)
    RunService:UnbindFromRenderStep("WeaponSwing")
    onCharacter(newCharacter)
end)
