-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local FREE_CAM_SPEED = 50
local ROTATION_SENSITIVITY = 0.8

-- State variables
local freeCamEnabled = false
local originalCameraType = Camera.CameraType
local originalWalkSpeed = 16
local cameraCFrame = Camera.CFrame
local lookX, lookY = 0, 0

-- Character control
local function anchorCharacter(enable)
    local character = Player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid then
            humanoid.WalkSpeed = enable and 0 or originalWalkSpeed
            humanoid.AutoRotate = not enable
        end
        
        if rootPart then
            rootPart.Anchored = enable
        end
    end
end

-- Camera movement logic
local function updateFreeCam(dt)
    local moveVector = Vector3.new()
    
    -- WASD Movement
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= Camera.CFrame.RightVector end
    
    -- Q/E Vertical movement
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector += Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector -= Vector3.new(0,1,0) end
    
    -- Apply movement
    cameraCFrame = cameraCFrame + (moveVector * FREE_CAM_SPEED * dt)
    
    -- Mouse look
    lookX = lookX - UserInputService:GetMouseDelta().X * ROTATION_SENSITIVITY
    lookY = math.clamp(lookY - UserInputService:GetMouseDelta().Y * ROTATION_SENSITIVITY, -89, 89)
    
    -- Update camera
    Camera.CFrame = cameraCFrame * CFrame.Angles(math.rad(lookY), math.rad(lookX), 0)
end

-- Toggle with Ctrl+8
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Eight and
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
       (UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and
       not processed then
        
        freeCamEnabled = not freeCamEnabled
        
        if freeCamEnabled then
            -- Enable free cam
            originalCameraType = Camera.CameraType
            originalWalkSpeed = Player.Character.Humanoid.WalkSpeed
            Camera.CameraType = Enum.CameraType.Scriptable
            anchorCharacter(true)
            cameraCFrame = Camera.CFrame
            lookX, lookY = 0, 0
            
            -- Start camera update loop
            RunService:BindToRenderStep("FreeCamera", Enum.RenderPriority.Camera.Value, function(dt)
                updateFreeCam(dt)
            end)
        else
            -- Restore normal
            RunService:UnbindFromRenderStep("FreeCamera")
            Camera.CameraType = originalCameraType
            anchorCharacter(false)
        end
    end
end)

-- Cleanup when character respawns
Player.CharacterAdded:Connect(function()
    if freeCamEnabled then
        RunService:UnbindFromRenderStep("FreeCamera")
        Camera.CameraType = originalCameraType
        anchorCharacter(false)
        freeCamEnabled = false
    end
end)
