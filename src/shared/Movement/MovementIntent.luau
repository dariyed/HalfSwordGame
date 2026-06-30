--[[
    Pure function: raw key input → movement intent.
    No Roblox Instances — safe to test headlessly under Lune.
]]

local STANCE_SPEED_MULTIPLIER = 0.45

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
    inStance: boolean,
}

local function compute(input: Input): Intent
    local x = (input.d and 1 or 0) - (input.a and 1 or 0)
    local z = (input.s and 1 or 0) - (input.w and 1 or 0)

    local len = math.sqrt(x * x + z * z)
    if len > 0 then
        x = x / len
        z = z / len
    end

    return {
        direction = { x = x, z = z },
        speedMultiplier = input.shift and STANCE_SPEED_MULTIPLIER or 1.0,
        inStance = input.shift,
    }
end

return {
    compute = compute,
    STANCE_SPEED_MULTIPLIER = STANCE_SPEED_MULTIPLIER,
}
