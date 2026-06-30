--[[
    Mouse-driven arm swing via Motor6D.Transform.

    The RightShoulder Motor6D lives inside RightUpperArm and drives the whole arm.
    Setting its Transform adds rotation on top of the idle/walk animation.
    The sword is welded to RightHand so it follows for free — zero physics on the sword.

    LMB held   → Transform lerps to mouse-derived rotation
    LMB release → Transform lerps back to identity (animation takes over)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)

-- === Feel knobs ===
-- How fast the IK weight blends in/out (lerp factor per frame at 60 fps)
local WEIGHT_SPEED = 0.15

local player = Players.LocalPlayer

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
    character:WaitForChild("Sword", 10)

    local rightUpperArm = character:WaitForChild("RightUpperArm", 5) :: BasePart?
    if not rightUpperArm then
        warn("WeaponController: RightUpperArm not found")
        return
    end

    -- The Motor6D that controls where the upper arm sits relative to the torso.
    -- Transform on this motor rotates the WHOLE arm (upper + lower + hand + sword).
    local shoulder = rightUpperArm:FindFirstChildOfClass("Motor6D") :: Motor6D?
    if not shoulder then
        warn("WeaponController: shoulder Motor6D not found in RightUpperArm")
        return
    end

    currentWeight = 0

    RunService.RenderStepped:Connect(function()
        if not character:IsDescendantOf(game) then
            return
        end

        if lmbDown then
            local delta = UserInputService:GetMouseDelta()
            swingState = SwingMath.accumulate(swingState, delta.X, delta.Y)
        else
            -- Drift back toward ready position
            swingState = {
                yaw = swingState.yaw * 0.9,
                pitch = swingState.pitch * 0.9 + math.rad(-25) * 0.1,
            }
        end

        -- Blend weight
        local targetWeight = lmbDown and 1 or 0
        currentWeight = currentWeight + (targetWeight - currentWeight) * WEIGHT_SPEED

        -- Build shoulder rotation from swing state, blended by currentWeight.
        -- yaw  → left/right sweep  (Y axis of the joint)
        -- pitch → forward/back raise (X axis of the joint)
        -- If a direction is reversed in-game, negate the relevant term.
        local w = currentWeight
        shoulder.Transform = CFrame.Angles(-swingState.pitch * w, -swingState.yaw * w, 0)
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(onCharacter)
