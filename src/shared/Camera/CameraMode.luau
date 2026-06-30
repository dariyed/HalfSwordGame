--[[
    Pure state machine: ThirdPerson ⇄ FirstPerson, toggled by C key.
]]

type Mode = "ThirdPerson" | "FirstPerson"

type CameraMode = {
    _mode: Mode,
    toggle: (self: CameraMode) -> (),
    getMode: (self: CameraMode) -> Mode,
    isFirstPerson: (self: CameraMode) -> boolean,
}

local CameraMode = {}
CameraMode.__index = CameraMode

function CameraMode.new(): CameraMode
    return setmetatable({ _mode = "ThirdPerson" :: Mode }, CameraMode) :: any
end

function CameraMode:toggle()
    self._mode = self._mode == "ThirdPerson" and "FirstPerson" or "ThirdPerson"
end

function CameraMode:getMode(): Mode
    return self._mode
end

function CameraMode:isFirstPerson(): boolean
    return self._mode == "FirstPerson"
end

return CameraMode
