--[[
    Mouse-driven weapon control.

    While LMB is held: constraints target the mouse-derived goal on the reach sphere.
    The sword physically fights through its mass to get there, giving it weight.

    While LMB is released: same constraints target the hand grip with high force,
    so the sword rides the hand without a weld.

    Feel knobs at the top.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)
local WeaponConfig = require(game.ReplicatedStorage.Shared.Weapon.WeaponConfig)

-- === Feel knobs ===
local config = WeaponConfig.get("default")
-- While swinging: full force so the blade actually moves
local SWING_MAX_FORCE = config.maxForce
local SWING_MAX_TORQUE = config.maxTorque
local SWING_RESPONSIVENESS = config.responsiveness
-- While at rest (LMB up): very high force so the sword feels welded to hand
local REST_MAX_FORCE = 40000
local REST_MAX_TORQUE = 20000
local REST_RESPONSIVENESS = 50

local player = Players.LocalPlayer

local swingState: SwingMath.SwingState = { yaw = 0, pitch = 0 }
local lmbDown = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = true
        swingState = { yaw = 0, pitch = 0 }
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = false
    end
end)

local function onCharacter(character: Model)
    -- Wait for WeaponService to spawn the sword into the character
    local sword = character:WaitForChild("Sword", 10) :: BasePart?
    if not sword then
        warn("WeaponController: Sword not found in character")
        return
    end

    local hand = character:WaitForChild("RightHand", 5) :: BasePart?
    if not hand then
        return
    end

    -- Attachment at sword centre (AlignPosition targets this point)
    local swordAttach = Instance.new("Attachment")
    swordAttach.Position = Vector3.new(0, 0, 0)
    swordAttach.Parent = sword

    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = swordAttach
    alignPos.Position = sword.Position
    alignPos.MaxForce = REST_MAX_FORCE
    alignPos.Responsiveness = REST_RESPONSIVENESS
    alignPos.RigidityEnabled = false
    alignPos.ApplyAtCenterOfMass = false
    alignPos.Parent = sword

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = swordAttach
    alignOri.CFrame = sword.CFrame
    alignOri.MaxTorque = REST_MAX_TORQUE
    alignOri.Responsiveness = REST_RESPONSIVENESS
    alignOri.RigidityEnabled = false
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
            -- Swing mode: chase mouse on reach sphere
            local delta = UserInputService:GetMouseDelta()
            swingState = SwingMath.accumulate(swingState, delta.X, delta.Y)
            local goalCF = SwingMath.toGoalCFrame(swingState, root.CFrame)

            alignPos.Position = goalCF.Position
            alignPos.MaxForce = SWING_MAX_FORCE
            alignPos.Responsiveness = SWING_RESPONSIVENESS

            alignOri.CFrame = goalCF
            alignOri.MaxTorque = SWING_MAX_TORQUE
            alignOri.Responsiveness = SWING_RESPONSIVENESS
        else
            -- Rest mode: track the hand so the sword rides it like a weld
            local restPos = (hand.CFrame * CFrame.new(0, -1.1, 0)).Position
            alignPos.Position = restPos
            alignPos.MaxForce = REST_MAX_FORCE
            alignPos.Responsiveness = REST_RESPONSIVENESS

            alignOri.CFrame = hand.CFrame
            alignOri.MaxTorque = REST_MAX_TORQUE
            alignOri.Responsiveness = REST_RESPONSIVENESS

            -- Decay swing state so next LMB press starts from neutral
            swingState = {
                yaw = swingState.yaw * 0.85,
                pitch = swingState.pitch * 0.85,
            }
        end
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(onCharacter)
