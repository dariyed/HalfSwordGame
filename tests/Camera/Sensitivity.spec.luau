local Sensitivity = require("../../src/shared/Settings/Sensitivity")

return {
    ["scale: delta multiplied by sensitivity"] = function()
        local result = Sensitivity.scale(10, 0.5)
        assert(result == 5, "expected 5, got " .. result)
    end,

    ["scale: zero delta gives zero"] = function()
        assert(Sensitivity.scale(0, 0.8) == 0, "expected 0")
    end,

    ["clamp: value within range is unchanged"] = function()
        local s = (Sensitivity.MIN + Sensitivity.MAX) / 2
        assert(Sensitivity.clamp(s) == s, "expected unchanged")
    end,

    ["clamp: below MIN is clamped to MIN"] = function()
        assert(Sensitivity.clamp(Sensitivity.MIN - 0.001) == Sensitivity.MIN, "expected MIN")
    end,

    ["clamp: above MAX is clamped to MAX"] = function()
        assert(Sensitivity.clamp(Sensitivity.MAX + 0.1) == Sensitivity.MAX, "expected MAX")
    end,

    ["scale is monotonic: higher sensitivity → larger output"] = function()
        local lo = Sensitivity.scale(10, 0.1)
        local hi = Sensitivity.scale(10, 0.9)
        assert(hi > lo, "higher sensitivity must produce larger scaled delta")
    end,

    ["DEFAULT is within [MIN, MAX]"] = function()
        assert(
            Sensitivity.DEFAULT >= Sensitivity.MIN and Sensitivity.DEFAULT <= Sensitivity.MAX,
            "DEFAULT must be within valid range"
        )
    end,
}
