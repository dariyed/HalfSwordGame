--[[
    Custom scriptable camera: third-person orbit with mouse-look, C key toggles first-person.
    Wall collision via raycast prevents clipping through geometry.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraMath = require(game.ReplicatedStorage.Shared.Camera.CameraMath)
local CameraMode = require(game.ReplicatedStorage.Shared.Camera.CameraMode)
local Sensitivity = require(game.ReplicatedStorage.Shared.Settings.Sensitivity)

-- === Feel knobs ===
local CAMERA_DISTANCE = 12 -- studs behind the character in third-person
local HEAD_OFFSET = Vector3.new(0, 1.5, 0) -- point camera looks at (upper chest / neck)
local WALL_MARGIN = 0.35 -- studs to stay away from walls
local sensitivity = Sensitivity.DEFAULT -- start with the shared default; tunable in Issue #7

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

local mode = CameraMode.new()
local yaw = 0
local pitch = math.rad(-15) -- slight downward tilt by default

-- C key toggles first/third person
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.C then
        mode:toggle()
        local character = player.Character
        if not character then
            return
        end
        local inFirst = mode:isFirstPerson()
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") or part:IsA("Decal") then
                (part :: BasePart).LocalTransparencyModifier = inFirst and 1 or 0
            end
        end
    end
end)

-- Raycast from target toward camera; if something blocks, pull the camera closer.
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

RunService.RenderStepped:Connect(function()
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

    local target = root.Position + HEAD_OFFSET

    if mode:isFirstPerson() then
        camera.CFrame = CFrame.new(target) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
    else
        local desired = CameraMath.toCFrame(target, yaw, pitch, CAMERA_DISTANCE)
        camera.CFrame = collide(target, desired)
    end
end)
