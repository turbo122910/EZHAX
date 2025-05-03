-- LocalScript (Place in StarterPlayerScripts)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configuration
local BUTTON_CONFIG = {
    {
        name = "ESP",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/esp.lua",
        active = false,
        objects = {}
    },
    {
        name = "Healthbar",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/Healthbar.lua",
        active = false,
        objects = {}
    },
    {
        name = "Aimlock",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/aimlock.lua",
        active = false,
        objects = {}
    },
    {
        name = "Skeleton ESP",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/SkeletonESP.lua",
        active = false,
        objects = {}
    }
}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalHax_GUI"
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

-- Track created objects
local function trackCreation(config)
    local oldNew = Instance.new
    Instance.new = function(...)
        local obj = oldNew(...)
        table.insert(config.objects, obj)
        return obj
    end
end

local function stopTracking()
    Instance.new = getgenv().Instance.new
end

-- Create Buttons
for _, config in ipairs(BUTTON_CONFIG) do
    local button = Instance.new("TextButton")
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
            trackCreation(config)
            local success, err = pcall(function()
                loadstring(game:HttpGet(config.url))()
            end)
            stopTracking()
            
            if success then
                button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            else
                warn("Activation failed:", err)
                config.active = false
                button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            end
        else
            -- Deactivation
            for _, obj in pairs(config.objects) do
                pcall(function()
                    if obj:IsA("Connection") then
                        obj:Disconnect()
                    else
                        obj:Destroy()
                    end
                end)
            end
            config.objects = {}
            button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
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

-- Cleanup when GUI is destroyed
ScreenGui.Destroying:Connect(function()
    for _, config in ipairs(BUTTON_CONFIG) do
        if config.active then
            -- Trigger deactivation
            button.MouseButton1Click:Connect()
        end
    end
end)
