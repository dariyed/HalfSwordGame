--[[
    Reads WASD + Shift + Space each frame, feeds them through the pure shared modules,
    and drives the Humanoid's WalkSpeed and jump.

    Acceleration/deceleration feel knobs are at the top — Dariy can tweak them.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraState = require(game.ReplicatedStorage.Shared.Camera.CameraState)
local DodgeMachine = require(game.ReplicatedStorage.Shared.Movement.DodgeMachine)
local MovementIntent = require(game.ReplicatedStorage.Shared.Movement.MovementIntent)
local StanceMachine = require(game.ReplicatedStorage.Shared.Movement.StanceMachine)

-- === Feel knobs (tune these during play-test) ===
local BASE_WALK_SPEED = 16 -- studs/s at full speed
local ACCEL_FACTOR = 8 -- higher = snappier acceleration
local DECEL_FACTOR = 50 -- higher = snappier stop

local player = Players.LocalPlayer

-- Disable Roblox's built-in control script so this controller owns movement and jump entirely.
-- Without this the default script also sets humanoid.Jump = true while Space is held,
-- causing the character to re-jump every time it lands.
local PlayerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
PlayerModule:GetControls():Disable()

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- Character faces camera direction, not movement direction.
-- AutoRotate would spin the body toward WASD; we rotate it manually via CameraState.yaw.
humanoid.AutoRotate = false

local stanceMachine = StanceMachine.new()
local dodgeMachine = DodgeMachine.new()
local currentSpeedMul = 0 -- smoothed speed multiplier, drives actual WalkSpeed

-- Track jump to prevent double-jump (and held-Space re-jump on landing)
local canJump = true
humanoid.StateChanged:Connect(function(_, new)
    if new == Enum.HumanoidStateType.Jumping then
        humanoid.Jump = false -- clear flag so landing with Space held doesn't re-trigger
        canJump = false
    elseif new == Enum.HumanoidStateType.Freefall then
        canJump = false
    elseif new == Enum.HumanoidStateType.Landed then
        canJump = true
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

    -- Both dashes require Shift. Side dash also blocked while W or S held.
    local noShift = not keys.shift
    local dodging = dodgeMachine:update(
        keys.a,
        keys.d,
        keys.w,
        keys.s,
        dt,
        noShift or keys.w or keys.s,
        noShift
    )

    -- Smooth the speed multiplier for weighty acceleration/deceleration feel
    local moving = math.abs(intent.direction.x) + math.abs(intent.direction.z) > 0
    local targetMul = (dodging and dodgeMachine:activeDodgeMultiplier() or intent.speedMultiplier)
        * (moving and 1 or 0)
    local factor = targetMul > currentSpeedMul and ACCEL_FACTOR or DECEL_FACTOR
    currentSpeedMul = currentSpeedMul + (targetMul - currentSpeedMul) * math.min(dt * factor, 1)
    if math.abs(currentSpeedMul - targetMul) < 0.08 then
        currentSpeedMul = targetMul
    end

    humanoid.WalkSpeed = BASE_WALK_SPEED * currentSpeedMul

    -- Drive movement direction relative to camera.
    -- Project the camera's look and right vectors onto the XZ plane so slope doesn't tilt movement.
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local look = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector
    local camForward = Vector3.new(look.X, 0, look.Z)
    local camRight = Vector3.new(right.X, 0, right.Z)
    if camForward.Magnitude > 0.001 then
        camForward = camForward.Unit
    end
    if camRight.Magnitude > 0.001 then
        camRight = camRight.Unit
    end

    -- intent.direction.z = -1 for W (forward), so negate it to align with camera forward
    local worldDir = camForward * -intent.direction.z + camRight * intent.direction.x
    humanoid:Move(worldDir, false)

    -- Rotate the character to face the camera yaw (written by CameraController each frame).
    local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
    if root then
        local facingCF = CFrame.new(root.Position) * CFrame.Angles(0, CameraState.yaw, 0)
        root.CFrame = facingCF
    end
end)
