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
    
    -- Cleanup existing connections
    if trackedPlayers[player] then
        if trackedPlayers[player].characterAdded then
            trackedPlayers[player].characterAdded:Disconnect()
        end
        if trackedPlayers[player].highlight then
            trackedPlayers[player].highlight:Destroy()
        end
    end

    trackedPlayers[player] = {
        highlight = nil,
        characterAdded = nil,
        humanoid = nil
    }

    -- Handle current character
    local function handleCharacter(character)
        if trackedPlayers[player].highlight then
            trackedPlayers[player].highlight:Destroy()
        end
        
        local highlight = createHighlight(player)
        highlight.Parent = character
        trackedPlayers[player].highlight = highlight
        
        -- Handle death/respawn
        local humanoid = character:WaitForChild("Humanoid")
        trackedPlayers[player].humanoid = humanoid
        
        humanoid.Died:Connect(function()
            if trackedPlayers[player].highlight then
                trackedPlayers[player].highlight:Destroy()
                trackedPlayers[player].highlight = nil
            end
        end)
    end

    if player.Character then
        handleCharacter(player.Character)
    end
    
    -- Listen for new characters
    trackedPlayers[player].characterAdded = player.CharacterAdded:Connect(handleCharacter)
end

local function removeESP(player)
    if trackedPlayers[player] then
        if trackedPlayers[player].characterAdded then
            trackedPlayers[player].characterAdded:Disconnect()
        end
        if trackedPlayers[player].highlight then
            trackedPlayers[player].highlight:Destroy()
        end
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
        
        playerAddedConn = Players.PlayerAdded:Connect(function(newPlayer)
            updateESP(newPlayer)
        end)
        
        playerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
            removeESP(leavingPlayer)
        end)
    else
        -- Deactivate
        for player in pairs(trackedPlayers) do
            removeESP(player)
        end
        
        if playerAddedConn then
            playerAddedConn:Disconnect()
        end
        if playerRemovingConn then
            playerRemovingConn:Disconnect()
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
