--[[
    Mouse-driven weapon control — shoulder-pivot swing.

    The swing ORIGIN is a fixed point at right-shoulder height in character space.
    The tip sweeps a large arc around that origin, so movement feels driven by the
    whole arm, not the wrist.

    At rest (LMB up):   sword hangs straight down below the hand, rigid.
    While swinging (LMB held): sword chases the mouse goal with physics lag (weight).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)
local WeaponConfig = require(game.ReplicatedStorage.Shared.Weapon.WeaponConfig)

-- === Feel knobs ===
local config = WeaponConfig.get("default")
local SWING_MAX_FORCE = config.maxForce
local SWING_MAX_TORQUE = config.maxTorque
local SWING_RESPONSIVENESS = config.responsiveness

-- Right-shoulder origin in character (root) local space
-- This is the pivot — tip sweeps a large arc around here, like a real arm swing
local SHOULDER_LOCAL = Vector3.new(1.2, 1.5, 0)
-- How far from the shoulder the sword CENTER sits (stud).
-- arm ≈ 2 studs, so center at 2.5 puts hilt near hand and tip 1.5 studs past hand
local SWING_REACH = 2.5

local player = Players.LocalPlayer

-- Start in a natural ready position: sword forward and slightly down
local swingState: SwingMath.SwingState = { yaw = 0, pitch = math.rad(-25) }
local lmbDown = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = true
        -- No state reset — sword stays where it is, no jump
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = false
    end
end)

-- Build a CFrame whose +Y axis points along worldDir.
-- The sword Part's long axis is +Y, so this orients it as a blade.
local function bladeCF(worldDir: Vector3): CFrame
    -- CFrame.lookAt makes -Z face the target; rotating +90° on X turns -Z into +Y.
    return CFrame.lookAt(Vector3.zero, worldDir) * CFrame.Angles(math.pi / 2, 0, 0)
end

local function onCharacter(character: Model)
    local sword = character:WaitForChild("Sword", 10) :: BasePart?
    if not sword then
        warn("WeaponController: Sword not found")
        return
    end
    local hand = character:WaitForChild("RightHand", 5) :: BasePart?
    if not hand then
        return
    end

    local swordAttach = Instance.new("Attachment")
    swordAttach.Parent = sword

    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = swordAttach
    alignPos.Position = sword.Position
    alignPos.MaxForce = 40000
    alignPos.Responsiveness = 200
    alignPos.RigidityEnabled = true
    alignPos.Parent = sword

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = swordAttach
    alignOri.CFrame = bladeCF(Vector3.new(0, -1, 0))
    alignOri.MaxTorque = 20000
    alignOri.Responsiveness = 200
    alignOri.RigidityEnabled = true
    alignOri.Parent = sword

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

            local lx, ly, lz = SwingMath.localBladeDir(swingState)
            local worldDir = root.CFrame:VectorToWorldSpace(Vector3.new(lx, ly, lz))

            -- Sword center sits SWING_REACH studs from the shoulder along the blade direction
            local shoulderWorld = root.CFrame:PointToWorldSpace(SHOULDER_LOCAL)
            alignPos.Position = shoulderWorld + worldDir * SWING_REACH
            alignPos.MaxForce = SWING_MAX_FORCE
            alignPos.Responsiveness = SWING_RESPONSIVENESS
            alignPos.RigidityEnabled = false

            alignOri.CFrame = bladeCF(worldDir)
            alignOri.MaxTorque = SWING_MAX_TORQUE
            alignOri.Responsiveness = SWING_RESPONSIVENESS
            alignOri.RigidityEnabled = false
        else
            -- Rest: hang straight down below the hand, rigid
            alignPos.Position = hand.Position + Vector3.new(0, -1, 0)
            alignPos.MaxForce = 40000
            alignPos.Responsiveness = 200
            alignPos.RigidityEnabled = true

            alignOri.CFrame = bladeCF(Vector3.new(0, -1, 0))
            alignOri.MaxTorque = 20000
            alignOri.Responsiveness = 200
            alignOri.RigidityEnabled = true

            -- Drift back toward ready position for next LMB press
            swingState = {
                yaw = swingState.yaw * 0.9,
                pitch = swingState.pitch * 0.9 + math.rad(-25) * 0.1,
            }
        end
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(onCharacter)
