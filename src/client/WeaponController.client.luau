--[[
    Mouse-driven arm swing via IKControl.

    The sword is welded to the hand — it never moves independently.
    Instead, an IKControl under the Humanoid bends the right arm so the
    hand reaches the mouse-derived target position. The sword follows for free.

    While LMB is held   → IK weight = 1, arm tracks mouse
    While LMB released  → IK weight blends to 0, arm returns to idle animation
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)

-- === Feel knobs ===
-- Right shoulder joint in character-local (root) space.
-- Tune X (right) and Y (up) if the IK pivot feels off.
local SHOULDER_LOCAL = Vector3.new(1.5, 1.5, 0)
-- How far from the shoulder joint the hand should reach (arm length in studs).
local ARM_LENGTH = 2.5
-- How quickly IK weight blends in/out (0-1 lerp factor per frame).
local WEIGHT_SPEED = 0.2

local player = Players.LocalPlayer

-- Start with arm in a natural ready position: forward and slightly down
local swingState: SwingMath.SwingState = { yaw = 0, pitch = math.rad(-25) }
local lmbDown = false
local currentWeight = 0

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
    character:WaitForChild("Sword", 10) -- wait for WeaponService to weld the sword

    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    local rightUpperArm = character:WaitForChild("RightUpperArm", 5) :: BasePart?
    local rightHand = character:WaitForChild("RightHand", 5) :: BasePart?
    if not rightUpperArm or not rightHand then
        return
    end

    -- Invisible anchored target part that the hand will chase
    local ikTarget = Instance.new("Part")
    ikTarget.Name = "SwingTarget"
    ikTarget.Size = Vector3.new(0.1, 0.1, 0.1)
    ikTarget.Anchored = true
    ikTarget.CanCollide = false
    ikTarget.CanTouch = false
    ikTarget.Transparency = 1
    ikTarget.CFrame = rightHand.CFrame -- start at current hand position
    ikTarget.Parent = workspace

    -- IKControl bends RightUpperArm → RightHand chain toward ikTarget
    local ikControl = Instance.new("IKControl")
    ikControl.Name = "SwingIK"
    ikControl.Type = Enum.IKControlType.Position
    ikControl.ChainRoot = rightUpperArm
    ikControl.EndEffector = rightHand
    ikControl.Target = ikTarget
    ikControl.SmoothingEnabled = true
    ikControl.Weight = 0
    ikControl.Parent = humanoid

    -- Clean up the target part when the character is removed
    character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(game) then
            ikTarget:Destroy()
        end
    end)

    currentWeight = 0

    RunService.RenderStepped:Connect(function()
        if not character:IsDescendantOf(game) then
            return
        end
        local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not root then
            return
        end

        if lmbDown then
            local delta = UserInputService:GetMouseDelta()
            swingState = SwingMath.accumulate(swingState, delta.X, delta.Y)
        else
            -- Drift swingState back to ready position while arm relaxes
            swingState = {
                yaw = swingState.yaw * 0.9,
                pitch = swingState.pitch * 0.9 + math.rad(-25) * 0.1,
            }
        end

        -- Compute hand target: shoulder + arm direction * arm length
        local lx, ly, lz = SwingMath.localBladeDir(swingState)
        local worldDir = root.CFrame:VectorToWorldSpace(Vector3.new(lx, ly, lz))
        local shoulderWorld = root.CFrame:PointToWorldSpace(SHOULDER_LOCAL)
        ikTarget.CFrame = CFrame.new(shoulderWorld + worldDir * ARM_LENGTH)

        -- Blend IK weight in/out smoothly
        local targetWeight = lmbDown and 1 or 0
        currentWeight = currentWeight + (targetWeight - currentWeight) * WEIGHT_SPEED
        ikControl.Weight = currentWeight
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(onCharacter)
