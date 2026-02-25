-- ============================================================
--   KAIM v2.0  |  WindUI Edition
--   Advanced Aimlock & Combat Hub
-- ============================================================

-- Load WindUI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services & Variables
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui       = game:GetService("CoreGui")
local LocalPlayer   = Players.LocalPlayer
local Camera        = workspace.CurrentCamera

-- ============================================================
--  SCRIPT SETTINGS
-- ============================================================
local Settings = {
    Aimlock = {
        Enabled         = false,
        Prediction      = 0.135,
        TargetPart      = "HumanoidRootPart",
        AimMode         = "Head",
        IsAiming        = false,
        CurrentTarget   = nil,
        WallCheck       = true,
        TeamCheck       = true,
        SilentAim       = false,
        AutoTrigger     = false,
        FlickShots      = false,
        FlickCooldown   = 0,
        SmoothAiming    = false,
        SmoothSpeed     = 0.3,
        StrafePrediction = 1.0,
        AntiAim         = false,
        RandomJitter    = false,
        JitterAmount    = 0.05,
        PeriodicDisable  = false,
        DisableInterval  = 0,
        Keybind         = "RightClick",
    },

    FOV = {
        Visible = true,
        Radius  = 150,
        Color   = Color3.fromRGB(255, 255, 255),
        Transparency = 0.8,
    },

    Visuals = {
        TeamCheck       = true,
        ESPEnabled      = false,
        ESPBoxes        = true,
        ESPNames        = true,
        ShowTeammates   = false,
        TeammateColor   = Color3.fromRGB(0, 255, 255),
        DistanceDisplay = false,
        HealthNumbers   = false,
        UseVisColors    = true,
        VisColor        = Color3.fromRGB(50, 255, 50),
        HiddenColor     = Color3.fromRGB(255, 50, 50),
        ChamsEnabled        = false,
        ChamsFillColor      = Color3.fromRGB(255, 0, 0),
        ChamsOutlineColor   = Color3.fromRGB(255, 255, 255),
        TracerLines     = false,
        TracerColor     = Color3.fromRGB(0, 255, 255),
        SnapLines       = false,
        SnapLineColor   = Color3.fromRGB(255, 0, 255),
        TargetUI        = true,
    },

    Player = {
        WalkSpeedEnabled = false,
        WalkSpeed        = 16,
        JumpPowerEnabled = false,
        JumpPower        = 50,
        NoclipEnabled    = false,
    },

    DetectionAvoidance = {
        RandomJitter            = false,
        AimSmoothingAnimation   = true,
        PeriodicAimDisable      = false,
        DisableChance           = 0.1,
        DisableDuration         = 0.2,
    },

    Notifications = {
        Enabled         = true,
        ShowKills       = true,
        ShowHeadshots   = true,
    },
}

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing = Drawing.new("Circle")
FOVRing.Visible      = false
FOVRing.Thickness    = 1.5
FOVRing.Transparency = Settings.FOV.Transparency
FOVRing.Color        = Settings.FOV.Color
FOVRing.Filled       = false

local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name   = "KaimChams"
ChamsFolder.Parent = CoreGui

local TracerLines = {}

-- Target UI - Enhanced HUD
local TargetGui   = Instance.new("ScreenGui", CoreGui)
TargetGui.Name = "TargetHUD"
TargetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local TargetFrame = Instance.new("Frame", TargetGui)
TargetFrame.Name = "TargetCard"
TargetFrame.Size              = UDim2.new(0, 300, 0, 120)
TargetFrame.Position          = UDim2.new(0.5, -150, 0.65, 0)
TargetFrame.BackgroundColor3  = Color3.fromRGB(20, 20, 28)
TargetFrame.BackgroundTransparency = 0.15
TargetFrame.Visible           = false
TargetFrame.BorderSizePixel   = 0

-- Corner and border styling
local Corner = Instance.new("UICorner", TargetFrame)
Corner.CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke", TargetFrame)
Stroke.Color        = Color3.fromRGB(100, 200, 255)
Stroke.Thickness    = 2
Stroke.Transparency = 0.3

