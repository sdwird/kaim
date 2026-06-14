-- ============================================================
--  KAIM v4.1  |  WindUI Edition (Maximum Optimization)
--  Advanced Combat Hub & Visuals
-- ============================================================

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local VirtualInput     = game:GetService("VirtualInputManager")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ============================================================
--  WINDUI SECURE INITIALIZATION
-- ============================================================
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local WindUI

local ok, result = pcall(function()
return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if ok and result then
WindUI = result
else
warn("KAIM | Failed to load WindUI from GitHub. Please check your internet or executor.")
return
end

-- ============================================================
--  DRAWING API SAFE WRAPPER
-- ============================================================
local HAS_DRAWING = type(Drawing) == "table" and type(Drawing.new) == "function"
local DummyDrawing = {
Visible = false, Thickness = 1, Transparency = 1, Color = Color3.new(), Filled = false,
Text = "", Size = 12, Center = false, Outline = false, OutlineColor = Color3.new(),
Font = 1, From = Vector2.new(), To = Vector2.new(), Position = Vector2.new(),
Radius = 0, Remove = function() end, Destroy = function() end,
}
setmetatable(DummyDrawing, {__index = function() return nil end})

local function SafeDrawingNew(objType)
if HAS_DRAWING then
local success, res = pcall(Drawing.new, objType)
if success and res then return res end
end
local d = {}
for k, v in pairs(DummyDrawing) do d[k] = v end
return d
end

-- ============================================================
--  FAST LOCALS & MATH CACHING (Micro-Optimizations)
-- ============================================================
local mathFloor   = math.floor
local mathClamp   = math.clamp
local mathAbs     = math.abs
local mathMax     = math.max
local mathRandom  = math.random
local Vector2New  = Vector2.new
local Vector3New  = Vector3.new
local Color3RGB   = Color3.fromRGB
local CFrameNew   = CFrame.new
local tableInsert = table.insert
local tableRemove = table.remove
local tableSort   = table.sort

-- ============================================================
--  ENVIRONMENT DIAGNOSTICS
-- ============================================================
local function GetEnvironmentData()
local execName, execVersion = "Unknown", "Unknown"
pcall(function()
if identifyexecutor then execName, execVersion = identifyexecutor() end
end)

local TrustMap = {
    ["Krampus"]    = "Level 4 - Premium, Highly Safe",
    ["Ro-Exec"]    = "Level 4 - Premium, Highly Safe",
    ["Wave"]       = "High - Premium, Safe",
    ["MacSploit"]  = "High - Premium, Safe",
    ["Electron"]   = "High - Good Compatibility",
    ["Xeno"]       = "Mid/High - Good Compatibility, Safe",
    ["Solara"]     = "Level 3 - Safe (Standard)",
    ["Celery"]     = "Level 3 - Safe (Standard)",
    ["Hydrogen"]   = "Level 3 - Safe (Standard)",
    ["Appleware"]  = "Level 3 - Safe (Standard)",
    ["Delta"]      = "Mid - Mobile/Emulator (Adware Warning)",
    ["Codex"]      = "Mid - Mobile/Emulator (Adware Warning)",
    ["AWP"]        = "High - Good Compatibility",
    ["Evon"]       = "CRITICAL RISK - Known Malware/Miner History",
    ["Trigon"]     = "HIGH RISK - Adware Warning",
    ["Valyse"]     = "HIGH RISK - Adware Warning",
}

local safetyRating = "Unknown / Untested Environment"
for knownExec, rating in pairs(TrustMap) do
    if string.find(string.lower(execName), string.lower(knownExec)) then
        safetyRating = rating
        break
    end
end

local uncFuncs = {
    "getgenv", "getrenv", "getgc", "getconnections", "fireclickdetector",
    "isnetworkowner", "hookmetamethod", "checkcaller", "Drawing", "request",
    "readfile", "writefile", "setclipboard", "gethui", "identifyexecutor"
}
local passed = 0
local env = getgenv and getgenv() or _G

for _, f in ipairs(uncFuncs) do
    if env[f] or (f == "Drawing" and HAS_DRAWING) then passed = passed + 1 end
end
local uncRate = mathFloor((passed / #uncFuncs) * 100)

local compat = HAS_DRAWING and "Flawless" or "Broken (Missing Drawing API)"
return execName, execVersion, safetyRating, uncRate, compat


end

local ExecName, ExecVer, ExecSafety, ExecUNC, ExecCompat = GetEnvironmentData()

-- ============================================================
--  DEFAULT SETTINGS v4.1
-- ============================================================
local Settings = {
Aimlock = {
Enabled            = false,
Prediction         = 0.135,
PredictionEnabled  = true,
AimMode            = "Smart",
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
Triggerbot = {
Enabled            = false,
Delay              = 0.05,
TeamCheck          = true,
UseFOV             = false,
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
ESPBoxFill         = false,
ESPBoxFillTrans    = 0.2,
ESPNames           = true,
ESPNameStyle       = "Display Name",
ESPOutline         = true,
ESPTextScale       = 14,
ESPFont            = 2,
UseCustomNameColor = false,
ESPNameColor       = Color3RGB(255, 255, 255),
ESPUsernameColor   = Color3RGB(180, 180, 200),
TeamCheck          = true,
ShowTeammates      = false,
TeammateColor      = Color3RGB(0, 200, 255),
UseVisColors       = true,
VisColor           = Color3RGB(0, 255, 100),
HiddenColor        = Color3RGB(255, 50, 50),
DistanceDisplay    = false,
HealthNumbers      = false,
HealthBar          = true,

    -- Upgraded Chams Settings
    ChamsEnabled       = false,
    ChamsUseVisColors  = true,
    ChamsFillColor     = Color3RGB(255, 85, 0),
    ChamsOutlineColor  = Color3RGB(255, 255, 255),
    ChamsFillTrans     = 0.5,
    ChamsOutlineTrans  = 0,
    ChamsDepth         = true,
    
    TracerLines        = false,
    TracerOrigin       = "Bottom",
    TracerColor        = Color3RGB(255, 170, 0),
    SnapLines          = false,
    SnapLineColor      = Color3RGB(255, 85, 0),
    TargetUI           = true,
    TargetUIScale      = 1.0,
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
--  CACHES, STATE & CONNECTIONS
-- ============================================================
local KaimConnections = {}
local PlayerCache     = {}
local TeamCache       = {}
local ESPObjects      = {}
local TracerLineCache = {}

local RaycastFilterTable = { nil, nil }
local RaycastParamsCache = RaycastParams.new()
RaycastParamsCache.FilterType = Enum.RaycastFilterType.Exclude
RaycastParamsCache.IgnoreWater = true

local chaosTimer       = 0
local chaosCurrentPart = "Head"
local chaosLastPart    = ""
local CHAOS_INTERVAL   = 0.3
local CHAOS_PICK_LIST  = {"Head", "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}

local periodicDisableTimer = 0
local triggerbotTimer      = 0
local FRAME_COUNT          = 0
local STAGGER_MOD          = 3
local cachedNoclipKC       = Enum.KeyCode.N

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing = SafeDrawingNew("Circle")
FOVRing.Visible   = false
FOVRing.Thickness = 1.5
FOVRing.Filled    = false

local FOVFill = SafeDrawingNew("Circle")
FOVFill.Visible   = false
FOVFill.Thickness = 1
FOVFill.Filled    = true

local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name  = "KaimChams"
pcall(function() ChamsFolder.Parent = Camera end)

-- TARGET HUD (Drawing API)
local THUD = {
BG     = SafeDrawingNew("Square"),
Accent = SafeDrawingNew("Square"),
Name   = SafeDrawingNew("Text"),
Data   = SafeDrawingNew("Text"),
BarBG  = SafeDrawingNew("Square"),
BarFG  = SafeDrawingNew("Square"),
}

THUD.BG.Visible = false; THUD.BG.Filled = true; THUD.BG.Color = Color3RGB(15, 15, 20); THUD.BG.Transparency = 0.9
THUD.Accent.Visible = false; THUD.Accent.Filled = true; THUD.Accent.Transparency = 1
THUD.Name.Visible = false; THUD.Name.Center = false; THUD.Name.Outline = true; THUD.Name.Color = Color3RGB(255, 255, 255); THUD.Name.Font = 2
THUD.Data.Visible = false; THUD.Data.Center = false; THUD.Data.Outline = true; THUD.Data.Color = Color3RGB(180, 180, 200); THUD.Data.Font = 2
THUD.BarBG.Visible = false; THUD.BarBG.Filled = true; THUD.BarBG.Color = Color3RGB(25, 25, 30); THUD.BarBG.Transparency = 1
THUD.BarFG.Visible = false; THUD.BarFG.Filled = true; THUD.BarFG.Transparency = 1

-- ============================================================
--  UTILITY FUNCTIONS
-- ============================================================
local function PickNextChaosPart()
local candidates = {}
for _, name in ipairs(CHAOS_PICK_LIST) do
if name ~= chaosLastPart then tableInsert(candidates, name) end
end
local chosen = candidates[mathRandom(#candidates)]
chaosLastPart = chosen
return chosen
end

local function IsTeammateCached(player)
if TeamCache[player] == nil then
TeamCache[player] = (player.Team ~= nil and player.Team == LocalPlayer.Team)
end
return TeamCache[player]
end

local function IsTargetAlive(player, settingsRef)
if not player or not player.Character then return false end
if settingsRef.TeamCheck and IsTeammateCached(player) then return false end
local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
return humanoid and (humanoid.Health or 0) > 0
end

local function GetRayParams(character)
RaycastFilterTable[1] = LocalPlayer.Character or character
RaycastFilterTable[2] = character
RaycastParamsCache.FilterDescendantsInstances = RaycastFilterTable
return RaycastParamsCache
end

local function IsVisible(targetPart, targetChar)
local camPos = Camera.CFrame.Position
local direction = targetPart.Position - camPos
local result = workspace:Raycast(camPos, direction, GetRayParams(targetChar))
return result == nil
end

local SMART_PRIORITY = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

local function GetAimPart(character, aimMode)
if aimMode == "Smart" then
for _, partName in ipairs(SMART_PRIORITY) do
local part = character:FindFirstChild(partName)
if part and IsVisible(part, character) then return part, true end
end
return character:FindFirstChild("HumanoidRootPart"), false
elseif aimMode == "Chaos" then
local part = character:FindFirstChild(chaosCurrentPart) or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
return part, true
elseif aimMode == "Head" then
return character:FindFirstChild("Head"), true
elseif aimMode == "Torso" then
return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"), true
elseif aimMode == "Limbs" then
local leftArm = character:FindFirstChild("LeftUpperArm")
local rightArm = character:FindFirstChild("RightUpperArm")
if leftArm and rightArm then return (mathRandom() < 0.5 and leftArm or rightArm), true end
return (leftArm or rightArm), true
else
return character:FindFirstChild("HumanoidRootPart"), true
end
end

-- Pre-allocate Candidate Pool for memory efficiency
local CandidatePool = {}

local function GetClosestPlayer(fovSettings, aimSettings)
local fovSq = fovSettings.Radius * fovSettings.Radius
local refPos = fovSettings.FollowCursor and UserInputService:GetMouseLocation() or Vector2New(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)

table.clear(CandidatePool)

for _, player in ipairs(PlayerCache) do
    if not IsTargetAlive(player, aimSettings) then continue end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then continue end

    local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
    if not onScreen then continue end

    local dx = refPos.X - screenPos.X
    local dy = refPos.Y - screenPos.Y
    local distSq = dx*dx + dy*dy

    if distSq <= fovSq then
        tableInsert(CandidatePool, { player = player, char = character, distSq = distSq })
    end
end

tableSort(CandidatePool, function(a, b) return a.distSq < b.distSq end)

local wallCheck = aimSettings.WallCheck
local aimMode = aimSettings.AimMode

for _, candidate in ipairs(CandidatePool) do
    if not wallCheck then return candidate.player end
    local part, visible = GetAimPart(candidate.char, aimMode)
    if part and visible then return candidate.player end
end

return nil


end

-- ============================================================
--  ESP LIFECYCLE MANAGEMENT
-- ============================================================
local function SetupDrawingText(textObj, visSettings)
textObj.Center       = true
textObj.Outline      = true
textObj.OutlineColor = Color3RGB(0, 0, 0)
textObj.Font         = visSettings.ESPFont
end

local function CreateESP(player)
local esp = {
Box        = SafeDrawingNew("Square"),
BoxOutline = SafeDrawingNew("Square"),
BoxFill    = SafeDrawingNew("Square"),
Name       = SafeDrawingNew("Text"),
Username   = SafeDrawingNew("Text"),
Distance   = SafeDrawingNew("Text"),
Health     = SafeDrawingNew("Text"),
BarBG      = SafeDrawingNew("Square"),
BarFG      = SafeDrawingNew("Square"),
Highlight  = Instance.new("Highlight"),
SnapLine   = nil,
_isVisible   = false,
_lastVisible = false,
_staggerSlot = mathRandom(0, STAGGER_MOD - 1),
_lastCFill   = nil,
_lastCOut    = nil,
_lastCFTrans = nil,
_lastCOTrans = nil,
}

esp.Box.Thickness = 1.5; esp.Box.Transparency = 1; esp.Box.Filled = false
esp.BoxOutline.Thickness = 3.5; esp.BoxOutline.Transparency = 0.7; esp.BoxOutline.Filled = false; esp.BoxOutline.Color = Color3RGB(0, 0, 0)
esp.BoxFill.Thickness = 1; esp.BoxFill.Filled = true

SetupDrawingText(esp.Name, Settings.Visuals)
SetupDrawingText(esp.Username, Settings.Visuals)
SetupDrawingText(esp.Distance, Settings.Visuals)
SetupDrawingText(esp.Health, Settings.Visuals)
esp.Username.Color = Color3RGB(180, 180, 200)

esp.BarBG.Filled = true; esp.BarBG.Transparency = 0.6; esp.BarBG.Color = Color3RGB(15, 15, 15); esp.BarBG.Thickness = 1
esp.BarFG.Filled = true; esp.BarFG.Transparency = 1; esp.BarFG.Thickness = 1

esp.Highlight.Parent = ChamsFolder
esp.Highlight.Enabled = false

ESPObjects[player] = esp


end

local function HideESP(esp)
if not esp._lastVisible then return end
esp.Box.Visible = false; esp.BoxOutline.Visible = false; esp.BoxFill.Visible = false
esp.Name.Visible = false; esp.Username.Visible = false; esp.Distance.Visible = false; esp.Health.Visible = false
esp.BarBG.Visible = false; esp.BarFG.Visible = false; esp.Highlight.Enabled = false
if esp.SnapLine then esp.SnapLine.Visible = false end
esp._lastVisible = false
end

local function RegisterPlayer(player)
if player == LocalPlayer then return end
tableInsert(PlayerCache, player)
CreateESP(player)
tableInsert(KaimConnections, player:GetPropertyChangedSignal("Team"):Connect(function() TeamCache[player] = nil end))
end

for _, player in ipairs(Players:GetPlayers()) do RegisterPlayer(player) end
tableInsert(KaimConnections, Players.PlayerAdded:Connect(RegisterPlayer))

tableInsert(KaimConnections, Players.PlayerRemoving:Connect(function(player)
for i, p in ipairs(PlayerCache) do
if p == player then tableRemove(PlayerCache, i); break end
end
local esp = ESPObjects[player]
if esp then
esp.Box:Remove(); esp.BoxOutline:Remove(); esp.BoxFill:Remove()
esp.Name:Remove(); esp.Username:Remove(); esp.Distance:Remove(); esp.Health:Remove()
esp.BarBG:Remove(); esp.BarFG:Remove()
if esp.SnapLine then esp.SnapLine:Remove() end
esp.Highlight:Destroy()
ESPObjects[player] = nil
end
if TracerLineCache[player] then
TracerLineCache[player]:Remove()
TracerLineCache[player] = nil
end
TeamCache[player] = nil
end))

local function GetHealthColor(percentage)
if percentage > 0.80 then return Color3RGB(0, 255, 100) end
if percentage > 0.60 then return Color3RGB(100, 255, 50) end
if percentage > 0.40 then return Color3RGB(255, 200, 0) end
if percentage > 0.20 then return Color3RGB(255, 130, 0) end
return Color3RGB(255, 50, 50)
end

local function GetDistanceColor(distance)
if distance < 50  then return Color3RGB(0, 255, 100) end
if distance < 100 then return Color3RGB(100, 255, 100) end
if distance < 200 then return Color3RGB(255, 210, 0) end
if distance < 350 then return Color3RGB(255, 140, 0) end
return Color3RGB(255, 50, 50)
end

-- ============================================================
--  UPDATE MODULES
-- ============================================================
local function UpdateFOV(centerPoint, fovSet)
local fovPos = fovSet.FollowCursor and UserInputService:GetMouseLocation() or centerPoint
FOVRing.Position = fovPos; FOVRing.Radius = fovSet.Radius; FOVRing.Color = fovSet.Color; FOVRing.Transparency = fovSet.Transparency; FOVRing.Visible = fovSet.Visible
FOVFill.Position = fovPos; FOVFill.Radius = fovSet.Radius; FOVFill.Color = fovSet.FilledColor; FOVFill.Transparency = fovSet.FilledTransp; FOVFill.Visible = fovSet.Visible and fovSet.Filled
end

local function UpdateTriggerbot(deltaTime, tbSet, aimSet)
if not tbSet.Enabled then return end
triggerbotTimer = triggerbotTimer - deltaTime
if triggerbotTimer > 0 then return end

local cx, cy = Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5
local originPos = Camera.CFrame.Position
local direction = Camera.CFrame.LookVector * 1000

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

local result = workspace:Raycast(originPos, direction, params)

if result and result.Instance then
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        local hum = model:FindFirstChild("Humanoid")
        if hum.Health > 0 then
            local targetPlayer = Players:GetPlayerFromCharacter(model)
            if targetPlayer and targetPlayer ~= LocalPlayer then
                if tbSet.TeamCheck and IsTeammateCached(targetPlayer) then return end
                
                pcall(function()
                    VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                end)
                
                triggerbotTimer = tbSet.Delay
            end
        end
    end
end


end

local function UpdateAimlock(camPos, screenWidth, screenHeight, deltaTime, aimSet, avoidSet, visSet, fovSet)
if avoidSet.PeriodicAimDisable and aimSet.Enabled then
periodicDisableTimer = periodicDisableTimer - deltaTime
if periodicDisableTimer <= 0 then
aimSet.PeriodicDisable = (mathRandom() < avoidSet.DisableChance)
periodicDisableTimer = avoidSet.DisableDuration + (mathRandom() * 0.4)
end
else
aimSet.PeriodicDisable = false
end

if aimSet.AimMode == "Chaos" and aimSet.IsAiming then
    chaosTimer = chaosTimer - deltaTime
    if chaosTimer <= 0 then 
        chaosTimer = CHAOS_INTERVAL
        chaosCurrentPart = PickNextChaosPart() 
    end
else
    if aimSet.AimMode ~= "Chaos" then chaosTimer = CHAOS_INTERVAL end
end

local showHUD = false

if aimSet.Enabled and aimSet.IsAiming and not aimSet.PeriodicDisable then
    if not aimSet.CurrentTarget or not IsTargetAlive(aimSet.CurrentTarget, aimSet) then
        aimSet.CurrentTarget = GetClosestPlayer(fovSet, aimSet)
    end

    local target = aimSet.CurrentTarget

    if target and target.Character then
        local targetPart, lockIsVisible = GetAimPart(target.Character, aimSet.AimMode)
        targetPart = targetPart or target.Character:FindFirstChild("HumanoidRootPart")
        if lockIsVisible == nil then lockIsVisible = true end

        if targetPart then
            local aimPos = targetPart.Position
            
            if aimSet.PredictionEnabled then
                local velocity = targetPart.AssemblyLinearVelocity
                if velocity.Magnitude > 300 then velocity = velocity.Unit * 300 end
                aimPos = aimPos + (velocity * aimSet.StrafePrediction * aimSet.Prediction)
            end
            
            if avoidSet.RandomJitter then
                local jitter = avoidSet.JitterAmount
                aimPos = aimPos + Vector3New((mathRandom() - 0.5) * jitter, (mathRandom() - 0.5) * jitter, (mathRandom() - 0.5) * jitter)
            end

            local targetCFrame = CFrameNew(camPos, aimPos)
            if aimSet.SmoothAiming then
                local smoothFactor = aimSet.SmoothSpeed
                if smoothFactor < 1 then smoothFactor = 1 - math.pow(1 - smoothFactor, deltaTime * 60) end
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
            else
                Camera.CFrame = targetCFrame
            end

            if visSet.TargetUI then
                showHUD = true
                local scale = visSet.TargetUIScale
                
                local boxW = mathFloor(220 * scale)
                local boxH = mathFloor(52 * scale)
                local hudX = (screenWidth / 2) - (boxW / 2)
                local hudY = screenHeight - mathFloor(140 * scale)
                
                THUD.BG.Size = Vector2New(boxW, boxH)
                THUD.BG.Position = Vector2New(hudX, hudY)
                
                THUD.Accent.Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale)))
                THUD.Accent.Position = Vector2New(hudX, hudY)
                local accentColor = lockIsVisible and visSet.VisColor or visSet.HiddenColor
                if THUD.Accent.Color ~= accentColor then THUD.Accent.Color = accentColor end
                
                THUD.Name.Size = mathMax(10, mathFloor(16 * scale))
                THUD.Name.Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(8 * scale))
                local nameStr = target.DisplayName
                if THUD.Name.Text ~= nameStr then THUD.Name.Text = nameStr end
                
                local infoText = ""
                local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
                local hpPct = 1
                
                if humanoid then
                    hpPct = mathClamp((humanoid.Health or 0) / (humanoid.MaxHealth or 100), 0, 1)
                    infoText = "HP: " .. mathFloor(humanoid.Health) .. "  |  "
                end
                
                local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
                local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart and localRoot then
                    infoText = infoText .. "Dist: " .. mathFloor((localRoot.Position - rootPart.Position).Magnitude) .. "m"
                end
                
                if aimSet.AimMode == "Chaos" then
                    infoText = infoText .. "  |  ⚡ " .. chaosCurrentPart
                end

                THUD.Data.Size = mathMax(10, mathFloor(12 * scale))
                if THUD.Data.Text ~= infoText then THUD.Data.Text = infoText end
                THUD.Data.Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(26 * scale))
                
                local barW = boxW - mathFloor(20 * scale)
                local barH = mathMax(1, mathFloor(3 * scale))
                local barY = hudY + mathFloor(43 * scale)
                
                THUD.BarBG.Size = Vector2New(barW, barH)
                THUD.BarBG.Position = Vector2New(hudX + mathFloor(10 * scale), barY)
                
                THUD.BarFG.Size = Vector2New(barW * hpPct, barH)
                THUD.BarFG.Position = Vector2New(hudX + mathFloor(10 * scale), barY)
                
                local hColor = GetHealthColor(hpPct)
                if THUD.BarFG.Color ~= hColor then THUD.BarFG.Color = hColor end
            end
        else
            aimSet.CurrentTarget = nil
        end
    end
else
    aimSet.CurrentTarget = nil
end

THUD.BG.Visible = showHUD; THUD.Accent.Visible = showHUD; THUD.Name.Visible = showHUD
THUD.Data.Visible = showHUD; THUD.BarBG.Visible = showHUD; THUD.BarFG.Visible = showHUD


end

local function UpdatePlayerMods(playerSet)
if not LocalPlayer.Character then return end
local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if not humanoid then return end
if playerSet.WalkSpeedEnabled then humanoid.WalkSpeed = playerSet.WalkSpeed end
if playerSet.JumpPowerEnabled then humanoid.JumpPower = playerSet.JumpPower end
end

local function UpdateESP(camPos, screenWidth, screenHeight, visSet)
local center = Vector2New(screenWidth * 0.5, screenHeight * 0.5)
local espEnabled = visSet.ESPEnabled
local chamsEnabled = visSet.ChamsEnabled
local maxDistanceSq = visSet.MaxESPDistance ^ 2
local currentTickSlot = FRAME_COUNT % STAGGER_MOD

local tracerOrigin = visSet.TracerOrigin
local tracerOriginY = (tracerOrigin == "Bottom") and screenHeight or (tracerOrigin == "Top") and 0 or (screenHeight * 0.5)
local tracerStartPos = Vector2New(screenWidth * 0.5, tracerOriginY)

for _, player in ipairs(PlayerCache) do
    local esp = ESPObjects[player]
    if not esp then continue end

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    local isTeammate = IsTeammateCached(player)
    local isAlive = humanoid and (humanoid.Health > 0)

    -- Master Cull: Distance Check (Affects both 2D and 3D Chams)
    if not isAlive or not rootPart or (visSet.TeamCheck and isTeammate and not visSet.ShowTeammates) then
        HideESP(esp)
        if TracerLineCache[player] then TracerLineCache[player].Visible = false end
        continue
    end
    
    local distSq = (rootPart.Position - camPos).Magnitude ^ 2
    if distSq > maxDistanceSq then
        HideESP(esp)
        if TracerLineCache[player] then TracerLineCache[player].Visible = false end
        continue
    end

    -- Staggered Raycast Visibility Checker (Calculated before Chams use it)
    if esp._staggerSlot == currentTickSlot then 
        esp._isVisible = IsVisible(rootPart, character) 
    end
    esp._lastVisible = true

    -- === 3D CHAMS ENGINE (Decoupled from 2D Screen Bounds) ===
    if chamsEnabled then
        if esp.Highlight.Adornee ~= character then
            esp.Highlight.Adornee = character
            esp.Highlight.Enabled = true
        end
        
        -- Tactical Visibility Colors integration
        local cFill = visSet.ChamsUseVisColors and (esp._isVisible and visSet.VisColor or visSet.HiddenColor) or visSet.ChamsFillColor
        local cOut = visSet.ChamsOutlineColor
        local cFTrans = visSet.ChamsFillTrans
        local cOTrans = visSet.ChamsOutlineTrans

        -- C++ Bridge Optimization: Only update Highlight properties if they changed
        if esp._lastCFill ~= cFill then esp.Highlight.FillColor = cFill; esp._lastCFill = cFill end
        if esp._lastCOut ~= cOut then esp.Highlight.OutlineColor = cOut; esp._lastCOut = cOut end
        if esp._lastCFTrans ~= cFTrans then esp.Highlight.FillTransparency = cFTrans; esp._lastCFTrans = cFTrans end
        if esp._lastCOTrans ~= cOTrans then esp.Highlight.OutlineTransparency = cOTrans; esp._lastCOTrans = cOTrans end
    else
        if esp.Highlight.Enabled then
            esp.Highlight.Enabled = false
            esp.Highlight.Adornee = nil
        end
    end

    -- === 2D SCREEN ENGINE (Boxes, Names, Tracers) ===
    local rootScreenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local depth = rootScreenPos.Z

    -- Tracers can technically render pointing off-screen, but we cull them if behind camera
    if visSet.TracerLines and depth > 0 then
        if not TracerLineCache[player] then
            TracerLineCache[player] = SafeDrawingNew("Line")
            TracerLineCache[player].Thickness = 1.5
        end
        local tLine = TracerLineCache[player]
        tLine.Color = visSet.TracerColor
        tLine.From = tracerStartPos
        tLine.To = Vector2New(rootScreenPos.X, rootScreenPos.Y)
        tLine.Visible = onScreen
    elseif TracerLineCache[player] then
        TracerLineCache[player].Visible = false
    end

    -- Cull 2D ESP if off-screen or ESP disabled
    if not espEnabled or not onScreen or depth <= 0 then
        esp.Box.Visible = false; esp.BoxOutline.Visible = false; esp.BoxFill.Visible = false
        esp.Name.Visible = false; esp.Username.Visible = false; esp.Distance.Visible = false; esp.Health.Visible = false
        esp.BarBG.Visible = false; esp.BarFG.Visible = false
        if esp.SnapLine then esp.SnapLine.Visible = false end
        continue
    end

    -- Stable Box Math (Prevents Animation Jitter)
    local headCalcPos = rootPart.Position + Vector3New(0, 2.5, 0)
    local legCalcPos = rootPart.Position - Vector3New(0, 3, 0)
    local headScreenPos = Camera:WorldToViewportPoint(headCalcPos)
    local legScreenPos = Camera:WorldToViewportPoint(legCalcPos)

    local boxHeight = mathAbs(headScreenPos.Y - legScreenPos.Y)
    local boxWidth = boxHeight * 0.6
    local xPosition = rootScreenPos.X - (boxWidth * 0.5)
    local yPosition = headScreenPos.Y
    
    local finalDrawColor
    if isTeammate and visSet.ShowTeammates then 
        finalDrawColor = visSet.TeammateColor
    elseif visSet.UseVisColors then 
        finalDrawColor = esp._isVisible and visSet.VisColor or visSet.HiddenColor
    else 
        finalDrawColor = visSet.VisColor 
    end

    -- Box Rendering
    if visSet.ESPBoxes then
        esp.Box.Visible = true; esp.Box.Size = Vector2New(boxWidth, boxHeight)
        esp.Box.Position = Vector2New(xPosition, yPosition)
        if esp.Box.Color ~= finalDrawColor then esp.Box.Color = finalDrawColor end
        
        if visSet.ESPOutline then
            esp.BoxOutline.Visible = true; esp.BoxOutline.Size = Vector2New(boxWidth + 3, boxHeight + 3)
            esp.BoxOutline.Position = Vector2New(xPosition - 1.5, yPosition - 1.5)
        else 
            esp.BoxOutline.Visible = false 
        end

        if visSet.ESPBoxFill then
            esp.BoxFill.Visible = true; esp.BoxFill.Size = Vector2New(boxWidth, boxHeight)
            esp.BoxFill.Position = Vector2New(xPosition, yPosition)
            if esp.BoxFill.Color ~= finalDrawColor then esp.BoxFill.Color = finalDrawColor end
            esp.BoxFill.Transparency = visSet.ESPBoxFillTrans
        else
            esp.BoxFill.Visible = false
        end
    else
        esp.Box.Visible = false; esp.BoxOutline.Visible = false; esp.BoxFill.Visible = false
    end

    -- Text Property Caching
    if esp.Name.Font ~= visSet.ESPFont then esp.Name.Font = visSet.ESPFont end
    if esp.Username.Font ~= visSet.ESPFont then esp.Username.Font = visSet.ESPFont end
    if esp.Distance.Font ~= visSet.ESPFont then esp.Distance.Font = visSet.ESPFont end
    if esp.Health.Font ~= visSet.ESPFont then esp.Health.Font = visSet.ESPFont end

    local nameYPos = yPosition - visSet.ESPTextScale - 4
    local nameColor = visSet.UseCustomNameColor and visSet.ESPNameColor or finalDrawColor
    local userColor = visSet.UseCustomNameColor and visSet.ESPUsernameColor or finalDrawColor

    -- Name Rendering
    if visSet.ESPNames then
        if visSet.ESPNameStyle == "Display Name" or visSet.ESPNameStyle == "Both" then
            esp.Name.Visible = true
            local dName = player.DisplayName
            if esp.Name.Text ~= dName then esp.Name.Text = dName end
            esp.Name.Position = Vector2New(rootScreenPos.X, nameYPos)
            if esp.Name.Color ~= nameColor then esp.Name.Color = nameColor end
            if esp.Name.Size ~= visSet.ESPTextScale then esp.Name.Size = visSet.ESPTextScale end
            
            if visSet.ESPNameStyle == "Both" then nameYPos = nameYPos - (visSet.ESPTextScale - 2) end
        else esp.Name.Visible = false end

        if visSet.ESPNameStyle == "Username" or visSet.ESPNameStyle == "Both" then
            esp.Username.Visible = true
            local uName = "@" .. player.Name
            if esp.Username.Text ~= uName then esp.Username.Text = uName end
            esp.Username.Position = Vector2New(rootScreenPos.X, nameYPos)
            if esp.Username.Color ~= userColor then esp.Username.Color = userColor end
            local smallSize = mathMax(10, visSet.ESPTextScale - 2)
            if esp.Username.Size ~= smallSize then esp.Username.Size = smallSize end
        else esp.Username.Visible = false end
    else 
        esp.Name.Visible = false; esp.Username.Visible = false 
    end

    -- Health Bar Rendering
    local healthPercentage = mathClamp((humanoid.Health or 0) / (humanoid.MaxHealth or 100), 0, 1)
    if visSet.HealthBar then
        local fillHeight = mathMax(1, boxHeight * healthPercentage)
        esp.BarBG.Visible = true; esp.BarBG.Size = Vector2New(4, boxHeight + 2)
        esp.BarBG.Position = Vector2New(xPosition - 7, yPosition - 1)
        
        esp.BarFG.Visible = true; esp.BarFG.Size = Vector2New(2, fillHeight)
        esp.BarFG.Position = Vector2New(xPosition - 6, yPosition + boxHeight - fillHeight)
        local hpCol = GetHealthColor(healthPercentage)
        if esp.BarFG.Color ~= hpCol then esp.BarFG.Color = hpCol end
    else 
        esp.BarBG.Visible = false; esp.BarFG.Visible = false 
    end

    local belowOffset = 4
    -- Distance Rendering
    if visSet.DistanceDisplay then
        esp.Distance.Visible = true
        local distStr = mathFloor(depth) .. "m"
        if esp.Distance.Text ~= distStr then 
            esp.Distance.Text = distStr 
            esp.Distance.Color = GetDistanceColor(depth)
        end
        esp.Distance.Position = Vector2New(rootScreenPos.X, yPosition + boxHeight + belowOffset)
        local distSize = mathMax(10, visSet.ESPTextScale - 2)
        if esp.Distance.Size ~= distSize then esp.Distance.Size = distSize end
        belowOffset = belowOffset + distSize + 2
    else 
        esp.Distance.Visible = false 
    end

    -- Health Text Rendering
    if visSet.HealthNumbers then
        esp.Health.Visible = true
        local hpStr = mathFloor(humanoid.Health) .. " HP"
        if esp.Health.Text ~= hpStr then 
            esp.Health.Text = hpStr 
            esp.Health.Color = GetHealthColor(healthPercentage)
        end
        esp.Health.Position = Vector2New(rootScreenPos.X, yPosition + boxHeight + belowOffset)
        local hpSize = mathMax(10, visSet.ESPTextScale - 2)
        if esp.Health.Size ~= hpSize then esp.Health.Size = hpSize end
    else 
        esp.Health.Visible = false 
    end

    -- Snap Lines Rendering
    if visSet.SnapLines then
        if not esp.SnapLine then 
            esp.SnapLine = SafeDrawingNew("Line")
            esp.SnapLine.Thickness = 1.5 
        end
        if esp.SnapLine.Color ~= visSet.SnapLineColor then esp.SnapLine.Color = visSet.SnapLineColor end
        esp.SnapLine.From = center
        esp.SnapLine.To = Vector2New(rootScreenPos.X, rootScreenPos.Y)
        esp.SnapLine.Visible = true
    elseif esp.SnapLine then
        esp.SnapLine:Remove(); esp.SnapLine = nil
    end
end


end

-- ============================================================
--  MASTER RENDER LOOP
-- ============================================================
tableInsert(KaimConnections, RunService.RenderStepped:Connect(function(deltaTime)
FRAME_COUNT = FRAME_COUNT + 1
Camera = workspace.CurrentCamera -- Dynamic Camera Refresh (Prevents cutscene/vehicle breaks)

local camPos = Camera.CFrame.Position
local viewport = Camera.ViewportSize
if viewport.X == 0 or viewport.Y == 0 then return end

local screenWidth, screenHeight = viewport.X, viewport.Y
local screenCenter = Vector2New(screenWidth * 0.5, screenHeight * 0.5)

-- Retrieve fast pointers to settings
local aimSet   = Settings.Aimlock
local tbSet    = Settings.Triggerbot
local fovSet   = Settings.FOV
local visSet   = Settings.Visuals
local avoidSet = Settings.DetectionAvoidance

UpdateFOV(screenCenter, fovSet)
UpdateAimlock(camPos, screenWidth, screenHeight, deltaTime, aimSet, avoidSet, visSet, fovSet)
UpdateTriggerbot(deltaTime, tbSet, aimSet)
UpdatePlayerMods(Settings.Player)
UpdateESP(camPos, screenWidth, screenHeight, visSet)


end))

-- ============================================================
--  WINDUI MENU BUILDING
-- ============================================================
local Window = WindUI:CreateWindow({
Title       = "KAIM v4.1",
Author      = "by FRK",
Folder      = "Kaim",
Size        = UDim2.fromOffset(650, 580),
Theme       = "Dark",
Transparent = true,
Resizable   = true,
})

Window:Tag({
Title = "v4.1.2",
Icon = "github",
Color = Color3.fromRGB(0, 255, 100),
Border = true
})
Window:SetToggleKey(Enum.KeyCode.K)

-- Strict Tab Parenting to Window
local Tabs = {
Home    = Window:Tab({ Title = "Home", Icon = "home" }),
Combat  = Window:Tab({ Title = "Combat", Icon = "crosshair" }),
ESP     = Window:Tab({ Title = "ESP Visuals", Icon = "eye" }),
Player  = Window:Tab({ Title = "Local Player", Icon = "user" }),
Visuals = Window:Tab({ Title = "UI & Screen", Icon = "palette" }),
Config  = Window:Tab({ Title = "Config & Settings", Icon = "settings" })
}

-- ============================================================
--  HOME TAB
-- ============================================================
Tabs.Home:Paragraph({ Title = "Welcome to KAIM v4.1", Desc = "KAIM v4.1 is the latest, most highly optimized combat utility built on WindUI. Every loop is designed for true 144+ FPS performance with $O(1)$ memory caching." })
Tabs.Home:Paragraph({ Title = "What's New in v4.1", Desc = "• New Triggerbot Module\n• Upgraded Chams Engine\n• Zero-Leak Disconnect Engine\n• Dynamic Executor Analytics" })
Tabs.Home:Space()
Tabs.Home:Paragraph({ Title = "Getting Started", Desc = "Press K to open and close this menu at any time. Hold Right Click (or custom keybind) to activate aimlock. Try turning on Triggerbot for automatic shots." })
Tabs.Home:Paragraph({ Title = "Aim Modes", Desc = "Smart: Picks highest-priority visible part.\nChaos: Randomly cycles parts every 0.3s to bypass hit checks." })
Tabs.Home:Space()
Tabs.Home:Paragraph({ Title = "Default Keybinds", Desc = "K — Open/Close menu\nRight Click — Hold for Aimlock\nN — Toggle Noclip" })

-- ============================================================
--  COMBAT TAB (Aimlock + Triggerbot)
-- ============================================================
local AimSection = Tabs.Combat:Section({ Title = "Aimlock Core", Box = true, Opened = true })
AimSection:Toggle({ Title = "Enable Aimlock", Flag = "AimlockEnabled", Value = false, Callback = function(v) Settings.Aimlock.Enabled = v end })
AimSection:Keybind({ Title = "Aimlock Key", Flag = "AimlockKeybind", Value = "RightClick", Callback = function(v) Settings.Aimlock.Keybind = v end })
AimSection:Toggle({ Title = "Wall Check", Flag = "AimlockWallCheck", Value = true, Callback = function(v) Settings.Aimlock.WallCheck = v end })
AimSection:Toggle({ Title = "Team Check", Flag = "AimlockTeamCheck", Value = true, Callback = function(v) Settings.Aimlock.TeamCheck = v end })

local TBotSection = Tabs.Combat:Section({ Title = "Triggerbot", Box = true, Opened = true })
TBotSection:Toggle({ Title = "Enable Triggerbot", Flag = "TBEnabled", Value = false, Callback = function(v) Settings.Triggerbot.Enabled = v end })
TBotSection:Slider({ Title = "Trigger Delay", Flag = "TBDelay", Step = 0.01, Value = { Min = 0.01, Max = 0.5, Default = 0.05 }, Callback = function(v) Settings.Triggerbot.Delay = v end })
TBotSection:Toggle({ Title = "Team Check", Flag = "TBTeamCheck", Value = true, Callback = function(v) Settings.Triggerbot.TeamCheck = v end })

local AimTuning = Tabs.Combat:Section({ Title = "Aim Tuning", Box = true, Opened = false })
AimTuning:Dropdown({
Title = "Aim Mode", Flag = "AimlockAimMode", Values = { "Smart", "Chaos", "Head", "Torso", "Limbs", "HRP" }, Value = "Smart",
Callback = function(v)
Settings.Aimlock.AimMode = v
if v == "Chaos" then chaosTimer = 0; chaosLastPart = ""; chaosCurrentPart = PickNextChaosPart() end
end
})
AimTuning:Toggle({ Title = "Enable Prediction", Flag = "AimlockPredictionEnabled", Value = true, Callback = function(v) Settings.Aimlock.PredictionEnabled = v end })
AimTuning:Slider({ Title = "Prediction Strength", Flag = "AimlockPrediction", Step = 0.005, Value = { Min = 0, Max = 0.3, Default = 0.135 }, Callback = function(v) Settings.Aimlock.Prediction = v end })
AimTuning:Slider({ Title = "Strafe Multiplier", Flag = "AimlockStrafePrediction", Step = 0.05, Value = { Min = 0.5, Max = 2.5, Default = 1.0 }, Callback = function(v) Settings.Aimlock.StrafePrediction = v end })

local AdvAim = Tabs.Combat:Section({ Title = "Advanced Aiming", Box = true, Opened = false })
AdvAim:Toggle({ Title = "Smooth Aiming", Flag = "AimlockSmooth", Value = false, Callback = function(v) Settings.Aimlock.SmoothAiming = v end })
AdvAim:Slider({ Title = "Smooth Speed", Flag = "AimlockSmoothSpeed", Step = 0.05, Value = { Min = 0.05, Max = 1.0, Default = 0.3 }, Callback = function(v) Settings.Aimlock.SmoothSpeed = v end })
AdvAim:Toggle({ Title = "Random Jitter", Flag = "AimlockJitter", Value = false, Callback = function(v) Settings.DetectionAvoidance.RandomJitter = v end })
AdvAim:Slider({ Title = "Jitter Amount", Flag = "AimlockJitterAmount", Step = 0.005, Value = { Min = 0, Max = 0.2, Default = 0.05 }, Callback = function(v) Settings.DetectionAvoidance.JitterAmount = v end })
AdvAim:Toggle({ Title = "Periodic Disable", Flag = "AimlockPeriodicDisable", Value = false, Callback = function(v) Settings.DetectionAvoidance.PeriodicAimDisable = v end })
AdvAim:Slider({ Title = "Disable Chance", Flag = "AimlockDisableChance", Step = 0.01, Value = { Min = 0, Max = 1.0, Default = 0.1 }, Callback = function(v) Settings.DetectionAvoidance.DisableChance = v end })

-- ============================================================
--  ESP TAB
-- ============================================================
local ESPCore = Tabs.ESP:Section({ Title = "ESP Core", Box = true, Opened = true })
ESPCore:Toggle({ Title = "Enable ESP", Flag = "ESPEnabled", Value = false, Callback = function(v) Settings.Visuals.ESPEnabled = v end })
ESPCore:Toggle({ Title = "Team Check", Flag = "ESPTeamCheck", Value = true, Callback = function(v) Settings.Visuals.TeamCheck = v end })
ESPCore:Toggle({ Title = "Show Teammates", Flag = "ESPShowTeammates", Value = false, Callback = function(v) Settings.Visuals.ShowTeammates = v end })
ESPCore:Colorpicker({ Title = "Teammate Color", Flag = "ESPTeammateColor", Default = Color3RGB(0, 200, 255), Transparency = 0, Callback = function(v) Settings.Visuals.TeammateColor = v end })

local BoxSection = Tabs.ESP:Section({ Title = "Box Styling", Box = true, Opened = true })
BoxSection:Toggle({ Title = "ESP Boxes", Flag = "ESPBoxes", Value = true, Callback = function(v) Settings.Visuals.ESPBoxes = v end })
BoxSection:Toggle({ Title = "Box Outline", Flag = "ESPOutline", Value = true, Callback = function(v) Settings.Visuals.ESPOutline = v end })
BoxSection:Toggle({ Title = "Box Fill (Background)", Flag = "ESPBoxFill", Value = false, Callback = function(v) Settings.Visuals.ESPBoxFill = v end })
BoxSection:Slider({ Title = "Fill Transparency", Flag = "ESPBoxFillTrans", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0.2 }, Callback = function(v) Settings.Visuals.ESPBoxFillTrans = v end })

local ColorSection = Tabs.ESP:Section({ Title = "Visibility Colors", Box = true, Opened = false })
ColorSection:Toggle({ Title = "Visibility Colors", Flag = "ESPVisColors", Value = true, Callback = function(v) Settings.Visuals.UseVisColors = v end })
ColorSection:Colorpicker({ Title = "Visible Color", Flag = "ESPVisColor", Default = Color3RGB(0, 255, 100), Transparency = 0, Callback = function(v) Settings.Visuals.VisColor = v end })
ColorSection:Colorpicker({ Title = "Hidden Color", Flag = "ESPHiddenColor", Default = Color3RGB(255, 50, 50), Transparency = 0, Callback = function(v) Settings.Visuals.HiddenColor = v end })

local TextSection = Tabs.ESP:Section({ Title = "Text & Typography", Box = true, Opened = false })
TextSection:Toggle({ Title = "Show Names", Flag = "ESPNames", Value = true, Callback = function(v) Settings.Visuals.ESPNames = v end })
TextSection:Dropdown({ Title = "Name Style", Flag = "ESPNameStyle", Values = { "Display Name", "Username", "Both" }, Value = "Display Name", Callback = function(v) Settings.Visuals.ESPNameStyle = v end })
TextSection:Dropdown({ Title = "ESP Font", Flag = "ESPFont", Values = { "UI", "System", "Plex", "Monospace" }, Value = "Plex", Callback = function(v)
local fontMap = { UI = 0, System = 1, Plex = 2, Monospace = 3 }
Settings.Visuals.ESPFont = fontMap[v] or 2
end })
TextSection:Slider({ Title = "Text Scale", Flag = "ESPTextScale", Step = 1, Value = { Min = 10, Max = 22, Default = 14 }, Callback = function(v) Settings.Visuals.ESPTextScale = v end })
TextSection:Toggle({ Title = "Custom Name Color", Flag = "ESPCustomNameColor", Value = false, Callback = function(v) Settings.Visuals.UseCustomNameColor = v end })
TextSection:Colorpicker({ Title = "Display Name Color", Flag = "ESPNameColor", Default = Color3RGB(255, 255, 255), Transparency = 0, Callback = function(v) Settings.Visuals.ESPNameColor = v end })

local HealthSection = Tabs.ESP:Section({ Title = "Health Info", Box = true, Opened = false })
HealthSection:Toggle({ Title = "Health Bar", Flag = "ESPHealthBar", Value = true, Callback = function(v) Settings.Visuals.HealthBar = v end })
HealthSection:Toggle({ Title = "Health Numbers", Flag = "ESPHealthNumbers", Value = false, Callback = function(v) Settings.Visuals.HealthNumbers = v end })

local DistSection = Tabs.ESP:Section({ Title = "Distance Info", Box = true, Opened = false })
DistSection:Slider({ Title = "ESP Range", Flag = "ESPRange", Step = 100, Value = { Min = 100, Max = 5000, Default = 1000 }, Callback = function(v) Settings.Visuals.MaxESPDistance = v end })
DistSection:Toggle({ Title = "Distance Display", Flag = "ESPDistDisplay", Value = false, Callback = function(v) Settings.Visuals.DistanceDisplay = v end })

-- UPGRADED CHAMS SECTION
local ChamsSection = Tabs.ESP:Section({ Title = "Chams Overlay", Box = true, Opened = false })
ChamsSection:Toggle({ Title = "Enable Chams", Flag = "ChamsEnabled", Value = false, Callback = function(v) Settings.Visuals.ChamsEnabled = v end })
ChamsSection:Toggle({ Title = "See Through Walls", Flag = "ChamsDepth", Value = true, Callback = function(v)
Settings.Visuals.ChamsDepth = v
for _, esp in pairs(ESPObjects) do
if esp.Highlight then
esp.Highlight.DepthMode = v and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
end
end
end })
ChamsSection:Toggle({ Title = "Use Visibility Colors", Flag = "ChamsVisColors", Value = true, Callback = function(v) Settings.Visuals.ChamsUseVisColors = v end })
ChamsSection:Slider({ Title = "Fill Transparency", Flag = "ChamsFillTrans", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0.5 }, Callback = function(v) Settings.Visuals.ChamsFillTrans = v end })
ChamsSection:Slider({ Title = "Outline Transparency", Flag = "ChamsOutlineTrans", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0 }, Callback = function(v) Settings.Visuals.ChamsOutlineTrans = v end })
ChamsSection:Colorpicker({ Title = "Fill Color", Flag = "ChamsFill", Default = Color3RGB(255, 85, 0), Transparency = 0, Callback = function(v) Settings.Visuals.ChamsFillColor = v end })
ChamsSection:Colorpicker({ Title = "Outline Color", Flag = "ChamsOutline", Default = Color3RGB(255, 255, 255), Transparency = 0, Callback = function(v) Settings.Visuals.ChamsOutlineColor = v end })

local LinesSection = Tabs.ESP:Section({ Title = "Tracers & Lines", Box = true, Opened = false })
LinesSection:Toggle({ Title = "Tracer Lines", Flag = "TracerLines", Value = false, Callback = function(v) Settings.Visuals.TracerLines = v end })
LinesSection:Dropdown({ Title = "Tracer Origin", Flag = "TracerOrigin", Values = { "Bottom", "Center", "Top" }, Value = "Bottom", Callback = function(v) Settings.Visuals.TracerOrigin = v end })
LinesSection:Colorpicker({ Title = "Tracer Color", Flag = "TracerColor", Default = Color3RGB(255, 170, 0), Transparency = 0, Callback = function(v) Settings.Visuals.TracerColor = v end })
LinesSection:Toggle({ Title = "Snap Lines", Flag = "SnapLines", Value = false, Callback = function(v) Settings.Visuals.SnapLines = v end })
LinesSection:Colorpicker({ Title = "Snap Line Color", Flag = "SnapLineColor", Default = Color3RGB(255, 85, 0), Transparency = 0, Callback = function(v) Settings.Visuals.SnapLineColor = v end })

-- ============================================================
--  PLAYER TAB
-- ============================================================
local SpeedSection = Tabs.Player:Section({ Title = "Walk Speed", Box = true, Opened = true })
SpeedSection:Toggle({ Title = "Enable Walk Speed", Flag = "WalkSpeedEnabled", Value = false, Callback = function(v) Settings.Player.WalkSpeedEnabled = v end })
SpeedSection:Slider({ Title = "Walk Speed", Flag = "WalkSpeed", Step = 1, Value = { Min = 5, Max = 100, Default = 16 }, Callback = function(v) Settings.Player.WalkSpeed = v end })

local JumpSection = Tabs.Player:Section({ Title = "Jump Power", Box = true, Opened = true })
JumpSection:Toggle({ Title = "Enable Jump Power", Flag = "JumpPowerEnabled", Value = false, Callback = function(v) Settings.Player.JumpPowerEnabled = v end })
JumpSection:Slider({ Title = "Jump Power", Flag = "JumpPower", Step = 5, Value = { Min = 10, Max = 250, Default = 50 }, Callback = function(v) Settings.Player.JumpPower = v end })

local NoclipSection = Tabs.Player:Section({ Title = "Noclip", Box = true, Opened = true })
local noclipConn = nil
local noclipCache = {}

local function BuildNoclipCache(character)
noclipCache = {}
if not character then return end
for _, part in ipairs(character:GetDescendants()) do
if part:IsA("BasePart") then tableInsert(noclipCache, { part = part, original = part.CanCollide }) end
end
end

local function SetNoclip(state)
Settings.Player.NoclipEnabled = state
if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
if state then
BuildNoclipCache(LocalPlayer.Character)
noclipConn = RunService.Stepped:Connect(function()
for _, entry in ipairs(noclipCache) do
if entry.part and entry.part.CanCollide then entry.part.CanCollide = false end
end
end)
tableInsert(KaimConnections, noclipConn)
else
for _, entry in ipairs(noclipCache) do
if entry.part then entry.part.CanCollide = entry.original end
end
noclipCache = {}
end
end

tableInsert(KaimConnections, LocalPlayer.CharacterAdded:Connect(function(char)
if Settings.Player.NoclipEnabled then task.defer(function() BuildNoclipCache(char) end) end
end))

NoclipSection:Toggle({ Title = "Enable Noclip", Flag = "Noclip", Value = false, Callback = function(v) SetNoclip(v) end })
NoclipSection:Keybind({ Title = "Noclip Keybind", Flag = "NoclipKeybind", Value = "N", Callback = function(v)
Settings.Player.NoclipKeybind = v
pcall(function() cachedNoclipKC = Enum.KeyCode[v] end)
end })

-- ============================================================
--  VISUALS TAB
-- ============================================================
local FOVSection = Tabs.Visuals:Section({ Title = "FOV Circle", Box = true, Opened = true })
FOVSection:Toggle({ Title = "Show FOV Circle", Flag = "FOVVisible", Value = true, Callback = function(v) Settings.FOV.Visible = v end })
FOVSection:Toggle({ Title = "Follow Cursor", Flag = "FOVFollowCursor", Value = true, Callback = function(v) Settings.FOV.FollowCursor = v end })
FOVSection:Slider({ Title = "FOV Radius", Flag = "FOVRadius", Step = 5, Value = { Min = 30, Max = 600, Default = 150 }, Callback = function(v) Settings.FOV.Radius = v end })
FOVSection:Slider({ Title = "Ring Thickness", Flag = "FOVThickness", Step = 0.5, Value = { Min = 0.5, Max = 6, Default = 1.5 }, Callback = function(v) Settings.FOV.Thickness = v end })
FOVSection:Slider({ Title = "Ring Transparency", Flag = "FOVTransparency", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0.8 }, Callback = function(v) Settings.FOV.Transparency = v end })
FOVSection:Colorpicker({ Title = "Ring Color", Flag = "FOVColor", Default = Color3RGB(255, 255, 255), Transparency = 0, Callback = function(v) Settings.FOV.Color = v end })

