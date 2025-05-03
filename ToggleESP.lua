local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Original ESP Code
local espEnabled = false
local trackedPlayers = {}

local function createHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = player.TeamColor.Color
    highlight.OutlineColor = player.TeamColor.Color
    highlight.FillTransparency = 0.5
    return highlight
end

local function updateESP(player)
    if not espEnabled then return end
    
    local character = player.Character or player.CharacterAdded:Wait()
    if character then
        local highlight = createHighlight(player)
        highlight.Parent = character
        trackedPlayers[player] = highlight
    end
end

local function removeESP(player)
    if trackedPlayers[player] then
        trackedPlayers[player]:Destroy()
        trackedPlayers[player] = nil
    end
end

-- Toggle System
local function toggleESP()
    espEnabled = not espEnabled
    
    if espEnabled then
        -- Activate ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                updateESP(player)
            end
        end
        
        Players.PlayerAdded:Connect(function(player)
            updateESP(player)
        end)
        
        Players.PlayerRemoving:Connect(function(player)
            removeESP(player)
        end)
    else
        -- Deactivate ESP
        for player in pairs(trackedPlayers) do
            removeESP(player)
        end
        
        -- Disconnect events
        getconnections(Players.PlayerAdded)[1]:Disconnect()
        getconnections(Players.PlayerRemoving)[1]:Disconnect()
    end
end

-- Keybind
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.One then
        toggleESP()
    end
end)
