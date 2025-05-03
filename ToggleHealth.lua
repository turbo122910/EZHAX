local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Healthbar Configuration
local healthbarsEnabled = false
local trackedHealthbars = {}

local function createHealthbar(character)
    local humanoid = character:WaitForChild("Humanoid")
    local head = character:WaitForChild("Head")
    
    local healthbar = Instance.new("BillboardGui")
    healthbar.Name = "PlayerHealthBar"
    healthbar.Size = UDim2.new(4, 0, 0.5, 0)
    healthbar.StudsOffset = Vector3.new(0, 2.5, 0)
    healthbar.AlwaysOnTop = true
    healthbar.Adornee = head
    
    local background = Instance.new("Frame")
    background.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Parent = healthbar
    
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.new(1, 0, 0)
    fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
    fill.AnchorPoint = Vector2.new(0, 0.5)
    fill.Position = UDim2.new(0, 0, 0.5, 0)
    fill.Parent = background
    
    humanoid.HealthChanged:Connect(function()
        fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
    end)
    
    return healthbar
end

local function updateHealthbars(player)
    if not healthbarsEnabled then return end
    
    local character = player.Character or player.CharacterAdded:Wait()
    if character then
        local healthbar = createHealthbar(character)
        healthbar.Parent = character
        trackedHealthbars[player] = healthbar
    end
end

local function removeHealthbars(player)
    if trackedHealthbars[player] then
        trackedHealthbars[player]:Destroy()
        trackedHealthbars[player] = nil
    end
end

-- Toggle System with Ctrl+0
local playerAddedConn, playerRemovingConn

local function toggleHealthbars()
    healthbarsEnabled = not healthbarsEnabled
    
    if healthbarsEnabled then
        -- Activate
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                updateHealthbars(player)
            end
        end
        
        playerAddedConn = Players.PlayerAdded:Connect(updateHealthbars)
        playerRemovingConn = Players.PlayerRemoving:Connect(removeHealthbars)
    else
        -- Deactivate
        for player in pairs(trackedHealthbars) do
            removeHealthbars(player)
        end
        
        if playerAddedConn then
            playerAddedConn:Disconnect()
            playerAddedConn = nil
        end
        
        if playerRemovingConn then
            playerRemovingConn:Disconnect()
            playerRemovingConn = nil
        end
    end
end

-- Ctrl+0 Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Zero and
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and
       not gameProcessed then
        toggleHealthbars()
    end
end)
