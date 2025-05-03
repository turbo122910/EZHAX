-- LocalScript (Place in StarterPlayerScripts)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configuration
local BUTTON_CONFIG = {
    {
        name = "ESP",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/esp.lua",
        active = false,
        instance = nil
    },
    {
        name = "Healthbar",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/Healthbar.lua",
        active = false,
        instance = nil
    },
    {
        name = "Aimlock",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/aimlock.lua",
        active = false,
        instance = nil
    },
    {
        name = "Skeleton ESP",
        url = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/SkeletonESP.lua",
        active = false,
        instance = nil
    }
}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WorkingHaxGUI"
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

-- Verify URLs are accessible
local function verifyUrl(url)
    local success = pcall(function()
        return game:HttpGet(url, true)
    end)
    return success
end

-- Create Buttons with Status Feedback
for _, config in ipairs(BUTTON_CONFIG) do
    local button = Instance.new("TextButton")
    button.Text = config.name
    button.Size = UDim2.new(0.9, 0, 0.2, 0)
    button.Position = UDim2.new(0.05, 0, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    
    -- Pre-check URL accessibility
    if not verifyUrl(config.url) then
        button.Text = config.name .. " (URL Error)"
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        button.Active = false
    end
    
    button.MouseButton1Click:Connect(function()
        if not verifyUrl(config.url) then return end
        
        config.active = not config.active
        
        if config.active then
            -- Activation
            local success, result = pcall(function()
                local code = game:HttpGet(config.url, true)
                return loadstring(code)()
            end)
            
            if success then
                -- Handle different script return types
                if type(result) == "function" then
                    result() -- Execute if it's a function
                elseif type(result) == "table" and result.Toggle then
                    result:Toggle(true)
                    config.instance = result
                end
                
                button.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                print(config.name .. " activated successfully!")
            else
                warn("Activation Error:", result)
                button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                config.active = false
            end
        else
            -- Deactivation
            if config.instance and type(config.instance.Toggle) == "function" then
                config.instance:Toggle(false)
            end
            button.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            print(config.name .. " deactivated!")
        end
    end)
    
    button.Parent = MainFrame
end

-- Toggle GUI with better visibility check
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

-- Connection cleanup
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    for _, config in ipairs(BUTTON_CONFIG) do
        if config.active then
            pcall(function()
                if config.instance and config.instance.Toggle then
                    config.instance:Toggle(false)
                    config.instance:Toggle(true)
                end
            end)
        end
    end
end)
