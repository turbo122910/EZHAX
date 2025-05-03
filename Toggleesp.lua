local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ESP Configuration
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

-- Toggle System with Ctrl+1
local playerAddedConn, playerRemovingConn

local function toggleESP()
    espEnabled = not espEnabled
    
    if espEnabled then
        -- Activate
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                updateESP(player)
            end
        end
        
        playerAddedConn = Players.PlayerAdded:Connect(updateESP)
        playerRemovingConn = Players.PlayerRemoving:Connect(removeESP)
    else
        -- Deactivate
        for player in pairs(trackedPlayers) do
            removeESP(player)
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

-- Ctrl+1 Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.One and
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and
       not gameProcessed then
        toggleESP()
    end
end)
