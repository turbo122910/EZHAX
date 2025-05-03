local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local ESP_COLORS = {
    DEFAULT = Color3.new(1, 1, 1),
    FRIENDLY = Color3.new(0, 1, 0),
    ENEMY = Color3.new(1, 0, 0)
}

local BONE_CONNECTIONS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

-- ESP Tracking
local trackedPlayers = {}

local function getTeamColor(player)
    if player.Team then
        return player.TeamColor.Color
    end
    return ESP_COLORS.DEFAULT
end

local function createBoneLine()
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Visible = true
    return line
end

local function updateESP(player)
    if not trackedPlayers[player] then
        trackedPlayers[player] = {
            Lines = {},
            Connections = {}
        }
    end
    
    local character = player.Character or player.CharacterAdded:Wait()
    local color = getTeamColor(player)
    
    -- Create bone connections
    for _, connection in pairs(BONE_CONNECTIONS) do
        local part1 = character:WaitForChild(connection[1])
        local part2 = character:WaitForChild(connection[2])
        
        local line = createBoneLine()
        line.Color = color
        table.insert(trackedPlayers[player].Lines, {
            Line = line,
            Part1 = part1,
            Part2 = part2
        })
    end
    
    -- Update loop
    trackedPlayers[player].Connections.heartbeat = RunService.Heartbeat:Connect(function()
        if not character or
