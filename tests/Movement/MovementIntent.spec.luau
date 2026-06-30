local MovementIntent = require("../../src/shared/Movement/MovementIntent")

local EPSILON = 1e-6

local function approxEq(a: number, b: number): boolean
    return math.abs(a - b) < EPSILON
end

local function vecLength(v: { x: number, z: number }): number
    return math.sqrt(v.x * v.x + v.z * v.z)
end

return {
    -- Direction mapping

    ["no keys held → zero direction"] = function()
        local result =
            MovementIntent.compute({ w = false, a = false, s = false, d = false, shift = false })
        assert(approxEq(result.direction.x, 0), "expected x=0")
        assert(approxEq(result.direction.z, 0), "expected z=0")
    end,

    ["W → forward (z = -1)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = false })
        assert(approxEq(result.direction.z, -1), "expected z=-1, got " .. result.direction.z)
        assert(approxEq(result.direction.x, 0), "expected x=0")
    end,

    ["S → backward (z = +1)"] = function()
        local result =
            MovementIntent.compute({ w = false, a = false, s = true, d = false, shift = false })
        assert(approxEq(result.direction.z, 1), "expected z=1")
    end,

    ["A → left (x = -1)"] = function()
        local result =
            MovementIntent.compute({ w = false, a = true, s = false, d = false, shift = false })
        assert(approxEq(result.direction.x, -1), "expected x=-1")
    end,

    ["D → right (x = +1)"] = function()
        -- A+D cancel to zero; alone D gives +1
        local result2 =
            MovementIntent.compute({ w = false, a = false, s = false, d = true, shift = false })
        assert(approxEq(result2.direction.x, 1), "expected x=1")
    end,

    ["W+D → normalised diagonal (length = 1)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = false, d = true, shift = false })
        local len = vecLength(result.direction)
        assert(approxEq(len, 1), "diagonal must be normalised, got length " .. len)
    end,

    ["W+S cancel → zero direction"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = true, d = false, shift = false })
        assert(
            approxEq(result.direction.x, 0) and approxEq(result.direction.z, 0),
            "opposing keys must cancel"
        )
    end,

    ["A+D cancel → zero direction"] = function()
        local result =
            MovementIntent.compute({ w = false, a = true, s = false, d = true, shift = false })
        assert(
            approxEq(result.direction.x, 0) and approxEq(result.direction.z, 0),
            "opposing keys must cancel"
        )
    end,

    -- Speed multiplier

    ["no shift → full speed multiplier (1.0)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = false })
        assert(
            approxEq(result.speedMultiplier, 1.0),
            "expected 1.0, got " .. result.speedMultiplier
        )
    end,

    ["shift+W → sprint speed multiplier (> 1.0)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = true })
        assert(result.speedMultiplier > 1.0, "sprint speed must be greater than 1.0")
        assert(
            approxEq(result.speedMultiplier, MovementIntent.SPRINT_SPEED_MULTIPLIER),
            "expected SPRINT_SPEED_MULTIPLIER"
        )
    end,

    ["shift+W+A → sprint (W held with sideways)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = true, s = false, d = false, shift = true })
        assert(result.speedMultiplier > 1.0, "shift+W+A should sprint")
    end,

    ["shift without W → no sprint (normal speed)"] = function()
        local result =
            MovementIntent.compute({ w = false, a = true, s = false, d = false, shift = true })
        assert(approxEq(result.speedMultiplier, 1.0), "shift alone without W must not sprint")
    end,

    ["diagonal speed equals straight speed (no faster-diagonal bug)"] = function()
        local straight =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = false })
        local diagonal =
            MovementIntent.compute({ w = true, a = false, s = false, d = true, shift = false })
        assert(
            approxEq(straight.speedMultiplier, diagonal.speedMultiplier),
            "diagonal must not be faster than straight"
        )
    end,

    -- Sprint flag

    ["shift+W → isSprinting = true"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = true })
        assert(result.isSprinting == true, "expected isSprinting=true")
    end,

    ["shift without W → isSprinting = false"] = function()
        local result =
            MovementIntent.compute({ w = false, a = true, s = false, d = false, shift = true })
        assert(result.isSprinting == false, "expected isSprinting=false when W not held")
    end,

    ["shift not held → isSprinting = false"] = function()
        local result =
            MovementIntent.compute({ w = false, a = false, s = false, d = false, shift = false })
        assert(result.isSprinting == false, "expected isSprinting=false")
    end,
}
