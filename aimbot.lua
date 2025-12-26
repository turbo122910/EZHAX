-- LocalPlayer and services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local LOCK_RANGE = 50  -- Max distance to lock onto players
local LOCK_ANGLE = 30  -- Degrees (cone angle)
local LOCK_SMOOTHNESS = 0.3  -- Smoothing factor for cursor movement (0-1, lower = smoother)

-- State variables
local isLocking = false
local currentTarget = nil
local mouse = LocalPlayer:GetMouse()
local lockedIndicator = nil
local lockSound = nil

-- Check if target is from a different team
local function isEnemyPlayer(player)
    -- Check if both players have teams
    if LocalPlayer.Team and player.Team then
        -- Different teams = enemy
        return LocalPlayer.Team ~= player.Team
    end
    
    -- If no teams system or one player has no team, treat as enemy
    -- You can change this behavior based on your game
    return true
end

-- Convert degrees to radians
local function toRadians(degrees)
	return math.rad(degrees)
end

-- Check if a target is within the cone
local function isInCone(cameraCF, targetPosition)
	-- Get camera position and look direction
	local cameraPos = cameraCF.Position
	local cameraLook = cameraCF.LookVector
	
	-- Calculate vector to target
	local toTarget = (targetPosition - cameraPos).Unit
	
	-- Calculate angle between camera look direction and target direction
	local dot = cameraLook:Dot(toTarget)
	local angle = math.deg(math.acos(dot))
	
	return angle <= LOCK_ANGLE / 2
end

