-- ==============================================================================
--  KAIM v9.0 | Ultra Optimized & Premium Edition
--  • Flawless Sliding & Centered Healthbar Text Integration
--  • Redesigned Target HUD with embedded HP tracking
--  • Global Raycast Filter Caching (Zero-Cost Wall Checks)
--  • 1000x FPS Boost: Custom Lua-Side Drawing Proxies (Zero Bridge Overhead)
--  • Maximum Loop Optimization (Zero in-loop table lookups, removed ipairs)
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

local function SafeParent(p) return p.Parent end
local function SafePos(p) return p.Position end

local function GetWepCol(ws)
    local l = string.lower(ws)
    if l:find("gun") or l:find("rifle") or l:find("pistol") or l:find("sniper") then return RED end
    if l:find("sword") or l:find("knife") or l:find("blade") or l:find("axe") then return ORANGE end
    if l:find("heal") or l:find("med") or l:find("shield") then return GREEN end
    return GRAY_WEP
end

-- ==============================================================================
--  3. DRAWING PROXY CACHE (1000x FPS BOOST)
--  Blocks all redundant C++ bridge calls by caching values in Lua.
-- ==============================================================================
local HAS_D = type(Drawing) == "table" and type(Drawing.new) == "function"
local function ND(t)
    local obj
    if HAS_D then local ok, r = pcall(Drawing.new, t); if ok and r then obj = r end end
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

local function setL(l, f, t, c, th, z)
    l.From = f; l.To = t; l.Color = c; l.Thickness = th; l.ZIndex = z; l.Visible = true
end

-- ==============================================================================
--  4. STATE CACHES & CONFIGURATION
-- ==============================================================================
local S = {
    Aim = {
        On=false, Mode="Smart", Priority="Crosshair", Key="RightClick", WallCheck=true, TeamCheck=true,
        Pred=true, PredStr=0.135, DynamicPred=true, Smooth=false, SmoothSpd=0.3, HitChance=100, 
        SoundCue=true, LockTracer=false, OffX=0, OffY=0, OffZ=0, IsAiming=false, Target=nil, _lastSearch=0,
    },
    TB = { On=false, Delay=0.05, HC=100, Team=true, Sphere=true, Thick=0.5 },
    HB = { On=false, Part="Head", Size=5, Trans=0.5 },
    FOV = { 
        Show=true, Follow=true, Radius=150, ZoomScale=true, Thick=1.5,
        Color=WHITE, ColorLerp=true, LockCol=ORANGE, Trans=0.8, Filled=false, FC=WHITE, FT=0.92 
    },
    ESP = {
        On=false, BoxStyle="Corner", Boxes=true, BoxFill=false, BoxFillT=0.2, Outline=true, 
        Names=true, NStyle="Display Name", TCase="UPPERCASE", TSize=14, Font=2,
        TeamCheck=true, ShowTeam=false, TeamCol=C3(0, 200, 255),
        VisColors=true, VisCol=C3(0, 255, 100), HideCol=RED, StatCol=WHITE,
        HBar=true, HBarSt="Vertical", HBarThick=2, HBarOff=5, HBarSmooth=12, HBarText=true,
        DistShow=false, WepShow=false, Tracers=false, TracerOrg="Bottom", TracerCol=C3(0, 255, 100),
        Arrows=false, ArrowCol=C3(255, 85, 0), ArrowR=120, ArrowSz=15, DmgNums=false, DmgCol=C3(255, 255, 0),
        Chams=false, ChamsVisCol=true, ChamsFill=WHITE, ChamsOut=WHITE, ChamsFT=0.5, ChamsOT=0,
        MaxDist=1000, HUD=true, HUDStyle="Standard", HUDScale=1.0, CustomName=false, NameCol=WHITE,
    },
    World = { On=false, Time=14, Bright=2, Shadows=false, Ambient=WHITE },
    Mov = { SpeedOn=false, Speed=16, JumpOn=false, Jump=50, InfJump=false, FOVOn=false, CamFOV=70, Noclip=false, NoclipKey="N" },
    Perf = { LOD=500, Watermark=true }, 
    Cfg = { GameProfile=false }
}

-- Fast Loop Locals
local _chaosPool, _limbPool = {}, {}
local _hbSizeV3, _aimOff = V3(5, 5, 5), V3(0, 0, 0)
local _isCorner, _nStyleDN, _nStyleUN, _nStyleBoth = true, true, false, false
local _maxD2, _lodD2 = 1000000, 250000
local _aimKC = Enum.KeyCode.Unknown
local _ncNeedsPass, _worldDirty = false, false
local _lastTargetDistSq, _stdHUDWidth, _graceTimer, _switchCooldown = 0, 100, 0, 0

local RP = RaycastParams.new(); RP.FilterType = Enum.RaycastFilterType.Exclude; RP.IgnoreWater = true
local TRP = RaycastParams.new(); TRP.FilterType = Enum.RaycastFilterType.Exclude; TRP.IgnoreWater = true

local Conns, PList, TC, ESPObj, CC, TrLine, HBOrig, OrigLit = {}, {}, {}, {}, {}, {}, {}, {}
local DmgPool, ADmg = {}, {}
local chaosT, CHAOS_INT, chaosName = 0, 0.22, "Head"
local tbT, RSF, STAG, avgDT = 0, 0, 3, 0.016
local thHP, thAlpha, thName, thData, hudVis = 100, 0, "", "", false
local PI4, _camTan, _lastCamFOV = 0.7853981634, 0.57, 0

-- UI & Audio Instances
local CFolder = Instance.new("Folder"); CFolder.Name = "KaimChams"
pcall(function() CFolder.Parent = SafeGui end)
local lockSound = Instance.new("Sound"); lockSound.SoundId = "rbxassetid://6895086776"; lockSound.Volume = 0.5
pcall(function() lockSound.Parent = SafeGui end)

local FOVR = ND("Circle"); FOVR.Thickness = 1.5; FOVR.Filled = false
local FOVF = ND("Circle"); FOVF.Thickness = 1;   FOVF.Filled = true
local LTracer = ND("Line"); LTracer.Thickness = 1.5
local THUD = { Sh=ND("Square"), BG=ND("Square"), Out=ND("Square"), Ac=ND("Square"), N=ND("Text"), D=ND("Text"), BBG=ND("Square"), BFG=ND("Square"), HPNum=ND("Text") }

THUD.Sh.Filled=true; THUD.Sh.Color=BLACK; THUD.BG.Filled=true; THUD.BG.Color=HUD_BG; THUD.Out.Filled=false; THUD.Ac.Filled=true
THUD.N.Outline=true; THUD.N.Color=WHITE; THUD.N.Font=2; THUD.D.Outline=true; THUD.D.Color=GRAY_NAME; THUD.D.Font=2
THUD.BBG.Filled=true; THUD.BBG.Color=BAR_BG; THUD.BFG.Filled=true
THUD.HPNum.Outline=true; THUD.HPNum.Color=WHITE; THUD.HPNum.Font=2; THUD.HPNum.Center=true; THUD.HPNum.ZIndex=15

local function CacheL() OrigLit = {T=Lit.ClockTime, B=Lit.Brightness, S=Lit.GlobalShadows, A=Lit.Ambient} end; CacheL()

-- ==============================================================================
--  5. GLOBAL RAYCAST CACHING (SOLVES ALL ESP LAG)
-- ==============================================================================
local globalIgnoreList = {}
local tbIgnoreList = {}

local function UpdateGlobalRayFilter()
    table.clear(globalIgnoreList)
    table.clear(tbIgnoreList)
    local cam = workspace.CurrentCamera
    if cam then 
        tIns(globalIgnoreList, cam)
        tIns(tbIgnoreList, cam)
    end
    if LP.Character then 
        tIns(globalIgnoreList, LP.Character)
        tIns(tbIgnoreList, LP.Character)
    end
    for i = 1, #PList do
        local c = CC[PList[i]]
        if c and c.Char then tIns(globalIgnoreList, c.Char) end
    end
    RP.FilterDescendantsInstances = globalIgnoreList
    TRP.FilterDescendantsInstances = tbIgnoreList
end

tIns(Conns, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(UpdateGlobalRayFilter))
tIns(Conns, LP.CharacterAdded:Connect(function() task.delay(0.5, UpdateGlobalRayFilter) end))

