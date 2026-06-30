--[[
    Detects a quick A→D or D→A direction switch and outputs a speed boost.
    "Quick" means the new key is pressed within SWITCH_WINDOW seconds of releasing the old one.
    Pure module — accumulates time from dt, no Roblox APIs.
]]

local SWITCH_WINDOW = 0.25 -- seconds: how fast the switch must happen to count as a dodge
local DODGE_DURATION = 0.18 -- seconds: how long the speed boost lasts
local DODGE_COOLDOWN = 1.2 -- seconds: minimum gap between dodges
local DODGE_MULTIPLIER = 2.2 -- speed multiplier during the boost

local DodgeMachine = {}
DodgeMachine.__index = DodgeMachine

function DodgeMachine.new()
    return setmetatable({
        _time = 0,
        _lastLeftRelease = -math.huge,
        _lastRightRelease = -math.huge,
        _dodgeTimer = 0,
        _cooldownTimer = 0,
        _prevLeft = false,
        _prevRight = false,
    }, DodgeMachine)
end

function DodgeMachine:update(leftHeld: boolean, rightHeld: boolean, dt: number): boolean
    self._time += dt
    self._dodgeTimer = math.max(0, self._dodgeTimer - dt)
    self._cooldownTimer = math.max(0, self._cooldownTimer - dt)

    -- Record when each key was released
    if self._prevLeft and not leftHeld then
        self._lastLeftRelease = self._time
    end
    if self._prevRight and not rightHeld then
        self._lastRightRelease = self._time
    end

    if self._cooldownTimer <= 0 then
        -- Just pressed D after recently releasing A → dodge right
        if rightHeld and not self._prevRight then
            if self._time - self._lastLeftRelease <= SWITCH_WINDOW then
                self._dodgeTimer = DODGE_DURATION
                self._cooldownTimer = DODGE_COOLDOWN
            end
        end
        -- Just pressed A after recently releasing D → dodge left
        if leftHeld and not self._prevLeft then
            if self._time - self._lastRightRelease <= SWITCH_WINDOW then
                self._dodgeTimer = DODGE_DURATION
                self._cooldownTimer = DODGE_COOLDOWN
            end
        end
    end

    self._prevLeft = leftHeld
    self._prevRight = rightHeld

    return self._dodgeTimer > 0
end

function DodgeMachine:isDodging(): boolean
    return self._dodgeTimer > 0
end

function DodgeMachine:isOnCooldown(): boolean
    return self._cooldownTimer > 0
end

return {
    new = function()
        return DodgeMachine.new()
    end,
    DODGE_MULTIPLIER = DODGE_MULTIPLIER,
    SWITCH_WINDOW = SWITCH_WINDOW,
    DODGE_DURATION = DODGE_DURATION,
    DODGE_COOLDOWN = DODGE_COOLDOWN,
}
