-- ============================================================
--  KAIM v6.0  |  WindUI Edition (The Zenith Update)
--  Flawless State Caching, Native APIs & True Optimization
-- ============================================================

-- STREAMING_CHUNK:Initializing core runtime services...
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInput     = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- Wait for engine readiness to prevent execution crashes
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- STREAMING_CHUNK:Securing injection container and fetching WindUI...
-- ============================================================
--  WINDUI SECURE INITIALIZATION
-- ============================================================
local SafeContainer = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
local WindUI

local function LoadWindUI()
local urls = {
"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
}
for _, url in ipairs(urls) do
local ok, result = pcall(function()
return loadstring(game:HttpGet(url))()
end)
if ok and result then return result end
end
return nil
end

WindUI = LoadWindUI()
if not WindUI then
warn("KAIM | Failed to load WindUI. Please check your internet or executor HTTP capabilities.")
return
end

-- STREAMING_CHUNK:Applying KAIM Signature styling palette...
-- ============================================================
--  KAIM SIGNATURE THEME
-- ============================================================
WindUI:AddTheme({
Name = "KAIM Signature",
Accent = Color3.fromHex("#FFFFFF"),
Background = Color3.fromHex("#080808"),
BackgroundTransparency = 0,
Outline = Color3.fromHex("#222222"),
Text = Color3.fromHex("#EAEAEA"),
Placeholder = Color3.fromHex("#666666"),
Button = Color3.fromHex("#121212"),
Icon = Color3.fromHex("#FFFFFF"),
Hover = Color3.fromHex("#1A1A1A"),
WindowBackground = Color3.fromHex("#060606"),
WindowShadow = Color3.fromHex("#000000"),
DialogBackground = Color3.fromHex("#080808"),
DialogBackgroundTransparency = 0,
DialogTitle = Color3.fromHex("#FFFFFF"),
DialogContent = Color3.fromHex("#AAAAAA"),
DialogIcon = Color3.fromHex("#FFFFFF"),
WindowTopbarButtonIcon = Color3.fromHex("#888888"),
WindowTopbarTitle = Color3.fromHex("#FFFFFF"),
WindowTopbarAuthor = Color3.fromHex("#888888"),
WindowTopbarIcon = Color3.fromHex("#FFFFFF"),
TabBackground = Color3.fromHex("#0C0C0C"),
TabTitle = Color3.fromHex("#FFFFFF"),
TabIcon = Color3.fromHex("#FFFFFF"),
ElementBackground = Color3.fromHex("#0C0C0C"),
ElementTitle = Color3.fromHex("#FFFFFF"),
ElementDesc = Color3.fromHex("#888888"),
ElementIcon = Color3.fromHex("#FFFFFF"),
PopupBackground = Color3.fromHex("#080808"),
PopupBackgroundTransparency = 0,
PopupTitle = Color3.fromHex("#FFFFFF"),
PopupContent = Color3.fromHex("#AAAAAA"),
PopupIcon = Color3.fromHex("#FFFFFF"),
Toggle = Color3.fromHex("#151515"),
ToggleBar = Color3.fromHex("#FFFFFF"),
Checkbox = Color3.fromHex("#151515"),
CheckboxIcon = Color3.fromHex("#000000"),
Slider = Color3.fromHex("#151515"),
SliderThumb = Color3.fromHex("#FFFFFF"),
})

-- STREAMING_CHUNK:Constructing Drawing API safety wrapper...
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

-- SMART STATE CACHER: Only writes to Drawing API if the value actually changed.
local function UpdateDraw(obj, props)
for k, v in pairs(props) do
if obj[k] ~= v then obj[k] = v end
end
end

-- STREAMING_CHUNK:Localizing math and CFrame matrices for high performance...
-- ============================================================
--  FAST LOCALS, CONSTANTS & MATH CACHING
-- ============================================================
local mathFloor   = math.floor
local mathClamp   = math.clamp
local mathAbs     = math.abs
local mathMax     = math.max
local mathMin     = math.min
local mathRandom  = math.random
local mathNoise   = math.noise
local mathAtan2   = math.atan2
local mathSin     = math.sin
local mathCos     = math.cos
local mathPi      = math.pi
local stringLen   = string.len
local osClock     = os.clock
local Vector2New  = Vector2.new
local Vector3New  = Vector3.new
local Color3RGB   = Color3.fromRGB
local CFrameNew   = CFrame.new
local tableInsert = table.insert
local tableRemove = table.remove

local VEC3_HEAD_OFFSET = Vector3New(0, 2.5, 0)
local VEC3_LEG_OFFSET  = Vector3New(0, 3, 0)

-- Pre-defining global color palettes for zero-GC allocation
local HP_COLORS = {
Color3RGB(255, 50, 50),   -- Red
Color3RGB(255, 130, 0),   -- Orange
Color3RGB(255, 200, 0),   -- Yellow
Color3RGB(100, 255, 50),  -- Lime
Color3RGB(0, 255, 100)    -- Green
}

local DIST_COLORS = {
Color3RGB(0, 255, 100),

Color3RGB(100, 255, 100),
Color3RGB(255, 210, 0),

Color3RGB(255, 140, 0),

Color3RGB(255, 50, 50)

}

-- STREAMING_CHUNK:Generating central configuration dictionary...
-- ============================================================
--  DEFAULT SETTINGS v6.0
-- ============================================================
local Settings = {
Aimlock = {
Enabled            = false,
AimMode            = "Smart",
TargetPriority     = "Crosshair",
Keybind            = "RightClick",
WallCheck          = true,
TeamCheck          = true,
PredictionEnabled  = true,
Prediction         = 0.135,
DynamicPrediction  = true,
StrafePrediction   = 1.0,
SmoothAiming       = false,
SmoothSpeed        = 0.3,
DynamicSmoothing   = false,
HitChance          = 100,
OffsetX            = 0,
OffsetY            = 0,
OffsetZ            = 0,
PerlinNoise        = false,
NoiseSpeed         = 1.0,
NoiseAmount        = 0.5,
PeriodicDisable    = false,
IsAiming           = false,
CurrentTarget      = nil,
_lastTargetSearch  = 0,
},
Triggerbot = {
Enabled            = false,
Delay              = 0.05,
HitChance          = 100,
TeamCheck          = true,
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
Pulse          = false,
},
Crosshair = {
Enabled        = false,
Size           = 8,
Gap            = 3,
Thickness      = 1.5,
Color          = Color3RGB(0, 255, 100),
ShowDot        = true,
DotSize        = 2,
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
WeaponESP          = false,
HealthNumbers      = false,
HealthBar          = true,
SkeletonESP        = false,
SkeletonColor      = Color3RGB(255, 255, 255),
SkeletonThickness  = 1.5,
LookTracers        = false,
LookTracerLength   = 5,
LookTracerColor    = Color3RGB(255, 255, 255),
OffScreenArrows    = false,
ArrowColor         = Color3RGB(255, 85, 0),
ArrowRadius        = 120,
ArrowSize          = 15,
ChamsEnabled       = false,
ChamsUseVisColors  = true,
ChamsFillColor     = Color3RGB(255, 255, 255),
ChamsOutlineColor  = Color3RGB(255, 255, 255),
ChamsFillTrans     = 0.5,
ChamsOutlineTrans  = 0,
ChamsDepth         = true,
TracerLines        = false,
TracerOrigin       = "Bottom",
TracerColor        = Color3RGB(255, 170, 0),
SnapLines          = false,
SnapLineColor      = Color3RGB(255, 85, 0),
DamageNumbers      = false,
DamageColor        = Color3RGB(255, 255, 0),
TargetUI           = true,
TargetUIStyle      = "Valorant",
TargetUIScale      = 1.0,
MaxESPDistance     = 1000,
},
Player = {
WalkSpeedEnabled = false,
WalkSpeed        = 16,
JumpPowerEnabled = false,
JumpPower        = 50,
InfiniteJump     = false,
CameraFOVEnabled = false,
CameraFOV        = 70,
NoclipEnabled    = false,
NoclipKeybind    = "N",
},
DetectionAvoidance = {
PeriodicAimDisable = false,
DisableChance      = 0.1,
DisableDuration    = 0.2,
},
UI = {
ToggleKey = "K",
},
}

-- STREAMING_CHUNK:Establishing non-volatile memory pools for objects...
-- ============================================================
--  ZERO-GC POOLS & HARD-POINTER CACHING
-- ============================================================
local KaimConnections = {}
local PlayerCache     = {}
local TeamCache       = {}
local ESPObjects      = {}
local CharCache       = {}
local TracerLineCache = {}
local LookTracerCache = {}

local DamageObjPool       = {}
local ActiveDamageNumbers = {}

local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRayParams.IgnoreWater = true
local GlobalRayFilter = {}

local CandidatePool = {}

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

local thudLerpedHP = 100
local thudAlpha    = 0
local thudLastTextCache = ""

