--[[
    Reads WASD + Shift + Space each frame, feeds them through the pure shared modules,
    and drives the Humanoid's WalkSpeed and jump.

    Acceleration/deceleration feel knobs are at the top — Dariy can tweak them.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MovementIntent = require(game.ReplicatedStorage.Shared.Movement.MovementIntent)
local StanceMachine = require(game.ReplicatedStorage.Shared.Movement.StanceMachine)

-- === Feel knobs (tune these during play-test) ===
local BASE_WALK_SPEED = 16 -- studs/s at full speed
local ACCEL_FACTOR = 8 -- higher = snappier acceleration
local DECEL_FACTOR = 10 -- higher = snappier stop

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local stanceMachine = StanceMachine.new()
local currentSpeedMul = 0 -- smoothed speed multiplier, drives actual WalkSpeed

-- Track jump to prevent double-jump
local canJump = true
humanoid.StateChanged:Connect(function(_, new)
    if new == Enum.HumanoidStateType.Landed then
        canJump = true
    elseif new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
        canJump = false
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.Space and canJump then
        humanoid.Jump = true
    end
end)

RunService.Heartbeat:Connect(function(dt)
    -- Re-fetch character state each frame in case of respawn
    character = player.Character
    if not character then
        return
    end
    humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local keys = {
        w = UserInputService:IsKeyDown(Enum.KeyCode.W),
        a = UserInputService:IsKeyDown(Enum.KeyCode.A),
        s = UserInputService:IsKeyDown(Enum.KeyCode.S),
        d = UserInputService:IsKeyDown(Enum.KeyCode.D),
        shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift),
    }

    stanceMachine:update(keys.shift)
    local intent = MovementIntent.compute(keys)

    -- Smooth the speed multiplier for weighty acceleration/deceleration feel
    local targetMul = intent.speedMultiplier
        * (math.abs(intent.direction.x) + math.abs(intent.direction.z) > 0 and 1 or 0)
    local factor = targetMul > currentSpeedMul and ACCEL_FACTOR or DECEL_FACTOR
    currentSpeedMul = currentSpeedMul + (targetMul - currentSpeedMul) * math.min(dt * factor, 1)

    humanoid.WalkSpeed = BASE_WALK_SPEED * math.max(currentSpeedMul, intent.speedMultiplier * 0.01)

    -- Drive movement direction relative to camera
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local camYaw = math.atan2(-camera.CFrame.LookVector.X, -camera.CFrame.LookVector.Z)
    local cos, sin = math.cos(camYaw), math.sin(camYaw)
    local worldX = intent.direction.x * cos - intent.direction.z * sin
    local worldZ = intent.direction.x * sin + intent.direction.z * cos

    humanoid:Move(Vector3.new(worldX, 0, worldZ), false)
end)
