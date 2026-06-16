-- ============================================================
--  KAIM v7.8  |  WindUI Edition (Thread-Safe Injector)
--  Zero-Yield Injection, Safe GUI Parenting, Ultimate FPS
-- ============================================================

-- Wrap the entire execution in an asynchronous thread.
-- This prevents the executor's C++ bridge from locking/crashing if the script yields.
task.spawn(function()

-- Prevent double-execution crashes safely
local _env = (type(getgenv) == "function" and getgenv()) or _G
if _env.KAIM_LOADED then return end
_env.KAIM_LOADED = true

-- STREAMING_CHUNK: Safely initializing core runtime services...
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

-- XENO FIX 1: Strict single-assignment pcalls to prevent Access Violations
local VirtualInput
pcall(function() VirtualInput = game:GetService("VirtualInputManager") end)

local Camera = workspace.CurrentCamera

-- STREAMING_CHUNK: Securing injection container WITHOUT workspace fallback
-- ============================================================
--  WINDUI SECURE INITIALIZATION
-- ============================================================
-- Never use workspace as a GUI parent; it causes instant hard crashes.
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 9e9)
local SafeContainer = PlayerGui
pcall(function()
    local hui = gethui and gethui()
    if hui and typeof(hui) == "Instance" then SafeContainer = hui end
end)

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

-- STREAMING_CHUNK: Applying KAIM Signature styling palette...
-- ============================================================
--  KAIM SIGNATURE THEME
-- ============================================================
WindUI:AddTheme({
    Name = "KAIM Signature",
    Accent = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(8, 8, 8),
    BackgroundTransparency = 0,
    Outline = Color3.fromRGB(34, 34, 34),
    Text = Color3.fromRGB(234, 234, 234),
    Placeholder = Color3.fromRGB(102, 102, 102),
    Button = Color3.fromRGB(18, 18, 18),
    Icon = Color3.fromRGB(255, 255, 255),
    Hover = Color3.fromRGB(26, 26, 26),
    WindowBackground = Color3.fromRGB(6, 6, 6),
    WindowShadow = Color3.fromRGB(0, 0, 0),
    DialogBackground = Color3.fromRGB(8, 8, 8),
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromRGB(255, 255, 255),
    DialogContent = Color3.fromRGB(170, 170, 170),
    DialogIcon = Color3.fromRGB(255, 255, 255),
    WindowTopbarButtonIcon = Color3.fromRGB(136, 136, 136),
    WindowTopbarTitle = Color3.fromRGB(255, 255, 255),
    WindowTopbarAuthor = Color3.fromRGB(136, 136, 136),
    WindowTopbarIcon = Color3.fromRGB(255, 255, 255),
    TabBackground = Color3.fromRGB(12, 12, 12),
    TabTitle = Color3.fromRGB(255, 255, 255),
    TabIcon = Color3.fromRGB(255, 255, 255),
    ElementBackground = Color3.fromRGB(12, 12, 12),
    ElementTitle = Color3.fromRGB(255, 255, 255),
    ElementDesc = Color3.fromRGB(136, 136, 136),
    ElementIcon = Color3.fromRGB(255, 255, 255),
    PopupBackground = Color3.fromRGB(8, 8, 8),
    PopupBackgroundTransparency = 0,
    PopupTitle = Color3.fromRGB(255, 255, 255),
    PopupContent = Color3.fromRGB(170, 170, 170),
    PopupIcon = Color3.fromRGB(255, 255, 255),
    Toggle = Color3.fromRGB(21, 21, 21),
    ToggleBar = Color3.fromRGB(255, 255, 255),
    Checkbox = Color3.fromRGB(21, 21, 21),
    CheckboxIcon = Color3.fromRGB(0, 0, 0),
    Slider = Color3.fromRGB(21, 21, 21),
    SliderThumb = Color3.fromRGB(255, 255, 255),
})

-- STREAMING_CHUNK: Constructing Drawing API safety wrapper...
-- ============================================================
--  DRAWING API SAFE WRAPPER & CACHING
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
        if success and res then 
            pcall(function() res.Visible = false end)
            return res 
        end
    end
    local d = {}
    for k, v in pairs(DummyDrawing) do d[k] = v end
    return d
end

local function UpdateDraw(obj, props)
    for k, v in pairs(props) do
        if obj[k] ~= v then obj[k] = v end
    end
end

-- STREAMING_CHUNK: Localizing math and CFrame matrices for high performance...
-- ============================================================
--  FAST LOCALS, CONSTANTS & STATIC COLORS
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
local mathSqrt    = math.sqrt
local stringLen   = string.len
local stringUpper = string.upper
local osClock     = os.clock
local Vector2New  = Vector2.new
local Vector3New  = Vector3.new
local Color3RGB   = Color3.fromRGB
local CFrameNew   = CFrame.new
local tableInsert = table.insert

local VEC3_HEAD_OFFSET = Vector3New(0, 2.5, 0)
local VEC3_LEG_OFFSET  = Vector3New(0, 3, 0)
local PI_OVER_4        = 0.78539816339

-- Zero-GC Color Caching
local COLOR_BLACK      = Color3RGB(0, 0, 0)
local COLOR_WHITE      = Color3RGB(255, 255, 255)
local COLOR_RED        = Color3RGB(255, 50, 50)
local COLOR_HUD_BG     = Color3RGB(12, 12, 14)
local COLOR_HUD_OUT    = Color3RGB(34, 34, 40)
local COLOR_HUD_VAL    = Color3RGB(17, 17, 17)
local COLOR_HUD_BAR_BG = Color3RGB(20, 20, 25)

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

