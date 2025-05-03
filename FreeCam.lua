-- LocalScript (Changed toggle key to Ctrl+8)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local freeCamEnabled = false
local originalCameraType = Camera.CameraType
local originalWalkSpeed = 16

-- ... [rest of the original functions remain the same] ...

-- Changed toggle key to Ctrl+8 (main keyboard number 8)
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Eight and -- Changed from Enum.KeyCode.P
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or 
       UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and
       not processed then
        
        freeCamEnabled = not freeCamEnabled
        
        if freeCamEnabled then
            -- Enable free cam
            originalCameraType = Camera.CameraType
            originalWalkSpeed = Player.Character.Humanoid.WalkSpeed
            Camera.CameraType = Enum.CameraType.Scriptable
            anchorCharacter(true)
            
            -- Start update loop
            RunService:BindToRenderStep("FreeCamera", Enum.RenderPriority.Camera.Value, updateFreeCam)
        else
            -- Restore normal
            RunService:UnbindFromRenderStep("FreeCamera")
            Camera.CameraType = originalCameraType
            anchorCharacter(false)
        end
    end
end)
