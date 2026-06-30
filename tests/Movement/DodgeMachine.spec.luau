local DodgeMachine = require("../../src/shared/Movement/DodgeMachine")

-- helpers: side tick (no forward/backward), axis tick (no left/right)
local function side(machine, left, right, dt, blocked)
    return machine:update(left, right, false, false, dt, blocked)
end

local function axis(machine, forward, backward, dt)
    return machine:update(false, false, forward, backward, dt, false)
end

return {
    -- ── Side dodge (A↔D) ──────────────────────────────────────────────

    ["starts not dodging"] = function()
        local m = DodgeMachine.new()
        assert(m:isDodging() == false, "should not be dodging at start")
    end,

    ["A→D quick switch triggers side dodge"] = function()
        local m = DodgeMachine.new()
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        local dodging = side(m, false, true, 0.01)
        assert(dodging == true, "A→D quick switch should trigger dodge")
    end,

    ["D→A quick switch triggers side dodge"] = function()
        local m = DodgeMachine.new()
        side(m, false, true, 0.01)
        side(m, false, false, 0.01)
        local dodging = side(m, true, false, 0.01)
        assert(dodging == true, "D→A quick switch should trigger dodge")
    end,

    ["slow A→D does not trigger side dodge"] = function()
        local m = DodgeMachine.new()
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        side(m, false, false, DodgeMachine.SWITCH_WINDOW + 0.05)
        local dodging = side(m, false, true, 0.01)
        assert(dodging == false, "slow switch must not dodge")
    end,

    ["side dodge expires after DODGE_DURATION"] = function()
        local m = DodgeMachine.new()
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        side(m, false, true, 0.01)
        side(m, false, true, DodgeMachine.DODGE_DURATION + 0.01)
        assert(m:isDodging() == false, "side dodge should expire")
    end,

    ["side dodge blocked while forward held"] = function()
        local m = DodgeMachine.new()
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        local dodging = side(m, false, true, 0.01, true) -- blocked = true (W held)
        assert(dodging == false, "side dodge must not trigger while W held")
    end,

    ["side cooldown prevents immediate re-dodge"] = function()
        local m = DodgeMachine.new()
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        side(m, false, true, 0.01)
        side(m, false, true, DodgeMachine.DODGE_DURATION + 0.05)
        side(m, false, false, 0.05)
        local dodging = side(m, true, false, 0.01)
        assert(dodging == false, "cooldown should block re-dodge")
    end,

    ["can side-dodge again after cooldown"] = function()
        local m = DodgeMachine.new()
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        side(m, false, true, 0.01)
        side(m, false, true, DodgeMachine.DODGE_COOLDOWN + 0.1)
        side(m, false, false, 0.05)
        local dodging = side(m, true, false, 0.01)
        assert(dodging == true, "should dodge again after cooldown")
    end,

    -- ── Axis dodge (W↔S) ──────────────────────────────────────────────

    ["W→S quick switch triggers axis dodge"] = function()
        local m = DodgeMachine.new()
        axis(m, true, false, 0.01)
        axis(m, false, false, 0.01)
        local dodging = axis(m, false, true, 0.01)
        assert(dodging == true, "W→S should trigger axis dodge")
    end,

    ["S→W quick switch triggers axis dodge"] = function()
        local m = DodgeMachine.new()
        axis(m, false, true, 0.01)
        axis(m, false, false, 0.01)
        local dodging = axis(m, true, false, 0.01)
        assert(dodging == true, "S→W should trigger axis dodge")
    end,

    ["slow W→S does not trigger axis dodge"] = function()
        local m = DodgeMachine.new()
        axis(m, true, false, 0.01)
        axis(m, false, false, 0.01)
        axis(m, false, false, DodgeMachine.SWITCH_WINDOW + 0.05)
        local dodging = axis(m, false, true, 0.01)
        assert(dodging == false, "slow W→S must not dodge")
    end,

    ["axis dodge lasts longer than side dodge"] = function()
        assert(
            DodgeMachine.AXIS_DODGE_DURATION > DodgeMachine.DODGE_DURATION,
            "axis dodge must be longer than side dodge"
        )
    end,

    ["axis cooldown is separate from side cooldown"] = function()
        local m = DodgeMachine.new()
        -- trigger side dodge
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        side(m, false, true, 0.01)
        -- axis dodge should still be available
        axis(m, true, false, 0.01)
        axis(m, false, false, 0.01)
        local dodging = axis(m, false, true, 0.01)
        assert(dodging == true, "axis cooldown must be independent of side cooldown")
    end,

    ["activeDodgeMultiplier returns 1 when not dodging"] = function()
        local m = DodgeMachine.new()
        assert(m:activeDodgeMultiplier() == 1, "expected 1 when idle")
    end,

    ["activeDodgeMultiplier returns DODGE_MULTIPLIER during side dodge"] = function()
        local m = DodgeMachine.new()
        side(m, true, false, 0.01)
        side(m, false, false, 0.01)
        side(m, false, true, 0.01)
        assert(
            m:activeDodgeMultiplier() == DodgeMachine.DODGE_MULTIPLIER,
            "expected DODGE_MULTIPLIER"
        )
    end,

    ["activeDodgeMultiplier returns AXIS_DODGE_MULTIPLIER during axis dodge"] = function()
        local m = DodgeMachine.new()
        axis(m, true, false, 0.01)
        axis(m, false, false, 0.01)
        axis(m, false, true, 0.01)
        assert(
            m:activeDodgeMultiplier() == DodgeMachine.AXIS_DODGE_MULTIPLIER,
            "expected AXIS_DODGE_MULTIPLIER"
        )
    end,
}