-- STREAMING_CHUNK:Rendering 2D and 3D geometric boundaries...
-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing = SafeDrawingNew("Circle"); FOVRing.Visible = false; FOVRing.Thickness = 1.5; FOVRing.Filled = false
local FOVFill = SafeDrawingNew("Circle"); FOVFill.Visible = false; FOVFill.Thickness = 1; FOVFill.Filled = true

local CrosshairL = SafeDrawingNew("Line"); local CrosshairR = SafeDrawingNew("Line")
local CrosshairT = SafeDrawingNew("Line"); local CrosshairB = SafeDrawingNew("Line")
local CrosshairDot = SafeDrawingNew("Circle"); CrosshairDot.Visible = false; CrosshairDot.Filled = true

local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name  = "KaimChams"
pcall(function() ChamsFolder.Parent = SafeContainer end)

local THUD = {
Shadow = SafeDrawingNew("Square"), BG = SafeDrawingNew("Square"), Outline = SafeDrawingNew("Square"),
Accent = SafeDrawingNew("Square"), Accent2 = SafeDrawingNew("Square"),
Name = SafeDrawingNew("Text"), Data = SafeDrawingNew("Text"),
BarBG = SafeDrawingNew("Square"), BarFG = SafeDrawingNew("Square"),
}

local function InitTHUD()
THUD.Shadow.Filled = true; THUD.Shadow.Color = Color3RGB(0, 0, 0)
THUD.BG.Filled = true; THUD.BG.Color = Color3RGB(12, 12, 14)
THUD.Outline.Filled = false; THUD.Outline.Color = Color3RGB(34, 34, 40)
THUD.Accent.Filled = true; THUD.Accent2.Filled = true
THUD.Name.Outline = true; THUD.Name.Color = Color3RGB(255, 255, 255); THUD.Name.Font = 2
THUD.Data.Outline = true; THUD.Data.Color = Color3RGB(180, 180, 200); THUD.Data.Font = 2
THUD.BarBG.Filled = true; THUD.BarBG.Color = Color3RGB(20, 20, 25)
THUD.BarFG.Filled = true
end
InitTHUD()

-- STREAMING_CHUNK:Formulating logic for math helpers and physics engine...
-- ============================================================
--  UTILITY FUNCTIONS & PHYSICS ENGINE
-- ============================================================
local function GetHealthColor(percentage)
if percentage > 0.80 then return HP_COLORS[5] end
if percentage > 0.60 then return HP_COLORS[4] end
if percentage > 0.40 then return HP_COLORS[3] end
if percentage > 0.20 then return HP_COLORS[2] end
return HP_COLORS[1]
end

local function GetDistanceColor(distance)
if distance < 50  then return DIST_COLORS[1] end
if distance < 100 then return DIST_COLORS[2] end
if distance < 200 then return DIST_COLORS[3] end
if distance < 350 then return DIST_COLORS[4] end
return DIST_COLORS[5]
end

local function SpawnDamageNumber(damage, pos3d)
local dn = tableRemove(DamageObjPool)
if not dn then
dn = { TextObj = SafeDrawingNew("Text"), DamageStr = "", StartPos = Vector3New(), Velocity = Vector3New(), StartTime = 0 }
dn.TextObj.Center = true
dn.TextObj.Outline = true
dn.TextObj.OutlineColor = Color3RGB(0, 0, 0)
dn.TextObj.Font = 3
end

dn.DamageStr = tostring(mathFloor(damage)) 
local angle = mathRandom() * mathPi * 2
local speed = mathRandom(15, 30) / 10
dn.Velocity = Vector3New(mathCos(angle) * speed, mathRandom(35, 55) / 10, mathSin(angle) * speed)
dn.StartPos = pos3d + Vector3New((mathRandom()-0.5), 1.0, (mathRandom()-0.5))
dn.StartTime = osClock()

tableInsert(ActiveDamageNumbers, dn)


end

-- STREAMING_CHUNK:Compiling active damage number physics calculation...
local function UpdateDamageNumbers(visSet)
if not visSet.DamageNumbers and #ActiveDamageNumbers == 0 then return end
local currentTime = osClock()

for i = #ActiveDamageNumbers, 1, -1 do
    local dn = ActiveDamageNumbers[i]
    local elapsed = currentTime - dn.StartTime
    
    if elapsed >= 1.5 or not visSet.DamageNumbers then
        dn.TextObj.Visible = false
        tableInsert(DamageObjPool, dn)
        tableRemove(ActiveDamageNumbers, i)
    else
        local currentPos = dn.StartPos + (dn.Velocity * elapsed) - Vector3New(0, 12.5 * elapsed * elapsed, 0)
        local screenPos, onScreen = Camera:WorldToViewportPoint(currentPos)
        
        if onScreen then
            local size = elapsed < 0.15 and (14 + 18 * (elapsed / 0.15)) or (elapsed < 0.35 and (32 - 12 * ((elapsed - 0.15) / 0.20)) or 20)
            if dn.TextObj.Text ~= dn.DamageStr then dn.TextObj.Text = dn.DamageStr end
            
            local v2Pos = Vector2New(screenPos.X, screenPos.Y)
            if dn.TextObj.Position ~= v2Pos then dn.TextObj.Position = v2Pos end
            if dn.TextObj.Size ~= size then dn.TextObj.Size = size end
            if dn.TextObj.Color ~= visSet.DamageColor then dn.TextObj.Color = visSet.DamageColor end
            
            local alpha = elapsed > 1.0 and (1 - ((elapsed - 1.0) * 2)) or 1
            if dn.TextObj.Transparency ~= alpha then dn.TextObj.Transparency = alpha end
            if not dn.TextObj.Visible then dn.TextObj.Visible = true end
        else
            if dn.TextObj.Visible then dn.TextObj.Visible = false end
        end
    end
end


end