-- STREAMING_CHUNK: Generating central configuration dictionary...
-- ============================================================
--  DEFAULT SETTINGS v7.8
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
    Hitbox = {
        Enabled            = false,
        Part               = "Head",
        Size               = 5,
        Transparency       = 0.5,
    },
    FOV = {
        Visible        = true,
        FollowCursor   = true,
        Radius         = 150,
        Thickness      = 1.5,
        Color          = COLOR_WHITE,
        Transparency   = 0.8,
        Filled         = false,
        FilledColor    = COLOR_WHITE,
        FilledTransp   = 0.92,
        Pulse          = false,
    },
    Visuals = {
        ESPEnabled         = false,
        ESPBoxStyle        = "Corner",
        ESPBoxes           = true,
        ESPBoxFill         = false,
        ESPBoxFillTrans    = 0.2,
        DynamicThickness   = true,
        BaseThickness      = 1.5,
        ESPNames           = true,
        ESPNameStyle       = "Display Name",
        TextCase           = "UPPERCASE",
        ESPOutline         = true,
        ESPTextScale       = 14,
        ESPFont            = 2, 
        UseCustomNameColor = false,
        ESPNameColor       = COLOR_WHITE,
        ESPUsernameColor   = Color3RGB(180, 180, 200),
        TeamCheck          = true,
        ShowTeammates      = false,
        TeammateColor      = Color3RGB(0, 200, 255),
        UseVisColors       = true,
        VisColor           = Color3RGB(0, 255, 100), 
        HiddenColor        = COLOR_RED, 
        StaticBoxColor     = COLOR_WHITE,
        DistanceDisplay    = false,
        WeaponESP          = false,
        HealthNumbers      = false,
        HealthBar          = true,
        LookTracers        = false,
        LookTracerLength   = 5,
        LookTracerColor    = COLOR_WHITE,
        OffScreenArrows    = false,
        ArrowColor         = Color3RGB(255, 85, 0),
        ArrowRadius        = 120,
        ArrowSize          = 15,
        ChamsEnabled       = false,
        ChamsUseVisColors  = true,
        ChamsFillColor     = COLOR_WHITE,
        ChamsOutlineColor  = COLOR_WHITE,
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
    World = {
        Enabled        = false,
        Time           = 14,
        Brightness     = 2,
        GlobalShadows  = false,
        Ambient        = COLOR_WHITE,
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

-- STREAMING_CHUNK: Establishing non-volatile memory pools for objects...
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
local OriginalHitboxCache = {}
local OriginalLighting = {}

local DamageObjPool       = {}
local ActiveDamageNumbers = {}

local GlobalRayParams = RaycastParams.new()
GlobalRayParams.FilterType = Enum.RaycastFilterType.Exclude
GlobalRayParams.IgnoreWater = true
local TBotLastChar  = nil

local CandidatePool = {}
local ChaosPool = {}

local chaosTimer       = 0
local chaosCurrentPart = "Head"
local chaosLastPart    = ""
local CHAOS_INTERVAL   = 0.3
local CHAOS_PICK_LIST  = {"Head", "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}

local periodicDisableTimer = 0
local triggerbotTimer      = 0
local FRAME_COUNT_RS       = 0
local FRAME_COUNT_HB       = 0
local DYNAMIC_STAGGER      = 3 
local cachedNoclipKC       = Enum.KeyCode.N

local thudLerpedHP = 100
local thudAlpha    = 0 
local thudLastTextCache = ""
local thudLastNameCache = ""

-- Global Team Listener
tableInsert(KaimConnections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    table.clear(TeamCache)
end))

-- ============================================================
--  LIGHTING CACHE
-- ============================================================
local function CacheOriginalLighting()
    OriginalLighting = {
        Time = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient
    }
end
CacheOriginalLighting()

-- STREAMING_CHUNK: Rendering 2D and 3D geometric boundaries...
-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing = SafeDrawingNew("Circle"); FOVRing.Thickness = 1.5; FOVRing.Filled = false
local FOVFill = SafeDrawingNew("Circle"); FOVFill.Thickness = 1; FOVFill.Filled = true

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
    THUD.Shadow.Filled = true; THUD.Shadow.Color = COLOR_BLACK
    THUD.BG.Filled = true; THUD.BG.Color = COLOR_HUD_BG
    THUD.Outline.Filled = false; THUD.Outline.Color = COLOR_HUD_OUT
    THUD.Accent.Filled = true; THUD.Accent2.Filled = true
    THUD.Name.Outline = true; THUD.Name.Color = COLOR_WHITE; THUD.Name.Font = 2
    THUD.Data.Outline = true; THUD.Data.Color = Color3RGB(180, 180, 200); THUD.Data.Font = 2
    THUD.BarBG.Filled = true; THUD.BarBG.Color = COLOR_HUD_BAR_BG
    THUD.BarFG.Filled = true
end
InitTHUD()

-- STREAMING_CHUNK: Formulating logic for math helpers and physics engine...
-- ============================================================
--  UTILITY FUNCTIONS & PHYSICS ENGINE
-- ============================================================
local function FormatText(str, formatType)
    if formatType == "UPPERCASE" then return stringUpper(str) end
    return str
end

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
    local dn
    if #DamageObjPool > 0 then
        dn = DamageObjPool[#DamageObjPool]
        DamageObjPool[#DamageObjPool] = nil
    else
        dn = { TextObj = SafeDrawingNew("Text"), DamageStr = "", StartPos = Vector3New(), Velocity = Vector3New(), StartTime = 0 }
        dn.TextObj.Center = true
        dn.TextObj.Outline = true
        dn.TextObj.OutlineColor = COLOR_BLACK
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

local function UpdateDamageNumbers(visSet)
    if not visSet.DamageNumbers and #ActiveDamageNumbers == 0 then return end
    local currentTime = osClock()
    
    for i = #ActiveDamageNumbers, 1, -1 do
        local dn = ActiveDamageNumbers[i]
        local elapsed = currentTime - dn.StartTime
        
        if elapsed >= 1.5 or not visSet.DamageNumbers then
            dn.TextObj.Visible = false
            tableInsert(DamageObjPool, dn)
            ActiveDamageNumbers[i] = ActiveDamageNumbers[#ActiveDamageNumbers]
            ActiveDamageNumbers[#ActiveDamageNumbers] = nil
        else
            local vel = dn.Velocity
            local currentPos = dn.StartPos + Vector3New(vel.X * elapsed, (vel.Y * elapsed) - (12.5 * elapsed * elapsed), vel.Z * elapsed)
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
    table.clear(ChaosPool)
    for _, name in ipairs(CHAOS_PICK_LIST) do
        if name ~= chaosLastPart then tableInsert(ChaosPool, name) end
    end
    chaosLastPart = ChaosPool[mathRandom(#ChaosPool)]
    return chaosLastPart
end

local function IsTeammateCached(player)
    if TeamCache[player] == nil then TeamCache[player] = (player.Team ~= nil and player.Team == LocalPlayer.Team) end
    return TeamCache[player]
end

local function UpdateCharCache(player, char)
    if not char then CharCache[player] = nil; return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp and head and hum then
        local cData = CharCache[player]
        if not cData then
            cData = { RayParams = RaycastParams.new() }
            cData.RayParams.FilterType = Enum.RaycastFilterType.Exclude
            cData.RayParams.IgnoreWater = true
            CharCache[player] = cData
        end
        cData.Char = char
        cData.HRP = hrp
        cData.Head = head
        cData.Hum = hum
        cData._lastLPChar = nil
        cData._onScreen = false
    else
        CharCache[player] = nil
    end
end

local function IsVisible(targetPart, targetChar, cData)
    if not targetPart or not targetChar or not cData then return false end
    local camPos = Camera.CFrame.Position
    local direction = targetPart.Position - camPos
    
    local lpChar = LocalPlayer.Character
    if cData._lastLPChar ~= lpChar then
        local freshFilter = {targetChar}
        if lpChar then tableInsert(freshFilter, lpChar) end
        cData.RayParams.FilterDescendantsInstances = freshFilter
        cData._lastLPChar = lpChar
    end
    
    local result = workspace:Raycast(camPos, direction, cData.RayParams)
    return result == nil
end

local SMART_PRIORITY = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

local function GetAimPart(cData, aimMode)
    local char = cData.Char
    if aimMode == "Smart" then
        for _, partName in ipairs(SMART_PRIORITY) do
            local part = char:FindFirstChild(partName)
            if part and IsVisible(part, char, cData) then
                return part, true
            end
        end
        return cData.HRP, false
    elseif aimMode == "Chaos" then
        return char:FindFirstChild(chaosCurrentPart) or cData.HRP, true
    elseif aimMode == "Head" then return cData.Head, true
    elseif aimMode == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), true
    elseif aimMode == "Limbs" then
        local la = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
        local ra = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        return (la and ra) and (mathRandom() < 0.5 and la or ra) or (la or ra), true
    else
        return cData.HRP, true
    end
end

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

local function GetClosestPlayer(fovSet, aimSet, refPos)
    local fovSq = fovSet.Radius * fovSet.Radius
    local myCData = CharCache[LocalPlayer]
    local myRootPos = myCData and myCData.HRP and myCData.HRP.Position or Camera.CFrame.Position
    local candCount = 0

    for i = 1, #PlayerCache do
        local player = PlayerCache[i]
        local cData = CharCache[player]
        if not cData or (cData.Hum.Health <= 0) then continue end
        if aimSet.TeamCheck and IsTeammateCached(player) then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(cData.HRP.Position)
        if not onScreen then continue end

        local dx, dy = refPos.X - screenPos.X, refPos.Y - screenPos.Y
        local distToMouseSq = dx*dx + dy*dy

        if distToMouseSq <= fovSq then 
            local distToPlayerSq = math.huge
            local ox = myRootPos.X - cData.HRP.Position.X
            local oy = myRootPos.Y - cData.HRP.Position.Y
            local oz = myRootPos.Z - cData.HRP.Position.Z
            distToPlayerSq = ox*ox + oy*oy + oz*oz
            
            candCount = candCount + 1
            if not CandidatePool[candCount] then CandidatePool[candCount] = {} end
            
            local cand = CandidatePool[candCount]
            cand.player = player
            cand.cData = cData
            cand.distToMouse = distToMouseSq
            cand.distToPlayer = distToPlayerSq
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

-- STREAMING_CHUNK: Preparing ESP mapping arrays for rig detection...
-- ============================================================
--  ESP LIFECYCLE & CACHE REGISTRATION
-- ============================================================
local function CreateESP(player)
    local esp = {
        Box = SafeDrawingNew("Square"), BoxOutline = SafeDrawingNew("Square"), BoxFill = SafeDrawingNew("Square"),
        CornerLines = {},
        Name = SafeDrawingNew("Text"), Username = SafeDrawingNew("Text"), Distance = SafeDrawingNew("Text"), Health = SafeDrawingNew("Text"), Weapon = SafeDrawingNew("Text"),
        BarBG = SafeDrawingNew("Square"), BarFG = SafeDrawingNew("Square"), BarOutline = SafeDrawingNew("Square"),
        ArrowL1 = SafeDrawingNew("Line"), ArrowL2 = SafeDrawingNew("Line"), ArrowL3 = SafeDrawingNew("Line"), ArrowL4 = SafeDrawingNew("Line"),
        Highlight = nil, SnapLine = nil,
        _isVisible = false, _lastVisible = false,
        _staggerSlot = mathRandom(0, 2),
        _trackedHP = 100,
        
        -- String GC Cache
        _lastTextCase = "",
        _lastDistStrInt = -1,
        _lastHPStrInt = -1,
        _lastWepStr = "\0",
        _lastNameStr = "\0",
        _lastUnameStr = "\0"
    }

    esp.Box.Thickness = 1.5; esp.BoxOutline.Thickness = 3.5; esp.BoxFill.Thickness = 1
    esp.Box.Filled = false; esp.BoxOutline.Filled = false; esp.BoxFill.Filled = true
    esp.BoxOutline.Transparency = 0.7; esp.BoxOutline.Color = COLOR_BLACK

    for i = 1, 8 do
        esp.CornerLines[i] = { Main = SafeDrawingNew("Line"), Out = SafeDrawingNew("Line") }
        esp.CornerLines[i].Main.Thickness = 1.5
        esp.CornerLines[i].Out.Thickness = 3.5
        esp.CornerLines[i].Out.Color = COLOR_BLACK
        esp.CornerLines[i].Out.Transparency = 0.7
    end

    for _, txt in ipairs({esp.Name, esp.Username, esp.Distance, esp.Health, esp.Weapon}) do
        txt.Center = true; txt.Outline = true; txt.OutlineColor = COLOR_BLACK
    end
    
    esp.BarBG.Filled = true; esp.BarBG.Color = Color3RGB(15, 15, 15); esp.BarFG.Filled = true
    esp.BarOutline.Filled = false; esp.BarOutline.Color = COLOR_BLACK; esp.BarOutline.Thickness = 1
    
    ESPObjects[player] = esp
end

local function HideESP(esp)
    if not esp._lastVisible then return end
    esp.Box.Visible = false; esp.BoxOutline.Visible = false; esp.BoxFill.Visible = false
    for i = 1, 8 do esp.CornerLines[i].Main.Visible = false; esp.CornerLines[i].Out.Visible = false end
    
    esp.Name.Visible = false; esp.Username.Visible = false; esp.Distance.Visible = false; esp.Health.Visible = false; esp.Weapon.Visible = false
    esp.BarBG.Visible = false; esp.BarFG.Visible = false; esp.BarOutline.Visible = false
    esp.ArrowL1.Visible = false; esp.ArrowL2.Visible = false; esp.ArrowL3.Visible = false; esp.ArrowL4.Visible = false
    
    if esp.Highlight and esp.Highlight.Enabled then esp.Highlight.Enabled = false end
    if esp.SnapLine then esp.SnapLine.Visible = false end
    esp._lastVisible = false
end

local function RegisterPlayer(player)
    if player == LocalPlayer then return end
    tableInsert(PlayerCache, player)
    CreateESP(player)
    tableInsert(KaimConnections, player:GetPropertyChangedSignal("Team"):Connect(function() TeamCache[player] = nil end))
    tableInsert(KaimConnections, player.CharacterAdded:Connect(function(c) UpdateCharCache(player, c) end))
    tableInsert(KaimConnections, player.CharacterRemoving:Connect(function() CharCache[player] = nil end))
    if player.Character then UpdateCharCache(player, player.Character) end
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
    for i = 1, #PlayerCache do 
        if PlayerCache[i] == player then 
            PlayerCache[i] = PlayerCache[#PlayerCache]
            PlayerCache[#PlayerCache] = nil
            break 
        end 
    end
    local esp = ESPObjects[player]
    if esp then
        pcall(function()
            esp.Box:Remove(); esp.BoxOutline:Remove(); esp.BoxFill:Remove()
            for i = 1, 8 do esp.CornerLines[i].Main:Remove(); esp.CornerLines[i].Out:Remove() end
            esp.Name:Remove(); esp.Username:Remove(); esp.Distance:Remove(); esp.Health:Remove(); esp.Weapon:Remove()
            esp.BarBG:Remove(); esp.BarFG:Remove(); esp.BarOutline:Remove()
            esp.ArrowL1:Remove(); esp.ArrowL2:Remove(); esp.ArrowL3:Remove(); esp.ArrowL4:Remove()
            if esp.SnapLine then esp.SnapLine:Remove() end
            if esp.Highlight then esp.Highlight:Destroy() end
        end)
    end
    ESPObjects[player] = nil; CharCache[player] = nil; TeamCache[player] = nil
    if TracerLineCache[player] then TracerLineCache[player]:Remove(); TracerLineCache[player] = nil end
    if LookTracerCache[player] then LookTracerCache[player]:Remove(); LookTracerCache[player] = nil end
    if OriginalHitboxCache[player] then OriginalHitboxCache[player] = nil end
end))

tableInsert(KaimConnections, LocalPlayer.CharacterAdded:Connect(function(c) UpdateCharCache(LocalPlayer, c) end))
if LocalPlayer.Character then UpdateCharCache(LocalPlayer, LocalPlayer.Character) end

-- STREAMING_CHUNK: Rendering detection matrices and FOV bounds...
-- ============================================================
--  CORE UPDATE MODULES
-- ============================================================
local function UpdateFOV(centerPoint, fovSet)
    local fovPos = fovSet.FollowCursor and UserInputService:GetMouseLocation() or centerPoint
    local pulseOffset = fovSet.Pulse and (mathSin(osClock() * 4) * 5) or 0
    local rad = mathMax(1, fovSet.Radius + pulseOffset)

    UpdateDraw(FOVRing, {Position = fovPos, Radius = rad, Color = fovSet.Color, Transparency = fovSet.Transparency, Visible = fovSet.Visible})
    local fillVis = fovSet.Visible and fovSet.Filled
    UpdateDraw(FOVFill, {Position = fovPos, Radius = rad, Color = fovSet.FilledColor, Transparency = fovSet.FilledTransp, Visible = fillVis})

    return fovPos
end

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
            local curCData = curTar and CharCache[curTar]
            if not curCData or curCData.Hum.Health <= 0 then
                local now = osClock()
                if now - aimSet._lastTargetSearch > 0.06 then 
                    aimSet.CurrentTarget = GetClosestPlayer(fovSet, aimSet, fovPos)
                    aimSet._lastTargetSearch = now
                end
            end
        end

        local target = aimSet.CurrentTarget
        local cData = target and CharCache[target]

        if cData then
            local targetPart, lockIsVisible = GetAimPart(cData, aimSet.AimMode)
            
            if targetPart then
                local aimPos = targetPart.Position
                if aimSet.PredictionEnabled then
                    local velocity = targetPart.AssemblyLinearVelocity
                    if velocity.X*velocity.X + velocity.Y*velocity.Y + velocity.Z*velocity.Z > 90000 then 
                        velocity = velocity.Unit * 300 
                    end
                    
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
                            local dx, dy = screenAimPos.X - mousePos.X, screenAimPos.Y - mousePos.Y
                            local distToCrosshair = mathSqrt(dx*dx + dy*dy)
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
                    local accentColor = lockIsVisible and COLOR_WHITE or COLOR_RED
                    
                    local actualHP = cData.Hum.Health or 0
                    thudLerpedHP = thudLerpedHP + (actualHP - thudLerpedHP) * (deltaTime * 10)
                    if thudLerpedHP ~= thudLerpedHP then thudLerpedHP = 0 end 
                    local hpPct = mathClamp(thudLerpedHP / (cData.Hum.MaxHealth or 100), 0, 1)

                    local distInt = 0
                    local myCData = CharCache[LocalPlayer]
                    if myCData and myCData.HRP then distInt = mathFloor((myCData.HRP.Position - cData.HRP.Position).Magnitude) end
                    
                    local rawName = target.DisplayName
                    local rawData = "HP: " .. mathFloor(actualHP) .. "  |  Dist: " .. distInt .. "m"
                    if aimSet.AimMode == "Chaos" then rawData = rawData .. "  |  ⚡ " .. chaosCurrentPart end
                    
                    if thudLastNameCache ~= rawName then
                        thudLastNameCache = rawName
                        THUD.Name.Text = FormatText(rawName, visSet.TextCase)
                    end

                    if thudLastTextCache ~= rawData then 
                        thudLastTextCache = rawData 
                        THUD.Data.Text = FormatText(rawData, visSet.TextCase)
                    end

                    thudAlpha = mathClamp(thudAlpha + (deltaTime * 7), 0, 1)
                    local easeAlpha = 1 - (1 - thudAlpha) ^ 4
                    local ySlideOffset = (1 - easeAlpha) * 35

                    UpdateDraw(THUD.Shadow, {Visible = false}); UpdateDraw(THUD.Outline, {Visible = false}); UpdateDraw(THUD.BG, {Visible = false}); UpdateDraw(THUD.Accent2, {Visible = false})
                    UpdateDraw(THUD.BarBG, {Visible = false}); UpdateDraw(THUD.BarFG, {Visible = false})
                    UpdateDraw(THUD.Name, {Outline = true, Center = false}); UpdateDraw(THUD.Data, {Outline = true, Center = false})

                    if style == "Valorant" then
                        local boxW = mathFloor(280 * scale)
                        local boxH = mathFloor(45 * scale)
                        local hudX = (screenWidth / 2) - (boxW / 2)
                        local hudY = mathFloor(screenHeight * 0.08) - ySlideOffset 
                        
                        UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.85 * easeAlpha, Color = COLOR_HUD_VAL})
                        UpdateDraw(THUD.Accent, {Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY + boxH), Color = accentColor, Transparency = 1 * easeAlpha})
                        
                        UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(17 * scale)), Position = Vector2New(hudX + mathFloor(12*scale), hudY + mathFloor(6*scale)), Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(12 * scale)), Position = Vector2New(hudX + mathFloor(12*scale), hudY + mathFloor(24*scale)), Transparency = 1 * easeAlpha})
                        
                        local barW = boxW; local barH = mathMax(1, mathFloor(3 * scale)); local barY = hudY + boxH + mathFloor(2 * scale)
                        UpdateDraw(THUD.BarBG, {Visible = true, Size = Vector2New(barW, barH), Position = Vector2New(hudX, barY), Transparency = 1 * easeAlpha, Color = COLOR_BLACK})
                        UpdateDraw(THUD.BarFG, {Visible = true, Size = Vector2New(barW * hpPct, barH), Position = Vector2New(hudX, barY), Color = GetHealthColor(hpPct), Transparency = 1 * easeAlpha})

                    elseif style == "Standard" then
                        local calculatedWidth = mathMax(200, 40 + stringLen(thudLastNameCache) * 9)
                        local boxW = mathFloor(calculatedWidth * scale); local boxH = mathFloor(56 * scale)
                        local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(140 * scale)) + ySlideOffset
                        
                        UpdateDraw(THUD.Shadow, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX + 3, hudY + 3), Transparency = 0.5 * easeAlpha})
                        UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.85 * easeAlpha, Color = COLOR_HUD_BG})
                        UpdateDraw(THUD.Outline, {Visible = true, Size = Vector2New(boxW + 2, boxH + 2), Position = Vector2New(hudX - 1, hudY - 1), Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Accent, {Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                        
                        UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(16 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(8 * scale)), Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(13 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(28 * scale)), Transparency = 1 * easeAlpha})
                        
                        local barW = boxW - mathFloor(20 * scale); local barH = mathMax(1, mathFloor(3 * scale)); local barY = hudY + mathFloor(46 * scale)
                        UpdateDraw(THUD.BarBG, {Visible = true, Size = Vector2New(barW, barH), Position = Vector2New(hudX + mathFloor(10 * scale), barY), Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.BarFG, {Visible = true, Size = Vector2New(barW * hpPct, barH), Position = Vector2New(hudX + mathFloor(10 * scale), barY), Color = GetHealthColor(hpPct), Transparency = 1 * easeAlpha})
                        
                    elseif style == "Cyber" then
                        local calculatedWidth = mathMax(220, 50 + stringLen(thudLastNameCache) * 9)
                        local boxW = mathFloor(calculatedWidth * scale); local boxH = mathFloor(48 * scale)
                        local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(150 * scale)) + ySlideOffset
                        
                        UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.7 * easeAlpha, Color = COLOR_HUD_BG})
                        UpdateDraw(THUD.Accent, {Size = Vector2New(mathMax(2, mathFloor(6 * scale)), boxH), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Accent2, {Visible = true, Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 0.5 * easeAlpha})
                        
                        UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(17 * scale)), Position = Vector2New(hudX + mathFloor(16 * scale), hudY + mathFloor(8 * scale)), Text = "[" .. FormatText(thudLastNameCache, visSet.TextCase) .. "]", Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(11 * scale)), Position = Vector2New(hudX + mathFloor(16 * scale), hudY + mathFloor(28 * scale)), Transparency = 1 * easeAlpha})
    
                    elseif style == "Minimal" then
                        local hudX = (screenWidth / 2) - mathFloor(100 * scale)
                        local hudY = (screenHeight - mathFloor(130 * scale)) + ySlideOffset
                        
                        UpdateDraw(THUD.Accent, {Size = Vector2New(mathMax(1, mathFloor(3 * scale)), mathFloor(36 * scale)), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(16 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY), Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(13 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(20 * scale)), Transparency = 1 * easeAlpha})
                    
                    elseif style == "Tech" then
                        local calculatedWidth = mathMax(200, 40 + stringLen(thudLastNameCache) * 9)
                        local boxW = mathFloor(calculatedWidth * scale); local boxH = mathFloor(56 * scale)
                        local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(140 * scale)) + ySlideOffset
                        
                        UpdateDraw(THUD.Outline, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.5 * easeAlpha, Color = COLOR_HUD_BG})
                        UpdateDraw(THUD.Accent, {Size = Vector2New(boxW, mathMax(1, mathFloor(2 * scale))), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                        
                        UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(16 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(8 * scale)), Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(13 * scale)), Position = Vector2New(hudX + mathFloor(10 * scale), hudY + mathFloor(28 * scale)), Transparency = 1 * easeAlpha})
                    
                    elseif style == "Apex" then
                        local boxW = mathFloor(220 * scale); local boxH = mathFloor(45 * scale)
                        local hudX = (screenWidth / 2) - (boxW / 2); local hudY = (screenHeight - mathFloor(120 * scale)) + ySlideOffset
                        
                        UpdateDraw(THUD.BG, {Visible = true, Size = Vector2New(boxW, boxH), Position = Vector2New(hudX, hudY), Transparency = 0.6 * easeAlpha, Color = COLOR_HUD_BG})
                        UpdateDraw(THUD.Accent, {Size = Vector2New(mathMax(1, mathFloor(4 * scale)), boxH), Position = Vector2New(hudX, hudY), Color = accentColor, Transparency = 1 * easeAlpha})
                        
                        UpdateDraw(THUD.Name, {Size = mathMax(10, mathFloor(15 * scale)), Position = Vector2New(hudX + mathFloor(12 * scale), hudY + mathFloor(6 * scale)), Transparency = 1 * easeAlpha})
                        UpdateDraw(THUD.Data, {Size = mathMax(10, mathFloor(11 * scale)), Position = Vector2New(hudX + mathFloor(12 * scale), hudY + mathFloor(24 * scale)), Transparency = 1 * easeAlpha})
                        
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