local FillSection = Tabs.Visuals:Section({ Title = "FOV Fill", Box = true, Opened = false })
FillSection:Toggle({ Title = "Filled Circle", Flag = "FOVFilled", Value = false, Callback = function(v) Settings.FOV.Filled = v end })
FillSection:Slider({ Title = "Fill Transparency", Flag = "FOVFilledTransp", Step = 0.02, Value = { Min = 0.5, Max = 1, Default = 0.92 }, Callback = function(v) Settings.FOV.FilledTransp = v end })
FillSection:Colorpicker({ Title = "Fill Color", Flag = "FOVFillColor", Default = Color3RGB(255, 255, 255), Transparency = 0, Callback = function(v) Settings.FOV.FilledColor = v end })

local HUDSection = Tabs.Visuals:Section({ Title = "Target HUD", Box = true, Opened = true })
HUDSection:Toggle({ Title = "Show Target HUD", Flag = "HUDEnabled", Value = true, Callback = function(v) Settings.Visuals.TargetUI = v end })
HUDSection:Slider({ Title = "Target HUD Scale", Flag = "HUDScale", Step = 0.1, Value = { Min = 0.5, Max = 2.0, Default = 1.0 }, Callback = function(v) Settings.Visuals.TargetUIScale = v end })

-- ============================================================
--  CONFIG & SETTINGS TAB
-- ============================================================
local DiagnosticsSection = Tabs.Config:Section({ Title = "Environment Analytics (v4.1)", Box = true, Opened = true })
Tabs.Config:Paragraph({ Title = "Executor Environment", Desc = string.format("%s (v%s)", ExecName, ExecVer) })
Tabs.Config:Paragraph({ Title = "Trust Status", Desc = ExecSafety })
Tabs.Config:Paragraph({ Title = "Universal Naming Convention", Desc = string.format("~%d%% Custom UNC Coverage", ExecUNC) })
Tabs.Config:Paragraph({ Title = "Compatibility", Desc = ExecCompat })

