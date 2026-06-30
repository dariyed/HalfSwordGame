--[[
    Detects quick direction switches and outputs speed boosts.

    Side dodge  (A→D or D→A): short burst, blocked while W or S held.
    Axis dodge  (W→S or S→W): longer burst, separate cooldown.

    Pure module — accumulates time from dt, no Roblox APIs.
]]

-- Side dodge (A↔D)
local DODGE_DURATION = 0.14
local DODGE_COOLDOWN = 1.2
local DODGE_MULTIPLIER = 1.5

-- Axis dodge (W↔S)
local AXIS_DODGE_DURATION = 0.22
local AXIS_DODGE_COOLDOWN = 1.8
local AXIS_DODGE_MULTIPLIER = 1.6

local SWITCH_WINDOW = 0.25 -- seconds: how fast the switch must happen to count

local DodgeMachine = {}
DodgeMachine.__index = DodgeMachine

function DodgeMachine.new()
    return setmetatable({
        _time = 0,
        -- side
        _lastLeftRelease = -math.huge,
        _lastRightRelease = -math.huge,
        _dodgeTimer = 0,
        _cooldownTimer = 0,
        _prevLeft = false,
        _prevRight = false,
        -- axis
        _lastForwardRelease = -math.huge,
        _lastBackwardRelease = -math.huge,
        _axisDodgeTimer = 0,
        _axisCooldownTimer = 0,
        _prevForward = false,
        _prevBackward = false,
    }, DodgeMachine)
end

--[[
    sideBlocked: blocks A↔D dodge (pass: not shift, or W/S held).
    axisBlocked: blocks W↔S dodge (pass: not shift).
    Returns true if any dodge is active.
]]
function DodgeMachine:update(
    leftHeld: boolean,
    rightHeld: boolean,
    forwardHeld: boolean,
    backwardHeld: boolean,
    dt: number,
    sideBlocked: boolean?,
    axisBlocked: boolean?
): boolean
    self._time += dt

    self._dodgeTimer = math.max(0, self._dodgeTimer - dt)
    self._cooldownTimer = math.max(0, self._cooldownTimer - dt)
    self._axisDodgeTimer = math.max(0, self._axisDodgeTimer - dt)
    self._axisCooldownTimer = math.max(0, self._axisCooldownTimer - dt)

    -- Record releases
    if self._prevLeft and not leftHeld then
        self._lastLeftRelease = self._time
    end
    if self._prevRight and not rightHeld then
        self._lastRightRelease = self._time
    end
    if self._prevForward and not forwardHeld then
        self._lastForwardRelease = self._time
    end
    if self._prevBackward and not backwardHeld then
        self._lastBackwardRelease = self._time
    end

    -- Side dodge (A↔D), blocked while any forward/backward key held
    if self._cooldownTimer <= 0 and not sideBlocked then
        if rightHeld and not self._prevRight then
            if self._time - self._lastLeftRelease <= SWITCH_WINDOW then
                self._dodgeTimer = DODGE_DURATION
                self._cooldownTimer = DODGE_COOLDOWN
            end
        end
        if leftHeld and not self._prevLeft then
            if self._time - self._lastRightRelease <= SWITCH_WINDOW then
                self._dodgeTimer = DODGE_DURATION
                self._cooldownTimer = DODGE_COOLDOWN
            end
        end
    end

    -- Axis dodge (W↔S), separate cooldown
    if self._axisCooldownTimer <= 0 and not axisBlocked then
        if backwardHeld and not self._prevBackward then
            if self._time - self._lastForwardRelease <= SWITCH_WINDOW then
                self._axisDodgeTimer = AXIS_DODGE_DURATION
                self._axisCooldownTimer = AXIS_DODGE_COOLDOWN
            end
        end
        if forwardHeld and not self._prevForward then
            if self._time - self._lastBackwardRelease <= SWITCH_WINDOW then
                self._axisDodgeTimer = AXIS_DODGE_DURATION
                self._axisCooldownTimer = AXIS_DODGE_COOLDOWN
            end
        end
    end

    self._prevLeft = leftHeld
    self._prevRight = rightHeld
    self._prevForward = forwardHeld
    self._prevBackward = backwardHeld

    return self._dodgeTimer > 0 or self._axisDodgeTimer > 0
end

function DodgeMachine:isDodging(): boolean
    return self._dodgeTimer > 0 or self._axisDodgeTimer > 0
end

function DodgeMachine:activeDodgeMultiplier(): number
    if self._dodgeTimer > 0 then
        return DODGE_MULTIPLIER
    elseif self._axisDodgeTimer > 0 then
        return AXIS_DODGE_MULTIPLIER
    end
    return 1
end

function DodgeMachine:isOnCooldown(): boolean
    return self._cooldownTimer > 0
end

function DodgeMachine:isAxisOnCooldown(): boolean
    return self._axisCooldownTimer > 0
end

return {
    new = DodgeMachine.new,
    DODGE_MULTIPLIER = DODGE_MULTIPLIER,
    AXIS_DODGE_MULTIPLIER = AXIS_DODGE_MULTIPLIER,
    SWITCH_WINDOW = SWITCH_WINDOW,
    DODGE_DURATION = DODGE_DURATION,
    AXIS_DODGE_DURATION = AXIS_DODGE_DURATION,
    DODGE_COOLDOWN = DODGE_COOLDOWN,
    AXIS_DODGE_COOLDOWN = AXIS_DODGE_COOLDOWN,
}
