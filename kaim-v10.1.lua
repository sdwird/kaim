-- ==============================================================================
--  KAIM v10.1 | Obsidian Edition (Polished & Optimized)
--  • Fixed: SetNC, OrigLit, _lastPos, triggerbot, hitbox, world lighting
--  • Zero-Bridge Drawing Proxies | Single-Lock Aiming | Global Ray Caching
--  • Hoisted ESP Loop | Pure Competitive Visuals | Obsidian UI
-- ==============================================================================
task.spawn(function()
local ok, err = xpcall(function()

local _env = (type(getgenv) == "function" and getgenv()) or _G
if _env.KAIM_LOADED then
    warn("KAIM | Already loaded. Press K to toggle UI."); return
end
if not game:IsLoaded() then game.Loaded:Wait() end

-- ==============================================================================
--  1. SERVICES & IMPORTS
-- ==============================================================================
local RS  = game:GetService("RunService")
local Plr = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lit = game:GetService("Lighting")
local LP  = Plr.LocalPlayer

local VI; pcall(function() VI = game:GetService("VirtualInputManager") end)

local SafeGui = LP:FindFirstChild("PlayerGui") or workspace
pcall(function() local c = game:GetService("CoreGui"); if c then SafeGui = c end end)
pcall(function() local h = gethui and gethui(); if h and typeof(h) == "Instance" then SafeGui = h end end)

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Lib  = loadstring(game:HttpGet(repo.."Library.lua"))()
local SM   = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()
local TM   = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
assert(Lib, "KAIM | Failed to load Obsidian Library.")
_env.KAIM_LOADED = true

-- ==============================================================================
--  2. MATH & FAST LOCALS
-- ==============================================================================
local mFloor, mClamp, mMax, mMin, mSqrt = math.floor, math.clamp, math.max, math.min, math.sqrt
local mSin, mCos, mAtan2, mExp, mRand, mPi = math.sin, math.cos, math.atan2, math.exp, math.random, math.pi
local sUp, sClock = string.upper, os.clock
local V2, V3, C3, CF = Vector2.new, Vector3.new, Color3.fromRGB, CFrame.new
local tIns, tRem = table.insert, table.remove

-- Static Palette
local BLACK     = C3(0, 0, 0)
local WHITE     = C3(255, 255, 255)
local RED       = C3(255, 50, 50)
local ORANGE    = C3(255, 130, 0)
local GREEN     = C3(100, 255, 50)
local HUD_BG    = C3(12, 12, 14)
local HUD_DARK  = C3(5, 5, 10)
local BAR_BG    = C3(20, 20, 25)
local GRAY_NAME = C3(180, 180, 200)
local GRAY_WEP  = C3(220, 220, 220)

local HP_PAL = {C3(255, 50, 50), C3(255, 130, 0), C3(255, 200, 0), C3(100, 255, 50), C3(0, 255, 100)}
local D_PAL  = {C3(0, 255, 100), C3(100, 255, 100), C3(255, 210, 0), C3(255, 140, 0), C3(255, 50, 50)}

local function Grad5(p, t)
    if p <= 0 then return t[1] end; if p >= 1 then return t[5] end
    local s = p * 4 + 1; local i = mFloor(s); local f = s - i
    return (t[i] and t[i+1]) and t[i]:Lerp(t[i+1], f) or t[5]
end
local function HPC(p) return Grad5(p, HP_PAL) end
local function DC5(d, mx) return Grad5(1 - mClamp(d/mMax(mx, 1), 0, 1), D_PAL) end
local function Fmt(s, c) return c == "UPPERCASE" and sUp(s) or s end

local function GetWepCol(ws)
    local l = string.lower(ws)
    if l:find("gun") or l:find("rifle") or l:find("pistol") or l:find("sniper") then return RED end
    if l:find("sword") or l:find("knife") or l:find("blade") or l:find("axe") then return ORANGE end
    if l:find("heal") or l:find("med") or l:find("shield") then return GREEN end
    return GRAY_WEP
end

-- ==============================================================================
--  3. DRAWING PROXY CACHE (Zero-Bridge Rule)
-- ==============================================================================
local HAS_D = type(Drawing) == "table" and type(Drawing.new) == "function"

if not HAS_D then
    Lib:Notify("Warning: Your executor does not support the Drawing API. ESP visuals will not render.", 10)
end

local function ND(t)
    local obj
    if HAS_D then local ok2, r = pcall(Drawing.new, t); if ok2 and r then obj = r end end
    if not obj then
        obj = {Remove=function()end, Destroy=function()end}
        setmetatable(obj, {__newindex=function()end})
    end

    local cache = {
        Visible = false, ZIndex = 1, Transparency = 1, Color = Color3.new(),
        Thickness = 1, Filled = false, Position = Vector2.new(),
        Size = (t == "Text" and 12 or (t == "Square" and Vector2.new() or 0)),
        Text = "", Center = false, Outline = false, OutlineColor = Color3.new(),
        Font = 1, From = Vector2.new(), To = Vector2.new(), Radius = 0
    }

    for k, v in pairs(cache) do pcall(function() obj[k] = v end) end

    local proxy = {
        Remove = function() pcall(function() obj:Remove() end) end,
        Destroy = function() pcall(function() obj:Destroy() end) end
    }

    return setmetatable(proxy, {
        __index = cache,
        __newindex = function(_, k, v)
            if cache[k] ~= v then
                cache[k] = v
                obj[k] = v
            end
        end
    })
end

local function setL(l, f, t2, c, th, z)
    l.From = f; l.To = t2; l.Color = c; l.Thickness = th; l.ZIndex = z; l.Visible = true
end

local function setRect(rect, sz, pos, c, z, thick, trans, vis)
    if rect.Size ~= sz then rect.Size = sz end
    if rect.Position ~= pos then rect.Position = pos end
    if c and rect.Color ~= c then rect.Color = c end
    if z and rect.ZIndex ~= z then rect.ZIndex = z end
    if thick and rect.Thickness ~= thick then rect.Thickness = thick end
    if trans and rect.Transparency ~= trans then rect.Transparency = trans end
    if vis ~= nil then
        if rect.Visible ~= vis then rect.Visible = vis end
    elseif not rect.Visible then rect.Visible = true end
end

local function setText(txt, str, pos, c, sz, z)
    if txt.Text ~= str then txt.Text = str end
    if txt.Position ~= pos then txt.Position = pos end
    if txt.Color ~= c then txt.Color = c end
    if txt.Size ~= sz then txt.Size = sz end
    if z and txt.ZIndex ~= z then txt.ZIndex = z end
    if not txt.Visible then txt.Visible = true end
end

local function setCirc(c2, p, r, col, th, trans, vis)
    if c2.Position ~= p then c2.Position = p end
    if c2.Radius ~= r then c2.Radius = r end
    if c2.Color ~= col then c2.Color = col end
    if th and c2.Thickness ~= th then c2.Thickness = th end
    if trans and c2.Transparency ~= trans then c2.Transparency = trans end
    if c2.Visible ~= vis then c2.Visible = vis end
end

-- ==============================================================================
--  4. STATE CACHES & CONFIGURATION
-- ==============================================================================
local S = {
    Aim = {
        On=false, Mode="Smart", Priority="Crosshair", Key="RightClick", WallCheck=true, TeamCheck=true,
        ESPTargetsOnly=false, Pred=true, PredStr=0.135, Smooth=false, SmoothSpd=0.3, HitChance=100,
        SoundCue=true, NotifyLock=false, LockTracer=false, OffX=0, OffY=0, OffZ=0,
        IsAiming=false, Target=nil, HasLockedThisPress=false, _lastSearch=0,
    },
    TB = { On=false, Delay=0.05, HC=100, Team=true, Sphere=true, Thick=0.5 },
    HB = { On=false, Part="Head", Size=5, Trans=0.5 },
    FOV = {
        Show=true, Follow=true, Radius=150, ZoomScale=true, Thick=1.5,
        Color=WHITE, ColorLerp=true, LockCol=ORANGE, Trans=0.8, Filled=false, FC=WHITE, FT=0.92
    },
    ESP = {
        On=false, Boxes=true, BoxFill=false, BoxFillT=0.2, Outline=true,
        Names=true, TCase="UPPERCASE", TSize=14, Font=2,
        TeamCheck=true, ShowTeam=false, TeamCol=C3(0, 200, 255),
        VisColors=true, VisCol=C3(0, 255, 100), HideCol=RED, StatCol=WHITE,
        HBar=true, HBarThick=2, HBarOff=5, HBarSmooth=12, HBarText=true,
        DistShow=false, WepShow=false, Tracers=false, TracerOrg="Bottom", TracerCol=C3(0, 255, 100),
        MaxDist=1000, HUD=true, HUDStyle="Top Premium", HUDScale=1.0, CustomName=false, NameCol=WHITE,
    },
    World = { On=false, Time=14, Bright=2, Shadows=false, Ambient=WHITE },
    Mov = {
        SpeedOn=false, Speed=16, JumpOn=false, Jump=50, InfJump=false, BHop=false,
        Spinbot=false, SpinSpeed=20, FOVOn=false, CamFOV=70, Noclip=false, NoclipKey="N",
        GravOn=false, Gravity=196.2, BlinkKey="None"
    },
    Perf = { LOD=500, Watermark=true },
    Cfg = { GameProfile=false }
}

-- Fast Loop Locals
local _limbPool = {}
local _hbSizeV3, _aimOff = V3(5, 5, 5), V3(0, 0, 0)
local _maxD2, _lodD2 = 1000000, 250000
local _aimKC, _blinkKC = Enum.KeyCode.Unknown, Enum.KeyCode.Unknown
local _ncNeedsPass = false
local _lastTargetDistSq, _graceTimer, _switchCooldown = 0, 0, 0

-- Raycast params: visibility uses per-target filter, triggerbot uses global
local RP = RaycastParams.new(); RP.FilterType = Enum.RaycastFilterType.Exclude; RP.IgnoreWater = true
local TRP = RaycastParams.new(); TRP.FilterType = Enum.RaycastFilterType.Exclude; TRP.IgnoreWater = true

local Conns, PList, TC, ESPObj, CC, HBOrig = {}, {}, {}, {}, {}, {}
local chaosT, CHAOS_INT, chaosName = 0, 0.22, "Head"
local tbT, RSF, STAG, avgDT = 0, 0, 3, 0.016
local thHP, thAlpha, thName, thData, hudVis = 100, 0, "", "", false
local PI4, _camTan, _lastCamFOV = 0.7853981634, 0.57, 0

-- FIX: Properly declare OrigLit as local (was leaking to global)
local OrigLit = {}

-- Audio Instances
local lockSound = Instance.new("Sound"); lockSound.SoundId = "rbxassetid://6895086776"; lockSound.Volume = 0.5
pcall(function() lockSound.Parent = SafeGui end)

-- Drawing Objects
local FOVR = ND("Circle"); FOVR.Thickness = 1.5; FOVR.Filled = false
local FOVF = ND("Circle"); FOVF.Thickness = 1;   FOVF.Filled = true
local LTracer = ND("Line"); LTracer.Thickness = 1.5

local THUD = { BG=ND("Square"), Out=ND("Square"), Ac=ND("Square"), N=ND("Text"), BBG=ND("Square"), BFG=ND("Square"), HPNum=ND("Text") }
THUD.BG.Filled=true; THUD.BG.Color=HUD_BG; THUD.Out.Filled=false; THUD.Ac.Filled=true
THUD.N.Outline=true; THUD.N.Color=WHITE; THUD.N.Font=2; THUD.N.Center=true
THUD.BBG.Filled=true; THUD.BBG.Color=BAR_BG; THUD.BFG.Filled=true
THUD.HPNum.Outline=true; THUD.HPNum.Color=WHITE; THUD.HPNum.Font=2; THUD.HPNum.Center=true; THUD.HPNum.ZIndex=15

local function CacheL() OrigLit = {T=Lit.ClockTime, B=Lit.Brightness, S=Lit.GlobalShadows, A=Lit.Ambient} end; CacheL()

-- ==============================================================================
--  5. GLOBAL RAYCAST CACHING (Rule 3)
-- ==============================================================================
-- Visibility raycast only needs to ignore: LocalPlayer's character + target's character
-- Triggerbot raycast ignores: LocalPlayer's character only
local visRayFilter = {}
local tbRayFilter = {}

local function UpdateTBRayFilter()
    table.clear(tbRayFilter)
    local cam = workspace.CurrentCamera
    if cam then tIns(tbRayFilter, cam) end
    if LP.Character then tIns(tbRayFilter, LP.Character) end
    TRP.FilterDescendantsInstances = tbRayFilter
end

local function SetVisFilter(targetChar)
    -- Per-target: ignore local character + target character only (2 items max)
    table.clear(visRayFilter)
    if LP.Character then tIns(visRayFilter, LP.Character) end
    if targetChar then tIns(visRayFilter, targetChar) end
    RP.FilterDescendantsInstances = visRayFilter
end

tIns(Conns, LP.CharacterAdded:Connect(function() task.delay(0.5, UpdateTBRayFilter) end))

-- ==============================================================================
--  6. CORE UTILITIES
-- ==============================================================================
local function UpdateSTAG() STAG = mClamp(mFloor(#PList / 6), 3, 15) end
local function IsTeam(p) if TC[p] == nil then TC[p] = (p.Team ~= nil and p.Team == LP.Team) end; return TC[p] end
tIns(Conns, LP:GetPropertyChangedSignal("Team"):Connect(function() table.clear(TC) end))

local function BuildCC(pl, char)
    local old = CC[pl]
    if old and old._hpConn then pcall(function() old._hpConn:Disconnect() end) end
    CC[pl] = nil
    if not char then UpdateTBRayFilter(); return end
    task.spawn(function()
        local hrp, head, hum
        task.spawn(function() hrp = char:WaitForChild("HumanoidRootPart", 5) end)
        task.spawn(function() head = char:WaitForChild("Head", 5) end)
        task.spawn(function() hum = char:WaitForChild("Humanoid", 5) end)
        while (not hrp or not head or not hum) and char.Parent do task.wait() end
        if not char.Parent or pl.Character ~= char then return end

        if hrp and head and hum then
            local c = {}
            c.Char = char; c.HRP = hrp; c.Head = head; c.Hum = hum
            c._rig = char:FindFirstChild("UpperTorso") and "R15" or "R6"
            c._charH = c._rig == "R15" and 2.9 or 2.6
            c._charW = 1.0; c._maxHP = hum.MaxHealth
            c._hpConn = hum:GetPropertyChangedSignal("MaxHealth"):Connect(function() c._maxHP = hum.MaxHealth end)
            c._chaosParts = {}
            for _, n in ipairs({"Head","Neck","UpperTorso","LowerTorso","Torso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftHand","RightHand","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot","Left Arm","Right Arm","Left Leg","Right Leg"}) do
                local p = char:FindFirstChild(n); if p and p:IsA("BasePart") then tIns(c._chaosParts, p) end
            end
            -- FIX: Initialize _lastPos so heartbeat doesn't crash on first tick
            c._lastPos = hrp.Position
            c._sp = V3(); c._onSc = false; c._depth = 0; c._distSq = 0
            CC[pl] = c
            UpdateTBRayFilter()
        end
    end)
end

local function IsVis(part, camP, targetChar)
    if not part then return false end
    local pOk, inWs = pcall(function() return part:IsDescendantOf(workspace) end)
    if not pOk or not inWs then return false end
    SetVisFilter(targetChar)
    return workspace:Raycast(camP, part.Position - camP, RP) == nil
end

-- ==============================================================================
--  7. AIMING PIPELINE (Single-Lock Rule)
-- ==============================================================================
local SMART_P = {"Head", "Neck", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}
local function GetAimPart(cd, mode, camP, fovP, cam)
    local ch = cd.Char
    if mode == "Smart" then
        -- Try cached part first, but verify it's still valid
        if cd._smartPart then
            local sp = ch:FindFirstChild(cd._smartPart)
            if sp and IsVis(sp, camP, ch) then return sp, true end
            cd._smartPart = nil -- Clear stale cache
        end
        for i = 1, #SMART_P do
            local p = ch:FindFirstChild(SMART_P[i])
            if p and IsVis(p, camP, ch) then cd._smartPart = SMART_P[i]; return p, true end
        end
        return cd.HRP, false
    elseif mode == "Nearest Part" then
        local bestP, bestDist = cd.HRP, math.huge
        for i = 1, #SMART_P do
            local p = ch:FindFirstChild(SMART_P[i])
            if p then
                local sp, on = cam:WorldToViewportPoint(p.Position)
                if on then
                    local d = (V2(sp.X, sp.Y) - fovP).Magnitude
                    if d < bestDist and (not S.Aim.WallCheck or IsVis(p, camP, ch)) then
                        bestDist = d; bestP = p
                    end
                end
            end
        end
        return bestP, IsVis(bestP, camP, ch)
    end

    local part = cd.HRP
    if mode == "Chaos" then part = ch:FindFirstChild(chaosName) or cd.HRP
    elseif mode == "Head"  then part = cd.Head or cd.HRP
    elseif mode == "Neck"  then part = ch:FindFirstChild("Neck") or cd.Head or cd.HRP
    elseif mode == "Torso" then part = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or cd.HRP
    elseif mode == "LowerTorso" then part = ch:FindFirstChild("LowerTorso") or ch:FindFirstChild("Torso") or cd.HRP
    elseif mode == "Limbs" then
        table.clear(_limbPool)
        for _, n in ipairs({"LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local p = ch:FindFirstChild(n); if p then tIns(_limbPool, p) end
        end
        part = #_limbPool > 0 and _limbPool[mRand(1, mMax(1, #_limbPool))] or cd.HRP
    elseif mode == "HRP" then part = cd.HRP end

    return part, IsVis(part, camP, ch)
end

local function PickChaos(cd) if cd and cd._chaosParts and #cd._chaosParts > 0 then chaosName = cd._chaosParts[mRand(1, #cd._chaosParts)].Name end end

local function GetTarget(camP, fovP, cam)
    local bestTarget, bestVal = nil, math.huge
    local scale = S.FOV.ZoomScale and (70/cam.FieldOfView) or 1
    local efFovRadius = S.FOV.Radius * scale
    local byD = S.Aim.Priority == "Distance"

    for i = 1, #PList do
        local pl = PList[i]; local cd = CC[pl]
        if not cd or not cd.Hum or cd.Hum.Health <= 0 then continue end
        if S.Aim.TeamCheck and IsTeam(pl) then continue end
        if not cd._onSc then continue end

        if S.Aim.ESPTargetsOnly then
            local e = ESPObj[pl]
            if not e or not e._lv or not e.vis then continue end
        end

        local dist2D = mSqrt((fovP.X - cd._sp.X)^2 + (fovP.Y - cd._sp.Y)^2)
        if dist2D > efFovRadius then continue end

        local val = byD and cd._distSq or dist2D
        if val < bestVal then
            if not S.Aim.WallCheck or select(2, GetAimPart(cd, S.Aim.Mode, camP, fovP, cam)) then
                bestVal = val; bestTarget = pl
            end
        end
    end
    return bestTarget
end

-- ==============================================================================
--  8. ESP PIPELINE & REGISTRATION
-- ==============================================================================
local function MkESP(pl)
    local e = {
        Box=ND("Square"), BoxOut=ND("Square"), BoxFill=ND("Square"), Tracer=ND("Line"),
        N=ND("Text"), Di=ND("Text"), HTxt=ND("Text"), W=ND("Text"),
        BBG=ND("Square"), BFG=ND("Square"), BOut=ND("Square"),
        vis=false, _lv=false, _stag=mRand(0, 3),
        _smoothHp=100, _font=-1, _tc="", _di=-1, _ws="\0", _ns="\0", _wCol=WHITE, _hi=-1,
        _hiTxt1="0",
    }

    e.Box.Thickness = 1.5; e.BoxOut.Thickness = 3.5; e.BoxFill.Thickness = 1
    e.Box.Filled = false; e.BoxOut.Filled = false; e.BoxFill.Filled = true
    e.BoxOut.Transparency = 0.7; e.BoxOut.Color = BLACK
    e.Tracer.Thickness = 1.5

    e._texts = {e.N, e.Di, e.W}
    for i = 1, #e._texts do
        e._texts[i].Center = true; e._texts[i].Outline = true; e._texts[i].OutlineColor = BLACK; e._texts[i].ZIndex = 5
    end

    e.HTxt.Outline = true; e.HTxt.OutlineColor = BLACK; e.HTxt.Font = 2

    e.BBG.Filled = true; e.BBG.Color = C3(10, 10, 10); e.BBG.Transparency = 0.6; e.BBG.ZIndex = 2
    e.BFG.Filled = true; e.BFG.ZIndex = 3
    e.BOut.Filled = false; e.BOut.Color = BLACK; e.BOut.Thickness = 1; e.BOut.ZIndex = 1

    ESPObj[pl] = e
end

local function HideE(e)
    if not e._lv then return end
    if e.Box.Visible then e.Box.Visible = false end
    if e.BoxOut.Visible then e.BoxOut.Visible = false end
    if e.BoxFill.Visible then e.BoxFill.Visible = false end
    if e.Tracer.Visible then e.Tracer.Visible = false end
    for i=1, #e._texts do if e._texts[i].Visible then e._texts[i].Visible = false end end
    if e.HTxt.Visible then e.HTxt.Visible = false end
    if e.BBG.Visible then e.BBG.Visible = false end
    if e.BFG.Visible then e.BFG.Visible = false end
    if e.BOut.Visible then e.BOut.Visible = false end
    e._lv = false; e.vis = false
end

local function DelE(e)
    pcall(function()
        e.Box:Remove(); e.BoxOut:Remove(); e.BoxFill:Remove(); e.Tracer:Remove()
        for i=1, #e._texts do e._texts[i]:Remove() end
        e.HTxt:Remove()
        e.BBG:Remove(); e.BFG:Remove(); e.BOut:Remove()
    end)
end

local function RegPl(pl)
    if pl == LP then return end
    tIns(PList, pl); MkESP(pl); UpdateSTAG()
    tIns(Conns, pl:GetPropertyChangedSignal("Team"):Connect(function() TC[pl] = nil end))
    tIns(Conns, pl.CharacterAdded:Connect(function(c) BuildCC(pl, c) end))
    tIns(Conns, pl.CharacterRemoving:Connect(function()
        if CC[pl] and CC[pl]._hpConn then pcall(function() CC[pl]._hpConn:Disconnect() end) end
        CC[pl] = nil; HBOrig[pl] = nil; UpdateTBRayFilter()
    end))
    if pl.Character then BuildCC(pl, pl.Character) end
end

task.spawn(function() for _, p in ipairs(Plr:GetPlayers()) do if p ~= LP then RegPl(p); task.wait() end end end)
tIns(Conns, Plr.PlayerAdded:Connect(RegPl))
tIns(Conns, Plr.PlayerRemoving:Connect(function(pl)
    for i=1, #PList do if PList[i] == pl then tRem(PList, i); break end end; UpdateSTAG()
    local e = ESPObj[pl]; if e then task.defer(function() DelE(e) end) end
    ESPObj[pl] = nil; CC[pl] = nil; HBOrig[pl] = nil
    UpdateTBRayFilter()
end))
tIns(Conns, LP.CharacterAdded:Connect(function(c)
    BuildCC(LP, c)
    UpdateTBRayFilter()
    if S.Mov.Noclip then task.defer(function() if _G._KaimNC then _G._KaimNC(c) end end) end
end))
if LP.Character then BuildCC(LP, LP.Character) end
UpdateTBRayFilter()

-- ==============================================================================
--  8.5. NOCLIP SYSTEM (FIX: was undefined)
-- ==============================================================================
local _ncConn = nil
local _ncParts = {}

local function BuildNoclipCache(char)
    table.clear(_ncParts)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then tIns(_ncParts, p) end
    end
end
_G._KaimNC = BuildNoclipCache

local function SetNC(enabled)
    S.Mov.Noclip = enabled
    if enabled then
        local char = LP.Character
        if char then BuildNoclipCache(char) end
        if not _ncConn then
            _ncConn = RS.Stepped:Connect(function()
                if not S.Mov.Noclip then return end
                for i = 1, #_ncParts do
                    local p = _ncParts[i]
                    if p and p.Parent and p.CanCollide then p.CanCollide = false end
                end
            end)
            tIns(Conns, _ncConn)
        end
    else
        if _ncConn then pcall(function() _ncConn:Disconnect() end); _ncConn = nil end
        table.clear(_ncParts)
    end
end

-- ==============================================================================
--  9. RENDER LOGIC & LIVE TARGET HUD
-- ==============================================================================
local _liveTargetName = "None"
local _liveTargetHP = "-"
local _liveTargetDist = "-"

local function TickFOV(ctr, cam)
    local pos = S.FOV.Follow and UIS:GetMouseLocation() or ctr
    local scale = S.FOV.ZoomScale and (70/cam.FieldOfView) or 1
    local r = mMax(1, (S.FOV.Radius * scale))
    local fCol = (S.FOV.ColorLerp and S.Aim.Target and S.Aim.IsAiming) and S.FOV.LockCol or S.FOV.Color
    setCirc(FOVR, pos, r, fCol, S.FOV.Thick, S.FOV.Trans, S.FOV.Show)
    setCirc(FOVF, pos, r, S.FOV.FC, nil, S.FOV.FT, S.FOV.Show and S.FOV.Filled)
    return pos
end

local function HideTHUD()
    if not hudVis then return end
    THUD.BG.Visible=false; THUD.Out.Visible=false; THUD.Ac.Visible=false
    THUD.N.Visible=false; THUD.BBG.Visible=false; THUD.BFG.Visible=false
    THUD.HPNum.Visible=false
    hudVis = false
end

local _lockedDiedConn = nil
local function ClearTarget()
    S.Aim.Target = nil
    _liveTargetName = "None"; _liveTargetHP = "-"; _liveTargetDist = "-"
    if _lockedDiedConn then pcall(function() _lockedDiedConn:Disconnect() end); _lockedDiedConn = nil end
end

local function TickAim(camP, sw, sh, dt, fovP, cam)
    if S.Aim.Mode == "Chaos" and S.Aim.IsAiming then
        chaosT = chaosT - dt; if chaosT <= 0 then chaosT = CHAOS_INT; local tc = S.Aim.Target and CC[S.Aim.Target]; if tc then PickChaos(tc) end end
    end

    local showHUD = false
    if S.Aim.On and S.Aim.IsAiming then
        -- Single-Lock Rule: Never pick a new target if we already claimed one this press
        if not S.Aim.Target and not S.Aim.HasLockedThisPress then
            local newT = GetTarget(camP, fovP, cam)
            if newT then
                S.Aim.Target = newT
                S.Aim.HasLockedThisPress = true
                _graceTimer = 0
                if S.Aim.SoundCue then pcall(function() lockSound:Play() end) end
                if S.Aim.NotifyLock then Lib:Notify("Target Locked: " .. newT.DisplayName, 2) end
                local cd = CC[newT]
                if cd and cd.Hum then
                    _lockedDiedConn = cd.Hum.Died:Connect(ClearTarget)
                end
            end
        end

        local tar = S.Aim.Target; local cd = tar and CC[tar]
        if cd then
            if cd.Hum.Health <= 0 then
                ClearTarget()
            else
                local part, lockVis = GetAimPart(cd, S.Aim.Mode, camP, fovP, cam)
                if not lockVis and S.Aim.WallCheck then
                    _graceTimer = _graceTimer + dt
                    if _graceTimer > 0.5 then
                        ClearTarget()
                        part = nil
                    end
                else
                    _graceTimer = 0
                end

                if part then
                    local ap = part.Position
                    local distToTarget = mSqrt(cd._distSq); _lastTargetDistSq = cd._distSq

                    if S.Aim.Pred then
                        local vel = part.AssemblyLinearVelocity
                        -- Clamp extreme velocities to prevent teleport-aim
                        local vMag = vel.Magnitude
                        if vMag > 300 then vel = vel.Unit * 300 end
                        ap = ap + (vel * S.Aim.PredStr)
                    end
                    if S.Aim.OffX ~= 0 or S.Aim.OffY ~= 0 or S.Aim.OffZ ~= 0 then ap = ap + _aimOff end
                    local tCF = CF(camP, ap)

                    -- Snap detection: skip smooth if already on target
                    local apSc, on2 = cam:WorldToViewportPoint(ap)
                    local snap = false
                    if on2 then
                        local cx, cy = sw*0.5, sh*0.5
                        if S.FOV.Follow then local ms = UIS:GetMouseLocation(); cx=ms.X; cy=ms.Y end
                        if (V2(apSc.X, apSc.Y) - V2(cx, cy)).Magnitude < 8 then snap = true end
                    end

                    if mRand(1, 100) <= S.Aim.HitChance then
                        if S.Aim.Smooth and not snap then
                            local sf = mClamp(1 - mExp(-S.Aim.SmoothSpd * 15 * dt), 0.01, 1)
                            cam.CFrame = cam.CFrame:Lerp(tCF, sf)
                        else cam.CFrame = tCF end
                    end

                    if S.Aim.LockTracer and cd._onSc then
                        setL(LTracer, V2(sw*0.5, sh*0.5), V2(cd._sp.X, cd._sp.Y), lockVis and WHITE or RED, 1.5, 1)
                    else if LTracer.Visible then LTracer.Visible = false end end

                    -- Update Live Variables for UI
                    _liveTargetName = tar.DisplayName
                    _liveTargetHP = ("%d / %d"):format(mFloor(cd.Hum.Health), mFloor(cd._maxHP or 100))
                    _liveTargetDist = ("%dm"):format(mFloor(distToTarget))

                    if S.ESP.HUD then
                        showHUD = true; local sc = S.ESP.HUDScale; local st = S.ESP.HUDStyle; local ac = lockVis and WHITE or RED
                        local aHP = cd.Hum.Health or 0; thHP = thHP + (aHP - thHP)*(dt*10); if thHP ~= thHP or thHP < 0 then thHP = 0 end
                        local maxHP = mMax(1, cd._maxHP or 100)
                        local hpPct = mClamp(thHP / maxHP, 0, 1)
                        local di = mFloor(distToTarget); local rN = sUp(tar.DisplayName)

                        local fullStr = ("%s  [%dm]"):format(rN, di)
                        if S.Aim.Mode == "Chaos" then fullStr = fullStr .. " - " .. chaosName end
                        if thName ~= fullStr then thName = fullStr end
                        local hpStr = ("%d / %d"):format(mFloor(aHP), mFloor(maxHP))

                        thAlpha = mClamp(thAlpha + dt*10, 0, 1); local ea = 1 - mExp(-thAlpha * 6); local ys = (1 - ea) * 20

                        local bw = mFloor(mMax(220, 40 + #thName * 8) * sc)
                        local bh = mFloor(46 * sc)
                        local hx = mFloor((sw - bw) * 0.5)
                        local hy = st == "Top Premium" and (mFloor(sh * 0.06) - mFloor(ys)) or (mFloor(sh * 0.82) + mFloor(ys))

                        setRect(THUD.BG, V2(bw,bh), V2(hx,hy), C3(15, 15, 15), nil, nil, 0.85*ea, true)
                        setRect(THUD.Out, V2(bw+2,bh+2), V2(hx-1,hy-1), BLACK, nil, nil, ea, true)
                        setRect(THUD.Ac, V2(bw, 2), V2(hx,hy), ac, nil, nil, ea, true)
                        setText(THUD.N, thName, V2(hx+(bw*0.5), hy+mFloor(8*sc)), WHITE, mMax(12,mFloor(14*sc)), nil); THUD.N.Transparency=ea

                        local barThick = mMax(8, mFloor(10*sc))
                        local barY = hy + mFloor(28*sc)
                        local barW = bw - mFloor(20*sc)
                        local barX = hx + mFloor(10*sc)

                        setRect(THUD.BBG, V2(barW,barThick), V2(barX,barY), BLACK, nil, nil, 0.6*ea, true)
                        setRect(THUD.BFG, V2(mFloor(barW*hpPct),barThick), V2(barX,barY), HPC(hpPct), nil, nil, ea, true)
                        setText(THUD.HPNum, hpStr, V2(hx+(bw*0.5), barY - mFloor(2*sc)), WHITE, mMax(10, mFloor(11*sc)), nil); THUD.HPNum.Transparency=ea

                        hudVis = true
                    end
                end
            end
        end
    else
        ClearTarget()
    end

    if not S.Aim.Target or not S.Aim.IsAiming then if LTracer.Visible then LTracer.Visible = false end end
    if not showHUD then
        thAlpha = mClamp(thAlpha - dt*8, 0, 1)
        if thAlpha <= 0.05 then HideTHUD() else
            local ea = 1 - mExp(-thAlpha * 6)
            THUD.BG.Transparency = 0.85*ea; THUD.Out.Transparency = ea; THUD.Ac.Transparency = ea
            THUD.N.Transparency = ea; THUD.BBG.Transparency = 0.6*ea; THUD.BFG.Transparency = ea; THUD.HPNum.Transparency = ea
        end
    end
end

local function TickESP(camP, sw, sh, cam, tStart, dt)
    local cfov = cam.FieldOfView
    if cfov ~= _lastCamFOV then _lastCamFOV = cfov; _camTan = math.tan(math.rad(cfov*0.5)) end

    local halfH = sh * 0.5

    -- Rule 4: Hoisted variables — zero table lookups in the loop
    local esp = S.ESP
    local esOn = esp.On; local esVisCol = esp.VisColors
    local esTr = esp.Tracers
    local esHBar = esp.HBar; local esHBThick = esp.HBarThick; local esHBOff = esp.HBarOff; local esHBSm = esp.HBarSmooth; local esHBTxt = esp.HBarText
    local esNames = esp.Names; local esTC = esp.TCase
    local esDist = esp.DistShow; local esWep = esp.WepShow
    local esFont = esp.Font; local esTSz = esp.TSize; local subTS = mMax(10, esTSz - 2)
    local esBoxes = esp.Boxes; local esOutline = esp.Outline; local esBFill = esp.BoxFill; local esBFillT = esp.BoxFillT
    local esVisC = esp.VisCol; local esHideC = esp.HideCol; local esStatC = esp.StatCol
    local esTeamChk = esp.TeamCheck; local esShowTeam = esp.ShowTeam; local esTeamCol = esp.TeamCol
    local esCustomN = esp.CustomName; local esNameCol = esp.NameCol
    local esTracerCol = esp.TracerCol; local esMaxDist = esp.MaxDist

    for i = 1, #PList do
        local pl = PList[i]; local e = ESPObj[pl]; if not e then continue end
        local cd = CC[pl]

        -- Safety: pcall-guard HRP access
        if not cd or not cd.HRP or not cd.Hum or cd.Hum.Health <= 0 then HideE(e); continue end
        local hrpOk, hrpInWs = pcall(function() return cd.HRP:IsDescendantOf(workspace) end)
        if not hrpOk or not hrpInWs then HideE(e); continue end

        local isTM = IsTeam(pl)
        if esTeamChk and isTM and not esShowTeam then HideE(e); continue end

        local d2 = cd._distSq; if d2 > _maxD2 then HideE(e); continue end
        local onSc, depth = cd._onSc, cd._depth
        if depth <= 0 then HideE(e); continue end
        local isLOD = d2 > _lodD2

        -- Smooth Health Lerp: exponential decay for butter-smooth bars
        local targetHP = cd.Hum.Health
        local hpDiff = targetHP - e._smoothHp
        if hpDiff < 0 then
            -- Damage: fast drop
            e._smoothHp = e._smoothHp + hpDiff * mClamp(esHBSm * dt, 0, 1)
        else
            -- Heal: instant recovery
            e._smoothHp = targetHP
        end
        local hpPct = mClamp(e._smoothHp / mMax(1, cd._maxHP or 100), 0, 1)

        -- Staggered visibility raycast (skip LOD players)
        if not isLOD and onSc and esVisCol then
            if e._stag == (RSF % STAG) then e.vis = IsVis(cd.HRP, camP, cd.Char) end
        else e.vis = true end

        local col = (isTM and esShowTeam) and esTeamCol or (esVisCol and (e.vis and esVisC or esHideC) or esStatC)

        -- Tracers (skip LOD)
        if esTr and not isLOD then
            setL(e.Tracer, tStart, V2(cd._sp.X, cd._sp.Y), esTracerCol, 1.5, 1)
            if e.Tracer.Visible ~= onSc then e.Tracer.Visible = onSc end
        elseif e.Tracer.Visible then e.Tracer.Visible = false end

        if not esOn or not onSc then
            if e.Box.Visible then e.Box.Visible = false end; if e.BoxOut.Visible then e.BoxOut.Visible = false end; if e.BoxFill.Visible then e.BoxFill.Visible = false end
            for j=1, #e._texts do if e._texts[j].Visible then e._texts[j].Visible = false end end
            if e.HTxt.Visible then e.HTxt.Visible = false end
            if e.BBG.Visible then e.BBG.Visible = false end; if e.BFG.Visible then e.BFG.Visible = false end; if e.BOut.Visible then e.BOut.Visible = false end
            continue
        end
        e._lv = true

        depth = mMax(depth, 0.1)
        local pps = halfH / (depth * _camTan)
        local bw, bh = mFloor(mMax(2, cd._charW * 2 * pps)), mFloor(mMax(4, cd._charH * 2 * pps))
        local bx, by = mFloor(cd._sp.X - bw * 0.5), mFloor(cd._sp.Y - bh * 0.5)
        local zIndex = mFloor(10000 - depth)

        if esBoxes then
            setRect(e.Box, V2(bw, bh), V2(bx, by), col, zIndex + 2, 1.5, 1, true)
            if esOutline then
                setRect(e.BoxOut, V2(bw+2, bh+2), V2(bx-1, by-1), BLACK, zIndex + 1, 1.5, 0.7, true)
            else if e.BoxOut.Visible then e.BoxOut.Visible = false end end
            if esBFill then
                setRect(e.BoxFill, V2(bw, bh), V2(bx, by), col, zIndex, nil, esBFillT, true)
            else if e.BoxFill.Visible then e.BoxFill.Visible = false end end
        else
            if e.Box.Visible then e.Box.Visible = false; e.BoxOut.Visible = false end
            if e.BoxFill.Visible then e.BoxFill.Visible = false end
        end

        local hpCol = HPC(hpPct)
        local hi = mFloor(e._smoothHp)
        if e._hi ~= hi then e._hi = hi; e._hiTxt1 = tostring(hi) end

        if esHBar then
            local showHTxt = esHBTxt and e.vis
            local fh = mMax(1, mFloor(bh * hpPct))
            local barX = bx - esHBOff - esHBThick
            setRect(e.BOut, V2(esHBThick+2, bh+2), V2(barX-1, by-1), BLACK, zIndex+1, 1, nil, true)
            setRect(e.BBG, V2(esHBThick, bh), V2(barX, by), C3(10,10,10), zIndex+2, 1, 0.6, true)
            setRect(e.BFG, V2(esHBThick, fh), V2(barX, by+bh-fh), hpCol, zIndex+3, 1, nil, true)

            if showHTxt then
                e.HTxt.Center = true
                setText(e.HTxt, e._hiTxt1, V2(barX - 12, by + bh - fh - (subTS * 0.4)), hpCol, subTS, zIndex + 4)
            else
                if e.HTxt.Visible then e.HTxt.Visible = false end
            end
        else
            if e.BBG.Visible then e.BBG.Visible=false; e.BFG.Visible=false; e.BOut.Visible=false end
            if e.HTxt.Visible then e.HTxt.Visible=false end
        end

        if e._font ~= esFont then e._font = esFont; for j=1, #e._texts do e._texts[j].Font = esFont end; e.HTxt.Font = esFont end
        if e._tc ~= esTC then e._tc = esTC; e._ws="\0"; e._ns="\0"; e._di=-1 end

        local ty = by - esTSz - 4
        local by2 = by + bh + 4
        local nCol = esCustomN and esNameCol or col

        if esNames then
            local dn = pl.DisplayName; if e._ns ~= dn then e._ns = dn; e._nsFmt = Fmt(dn, esTC) end
            setText(e.N, e._nsFmt, V2(mFloor(cd._sp.X), ty), nCol, esTSz, zIndex + 5)
        else if e.N.Visible then e.N.Visible = false end end

        if esDist then
            local di = mFloor(mSqrt(d2)); if e._di ~= di then e._di = di; e._diFmt = Fmt(di.."m", esTC) end
            setText(e.Di, e._diFmt, V2(mFloor(cd._sp.X), by2), DC5(di, esMaxDist), subTS, zIndex + 5)
            by2 = by2 + subTS + 2
        else if e.Di.Visible then e.Di.Visible = false end end

        if esWep and not isLOD then
            local tool = cd.Char:FindFirstChildOfClass("Tool"); local ws = tool and tool.Name or "None"
            if e._ws ~= ws then e._ws = ws; e._wsFmt = Fmt(ws, esTC); e._wCol = GetWepCol(ws) end
            setText(e.W, e._wsFmt, V2(mFloor(cd._sp.X), by2), e._wCol, subTS, zIndex + 5)
        else if e.W.Visible then e.W.Visible = false end end
    end
end

-- ==============================================================================
--  10. HEARTBEAT LOOP (Physics, Triggerbot, Hitbox, World)
-- ==============================================================================
local function TickHB(dt)
    -- Camera FOV override
    if S.Mov.FOVOn then
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= S.Mov.CamFOV then cam.FieldOfView = S.Mov.CamFOV end
    end

    -- Gravity override
    if S.Mov.GravOn then
        if workspace.Gravity ~= S.Mov.Gravity then workspace.Gravity = S.Mov.Gravity end
    end

    -- World Lighting (FIX: was missing entirely)
    if S.World.On then
        if Lit.ClockTime ~= S.World.Time then Lit.ClockTime = S.World.Time end
        if Lit.Brightness ~= S.World.Bright then Lit.Brightness = S.World.Bright end
        if Lit.GlobalShadows ~= S.World.Shadows then Lit.GlobalShadows = S.World.Shadows end
        if Lit.Ambient ~= S.World.Ambient then Lit.Ambient = S.World.Ambient end
    end

    -- Character overrides
    local mc = CC[LP]
    if mc and mc.Hum and mc.HRP then
        if S.Mov.SpeedOn then
            if mc.Hum.WalkSpeed ~= S.Mov.Speed then mc.Hum.WalkSpeed = S.Mov.Speed end
        end
        if S.Mov.JumpOn then
            if not mc.Hum.UseJumpPower then mc.Hum.UseJumpPower = true end
            if mc.Hum.JumpPower ~= S.Mov.Jump then mc.Hum.JumpPower = S.Mov.Jump end
        end
        if S.Mov.BHop and mc.Hum.MoveDirection.Magnitude > 0 then
            if mc.Hum.FloorMaterial ~= Enum.Material.Air then mc.Hum.Jump = true end
        end
        if S.Mov.Spinbot then
            mc.HRP.CFrame = mc.HRP.CFrame * CFrame.Angles(0, math.rad(S.Mov.SpinSpeed), 0)
        end
    end

    -- Hitbox Expander (FIX: was missing entirely)
    if S.HB.On then
        local newSz = V3(S.HB.Size, S.HB.Size, S.HB.Size)
        local newTr = S.HB.Trans
        for ii = 1, #PList do
            local pl = PList[ii]
            if S.Aim.TeamCheck and IsTeam(pl) then continue end
            local cd = CC[pl]
            if cd and cd.Hum and cd.Hum.Health > 0 then
                local part = S.HB.Part == "Head" and cd.Head or (S.HB.Part == "HumanoidRootPart" and cd.HRP or cd.Char:FindFirstChild(S.HB.Part))
                if part and part:IsA("BasePart") then
                    if not HBOrig[pl] then HBOrig[pl] = {} end
                    if not HBOrig[pl][part] then HBOrig[pl][part] = {Size=part.Size, Trans=part.Transparency, CC=part.CanCollide} end
                    if part.Size ~= newSz then part.Size = newSz end
                    if part.Transparency ~= newTr then part.Transparency = newTr end
                    if part.CanCollide then part.CanCollide = false end
                end
            end
        end
    else
        for pl, parts in pairs(HBOrig) do
            for part, d in pairs(parts) do
                if part and part.Parent then
                    part.Size = d.Size; part.Transparency = d.Trans; part.CanCollide = d.CC
                end
            end
        end
        if next(HBOrig) then table.clear(HBOrig) end
    end

    -- Triggerbot (FIX: was missing entirely)
    if S.TB.On and VI then
        tbT = tbT - dt
        if tbT <= 0 and mRand(1, 100) <= S.TB.HC then
            local cam = workspace.CurrentCamera
            if cam then
                local origin = cam.CFrame.Position
                local dir = cam.CFrame.LookVector * 1000
                local result
                if S.TB.Sphere then
                    result = workspace:Spherecast(origin, S.TB.Thick, dir, TRP)
                else
                    result = workspace:Raycast(origin, dir, TRP)
                end
                if result and result.Instance then
                    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
                    if hitModel then
                        local hitPl = Plr:GetPlayerFromCharacter(hitModel)
                        if hitPl and hitPl ~= LP and (not S.TB.Team or not IsTeam(hitPl)) then
                            local cd = CC[hitPl]
                            if cd and cd.Hum and cd.Hum.Health > 0 then
                                task.defer(function()
                                    local cx = cam.ViewportSize.X * 0.5
                                    local cy = cam.ViewportSize.Y * 0.5
                                    VI:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                                    task.wait(0.01)
                                    VI:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                                end)
                                tbT = S.TB.Delay
                            end
                        end
                    end
                end
            end
        end
    end

    -- Update player screen positions for next render tick
    for i = 1, #PList do
        local cd = CC[PList[i]]
        if cd and cd.HRP and cd._lastPos then
            cd._lastPos = cd.HRP.Position
        end
    end
end

-- ==============================================================================
--  11. MASTER RENDER (RenderStepped)
-- ==============================================================================
local function TickRender(dt)
    RSF = RSF + 1; avgDT = avgDT + (dt - avgDT) * 0.1
    local cam = workspace.CurrentCamera; if not cam then return end
    local vp = cam.ViewportSize; if vp.X == 0 or vp.Y == 0 then return end
    local cp = cam.CFrame.Position; local sw, sh = vp.X, vp.Y
    local myC = CC[LP]; local myP = (myC and myC.HRP) and myC.HRP.Position or cp

    -- Pre-compute all player screen positions (shared data for aim + ESP)
    for i=1, #PList do
        local pl = PList[i]; local cd = CC[pl]
        if cd and cd.HRP and cd.Hum and cd.Hum.Health > 0 then
            local hp = cd.HRP.Position
            local sp, on = cam:WorldToViewportPoint(hp)
            cd._sp = sp; cd._onSc = on; cd._depth = sp.Z
            local dx, dy, dz = hp.X - myP.X, hp.Y - myP.Y, hp.Z - myP.Z
            cd._distSq = dx*dx + dy*dy + dz*dz
        else
            if cd then cd._onSc = false; cd._depth = 0 end
        end
    end

    local fovP = TickFOV(V2(sw*0.5, sh*0.5), cam)
    local tStart = V2(sw*0.5, S.ESP.TracerOrg=="Top" and 0 or (S.ESP.TracerOrg=="Center" and sh*0.5 or sh))

    TickAim(cp, sw, sh, dt, fovP, cam)
    TickESP(cp, sw, sh, cam, tStart, dt)
end

tIns(Conns, RS.Heartbeat:Connect(TickHB))
tIns(Conns, RS.RenderStepped:Connect(TickRender))

-- ==============================================================================
--  12. OBSIDIAN USER INTERFACE
-- ==============================================================================
local Win = Lib:CreateWindow({ Title="KAIM", Footer="v10.1 | IDLE", ToggleKeybind=Enum.KeyCode.K, NotifySide="Right" })

local T = {
    Home   = Win:AddTab("Home",     "home"),
    Combat = Win:AddTab("Combat",   "crosshair"),
    Visual = Win:AddTab("Visuals",  "eye"),
    Player = Win:AddTab("Movement", "zap"),
    Config = Win:AddTab("Config",   "settings"),
}

local W_MARK = S.Perf.Watermark and Lib:AddDraggableLabel("KAIM v10.1 | FPS: --", "cpu") or nil
if W_MARK then W_MARK:SetVisible(true) end

-- ---------- Home Tab ----------
local HL_Welcome = T.Home:AddLeftGroupbox("Welcome to KAIM")
HL_Welcome:AddLabel("User: " .. LP.Name)
local executorName = (identifyexecutor and identifyexecutor() or "Unknown Executor")
HL_Welcome:AddLabel("Executor: " .. executorName)
HL_Welcome:AddLabel("KAIM Version: 10.1 (Polished)")

local HL_Info = T.Home:AddLeftGroupbox("Aim Modes Explained")
HL_Info:AddLabel({Text="• Smart: Locks onto the first visible part.\n• Nearest Part: Targets the body part closest to the cursor.\n• Chaos: Erratically switches parts.\n• Head/Neck/Torso/HRP: Strict part targeting.\n• Limbs: Targets random arms or legs.", DoesWrap=true})

local HR_Stats = T.Home:AddRightGroupbox("Live Statistics")
local lFPS = HR_Stats:AddLabel({Text="FPS: —"})
local lPL  = HR_Stats:AddLabel({Text="Players: 0"})
local lLck = HR_Stats:AddLabel({Text="LOCKED: None"})

local HR_Actions = T.Home:AddRightGroupbox("Quick Actions")
HR_Actions:AddButton("Quick Unload", function()
    ClearTarget()
    for i = 1, #Conns do pcall(function() Conns[i]:Disconnect() end) end
    for _, e in pairs(ESPObj) do DelE(e) end; ESPObj = {}
    SetNC(false)
    if S.Mov.FOVOn then pcall(function() workspace.CurrentCamera.FieldOfView = 70 end) end
    if S.Mov.GravOn then pcall(function() workspace.Gravity = 196.2 end) end
    if S.World.On then
        pcall(function() Lit.ClockTime = OrigLit.T; Lit.Brightness = OrigLit.B; Lit.GlobalShadows = OrigLit.S; Lit.Ambient = OrigLit.A end)
    end
    if CC[LP] and CC[LP].Hum then CC[LP].Hum.WalkSpeed = 16; CC[LP].Hum.UseJumpPower = true; CC[LP].Hum.JumpPower = 50 end
    for pl, parts in pairs(HBOrig) do for part, d in pairs(parts) do if part and part.Parent then part.Size=d.Size; part.Transparency=d.Trans; part.CanCollide=d.CC end end end
    pcall(function() FOVR:Remove(); FOVF:Remove(); LTracer:Remove() end)
    pcall(function() lockSound:Destroy() end)
    pcall(function() for _, v in pairs(THUD) do v:Remove() end end)
    if W_MARK then W_MARK:Destroy() end
    _env.KAIM_LOADED = false; _G._KaimNC = nil
    Lib:Notify("KAIM unloaded safely.", 4, "power-off")
end)

task.spawn(function()
    while _env.KAIM_LOADED do
        local fps = mFloor(1/mMax(avgDT, 0.001))
        pcall(function()
            lFPS:SetText(("FPS: %d  (%.1fms)"):format(fps, avgDT*1000)); lPL:SetText("Players: "..#PList.." tracked")
            if S.Aim.Target and S.Aim.IsAiming then
                lLck:SetText("LOCKED: " .. S.Aim.Target.DisplayName); Win:SetFooter("v10.1 | LOCKED: " .. S.Aim.Target.DisplayName)
            else
                lLck:SetText("LOCKED: None"); Win:SetFooter("v10.1 | SEARCHING/IDLE")
            end
            if W_MARK and S.Perf.Watermark then W_MARK:SetText(("KAIM v10.1 | FPS: %d"):format(fps)) end
        end)
        task.wait(0.5)
    end
end)

-- ---------- Combat Tab ----------
local AL = T.Combat:AddLeftGroupbox("Aimlock Core")
local AimOnToggle = AL:AddToggle("AimOn", {Text="Enable Aimlock", Default=false, Tooltip="Master switch for the Aimlock system.", Callback=function(v) S.Aim.On=v end})
local AimSettings = AL:AddDependencyBox(); AimSettings:SetupDependencies({{AimOnToggle, true}})

AimSettings:AddLabel("Aim Key"):AddKeyPicker("AimKey",{Default="RightClick", Text="Aim Key", Tooltip="The key used to lock onto targets.", Callback=function(v) S.Aim.Key=v; pcall(function() _aimKC=Enum.KeyCode[v] end) end})
AimSettings:AddToggle("AimWall",   {Text="Wall Check", Default=true, Tooltip="Ensure the target is visible before locking.", Callback=function(v) S.Aim.WallCheck=v end})
AimSettings:AddToggle("AimTeam",   {Text="Team Check", Default=true, Tooltip="Ignore players on your team.", Callback=function(v) S.Aim.TeamCheck=v end})
AimSettings:AddToggle("AimESPOnly",{Text="Only Lock ESP Targets", Default=false, Tooltip="Requires the target's ESP to be rendered.", Callback=function(v) S.Aim.ESPTargetsOnly=v end})
AimSettings:AddToggle("AimNotif",  {Text="Notify on Lock", Default=false, Tooltip="Notification when acquiring a new target.", Callback=function(v) S.Aim.NotifyLock=v end})
AimSettings:AddToggle("AimLTrace", {Text="Lock Tracer Line", Default=false, Tooltip="Draws a line from screen center to your locked target.", Callback=function(v) S.Aim.LockTracer=v end})

local AL2 = T.Combat:AddLeftGroupbox("Smoothing & Prediction")
local AimSettings2 = AL2:AddDependencyBox(); AimSettings2:SetupDependencies({{AimOnToggle, true}})

AimSettings2:AddSlider("AimHC",     {Text="Hit Chance %", Default=100, Min=1, Max=100, Rounding=0, Tooltip="100% means always track perfectly.", Callback=function(v) S.Aim.HitChance=v end})
AimSettings2:AddToggle("AimPred",   {Text="Velocity Prediction", Default=true, Tooltip="Predict target movement based on velocity.", Callback=function(v) S.Aim.Pred=v end})
AimSettings2:AddSlider("AimPStr",   {Text="Pred Strength", Default=0.135, Min=0, Max=0.3, Rounding=3, Tooltip="How far ahead to aim.", Callback=function(v) S.Aim.PredStr=v end})
AimSettings2:AddToggle("AimSmooth", {Text="Smooth Aim", Default=false, Tooltip="Camera glides smoothly to target.", Callback=function(v) S.Aim.Smooth=v end})
AimSettings2:AddSlider("AimSSpd",   {Text="Smooth Speed", Default=0.3, Min=0.05, Max=1, Rounding=2, Tooltip="Lower = slower (legit), higher = snappier.", Callback=function(v) S.Aim.SmoothSpd=v end})
AimSettings2:AddToggle("AimSnd",    {Text="Lock Sound Cue", Default=true, Tooltip="Plays confirmation audio when target locked.", Callback=function(v) S.Aim.SoundCue=v end})

local AR = T.Combat:AddRightGroupbox("Targeting Options")
AR:AddDropdown("AimPri",  {Text="Priority", Values={"Crosshair","Distance"}, Default="Crosshair", Tooltip="How to choose who to lock onto.", Callback=function(v) S.Aim.Priority=v end})
AR:AddDropdown("AimMode", {Text="Aim Mode", Values={"Smart","Nearest Part","Chaos","Head","Neck","Torso","LowerTorso","Limbs","HRP"}, Default="Smart", Tooltip="Which body part to target.", Callback=function(v) S.Aim.Mode=v end})
AR:AddSlider("AimOX",{Text="Offset X", Default=0, Min=-5, Max=5, Rounding=1, Callback=function(v) S.Aim.OffX=v; _aimOff=V3(S.Aim.OffX,S.Aim.OffY,S.Aim.OffZ) end})
AR:AddSlider("AimOY",{Text="Offset Y", Default=0, Min=-5, Max=5, Rounding=1, Callback=function(v) S.Aim.OffY=v; _aimOff=V3(S.Aim.OffX,S.Aim.OffY,S.Aim.OffZ) end})
AR:AddSlider("AimOZ",{Text="Offset Z", Default=0, Min=-5, Max=5, Rounding=1, Callback=function(v) S.Aim.OffZ=v; _aimOff=V3(S.Aim.OffX,S.Aim.OffY,S.Aim.OffZ) end})

local CT_Box = T.Combat:AddRightGroupbox("Current Target")
local lCT_Name = CT_Box:AddLabel("Name: None")
local lCT_HP   = CT_Box:AddLabel("Health: -")
local lCT_Dist = CT_Box:AddLabel("Distance: -")

task.spawn(function()
    while _env.KAIM_LOADED do
        pcall(function()
            lCT_Name:SetText("Name: " .. _liveTargetName)
            lCT_HP:SetText("Health: " .. _liveTargetHP)
            lCT_Dist:SetText("Distance: " .. _liveTargetDist)
        end)
        task.wait(0.1)
    end
end)

-- Triggerbot UI (FIX: was missing)
local TBG = T.Combat:AddRightGroupbox("Triggerbot")
local TBToggle = TBG:AddToggle("TBOn", {Text="Enable Triggerbot", Default=false, Tooltip="Auto-fires when crosshair aligns with an enemy.", Callback=function(v) S.TB.On=v end})
local TBSettings = TBG:AddDependencyBox(); TBSettings:SetupDependencies({{TBToggle, true}})
TBSettings:AddToggle("TBTeam", {Text="Team Check", Default=true, Callback=function(v) S.TB.Team=v end})
TBSettings:AddToggle("TBSph",  {Text="Spherecast", Default=true, Tooltip="Forgiving thick-ray for fast targets.", Callback=function(v) S.TB.Sphere=v end})
TBSettings:AddSlider("TBThk",  {Text="Ray Thickness", Default=0.5, Min=0.1, Max=3, Rounding=1, Callback=function(v) S.TB.Thick=v end})
TBSettings:AddSlider("TBDel",  {Text="Trigger Delay", Default=0.05, Min=0.01, Max=0.5, Rounding=2, Suffix="s", Callback=function(v) S.TB.Delay=v end})
TBSettings:AddSlider("TBHC",   {Text="Hit Chance %", Default=100, Min=1, Max=100, Rounding=0, Callback=function(v) S.TB.HC=v end})

local FG = T.Combat:AddLeftGroupbox("FOV Circle")
local FOVToggle = FG:AddToggle("FOVShow",  {Text="Show FOV", Default=true, Tooltip="Draws the aimlock acquisition radius.", Callback=function(v) S.FOV.Show=v end})
local FOVSettings = FG:AddDependencyBox(); FOVSettings:SetupDependencies({{FOVToggle, true}})

FOVSettings:AddToggle("FOVFol",   {Text="Follow Cursor", Default=true, Callback=function(v) S.FOV.Follow=v end})
FOVSettings:AddToggle("FOVZsc",   {Text="Scale with Zoom", Default=true, Callback=function(v) S.FOV.ZoomScale=v end})
FOVSettings:AddSlider("FOVRad",   {Text="Radius", Default=150, Min=20, Max=600, Rounding=0, Suffix="px", Callback=function(v) S.FOV.Radius=v end})
FOVSettings:AddSlider("FOVThk",   {Text="Thickness", Default=1.5, Min=0.5, Max=5, Rounding=1, Callback=function(v) S.FOV.Thick=v end})
FOVSettings:AddToggle("FOVFill",  {Text="Filled", Default=false, Callback=function(v) S.FOV.Filled=v end})
FOVSettings:AddLabel("Ring Color"):AddColorPicker("FOVCol", {Default=WHITE, Callback=function(v) S.FOV.Color=v end})
FOVSettings:AddLabel("Locked Color"):AddColorPicker("FOVLC",{Default=ORANGE, Callback=function(v) S.FOV.LockCol=v end})

-- ---------- Visuals Tab ----------
local EL = T.Visual:AddLeftGroupbox("ESP Master")
local ESPToggle = EL:AddToggle("ESPOn", {Text="Enable ESP", Default=false, Tooltip="Master switch for all ESP.", Callback=function(v) S.ESP.On=v end})
local ESPSettings = EL:AddDependencyBox(); ESPSettings:SetupDependencies({{ESPToggle, true}})

ESPSettings:AddSlider("ESPDist",  {Text="Max Distance", Default=1000, Min=100, Max=5000, Rounding=0, Suffix="m", Callback=function(v) S.ESP.MaxDist=v; _maxD2=v*v end})
ESPSettings:AddToggle("ESPTeam",  {Text="Team Check", Default=true, Callback=function(v) S.ESP.TeamCheck=v end})

local EL2 = T.Visual:AddLeftGroupbox("ESP Elements")
local ESP2Settings = EL2:AddDependencyBox(); ESP2Settings:SetupDependencies({{ESPToggle, true}})

ESP2Settings:AddToggle("ESPBoxes", {Text="Show Boxes", Default=true, Callback=function(v) S.ESP.Boxes=v end})
ESP2Settings:AddToggle("ESPOutline",{Text="Box Outline", Default=true, Callback=function(v) S.ESP.Outline=v end})
ESP2Settings:AddToggle("ESPBFill", {Text="Box Fill", Default=false, Callback=function(v) S.ESP.BoxFill=v end})
ESP2Settings:AddSlider("ESPBFillT",{Text="Fill Opacity", Default=0.2, Min=0, Max=1, Rounding=2, Callback=function(v) S.ESP.BoxFillT=v end})

local HBToggle = ESP2Settings:AddToggle("ESPHBar",  {Text="Health Bar", Default=true, Callback=function(v) S.ESP.HBar=v end})
local HBSettings = ESP2Settings:AddDependencyBox(); HBSettings:SetupDependencies({{ESPToggle, true}, {HBToggle, true}})
HBSettings:AddToggle("ESPHBTxt", {Text="Show HP Text", Default=true, Callback=function(v) S.ESP.HBarText=v end})
HBSettings:AddSlider("ESPHBThick", {Text="Bar Thickness", Default=2, Min=1, Max=10, Rounding=0, Callback=function(v) S.ESP.HBarThick=v end})
HBSettings:AddSlider("ESPHBOff", {Text="Bar Offset", Default=5, Min=1, Max=20, Rounding=0, Callback=function(v) S.ESP.HBarOff=v end})

local TrToggle = ESP2Settings:AddToggle("ESPTracer", {Text="Tracers", Default=false, Callback=function(v) S.ESP.Tracers=v end})
local TrSettings = ESP2Settings:AddDependencyBox(); TrSettings:SetupDependencies({{ESPToggle, true}, {TrToggle, true}})
TrSettings:AddDropdown("ESPTracerOrg", {Text="Tracer Origin", Values={"Bottom","Center","Top"}, Default="Bottom", Callback=function(v) S.ESP.TracerOrg=v end})
TrSettings:AddLabel("Tracer Color"):AddColorPicker("TrCol", {Default=C3(0, 255, 100), Callback=function(v) S.ESP.TracerCol=v end})

local ER = T.Visual:AddRightGroupbox("Colors & Text")
local ERSettings = ER:AddDependencyBox(); ERSettings:SetupDependencies({{ESPToggle, true}})

ERSettings:AddToggle("ESPVCol",  {Text="Visibility Colors", Default=true, Callback=function(v) S.ESP.VisColors=v end})
ERSettings:AddLabel("Visible"):AddColorPicker("ESPVis",{Default=C3(0, 255, 100), Callback=function(v) S.ESP.VisCol=v end})
ERSettings:AddLabel("Hidden"):AddColorPicker("ESPHid", {Default=RED, Callback=function(v) S.ESP.HideCol=v end})
ERSettings:AddToggle("ESPNames", {Text="Names", Default=true, Callback=function(v) S.ESP.Names=v end})
ERSettings:AddToggle("ESPWep",   {Text="Weapon", Default=false, Callback=function(v) S.ESP.WepShow=v end})
ERSettings:AddToggle("ESPDist2", {Text="Distance", Default=false, Callback=function(v) S.ESP.DistShow=v end})
ERSettings:AddDropdown("ESPCase", {Text="Text Case", Values={"Normal","UPPERCASE"}, Default="UPPERCASE", Callback=function(v) S.ESP.TCase=v end})
ERSettings:AddSlider("ESPFont",  {Text="Font ID", Default=2, Min=0, Max=3, Rounding=0, Callback=function(v) S.ESP.Font=v end})
ERSettings:AddSlider("ESPTSz",   {Text="Text Size", Default=14, Min=10, Max=22, Rounding=0, Callback=function(v) S.ESP.TSize=v end})

local HLBox = T.Visual:AddRightGroupbox("Target HUD")
local HUDToggle = HLBox:AddToggle("ESPHUD", {Text="Enable Target HUD", Default=true, Callback=function(v) S.ESP.HUD=v end})
local HUDSettings = HLBox:AddDependencyBox(); HUDSettings:SetupDependencies({{HUDToggle, true}})
HUDSettings:AddDropdown("HUDStyle", {Text="HUD Style", Values={"Top Premium","Bottom Competitive"}, Default="Top Premium", Callback=function(v) S.ESP.HUDStyle=v end})
HUDSettings:AddSlider("HUDScale", {Text="HUD Scale", Default=1.0, Min=0.5, Max=2.0, Rounding=2, Callback=function(v) S.ESP.HUDScale=v end})

-- ---------- Movement Tab ----------
local ML = T.Player:AddLeftGroupbox("Character Overrides")

local SpdToggle = ML:AddToggle("MovSpeedOn", {Text="Override WalkSpeed", Default=false, Callback=function(v) S.Mov.SpeedOn=v; if not v and CC[LP] and CC[LP].Hum then CC[LP].Hum.WalkSpeed=16 end end})
local SpdSettings = ML:AddDependencyBox(); SpdSettings:SetupDependencies({{SpdToggle, true}})
SpdSettings:AddSlider("MovSpeed", {Text="WalkSpeed", Default=16, Min=16, Max=150, Rounding=0, Callback=function(v) S.Mov.Speed=v end})

local JmpToggle = ML:AddToggle("MovJumpOn", {Text="Override JumpPower", Default=false, Callback=function(v) S.Mov.JumpOn=v; if not v and CC[LP] and CC[LP].Hum then CC[LP].Hum.UseJumpPower=true; CC[LP].Hum.JumpPower=50 end end})
local JmpSettings = ML:AddDependencyBox(); JmpSettings:SetupDependencies({{JmpToggle, true}})
JmpSettings:AddSlider("MovJump", {Text="JumpPower", Default=50, Min=50, Max=200, Rounding=0, Callback=function(v) S.Mov.Jump=v end})

local GravToggle = ML:AddToggle("MovGravOn", {Text="Override Gravity", Default=false, Callback=function(v) S.Mov.GravOn=v; if not v then workspace.Gravity = 196.2 end end})
local GravSettings = ML:AddDependencyBox(); GravSettings:SetupDependencies({{GravToggle, true}})
GravSettings:AddSlider("MovGrav", {Text="Gravity", Default=196.2, Min=0, Max=500, Rounding=1, Callback=function(v) S.Mov.Gravity=v end})

local ML_Fun = T.Player:AddLeftGroupbox("Movement Enhancements")
ML_Fun:AddToggle("MovBHop", {Text="Bunny Hop", Default=false, Callback=function(v) S.Mov.BHop=v end})
ML_Fun:AddToggle("MovInfJump", {Text="Infinite Jump", Default=false, Callback=function(v) S.Mov.InfJump=v end})

-- Hitbox UI (FIX: was missing)
local HBG = T.Player:AddLeftGroupbox("Hitbox Expander")
local HBEnToggle = HBG:AddToggle("HBOn", {Text="Enable Hitbox Expand", Default=false, Tooltip="Scales enemy hitbox parts larger for easier hits.", Callback=function(v) S.HB.On=v end})
local HBDepSettings = HBG:AddDependencyBox(); HBDepSettings:SetupDependencies({{HBEnToggle, true}})
HBDepSettings:AddDropdown("HBPart", {Text="Target Part", Values={"Head","HumanoidRootPart","UpperTorso"}, Default="Head", Callback=function(v) S.HB.Part=v end})
HBDepSettings:AddSlider("HBSize", {Text="Hitbox Size", Default=5, Min=2, Max=30, Rounding=0, Callback=function(v) S.HB.Size=v end})
HBDepSettings:AddSlider("HBTrans", {Text="Transparency", Default=0.5, Min=0, Max=1, Rounding=2, Callback=function(v) S.HB.Trans=v end})

local MR = T.Player:AddRightGroupbox("World & Exploits")

-- World Lighting UI (FIX: was missing)
local WorldToggle = MR:AddToggle("WorldOn", {Text="Override Lighting", Default=false, Tooltip="Override server day/night cycle.", Callback=function(v) S.World.On=v; if not v then pcall(function() Lit.ClockTime=OrigLit.T; Lit.Brightness=OrigLit.B; Lit.GlobalShadows=OrigLit.S; Lit.Ambient=OrigLit.A end) end end})
local WorldSettings = MR:AddDependencyBox(); WorldSettings:SetupDependencies({{WorldToggle, true}})
WorldSettings:AddSlider("WorldTime", {Text="Time of Day", Default=14, Min=0, Max=24, Rounding=1, Callback=function(v) S.World.Time=v end})
WorldSettings:AddSlider("WorldBright", {Text="Brightness", Default=2, Min=0, Max=5, Rounding=1, Callback=function(v) S.World.Bright=v end})
WorldSettings:AddToggle("WorldShadow", {Text="Global Shadows", Default=false, Callback=function(v) S.World.Shadows=v end})
WorldSettings:AddLabel("Ambient"):AddColorPicker("WorldAmb", {Default=WHITE, Callback=function(v) S.World.Ambient=v end})

MR:AddToggle("NCOn",{Text="Noclip", Default=false, Tooltip="Walk through walls.", Callback=function(v) SetNC(v) end})
MR:AddLabel("Noclip Key"):AddKeyPicker("NCKey",{Default="N", Text="Noclip Key", Callback=function(v) S.Mov.NoclipKey=v end})

local SpinToggle = MR:AddToggle("MovSpinOn", {Text="Spinbot (Anti-Aim)", Default=false, Callback=function(v) S.Mov.Spinbot=v end})
local SpinSettings = MR:AddDependencyBox(); SpinSettings:SetupDependencies({{SpinToggle, true}})
SpinSettings:AddSlider("MovSpinSpd", {Text="Spin Speed", Default=20, Min=1, Max=100, Rounding=0, Callback=function(v) S.Mov.SpinSpeed=v end})

MR:AddLabel("Blink to Target"):AddKeyPicker("BlinkKey", {Default="None", Text="Blink", Tooltip="Teleport 4 studs behind your locked target.", Callback=function(v) S.Mov.BlinkKey=v; pcall(function() _blinkKC=Enum.KeyCode[v] end) end})

local FOVTog = MR:AddToggle("CamFOVOn", {Text="Override Camera FOV", Default=false, Callback=function(v) S.Mov.FOVOn=v; if not v then pcall(function() workspace.CurrentCamera.FieldOfView = 70 end) end end})
local FOVSett = MR:AddDependencyBox(); FOVSett:SetupDependencies({{FOVTog, true}})
FOVSett:AddSlider("CamFOV", {Text="Camera FOV", Default=70, Min=10, Max=120, Rounding=0, Callback=function(v) S.Mov.CamFOV=v end})

-- ---------- Config Tab ----------
local CL = T.Config:AddLeftGroupbox("Save / Load")
local CR = T.Config:AddRightGroupbox("Performance & Actions")
CR:AddToggle("PerfWM",  {Text="FPS Watermark", Default=true, Callback=function(v) S.Perf.Watermark=v; if W_MARK then W_MARK:SetVisible(v) end end})
CR:AddSlider("PerfLOD", {Text="LOD Distance", Default=500, Min=100, Max=2000, Rounding=0, Suffix="m", Tooltip="Players beyond this get simplified ESP (no tracers, weapon, raycasts).", Callback=function(v) S.Perf.LOD=v; _lodD2=v*v end})

CL:AddToggle("CfgProf", {Text="Use Game Profiles", Default=false, Callback=function(v)
    S.Cfg.GameProfile=v; if v then SM:SetSubFolder(tostring(game.PlaceId)) else SM:SetSubFolder("") end
end})

SM:SetLibrary(Lib); SM:IgnoreThemeSettings(); SM:SetIgnoreIndexes({"AimKey","NCKey", "BlinkKey"})
SM:SetFolder("KAIM_v10"); SM:BuildConfigSection(T.Config)
TM:SetLibrary(Lib); TM:SetFolder("KAIM_v10"); TM:ApplyToTab(T.Config); TM:LoadDefault()

local DG = T.Config:AddLeftGroupbox("Danger Zone")
DG:AddButton("Unload KAIM", function()
    Win:AddDialog("UnloadConfirm", {
        Title = "Confirm Unload", Description = "Are you sure you want to completely unload KAIM?", AutoDismiss = true,
        FooterButtons = {
            Cancel = {Title = "Cancel", Variant = "Secondary"},
            Confirm = {Title = "Unload", Variant = "Destructive", Callback = function()
                ClearTarget()
                for i = 1, #Conns do pcall(function() Conns[i]:Disconnect() end) end
                for _, e in pairs(ESPObj) do DelE(e) end; ESPObj = {}
                SetNC(false)
                if S.Mov.FOVOn then pcall(function() workspace.CurrentCamera.FieldOfView = 70 end) end
                if S.Mov.GravOn then pcall(function() workspace.Gravity = 196.2 end) end
                if S.World.On then pcall(function() Lit.ClockTime=OrigLit.T; Lit.Brightness=OrigLit.B; Lit.GlobalShadows=OrigLit.S; Lit.Ambient=OrigLit.A end) end
                if CC[LP] and CC[LP].Hum then CC[LP].Hum.WalkSpeed = 16; CC[LP].Hum.UseJumpPower = true; CC[LP].Hum.JumpPower = 50 end
                for pl, parts in pairs(HBOrig) do for part, d in pairs(parts) do if part and part.Parent then part.Size=d.Size; part.Transparency=d.Trans; part.CanCollide=d.CC end end end
                pcall(function() FOVR:Remove(); FOVF:Remove(); LTracer:Remove() end)
                pcall(function() lockSound:Destroy() end)
                pcall(function() for _, v in pairs(THUD) do v:Remove() end end)
                if W_MARK then W_MARK:Destroy() end
                _env.KAIM_LOADED = false; _G._KaimNC = nil
                Lib:Notify("KAIM unloaded safely.", 4, "power-off")
            end}
        }
    })
end)

-- ==============================================================================
--  13. INPUT HANDLING
-- ==============================================================================
tIns(Conns, UIS.JumpRequest:Connect(function()
    if S.Mov.InfJump and LP.Character and CC[LP] and CC[LP].Hum then
        CC[LP].Hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

tIns(Conns, UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == _blinkKC and S.Aim.Target then
        local tc = CC[S.Aim.Target]
        local mc = CC[LP]
        if tc and tc.HRP and mc and mc.HRP then
            mc.HRP.CFrame = tc.HRP.CFrame * CFrame.new(0, 0, 4)
            Lib:Notify("Blinked to " .. S.Aim.Target.DisplayName, 2, "zap")
        end
    elseif inp.KeyCode.Name == S.Mov.NoclipKey then
        local ns = not S.Mov.Noclip; SetNC(ns); Lib:Notify("Noclip "..(ns and "ON" or "OFF"), 2, "ghost")
    elseif inp.KeyCode == _aimKC or (S.Aim.Key == "RightClick" and inp.UserInputType == Enum.UserInputType.MouseButton2) then
        S.Aim.IsAiming = true
        S.Aim.HasLockedThisPress = false
    end
end))

tIns(Conns, UIS.InputEnded:Connect(function(inp)
    if inp.KeyCode == _aimKC or (S.Aim.Key == "RightClick" and inp.UserInputType == Enum.UserInputType.MouseButton2) then
        S.Aim.IsAiming = false
        S.Aim.HasLockedThisPress = false
    end
end))

SM:LoadAutoloadConfig()
Lib:Notify("KAIM v10.1 loaded — Press K to toggle.", 4, "check")

end, debug.traceback)
if not ok then warn("KAIM FATAL:\n"..tostring(err)) end
end)