local function PickNextChaosPart()
local c = {}
for _, name in ipairs(CHAOS_PICK_LIST) do
if name ~= chaosLastPart then tableInsert(c, name) end
end
chaosLastPart = c[mathRandom(#c)]
return chaosLastPart
end

local function IsTeammateCached(player)
if TeamCache[player] == nil then TeamCache[player] = (player.Team ~= nil and player.Team == LocalPlayer.Team) end
return TeamCache[player]
end

-- STREAMING_CHUNK:Configuring Xeno-safe recursive raycast validation...
local function IsVisible(targetPart, targetChar)
if not targetPart or not targetChar then return false end
local camPos = Camera.CFrame.Position
local direction = targetPart.Position - camPos

table.clear(GlobalRayFilter)
if LocalPlayer.Character then tableInsert(GlobalRayFilter, LocalPlayer.Character) end
tableInsert(GlobalRayFilter, targetChar)

GlobalRayParams.FilterDescendantsInstances = GlobalRayFilter
local result = workspace:Raycast(camPos, direction, GlobalRayParams)
return result == nil


end

local SMART_PRIORITY = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

local function GetAimPart(charData, aimMode)
local char = charData.Char
if aimMode == "Smart" then
for _, partName in ipairs(SMART_PRIORITY) do
local part = char:FindFirstChild(partName)
if part and IsVisible(part, char) then return part, true end
end
return charData.HRP, false
elseif aimMode == "Chaos" then
return char:FindFirstChild(chaosCurrentPart) or charData.HRP, true
elseif aimMode == "Head" then return charData.Head, true
elseif aimMode == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), true
elseif aimMode == "Limbs" then
local la = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
local ra = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
return (la and ra) and (mathRandom() < 0.5 and la or ra) or (la or ra), true
else
return charData.HRP, true
end
end

-- STREAMING_CHUNK:Deploying optimized C++ bridge for array sorting...
local function CustomSort(pool, count, sortByDistance)
for i = 2, count do
local key = pool[i]
local j = i - 1
if sortByDistance then
while j > 0 and pool[j].distToPlayer > key.distToPlayer do
pool[j + 1] = pool[j]; j = j - 1
end
else
while j > 0 and pool[j].distToMouse > key.distToMouse do
pool[j + 1] = pool[j]; j = j - 1
end
end
pool[j + 1] = key
end
end

local function GetCharData(player)
local cData = CharCache[player]
local char = player.Character
if not char then
CharCache[player] = nil
return nil
end
if not cData or cData.Char ~= char or not cData.HRP or not cData.HRP.Parent then
local hrp = char:FindFirstChild("HumanoidRootPart")
local head = char:FindFirstChild("Head")
local hum = char:FindFirstChildOfClass("Humanoid")
if hrp and head and hum then
cData = { Char = char, HRP = hrp, Head = head, Hum = hum }
CharCache[player] = cData
else
CharCache[player] = nil
return nil
end
end
return cData
end

local function GetClosestPlayer(fovSet, aimSet, refPos)
local fovSq = fovSet.Radius * fovSet.Radius
local myCharData = GetCharData(LocalPlayer)
local myRootPos = myCharData and myCharData.HRP and myCharData.HRP.Position
local candCount = 0

for _, player in ipairs(PlayerCache) do
    local cData = GetCharData(player)
    if not cData or (cData.Hum.Health <= 0) then continue end
    if aimSet.TeamCheck and IsTeammateCached(player) then continue end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(cData.HRP.Position)
    if not onScreen then continue end

    local dx, dy = refPos.X - screenPos.X, refPos.Y - screenPos.Y
    local distToMouseSq = dx*dx + dy*dy

    if distToMouseSq <= fovSq then 
        local distToPlayer = myRootPos and (myRootPos - cData.HRP.Position).Magnitude or math.huge
        candCount = candCount + 1
        if not CandidatePool[candCount] then CandidatePool[candCount] = {} end
        
        local cand = CandidatePool[candCount]
        cand.player = player
        cand.cData = cData
        cand.distToMouse = distToMouseSq
        cand.distToPlayer = distToPlayer
    end
end

if candCount == 0 then return nil end
CustomSort(CandidatePool, candCount, aimSet.TargetPriority == "Distance")

local wallCheck, aimMode = aimSet.WallCheck, aimSet.AimMode
local maxChecks = mathMin(candCount, 3) 
for i = 1, maxChecks do
    local candidate = CandidatePool[i]
    if not wallCheck then return candidate.player end
    local part, visible = GetAimPart(candidate.cData, aimMode)
    if part and visible then return candidate.player end
end
return nil


end

-- STREAMING_CHUNK:Preparing skeleton mapping arrays for rig detection...
-- ============================================================
--  ESP LIFECYCLE & CACHE REGISTRATION
-- ============================================================
local R15_BONES = {
{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"LowerTorso", "LeftUpperLeg"},
{"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
{"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}, {"UpperTorso", "LeftUpperArm"},
{"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
{"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}
}

local R6_BONES = {
{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
{"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function CreateESP(player)
local esp = {
Box = SafeDrawingNew("Square"), BoxOutline = SafeDrawingNew("Square"), BoxFill = SafeDrawingNew("Square"),
Name = SafeDrawingNew("Text"), Username = SafeDrawingNew("Text"), Distance = SafeDrawingNew("Text"), Health = SafeDrawingNew("Text"), Weapon = SafeDrawingNew("Text"),
BarBG = SafeDrawingNew("Square"), BarFG = SafeDrawingNew("Square"),
ArrowL1 = SafeDrawingNew("Line"), ArrowL2 = SafeDrawingNew("Line"), ArrowL3 = SafeDrawingNew("Line"), ArrowL4 = SafeDrawingNew("Line"),
Highlight = Instance.new("Highlight"), SkeletonLines = {}, SnapLine = nil,
_isVisible = false, _lastVisible = false, _staggerSlot = mathRandom(0, STAGGER_MOD - 1),
_trackedHP = 100
}

esp.Box.Thickness = 1.5; esp.BoxOutline.Thickness = 3.5; esp.BoxFill.Thickness = 1
esp.Box.Filled = false; esp.BoxOutline.Filled = false; esp.BoxFill.Filled = true
esp.BoxOutline.Transparency = 0.7; esp.BoxOutline.Color = Color3RGB(0, 0, 0)

for _, txt in ipairs({esp.Name, esp.Username, esp.Distance, esp.Health, esp.Weapon}) do
    txt.Center = true; txt.Outline = true; txt.OutlineColor = Color3RGB(0,0,0)
end
esp.BarBG.Filled = true; esp.BarBG.Color = Color3RGB(15, 15, 15); esp.BarFG.Filled = true

for i = 1, 14 do
    local line = SafeDrawingNew("Line")
    line.Thickness = 1.5; tableInsert(esp.SkeletonLines, line)
end

esp.Highlight.Parent = ChamsFolder; esp.Highlight.Enabled = false
ESPObjects[player] = esp


end

local function HideESP(esp)
if not esp._lastVisible then return end
esp.Box.Visible = false; esp.BoxOutline.Visible = false; esp.BoxFill.Visible = false
esp.Name.Visible = false; esp.Username.Visible = false; esp.Distance.Visible = false; esp.Health.Visible = false; esp.Weapon.Visible = false
esp.BarBG.Visible = false; esp.BarFG.Visible = false; esp.ArrowL1.Visible = false; esp.ArrowL2.Visible = false; esp.ArrowL3.Visible = false; esp.ArrowL4.Visible = false
esp.Highlight.Enabled = false
if esp.SnapLine then esp.SnapLine.Visible = false end
for _, line in ipairs(esp.SkeletonLines) do line.Visible = false end
esp._lastVisible = false
end

-- STREAMING_CHUNK:Initializing event hooks and garbage cleanup routines...
local function RegisterPlayer(player)
if player == LocalPlayer then return end
tableInsert(PlayerCache, player)
CreateESP(player)
tableInsert(KaimConnections, player:GetPropertyChangedSignal("Team"):Connect(function() TeamCache[player] = nil end))
end

task.spawn(function()
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
RegisterPlayer(p)
task.wait()
end
end
end)

tableInsert(KaimConnections, Players.PlayerAdded:Connect(RegisterPlayer))
tableInsert(KaimConnections, Players.PlayerRemoving:Connect(function(player)
for i, p in ipairs(PlayerCache) do if p == player then tableRemove(PlayerCache, i); break end end
local esp = ESPObjects[player]
if esp then
pcall(function()
esp.Box:Remove(); esp.BoxOutline:Remove(); esp.BoxFill:Remove()
esp.Name:Remove(); esp.Username:Remove(); esp.Distance:Remove(); esp.Health:Remove(); esp.Weapon:Remove()
esp.BarBG:Remove(); esp.BarFG:Remove(); esp.ArrowL1:Remove(); esp.ArrowL2:Remove(); esp.ArrowL3:Remove(); esp.ArrowL4:Remove()
if esp.SnapLine then esp.SnapLine:Remove() end
for _, line in ipairs(esp.SkeletonLines) do line:Remove() end
esp.Highlight:Destroy()
end)
end
ESPObjects[player] = nil; CharCache[player] = nil; TeamCache[player] = nil
if TracerLineCache[player] then TracerLineCache[player]:Remove(); TracerLineCache[player] = nil end
if LookTracerCache[player] then LookTracerCache[player]:Remove(); LookTracerCache[player] = nil end
end))

-- STREAMING_CHUNK:Rendering detection matrices and FOV bounds...
-- ============================================================
--  CORE UPDATE MODULES
-- ============================================================
local function UpdateFOVAndCrosshair(centerPoint, fovSet, crossSet)
local fovPos = fovSet.FollowCursor and UserInputService:GetMouseLocation() or centerPoint
local pulseOffset = fovSet.Pulse and (mathSin(osClock() * 4) * 5) or 0
local rad = mathMax(1, fovSet.Radius + pulseOffset)

UpdateDraw(FOVRing, {Position = fovPos, Radius = rad, Color = fovSet.Color, Transparency = fovSet.Transparency, Visible = fovSet.Visible})
local fillVis = fovSet.Visible and fovSet.Filled
UpdateDraw(FOVFill, {Position = fovPos, Radius = rad, Color = fovSet.FilledColor, Transparency = fovSet.FilledTransp, Visible = fillVis})

if crossSet.Enabled then
    local cx, cy = centerPoint.X, centerPoint.Y
    local s, g = crossSet.Size, crossSet.Gap
    
    for _, line in ipairs({CrosshairL, CrosshairR, CrosshairT, CrosshairB}) do
        UpdateDraw(line, {Visible = true, Color = crossSet.Color, Thickness = crossSet.Thickness})
    end
    
    UpdateDraw(CrosshairL, {From = Vector2New(cx - g, cy), To = Vector2New(cx - g - s, cy)})
    UpdateDraw(CrosshairR, {From = Vector2New(cx + g, cy), To = Vector2New(cx + g + s, cy)})
    UpdateDraw(CrosshairT, {From = Vector2New(cx, cy - g), To = Vector2New(cx, cy - g - s)})
    UpdateDraw(CrosshairB, {From = Vector2New(cx, cy + g), To = Vector2New(cx, cy + g + s)})
    
    if crossSet.ShowDot then
        UpdateDraw(CrosshairDot, {Visible = true, Radius = crossSet.DotSize, Color = crossSet.Color, Position = Vector2New(cx, cy)})
    else
        if CrosshairDot.Visible then CrosshairDot.Visible = false end
    end
else
    if CrosshairL.Visible then
        CrosshairL.Visible = false; CrosshairR.Visible = false; CrosshairT.Visible = false; CrosshairB.Visible = false; CrosshairDot.Visible = false
    end
end
return fovPos


end

-- STREAMING_CHUNK:Activating hardware-level triggerbot verification...
local function UpdateTriggerbot(deltaTime, tbSet, fovSet)
if not tbSet.Enabled or not VirtualInput then return end
triggerbotTimer = triggerbotTimer - deltaTime
if triggerbotTimer > 0 then return end
if mathRandom(1, 100) > tbSet.HitChance then return end

local cx, cy = Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5
local originPos, direction

-- Precision Triggerbot Projection (Native Mouse Sync)
if fovSet.FollowCursor then
    local mousePos = UserInputService:GetMouseLocation()
    cx, cy = mousePos.X, mousePos.Y
    local unitRay = Camera:ViewportPointToRay(cx, cy)
    originPos = unitRay.Origin
    direction = unitRay.Direction * 1000
else
    originPos = Camera.CFrame.Position
    direction = Camera.CFrame.LookVector * 1000
end

table.clear(GlobalRayFilter)
tableInsert(GlobalRayFilter, Camera)
if LocalPlayer.Character then tableInsert(GlobalRayFilter, LocalPlayer.Character) end
GlobalRayParams.FilterDescendantsInstances = GlobalRayFilter

local result = workspace:Raycast(originPos, direction, GlobalRayParams)
if result and result.Instance then
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChild("Humanoid") then
        local targetPlayer = Players:GetPlayerFromCharacter(model)
        if targetPlayer and targetPlayer ~= LocalPlayer then
            if tbSet.TeamCheck and IsTeammateCached(targetPlayer) then return end
            task.spawn(function()
                pcall(function()
                    VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                end)
            end)
            triggerbotTimer = tbSet.Delay
        end
    end
end


end

-- STREAMING_CHUNK:Formulating aimbot predictions and dynamic interpolation...
local function UpdateAimlock(camPos, screenWidth, screenHeight, deltaTime, aimSet, avoidSet, visSet, fovSet, fovPos)
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
    if chaosTimer <= 0 then chaosTimer = CHAOS_INTERVAL; chaosCurrentPart = PickNextChaosPart() end
end

local showHUD = false

if aimSet.Enabled and aimSet.IsAiming and not aimSet.PeriodicDisable then
    if mathRandom(1, 100) > aimSet.HitChance then
        aimSet.CurrentTarget = nil
    else
        local curTar = aimSet.CurrentTarget
        local curCData = curTar and GetCharData(curTar)
        if not curCData or curCData.Hum.Health <= 0 then
            local now = osClock()
            if now - aimSet._lastTargetSearch > 0.06 then 
                aimSet.CurrentTarget = GetClosestPlayer(fovSet, aimSet, fovPos)
                aimSet._lastTargetSearch = now
            end
        end
    end

    local target = aimSet.CurrentTarget
    local cData = target and GetCharData(target)

    if cData then
        local targetPart, lockIsVisible = GetAimPart(cData, aimSet.AimMode)
        
        if targetPart then
            local aimPos = targetPart.Position
            if aimSet.PredictionEnabled then
                local velocity = targetPart.AssemblyLinearVelocity
                if velocity.Magnitude > 300 then velocity = velocity.Unit * 300 end
                
                -- Dynamic Prediction: Scales based on distance
                local predictionTime = aimSet.Prediction
                if aimSet.DynamicPrediction then
                    local dist = (camPos - targetPart.Position).Magnitude
                    predictionTime = predictionTime + (dist / 1000) * 0.05
                end
                
                aimPos = aimPos + (velocity * aimSet.StrafePrediction * predictionTime)
            end
            
            aimPos = aimPos + Vector3New(aimSet.OffsetX, aimSet.OffsetY, aimSet.OffsetZ)

            if aimSet.PerlinNoise then
                local timeTick = osClock() * aimSet.NoiseSpeed
                local noiseX = mathNoise(timeTick, 0, 0) * aimSet.NoiseAmount
                local noiseY = mathNoise(0, timeTick, 0) * aimSet.NoiseAmount
                local noiseZ = mathNoise(0, 0, timeTick) * aimSet.NoiseAmount
                aimPos = aimPos + Vector3New(noiseX, noiseY, noiseZ)
            end

            local targetCFrame = CFrameNew(camPos, aimPos)
            if aimSet.SmoothAiming then
                local smoothFactor = aimSet.SmoothSpeed
                if aimSet.DynamicSmoothing then
                    local screenAimPos, onScreen = Camera:WorldToViewportPoint(aimPos)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local distToCrosshair = (Vector2New(screenAimPos.X, screenAimPos.Y) - mousePos).Magnitude
                        smoothFactor = smoothFactor * mathClamp(distToCrosshair / 200, 0.1, 1.0)
                    end
                end
                if smoothFactor < 1 then smoothFactor = 1 - (1 - smoothFactor) ^ (deltaTime * 60) end
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
            else
                Camera.CFrame = targetCFrame
            end

            if visSet.TargetUI then
                showHUD = true
                local scale = visSet.TargetUIScale
                local style = visSet.TargetUIStyle
                local accentColor = lockIsVisible and Color3RGB(255, 255, 255) or Color3RGB(255, 50, 50)
                
                local actualHP = cData.Hum.Health or 0
                thudLerpedHP = thudLerpedHP + (actualHP - thudLerpedHP) * (deltaTime * 10)
                if thudLerpedHP ~= thudLerpedHP then thudLerpedHP = 0 end 
                local hpPct = mathClamp(thudLerpedHP / (cData.Hum.MaxHealth or 100), 0, 1)

                local distInt = 0
                local myCData = GetCharData(LocalPlayer)
                if myCData and myCData.HRP then distInt = mathFloor((myCData.HRP.Position - cData.HRP.Position).Magnitude) end
                
                local newThudString = "HP: " .. mathFloor(actualHP) .. "  |  Dist: " .. distInt .. "m"
                if aimSet.AimMode == "Chaos" then newThudString = newThudString .. "  |  ⚡ " .. chaosCurrentPart end
                if thudLastTextCache ~= newThudString then thudLastTextCache = newThudString end

                thudAlpha = mathClamp(thudAlpha + (deltaTime * 7), 0, 1)
                local easeAlpha = 1 - (1 - thudAlpha) ^ 4
                local ySlideOffset = (1 - easeAlpha) * 35

                -- Default Hide All
                UpdateDraw(THUD.Shadow, {Visible = false}); UpdateDraw(THUD.Outline, {Visible = false}); UpdateDraw(THUD.BG, {Visible = false}); UpdateDraw(THUD.Accent2, {Visible = false})
                UpdateDraw(THUD.BarBG, {Visible = false}); UpdateDraw(THUD.BarFG, {Visible = false})
                UpdateDraw(THUD.Name, {Outline = true, Center = false}); UpdateDraw(THUD.Data, {Outline = true, Center = false})

                if style == "Valorant" then
                    local boxW = mathFloor(280 * scale)
                    local boxH = mathFloor(45 * scale)
                    local hudX = (screenWidth / 2) - (boxW / 2)
                    local hudY = mathFloor(screenHeight * 0.08) - ySlideOffset 
                    
                    UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.85 * easeAlpha, Color = Color3RGB(17, 17, 17)})
                    UpdateDraw(THUD.Accent, {Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY + boxH), Color = accentColor, Transparency = 1 * easeAlpha})
                    
                    UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(17 * scale)), Position = Vector2New(hudX + mathFloor(12*scale), hudY + mathFloor(6*scale)), Text = target.DisplayName, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(12 * scale)), Position = Vector2New(hudX + mathFloor(12*scale), hudY + mathFloor(24*scale)), Text = thudLastTextCache, Transparency = 1 * easeAlpha})
                    
                    local barW = boxW; local barH = mathMax(1, mathFloor(3 * scale)); local barY = hudY + boxH + mathFloor(2 * scale)
                    UpdateDraw(THUD.BarBG, {Visible = true, Size = Vector2New(barW, barH), Position = Vector2New(hudX, barY), Transparency = 1 * easeAlpha, Color = Color3RGB(0,0,0)})
                    UpdateDraw(THUD.BarFG, {Visible = true, Size = Vector2New(barW * hpPct, barH), Position = Vector2New(hudX, barY), Color = GetHealthColor(hpPct), Transparency = 1 * easeAlpha})

                elseif style == "Standard" then
                    local calculatedWidth = mathMax(200, 40 + stringLen(target.DisplayName) * 9)
                    local boxW = mathFloor(calculatedWidth * scale); local boxH = mathFloor(56 * scale)
                    local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(140 * scale)) + ySlideOffset
                    
                    UpdateDraw(THUD.Shadow, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX + 3, hudY + 3), Transparency = 0.5 * easeAlpha})
                    UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.85 * easeAlpha, Color = Color3RGB(12, 12, 14)})
                    UpdateDraw(THUD.Outline, {Visible = true, Size = Vector2New(boxW + 2, boxH + 2), Position = Vector2New(hudX - 1, hudY - 1), Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Accent, {Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                    
                    UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(16 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(8 * scale)), Text = target.DisplayName, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(13 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(28 * scale)), Text = thudLastTextCache, Transparency = 1 * easeAlpha})
                    
                    local barW = boxW - mathFloor(20 * scale); local barH = mathMax(1, mathFloor(3 * scale)); local barY = hudY + mathFloor(46 * scale)
                    UpdateDraw(THUD.BarBG, {Visible = true, Size = Vector2New(barW, barH), Position = Vector2New(hudX + mathFloor(10 * scale), barY), Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.BarFG, {Visible = true, Size = Vector2New(barW * hpPct, barH), Position = Vector2New(hudX + mathFloor(10 * scale), barY), Color = GetHealthColor(hpPct), Transparency = 1 * easeAlpha})
                    
                elseif style == "Cyber" then
                    local calculatedWidth = mathMax(220, 50 + stringLen(target.DisplayName) * 9)
                    local boxW = mathFloor(calculatedWidth * scale); local boxH = mathFloor(48 * scale)
                    local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(150 * scale)) + ySlideOffset
                    
                    UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.7 * easeAlpha, Color = Color3RGB(12, 12, 14)})
                    UpdateDraw(THUD.Accent, {Size = Vector2New(mathMax(2, mathFloor(6 * scale)), boxH), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Accent2, {Visible = true, Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 0.5 * easeAlpha})
                    
                    UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(17 * scale)), Position = Vector2New(hudX + mathFloor(16 * scale), hudY + mathFloor(8 * scale)), Text = "[" .. target.DisplayName .. "]", Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(11 * scale)), Position = Vector2New(hudX + mathFloor(16 * scale), hudY + mathFloor(28 * scale)), Text = thudLastTextCache, Transparency = 1 * easeAlpha})

                elseif style == "Minimal" then
                    local hudX = (screenWidth / 2) - mathFloor(100 * scale)
                    local hudY = (screenHeight - mathFloor(130 * scale)) + ySlideOffset
                    
                    UpdateDraw(THUD.Accent, {Size = Vector2New(mathMax(1, mathFloor(3 * scale)), mathFloor(36 * scale)), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(16 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY), Text = target.DisplayName, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(13 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(20 * scale)), Text = thudLastTextCache, Transparency = 1 * easeAlpha})
                
                elseif style == "Tech" then
                    local calculatedWidth = mathMax(200, 40 + stringLen(target.DisplayName) * 9)
                    local boxW = mathFloor(calculatedWidth * scale); local boxH = mathFloor(56 * scale)
                    local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(140 * scale)) + ySlideOffset
                    
                    UpdateDraw(THUD.Outline, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.5 * easeAlpha, Color = Color3RGB(12, 12, 14)})
                    UpdateDraw(THUD.Accent, {Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                    
                    UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(16 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(8 * scale)), Text = target.DisplayName, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(13 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(28 * scale)), Text = thudLastTextCache, Transparency = 1 * easeAlpha})
                
                elseif style == "Apex" then
                    local boxW = mathFloor(220 * scale); local boxH = mathFloor(45 * scale)
                    local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(120 * scale)) + ySlideOffset
                    
                    UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.6 * easeAlpha, Color = Color3RGB(12, 12, 14)})
                    UpdateDraw(THUD.Accent, {Size = Vector2New(mathMax(1, mathFloor(4 * scale)), boxH), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                    
                    UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(15 * scale)), Position = Vector2New(hudX + mathFloor(12 * scale), hudY + mathFloor(6 * scale)), Text = target.DisplayName, Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(11 * scale)), Position = Vector2New(hudX + mathFloor(12 * scale), hudY + mathFloor(24 * scale)), Text = thudLastTextCache, Transparency = 1 * easeAlpha})
                    
                    local barW = boxW; local barH = mathMax(1, mathFloor(3 * scale)); local barY = hudY + boxH
                    UpdateDraw(THUD.BarBG, {Visible = true, Size = Vector2New(barW, barH), Position = Vector2New(hudX, barY), Transparency = 1 * easeAlpha})
                    UpdateDraw(THUD.BarFG, {Visible = true, Size = Vector2New(barW * hpPct, barH), Position = Vector2New(hudX, barY), Color = GetHealthColor(hpPct), Transparency = 1 * easeAlpha})
                end
            end
        else
            aimSet.CurrentTarget = nil
        end
    end
