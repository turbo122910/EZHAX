-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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

-- Debug messages
local function debug(msg)
    print("[FreeCam] " .. msg)
    -- Uncomment to show on screen:
    -- game.StarterGui:SetCore("ChatMakeSystemMessage", {Text = "[FreeCam] "..msg})
end

-- Character control
local function anchorCharacter(enable)
    local character = Player.Character
    if not character then
        debug("No character found!")
        return false
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid then
        humanoid.WalkSpeed = enable and 0 or originalWalkSpeed
        humanoid.AutoRotate = not enable
        debug(enable and "Character anchored" or "Character released")
    else
        debug("Missing Humanoid!")
    end
    
    if rootPart then
        rootPart.Anchored = enable
    else
        debug("Missing HumanoidRootPart!")
    end
    
    return true
end

-- Camera movement logic
local function updateFreeCam(dt)
    local moveVector = Vector3.new()
    
    -- Movement inputs
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector += Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector -= Vector3.new(0,1,0) end
    
    -- Apply movement
    cameraCFrame = cameraCFrame + (moveVector * FREE_CAM_SPEED * dt)
    
    -- Mouse look
    local delta = UserInputService:GetMouseDelta()
    lookX = lookX - delta.X * ROTATION_SENSITIVITY
    lookY = math.clamp(lookY - delta.Y * ROTATION_SENSITIVITY, -89, 89)
    
    -- Update camera
    Camera.CFrame = cameraCFrame * CFrame.Angles(math.rad(lookY), math.rad(lookX), 0)
end

-- Toggle with Ctrl+8 (fixed and debugged)
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Eight 
       and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) 
       or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) 
       and not processed then
        
        freeCamEnabled = not freeCamEnabled
        debug("Toggling FreeCam: " .. tostring(freeCamEnabled))
        
        if freeCamEnabled then
            if not Player.Character then
                debug("No character found!")
                return
            end
            
            originalCameraType = Camera.CameraType
            originalWalkSpeed = Player.Character.Humanoid.WalkSpeed
            Camera.CameraType = Enum.CameraType.Scriptable
            cameraCFrame = Camera.CFrame
            lookX, lookY = 0, 0
            
            if anchorCharacter(true) then
                debug("FreeCam activated!")
                RunService:BindToRenderStep("FreeCamera", Enum.RenderPriority.Camera.Value, function(dt)
                    updateFreeCam(dt)
                end)
            end
        else
            RunService:UnbindFromRenderStep("FreeCamera")
            Camera.CameraType = originalCameraType
            anchorCharacter(false)
            debug("FreeCam deactivated!")
        end
    end
end)

-- Cleanup
Player.CharacterAdded:Connect(function()
    if freeCamEnabled then
        RunService:UnbindFromRenderStep("FreeCamera")
        Camera.CameraType = originalCameraType
        anchorCharacter(false)
        freeCamEnabled = false
        debug("Reset after respawn")
    end
end)
