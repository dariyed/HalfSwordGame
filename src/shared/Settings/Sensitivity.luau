--[[
    Pure sensitivity helpers shared by camera and weapon control.
    Low default is intentional — Half Sword's weighty feel needs a slow, deliberate mouse.
]]

local MIN = 0.001
local MAX = 1.0
local DEFAULT = 0.003

local function clamp(sensitivity: number): number
    return math.clamp(sensitivity, MIN, MAX)
end

local function scale(delta: number, sensitivity: number): number
    return delta * sensitivity
end

return {
    MIN = MIN,
    MAX = MAX,
    DEFAULT = DEFAULT,
    clamp = clamp,
    scale = scale,
}