local UISection = Tabs.Config:Section({ Title = "UI Controls", Box = true, Opened = false })
UISection:Keybind({ Title = "Toggle UI Key", Flag = "UIToggleKey", Value = "K", Callback = function(v)
Settings.UI.ToggleKey = v
local ok, kc = pcall(function() return Enum.KeyCode[v] end)
if ok and kc then Window:SetToggleKey(kc) end
end })
UISection:Slider({ Title = "Window Transparency", Flag = "UITransparency", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0 }, Callback = function(v) Window:SetBackgroundImageTransparency(v) end })
UISection:Toggle({ Title = "Lower Notifications", Flag = "UILowerNotify", Value = false, Callback = function(v) WindUI:SetNotificationLower(v) end })

local ThemeSection = Tabs.Config:Section({ Title = "Interface Theme & Style", Box = true, Opened = false })
ThemeSection:Dropdown({ Title = "Select Theme", Flag = "UITheme", Values = { "Dark", "Light", "Rose", "Mellowsi", "Amethyst", "Ocean", "Sunset" }, Value = "Dark", Callback = function(v) WindUI:SetTheme(v) end })
ThemeSection:Slider({ Title = "UI Scale", Flag = "UIScale", Step = 0.05, Value = { Min = 0.5, Max = 1.5, Default = 1.0 }, Callback = function(v) pcall(function() Window:SetUIScale(v) end) end })

