--[[
    Pure function: raw key input → movement intent.
    No Roblox Instances — safe to test headlessly under Lune.
]]

local SPRINT_SPEED_MULTIPLIER = 1.1 -- Shift+W: slightly faster than walking
local STRAFE_SPEED_MULTIPLIER = 0.7 -- A/D only: slower sideways movement
local BACKWARD_SPEED_MULTIPLIER = 0.6 -- S only: slowest, backing away

export type Input = {
    w: boolean,
    a: boolean,
    s: boolean,
    d: boolean,
    shift: boolean,
}

export type Intent = {
    direction: { x: number, z: number },
    speedMultiplier: number,
    isSprinting: boolean,
}

local function compute(input: Input): Intent
    local x = (input.d and 1 or 0) - (input.a and 1 or 0)
    local z = (input.s and 1 or 0) - (input.w and 1 or 0)

    local len = math.sqrt(x * x + z * z)
    if len > 0 then
        x = x / len
        z = z / len
    end

    local sprinting = input.shift and input.w and not input.s

    local speedMultiplier
    if sprinting then
        speedMultiplier = SPRINT_SPEED_MULTIPLIER
    elseif input.w and not input.s then
        speedMultiplier = 1.0 -- forward (with or without strafe)
    elseif input.s and not input.w then
        speedMultiplier = BACKWARD_SPEED_MULTIPLIER
    elseif (input.a or input.d) and not input.w and not input.s then
        speedMultiplier = STRAFE_SPEED_MULTIPLIER
    else
        speedMultiplier = 1.0 -- standing or opposing keys cancel
    end

    return {
        direction = { x = x, z = z },
        speedMultiplier = speedMultiplier,
        isSprinting = sprinting,
    }
end

return {
    compute = compute,
    SPRINT_SPEED_MULTIPLIER = SPRINT_SPEED_MULTIPLIER,
    STRAFE_SPEED_MULTIPLIER = STRAFE_SPEED_MULTIPLIER,
    BACKWARD_SPEED_MULTIPLIER = BACKWARD_SPEED_MULTIPLIER,
}
