-- LocalScript (Place in StarterPlayerScripts)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configuration
local BUTTON_CONFIG = {
    {
        name = "ESP",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/esp.lua",
        active = false,
        instance = nil,
        connections = {}
    },
    {
        name = "Healthbar",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/Healthbar.lua",
        active = false,
        instance = nil,
        connections = {}
    },
    {
        name = "Aimlock",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/aimlock.lua",
        active = false,
        instance = nil,
        connections = {}
    },
    {
        name = "Skeleton ESP",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/SkeletonESP.lua",
        active = false,
        instance = nil,
        connections = {}
    }
}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FixedHaxGUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.18, 0, 0.35, 0)
MainFrame.Position = UDim2.new(0.01, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(55, 0, 55)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = MainFrame

-- Universal cleanup function
local function cleanUp(config)
    -- Clear connections
    for _, conn in ipairs(config.connections) do
        if type(conn) == "userdata" and conn.Connected then
            conn:Disconnect()
        end
    end
    config.connections = {}

    -- Clear instances
    if type(config.instance) == "table" then
        for _, obj in pairs(config.instance) do
            pcall(function()
                if obj:IsA("Instance") then
                    obj:Destroy()
                end
            end)
        end
    end
    config.instance = nil
end

-- Create buttons with proper tracking
for index, config in ipairs(BUTTON_CONFIG) do
    local button = Instance.new("TextButton")
    button.Name = "Button"..index
    button.Text = config.name
    button.Size = UDim2.new(0.9, 0, 0.2, 0)
    button.Position = UDim2.new(0.05, 0, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    
    button.MouseButton1Click:Connect(function()
        config.active = not config.active
        
        if config.active then
            -- Activation
            local success, result = pcall(function()
                local code = game:HttpGet(config.url, true)
                return loadstring(code)()
            end)
            
            if success then
                -- Handle different script types
                if type(result) == "function" then
                    -- Store function and call
                    config.instance = result
                    table.insert(config.connections, result())
                elseif type(result) == "table" then
                    -- Store table and toggle
                    config.instance = result
                    if result.Toggle then
                        result:Toggle(true)
                    end
                end
                
                button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                print(config.name .. " activated")
            else
                warn("Activation failed:", result)
                button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                config.active = false
            end
        else
            -- Deactivation
            cleanUp(config)
            button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            print(config.name .. " deactivated")
        end
    end)
    
    button.Parent = MainFrame
end

-- Toggle GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.T and not gameProcessed then
        MainFrame.Visible = not MainFrame.Visible
        TweenService:Create(
            MainFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad),
            {Position = MainFrame.Visible and UDim2.new(0.01, 0, 0.3, 0) or UDim2.new(-0.18, 0, 0.3, 0)}
        ):Play()
    end
end)

-- Force cleanup when GUI closes
MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    if not MainFrame.Visible then
        for _, config in ipairs(BUTTON_CONFIG) do
            if config.active then
                cleanUp(config)
                config.active = false
            end
        end
    end
end)