else
    aimSet.CurrentTarget = nil
end

if not showHUD then
    thudAlpha = mathClamp(thudAlpha - (deltaTime * 8), 0, 1)
    if thudAlpha <= 0 then
        UpdateDraw(THUD.Shadow, {Visible = false}); UpdateDraw(THUD.BG, {Visible = false}); UpdateDraw(THUD.Outline, {Visible = false})
        UpdateDraw(THUD.Accent, {Visible = false}); UpdateDraw(THUD.Accent2, {Visible = false})
        UpdateDraw(THUD.Name, {Visible = false}); UpdateDraw(THUD.Data, {Visible = false})
        UpdateDraw(THUD.BarBG, {Visible = false}); UpdateDraw(THUD.BarFG, {Visible = false})
    else
        local easeAlpha = 1 - (1 - thudAlpha) ^ 4
        UpdateDraw(THUD.Shadow, {Transparency = 0.5 * easeAlpha}); UpdateDraw(THUD.BG, {Transparency = 0.85 * easeAlpha})
        UpdateDraw(THUD.Outline, {Transparency = 1 * easeAlpha}); UpdateDraw(THUD.Accent, {Transparency = 1 * easeAlpha})
        UpdateDraw(THUD.Name, {Transparency = 1 * easeAlpha}); UpdateDraw(THUD.Data, {Transparency = 1 * easeAlpha})
        UpdateDraw(THUD.BarBG, {Transparency = 1 * easeAlpha}); UpdateDraw(THUD.BarFG, {Transparency = 1 * easeAlpha})
    end
