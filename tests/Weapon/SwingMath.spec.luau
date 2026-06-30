local SwingMath = require("../../src/shared/Weapon/SwingMath")

local EPSILON = 0.01

local function approxEq(a: number, b: number): boolean
    return math.abs(a - b) < EPSILON
end

local neutral: SwingMath.SwingState = { yaw = 0, pitch = 0 }

return {
    -- accumulate

    ["accumulate: zero delta leaves state unchanged"] = function()
        local s = SwingMath.accumulate(neutral, 0, 0)
        assert(approxEq(s.yaw, 0) and approxEq(s.pitch, 0), "zero delta must not change state")
    end,

    ["accumulate: positive dx increases yaw"] = function()
        local s = SwingMath.accumulate(neutral, 100, 0)
        assert(s.yaw > 0, "positive dx should increase yaw")
    end,

    ["accumulate: negative dx decreases yaw"] = function()
        local s = SwingMath.accumulate(neutral, -100, 0)
        assert(s.yaw < 0, "negative dx should decrease yaw")
    end,

    ["accumulate: positive dy decreases pitch (mouse down = tip down)"] = function()
        local s = SwingMath.accumulate(neutral, 0, 100)
        assert(s.pitch < 0, "positive dy should decrease pitch")
    end,

    ["accumulate: pitch clamps at MAX_PITCH"] = function()
        local s = SwingMath.accumulate(neutral, 0, -100000)
        assert(approxEq(s.pitch, SwingMath.MAX_PITCH), "pitch must clamp at MAX_PITCH")
    end,

    ["accumulate: pitch clamps at MIN_PITCH"] = function()
        local s = SwingMath.accumulate(neutral, 0, 100000)
        assert(approxEq(s.pitch, SwingMath.MIN_PITCH), "pitch must clamp at MIN_PITCH")
    end,

    ["accumulate: yaw wraps past π"] = function()
        local s = SwingMath.accumulate(neutral, 100000, 0)
        assert(s.yaw >= -math.pi and s.yaw <= math.pi, "yaw must stay in [-π, π]")
    end,

    -- classifyDelta

    ["classifyDelta: large rightward dx → right"] = function()
        assert(SwingMath.classifyDelta(50, 0) == "right", "expected right")
    end,

    ["classifyDelta: large leftward dx → left"] = function()
        assert(SwingMath.classifyDelta(-50, 0) == "left", "expected left")
    end,

    ["classifyDelta: large upward dy → up"] = function()
        assert(SwingMath.classifyDelta(0, -50) == "up", "expected up")
    end,

    ["classifyDelta: large downward dy → down"] = function()
        assert(SwingMath.classifyDelta(0, 50) == "down", "expected down")
    end,

    ["classifyDelta: tiny delta → none"] = function()
        assert(SwingMath.classifyDelta(1, 1) == "none", "expected none for tiny delta")
    end,

    ["classifyDelta: dominant axis wins"] = function()
        assert(SwingMath.classifyDelta(10, 3) == "right", "horizontal must win when larger")
        assert(SwingMath.classifyDelta(3, 10) == "down", "vertical must win when larger")
    end,

    -- isWithinReach

    ["isWithinReach: distance on radius is within reach"] = function()
        assert(
            SwingMath.isWithinReach(SwingMath.REACH_RADIUS),
            "distance == REACH_RADIUS must be within reach"
        )
    end,

    ["isWithinReach: distance past radius is outside reach"] = function()
        assert(
            not SwingMath.isWithinReach(SwingMath.REACH_RADIUS + 10),
            "far distance must be outside reach"
        )
    end,
}
