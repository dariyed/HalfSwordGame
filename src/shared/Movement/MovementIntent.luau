--[[
    Pure function: raw key input → movement intent.
    No Roblox Instances — safe to test headlessly under Lune.
]]

local SPRINT_SPEED_MULTIPLIER = 1.6

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

    local sprinting = input.shift and input.w

    return {
        direction = { x = x, z = z },
        speedMultiplier = sprinting and SPRINT_SPEED_MULTIPLIER or 1.0,
        isSprinting = sprinting,
    }
end

return {
    compute = compute,
    SPRINT_SPEED_MULTIPLIER = SPRINT_SPEED_MULTIPLIER,
}