-- Official Config Manager Implementation
local ConfigSection = Tabs.Config:Section({ Title = "Config Manager", Box = true, Opened = true })
local ConfigManager = Window.ConfigManager
local ConfigName = "kaim_v4"

local ConfigNameInput = ConfigSection:Input({
Title = "Config Name",
Icon = "file-cog",
Callback = function(value) ConfigName = value end
})

local AllConfigs = ConfigManager:AllConfigs()
local DefaultValue = table.find(AllConfigs, ConfigName) and ConfigName or nil

local AllConfigsDropdown = ConfigSection:Dropdown({
Title = "Saved Configs",
Desc = "Select existing configs",
Values = AllConfigs,
Value = DefaultValue,
Callback = function(value)
ConfigName = value
ConfigNameInput:Set(value)
end
})

ConfigSection:Button({
Title = "Save Config",
Justify = "Center",
Callback = function()
Window.CurrentConfig = ConfigManager:Config(ConfigName)
if Window.CurrentConfig:Save() then
WindUI:Notify({ Title = "Config Saved", Content = "Saved " .. ConfigName .. ".json", Icon = "check" })
end
AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
end
})

ConfigSection:Button({
Title = "Load Config",
Justify = "Center",
Callback = function()
Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
if Window.CurrentConfig:Load() then
WindUI:Notify({ Title = "Config Loaded", Content = "Loaded " .. ConfigName .. ".json", Icon = "check" })
end
end
})

