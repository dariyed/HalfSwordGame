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
        local result =
            MovementIntent.compute({ w = false, a = false, s = false, d = true, shift = false })
        assert(approxEq(result.direction.x, 1), "expected x=1")
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

    -- Directional speed multipliers

    ["W → full speed (1.0)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = false })
        assert(approxEq(result.speedMultiplier, 1.0), "forward must be 1.0")
    end,

    ["S → backward speed (< 1.0)"] = function()
        local result =
            MovementIntent.compute({ w = false, a = false, s = true, d = false, shift = false })
        assert(result.speedMultiplier < 1.0, "backward must be slower than forward")
        assert(
            approxEq(result.speedMultiplier, MovementIntent.BACKWARD_SPEED_MULTIPLIER),
            "expected BACKWARD_SPEED_MULTIPLIER"
        )
    end,

    ["A only → strafe speed (< 1.0)"] = function()
        local result =
            MovementIntent.compute({ w = false, a = true, s = false, d = false, shift = false })
        assert(result.speedMultiplier < 1.0, "strafe must be slower than forward")
        assert(
            approxEq(result.speedMultiplier, MovementIntent.STRAFE_SPEED_MULTIPLIER),
            "expected STRAFE_SPEED_MULTIPLIER"
        )
    end,

    ["D only → strafe speed (< 1.0)"] = function()
        local result =
            MovementIntent.compute({ w = false, a = false, s = false, d = true, shift = false })
        assert(
            approxEq(result.speedMultiplier, MovementIntent.STRAFE_SPEED_MULTIPLIER),
            "expected STRAFE_SPEED_MULTIPLIER"
        )
    end,

    ["forward faster than strafe"] = function()
        local fwd =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = false })
        local str =
            MovementIntent.compute({ w = false, a = true, s = false, d = false, shift = false })
        assert(fwd.speedMultiplier > str.speedMultiplier, "forward must be faster than strafe")
    end,

    ["strafe faster than backward"] = function()
        local str =
            MovementIntent.compute({ w = false, a = true, s = false, d = false, shift = false })
        local bwd =
            MovementIntent.compute({ w = false, a = false, s = true, d = false, shift = false })
        assert(str.speedMultiplier > bwd.speedMultiplier, "strafe must be faster than backward")
    end,

    -- Sprint

    ["shift+W → sprint speed (> 1.0)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = false, s = false, d = false, shift = true })
        assert(result.speedMultiplier > 1.0, "sprint must be faster than walk")
        assert(
            approxEq(result.speedMultiplier, MovementIntent.SPRINT_SPEED_MULTIPLIER),
            "expected SPRINT_SPEED_MULTIPLIER"
        )
    end,

    ["shift+W+A → sprint (W held with strafe)"] = function()
        local result =
            MovementIntent.compute({ w = true, a = true, s = false, d = false, shift = true })
        assert(result.speedMultiplier > 1.0, "shift+W+A should sprint")
    end,

    ["shift without W → no sprint"] = function()
        local result =
            MovementIntent.compute({ w = false, a = true, s = false, d = false, shift = true })
        assert(
            approxEq(result.speedMultiplier, MovementIntent.STRAFE_SPEED_MULTIPLIER),
            "strafe speed when shift+A"
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