else
    UpdateDraw(THUD.Accent, {Visible = true}); UpdateDraw(THUD.Name, {Visible = true}); UpdateDraw(THUD.Data, {Visible = true})
end


end

-- STREAMING_CHUNK:Running precise ESP stacking logic and bone mapping...
local function UpdatePlayerMods(playerSet)
if playerSet.CameraFOVEnabled and Camera.FieldOfView ~= playerSet.CameraFOV then Camera.FieldOfView = playerSet.CameraFOV end
local cData = GetCharData(LocalPlayer)
if cData then
if playerSet.WalkSpeedEnabled and cData.Hum.WalkSpeed ~= playerSet.WalkSpeed then cData.Hum.WalkSpeed = playerSet.WalkSpeed end
if playerSet.JumpPowerEnabled and cData.Hum.JumpPower ~= playerSet.JumpPower then cData.Hum.JumpPower = playerSet.JumpPower end
end
end

local function UpdateESP(camPos, screenWidth, screenHeight, visSet)
-- Cache settings localized to eliminate table index lookup overhead per loop iteration
local espEnabled = visSet.ESPEnabled
local chamsEnabled = visSet.ChamsEnabled
local maxDist = visSet.MaxESPDistance
local teamCheck = visSet.TeamCheck
local showTM = visSet.ShowTeammates
local useVisColor = visSet.UseVisColors
local dmgNums = visSet.DamageNumbers
local arrows = visSet.OffScreenArrows
local tracers = visSet.TracerLines
local lookTrc = visSet.LookTracers
local skelESP = visSet.SkeletonESP
local boxes = visSet.ESPBoxes

local center = Vector2New(screenWidth * 0.5, screenHeight * 0.5)
local currentTickSlot = FRAME_COUNT % STAGGER_MOD
local tracerOriginY = (visSet.TracerOrigin == "Bottom") and screenHeight or (visSet.TracerOrigin == "Top") and 0 or (screenHeight * 0.5)
local tracerStartPos = Vector2New(screenWidth * 0.5, tracerOriginY)