-- Target name label
local NameLabel = Instance.new("TextLabel", TargetFrame)
NameLabel.Name = "PlayerName"
NameLabel.Size               = UDim2.new(1, -20, 0, 30)
NameLabel.Position           = UDim2.new(0, 10, 0, 10)
NameLabel.BackgroundTransparency = 1
NameLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
NameLabel.TextXAlignment     = Enum.TextXAlignment.Left
NameLabel.TextYAlignment     = Enum.TextYAlignment.Center
NameLabel.Font               = Enum.Font.GothamBold
NameLabel.TextSize           = 18
NameLabel.Text               = "Player"

-- Status indicator (locked/in range)
local StatusIndicator = Instance.new("Frame", TargetFrame)
StatusIndicator.Name = "StatusDot"
StatusIndicator.Size = UDim2.new(0, 8, 0, 8)
StatusIndicator.Position = UDim2.new(1, -25, 0, 16)
StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
StatusIndicator.BorderSizePixel = 0
Instance.new("UICorner", StatusIndicator).CornerRadius = UDim.new(1, 0)

-- Health text (HP number)
local HealthText = Instance.new("TextLabel", TargetFrame)
HealthText.Name = "HealthText"
HealthText.Size = UDim2.new(0, 100, 0, 20)
HealthText.Position = UDim2.new(1, -110, 0, 10)
HealthText.BackgroundTransparency = 1
HealthText.TextColor3 = Color3.fromRGB(100, 200, 255)
HealthText.TextXAlignment = Enum.TextXAlignment.Right
HealthText.Font = Enum.Font.GothamSemibold
HealthText.TextSize = 13
HealthText.Text = "HP: 100/100"

-- Distance display
local DistanceText = Instance.new("TextLabel", TargetFrame)
DistanceText.Name = "Distance"
DistanceText.Size = UDim2.new(0, 100, 0, 20)
DistanceText.Position = UDim2.new(1, -110, 0, 35)
DistanceText.BackgroundTransparency = 1
DistanceText.TextColor3 = Color3.fromRGB(150, 150, 150)
DistanceText.TextXAlignment = Enum.TextXAlignment.Right
DistanceText.Font = Enum.Font.Gotham
DistanceText.TextSize = 12
DistanceText.Text = "Distance: 0m"

-- Health bar background
local HealthBarBG = Instance.new("Frame", TargetFrame)
HealthBarBG.Name = "HealthBarBG"
HealthBarBG.Size             = UDim2.new(1, -20, 0, 15)
HealthBarBG.Position         = UDim2.new(0, 10, 0, 65)
HealthBarBG.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
HealthBarBG.BorderSizePixel  = 0
Instance.new("UICorner", HealthBarBG).CornerRadius = UDim.new(0, 4)

-- Health bar fill
local HealthBarFill = Instance.new("Frame", HealthBarBG)
HealthBarFill.Name = "HealthFill"
HealthBarFill.Size           = UDim2.new(0.5, 0, 1, 0)
HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
HealthBarFill.BorderSizePixel = 0
Instance.new("UICorner", HealthBarFill).CornerRadius = UDim.new(0, 3)

-- Health bar outline
local HealthStroke = Instance.new("UIStroke", HealthBarBG)
HealthStroke.Color = Color3.fromRGB(0, 255, 100)
HealthStroke.Thickness = 1
HealthStroke.Transparency = 0.5

-- ============================================================
--  WINDUI WINDOW SETUP
-- ============================================================
local Window = WindUI:CreateWindow({
    Title = "KAIM v2.0",
    Icon = "crosshair",
    Author = "by FRK",
    Folder = "Kaim",
    Size = UDim2.fromOffset(600, 500),
    Transparent = false,
    Theme = "Dark",
    Resizable = true,
})

Window:SetToggleKey(Enum.KeyCode.K)

local AimlockTab = Window:Tab({Title = "Aimlock", Icon = "crosshair"})
local ESPTab = Window:Tab({Title = "ESP", Icon = "eye"})
local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local VisualsTab = Window:Tab({Title = "Visuals", Icon = "palette"})
local SettingsTab = Window:Tab({Title = "Settings", Icon = "settings"})

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================
local function IsTeammate(player)
    if not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function IsVisible(targetPart, targetChar)
    local origin    = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local params    = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    params.FilterType  = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

