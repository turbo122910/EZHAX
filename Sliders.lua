-- LocalScript (Complete Version)
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.2, 0, 0.15, 0)
MainFrame.Position = UDim2.new(0.5, -100, 0.8, 0) -- Centered at bottom
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = MainFrame

-- Toggle with T Key
local guiVisible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.T and not processed then
        guiVisible = not guiVisible
        TweenService:Create(
            MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {Position = guiVisible and UDim2.new(0.5, -100, 0.8, 0) or UDim2.new(0.5, -100, 1.5, 0)}
        ):Play()
    end
end)

-- Slider Creation Function
local function createSlider(name, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel")
    label.Text = name
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.BackgroundTransparency = 1
    label.Parent = container
    
    local valueBox = Instance.new("TextBox")
    valueBox.Size = UDim2.new(0.2, 0, 1, 0)
    valueBox.Position = UDim2.new(0.8, 0, 0, 0)
    valueBox.Text = tostring(defaultValue)
    valueBox.TextColor3 = Color3.new(1, 1, 1)
    valueBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    valueBox.Parent = container
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(0.55, 0, 0.3, 0)
    sliderTrack.Position = UDim2.new(0.4, 0, 0.35, 0)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    sliderTrack.Parent = container
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    sliderFill.Parent = sliderTrack
    
    local dragging = false
    local min = 0
    local max = 200
    
    local function updateValue(value)
        value = math.clamp(math.floor(value), min, max)
        valueBox.Text = tostring(value)
        sliderFill.Size = UDim2.new(value/max, 0, 1, 0)
        callback(value)
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local xOffset = input.Position.X - sliderTrack.AbsolutePosition.X
            local value = (xOffset / sliderTrack.AbsoluteSize.X) * max
            updateValue(value)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local xOffset = input.Position.X - sliderTrack.AbsolutePosition.X
            local value = (xOffset / sliderTrack.AbsoluteSize.X) * max
            updateValue(value)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    valueBox.FocusLost:Connect(function()
        updateValue(tonumber(valueBox.Text) or defaultValue)
    end)
    
    return container
end

-- Create Sliders
createSlider("FOV", 70, function(value)
    camera.FieldOfView = value
end)

local humanoid
createSlider("Speed", 16, function(value)
    if player.Character then
        humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
end)

-- Handle character respawns
player.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    humanoid = character.Humanoid
end)