for _, player in ipairs(PlayerCache) do
    local esp = ESPObjects[player]
    if not esp then continue end

    local cData = GetCharData(player)
    if not cData or not cData.HRP.Parent or cData.Hum.Health <= 0 then
        HideESP(esp)
        if TracerLineCache[player] and TracerLineCache[player].Visible then TracerLineCache[player].Visible = false end
        if LookTracerCache[player] and LookTracerCache[player].Visible then LookTracerCache[player].Visible = false end
        continue
    end
    
    local isTeammate = IsTeammateCached(player)
    if teamCheck and isTeammate and not showTM then
        HideESP(esp); continue
    end
    
    local dist = (cData.HRP.Position - camPos).Magnitude
    if dist > maxDist then 
        HideESP(esp); continue
    end

    local rootScreenPos, onScreen = Camera:WorldToViewportPoint(cData.HRP.Position)
    local depth = rootScreenPos.Z

    local needsVisRaycast = (espEnabled and useVisColor) or (chamsEnabled and visSet.ChamsUseVisColors)
    if needsVisRaycast then
        if esp._staggerSlot == currentTickSlot then esp._isVisible = IsVisible(cData.HRP, cData.Char) end
    else
        esp._isVisible = true 
    end
    
    esp._lastVisible = true

    if chamsEnabled then
        if esp.Highlight.Adornee ~= cData.Char then esp.Highlight.Adornee = cData.Char; esp.Highlight.Enabled = true end
        local fC = visSet.ChamsUseVisColors and (esp._isVisible and visSet.VisColor or visSet.HiddenColor) or visSet.ChamsFillColor
        local oC = visSet.ChamsOutlineColor
        local fT = visSet.ChamsFillTrans
        local oT = visSet.ChamsOutlineTrans
        if esp.Highlight.FillColor ~= fC then esp.Highlight.FillColor = fC end
        if esp.Highlight.OutlineColor ~= oC then esp.Highlight.OutlineColor = oC end
        if esp.Highlight.FillTransparency ~= fT then esp.Highlight.FillTransparency = fT end
        if esp.Highlight.OutlineTransparency ~= oT then esp.Highlight.OutlineTransparency = oT end
    else
        if esp.Highlight.Enabled then esp.Highlight.Enabled = false; esp.Highlight.Adornee = nil end
    end

    if cData.Hum.Health ~= esp._trackedHP then
        local diff = esp._trackedHP - cData.Hum.Health
        if diff > 0.5 and dmgNums then SpawnDamageNumber(diff, cData.Head.Position) end
        esp._trackedHP = cData.Hum.Health
    end

    if arrows and (not onScreen or depth <= 0) then
        local relativePos = Camera.CFrame:PointToObjectSpace(cData.HRP.Position)
        local angle = mathAtan2(relativePos.X, -relativePos.Z)
        local arrowCenter = center + Vector2New(mathSin(angle) * visSet.ArrowRadius, -mathCos(angle) * visSet.ArrowRadius)
        local size = visSet.ArrowSize
        
        local p1 = arrowCenter + Vector2New(mathSin(angle) * size, -mathCos(angle) * size)
        local p2 = arrowCenter + Vector2New(mathSin(angle - mathPi/4) * size*0.75, -mathCos(angle - mathPi/4) * size*0.75)
        local p3 = arrowCenter + Vector2New(mathSin(angle) * size*0.3, -mathCos(angle) * size*0.3)
        local p4 = arrowCenter + Vector2New(mathSin(angle + mathPi/4) * size*0.75, -mathCos(angle + mathPi/4) * size*0.75)

        UpdateDraw(esp.ArrowL1, {From = p1, To = p2, Color = visSet.ArrowColor, Visible = true})
        UpdateDraw(esp.ArrowL2, {From = p2, To = p3, Color = visSet.ArrowColor, Visible = true})
        UpdateDraw(esp.ArrowL3, {From = p3, To = p4, Color = visSet.ArrowColor, Visible = true})
        UpdateDraw(esp.ArrowL4, {From = p4, To = p1, Color = visSet.ArrowColor, Visible = true})
    else
        if esp.ArrowL1.Visible then
            UpdateDraw(esp.ArrowL1, {Visible = false}); UpdateDraw(esp.ArrowL2, {Visible = false}); UpdateDraw(esp.ArrowL3, {Visible = false}); UpdateDraw(esp.ArrowL4, {Visible = false})
        end
    end

    if tracers and depth > 0 then
        if not TracerLineCache[player] then TracerLineCache[player] = SafeDrawingNew("Line"); TracerLineCache[player].Thickness = 1.5 end
        UpdateDraw(TracerLineCache[player], {Color = visSet.TracerColor, From = tracerStartPos, To = Vector2New(rootScreenPos.X, rootScreenPos.Y), Visible = onScreen})
    elseif TracerLineCache[player] and TracerLineCache[player].Visible then
        TracerLineCache[player].Visible = false
    end

    if lookTrc and depth > 0 then
        if not LookTracerCache[player] then LookTracerCache[player] = SafeDrawingNew("Line"); LookTracerCache[player].Thickness = 1.5 end
        local lookPos3D = cData.Head.Position + (cData.Head.CFrame.LookVector * visSet.LookTracerLength)
        local headScreenPos = Camera:WorldToViewportPoint(cData.Head.Position)
        local lookScreenPos, lookOnScreen = Camera:WorldToViewportPoint(lookPos3D)
        if lookOnScreen then
            UpdateDraw(LookTracerCache[player], {From = Vector2New(headScreenPos.X, headScreenPos.Y), To = Vector2New(lookScreenPos.X, lookScreenPos.Y), Color = visSet.LookTracerColor, Visible = true})
        else
            if LookTracerCache[player].Visible then LookTracerCache[player].Visible = false end
        end
    elseif LookTracerCache[player] and LookTracerCache[player].Visible then
        LookTracerCache[player].Visible = false
    end
    
    -- Fully Restored & Optimized Skeleton ESP
    if skelESP and onScreen and depth > 0 and depth < (maxDist * 0.6) then 
        local isR15 = cData.Char:FindFirstChild("UpperTorso") ~= nil
        local boneMap = isR15 and R15_BONES or R6_BONES
        for i = 1, #boneMap do
            local line = esp.SkeletonLines[i]
            local part1 = cData.Char:FindFirstChild(boneMap[i][1])
            local part2 = cData.Char:FindFirstChild(boneMap[i][2])
            if part1 and part2 then
                local p1, on1 = Camera:WorldToViewportPoint(part1.Position)
                local p2, on2 = Camera:WorldToViewportPoint(part2.Position)
                if on1 and on2 then
                    UpdateDraw(line, {From = Vector2New(p1.X, p1.Y), To = Vector2New(p2.X, p2.Y), Color = visSet.SkeletonColor, Thickness = visSet.SkeletonThickness, Visible = true})
                else
                    if line.Visible then line.Visible = false end
                end
            else
                if line.Visible then line.Visible = false end
            end
        end
        for i = #boneMap + 1, 14 do
            if esp.SkeletonLines[i].Visible then esp.SkeletonLines[i].Visible = false end
        end
    else
        for _, line in ipairs(esp.SkeletonLines) do 
            if line.Visible then line.Visible = false end
        end
    end

    if not espEnabled or not onScreen or depth <= 0 then
        HideESP(esp); continue
    end

    local headCalcPos = cData.HRP.Position + VEC3_HEAD_OFFSET
    local legCalcPos = cData.HRP.Position - VEC3_LEG_OFFSET
    local headScreenPos = Camera:WorldToViewportPoint(headCalcPos)
    local legScreenPos = Camera:WorldToViewportPoint(legCalcPos)

    local boxHeight = mathAbs(headScreenPos.Y - legScreenPos.Y); local boxWidth = boxHeight * 0.6
    local xPosition = rootScreenPos.X - (boxWidth * 0.5); local yPosition = headScreenPos.Y
    
    local finalColor = (isTeammate and showTM) and visSet.TeammateColor or (useVisColor and (esp._isVisible and visSet.VisColor or visSet.HiddenColor) or visSet.VisColor)

    if boxes then
        UpdateDraw(esp.Box, {Visible = true, Size = Vector2New(boxWidth, boxHeight), Position = Vector2New(xPosition, yPosition), Color = finalColor})

        if visSet.ESPOutline then 
            UpdateDraw(esp.BoxOutline, {Visible = true, Size = Vector2New(boxWidth + 3, boxHeight + 3), Position = Vector2New(xPosition - 1.5, yPosition - 1.5)})
        else 
            if esp.BoxOutline.Visible then esp.BoxOutline.Visible = false end
        end

        if visSet.ESPBoxFill then 
            UpdateDraw(esp.BoxFill, {Visible = true, Size = Vector2New(boxWidth, boxHeight), Position = Vector2New(xPosition, yPosition), Color = finalColor, Transparency = visSet.ESPBoxFillTrans})
        else 
            if esp.BoxFill.Visible then esp.BoxFill.Visible = false end
        end
    else
        if esp.Box.Visible then esp.Box.Visible = false; esp.BoxOutline.Visible = false; esp.BoxFill.Visible = false end
    end

    local healthPercentage = mathClamp(cData.Hum.Health / (cData.Hum.MaxHealth or 100), 0, 1)

    if visSet.HealthBar then
        local fillHeight = mathMax(1, boxHeight * healthPercentage)
        UpdateDraw(esp.BarBG, {Visible = true, Size = Vector2New(4, boxHeight + 2), Position = Vector2New(xPosition - 7, yPosition - 1)})
        UpdateDraw(esp.BarFG, {Visible = true, Size = Vector2New(2, fillHeight), Position = Vector2New(xPosition - 6, yPosition + boxHeight - fillHeight), Color = GetHealthColor(healthPercentage)})
    else 
        if esp.BarBG.Visible then esp.BarBG.Visible = false; esp.BarFG.Visible = false end 
    end

    if esp.Name.Font ~= visSet.ESPFont then
        for _, txt in ipairs({esp.Name, esp.Username, esp.Distance, esp.Health, esp.Weapon}) do txt.Font = visSet.ESPFont end
    end
    
    -- ESP Stacking System
    local textYPositionTop = yPosition - visSet.ESPTextScale - 4
    local textYPositionBottom = yPosition + boxHeight + 4
    local nameColor = visSet.UseCustomNameColor and visSet.ESPNameColor or finalColor

    if visSet.ESPNames then
        if visSet.ESPNameStyle == "Display Name" or visSet.ESPNameStyle == "Both" then
            UpdateDraw(esp.Name, {Visible = true, Text = player.DisplayName, Position = Vector2New(rootScreenPos.X, textYPositionTop), Color = nameColor, Size = visSet.ESPTextScale})
            if visSet.ESPNameStyle == "Both" then textYPositionTop = textYPositionTop - (visSet.ESPTextScale - 2) end
        else 
            if esp.Name.Visible then esp.Name.Visible = false end 
        end
    else 
        if esp.Name.Visible then esp.Name.Visible = false; esp.Username.Visible = false end
    end

    if visSet.DistanceDisplay then
        local dSize = mathMax(10, visSet.ESPTextScale - 2)
        UpdateDraw(esp.Distance, {Visible = true, Text = mathFloor(dist) .. "m", Color = GetDistanceColor(mathFloor(dist)), Position = Vector2New(rootScreenPos.X, textYPositionBottom), Size = dSize})
        textYPositionBottom = textYPositionBottom + dSize + 2
    else 
        if esp.Distance.Visible then esp.Distance.Visible = false end
    end
    
    if visSet.HealthNumbers then
        local hSize = mathMax(10, visSet.ESPTextScale - 2)
        UpdateDraw(esp.Health, {Visible = true, Text = mathFloor(cData.Hum.Health) .. " HP", Color = GetHealthColor(healthPercentage), Position = Vector2New(rootScreenPos.X, textYPositionBottom), Size = hSize})
        textYPositionBottom = textYPositionBottom + hSize + 2
    else
        if esp.Health.Visible then esp.Health.Visible = false end
    end
    
    if visSet.WeaponESP then
        local tool = cData.Char:FindFirstChildOfClass("Tool")
        local wStr = tool and tool.Name or "None"
        local wSize = mathMax(10, visSet.ESPTextScale - 2)
        UpdateDraw(esp.Weapon, {Visible = true, Text = wStr, Color = Color3RGB(220, 220, 220), Position = Vector2New(rootScreenPos.X, textYPositionBottom), Size = wSize})
        textYPositionBottom = textYPositionBottom + wSize + 2
    else
        if esp.Weapon.Visible then esp.Weapon.Visible = false end
    end
