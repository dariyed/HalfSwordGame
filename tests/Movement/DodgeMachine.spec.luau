local DodgeMachine = require("../../src/shared/Movement/DodgeMachine")

local function tick(machine, left, right, dt)
    return machine:update(left, right, dt)
end

return {
    ["starts not dodging"] = function()
        local m = DodgeMachine.new()
        assert(m:isDodging() == false, "should not be dodging at start")
    end,

    ["A→D quick switch triggers dodge"] = function()
        local m = DodgeMachine.new()
        tick(m, true, false, 0.01) -- hold A
        tick(m, false, false, 0.1) -- release A
        local dodging = tick(m, false, true, 0.01) -- press D within window
        assert(dodging == true, "A→D quick switch should trigger dodge")
    end,

    ["D→A quick switch triggers dodge"] = function()
        local m = DodgeMachine.new()
        tick(m, false, true, 0.01) -- hold D
        tick(m, false, false, 0.1) -- release D
        local dodging = tick(m, true, false, 0.01) -- press A within window
        assert(dodging == true, "D→A quick switch should trigger dodge")
    end,

    ["slow A→D switch does not trigger dodge"] = function()
        local m = DodgeMachine.new()
        tick(m, true, false, 0.01) -- hold A
        tick(m, false, false, 0.01) -- release A (timestamp recorded here)
        tick(m, false, false, DodgeMachine.SWITCH_WINDOW + 0.05) -- wait too long
        local dodging = tick(m, false, true, 0.01) -- press D — too late
        assert(dodging == false, "slow switch must not dodge")
    end,

    ["dodge expires after DODGE_DURATION"] = function()
        local m = DodgeMachine.new()
        tick(m, true, false, 0.01)
        tick(m, false, false, 0.05)
        tick(m, false, true, 0.01) -- trigger dodge
        -- advance past duration
        tick(m, false, true, DodgeMachine.DODGE_DURATION + 0.01)
        assert(m:isDodging() == false, "dodge should expire after DODGE_DURATION")
    end,

    ["cooldown prevents immediate re-dodge"] = function()
        local m = DodgeMachine.new()
        -- First dodge: A→D
        tick(m, true, false, 0.01)
        tick(m, false, false, 0.05)
        tick(m, false, true, 0.01)
        -- Wait for dodge to end but not cooldown
        tick(m, false, true, DodgeMachine.DODGE_DURATION + 0.05)
        -- Try D→A immediately
        tick(m, false, false, 0.05) -- release D
        local dodging = tick(m, true, false, 0.01) -- press A
        assert(dodging == false, "cooldown should block re-dodge")
    end,

    ["can dodge again after cooldown expires"] = function()
        local m = DodgeMachine.new()
        -- First dodge
        tick(m, true, false, 0.01)
        tick(m, false, false, 0.05)
        tick(m, false, true, 0.01)
        -- Wait out full cooldown
        tick(m, false, true, DodgeMachine.DODGE_COOLDOWN + 0.1)
        -- Second dodge: D→A
        tick(m, false, false, 0.05)
        local dodging = tick(m, true, false, 0.01)
        assert(dodging == true, "should be able to dodge again after cooldown")
    end,

    ["DODGE_MULTIPLIER is greater than sprint speed"] = function()
        local MovementIntent = require("../../src/shared/Movement/MovementIntent")
        assert(
            DodgeMachine.DODGE_MULTIPLIER > MovementIntent.SPRINT_SPEED_MULTIPLIER,
            "dodge must be faster than sprint"
        )
    end,
}