local DangerSection = Tabs.Config:Section({ Title = "Danger Zone", Box = true, Opened = true })
DangerSection:Button({
Title = "Unload KAIM",
Justify = "Center",
Callback = function()
for _, conn in ipairs(KaimConnections) do conn:Disconnect() end
for _, esp in pairs(ESPObjects) do
pcall(function()
esp.Box:Remove(); esp.BoxOutline:Remove(); esp.BoxFill:Remove()
esp.Name:Remove(); esp.Username:Remove(); esp.Distance:Remove(); esp.Health:Remove()
esp.BarBG:Remove(); esp.BarFG:Remove()
if esp.SnapLine then esp.SnapLine:Remove() end
esp.Highlight:Destroy()
end)
end
ESPObjects = {}
for _, line in pairs(TracerLineCache) do pcall(function() line:Remove() end) end
TracerLineCache = {}

    pcall(function() FOVRing:Remove() end)
    pcall(function() FOVFill:Remove() end)
    pcall(function() ChamsFolder:Destroy() end)

    pcall(function() THUD.BG:Remove() end)
    pcall(function() THUD.Accent:Remove() end)
    pcall(function() THUD.Name:Remove() end)
    pcall(function() THUD.Data:Remove() end)
    pcall(function() THUD.BarBG:Remove() end)
    pcall(function() THUD.BarFG:Remove() end)

    Window:Destroy()
end


})

