--[[
    Pure functions: mouse input → weapon goal CFrame.
    No Roblox Instances — safe for headless Lune tests.

    How it works:
    The mouse position is projected onto a sphere of REACH_RADIUS centred on the
    character root. Moving the mouse rotates a point on that sphere, and the sword
    tries to point its tip toward that point via AlignOrientation.
]]

local REACH_RADIUS = 4 -- studs: how far the sword tip can reach from root
local MOUSE_SCALE = 0.003 -- radians per pixel of mouse delta (tuned for feel)

export type SwingState = {
    yaw: number, -- horizontal angle of the goal point around the character (radians)
    pitch: number, -- vertical angle (radians)
}

export type SwingDirection = "left" | "right" | "up" | "down" | "none"

-- Clamp pitch so the blade can't flip completely over
local MIN_PITCH = math.rad(-70)
local MAX_PITCH = math.rad(70)

local function clampPitch(p: number): number
    return math.clamp(p, MIN_PITCH, MAX_PITCH)
end

local function wrapYaw(y: number): number
    while y > math.pi do
        y -= math.pi * 2
    end
    while y < -math.pi do
        y += math.pi * 2
    end
    return y
end

-- Accumulate mouse delta into swing state
local function accumulate(state: SwingState, dx: number, dy: number, scale: number?): SwingState
    local s = scale or MOUSE_SCALE
    return {
        yaw = wrapYaw(state.yaw + dx * s),
        pitch = clampPitch(state.pitch - dy * s),
    }
end

-- Convert swing state → world-space goal CFrame for the sword hilt.
-- rootCFrame: the character's HumanoidRootPart CFrame.
-- The goal sits on the REACH_RADIUS sphere, offset from the root.
local function toGoalCFrame(state: SwingState, rootCFrame: CFrame): CFrame
    -- Direction the blade tip should point relative to root
    local localDir = Vector3.new(
        math.sin(state.yaw) * math.cos(state.pitch),
        math.sin(state.pitch),
        -math.cos(state.yaw) * math.cos(state.pitch)
    )

    local worldDir = rootCFrame:VectorToWorldSpace(localDir)
    local tipPos = rootCFrame.Position + worldDir * REACH_RADIUS

    -- Goal CFrame: positioned at the midpoint between root and tip,
    -- oriented so the stick's +Y axis points toward the tip.
    local midPos = rootCFrame.Position + worldDir * (REACH_RADIUS * 0.5)
    local goalCFrame = CFrame.lookAt(midPos, midPos + worldDir) * CFrame.Angles(math.pi / 2, 0, 0) -- rotate so +Y is the blade axis

    return goalCFrame, tipPos
end

-- Classify the dominant direction of a mouse delta
local function classifyDelta(dx: number, dy: number): SwingDirection
    local ax = math.abs(dx)
    local ay = math.abs(dy)
    if ax < 2 and ay < 2 then
        return "none"
    end
    if ax >= ay then
        return dx > 0 and "right" or "left"
    else
        return dy > 0 and "down" or "up"
    end
end

-- Returns true if a pre-computed distance is within REACH_RADIUS
local function isWithinReach(distance: number): boolean
    return distance <= REACH_RADIUS + 0.01
end

return {
    accumulate = accumulate,
    toGoalCFrame = toGoalCFrame,
    classifyDelta = classifyDelta,
    isWithinReach = isWithinReach,
    REACH_RADIUS = REACH_RADIUS,
    MOUSE_SCALE = MOUSE_SCALE,
    MIN_PITCH = MIN_PITCH,
    MAX_PITCH = MAX_PITCH,
}
