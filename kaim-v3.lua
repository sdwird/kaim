-- ============================================================
--   KAIM v3.0  |  WindUI Edition
--   Advanced Aimlock & Combat Hub
-- ============================================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ============================================================
--  SETTINGS
-- ============================================================
local Settings = {
    Aimlock = {
        Enabled          = false,
        Prediction       = 0.135,
        TargetPart       = "HumanoidRootPart",
        AimMode          = "Head",
        IsAiming         = false,
        CurrentTarget    = nil,
        WallCheck        = true,
        TeamCheck        = true,
        SmoothAiming     = false,
        SmoothSpeed      = 0.3,
        StrafePrediction = 1.0,
        PeriodicDisable  = false,
        Keybind          = "RightClick",
    },
    FOV = {
        Visible      = true,
        Radius       = 150,
        Color        = Color3.fromRGB(255, 255, 255),
        Transparency = 0.8,
    },
    Visuals = {
        ESPEnabled      = false,
        ESPBoxes        = true,
        ESPNames        = true,
        ESPNameStyle    = "Display Name",
        ESPOutline      = true,
        ESPTextScale    = 14,        -- text scale (10–22)
        TeamCheck       = true,
        ShowTeammates   = false,
        TeammateColor   = Color3.fromRGB(0, 200, 255),
        UseVisColors    = true,
        VisColor        = Color3.fromRGB(50, 255, 80),
        HiddenColor     = Color3.fromRGB(255, 60, 60),
        DistanceDisplay = false,
        HealthNumbers   = false,
        ChamsEnabled      = false,
        ChamsFillColor    = Color3.fromRGB(255, 30, 30),
        ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
        ChamsDepth        = true,
        TracerLines   = false,
        TracerOrigin  = "Bottom",
        TracerColor   = Color3.fromRGB(0, 200, 255),
        SnapLines     = false,
        SnapLineColor = Color3.fromRGB(255, 0, 220),
        TargetUI       = true,
        HealthPosition = "TopRight",
    },
    Player = {
        WalkSpeedEnabled = false,
        WalkSpeed        = 16,
        JumpPowerEnabled = false,
        JumpPower        = 50,
        NoclipEnabled    = false,
    },
    DetectionAvoidance = {
        RandomJitter       = false,
        JitterAmount       = 0.05,
        PeriodicAimDisable = false,
        DisableChance      = 0.1,
        DisableDuration    = 0.2,
    },
    UI = {
        ToggleKey = "K",
    },
}

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing        = Drawing.new("Circle")
FOVRing.Visible      = false
FOVRing.Thickness    = 1.5
FOVRing.Transparency = Settings.FOV.Transparency
FOVRing.Color        = Settings.FOV.Color
FOVRing.Filled       = false

local ChamsFolder  = Instance.new("Folder")
ChamsFolder.Name   = "KaimChams"
ChamsFolder.Parent = CoreGui

local TracerLineCache = {}

-- ============================================================
--  TARGET HUD
-- ============================================================
local TargetGui = Instance.new("ScreenGui")
TargetGui.Name           = "KaimTargetHUD"
TargetGui.ResetOnSpawn   = false
TargetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
TargetGui.Parent         = CoreGui

local TargetFrame = Instance.new("Frame", TargetGui)
TargetFrame.Size                   = UDim2.new(0, 280, 0, 80)
TargetFrame.Position               = UDim2.new(0.5, -140, 0.65, 0)
TargetFrame.BackgroundColor3       = Color3.fromRGB(14, 14, 20)
TargetFrame.BackgroundTransparency = 0.1
TargetFrame.Visible                = false
TargetFrame.BorderSizePixel        = 0
Instance.new("UICorner", TargetFrame).CornerRadius = UDim.new(0, 10)
local TStroke        = Instance.new("UIStroke", TargetFrame)
TStroke.Color        = Color3.fromRGB(80, 180, 255)
TStroke.Thickness    = 1.5
TStroke.Transparency = 0.3

local NameLabel                  = Instance.new("TextLabel", TargetFrame)
NameLabel.Size                   = UDim2.new(1, -16, 0, 28)
NameLabel.Position               = UDim2.new(0, 8, 0, 8)
NameLabel.BackgroundTransparency = 1
NameLabel.TextColor3             = Color3.fromRGB(240, 240, 255)
NameLabel.TextXAlignment         = Enum.TextXAlignment.Left
NameLabel.Font                   = Enum.Font.GothamBold
NameLabel.TextSize               = 16
NameLabel.Text                   = "Target"

local DistLabel                  = Instance.new("TextLabel", TargetFrame)
DistLabel.Size                   = UDim2.new(1, -16, 0, 20)
DistLabel.Position               = UDim2.new(0, 8, 0, 36)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3             = Color3.fromRGB(130, 130, 160)
DistLabel.TextXAlignment         = Enum.TextXAlignment.Left
DistLabel.Font                   = Enum.Font.Gotham
DistLabel.TextSize               = 13
DistLabel.Text                   = "Distance: 0m"

local HPLabel                    = Instance.new("TextLabel", TargetFrame)
HPLabel.Size                     = UDim2.new(0, 60, 0, 24)
HPLabel.Position                 = UDim2.new(1, -68, 0, 8)
HPLabel.BackgroundColor3         = Color3.fromRGB(10, 10, 16)
HPLabel.BackgroundTransparency   = 0.1
HPLabel.TextColor3               = Color3.fromRGB(0, 255, 120)
HPLabel.TextXAlignment           = Enum.TextXAlignment.Center
HPLabel.Font                     = Enum.Font.GothamBlack
HPLabel.TextSize                 = 15
HPLabel.Text                     = "100"
HPLabel.Visible                  = false
Instance.new("UICorner", HPLabel).CornerRadius = UDim.new(0, 6)
local HPStroke        = Instance.new("UIStroke", HPLabel)
HPStroke.Color        = Color3.fromRGB(0, 255, 120)
HPStroke.Thickness    = 1.5
HPStroke.Transparency = 0.3