-- ============================================================
--  INPUT HANDLING
-- ============================================================
local noclipNotifyDebounce = false

tableInsert(KaimConnections, UserInputService.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == cachedNoclipKC then
if not noclipNotifyDebounce then
noclipNotifyDebounce = true
local newState = not Settings.Player.NoclipEnabled
SetNoclip(newState)
WindUI:Notify({ Title = "Noclip", Content = "Noclip is now " .. (newState and "ON" or "OFF"), Duration = 2, Icon = "ghost" })
task.delay(0.3, function() noclipNotifyDebounce = false end)
end
end
local aimKey = Settings.Aimlock.Keybind
if aimKey == "RightClick" then
if input.UserInputType == Enum.UserInputType.MouseButton2 then Settings.Aimlock.IsAiming = true end
else
local ok, kc = pcall(function() return Enum.KeyCode[aimKey] end)
if ok and kc and input.KeyCode == kc then Settings.Aimlock.IsAiming = true end
end
end))

tableInsert(KaimConnections, UserInputService.InputEnded:Connect(function(input)
local aimKey = Settings.Aimlock.Keybind
if aimKey == "RightClick" then
if input.UserInputType == Enum.UserInputType.MouseButton2 then Settings.Aimlock.IsAiming = false end
else
local ok, kc = pcall(function() return Enum.KeyCode[aimKey] end)
if ok and kc and input.KeyCode == kc then Settings.Aimlock.IsAiming = false end
end
end))

Tabs.Home:Select()
WindUI:Notify({ Title = "KAIM v4.1 Chams Overhauled", Content = "Press K to toggle UI", Duration = 5, Icon = "check" })
