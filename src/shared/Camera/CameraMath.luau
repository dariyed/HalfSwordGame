--[[
    Pure camera math: yaw/pitch accumulation, clamping, and CFrame computation.
    The toCFrame function is Roblox-only and not covered by headless tests.
]]

local MIN_PITCH = math.rad(-70)
local MAX_PITCH = math.rad(20)

local function clampPitch(pitch: number): number
    return math.clamp(pitch, MIN_PITCH, MAX_PITCH)
end

local function wrapYaw(yaw: number): number
    while yaw > math.pi do
        yaw -= 2 * math.pi
    end
    while yaw < -math.pi do
        yaw += 2 * math.pi
    end
    return yaw
end

-- Accumulates mouse delta into yaw/pitch and applies clamping.
-- dx/dy are raw pixel deltas; sensitivity scales them to radians.
local function accumulate(
    yaw: number,
    pitch: number,
    dx: number,
    dy: number,
    sensitivity: number
): (number, number)
    yaw = wrapYaw(yaw - dx * sensitivity)
    pitch = clampPitch(pitch - dy * sensitivity)
    return yaw, pitch
end

-- Roblox-only: not called in headless tests.
local function toCFrame(target: Vector3, yaw: number, pitch: number, distance: number): CFrame
    local cf = CFrame.new(target) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
    return cf * CFrame.new(0, 0, distance)
end

return {
    MIN_PITCH = MIN_PITCH,
    MAX_PITCH = MAX_PITCH,
    clampPitch = clampPitch,
    wrapYaw = wrapYaw,
    accumulate = accumulate,
    toCFrame = toCFrame,
}
