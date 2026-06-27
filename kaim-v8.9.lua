-- ============================================================
--  KAIM v8.8  |  Obsidian Edition (Singularity Revision)
--  Filtered Kinematics, Spherecast Triggerbot, Dynamic Bounds
--  Optimized: FPS-adaptive LOD, zero-alloc hot paths, green ESP
-- ============================================================

task.spawn(function()
local ok, err = xpcall(function()

-- Prevent double-execution crashes safely
local _env = (type(getgenv) == "function" and getgenv()) or _G
if _env.KAIM_LOADED then
    warn("KAIM | Script is already loaded! Press K to toggle the UI, or use the Unload button in Settings.")
    return
end

-- Wait for game to be ready
if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================================
--  SERVICES
-- ============================================================
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

local VirtualInput
pcall(function() VirtualInput = game:GetService("VirtualInputManager") end)

-- ============================================================
--  OBSIDIAN SECURE INITIALIZATION
-- ============================================================
local SafeContainer = LocalPlayer:FindFirstChild("PlayerGui") or workspace
pcall(function()
    local cg = game:GetService("CoreGui")
    if cg then SafeContainer = cg end
end)
pcall(function()
    local hui = gethui and gethui()
    if hui and typeof(hui) == "Instance" then SafeContainer = hui end
end)

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
if not Library then
    error("KAIM | Failed to load Obsidian Library. Check executor HTTP capabilities or internet connection.")
end

local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

_env.KAIM_LOADED = true

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
    local Visible = props.Visible
    if Visible ~= nil and obj.Visible ~= Visible then obj.Visible = Visible end
    local Position = props.Position
    if Position ~= nil and obj.Position ~= Position then obj.Position = Position end
    local Size = props.Size
    if Size ~= nil and obj.Size ~= Size then obj.Size = Size end
    local Color = props.Color
    if Color ~= nil and obj.Color ~= Color then obj.Color = Color end
    local Transparency = props.Transparency
    if Transparency ~= nil and obj.Transparency ~= Transparency then obj.Transparency = Transparency end
    local From = props.From
    if From ~= nil and obj.From ~= From then obj.From = From end
    local To = props.To
    if To ~= nil and obj.To ~= To then obj.To = To end
    local Thickness = props.Thickness
    if Thickness ~= nil and obj.Thickness ~= Thickness then obj.Thickness = Thickness end
    local Radius = props.Radius
    if Radius ~= nil and obj.Radius ~= Radius then obj.Radius = Radius end
    local Text = props.Text
    if Text ~= nil and obj.Text ~= Text then obj.Text = Text end
    local Outline = props.Outline
    if Outline ~= nil and obj.Outline ~= Outline then obj.Outline = Outline end
    local Center = props.Center
    if Center ~= nil and obj.Center ~= Center then obj.Center = Center end
    local Filled = props.Filled
    if Filled ~= nil and obj.Filled ~= Filled then obj.Filled = Filled end
    local Font = props.Font
    if Font ~= nil and obj.Font ~= Font then obj.Font = Font end
end

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
local mathExp     = math.exp
local stringLen   = string.len
local stringUpper = string.upper
local osClock     = os.clock
local Vector2New  = Vector2.new
local Vector3New  = Vector3.new
local Color3RGB   = Color3.fromRGB
local CFrameNew   = CFrame.new
local tableInsert = table.insert
local tableRemove = table.remove

local VEC3_ZERO = Vector3New(0, 0, 0)
local PI_OVER_4 = 0.78539816339

local COLOR_BLACK      = Color3RGB(0, 0, 0)
local COLOR_WHITE      = Color3RGB(255, 255, 255)
local COLOR_RED        = Color3RGB(255, 50, 50)
local COLOR_HUD_BG     = Color3RGB(12, 12, 14)
local COLOR_HUD_OUT    = Color3RGB(34, 34, 40)
local COLOR_HUD_VAL    = Color3RGB(17, 17, 17)
local COLOR_HUD_BAR_BG = Color3RGB(20, 20, 25)

local HP_COLORS = {
    Color3RGB(255, 50, 50),
    Color3RGB(255, 130, 0),
    Color3RGB(255, 200, 0),
    Color3RGB(100, 255, 50),
    Color3RGB(0, 255, 100)
}

local DIST_COLORS = {
    Color3RGB(0, 255, 100),
    Color3RGB(100, 255, 100),
    Color3RGB(255, 210, 0),
    Color3RGB(255, 140, 0),
    Color3RGB(255, 50, 50)
}

-- ============================================================
--  DEFAULT SETTINGS v8.8
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
        JerkPrediction     = true,
        BulletDropCompensation = false,
        ProjectileSpeed    = 1000,
        SmoothAiming       = false,
        SmoothSpeed        = 0.3,
        DynamicSmoothing   = false,
        HumanizeSmoothing  = false,
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
        Enabled   = false,
        Delay     = 0.05,
        HitChance = 100,
        TeamCheck = true,
        Spherecast = true,
        Thickness  = 0.5,
    },
    Hitbox = {
        Enabled      = false,
        Part         = "Head",
        Size         = 5,
        Transparency = 0.5,
    },
    FOV = {
        Visible      = true,
        FollowCursor = true,
        Radius       = 150,
        Thickness    = 1.5,
        Color        = COLOR_WHITE,
        Transparency = 0.8,
        Filled       = false,
        FilledColor  = COLOR_WHITE,
        FilledTransp = 0.92,
        Pulse        = false,
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
        TracerColor        = Color3RGB(0, 255, 100),
        DamageNumbers      = false,
        DamageColor        = Color3RGB(255, 255, 0),
        TargetUI           = true,
        TargetUIStyle      = "Ascension",
        TargetUIScale      = 1.0,
        MaxESPDistance     = 1000,
        LODDistance        = 500,
    },
    World = {
        Enabled       = false,
        Time          = 14,
        Brightness    = 2,
        GlobalShadows = false,
        Ambient       = COLOR_WHITE,
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
    Performance = {
        FrameSkip      = true,
        MaxESPPerFrame = 20,
    },
    UI = {
        ToggleKey = "K",
    },
}

-- ============================================================
--  ZERO-GC POOLS & GLOBAL CACHING
-- ============================================================
local KaimConnections     = {}
local PlayerCache         = {}
local TeamCache           = {}
local ESPObjects          = {}
local CharCache           = {}
local TracerLineCache     = {}
local LookTracerCache     = {}
local OriginalHitboxCache = {}
local OriginalLighting    = {}

local DamageObjPool       = {}
local ActiveDamageNumbers = {}

local SharedRayParams = RaycastParams.new()
SharedRayParams.FilterType  = Enum.RaycastFilterType.Exclude
SharedRayParams.IgnoreWater = true
local SharedRayFilter = {nil, nil}

local GlobalTriggerRayParams = RaycastParams.new()
GlobalTriggerRayParams.FilterType  = Enum.RaycastFilterType.Exclude
GlobalTriggerRayParams.IgnoreWater = true
local TriggerRayFilter = {nil, nil}
local TBotLastChar = nil

local CandidatePool = {}
local ChaosPool     = {}

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

local _lastFrameTime    = 0
local _avgDeltaTime     = 0.016
local _fpsAdaptiveSkip  = 1

local thudLerpedHP      = 100
local thudAlpha         = 0
local thudLastTextCache = ""
local thudLastNameCache = ""
local _hudLastVisible   = false

tableInsert(KaimConnections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    table.clear(TeamCache)
end))

-- ============================================================
--  LIGHTING CACHE
-- ============================================================
local function CacheOriginalLighting()
    OriginalLighting = {
        Time          = Lighting.ClockTime,
        Brightness    = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient       = Lighting.Ambient
    }
end
CacheOriginalLighting()

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing = SafeDrawingNew("Circle"); FOVRing.Thickness = 1.5; FOVRing.Filled = false
local FOVFill = SafeDrawingNew("Circle"); FOVFill.Thickness = 1;   FOVFill.Filled = true

local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name  = "KaimChams"
pcall(function() ChamsFolder.Parent = SafeContainer end)

local THUD = {
    Shadow  = SafeDrawingNew("Square"), BG      = SafeDrawingNew("Square"),
    Outline = SafeDrawingNew("Square"), Accent  = SafeDrawingNew("Square"),
    Accent2 = SafeDrawingNew("Square"), Name    = SafeDrawingNew("Text"),
    Data    = SafeDrawingNew("Text"),   BarBG   = SafeDrawingNew("Square"),
    BarFG   = SafeDrawingNew("Square"),
}

local function InitTHUD()
    THUD.Shadow.Filled  = true;  THUD.Shadow.Color  = COLOR_BLACK
    THUD.BG.Filled      = true;  THUD.BG.Color      = COLOR_HUD_BG
    THUD.Outline.Filled = false; THUD.Outline.Color = COLOR_HUD_OUT
    THUD.Accent.Filled  = true;  THUD.Accent2.Filled = true
    THUD.Name.Outline = true;  THUD.Name.Color  = COLOR_WHITE;             THUD.Name.Font = 2
    THUD.Data.Outline = true;  THUD.Data.Color  = Color3RGB(180,180,200);  THUD.Data.Font = 2
    THUD.BarBG.Filled = true;  THUD.BarBG.Color = COLOR_HUD_BAR_BG
    THUD.BarFG.Filled = true
end
InitTHUD()

-- ============================================================
--  UTILITY FUNCTIONS & PHYSICS ENGINE
-- ============================================================
local function FormatText(str, formatType)
    if formatType == "UPPERCASE" then return stringUpper(str) end
    return str
end

