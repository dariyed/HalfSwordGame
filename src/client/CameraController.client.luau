--[[
    Custom scriptable camera: third-person orbit with mouse-look, C key toggles first-person.
    Wall collision via raycast prevents clipping through geometry.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraMath = require(game.ReplicatedStorage.Shared.Camera.CameraMath)
local CameraMode = require(game.ReplicatedStorage.Shared.Camera.CameraMode)
local CameraState = require(game.ReplicatedStorage.Shared.Camera.CameraState)
local Sensitivity = require(game.ReplicatedStorage.Shared.Settings.Sensitivity)

-- === Feel knobs ===
local CAMERA_DISTANCE = 7
local HEAD_OFFSET = Vector3.new(0, 1.5, 0)
local WALL_MARGIN = 0.35
local sensitivity = Sensitivity.DEFAULT

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Disable Roblox's built-in camera module so it doesn't fight ours.
-- pcall guards against API changes across Studio versions.
local PlayerModule = require(player.PlayerScripts:WaitForChild("PlayerModule"))
pcall(function()
    PlayerModule:GetCameras():Disable()
end)

-- Sink scroll wheel so Roblox can't zoom in/out underneath us.
ContextActionService:BindActionAtPriority("SinkCameraZoom", function()
    return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, Enum.UserInputType.MouseWheel)

camera.CameraType = Enum.CameraType.Scriptable
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
UserInputService.MouseIconEnabled = false

local mode = CameraMode.new()
local yaw = 0
local pitch = math.rad(-15)

-- C key toggles first/third person
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.V then
        mode:toggle()
        local character = player.Character
        if not character then
            return
        end
        -- R6 parts to keep visible in first-person (arms and legs, not head/torso)
        local KEEP_VISIBLE = {
            ["Left Arm"] = true,
            ["Right Arm"] = true,
            ["Left Leg"] = true,
            ["Right Leg"] = true,
        }
        local inFirst = mode:isFirstPerson()
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") or part:IsA("Decal") then
                local keep = KEEP_VISIBLE[part.Name] == true
                (part :: BasePart).LocalTransparencyModifier = (inFirst and not keep) and 1 or 0
            end
        end
    end
end)

local function collide(target: Vector3, desiredCF: CFrame): CFrame
    local dir = desiredCF.Position - target
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local character = player.Character
    if character then
        params.FilterDescendantsInstances = { character }
    end
    local hit = workspace:Raycast(target, dir, params)
    if hit then
        local safeDist = math.max(0.5, (hit.Position - target).Magnitude - WALL_MARGIN)
        return CameraMath.toCFrame(target, yaw, pitch, safeDist)
    end
    return desiredCF
end

-- Priority Camera.Value + 1 means we run AFTER the default Roblox camera each frame,
-- so our CFrame always wins even if the default script also wrote to it this frame.
RunService:BindToRenderStep("HalfSwordCamera", Enum.RenderPriority.Camera.Value + 1, function()
    -- Re-assert each frame in case another script resets them.
    camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    local character = player.Character
    if not character then
        return
    end
    local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
    if not root then
        return
    end

    local delta = UserInputService:GetMouseDelta()
    yaw, pitch = CameraMath.accumulate(yaw, pitch, delta.X, delta.Y, sensitivity)

    -- Publish yaw so MovementController can rotate the character to match.
    CameraState.yaw = yaw

    local target = root.Position + HEAD_OFFSET

    if mode:isFirstPerson() then
        camera.CFrame = CFrame.new(target) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
    else
        local desired = CameraMath.toCFrame(target, yaw, pitch, CAMERA_DISTANCE)
        camera.CFrame = collide(target, desired)
    end
end)