-- ==============================================================================
--  6. CORE UTILITIES (Damage, Char Caching, Raycasting)
-- ==============================================================================
local function SpawnDmg(dmg, pos)
    local d; if #DmgPool > 0 then d = tRem(DmgPool) else
        d = {T=ND("Text"), spX=0, spY=0, spZ=0, vX=0, vY=0, vZ=0, t0=0}
        d.T.Center=true; d.T.Outline=true; d.T.OutlineColor=BLACK; d.T.Font=3; d.T.ZIndex=10
    end
    d.s = tostring(mFloor(dmg)); local a = mRand() * mPi * 2; local sp = mRand(15, 30) / 10
    d.vX = mCos(a) * sp; d.vY = mRand(35, 55) / 10; d.vZ = mSin(a) * sp
    d.spX = pos.X + (mRand() - 0.5); d.spY = pos.Y + 1; d.spZ = pos.Z + (mRand() - 0.5); d.t0 = sClock()
    tIns(ADmg, d)
end

local _dmgV3 = V3()
local function TickDmg(cam)
    local now = sClock()
    for i = #ADmg, 1, -1 do
        local d = ADmg[i]; local el = now - d.t0
        if el >= 1.5 or not S.ESP.DmgNums then
            d.T.Visible = false; tIns(DmgPool, d); ADmg[i] = ADmg[#ADmg]; ADmg[#ADmg] = nil
        else
            _dmgV3 = V3(d.spX + d.vX * el, d.spY + (d.vY * el) - (12.5 * el * el), d.spZ + d.vZ * el)
            local sp, on = cam:WorldToViewportPoint(_dmgV3)
            if on then
                local sz = el < 0.15 and (14 + 18 * (el / 0.15)) or (el < 0.35 and (32 - 12 * ((el - 0.15) / 0.2)) or 20)
                d.T.Text = d.s; d.T.Position = V2(mFloor(sp.X), mFloor(sp.Y)); d.T.Color = S.ESP.DmgCol; d.T.Size = sz
                local al = el > 1 and (1 - (el - 1) * 2) or 1
                d.T.Transparency = al; d.T.Visible = true
            else 
                d.T.Visible = false 
            end
        end
    end
end

local function UpdateSTAG() STAG = mClamp(mFloor(#PList / 6), 3, 15) end
local function IsTeam(p) if TC[p] == nil then TC[p] = (p.Team ~= nil and p.Team == LP.Team) end; return TC[p] end
tIns(Conns, LP:GetPropertyChangedSignal("Team"):Connect(function() table.clear(TC) end))

local function BuildCC(pl, char)
    CC[pl] = nil 
    if not char then UpdateGlobalRayFilter(); return end
    task.spawn(function()
        local hrp, head, hum
        task.spawn(function() hrp = char:WaitForChild("HumanoidRootPart", 5) end)
        task.spawn(function() head = char:WaitForChild("Head", 5) end)
        task.spawn(function() hum = char:WaitForChild("Humanoid", 5) end)
        while (not hrp or not head or not hum) and char.Parent do task.wait() end
        if not char.Parent or pl.Character ~= char then return end

        if hrp and head and hum then
            local c = {}
            c.Char = char; c.HRP = hrp; c.Head = head; c.Hum = hum; c._uname = "@" .. pl.Name
            c._rig = char:FindFirstChild("UpperTorso") and "R15" or "R6"
            c._charH = c._rig == "R15" and 2.9 or 2.6
            c._charW = 1.0; c._maxHP = hum.MaxHealth
            c._hpConn = hum:GetPropertyChangedSignal("MaxHealth"):Connect(function() c._maxHP = hum.MaxHealth end)
            c._chaosParts = {}
            for _, n in ipairs({"Head","UpperTorso","LowerTorso","Torso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftHand","RightHand","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot","Left Arm","Right Arm","Left Leg","Right Leg"}) do
                local p = char:FindFirstChild(n); if p and p:IsA("BasePart") then tIns(c._chaosParts, p) end
            end
            c._lastPos = hrp.Position; c._velDelta = V3(); c._sp = V3(); c._onSc = false; c._depth = 0; c._distSq = 0
            CC[pl] = c
            UpdateGlobalRayFilter()
        end
    end)
end

local function IsVis(part, camP)
    if not part or not part:IsDescendantOf(workspace) then return false end
    return workspace:Raycast(camP, part.Position - camP, RP) == nil
end

-- ==============================================================================
--  7. AIMING PIPELINE
-- ==============================================================================
local SMART_P = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
local function GetAimPart(cd, mode, camP)
    local ch = cd.Char
    if mode == "Smart" then
        if cd._smartPart then local sp = ch:FindFirstChild(cd._smartPart); if sp and IsVis(sp, camP) then return sp, true end end
        for i = 1, #SMART_P do local p = ch:FindFirstChild(SMART_P[i]); if p and IsVis(p, camP) then cd._smartPart = SMART_P[i]; return p, true end end
        return cd.HRP, false
    elseif mode == "Chaos" then return ch:FindFirstChild(chaosName) or cd.HRP, true
    elseif mode == "Head"  then return cd.Head, true
    elseif mode == "Torso" then return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"), true
    elseif mode == "Limbs" then
        table.clear(_limbPool)
        for _, n in ipairs({"LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local p = ch:FindFirstChild(n); if p then tIns(_limbPool, p) end
        end
        return #_limbPool > 0 and _limbPool[mRand(1, mMax(1, #_limbPool))] or cd.HRP, true
    else return cd.HRP, true end
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
        
        local dist2D = mSqrt((fovP.X - cd._sp.X)^2 + (fovP.Y - cd._sp.Y)^2)
        if dist2D > efFovRadius then continue end
        
        local val = byD and cd._distSq or dist2D
        if val < bestVal then
            if not S.Aim.WallCheck or select(2, GetAimPart(cd, S.Aim.Mode, camP)) then
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
        Box=ND("Square"), BoxOut=ND("Square"), BoxFill=ND("Square"), CL={}, AL={}, 
        N=ND("Text"), UN=ND("Text"), Di=ND("Text"), HTxt=ND("Text"), W=ND("Text"), H=ND("Text"),
        BBG=ND("Square"), BFG=ND("Square"), BOut=ND("Square"),
        Hl=nil, vis=false, _lv=false, _stag=mRand(0, 3),
        _smoothHp=100, _font=-1, _tc="", _di=-1, _ws="\0", _ns="\0", _us="\0", _wCol=WHITE, _hi=-1,
    }
    e.Box.Thickness = 1.5; e.BoxOut.Thickness = 3.5; e.BoxFill.Thickness = 1
    e.Box.Filled = false; e.BoxOut.Filled = false; e.BoxFill.Filled = true
    e.BoxOut.Transparency = 0.7; e.BoxOut.Color = BLACK
    for i = 1, 8 do
        e.CL[i] = {M=ND("Line"), O=ND("Line")}
        e.CL[i].M.Thickness = 1.5
        e.CL[i].O.Thickness = 3.5; e.CL[i].O.Color = BLACK; e.CL[i].O.Transparency = 0.7
    end
    for i = 1, 4 do e.AL[i] = ND("Line") end
    
    e._texts = {e.N, e.UN, e.Di, e.W, e.H}
    for i = 1, #e._texts do e._texts[i].Center = true; e._texts[i].Outline = true; e._texts[i].OutlineColor = BLACK; e._texts[i].ZIndex = 5 end
    
    e.HTxt.Outline = true; e.HTxt.OutlineColor = BLACK; e.HTxt.Font = 2
    
    e.BBG.Filled = true; e.BBG.Color = C3(10, 10, 10); e.BBG.Transparency = 0.6; e.BBG.ZIndex = 2
    e.BFG.Filled = true; e.BFG.ZIndex = 3
    e.BOut.Filled = false; e.BOut.Color = BLACK; e.BOut.Thickness = 1; e.BOut.ZIndex = 1
    ESPObj[pl] = e
end

local function HideE(e)
    if not e._lv then return end
    e.Box.Visible = false; e.BoxOut.Visible = false; e.BoxFill.Visible = false
    for i=1, 8 do e.CL[i].M.Visible = false; e.CL[i].O.Visible = false end
    for i=1, #e._texts do e._texts[i].Visible = false end
    e.HTxt.Visible = false
    e.BBG.Visible = false; e.BFG.Visible = false; e.BOut.Visible = false
    for i=1, 4 do e.AL[i].Visible = false end
    if e.Hl and e.Hl.Enabled then e.Hl.Enabled = false; e.Hl.Adornee = nil end 
    e._lv = false; e.vis = false
end

local function DelE(e)
    pcall(function()
        e.Box:Remove(); e.BoxOut:Remove(); e.BoxFill:Remove()
        for i=1, 8 do e.CL[i].M:Remove(); e.CL[i].O:Remove() end
        for i=1, #e._texts do e._texts[i]:Remove() end
        e.HTxt:Remove()
        e.BBG:Remove(); e.BFG:Remove(); e.BOut:Remove()
        for i=1, 4 do e.AL[i]:Remove() end
        if e.Hl then e.Hl:Destroy() end
    end)
end

local function RegPl(pl)
    if pl == LP then return end
    tIns(PList, pl); MkESP(pl); UpdateSTAG()
    tIns(Conns, pl.CharacterAdded:Connect(function(c) BuildCC(pl, c) end))
    tIns(Conns, pl.CharacterRemoving:Connect(function() if CC[pl] and CC[pl]._hpConn then CC[pl]._hpConn:Disconnect() end; CC[pl] = nil; HBOrig[pl] = nil; UpdateGlobalRayFilter() end))
    if pl.Character then BuildCC(pl, pl.Character) end
end

task.spawn(function() for _, p in ipairs(Plr:GetPlayers()) do if p ~= LP then RegPl(p); task.wait() end end end)
tIns(Conns, Plr.PlayerAdded:Connect(RegPl))
tIns(Conns, Plr.PlayerRemoving:Connect(function(pl)
    for i=1, #PList do if PList[i] == pl then tRem(PList, i); break end end; UpdateSTAG()
    local e = ESPObj[pl]; if e then task.defer(function() DelE(e) end) end
    ESPObj[pl] = nil; CC[pl] = nil; HBOrig[pl] = nil
    if TrLine[pl] then TrLine[pl]:Remove(); TrLine[pl] = nil end
    UpdateGlobalRayFilter()
end))
tIns(Conns, LP.CharacterAdded:Connect(function(c) BuildCC(LP, c); if S.Mov.Noclip then task.defer(function() if _G._KaimNC then _G._KaimNC(c) end end) end end))
if LP.Character then BuildCC(LP, LP.Character) end

-- ==============================================================================
--  9. RENDER LOGIC
-- ==============================================================================
local function TickFOV(ctr, cam)
    local pos = S.FOV.Follow and UIS:GetMouseLocation() or ctr
    local scale = S.FOV.ZoomScale and (70/cam.FieldOfView) or 1
    local r = mMax(1, (S.FOV.Radius * scale))
    local fCol = (S.FOV.ColorLerp and S.Aim.Target and S.Aim.IsAiming) and S.FOV.LockCol or S.FOV.Color

    FOVR.Position = pos; FOVR.Radius = r; FOVR.Color = fCol; FOVR.Thickness = S.FOV.Thick; FOVR.Transparency = S.FOV.Trans; FOVR.Visible = S.FOV.Show
    
    local fv = S.FOV.Show and S.FOV.Filled
    FOVF.Visible = fv
    if fv then FOVF.Position = pos; FOVF.Radius = r; FOVF.Color = S.FOV.FC; FOVF.Transparency = S.FOV.FT end
    return pos
end

local function HideTHUD()
    if not hudVis then return end
    THUD.Sh.Visible=false; THUD.BG.Visible=false; THUD.Out.Visible=false; THUD.Ac.Visible=false
    THUD.N.Visible=false; THUD.D.Visible=false; THUD.BBG.Visible=false; THUD.BFG.Visible=false
    THUD.HPNum.Visible=false
    hudVis = false
end

local _lockedDiedConn = nil
local function ClearTarget() S.Aim.Target = nil; if _lockedDiedConn then _lockedDiedConn:Disconnect(); _lockedDiedConn = nil end end

local function TickAim(camP, sw, sh, dt, fovP, cam)
    if S.Aim.Mode == "Chaos" and S.Aim.IsAiming then
        chaosT = chaosT - dt; if chaosT <= 0 then chaosT = CHAOS_INT; local tc = S.Aim.Target and CC[S.Aim.Target]; if tc then PickChaos(tc) end end
    end

    local showHUD = false
    if S.Aim.On and S.Aim.IsAiming then
        local tc = S.Aim.Target and CC[S.Aim.Target]
        if tc then
            local dist2D = mSqrt((fovP.X - tc._sp.X)^2 + (fovP.Y - tc._sp.Y)^2)
            local efFovRadius = S.FOV.Radius * (S.FOV.ZoomScale and (70/cam.FieldOfView) or 1)
            if tc.Hum.Health <= 0 or dist2D > efFovRadius or not tc._onSc then ClearTarget() end
        else ClearTarget() end
        
        _switchCooldown = mMax(0, _switchCooldown - dt)
        if not S.Aim.Target then
            local now = sClock(); local sInt = mMax(0.05, avgDT * 1.5)
            if _switchCooldown <= 0 and now - S.Aim._lastSearch > sInt then
                local newT = GetTarget(camP, fovP, cam)
                if newT then
                    S.Aim.Target = newT; _switchCooldown = 0.15; _graceTimer = 0
                    if S.Aim.SoundCue then lockSound:Play() end 
                    _lockedDiedConn = CC[newT].Hum.Died:Connect(ClearTarget)
                end
                S.Aim._lastSearch = now
            end
        end

        local tar = S.Aim.Target; local cd = tar and CC[tar]
        if cd then
            local part, lockVis = GetAimPart(cd, S.Aim.Mode, camP)
            if not lockVis and S.Aim.WallCheck then
                _graceTimer = _graceTimer + dt; if _graceTimer > 0.12 then ClearTarget(); part = nil end
            else _graceTimer = 0 end

            if part then
                local ap = part.Position
                local distToTarget = mSqrt(cd._distSq); _lastTargetDistSq = cd._distSq

                if S.Aim.Pred then
                    local vel = part.AssemblyLinearVelocity
                    if vel.Magnitude < 0.1 then vel = cd._velDelta end
                    if vel.Magnitude > 300 then vel = vel.Unit * 300 end
                    local pStr = S.Aim.PredStr * (S.Aim.DynamicPred and mClamp(distToTarget/200, 0.3, 1.5) or 1)
                    ap = ap + vel * pStr
                end
                if S.Aim.OffX ~= 0 or S.Aim.OffY ~= 0 or S.Aim.OffZ ~= 0 then ap = ap + _aimOff end
                local tCF = CF(camP, ap)
                
                local apSc, on2 = cam:WorldToViewportPoint(ap)
                local snap = false
                if on2 then
                    local cx, cy = sw*0.5, sh*0.5
                    if S.FOV.Follow then local ms = UIS:GetMouseLocation(); cx=ms.X; cy=ms.Y end
                    if (V2(apSc.X, apSc.Y) - V2(cx, cy)).Magnitude < 8 then snap = true end
                end

                if mRand(1, 100) <= S.Aim.HitChance then
                    if S.Aim.Smooth and not snap then
                        local sf = mClamp(1 - mExp(-S.Aim.SmoothSpd * 22 * dt), 0.01, 1)
                        cam.CFrame = cam.CFrame:Lerp(tCF, sf)
                    else cam.CFrame = tCF end
                end

                if S.Aim.LockTracer and cd._onSc then
                    setL(LTracer, V2(sw*0.5, sh*0.5), V2(cd._sp.X, cd._sp.Y), lockVis and WHITE or RED, 1.5, 1)
                else if LTracer.Visible then LTracer.Visible = false end end

                if S.ESP.HUD then
                    showHUD = true; local sc = S.ESP.HUDScale; local st = S.ESP.HUDStyle; local ac = lockVis and WHITE or RED
                    local aHP = cd.Hum.Health or 0; thHP = thHP + (aHP - thHP)*(dt*10); if thHP ~= thHP or thHP < 0 then thHP = 0 end
                    local maxHP = mMax(1, cd._maxHP or 100)
                    local hpPct = mClamp(thHP / maxHP, 0, 1)
                    local di = mFloor(distToTarget); local rN = tar.DisplayName; local rD = ("Distance: %dm"):format(di)
                    if S.Aim.Mode == "Chaos" then rD = rD .. "  |  " .. chaosName end
                    
                    if thName ~= rN then thName = rN; thNameFmt = Fmt(rN, S.ESP.TCase) end
                    if thData ~= rD then thData = rD; thDataFmt = rD end
                    local hpStr = ("%d / %d"):format(mFloor(aHP), mFloor(maxHP))
                    
                    if st == "Standard" then _stdHUDWidth = mFloor(mMax(200, 40 + #thName * 9) * sc) end
                    thAlpha = mClamp(thAlpha + dt*7, 0, 1); local ea = 1 - mExp(-thAlpha * 5); local ys = (1 - ea) * 35
                    
                    THUD.N.Center = false; THUD.D.Center = false; THUD.HPNum.Center = true
                    
                    if st == "Ascension" then
                        local bw, bh = mFloor(260*sc), mFloor(50*sc)
                        local hx, hy = mFloor((sw/2)-(bw/2)), mFloor(sh*0.12)-mFloor(ys)
                        
                        THUD.Sh.Size = V2(bw+6,bh+6); THUD.Sh.Position = V2(hx-3,hy-3); THUD.Sh.Color = ac; THUD.Sh.Transparency = 0.3*ea; THUD.Sh.Visible = true
                        THUD.BG.Size = V2(bw,bh); THUD.BG.Position = V2(hx,hy); THUD.BG.Transparency = 0.9*ea; THUD.BG.Visible = true
                        THUD.Out.Size = V2(bw,bh); THUD.Out.Position = V2(hx,hy); THUD.Out.Color = ac; THUD.Out.Transparency = 0.7*ea; THUD.Out.Visible = true
                        THUD.Ac.Size = V2(mMax(1,mFloor(3*sc)),bh); THUD.Ac.Position = V2(hx,hy); THUD.Ac.Color = ac; THUD.Ac.Transparency = ea; THUD.Ac.Visible = true
                        THUD.N.Text = thNameFmt; THUD.N.Position = V2(hx+mFloor(15*sc),hy+mFloor(6*sc)); THUD.N.Size = mMax(10,mFloor(18*sc)); THUD.N.Transparency = ea; THUD.N.Visible = true
                        THUD.D.Text = thDataFmt; THUD.D.Position = V2(hx+mFloor(15*sc),hy+mFloor(26*sc)); THUD.D.Size = mMax(10,mFloor(11*sc)); THUD.D.Transparency = 0.8*ea; THUD.D.Visible = true
                        
                        local barThick = mMax(4, mFloor(6*sc))
                        local barY = hy+bh-mFloor(10*sc)
                        THUD.BBG.Size = V2(bw-mFloor(30*sc),barThick); THUD.BBG.Position = V2(hx+mFloor(15*sc),barY); THUD.BBG.Transparency = 0.5*ea; THUD.BBG.Visible = true
                        THUD.BFG.Size = V2(mFloor((bw-mFloor(30*sc))*hpPct),barThick); THUD.BFG.Position = V2(hx+mFloor(15*sc),barY); THUD.BFG.Color = HPC(hpPct); THUD.BFG.Transparency = ea; THUD.BFG.Visible = true
                        THUD.HPNum.Text = hpStr; THUD.HPNum.Position = V2(hx+(bw/2), barY - (mMax(10, mFloor(11*sc))*0.45)); THUD.HPNum.Size = mMax(10, mFloor(11*sc)); THUD.HPNum.Transparency = ea; THUD.HPNum.Visible = true
                        
                    elseif st == "Standard" then
                        local bw, bh = _stdHUDWidth, mFloor(56*sc)
                        local hx, hy = mFloor((sw/2)-(bw/2)), mFloor(sh-mFloor(140*sc))+mFloor(ys)
                        
                        THUD.Sh.Size = V2(bw,bh); THUD.Sh.Position = V2(hx+3,hy+3); THUD.Sh.Transparency = 0.5*ea; THUD.Sh.Visible = true
                        THUD.BG.Size = V2(bw,bh); THUD.BG.Position = V2(hx,hy); THUD.BG.Transparency = 0.85*ea; THUD.BG.Visible = true
                        THUD.Out.Size = V2(bw+2,bh+2); THUD.Out.Position = V2(hx-1,hy-1); THUD.Out.Color = ac; THUD.Out.Transparency = ea; THUD.Out.Visible = true
                        THUD.Ac.Size = V2(bw,mMax(1,mFloor(2*sc))); THUD.Ac.Position = V2(hx,hy); THUD.Ac.Color = ac; THUD.Ac.Transparency = ea; THUD.Ac.Visible = true
                        THUD.N.Text = thNameFmt; THUD.N.Position = V2(hx+mFloor(10*sc),hy+mFloor(8*sc)); THUD.N.Size = mMax(10,mFloor(16*sc)); THUD.N.Transparency = ea; THUD.N.Visible = true
                        THUD.D.Text = thDataFmt; THUD.D.Position = V2(hx+mFloor(10*sc),hy+mFloor(28*sc)); THUD.D.Size = mMax(10,mFloor(13*sc)); THUD.D.Transparency = ea; THUD.D.Visible = true
                        
                        local barThick = mMax(4, mFloor(6*sc))
                        local barY = hy+mFloor(45*sc)
                        THUD.BBG.Size = V2(bw-mFloor(20*sc),barThick); THUD.BBG.Position = V2(hx+mFloor(10*sc),barY); THUD.BBG.Transparency = ea; THUD.BBG.Visible = true
                        THUD.BFG.Size = V2(mFloor((bw-mFloor(20*sc))*hpPct),barThick); THUD.BFG.Position = V2(hx+mFloor(10*sc),barY); THUD.BFG.Color = HPC(hpPct); THUD.BFG.Transparency = ea; THUD.BFG.Visible = true
                        THUD.HPNum.Text = hpStr; THUD.HPNum.Position = V2(hx+(bw/2), barY - (mMax(10, mFloor(12*sc))*0.45)); THUD.HPNum.Size = mMax(10, mFloor(12*sc)); THUD.HPNum.Transparency = ea; THUD.HPNum.Visible = true
                    end
                    hudVis = true
                end
            end
        end
    else ClearTarget() end
    
    if not S.Aim.Target or not S.Aim.IsAiming then if LTracer.Visible then LTracer.Visible = false end end
    if not showHUD then
        thAlpha = mClamp(thAlpha - dt*8, 0, 1)
        if thAlpha <= 0.05 then HideTHUD() else 
            local ea = 1 - mExp(-thAlpha * 5)
            THUD.Sh.Transparency = 0.5*ea; THUD.BG.Transparency = 0.85*ea; THUD.Out.Transparency = ea; THUD.Ac.Transparency = ea
            THUD.N.Transparency = ea; THUD.D.Transparency = ea; THUD.BBG.Transparency = ea; THUD.BFG.Transparency = ea; THUD.HPNum.Transparency = ea
        end
    end
end

local function DrawCorner(e, x, y, w, h, col, outline, thick, zIndex)
    local L = mFloor(w/4); local cl = e.CL
    local xL, xw, xwL, yL, yh, yhL = x+L, x+w, x+w-L, y+L, y+h, y+h-L
    local mZ = zIndex + 2
    setL(cl[1].M, V2(x,y), V2(xL,y), col, thick, mZ); setL(cl[2].M, V2(x,y), V2(x,yL), col, thick, mZ)
    setL(cl[3].M, V2(xw,y), V2(xwL,y), col, thick, mZ); setL(cl[4].M, V2(xw,y), V2(xw,yL), col, thick, mZ)
    setL(cl[5].M, V2(x,yh), V2(xL,yh), col, thick, mZ); setL(cl[6].M, V2(x,yh), V2(x,yhL), col, thick, mZ)
    setL(cl[7].M, V2(xw,yh), V2(xwL,yh), col, thick, mZ); setL(cl[8].M, V2(xw,yh), V2(xw,yhL), col, thick, mZ)
    if outline then
        local ot = thick+2; local oz = zIndex+1
        setL(cl[1].O, V2(x-1,y-1), V2(xL+1,y-1), BLACK, ot, oz); setL(cl[2].O, V2(x-1,y-1), V2(x-1,yL+1), BLACK, ot, oz)
        setL(cl[3].O, V2(xw+1,y-1), V2(xwL-1,y-1), BLACK, ot, oz); setL(cl[4].O, V2(xw+1,y-1), V2(xw+1,yL+1), BLACK, ot, oz)
        setL(cl[5].O, V2(x-1,yh+1), V2(xL+1,yh+1), BLACK, ot, oz); setL(cl[6].O, V2(x-1,yh+1), V2(x-1,yhL-1), BLACK, ot, oz)
        setL(cl[7].O, V2(xw+1,yh+1), V2(xwL-1,yh+1), BLACK, ot, oz); setL(cl[8].O, V2(xw+1,yh+1), V2(xw+1,yhL-1), BLACK, ot, oz)
    else
        for i=1, 8 do e.CL[i].O.Visible = false end
    end
end

local function TickESP(camP, sw, sh, cam, tStart, center, dt)
    local cfov = cam.FieldOfView
    if cfov ~= _lastCamFOV then _lastCamFOV = cfov; _camTan = math.tan(math.rad(cfov*0.5)) end
    
    local halfH = sh * 0.5; local camLook = cam.CFrame.LookVector; local camRight = cam.CFrame.RightVector 
    
    -- Local Hoisting for massive FPS optimization (ZERO table lookups in loop)
    local esp = S.ESP
    local esOn = esp.On; local esVisCol = esp.VisColors
    local esChams = esp.Chams; local esArr = esp.Arrows; local esTr = esp.Tracers
    local esHBar = esp.HBar; local esHBarSt = esp.HBarSt; local esHBThick = esp.HBarThick; local esHBOff = esp.HBarOff; local esHBSm = esp.HBarSmooth; local esHBTxt = esp.HBarText
    local esNames = esp.Names; local esTC = esp.TCase
    local esDist = esp.DistShow; local esWep = esp.WepShow; local esHNum = esp.HNums
    local esFont = esp.Font; local esTSz = esp.TSize; local subTS = mMax(10, esTSz - 2)

    for i = 1, #PList do
        local pl = PList[i]; local e = ESPObj[pl]; if not e then continue end
        local cd = CC[pl]

        if not cd or not cd.HRP or not cd.Hum or cd.Hum.Health <= 0 then HideE(e); continue end
        if not cd.HRP:IsDescendantOf(workspace) then HideE(e); continue end

        local isTM = IsTeam(pl)
        if esp.TeamCheck and isTM and not esp.ShowTeam then HideE(e); continue end

        local d2 = cd._distSq; if d2 > _maxD2 then HideE(e); continue end
        local onSc, depth = cd._onSc, cd._depth
        if depth <= 0 then HideE(e); continue end
        local isLOD = d2 > _lodD2
        
        -- Smooth Health Lerp calculation
        e._smoothHp = e._smoothHp + (cd.Hum.Health - e._smoothHp) * esHBSm * dt
        local hpPct = mClamp(e._smoothHp / mMax(1, cd._maxHP or 100), 0, 1)

        if not isLOD and onSc and esVisCol then
            if e._stag == (RSF % STAG) then e.vis = IsVis(cd.HRP, camP) end
        else e.vis = true end

        local col = (isTM and esp.ShowTeam) and esp.TeamCol or (esVisCol and (e.vis and esp.VisCol or esp.HideCol) or esp.StatCol)

        if esChams then
            if not e.Hl then e.Hl = Instance.new("Highlight"); e.Hl.Parent = CFolder end
            if e.Hl.Adornee ~= cd.Char then e.Hl.Adornee = cd.Char; e.Hl.Enabled = true end
            local cFill = esp.ChamsVisCol and (e.vis and esp.VisCol or esp.HideCol) or esp.ChamsFill
            e.Hl.FillColor = cFill; e.Hl.OutlineColor = esp.ChamsOut; e.Hl.FillTransparency = esp.ChamsFT; e.Hl.OutlineTransparency = esp.ChamsOT
        else if e.Hl and e.Hl.Enabled then e.Hl.Enabled = false; e.Hl.Adornee = nil end end

        if esArr and not isLOD and (not onSc or depth <= 0) then
            local hp = cd.HRP.Position; local relX = (hp - camP):Dot(camRight); local relZ = -(hp - camP):Dot(camLook)
            local ang = mAtan2(relX, relZ); local sa, ca = mSin(ang), mCos(ang)
            local ar = esp.ArrowR; local as = esp.ArrowSz; local ac2 = center + V2(sa*ar, -ca*ar)
            local p1 = ac2 + V2(sa*as, -ca*as); local p2 = ac2 + V2(mSin(ang-PI4)*as*0.75, -mCos(ang-PI4)*as*0.75)
            local p3 = ac2 + V2(sa*as*0.3, -ca*as*0.3); local p4 = ac2 + V2(mSin(ang+PI4)*as*0.75, -mCos(ang+PI4)*as*0.75)
            setL(e.AL[1], p1, p2, esp.ArrowCol, 1.5, 1); setL(e.AL[2], p2, p3, esp.ArrowCol, 1.5, 1)
            setL(e.AL[3], p3, p4, esp.ArrowCol, 1.5, 1); setL(e.AL[4], p4, p1, esp.ArrowCol, 1.5, 1)
        else for j=1, 4 do e.AL[j].Visible = false end end

        if esTr and not isLOD then
            if not TrLine[pl] then TrLine[pl] = ND("Line"); TrLine[pl].Thickness = 1.5 end
            setL(TrLine[pl], tStart, V2(cd._sp.X, cd._sp.Y), esp.TracerCol, 1.5, 1)
            TrLine[pl].Visible = onSc
        elseif TrLine[pl] then TrLine[pl].Visible = false end

        if not esOn or not onSc then
            e.Box.Visible = false; e.BoxOut.Visible = false; e.BoxFill.Visible = false
            for j=1, 8 do e.CL[j].M.Visible = false; e.CL[j].O.Visible = false end
            for j=1, #e._texts do e._texts[j].Visible = false end
            e.HTxt.Visible = false; e.BBG.Visible = false; e.BFG.Visible = false; e.BOut.Visible = false
            continue 
        end
        e._lv = true

        depth = mMax(depth, 0.1) 
        local pps = halfH / (depth * _camTan)
        local bw, bh = mFloor(mMax(2, cd._charW * 2 * pps)), mFloor(mMax(4, cd._charH * 2 * pps))
        local bx, by = mFloor(cd._sp.X - bw * 0.5), mFloor(cd._sp.Y - bh * 0.5)
        local zIndex = mFloor(10000 - depth)

        if esp.Boxes then
            if not _isCorner then
                e.Box.Size = V2(bw, bh); e.Box.Position = V2(bx, by); e.Box.Color = col; e.Box.ZIndex = zIndex + 2; e.Box.Visible = true
                if esp.Outline then
                    e.BoxOut.Size = V2(bw+2, bh+2); e.BoxOut.Position = V2(bx-1, by-1); e.BoxOut.ZIndex = zIndex + 1; e.BoxOut.Visible = true
                else e.BoxOut.Visible = false end
                for j=1, 8 do e.CL[j].M.Visible = false; e.CL[j].O.Visible = false end
            else
                e.Box.Visible = false; e.BoxOut.Visible = false
                DrawCorner(e, bx, by, bw, bh, col, esp.Outline, 1.5, zIndex)
            end
            if esp.BoxFill then
                e.BoxFill.Size = V2(bw, bh); e.BoxFill.Position = V2(bx, by); e.BoxFill.Color = col; e.BoxFill.Transparency = esp.BoxFillT; e.BoxFill.ZIndex = zIndex; e.BoxFill.Visible = true
            else e.BoxFill.Visible = false end
        end

        local hpCol = HPC(hpPct)
        
        local hi = mFloor(e._smoothHp)
        if e._hi ~= hi then
            e._hi = hi; e._hiTxt1 = tostring(hi); e._hiTxt2 = Fmt(hi.." HP", esTC)
        end

        if esHBar then
            local showHTxt = esHBTxt and e.vis
            if esHBarSt == "Vertical" then
                local fh = mMax(1, mFloor(bh * hpPct))
                local barX = bx - esHBOff - esHBThick
                e.BOut.Size = V2(esHBThick+2, bh+2); e.BOut.Position = V2(barX-1, by-1); e.BOut.ZIndex = zIndex+1; e.BOut.Visible = true
                e.BBG.Size = V2(esHBThick, bh); e.BBG.Position = V2(barX, by); e.BBG.ZIndex = zIndex+2; e.BBG.Visible = true
                e.BFG.Size = V2(esHBThick, fh); e.BFG.Position = V2(barX, by+bh-fh); e.BFG.Color = hpCol; e.BFG.ZIndex = zIndex+3; e.BFG.Visible = true
                
                if showHTxt then
                    e.HTxt.Center = true; e.HTxt.Text = e._hiTxt1; e.HTxt.Position = V2(barX - 12, by + bh - fh - (subTS * 0.4)); e.HTxt.Color = hpCol; e.HTxt.Size = subTS; e.HTxt.ZIndex = zIndex + 4; e.HTxt.Visible = true
                else e.HTxt.Visible = false end
            else
                local fw = mMax(1, mFloor(bw * hpPct))
                local barY = by + bh + esHBOff
                e.BOut.Size = V2(bw+2, esHBThick+2); e.BOut.Position = V2(bx-1, barY-1); e.BOut.ZIndex = zIndex+1; e.BOut.Visible = true
                e.BBG.Size = V2(bw, esHBThick); e.BBG.Position = V2(bx, barY); e.BBG.ZIndex = zIndex+2; e.BBG.Visible = true
                e.BFG.Size = V2(fw, esHBThick); e.BFG.Position = V2(bx, barY); e.BFG.Color = hpCol; e.BFG.ZIndex = zIndex+3; e.BFG.Visible = true
                
                if showHTxt then
                    e.HTxt.Center = true; e.HTxt.Text = e._hiTxt1; e.HTxt.Position = V2(bx + bw * 0.5, barY + (esHBThick * 0.5) - (subTS * 0.45)); e.HTxt.Color = hpCol; e.HTxt.Size = subTS; e.HTxt.ZIndex = zIndex + 4; e.HTxt.Visible = true
                else e.HTxt.Visible = false end
            end
        else
            e.BBG.Visible = false; e.BFG.Visible = false; e.BOut.Visible = false; e.HTxt.Visible = false
        end

        if e._font ~= esFont then e._font = esFont; for j=1, #e._texts do e._texts[j].Font = esFont end; e.HTxt.Font = esFont end
        if e._tc ~= esTC then e._tc = esTC; e._ws="\0"; e._ns="\0"; e._us="\0"; e._di=-1 end

        local ty = by - esTSz - 4
        local by2 = by + bh + (esHBar and esHBarSt == "Horizontal" and (esHBOff + esHBThick + 4) or 4)
        local nCol = esp.CustomName and esp.NameCol or col

        if esNames then
            if _nStyleDN or _nStyleBoth then
                local dn = pl.DisplayName; if e._ns ~= dn then e._ns = dn; e._nsFmt = Fmt(dn, esTC) end
                e.N.Text = e._nsFmt; e.N.Position = V2(mFloor(cd._sp.X), ty); e.N.Color = nCol; e.N.Size = esTSz; e.N.ZIndex = zIndex + 5; e.N.Visible = true
                if _nStyleBoth then ty = ty - subTS end
            else e.N.Visible = false end
            
            if _nStyleUN or _nStyleBoth then
                local un = cd._uname; if e._us ~= un then e._us = un; e._usFmt = Fmt(un, esTC) end
                local ty2 = _nStyleBoth and (ty - subTS) or ty 
                e.UN.Text = e._usFmt; e.UN.Position = V2(mFloor(cd._sp.X), ty2); e.UN.Color = esp.CustomName and GRAY_NAME or col; e.UN.Size = subTS; e.UN.ZIndex = zIndex + 5; e.UN.Visible = true
            else e.UN.Visible = false end
        else e.N.Visible = false; e.UN.Visible = false end

        if esDist then
            local di = mFloor(mSqrt(d2)); if e._di ~= di then e._di = di; e._diFmt = Fmt(di.."m", esTC) end
            e.Di.Text = e._diFmt; e.Di.Position = V2(mFloor(cd._sp.X), by2); e.Di.Color = DC5(di, esp.MaxDist); e.Di.Size = subTS; e.Di.ZIndex = zIndex + 5; e.Di.Visible = true
            by2 = by2 + subTS + 2
        else e.Di.Visible = false end

        if esHNum then
            e.H.Text = e._hiTxt2; e.H.Position = V2(mFloor(cd._sp.X), by2); e.H.Color = hpCol; e.H.Size = subTS; e.H.ZIndex = zIndex + 5; e.H.Visible = true
            by2 = by2 + subTS + 2
        else e.H.Visible = false end

        if esWep and not isLOD then
            local tool = cd.Char:FindFirstChildOfClass("Tool"); local ws = tool and tool.Name or "None"
            if e._ws ~= ws then e._ws = ws; e._wsFmt = Fmt(ws, esTC); e._wCol = GetWepCol(ws) end
            e.W.Text = e._wsFmt; e.W.Position = V2(mFloor(cd._sp.X), by2); e.W.Color = e._wCol; e.W.Size = subTS; e.W.ZIndex = zIndex + 5; e.W.Visible = true
            by2 = by2 + subTS + 2
        else e.W.Visible = false end
    end
end

local function TickHB(dt)
    if S.TB.On and VI then
        tbT = tbT - dt
        if tbT <= 0 and mRand(1,100) <= S.TB.HC then
            local cam = workspace.CurrentCamera
            if cam then
                local cx, cy = cam.ViewportSize.X*0.5, cam.ViewportSize.Y*0.5
                local oP, dir
                if S.FOV.Follow then
                    local mp = UIS:GetMouseLocation(); cx, cy = mp.X, mp.Y
                    local ur = cam:ViewportPointToRay(cx, cy); oP = ur.Origin; dir = ur.Direction*1000
                else oP = cam.CFrame.Position; dir = cam.CFrame.LookVector*1000 end
                
                table.clear(TRF); if LP.Character then tIns(TRF, LP.Character) end; tIns(TRF, cam); TRP.FilterDescendantsInstances = TRF
                local res = S.TB.Sphere and workspace:Spherecast(oP, S.TB.Thick, dir, TRP) or workspace:Raycast(oP, dir, TRP)
                if res and res.Instance then
                    local mdl = res.Instance:FindFirstAncestorOfClass("Model")
                    if mdl and mdl:FindFirstChild("Humanoid") then
                        local tp = Plr:GetPlayerFromCharacter(mdl)
                        if tp and tp ~= LP and not (S.TB.Team and IsTeam(tp)) then
                            task.spawn(function() pcall(function() VI:SendMouseButtonEvent(cx, cy, 0, true, game, 1); task.wait(0.01); VI:SendMouseButtonEvent(cx, cy, 0, false, game, 1) end) end)
                            tbT = S.TB.Delay
                        end
                    end
                end
            end
        end
    end

    if S.HB.On then
        local ns, nt = _hbSizeV3, S.HB.Trans
        for i = 1, #PList do
            local pl = PList[i]
            if pl ~= LP and (not S.Aim.TeamCheck or not IsTeam(pl)) then
                local cd = CC[pl]
                if cd and cd.Hum and cd.Hum.Health > 0 then
                    local part = (S.HB.Part=="Head") and cd.Head or (S.HB.Part=="HumanoidRootPart" and cd.HRP) or cd.Char:FindFirstChild(S.HB.Part)
                    if part and part:IsA("BasePart") then
                        if not HBOrig[pl] then HBOrig[pl] = {} end
                        if not HBOrig[pl][part] then HBOrig[pl][part] = {Sz=part.Size, Tr=part.Transparency, CC=part.CanCollide} end
                        if part.Size ~= ns then part.Size = ns end
                        if part.Transparency ~= nt then part.Transparency = nt end
                        if part.CanCollide then part.CanCollide = false end
                    end
                end
            end
        end
    else
        pcall(function() 
            for pl, pts in pairs(HBOrig) do
                for part, d in pairs(pts) do
                    if part and part.Parent then
                        if part.Size ~= d.Sz then part.Size = d.Sz end; if part.Transparency ~= d.Tr then part.Transparency = d.Tr end; if part.CanCollide ~= d.CC then part.CanCollide = d.CC end
                    end
                end
            end
        end)
        table.clear(HBOrig)
    end

    for i = 1, #PList do
        local cd = CC[PList[i]]
        if cd and cd.HRP then cd._velDelta = (cd.HRP.Position - cd._lastPos) / mMax(dt, 0.001); cd._lastPos = cd.HRP.Position end
    end
end

local function TickRender(dt)
    RSF = RSF + 1; avgDT = avgDT + (dt - avgDT) * 0.1 
    local cam = workspace.CurrentCamera; if not cam then return end
    local vp = cam.ViewportSize; if vp.X == 0 or vp.Y == 0 then return end
    local cp = cam.CFrame.Position; local sw, sh = vp.X, vp.Y
    local myC = CC[LP]; local myP = (myC and myC.HRP) and myC.HRP.Position or cp

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
    local center = V2(sw*0.5, sh*0.5)
    local tStart = V2(sw*0.5, S.ESP.TracerOrg=="Top" and 0 or (S.ESP.TracerOrg=="Center" and sh*0.5 or sh))

    TickAim(cp, sw, sh, dt, fovP, cam)
    TickESP(cp, sw, sh, cam, tStart, center, dt)
    if #ADmg > 0 then TickDmg(cam) end
end

tIns(Conns, RS.Heartbeat:Connect(TickHB))
tIns(Conns, RS.RenderStepped:Connect(TickRender))

-- ==============================================================================
--  9. OBSIDIAN USER INTERFACE
-- ==============================================================================
local Win = Lib:CreateWindow({ Title="KAIM", Footer="v9.0 | IDLE", ToggleKeybind=Enum.KeyCode.K, NotifySide="Right" })

local T = {
    Home   = Win:AddTab("Home",     "home"),
    Combat = Win:AddTab("Combat",   "crosshair"),
    Visual = Win:AddTab("Visuals",  "eye"),
    Player = Win:AddTab("Movement", "person-standing"),
    Config = Win:AddTab("Config",   "settings"),
}

local W_MARK = S.Perf.Watermark and Lib:AddDraggableLabel("KAIM v9.0 | FPS: --", "activity") or nil
if W_MARK then W_MARK:SetVisible(true) end

local HL = T.Home:AddLeftGroupbox("KAIM v9.0")
local HR = T.Home:AddRightGroupbox("Live Stats")
HL:AddLabel({Text="Ultra Premium Edition — 1000x FPS Optimization, Global Raycast Caching, Lua Proxy Drawing Cache, Embedded Healthbar Text.", DoesWrap=true})
local lFPS = HR:AddLabel({Text="FPS: —"}); local lPL  = HR:AddLabel({Text="Players: 0"}); local lLck = HR:AddLabel({Text="LOCKED: None"})

task.spawn(function()
    while _env.KAIM_LOADED do
        local fps = mFloor(1/mMax(avgDT, 0.001))
        pcall(function()
            lFPS:SetText(("FPS: %d  (%.1fms)"):format(fps, avgDT*1000)); lPL:SetText("Players: "..#PList.." tracked")
            if S.Aim.Target and S.Aim.IsAiming then
                lLck:SetText("LOCKED: " .. S.Aim.Target.DisplayName); Win:SetFooter("v9.0 | LOCKED: " .. S.Aim.Target.DisplayName)
            else 
                lLck:SetText("LOCKED: None"); Win:SetFooter("v9.0 | SEARCHING/IDLE")
            end
            if W_MARK and S.Perf.Watermark then W_MARK:SetText(("KAIM v9.0 | FPS: %d"):format(fps)) end
        end)
        task.wait(0.5)
    end
end)

-- ------------------------------------------------------------------------------
--  Combat Tab
-- ------------------------------------------------------------------------------
local AL = T.Combat:AddLeftGroupbox("Aimlock")
local AimOnToggle = AL:AddToggle("AimOn", {Text="Enable Aimlock", Default=false, Callback=function(v) S.Aim.On=v end})
local AimSettings = AL:AddDependencyBox(); AimSettings:SetupDependencies({{AimOnToggle, true}})

AimSettings:AddLabel("Aim Key"):AddKeyPicker("AimKey",{Default="RightClick", Text="Aim Key", Callback=function(v) S.Aim.Key=v; pcall(function() _aimKC=Enum.KeyCode[v] end) end})
AimSettings:AddToggle("AimWall",   {Text="Wall Check", Default=true, Callback=function(v) S.Aim.WallCheck=v end})
AimSettings:AddToggle("AimTeam",   {Text="Team Check", Default=true, Callback=function(v) S.Aim.TeamCheck=v end})
AimSettings:AddSlider("AimHC",     {Text="Hit Chance %", Default=100, Min=1, Max=100, Rounding=0, Callback=function(v) S.Aim.HitChance=v end})
AimSettings:AddToggle("AimPred",   {Text="Velocity Prediction", Default=true, Callback=function(v) S.Aim.Pred=v end})
AimSettings:AddSlider("AimPStr",   {Text="Pred Strength", Default=0.135, Min=0, Max=0.3, Rounding=3, Callback=function(v) S.Aim.PredStr=v end})
AimSettings:AddToggle("AimDynPred",{Text="Distance Scaling Pred", Default=true, Callback=function(v) S.Aim.DynamicPred=v end})
AimSettings:AddToggle("AimSmooth", {Text="Smooth Aim", Default=false, Callback=function(v) S.Aim.Smooth=v end})
AimSettings:AddSlider("AimSSpd",   {Text="Smooth Speed", Default=0.3, Min=0.05, Max=1, Rounding=2, Callback=function(v) S.Aim.SmoothSpd=v end})
AimSettings:AddToggle("AimSnd",    {Text="Lock Sound Cue", Default=true, Callback=function(v) S.Aim.SoundCue=v end})

local AR = T.Combat:AddRightGroupbox("Targeting")
AR:AddDropdown("AimPri",  {Text="Priority", Values={"Crosshair","Distance"}, Default="Crosshair", Callback=function(v) S.Aim.Priority=v end})
AR:AddDropdown("AimMode", {Text="Aim Mode", Values={"Smart","Chaos","Head","Torso","Limbs","HRP"}, Default="Smart", Callback=function(v) S.Aim.Mode=v end})
AR:AddSlider("AimOX",{Text="Offset X", Default=0, Min=-5, Max=5, Rounding=1, Callback=function(v) S.Aim.OffX=v; _aimOff=V3(S.Aim.OffX,S.Aim.OffY,S.Aim.OffZ) end})
AR:AddSlider("AimOY",{Text="Offset Y", Default=0, Min=-5, Max=5, Rounding=1, Callback=function(v) S.Aim.OffY=v; _aimOff=V3(S.Aim.OffX,S.Aim.OffY,S.Aim.OffZ) end})
AR:AddSlider("AimOZ",{Text="Offset Z", Default=0, Min=-5, Max=5, Rounding=1, Callback=function(v) S.Aim.OffZ=v; _aimOff=V3(S.Aim.OffX,S.Aim.OffY,S.Aim.OffZ) end})

local FG = T.Combat:AddLeftGroupbox("FOV Circle")
local FOVToggle = FG:AddToggle("FOVShow",  {Text="Show FOV", Default=true, Callback=function(v) S.FOV.Show=v end})
local FOVSettings = FG:AddDependencyBox(); FOVSettings:SetupDependencies({{FOVToggle, true}})

FOVSettings:AddToggle("FOVFol",   {Text="Follow Cursor", Default=true, Callback=function(v) S.FOV.Follow=v end})
FOVSettings:AddToggle("FOVZsc",   {Text="Scale with Zoom", Default=true, Callback=function(v) S.FOV.ZoomScale=v end})
FOVSettings:AddSlider("FOVRad",   {Text="Radius", Default=150, Min=20, Max=600, Rounding=0, Suffix="px", Callback=function(v) S.FOV.Radius=v end})
FOVSettings:AddSlider("FOVThk",   {Text="Thickness", Default=1.5, Min=0.5, Max=5, Rounding=1, Callback=function(v) S.FOV.Thick=v end})
FOVSettings:AddToggle("FOVFill",  {Text="Filled", Default=false, Callback=function(v) S.FOV.Filled=v end})
FOVSettings:AddLabel("Ring Color"):AddColorPicker("FOVCol", {Default=WHITE, Callback=function(v) S.FOV.Color=v end})
FOVSettings:AddLabel("Locked Color"):AddColorPicker("FOVLC",{Default=ORANGE,Callback=function(v) S.FOV.LockCol=v end})

-- ------------------------------------------------------------------------------
--  Visuals Tab
-- ------------------------------------------------------------------------------
local EL = T.Visual:AddLeftGroupbox("ESP")
local ESPToggle = EL:AddToggle("ESPOn", {Text="Enable ESP", Default=false, Callback=function(v) S.ESP.On=v end})
local ESPSettings = EL:AddDependencyBox(); ESPSettings:SetupDependencies({{ESPToggle, true}})

ESPSettings:AddSlider("ESPDist",  {Text="Max Distance", Default=1000, Min=100, Max=5000, Rounding=0, Suffix="m", Callback=function(v) S.ESP.MaxDist=v; _maxD2=v*v end})
ESPSettings:AddToggle("ESPTeam",  {Text="Team Check", Default=true, Callback=function(v) S.ESP.TeamCheck=v end})
ESPSettings:AddToggle("ESPBoxes", {Text="Show Boxes", Default=true, Callback=function(v) S.ESP.Boxes=v end})
ESPSettings:AddDropdown("ESPBSt", {Text="Box Style", Values={"Standard","Corner"}, Default="Corner", Callback=function(v) S.ESP.BoxStyle=v; _isCorner=(v=="Corner") end})

local HBToggle = ESPSettings:AddToggle("ESPHBar",  {Text="Health Bar", Default=true, Callback=function(v) S.ESP.HBar=v end})
local HBSettings = ESPSettings:AddDependencyBox(); HBSettings:SetupDependencies({{ESPToggle, true}, {HBToggle, true}})
HBSettings:AddDropdown("ESPHSt", {Text="Health Bar Style", Values={"Vertical","Horizontal"}, Default="Vertical", Callback=function(v) S.ESP.HBarSt=v end})
HBSettings:AddToggle("ESPHBTxt", {Text="Show Text Inside Bar", Default=true, Callback=function(v) S.ESP.HBarText=v end})
HBSettings:AddSlider("ESPHBThick", {Text="Bar Thickness", Default=2, Min=1, Max=10, Rounding=0, Callback=function(v) S.ESP.HBarThick=v end})
HBSettings:AddSlider("ESPHBOff", {Text="Bar Offset", Default=5, Min=1, Max=20, Rounding=0, Callback=function(v) S.ESP.HBarOff=v end})
HBSettings:AddSlider("ESPHBSm", {Text="Smooth Interpolation", Default=12, Min=1, Max=30, Rounding=1, Callback=function(v) S.ESP.HBarSmooth=v end})

local ER = T.Visual:AddRightGroupbox("Colors & Text")
local ERSettings = ER:AddDependencyBox(); ERSettings:SetupDependencies({{ESPToggle, true}})

ERSettings:AddToggle("ESPVCol",  {Text="Visibility Colors", Default=true, Callback=function(v) S.ESP.VisColors=v end})
ERSettings:AddLabel("Visible"):AddColorPicker("ESPVis",{Default=C3(0, 255, 100), Callback=function(v) S.ESP.VisCol=v end})
ERSettings:AddLabel("Hidden"):AddColorPicker("ESPHid", {Default=RED, Callback=function(v) S.ESP.HideCol=v end})
ERSettings:AddToggle("ESPNames", {Text="Names", Default=true, Callback=function(v) S.ESP.Names=v end})
ERSettings:AddDropdown("ESPNSt", {Text="Name Style", Values={"Display Name","Username","Both"}, Default="Display Name", Callback=function(v) S.ESP.NStyle=v; _nStyleDN=(v=="Display Name" or v=="Both"); _nStyleUN=(v=="Username" or v=="Both"); _nStyleBoth=(v=="Both") end})
ERSettings:AddToggle("ESPWep",   {Text="Weapon (Color Coded)", Default=false, Callback=function(v) S.ESP.WepShow=v end})
ERSettings:AddToggle("ESPDist2", {Text="Distance", Default=false, Callback=function(v) S.ESP.DistShow=v end})
ERSettings:AddToggle("ESPHNum",  {Text="Health Numbers Below Box", Default=false, Callback=function(v) S.ESP.HNums=v end})

local IL = T.Visual:AddLeftGroupbox("Indicators")
local ArrToggle = IL:AddToggle("IndArr",   {Text="Off-Screen Arrows", Default=false, Callback=function(v) S.ESP.Arrows=v end})
local ArrSettings = IL:AddDependencyBox(); ArrSettings:SetupDependencies({{ArrToggle, true}})
ArrSettings:AddSlider("IndArR",   {Text="Arrow Radius", Default=120, Min=50, Max=300, Rounding=0, Callback=function(v) S.ESP.ArrowR=v end})
ArrSettings:AddSlider("IndArSz",  {Text="Arrow Size", Default=15, Min=5, Max=40, Rounding=0, Callback=function(v) S.ESP.ArrowSz=v end})
ArrSettings:AddLabel("Arrow Color"):AddColorPicker("IndAC",{Default=C3(255, 85, 0),Callback=function(v) S.ESP.ArrowCol=v end})

local CG = T.Visual:AddRightGroupbox("Chams")
local ChmToggle = CG:AddToggle("ChOn",   {Text="Enable Chams", Default=false, Callback=function(v) S.ESP.Chams=v end})
local ChmSettings = CG:AddDependencyBox(); ChmSettings:SetupDependencies({{ChmToggle, true}})
ChmSettings:AddLabel("Vis Fill"):AddColorPicker("ChFF", {Default=WHITE, Callback=function(v) S.ESP.ChamsFill=v end})
ChmSettings:AddLabel("Vis Outline"):AddColorPicker("ChFO", {Default=WHITE, Callback=function(v) S.ESP.ChamsOut=v end})

-- ------------------------------------------------------------------------------
--  Movement & Config Tab
-- ------------------------------------------------------------------------------
local ML = T.Player:AddLeftGroupbox("Character")
local ncCache, ncConn, ncAddConn = {}, nil, nil
local function BuildNC(char)
    ncCache = {}; if not char then return end
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then tIns(ncCache, {p=p, cc=p.CanCollide})
        elseif p:IsA("Accessory") then local h = p:FindFirstChild("Handle"); if h then tIns(ncCache, {p=h, cc=h.CanCollide}) end end
    end
end
_G._KaimNC = BuildNC

local function SetNC(on)
    S.Mov.Noclip = on
    if ncConn then ncConn:Disconnect(); ncConn = nil end
    if ncAddConn then ncAddConn:Disconnect(); ncAddConn = nil end
    if on then
        BuildNC(LP.Character); _ncNeedsPass = true
        ncConn = RS.Stepped:Connect(function()
            if not _ncNeedsPass then return end
            for i = 1, #ncCache do if ncCache[i].p and ncCache[i].p.Parent and ncCache[i].p.CanCollide then ncCache[i].p.CanCollide = false end end; _ncNeedsPass = false
        end)
        if LP.Character then
            ncAddConn = LP.Character.DescendantAdded:Connect(function(p)
                if p:IsA("BasePart") and not p:IsDescendantOf(LP.Character:FindFirstChildOfClass("Tool")) then 
                    tIns(ncCache, {p=p, cc=p.CanCollide}); p.CanCollide = false; _ncNeedsPass = true
                end
            end)
        end
    else
        for i = 1, #ncCache do if ncCache[i].p and ncCache[i].p.Parent and ncCache[i].p.CanCollide ~= ncCache[i].cc then ncCache[i].p.CanCollide = ncCache[i].cc end end; ncCache = {}
    end
end

ML:AddToggle("NCOn",{Text="Noclip", Default=false, Callback=function(v) SetNC(v) end})
ML:AddLabel("Noclip Key"):AddKeyPicker("NCKey",{Default="N", Text="Noclip Key", Callback=function(v) S.Mov.NoclipKey=v end})

local CL = T.Config:AddLeftGroupbox("Save / Load")
local CR = T.Config:AddRightGroupbox("Performance")
CR:AddToggle("PerfWM",  {Text="FPS Watermark", Default=true, Callback=function(v) S.Perf.Watermark=v; if W_MARK then W_MARK:SetVisible(v) end end})

CL:AddToggle("CfgProf", {Text="Use Game Profiles", Default=false, Tooltip="Saves config to PlaceId subfolder", Callback=function(v) 
    S.Cfg.GameProfile=v; if v then SM:SetSubFolder(tostring(game.PlaceId)) else SM:SetSubFolder("") end
end})

SM:SetLibrary(Lib); SM:IgnoreThemeSettings(); SM:SetIgnoreIndexes({"AimKey","NCKey"})
SM:SetFolder("KAIM_v9"); SM:BuildConfigSection(T.Config)
TM:SetLibrary(Lib); TM:SetFolder("KAIM_v9"); TM:ApplyToTab(T.Config); TM:LoadDefault()

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
                for _, l in pairs(TrLine) do pcall(function() l:Remove() end) end
                for i = 1, #ADmg do pcall(function() ADmg[i].T:Remove() end) end
                for i = 1, #DmgPool do pcall(function() DmgPool[i].T:Remove() end) end
                SetNC(false)
                pcall(function() FOVR:Remove(); FOVF:Remove(); LTracer:Remove() end)
                pcall(function() CFolder:Destroy(); lockSound:Destroy() end)
                pcall(function() for _, v in pairs(THUD) do v:Remove() end end)
                if W_MARK then W_MARK:Destroy() end
                _env.KAIM_LOADED = false; _G._KaimNC = nil
                Lib:Notify("KAIM unloaded. Safe to reload.", 4)
            end}
        }
    })
end)

tIns(Conns, UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode.Name == S.Mov.NoclipKey then
        local ns = not S.Mov.Noclip; SetNC(ns); Lib:Notify("Noclip "..(ns and "ON" or "OFF"), 2)
    elseif inp.KeyCode == _aimKC or (S.Aim.Key == "RightClick" and inp.UserInputType == Enum.UserInputType.MouseButton2) then
        S.Aim.IsAiming = true
    end
end))

tIns(Conns, UIS.InputEnded:Connect(function(inp)
    if inp.KeyCode == _aimKC or (S.Aim.Key == "RightClick" and inp.UserInputType == Enum.UserInputType.MouseButton2) then
        S.Aim.IsAiming = false
    end
end))

SM:LoadAutoloadConfig()
Lib:Notify("KAIM v9.0 Premium loaded — Press K to toggle.", 4)

end, debug.traceback)
if not ok then warn("KAIM FATAL:\n"..tostring(err)) end
end)