local HUDLastHP = -1

-- ============================================================
--  WINDOW
-- ============================================================
local Window = WindUI:CreateWindow({
    Title     = "KAIM v3.0",
    Author    = "by FRK",
    Folder    = "Kaim",
    Size      = UDim2.fromOffset(610, 520),
    Theme     = "Dark",
    Resizable = true,
})

do
    Window:Tag({
        Title = "v" .. WindUI.Version,
        Icon = "github",
        Color = Color3.fromHex("#1c1c1c"),
        Border = true,
    })
end

Window:SetToggleKey(Enum.KeyCode.K)

-- ============================================================
--  TABS
-- ============================================================
local AimlockTab  = Window:Tab({ Title = "Aimlock",  Icon = "crosshair"  })
local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "eye"        })
local PlayerTab   = Window:Tab({ Title = "Player",   Icon = "user"       })
local VisualsTab  = Window:Tab({ Title = "Visuals",  Icon = "palette"    })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings"   })

-- ============================================================
--  AIMLOCK TAB
-- ============================================================
local AimSection = AimlockTab:Section({ Title = "Aimlock Control", Opened = true })

AimSection:Toggle({
    Title    = "Enable Aimlock",
    Desc     = "Master toggle for the aimlock system",
    Value    = false,
    Callback = function(v) Settings.Aimlock.Enabled = v end
})

AimSection:Keybind({
    Title    = "Aimlock Key",
    Desc     = "Hold this key to lock onto the nearest target",
    Value    = "RightClick",
    Callback = function(v) Settings.Aimlock.Keybind = v end
})

AimSection:Toggle({
    Title    = "Wall Check",
    Desc     = "Ignore targets that are behind walls",
    Value    = true,
    Callback = function(v) Settings.Aimlock.WallCheck = v end
})

AimSection:Toggle({
    Title    = "Team Check",
    Desc     = "Never lock onto players on your team",
    Value    = true,
    Callback = function(v) Settings.Aimlock.TeamCheck = v end
})

local AimTuning = AimlockTab:Section({ Title = "Aim Tuning", Opened = true })

AimTuning:Slider({
    Title    = "Prediction",
    Desc     = "How far ahead to lead moving targets (seconds)",
    Step     = 0.005,
    Value    = { Min = 0, Max = 0.3, Default = 0.135 },
    Callback = function(v) Settings.Aimlock.Prediction = v end
})

AimTuning:Dropdown({
    Title    = "Aim Target",
    Desc     = "Which body part the aimlock snaps to",
    Values   = { "Head", "Torso", "Limbs" },
    Value    = "Head",
    Callback = function(v) Settings.Aimlock.AimMode = v end
})

AimTuning:Slider({
    Title    = "Strafe Prediction",
    Desc     = "Velocity multiplier for strafing targets",
    Step     = 0.05,
    Value    = { Min = 0.5, Max = 2.5, Default = 1.0 },
    Callback = function(v) Settings.Aimlock.StrafePrediction = v end
})

local AdvAim = AimlockTab:Section({ Title = "Advanced", Opened = false })

AdvAim:Toggle({
    Title    = "Smooth Aiming",
    Desc     = "Gradually lerp the camera to the target",
    Value    = false,
    Callback = function(v) Settings.Aimlock.SmoothAiming = v end
})

AdvAim:Slider({
    Title    = "Smooth Speed",
    Desc     = "Lerp factor — higher feels snappier",
    Step     = 0.05,
    Value    = { Min = 0.05, Max = 1.0, Default = 0.3 },
    Callback = function(v) Settings.Aimlock.SmoothSpeed = v end
})

AdvAim:Toggle({
    Title    = "Random Jitter",
    Desc     = "Add subtle noise to aim to look more human",
    Value    = false,
    Callback = function(v) Settings.DetectionAvoidance.RandomJitter = v end
})

AdvAim:Slider({
    Title    = "Jitter Amount",
    Desc     = "Strength of random aim displacement",
    Step     = 0.005,
    Value    = { Min = 0, Max = 0.2, Default = 0.05 },
    Callback = function(v) Settings.DetectionAvoidance.JitterAmount = v end
})

AdvAim:Toggle({
    Title    = "Periodic Disable",
    Desc     = "Randomly pause aimlock to avoid detection",
    Value    = false,
    Callback = function(v) Settings.DetectionAvoidance.PeriodicAimDisable = v end
})

AdvAim:Slider({
    Title    = "Disable Chance",
    Desc     = "Probability per cycle that aimlock pauses",
    Step     = 0.01,
    Value    = { Min = 0, Max = 1.0, Default = 0.1 },
    Callback = function(v) Settings.DetectionAvoidance.DisableChance = v end
})

-- ============================================================
--  ESP TAB
-- ============================================================
local ESPCore = ESPTab:Section({ Title = "ESP Core", Opened = true })

ESPCore:Toggle({
    Title    = "Enable ESP",
    Desc     = "Show player boxes, names, and health",
    Value    = false,
    Callback = function(v) Settings.Visuals.ESPEnabled = v end
})

ESPCore:Toggle({
    Title    = "Team Check",
    Desc     = "Do not show ESP on players in your team",
    Value    = true,
    Callback = function(v) Settings.Visuals.TeamCheck = v end
})

