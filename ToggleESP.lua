local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ESP Configuration
local espEnabled = false
local trackedPlayers = {}

local function createESP(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(148, 0, 211) -- Purple
    highlight.OutlineColor = player.TeamColor.Color
    highlight.FillTransparency = 0.5
    
    -- Name Tag
    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "ESP_NameTag"
    nameTag.Size = UDim2.new(0, 200, 0, 50)
    nameTag.StudsOffset = Vector3.new(0, 3, 0)
    nameTag.AlwaysOnTop = true
    
    local tagText = Instance.new("TextLabel")
    tagText.Size = UDim2.new(1, 0, 1, 0)
    tagText.BackgroundTransparency = 1
    tagText.Text = player.Name
    tagText.TextColor3 = player.TeamColor.Color
    tagText.Font = Enum.Font.SourceSansBold
    tagText.TextSize = 18
    tagText.Parent = nameTag
    
    return highlight, nameTag
end

local function updateESP(player)
    if not espEnabled then return end
    
    -- Cleanup existing
    if trackedPlayers[player] then
        if trackedPlayers[player].highlight then trackedPlayers[player].highlight:Destroy() end
        if trackedPlayers[player].nameTag then trackedPlayers[player].nameTag:Destroy() end
        if trackedPlayers[player].connections then
            for _, conn in pairs(trackedPlayers[player].connections) do
                conn:Disconnect()
            end
        end
    end

    trackedPlayers[player] = {
        highlight = nil,
        nameTag = nil,
        connections = {}
    }

    local function handleCharacter(character)
        -- Create ESP elements
        local highlight, nameTag = createESP(player)
        local head = character:WaitForChild("Head")
        
        highlight.Parent = character
        nameTag.Adornee = head
        nameTag.Parent = character
        
        trackedPlayers[player].highlight = highlight
        trackedPlayers[player].nameTag = nameTag
        
        -- Death/respawn handling
        local humanoid = character:WaitForChild("Humanoid")
        local diedConn = humanoid.Died:Connect(function()
            highlight:Destroy()
            nameTag:Destroy()
        end)
        
        local respawnConn = player.CharacterAdded:Connect(function(newChar)
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
        if trackedPlayers[player].highlight then trackedPlayers[player].highlight:Destroy() end
        if trackedPlayers[player].nameTag then trackedPlayers[player].nameTag:Destroy() end
        for _, conn in pairs(trackedPlayers[player].connections) do
            conn:Disconnect()
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

-- Keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Nine and
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and
       not gameProcessed then
        toggleESP()
    end
end)