local function IsTargetValid(player)
    if not player or not player.Character then return false end
    if Settings.Aimlock.TeamCheck and IsTeammate(player) then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local targetPart = player.Character:FindFirstChild(Settings.Aimlock.TargetPart)
    
    if not humanoid or not targetPart or humanoid.Health <= 0 then return false end
    if Settings.Aimlock.WallCheck and not IsVisible(targetPart, player.Character) then return false end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    return onScreen
end

-- Check if target is alive (for sticky lock - stays locked regardless of walls/visibility)
local function IsTargetAlive(player)
    if not player or not player.Character then return false end
    if Settings.Aimlock.TeamCheck and IsTeammate(player) then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local targetPart = player.Character:FindFirstChild(Settings.Aimlock.TargetPart)
    
    if not humanoid or not targetPart or humanoid.Health <= 0 then return false end
    return true
end

local function GetAimPart(character)
    if Settings.Aimlock.AimMode == "Head" then
        return character:FindFirstChild("Head")
    elseif Settings.Aimlock.AimMode == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif Settings.Aimlock.AimMode == "Limbs" then
        local limbs = {character:FindFirstChild("LeftUpperArm"), character:FindFirstChild("RightUpperArm")}
        return limbs[math.random(1, 2)]
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function AddJitter(position)
    if Settings.DetectionAvoidance.RandomJitter then
        local jitter = Settings.Aimlock.JitterAmount
        return position + Vector3.new(
            (math.random() - 0.5) * jitter * 2,
            (math.random() - 0.5) * jitter * 2,
            (math.random() - 0.5) * jitter * 2
        )
    end
    return position
end

local function SmoothAim(currentCFrame, targetCFrame, speed)
    if not Settings.Aimlock.SmoothAiming then return targetCFrame end
    return currentCFrame:Lerp(targetCFrame, speed or Settings.Aimlock.SmoothSpeed)
end

function GetClosestPlayer()
    local closestDistance = Settings.FOV.Radius
    local closestTarget   = nil
    local screenCenter    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsTargetValid(player) then
            local targetPart = player.Character[Settings.Aimlock.TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            local distance = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestTarget   = player
            end
        end
    end
    return closestTarget
end

-- ============================================================
--  ESP ENGINE
-- ============================================================
local ESPObjects = {}

local function CreateESP(player)
    local esp = {
        Box       = Drawing.new("Square"),
        Name      = Drawing.new("Text"),
        Health    = Drawing.new("Text"),
        Highlight = Instance.new("Highlight"),
    }

    esp.Box.Visible      = false
    esp.Box.Thickness    = 1.2
    esp.Box.Transparency = 1
    esp.Box.Filled       = false

    esp.Name.Visible  = false
    esp.Name.Size     = 16
    esp.Name.Center   = true
    esp.Name.Outline  = true

    esp.Health.Visible = false
    esp.Health.Size    = 14
    esp.Health.Center  = true
    esp.Health.Outline = true

    esp.Highlight.Parent    = ChamsFolder
    esp.Highlight.Enabled   = false
    esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    ESPObjects[player] = esp
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(player) CreateESP(player) end)
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        ESPObjects[player].Box:Remove()
        ESPObjects[player].Name:Remove()
        ESPObjects[player].Health:Remove()
        ESPObjects[player].Highlight:Destroy()
        ESPObjects[player] = nil
    end
end)

-- ============================================================
--  WINDUI ELEMENTS - AIMLOCK TAB
-- ============================================================
local AimlockSection = AimlockTab:Section({Title = "Aimlock Control", Opened = true})

AimlockSection:Toggle({
    Title = "Enable Aimlock",
    Desc = "Master toggle for aimlock",
    Callback = function(v) Settings.Aimlock.Enabled = v end
})

AimlockSection:Keybind({
    Title = "Aimlock Key",
    Desc = "Press to aim lock",
    Value = "RightClick",
    Callback = function(v) Settings.Aimlock.Keybind = v end
})

