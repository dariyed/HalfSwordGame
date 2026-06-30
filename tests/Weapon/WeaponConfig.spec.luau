local WeaponConfig = require("../../src/shared/Weapon/WeaponConfig")

return {
    ["default preset is valid"] = function()
        local p = WeaponConfig.get("default")
        assert(WeaponConfig.isValid(p), "default preset must be valid")
    end,

    ["heavy preset is valid"] = function()
        local p = WeaponConfig.get("heavy")
        assert(WeaponConfig.isValid(p), "heavy preset must be valid")
    end,

    ["light preset is valid"] = function()
        local p = WeaponConfig.get("light")
        assert(WeaponConfig.isValid(p), "light preset must be valid")
    end,

    ["all presets pass isValid"] = function()
        for name, preset in WeaponConfig.PRESETS do
            assert(WeaponConfig.isValid(preset), "preset '" .. name .. "' must be valid")
        end
    end,

    ["heavy is slower than default (lower responsiveness)"] = function()
        local heavy = WeaponConfig.get("heavy")
        local default = WeaponConfig.get("default")
        assert(heavy.responsiveness < default.responsiveness, "heavy must be less responsive")
    end,

    ["light is faster than default (higher responsiveness)"] = function()
        local light = WeaponConfig.get("light")
        local default = WeaponConfig.get("default")
        assert(light.responsiveness > default.responsiveness, "light must be more responsive")
    end,

    ["heavy weighs more than default"] = function()
        local heavy = WeaponConfig.get("heavy")
        local default = WeaponConfig.get("default")
        assert(heavy.mass > default.mass, "heavy must have more mass")
    end,

    ["get: unknown preset raises error"] = function()
        local ok = pcall(function()
            WeaponConfig.get("nonexistent")
        end)
        assert(not ok, "get with unknown name must error")
    end,

    ["isValid: rejects zero maxForce"] = function()
        local bad = { maxForce = 0, maxTorque = 4000, responsiveness = 18, mass = 5 }
        assert(not WeaponConfig.isValid(bad), "zero maxForce must be invalid")
    end,

    ["isValid: rejects zero mass"] = function()
        local bad = { maxForce = 8000, maxTorque = 4000, responsiveness = 18, mass = 0 }
        assert(not WeaponConfig.isValid(bad), "zero mass must be invalid")
    end,
}