ESPCore:Toggle({
    Title    = "Show Teammates",
    Desc     = "Highlight your teammates with a separate color",
    Value    = false,
    Callback = function(v) Settings.Visuals.ShowTeammates = v end
})

ESPCore:Colorpicker({
    Title    = "Teammate Color",
    Desc     = "Color used for teammate ESP overlays",
    Default  = Color3.fromRGB(0, 200, 255),
    Callback = function(v) Settings.Visuals.TeammateColor = v end
})

local BoxSection = ESPTab:Section({ Title = "Box", Opened = true })

BoxSection:Toggle({
    Title    = "ESP Boxes",
    Desc     = "Draw a full bounding box around each player",
    Value    = true,
    Callback = function(v) Settings.Visuals.ESPBoxes = v end
})

BoxSection:Toggle({
    Title    = "Box Outline",
    Desc     = "Add a dark outline behind the box for contrast",
    Value    = true,
    Callback = function(v) Settings.Visuals.ESPOutline = v end
})

local ColorSection = ESPTab:Section({ Title = "Colors", Opened = true })

ColorSection:Toggle({
    Title    = "Visibility Colors",
    Desc     = "Use different colors for visible vs hidden targets",
    Value    = true,
    Callback = function(v) Settings.Visuals.UseVisColors = v end
})

ColorSection:Colorpicker({
    Title    = "Visible Color",
    Desc     = "ESP color when you have line-of-sight on the target",
    Default  = Color3.fromRGB(50, 255, 80),
    Callback = function(v) Settings.Visuals.VisColor = v end
})

ColorSection:Colorpicker({
    Title    = "Hidden Color",
    Desc     = "ESP color when target is behind a wall",
    Default  = Color3.fromRGB(255, 60, 60),
    Callback = function(v) Settings.Visuals.HiddenColor = v end
})

local TextSection = ESPTab:Section({ Title = "Text & Names", Opened = true })

TextSection:Toggle({
    Title    = "Show Names",
    Desc     = "Display the player name above their box",
    Value    = true,
    Callback = function(v) Settings.Visuals.ESPNames = v end
})

TextSection:Dropdown({
    Title    = "Name Style",
    Desc     = "Which name format to display",
    Values   = { "Display Name", "Username", "Both" },
    Value    = "Display Name",
    Callback = function(v) Settings.Visuals.ESPNameStyle = v end
})

TextSection:Slider({
    Title    = "Text Scale",
    Desc     = "Size of all ESP text — names, distance, health numbers",
    Step     = 1,
    Value    = { Min = 10, Max = 22, Default = 14 },
    Callback = function(v)
        Settings.Visuals.ESPTextScale = v
    end
})

local HealthSection = ESPTab:Section({ Title = "Health", Opened = true })

HealthSection:Toggle({
    Title    = "Health Numbers",
    Desc     = "Display the exact HP value on the ESP",
    Value    = false,
    Callback = function(v) Settings.Visuals.HealthNumbers = v end
})

local DistSection = ESPTab:Section({ Title = "Distance", Opened = false })

DistSection:Toggle({
    Title    = "Distance Display",
    Desc     = "Show stud distance below each player box",
    Value    = false,
    Callback = function(v) Settings.Visuals.DistanceDisplay = v end
})

local ChamsSection = ESPTab:Section({ Title = "Chams", Opened = false })

ChamsSection:Toggle({
    Title    = "Enable Chams",
    Desc     = "Highlight player characters using Roblox Highlight",
    Value    = false,
    Callback = function(v) Settings.Visuals.ChamsEnabled = v end
})

ChamsSection:Toggle({
    Title    = "See Through Walls",
    Desc     = "Show chams even when player is behind geometry",
    Value    = true,
    Callback = function(v)
        Settings.Visuals.ChamsDepth = v
        for _, esp in pairs(ESPObjects) do
            if esp and esp.Highlight then
                esp.Highlight.DepthMode = v
                    and Enum.HighlightDepthMode.AlwaysOnTop
                    or  Enum.HighlightDepthMode.Occluded
            end
        end
    end
})

ChamsSection:Colorpicker({
    Title    = "Fill Color",
    Desc     = "Interior color of the Highlight",
    Default  = Color3.fromRGB(255, 30, 30),
    Callback = function(v) Settings.Visuals.ChamsFillColor = v end
})

ChamsSection:Colorpicker({
    Title    = "Outline Color",
    Desc     = "Outline color of the Highlight",
    Default  = Color3.fromRGB(255, 255, 255),
    Callback = function(v) Settings.Visuals.ChamsOutlineColor = v end
})

local LinesSection = ESPTab:Section({ Title = "Lines", Opened = false })

LinesSection:Toggle({
    Title    = "Tracer Lines",
    Desc     = "Draw a line from screen edge to each enemy player",
    Value    = false,
    Callback = function(v) Settings.Visuals.TracerLines = v end
})

LinesSection:Dropdown({
    Title    = "Tracer Origin",
    Desc     = "Where on-screen the tracer line starts",
    Values   = { "Bottom", "Center", "Top" },
    Value    = "Bottom",
    Callback = function(v) Settings.Visuals.TracerOrigin = v end
})

LinesSection:Colorpicker({
    Title    = "Tracer Color",
    Desc     = "Color of tracer lines",
    Default  = Color3.fromRGB(0, 200, 255),
    Callback = function(v) Settings.Visuals.TracerColor = v end
})

LinesSection:Toggle({
    Title    = "Snap Lines",
    Desc     = "Draw a line from screen center to each enemy",
    Value    = false,
    Callback = function(v) Settings.Visuals.SnapLines = v end
})