AimlockSection:Toggle({
    Title = "Wall Check",
    Desc = "Skip targets behind walls",
    Value = true,
    Callback = function(v) Settings.Aimlock.WallCheck = v end
})

AimlockSection:Toggle({
    Title = "Team Check",
    Desc = "Skip teammates",
    Value = true,
    Callback = function(v) Settings.Aimlock.TeamCheck = v end
})

local AimTuningSection = AimlockTab:Section({Title = "Aim Tuning", Opened = true})

AimTuningSection:Slider({
    Title = "Prediction",
    Desc = "Lead time in seconds",
    Step = 0.005,
    Value = {Min = 0, Max = 0.2, Default = 0.135},
    Callback = function(v) Settings.Aimlock.Prediction = v end
})

AimTuningSection:Dropdown({
    Title = "Aim Mode",
    Desc = "Target part to aim at",
    Values = {"Head", "Torso", "Limbs"},
    Value = "Head",
    Callback = function(v) Settings.Aimlock.AimMode = v end
})

AimTuningSection:Slider({
    Title = "Strafe Prediction",
    Desc = "Velocity multiplier",
    Step = 0.1,
    Value = {Min = 0.5, Max = 2, Default = 1.0},
    Callback = function(v) Settings.Aimlock.StrafePrediction = v end
})

local AdvancedAimSection = AimlockTab:Section({Title = "Advanced Aim", Opened = false})

AdvancedAimSection:Toggle({
    Title = "Smooth Aiming",
    Desc = "Lerp camera to target",
    Callback = function(v) Settings.Aimlock.SmoothAiming = v end
})

AdvancedAimSection:Slider({
    Title = "Smooth Speed",
    Desc = "Lerp factor",
    Step = 0.05,
    Value = {Min = 0.1, Max = 1, Default = 0.3},
    Callback = function(v) Settings.Aimlock.SmoothSpeed = v end
})

AdvancedAimSection:Toggle({
    Title = "Silent Aim",
    Callback = function(v) Settings.Aimlock.SilentAim = v end
})

AdvancedAimSection:Toggle({
    Title = "Auto Trigger",
    Callback = function(v) Settings.Aimlock.AutoTrigger = v end
})

-- ============================================================
--  WINDUI ELEMENTS - ESP TAB
-- ============================================================
local ESPSection = ESPTab:Section({Title = "2D ESP", Opened = true})

ESPSection:Toggle({
    Title = "Enable ESP",
    Desc = "Show player boxes",
    Callback = function(v) Settings.Visuals.ESPEnabled = v end
})

ESPSection:Toggle({
    Title = "Team Check",
    Desc = "Skip teammates",
    Value = true,
    Callback = function(v) Settings.Visuals.TeamCheck = v end
})

ESPSection:Toggle({
    Title = "Show Teammates",
    Desc = "Show teammates with color",
    Value = false,
    Callback = function(v) Settings.Visuals.ShowTeammates = v end
})

ESPSection:Colorpicker({
    Title = "Teammate Color",
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(v) Settings.Visuals.TeammateColor = v end
})

ESPSection:Toggle({
    Title = "Use Visibility Colors",
    Desc = "Different colors for visible/hidden",
    Value = true,
    Callback = function(v) Settings.Visuals.UseVisColors = v end
})

ESPSection:Toggle({
    Title = "Distance Display",
    Callback = function(v) Settings.Visuals.DistanceDisplay = v end
})

ESPSection:Toggle({
    Title = "Health Numbers",
    Callback = function(v) Settings.Visuals.HealthNumbers = v end
})

local ChamsSection = ESPTab:Section({Title = "Chams", Opened = false})

ChamsSection:Toggle({
    Title = "Enable Chams",
    Callback = function(v) Settings.Visuals.ChamsEnabled = v end
})

ChamsSection:Colorpicker({
    Title = "Fill Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(v) Settings.Visuals.ChamsFillColor = v end
})

ChamsSection:Colorpicker({
    Title = "Outline Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) Settings.Visuals.ChamsOutlineColor = v end
})

local LinesSection = ESPTab:Section({Title = "Lines", Opened = false})

LinesSection:Toggle({
    Title = "Tracer Lines",
    Callback = function(v) Settings.Visuals.TracerLines = v end
})

