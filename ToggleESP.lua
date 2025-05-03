local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ESP Configuration
local espEnabled = false
local trackedPlayers = {}

local function createHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(148, 0, 211) -- Purple color
    highlight.OutlineColor = player.TeamColor.Color -- Team-colored outline
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    return highlight
end

local function updateESP(player)
    if not espEnabled then return end
    
    -- Cleanup existing connections
    if trackedPlayers[player] then
        if trackedPlayers[player].connections then
            for _, conn in pairs(trackedPlayers[player].connections) do
                conn:Disconnect()
            end
        end
        if trackedPlayers[player].highlight then
            trackedPlayers[player].highlight:Destroy()
        end
    end

    trackedPlayers[player] = {
        highlight = nil,
        connections = {}
    }

    local function handleCharacter(character)
        -- Clear old highlight
        if trackedPlayers[player].highlight then
            trackedPlayers[player].highlight:Destroy()
        end
        
        -- Create new highlight
        local highlight = createHighlight(player)
        highlight.Parent = character
        trackedPlayers[player].highlight = highlight
        
        -- Death/respawn handling
        local humanoid = character:WaitForChild("Humanoid")
        local diedConn = humanoid.Died:Connect(function()
            highlight.Enabled = false
        end)
        
        local respawnConn = player.CharacterAdded:Connect(function(newChar)
            highlight:Destroy()
            handleCharacter(newChar)
        end)
        
        table.insert(trackedPlayers[player].connections, diedConn)
        table.insert(trackedPlayers[player].connections, respawnConn)
    end

    if player.Character then
        handleCharacter(player.Character)
    end
    
    local charAddedConn = player.CharacterAdded:Connect(handleCharacter)
    table.insert(trackedPlayers[player].connections, charAddedConn)
end

local function removeESP(player)
    if trackedPlayers[player] then
        -- Disconnect all connections
        for _, conn in ipairs(trackedPlayers[player].connections) do
            conn:Disconnect()
        end
        
        -- Destroy highlight
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
        
        if playerAddedConn then playerAddedConn:Disconnect() end
        if playerRemovingConn then playerRemovingConn:Disconnect() end
    end
end

-- Ctrl+1 Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Nine and
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and
       not gameProcessed then
        toggleESP()
    end
end)