local function GetColorFromGradient(pct, colorsArray)
    if pct >= 1 then return colorsArray[#colorsArray] end
    if pct <= 0 then return colorsArray[1] end
    local scaled = pct * (#colorsArray - 1) + 1
    local idx    = mathFloor(scaled)
    local frac   = scaled - idx
    if colorsArray[idx] and colorsArray[idx + 1] then
        return colorsArray[idx]:Lerp(colorsArray[idx + 1], frac)
    end
    return colorsArray[#colorsArray]
end

local function GetHealthColor(percentage)
    return GetColorFromGradient(percentage, HP_COLORS)
end

local function GetDistanceColor(distance)
    local pct = 1 - mathClamp(distance / Settings.Visuals.MaxESPDistance, 0, 1)
    return GetColorFromGradient(pct, DIST_COLORS)
end

local function SpawnDamageNumber(damage, pos3d)
    local dn
    if #DamageObjPool > 0 then
        dn = tableRemove(DamageObjPool)
    else
        dn = { TextObj = SafeDrawingNew("Text"), DamageStr = "", StartPos = Vector3New(), Velocity = Vector3New(), StartTime = 0 }
        dn.TextObj.Center       = true
        dn.TextObj.Outline      = true
        dn.TextObj.OutlineColor = COLOR_BLACK
        dn.TextObj.Font         = 3
    end
    dn.DamageStr = tostring(mathFloor(damage))
    local angle  = mathRandom() * mathPi * 2
    local speed  = mathRandom(15, 30) / 10
    dn.Velocity  = Vector3New(mathCos(angle) * speed, mathRandom(35, 55) / 10, mathSin(angle) * speed)
    dn.StartPos  = pos3d + Vector3New((mathRandom()-0.5), 1.0, (mathRandom()-0.5))
    dn.StartTime = osClock()
    tableInsert(ActiveDamageNumbers, dn)
end

local function UpdateDamageNumbers(visSet, activeCam)
    if not visSet.DamageNumbers and #ActiveDamageNumbers == 0 then return end
    local currentTime = osClock()
    for i = #ActiveDamageNumbers, 1, -1 do
        local dn      = ActiveDamageNumbers[i]
        local elapsed = currentTime - dn.StartTime
        if elapsed >= 1.5 or not visSet.DamageNumbers then
            dn.TextObj.Visible = false
            tableInsert(DamageObjPool, dn)
            tableRemove(ActiveDamageNumbers, i)
        else
            local vel        = dn.Velocity
            local currentPos = dn.StartPos + Vector3New(vel.X*elapsed, (vel.Y*elapsed)-(12.5*elapsed*elapsed), vel.Z*elapsed)
            local screenPos, onScreen = activeCam:WorldToViewportPoint(currentPos)
            if onScreen then
                local size = elapsed < 0.15 and (14+18*(elapsed/0.15))
                    or (elapsed < 0.35 and (32-12*((elapsed-0.15)/0.20)) or 20)
                if dn.TextObj.Text ~= dn.DamageStr then dn.TextObj.Text = dn.DamageStr end
                local v2Pos = Vector2New(screenPos.X, screenPos.Y)
                if dn.TextObj.Position ~= v2Pos then dn.TextObj.Position = v2Pos end
                if dn.TextObj.Size     ~= size   then dn.TextObj.Size     = size   end
                if dn.TextObj.Color    ~= visSet.DamageColor then dn.TextObj.Color = visSet.DamageColor end
                local alpha = elapsed > 1.0 and (1-((elapsed-1.0)*2)) or 1
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
    if TeamCache[player] == nil then
        TeamCache[player] = (player.Team ~= nil and player.Team == LocalPlayer.Team)
    end
    return TeamCache[player]
end

local function UpdateCharCache(player, char)
    if not char then CharCache[player] = nil; return end
    task.spawn(function()
        local hrp  = char:WaitForChild("HumanoidRootPart", 5)
        local head = char:WaitForChild("Head", 5)
        local hum  = char:WaitForChild("Humanoid", 5)
        if not char.Parent or player.Character ~= char then return end
        if hrp and head and hum then
            local cData = CharCache[player] or {}
            cData.Char       = char
            cData.HRP        = hrp
            cData.Head       = head
            cData.Hum        = hum
            cData._onScreen  = false
            cData.VelHistory = {}
            cData._velRing   = {Vector3New(), Vector3New(), Vector3New()}
            cData._velIdx    = 1
            CharCache[player] = cData
        else
            CharCache[player] = nil
        end
    end)
end

local function IsVisible(targetPart, targetChar, camPos)
    if not targetPart or not targetChar then return false end
    local ok, pos = pcall(function() return targetPart.Position end)
    if not ok then return false end
    local direction = pos - camPos
    SharedRayFilter[1] = targetChar
    SharedRayFilter[2] = LocalPlayer.Character
    SharedRayParams.FilterDescendantsInstances = SharedRayFilter
    local result = workspace:Raycast(camPos, direction, SharedRayParams)
    return result == nil
end

local SMART_PRIORITY = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}

local function GetAimPart(cData, aimMode, camPos)
    local char = cData.Char
    if aimMode == "Smart" then
        for _, partName in ipairs(SMART_PRIORITY) do
            local part = char:FindFirstChild(partName)
            if part and IsVisible(part, char, camPos) then return part, true end
        end
        return cData.HRP, false
    elseif aimMode == "Chaos" then
        return char:FindFirstChild(chaosCurrentPart) or cData.HRP, true
    elseif aimMode == "Head" then
        return cData.Head, true
    elseif aimMode == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), true
    elseif aimMode == "Limbs" then
        local la = char:FindFirstChild("LeftUpperArm")  or char:FindFirstChild("Left Arm")
        local ra = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        return (la and ra) and (mathRandom() < 0.5 and la or ra) or (la or ra), true
    else
        return cData.HRP, true
    end
end

local function CustomSort(pool, count, sortByDistance)
    for i = 2, count do
        local key = pool[i]
        local j   = i - 1
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

local function GetClosestPlayer(fovSet, aimSet, refPos, activeCam, camPos)
    local fovSq     = fovSet.Radius * fovSet.Radius
    local myCData   = CharCache[LocalPlayer]
    local myRootPos = myCData and myCData.HRP and myCData.HRP.Position or camPos
    local candCount = 0

    for i = 1, #PlayerCache do
        local player = PlayerCache[i]
        local cData  = CharCache[player]
        if not cData or not cData.Hum or cData.Hum.Health <= 0 then continue end
        if aimSet.TeamCheck and IsTeammateCached(player) then continue end

        local screenPos, onScreen = activeCam:WorldToViewportPoint(cData.HRP.Position)
        if not onScreen then continue end

        local dx, dy    = refPos.X - screenPos.X, refPos.Y - screenPos.Y
        local distToMSq = dx*dx + dy*dy

        if distToMSq <= fovSq then
            local ox = myRootPos.X - cData.HRP.Position.X
            local oy = myRootPos.Y - cData.HRP.Position.Y
            local oz = myRootPos.Z - cData.HRP.Position.Z
            local distToPlayerSq = ox*ox + oy*oy + oz*oz

            candCount = candCount + 1
            if not CandidatePool[candCount] then CandidatePool[candCount] = {} end
            local cand = CandidatePool[candCount]
            cand.player       = player
            cand.cData        = cData
            cand.distToMouse  = distToMSq
            cand.distToPlayer = distToPlayerSq
        end
    end

    for i = candCount + 1, #CandidatePool do CandidatePool[i] = nil end
    if candCount == 0 then return nil end

    CustomSort(CandidatePool, candCount, aimSet.TargetPriority == "Distance")

    local wallCheck = aimSet.WallCheck
    local aimMode   = aimSet.AimMode
    local maxChecks = mathMin(candCount, 3)
    for i = 1, maxChecks do
        local candidate = CandidatePool[i]
        if not wallCheck then return candidate.player end
        local part, visible = GetAimPart(candidate.cData, aimMode, camPos)
        if part and visible then return candidate.player end
    end
    return nil
end

-- ============================================================
--  ESP LIFECYCLE & CACHE REGISTRATION
-- ============================================================
local function CreateESP(player)
    local esp = {
        Box         = SafeDrawingNew("Square"),
        BoxOutline  = SafeDrawingNew("Square"),
        BoxFill     = SafeDrawingNew("Square"),
        CornerLines = {},
        Name        = SafeDrawingNew("Text"),
        Username    = SafeDrawingNew("Text"),
        Distance    = SafeDrawingNew("Text"),
        Health      = SafeDrawingNew("Text"),
        Weapon      = SafeDrawingNew("Text"),
        BarBG       = SafeDrawingNew("Square"),
        BarFG       = SafeDrawingNew("Square"),
        BarOutline  = SafeDrawingNew("Square"),
        ArrowLines  = {},
        Highlight   = nil,
        _isVisible       = false,
        _lastVisible     = false,
        _staggerSlot     = mathRandom(0, 2),
        _trackedHP       = 100,
        _lastFont        = -1,
        _lastTextCase    = "",
        _lastDistStrInt  = -1,
        _lastHPStrInt    = -1,
        _lastWepStr      = "\0",
        _lastNameStr     = "\0",
        _lastUnameStr    = "\0",
        _cachedExtentsY  = 4,
        _cachedExtentsX  = 2,
        _extentsStagger  = mathRandom(0, 5),
    }

    esp.Box.Thickness           = 1.5; esp.BoxOutline.Thickness = 3.5; esp.BoxFill.Thickness = 1
    esp.Box.Filled              = false; esp.BoxOutline.Filled  = false; esp.BoxFill.Filled   = true
    esp.BoxOutline.Transparency = 0.7; esp.BoxOutline.Color     = COLOR_BLACK

    for i = 1, 8 do
        esp.CornerLines[i] = { Main = SafeDrawingNew("Line"), Out = SafeDrawingNew("Line") }
        esp.CornerLines[i].Main.Thickness = 1.5
        esp.CornerLines[i].Out.Thickness  = 3.5
        esp.CornerLines[i].Out.Color      = COLOR_BLACK
        esp.CornerLines[i].Out.Transparency = 0.7
    end

    for i = 1, 4 do
        esp.ArrowLines[i] = SafeDrawingNew("Line")
    end

    for _, txt in ipairs({esp.Name, esp.Username, esp.Distance, esp.Health, esp.Weapon}) do
        txt.Center = true; txt.Outline = true; txt.OutlineColor = COLOR_BLACK
    end

    esp.BarBG.Filled    = true; esp.BarBG.Color    = Color3RGB(15,15,15); esp.BarFG.Filled = true
    esp.BarOutline.Filled = false; esp.BarOutline.Color = COLOR_BLACK; esp.BarOutline.Thickness = 1

    ESPObjects[player] = esp
end

local function HideESP(esp)
    if not esp._lastVisible then return end
    esp.Box.Visible        = false
    esp.BoxOutline.Visible = false
    esp.BoxFill.Visible    = false
    for i = 1, 8 do
        esp.CornerLines[i].Main.Visible = false
        esp.CornerLines[i].Out.Visible  = false
    end
    esp.Name.Visible       = false; esp.Username.Visible = false
    esp.Distance.Visible   = false; esp.Health.Visible   = false; esp.Weapon.Visible    = false
    esp.BarBG.Visible      = false; esp.BarFG.Visible    = false; esp.BarOutline.Visible = false
    for i = 1, 4 do esp.ArrowLines[i].Visible = false end
    if esp.Highlight and esp.Highlight.Enabled then esp.Highlight.Enabled = false end
    esp._lastVisible = false
end

local function DestroyESP(esp)
    pcall(function()
        esp.Box:Remove(); esp.BoxOutline:Remove(); esp.BoxFill:Remove()
        for i = 1, 8 do
            esp.CornerLines[i].Main:Remove()
            esp.CornerLines[i].Out:Remove()
        end
        esp.Name:Remove(); esp.Username:Remove(); esp.Distance:Remove()
        esp.Health:Remove(); esp.Weapon:Remove()
        esp.BarBG:Remove(); esp.BarFG:Remove(); esp.BarOutline:Remove()
        for i = 1, 4 do esp.ArrowLines[i]:Remove() end
        if esp.Highlight then esp.Highlight:Destroy() end
    end)
end

local function RegisterPlayer(player)
    if player == LocalPlayer then return end
    tableInsert(PlayerCache, player)
    CreateESP(player)
    tableInsert(KaimConnections, player:GetPropertyChangedSignal("Team"):Connect(function()
        TeamCache[player] = nil
    end))
    tableInsert(KaimConnections, player.CharacterAdded:Connect(function(c)
        UpdateCharCache(player, c)
    end))
    tableInsert(KaimConnections, player.CharacterRemoving:Connect(function()
        CharCache[player] = nil
        if OriginalHitboxCache[player] then OriginalHitboxCache[player] = nil end
    end))
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
            tableRemove(PlayerCache, i)
            break
        end
    end
    local esp = ESPObjects[player]
    if esp then task.defer(function() DestroyESP(esp) end) end
    ESPObjects[player] = nil
    CharCache[player]  = nil
    TeamCache[player]  = nil
    if TracerLineCache[player] then TracerLineCache[player]:Remove(); TracerLineCache[player] = nil end
    if LookTracerCache[player] then LookTracerCache[player]:Remove(); LookTracerCache[player] = nil end
    if OriginalHitboxCache[player] then OriginalHitboxCache[player] = nil end
end))

tableInsert(KaimConnections, LocalPlayer.CharacterAdded:Connect(function(c)
    UpdateCharCache(LocalPlayer, c)
    if Settings.Player.NoclipEnabled then
        task.defer(function()
            if _G._KaimBuildNoclipCache then _G._KaimBuildNoclipCache(c) end
        end)
    end
end))
if LocalPlayer.Character then UpdateCharCache(LocalPlayer, LocalPlayer.Character) end

-- ============================================================
--  CORE UPDATE MODULES
-- ============================================================
local function UpdateFOV(centerPoint, fovSet)
    local fovPos      = fovSet.FollowCursor and UserInputService:GetMouseLocation() or centerPoint
    local pulseOffset = fovSet.Pulse and (mathSin(osClock() * 4) * 5) or 0
    local rad         = mathMax(1, fovSet.Radius + pulseOffset)

    UpdateDraw(FOVRing, {Position = fovPos, Radius = rad, Color = fovSet.Color, Transparency = fovSet.Transparency, Visible = fovSet.Visible})
    local fillVis = fovSet.Visible and fovSet.Filled
    UpdateDraw(FOVFill, {Position = fovPos, Radius = rad, Color = fovSet.FilledColor, Transparency = fovSet.FilledTransp, Visible = fillVis})

    return fovPos
end

local function HideTHUD()
    if not _hudLastVisible then return end
    UpdateDraw(THUD.Shadow,  {Visible = false})
    UpdateDraw(THUD.BG,      {Visible = false})
    UpdateDraw(THUD.Outline, {Visible = false})
    UpdateDraw(THUD.Accent,  {Visible = false})
    UpdateDraw(THUD.Accent2, {Visible = false})
    UpdateDraw(THUD.Name,    {Visible = false})
    UpdateDraw(THUD.Data,    {Visible = false})
    UpdateDraw(THUD.BarBG,   {Visible = false})
    UpdateDraw(THUD.BarFG,   {Visible = false})
    _hudLastVisible = false
end