local function DrawCornerBox(esp, x, y, w, h, col, doOutline, thickness)
    local lineLength = mathFloor(w / 3)
    
    UpdateDraw(esp.CornerLines[1].Main, {From = Vector2New(x, y), To = Vector2New(x + lineLength, y), Color = col, Thickness = thickness, Visible = true})
    UpdateDraw(esp.CornerLines[2].Main, {From = Vector2New(x, y), To = Vector2New(x, y + lineLength), Color = col, Thickness = thickness, Visible = true})
    UpdateDraw(esp.CornerLines[3].Main, {From = Vector2New(x + w, y), To = Vector2New(x + w - lineLength, y), Color = col, Thickness = thickness, Visible = true})
    UpdateDraw(esp.CornerLines[4].Main, {From = Vector2New(x + w, y), To = Vector2New(x + w, y + lineLength), Color = col, Thickness = thickness, Visible = true})
    UpdateDraw(esp.CornerLines[5].Main, {From = Vector2New(x, y + h), To = Vector2New(x + lineLength, y + h), Color = col, Thickness = thickness, Visible = true})
    UpdateDraw(esp.CornerLines[6].Main, {From = Vector2New(x, y + h), To = Vector2New(x, y + h - lineLength), Color = col, Thickness = thickness, Visible = true})
    UpdateDraw(esp.CornerLines[7].Main, {From = Vector2New(x + w, y + h), To = Vector2New(x + w - lineLength, y + h), Color = col, Thickness = thickness, Visible = true})
    UpdateDraw(esp.CornerLines[8].Main, {From = Vector2New(x + w, y + h), To = Vector2New(x + w, y + h - lineLength), Color = col, Thickness = thickness, Visible = true})

    if doOutline then
        local oT = thickness + 2
        UpdateDraw(esp.CornerLines[1].Out, {From = Vector2New(x - 1, y - 1), To = Vector2New(x + lineLength + 1, y - 1), Thickness = oT, Visible = true})
        UpdateDraw(esp.CornerLines[2].Out, {From = Vector2New(x - 1, y - 1), To = Vector2New(x - 1, y + lineLength + 1), Thickness = oT, Visible = true})
        UpdateDraw(esp.CornerLines[3].Out, {From = Vector2New(x + w + 1, y - 1), To = Vector2New(x + w - lineLength - 1, y - 1), Thickness = oT, Visible = true})
        UpdateDraw(esp.CornerLines[4].Out, {From = Vector2New(x + w + 1, y - 1), To = Vector2New(x + w + 1, y + lineLength + 1), Thickness = oT, Visible = true})
        UpdateDraw(esp.CornerLines[5].Out, {From = Vector2New(x - 1, y + h + 1), To = Vector2New(x + lineLength + 1, y + h + 1), Thickness = oT, Visible = true})
        UpdateDraw(esp.CornerLines[6].Out, {From = Vector2New(x - 1, y + h + 1), To = Vector2New(x - 1, y + h - lineLength - 1), Thickness = oT, Visible = true})
        UpdateDraw(esp.CornerLines[7].Out, {From = Vector2New(x + w + 1, y + h + 1), To = Vector2New(x + w - lineLength - 1, y + h + 1), Thickness = oT, Visible = true})
        UpdateDraw(esp.CornerLines[8].Out, {From = Vector2New(x + w + 1, y + h + 1), To = Vector2New(x + w + 1, y + h - lineLength - 1), Thickness = oT, Visible = true})
    else
        for i = 1, 8 do UpdateDraw(esp.CornerLines[i].Out, {Visible = false}) end
    end
