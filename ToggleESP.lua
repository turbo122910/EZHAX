local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- ESP Configuration
local espEnabled = false
local trackedPlayers = {}

local function createESPComponents(player)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(148, 0, 211)
    highlight.OutlineColor = player.TeamColor.Color
    highlight.FillTransparency = 0.5

    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "ESP_NameTag"
    nameTag.Size = UDim2.new(0, 200, 0, 50)
    nameTag.StudsOffset = Vector3.new(0, 3.5, 0)
    nameTag.AlwaysOnTop = true
    nameTag.MaxDistance = 200

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

local function updatePlayerESP(player)
    if not espEnabled or not player then return end

    -- Cleanup existing components
    if trackedPlayers[player] then
        if trackedPlayers[player].highlight then
            trackedPlayers[player].highlight:Destroy()
        end
        if trackedPlayers[player].nameTag then
            trackedPlayers[player].nameTag:Destroy()
        end
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
        -- Wait for critical components
        if not character or not character.Parent then return end
        
        local success, _ = pcall(function()
            character:WaitForChild("Head", 2)
            character:WaitForChild("Humanoid", 2)
        end)

        if not success then return end

        -- Create new components
        local highlight, nameTag = createESPComponents(player)
        
        highlight.Parent = character
        nameTag.Adornee = character:WaitForChild("Head")
        nameTag.Parent = character

        trackedPlayers[player].highlight = highlight
        trackedPlayers[player].nameTag = nameTag

        -- Lifecycle management
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local diedConn = humanoid.Died:Connect(function()
                highlight:Destroy()
                nameTag:Destroy()
            end)
            table.insert(trackedPlayers[player].connections, diedConn)
        end

        local respawnConn = player.CharacterAdded:Connect(function(newChar)
            handleCharacter(newChar)
        end)
        table.insert(trackedPlayers[player].connections, respawnConn)
    end

    -- Initial character handling
    if player.Character then
        handleCharacter(player.Character)
    end
    
    local charAddedConn = player.CharacterAdded:Connect(handleCharacter)
    table.insert(trackedPlayers[player].connections, charAddedConn)
end

local function removePlayerESP(player)
    if trackedPlayers[player] then
        -- Cleanup visuals
        if trackedPlayers[player].highlight then
            trackedPlayers[player].highlight:Destroy()
        end
        if trackedPlayers[player].nameTag then
            trackedPlayers[player].nameTag:Destroy()
        end
        
        -- Cleanup connections
        for _, conn in pairs(trackedPlayers[player].connections) do
            conn:Disconnect()
        end
        
        trackedPlayers[player] = nil
    end
end

-- Toggle System
local function toggleESP()
    espEnabled = not espEnabled

    if espEnabled then
        -- Initialize for all players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                updatePlayerESP(player)
            end
        end

        -- Connect future players
        Players.PlayerAdded:Connect(function(newPlayer)
            updatePlayerESP(newPlayer)
        end)

        -- Cleanup leaving players
        Players.PlayerRemoving:Connect(function(leavingPlayer)
            removePlayerESP(leavingPlayer)
        end)
    else
        -- Cleanup all
        for player in pairs(trackedPlayers) do
            removePlayerESP(player)
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
