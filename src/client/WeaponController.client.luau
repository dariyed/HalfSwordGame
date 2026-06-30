--[[
    Mouse-driven arm swing via Motor6D.C0.

    The RightShoulder Motor6D's C0 property is the joint's base offset.
    The Animator writes to Motor6D.Transform, but never touches C0.
    So we multiply C0 by our swing rotation each frame — the result is
    the arm rotating on top of whatever animation is playing.

    The sword is welded to RightHand so it follows the arm for free.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)

-- === Feel knobs ===
local WEIGHT_SPEED = 0.15 -- lerp factor per frame for blend in/out

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

    -- WaitForChild ensures both parts have finished loading before we touch them
    local rightUpperArm = character:WaitForChild("RightUpperArm", 10) :: BasePart?
    if not rightUpperArm then
        warn("WeaponController: RightUpperArm not found")
        return
    end

    local shoulder = rightUpperArm:WaitForChild("RightShoulder", 10) :: Motor6D?
    if not shoulder then
        warn("WeaponController: RightShoulder Motor6D not found")
        return
    end

    -- C0 is the joint's base offset on the torso side.
    -- The Animator never modifies C0, so we can safely multiply our rotation in.
    local originalC0 = shoulder.C0
    currentWeight = 0

    character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(game) then
            -- Restore C0 in case the Humanoid lingers after respawn
            shoulder.C0 = originalC0
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not character:IsDescendantOf(game) then
            return
        end

        if lmbDown then
            local delta = UserInputService:GetMouseDelta()
            swingState = SwingMath.accumulate(swingState, delta.X, delta.Y)
        else
            swingState = {
                yaw = swingState.yaw * 0.9,
                pitch = swingState.pitch * 0.9 + math.rad(-25) * 0.1,
            }
        end

        local targetWeight = lmbDown and 1 or 0
        currentWeight = currentWeight + (targetWeight - currentWeight) * WEIGHT_SPEED

        -- Post-multiply C0 by the swing rotation so it sits on top of the animation.
        -- Axes (in joint local space):
        --   X (first)  → forward / backward arm raise  (pitch)
        --   Y (second) → horizontal arm sweep           (yaw)
        -- If a direction feels reversed, negate the matching term.
        local w = currentWeight
        shoulder.C0 = originalC0 * CFrame.Angles(-swingState.pitch * w, -swingState.yaw * w, 0)
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(onCharacter)
