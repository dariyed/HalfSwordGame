local CameraMath = require("../../src/shared/Camera/CameraMath")

local EPSILON = 1e-6

local function approxEq(a: number, b: number): boolean
    return math.abs(a - b) < EPSILON
end

return {
    -- clampPitch

    ["clampPitch: value within range is unchanged"] = function()
        local p = math.rad(-30)
        assert(approxEq(CameraMath.clampPitch(p), p), "expected unchanged pitch")
    end,

    ["clampPitch: above MAX_PITCH is clamped to MAX_PITCH"] = function()
        local over = CameraMath.MAX_PITCH + math.rad(10)
        assert(approxEq(CameraMath.clampPitch(over), CameraMath.MAX_PITCH), "expected MAX_PITCH")
    end,

    ["clampPitch: below MIN_PITCH is clamped to MIN_PITCH"] = function()
        local under = CameraMath.MIN_PITCH - math.rad(10)
        assert(approxEq(CameraMath.clampPitch(under), CameraMath.MIN_PITCH), "expected MIN_PITCH")
    end,

    ["clampPitch: MIN_PITCH < MAX_PITCH (no somersault)"] = function()
        assert(CameraMath.MIN_PITCH < CameraMath.MAX_PITCH, "MIN must be less than MAX")
    end,

    -- wrapYaw

    ["wrapYaw: value in range unchanged"] = function()
        local y = math.rad(45)
        assert(approxEq(CameraMath.wrapYaw(y), y), "expected unchanged yaw")
    end,

    ["wrapYaw: value > π wraps to [-π, π]"] = function()
        local y = CameraMath.wrapYaw(math.pi + 0.1)
        assert(y >= -math.pi and y <= math.pi, "expected yaw in [-π, π], got " .. y)
    end,

    ["wrapYaw: value < -π wraps to [-π, π]"] = function()
        local y = CameraMath.wrapYaw(-math.pi - 0.1)
        assert(y >= -math.pi and y <= math.pi, "expected yaw in [-π, π], got " .. y)
    end,

    -- accumulate

    ["accumulate: zero delta leaves angles unchanged"] = function()
        local y0, p0 = math.rad(30), math.rad(-20)
        local y1, p1 = CameraMath.accumulate(y0, p0, 0, 0, 0.005)
        assert(approxEq(y1, y0), "yaw should not change")
        assert(approxEq(p1, p0), "pitch should not change")
    end,

    ["accumulate: positive dx rotates yaw left (decreases yaw)"] = function()
        local y0, p0 = 0, 0
        local y1, _ = CameraMath.accumulate(y0, p0, 10, 0, 0.005)
        assert(y1 < y0, "positive dx should decrease yaw (look left)")
    end,

    ["accumulate: positive dy rotates pitch down (decreases pitch)"] = function()
        local y0, p0 = 0, 0
        local _, p1 = CameraMath.accumulate(y0, p0, 0, 10, 0.005)
        assert(p1 < p0, "positive dy should decrease pitch (look down)")
    end,

    ["accumulate: pitch is clamped when delta would exceed MAX_PITCH"] = function()
        local _, p1 = CameraMath.accumulate(0, CameraMath.MAX_PITCH - math.rad(1), 0, -1000, 0.005)
        assert(approxEq(p1, CameraMath.MAX_PITCH), "pitch must clamp at MAX_PITCH")
    end,

    ["accumulate: pitch is clamped when delta would exceed MIN_PITCH"] = function()
        local _, p1 = CameraMath.accumulate(0, CameraMath.MIN_PITCH + math.rad(1), 0, 1000, 0.005)
        assert(approxEq(p1, CameraMath.MIN_PITCH), "pitch must clamp at MIN_PITCH")
    end,
}