end

local function UpdateESP(camPos, screenWidth, screenHeight, visSet)
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
    local boxes = visSet.ESPBoxes
    local textCase = visSet.TextCase
    local boxStyle = visSet.ESPBoxStyle
    
    local center = Vector2New(screenWidth * 0.5, screenHeight * 0.5)
    
    local tracerOriginY = (visSet.TracerOrigin == "Bottom") and screenHeight or (visSet.TracerOrigin == "Top") and 0 or (screenHeight * 0.5)
    local tracerStartPos = Vector2New(screenWidth * 0.5, tracerOriginY)

    for i = 1, #PlayerCache do
        local player = PlayerCache[i]
        local esp = ESPObjects[player]
        if not esp then continue end

        local cData = CharCache[player]
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
        
        local myCData = CharCache[LocalPlayer]
        local myRootPos = (myCData and myCData.HRP) and myCData.HRP.Position or camPos
        local dist = (cData.HRP.Position - myRootPos).Magnitude

        if dist > maxDist then 
            HideESP(esp); continue
        end

        local rootScreenPos, onScreen = Camera:WorldToViewportPoint(cData.HRP.Position)
        local depth = rootScreenPos.Z
        
        local needsVisRaycast = (espEnabled and useVisColor) or (chamsEnabled and visSet.ChamsUseVisColors)
        if needsVisRaycast and onScreen then
            if esp._staggerSlot == (FRAME_COUNT_RS % DYNAMIC_STAGGER) then
                esp._isVisible = IsVisible(cData.HRP, cData.Char, cData)
            end
        else
            esp._isVisible = true
        end

        local finalColor = (isTeammate and showTM) and visSet.TeammateColor or (useVisColor and (esp._isVisible and visSet.VisColor or visSet.HiddenColor) or visSet.StaticBoxColor)

        if chamsEnabled then
            if not esp.Highlight then
                esp.Highlight = Instance.new("Highlight")
                esp.Highlight.Parent = ChamsFolder
            end
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
            if esp.Highlight and esp.Highlight.Enabled then esp.Highlight.Enabled = false; esp.Highlight.Adornee = nil end
        end

        if cData.Hum.Health ~= esp._trackedHP then
            local diff = esp._trackedHP - cData.Hum.Health
            if diff > 0.5 and dmgNums then SpawnDamageNumber(diff, cData.Head.Position) end
            esp._trackedHP = cData.Hum.Health
        end

        if arrows and (not onScreen or depth <= 0) then
            local relativePos = Camera.CFrame:PointToObjectSpace(cData.HRP.Position)
            local angle = mathAtan2(relativePos.X, -relativePos.Z)
            
            local sAngle = mathSin(angle)
            local cAngle = mathCos(angle)
            local sAngle_minus = mathSin(angle - PI_OVER_4)
            local cAngle_minus = mathCos(angle - PI_OVER_4)
            local sAngle_plus = mathSin(angle + PI_OVER_4)
            local cAngle_plus = mathCos(angle + PI_OVER_4)
            
            local radius = visSet.ArrowRadius
            local size = visSet.ArrowSize
            local arrowCenter = center + Vector2New(sAngle * radius, -cAngle * radius)
            
            local p1 = arrowCenter + Vector2New(sAngle * size, -cAngle * size)
            local p2 = arrowCenter + Vector2New(sAngle_minus * size*0.75, -cAngle_minus * size*0.75)
            local p3 = arrowCenter + Vector2New(sAngle * size*0.3, -cAngle * size*0.3)
            local p4 = arrowCenter + Vector2New(sAngle_plus * size*0.75, -cAngle_plus * size*0.75)

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
        
        local dThick = visSet.BaseThickness
        if visSet.DynamicThickness and depth > 0 then
            dThick = mathClamp(visSet.BaseThickness * (100 / mathMax(depth, 10)), 0.5, 3)
        end

        if not espEnabled or not onScreen or depth <= 0 then
            HideESP(esp); continue
        end

        esp._lastVisible = true
        local headCalcPos = cData.HRP.Position + VEC3_HEAD_OFFSET
        local legCalcPos = cData.HRP.Position - VEC3_LEG_OFFSET
        local headScreenPos = Camera:WorldToViewportPoint(headCalcPos)
        local legScreenPos = Camera:WorldToViewportPoint(legCalcPos)

        local boxHeight = mathAbs(headScreenPos.Y - legScreenPos.Y); local boxWidth = boxHeight * 0.6
        local xPosition = rootScreenPos.X - (boxWidth * 0.5); local yPosition = headScreenPos.Y

        if boxes then
            if boxStyle == "Standard" then
                UpdateDraw(esp.Box, {Visible = true, Size = Vector2New(boxWidth, boxHeight), Position = Vector2New(xPosition, yPosition), Color = finalColor, Thickness = dThick})
                if visSet.ESPOutline then UpdateDraw(esp.BoxOutline, {Visible = true, Size = Vector2New(boxWidth + 3, boxHeight + 3), Position = Vector2New(xPosition - 1.5, yPosition - 1.5), Thickness = dThick + 2}) else UpdateDraw(esp.BoxOutline, {Visible = false}) end
                for i = 1, 8 do UpdateDraw(esp.CornerLines[i].Main, {Visible = false}); UpdateDraw(esp.CornerLines[i].Out, {Visible = false}) end
            else
                UpdateDraw(esp.Box, {Visible = false}); UpdateDraw(esp.BoxOutline, {Visible = false})
                DrawCornerBox(esp, xPosition, yPosition, boxWidth, boxHeight, finalColor, visSet.ESPOutline, dThick)
            end

            if visSet.ESPBoxFill then 
                UpdateDraw(esp.BoxFill, {Visible = true, Size = Vector2New(boxWidth, boxHeight), Position = Vector2New(xPosition, yPosition), Color = finalColor, Transparency = visSet.ESPBoxFillTrans})
            else 
                UpdateDraw(esp.BoxFill, {Visible = false})
            end
        else
            UpdateDraw(esp.Box, {Visible = false}); UpdateDraw(esp.BoxOutline, {Visible = false}); UpdateDraw(esp.BoxFill, {Visible = false})
            for i = 1, 8 do UpdateDraw(esp.CornerLines[i].Main, {Visible = false}); UpdateDraw(esp.CornerLines[i].Out, {Visible = false}) end
        end

        local healthPercentage = mathClamp(cData.Hum.Health / (cData.Hum.MaxHealth or 100), 0, 1)

        if visSet.HealthBar then
            local fillHeight = mathMax(1, boxHeight * healthPercentage)
            UpdateDraw(esp.BarBG, {Visible = true, Size = Vector2New(4, boxHeight + 2), Position = Vector2New(xPosition - 7, yPosition - 1)})
            UpdateDraw(esp.BarOutline, {Visible = true, Size = Vector2New(6, boxHeight + 4), Position = Vector2New(xPosition - 8, yPosition - 2)})
            UpdateDraw(esp.BarFG, {Visible = true, Size = Vector2New(2, fillHeight), Position = Vector2New(xPosition - 6, yPosition + boxHeight - fillHeight), Color = GetHealthColor(healthPercentage)})
        else 
            UpdateDraw(esp.BarBG, {Visible = false}); UpdateDraw(esp.BarFG, {Visible = false}); UpdateDraw(esp.BarOutline, {Visible = false})
        end

        if esp.Name.Font ~= visSet.ESPFont then
            for _, txt in ipairs({esp.Name, esp.Username, esp.Distance, esp.Health, esp.Weapon}) do txt.Font = visSet.ESPFont end
        end
        
        local textYPositionTop = yPosition - visSet.ESPTextScale - 4
        local textYPositionBottom = yPosition + boxHeight + 4
        local nameColor = visSet.UseCustomNameColor and visSet.ESPNameColor or finalColor
        
        if esp._lastTextCase ~= textCase then
            esp._lastTextCase = textCase
            esp._lastDistStrInt = -1
            esp._lastHPStrInt = -1
            esp._lastWepStr = "\0"
            esp._lastNameStr = "\0"
            esp._lastUnameStr = "\0"
        end

        if visSet.ESPNames then
            if visSet.ESPNameStyle == "Display Name" or visSet.ESPNameStyle == "Both" then
                local dName = player.DisplayName
                if esp._lastNameStr ~= dName then
                    esp._lastNameStr = dName
                    esp.Name.Text = FormatText(dName, textCase)
                end
                UpdateDraw(esp.Name, {Visible = true, Position = Vector2New(rootScreenPos.X, textYPositionTop), Color = nameColor, Size = visSet.ESPTextScale})
                if visSet.ESPNameStyle == "Both" then textYPositionTop = textYPositionTop - (visSet.ESPTextScale - 2) end
            else 
                UpdateDraw(esp.Name, {Visible = false}) 
            end

            if visSet.ESPNameStyle == "Username" or visSet.ESPNameStyle == "Both" then
                local uName = "@" .. player.Name
                if esp._lastUnameStr ~= uName then
                    esp._lastUnameStr = uName
                    esp.Username.Text = FormatText(uName, textCase)
                end
                UpdateDraw(esp.Username, {Visible = true, Position = Vector2New(rootScreenPos.X, textYPositionTop), Color = visSet.UseCustomNameColor and visSet.ESPUsernameColor or finalColor, Size = mathMax(10, visSet.ESPTextScale - 2)})
            else 
                UpdateDraw(esp.Username, {Visible = false}) 
            end
        else 
            UpdateDraw(esp.Name, {Visible = false}); UpdateDraw(esp.Username, {Visible = false})
        end

        if visSet.DistanceDisplay then
            local dSize = mathMax(10, visSet.ESPTextScale - 2)
            local trueDist = mathFloor(dist)
            if esp._lastDistStrInt ~= trueDist then
                local txt = trueDist .. "m"
                esp.Distance.Text = FormatText(txt, textCase)
                esp.Distance.Color = GetDistanceColor(trueDist)
                esp._lastDistStrInt = trueDist
            end
            UpdateDraw(esp.Distance, {Visible = true, Position = Vector2New(rootScreenPos.X, textYPositionBottom), Size = dSize})
            textYPositionBottom = textYPositionBottom + dSize + 2
        else 
            UpdateDraw(esp.Distance, {Visible = false})
        end
        
        if visSet.HealthNumbers then
            local hSize = mathMax(10, visSet.ESPTextScale - 2)
            local hpInt = mathFloor(cData.Hum.Health)
            if esp._lastHPStrInt ~= hpInt then
                local txt = hpInt .. " HP"
                esp.Health.Text = FormatText(txt, textCase)
                esp._lastHPStrInt = hpInt
            end
            UpdateDraw(esp.Health, {Visible = true, Color = GetHealthColor(healthPercentage), Position = Vector2New(rootScreenPos.X, textYPositionBottom), Size = hSize})
            textYPositionBottom = textYPositionBottom + hSize + 2
        else
            UpdateDraw(esp.Health, {Visible = false})
        end
        
        if visSet.WeaponESP then
            local tool = cData.Char:FindFirstChildOfClass("Tool")
            local wStr = tool and tool.Name or "None"
            local wSize = mathMax(10, visSet.ESPTextScale - 2)
            if esp._lastWepStr ~= wStr then
                esp.Weapon.Text = FormatText(wStr, textCase)
                esp._lastWepStr = wStr
            end
            UpdateDraw(esp.Weapon, {Visible = true, Color = Color3RGB(220, 220, 220), Position = Vector2New(rootScreenPos.X, textYPositionBottom), Size = wSize})
            textYPositionBottom = textYPositionBottom + wSize + 2
        else
            UpdateDraw(esp.Weapon, {Visible = false})
        end
    end
