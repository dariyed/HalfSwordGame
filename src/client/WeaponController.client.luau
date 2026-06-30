--[[
    Mouse-driven weapon control.

    The hilt is pinned to the hand at all times via a rigid TwoAttachment
    AlignPosition. Only the blade direction changes — AlignOrientation swings
    the +Y axis of the sword to point where the mouse says.

    At rest (LMB up):   blade points down-forward along the arm.
    While swinging (LMB held): mouse delta rotates the tip; hilt stays in hand.

    Feel knobs at the top.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SwingMath = require(game.ReplicatedStorage.Shared.Weapon.SwingMath)
local WeaponConfig = require(game.ReplicatedStorage.Shared.Weapon.WeaponConfig)

-- === Feel knobs ===
local config = WeaponConfig.get("default")
local SWING_MAX_TORQUE = config.maxTorque
local SWING_RESPONSIVENESS = config.responsiveness
local REST_MAX_TORQUE = 20000
local REST_RESPONSIVENESS = 50

-- Sword geometry: Part.Size.Y = 2, so half-length = 1
local SWORD_HALF = 1

local player = Players.LocalPlayer

-- Start with blade pointing forward-down so there's no jump on first LMB
local swingState: SwingMath.SwingState = { yaw = 0, pitch = math.rad(-50) }
local lmbDown = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = true
        -- Do NOT reset swingState here — sword stays where it is, no jump
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lmbDown = false
    end
end)

local function onCharacter(character: Model)
    local sword = character:WaitForChild("Sword", 10) :: BasePart?
    if not sword then
        warn("WeaponController: Sword not found in character")
        return
    end

    local hand = character:WaitForChild("RightHand", 5) :: BasePart?
    if not hand then
        return
    end

    local handGrip = hand:WaitForChild("WeaponGrip", 5) :: Attachment?
    if not handGrip then
        return
    end

    -- Attachment at the hilt (top end of sword, -Y from centre when +Y = tip direction)
    local hiltAttach = Instance.new("Attachment")
    hiltAttach.Position = Vector3.new(0, -SWORD_HALF, 0)
    hiltAttach.Parent = sword

    -- Rigid position: hilt always at hand grip, zero lag
    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = hiltAttach
    alignPos.Attachment1 = handGrip
    alignPos.MaxForce = 40000
    alignPos.Responsiveness = 200
    alignPos.RigidityEnabled = true
    alignPos.Parent = sword

    -- Orientation: swings the blade direction
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = hiltAttach
    alignOri.MaxTorque = REST_MAX_TORQUE
    alignOri.Responsiveness = REST_RESPONSIVENESS
    alignOri.RigidityEnabled = false
    alignOri.Parent = sword

    -- Build orientation CFrame: make sword's +Y axis point along worldDir
    local function bladeCF(worldDir: Vector3): CFrame
        -- CFrame.lookAt makes -Z point at target; rotating pi/2 on X turns -Z into +Y
        return CFrame.lookAt(Vector3.zero, worldDir) * CFrame.Angles(math.pi / 2, 0, 0)
    end

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

            alignOri.CFrame = bladeCF(worldDir)
            alignOri.MaxTorque = SWING_MAX_TORQUE
            alignOri.Responsiveness = SWING_RESPONSIVENESS
        else
            -- Rest: blade follows the hand's downward direction
            local restDir = -hand.CFrame.YVector
            alignOri.CFrame = bladeCF(restDir)
            alignOri.MaxTorque = REST_MAX_TORQUE
            alignOri.Responsiveness = REST_RESPONSIVENESS

            -- Drift swingState back toward the rest angle so next swing starts naturally
            swingState = {
                yaw = swingState.yaw * 0.9,
                pitch = swingState.pitch * 0.9 + math.rad(-50) * 0.1,
            }
        end
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(onCharacter)
