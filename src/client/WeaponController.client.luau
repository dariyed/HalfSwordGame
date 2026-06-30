--[[
    Mouse-driven arm swing via Motor6D.Transform.

    The Animator writes Motor6D.Transform during the physics step.
    By binding at Enum.RenderPriority.Last (runs last before the frame draws),
    we overwrite the Animator's value so our rotation is what actually renders.

    Only write Transform while weight > 0 — when we stop writing, the Animator
    resumes full control and the arm returns to its idle/walk pose.

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

    local rightUpperArm = character:WaitForChild("RightUpperArm", 10) :: BasePart?
    if not rightUpperArm then
        warn("WeaponController: RightUpperArm not found")
        return
    end

    local shoulder = rightUpperArm:WaitForChild("RightShoulder", 10) :: Motor6D?
    if not shoulder then
        warn("WeaponController: RightShoulder not found inside RightUpperArm")
        return
    end

    currentWeight = 0

    RunService:BindToRenderStep(
        "WeaponSwing",
        Enum.RenderPriority.Last.Value, -- runs after Animator; our value wins
        function()
            if not character:IsDescendantOf(game) then
                RunService:UnbindFromRenderStep("WeaponSwing")
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

            -- Only write while weight is meaningful.
            -- When we stop writing, the Animator takes full control again.
            if currentWeight > 0.005 then
                local w = currentWeight
                -- Post-multiply Transform so our swing sits on top of the animation pose.
                -- X → forward/back arm raise (pitch), Y → horizontal sweep (yaw).
                -- Negate a term if its direction feels reversed in-game.
                shoulder.Transform = CFrame.Angles(-swingState.pitch * w, -swingState.yaw * w, 0)
            end
        end
    )
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(function(newCharacter)
    RunService:UnbindFromRenderStep("WeaponSwing")
    onCharacter(newCharacter)
end)