end

-- STREAMING_CHUNK: THREAD DECOUPLING - Heartbeat Loop for Physics & Raycasts
-- ============================================================
--  HEARTBEAT LOOP (Physics / Raycasting)
-- ============================================================
local function HeartbeatLoop(deltaTime)
    FRAME_COUNT_HB = FRAME_COUNT_HB + 1
    
    local playerCount = #PlayerCache
    DYNAMIC_STAGGER = mathClamp(mathFloor(playerCount / 6), 3, 15)
    local currentTickSlot = FRAME_COUNT_HB % DYNAMIC_STAGGER

    -- Triggerbot
    if Settings.Triggerbot.Enabled and VirtualInput then
        triggerbotTimer = triggerbotTimer - deltaTime
        if triggerbotTimer <= 0 and mathRandom(1, 100) <= Settings.Triggerbot.HitChance then
            local cx, cy = Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5
            local originPos, direction

            if Settings.FOV.FollowCursor then
                local mousePos = UserInputService:GetMouseLocation()
                cx, cy = mousePos.X, mousePos.Y
                local unitRay = Camera:ViewportPointToRay(cx, cy)
                originPos = unitRay.Origin
                direction = unitRay.Direction * 1000
            else
                originPos = Camera.CFrame.Position
                direction = Camera.CFrame.LookVector * 1000
            end

            local lpChar = LocalPlayer.Character
            if TBotLastChar ~= lpChar then
                local newFilter = {Camera}
                if lpChar then tableInsert(newFilter, lpChar) end
                GlobalRayParams.FilterDescendantsInstances = newFilter
                TBotLastChar = lpChar
            end

            local result = workspace:Raycast(originPos, direction, GlobalRayParams)
            if result and result.Instance then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                if model and model:FindFirstChild("Humanoid") then
                    local targetPlayer = Players:GetPlayerFromCharacter(model)
                    if targetPlayer and targetPlayer ~= LocalPlayer then
                        if not (Settings.Triggerbot.TeamCheck and IsTeammateCached(targetPlayer)) then
                            task.spawn(function()
                                pcall(function()
                                    VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                                    task.wait(0.01)
                                    VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                                end)
                            end)
                            triggerbotTimer = Settings.Triggerbot.Delay
                        end
                    end
                end
            end
        end
    end

    -- Hitbox Expander
    if Settings.Hitbox.Enabled then
        local targetPartName = Settings.Hitbox.Part
        local newSize = Vector3New(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
        local newTrans = Settings.Hitbox.Transparency
        
        for _, player in ipairs(PlayerCache) do
            if player ~= LocalPlayer and (not Settings.Aimlock.TeamCheck or not IsTeammateCached(player)) then
                local cData = CharCache[player]
                if cData and cData.Hum.Health > 0 then
                    local part = (targetPartName == "Head") and cData.Head or (targetPartName == "HumanoidRootPart" and cData.HRP) or cData.Char:FindFirstChild(targetPartName)
                    if part and part:IsA("BasePart") then
                        if not OriginalHitboxCache[player] then OriginalHitboxCache[player] = {} end
                        if not OriginalHitboxCache[player][part] then
                            OriginalHitboxCache[player][part] = {
                                Size = part.Size,
                                Transparency = part.Transparency,
                                CanCollide = part.CanCollide
                            }
                        end
                        if part.Size ~= newSize then part.Size = newSize end
                        if part.Transparency ~= newTrans then part.Transparency = newTrans end
                        if part.CanCollide then part.CanCollide = false end
                    end
                end
            end
        end
    else
        for player, parts in pairs(OriginalHitboxCache) do
            for part, data in pairs(parts) do
                if part and part.Parent then
                    if part.Size ~= data.Size then part.Size = data.Size end
                    if part.Transparency ~= data.Transparency then part.Transparency = data.Transparency end
                    if part.CanCollide ~= data.CanCollide then part.CanCollide = data.CanCollide end
                end
            end
        end
        table.clear(OriginalHitboxCache)
    end

    -- World Modifiers
    if Settings.World.Enabled then
        if Lighting.ClockTime ~= Settings.World.Time then Lighting.ClockTime = Settings.World.Time end
        if Lighting.Brightness ~= Settings.World.Brightness then Lighting.Brightness = Settings.World.Brightness end
        if Lighting.GlobalShadows ~= Settings.World.GlobalShadows then Lighting.GlobalShadows = Settings.World.GlobalShadows end
        if Lighting.Ambient ~= Settings.World.Ambient then Lighting.Ambient = Settings.World.Ambient end
    else
        if Lighting.ClockTime ~= OriginalLighting.Time then Lighting.ClockTime = OriginalLighting.Time end
        if Lighting.Brightness ~= OriginalLighting.Brightness then Lighting.Brightness = OriginalLighting.Brightness end
        if Lighting.GlobalShadows ~= OriginalLighting.GlobalShadows then Lighting.GlobalShadows = OriginalLighting.GlobalShadows end
        if Lighting.Ambient ~= OriginalLighting.Ambient then Lighting.Ambient = OriginalLighting.Ambient end
    end

    -- Player Mods
    if Settings.Player.CameraFOVEnabled and Camera.FieldOfView ~= Settings.Player.CameraFOV then Camera.FieldOfView = Settings.Player.CameraFOV end
    local myCData = CharCache[LocalPlayer]
    if myCData then
        if Settings.Player.WalkSpeedEnabled and myCData.Hum.WalkSpeed ~= Settings.Player.WalkSpeed then myCData.Hum.WalkSpeed = Settings.Player.WalkSpeed end
        if Settings.Player.JumpPowerEnabled and myCData.Hum.JumpPower ~= Settings.Player.JumpPower then myCData.Hum.JumpPower = Settings.Player.JumpPower end
    end
end

-- ============================================================
--  MASTER RENDER LOOP
-- ============================================================
local function MasterRenderLoop(deltaTime)
    local ok, err = pcall(function()
        FRAME_COUNT_RS = FRAME_COUNT_RS + 1
        Camera = workspace.CurrentCamera
        if not Camera then return end

        local camPos = Camera.CFrame.Position
        local viewport = Camera.ViewportSize
        if viewport.X == 0 or viewport.Y == 0 then return end

        local screenWidth, screenHeight = viewport.X, viewport.Y
        local screenCenter = Vector2New(screenWidth * 0.5, screenHeight * 0.5)

        local fovPos = UpdateFOV(screenCenter, Settings.FOV)
        UpdateAimlock(camPos, screenWidth, screenHeight, deltaTime, Settings.Aimlock, Settings.DetectionAvoidance, Settings.Visuals, Settings.FOV, fovPos)
        UpdateESP(camPos, screenWidth, screenHeight, Settings.Visuals)
        UpdateDamageNumbers(Settings.Visuals)
    end)
    if not ok then warn("KAIM Rendering Error: " .. tostring(err)) end
end

tableInsert(KaimConnections, RunService.Heartbeat:Connect(HeartbeatLoop))
tableInsert(KaimConnections, RunService.RenderStepped:Connect(MasterRenderLoop))

-- ============================================================
--  WINDUI MENU BUILDING (Polished Layout)
-- ============================================================
local Window = WindUI:CreateWindow({
    Title       = "KAIM v7.8",
    Author      = "by FRK (Thread-Safe)",
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
    Misc     = Window:Tab({ Title = "World & Misc", Icon = "globe" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}

-- [ DASHBOARD ]
local HomeWelcome = Tabs.Home:Section({ Title = "Welcome to KAIM v7.8", Box = true, Opened = true })
HomeWelcome:Paragraph({ Title = "Thread-Safe Engine", Desc = "v7.8 entirely prevents execution-time crashing by encapsulating the engine inside an asynchronous thread and utilizing non-yielding UI fallback containers.", Icon = "shield-check" })

-- [ COMBAT TAB ]
local AimCore = Tabs.Combat:Section({ Title = "Aimlock Core", Box = true, Opened = true })
AimCore:Toggle({ Title = "Enable Aimlock", Flag = "AimlockEnabled", Value = false, Callback = function(v) Settings.Aimlock.Enabled = v end })
AimCore:Keybind({ Title = "Aimlock Key", Flag = "AimlockKeybind", Value = "RightClick", Callback = function(v) Settings.Aimlock.Keybind = v end })
AimCore:Dropdown({ Title = "Target Priority", Flag = "AimlockPriority", Values = { "Crosshair", "Distance" }, Value = "Crosshair", Callback = function(v) Settings.Aimlock.TargetPriority = v end })

local TBotCore = Tabs.Combat:Section({ Title = "Triggerbot Settings", Box = true, Opened = true })
TBotCore:Toggle({ Title = "Enable Triggerbot", Flag = "TBEnabled", Value = false, Callback = function(v) Settings.Triggerbot.Enabled = v end })
TBotCore:Slider({ Title = "Trigger Delay", Flag = "TBDelay", Step = 0.01, Value = { Min = 0.01, Max = 0.5, Default = 0.05 }, Callback = function(v) Settings.Triggerbot.Delay = v end })

local AimAdvanced = Tabs.Combat:Section({ Title = "Aim Tuning (Prediction & Smooth)", Box = true, Opened = false })
AimAdvanced:Dropdown({ Title = "Aim Mode", Flag = "AimlockAimMode", Values = { "Smart", "Chaos", "Head", "Torso", "Limbs", "HRP" }, Value = "Smart", Callback = function(v) Settings.Aimlock.AimMode = v end })
AimAdvanced:Toggle({ Title = "Enable Prediction", Flag = "AimlockPredictionEnabled", Value = true, Callback = function(v) Settings.Aimlock.PredictionEnabled = v end })
AimAdvanced:Toggle({ Title = "Distance Scaling Prediction", Flag = "AimlockDynPred", Value = true, Callback = function(v) Settings.Aimlock.DynamicPrediction = v end })
AimAdvanced:Slider({ Title = "Base Prediction Strength", Flag = "AimlockPrediction", Step = 0.005, Value = { Min = 0, Max = 0.3, Default = 0.135 }, Callback = function(v) Settings.Aimlock.Prediction = v end })
AimAdvanced:Toggle({ Title = "Smooth Aiming", Flag = "AimlockSmooth", Value = false, Callback = function(v) Settings.Aimlock.SmoothAiming = v end })
AimAdvanced:Slider({ Title = "Smooth Speed", Flag = "AimlockSmoothSpeed", Step = 0.05, Value = { Min = 0.05, Max = 1.0, Default = 0.3 }, Callback = function(v) Settings.Aimlock.SmoothSpeed = v end })

local HitboxCore = Tabs.Combat:Section({ Title = "Hitbox Expander", Box = true, Opened = false })
HitboxCore:Toggle({ Title = "Enable Hitbox Expander", Flag = "HitboxEnabled", Value = false, Callback = function(v) Settings.Hitbox.Enabled = v end })
HitboxCore:Dropdown({ Title = "Target Part", Flag = "HitboxPart", Values = { "Head", "HumanoidRootPart", "UpperTorso" }, Value = "Head", Callback = function(v) Settings.Hitbox.Part = v end })
HitboxCore:Slider({ Title = "Hitbox Size", Flag = "HitboxSize", Step = 0.5, Value = { Min = 2, Max = 30, Default = 5 }, Callback = function(v) Settings.Hitbox.Size = v end })
HitboxCore:Slider({ Title = "Hitbox Transparency", Flag = "HitboxTrans", Step = 0.05, Value = { Min = 0, Max = 1, Default = 0.5 }, Callback = function(v) Settings.Hitbox.Transparency = v end })

local DetectionSec = Tabs.Combat:Section({ Title = "Detection Avoidance", Box = true, Opened = false })
DetectionSec:Toggle({ Title = "Periodic Disable", Flag = "PeriodicDisable", Value = false, Callback = function(v) Settings.DetectionAvoidance.PeriodicAimDisable = v end })
DetectionSec:Slider({ Title = "Disable Chance", Flag = "DisableChance", Step = 0.01, Value = { Min = 0.01, Max = 1.0, Default = 0.1 }, Callback = function(v) Settings.DetectionAvoidance.DisableChance = v end })

-- [ VISUALS TAB ]
local ESPCore = Tabs.Visuals:Section({ Title = "ESP Overlays", Box = true, Opened = true })
ESPCore:Toggle({ Title = "Enable ESP", Flag = "ESPEnabled", Value = false, Callback = function(v) Settings.Visuals.ESPEnabled = v end })
ESPCore:Dropdown({ Title = "Box Style", Flag = "ESPBoxStyle", Values = { "Standard", "Corner" }, Value = "Corner", Callback = function(v) Settings.Visuals.ESPBoxStyle = v end })
ESPCore:Toggle({ Title = "ESP Boxes", Flag = "ESPBoxes", Value = true, Callback = function(v) Settings.Visuals.ESPBoxes = v end })
ESPCore:Toggle({ Title = "3D Depth Scaling (Dynamic Thickness)", Flag = "ESPDynamicThick", Value = true, Callback = function(v) Settings.Visuals.DynamicThickness = v end })
ESPCore:Slider({ Title = "Base Line Thickness", Flag = "ESPBaseThick", Step = 0.5, Value = { Min = 0.5, Max = 3, Default = 1.5 }, Callback = function(v) Settings.Visuals.BaseThickness = v end })

local ESPText = Tabs.Visuals:Section({ Title = "Names & Text Info", Box = true, Opened = true })
ESPText:Toggle({ Title = "Show Names", Flag = "ESPNames", Value = true, Callback = function(v) Settings.Visuals.ESPNames = v end })
ESPText:Toggle({ Title = "Show Distance", Flag = "ESPDistDisplay", Value = false, Callback = function(v) Settings.Visuals.DistanceDisplay = v end })
ESPText:Toggle({ Title = "Show Weapon", Flag = "ESPWeapon", Value = false, Callback = function(v) Settings.Visuals.WeaponESP = v end })
ESPText:Dropdown({ Title = "Text Case", Flag = "ESPTextCase", Values = { "Normal", "UPPERCASE" }, Value = "UPPERCASE", Callback = function(v) Settings.Visuals.TextCase = v end })
ESPText:Slider({ Title = "Text Scale", Flag = "ESPTextScale", Step = 1, Value = { Min = 10, Max = 22, Default = 14 }, Callback = function(v) Settings.Visuals.ESPTextScale = v end })

local ESPColors = Tabs.Visuals:Section({ Title = "Colors & Visibility", Box = true, Opened = false })
ESPColors:Toggle({ Title = "Use Visibility Colors", Flag = "ESPVisColors", Value = true, Callback = function(v) Settings.Visuals.UseVisColors = v end })
ESPColors:Colorpicker({ Title = "Visible Color", Flag = "ESPVisColor", Default = Color3RGB(0, 255, 100), Transparency = 0, Callback = function(v) Settings.Visuals.VisColor = v end })
ESPColors:Colorpicker({ Title = "Hidden Color", Flag = "ESPHiddenColor", Default = COLOR_RED, Transparency = 0, Callback = function(v) Settings.Visuals.HiddenColor = v end })

local HitVisuals = Tabs.Visuals:Section({ Title = "Health Info & Effects", Box = true, Opened = false })
HitVisuals:Toggle({ Title = "Health Bar", Flag = "ESPHealthBar", Value = true, Callback = function(v) Settings.Visuals.HealthBar = v end })
HitVisuals:Toggle({ Title = "Health Numbers", Flag = "ESPHealthNumbers", Value = false, Callback = function(v) Settings.Visuals.HealthNumbers = v end })
HitVisuals:Toggle({ Title = "Show Damage Numbers", Flag = "DamageNumbers", Value = false, Callback = function(v) Settings.Visuals.DamageNumbers = v end })
HitVisuals:Colorpicker({ Title = "Damage Number Color", Flag = "DamageColor", Default = Color3RGB(255, 255, 0), Transparency = 0, Callback = function(v) Settings.Visuals.DamageColor = v end })

local ESPChams = Tabs.Visuals:Section({ Title = "3D Chams & Tracers", Box = true, Opened = false })
ESPChams:Toggle({ Title = "Enable Chams", Flag = "ChamsEnabled", Value = false, Callback = function(v) Settings.Visuals.ChamsEnabled = v end })
ESPChams:Toggle({ Title = "See Through Walls", Flag = "ChamsDepth", Value = true, Callback = function(v) Settings.Visuals.ChamsDepth = v end })
ESPChams:Toggle({ Title = "Look Tracers (View Angles)", Flag = "LookTracers", Value = false, Callback = function(v) Settings.Visuals.LookTracers = v end })
ESPChams:Toggle({ Title = "Off-Screen Arrows", Flag = "OffScreen", Value = false, Callback = function(v) Settings.Visuals.OffScreenArrows = v end })

local HUDSection = Tabs.Visuals:Section({ Title = "Radar & Target HUD", Box = true, Opened = false })
HUDSection:Toggle({ Title = "Show Target HUD", Flag = "HUDEnabled", Value = true, Callback = function(v) Settings.Visuals.TargetUI = v end })
HUDSection:Dropdown({ Title = "HUD Style", Flag = "HUDStyle", Values = { "Valorant", "Standard", "Cyber", "Minimal", "Tech", "Apex", "Crosshair" }, Value = "Valorant", Callback = function(v) Settings.Visuals.TargetUIStyle = v end })
HUDSection:Slider({ Title = "HUD Scale", Flag = "HUDScale", Step = 0.1, Value = { Min = 0.5, Max = 2.0, Default = 1.0 }, Callback = function(v) Settings.Visuals.TargetUIScale = v end })
HUDSection:Toggle({ Title = "Show FOV Circle", Flag = "FOVVisible", Value = true, Callback = function(v) Settings.FOV.Visible = v end })

-- [ WORLD / MISC TAB ]
local MovementSec = Tabs.Misc:Section({ Title = "Local Player Movement", Box = true, Opened = true })
MovementSec:Toggle({ Title = "Loop Walk Speed", Flag = "WalkSpeedEnabled", Value = false, Callback = function(v) Settings.Player.WalkSpeedEnabled = v end })
MovementSec:Slider({ Title = "Walk Speed", Flag = "WalkSpeed", Step = 1, Value = { Min = 5, Max = 100, Default = 16 }, Callback = function(v) Settings.Player.WalkSpeed = v end })
MovementSec:Toggle({ Title = "Loop Jump Power", Flag = "JumpPowerEnabled", Value = false, Callback = function(v) Settings.Player.JumpPowerEnabled = v end })
MovementSec:Slider({ Title = "Jump Power", Flag = "JumpPower", Step = 5, Value = { Min = 10, Max = 250, Default = 50 }, Callback = function(v) Settings.Player.JumpPower = v end })
MovementSec:Toggle({ Title = "Infinite Jump", Flag = "InfiniteJump", Value = false, Callback = function(v) Settings.Player.InfiniteJump = v end })

local NoclipSec = Tabs.Misc:Section({ Title = "Physics (Noclip)", Box = true, Opened = true })
local noclipConn = nil
local noclipAddConn = nil
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
    if noclipAddConn then noclipAddConn:Disconnect(); noclipAddConn = nil end
    if state then
        BuildNoclipCache(LocalPlayer.Character)
        noclipConn = RunService.Stepped:Connect(function()
            for _, entry in ipairs(noclipCache) do 
                if entry.part and entry.part.Parent and entry.part.CanCollide then 
                    entry.part.CanCollide = false 
                end 
            end
        end)
        noclipAddConn = LocalPlayer.Character.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                tableInsert(noclipCache, { part = part, original = part.CanCollide })
                part.CanCollide = false
            end
        end)
        tableInsert(KaimConnections, noclipConn)
        tableInsert(KaimConnections, noclipAddConn)
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

tableInsert(KaimConnections, UserInputService.JumpRequest:Connect(function()
    if Settings.Player.InfiniteJump then
        local cData = CharCache[LocalPlayer]
        if cData and cData.Hum then
            cData.Hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

local WorldCore = Tabs.Misc:Section({ Title = "World Environment", Box = true, Opened = false })
WorldCore:Toggle({ Title = "Enable Lighting Modifiers", Flag = "WorldEnabled", Value = false, Callback = function(v) Settings.World.Enabled = v end })
WorldCore:Slider({ Title = "Time of Day", Flag = "WorldTime", Step = 0.5, Value = { Min = 0, Max = 24, Default = 14 }, Callback = function(v) Settings.World.Time = v end })
WorldCore:Toggle({ Title = "Global Shadows", Flag = "WorldShadows", Value = false, Callback = function(v) Settings.World.GlobalShadows = v end })

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
                for i = 1, 8 do esp.CornerLines[i].Main:Remove(); esp.CornerLines[i].Out:Remove() end
                esp.Name:Remove(); esp.Username:Remove(); esp.Distance:Remove(); esp.Health:Remove(); esp.Weapon:Remove()
                esp.BarBG:Remove(); esp.BarFG:Remove(); esp.BarOutline:Remove()
                esp.ArrowL1:Remove(); esp.ArrowL2:Remove(); esp.ArrowL3:Remove(); esp.ArrowL4:Remove()
                if esp.SnapLine then esp.SnapLine:Remove() end
                if esp.Highlight then esp.Highlight:Destroy() end
            end)
        end
        ESPObjects = {}
        
        for _, line in pairs(TracerLineCache) do pcall(function() line:Remove() end) end
        TracerLineCache = {}
        for _, line in pairs(LookTracerCache) do pcall(function() line:Remove() end) end
        LookTracerCache = {}
        for _, dn in pairs(ActiveDamageNumbers) do pcall(function() dn.TextObj:Remove() end) end
        for _, dn in pairs(DamageObjPool) do pcall(function() dn.TextObj:Remove() end) end
        ActiveDamageNumbers = {}
        DamageObjPool = {}
        
        -- Restore original lighting and hitboxes before destroying
        Lighting.ClockTime = OriginalLighting.Time
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient

        for player, parts in pairs(OriginalHitboxCache) do
            for part, data in pairs(parts) do
                if part and part.Parent then
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                    part.CanCollide = data.CanCollide
                end
            end
        end
        
        pcall(function() FOVRing:Remove(); FOVFill:Remove() end)
        pcall(function() ChamsFolder:Destroy() end)
        pcall(function() THUD.Shadow:Remove(); THUD.BG:Remove(); THUD.Outline:Remove(); THUD.Accent:Remove(); THUD.Accent2:Remove(); THUD.Name:Remove(); THUD.Data:Remove(); THUD.BarBG:Remove(); THUD.BarFG:Remove() end)
        Window:Destroy()
    end
})

-- STREAMING_CHUNK: Finalizing dynamic input and instant UI toggles...
-- ============================================================
--  ZERO-WIGGLE UI TOGGLE HOOK
-- ============================================================
local kaimScreenGui = nil

local function ToggleUI()
    if not kaimScreenGui or not kaimScreenGui.Parent then
        -- Use SafeContainer and fallbacks, safely verifying the gui
        local containers = { SafeContainer, PlayerGui, LocalPlayer:FindFirstChild("PlayerGui") }
        for _, container in ipairs(containers) do
            if container then
                for _, gui in ipairs(container:GetChildren()) do
                    if gui:IsA("ScreenGui") and (gui.Name == "Kaim" or gui.Name == "WindUI" or gui:FindFirstChild("Main") or gui:FindFirstChild("CanvasGroup") or gui:FindFirstChild("Window")) then
                        kaimScreenGui = gui
                        break
                    end
                end
            end
            if kaimScreenGui then break end
        end
    end

    if kaimScreenGui then
        kaimScreenGui.Enabled = not kaimScreenGui.Enabled
    else
        pcall(function() Window:Toggle() end)
    end
end

tableInsert(KaimConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    local toggleKey = Settings.UI.ToggleKey
    local ok, kc = pcall(function() return Enum.KeyCode[toggleKey] end)
    if ok and kc and input.KeyCode == kc then
        ToggleUI()
    end

    if input.KeyCode == cachedNoclipKC then
        local newState = not Settings.Player.NoclipEnabled
        SetNoclip(newState)
        WindUI:Notify({ Title = "Noclip", Content = "Noclip is now " .. (newState and "ON" or "OFF"), Duration = 2, Icon = "ghost" })
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
WindUI:Notify({ Title = "KAIM v7.8 (Thread-Safe)", Content = "Press K to toggle UI", Duration = 5, Icon = "shield-check" })


end)
