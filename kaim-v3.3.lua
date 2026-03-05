-- ============================================================
--  KAIM v3.3  |  WindUI Edition
--  Advanced Aimlock & Combat Hub
--
--  Changes vs v3.2:
--    NEW  • Home tab added as the first tab — gives the user a full
--            feature overview and quick-reference keybind list on load
-- ============================================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ============================================================
--  FAST LOCALS
-- ============================================================
local mathFloor  = math.floor
local mathClamp  = math.clamp
local mathAbs    = math.abs
local mathMax    = math.max
local mathRandom = math.random
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local Color3RGB  = Color3.fromRGB
local CFrameNew  = CFrame.new

-- ============================================================
--  SETTINGS
-- ============================================================
local Settings = {
    Aimlock = {
        Enabled            = false,
        Prediction         = 0.135,
        PredictionEnabled  = true,
        AimMode            = "Smart",   -- Smart / Head / Torso / Limbs / HRP / Chaos
        IsAiming           = false,
        CurrentTarget      = nil,
        WallCheck          = true,
        TeamCheck          = true,
        SmoothAiming       = false,
        SmoothSpeed        = 0.3,
        StrafePrediction   = 1.0,
        PeriodicDisable    = false,
        Keybind            = "RightClick",
    },
    FOV = {
        Visible        = true,
        FollowCursor   = true,
        Radius         = 150,
        Thickness      = 1.5,
        Color          = Color3RGB(255, 255, 255),
        Transparency   = 0.8,
        Filled         = false,
        FilledColor    = Color3RGB(255, 255, 255),
        FilledTransp   = 0.92,
    },
    Visuals = {
        ESPEnabled         = false,
        ESPBoxes           = true,
        ESPNames           = true,
        ESPNameStyle       = "Display Name",
        ESPOutline         = true,
        ESPTextScale       = 14,
        UseCustomNameColor = false,
        ESPNameColor       = Color3RGB(255, 255, 255),
        ESPUsernameColor   = Color3RGB(180, 180, 200),
        TeamCheck          = true,
        ShowTeammates      = false,
        TeammateColor      = Color3RGB(0, 200, 255),
        UseVisColors       = true,
        VisColor           = Color3RGB(50, 255, 80),
        HiddenColor        = Color3RGB(255, 60, 60),
        DistanceDisplay    = false,
        HealthNumbers      = false,
        HealthBar          = true,
        ChamsEnabled       = false,
        ChamsFillColor     = Color3RGB(255, 30, 30),
        ChamsOutlineColor  = Color3RGB(255, 255, 255),
        ChamsDepth         = true,
        TracerLines        = false,
        TracerOrigin       = "Bottom",
        TracerColor        = Color3RGB(0, 200, 255),
        SnapLines          = false,
        SnapLineColor      = Color3RGB(255, 0, 220),
        TargetUI           = true,
        HealthPosition     = "TopRight",
        MaxESPDistance     = 1000,
    },
    Player = {
        WalkSpeedEnabled = false,
        WalkSpeed        = 16,
        JumpPowerEnabled = false,
        JumpPower        = 50,
        NoclipEnabled    = false,
        NoclipKeybind    = "N",
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
--  CHAOS AIM MODE STATE
--  Rotates through body parts every CHAOS_INTERVAL seconds,
--  never picking the same part twice in a row.
-- ============================================================
local CHAOS_INTERVAL  = 0.3   -- seconds between part switches
local CHAOS_PARTS     = {
    "Head",
    "UpperTorso",       -- R15 torso; fallback to "Torso" (R6) handled in GetAimPart
    "Torso",            -- included so R6 characters also get torso hits
    "LeftUpperArm",
    "RightUpperArm",
    "LeftUpperLeg",
    "RightUpperLeg",
}
-- Deduplicated list used for selection (Torso + UpperTorso are both in the
-- pool; whichever exists on the character will be chosen at runtime).
local CHAOS_PICK_LIST = {
    "Head",
    "UpperTorso",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftUpperLeg",
    "RightUpperLeg",
}
local chaosCurrentPart  = "Head"   -- currently active part name
local chaosLastPart     = ""       -- tracks previous pick to avoid repeats
local chaosTimer        = 0        -- countdown to next switch

local function PickNextChaosPart()
    local pool   = CHAOS_PICK_LIST
    local count  = #pool
    if count == 1 then return pool[1] end
    -- Build a filtered list that excludes the last pick
    local candidates = {}
    for _, name in ipairs(pool) do
        if name ~= chaosLastPart then
            candidates[#candidates + 1] = name
        end
    end
    local chosen  = candidates[mathRandom(#candidates)]
    chaosLastPart = chosen
    return chosen
end

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing        = Drawing.new("Circle")
FOVRing.Visible      = false
FOVRing.Thickness    = 1.5
FOVRing.Transparency = Settings.FOV.Transparency
FOVRing.Color        = Settings.FOV.Color
FOVRing.Filled       = false

local FOVFill        = Drawing.new("Circle")
FOVFill.Visible      = false
FOVFill.Thickness    = 1
FOVFill.Transparency = Settings.FOV.FilledTransp
FOVFill.Color        = Settings.FOV.FilledColor
FOVFill.Filled       = true

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
TargetFrame.BackgroundColor3       = Color3RGB(14, 14, 20)
TargetFrame.BackgroundTransparency = 0.1
TargetFrame.Visible                = false
TargetFrame.BorderSizePixel        = 0
Instance.new("UICorner", TargetFrame).CornerRadius = UDim.new(0, 10)
local TStroke        = Instance.new("UIStroke", TargetFrame)
TStroke.Color        = Color3RGB(80, 180, 255)
TStroke.Thickness    = 1.5
TStroke.Transparency = 0.3

local NameLabel                  = Instance.new("TextLabel", TargetFrame)
NameLabel.Size                   = UDim2.new(1, -16, 0, 28)
NameLabel.Position               = UDim2.new(0, 8, 0, 8)
NameLabel.BackgroundTransparency = 1
NameLabel.TextColor3             = Color3RGB(240, 240, 255)
NameLabel.TextXAlignment         = Enum.TextXAlignment.Left
NameLabel.Font                   = Enum.Font.GothamBold
NameLabel.TextSize               = 16
NameLabel.Text                   = "Target"

local DistLabel                  = Instance.new("TextLabel", TargetFrame)
DistLabel.Size                   = UDim2.new(1, -16, 0, 20)
DistLabel.Position               = UDim2.new(0, 8, 0, 36)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3             = Color3RGB(130, 130, 160)
DistLabel.TextXAlignment         = Enum.TextXAlignment.Left
DistLabel.Font                   = Enum.Font.Gotham
DistLabel.TextSize               = 13
DistLabel.Text                   = "Distance: 0m"

local HPLabel                    = Instance.new("TextLabel", TargetFrame)
HPLabel.Size                     = UDim2.new(0, 60, 0, 24)
HPLabel.Position                 = UDim2.new(1, -68, 0, 8)
HPLabel.BackgroundColor3         = Color3RGB(10, 10, 16)
HPLabel.BackgroundTransparency   = 0.1
HPLabel.TextColor3               = Color3RGB(0, 255, 120)
HPLabel.TextXAlignment           = Enum.TextXAlignment.Center
HPLabel.Font                     = Enum.Font.GothamBlack
HPLabel.TextSize                 = 15
HPLabel.Text                     = "100"
HPLabel.Visible                  = false
Instance.new("UICorner", HPLabel).CornerRadius = UDim.new(0, 6)
local HPStroke        = Instance.new("UIStroke", HPLabel)
HPStroke.Color        = Color3RGB(0, 255, 120)
HPStroke.Thickness    = 1.5
HPStroke.Transparency = 0.3

-- Chaos mode indicator label — shows which part is currently targeted
local ChaosLabel                  = Instance.new("TextLabel", TargetFrame)
ChaosLabel.Size                   = UDim2.new(1, -16, 0, 16)
ChaosLabel.Position               = UDim2.new(0, 8, 0, 58)
ChaosLabel.BackgroundTransparency = 1
ChaosLabel.TextColor3             = Color3RGB(255, 160, 40)
ChaosLabel.TextXAlignment         = Enum.TextXAlignment.Left
ChaosLabel.Font                   = Enum.Font.Gotham
ChaosLabel.TextSize               = 11
ChaosLabel.Text                   = ""
ChaosLabel.Visible                = false

local HUDLastHP   = -1
local HUDLastDist = -1

-- ============================================================
--  WINDOW
-- ============================================================
local Window = WindUI:CreateWindow({
    Title     = "KAIM v3.3",
    Author    = "by FRK",
    Folder    = "Kaim",
    Size      = UDim2.fromOffset(610, 560),
    Theme     = "Dark",
    Resizable = true,
})

Window:Tag({
    Title  = "v" .. WindUI.Version,
    Icon   = "github",
    Color  = Color3.fromHex("#1c1c1c"),
    Border = true,
})

Window:SetToggleKey(Enum.KeyCode.K)

-- ============================================================
--  TABS
-- ============================================================
local HomeTab     = Window:Tab({ Title = "Home",    Icon = "home"      })
local AimlockTab  = Window:Tab({ Title = "Aimlock",  Icon = "crosshair" })
local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "eye"       })
local PlayerTab   = Window:Tab({ Title = "Player",   Icon = "user"      })
local VisualsTab  = Window:Tab({ Title = "Visuals",  Icon = "palette"   })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings"  })

-- ============================================================
--  HOME TAB  —  feature overview & quick reference
-- ============================================================
local HomeWelcome = HomeTab:Section({ Title = "Welcome to KAIM v3.3", Opened = true })

HomeWelcome:Paragraph({
    Title = "What is KAIM?",
    Desc  = "KAIM is a lightweight, performance-focused combat utility built on WindUI. Every feature is designed to be highly configurable — nothing is hardcoded. You can tune every setting to match your playstyle and the game you're in.",
    Color = "Blue",
})

HomeWelcome:Paragraph({
    Title = "Getting Started",
    Desc  = "Press K to open and close this menu at any time. Hold Right Click (or your custom keybind) to activate aimlock while the menu is closed. All settings save via the Config system in the Settings tab.",
    Color = "Green",
})



-- ============================================================
local HomeAimlock = HomeTab:Section({ Title = "Aimlock", Opened = true })

HomeAimlock:Paragraph({
    Title = "Core Aimlock",
    Desc  = "Hold your aimlock key to lock the camera onto the nearest enemy within your FOV circle. Wall Check skips enemies behind geometry. Team Check prevents locking teammates. The lock releases the moment you let go of the key.",
    Color = "Blue",
})

HomeAimlock:Paragraph({
    Title = "Aim Modes",
    Desc  = "Smart — Automatically picks the highest-priority visible body part (Head first, then Torso, then HRP). Keeps locking even if only the torso is peeking.\n\nChaos — Randomly cycles between Head, Torso, Arms, and Legs every 0.3 seconds, never hitting the same part twice in a row. Great for bypassing per-hitbox anticheat.\n\nHead / Torso / Limbs / HRP — Force a fixed body part regardless of visibility.",
    Color = "Blue",
})

HomeAimlock:Paragraph({
    Title = "Prediction",
    Desc  = "When enabled, velocity-based prediction offsets the aim point ahead of the target so bullets land even on moving or strafing enemies. Adjust Prediction Strength (how far ahead) and Strafe Multiplier (how much side-movement is factored in) in the Aim Tuning section.",
    Color = "Blue",
})

HomeAimlock:Paragraph({
    Title = "Smooth Aiming",
    Desc  = "Instead of snapping instantly, the camera lerps toward the target each frame. Lower Smooth Speed values feel floaty and human-like; values near 1.0 are nearly instant. Use this when you want the lock to look less mechanical.",
    Color = "Blue",
})

HomeAimlock:Paragraph({
    Title = "Detection Avoidance",
    Desc  = "Random Jitter adds tiny positional noise to your aim to avoid perfect-lock detection patterns. Periodic Disable randomly pauses aimlock for short intervals so your aim history does not look robotic over time. Both are tunable in the Advanced section.",
    Color = "Grey",
})

-- ============================================================
local HomeESP = HomeTab:Section({ Title = "ESP", Opened = true })

HomeESP:Paragraph({
    Title = "2D Boxes & Names",
    Desc  = "Draws a 2D bounding box around every enemy player scaled to their on-screen height. Display Name, Username, or Both can appear above the box. An optional dark outline adds contrast against bright backgrounds.",
    Color = "Blue",
})

HomeESP:Paragraph({
    Title = "Visibility Colors",
    Desc  = "When enabled, boxes and names switch between two colors depending on whether you have line-of-sight to the target. Visible Color is shown when the enemy is exposed; Hidden Color when they are behind a wall. Both are fully customisable.",
    Color = "Blue",
})

HomeESP:Paragraph({
    Title = "Health Bar",
    Desc  = "A vertical bar on the left side of each box shows the enemy's current health as a percentage. The bar color transitions from green (full HP) through yellow and orange to red (low HP) automatically.",
    Color = "Blue",
})

HomeESP:Paragraph({
    Title = "Chams",
    Desc  = "Uses Roblox's native Highlight system to paint a colored fill and outline over enemy characters. See Through Walls mode shows chams even when enemies are fully behind geometry. Fill and outline colors are set independently.",
    Color = "Blue",
})

HomeESP:Paragraph({
    Title = "Tracer & Snap Lines",
    Desc  = "Tracer Lines draw a line from a chosen screen edge (Bottom, Center, or Top) to each enemy. Snap Lines draw from the exact screen center. Both have independent color pickers and can be used together.",
    Color = "Blue",
})

HomeESP:Paragraph({
    Title = "ESP Range",
    Desc  = "The ESP Range slider (100–5000 studs) culls any enemy beyond that distance before any drawing work is done, keeping performance high in large open-world maps.",
    Color = "Grey",
})

-- ============================================================
local HomePlayer = HomeTab:Section({ Title = "Player", Opened = true })

HomePlayer:Paragraph({
    Title = "Walk Speed & Jump Power",
    Desc  = "Override your character's WalkSpeed and JumpPower to any value. Toggle each on or off independently — turning them off restores the game's default values immediately.",
    Color = "Blue",
})

HomePlayer:Paragraph({
    Title = "Noclip",
    Desc  = "Disables collision on all your character parts so you can move through walls and floors. Original collision states are cached on enable and restored exactly on disable — no permanently broken hitboxes. Assign any keyboard key to toggle it without opening the menu.",
    Color = "Blue",
})

-- ============================================================
local HomeVisuals = HomeTab:Section({ Title = "Visuals", Opened = true })

HomeVisuals:Paragraph({
    Title = "FOV Circle",
    Desc  = "A configurable circle that shows the aimlock detection radius. Follow Cursor mode moves it with your mouse so the circle always matches exactly where the aimlock will search. Screen Center mode locks it to the middle of the screen. Radius, thickness, color, and transparency are all adjustable.",
    Color = "Blue",
})

HomeVisuals:Paragraph({
    Title = "Filled FOV",
    Desc  = "An optional semi-transparent fill inside the FOV ring. Fill color and transparency are set independently from the ring outline, so you can have a bright ring with a barely-visible interior tint.",
    Color = "Blue",
})

HomeVisuals:Paragraph({
    Title = "Target HUD",
    Desc  = "A small card that appears at the bottom of your screen while you are locked onto a target. Shows the enemy's display name and distance in studs. Optionally shows exact HP as a badge. The card border turns orange when locking through a wall (Smart or Chaos mode only).",
    Color = "Blue",
})

-- ============================================================
local HomeSettings = HomeTab:Section({ Title = "Settings & Config", Opened = true })

HomeSettings:Paragraph({
    Title = "Config System",
    Desc  = "Save Config writes every toggle, slider, dropdown, keybind, and color picker to a JSON file in your executor's workspace folder under Kaim/config/kaim_config.json. Load Config restores all settings from that file. This persists between sessions.",
    Color = "Blue",
})

HomeSettings:Paragraph({
    Title = "Themes",
    Desc  = "Switch between Dark, Light, and Rose WindUI themes instantly from the Settings tab. The theme change applies to all menus immediately with no restart needed.",
    Color = "Blue",
})

-- ============================================================
local HomeKeybinds = HomeTab:Section({ Title = "Keybind Reference", Opened = true })

HomeKeybinds:Paragraph({
    Title = "Default Keybinds",
    Desc  = "K  —  Open / close the KAIM menu\nRight Click  —  Hold to activate aimlock\nN  —  Toggle noclip on / off\n\nAll three keybinds are fully rebindable inside the menu.",
    Color = "Green",
})

HomeKeybinds:Paragraph({
    Title = "Tips",
    Desc  = "• Aimlock only activates while the key is held — releasing it immediately drops the lock and returns camera control to you.\n• In Chaos mode the Target HUD shows which body part is currently being targeted in real time (⚡ PartName).\n• The FOV circle is the true search boundary — if an enemy is outside it, they will never be locked.",
    Color = "Grey",
})

-- ============================================================
--  AIMLOCK TAB
-- ============================================================
local AimSection = AimlockTab:Section({ Title = "Aimlock Control", Opened = true })

AimSection:Toggle({
    Title    = "Enable Aimlock",
    Desc     = "Master toggle for the aimlock system",
    Flag     = "AimlockEnabled",
    Value    = false,
    Callback = function(v) Settings.Aimlock.Enabled = v end,
})

AimSection:Keybind({
    Title    = "Aimlock Key",
    Desc     = "Hold this key to lock onto the nearest target",
    Flag     = "AimlockKeybind",
    Value    = "RightClick",
    Callback = function(v) Settings.Aimlock.Keybind = v end,
})

AimSection:Toggle({
    Title    = "Wall Check",
    Desc     = "Ignore targets that are behind walls",
    Flag     = "AimlockWallCheck",
    Value    = true,
    Callback = function(v) Settings.Aimlock.WallCheck = v end,
})

AimSection:Toggle({
    Title    = "Team Check",
    Desc     = "Never lock onto players on your team",
    Flag     = "AimlockTeamCheck",
    Value    = true,
    Callback = function(v) Settings.Aimlock.TeamCheck = v end,
})

local AimTuning = AimlockTab:Section({ Title = "Aim Tuning", Opened = true })

AimTuning:Dropdown({
    Title    = "Aim Mode",
    Desc     = "Smart = highest visible part. Chaos = randomises every 0.3s. Others force a fixed part.",
    Flag     = "AimlockAimMode",
    Values   = { "Smart", "Chaos", "Head", "Torso", "Limbs", "HRP" },
    Value    = "Smart",
    Callback = function(v)
        Settings.Aimlock.AimMode = v
        -- Reset chaos state when switching to Chaos so it starts fresh
        if v == "Chaos" then
            chaosTimer       = 0
            chaosLastPart    = ""
            chaosCurrentPart = PickNextChaosPart()
        end
    end,
})

AimTuning:Toggle({
    Title    = "Enable Prediction",
    Desc     = "Apply velocity-based prediction to lead moving targets",
    Flag     = "AimlockPredictionEnabled",
    Value    = true,
    Callback = function(v) Settings.Aimlock.PredictionEnabled = v end,
})

AimTuning:Slider({
    Title    = "Prediction Strength",
    Desc     = "How far ahead to lead moving targets (seconds)",
    Flag     = "AimlockPrediction",
    Step     = 0.005,
    Value    = { Min = 0, Max = 0.3, Default = 0.135 },
    Callback = function(v) Settings.Aimlock.Prediction = v end,
})

AimTuning:Slider({
    Title    = "Strafe Multiplier",
    Desc     = "Velocity scale for strafing targets",
    Flag     = "AimlockStrafePrediction",
    Step     = 0.05,
    Value    = { Min = 0.5, Max = 2.5, Default = 1.0 },
    Callback = function(v) Settings.Aimlock.StrafePrediction = v end,
})

local AdvAim = AimlockTab:Section({ Title = "Advanced", Opened = false })

AdvAim:Toggle({
    Title    = "Smooth Aiming",
    Desc     = "Gradually lerp the camera to the target",
    Flag     = "AimlockSmooth",
    Value    = false,
    Callback = function(v) Settings.Aimlock.SmoothAiming = v end,
})

AdvAim:Slider({
    Title    = "Smooth Speed",
    Desc     = "Lerp factor — higher feels snappier",
    Flag     = "AimlockSmoothSpeed",
    Step     = 0.05,
    Value    = { Min = 0.05, Max = 1.0, Default = 0.3 },
    Callback = function(v) Settings.Aimlock.SmoothSpeed = v end,
})

AdvAim:Toggle({
    Title    = "Random Jitter",
    Desc     = "Add subtle noise to aim to look more human",
    Flag     = "AimlockJitter",
    Value    = false,
    Callback = function(v) Settings.DetectionAvoidance.RandomJitter = v end,
})

AdvAim:Slider({
    Title    = "Jitter Amount",
    Desc     = "Strength of random aim displacement",
    Flag     = "AimlockJitterAmount",
    Step     = 0.005,
    Value    = { Min = 0, Max = 0.2, Default = 0.05 },
    Callback = function(v) Settings.DetectionAvoidance.JitterAmount = v end,
})

AdvAim:Toggle({
    Title    = "Periodic Disable",
    Desc     = "Randomly pause aimlock to avoid detection",
    Flag     = "AimlockPeriodicDisable",
    Value    = false,
    Callback = function(v) Settings.DetectionAvoidance.PeriodicAimDisable = v end,
})

AdvAim:Slider({
    Title    = "Disable Chance",
    Desc     = "Probability per cycle that aimlock pauses",
    Flag     = "AimlockDisableChance",
    Step     = 0.01,
    Value    = { Min = 0, Max = 1.0, Default = 0.1 },
    Callback = function(v) Settings.DetectionAvoidance.DisableChance = v end,
})

-- ============================================================
--  ESP TAB
-- ============================================================
local ESPCore = ESPTab:Section({ Title = "ESP Core", Opened = true })

ESPCore:Toggle({
    Title    = "Enable ESP",
    Desc     = "Show player boxes, names, and health",
    Flag     = "ESPEnabled",
    Value    = false,
    Callback = function(v) Settings.Visuals.ESPEnabled = v end,
})

ESPCore:Toggle({
    Title    = "Team Check",
    Desc     = "Do not show ESP on players in your team",
    Flag     = "ESPTeamCheck",
    Value    = true,
    Callback = function(v) Settings.Visuals.TeamCheck = v end,
})

ESPCore:Toggle({
    Title    = "Show Teammates",
    Desc     = "Highlight your teammates with a separate color",
    Flag     = "ESPShowTeammates",
    Value    = false,
    Callback = function(v) Settings.Visuals.ShowTeammates = v end,
})

ESPCore:Colorpicker({
    Title    = "Teammate Color",
    Desc     = "Color used for teammate ESP overlays",
    Flag     = "ESPTeammateColor",
    Default  = Color3RGB(0, 200, 255),
    Callback = function(v) Settings.Visuals.TeammateColor = v end,
})

local BoxSection = ESPTab:Section({ Title = "Box", Opened = true })

BoxSection:Toggle({
    Title    = "ESP Boxes",
    Desc     = "Draw a bounding box around each player",
    Flag     = "ESPBoxes",
    Value    = true,
    Callback = function(v) Settings.Visuals.ESPBoxes = v end,
})

BoxSection:Toggle({
    Title    = "Box Outline",
    Desc     = "Add a dark outline behind the box for contrast",
    Flag     = "ESPOutline",
    Value    = true,
    Callback = function(v) Settings.Visuals.ESPOutline = v end,
})

local ColorSection = ESPTab:Section({ Title = "Colors", Opened = true })

ColorSection:Toggle({
    Title    = "Visibility Colors",
    Desc     = "Use different colors for visible vs hidden targets",
    Flag     = "ESPVisColors",
    Value    = true,
    Callback = function(v) Settings.Visuals.UseVisColors = v end,
})

ColorSection:Colorpicker({
    Title    = "Visible Color",
    Desc     = "ESP color when you have line-of-sight on the target",
    Flag     = "ESPVisColor",
    Default  = Color3RGB(50, 255, 80),
    Callback = function(v) Settings.Visuals.VisColor = v end,
})

ColorSection:Colorpicker({
    Title    = "Hidden Color",
    Desc     = "ESP color when target is behind a wall",
    Flag     = "ESPHiddenColor",
    Default  = Color3RGB(255, 60, 60),
    Callback = function(v) Settings.Visuals.HiddenColor = v end,
})

local TextSection = ESPTab:Section({ Title = "Text & Names", Opened = true })

TextSection:Toggle({
    Title    = "Show Names",
    Desc     = "Display the player name above their box",
    Flag     = "ESPNames",
    Value    = true,
    Callback = function(v) Settings.Visuals.ESPNames = v end,
})

TextSection:Dropdown({
    Title    = "Name Style",
    Desc     = "Which name format to display",
    Flag     = "ESPNameStyle",
    Values   = { "Display Name", "Username", "Both" },
    Value    = "Display Name",
    Callback = function(v) Settings.Visuals.ESPNameStyle = v end,
})

TextSection:Slider({
    Title    = "Text Scale",
    Desc     = "Size of all ESP text",
    Flag     = "ESPTextScale",
    Step     = 1,
    Value    = { Min = 10, Max = 22, Default = 14 },
    Callback = function(v) Settings.Visuals.ESPTextScale = v end,
})

TextSection:Toggle({
    Title    = "Custom Name Color",
    Desc     = "Use a fixed color for names instead of the box color",
    Flag     = "ESPCustomNameColor",
    Value    = false,
    Callback = function(v)
        Settings.Visuals.UseCustomNameColor = v
        for _, esp in pairs(ESPObjects) do esp._lastNameCol = nil end
    end,
})

TextSection:Colorpicker({
    Title    = "Display Name Color",
    Desc     = "Color for the display name label (requires Custom Name Color on)",
    Flag     = "ESPNameColor",
    Default  = Color3RGB(255, 255, 255),
    Callback = function(v)
        Settings.Visuals.ESPNameColor = v
        for _, esp in pairs(ESPObjects) do esp._lastNameCol = nil end
    end,
})

TextSection:Colorpicker({
    Title    = "Username Color",
    Desc     = "Color for the @username label (requires Custom Name Color on)",
    Flag     = "ESPUsernameColor",
    Default  = Color3RGB(180, 180, 200),
    Callback = function(v)
        Settings.Visuals.ESPUsernameColor = v
        for _, esp in pairs(ESPObjects) do esp._lastNameCol = nil end
    end,
})

local HealthSection = ESPTab:Section({ Title = "Health", Opened = true })

HealthSection:Toggle({
    Title    = "Health Bar",
    Desc     = "Draw a color-coded health bar on the left side of the box",
    Flag     = "ESPHealthBar",
    Value    = true,
    Callback = function(v) Settings.Visuals.HealthBar = v end,
})

HealthSection:Toggle({
    Title    = "Health Numbers",
    Desc     = "Display the exact HP value below the box",
    Flag     = "ESPHealthNumbers",
    Value    = false,
    Callback = function(v) Settings.Visuals.HealthNumbers = v end,
})

local DistSection = ESPTab:Section({ Title = "Distance", Opened = true })

DistSection:Slider({
    Title    = "ESP Range",
    Desc     = "Only render ESP on players closer than this (studs)",
    Flag     = "ESPRange",
    Step     = 100,
    Value    = { Min = 100, Max = 5000, Default = 1000 },
    Callback = function(v) Settings.Visuals.MaxESPDistance = v end,
})

DistSection:Toggle({
    Title    = "Distance Display",
    Desc     = "Show stud distance below each player box",
    Flag     = "ESPDistDisplay",
    Value    = false,
    Callback = function(v) Settings.Visuals.DistanceDisplay = v end,
})

local ChamsSection = ESPTab:Section({ Title = "Chams", Opened = false })

ChamsSection:Toggle({
    Title    = "Enable Chams",
    Desc     = "Highlight player characters using Roblox Highlight",
    Flag     = "ChamsEnabled",
    Value    = false,
    Callback = function(v) Settings.Visuals.ChamsEnabled = v end,
})

ChamsSection:Toggle({
    Title    = "See Through Walls",
    Desc     = "Show chams even when player is behind geometry",
    Flag     = "ChamsDepth",
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
    end,
})

ChamsSection:Colorpicker({
    Title    = "Fill Color",
    Desc     = "Interior color of the Highlight",
    Flag     = "ChamsFill",
    Default  = Color3RGB(255, 30, 30),
    Callback = function(v) Settings.Visuals.ChamsFillColor = v end,
})

ChamsSection:Colorpicker({
    Title    = "Outline Color",
    Desc     = "Outline color of the Highlight",
    Flag     = "ChamsOutline",
    Default  = Color3RGB(255, 255, 255),
    Callback = function(v) Settings.Visuals.ChamsOutlineColor = v end,
})

local LinesSection = ESPTab:Section({ Title = "Lines", Opened = false })

LinesSection:Toggle({
    Title    = "Tracer Lines",
    Desc     = "Draw a line from screen edge to each enemy",
    Flag     = "TracerLines",
    Value    = false,
    Callback = function(v) Settings.Visuals.TracerLines = v end,
})

LinesSection:Dropdown({
    Title    = "Tracer Origin",
    Desc     = "Where on-screen the tracer line starts",
    Flag     = "TracerOrigin",
    Values   = { "Bottom", "Center", "Top" },
    Value    = "Bottom",
    Callback = function(v) Settings.Visuals.TracerOrigin = v end,
})

LinesSection:Colorpicker({
    Title    = "Tracer Color",
    Flag     = "TracerColor",
    Default  = Color3RGB(0, 200, 255),
    Callback = function(v) Settings.Visuals.TracerColor = v end,
})

LinesSection:Toggle({
    Title    = "Snap Lines",
    Desc     = "Draw a line from screen center to each enemy",
    Flag     = "SnapLines",
    Value    = false,
    Callback = function(v) Settings.Visuals.SnapLines = v end,
})

LinesSection:Colorpicker({
    Title    = "Snap Line Color",
    Flag     = "SnapLineColor",
    Default  = Color3RGB(255, 0, 220),
    Callback = function(v) Settings.Visuals.SnapLineColor = v end,
})

-- ============================================================
--  PLAYER TAB
-- ============================================================
local SpeedSection = PlayerTab:Section({ Title = "Walk Speed", Opened = true })

SpeedSection:Toggle({
    Title    = "Enable Walk Speed",
    Flag     = "WalkSpeedEnabled",
    Value    = false,
    Callback = function(v) Settings.Player.WalkSpeedEnabled = v end,
})

SpeedSection:Slider({
    Title    = "Walk Speed",
    Desc     = "Default Roblox walk speed is 16",
    Flag     = "WalkSpeed",
    Step     = 1,
    Value    = { Min = 5, Max = 100, Default = 16 },
    Callback = function(v) Settings.Player.WalkSpeed = v end,
})

local JumpSection = PlayerTab:Section({ Title = "Jump Power", Opened = true })

JumpSection:Toggle({
    Title    = "Enable Jump Power",
    Flag     = "JumpPowerEnabled",
    Value    = false,
    Callback = function(v) Settings.Player.JumpPowerEnabled = v end,
})

JumpSection:Slider({
    Title    = "Jump Power",
    Desc     = "Default Roblox jump power is 50",
    Flag     = "JumpPower",
    Step     = 5,
    Value    = { Min = 10, Max = 250, Default = 50 },
    Callback = function(v) Settings.Player.JumpPower = v end,
})

local NoclipSection = PlayerTab:Section({ Title = "Noclip", Opened = true })

local noclipConn      = nil
local noclipPartCache = {}
local noclipCharConn  = nil

local function BuildNoclipCache(char)
    noclipPartCache = {}
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            noclipPartCache[#noclipPartCache + 1] = { part = p, original = p.CanCollide }
        end
    end
end

local function SetNoclip(state)
    Settings.Player.NoclipEnabled = state

    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end

    if state then
        BuildNoclipCache(LocalPlayer.Character)
        noclipConn = RunService.Stepped:Connect(function()
            for _, entry in ipairs(noclipPartCache) do
                if entry.part and entry.part.CanCollide then
                    entry.part.CanCollide = false
                end
            end
        end)
    else
        for _, entry in ipairs(noclipPartCache) do
            if entry.part then
                entry.part.CanCollide = entry.original
            end
        end
        noclipPartCache = {}
    end
end

if noclipCharConn then noclipCharConn:Disconnect() end
noclipCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
    if Settings.Player.NoclipEnabled then
        task.defer(function() BuildNoclipCache(char) end)
    end
end)

NoclipSection:Toggle({
    Title    = "Enable Noclip",
    Desc     = "Phase through all parts and walls",
    Flag     = "Noclip",
    Value    = false,
    Callback = function(v) SetNoclip(v) end,
})

-- FIX: single Keybind element — both updates Settings AND the cached KeyCode.
--      v3.1 had a duplicate "NoclipKeybindSync" element below InputBegan which
--      caused two keybind controls to appear in the Player tab.
local cachedNoclipKC = Enum.KeyCode.N

NoclipSection:Keybind({
    Title    = "Noclip Keybind",
    Desc     = "Press to toggle Noclip on/off",
    Flag     = "NoclipKeybind",
    Value    = "N",
    Callback = function(v)
        Settings.Player.NoclipKeybind = v
        local ok, kc = pcall(function() return Enum.KeyCode[v] end)
        if ok and kc then cachedNoclipKC = kc end
    end,
})

-- ============================================================
--  VISUALS TAB
-- ============================================================
local FOVSection = VisualsTab:Section({ Title = "FOV Circle", Opened = true })

FOVSection:Toggle({
    Title    = "Show FOV Circle",
    Desc     = "Display the aimlock FOV ring on screen",
    Flag     = "FOVVisible",
    Value    = true,
    Callback = function(v) Settings.FOV.Visible = v end,
})

FOVSection:Toggle({
    Title    = "Follow Cursor",
    Desc     = "ON = circle follows your mouse  |  OFF = locked to screen center",
    Flag     = "FOVFollowCursor",
    Value    = true,
    Callback = function(v) Settings.FOV.FollowCursor = v end,
})

FOVSection:Slider({
    Title    = "FOV Radius",
    Desc     = "Size of the FOV circle in pixels",
    Flag     = "FOVRadius",
    Step     = 5,
    Value    = { Min = 30, Max = 600, Default = 150 },
    Callback = function(v) Settings.FOV.Radius = v end,
})

FOVSection:Slider({
    Title    = "Ring Thickness",
    Desc     = "Thickness of the FOV ring outline",
    Flag     = "FOVThickness",
    Step     = 0.5,
    Value    = { Min = 0.5, Max = 6, Default = 1.5 },
    Callback = function(v)
        Settings.FOV.Thickness = v
        FOVRing.Thickness      = v
    end,
})

FOVSection:Slider({
    Title    = "Ring Transparency",
    Desc     = "0 = fully opaque  |  1 = invisible",
    Flag     = "FOVTransparency",
    Step     = 0.05,
    Value    = { Min = 0, Max = 1, Default = 0.8 },
    Callback = function(v)
        Settings.FOV.Transparency = v
        FOVRing.Transparency      = v
    end,
})

FOVSection:Colorpicker({
    Title    = "Ring Color",
    Desc     = "Color of the FOV ring outline",
    Flag     = "FOVColor",
    Default  = Color3RGB(255, 255, 255),
    Callback = function(v)
        Settings.FOV.Color = v
        FOVRing.Color      = v
    end,
})

FOVSection:Toggle({
    Title    = "Filled Circle",
    Desc     = "Draw a semi-transparent fill inside the FOV ring",
    Flag     = "FOVFilled",
    Value    = false,
    Callback = function(v) Settings.FOV.Filled = v end,
})

FOVSection:Slider({
    Title    = "Fill Transparency",
    Desc     = "Transparency of the filled interior (higher = more transparent)",
    Flag     = "FOVFilledTransp",
    Step     = 0.02,
    Value    = { Min = 0.5, Max = 1, Default = 0.92 },
    Callback = function(v)
        Settings.FOV.FilledTransp = v
        FOVFill.Transparency      = v
    end,
})

FOVSection:Colorpicker({
    Title    = "Fill Color",
    Desc     = "Color of the filled circle interior",
    Flag     = "FOVFillColor",
    Default  = Color3RGB(255, 255, 255),
    Callback = function(v)
        Settings.FOV.FilledColor = v
        FOVFill.Color            = v
    end,
})

local HUDSection = VisualsTab:Section({ Title = "Target HUD", Opened = true })

HUDSection:Toggle({
    Title    = "Show Target HUD",
    Desc     = "Show info card at bottom of screen while aiming",
    Flag     = "HUDEnabled",
    Value    = true,
    Callback = function(v) Settings.Visuals.TargetUI = v end,
})

HUDSection:Toggle({
    Title    = "Health on HUD",
    Desc     = "Show exact HP number on the target card",
    Flag     = "HUDHealth",
    Value    = false,
    Callback = function(v) Settings.Visuals.HealthNumbers = v end,
})

HUDSection:Dropdown({
    Title    = "Health Number Position",
    Desc     = "Where the HP badge appears on the target card",
    Flag     = "HUDHealthPos",
    Values   = { "TopRight", "TopLeft", "BottomRight", "BottomLeft" },
    Value    = "TopRight",
    Callback = function(v) Settings.Visuals.HealthPosition = v end,
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
    Flag     = "UIToggleKey",
    Value    = "K",
    Callback = function(v)
        Settings.UI.ToggleKey = v
        local ok, kc = pcall(function() return Enum.KeyCode[v] end)
        if ok and kc then Window:SetToggleKey(kc) end
    end,
})

local ThemeSection = SettingsTab:Section({ Title = "Theme", Opened = true })
ThemeSection:Button({ Title = "Dark Theme",  Callback = function() WindUI:SetTheme("Dark")  end })
ThemeSection:Button({ Title = "Light Theme", Callback = function() WindUI:SetTheme("Light") end })
ThemeSection:Button({ Title = "Rose Theme",  Callback = function() WindUI:SetTheme("Rose")  end })

local ConfigSection = SettingsTab:Section({ Title = "Config", Opened = true })

ConfigSection:Paragraph({
    Title = "Config System",
    Desc  = "Save and load all your settings. Config is stored in your executor's workspace folder under Kaim/config/.",
    Color = "Blue",
})

local ConfigManager = Window.ConfigManager
local KaimConfig    = ConfigManager:CreateConfig("kaim_config")
KaimConfig:Register(Window)

ConfigSection:Button({
    Title    = "Save Config",
    Callback = function()
        KaimConfig:Save()
        WindUI:Notify({ Title = "Config Saved", Content = "Settings saved to kaim_config.json", Duration = 3, Icon = "save" })
    end,
})

ConfigSection:Button({
    Title    = "Load Config",
    Callback = function()
        KaimConfig:Load()
        WindUI:Notify({ Title = "Config Loaded", Content = "Settings loaded from kaim_config.json", Duration = 3, Icon = "folder-open" })
    end,
})

local InfoSection = SettingsTab:Section({ Title = "About KAIM", Opened = true })

InfoSection:Paragraph({
    Title = "KAIM v3.3",
    Desc  = "Advanced Aimlock & Combat Hub — built with WindUI.",
    Color = "Blue",
})

InfoSection:Paragraph({
    Title = "Features",
    Desc  = "Smart Aimlock  •  Chaos Mode  •  Velocity Prediction  •  2D ESP + Health Bar  •  Chams  •  Player Mods  •  FOV Ring  •  Target HUD  •  Snap & Tracer Lines  •  Config Save/Load",
    Color = "Green",
})

InfoSection:Paragraph({
    Title = "Keybinds",
    Desc  = "UI Toggle: K (changeable above)\nAimlock: Right Click (changeable in Aimlock tab)",
    Color = "Grey",
})

-- ============================================================
--  TEAM CACHE
-- ============================================================
local TeamCache = {}

local function InvalidateTeamCache(player)
    TeamCache[player] = nil
end

Players.PlayerAdded:Connect(function(player)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        InvalidateTeamCache(player)
    end)
end)

local function IsTeammateCached(player)
    local v = TeamCache[player]
    if v == nil then
        v = (player.Team ~= nil) and (player.Team == LocalPlayer.Team) or false
        TeamCache[player] = v
    end
    return v
end

-- ============================================================
--  RAYCAST PARAMS CACHE
-- ============================================================
local RayParamsCache = {}

local function GetRayParams(player, char)
    local cached = RayParamsCache[player]
    if cached and cached.char == char then
        if cached.filter[1] ~= LocalPlayer.Character then
            cached.filter[1]                         = LocalPlayer.Character
            cached.params.FilterDescendantsInstances = cached.filter
        end
        return cached.params
    end
    local filter = { LocalPlayer.Character, char }
    local p      = RaycastParams.new()
    p.FilterDescendantsInstances = filter
    p.FilterType                 = Enum.RaycastFilterType.Exclude
    p.IgnoreWater                = true
    RayParamsCache[player] = { char = char, params = p, filter = filter }
    return p
end

-- ============================================================
--  ESP OBJECTS
-- ============================================================
local ESPObjects = {}

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================
local function IsVisible(targetPart, targetChar, player)
    local camCF     = Camera.CFrame.Position
    local direction = targetPart.Position - camCF
    local params    = GetRayParams(player, targetChar)
    local result    = workspace:Raycast(camCF, direction, params)
    return result == nil
end

local function IsTargetAlive(player)
    if not player or not player.Character then return false end
    if Settings.Aimlock.TeamCheck and IsTeammateCached(player) then return false end
    local hum  = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    return (hum.Health or 0) > 0
end

-- Smart aim: returns first visible part in priority order.
local SMART_PRIORITY = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

local function GetSmartAimPart(char, player)
    for _, partName in ipairs(SMART_PRIORITY) do
        local part = char:FindFirstChild(partName)
        if part and IsVisible(part, char, player) then
            return part, true
        end
    end
    return char:FindFirstChild("HumanoidRootPart"), false
end

-- Chaos aim: returns the currently active chaosCurrentPart, falling back
-- down a short priority list if that part doesn't exist on this character
-- (e.g. an R6 rig won't have UpperTorso, so we fall back to Torso).
local CHAOS_FALLBACKS = {
    UpperTorso    = { "Torso", "HumanoidRootPart" },
    LeftUpperArm  = { "LeftArm",  "HumanoidRootPart" },
    RightUpperArm = { "RightArm", "HumanoidRootPart" },
    LeftUpperLeg  = { "LeftLeg",  "HumanoidRootPart" },
    RightUpperLeg = { "RightLeg", "HumanoidRootPart" },
}

local function GetChaosAimPart(char)
    local primary = char:FindFirstChild(chaosCurrentPart)
    if primary then return primary end
    local fallbacks = CHAOS_FALLBACKS[chaosCurrentPart]
    if fallbacks then
        for _, fb in ipairs(fallbacks) do
            local p = char:FindFirstChild(fb)
            if p then return p end
        end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetAimPart(character, player)
    local mode = Settings.Aimlock.AimMode
    if mode == "Smart" then
        return GetSmartAimPart(character, player)
    elseif mode == "Chaos" then
        -- Chaos returns a single value; lockIsVisible defaults to true at call site
        return GetChaosAimPart(character)
    elseif mode == "Head" then
        return character:FindFirstChild("Head")
    elseif mode == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    elseif mode == "Limbs" then
        local la = character:FindFirstChild("LeftUpperArm")
        local ra = character:FindFirstChild("RightUpperArm")
        if la and ra then return mathRandom() < 0.5 and la or ra end
        return la or ra
    elseif mode == "HRP" then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function AddJitter(position)
    if not Settings.DetectionAvoidance.RandomJitter then return position end
    local j = Settings.DetectionAvoidance.JitterAmount
    return position + Vector3New(
        (mathRandom() - 0.5) * j * 2,
        (mathRandom() - 0.5) * j * 2,
        (mathRandom() - 0.5) * j * 2
    )
end

-- ============================================================
--  COLOR HELPERS
-- ============================================================
local function GetHealthColor(pct)
    if pct > 0.80 then return Color3RGB(0,   255, 100) end
    if pct > 0.60 then return Color3RGB(100, 255, 50)  end
    if pct > 0.40 then return Color3RGB(255, 200, 0)   end
    if pct > 0.20 then return Color3RGB(255, 130, 0)   end
    return                  Color3RGB(255, 50,  50)
end

local function GetDistanceColor(dist)
    if dist < 50  then return Color3RGB(0,   255, 100) end
    if dist < 100 then return Color3RGB(100, 255, 100) end
    if dist < 200 then return Color3RGB(255, 210, 0)   end
    if dist < 350 then return Color3RGB(255, 140, 0)   end
    return                  Color3RGB(255, 90,  90)
end

-- ============================================================
--  GET CLOSEST PLAYER
-- ============================================================
local CLOSEST_THROTTLE    = 4
local closestThrottleTick = CLOSEST_THROTTLE   -- start at max so first press fires immediately

local function GetClosestPlayer()
    local fovSq         = Settings.FOV.Radius * Settings.FOV.Radius
    local closestDistSq = fovSq
    local closestTarget = nil
    local refPos
    if Settings.FOV.FollowCursor then
        refPos = UserInputService:GetMouseLocation()
    else
        local vp = Camera.ViewportSize
        refPos   = Vector2New(vp.X * 0.5, vp.Y * 0.5)
    end
    local cx        = refPos.X
    local cy        = refPos.Y
    local aimCheck  = Settings.Aimlock.WallCheck
    local teamCheck = Settings.Aimlock.TeamCheck
    local isSmart   = Settings.Aimlock.AimMode == "Smart"

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        if teamCheck and IsTeammateCached(player) then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or (hum.Health or 0) <= 0 then continue end

        local part, partIsVisible
        if isSmart then
            part, partIsVisible = GetSmartAimPart(char, player)
            if aimCheck and not partIsVisible then continue end
        else
            part = GetAimPart(char, player) or char:FindFirstChild("HumanoidRootPart")
            if not part then continue end
            if aimCheck and not IsVisible(part, char, player) then continue end
        end

        if not part then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dx  = cx - sp.X
        local dy  = cy - sp.Y
        local dSq = dx * dx + dy * dy
        if dSq < closestDistSq then
            closestDistSq = dSq
            closestTarget = player
        end
    end
    return closestTarget
end

-- ============================================================
--  CREATE ESP OBJECT
-- ============================================================
local BLACK = Color3RGB(0, 0, 0)

local function CreateESP(player)
    local ok, err = pcall(function()
        local esp = {
            Box          = Drawing.new("Square"),
            BoxOutline   = Drawing.new("Square"),
            Name         = Drawing.new("Text"),
            Username     = Drawing.new("Text"),
            Distance     = Drawing.new("Text"),
            Health       = Drawing.new("Text"),
            BarBG        = Drawing.new("Square"),
            BarFG        = Drawing.new("Square"),
            Highlight    = Instance.new("Highlight"),
            SnapLine     = nil,
            _onScreen    = false,
            _screenRootX = 0,
            _screenRootY = 0,
            _screenHeadY = 0,
            _screenDepth = 0,
            _isVisible   = false,
            _lastVisible  = false,
            _lastColor    = nil,
            _lastBoxX     = 0,
            _lastBoxY     = 0,
            _lastBoxW     = 0,
            _lastBoxH     = 0,
            _lastDist     = -1,
            _lastHP       = -1,
            _lastHPPct    = -1,
            _lastNameTxt  = "",
            _lastUserTxt  = "",
            _lastNameCol  = nil,
            _staggerSlot  = 0,
        }

        esp.Box.Visible      = false
        esp.Box.Thickness    = 1.5
        esp.Box.Transparency = 0.8
        esp.Box.Filled       = false

        esp.BoxOutline.Visible      = false
        esp.BoxOutline.Thickness    = 3.5
        esp.BoxOutline.Transparency = 0.6
        esp.BoxOutline.Filled       = false
        esp.BoxOutline.Color        = BLACK

        esp.Name.Visible      = false
        esp.Name.Size         = Settings.Visuals.ESPTextScale
        esp.Name.Center       = true
        esp.Name.Outline      = true
        esp.Name.OutlineColor = BLACK
        esp.Name.Font         = 2

        esp.Username.Visible      = false
        esp.Username.Size         = mathMax(10, Settings.Visuals.ESPTextScale - 2)
        esp.Username.Center       = true
        esp.Username.Outline      = true
        esp.Username.OutlineColor = BLACK
        esp.Username.Color        = Color3RGB(180, 180, 200)
        esp.Username.Font         = 2

        esp.Distance.Visible      = false
        esp.Distance.Size         = mathMax(10, Settings.Visuals.ESPTextScale - 2)
        esp.Distance.Center       = true
        esp.Distance.Outline      = true
        esp.Distance.OutlineColor = BLACK
        esp.Distance.Font         = 2

        esp.Health.Visible      = false
        esp.Health.Size         = mathMax(10, Settings.Visuals.ESPTextScale - 2)
        esp.Health.Center       = true
        esp.Health.Outline      = true
        esp.Health.OutlineColor = BLACK
        esp.Health.Font         = 2

        esp.BarBG.Visible      = false
        esp.BarBG.Filled       = true
        esp.BarBG.Transparency = 0.4
        esp.BarBG.Color        = Color3RGB(20, 20, 20)
        esp.BarBG.Thickness    = 1

        esp.BarFG.Visible      = false
        esp.BarFG.Filled       = true
        esp.BarFG.Transparency = 0.1
        esp.BarFG.Thickness    = 1

        esp.Highlight.Parent    = ChamsFolder
        esp.Highlight.Enabled   = false
        esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        ESPObjects[player] = esp
    end)
    if not ok then
        warn("KAIM | CreateESP error for " .. tostring(player) .. ": " .. tostring(err))
    end
end

-- ============================================================
--  STAGGER REGISTRATION
-- ============================================================
local staggerCounter = 0
local STAGGER_MOD    = 3

local function RegisterPlayer(player)
    if player == LocalPlayer then return end
    CreateESP(player)
    local esp = ESPObjects[player]
    if esp then
        staggerCounter   = staggerCounter + 1
        esp._staggerSlot = staggerCounter % STAGGER_MOD
    end
end

for _, p in ipairs(Players:GetPlayers()) do RegisterPlayer(p) end
Players.PlayerAdded:Connect(RegisterPlayer)

Players.PlayerRemoving:Connect(function(player)
    local esp = ESPObjects[player]
    if not esp then return end
    pcall(function()
        esp.Box:Remove();       esp.BoxOutline:Remove()
        esp.Name:Remove();      esp.Username:Remove()
        esp.Distance:Remove();  esp.Health:Remove()
        esp.BarBG:Remove();     esp.BarFG:Remove()
        if esp.SnapLine then esp.SnapLine:Remove() end
        esp.Highlight:Destroy()
    end)
    ESPObjects[player]     = nil
    TeamCache[player]      = nil
    RayParamsCache[player] = nil
end)

-- ============================================================
--  HIDE ESP
-- ============================================================
local function HideESP(esp)
    if not esp._lastVisible then return end
    esp.Box.Visible        = false
    esp.BoxOutline.Visible = false
    esp.Name.Visible       = false
    esp.Username.Visible   = false
    esp.Distance.Visible   = false
    esp.Health.Visible     = false
    esp.BarBG.Visible      = false
    esp.BarFG.Visible      = false
    esp.Highlight.Enabled  = false
    esp._lastVisible       = false
    esp._lastColor         = nil
    esp._lastNameCol       = nil
end

-- ============================================================
--  ACTIVE PLAYER LIST
-- ============================================================
local ActivePlayers    = {}
local activeListTimer  = 0
local ACTIVE_LIST_RATE = 0.5

local function RebuildActiveList()
    local t, n = {}, 0
    for player, esp in pairs(ESPObjects) do
        n    = n + 1
        t[n] = { player = player, esp = esp }
    end
    ActivePlayers = t
end

RebuildActiveList()
Players.PlayerAdded:Connect(function()    task.defer(RebuildActiveList) end)
Players.PlayerRemoving:Connect(function() task.defer(RebuildActiveList) end)

-- ============================================================
--  PERIODIC DISABLE TIMER / FRAME COUNTER
-- ============================================================
local periodicDisableTimer = 0
local FRAME_COUNT          = 0

-- ============================================================
--  PROCESS PLAYER  (upvalues written before each Heartbeat loop)
-- ============================================================
local _sw, _sh, _camPos
local _teamCheck, _showTM, _useVisCol, _visCol, _hidCol, _tmCol
local _nameStyle, _txtScale, _txtSmall, _nameSpacing
local _doBoxes, _doOutline, _doNames, _doDist, _doHP, _doBar, _doSnap
local _snapCol, _maxDistSq, _chamsFill, _chamsOut, _chamsOn, _espOn
local _useCustomNC, _nameCol, _userCol
local _tickSlot, _visSlot
local _halfSW, _halfSH

local function ProcessPlayer(player, esp)
    local char = player.Character
    if not char then HideESP(esp); return end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then HideESP(esp); return end
    if (humanoid.Health or 0) <= 0 then HideESP(esp); return end

    local rp  = rootPart.Position
    local dx3 = rp.X - _camPos.X
    local dy3 = rp.Y - _camPos.Y
    local dz3 = rp.Z - _camPos.Z
    if (dx3*dx3 + dy3*dy3 + dz3*dz3) > _maxDistSq then
        HideESP(esp); return
    end

    local isTeammate = IsTeammateCached(player)

    -- Chams
    if _chamsOn and not (_teamCheck and isTeammate) then
        if not esp.Highlight.Enabled or esp.Highlight.Adornee ~= char then
            esp.Highlight.Adornee = char
            esp.Highlight.Enabled = true
        end
        esp.Highlight.FillColor    = _chamsFill
        esp.Highlight.OutlineColor = _chamsOut
    else
        if esp.Highlight.Enabled then
            esp.Highlight.Enabled = false
            esp.Highlight.Adornee = nil
        end
    end

    if not _espOn then
        if esp._lastVisible then
            esp.Box.Visible  = false
            esp.Name.Visible = false
            esp._lastVisible = false
        end
        return
    end

    if _teamCheck and isTeammate and not _showTM then HideESP(esp); return end

    local head = char:FindFirstChild("Head")
    if not head then HideESP(esp); return end

    if esp._staggerSlot == _tickSlot then
        local root_sp, onSc = Camera:WorldToViewportPoint(rootPart.Position)
        local head_sp       = Camera:WorldToViewportPoint(head.Position + Vector3New(0, 0.5, 0))
        esp._screenRootX = root_sp.X
        esp._screenRootY = root_sp.Y
        esp._screenHeadY = head_sp.Y
        esp._screenDepth = root_sp.Z
        esp._onScreen    = onSc
    end

    if not esp._onScreen or esp._screenDepth <= 0 then HideESP(esp); return end
    local rx    = esp._screenRootX
    local ry    = esp._screenRootY
    local hy    = esp._screenHeadY
    local depth = esp._screenDepth
    if rx < -80 or rx > _sw+80 or ry < -80 or ry > _sh+80 then HideESP(esp); return end

    if esp._staggerSlot == (_visSlot % STAGGER_MOD) then
        esp._isVisible = IsVisible(rootPart, char, player)
    end

    esp._lastVisible = true

    local col
    if isTeammate and _showTM then
        col = _tmCol
    elseif _useVisCol then
        col = esp._isVisible and _visCol or _hidCol
    else
        col = _visCol
    end

    local legY  = ry + (hy - ry) * 3
    local boxH  = mathAbs(hy - legY)
    local boxW  = boxH * 0.55
    local halfW = boxW * 0.5
    local x1    = rx - halfW
    local y1    = hy
    local y2    = y1 + boxH

    if _doBoxes then
        local colChanged = (esp._lastColor ~= col)
        local posChanged = (esp._lastBoxX ~= x1 or esp._lastBoxY ~= y1 or
                            esp._lastBoxW ~= boxW or esp._lastBoxH ~= boxH)

        if _doOutline then
            if not esp.BoxOutline.Visible then esp.BoxOutline.Visible = true end
            if posChanged then
                esp.BoxOutline.Size     = Vector2New(boxW + 3, boxH + 3)
                esp.BoxOutline.Position = Vector2New(x1 - 1.5, y1 - 1.5)
            end
        else
            if esp.BoxOutline.Visible then esp.BoxOutline.Visible = false end
        end

        if not esp.Box.Visible then esp.Box.Visible = true end
        if colChanged then
            esp.Box.Color  = col
            esp._lastColor = col
        end
        if posChanged then
            esp.Box.Size     = Vector2New(boxW, boxH)
            esp.Box.Position = Vector2New(x1, y1)
            esp._lastBoxX = x1;   esp._lastBoxY = y1
            esp._lastBoxW = boxW; esp._lastBoxH = boxH
        end
    else
        if esp.Box.Visible        then esp.Box.Visible        = false end
        if esp.BoxOutline.Visible then esp.BoxOutline.Visible = false end
    end

    if esp.Name.Size     ~= _txtScale then esp.Name.Size     = _txtScale end
    if esp.Username.Size ~= _txtSmall then esp.Username.Size = _txtSmall end
    if esp.Distance.Size ~= _txtSmall then esp.Distance.Size = _txtSmall end
    if esp.Health.Size   ~= _txtSmall then esp.Health.Size   = _txtSmall end

    local nameY = y1 - _nameSpacing
    if _doNames then
        local resolvedNameCol = _useCustomNC and _nameCol or col
        local resolvedUserCol = _useCustomNC and _userCol or col
        local nameColChanged  = (esp._lastNameCol ~= resolvedNameCol)

        if _nameStyle == "Display Name" or _nameStyle == "Both" then
            local txt = player.DisplayName
            if not esp.Name.Visible then esp.Name.Visible = true end
            if esp._lastNameTxt ~= txt then
                esp.Name.Text    = txt
                esp._lastNameTxt = txt
            end
            if nameColChanged then esp.Name.Color = resolvedNameCol end
            esp.Name.Position = Vector2New(rx, nameY)
            if _nameStyle == "Both" then nameY = nameY - (_txtSmall + 2) end
        else
            if esp.Name.Visible then esp.Name.Visible = false end
        end

        if _nameStyle == "Username" or _nameStyle == "Both" then
            local utxt = "@" .. player.Name
            if not esp.Username.Visible then esp.Username.Visible = true end
            if esp._lastUserTxt ~= utxt then
                esp.Username.Text = utxt
                esp._lastUserTxt  = utxt
            end
            if nameColChanged then esp.Username.Color = resolvedUserCol end
            esp.Username.Position = Vector2New(rx, nameY)
        else
            if esp.Username.Visible then esp.Username.Visible = false end
        end

        if nameColChanged then esp._lastNameCol = resolvedNameCol end
    else
        if esp.Name.Visible     then esp.Name.Visible     = false end
        if esp.Username.Visible then esp.Username.Visible = false end
    end

    local hp     = humanoid.Health    or 0
    local hpMax  = humanoid.MaxHealth or 100
    if hpMax <= 0 then hpMax = 100 end
    local hpPct  = mathClamp(hp / hpMax, 0, 1)
    local hColor = GetHealthColor(hpPct)

    if _doBar then
        local barX = x1 - 5
        local barW = 3
        local barH = boxH
        local fgH  = mathMax(1, barH * hpPct)

        if not esp.BarBG.Visible then esp.BarBG.Visible = true end
        esp.BarBG.Size     = Vector2New(barW, barH)
        esp.BarBG.Position = Vector2New(barX, y1)

        if not esp.BarFG.Visible then esp.BarFG.Visible = true end
        esp.BarFG.Size     = Vector2New(barW, fgH)
        esp.BarFG.Position = Vector2New(barX, y1 + barH - fgH)

        local hpPctRounded = mathFloor(hpPct * 100)
        if hpPctRounded ~= esp._lastHPPct then
            esp.BarFG.Color = hColor
            esp._lastHPPct  = hpPctRounded
        end
    else
        if esp.BarBG.Visible then esp.BarBG.Visible = false end
        if esp.BarFG.Visible then esp.BarFG.Visible = false end
    end

    local belowOffset = 3
    if _doDist then
        local distInt = mathFloor(depth)
        if not esp.Distance.Visible then esp.Distance.Visible = true end
        if distInt ~= esp._lastDist then
            esp._lastDist      = distInt
            esp.Distance.Text  = distInt .. "m"
            esp.Distance.Color = GetDistanceColor(depth)
        end
        esp.Distance.Position = Vector2New(rx, y2 + belowOffset)
        belowOffset = belowOffset + _txtSmall + 2
    else
        if esp.Distance.Visible then esp.Distance.Visible = false end
    end

    if _doHP then
        local hpInt = mathFloor(hp)
        if not esp.Health.Visible then esp.Health.Visible = true end
        if hpInt ~= esp._lastHP then
            esp._lastHP      = hpInt
            esp.Health.Text  = hpInt .. " HP"
            esp.Health.Color = hColor
        end
        esp.Health.Position = Vector2New(rx, y2 + belowOffset)
    else
        if esp.Health.Visible then esp.Health.Visible = false end
    end

    if _doSnap then
        if not esp.SnapLine then
            esp.SnapLine           = Drawing.new("Line")
            esp.SnapLine.Thickness = 1.5
        end
        esp.SnapLine.Color = _snapCol
        esp.SnapLine.From  = Vector2New(_halfSW, _halfSH)
        esp.SnapLine.To    = Vector2New(rx, ry)
        if not esp.SnapLine.Visible then esp.SnapLine.Visible = true end
    elseif esp.SnapLine then
        esp.SnapLine:Remove(); esp.SnapLine = nil
    end
end

-- ============================================================
--  RENDER STEPPED
-- ============================================================
RunService.RenderStepped:Connect(function(dt)
    FRAME_COUNT = FRAME_COUNT + 1

    -- Chaos timer — advance every frame, switch part when interval elapses
    if Settings.Aimlock.AimMode == "Chaos" and Settings.Aimlock.IsAiming then
        chaosTimer = chaosTimer - dt
        if chaosTimer <= 0 then
            chaosTimer       = CHAOS_INTERVAL
            chaosCurrentPart = PickNextChaosPart()
        end
    else
        -- Reset timer when not actively using Chaos so the first switch after
        -- enabling fires exactly CHAOS_INTERVAL seconds later, not immediately.
        if Settings.Aimlock.AimMode ~= "Chaos" then
            chaosTimer = CHAOS_INTERVAL
        end
    end

    -- FOV ring
    local fovPos
    if Settings.FOV.FollowCursor then
        fovPos = UserInputService:GetMouseLocation()
    else
        local vp = Camera.ViewportSize
        fovPos   = Vector2New(vp.X * 0.5, vp.Y * 0.5)
    end
    FOVRing.Position     = fovPos
    FOVRing.Radius       = Settings.FOV.Radius
    FOVRing.Thickness    = Settings.FOV.Thickness
    FOVRing.Visible      = Settings.FOV.Visible
    FOVRing.Transparency = Settings.FOV.Transparency
    FOVFill.Position     = fovPos
    FOVFill.Radius       = Settings.FOV.Radius
    FOVFill.Visible      = Settings.FOV.Visible and Settings.FOV.Filled
    FOVFill.Transparency = Settings.FOV.FilledTransp
    FOVFill.Color        = Settings.FOV.FilledColor

    -- Periodic disable
    if Settings.DetectionAvoidance.PeriodicAimDisable and Settings.Aimlock.Enabled then
        periodicDisableTimer = periodicDisableTimer - dt
        if periodicDisableTimer <= 0 then
            Settings.Aimlock.PeriodicDisable = mathRandom() < Settings.DetectionAvoidance.DisableChance
            periodicDisableTimer = Settings.DetectionAvoidance.DisableDuration + mathRandom() * 0.4
        end
    else
        Settings.Aimlock.PeriodicDisable = false
    end

    -- Target acquisition (throttled)
    if Settings.Aimlock.Enabled and Settings.Aimlock.IsAiming then
        if not Settings.Aimlock.CurrentTarget or not IsTargetAlive(Settings.Aimlock.CurrentTarget) then
            -- FIX: reset to CLOSEST_THROTTLE so the scan fires on the very next
            --      frame after target loss rather than waiting 4 more frames.
            closestThrottleTick = closestThrottleTick + 1
            if closestThrottleTick >= CLOSEST_THROTTLE then
                closestThrottleTick            = 0
                Settings.Aimlock.CurrentTarget = GetClosestPlayer()
            end
        end
    end

    -- Camera lock + HUD
    local showHUD = false

    if Settings.Aimlock.Enabled and Settings.Aimlock.IsAiming
       and Settings.Aimlock.CurrentTarget and not Settings.Aimlock.PeriodicDisable then

        local tChar = Settings.Aimlock.CurrentTarget.Character
        if tChar then
            local tPart, lockIsVisible = GetAimPart(tChar, Settings.Aimlock.CurrentTarget)
            tPart = tPart or tChar:FindFirstChild("HumanoidRootPart")
            if lockIsVisible == nil then lockIsVisible = true end

            local hum = tChar:FindFirstChildOfClass("Humanoid")
            if tPart and hum and (hum.Health or 0) > 0 then
                local aimPos
                if Settings.Aimlock.PredictionEnabled then
                    local vel = tPart.AssemblyLinearVelocity * Settings.Aimlock.StrafePrediction
                    aimPos    = AddJitter(tPart.Position + vel * Settings.Aimlock.Prediction)
                else
                    aimPos = AddJitter(tPart.Position)
                end
                local tCF = CFrameNew(Camera.CFrame.Position, aimPos)
                if Settings.Aimlock.SmoothAiming then
                    Camera.CFrame = Camera.CFrame:Lerp(tCF, Settings.Aimlock.SmoothSpeed)
                else
                    Camera.CFrame = tCF
                end

                if Settings.Visuals.TargetUI then
                    showHUD        = true
                    NameLabel.Text = Settings.Aimlock.CurrentTarget.DisplayName
                    TStroke.Color  = lockIsVisible and Color3RGB(80, 180, 255) or Color3RGB(255, 140, 40)

                    -- Show current Chaos part in the HUD indicator
                    if Settings.Aimlock.AimMode == "Chaos" then
                        ChaosLabel.Visible = true
                        ChaosLabel.Text    = "⚡ " .. chaosCurrentPart
                    else
                        ChaosLabel.Visible = false
                        ChaosLabel.Text    = ""
                    end

                    local hp     = hum.Health    or 0
                    local hpMax  = hum.MaxHealth or 100
                    if hpMax <= 0 then hpMax = 100 end
                    local hpPct  = mathClamp(hp / hpMax, 0, 1)

                    if Settings.Visuals.HealthNumbers then
                        HPLabel.Visible = true
                        local hpInt = mathFloor(hp)
                        if hpInt ~= HUDLastHP then
                            HUDLastHP          = hpInt
                            HPLabel.Text       = tostring(hpInt)
                            local hc           = GetHealthColor(hpPct)
                            HPLabel.TextColor3 = hc
                            HPStroke.Color     = hc
                        end
                        local pos = Settings.Visuals.HealthPosition
                        if     pos == "TopRight"    then HPLabel.Position = UDim2.new(1,-68, 0,8)
                        elseif pos == "TopLeft"     then HPLabel.Position = UDim2.new(0,8,   0,8)
                        elseif pos == "BottomRight" then HPLabel.Position = UDim2.new(1,-68, 1,-32)
                        elseif pos == "BottomLeft"  then HPLabel.Position = UDim2.new(0,8,   1,-32)
                        end
                    else
                        HPLabel.Visible = false
                    end

                    local lhrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local thrp = tChar:FindFirstChild("HumanoidRootPart")
                    if lhrp and thrp then
                        local d = mathFloor((lhrp.Position - thrp.Position).Magnitude)
                        if d ~= HUDLastDist then
                            HUDLastDist    = d
                            DistLabel.Text = "Distance: " .. d .. "m"
                        end
                    end
                end
            else
                Settings.Aimlock.CurrentTarget = nil
                -- FIX: force immediate re-scan on next frame
                closestThrottleTick = CLOSEST_THROTTLE
            end
        else
            Settings.Aimlock.CurrentTarget = nil
            closestThrottleTick = CLOSEST_THROTTLE
        end
    end

    TargetFrame.Visible = showHUD
    if not showHUD then
        HPLabel.Visible    = false
        ChaosLabel.Visible = false
        HUDLastHP          = -1
        HUDLastDist        = -1
    end

    -- Player mods
    local myChar = LocalPlayer.Character
    if myChar then
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if hum then
            if Settings.Player.WalkSpeedEnabled then hum.WalkSpeed = Settings.Player.WalkSpeed end
            if Settings.Player.JumpPowerEnabled  then hum.JumpPower = Settings.Player.JumpPower end
        end
    end
end)

-- ============================================================
--  HEARTBEAT  —  ESP + tracers
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    activeListTimer = activeListTimer + dt
    if activeListTimer >= ACTIVE_LIST_RATE then
        activeListTimer = 0
        RebuildActiveList()
    end

    local espOn   = Settings.Visuals.ESPEnabled
    local chamsOn = Settings.Visuals.ChamsEnabled

    if Settings.Visuals.TracerLines and espOn then
        local sw   = Camera.ViewportSize.X
        local sh   = Camera.ViewportSize.Y
        local orig = Settings.Visuals.TracerOrigin
        local oy   = orig == "Bottom" and sh or orig == "Top" and 0 or sh * 0.5
        local from = Vector2New(sw * 0.5, oy)
        local tCol = Settings.Visuals.TracerColor

        for _, entry in ipairs(ActivePlayers) do
            local player = entry.player
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
                        local ln     = Drawing.new("Line")
                        ln.Thickness = 1.5
                        TracerLineCache[player] = ln
                    end
                    local ln = TracerLineCache[player]
                    local tp = Camera:WorldToViewportPoint(hrp.Position)
                    ln.Color   = tCol
                    ln.From    = from
                    ln.To      = Vector2New(tp.X, tp.Y)
                    ln.Visible = tp.Z > 0
                end
            end
        end
    else
        for _, ln in pairs(TracerLineCache) do ln:Remove() end
        table.clear(TracerLineCache)
    end

    if not espOn and not chamsOn then
        for _, entry in ipairs(ActivePlayers) do HideESP(entry.esp) end
        return
    end

    local vp   = Camera.ViewportSize
    _sw        = vp.X
    _sh        = vp.Y
    _halfSW    = _sw * 0.5
    _halfSH    = _sh * 0.5
    _camPos    = Camera.CFrame.Position
    _teamCheck = Settings.Visuals.TeamCheck
    _showTM    = Settings.Visuals.ShowTeammates
    _useVisCol = Settings.Visuals.UseVisColors
    _visCol    = Settings.Visuals.VisColor
    _hidCol    = Settings.Visuals.HiddenColor
    _tmCol     = Settings.Visuals.TeammateColor
    _nameStyle = Settings.Visuals.ESPNameStyle
    _txtScale  = Settings.Visuals.ESPTextScale
    _txtSmall  = mathMax(10, _txtScale - 2)
    _nameSpacing = _txtScale + 2
    _doBoxes   = Settings.Visuals.ESPBoxes
    _doOutline = Settings.Visuals.ESPOutline
    _doNames   = Settings.Visuals.ESPNames
    _doDist    = Settings.Visuals.DistanceDisplay
    _doHP      = Settings.Visuals.HealthNumbers
    _doBar     = Settings.Visuals.HealthBar
    _doSnap    = Settings.Visuals.SnapLines
    _snapCol   = Settings.Visuals.SnapLineColor
    local md   = Settings.Visuals.MaxESPDistance
    _maxDistSq = md * md
    _chamsFill = Settings.Visuals.ChamsFillColor
    _chamsOut  = Settings.Visuals.ChamsOutlineColor
    _chamsOn   = chamsOn
    _espOn     = espOn
    _useCustomNC = Settings.Visuals.UseCustomNameColor
    _nameCol     = Settings.Visuals.ESPNameColor
    _userCol     = Settings.Visuals.ESPUsernameColor
    _tickSlot    = FRAME_COUNT % STAGGER_MOD
    _visSlot     = FRAME_COUNT % (STAGGER_MOD * 3)

    for _, entry in ipairs(ActivePlayers) do
        local ok, err = pcall(ProcessPlayer, entry.player, entry.esp)
        if not ok then warn("KAIM ESP error:", err) end
    end
end)

-- ============================================================
--  KEYBIND HANDLING
-- ============================================================
local noclipNotifyDebounce = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Noclip toggle: FIX — removed the "if NoclipEnabled" guard so the
    -- keybind works in both directions (on → off AND off → on).
    if input.KeyCode == cachedNoclipKC then
        if not noclipNotifyDebounce then
            noclipNotifyDebounce = true
            local newState = not Settings.Player.NoclipEnabled
            SetNoclip(newState)
            WindUI:Notify({
                Title    = "Noclip",
                Content  = "Noclip is now " .. (newState and "ON" or "OFF"),
                Duration = 2,
                Icon     = "ghost"
            })
            task.delay(0.3, function() noclipNotifyDebounce = false end)
        end
    end

    -- Aimlock key
    local pressed = false
    if Settings.Aimlock.Keybind == "RightClick" then
        pressed = input.UserInputType == Enum.UserInputType.MouseButton2
    else
        local ok, kc = pcall(function() return Enum.KeyCode[Settings.Aimlock.Keybind] end)
        if ok and kc then pressed = (input.KeyCode == kc) end
    end
    if pressed then
        Settings.Aimlock.IsAiming = true
        -- Reset chaos timer so the first switch happens exactly CHAOS_INTERVAL
        -- seconds after the player starts aiming, not sooner.
        if Settings.Aimlock.AimMode == "Chaos" then
            chaosTimer       = CHAOS_INTERVAL
            chaosLastPart    = ""
            chaosCurrentPart = PickNextChaosPart()
        end
        if Settings.Aimlock.Enabled then
            closestThrottleTick            = CLOSEST_THROTTLE
            Settings.Aimlock.CurrentTarget = GetClosestPlayer()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local released = false
    if Settings.Aimlock.Keybind == "RightClick" then
        released = input.UserInputType == Enum.UserInputType.MouseButton2
    else
        local ok, kc = pcall(function() return Enum.KeyCode[Settings.Aimlock.Keybind] end)
        if ok and kc then released = (input.KeyCode == kc) end
    end
    if released then
        Settings.Aimlock.IsAiming      = false
        Settings.Aimlock.CurrentTarget = nil
        closestThrottleTick            = CLOSEST_THROTTLE
    end
end)

-- ============================================================
WindUI:Notify({
    Title    = "KAIM v3.3 Loaded",
    Content  = "Press K to toggle UI  •  Right Click to aimlock",
    Duration = 5,
    Icon     = "crosshair",
})
print("KAIM v3.3 loaded — press K to toggle UI.")