end


end

-- STREAMING_CHUNK:Finalizing Master rendering cycle...
local function MasterRenderLoop(deltaTime)
local ok, err = pcall(function()
FRAME_COUNT = FRAME_COUNT + 1
Camera = workspace.CurrentCamera
if not Camera then return end

    local camPos = Camera.CFrame.Position
    local viewport = Camera.ViewportSize
    if viewport.X == 0 or viewport.Y == 0 then return end

    local screenWidth, screenHeight = viewport.X, viewport.Y
    local screenCenter = Vector2New(screenWidth * 0.5, screenHeight * 0.5)

    local fovPos = UpdateFOVAndCrosshair(screenCenter, Settings.FOV, Settings.Crosshair)
    UpdateAimlock(camPos, screenWidth, screenHeight, deltaTime, Settings.Aimlock, Settings.DetectionAvoidance, Settings.Visuals, Settings.FOV, fovPos)
    UpdateTriggerbot(deltaTime, Settings.Triggerbot, Settings.FOV)
    UpdatePlayerMods(Settings.Player)
    UpdateESP(camPos, screenWidth, screenHeight, Settings.Visuals)
    UpdateDamageNumbers(Settings.Visuals)
end)
if not ok then warn("KAIM Runtime Error: " .. tostring(err)) end


end

tableInsert(KaimConnections, RunService.RenderStepped:Connect(MasterRenderLoop))

-- STREAMING_CHUNK:Constructing the WindUI framework elements...
-- ============================================================
--  WINDUI MENU BUILDING
-- ============================================================
local Window = WindUI:CreateWindow({
Title       = "KAIM v6.0",
Author      = "by FRK (The Zenith Update)",
Folder      = "Kaim",
Size        = UDim2.fromOffset(680, 600),
Theme       = "KAIM Signature",
Resizable   = true,
})
Window:SetToggleKey(nil)

local Tabs = {
Home     = Window:Tab({ Title = "Dashboard", Icon = "home" }),
Combat   = Window:Tab({ Title = "Combat", Icon = "crosshair" }),
Visuals  = Window:Tab({ Title = "Visuals", Icon = "eye" }),
Player   = Window:Tab({ Title = "Local Player", Icon = "user" }),
Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}

-- [ DASHBOARD ]
local HomeWelcome = Tabs.Home:Section({ Title = "Welcome to KAIM v6.0", Box = true, Opened = true })
HomeWelcome:Paragraph({ Title = "The Zenith Update", Desc = "v6.0 represents absolute peak engineering. Triggerbot now features hyper-accurate mouse tracking, UI toggling uses native WindUI callbacks, and all memory leaks during Unloading have been completely eradicated.", Icon = "crown" })

-- [ COMBAT TAB ]
local AimCore = Tabs.Combat:Section({ Title = "Aim Assist Core", Box = true, Opened = true })
AimCore:Toggle({ Title = "Enable Aimlock", Flag = "AimlockEnabled", Value = false, Callback = function(v) Settings.Aimlock.Enabled = v end })
AimCore:Keybind({ Title = "Aimlock Key", Flag = "AimlockKeybind", Value = "RightClick", Callback = function(v) Settings.Aimlock.Keybind = v end })
AimCore:Dropdown({ Title = "Aim Mode", Flag = "AimlockAimMode", Values = { "Smart", "Chaos", "Head", "Torso", "Limbs", "HRP" }, Value = "Smart", Callback = function(v) Settings.Aimlock.AimMode = v end })
AimCore:Dropdown({ Title = "Target Priority", Flag = "AimlockPriority", Values = { "Crosshair", "Distance" }, Value = "Crosshair", Callback = function(v) Settings.Aimlock.TargetPriority = v end })

local TBotCore = Tabs.Combat:Section({ Title = "Triggerbot Settings", Box = true, Opened = false })
TBotCore:Toggle({ Title = "Enable Triggerbot", Flag = "TBEnabled", Value = false, Callback = function(v) Settings.Triggerbot.Enabled = v end })
TBotCore:Slider({ Title = "Trigger Delay", Flag = "TBDelay", Step = 0.01, Value = { Min = 0.01, Max = 0.5, Default = 0.05 }, Callback = function(v) Settings.Triggerbot.Delay = v end })

local AimAdvanced = Tabs.Combat:Section({ Title = "Aim Tuning (Prediction & Smooth)", Box = true, Opened = false })
AimAdvanced:Toggle({ Title = "Enable Prediction", Flag = "AimlockPredictionEnabled", Value = true, Callback = function(v) Settings.Aimlock.PredictionEnabled = v end })
AimAdvanced:Toggle({ Title = "Distance Scaling Prediction", Flag = "AimlockDynPred", Value = true, Callback = function(v) Settings.Aimlock.DynamicPrediction = v end })
AimAdvanced:Slider({ Title = "Base Prediction Strength", Flag = "AimlockPrediction", Step = 0.005, Value = { Min = 0, Max = 0.3, Default = 0.135 }, Callback = function(v) Settings.Aimlock.Prediction = v end })
AimAdvanced:Toggle({ Title = "Smooth Aiming", Flag = "AimlockSmooth", Value = false, Callback = function(v) Settings.Aimlock.SmoothAiming = v end })
AimAdvanced:Slider({ Title = "Smooth Speed", Flag = "AimlockSmoothSpeed", Step = 0.05, Value = { Min = 0.05, Max = 1.0, Default = 0.3 }, Callback = function(v) Settings.Aimlock.SmoothSpeed = v end })

-- [ VISUALS TAB ]
local ESPCore = Tabs.Visuals:Section({ Title = "Player Overlays", Box = true, Opened = true })
ESPCore:Toggle({ Title = "Enable ESP", Flag = "ESPEnabled", Value = false, Callback = function(v) Settings.Visuals.ESPEnabled = v end })
ESPCore:Toggle({ Title = "ESP Boxes", Flag = "ESPBoxes", Value = true, Callback = function(v) Settings.Visuals.ESPBoxes = v end })
ESPCore:Toggle({ Title = "Show Names", Flag = "ESPNames", Value = true, Callback = function(v) Settings.Visuals.ESPNames = v end })
ESPCore:Toggle({ Title = "Show Distance", Flag = "ESPDistDisplay", Value = false, Callback = function(v) Settings.Visuals.DistanceDisplay = v end })
ESPCore:Toggle({ Title = "Show Weapon", Flag = "ESPWeapon", Value = false, Callback = function(v) Settings.Visuals.WeaponESP = v end })

