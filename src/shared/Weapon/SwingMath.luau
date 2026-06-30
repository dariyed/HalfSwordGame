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
    yaw: number, -- horizontal angle around the character (radians)
    pitch: number, -- vertical angle (radians)
}

export type SwingDirection = "left" | "right" | "up" | "down" | "none"

-- Arm reach limits — no 360 spin; matches a realistic sword arc.
-- MIN_YAW is intentionally narrower than MAX_YAW: the right arm cannot reach
-- far past the body centerline without the IK solver flipping the elbow.
local MIN_YAW = math.rad(-70)
local MAX_YAW = math.rad(110)
local MIN_PITCH = math.rad(-70)
local MAX_PITCH = math.rad(70)

-- Accumulate mouse delta into swing state
local function accumulate(state: SwingState, dx: number, dy: number, scale: number?): SwingState
    local s = scale or MOUSE_SCALE
    return {
        yaw = math.clamp(state.yaw + dx * s, MIN_YAW, MAX_YAW),
        pitch = math.clamp(state.pitch - dy * s, MIN_PITCH, MAX_PITCH),
    }
end

-- Returns the blade direction as local-space components (no Roblox types).
-- Caller converts to world space via rootCFrame:VectorToWorldSpace().
local function localBladeDir(state: SwingState): (number, number, number)
    local cy = math.cos(state.pitch)
    return math.sin(state.yaw) * cy, math.sin(state.pitch), -math.cos(state.yaw) * cy
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
    localBladeDir = localBladeDir,
    classifyDelta = classifyDelta,
    isWithinReach = isWithinReach,
    REACH_RADIUS = REACH_RADIUS,
    MOUSE_SCALE = MOUSE_SCALE,
    MIN_YAW = MIN_YAW,
    MAX_YAW = MAX_YAW,
    MIN_PITCH = MIN_PITCH,
    MAX_PITCH = MAX_PITCH,
}
