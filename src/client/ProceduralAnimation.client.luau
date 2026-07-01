--[[
    Procedural body animation — Half Sword-style movement feel.

    Applied in RenderStepped after the Animator updates Motor6D joints,
    so our transform sticks for that render frame without fighting the
    animation system.

    Modifies the Waist joint (LowerTorso → UpperTorso):
      • Constant forward lean  = combat-crouch posture, always on
      • Speed-based extra lean = leans further into movement
      • Side lean              = tilts into strafe direction

    === Feel knobs ===
    IDLE_LEAN      degrees of forward tilt even when standing still
    MOVE_LEAN      additional degrees at full WalkSpeed
    SIDE_LEAN      max degrees of sideways tilt when strafing
    LEAN_SMOOTH    lerp factor: lower = lazier lean, higher = snappier
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IDLE_LEAN  = 8    -- degrees forward at rest (combat crouch)
local MOVE_LEAN  = 12   -- additional degrees at full speed
local SIDE_LEAN  = 6    -- max sideways tilt when strafing
local LEAN_SMOOTH = 0.12 -- lerp per frame

local player = Players.LocalPlayer

local function onCharacter(character: Model)
    local humanoid   = character:WaitForChild("Humanoid")   :: Humanoid
    local rootPart   = character:WaitForChild("HumanoidRootPart") :: BasePart
    local lowerTorso = character:WaitForChild("LowerTorso") :: BasePart

    local waist = lowerTorso:WaitForChild("Waist") :: Motor6D

    -- The Animator writes Motor6D.Transform every frame and overrides it.
    -- C0 is the joint's rest position — the Animator never touches it,
    -- so modifying C0 persists across animation updates reliably.
    local baseC0 = waist.C0

    local currentLeanX = 0
    local currentLeanZ = 0

    RunService:BindToRenderStep("ProceduralAnim", Enum.RenderPriority.Last.Value, function()
        if not character:IsDescendantOf(game) then
            RunService:UnbindFromRenderStep("ProceduralAnim")
            return
        end

        local vel = rootPart.AssemblyLinearVelocity
        local flatVel = Vector3.new(vel.X, 0, vel.Z)
        local speed = flatVel.Magnitude
        local t = math.clamp(speed / math.max(humanoid.WalkSpeed, 1), 0, 1)

        local targetLeanX = IDLE_LEAN + t * MOVE_LEAN

        local sideT = 0
        if speed > 0.5 then
            sideT = flatVel.Unit:Dot(rootPart.CFrame.RightVector)
        end
        local targetLeanZ = -sideT * SIDE_LEAN * t

        currentLeanX = currentLeanX + (targetLeanX - currentLeanX) * LEAN_SMOOTH
        currentLeanZ = currentLeanZ + (targetLeanZ - currentLeanZ) * LEAN_SMOOTH

        waist.C0 = baseC0 * CFrame.Angles(math.rad(-currentLeanX), 0, math.rad(currentLeanZ))
    end)
end

local character = player.Character or player.CharacterAdded:Wait()
onCharacter(character)
player.CharacterAdded:Connect(function(newCharacter)
    RunService:UnbindFromRenderStep("ProceduralAnim")
    onCharacter(newCharacter)
end)
