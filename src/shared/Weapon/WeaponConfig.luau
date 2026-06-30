--[[
    Pure weapon configuration — no Roblox Instances.
    Defines constraint parameters for how the sword feels when held and swung.
]]

export type Preset = {
    maxForce: number, -- AlignPosition max force (studs/s²)
    maxTorque: number, -- AlignOrientation max torque
    responsiveness: number, -- AlignPosition/Orientation responsiveness
    mass: number, -- sword part mass (heavier = more lag on swings)
}

local PRESETS: { [string]: Preset } = {
    -- Balanced one-handed sword feel
    default = {
        maxForce = 8000,
        maxTorque = 4000,
        responsiveness = 18,
        mass = 5,
    },
    -- Heavier, slower great-sword feel
    heavy = {
        maxForce = 6000,
        maxTorque = 2500,
        responsiveness = 10,
        mass = 12,
    },
    -- Light, snappy dagger feel
    light = {
        maxForce = 12000,
        maxTorque = 6000,
        responsiveness = 30,
        mass = 2,
    },
}

local MIN_FORCE = 100
local MAX_FORCE = 50000
local MIN_TORQUE = 100
local MAX_TORQUE = 50000
local MIN_RESPONSIVENESS = 1
local MAX_RESPONSIVENESS = 200
local MIN_MASS = 0.1
local MAX_MASS = 100

local function isValid(preset: Preset): boolean
    return preset.maxForce >= MIN_FORCE
        and preset.maxForce <= MAX_FORCE
        and preset.maxTorque >= MIN_TORQUE
        and preset.maxTorque <= MAX_TORQUE
        and preset.responsiveness >= MIN_RESPONSIVENESS
        and preset.responsiveness <= MAX_RESPONSIVENESS
        and preset.mass >= MIN_MASS
        and preset.mass <= MAX_MASS
end

local function get(name: string): Preset
    local preset = PRESETS[name]
    assert(preset, "WeaponConfig: unknown preset '" .. name .. "'")
    return preset
end

return {
    get = get,
    isValid = isValid,
    PRESETS = PRESETS,
    MIN_FORCE = MIN_FORCE,
    MAX_FORCE = MAX_FORCE,
    MIN_TORQUE = MIN_TORQUE,
    MAX_TORQUE = MAX_TORQUE,
    MIN_RESPONSIVENESS = MIN_RESPONSIVENESS,
    MAX_RESPONSIVENESS = MAX_RESPONSIVENESS,
    MIN_MASS = MIN_MASS,
    MAX_MASS = MAX_MASS,
}
