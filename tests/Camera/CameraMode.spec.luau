local CameraMode = require("../../src/shared/Camera/CameraMode")

return {
    ["starts in ThirdPerson"] = function()
        local m = CameraMode.new()
        assert(m:getMode() == "ThirdPerson", "expected ThirdPerson, got " .. m:getMode())
    end,

    ["toggle: ThirdPerson → FirstPerson"] = function()
        local m = CameraMode.new()
        m:toggle()
        assert(m:getMode() == "FirstPerson", "expected FirstPerson after toggle")
    end,

    ["toggle: FirstPerson → ThirdPerson"] = function()
        local m = CameraMode.new()
        m:toggle()
        m:toggle()
        assert(m:getMode() == "ThirdPerson", "expected ThirdPerson after second toggle")
    end,

    ["isFirstPerson: false by default"] = function()
        local m = CameraMode.new()
        assert(m:isFirstPerson() == false, "expected false")
    end,

    ["isFirstPerson: true after toggle"] = function()
        local m = CameraMode.new()
        m:toggle()
        assert(m:isFirstPerson() == true, "expected true")
    end,

    ["multiple toggles alternate correctly"] = function()
        local m = CameraMode.new()
        m:toggle()
        assert(m:getMode() == "FirstPerson", "toggle 1")
        m:toggle()
        assert(m:getMode() == "ThirdPerson", "toggle 2")
        m:toggle()
        assert(m:getMode() == "FirstPerson", "toggle 3")
    end,
}
