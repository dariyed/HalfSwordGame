--[[
    Shared mutable state between CameraController and MovementController.
    Both LocalScripts share the same ModuleScript instance in the client VM,
    so writing here is immediately visible to the other script.
]]

return {
    yaw = 0,
}
