--[[
    Spawns a gray stick and welds it to the player's right arm on spawn.
    Simple weld for now — physics-based swing comes in Issue #5.
]]

local Players = game:GetService("Players")

local function equipSword(character: Model, player: Player)
    local arm = character:WaitForChild("Right Arm", 5) :: BasePart
    if not arm then
        warn("WeaponService: Right Arm not found for", player.Name)
        return
    end

    local stick = Instance.new("Part")
    stick.Name = "Sword"
    stick.Size = Vector3.new(0.2, 2, 0.2)
    stick.BrickColor = BrickColor.new("Medium stone grey")
    stick.Material = Enum.Material.SmoothPlastic
    stick.CanCollide = false
    stick.Anchored = false
    stick.Parent = workspace

    -- Place grip at wrist (bottom of R6 arm, arm is 2 studs tall so offset -1.9)
    stick.CFrame = arm.CFrame * CFrame.new(0, -1.9, 0)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = arm
    weld.Part1 = stick
    weld.Parent = stick

    character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(game) then
            stick:Destroy()
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.defer(function()
            equipSword(character, player)
        end)
    end)
end)

for _, player in Players:GetPlayers() do
    if player.Character then
        task.defer(function()
            equipSword(player.Character, player)
        end)
    end
end
