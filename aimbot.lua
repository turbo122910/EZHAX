-- LocalScript (Place in StarterPlayerScripts)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local lockedTarget = nil
local CONE_ANGLE = math.rad(30) -- 30-degree cone

local function isInCone(targetPos)
    local cameraCF = camera.CFrame
    local directionToTarget = (targetPos - cameraCF.Position).Unit
    return cameraCF.LookVector:Dot(directionToTarget) > math.cos(CONE_ANGLE)
end

local function findTargetInCone()
    local closest = nil
    local closestDist = math.huge
    local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Team ~= player.Team then
            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if tRoot and isInCone(tRoot.Position) then
                local dist = (tRoot.Position - localRoot.Position).Magnitude
                if dist < closestDist then
                    closest = tChar
                    closestDist = dist
                end
            end
        end
    end
    return closest
end

local function emulateClick()
    -- WARNING: This is detectable and violates TOS
    local VirtualUser = game:GetService("VirtualUser")
    VirtualUser:ClickButton1(Vector2.new())
end

local function updateLock()
    if not lockedTarget then return end
    
    local head = lockedTarget:FindFirstChild("Head")
    if not head then return end
    
    -- Smooth tracking
    camera.CFrame = camera.CFrame:Lerp(
        CFrame.new(camera.CFrame.Position, head.Position),
        0.25
    )
    
    -- Auto-click
    emulateClick()
end

UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and not processed then
        lockedTarget = findTargetInCone()
        if lockedTarget then
            RunService:BindToRenderStep("AimLock", Enum.RenderPriority.Camera.Value, function()
                updateLock()
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RunService:UnbindFromRenderStep("AimLock")
        lockedTarget = nil
    end
end)

-- Cleanup
player.CharacterAdded:Connect(function()
    RunService:UnbindFromRenderStep("AimLock")
    lockedTarget = nil
end)