local function UpdateAimlock(camPos, screenWidth, screenHeight, deltaTime, aimSet, avoidSet, visSet, fovSet, fovPos, activeCam)
    if avoidSet.PeriodicAimDisable and aimSet.Enabled then
        periodicDisableTimer = periodicDisableTimer - deltaTime
        if periodicDisableTimer <= 0 then
            aimSet.PeriodicDisable = (mathRandom() < avoidSet.DisableChance)
            periodicDisableTimer   = avoidSet.DisableDuration + (mathRandom() * 0.4)
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
            local curTar   = aimSet.CurrentTarget
            local curCData = curTar and CharCache[curTar]
            if not curCData or not curCData.Hum or curCData.Hum.Health <= 0 then
                local now = osClock()
                if now - aimSet._lastTargetSearch > 0.06 then
                    aimSet.CurrentTarget     = GetClosestPlayer(fovSet, aimSet, fovPos, activeCam, camPos)
                    aimSet._lastTargetSearch = now
                end
            end
        end

        local target = aimSet.CurrentTarget
        local cData  = target and CharCache[target]

        if cData then
            local targetPart, lockIsVisible = GetAimPart(cData, aimSet.AimMode, camPos)

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
                        predictionTime = predictionTime + (dist / (aimSet.ProjectileSpeed or 1000))
                    end

                    local accel = cData.Acceleration or VEC3_ZERO
                    local jerk  = cData.Jerk         or VEC3_ZERO
                    local t     = predictionTime
                    local t2    = t * t

                    local predOffset = (velocity * aimSet.StrafePrediction * t) + (0.5 * accel * t2)
                    if aimSet.JerkPrediction then
                        predOffset = predOffset + (0.1666 * jerk * t2 * t)
                    end
                    if aimSet.BulletDropCompensation then
                        local gravity = aimSet.BulletGravity or workspace.Gravity
                        predOffset    = predOffset + Vector3New(0, 0.5 * gravity * t2, 0)
                    end

                    aimPos = aimPos + predOffset
                end

                aimPos = aimPos + Vector3New(aimSet.OffsetX, aimSet.OffsetY, aimSet.OffsetZ)

                if aimSet.PerlinNoise then
                    local timeTick = osClock() * aimSet.NoiseSpeed
                    aimPos = aimPos + Vector3New(
                        mathNoise(timeTick, 0, 0) * aimSet.NoiseAmount,
                        mathNoise(0, timeTick, 0) * aimSet.NoiseAmount,
                        mathNoise(0, 0, timeTick) * aimSet.NoiseAmount
                    )
                end

                local targetCFrame = CFrameNew(camPos, aimPos)
                if aimSet.SmoothAiming then
                    local smoothFactor = aimSet.SmoothSpeed
                    if aimSet.DynamicSmoothing then
                        local screenAimPos, onScreen = activeCam:WorldToViewportPoint(aimPos)
                        if onScreen then
                            local mousePos = UserInputService:GetMouseLocation()
                            local dx, dy   = screenAimPos.X - mousePos.X, screenAimPos.Y - mousePos.Y
                            smoothFactor   = smoothFactor * mathClamp(mathSqrt(dx*dx+dy*dy) / 200, 0.1, 1.0)
                        end
                    end
                    if smoothFactor < 1 then
                        local decayRate    = smoothFactor * 25
                        local humanizeDamp = aimSet.HumanizeSmoothing and (mathNoise(osClock()*10)*0.05) or 0
                        smoothFactor = mathClamp(1 - mathExp(-(decayRate + humanizeDamp) * deltaTime), 0.01, 1)
                    end
                    activeCam.CFrame = activeCam.CFrame:Lerp(targetCFrame, smoothFactor)
                else
                    activeCam.CFrame = targetCFrame
                end

                if visSet.TargetUI then
                    showHUD = true
                    local scale       = visSet.TargetUIScale
                    local style       = visSet.TargetUIStyle
                    local accentColor = lockIsVisible and COLOR_WHITE or COLOR_RED

                    local actualHP = cData.Hum.Health or 0
                    thudLerpedHP   = thudLerpedHP + (actualHP - thudLerpedHP) * (deltaTime * 10)
                    if thudLerpedHP ~= thudLerpedHP or thudLerpedHP < 0 then thudLerpedHP = 0 end
                    local hpPct = mathClamp(thudLerpedHP / mathMax(1, cData.Hum.MaxHealth or 100), 0, 1)

                    local distInt = 0
                    local myCData = CharCache[LocalPlayer]
                    if myCData and myCData.HRP then
                        distInt = mathFloor((myCData.HRP.Position - cData.HRP.Position).Magnitude)
                    end

                    local rawName = target.DisplayName
                    local rawData = "HP: " .. mathFloor(actualHP) .. "  |  Dist: " .. distInt .. "m"
                    if aimSet.AimMode == "Chaos" then rawData = rawData .. "  |  ⚡ " .. chaosCurrentPart end

                    if thudLastNameCache ~= rawName then
                        thudLastNameCache = rawName
                        THUD.Name.Text    = FormatText(rawName, visSet.TextCase)
                    end
                    if thudLastTextCache ~= rawData then
                        thudLastTextCache = rawData
                        THUD.Data.Text    = FormatText(rawData, visSet.TextCase)
                    end

                    thudAlpha = mathClamp(thudAlpha + (deltaTime * 7), 0, 1)
                    local easeAlpha    = 1 - mathExp(-thudAlpha * 5)
                    local ySlideOffset = (1 - easeAlpha) * 35

                    UpdateDraw(THUD.Shadow,  {Visible = false})
                    UpdateDraw(THUD.Outline, {Visible = false})
                    UpdateDraw(THUD.BG,      {Visible = false})
                    UpdateDraw(THUD.Accent2, {Visible = false})
                    UpdateDraw(THUD.BarBG,   {Visible = false})
                    UpdateDraw(THUD.BarFG,   {Visible = false})
                    UpdateDraw(THUD.Name, {Outline = true, Center = false})
                    UpdateDraw(THUD.Data, {Outline = true, Center = false})

                    if style == "Valorant" then
                        local boxW = mathFloor(280*scale); local boxH = mathFloor(45*scale)
                        local hudX = (screenWidth/2)-(boxW/2)
                        local hudY = mathFloor(screenHeight*0.08) - ySlideOffset
                        UpdateDraw(THUD.BG,     {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Transparency=0.85*easeAlpha, Color=COLOR_HUD_VAL})
                        UpdateDraw(THUD.Accent, {Size=Vector2New(boxW,mathMax(1,mathFloor(2*scale))), Position=Vector2New(hudX,hudY+boxH), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.Name,   {Size=mathMax(10,mathFloor(17*scale)), Position=Vector2New(hudX+mathFloor(12*scale),hudY+mathFloor(6*scale)), Transparency=easeAlpha})
                        UpdateDraw(THUD.Data,   {Size=mathMax(10,mathFloor(12*scale)), Position=Vector2New(hudX+mathFloor(12*scale),hudY+mathFloor(24*scale)), Transparency=easeAlpha})
                        local barW=boxW; local barH=mathMax(1,mathFloor(3*scale)); local barY=hudY+boxH+mathFloor(2*scale)
                        UpdateDraw(THUD.BarBG, {Visible=true, Size=Vector2New(barW,barH), Position=Vector2New(hudX,barY), Transparency=easeAlpha, Color=COLOR_BLACK})
                        UpdateDraw(THUD.BarFG, {Visible=true, Size=Vector2New(barW*hpPct,barH), Position=Vector2New(hudX,barY), Color=GetHealthColor(hpPct), Transparency=easeAlpha})

                    elseif style == "Standard" then
                        local calculatedWidth = mathMax(200, 40+stringLen(thudLastNameCache)*9)
                        local boxW=mathFloor(calculatedWidth*scale); local boxH=mathFloor(56*scale)
                        local hudX=(screenWidth/2)-(boxW/2); local hudY=(screenHeight-mathFloor(140*scale))+ySlideOffset
                        UpdateDraw(THUD.Shadow,  {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX+3,hudY+3), Transparency=0.5*easeAlpha})
                        UpdateDraw(THUD.BG,      {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Transparency=0.85*easeAlpha, Color=COLOR_HUD_BG})
                        UpdateDraw(THUD.Outline, {Visible=true, Size=Vector2New(boxW+2,boxH+2), Position=Vector2New(hudX-1,hudY-1), Transparency=easeAlpha})
                        UpdateDraw(THUD.Accent,  {Size=Vector2New(boxW,mathMax(1,mathFloor(2*scale))), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.Name,    {Size=mathMax(10,mathFloor(16*scale)), Position=Vector2New(hudX+mathFloor(10*scale),hudY+mathFloor(8*scale)), Transparency=easeAlpha})
                        UpdateDraw(THUD.Data,    {Size=mathMax(10,mathFloor(13*scale)), Position=Vector2New(hudX+mathFloor(10*scale),hudY+mathFloor(28*scale)), Transparency=easeAlpha})
                        local barW=boxW-mathFloor(20*scale); local barH=mathMax(1,mathFloor(3*scale)); local barY=hudY+mathFloor(46*scale)
                        UpdateDraw(THUD.BarBG, {Visible=true, Size=Vector2New(barW,barH), Position=Vector2New(hudX+mathFloor(10*scale),barY), Transparency=easeAlpha})
                        UpdateDraw(THUD.BarFG, {Visible=true, Size=Vector2New(barW*hpPct,barH), Position=Vector2New(hudX+mathFloor(10*scale),barY), Color=GetHealthColor(hpPct), Transparency=easeAlpha})

                    elseif style == "Ascension" then
                        local boxW=mathFloor(260*scale); local boxH=mathFloor(50*scale)
                        local hudX=(screenWidth/2)-(boxW/2); local hudY=mathFloor(screenHeight*0.12)-ySlideOffset
                        UpdateDraw(THUD.Shadow,  {Visible=true, Size=Vector2New(boxW+6,boxH+6), Position=Vector2New(hudX-3,hudY-3), Transparency=0.3*easeAlpha, Color=accentColor})
                        UpdateDraw(THUD.BG,      {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Transparency=0.9*easeAlpha, Color=Color3RGB(5,5,10)})
                        UpdateDraw(THUD.Outline, {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=0.7*easeAlpha})
                        local glitchOff = mathRandom(-2,2)*scale
                        UpdateDraw(THUD.Accent,  {Size=Vector2New(mathMax(1,mathFloor(3*scale)),boxH), Position=Vector2New(hudX+glitchOff,hudY), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.Name,    {Size=mathMax(10,mathFloor(18*scale)), Position=Vector2New(hudX+mathFloor(15*scale),hudY+mathFloor(6*scale)), Transparency=easeAlpha})
                        UpdateDraw(THUD.Data,    {Size=mathMax(10,mathFloor(11*scale)), Position=Vector2New(hudX+mathFloor(15*scale),hudY+mathFloor(26*scale)), Transparency=0.8*easeAlpha})
                        local barW=boxW-mathFloor(30*scale); local barH=mathMax(1,mathFloor(2*scale)); local barY=hudY+boxH-mathFloor(8*scale)
                        UpdateDraw(THUD.BarBG, {Visible=true, Size=Vector2New(barW,barH), Position=Vector2New(hudX+mathFloor(15*scale),barY), Transparency=0.5*easeAlpha, Color=COLOR_BLACK})
                        UpdateDraw(THUD.BarFG, {Visible=true, Size=Vector2New(barW*hpPct,barH), Position=Vector2New(hudX+mathFloor(15*scale),barY), Color=GetHealthColor(hpPct), Transparency=easeAlpha})

                    elseif style == "Cyber" then
                        local calculatedWidth = mathMax(220, 50+stringLen(thudLastNameCache)*9)
                        local boxW=mathFloor(calculatedWidth*scale); local boxH=mathFloor(48*scale)
                        local hudX=(screenWidth/2)-(boxW/2); local hudY=(screenHeight-mathFloor(150*scale))+ySlideOffset
                        UpdateDraw(THUD.BG,     {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Transparency=0.7*easeAlpha, Color=COLOR_HUD_BG})
                        UpdateDraw(THUD.Accent, {Size=Vector2New(mathMax(2,mathFloor(6*scale)),boxH), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.Accent2,{Visible=true, Size=Vector2New(boxW,mathMax(1,mathFloor(2*scale))), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=0.5*easeAlpha})
                        UpdateDraw(THUD.Name,   {Size=mathMax(10,mathFloor(17*scale)), Position=Vector2New(hudX+mathFloor(16*scale),hudY+mathFloor(8*scale)), Text="["..FormatText(thudLastNameCache,visSet.TextCase).."]", Transparency=easeAlpha})
                        UpdateDraw(THUD.Data,   {Size=mathMax(10,mathFloor(11*scale)), Position=Vector2New(hudX+mathFloor(16*scale),hudY+mathFloor(28*scale)), Transparency=easeAlpha})

                    elseif style == "Minimal" then
                        local hudX=(screenWidth/2)-mathFloor(100*scale)
                        local hudY=(screenHeight-mathFloor(130*scale))+ySlideOffset
                        UpdateDraw(THUD.Accent, {Size=Vector2New(mathMax(1,mathFloor(3*scale)),mathFloor(36*scale)), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.Name,   {Size=mathMax(10,mathFloor(16*scale)), Position=Vector2New(hudX+mathFloor(10*scale),hudY), Transparency=easeAlpha})
                        UpdateDraw(THUD.Data,   {Size=mathMax(10,mathFloor(13*scale)), Position=Vector2New(hudX+mathFloor(10*scale),hudY+mathFloor(20*scale)), Transparency=easeAlpha})

                    elseif style == "Tech" then
                        local calculatedWidth = mathMax(200, 40+stringLen(thudLastNameCache)*9)
                        local boxW=mathFloor(calculatedWidth*scale); local boxH=mathFloor(56*scale)
                        local hudX=(screenWidth/2)-(boxW/2); local hudY=(screenHeight-mathFloor(140*scale))+ySlideOffset
                        UpdateDraw(THUD.Outline,{Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.BG,     {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Transparency=0.5*easeAlpha, Color=COLOR_HUD_BG})
                        UpdateDraw(THUD.Accent, {Size=Vector2New(boxW,mathMax(1,mathFloor(2*scale))), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.Name,   {Size=mathMax(10,mathFloor(16*scale)), Position=Vector2New(hudX+mathFloor(10*scale),hudY+mathFloor(8*scale)), Transparency=easeAlpha})
                        UpdateDraw(THUD.Data,   {Size=mathMax(10,mathFloor(13*scale)), Position=Vector2New(hudX+mathFloor(10*scale),hudY+mathFloor(28*scale)), Transparency=easeAlpha})

                    elseif style == "Apex" then
                        local boxW=mathFloor(220*scale); local boxH=mathFloor(45*scale)
                        local hudX=(screenWidth/2)-(boxW/2); local hudY=(screenHeight-mathFloor(120*scale))+ySlideOffset
                        UpdateDraw(THUD.BG,     {Visible=true, Size=Vector2New(boxW,boxH), Position=Vector2New(hudX,hudY), Transparency=0.6*easeAlpha, Color=COLOR_HUD_BG})
                        UpdateDraw(THUD.Accent, {Size=Vector2New(mathMax(1,mathFloor(4*scale)),boxH), Position=Vector2New(hudX,hudY), Color=accentColor, Transparency=easeAlpha})
                        UpdateDraw(THUD.Name,   {Size=mathMax(10,mathFloor(15*scale)), Position=Vector2New(hudX+mathFloor(12*scale),hudY+mathFloor(6*scale)), Transparency=easeAlpha})
                        UpdateDraw(THUD.Data,   {Size=mathMax(10,mathFloor(11*scale)), Position=Vector2New(hudX+mathFloor(12*scale),hudY+mathFloor(24*scale)), Transparency=easeAlpha})
                        local barW=boxW; local barH=mathMax(1,mathFloor(3*scale)); local barY=hudY+boxH
                        UpdateDraw(THUD.BarBG, {Visible=true, Size=Vector2New(barW,barH), Position=Vector2New(hudX,barY), Transparency=easeAlpha})
                        UpdateDraw(THUD.BarFG, {Visible=true, Size=Vector2New(barW*hpPct,barH), Position=Vector2New(hudX,barY), Color=GetHealthColor(hpPct), Transparency=easeAlpha})
                    end

                    UpdateDraw(THUD.Accent, {Visible = true})
                    UpdateDraw(THUD.Name,   {Visible = true})
                    UpdateDraw(THUD.Data,   {Visible = true})
                    _hudLastVisible = true
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
            HideTHUD()
        else
            local easeAlpha = 1 - mathExp(-thudAlpha * 5)
            UpdateDraw(THUD.Shadow,  {Transparency = 0.5 * easeAlpha})
            UpdateDraw(THUD.BG,      {Transparency = 0.85 * easeAlpha})
            UpdateDraw(THUD.Outline, {Transparency = easeAlpha})
            UpdateDraw(THUD.Accent,  {Transparency = easeAlpha})
            UpdateDraw(THUD.Name,    {Transparency = easeAlpha})
            UpdateDraw(THUD.Data,    {Transparency = easeAlpha})
            UpdateDraw(THUD.BarBG,   {Transparency = easeAlpha})
            UpdateDraw(THUD.BarFG,   {Transparency = easeAlpha})
        end
    end
end

local function DrawCornerBox(esp, x, y, w, h, col, doOutline, thickness)
    local lineLength = mathFloor(w / 3)
    UpdateDraw(esp.CornerLines[1].Main, {From=Vector2New(x,y),       To=Vector2New(x+lineLength,y),          Color=col, Thickness=thickness, Visible=true})
    UpdateDraw(esp.CornerLines[2].Main, {From=Vector2New(x,y),       To=Vector2New(x,y+lineLength),          Color=col, Thickness=thickness, Visible=true})
    UpdateDraw(esp.CornerLines[3].Main, {From=Vector2New(x+w,y),     To=Vector2New(x+w-lineLength,y),        Color=col, Thickness=thickness, Visible=true})
    UpdateDraw(esp.CornerLines[4].Main, {From=Vector2New(x+w,y),     To=Vector2New(x+w,y+lineLength),        Color=col, Thickness=thickness, Visible=true})
    UpdateDraw(esp.CornerLines[5].Main, {From=Vector2New(x,y+h),     To=Vector2New(x+lineLength,y+h),        Color=col, Thickness=thickness, Visible=true})
    UpdateDraw(esp.CornerLines[6].Main, {From=Vector2New(x,y+h),     To=Vector2New(x,y+h-lineLength),        Color=col, Thickness=thickness, Visible=true})
    UpdateDraw(esp.CornerLines[7].Main, {From=Vector2New(x+w,y+h),   To=Vector2New(x+w-lineLength,y+h),      Color=col, Thickness=thickness, Visible=true})
    UpdateDraw(esp.CornerLines[8].Main, {From=Vector2New(x+w,y+h),   To=Vector2New(x+w,y+h-lineLength),      Color=col, Thickness=thickness, Visible=true})

    if doOutline then
        local oT = thickness + 2
        UpdateDraw(esp.CornerLines[1].Out, {From=Vector2New(x-1,y-1),     To=Vector2New(x+lineLength+1,y-1),    Thickness=oT, Visible=true})
        UpdateDraw(esp.CornerLines[2].Out, {From=Vector2New(x-1,y-1),     To=Vector2New(x-1,y+lineLength+1),    Thickness=oT, Visible=true})
        UpdateDraw(esp.CornerLines[3].Out, {From=Vector2New(x+w+1,y-1),   To=Vector2New(x+w-lineLength-1,y-1),  Thickness=oT, Visible=true})
        UpdateDraw(esp.CornerLines[4].Out, {From=Vector2New(x+w+1,y-1),   To=Vector2New(x+w+1,y+lineLength+1),  Thickness=oT, Visible=true})
        UpdateDraw(esp.CornerLines[5].Out, {From=Vector2New(x-1,y+h+1),   To=Vector2New(x+lineLength+1,y+h+1),  Thickness=oT, Visible=true})
        UpdateDraw(esp.CornerLines[6].Out, {From=Vector2New(x-1,y+h+1),   To=Vector2New(x-1,y+h-lineLength-1),  Thickness=oT, Visible=true})
        UpdateDraw(esp.CornerLines[7].Out, {From=Vector2New(x+w+1,y+h+1), To=Vector2New(x+w-lineLength-1,y+h+1),Thickness=oT, Visible=true})
        UpdateDraw(esp.CornerLines[8].Out, {From=Vector2New(x+w+1,y+h+1), To=Vector2New(x+w+1,y+h-lineLength-1),Thickness=oT, Visible=true})
    else
        for i = 1, 8 do UpdateDraw(esp.CornerLines[i].Out, {Visible = false}) end
    end
end

local function UpdateESP(camPos, screenWidth, screenHeight, visSet, activeCam)
    local espEnabled  = visSet.ESPEnabled
    local chamsEnabled = visSet.ChamsEnabled
    local maxDistSq   = visSet.MaxESPDistance * visSet.MaxESPDistance
    local lodDistSq   = (visSet.LODDistance or 500) * (visSet.LODDistance or 500)
    local teamCheck   = visSet.TeamCheck
    local showTM      = visSet.ShowTeammates
    local useVisColor = visSet.UseVisColors
    local dmgNums     = visSet.DamageNumbers
    local arrows      = visSet.OffScreenArrows
    local tracers     = visSet.TracerLines
    local lookTrc     = visSet.LookTracers
    local boxes       = visSet.ESPBoxes
    local textCase    = visSet.TextCase
    local boxStyle    = visSet.ESPBoxStyle
    local frameSkip   = Settings.Performance.FrameSkip
    local maxPerFrame = Settings.Performance.MaxESPPerFrame

    local center = Vector2New(screenWidth*0.5, screenHeight*0.5)
    local tracerOriginY
    if visSet.TracerOrigin == "Bottom" then
        tracerOriginY = screenHeight
    elseif visSet.TracerOrigin == "Top" then
        tracerOriginY = 0
    else
        tracerOriginY = screenHeight * 0.5
    end
    local tracerStartPos = Vector2New(screenWidth*0.5, tracerOriginY)

    local processed = 0
    for i = 1, #PlayerCache do
        if frameSkip and processed >= maxPerFrame and _avgDeltaTime > 0.02 then
            continue
        end

        local player = PlayerCache[i]
        local esp    = ESPObjects[player]
        if not esp then continue end

        local cData = CharCache[player]
        local hrpValid = false
        if cData and cData.HRP then
            local pOk, pRes = pcall(function() return cData.HRP.Parent end)
            hrpValid = pOk and pRes ~= nil
        end
        if not cData or not hrpValid or not cData.Hum or cData.Hum.Health <= 0 then
            HideESP(esp)
            if TracerLineCache[player] and TracerLineCache[player].Visible then TracerLineCache[player].Visible = false end
            if LookTracerCache[player] and LookTracerCache[player].Visible then LookTracerCache[player].Visible = false end
            continue
        end

        local isTeammate = IsTeammateCached(player)
        if teamCheck and isTeammate and not showTM then HideESP(esp); continue end

        processed = processed + 1

        local myCData   = CharCache[LocalPlayer]
        local myRootPos = (myCData and myCData.HRP) and myCData.HRP.Position or camPos

        local hrpPos = cData.HRP.Position
        local dx = hrpPos.X - myRootPos.X
        local dy = hrpPos.Y - myRootPos.Y
        local dz = hrpPos.Z - myRootPos.Z
        local distSq = dx*dx + dy*dy + dz*dz

        if distSq > maxDistSq then HideESP(esp); continue end

        local dist  = mathSqrt(distSq)
        local isLOD = distSq > lodDistSq

        local rootScreenPos, onScreen = activeCam:WorldToViewportPoint(hrpPos)
        local depth = rootScreenPos.Z

        local needsVisRaycast = (not isLOD) and ((espEnabled and useVisColor) or (chamsEnabled and visSet.ChamsUseVisColors))
        if needsVisRaycast and onScreen then
            if esp._staggerSlot == (FRAME_COUNT_RS % DYNAMIC_STAGGER) then
                esp._isVisible = IsVisible(cData.HRP, cData.Char, camPos)
            end
        else
            esp._isVisible = true
        end

        local finalColor = (isTeammate and showTM) and visSet.TeammateColor
            or (useVisColor and (esp._isVisible and visSet.VisColor or visSet.HiddenColor) or visSet.StaticBoxColor)

        if chamsEnabled and not isLOD then
            if not esp.Highlight then
                esp.Highlight = Instance.new("Highlight")
                esp.Highlight.Parent = ChamsFolder
            end
            if esp.Highlight.Adornee ~= cData.Char then
                esp.Highlight.Adornee = cData.Char
                esp.Highlight.Enabled = true
            end
            local fC = visSet.ChamsUseVisColors and (esp._isVisible and visSet.VisColor or visSet.HiddenColor) or visSet.ChamsFillColor
            if esp.Highlight.FillColor            ~= fC                       then esp.Highlight.FillColor            = fC end
            if esp.Highlight.OutlineColor         ~= visSet.ChamsOutlineColor then esp.Highlight.OutlineColor         = visSet.ChamsOutlineColor end
            if esp.Highlight.FillTransparency     ~= visSet.ChamsFillTrans    then esp.Highlight.FillTransparency     = visSet.ChamsFillTrans end
            if esp.Highlight.OutlineTransparency  ~= visSet.ChamsOutlineTrans then esp.Highlight.OutlineTransparency  = visSet.ChamsOutlineTrans end
        else
            if esp.Highlight and esp.Highlight.Enabled then
                esp.Highlight.Enabled = false
                esp.Highlight.Adornee = nil
            end
        end

        if not isLOD and cData.Hum.Health ~= esp._trackedHP then
            local diff = esp._trackedHP - cData.Hum.Health
            if diff > 0.5 and dmgNums then SpawnDamageNumber(diff, cData.Head.Position) end
            esp._trackedHP = cData.Hum.Health
        end

        if arrows and not isLOD and (not onScreen or depth <= 0) then
            local relativePos = activeCam.CFrame:PointToObjectSpace(cData.HRP.Position)
            local angle       = mathAtan2(relativePos.X, -relativePos.Z)
            local sA          = mathSin(angle);      local cA  = mathCos(angle)
            local sAm         = mathSin(angle-PI_OVER_4); local cAm = mathCos(angle-PI_OVER_4)
            local sAp         = mathSin(angle+PI_OVER_4); local cAp = mathCos(angle+PI_OVER_4)
            local radius      = visSet.ArrowRadius
            local size        = visSet.ArrowSize
            local ac          = center + Vector2New(sA*radius, -cA*radius)
            local p1 = ac + Vector2New(sA*size,      -cA*size)
            local p2 = ac + Vector2New(sAm*size*0.75, -cAm*size*0.75)
            local p3 = ac + Vector2New(sA*size*0.3,   -cA*size*0.3)
            local p4 = ac + Vector2New(sAp*size*0.75, -cAp*size*0.75)
            UpdateDraw(esp.ArrowLines[1], {From=p1, To=p2, Color=visSet.ArrowColor, Visible=true})
            UpdateDraw(esp.ArrowLines[2], {From=p2, To=p3, Color=visSet.ArrowColor, Visible=true})
            UpdateDraw(esp.ArrowLines[3], {From=p3, To=p4, Color=visSet.ArrowColor, Visible=true})
            UpdateDraw(esp.ArrowLines[4], {From=p4, To=p1, Color=visSet.ArrowColor, Visible=true})
        else
            if esp.ArrowLines[1].Visible then
                for i=1,4 do UpdateDraw(esp.ArrowLines[i], {Visible=false}) end
            end
        end

        if tracers and not isLOD and depth > 0 then
            if not TracerLineCache[player] then
                TracerLineCache[player] = SafeDrawingNew("Line")
                TracerLineCache[player].Thickness = 1.5
            end
            UpdateDraw(TracerLineCache[player], {Color=visSet.TracerColor, From=tracerStartPos, To=Vector2New(rootScreenPos.X,rootScreenPos.Y), Visible=onScreen})
        elseif TracerLineCache[player] and TracerLineCache[player].Visible then
            TracerLineCache[player].Visible = false
        end

        if lookTrc and not isLOD and depth > 0 then
            if not LookTracerCache[player] then
                LookTracerCache[player] = SafeDrawingNew("Line")
                LookTracerCache[player].Thickness = 1.5
            end
            local lookPos3D = cData.Head.Position + (cData.Head.CFrame.LookVector * visSet.LookTracerLength)
            local headSP    = activeCam:WorldToViewportPoint(cData.Head.Position)
            local lookSP, lookOnScreen = activeCam:WorldToViewportPoint(lookPos3D)
            if lookOnScreen then
                UpdateDraw(LookTracerCache[player], {From=Vector2New(headSP.X,headSP.Y), To=Vector2New(lookSP.X,lookSP.Y), Color=visSet.LookTracerColor, Visible=true})
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

        if not espEnabled or not onScreen or depth <= 0 then HideESP(esp); continue end

        esp._lastVisible = true

        if esp._extentsStagger == (FRAME_COUNT_RS % 6) then
            local extents = cData.Char:GetExtentsSize()
            esp._cachedExtentsY = extents.Y
            esp._cachedExtentsX = extents.X
        end

        local eY = esp._cachedExtentsY
        local eX = esp._cachedExtentsX
        local headSP2 = activeCam:WorldToViewportPoint(cData.HRP.Position + Vector3New(0,eY/2,0))
        local legSP   = activeCam:WorldToViewportPoint(cData.HRP.Position - Vector3New(0,eY/2,0))
        local boxHeight = mathAbs(headSP2.Y - legSP.Y)
        local rightPos  = cData.HRP.Position + (activeCam.CFrame.RightVector * (eX/2))
        local rightSP   = activeCam:WorldToViewportPoint(rightPos)
        local boxWidth  = mathAbs(rootScreenPos.X - rightSP.X) * 2
        local xPosition = rootScreenPos.X - (boxWidth*0.5)
        local yPosition = headSP2.Y

        if boxes then
            if boxStyle == "Standard" then
                UpdateDraw(esp.Box, {Visible=true, Size=Vector2New(boxWidth,boxHeight), Position=Vector2New(xPosition,yPosition), Color=finalColor, Thickness=dThick})
                if visSet.ESPOutline then
                    UpdateDraw(esp.BoxOutline, {Visible=true, Size=Vector2New(boxWidth+3,boxHeight+3), Position=Vector2New(xPosition-1.5,yPosition-1.5), Thickness=dThick+2})
                else
                    UpdateDraw(esp.BoxOutline, {Visible=false})
                end
                for i=1,8 do UpdateDraw(esp.CornerLines[i].Main,{Visible=false}); UpdateDraw(esp.CornerLines[i].Out,{Visible=false}) end
            else
                UpdateDraw(esp.Box,{Visible=false}); UpdateDraw(esp.BoxOutline,{Visible=false})
                DrawCornerBox(esp, xPosition, yPosition, boxWidth, boxHeight, finalColor, visSet.ESPOutline, dThick)
            end
            if visSet.ESPBoxFill then
                UpdateDraw(esp.BoxFill, {Visible=true, Size=Vector2New(boxWidth,boxHeight), Position=Vector2New(xPosition,yPosition), Color=finalColor, Transparency=visSet.ESPBoxFillTrans})
            else
                UpdateDraw(esp.BoxFill, {Visible=false})
            end
        else
            UpdateDraw(esp.Box,{Visible=false}); UpdateDraw(esp.BoxOutline,{Visible=false}); UpdateDraw(esp.BoxFill,{Visible=false})
            for i=1,8 do UpdateDraw(esp.CornerLines[i].Main,{Visible=false}); UpdateDraw(esp.CornerLines[i].Out,{Visible=false}) end
        end

        local healthPercentage = mathClamp(cData.Hum.Health / mathMax(1, cData.Hum.MaxHealth or 100), 0, 1)

        if visSet.HealthBar then
            local fillHeight = mathMax(1, boxHeight * healthPercentage)
            UpdateDraw(esp.BarBG,     {Visible=true, Size=Vector2New(4,boxHeight+2), Position=Vector2New(xPosition-7,yPosition-1)})
            UpdateDraw(esp.BarOutline,{Visible=true, Size=Vector2New(6,boxHeight+4), Position=Vector2New(xPosition-8,yPosition-2)})
            UpdateDraw(esp.BarFG,     {Visible=true, Size=Vector2New(2,fillHeight), Position=Vector2New(xPosition-6,yPosition+boxHeight-fillHeight), Color=GetHealthColor(healthPercentage)})
        else
            UpdateDraw(esp.BarBG,{Visible=false}); UpdateDraw(esp.BarFG,{Visible=false}); UpdateDraw(esp.BarOutline,{Visible=false})
        end

        if esp._lastFont ~= visSet.ESPFont then
            esp._lastFont = visSet.ESPFont
            for _, txt in ipairs({esp.Name, esp.Username, esp.Distance, esp.Health, esp.Weapon}) do
                txt.Font = visSet.ESPFont
            end
        end

        local textYTop    = yPosition - visSet.ESPTextScale - 4
        local textYBottom = yPosition + boxHeight + 4
        local nameColor   = visSet.UseCustomNameColor and visSet.ESPNameColor or finalColor

        if esp._lastTextCase ~= textCase then
            esp._lastTextCase   = textCase
            esp._lastDistStrInt = -1
            esp._lastHPStrInt   = -1
            esp._lastWepStr     = "\0"
            esp._lastNameStr    = "\0"
            esp._lastUnameStr   = "\0"
        end

        if visSet.ESPNames then
            if visSet.ESPNameStyle == "Display Name" or visSet.ESPNameStyle == "Both" then
                local dName = player.DisplayName
                if esp._lastNameStr ~= dName then
                    esp._lastNameStr = dName
                    esp.Name.Text    = FormatText(dName, textCase)
                end
                UpdateDraw(esp.Name, {Visible=true, Position=Vector2New(rootScreenPos.X,textYTop), Color=nameColor, Size=visSet.ESPTextScale})
                if visSet.ESPNameStyle == "Both" then textYTop = textYTop - (visSet.ESPTextScale-2) end
            else
                UpdateDraw(esp.Name, {Visible=false})
            end
            if visSet.ESPNameStyle == "Username" or visSet.ESPNameStyle == "Both" then
                local uName = "@" .. player.Name
                if esp._lastUnameStr ~= uName then
                    esp._lastUnameStr = uName
                    esp.Username.Text = FormatText(uName, textCase)
                end
                UpdateDraw(esp.Username, {Visible=true, Position=Vector2New(rootScreenPos.X,textYTop), Color=visSet.UseCustomNameColor and visSet.ESPUsernameColor or finalColor, Size=mathMax(10,visSet.ESPTextScale-2)})
            else
                UpdateDraw(esp.Username, {Visible=false})
            end
        else
            UpdateDraw(esp.Name,{Visible=false}); UpdateDraw(esp.Username,{Visible=false})
        end

        if visSet.DistanceDisplay then
            local dSize    = mathMax(10, visSet.ESPTextScale-2)
            local trueDist = mathFloor(dist)
            if esp._lastDistStrInt ~= trueDist then
                esp.Distance.Text   = FormatText(trueDist.."m", textCase)
                esp.Distance.Color  = GetDistanceColor(trueDist)
                esp._lastDistStrInt = trueDist
            end
            UpdateDraw(esp.Distance, {Visible=true, Position=Vector2New(rootScreenPos.X,textYBottom), Size=dSize})
            textYBottom = textYBottom + dSize + 2
        else
            UpdateDraw(esp.Distance, {Visible=false})
        end

        if visSet.HealthNumbers then
            local hSize = mathMax(10, visSet.ESPTextScale-2)
            local hpInt = mathFloor(cData.Hum.Health)
            if esp._lastHPStrInt ~= hpInt then
                esp.Health.Text   = FormatText(hpInt.." HP", textCase)
                esp._lastHPStrInt = hpInt
            end
            UpdateDraw(esp.Health, {Visible=true, Color=GetHealthColor(healthPercentage), Position=Vector2New(rootScreenPos.X,textYBottom), Size=hSize})
            textYBottom = textYBottom + hSize + 2
        else
            UpdateDraw(esp.Health, {Visible=false})
        end

        if visSet.WeaponESP and not isLOD then
            local tool  = cData.Char:FindFirstChildOfClass("Tool")
            local wStr  = tool and tool.Name or "None"
            local wSize = mathMax(10, visSet.ESPTextScale-2)
            if esp._lastWepStr ~= wStr then
                esp.Weapon.Text = FormatText(wStr, textCase)
                esp._lastWepStr = wStr
            end
            UpdateDraw(esp.Weapon, {Visible=true, Color=Color3RGB(220,220,220), Position=Vector2New(rootScreenPos.X,textYBottom), Size=wSize})
        else
            UpdateDraw(esp.Weapon, {Visible=false})
        end
    end
end

-- ============================================================
--  HEARTBEAT LOOP (Physics / Raycasting)
-- ============================================================
local function HeartbeatLoop(deltaTime)
    FRAME_COUNT_HB = FRAME_COUNT_HB + 1
    local playerCount = #PlayerCache
    DYNAMIC_STAGGER = mathClamp(mathFloor(playerCount / 6), 3, 15)

    if Settings.Triggerbot.Enabled and VirtualInput then
        triggerbotTimer = triggerbotTimer - deltaTime
        if triggerbotTimer <= 0 and mathRandom(1,100) <= Settings.Triggerbot.HitChance then
            local activeCam = workspace.CurrentCamera
            if not activeCam then return end
            local cx, cy = activeCam.ViewportSize.X*0.5, activeCam.ViewportSize.Y*0.5
            local originPos, direction

            if Settings.FOV.FollowCursor then
                local mp = UserInputService:GetMouseLocation()
                cx, cy   = mp.X, mp.Y
                local unitRay = activeCam:ViewportPointToRay(cx, cy)
                originPos = unitRay.Origin
                direction = unitRay.Direction * 1000
            else
                originPos = activeCam.CFrame.Position
                direction = activeCam.CFrame.LookVector * 1000
            end

            local lpChar = LocalPlayer.Character
            if TBotLastChar ~= lpChar then
                TriggerRayFilter[1] = activeCam
                TriggerRayFilter[2] = lpChar
                GlobalTriggerRayParams.FilterDescendantsInstances = TriggerRayFilter
                TBotLastChar = lpChar
            end

            local radius = Settings.Triggerbot.Thickness or 0.5
            local result = Settings.Triggerbot.Spherecast
                and workspace:Spherecast(originPos, radius, direction, GlobalTriggerRayParams)
                or  workspace:Raycast(originPos, direction, GlobalTriggerRayParams)

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

    if Settings.Hitbox.Enabled then
        local targetPartName = Settings.Hitbox.Part
        local newSize  = Vector3New(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
        local newTrans = Settings.Hitbox.Transparency
        for _, player in ipairs(PlayerCache) do
            if player ~= LocalPlayer and (not Settings.Aimlock.TeamCheck or not IsTeammateCached(player)) then
                local cData = CharCache[player]
                if cData and cData.Hum and cData.Hum.Health > 0 then
                    local part = (targetPartName=="Head") and cData.Head
                        or (targetPartName=="HumanoidRootPart" and cData.HRP)
                        or cData.Char:FindFirstChild(targetPartName)
                    if part and part:IsA("BasePart") then
                        if not OriginalHitboxCache[player] then OriginalHitboxCache[player] = {} end
                        if not OriginalHitboxCache[player][part] then
                            OriginalHitboxCache[player][part] = {Size=part.Size, Transparency=part.Transparency, CanCollide=part.CanCollide}
                        end
                        if part.Size         ~= newSize  then part.Size         = newSize  end
                        if part.Transparency ~= newTrans  then part.Transparency = newTrans  end
                        if part.CanCollide               then part.CanCollide   = false     end
                    end
                end
            end
        end
    else
        for player, parts in pairs(OriginalHitboxCache) do
            for part, data in pairs(parts) do
                if part and part.Parent then
                    if part.Size         ~= data.Size         then part.Size         = data.Size         end
                    if part.Transparency ~= data.Transparency  then part.Transparency = data.Transparency  end
                    if part.CanCollide   ~= data.CanCollide    then part.CanCollide   = data.CanCollide    end
                end
            end
        end
        table.clear(OriginalHitboxCache)
    end

    local now = osClock()
    for _, player in ipairs(PlayerCache) do
        local cData = CharCache[player]
        if cData and cData.HRP then
            local currentVel = cData.HRP.AssemblyLinearVelocity
            local dt         = now - (cData._lastTick or now)

            if dt > 0 and dt < 0.1 then
                local ring = cData._velRing or {VEC3_ZERO, VEC3_ZERO, VEC3_ZERO}
                local idx  = cData._velIdx or 1
                ring[idx]  = currentVel
                cData._velIdx = (idx % 3) + 1

                local avgX = (ring[1].X + ring[2].X + ring[3].X) / 3
                local avgY = (ring[1].Y + ring[2].Y + ring[3].Y) / 3
                local avgZ = (ring[1].Z + ring[2].Z + ring[3].Z) / 3
                local avgVel  = Vector3New(avgX, avgY, avgZ)

                local lastAvg = cData._lastAvgVel or avgVel
                local newAccel = (avgVel - lastAvg) * (1/dt)
                local lastAcc  = cData.Acceleration or VEC3_ZERO
                cData.Jerk         = (newAccel - lastAcc) * (1/dt)
                cData.Acceleration = newAccel
                cData._lastAvgVel  = avgVel
                cData._velRing     = ring
            else
                cData.Acceleration = VEC3_ZERO
                cData.Jerk         = VEC3_ZERO
                cData._velRing     = {VEC3_ZERO, VEC3_ZERO, VEC3_ZERO}
                cData._velIdx      = 1
            end
            cData._lastTick = now
        end
    end

    if Settings.World.Enabled then
        if Lighting.ClockTime     ~= Settings.World.Time          then Lighting.ClockTime     = Settings.World.Time          end
        if Lighting.Brightness    ~= Settings.World.Brightness    then Lighting.Brightness    = Settings.World.Brightness    end
        if Lighting.GlobalShadows ~= Settings.World.GlobalShadows then Lighting.GlobalShadows = Settings.World.GlobalShadows end
        if Lighting.Ambient       ~= Settings.World.Ambient       then Lighting.Ambient       = Settings.World.Ambient       end
    else
        if Lighting.ClockTime     ~= OriginalLighting.Time          then Lighting.ClockTime     = OriginalLighting.Time          end
        if Lighting.Brightness    ~= OriginalLighting.Brightness    then Lighting.Brightness    = OriginalLighting.Brightness    end
        if Lighting.GlobalShadows ~= OriginalLighting.GlobalShadows then Lighting.GlobalShadows = OriginalLighting.GlobalShadows end
        if Lighting.Ambient       ~= OriginalLighting.Ambient       then Lighting.Ambient       = OriginalLighting.Ambient       end
    end

    local activeCam = workspace.CurrentCamera
    if activeCam and Settings.Player.CameraFOVEnabled and activeCam.FieldOfView ~= Settings.Player.CameraFOV then
        activeCam.FieldOfView = Settings.Player.CameraFOV
    end
    local myCData = CharCache[LocalPlayer]
    if myCData and myCData.Hum then
        if Settings.Player.WalkSpeedEnabled and myCData.Hum.WalkSpeed ~= Settings.Player.WalkSpeed then
            myCData.Hum.WalkSpeed = Settings.Player.WalkSpeed
        end
        if Settings.Player.JumpPowerEnabled and myCData.Hum.JumpPower ~= Settings.Player.JumpPower then
            myCData.Hum.JumpPower = Settings.Player.JumpPower
        end
    end
end

-- ============================================================
--  MASTER RENDER LOOP
-- ============================================================
local function MasterRenderLoop(deltaTime)
    local ok, renderErr = pcall(function()
        FRAME_COUNT_RS = FRAME_COUNT_RS + 1
        _avgDeltaTime  = _avgDeltaTime * 0.9 + deltaTime * 0.1

        local activeCam = workspace.CurrentCamera
        if not activeCam then return end

        local viewport = activeCam.ViewportSize
        if viewport.X == 0 or viewport.Y == 0 then return end

        local camPos       = activeCam.CFrame.Position
        local screenWidth  = viewport.X
        local screenHeight = viewport.Y
        local screenCenter = Vector2New(screenWidth*0.5, screenHeight*0.5)

        local fovPos = UpdateFOV(screenCenter, Settings.FOV)
        UpdateAimlock(camPos, screenWidth, screenHeight, deltaTime, Settings.Aimlock, Settings.DetectionAvoidance, Settings.Visuals, Settings.FOV, fovPos, activeCam)
        UpdateESP(camPos, screenWidth, screenHeight, Settings.Visuals, activeCam)
        UpdateDamageNumbers(Settings.Visuals, activeCam)
    end)
    if not ok then warn("KAIM Rendering Error: " .. tostring(renderErr)) end
end

tableInsert(KaimConnections, RunService.Heartbeat:Connect(HeartbeatLoop))
tableInsert(KaimConnections, RunService.RenderStepped:Connect(MasterRenderLoop))

-- ============================================================
--  OBSIDIAN MENU BUILDING (Singularity v8.8)
-- ============================================================
local Window = Library:CreateWindow({
    Title          = "KAIM v8.8",
    Footer         = "Singularity Revision",
    ToggleKeybind  = Enum.KeyCode.K,
    NotifySide     = "Right",
})

local Tabs = {
    Home     = Window:AddTab("Dashboard",  "home"),
    Combat   = Window:AddTab("Combat",     "swords"),
    Visuals  = Window:AddTab("Visuals",    "eye"),
    Player   = Window:AddTab("Movement",   "person-standing"),
    Settings = Window:AddTab("Settings",   "settings"),
}

local Options  = Library.Options
local Toggles  = Library.Toggles

-- ============================================================
--  [ DASHBOARD TAB ]
-- ============================================================
local HomeLeft  = Tabs.Home:AddLeftGroupbox("KAIM v8.8", "crown")
local HomeRight = Tabs.Home:AddRightGroupbox("Quick Stats", "activity")

HomeLeft:AddLabel({
    Text     = "The Singularity Revision",
    DoesWrap = true,
})
HomeLeft:AddLabel({
    Text     = "v8.8: FPS-adaptive frame budgeting, LOD system for distant ESP, zero-allocation hot-path UpdateDraw, pcall-guarded HRP access, green visibility color, and comprehensive UI controls for every setting.",
    DoesWrap = true,
})

local fpsLabel    = HomeRight:AddLabel({ Text = "FPS: Measuring..." })
local playerLabel = HomeRight:AddLabel({ Text = "Players: 0 tracked" })

task.spawn(function()
    while _env.KAIM_LOADED do
        local fps = mathFloor(1 / mathMax(_avgDeltaTime, 0.001))
        pcall(function()
            fpsLabel:SetText("FPS: " .. fps .. "  |  " .. string.format("%.1f", _avgDeltaTime * 1000) .. "ms")
            playerLabel:SetText("Players: " .. #PlayerCache .. " tracked")
        end)
        task.wait(2)
    end
end)

-- ============================================================
--  [ COMBAT TAB ]
-- ============================================================

-- Core Aiming
local AimLeft  = Tabs.Combat:AddLeftGroupbox("Core Aiming", "crosshair")
local AimRight = Tabs.Combat:AddRightGroupbox("Targeting Setup", "target")

AimLeft:AddToggle("AimlockEnabled", {
    Text     = "Enable Aim Assist",
    Default  = false,
    Callback = function(v) Settings.Aimlock.Enabled = v end,
})
AimLeft:AddLabel("Aim Key"):AddKeyPicker("AimlockKeybind", {
    Default  = "RightClick",
    NoUI     = false,
    Text     = "Aim Key",
    Callback = function(v) Settings.Aimlock.Keybind = v end,
})
AimLeft:AddToggle("AimlockWallCheck", {
    Text     = "Wall Check",
    Tooltip  = "Only lock visible targets.",
    Default  = true,
    Callback = function(v) Settings.Aimlock.WallCheck = v end,
})
AimLeft:AddToggle("AimlockTeamCheck", {
    Text     = "Team Check",
    Tooltip  = "Ignore teammates.",
    Default  = true,
    Callback = function(v) Settings.Aimlock.TeamCheck = v end,
})
AimLeft:AddSlider("AimlockHitChance", {
    Text     = "Hit Chance %",
    Tooltip  = "Probability of registering a lock each frame.",
    Default  = 100,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Callback = function(v) Settings.Aimlock.HitChance = v end,
})

AimRight:AddDropdown("AimlockPriority", {
    Text     = "Target Priority",
    Tooltip  = "How the engine picks targets inside the FOV.",
    Values   = {"Crosshair", "Distance"},
    Default  = "Crosshair",
    Callback = function(v) Settings.Aimlock.TargetPriority = v end,
})
AimRight:AddDropdown("AimlockAimMode", {
    Text     = "Aim Mode",
    Tooltip  = "Smart: best visible part. Chaos: jitters to bypass ACs.",
    Values   = {"Smart", "Chaos", "Head", "Torso", "Limbs", "HRP"},
    Default  = "Smart",
    Callback = function(v) Settings.Aimlock.AimMode = v end,
})

-- FOV Controls
local FOVBox = Tabs.Combat:AddLeftTabbox("FOV Circle")
local FOVTab = FOVBox:AddTab("FOV", "circle")

FOVTab:AddToggle("FOVVisible", {
    Text     = "Show FOV Circle",
    Default  = true,
    Callback = function(v) Settings.FOV.Visible = v end,
})
FOVTab:AddToggle("FOVFollow", {
    Text     = "Follow Cursor",
    Tooltip  = "FOV circle tracks mouse position.",
    Default  = true,
    Callback = function(v) Settings.FOV.FollowCursor = v end,
})
FOVTab:AddSlider("FOVRadius", {
    Text     = "FOV Radius",
    Default  = 150,
    Min      = 20,
    Max      = 600,
    Rounding = 0,
    Suffix   = "px",
    Callback = function(v) Settings.FOV.Radius = v end,
})
FOVTab:AddSlider("FOVThickness", {
    Text     = "FOV Thickness",
    Default  = 1.5,
    Min      = 0.5,
    Max      = 5,
    Rounding = 1,
    Callback = function(v) Settings.FOV.Thickness = v end,
})
FOVTab:AddToggle("FOVPulse", {
    Text     = "Pulse Animation",
    Default  = false,
    Callback = function(v) Settings.FOV.Pulse = v end,
})
FOVTab:AddToggle("FOVFilled", {
    Text     = "Filled FOV",
    Default  = false,
    Callback = function(v) Settings.FOV.Filled = v end,
})
FOVTab:AddLabel("FOV Color"):AddColorPicker("FOVColor", {
    Default  = COLOR_WHITE,
    Callback = function(v) Settings.FOV.Color = v end,
})

-- Prediction
local PredBox = Tabs.Combat:AddRightTabbox("Kinematics")
local PredTab = PredBox:AddTab("Prediction", "zap")

PredTab:AddToggle("AimlockPredEnabled", {
    Text     = "Enable Prediction",
    Tooltip  = "Leads aim based on enemy velocity.",
    Default  = true,
    Callback = function(v) Settings.Aimlock.PredictionEnabled = v end,
})
PredTab:AddToggle("AimlockDynPred", {
    Text     = "Dynamic Prediction",
    Tooltip  = "Scales lead time with target distance.",
    Default  = true,
    Callback = function(v) Settings.Aimlock.DynamicPrediction = v end,
})
PredTab:AddToggle("AimlockJerk", {
    Text     = "Jerk Prediction (3rd Order)",
    Tooltip  = "Predicts sudden acceleration changes.",
    Default  = true,
    Callback = function(v) Settings.Aimlock.JerkPrediction = v end,
})
PredTab:AddToggle("AimlockDrop", {
    Text     = "Bullet Drop Compensation",
    Default  = false,
    Callback = function(v) Settings.Aimlock.BulletDropCompensation = v end,
})
PredTab:AddSlider("AimlockPrediction", {
    Text     = "Prediction Strength",
    Default  = 0.135,
    Min      = 0,
    Max      = 0.3,
    Rounding = 3,
    Callback = function(v) Settings.Aimlock.Prediction = v end,
})
PredTab:AddSlider("AimlockStrafePred", {
    Text     = "Strafe Multiplier",
    Default  = 1.0,
    Min      = 0,
    Max      = 3,
    Rounding = 2,
    Callback = function(v) Settings.Aimlock.StrafePrediction = v end,
})
PredTab:AddSlider("AimlockProjSpeed", {
    Text     = "Projectile Speed (m/s)",
    Default  = 1000,
    Min      = 100,
    Max      = 5000,
    Rounding = 0,
    Callback = function(v) Settings.Aimlock.ProjectileSpeed = v end,
})

-- Humanization
local SmoothLeft  = Tabs.Combat:AddLeftGroupbox("Humanization", "wand")
local OffsetRight = Tabs.Combat:AddRightGroupbox("Aim Offset", "move")

SmoothLeft:AddToggle("AimlockSmooth", {
    Text     = "Smooth Tracking",
    Tooltip  = "Lerps camera instead of snapping.",
    Default  = false,
    Callback = function(v) Settings.Aimlock.SmoothAiming = v end,
})
SmoothLeft:AddToggle("AimlockDynSmooth", {
    Text     = "Dynamic Smoothing",
    Default  = false,
    Callback = function(v) Settings.Aimlock.DynamicSmoothing = v end,
})
SmoothLeft:AddToggle("AimlockHumanize", {
    Text     = "Micro-Tremor (Jiggle)",
    Tooltip  = "Adds Perlin noise to bypass smoothing heuristics.",
    Default  = false,
    Callback = function(v) Settings.Aimlock.HumanizeSmoothing = v end,
})
SmoothLeft:AddSlider("AimlockSmoothSpeed", {
    Text     = "Smooth Speed",
    Default  = 0.3,
    Min      = 0.05,
    Max      = 1.0,
    Rounding = 2,
    Callback = function(v) Settings.Aimlock.SmoothSpeed = v end,
})
SmoothLeft:AddToggle("AimlockPerlin", {
    Text     = "Perlin Noise",
    Default  = false,
    Callback = function(v) Settings.Aimlock.PerlinNoise = v end,
})
SmoothLeft:AddSlider("AimlockNoiseSpd", {
    Text     = "Noise Speed",
    Default  = 1.0,
    Min      = 0.1,
    Max      = 5,
    Rounding = 1,
    Callback = function(v) Settings.Aimlock.NoiseSpeed = v end,
})
SmoothLeft:AddSlider("AimlockNoiseAmt", {
    Text     = "Noise Amount",
    Default  = 0.5,
    Min      = 0,
    Max      = 2,
    Rounding = 2,
    Callback = function(v) Settings.Aimlock.NoiseAmount = v end,
})

OffsetRight:AddSlider("AimOffX", {
    Text     = "Offset X",
    Tooltip  = "Horizontal aimpoint offset (studs).",
    Default  = 0,
    Min      = -5,
    Max      = 5,
    Rounding = 1,
    Callback = function(v) Settings.Aimlock.OffsetX = v end,
})
OffsetRight:AddSlider("AimOffY", {
    Text     = "Offset Y",
    Tooltip  = "Vertical aimpoint offset (studs).",
    Default  = 0,
    Min      = -5,
    Max      = 5,
    Rounding = 1,
    Callback = function(v) Settings.Aimlock.OffsetY = v end,
})
OffsetRight:AddSlider("AimOffZ", {
    Text     = "Offset Z",
    Tooltip  = "Depth aimpoint offset (studs).",
    Default  = 0,
    Min      = -5,
    Max      = 5,
    Rounding = 1,
    Callback = function(v) Settings.Aimlock.OffsetZ = v end,
})

-- Triggerbot
local TBotLeft  = Tabs.Combat:AddLeftGroupbox("Triggerbot", "mouse-pointer-click")
local HBRight   = Tabs.Combat:AddRightGroupbox("Hitbox Override", "box")

TBotLeft:AddToggle("TBEnabled", {
    Text     = "Enable Triggerbot",
    Default  = false,
    Callback = function(v) Settings.Triggerbot.Enabled = v end,
})
TBotLeft:AddToggle("TBTeamCheck", {
    Text     = "Team Check",
    Default  = true,
    Callback = function(v) Settings.Triggerbot.TeamCheck = v end,
})
TBotLeft:AddToggle("TBSphere", {
    Text     = "Spherecast (Thick Ray)",
    Default  = true,
    Callback = function(v) Settings.Triggerbot.Spherecast = v end,
})
TBotLeft:AddSlider("TBThick", {
    Text     = "Ray Thickness",
    Default  = 0.5,
    Min      = 0.1,
    Max      = 3.0,
    Rounding = 1,
    Callback = function(v) Settings.Triggerbot.Thickness = v end,
})
TBotLeft:AddSlider("TBDelay", {
    Text     = "Trigger Delay",
    Tooltip  = "Humanization delay before firing (seconds).",
    Default  = 0.05,
    Min      = 0.01,
    Max      = 0.5,
    Rounding = 2,
    Callback = function(v) Settings.Triggerbot.Delay = v end,
})
TBotLeft:AddSlider("TBHitChance", {
    Text     = "Hit Chance %",
    Default  = 100,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Callback = function(v) Settings.Triggerbot.HitChance = v end,
})

HBRight:AddToggle("HitboxEnabled", {
    Text     = "Enable Hitbox Expander",
    Default  = false,
    Callback = function(v) Settings.Hitbox.Enabled = v end,
})
HBRight:AddDropdown("HitboxPart", {
    Text     = "Target Part",
    Values   = {"Head", "HumanoidRootPart", "UpperTorso"},
    Default  = "Head",
    Callback = function(v) Settings.Hitbox.Part = v end,
})
HBRight:AddSlider("HitboxSize", {
    Text     = "Hitbox Size",
    Default  = 5,
    Min      = 2,
    Max      = 30,
    Rounding = 1,
    Callback = function(v) Settings.Hitbox.Size = v end,
})
HBRight:AddSlider("HitboxTrans", {
    Text     = "Transparency",
    Default  = 0.5,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Callback = function(v) Settings.Hitbox.Transparency = v end,
})

-- Detection Avoidance
local DetLeft = Tabs.Combat:AddLeftGroupbox("Security", "shield")
DetLeft:AddToggle("PeriodicDisable", {
    Text     = "Periodic Aim Disable",
    Tooltip  = "Randomly drops tracking to look legitimate.",
    Default  = false,
    Callback = function(v) Settings.DetectionAvoidance.PeriodicAimDisable = v end,
})
DetLeft:AddSlider("DisableChance", {
    Text     = "Disable Chance",
    Default  = 0.1,
    Min      = 0.01,
    Max      = 1.0,
    Rounding = 2,
    Callback = function(v) Settings.DetectionAvoidance.DisableChance = v end,
})
DetLeft:AddSlider("DisableDuration", {
    Text     = "Disable Duration",
    Tooltip  = "How long each disable cycle lasts (s).",
    Default  = 0.2,
    Min      = 0.05,
    Max      = 1.0,
    Rounding = 2,
    Callback = function(v) Settings.DetectionAvoidance.DisableDuration = v end,
})

-- ============================================================
--  [ VISUALS TAB ]
-- ============================================================
local ESPLeft  = Tabs.Visuals:AddLeftGroupbox("Master ESP", "eye")
local ESPRight = Tabs.Visuals:AddRightGroupbox("Box Customization", "square")

ESPLeft:AddToggle("ESPEnabled", {
    Text     = "Enable Visuals",
    Default  = false,
    Callback = function(v) Settings.Visuals.ESPEnabled = v end,
})
ESPLeft:AddSlider("ESPRange", {
    Text     = "Render Distance",
    Tooltip  = "Maximum studs to render visuals.",
    Default  = 1000,
    Min      = 100,
    Max      = 5000,
    Rounding = 0,
    Suffix   = "m",
    Callback = function(v) Settings.Visuals.MaxESPDistance = v end,
})
ESPLeft:AddToggle("ESPTeamCheck", {
    Text     = "Team Check",
    Default  = true,
    Callback = function(v) Settings.Visuals.TeamCheck = v end,
})
ESPLeft:AddToggle("ESPShowTeam", {
    Text     = "Show Teammates",
    Default  = false,
    Callback = function(v) Settings.Visuals.ShowTeammates = v end,
})
ESPLeft:AddLabel("Teammate Color"):AddColorPicker("ESPTeamColor", {
    Default  = Color3RGB(0,200,255),
    Callback = function(v) Settings.Visuals.TeammateColor = v end,
})

ESPRight:AddToggle("ESPBoxes", {
    Text     = "Enable Boxes",
    Default  = true,
    Callback = function(v) Settings.Visuals.ESPBoxes = v end,
})
ESPRight:AddDropdown("ESPBoxStyle", {
    Text     = "Box Style",
    Values   = {"Standard", "Corner"},
    Default  = "Corner",
    Callback = function(v) Settings.Visuals.ESPBoxStyle = v end,
})
ESPRight:AddToggle("ESPOutline", {
    Text     = "Box Outline",
    Default  = true,
    Callback = function(v) Settings.Visuals.ESPOutline = v end,
})
ESPRight:AddToggle("ESPBoxFill", {
    Text     = "Box Fill",
    Default  = false,
    Callback = function(v) Settings.Visuals.ESPBoxFill = v end,
})
ESPRight:AddSlider("ESPBoxFillTrans", {
    Text     = "Fill Transparency",
    Default  = 0.2,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Callback = function(v) Settings.Visuals.ESPBoxFillTrans = v end,
})
ESPRight:AddToggle("ESPDynThick", {
    Text     = "Depth Scaling",
    Default  = true,
    Callback = function(v) Settings.Visuals.DynamicThickness = v end,
})
ESPRight:AddSlider("ESPBaseThick", {
    Text     = "Base Thickness",
    Default  = 1.5,
    Min      = 0.5,
    Max      = 3,
    Rounding = 1,
    Callback = function(v) Settings.Visuals.BaseThickness = v end,
})

-- Text & Info
local TextLeft  = Tabs.Visuals:AddLeftGroupbox("Text & Information", "type")
local IndicRight = Tabs.Visuals:AddRightGroupbox("Indicators & Tracers", "antenna")

TextLeft:AddToggle("ESPNames", {
    Text     = "Show Names",
    Default  = true,
    Callback = function(v) Settings.Visuals.ESPNames = v end,
})
TextLeft:AddDropdown("ESPNameStyle", {
    Text     = "Name Style",
    Values   = {"Display Name", "Username", "Both"},
    Default  = "Display Name",
    Callback = function(v) Settings.Visuals.ESPNameStyle = v end,
})
TextLeft:AddDropdown("ESPTextCase", {
    Text     = "Text Casing",
    Values   = {"Normal", "UPPERCASE"},
    Default  = "UPPERCASE",
    Callback = function(v) Settings.Visuals.TextCase = v end,
})
TextLeft:AddSlider("ESPTextScale", {
    Text     = "Text Scale",
    Default  = 14,
    Min      = 10,
    Max      = 22,
    Rounding = 0,
    Callback = function(v) Settings.Visuals.ESPTextScale = v end,
})
TextLeft:AddToggle("ESPDistDisplay", {
    Text     = "Show Distance",
    Default  = false,
    Callback = function(v) Settings.Visuals.DistanceDisplay = v end,
})
TextLeft:AddToggle("ESPWeapon", {
    Text     = "Show Weapon",
    Default  = false,
    Callback = function(v) Settings.Visuals.WeaponESP = v end,
})
TextLeft:AddToggle("ESPHealthNums", {
    Text     = "Numeric Health",
    Default  = false,
    Callback = function(v) Settings.Visuals.HealthNumbers = v end,
})

IndicRight:AddToggle("ESPHealthBar", {
    Text     = "Health Bar",
    Default  = true,
    Callback = function(v) Settings.Visuals.HealthBar = v end,
})
IndicRight:AddToggle("TracerLines", {
    Text     = "Tracer Lines",
    Default  = false,
    Callback = function(v) Settings.Visuals.TracerLines = v end,
})
IndicRight:AddDropdown("TracerOrigin", {
    Text     = "Tracer Origin",
    Values   = {"Bottom", "Center", "Top"},
    Default  = "Bottom",
    Callback = function(v) Settings.Visuals.TracerOrigin = v end,
})
IndicRight:AddLabel("Tracer Color"):AddColorPicker("TracerColor", {
    Default  = Color3RGB(0,255,100),
    Callback = function(v) Settings.Visuals.TracerColor = v end,
})
IndicRight:AddToggle("LookTracers", {
    Text     = "Look Tracers",
    Default  = false,
    Callback = function(v) Settings.Visuals.LookTracers = v end,
})
IndicRight:AddSlider("LookTracerLen", {
    Text     = "Look Tracer Length",
    Default  = 5,
    Min      = 1,
    Max      = 30,
    Rounding = 0,
    Callback = function(v) Settings.Visuals.LookTracerLength = v end,
})
IndicRight:AddToggle("OffScreen", {
    Text     = "Off-Screen Arrows",
    Default  = false,
    Callback = function(v) Settings.Visuals.OffScreenArrows = v end,
})
IndicRight:AddToggle("DamageNumbers", {
    Text     = "Damage Numbers",
    Default  = false,
    Callback = function(v) Settings.Visuals.DamageNumbers = v end,
})

-- Target HUD
local HUDLeft   = Tabs.Visuals:AddLeftGroupbox("Target HUD", "monitor")
local ColorsRight = Tabs.Visuals:AddRightGroupbox("Colors", "palette")

HUDLeft:AddToggle("HUDEnabled", {
    Text     = "Show Target HUD",
    Default  = true,
    Callback = function(v) Settings.Visuals.TargetUI = v end,
})
HUDLeft:AddDropdown("HUDStyle", {
    Text     = "HUD Style",
    Values   = {"Ascension","Valorant","Standard","Cyber","Minimal","Tech","Apex"},
    Default  = "Ascension",
    Callback = function(v) Settings.Visuals.TargetUIStyle = v end,
})
HUDLeft:AddSlider("HUDScale", {
    Text     = "HUD Scale",
    Default  = 1.0,
    Min      = 0.5,
    Max      = 2.0,
    Rounding = 2,
    Callback = function(v) Settings.Visuals.TargetUIScale = v end,
})

ColorsRight:AddToggle("ESPVisColors", {
    Text     = "Visibility Check Colors",
    Default  = true,
    Callback = function(v) Settings.Visuals.UseVisColors = v end,
})
ColorsRight:AddLabel("Visible Color"):AddColorPicker("ESPVisColor", {
    Default  = Color3RGB(0,255,100),
    Callback = function(v) Settings.Visuals.VisColor = v end,
})
ColorsRight:AddLabel("Hidden Color"):AddColorPicker("ESPHiddenColor", {
    Default  = COLOR_RED,
    Callback = function(v) Settings.Visuals.HiddenColor = v end,
})
ColorsRight:AddLabel("Static Box Color"):AddColorPicker("ESPStaticColor", {
    Default  = COLOR_WHITE,
    Callback = function(v) Settings.Visuals.StaticBoxColor = v end,
})
ColorsRight:AddLabel("Damage Color"):AddColorPicker("DamageColor", {
    Default  = Color3RGB(255,255,0),
    Callback = function(v) Settings.Visuals.DamageColor = v end,
})
ColorsRight:AddToggle("ESPCustomName", {
    Text     = "Custom Name Color",
    Default  = false,
    Callback = function(v) Settings.Visuals.UseCustomNameColor = v end,
})
ColorsRight:AddLabel("Name Color"):AddColorPicker("ESPNameColor", {
    Default  = COLOR_WHITE,
    Callback = function(v) Settings.Visuals.ESPNameColor = v end,
})

-- Chams
local ChamsLeft = Tabs.Visuals:AddLeftGroupbox("Chams Overlay", "layers")
ChamsLeft:AddToggle("ChamsEnabled", {
    Text     = "Enable Highlights",
    Default  = false,
    Callback = function(v) Settings.Visuals.ChamsEnabled = v end,
})
ChamsLeft:AddToggle("ChamsVisColor", {
    Text     = "Use Visibility Colors",
    Default  = true,
    Callback = function(v) Settings.Visuals.ChamsUseVisColors = v end,
})
ChamsLeft:AddLabel("Fill Color"):AddColorPicker("ChamsFill", {
    Default  = COLOR_WHITE,
    Callback = function(v) Settings.Visuals.ChamsFillColor = v end,
})
ChamsLeft:AddLabel("Outline Color"):AddColorPicker("ChamsOutline", {
    Default  = COLOR_WHITE,
    Callback = function(v) Settings.Visuals.ChamsOutlineColor = v end,
})
ChamsLeft:AddSlider("ChamsFillTrans", {
    Text     = "Fill Transparency",
    Default  = 0.5,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Callback = function(v) Settings.Visuals.ChamsFillTrans = v end,
})
ChamsLeft:AddSlider("ChamsOutTrans", {
    Text     = "Outline Transparency",
    Default  = 0,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Callback = function(v) Settings.Visuals.ChamsOutlineTrans = v end,
})

-- World
local WorldRight = Tabs.Visuals:AddRightGroupbox("World Environment", "sun")
WorldRight:AddToggle("WorldEnabled", {
    Text     = "Enable Lighting Mod",
    Default  = false,
    Callback = function(v) Settings.World.Enabled = v end,
})
WorldRight:AddSlider("WorldTime", {
    Text     = "Time of Day",
    Tooltip  = "0–24 hour clock.",
    Default  = 14,
    Min      = 0,
    Max      = 24,
    Rounding = 1,
    Callback = function(v) Settings.World.Time = v end,
})
WorldRight:AddSlider("WorldBrightness", {
    Text     = "Brightness",
    Default  = 2,
    Min      = 0,
    Max      = 5,
    Rounding = 1,
    Callback = function(v) Settings.World.Brightness = v end,
})
WorldRight:AddToggle("WorldShadows", {
    Text     = "Global Shadows",
    Default  = false,
    Callback = function(v) Settings.World.GlobalShadows = v end,
})
WorldRight:AddLabel("Ambient Light"):AddColorPicker("WorldAmbient", {
    Default  = COLOR_WHITE,
    Callback = function(v) Settings.World.Ambient = v end,
})

-- ============================================================
--  [ MOVEMENT TAB ]
-- ============================================================
local MovLeft  = Tabs.Player:AddLeftGroupbox("Local Character", "person-standing")
local NoclipRight = Tabs.Player:AddRightGroupbox("Physics Manipulation", "ghost")

MovLeft:AddToggle("WalkSpeedEnabled", {
    Text     = "Force Walk Speed",
    Default  = false,
    Callback = function(v) Settings.Player.WalkSpeedEnabled = v end,
})
MovLeft:AddSlider("WalkSpeed", {
    Text     = "Walk Speed",
    Default  = 16,
    Min      = 5,
    Max      = 100,
    Rounding = 0,
    Callback = function(v) Settings.Player.WalkSpeed = v end,
})
MovLeft:AddToggle("JumpPowerEnabled", {
    Text     = "Force Jump Power",
    Default  = false,
    Callback = function(v) Settings.Player.JumpPowerEnabled = v end,
})
MovLeft:AddSlider("JumpPower", {
    Text     = "Jump Power",
    Default  = 50,
    Min      = 10,
    Max      = 250,
    Rounding = 0,
    Callback = function(v) Settings.Player.JumpPower = v end,
})
MovLeft:AddToggle("CamFOVEnabled", {
    Text     = "Camera FOV Override",
    Default  = false,
    Callback = function(v) Settings.Player.CameraFOVEnabled = v end,
})
MovLeft:AddSlider("CamFOV", {
    Text     = "Camera FOV",
    Default  = 70,
    Min      = 30,
    Max      = 120,
    Rounding = 0,
    Suffix   = "°",
    Callback = function(v) Settings.Player.CameraFOV = v end,
})
MovLeft:AddToggle("InfiniteJump", {
    Text     = "Infinite Jump",
    Default  = false,
    Callback = function(v) Settings.Player.InfiniteJump = v end,
})

-- Noclip
local noclipConn    = nil
local noclipAddConn = nil
local noclipCache   = {}

local function BuildNoclipCache(character)
    noclipCache = {}
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            tableInsert(noclipCache, { part = part, original = part.CanCollide })
        end
    end
end
_G._KaimBuildNoclipCache = BuildNoclipCache

local function SetNoclip(state)
    Settings.Player.NoclipEnabled = state
    if noclipConn    then noclipConn:Disconnect();    noclipConn    = nil end
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
        if LocalPlayer.Character then
            noclipAddConn = LocalPlayer.Character.DescendantAdded:Connect(function(part)
                if part:IsA("BasePart") then
                    tableInsert(noclipCache, { part = part, original = part.CanCollide })
                    part.CanCollide = false
                end
            end)
        end
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

NoclipRight:AddToggle("Noclip", {
    Text     = "Enable Noclip",
    Tooltip  = "Walk straight through map geometry.",
    Default  = false,
    Callback = function(v) SetNoclip(v) end,
})
NoclipRight:AddLabel("Noclip Hotkey"):AddKeyPicker("NoclipKeybind", {
    Default  = "N",
    NoUI     = false,
    Text     = "Noclip Hotkey",
    Callback = function(v)
        Settings.Player.NoclipKeybind = v
        pcall(function() cachedNoclipKC = Enum.KeyCode[v] end)
    end,
})

tableInsert(KaimConnections, UserInputService.JumpRequest:Connect(function()
    if Settings.Player.InfiniteJump then
        local cData = CharCache[LocalPlayer]
        if cData and cData.Hum then
            cData.Hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

-- ============================================================
--  [ SETTINGS TAB ]
-- ============================================================
local UILeft     = Tabs.Settings:AddLeftGroupbox("Interface", "settings")
local PerfRight  = Tabs.Settings:AddRightGroupbox("Performance", "gauge")

UILeft:AddLabel("Toggle UI Key"):AddKeyPicker("UIToggleKey", {
    Default  = "K",
    NoUI     = true,
    Text     = "Toggle UI Key",
    Callback = function(v) Settings.UI.ToggleKey = v end,
})

-- SaveManager + ThemeManager
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "UIToggleKey", "NoclipKeybind", "AimlockKeybind" })
SaveManager:SetFolder("KAIM_v8")
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("KAIM_v8")
ThemeManager:ApplyToTab(Tabs.Settings)
ThemeManager:LoadDefault()

-- Performance
PerfRight:AddToggle("PerfFrameSkip", {
    Text     = "FPS-Adaptive Frame Skip",
    Tooltip  = "When FPS drops below 50, limits ESP updates per frame.",
    Default  = true,
    Callback = function(v) Settings.Performance.FrameSkip = v end,
})
PerfRight:AddSlider("PerfMaxESP", {
    Text     = "Max ESP Per Frame",
    Tooltip  = "Max players to render ESP for in a single frame.",
    Default  = 20,
    Min      = 5,
    Max      = 50,
    Rounding = 0,
    Callback = function(v) Settings.Performance.MaxESPPerFrame = v end,
})
PerfRight:AddSlider("LODDistance", {
    Text     = "LOD Distance (studs)",
    Tooltip  = "Beyond this, players get simplified ESP. Saves heavy draw calls.",
    Default  = 500,
    Min      = 100,
    Max      = 1000,
    Rounding = 0,
    Suffix   = "m",
    Callback = function(v) Settings.Visuals.LODDistance = v end,
})
PerfRight:AddLabel({
    Text     = "Players further than LOD Distance get only box + name + health bar. Full ESP (tracers, chams, weapon) only inside LOD range.",
    DoesWrap = true,
})

-- Unload
local DangerLeft = Tabs.Settings:AddLeftGroupbox("Danger Zone", "alert-triangle")
DangerLeft:AddButton("Unload Framework", function()
    for _, conn in ipairs(KaimConnections) do pcall(function() conn:Disconnect() end) end

    for _, esp in pairs(ESPObjects) do DestroyESP(esp) end
    ESPObjects = {}

    for _, line in pairs(TracerLineCache)  do pcall(function() line:Remove() end) end
    for _, line in pairs(LookTracerCache)  do pcall(function() line:Remove() end) end
    TracerLineCache = {}; LookTracerCache = {}

    for _, dn in ipairs(ActiveDamageNumbers) do pcall(function() dn.TextObj:Remove() end) end
    for _, dn in ipairs(DamageObjPool)        do pcall(function() dn.TextObj:Remove() end) end
    ActiveDamageNumbers = {}; DamageObjPool = {}

    Lighting.ClockTime     = OriginalLighting.Time
    Lighting.Brightness    = OriginalLighting.Brightness
    Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    Lighting.Ambient       = OriginalLighting.Ambient

    for _, parts in pairs(OriginalHitboxCache) do
        for part, data in pairs(parts) do
            if part and part.Parent then
                part.Size         = data.Size
                part.Transparency = data.Transparency
                part.CanCollide   = data.CanCollide
            end
        end
    end

    SetNoclip(false)

    pcall(function() FOVRing:Remove(); FOVFill:Remove() end)
    pcall(function() ChamsFolder:Destroy() end)
    pcall(function()
        THUD.Shadow:Remove(); THUD.BG:Remove(); THUD.Outline:Remove()
        THUD.Accent:Remove(); THUD.Accent2:Remove()
        THUD.Name:Remove();   THUD.Data:Remove()
        THUD.BarBG:Remove();  THUD.BarFG:Remove()
    end)

    _env.KAIM_LOADED          = false
    _G._KaimBuildNoclipCache  = nil

    Library:Notify("KAIM Unloaded — All systems shut down. Reload safely.", 5)
end)

-- ============================================================
--  INPUT HANDLING
-- ============================================================
tableInsert(KaimConnections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- Noclip hotkey
    if input.KeyCode == cachedNoclipKC then
        local newState = not Settings.Player.NoclipEnabled
        SetNoclip(newState)
        Library:Notify("Noclip is now " .. (newState and "ON" or "OFF"), 2)
    end

    -- Aimlock activation
    local aimKey = Settings.Aimlock.Keybind
    if aimKey == "RightClick" then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Settings.Aimlock.IsAiming = true
        end
    else
        local ok, kc = pcall(function() return Enum.KeyCode[aimKey] end)
        if ok and kc and input.KeyCode == kc then Settings.Aimlock.IsAiming = true end
    end
end))

tableInsert(KaimConnections, UserInputService.InputEnded:Connect(function(input)
    local aimKey = Settings.Aimlock.Keybind
    if aimKey == "RightClick" then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Settings.Aimlock.IsAiming = false
        end
    else
        local ok, kc = pcall(function() return Enum.KeyCode[aimKey] end)
        if ok and kc and input.KeyCode == kc then Settings.Aimlock.IsAiming = false end
    end
end))

Tabs.Home:Select()
SaveManager:LoadAutoloadConfig()
Library:Notify("KAIM v8.8 Singularity — Initialization complete. Press K to toggle.", 5)

end, debug.traceback)

if not ok then
    warn("KAIM | FATAL INITIALIZATION ERROR:\n" .. tostring(err))
end

end)
