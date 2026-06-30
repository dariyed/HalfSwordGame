local StanceMachine = require("../../src/shared/Movement/StanceMachine")

return {
    ["initial state is Normal"] = function()
        local sm = StanceMachine.new()
        assert(sm:getState() == "Normal", "expected Normal, got " .. sm:getState())
    end,

    ["shift down → transitions to Stance"] = function()
        local sm = StanceMachine.new()
        sm:update(true)
        assert(sm:getState() == "Stance", "expected Stance after shift down")
    end,

    ["shift release → returns to Normal"] = function()
        local sm = StanceMachine.new()
        sm:update(true)
        sm:update(false)
        assert(sm:getState() == "Normal", "expected Normal after shift release")
    end,

    ["idempotent: repeated shift-down stays in Stance"] = function()
        local sm = StanceMachine.new()
        sm:update(true)
        sm:update(true)
        sm:update(true)
        assert(sm:getState() == "Stance", "expected Stance to stay Stance")
    end,

    ["idempotent: repeated shift-up stays in Normal"] = function()
        local sm = StanceMachine.new()
        sm:update(false)
        sm:update(false)
        assert(sm:getState() == "Normal", "expected Normal to stay Normal")
    end,

    ["isStance() returns true when in Stance"] = function()
        local sm = StanceMachine.new()
        sm:update(true)
        assert(sm:isStance() == true, "expected isStance()=true")
    end,

    ["isStance() returns false when in Normal"] = function()
        local sm = StanceMachine.new()
        assert(sm:isStance() == false, "expected isStance()=false")
    end,

    ["multiple stance toggles work correctly"] = function()
        local sm = StanceMachine.new()
        sm:update(true)
        assert(sm:getState() == "Stance", "expected Stance on toggle 1")
        sm:update(false)
        assert(sm:getState() == "Normal", "expected Normal on toggle 2")
        sm:update(true)
        assert(sm:getState() == "Stance", "expected Stance on toggle 3")
        sm:update(false)
        assert(sm:getState() == "Normal", "expected Normal on toggle 4")
    end,
}