-- Create visual lock indicator
local function createLockIndicator()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TargetLockIndicator"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main lock frame (centered on target)
    local lockFrame = Instance.new("Frame")
    lockFrame.Name = "LockFrame"
    lockFrame.Size = UDim2.new(0, 80, 0, 80)
    lockFrame.Position = UDim2.new(0.5, -40, 0.5, -40)
    lockFrame.BackgroundTransparency = 1
    lockFrame.Visible = false
    
    -- Outer circle
    local outerCircle = Instance.new("ImageLabel")
    outerCircle.Name = "OuterCircle"
    outerCircle.Size = UDim2.new(1, 0, 1, 0)
    outerCircle.BackgroundTransparency = 1
    outerCircle.Image = "rbxassetid://3570695787"  -- Simple circle
    outerCircle.ImageColor3 = Color3.fromRGB(255, 50, 50)  -- Red
    outerCircle.ImageTransparency = 0.3
    outerCircle.Parent = lockFrame
    
    -- Inner target
    local innerTarget = Instance.new("ImageLabel")
    innerTarget.Name = "InnerTarget"
    innerTarget.Size = UDim2.new(0.6, 0, 0.6, 0)
    innerTarget.Position = UDim2.new(0.2, 0, 0.2, 0)
    innerTarget.BackgroundTransparency = 1
    innerTarget.Image = "rbxassetid://3570695787"  -- Simple circle
    innerTarget.ImageColor3 = Color3.fromRGB(255, 0, 0)  -- Bright red
    innerTarget.ImageTransparency = 0.1
    innerTarget.Parent = lockFrame
    
    -- Target name display
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "TargetName"
    nameLabel.Size = UDim2.new(2, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(-0.5, 0, 1.2, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = ""
    nameLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 18
    nameLabel.Parent = lockFrame
    
    -- Distance display
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "TargetDistance"
    distanceLabel.Size = UDim2.new(2, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(-0.5, 0, 1.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = ""
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Font = Enum.Font.SourceSans
    distanceLabel.TextSize = 14
    distanceLabel.Parent = lockFrame
    
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return lockFrame
end

-- Create lock sound
local function createLockSound()
    local sound = Instance.new("Sound")
    sound.Name = "TargetLockSound"
    sound.SoundId = "rbxassetid://911846333"  -- Beep sound, change to your preferred sound
    sound.Volume = 0.5
    sound.Parent = workspace
    return sound
end

-- Update lock indicator position and info
local function updateLockIndicator(target, distance)
    if not lockedIndicator then
        lockedIndicator = createLockIndicator()
    end
    
    if target and lockedIndicator then
        local camera = workspace.CurrentCamera
        if camera then
            local aimPosition = getTargetAimPosition(target)
            if aimPosition then
                local screenPos, onScreen = camera:WorldToScreenPoint(aimPosition)
                if onScreen then
                    -- Update position
                    lockedIndicator.Position = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y - 40)
                    lockedIndicator.Visible = true
                    
                    -- Update target info
                    lockedIndicator.TargetName.Text = target.Name
                    lockedIndicator.TargetDistance.Text = "Distance: " .. math.floor(distance) .. " studs"
                    
                    -- Pulse animation
                    local outer = lockedIndicator.OuterCircle
                    local inner = lockedIndicator.InnerTarget
                    
                    spawn(function()
                        for i = 1, 0, -0.1 do
                            outer.ImageTransparency = 0.3 + (0.7 * i)
                            inner.ImageTransparency = 0.1 + (0.9 * i)
                            wait(0.05)
                        end
                    end)
                    
                    return
                end
            end
        end
    end
    
    -- Hide indicator if no valid target
    if lockedIndicator then
        lockedIndicator.Visible = false
    end
end

-- Find the best target within the cone (prioritizes closest enemies)
local function findBestTarget()
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	
	local cameraCF = camera.CFrame
	local cameraPos = cameraCF.Position
	local bestTarget = nil
	local bestScore = math.huge  -- Lower score is better
	
	-- Check all players
	for _, player in pairs(Players:GetPlayers()) do
		-- Skip local player, players without character, and teammates
		if player ~= LocalPlayer and player.Character and isEnemyPlayer(player) then
            -- Check if enemy is alive
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local targetPos = humanoidRootPart.Position
                    local distance = (targetPos - cameraPos).Magnitude
                    
                    -- Check if within range and cone
                    if distance <= LOCK_RANGE and isInCone(cameraCF, targetPos) then
                        -- Calculate screen position to check if target is visible
                        local screenPos, onScreen = camera:WorldToScreenPoint(targetPos)
                        
                        if onScreen then
                            -- Score based on distance and how centered the target is
                            -- Prioritize closest enemies (80% distance, 20% cursor distance)
                            local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                            local mousePos = Vector2.new(mouse.X, mouse.Y)
                            local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                            
                            -- Distance from cursor to target on screen
                            local cursorDistance = (mousePos - screenPoint).Magnitude
                            
                            -- Combined score: prioritize closer targets (80%) and those near cursor (20%)
                            local score = (distance * 0.8) + (cursorDistance * 0.2)
                            
                            if score < bestScore then
                                bestScore = score
                                bestTarget = player
                            end
                        end
                    end
                end
            end
		end
	end
	
	return bestTarget, bestScore
end

-- Get target's head position for aiming
local function getTargetAimPosition(target)
	if not target or not target.Character then return nil end
	
	-- Try to get head first, then humanoid root part
	local head = target.Character:FindFirstChild("Head")
	local humanoidRootPart = target.Character:FindFirstChild("HumanoidRootPart")
	
	if head then
		return head.Position
	elseif humanoidRootPart then
		return humanoidRootPart.Position + Vector3.new(0, 2, 0)  -- Approximate head height
	end
	
	return nil
end

-- Play lock sound
local function playLockSound()
    if not lockSound then
        lockSound = createLockSound()
    end
    
    if lockSound then
        lockSound:Play()
    end
end

-- Input handling
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isLocking = true
		local target, score = findBestTarget()
        currentTarget = target
        
        -- Visual and audio feedback
        if currentTarget then
            print("Locking onto enemy: " .. currentTarget.Name)
            playLockSound()
            
            -- Get distance for indicator
            local camera = workspace.CurrentCamera
            if camera and currentTarget.Character then
                local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = (hrp.Position - camera.CFrame.Position).Magnitude
                    updateLockIndicator(currentTarget, distance)
                end
            end
        end
	end
end

local function onInputEnded(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isLocking = false
        currentTarget = nil
        
        -- Hide lock indicator
        if lockedIndicator then
            lockedIndicator.Visible = false
        end
	end
end

-- Main update loop
local function updateLock()
	if not isLocking then return end
	
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	-- If we lost our target, try to find a new one
	if not currentTarget or not currentTarget.Character then
		local target, score = findBestTarget()
        currentTarget = target
        if not currentTarget then 
            if lockedIndicator then
                lockedIndicator.Visible = false
            end
            return 
        end
	end
	
	-- Double-check if target is still an enemy (in case team changed)
	if not isEnemyPlayer(currentTarget) then
		local target, score = findBestTarget()
        currentTarget = target
        if not currentTarget then 
            if lockedIndicator then
                lockedIndicator.Visible = false
            end
            return 
        end
	end
    
    -- Check if enemy is still alive
    local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        local target, score = findBestTarget()
        currentTarget = target
        if not currentTarget then 
            if lockedIndicator then
                lockedIndicator.Visible = false
            end
            return 
        end
    end
	
	local aimPosition = getTargetAimPosition(currentTarget)
	if not aimPosition then
		currentTarget = nil
        if lockedIndicator then
            lockedIndicator.Visible = false
        end
		return
	end
	
	-- Convert target position to screen space
	local screenPos, onScreen = camera:WorldToScreenPoint(aimPosition)
	
	if onScreen then
		-- Smoothly move the cursor toward the target
		local targetPos = Vector2.new(screenPos.X, screenPos.Y)
		local currentPos = Vector2.new(mouse.X, mouse.Y)
		local newPos = currentPos:Lerp(targetPos, LOCK_SMOOTHNESS)
		
		-- Move the cursor (this requires appropriate permissions)
		mousemoverel(newPos.X - currentPos.X, newPos.Y - currentPos.Y)
        
        -- Update lock indicator with distance
        local distance = (aimPosition - camera.CFrame.Position).Magnitude
        updateLockIndicator(currentTarget, distance)
	else
        -- Target not on screen, hide indicator
        if lockedIndicator then
            lockedIndicator.Visible = false
        end
    end
end

-- Debug visualization (optional - remove in production)
local function createConeVisualization()
	local conePart = Instance.new("Part")
	conePart.Name = "LockConeDebug"
	conePart.Anchored = true
	conePart.CanCollide = false
	conePart.Transparency = 0.7
	conePart.Color = Color3.fromRGB(255, 0, 0)  -- Red for enemy targeting
	conePart.Material = Enum.Material.Neon
	conePart.Size = Vector3.new(1, 1, LOCK_RANGE)
	conePart.Parent = workspace
	
	local weld = Instance.new("Weld")
	weld.Part0 = conePart
	weld.C0 = CFrame.Angles(-math.pi/2, 0, 0) * CFrame.new(0, 0, -LOCK_RANGE/2)
	
	return conePart, weld
end

-- Team change detection
local function setupTeamDetection()
    -- Update when player team changes
    LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        if isLocking and currentTarget then
            -- Check if current target is still an enemy
            if not isEnemyPlayer(currentTarget) then
                print("Team changed! Releasing lock on former teammate.")
                local target, score = findBestTarget()
                currentTarget = target
                
                if currentTarget then
                    print("New target: " .. currentTarget.Name)
                end
            end
        end
    end)
    
    -- Monitor other players' team changes
    Players.PlayerAdded:Connect(function(player)
        player:GetPropertyChangedSignal("Team"):Connect(function()
            if isLocking and currentTarget == player then
                if not isEnemyPlayer(player) then
                    print("Target changed teams! Finding new enemy...")
                    local target, score = findBestTarget()
                    currentTarget = target
                end
            end
        end)
    end)
end

-- Create HUD for lock status
local function createLockHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TargetLockHUD"
    screenGui.ResetOnSpawn = false
    
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(0, 250, 0, 60)
    statusFrame.Position = UDim2.new(0.5, -125, 0.02, 0)
    statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    statusFrame.BackgroundTransparency = 0.7
    statusFrame.BorderSizePixel = 2
    statusFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    statusFrame.Parent = screenGui
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "ENEMY TARGET LOCK"
    titleLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.Parent = statusFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0.6, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.4, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: READY | Hold RMB to lock"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 14
    statusLabel.Parent = statusFrame
    
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return statusLabel
end

-- Update HUD status
local hudStatus = nil
local function updateHUDStatus()
    if not hudStatus then
        hudStatus = createLockHUD()
    end
    
    if hudStatus then
        if isLocking then
            if currentTarget then
                local distance = 0
                if currentTarget.Character then
                    local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local camera = workspace.CurrentCamera
                        if camera then
                            distance = math.floor((hrp.Position - camera.CFrame.Position).Magnitude)
                        end
                    end
                end
                hudStatus.Text = "Status: LOCKED | Target: " .. currentTarget.Name .. " | Distance: " .. distance .. " studs"
                hudStatus.TextColor3 = Color3.fromRGB(255, 50, 50)
            else
                hudStatus.Text = "Status: SEARCHING | No enemies in range"
                hudStatus.TextColor3 = Color3.fromRGB(255, 150, 50)
            end
        else
            hudStatus.Text = "Status: READY | Hold RMB to lock onto enemies"
            hudStatus.TextColor3 = Color3.fromRGB(100, 200, 100)
        end
    end
end

-- Initialize
local function init()
    -- Connect input events
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)
    
    -- Start update loops
    RunService.RenderStepped:Connect(updateLock)
    RunService.RenderStepped:Connect(updateHUDStatus)
    
    -- Setup team detection
    setupTeamDetection()
    
    -- Optional: Create debug visualization
    local debugMode = false  -- Set to true for debugging
    if debugMode then
        local conePart, coneWeld = createConeVisualization()
        
        -- Update cone position to follow camera
        RunService.RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            if camera then
                conePart.CFrame = camera.CFrame
                coneWeld.Part1 = camera
            end
        end)
    end
    
    -- Create HUD
    updateHUDStatus()
    
    print("========================================")
    print("ENEMY TARGET LOCK SYSTEM INITIALIZED")
    print("========================================")
    print("Features:")
    print("- Only locks onto ENEMY players (different teams)")
    print("- Ignores teammates and dead players")
    print("- Visual lock indicator with target info")
    print("- Audio lock confirmation")
    print("- HUD status display")
    print("- Prioritizes closest enemies")
    print("")
    print("Controls: Hold RIGHT MOUSE BUTTON to lock")
    print("========================================")
end

-- Wait for player to load
if LocalPlayer.Character then
    init()
else
    LocalPlayer.CharacterAdded:Wait()
    init()
end
