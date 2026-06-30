--[[
    Pure state machine: Normal ⇄ Stance, driven by shift key.
    No Roblox Instances — safe to test headlessly under Lune.
]]

type State = "Normal" | "Stance"

type StanceMachine = {
    _state: State,
    update: (self: StanceMachine, shiftHeld: boolean) -> (),
    getState: (self: StanceMachine) -> State,
    isStance: (self: StanceMachine) -> boolean,
}

local StanceMachine = {}
StanceMachine.__index = StanceMachine

function StanceMachine.new(): StanceMachine
    return setmetatable({ _state = "Normal" :: State }, StanceMachine) :: any
end

function StanceMachine:update(shiftHeld: boolean)
    self._state = shiftHeld and "Stance" or "Normal"
end

function StanceMachine:getState(): State
    return self._state
end

function StanceMachine:isStance(): boolean
    return self._state == "Stance"
end

return StanceMachine
