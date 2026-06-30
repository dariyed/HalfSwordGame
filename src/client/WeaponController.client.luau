--[[
    Mouse-driven arm swing via IKControl.

    Motor6D.Transform is overridden by Roblox's animation engine on every physics
    step — scripts cannot win that race. IKControl is the correct hook: it runs
    INSIDE the Animator's IK pass, so its result is the final joint pose.

    Each frame we move an anchored Part ("SwingTarget") to where the right hand
    should be for the current mouse angle, then let IKControl pull the arm there.
    Weight blends smoothly 0 → 1 when LMB is held and back to 0 when released.

    The sword is welded to RightHand by WeaponService and follows for free.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)

-- === Feel knobs ===
local WEIGHT_SPEED = 0.15 -- lerp factor per frame: how fast the arm engages / releases
local ARM_REACH = 1.8 -- studs from shoulder to the IK target (arm roughly extended)

local player = Players.LocalPlayer

local swingState: SwingMath.SwingState = { yaw = 0, pitch = math.rad(-25) }
local lmbDown = false
local currentWeight = 0

-- Module-level refs so we can clean them up on respawn
local ikTarget: Part? = nil
local ikControl: IKControl? = nil

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
    -- Sword presence confirms WeaponService has finished equipping
    character:WaitForChild("Sword", 10)

    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    local rightUpperArm = character:WaitForChild("RightUpperArm", 10) :: BasePart?
    local rightHand = character:WaitForChild("RightHand", 10) :: BasePart?

    if not root or not rightUpperArm or not rightHand then
        warn("WeaponController: arm parts not found — arm swing disabled")
        return
    end

    -- Remove objects from any previous character life
    if ikTarget then
        ikTarget:Destroy()
    end
    if ikControl then
        ikControl:Destroy()
    end

    -- Anchored local part that we move each frame to steer the arm.
    -- Parented to workspace (client-only; server never sees it).
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

    -- IKControl parented to Humanoid — the Animator solves RightUpperArm → RightHand
    -- so that RightHand arrives at the SwingTarget position.
    local ik = Instance.new("IKControl")
    ik.Name = "SwingIK"
    ik.Type = Enum.IKControlType.Position
    ik.ChainRoot = rightUpperArm
    ik.EndEffector = rightHand
    ik.Target = t
    ik.Weight = 0
    ik.Parent = humanoid
    ikControl = ik

    currentWeight = 0

    RunService:BindToRenderStep("WeaponSwing", Enum.RenderPriority.Last.Value, function()
        if not character:IsDescendantOf(game) then
            RunService:UnbindFromRenderStep("WeaponSwing")
            return
        end

        -- Accumulate mouse delta when swinging; drift back to rest when not
        if lmbDown then
            local delta = UserInputService:GetMouseDelta()
            swingState = SwingMath.accumulate(swingState, delta.X, delta.Y)
        else
            swingState = {
                yaw = swingState.yaw * 0.9,
                pitch = swingState.pitch * 0.9 + math.rad(-25) * 0.1,
            }
        end

        -- Smooth weight: 0 = pure animation, 1 = pure IK swing
        local targetWeight = lmbDown and 1 or 0
        currentWeight = currentWeight + (targetWeight - currentWeight) * WEIGHT_SPEED
        ik.Weight = currentWeight

        -- World-space swing direction from the mouse angle
        local lx, ly, lz = SwingMath.localBladeDir(swingState)
        local worldDir = root.CFrame:VectorToWorldSpace(Vector3.new(lx, ly, lz))

        -- Target = where the hand should land when fully swinging in this direction.
        -- Shoulder is approximately the top of the upper arm.
        local shoulderPos = rightUpperArm.Position + Vector3.new(0, 0.3, 0)
        local swingPos = shoulderPos + worldDir * ARM_REACH

        -- Blend target from the animated hand position (weight ≈ 0) to the swing
        -- goal (weight ≈ 1) so the IK doesn't fight the animation when not swinging.
        t.CFrame = CFrame.new(rightHand.Position:Lerp(swingPos, currentWeight))
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(function(newCharacter)
    RunService:UnbindFromRenderStep("WeaponSwing")
    onCharacter(newCharacter)
end)