LinesSection:Toggle({
    Title = "Snap Lines",
    Callback = function(v) Settings.Visuals.SnapLines = v end
})

-- ============================================================
--  WINDUI ELEMENTS - PLAYER TAB
-- ============================================================
local SpeedSection = PlayerTab:Section({Title = "Walk Speed", Opened = true})

SpeedSection:Toggle({
    Title = "Enable Walk Speed",
    Callback = function(v) Settings.Player.WalkSpeedEnabled = v end
})

SpeedSection:Slider({
    Title = "Walk Speed",
    Step = 1,
    Value = {Min = 5, Max = 100, Default = 16},
    Callback = function(v) Settings.Player.WalkSpeed = v end
})

local JumpSection = PlayerTab:Section({Title = "Jump Power", Opened = true})

JumpSection:Toggle({
    Title = "Enable Jump Power",
    Callback = function(v) Settings.Player.JumpPowerEnabled = v end
})

JumpSection:Slider({
    Title = "Jump Power",
    Step = 5,
    Value = {Min = 10, Max = 200, Default = 50},
    Callback = function(v) Settings.Player.JumpPower = v end
})

local NoclipSection = PlayerTab:Section({Title = "Noclip", Opened = true})

NoclipSection:Toggle({
    Title = "Enable Noclip",
    Callback = function(v) Settings.Player.NoclipEnabled = v end
})

-- ============================================================
--  WINDUI ELEMENTS - VISUALS TAB
-- ============================================================
local FOVSection = VisualsTab:Section({Title = "FOV Circle", Opened = true})

FOVSection:Toggle({
    Title = "Show FOV Circle",
    Value = true,
    Callback = function(v) Settings.FOV.Visible = v end
})

FOVSection:Slider({
    Title = "FOV Radius",
    Step = 10,
    Value = {Min = 50, Max = 500, Default = 150},
    Callback = function(v) Settings.FOV.Radius = v end
})

FOVSection:Slider({
    Title = "FOV Transparency",
    Step = 0.1,
    Value = {Min = 0, Max = 1, Default = 0.8},
    Callback = function(v) Settings.FOV.Transparency = v; FOVRing.Transparency = v end
})

FOVSection:Colorpicker({
    Title = "FOV Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) Settings.FOV.Color = v; FOVRing.Color = v end
})

-- ============================================================
--  WINDUI ELEMENTS - SETTINGS TAB
-- ============================================================
local ThemeSection = SettingsTab:Section({Title = "Theme", Opened = true})

ThemeSection:Button({
    Title = "Dark Theme",
    Callback = function() Window.Theme = "Dark" end
})

ThemeSection:Button({
    Title = "Light Theme",
    Callback = function() Window.Theme = "Light" end
})

local InfoSection = SettingsTab:Section({Title = "Information", Opened = true})

InfoSection:Paragraph({
    Title = "KAIM v2.0",
    Desc = "Advanced Aimlock & Combat Hub",
    Image = "crosshair"
})

InfoSection:Paragraph({
    Title = "Features",
    Desc = "✓ Smooth Aimlock\n✓ 2D ESP Box\n✓ Chams\n✓ Player Mods\n✓ Custom Crosshair"
})

