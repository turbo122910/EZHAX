-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local flying = false
local SPEED = 50

local function toggleFly()
    flying = not flying
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if flying then
        -- Enable flight
        humanoid.PlatformStand = true
        if rootPart then
            -- Noclip setup
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Anchored = false
                end
            end
            
            -- Flight control loop
            local bg = Instance.new("BodyGyro", rootPart)
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            
            local bv = Instance.new("BodyVelocity", rootPart)
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new()
            
            RunService.Stepped:Connect(function()
                if not flying then return end
                
                -- Movement vectors
                local direction = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += rootPart.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= rootPart.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += rootPart.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= rootPart.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then direction += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then direction += Vector3.new(0,-1,0) end
                
                -- Apply movement
                bv.Velocity = direction * SPEED
                bg.CFrame = workspace.CurrentCamera.CFrame
            end)
        end
    else
        -- Disable flight
        humanoid.PlatformStand = false
        if rootPart then
            rootPart.Anchored = false
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            if rootPart:FindFirstChild("BodyGyro") then rootPart.BodyGyro:Destroy() end
            if rootPart:FindFirstChild("BodyVelocity") then rootPart.BodyVelocity:Destroy() end
        end
    end
end

-- Toggle with Shift+F
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.F and
       UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and
       not processed then
        toggleFly()
    end
end)

-- Auto-disable on respawn
player.CharacterAdded:Connect(function()
    if flying then
        flying = false
        toggleFly()
    end
end)
