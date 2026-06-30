--[[
    Mouse-driven weapon control.

    While LMB is held, the mouse position is projected onto a sphere around the
    character. AlignPosition + AlignOrientation on the sword hilt chase that goal
    each frame — the sword physically has to fight through its own mass to get there,
    giving it weight. On LMB release the constraints relax back to the weld.

    Feel knobs at the top.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)
local WeaponConfig = require(game.ReplicatedStorage.Shared.Weapon.WeaponConfig)

-- === Feel knobs ===
local config = WeaponConfig.get("default")
-- While swinging: high force/torque so the blade actually moves
local SWING_MAX_FORCE = config.maxForce
local SWING_MAX_TORQUE = config.maxTorque
local SWING_RESPONSIVENESS = config.responsiveness
-- While relaxed (LMB up): lower so the sword settles naturally back
local REST_MAX_FORCE = 2000
local REST_MAX_TORQUE = 1000
local REST_RESPONSIVENESS = 8

local player = Players.LocalPlayer
local swingState: SwingMath.SwingState = { yaw = 0, pitch = 0 }
local lmbDown = false

-- Wait for character and sword
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getSword(character: Model): BasePart?
    return character:FindFirstChild("Sword", true) :: BasePart?
end

local function getRootPart(character: Model): BasePart?
    return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Build AlignPosition + AlignOrientation on the sword hilt (runs once per life)
local function setupConstraints(sword: BasePart): (AlignPosition, AlignOrientation)
    -- Attachment at hilt centre
    local attach = sword:FindFirstChildOfClass("Attachment")
    if not attach then
        attach = Instance.new("Attachment")
        attach.Parent = sword
    end

    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "SwingAlignPos"
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = attach
    alignPos.Position = sword.Position -- updated each frame
    alignPos.MaxForce = REST_MAX_FORCE
    alignPos.Responsiveness = REST_RESPONSIVENESS
    alignPos.RigidityEnabled = false
    alignPos.Parent = sword

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Name = "SwingAlignOri"
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = attach
    alignOri.CFrame = sword.CFrame -- updated each frame
    alignOri.MaxTorque = REST_MAX_TORQUE
    alignOri.Responsiveness = REST_RESPONSIVENESS
    alignOri.RigidityEnabled = false
    alignOri.Parent = sword

    return alignPos, alignOri
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = true
        -- Reset swing state to current mouse heading so there's no jump on LMB press
        swingState = { yaw = 0, pitch = 0 }
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = false
    end
end)

-- Per-character setup
local function onCharacter(character: Model)
    -- Give WeaponService time to spawn and weld the sword
    task.wait(0.5)

    local sword = getSword(character)
    if not sword then
        return
    end

    -- Remove the weld while swinging (constraints drive position instead)
    local weld = sword:FindFirstChildOfClass("WeldConstraint")

    local alignPos, alignOri = setupConstraints(sword)

    -- Give sword network ownership to this client
    if sword:IsA("BasePart") then
        sword:SetNetworkOwner(player)
    end

    RunService.RenderStepped:Connect(function()
        if not character:IsDescendantOf(game) then
            return
        end
        local root = getRootPart(character)
        if not root then
            return
        end

        local delta = UserInputService:GetMouseDelta()

        if lmbDown then
            -- Disable weld so physics constraints can move the sword freely
            if weld then
                weld.Enabled = false
            end

            -- Accumulate mouse delta into swing state
            swingState = SwingMath.accumulate(swingState, delta.X, delta.Y)

            -- Compute goal CFrame from swing state
            local goalCF = SwingMath.toGoalCFrame(swingState, root.CFrame)

            -- Drive constraints toward goal
            alignPos.Position = goalCF.Position
            alignPos.MaxForce = SWING_MAX_FORCE
            alignPos.Responsiveness = SWING_RESPONSIVENESS

            alignOri.CFrame = goalCF
            alignOri.MaxTorque = SWING_MAX_TORQUE
            alignOri.Responsiveness = SWING_RESPONSIVENESS
        else
            -- Re-enable weld so sword returns to hand
            if weld then
                weld.Enabled = true
            end

            -- Relax constraints (let weld do the positioning)
            alignPos.MaxForce = REST_MAX_FORCE
            alignPos.Responsiveness = REST_RESPONSIVENESS
            alignOri.MaxTorque = REST_MAX_TORQUE
            alignOri.Responsiveness = REST_RESPONSIVENESS

            -- Slowly reset swing state toward neutral
            swingState = {
                yaw = swingState.yaw * 0.85,
                pitch = swingState.pitch * 0.85,
            }
        end
    end)
end

local character = getCharacter()
onCharacter(character)
player.CharacterAdded:Connect(onCharacter)