-- ============================================================
--  MAIN RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()

    -- FOV Circle
    FOVRing.Position = mousePos
    FOVRing.Radius   = Settings.FOV.Radius
    FOVRing.Visible  = Settings.FOV.Visible
    FOVRing.Transparency = Settings.FOV.Transparency

    -- Periodic aim disable
    if Settings.DetectionAvoidance.PeriodicAimDisable and Settings.Aimlock.Enabled then
        Settings.Aimlock.PeriodicDisable = math.random() < Settings.DetectionAvoidance.DisableChance
    end

    -- Aimlock logic
    if Settings.Aimlock.Enabled and Settings.Aimlock.IsAiming then
        if not Settings.Aimlock.CurrentTarget or not IsTargetAlive(Settings.Aimlock.CurrentTarget) then
            Settings.Aimlock.CurrentTarget = GetClosestPlayer()
        end
    end

    if Settings.Aimlock.Enabled and Settings.Aimlock.IsAiming and Settings.Aimlock.CurrentTarget and not Settings.Aimlock.PeriodicDisable then
        local targetChar = Settings.Aimlock.CurrentTarget.Character
        if targetChar then
            local targetPart = GetAimPart(targetChar) or targetChar:FindFirstChild(Settings.Aimlock.TargetPart)
            local humanoid   = targetChar:FindFirstChild("Humanoid")

            if targetPart and humanoid and humanoid.Health > 0 then
                local strateVelocity     = targetPart.Velocity * Settings.Aimlock.StrafePrediction
                local predictedPosition  = targetPart.Position + (strateVelocity * Settings.Aimlock.Prediction)
                predictedPosition        = AddJitter(predictedPosition)

                local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
                if Settings.Aimlock.SmoothAiming then
                    Camera.CFrame = SmoothAim(Camera.CFrame, targetCFrame)
                else
                    Camera.CFrame = targetCFrame
                end

                TargetFrame.Visible     = true
                NameLabel.Text          = Settings.Aimlock.CurrentTarget.DisplayName
                
                -- Update health bar and text
                local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                HealthBarFill.Size      = UDim2.new(healthPercent, 0, 1, 0)
                HealthText.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                
                -- Update health bar color based on health percentage
                if healthPercent > 0.6 then
                    HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                    HealthStroke.Color = Color3.fromRGB(0, 255, 100)
                elseif healthPercent > 0.3 then
                    HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                    HealthStroke.Color = Color3.fromRGB(255, 200, 0)
                else
                    HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                    HealthStroke.Color = Color3.fromRGB(255, 50, 50)
                end
                
                -- Update distance
                local targetRootPart = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRootPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, targetRootPart.Position)
                    DistanceText.Text = "Distance: " .. math.floor(distance) .. "m"
                end
            else
                Settings.Aimlock.CurrentTarget = nil
                TargetFrame.Visible = false
            end
        else
            Settings.Aimlock.CurrentTarget = nil
            TargetFrame.Visible = false
        end
    else
        TargetFrame.Visible = false
    end

    -- Player modifications
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and humanoidRootPart then
            if Settings.Player.WalkSpeedEnabled then
                humanoid.WalkSpeed = Settings.Player.WalkSpeed
            end
            
            if Settings.Player.JumpPowerEnabled then
                humanoid.JumpPower = Settings.Player.JumpPower
            end
        end
        
        if Settings.Player.NoclipEnabled then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end

    -- Tracer lines
    if Settings.Visuals.TracerLines then
        for player, esp in pairs(ESPObjects) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not IsTeammate(player) then
                if not TracerLines[player] then
                    TracerLines[player] = Drawing.new("Line")
                end
                local line        = TracerLines[player]
                local targetPos   = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                line.From         = screenCenter
                line.To           = Vector2.new(targetPos.X, targetPos.Y)
                line.Color        = Settings.Visuals.TracerColor
                line.Thickness    = 1
                line.Visible      = targetPos.Z > 0
            end
        end
    else
        for player, line in pairs(TracerLines) do
            line:Remove()
            TracerLines[player] = nil
        end
    end

    -- ESP logic
    for player, esp in pairs(ESPObjects) do
        local hasCharacter = player.Character
            and player.Character:FindFirstChild("HumanoidRootPart")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
        local isTeammate = IsTeammate(player)

        if Settings.Visuals.ChamsEnabled and hasCharacter and not (Settings.Visuals.TeamCheck and isTeammate) then
            esp.Highlight.Adornee      = player.Character
            esp.Highlight.Enabled      = true
            esp.Highlight.FillColor    = Settings.Visuals.ChamsFillColor
            esp.Highlight.OutlineColor = Settings.Visuals.ChamsOutlineColor
        else
            esp.Highlight.Enabled  = false
            esp.Highlight.Adornee  = nil
        end

        if Settings.Visuals.ESPEnabled and hasCharacter and not (Settings.Visuals.TeamCheck and isTeammate) then
            local rootPart = player.Character.HumanoidRootPart
            local head     = player.Character:FindFirstChild("Head")

            if head then
                local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

                if onScreen then
                    local isVisible = IsVisible(rootPart, player.Character)
                    local espColor  = Color3.fromRGB(255, 255, 255)

                    -- Determine color based on teammate or visibility
                    if isTeammate and Settings.Visuals.ShowTeammates then
                        espColor = Settings.Visuals.TeammateColor
                    elseif Settings.Visuals.UseVisColors then
                        espColor = isVisible and Settings.Visuals.VisColor or Settings.Visuals.HiddenColor
                    end

                    esp.Box.Color  = espColor
                    esp.Name.Color = espColor

                    local headPos   = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local legPos    = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                    local boxHeight = math.abs(headPos.Y - legPos.Y)
                    local boxWidth  = boxHeight * 0.6

                    if Settings.Visuals.ESPBoxes then
                        esp.Box.Visible  = true
                        esp.Box.Size     = Vector2.new(boxWidth, boxHeight)
                        esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y)
                    else
                        esp.Box.Visible = false
                    end

                    if Settings.Visuals.ESPNames then
                        local nameText = player.DisplayName
                        if Settings.Visuals.DistanceDisplay then
                            local distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, rootPart.Position)
                            nameText = nameText .. " [" .. math.floor(distance) .. "m]"
                        end
                        esp.Name.Visible   = true
                        esp.Name.Text      = nameText
                        esp.Name.Position  = Vector2.new(rootPos.X, headPos.Y - 20)
                    else
                        esp.Name.Visible = false
                    end

                    if Settings.Visuals.HealthNumbers then
                        local healthPercent = math.clamp(player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth, 0, 1)
                        local healthColor = Color3.fromRGB(255, 255, 255)
                        
                        if healthPercent > 0.6 then
                            healthColor = Color3.fromRGB(0, 255, 100)
                        elseif healthPercent > 0.3 then
                            healthColor = Color3.fromRGB(255, 200, 0)
                        else
                            healthColor = Color3.fromRGB(255, 50, 50)
                        end
                        
                        esp.Health.Visible = true
                        esp.Health.Text    = math.floor(player.Character.Humanoid.Health)
                        esp.Health.Color   = healthColor
                        esp.Health.Position = Vector2.new(rootPos.X - boxWidth / 2 - 30, headPos.Y + boxHeight / 2)
                    else
                        esp.Health.Visible = false
                    end

                    if Settings.Visuals.SnapLines then
                        if not esp.SnapLine then esp.SnapLine = Drawing.new("Line") end
                        local snapLine      = esp.SnapLine
                        local screenCenter  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        snapLine.From       = screenCenter
                        snapLine.To         = Vector2.new(rootPos.X, rootPos.Y)
                        snapLine.Color      = Settings.Visuals.SnapLineColor
                        snapLine.Thickness  = 1
                        snapLine.Visible    = true
                    elseif esp.SnapLine then
                        esp.SnapLine:Remove()
                        esp.SnapLine = nil
                    end
                else
                    esp.Box.Visible  = false
                    esp.Name.Visible = false
                end
            end
        else
            esp.Box.Visible  = false
            esp.Name.Visible = false
        end
    end
end)

-- Keybind handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local isAimKeyPressed = false
    
    if Settings.Aimlock.Keybind == "RightClick" then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isAimKeyPressed = true
        end
    else
        if input.KeyCode == Enum.KeyCode[Settings.Aimlock.Keybind] then
            isAimKeyPressed = true
        end
    end
    
    if isAimKeyPressed then
        Settings.Aimlock.IsAiming = true
        if Settings.Aimlock.Enabled then
            Settings.Aimlock.CurrentTarget = GetClosestPlayer()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    local isAimKeyReleased = false
    
    if Settings.Aimlock.Keybind == "RightClick" then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isAimKeyReleased = true
        end
    else
        if input.KeyCode == Enum.KeyCode[Settings.Aimlock.Keybind] then
            isAimKeyReleased = true
        end
    end
    
    if isAimKeyReleased then
        Settings.Aimlock.IsAiming = false
        Settings.Aimlock.CurrentTarget = nil
    end
end)

print("✓ KAIM v2.0 (WindUI) loaded successfully! Press K to toggle UI.")