local ESPSkel = Tabs.Visuals:Section({ Title = "Skeletons & Lines", Box = true, Opened = false })
ESPSkel:Toggle({ Title = "Skeleton ESP", Flag = "SkeletonESP", Value = false, Callback = function(v) Settings.Visuals.SkeletonESP = v end })
ESPSkel:Colorpicker({ Title = "Skeleton Color", Flag = "SkeletonColor", Default = Color3RGB(255, 255, 255), Transparency = 0, Callback = function(v) Settings.Visuals.SkeletonColor = v end })
ESPSkel:Toggle({ Title = "Look Tracers", Flag = "LookTracers", Value = false, Callback = function(v) Settings.Visuals.LookTracers = v end })

local HitVisuals = Tabs.Visuals:Section({ Title = "Combat Effects", Box = true, Opened = true })
HitVisuals:Toggle({ Title = "Show Damage Numbers", Flag = "DamageNumbers", Value = false, Callback = function(v) Settings.Visuals.DamageNumbers = v end })
HitVisuals:Colorpicker({ Title = "Damage Number Color", Flag = "DamageColor", Default = Color3RGB(255, 255, 0), Transparency = 0, Callback = function(v) Settings.Visuals.DamageColor = v end })

local ESPChams = Tabs.Visuals:Section({ Title = "3D Chams", Box = true, Opened = false })
ESPChams:Toggle({ Title = "Enable Chams", Flag = "ChamsEnabled", Value = false, Callback = function(v) Settings.Visuals.ChamsEnabled = v end })
ESPChams:Toggle({ Title = "See Through Walls", Flag = "ChamsDepth", Value = true, Callback = function(v) Settings.Visuals.ChamsDepth = v end })

local HUDSection = Tabs.Visuals:Section({ Title = "Radar & Target HUD", Box = true, Opened = false })
HUDSection:Toggle({ Title = "Show Target HUD", Flag = "HUDEnabled", Value = true, Callback = function(v) Settings.Visuals.TargetUI = v end })
HUDSection:Dropdown({ Title = "HUD Style", Flag = "HUDStyle", Values = { "Valorant", "Standard", "Cyber", "Minimal", "Tech", "Apex" }, Value = "Valorant", Callback = function(v) Settings.Visuals.TargetUIStyle = v end })
HUDSection:Slider({ Title = "HUD Scale", Flag = "HUDScale", Step = 0.1, Value = { Min = 0.5, Max = 2.0, Default = 1.0 }, Callback = function(v) Settings.Visuals.TargetUIScale = v end })
HUDSection:Toggle({ Title = "Show FOV Circle", Flag = "FOVVisible", Value = true, Callback = function(v) Settings.FOV.Visible = v end })

-- [ LOCAL PLAYER ]
local MovementSec = Tabs.Player:Section({ Title = "Movement Control", Box = true, Opened = true })
MovementSec:Toggle({ Title = "Enable Walk Speed", Flag = "WalkSpeedEnabled", Value = false, Callback = function(v) Settings.Player.WalkSpeedEnabled = v end })
MovementSec:Slider({ Title = "Walk Speed", Flag = "WalkSpeed", Step = 1, Value = { Min = 5, Max = 100, Default = 16 }, Callback = function(v) Settings.Player.WalkSpeed = v end })

local NoclipSec = Tabs.Player:Section({ Title = "Physics", Box = true, Opened = true })
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
if entry.part and entry.part.Parent and entry.part.CanCollide then
entry.part.CanCollide = false
end
end
end)
tableInsert(KaimConnections, noclipConn)
else
for _, entry in ipairs(noclipCache) do
if entry.part and entry.part.Parent and entry.part.CanCollide ~= entry.original then
entry.part.CanCollide = entry.original
end
end
noclipCache = {}
end
end
tableInsert(KaimConnections, LocalPlayer.CharacterAdded:Connect(function(char)
if Settings.Player.NoclipEnabled then task.defer(function() BuildNoclipCache(char) end) end
end))

NoclipSec:Toggle({ Title = "Enable Noclip", Flag = "Noclip", Value = false, Callback = function(v) SetNoclip(v) end })
NoclipSec:Keybind({ Title = "Noclip Keybind", Flag = "NoclipKeybind", Value = "N", Callback = function(v)
Settings.Player.NoclipKeybind = v
pcall(function() cachedNoclipKC = Enum.KeyCode[v] end)
end })

-- [ SETTINGS ]
local UISection = Tabs.Settings:Section({ Title = "Menu Settings", Box = true, Opened = true })
UISection:Keybind({ Title = "Toggle UI Key", Flag = "UIToggleKey", Value = "K", Callback = function(v)
Settings.UI.ToggleKey = v
end })

local ConfigSection = Tabs.Settings:Section({ Title = "Config Manager", Box = true, Opened = true })
local ConfigManager = Window.ConfigManager
local ConfigName = "kaim_v4"

local ConfigNameInput = ConfigSection:Input({ Title = "Config Name", Icon = "file-cog", Callback = function(value) ConfigName = value end })
local AllConfigsDropdown = ConfigSection:Dropdown({
Title = "Saved Configs", Desc = "Select existing configs", Values = ConfigManager:AllConfigs(), Value = nil,
Callback = function(value) ConfigName = value; ConfigNameInput:Set(value) end
})

ConfigSection:Button({ Title = "Save Config", Justify = "Center", Callback = function()
Window.CurrentConfig = ConfigManager:Config(ConfigName)
if Window.CurrentConfig:Save() then WindUI:Notify({ Title = "Saved", Content = ConfigName .. ".json", Icon = "check" }) end
AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
end })

ConfigSection:Button({ Title = "Load Config", Justify = "Center", Callback = function()
Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
if Window.CurrentConfig:Load() then WindUI:Notify({ Title = "Loaded", Content = ConfigName .. ".json", Icon = "check" }) end
end })

local DangerSection = Tabs.Settings:Section({ Title = "Danger Zone", Box = true, Opened = true })
DangerSection:Button({
Title = "Unload KAIM",
Justify = "Center",
Callback = function()
for _, conn in ipairs(KaimConnections) do conn:Disconnect() end
for _, esp in pairs(ESPObjects) do
pcall(function()
esp.Box:Remove(); esp.BoxOutline:Remove(); esp.BoxFill:Remove()
esp.Name:Remove(); esp.Username:Remove(); esp.Distance:Remove(); esp.Health:Remove(); esp.Weapon:Remove()
esp.BarBG:Remove(); esp.BarFG:Remove(); esp.ArrowL1:Remove(); esp.ArrowL2:Remove(); esp.ArrowL3:Remove(); esp.ArrowL4:Remove()
if esp.SnapLine then esp.SnapLine:Remove() end
for _, line in ipairs(esp.SkeletonLines) do line:Remove() end
esp.Highlight:Destroy()
end)
end
ESPObjects = {}

    -- Deep Cleanup (Memory Leak Fixes)
    for _, line in pairs(TracerLineCache) do pcall(function() line:Remove() end) end
    TracerLineCache = {}
    for _, line in pairs(LookTracerCache) do pcall(function() line:Remove() end) end
    LookTracerCache = {}
    for _, dn in pairs(ActiveDamageNumbers) do pcall(function() dn.TextObj:Remove() end) end
    for _, dn in pairs(DamageObjPool) do pcall(function() dn.TextObj:Remove() end) end
    ActiveDamageNumbers = {}
    DamageObjPool = {}
    
    pcall(function() FOVRing:Remove(); FOVFill:Remove() end)
    pcall(function() CrosshairL:Remove(); CrosshairR:Remove(); CrosshairT:Remove(); CrosshairB:Remove(); CrosshairDot:Remove() end)
    pcall(function() ChamsFolder:Destroy() end)
    pcall(function() THUD.Shadow:Remove(); THUD.BG:Remove(); THUD.Outline:Remove(); THUD.Accent:Remove(); THUD.Accent2:Remove(); THUD.Name:Remove(); THUD.Data:Remove(); THUD.BarBG:Remove(); THUD.BarFG:Remove() end)
    Window:Destroy()
end


})

-- STREAMING_CHUNK:Finalizing local inputs and native UI toggles...
local noclipNotifyDebounce = false

tableInsert(KaimConnections, UserInputService.InputBegan:Connect(function(input, gpe)
if gpe then return end

-- Native WindUI Toggle Integration (Zero Wiggle / Hacky Finds)
local toggleKey = Settings.UI.ToggleKey
local ok, kc = pcall(function() return Enum.KeyCode[toggleKey] end)
if ok and kc and input.KeyCode == kc then
    pcall(function() Window:Toggle() end)
end

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
    local okAim, kcAim = pcall(function() return Enum.KeyCode[aimKey] end)
    if okAim and kcAim and input.KeyCode == kcAim then Settings.Aimlock.IsAiming = true end
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
WindUI:Notify({ Title = "KAIM v6.0 (The Zenith Update)", Content = "Press K to toggle UI", Duration = 5, Icon = "shield-check" })