LinesSection:Colorpicker({
    Title    = "Snap Line Color",
    Desc     = "Color of snap lines",
    Default  = Color3.fromRGB(255, 0, 220),
    Callback = function(v) Settings.Visuals.SnapLineColor = v end
})

-- ============================================================
--  PLAYER TAB
-- ============================================================
local SpeedSection = PlayerTab:Section({ Title = "Walk Speed", Opened = true })

SpeedSection:Toggle({
    Title    = "Enable Walk Speed",
    Desc     = "Override your character walk speed",
    Value    = false,
    Callback = function(v) Settings.Player.WalkSpeedEnabled = v end
})

SpeedSection:Slider({
    Title    = "Walk Speed",
    Desc     = "Default Roblox walk speed is 16",
    Step     = 1,
    Value    = { Min = 5, Max = 100, Default = 16 },
    Callback = function(v) Settings.Player.WalkSpeed = v end
})

local JumpSection = PlayerTab:Section({ Title = "Jump Power", Opened = true })

JumpSection:Toggle({
    Title    = "Enable Jump Power",
    Desc     = "Override your character jump power",
    Value    = false,
    Callback = function(v) Settings.Player.JumpPowerEnabled = v end
})

JumpSection:Slider({
    Title    = "Jump Power",
    Desc     = "Default Roblox jump power is 50",
    Step     = 5,
    Value    = { Min = 10, Max = 250, Default = 50 },
    Callback = function(v) Settings.Player.JumpPower = v end
})

local NoclipSection = PlayerTab:Section({ Title = "Noclip", Opened = true })

NoclipSection:Toggle({
    Title    = "Enable Noclip",
    Desc     = "Phase through all parts and walls",
    Value    = false,
    Callback = function(v) Settings.Player.NoclipEnabled = v end
})

-- ============================================================
--  VISUALS TAB
-- ============================================================
local FOVSection = VisualsTab:Section({ Title = "FOV Circle", Opened = true })

FOVSection:Toggle({
    Title    = "Show FOV Circle",
    Desc     = "Display the aimlock radius ring on screen",
    Value    = true,
    Callback = function(v) Settings.FOV.Visible = v end
})

FOVSection:Slider({
    Title    = "FOV Radius",
    Desc     = "Size of the FOV circle in pixels",
    Step     = 5,
    Value    = { Min = 30, Max = 600, Default = 150 },
    Callback = function(v) Settings.FOV.Radius = v end
})

FOVSection:Slider({
    Title    = "FOV Transparency",
    Desc     = "0 = fully opaque  |  1 = invisible",
    Step     = 0.05,
    Value    = { Min = 0, Max = 1, Default = 0.8 },
    Callback = function(v)
        Settings.FOV.Transparency = v
        FOVRing.Transparency = v
    end
})

FOVSection:Colorpicker({
    Title    = "FOV Color",
    Desc     = "Color of the FOV ring",
    Default  = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        Settings.FOV.Color = v
        FOVRing.Color = v
    end
})

local HUDSection = VisualsTab:Section({ Title = "Target HUD", Opened = true })

HUDSection:Toggle({
    Title    = "Show Target HUD",
    Desc     = "Show info card at bottom of screen while aiming",
    Value    = true,
    Callback = function(v) Settings.Visuals.TargetUI = v end
})

HUDSection:Toggle({
    Title    = "Health on HUD",
    Desc     = "Show exact HP number on the target card",
    Value    = false,
    Callback = function(v) Settings.Visuals.HealthNumbers = v end
})

HUDSection:Dropdown({
    Title    = "Health Number Position",
    Desc     = "Where the HP badge appears on the target card",
    Values   = { "TopRight", "TopLeft", "BottomRight", "BottomLeft" },
    Value    = "TopRight",
    Callback = function(v) Settings.Visuals.HealthPosition = v end
})

-- ============================================================
--  SETTINGS TAB
-- ============================================================
local UISection = SettingsTab:Section({ Title = "UI Controls", Opened = true })

UISection:Paragraph({
    Title = "UI Toggle Key",
    Desc  = "Use the keybind below to change which key opens and closes the KAIM UI.",
    Color = "Blue",
})

UISection:Keybind({
    Title    = "Toggle UI Key",
    Desc     = "Press this key to open / close the KAIM window",
    Value    = "K",
    Callback = function(v)
        Settings.UI.ToggleKey = v
        local ok, kc = pcall(function() return Enum.KeyCode[v] end)
        if ok and kc then
            Window:SetToggleKey(kc)
        end
    end
})

local ThemeSection = SettingsTab:Section({ Title = "Theme", Opened = true })

ThemeSection:Button({
    Title    = "Dark Theme",
    Callback = function() WindUI:SetTheme("Dark") end
})

ThemeSection:Button({
    Title    = "Light Theme",
    Callback = function() WindUI:SetTheme("Light") end
})

ThemeSection:Button({
    Title    = "Rose Theme",
    Callback = function() WindUI:SetTheme("Rose") end
})

local InfoSection = SettingsTab:Section({ Title = "About KAIM", Opened = true })

InfoSection:Paragraph({
    Title = "KAIM v2.0",
    Desc  = "Advanced Aimlock & Combat Hub — built with WindUI. Use the keybind above to toggle the window.",
    Color = "Blue",
})

InfoSection:Paragraph({
    Title = "Feature List",
    Desc  = "Smooth Aimlock  •  Velocity Prediction  •  2D ESP  •  Chams  •  Health Numbers  •  Player Mods  •  FOV Ring  •  Target HUD  •  Snap & Tracer Lines",
    Color = "Green",
})

