-- Create fullscreen text display
local txt = Drawing.new("Text")
txt.Text = "HAX SUITE"
txt.Size = 150
txt.Color = Color3.new(9,9,0)
txt.Transparency = 1
txt.Visible = true
txt.Center = true
txt.Position = workspace.CurrentCamera.ViewportSize / 2
txt.Font = Drawing.Fonts.UI

-- Remove text after 10 seconds
task.spawn(function()
    task.wait(15)
    txt:Remove()
end)

-- Load hacks after initial display
local ToggleHealthURL = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/ToggleHealth.lua"
local ToggleESPURL = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/ToggleESP.lua"
local AimlockURL = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/aimlock.lua"
local FreeCamURL = "https://raw.githubusercontent.com/turbo122910/EZHAX/main/FreeCam.lua"
local function LoadScript(url)
    pcall(function()
        loadstring(game:HttpGet(url))()
    end)
end

LoadScript(ToggleHealthURL)
LoadScript(ToggleESPURL)
LoadScript(AimlockURL)
LoadScript(FreeCamURL)

print("EZHAX Suite Loaded - Cheats activated!")