InfoSection:Paragraph({
    Title = "Keybinds",
    Desc  = "UI Toggle: K (changeable above)\nAimlock: Right Click (changeable in Aimlock tab)",
    Color = "Grey",
})

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
    params.FilterDescendantsInstances = { LocalPlayer.Character, targetChar }
    params.FilterType                 = Enum.RaycastFilterType.Exclude
    params.IgnoreWater                = true
    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

local function IsTargetAlive(player)
    if not player or not player.Character then return false end
    if Settings.Aimlock.TeamCheck and IsTeammate(player) then return false end
    local hum  = player.Character:FindFirstChildOfClass("Humanoid")
    local part = player.Character:FindFirstChild(Settings.Aimlock.TargetPart)
    if not hum or not part then return false end
    return (hum.Health or 0) > 0
end

local function GetAimPart(character)
    if Settings.Aimlock.AimMode == "Head" then
        return character:FindFirstChild("Head")
    elseif Settings.Aimlock.AimMode == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    elseif Settings.Aimlock.AimMode == "Limbs" then
        local opts  = { character:FindFirstChild("LeftUpperArm"), character:FindFirstChild("RightUpperArm") }
        local valid = {}
        for _, p in ipairs(opts) do if p then valid[#valid+1] = p end end
        return valid[math.random(1, math.max(1, #valid))]
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function AddJitter(position)
    if not Settings.DetectionAvoidance.RandomJitter then return position end
    local j = Settings.DetectionAvoidance.JitterAmount
    return position + Vector3.new(
        (math.random()-0.5)*j*2,
        (math.random()-0.5)*j*2,
        (math.random()-0.5)*j*2
    )
end

-- ============================================================
--  CACHING
-- ============================================================
local TeamCache   = {}
local FRAME_COUNT = 0

Players.PlayerAdded:Connect(function(player)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        TeamCache[player] = nil
    end)
end)

local function IsTeammateCached(player)
    if TeamCache[player] == nil then
        TeamCache[player] = (player.Team ~= nil) and (player.Team == LocalPlayer.Team) or false
    end
    return TeamCache[player]
end

-- ============================================================
--  GET CLOSEST PLAYER
-- ============================================================
function GetClosestPlayer()
    local fovSq         = Settings.FOV.Radius * Settings.FOV.Radius
    local closestDistSq = fovSq
    local closestTarget = nil
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        if Settings.Aimlock.TeamCheck and IsTeammateCached(player) then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or (hum.Health or 0) <= 0 then continue end
        local part = char:FindFirstChild(Settings.Aimlock.TargetPart)
        if not part then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        if Settings.Aimlock.WallCheck and not IsVisible(part, char) then continue end
        local dx = cx - sp.X
        local dy = cy - sp.Y
        local dSq = dx*dx + dy*dy
        if dSq < closestDistSq then
            closestDistSq = dSq
            closestTarget = player
        end
    end
    return closestTarget
end

-- ============================================================
--  COLOR HELPERS
-- ============================================================
local function GetHealthColor(pct)
    if pct > 0.80 then return Color3.fromRGB(0,   255, 100) end
    if pct > 0.60 then return Color3.fromRGB(100, 255, 50)  end
    if pct > 0.40 then return Color3.fromRGB(255, 200, 0)   end
    if pct > 0.20 then return Color3.fromRGB(255, 130, 0)   end
    return                  Color3.fromRGB(255, 50,  50)
end

local function GetDistanceColor(dist)
    if dist < 50  then return Color3.fromRGB(0,   255, 100) end
    if dist < 100 then return Color3.fromRGB(100, 255, 100) end
    if dist < 200 then return Color3.fromRGB(255, 210, 0)   end
    if dist < 350 then return Color3.fromRGB(255, 140, 0)   end
    return                  Color3.fromRGB(255, 90,  90)
end

-- ============================================================
--  ESP OBJECTS
-- ============================================================
ESPObjects = {}

local function CreateESP(player)
    local ok, result = pcall(function()
        local esp = {
            Box         = Drawing.new("Square"),
            BoxOutline  = Drawing.new("Square"),
            Name        = Drawing.new("Text"),
            Username    = Drawing.new("Text"),
            Distance    = Drawing.new("Text"),
            Health      = Drawing.new("Text"),
            Highlight   = Instance.new("Highlight"),
            SnapLine    = nil,
            _lastVisible = false,
            _isVisible   = false,
            _screenRootX = 0,
            _screenRootY = 0,
            _screenHeadY = 0,
            _screenDepth = 0,
            _onScreen    = false,
            _lastDist    = -1,
        }

        esp.Box.Visible      = false
        esp.Box.Thickness    = 1.5
        esp.Box.Transparency = 0.8
        esp.Box.Filled       = false

        esp.BoxOutline.Visible      = false
        esp.BoxOutline.Thickness    = 3.5
        esp.BoxOutline.Transparency = 0.6
        esp.BoxOutline.Filled       = false
        esp.BoxOutline.Color        = Color3.fromRGB(0, 0, 0)

        esp.Name.Visible      = false
        esp.Name.Size         = Settings.Visuals.ESPTextScale
        esp.Name.Center       = true
        esp.Name.Outline      = true
        esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
        esp.Name.Font         = 2

        esp.Username.Visible      = false
        esp.Username.Size         = math.max(10, Settings.Visuals.ESPTextScale - 2)
        esp.Username.Center       = true
        esp.Username.Outline      = true
        esp.Username.OutlineColor = Color3.fromRGB(0, 0, 0)
        esp.Username.Color        = Color3.fromRGB(180, 180, 200)
        esp.Username.Font         = 2

        esp.Distance.Visible      = false
        esp.Distance.Size         = math.max(10, Settings.Visuals.ESPTextScale - 2)
        esp.Distance.Center       = true
        esp.Distance.Outline      = true
        esp.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
        esp.Distance.Font         = 2

        esp.Health.Visible      = false
        esp.Health.Size         = math.max(10, Settings.Visuals.ESPTextScale - 2)
        esp.Health.Center       = true
        esp.Health.Outline      = true
        esp.Health.OutlineColor = Color3.fromRGB(0, 0, 0)
        esp.Health.Font         = 2

        esp.Highlight.Parent    = ChamsFolder
        esp.Highlight.Enabled   = false
        esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        ESPObjects[player] = esp
    end)
    if not ok then
        warn("KAIM | CreateESP error for " .. tostring(player) .. ": " .. tostring(result))
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then CreateESP(p) end
end)

Players.PlayerRemoving:Connect(function(player)
    local esp = ESPObjects[player]
    if not esp then return end
    pcall(function()
        esp.Box:Remove();        esp.BoxOutline:Remove()
        esp.Name:Remove();       esp.Username:Remove()
        esp.Distance:Remove();   esp.Health:Remove()
        if esp.SnapLine then esp.SnapLine:Remove() end
        esp.Highlight:Destroy()
    end)
    ESPObjects[player] = nil
    TeamCache[player]  = nil
end)

-- ============================================================
--  HIDE ESP HELPER
-- ============================================================
local function HideESP(esp)
    if not esp._lastVisible then return end
    esp.Box.Visible         = false
    esp.BoxOutline.Visible  = false
    esp.Name.Visible        = false
    esp.Username.Visible    = false
    esp.Distance.Visible    = false
    esp.Health.Visible      = false
    esp.Highlight.Enabled   = false
    esp._lastVisible        = false
end

-- ============================================================
--  PERIODIC DISABLE TIMER
-- ============================================================
local periodicDisableTimer = 0

-- ============================================================
--  MAIN RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function(dt)
    FRAME_COUNT = FRAME_COUNT + 1

    -- FOV Ring
    local mousePos = UserInputService:GetMouseLocation()
    FOVRing.Position     = mousePos
    FOVRing.Radius       = Settings.FOV.Radius
    FOVRing.Visible      = Settings.FOV.Visible
    FOVRing.Transparency = Settings.FOV.Transparency

    -- Periodic disable timer
    if Settings.DetectionAvoidance.PeriodicAimDisable and Settings.Aimlock.Enabled then
        periodicDisableTimer = periodicDisableTimer - dt
        if periodicDisableTimer <= 0 then
            Settings.Aimlock.PeriodicDisable = math.random() < Settings.DetectionAvoidance.DisableChance
            periodicDisableTimer = Settings.DetectionAvoidance.DisableDuration + math.random() * 0.4
        end
    else
        Settings.Aimlock.PeriodicDisable = false
    end

    -- ================================================================
    --  AIMLOCK
    -- ================================================================
    if Settings.Aimlock.Enabled and Settings.Aimlock.IsAiming then
        if not Settings.Aimlock.CurrentTarget or not IsTargetAlive(Settings.Aimlock.CurrentTarget) then
            Settings.Aimlock.CurrentTarget = GetClosestPlayer()
        end
    end

    local showHUD = false

    if Settings.Aimlock.Enabled and Settings.Aimlock.IsAiming
       and Settings.Aimlock.CurrentTarget and not Settings.Aimlock.PeriodicDisable then
        local tChar = Settings.Aimlock.CurrentTarget.Character
        if tChar then
            local tPart = GetAimPart(tChar) or tChar:FindFirstChild(Settings.Aimlock.TargetPart)
            local hum   = tChar:FindFirstChildOfClass("Humanoid")
            if tPart and hum and (hum.Health or 0) > 0 then
                local vel       = tPart.Velocity * Settings.Aimlock.StrafePrediction
                local predicted = AddJitter(tPart.Position + vel * Settings.Aimlock.Prediction)
                local tCF       = CFrame.new(Camera.CFrame.Position, predicted)
                if Settings.Aimlock.SmoothAiming then
                    Camera.CFrame = Camera.CFrame:Lerp(tCF, Settings.Aimlock.SmoothSpeed)
                else
                    Camera.CFrame = tCF
                end

                if Settings.Visuals.TargetUI then
                    showHUD = true
                    NameLabel.Text = Settings.Aimlock.CurrentTarget.DisplayName

                    local hp    = hum.Health    or 0
                    local hpMax = hum.MaxHealth or 100
                    if hpMax <= 0 then hpMax = 100 end
                    local hpPct = math.clamp(hp / hpMax, 0, 1)

                    if Settings.Visuals.HealthNumbers then
                        HPLabel.Visible = true
                        local hpInt = math.floor(hp)
                        if hpInt ~= HUDLastHP then
                            HUDLastHP          = hpInt
                            HPLabel.Text       = tostring(hpInt)
                            local hc           = GetHealthColor(hpPct)
                            HPLabel.TextColor3 = hc
                            HPStroke.Color     = hc
                        end
                        local pos = Settings.Visuals.HealthPosition
                        if     pos == "TopRight"    then HPLabel.Position = UDim2.new(1,-68,0,8)
                        elseif pos == "TopLeft"     then HPLabel.Position = UDim2.new(0,8,0,8)
                        elseif pos == "BottomRight" then HPLabel.Position = UDim2.new(1,-68,1,-32)
                        elseif pos == "BottomLeft"  then HPLabel.Position = UDim2.new(0,8,1,-32)
                        end
                    else
                        HPLabel.Visible = false
                    end

                    local lhrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local thrp = tChar:FindFirstChild("HumanoidRootPart")
                    if lhrp and thrp then
                        DistLabel.Text = "Distance: " .. math.floor((lhrp.Position - thrp.Position).Magnitude) .. "m"
                    end
                end
            else
                Settings.Aimlock.CurrentTarget = nil
            end
        else
            Settings.Aimlock.CurrentTarget = nil
        end
    end

    TargetFrame.Visible = showHUD
    if not showHUD then HPLabel.Visible = false end

    -- ================================================================
    --  PLAYER MODS
    -- ================================================================
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if Settings.Player.WalkSpeedEnabled then hum.WalkSpeed = Settings.Player.WalkSpeed end
            if Settings.Player.JumpPowerEnabled  then hum.JumpPower  = Settings.Player.JumpPower  end
        end
        if Settings.Player.NoclipEnabled then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end

    -- ================================================================
    --  TRACER LINES
    -- ================================================================
    if Settings.Visuals.TracerLines and Settings.Visuals.ESPEnabled then
        local sw  = Camera.ViewportSize.X
        local sh  = Camera.ViewportSize.Y
        local oy  = Settings.Visuals.TracerOrigin == "Bottom" and sh
                    or Settings.Visuals.TracerOrigin == "Top"  and 0
                    or sh / 2
        local origin = Vector2.new(sw / 2, oy)
        for player in pairs(ESPObjects) do
            if IsTeammateCached(player) then
                if TracerLineCache[player] then
                    TracerLineCache[player]:Remove()
                    TracerLineCache[player] = nil
                end
                continue
            end
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not TracerLineCache[player] then
                        local line     = Drawing.new("Line")
                        line.Thickness = 1.5
                        TracerLineCache[player] = line
                    end
                    local line = TracerLineCache[player]
                    local tp   = Camera:WorldToViewportPoint(hrp.Position)
                    line.Color   = Settings.Visuals.TracerColor
                    line.From    = origin
                    line.To      = Vector2.new(tp.X, tp.Y)
                    line.Visible = tp.Z > 0
                end
            end
        end
    else
        for _, line in pairs(TracerLineCache) do line:Remove() end
        table.clear(TracerLineCache)
    end

    -- ================================================================
    --  ESP RENDER LOOP
    -- ================================================================
    local espOn   = Settings.Visuals.ESPEnabled
    local chamsOn = Settings.Visuals.ChamsEnabled

    if not espOn and not chamsOn then
        for _, esp in pairs(ESPObjects) do HideESP(esp) end
        return
    end

    local sw        = Camera.ViewportSize.X
    local sh        = Camera.ViewportSize.Y
    local teamCheck = Settings.Visuals.TeamCheck
    local showTM    = Settings.Visuals.ShowTeammates
    local useVisCol = Settings.Visuals.UseVisColors
    local visCol    = Settings.Visuals.VisColor
    local hidCol    = Settings.Visuals.HiddenColor
    local tmCol     = Settings.Visuals.TeammateColor
    local nameStyle = Settings.Visuals.ESPNameStyle
    local txtScale  = Settings.Visuals.ESPTextScale
    local txtSmall  = math.max(10, txtScale - 2)
    -- Name label spacing scales with text size
    local nameSpacing = txtScale + 2

    local updateScreen = (FRAME_COUNT % 3 == 0)
    local updateVis    = (FRAME_COUNT % 6 == 0)

    for player, esp in pairs(ESPObjects) do
        local ok2, err2 = pcall(function()
            local char = player.Character
            if not char then HideESP(esp); return end

            local rootPart = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not rootPart or not humanoid then HideESP(esp); return end
            if (humanoid.Health or 0) <= 0 then HideESP(esp); return end

            local isTeammate = IsTeammateCached(player)

            -- Chams
            if chamsOn and not (teamCheck and isTeammate) then
                esp.Highlight.Adornee      = char
                esp.Highlight.Enabled      = true
                esp.Highlight.FillColor    = Settings.Visuals.ChamsFillColor
                esp.Highlight.OutlineColor = Settings.Visuals.ChamsOutlineColor
            else
                if esp.Highlight.Enabled then
                    esp.Highlight.Enabled = false
                    esp.Highlight.Adornee = nil
                end
            end

            if not espOn then
                if esp._lastVisible then
                    esp.Box.Visible  = false
                    esp.Name.Visible = false
                    esp._lastVisible = false
                end
                return
            end

            if teamCheck and isTeammate and not showTM then HideESP(esp); return end

            local head = char:FindFirstChild("Head")
            if not head then HideESP(esp); return end

            -- Screen position cache (every 3 frames)
            if updateScreen then
                local rp, onSc = Camera:WorldToViewportPoint(rootPart.Position)
                local hp2      = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                esp._screenRootX = rp.X
                esp._screenRootY = rp.Y
                esp._screenHeadY = hp2.Y
                esp._screenDepth = rp.Z
                esp._onScreen    = onSc
            end

            if not esp._onScreen or esp._screenDepth <= 0 then HideESP(esp); return end
            local rx, ry, hy = esp._screenRootX, esp._screenRootY, esp._screenHeadY
            if rx < -60 or rx > sw+60 or ry < -60 or ry > sh+60 then HideESP(esp); return end

            -- Visibility cache (every 6 frames)
            if updateVis then
                esp._isVisible = IsVisible(rootPart, char)
            end

            esp._lastVisible = true

            -- Apply live text scale each frame
            esp.Name.Size     = txtScale
            esp.Username.Size = txtSmall
            esp.Distance.Size = txtSmall
            esp.Health.Size   = txtSmall

            -- Resolve color
            local col
            if isTeammate and showTM then
                col = tmCol
            elseif useVisCol then
                col = esp._isVisible and visCol or hidCol
            else
                col = visCol
            end

            -- Box geometry
            local legY  = ry + (hy - ry) * 3
            local boxH  = math.abs(hy - legY)
            local boxW  = boxH * 0.55
            local halfW = boxW * 0.5
            local x1    = rx - halfW
            local x2    = rx + halfW
            local y1    = hy
            local y2    = hy + boxH

            -- Draw box (full rectangle only)
            if Settings.Visuals.ESPBoxes then
                if Settings.Visuals.ESPOutline then
                    esp.BoxOutline.Visible  = true
                    esp.BoxOutline.Size     = Vector2.new(boxW+3, boxH+3)
                    esp.BoxOutline.Position = Vector2.new(x1-1.5, y1-1.5)
                else
                    esp.BoxOutline.Visible = false
                end
                esp.Box.Visible  = true
                esp.Box.Color    = col
                esp.Box.Size     = Vector2.new(boxW, boxH)
                esp.Box.Position = Vector2.new(x1, y1)
            else
                esp.Box.Visible        = false
                esp.BoxOutline.Visible = false
            end

            -- Names  (position shifts up based on text scale)
            local nameY = y1 - nameSpacing
            if Settings.Visuals.ESPNames then
                if nameStyle == "Display Name" or nameStyle == "Both" then
                    esp.Name.Visible  = true
                    esp.Name.Text     = player.DisplayName
                    esp.Name.Color    = col
                    esp.Name.Position = Vector2.new(rx, nameY)
                    if nameStyle == "Both" then nameY = nameY - (txtSmall + 2) end
                else
                    esp.Name.Visible = false
                end
                if nameStyle == "Username" or nameStyle == "Both" then
                    esp.Username.Visible  = true
                    esp.Username.Text     = "@" .. player.Name
                    esp.Username.Position = Vector2.new(rx, nameY)
                else
                    esp.Username.Visible = false
                end
            else
                esp.Name.Visible     = false
                esp.Username.Visible = false
            end

            -- Distance
            if Settings.Visuals.DistanceDisplay then
                local dist    = esp._screenDepth
                local distInt = math.floor(dist)
                if distInt ~= esp._lastDist then
                    esp._lastDist      = distInt
                    esp.Distance.Text  = distInt .. "m"
                    esp.Distance.Color = GetDistanceColor(dist)
                end
                esp.Distance.Visible  = true
                esp.Distance.Position = Vector2.new(rx, y2 + 3)
            else
                esp.Distance.Visible = false
            end

            -- Health numbers only (no bar)
            local hp2    = humanoid.Health    or 0
            local hpMax2 = humanoid.MaxHealth or 100
            if hpMax2 <= 0 then hpMax2 = 100 end
            local hpPct2   = math.clamp(hp2 / hpMax2, 0, 1)
            local hColor   = GetHealthColor(hpPct2)
            local numOffset = Settings.Visuals.DistanceDisplay and (txtSmall + 4) or 2

            if Settings.Visuals.HealthNumbers then
                esp.Health.Visible   = true
                esp.Health.Text      = math.floor(hp2) .. " HP"
                esp.Health.Color     = hColor
                esp.Health.Position  = Vector2.new(rx, y2 + numOffset)
            else
                esp.Health.Visible = false
            end

            -- Snap lines
            if Settings.Visuals.SnapLines then
                if not esp.SnapLine then
                    esp.SnapLine           = Drawing.new("Line")
                    esp.SnapLine.Thickness = 1.5
                end
                esp.SnapLine.Color   = Settings.Visuals.SnapLineColor
                esp.SnapLine.From    = Vector2.new(sw/2, sh/2)
                esp.SnapLine.To      = Vector2.new(rx, ry)
                esp.SnapLine.Visible = true
            elseif esp.SnapLine then
                esp.SnapLine:Remove(); esp.SnapLine = nil
            end
        end)
        if not ok2 then warn("KAIM ESP render error:", err2) end
    end
end)

-- ============================================================
--  KEYBIND HANDLING
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local pressed = false
    if Settings.Aimlock.Keybind == "RightClick" then
        pressed = input.UserInputType == Enum.UserInputType.MouseButton2
    else
        local ok, kc = pcall(function() return Enum.KeyCode[Settings.Aimlock.Keybind] end)
        if ok and kc then pressed = input.KeyCode == kc end
    end
    if pressed then
        Settings.Aimlock.IsAiming = true
        if Settings.Aimlock.Enabled then
            Settings.Aimlock.CurrentTarget = GetClosestPlayer()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, _)
    local released = false
    if Settings.Aimlock.Keybind == "RightClick" then
        released = input.UserInputType == Enum.UserInputType.MouseButton2
    else
        local ok, kc = pcall(function() return Enum.KeyCode[Settings.Aimlock.Keybind] end)
        if ok and kc then released = input.KeyCode == kc end
    end
    if released then
        Settings.Aimlock.IsAiming      = false
        Settings.Aimlock.CurrentTarget = nil
    end
end)

-- ============================================================
WindUI:Notify({
    Title    = "KAIM v3.0 Loaded",
    Content  = "Press K to toggle the UI. Change the key in Settings.",
    Duration = 5,
})
print("KAIM v3.0 loaded - press K to toggle UI.")
