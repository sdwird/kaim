-- ============================================================
--  KAIM v9.0  |  Obsidian Edition
--  Fixed: Chaos mode all limbs, ESP stable boxes, lean prediction
--  Optimized: batched draws, staggered raycasts, zero-GC hot path
-- ============================================================

task.spawn(function()
local ok, err = xpcall(function()

local _env = (type(getgenv) == "function" and getgenv()) or _G
if _env.KAIM_LOADED then
    warn("KAIM | Already loaded. Press K to toggle, or Unload in Settings.")
    return
end

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

local SafeContainer = LocalPlayer:FindFirstChild("PlayerGui") or workspace
pcall(function() local cg = game:GetService("CoreGui"); if cg then SafeContainer = cg end end)
pcall(function() local h = gethui and gethui(); if h and typeof(h)=="Instance" then SafeContainer=h end end)

-- ============================================================
--  OBSIDIAN LOAD
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library     = loadstring(game:HttpGet(repo.."Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()
local ThemeMgr    = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
if not Library then error("KAIM | Failed to load Obsidian.") end

_env.KAIM_LOADED = true

-- ============================================================
--  FAST LOCALS
-- ============================================================
local mFloor  = math.floor
local mClamp  = math.clamp
local mAbs    = math.abs
local mMax    = math.max
local mSqrt   = math.sqrt
local mSin    = math.sin
local mCos    = math.cos
local mAtan2  = math.atan2
local mExp    = math.exp
local mRandom = math.random
local mNoise  = math.noise
local mPi     = math.pi
local sUpper  = string.upper
local sClock  = os.clock
local V2      = Vector2.new
local V3      = Vector3.new
local C3      = Color3.fromRGB
local CF      = CFrame.new
local tInsert = table.insert
local tRemove = table.remove

local VEC3_ZERO = V3(0,0,0)
local PI4       = 0.78539816339

-- Static colors
local COL_BLACK   = C3(0,0,0)
local COL_WHITE   = C3(255,255,255)
local COL_RED     = C3(255,50,50)
local COL_HUD_BG  = C3(12,12,14)
local COL_HUD_OUT = C3(34,34,40)
local COL_HUD_VAL = C3(17,17,17)
local COL_BAR_BG  = C3(20,20,25)

local HP_COLORS = {C3(255,50,50), C3(255,130,0), C3(255,200,0), C3(100,255,50), C3(0,255,100)}
local DIST_COLORS = {C3(0,255,100), C3(100,255,100), C3(255,210,0), C3(255,140,0), C3(255,50,50)}

-- ============================================================
--  DRAWING WRAPPER
-- ============================================================
local HAS_DRAW = type(Drawing)=="table" and type(Drawing.new)=="function"

local function NewDraw(t)
    if HAS_DRAW then
        local ok, r = pcall(Drawing.new, t)
        if ok and r then r.Visible = false; return r end
    end
    -- Dummy that swallows all property sets
    local d = setmetatable({Visible=false,Thickness=1,Transparency=1,Color=Color3.new(),
        Filled=false,Text="",Size=12,Center=false,Outline=false,OutlineColor=Color3.new(),
        Font=1,From=V2(),To=V2(),Position=V2(),Radius=0},{
        __newindex=function(self,k,v) rawset(self,k,v) end,
        __index=function() return nil end,
    })
    d.Remove=function() end; d.Destroy=function() end
    return d
end

-- Inline-style updater: only write changed props to avoid redundant GPU calls
local function D(obj, v, p, s, c, tr, f, t, th, r, tx, o, ce, fi, fn)
    if v~=nil  and obj.Visible~=v   then obj.Visible=v   end
    if p~=nil  and obj.Position~=p  then obj.Position=p  end
    if s~=nil  and obj.Size~=s      then obj.Size=s      end
    if c~=nil  and obj.Color~=c     then obj.Color=c     end
    if tr~=nil and obj.Transparency~=tr then obj.Transparency=tr end
    if f~=nil  and obj.From~=f      then obj.From=f      end
    if t~=nil  and obj.To~=t        then obj.To=t        end
    if th~=nil and obj.Thickness~=th then obj.Thickness=th end
    if r~=nil  and obj.Radius~=r    then obj.Radius=r    end
    if tx~=nil and obj.Text~=tx     then obj.Text=tx     end
    if o~=nil  and obj.Outline~=o   then obj.Outline=o   end
    if ce~=nil and obj.Center~=ce   then obj.Center=ce   end
    if fi~=nil and obj.Filled~=fi   then obj.Filled=fi   end
    if fn~=nil and obj.Font~=fn     then obj.Font=fn     end
end

-- ============================================================
--  SETTINGS
-- ============================================================
local S = {
    Aim = {
        On            = false,
        Mode          = "Smart",   -- Smart|Chaos|Head|Torso|Limbs|HRP
        Priority      = "Crosshair",
        Key           = "RightClick",
        WallCheck     = true,
        TeamCheck     = true,
        Prediction    = true,
        PredStrength  = 0.135,
        Smooth        = false,
        SmoothSpeed   = 0.3,
        HitChance     = 100,
        OffX=0, OffY=0, OffZ=0,
        Noise         = false,
        NoiseSpd      = 1.0,
        NoiseAmt      = 0.5,
        IsAiming      = false,
        Target        = nil,
        _lastSearch   = 0,
    },
    TB = {
        On        = false,
        Delay     = 0.05,
        HitChance = 100,
        TeamCheck = true,
        Sphere    = true,
        Thick     = 0.5,
    },
    HB = {
        On    = false,
        Part  = "Head",
        Size  = 5,
        Trans = 0.5,
    },
    FOV = {
        Show   = true,
        Follow = true,
        Radius = 150,
        Thick  = 1.5,
        Color  = COL_WHITE,
        Trans  = 0.8,
        Filled = false,
        FColor = COL_WHITE,
        FTrans = 0.92,
        Pulse  = false,
    },
    ESP = {
        On           = false,
        BoxStyle     = "Corner",
        Boxes        = true,
        BoxFill      = false,
        BoxFillTrans = 0.2,
        Outline      = true,
        Names        = true,
        NameStyle    = "Display Name",
        TextCase     = "UPPERCASE",
        TextSize     = 14,
        Font         = 2,
        TeamCheck    = true,
        ShowTeam     = false,
        TeamColor    = C3(0,200,255),
        VisColors    = true,
        VisColor     = C3(0,255,100),
        HideColor    = COL_RED,
        StaticColor  = COL_WHITE,
        HealthBar    = true,
        HealthNums   = false,
        DistShow     = false,
        WeaponShow   = false,
        Tracers      = false,
        TracerOrigin = "Bottom",
        TracerColor  = C3(0,255,100),
        LookTrac     = false,
        LookLen      = 5,
        LookColor    = COL_WHITE,
        Arrows       = false,
        ArrowColor   = C3(255,85,0),
        ArrowRadius  = 120,
        ArrowSize    = 15,
        Chams        = false,
        ChamsVisCol  = true,
        ChamsFill    = COL_WHITE,
        ChamsOut     = COL_WHITE,
        ChamsFTrans  = 0.5,
        ChamsOTrans  = 0,
        DmgNums      = false,
        DmgColor     = C3(255,255,0),
        TargetHUD    = true,
        HUDStyle     = "Ascension",
        HUDScale     = 1.0,
        MaxDist      = 1000,
        -- Custom name color
        CustomName   = false,
        NameColor    = COL_WHITE,
    },
    World = {
        On      = false,
        Time    = 14,
        Bright  = 2,
        Shadows = false,
        Ambient = COL_WHITE,
    },
    Mov = {
        SpeedOn  = false, Speed    = 16,
        JumpOn   = false, Jump     = 50,
        InfJump  = false,
        FOVOn    = false, CamFOV   = 70,
        Noclip   = false,
    },
    Avoid = {
        On       = false,
        Chance   = 0.1,
        Duration = 0.2,
    },
    Perf = {
        Skip       = true,
        MaxPerFrame = 20,
        LODDist    = 500,
    },
}

-- ============================================================
--  STATE / CACHES
-- ============================================================
local Conns    = {}
local PCache   = {}   -- PlayerCache list
local TCache   = {}   -- TeamCache
local ESPObj   = {}   -- ESPObjects
local CCache   = {}   -- CharCache
local TracLine = {}
local LookLine = {}
local HBCache  = {}   -- original hitbox data
local OrigLit  = {}

local DmgPool    = {}
local ActiveDmg  = {}

-- Shared raycast params (zero-alloc)
local RayP = RaycastParams.new()
RayP.FilterType  = Enum.RaycastFilterType.Exclude
RayP.IgnoreWater = true
local RayF = {nil,nil}

local TBRayP = RaycastParams.new()
TBRayP.FilterType  = Enum.RaycastFilterType.Exclude
TBRayP.IgnoreWater = true
local TBRayF    = {nil,nil}
local TBLastChr = nil

local CandPool = {}

-- Chaos mode: pick from ALL parts the character actually has
local CHAOS_PARTS = {
    "Head","UpperTorso","LowerTorso","Torso",
    "LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
    "LeftHand","RightHand",
    "LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg",
    "LeftFoot","RightFoot",
    "Left Arm","Right Arm","Left Leg","Right Leg",
}
local chaosTimer    = 0
local CHAOS_INT     = 0.25
local chaosPartName = "Head"

local periodicTimer  = 0
local periodicOff    = false
local tbTimer        = 0
local RS_FRAME       = 0
local HB_FRAME       = 0
local STAGGER        = 3
local noclipKC       = Enum.KeyCode.N

local avgDT      = 0.016
local thudHP     = 100
local thudAlpha  = 0
local thudName   = ""
local thudData   = ""
local hudVisible = false

-- ============================================================
--  LIGHTING CACHE
-- ============================================================
local function CacheLit()
    OrigLit = {Time=Lighting.ClockTime, Bright=Lighting.Brightness,
               Shadows=Lighting.GlobalShadows, Ambient=Lighting.Ambient}
end
CacheLit()

tInsert(Conns, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    table.clear(TCache)
end))

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVRing = NewDraw("Circle"); FOVRing.Thickness=1.5; FOVRing.Filled=false
local FOVFill = NewDraw("Circle"); FOVFill.Thickness=1;   FOVFill.Filled=true

local ChamsFolder = Instance.new("Folder")
ChamsFolder.Name = "KaimChams"
pcall(function() ChamsFolder.Parent = SafeContainer end)

local THUD = {
    Shadow=NewDraw("Square"), BG=NewDraw("Square"), Outline=NewDraw("Square"),
    Accent=NewDraw("Square"), Accent2=NewDraw("Square"),
    Name=NewDraw("Text"), Data=NewDraw("Text"),
    BarBG=NewDraw("Square"), BarFG=NewDraw("Square"),
}
THUD.Shadow.Filled=true;  THUD.Shadow.Color=COL_BLACK
THUD.BG.Filled=true;      THUD.BG.Color=COL_HUD_BG
THUD.Outline.Filled=false; THUD.Outline.Color=COL_HUD_OUT
THUD.Accent.Filled=true;  THUD.Accent2.Filled=true
THUD.Name.Outline=true;   THUD.Name.Color=COL_WHITE;       THUD.Name.Font=2
THUD.Data.Outline=true;   THUD.Data.Color=C3(180,180,200); THUD.Data.Font=2
THUD.BarBG.Filled=true;   THUD.BarBG.Color=COL_BAR_BG
THUD.BarFG.Filled=true

-- ============================================================
--  UTILITIES
-- ============================================================
local function Fmt(s, c) return c=="UPPERCASE" and sUpper(s) or s end

local function Gradient(pct, arr)
    if pct<=0 then return arr[1] end
    if pct>=1 then return arr[#arr] end
    local sc  = pct*(#arr-1)+1
    local i   = mFloor(sc)
    local f   = sc-i
    if arr[i] and arr[i+1] then return arr[i]:Lerp(arr[i+1],f) end
    return arr[#arr]
end

local function HpColor(p)   return Gradient(p, HP_COLORS) end
local function DistColor(d)
    return Gradient(1-mClamp(d/mMax(S.ESP.MaxDist,1),0,1), DIST_COLORS)
end

-- Spawn floating damage number
local function SpawnDmg(dmg, pos3)
    local dn
    if #DmgPool>0 then dn=tRemove(DmgPool)
    else
        dn={T=NewDraw("Text"),str="",sp=V3(),vel=V3(),t0=0}
        dn.T.Center=true; dn.T.Outline=true; dn.T.OutlineColor=COL_BLACK; dn.T.Font=3
    end
    dn.str=tostring(mFloor(dmg))
    local a=mRandom()*mPi*2
    local spd=mRandom(15,30)/10
    dn.vel=V3(mCos(a)*spd, mRandom(35,55)/10, mSin(a)*spd)
    dn.sp=pos3+V3((mRandom()-0.5),1,(mRandom()-0.5))
    dn.t0=sClock()
    tInsert(ActiveDmg,dn)
end

local function UpdateDmgNums(cam)
    if not S.ESP.DmgNums and #ActiveDmg==0 then return end
    local now=sClock()
    for i=#ActiveDmg,1,-1 do
        local dn=ActiveDmg[i]; local el=now-dn.t0
        if el>=1.5 or not S.ESP.DmgNums then
            dn.T.Visible=false; tInsert(DmgPool,dn); tRemove(ActiveDmg,i)
        else
            local v=dn.vel
            local cp=dn.sp+V3(v.X*el,(v.Y*el)-(12.5*el*el),v.Z*el)
            local sp,on=cam:WorldToViewportPoint(cp)
            if on then
                local sz= el<0.15 and (14+18*(el/0.15)) or (el<0.35 and (32-12*((el-0.15)/0.2)) or 20)
                if dn.T.Text~=dn.str then dn.T.Text=dn.str end
                local p2=V2(sp.X,sp.Y)
                if dn.T.Position~=p2   then dn.T.Position=p2   end
                if dn.T.Size~=sz       then dn.T.Size=sz        end
                if dn.T.Color~=S.ESP.DmgColor then dn.T.Color=S.ESP.DmgColor end
                local al= el>1 and (1-(el-1)*2) or 1
                if dn.T.Transparency~=al then dn.T.Transparency=al end
                if not dn.T.Visible then dn.T.Visible=true end
            else
                if dn.T.Visible then dn.T.Visible=false end
            end
        end
    end
end

-- ============================================================
--  CHAOS PART PICKER — picks from parts that EXIST on the char
-- ============================================================
local function PickChaosPart(char)
    local found = {}
    for _,name in ipairs(CHAOS_PARTS) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then tInsert(found,p) end
    end
    if #found==0 then return char:FindFirstChild("HumanoidRootPart") end
    return found[mRandom(#found)]
end

-- ============================================================
--  TEAM / CHAR CACHE
-- ============================================================
local function IsTeam(p)
    if TCache[p]==nil then
        TCache[p]=(p.Team~=nil and p.Team==LocalPlayer.Team)
    end
    return TCache[p]
end

local function BuildChar(player, char)
    if not char then CCache[player]=nil; return end
    task.spawn(function()
        local hrp  = char:WaitForChild("HumanoidRootPart",5)
        local head = char:WaitForChild("Head",5)
        local hum  = char:WaitForChild("Humanoid",5)
        if not char.Parent or player.Character~=char then return end
        if hrp and head and hum then
            local cd = CCache[player] or {}
            cd.Char=char; cd.HRP=hrp; cd.Head=head; cd.Hum=hum
            cd._prevVel=VEC3_ZERO; cd._lastTick=sClock()
            CCache[player]=cd
        else CCache[player]=nil end
    end)
end

-- ============================================================
--  VISIBILITY RAYCAST
-- ============================================================
local function IsVis(part, char, camPos)
    if not part or not char then return false end
    local ok,pos=pcall(function() return part.Position end)
    if not ok then return false end
    RayF[1]=char; RayF[2]=LocalPlayer.Character
    RayP.FilterDescendantsInstances=RayF
    return workspace:Raycast(camPos, pos-camPos, RayP)==nil
end

-- ============================================================
--  AIM PART SELECTION
-- ============================================================
local SMART_PRIO = {"Head","UpperTorso","Torso","HumanoidRootPart"}

local function GetAimPart(cd, mode, camPos)
    local char=cd.Char
    if mode=="Smart" then
        for _,n in ipairs(SMART_PRIO) do
            local p=char:FindFirstChild(n)
            if p and IsVis(p,char,camPos) then return p,true end
        end
        return cd.HRP,false
    elseif mode=="Chaos" then
        -- chaosPartName is updated every CHAOS_INT seconds in the render loop
        local p=char:FindFirstChild(chaosPartName) or cd.HRP
        return p,true
    elseif mode=="Head" then return cd.Head,true
    elseif mode=="Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),true
    elseif mode=="Limbs" then
        local opts={}
        for _,n in ipairs({"LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
            "Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local p=char:FindFirstChild(n)
            if p then tInsert(opts,p) end
        end
        if #opts>0 then return opts[mRandom(#opts)],true end
        return cd.HRP,true
    else return cd.HRP,true end
end

-- ============================================================
--  TARGET SELECTION
-- ============================================================
local function GetTarget(camPos, fovPos, cam)
    local fovSq = S.FOV.Radius*S.FOV.Radius
    local myCd  = CCache[LocalPlayer]
    local myPos = myCd and myCd.HRP and myCd.HRP.Position or camPos
    local n=0

    for i=1,#PCache do
        local pl=PCache[i]; local cd=CCache[pl]
        if not cd or not cd.Hum or cd.Hum.Health<=0 then continue end
        if S.Aim.TeamCheck and IsTeam(pl) then continue end
        local sp,on=cam:WorldToViewportPoint(cd.HRP.Position)
        if not on then continue end
        local dx,dy=fovPos.X-sp.X, fovPos.Y-sp.Y
        local dmSq=dx*dx+dy*dy
        if dmSq>fovSq then continue end
        local rx=myPos.X-cd.HRP.Position.X
        local ry=myPos.Y-cd.HRP.Position.Y
        local rz=myPos.Z-cd.HRP.Position.Z
        n=n+1
        if not CandPool[n] then CandPool[n]={} end
        local c=CandPool[n]; c.pl=pl; c.cd=cd; c.dm=dmSq; c.dp=rx*rx+ry*ry+rz*rz
    end
    for i=n+1,#CandPool do CandPool[i]=nil end
    if n==0 then return nil end

    -- insertion sort
    local byDist = S.Aim.Priority=="Distance"
    for i=2,n do
        local k=CandPool[i]; local j=i-1
        if byDist then
            while j>0 and CandPool[j].dp>k.dp do CandPool[j+1]=CandPool[j];j=j-1 end
        else
            while j>0 and CandPool[j].dm>k.dm do CandPool[j+1]=CandPool[j];j=j-1 end
        end
        CandPool[j+1]=k
    end

    local checks=math.min(n,3)
    for i=1,checks do
        local c=CandPool[i]
        if not S.Aim.WallCheck then return c.pl end
        local p,vis=GetAimPart(c.cd, S.Aim.Mode, camPos)
        if p and vis then return c.pl end
    end
    return nil
end

-- ============================================================
--  ESP OBJECT LIFECYCLE
-- ============================================================
local function MakeESP(player)
    local e={
        Box=NewDraw("Square"), BoxOut=NewDraw("Square"), BoxFill=NewDraw("Square"),
        CL={}, -- corner lines [1..8] = {M=Line, O=Line}
        Name=NewDraw("Text"), Uname=NewDraw("Text"),
        Dist=NewDraw("Text"),  HP=NewDraw("Text"), Wep=NewDraw("Text"),
        BarBG=NewDraw("Square"), BarFG=NewDraw("Square"), BarOut=NewDraw("Square"),
        AL={}, -- arrow lines [1..4]
        Hl=nil,
        vis=false, _lv=false, _stag=mRandom(0,2),
        _hp=100, _font=-1,
        _tcase="", _dint=-1, _hint=-1, _wstr="\0", _nstr="\0", _ustr="\0",
    }
    e.Box.Thickness=1.5; e.BoxOut.Thickness=3.5; e.BoxFill.Thickness=1
    e.Box.Filled=false; e.BoxOut.Filled=false; e.BoxFill.Filled=true
    e.BoxOut.Transparency=0.7; e.BoxOut.Color=COL_BLACK

    for i=1,8 do
        e.CL[i]={M=NewDraw("Line"),O=NewDraw("Line")}
        e.CL[i].M.Thickness=1.5
        e.CL[i].O.Thickness=3.5; e.CL[i].O.Color=COL_BLACK; e.CL[i].O.Transparency=0.7
    end
    for i=1,4 do e.AL[i]=NewDraw("Line") end

    for _,t in ipairs({e.Name,e.Uname,e.Dist,e.HP,e.Wep}) do
        t.Center=true; t.Outline=true; t.OutlineColor=COL_BLACK
    end
    e.BarBG.Filled=true; e.BarBG.Color=C3(15,15,15)
    e.BarFG.Filled=true
    e.BarOut.Filled=false; e.BarOut.Color=COL_BLACK; e.BarOut.Thickness=1

    ESPObj[player]=e
end

local function HideESP(e)
    if not e._lv then return end
    e.Box.Visible=false; e.BoxOut.Visible=false; e.BoxFill.Visible=false
    for i=1,8 do e.CL[i].M.Visible=false; e.CL[i].O.Visible=false end
    e.Name.Visible=false; e.Uname.Visible=false; e.Dist.Visible=false
    e.HP.Visible=false; e.Wep.Visible=false
    e.BarBG.Visible=false; e.BarFG.Visible=false; e.BarOut.Visible=false
    for i=1,4 do e.AL[i].Visible=false end
    if e.Hl and e.Hl.Enabled then e.Hl.Enabled=false end
    e._lv=false
end

local function DestroyESP(e)
    pcall(function()
        e.Box:Remove(); e.BoxOut:Remove(); e.BoxFill:Remove()
        for i=1,8 do e.CL[i].M:Remove(); e.CL[i].O:Remove() end
        e.Name:Remove(); e.Uname:Remove(); e.Dist:Remove()
        e.HP:Remove(); e.Wep:Remove()
        e.BarBG:Remove(); e.BarFG:Remove(); e.BarOut:Remove()
        for i=1,4 do e.AL[i]:Remove() end
        if e.Hl then e.Hl:Destroy() end
    end)
end

-- ============================================================
--  PLAYER REGISTRATION
-- ============================================================
local function RegPlayer(pl)
    if pl==LocalPlayer then return end
    tInsert(PCache,pl)
    MakeESP(pl)
    tInsert(Conns, pl:GetPropertyChangedSignal("Team"):Connect(function() TCache[pl]=nil end))
    tInsert(Conns, pl.CharacterAdded:Connect(function(c) BuildChar(pl,c) end))
    tInsert(Conns, pl.CharacterRemoving:Connect(function()
        CCache[pl]=nil; HBCache[pl]=nil
    end))
    if pl.Character then BuildChar(pl,pl.Character) end
end

task.spawn(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then RegPlayer(p); task.wait() end
    end
end)

tInsert(Conns, Players.PlayerAdded:Connect(RegPlayer))
tInsert(Conns, Players.PlayerRemoving:Connect(function(pl)
    for i=1,#PCache do if PCache[i]==pl then tRemove(PCache,i); break end end
    local e=ESPObj[pl]
    if e then task.defer(function() DestroyESP(e) end) end
    ESPObj[pl]=nil; CCache[pl]=nil; TCache[pl]=nil; HBCache[pl]=nil
    if TracLine[pl] then TracLine[pl]:Remove(); TracLine[pl]=nil end
    if LookLine[pl] then LookLine[pl]:Remove(); LookLine[pl]=nil end
end))

tInsert(Conns, LocalPlayer.CharacterAdded:Connect(function(c)
    BuildChar(LocalPlayer,c)
    if S.Mov.Noclip then
        task.defer(function() if _G._KaimNC then _G._KaimNC(c) end end)
    end
end))
if LocalPlayer.Character then BuildChar(LocalPlayer,LocalPlayer.Character) end

-- ============================================================
--  FOV UPDATE
-- ============================================================
local function UpdateFOV(center)
    local pos  = S.FOV.Follow and UserInputService:GetMouseLocation() or center
    local pulse= S.FOV.Pulse and (mSin(sClock()*4)*5) or 0
    local rad  = mMax(1, S.FOV.Radius+pulse)
    D(FOVRing, S.FOV.Show, pos, rad, S.FOV.Color, S.FOV.Trans, nil,nil, S.FOV.Thick, rad)
    local fv = S.FOV.Show and S.FOV.Filled
    D(FOVFill, fv, pos, rad, S.FOV.FColor, S.FOV.FTrans)
    return pos
end

-- ============================================================
--  HUD HIDE
-- ============================================================
local function HideTHUD()
    if not hudVisible then return end
    for _,v in pairs(THUD) do v.Visible=false end
    hudVisible=false
end

-- ============================================================
--  AIMLOCK UPDATE
-- ============================================================
local function UpdateAim(camPos, sw, sh, dt, fovPos, cam)
    -- Periodic disable
    if S.Avoid.On and S.Aim.On then
        periodicTimer=periodicTimer-dt
        if periodicTimer<=0 then
            periodicOff=(mRandom()<S.Avoid.Chance)
            periodicTimer=S.Avoid.Duration+(mRandom()*0.4)
        end
    else periodicOff=false end

    -- Chaos: re-pick from char's actual parts
    if S.Aim.Mode=="Chaos" and S.Aim.IsAiming then
        chaosTimer=chaosTimer-dt
        if chaosTimer<=0 then
            chaosTimer=CHAOS_INT
            local cd=S.Aim.Target and CCache[S.Aim.Target]
            if cd and cd.Char then
                local p=PickChaosPart(cd.Char)
                chaosPartName=p and p.Name or "Head"
            end
        end
    end

    local showHUD=false

    if S.Aim.On and S.Aim.IsAiming and not periodicOff then
        if mRandom(1,100)>S.Aim.HitChance then
            S.Aim.Target=nil
        else
            local curCD=S.Aim.Target and CCache[S.Aim.Target]
            if not curCD or not curCD.Hum or curCD.Hum.Health<=0 then
                local now=sClock()
                if now-S.Aim._lastSearch>0.06 then
                    S.Aim.Target=GetTarget(camPos,fovPos,cam)
                    S.Aim._lastSearch=now
                end
            end
        end

        local tar=S.Aim.Target; local cd=tar and CCache[tar]
        if cd then
            local part,lockVis=GetAimPart(cd, S.Aim.Mode, camPos)
            if part then
                local aimPos=part.Position

                -- Prediction (velocity only, clean and simple)
                if S.Aim.Prediction then
                    local vel=part.AssemblyLinearVelocity
                    if vel.Magnitude>300 then vel=vel.Unit*300 end
                    aimPos=aimPos + vel*S.Aim.PredStrength
                end

                aimPos=aimPos+V3(S.Aim.OffX, S.Aim.OffY, S.Aim.OffZ)

                if S.Aim.Noise then
                    local tk=sClock()*S.Aim.NoiseSpd
                    aimPos=aimPos+V3(mNoise(tk,0,0)*S.Aim.NoiseAmt,
                                     mNoise(0,tk,0)*S.Aim.NoiseAmt,
                                     mNoise(0,0,tk)*S.Aim.NoiseAmt)
                end

                local tCF=CF(camPos,aimPos)
                if S.Aim.Smooth then
                    local spd=S.Aim.SmoothSpeed
                    local sf=mClamp(1-mExp(-spd*25*dt),0.01,1)
                    cam.CFrame=cam.CFrame:Lerp(tCF,sf)
                else
                    cam.CFrame=tCF
                end

                -- Target HUD
                if S.ESP.TargetHUD then
                    showHUD=true
                    local scale=S.ESP.HUDScale
                    local style=S.ESP.HUDStyle
                    local acCol= lockVis and COL_WHITE or COL_RED

                    local aHP=cd.Hum.Health or 0
                    thudHP=thudHP+(aHP-thudHP)*(dt*10)
                    if thudHP~=thudHP or thudHP<0 then thudHP=0 end
                    local hpPct=mClamp(thudHP/mMax(1,cd.Hum.MaxHealth or 100),0,1)

                    local di=0
                    local mc=CCache[LocalPlayer]
                    if mc and mc.HRP then di=mFloor((mc.HRP.Position-cd.HRP.Position).Magnitude) end

                    local rName=tar.DisplayName
                    local rData="HP: "..mFloor(aHP).."  |  Dist: "..di.."m"
                    if S.Aim.Mode=="Chaos" then rData=rData.."  |  "..chaosPartName end

                    if thudName~=rName then thudName=rName; THUD.Name.Text=Fmt(rName,S.ESP.TextCase) end
                    if thudData~=rData then thudData=rData; THUD.Data.Text=rData end

                    thudAlpha=mClamp(thudAlpha+dt*7,0,1)
                    local ea=1-mExp(-thudAlpha*5)
                    local ys=(1-ea)*35

                    -- reset all
                    for _,v in pairs(THUD) do v.Visible=false end
                    THUD.Name.Outline=true; THUD.Name.Center=false
                    THUD.Data.Outline=true; THUD.Data.Center=false

                    if style=="Valorant" then
                        local bw=mFloor(280*scale); local bh=mFloor(45*scale)
                        local hx=(sw/2)-(bw/2); local hy=mFloor(sh*0.08)-ys
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.85*ea; THUD.BG.Color=COL_HUD_VAL
                        THUD.Accent.Visible=true; THUD.Accent.Size=V2(bw,mMax(1,mFloor(2*scale))); THUD.Accent.Position=V2(hx,hy+bh); THUD.Accent.Color=acCol; THUD.Accent.Transparency=ea
                        THUD.Name.Visible=true; THUD.Name.Size=mMax(10,mFloor(17*scale)); THUD.Name.Position=V2(hx+mFloor(12*scale),hy+mFloor(6*scale)); THUD.Name.Transparency=ea
                        THUD.Data.Visible=true; THUD.Data.Size=mMax(10,mFloor(12*scale)); THUD.Data.Position=V2(hx+mFloor(12*scale),hy+mFloor(24*scale)); THUD.Data.Transparency=ea
                        THUD.BarBG.Visible=true; THUD.BarBG.Size=V2(bw,mMax(1,mFloor(3*scale))); THUD.BarBG.Position=V2(hx,hy+bh+mFloor(2*scale)); THUD.BarBG.Transparency=ea; THUD.BarBG.Color=COL_BLACK
                        THUD.BarFG.Visible=true; THUD.BarFG.Size=V2(bw*hpPct,mMax(1,mFloor(3*scale))); THUD.BarFG.Position=V2(hx,hy+bh+mFloor(2*scale)); THUD.BarFG.Color=HpColor(hpPct); THUD.BarFG.Transparency=ea

                    elseif style=="Standard" then
                        local bw=mFloor(mMax(200,40+#thudName*9)*scale); local bh=mFloor(56*scale)
                        local hx=(sw/2)-(bw/2); local hy=(sh-mFloor(140*scale))+ys
                        THUD.Shadow.Visible=true; THUD.Shadow.Size=V2(bw,bh); THUD.Shadow.Position=V2(hx+3,hy+3); THUD.Shadow.Transparency=0.5*ea
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.85*ea; THUD.BG.Color=COL_HUD_BG
                        THUD.Outline.Visible=true; THUD.Outline.Size=V2(bw+2,bh+2); THUD.Outline.Position=V2(hx-1,hy-1); THUD.Outline.Transparency=ea
                        THUD.Accent.Visible=true; THUD.Accent.Size=V2(bw,mMax(1,mFloor(2*scale))); THUD.Accent.Position=V2(hx,hy); THUD.Accent.Color=acCol; THUD.Accent.Transparency=ea
                        THUD.Name.Visible=true; THUD.Name.Size=mMax(10,mFloor(16*scale)); THUD.Name.Position=V2(hx+mFloor(10*scale),hy+mFloor(8*scale)); THUD.Name.Transparency=ea
                        THUD.Data.Visible=true; THUD.Data.Size=mMax(10,mFloor(13*scale)); THUD.Data.Position=V2(hx+mFloor(10*scale),hy+mFloor(28*scale)); THUD.Data.Transparency=ea
                        THUD.BarBG.Visible=true; THUD.BarBG.Size=V2(bw-mFloor(20*scale),mMax(1,mFloor(3*scale))); THUD.BarBG.Position=V2(hx+mFloor(10*scale),hy+mFloor(46*scale)); THUD.BarBG.Transparency=ea
                        THUD.BarFG.Visible=true; THUD.BarFG.Size=V2((bw-mFloor(20*scale))*hpPct,mMax(1,mFloor(3*scale))); THUD.BarFG.Position=V2(hx+mFloor(10*scale),hy+mFloor(46*scale)); THUD.BarFG.Color=HpColor(hpPct); THUD.BarFG.Transparency=ea

                    elseif style=="Ascension" then
                        local bw=mFloor(260*scale); local bh=mFloor(50*scale)
                        local hx=(sw/2)-(bw/2); local hy=mFloor(sh*0.12)-ys
                        THUD.Shadow.Visible=true; THUD.Shadow.Size=V2(bw+6,bh+6); THUD.Shadow.Position=V2(hx-3,hy-3); THUD.Shadow.Transparency=0.3*ea; THUD.Shadow.Color=acCol
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.9*ea; THUD.BG.Color=C3(5,5,10)
                        THUD.Outline.Visible=true; THUD.Outline.Size=V2(bw,bh); THUD.Outline.Position=V2(hx,hy); THUD.Outline.Color=acCol; THUD.Outline.Transparency=0.7*ea
                        THUD.Accent.Visible=true; THUD.Accent.Size=V2(mMax(1,mFloor(3*scale)),bh); THUD.Accent.Position=V2(hx,hy); THUD.Accent.Color=acCol; THUD.Accent.Transparency=ea
                        THUD.Name.Visible=true; THUD.Name.Size=mMax(10,mFloor(18*scale)); THUD.Name.Position=V2(hx+mFloor(15*scale),hy+mFloor(6*scale)); THUD.Name.Transparency=ea
                        THUD.Data.Visible=true; THUD.Data.Size=mMax(10,mFloor(11*scale)); THUD.Data.Position=V2(hx+mFloor(15*scale),hy+mFloor(26*scale)); THUD.Data.Transparency=0.8*ea
                        THUD.BarBG.Visible=true; THUD.BarBG.Size=V2(bw-mFloor(30*scale),mMax(1,mFloor(2*scale))); THUD.BarBG.Position=V2(hx+mFloor(15*scale),hy+bh-mFloor(8*scale)); THUD.BarBG.Transparency=0.5*ea; THUD.BarBG.Color=COL_BLACK
                        THUD.BarFG.Visible=true; THUD.BarFG.Size=V2((bw-mFloor(30*scale))*hpPct,mMax(1,mFloor(2*scale))); THUD.BarFG.Position=V2(hx+mFloor(15*scale),hy+bh-mFloor(8*scale)); THUD.BarFG.Color=HpColor(hpPct); THUD.BarFG.Transparency=ea

                    elseif style=="Minimal" then
                        local hx=(sw/2)-mFloor(100*scale); local hy=(sh-mFloor(130*scale))+ys
                        THUD.Accent.Visible=true; THUD.Accent.Size=V2(mMax(1,mFloor(3*scale)),mFloor(36*scale)); THUD.Accent.Position=V2(hx,hy); THUD.Accent.Color=acCol; THUD.Accent.Transparency=ea
                        THUD.Name.Visible=true; THUD.Name.Size=mMax(10,mFloor(16*scale)); THUD.Name.Position=V2(hx+mFloor(10*scale),hy); THUD.Name.Transparency=ea
                        THUD.Data.Visible=true; THUD.Data.Size=mMax(10,mFloor(13*scale)); THUD.Data.Position=V2(hx+mFloor(10*scale),hy+mFloor(20*scale)); THUD.Data.Transparency=ea

                    elseif style=="Apex" then
                        local bw=mFloor(220*scale); local bh=mFloor(45*scale)
                        local hx=(sw/2)-(bw/2); local hy=(sh-mFloor(120*scale))+ys
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.6*ea; THUD.BG.Color=COL_HUD_BG
                        THUD.Accent.Visible=true; THUD.Accent.Size=V2(mMax(1,mFloor(4*scale)),bh); THUD.Accent.Position=V2(hx,hy); THUD.Accent.Color=acCol; THUD.Accent.Transparency=ea
                        THUD.Name.Visible=true; THUD.Name.Size=mMax(10,mFloor(15*scale)); THUD.Name.Position=V2(hx+mFloor(12*scale),hy+mFloor(6*scale)); THUD.Name.Transparency=ea
                        THUD.Data.Visible=true; THUD.Data.Size=mMax(10,mFloor(11*scale)); THUD.Data.Position=V2(hx+mFloor(12*scale),hy+mFloor(24*scale)); THUD.Data.Transparency=ea
                        THUD.BarBG.Visible=true; THUD.BarBG.Size=V2(bw,mMax(1,mFloor(3*scale))); THUD.BarBG.Position=V2(hx,hy+bh); THUD.BarBG.Transparency=ea
                        THUD.BarFG.Visible=true; THUD.BarFG.Size=V2(bw*hpPct,mMax(1,mFloor(3*scale))); THUD.BarFG.Position=V2(hx,hy+bh); THUD.BarFG.Color=HpColor(hpPct); THUD.BarFG.Transparency=ea
                    end
                    hudVisible=true
                end
            else S.Aim.Target=nil end
        end
    else S.Aim.Target=nil end

    if not showHUD then
        thudAlpha=mClamp(thudAlpha-dt*8,0,1)
        if thudAlpha<=0 then HideTHUD()
        else
            local ea=1-mExp(-thudAlpha*5)
            if THUD.Shadow.Visible then THUD.Shadow.Transparency=0.5*ea end
            if THUD.BG.Visible     then THUD.BG.Transparency=0.85*ea    end
            if THUD.Outline.Visible then THUD.Outline.Transparency=ea   end
            if THUD.Accent.Visible  then THUD.Accent.Transparency=ea    end
            if THUD.Name.Visible    then THUD.Name.Transparency=ea      end
            if THUD.Data.Visible    then THUD.Data.Transparency=ea      end
            if THUD.BarBG.Visible   then THUD.BarBG.Transparency=ea     end
            if THUD.BarFG.Visible   then THUD.BarFG.Transparency=ea     end
        end
    end
end

-- ============================================================
--  CORNER BOX DRAW
-- ============================================================
local function DrawCorner(e, x, y, w, h, col, outline, thick)
    local L=mFloor(w/3)
    local cl=e.CL
    cl[1].M.From=V2(x,y);     cl[1].M.To=V2(x+L,y);     cl[1].M.Color=col; cl[1].M.Thickness=thick; cl[1].M.Visible=true
    cl[2].M.From=V2(x,y);     cl[2].M.To=V2(x,y+L);     cl[2].M.Color=col; cl[2].M.Thickness=thick; cl[2].M.Visible=true
    cl[3].M.From=V2(x+w,y);   cl[3].M.To=V2(x+w-L,y);   cl[3].M.Color=col; cl[3].M.Thickness=thick; cl[3].M.Visible=true
    cl[4].M.From=V2(x+w,y);   cl[4].M.To=V2(x+w,y+L);   cl[4].M.Color=col; cl[4].M.Thickness=thick; cl[4].M.Visible=true
    cl[5].M.From=V2(x,y+h);   cl[5].M.To=V2(x+L,y+h);   cl[5].M.Color=col; cl[5].M.Thickness=thick; cl[5].M.Visible=true
    cl[6].M.From=V2(x,y+h);   cl[6].M.To=V2(x,y+h-L);   cl[6].M.Color=col; cl[6].M.Thickness=thick; cl[6].M.Visible=true
    cl[7].M.From=V2(x+w,y+h); cl[7].M.To=V2(x+w-L,y+h); cl[7].M.Color=col; cl[7].M.Thickness=thick; cl[7].M.Visible=true
    cl[8].M.From=V2(x+w,y+h); cl[8].M.To=V2(x+w,y+h-L); cl[8].M.Color=col; cl[8].M.Thickness=thick; cl[8].M.Visible=true
    if outline then
        local ot=thick+2
        cl[1].O.From=V2(x-1,y-1);     cl[1].O.To=V2(x+L+1,y-1);     cl[1].O.Thickness=ot; cl[1].O.Visible=true
        cl[2].O.From=V2(x-1,y-1);     cl[2].O.To=V2(x-1,y+L+1);     cl[2].O.Thickness=ot; cl[2].O.Visible=true
        cl[3].O.From=V2(x+w+1,y-1);   cl[3].O.To=V2(x+w-L-1,y-1);   cl[3].O.Thickness=ot; cl[3].O.Visible=true
        cl[4].O.From=V2(x+w+1,y-1);   cl[4].O.To=V2(x+w+1,y+L+1);   cl[4].O.Thickness=ot; cl[4].O.Visible=true
        cl[5].O.From=V2(x-1,y+h+1);   cl[5].O.To=V2(x+L+1,y+h+1);   cl[5].O.Thickness=ot; cl[5].O.Visible=true
        cl[6].O.From=V2(x-1,y+h+1);   cl[6].O.To=V2(x-1,y+h-L-1);   cl[6].O.Thickness=ot; cl[6].O.Visible=true
        cl[7].O.From=V2(x+w+1,y+h+1); cl[7].O.To=V2(x+w-L-1,y+h+1); cl[7].O.Thickness=ot; cl[7].O.Visible=true
        cl[8].O.From=V2(x+w+1,y+h+1); cl[8].O.To=V2(x+w+1,y+h-L-1); cl[8].O.Thickness=ot; cl[8].O.Visible=true
    else for i=1,8 do if cl[i].O.Visible then cl[i].O.Visible=false end end end
end

-- ============================================================
--  ESP UPDATE  (rewritten for zero jitter + perf)
-- ============================================================
-- FIX: box size is now computed purely from screen-projected HRP + a fixed
-- half-height offset (no GetExtentsSize, which caused the jittery scaling)
-- We use a constant character half-height of 2.9 studs (covers most R6/R15 avatars).
local CHAR_HALF_H = 2.9
local CHAR_HALF_W = 1.0

local function UpdateESP(camPos, sw, sh, cam)
    local esp=S.ESP; local perf=S.Perf
    local maxDistSq = esp.MaxDist*esp.MaxDist
    local lodDistSq = perf.LODDist*perf.LODDist
    local center    = V2(sw*0.5, sh*0.5)

    local tracerY = sh
    if esp.TracerOrigin=="Top"    then tracerY=0
    elseif esp.TracerOrigin=="Center" then tracerY=sh*0.5 end
    local tracerStart=V2(sw*0.5, tracerY)

    local processed=0
    for i=1,#PCache do
        if perf.Skip and processed>=perf.MaxPerFrame and avgDT>0.02 then continue end

        local pl=PCache[i]; local e=ESPObj[pl]
        if not e then continue end

        local cd=CCache[pl]
        local hrpOk=false
        if cd and cd.HRP then
            local pok,pr=pcall(function() return cd.HRP.Parent end)
            hrpOk=pok and pr~=nil
        end
        if not cd or not hrpOk or not cd.Hum or cd.Hum.Health<=0 then
            HideESP(e)
            if TracLine[pl] and TracLine[pl].Visible then TracLine[pl].Visible=false end
            if LookLine[pl] and LookLine[pl].Visible then LookLine[pl].Visible=false end
            continue
        end

        local isTM=IsTeam(pl)
        if esp.TeamCheck and isTM and not esp.ShowTeam then HideESP(e); continue end

        processed=processed+1

        local myCd=CCache[LocalPlayer]
        local myPos=(myCd and myCd.HRP) and myCd.HRP.Position or camPos
        local hrpPos=cd.HRP.Position

        local dx=hrpPos.X-myPos.X; local dy=hrpPos.Y-myPos.Y; local dz=hrpPos.Z-myPos.Z
        local dSq=dx*dx+dy*dy+dz*dz
        if dSq>maxDistSq then HideESP(e); continue end
        local dist=mSqrt(dSq)

        local isLOD=dSq>lodDistSq

        -- WorldToViewport
        local rsp,onScreen=cam:WorldToViewportPoint(hrpPos)
        local depth=rsp.Z

        -- Visibility raycast (staggered)
        if (not isLOD) and onScreen and esp.VisColors then
            if e._stag==(RS_FRAME%STAGGER) then
                e.vis=IsVis(cd.HRP,cd.Char,camPos)
            end
        else e.vis=true end

        -- Final color
        local col
        if isTM and esp.ShowTeam then
            col=esp.TeamColor
        elseif esp.VisColors then
            col=e.vis and esp.VisColor or esp.HideColor
        else
            col=esp.StaticColor
        end

        -- Chams (skip LOD)
        if esp.Chams and not isLOD then
            if not e.Hl then
                e.Hl=Instance.new("Highlight"); e.Hl.Parent=ChamsFolder
            end
            if e.Hl.Adornee~=cd.Char then e.Hl.Adornee=cd.Char; e.Hl.Enabled=true end
            local fc=esp.ChamsVisCol and (e.vis and esp.VisColor or esp.HideColor) or esp.ChamsFill
            if e.Hl.FillColor~=fc           then e.Hl.FillColor=fc                end
            if e.Hl.OutlineColor~=esp.ChamsOut  then e.Hl.OutlineColor=esp.ChamsOut   end
            if e.Hl.FillTransparency~=esp.ChamsFTrans then e.Hl.FillTransparency=esp.ChamsFTrans end
            if e.Hl.OutlineTransparency~=esp.ChamsOTrans then e.Hl.OutlineTransparency=esp.ChamsOTrans end
        else
            if e.Hl and e.Hl.Enabled then e.Hl.Enabled=false; e.Hl.Adornee=nil end
        end

        -- Damage tracking (skip LOD)
        if not isLOD and cd.Hum.Health~=e._hp then
            local diff=e._hp-cd.Hum.Health
            if diff>0.5 and esp.DmgNums then SpawnDmg(diff,cd.Head.Position) end
            e._hp=cd.Hum.Health
        end

        -- Off-screen arrows (skip LOD)
        if esp.Arrows and not isLOD and (not onScreen or depth<=0) then
            local rel=cam.CFrame:PointToObjectSpace(hrpPos)
            local ang=mAtan2(rel.X,-rel.Z)
            local sa=mSin(ang); local ca=mCos(ang)
            local r=esp.ArrowRadius; local sz=esp.ArrowSize
            local ac=center+V2(sa*r,-ca*r)
            local p1=ac+V2(sa*sz,-ca*sz)
            local p2=ac+V2(mSin(ang-PI4)*sz*0.75,-mCos(ang-PI4)*sz*0.75)
            local p3=ac+V2(sa*sz*0.3,-ca*sz*0.3)
            local p4=ac+V2(mSin(ang+PI4)*sz*0.75,-mCos(ang+PI4)*sz*0.75)
            e.AL[1].From=p1; e.AL[1].To=p2; e.AL[1].Color=esp.ArrowColor; e.AL[1].Visible=true
            e.AL[2].From=p2; e.AL[2].To=p3; e.AL[2].Color=esp.ArrowColor; e.AL[2].Visible=true
            e.AL[3].From=p3; e.AL[3].To=p4; e.AL[3].Color=esp.ArrowColor; e.AL[3].Visible=true
            e.AL[4].From=p4; e.AL[4].To=p1; e.AL[4].Color=esp.ArrowColor; e.AL[4].Visible=true
        else if e.AL[1].Visible then for j=1,4 do e.AL[j].Visible=false end end end

        -- Tracers
        if esp.Tracers and not isLOD and depth>0 then
            if not TracLine[pl] then TracLine[pl]=NewDraw("Line"); TracLine[pl].Thickness=1.5 end
            TracLine[pl].Color=esp.TracerColor; TracLine[pl].From=tracerStart; TracLine[pl].To=V2(rsp.X,rsp.Y); TracLine[pl].Visible=onScreen
        elseif TracLine[pl] and TracLine[pl].Visible then TracLine[pl].Visible=false end

        -- Look tracers
        if esp.LookTrac and not isLOD and depth>0 then
            if not LookLine[pl] then LookLine[pl]=NewDraw("Line"); LookLine[pl].Thickness=1.5 end
            local lp=cd.Head.Position+(cd.Head.CFrame.LookVector*esp.LookLen)
            local hsp=cam:WorldToViewportPoint(cd.Head.Position)
            local lsp,lon=cam:WorldToViewportPoint(lp)
            if lon then
                LookLine[pl].From=V2(hsp.X,hsp.Y); LookLine[pl].To=V2(lsp.X,lsp.Y)
                LookLine[pl].Color=esp.LookColor; LookLine[pl].Visible=true
            else if LookLine[pl].Visible then LookLine[pl].Visible=false end end
        elseif LookLine[pl] and LookLine[pl].Visible then LookLine[pl].Visible=false end

        if not esp.On or not onScreen or depth<=0 then HideESP(e); continue end
        e._lv=true

        -- -------------------------------------------------------
        --  BOX COMPUTATION — fixed size, no GetExtentsSize
        --  Project top/bottom/side using constant offsets from HRP
        -- -------------------------------------------------------
        local topSP  = cam:WorldToViewportPoint(hrpPos + V3(0, CHAR_HALF_H, 0))
        local botSP  = cam:WorldToViewportPoint(hrpPos - V3(0, CHAR_HALF_H, 0))
        -- Use the camera's right vector to project side point
        local sideP  = hrpPos + cam.CFrame.RightVector * CHAR_HALF_W
        local sideSP = cam:WorldToViewportPoint(sideP)

        local bh = mAbs(topSP.Y - botSP.Y)
        local bw = mAbs(rsp.X - sideSP.X) * 2
        local bx = rsp.X - bw*0.5
        local by = topSP.Y

        -- Draw box
        if esp.Boxes then
            if esp.BoxStyle=="Standard" then
                e.Box.Visible=true; e.Box.Size=V2(bw,bh); e.Box.Position=V2(bx,by)
                e.Box.Color=col; e.Box.Thickness=1.5
                if esp.Outline then
                    e.BoxOut.Visible=true; e.BoxOut.Size=V2(bw+3,bh+3); e.BoxOut.Position=V2(bx-1.5,by-1.5)
                else if e.BoxOut.Visible then e.BoxOut.Visible=false end end
                for j=1,8 do
                    if e.CL[j].M.Visible then e.CL[j].M.Visible=false end
                    if e.CL[j].O.Visible then e.CL[j].O.Visible=false end
                end
            else
                if e.Box.Visible    then e.Box.Visible=false    end
                if e.BoxOut.Visible then e.BoxOut.Visible=false  end
                DrawCorner(e, bx, by, bw, bh, col, esp.Outline, 1.5)
            end
            if esp.BoxFill then
                e.BoxFill.Visible=true; e.BoxFill.Size=V2(bw,bh); e.BoxFill.Position=V2(bx,by)
                e.BoxFill.Color=col; e.BoxFill.Transparency=esp.BoxFillTrans
            else if e.BoxFill.Visible then e.BoxFill.Visible=false end end
        else
            if e.Box.Visible    then e.Box.Visible=false    end
            if e.BoxOut.Visible then e.BoxOut.Visible=false  end
            if e.BoxFill.Visible then e.BoxFill.Visible=false end
            for j=1,8 do
                if e.CL[j].M.Visible then e.CL[j].M.Visible=false end
                if e.CL[j].O.Visible then e.CL[j].O.Visible=false end
            end
        end

        local hpPct=mClamp(cd.Hum.Health/mMax(1,cd.Hum.MaxHealth or 100),0,1)

        -- Health bar
        if esp.HealthBar then
            local fh=mMax(1,bh*hpPct)
            e.BarBG.Visible=true; e.BarBG.Size=V2(4,bh+2); e.BarBG.Position=V2(bx-7,by-1)
            e.BarOut.Visible=true; e.BarOut.Size=V2(6,bh+4); e.BarOut.Position=V2(bx-8,by-2)
            e.BarFG.Visible=true; e.BarFG.Size=V2(2,fh); e.BarFG.Position=V2(bx-6,by+bh-fh); e.BarFG.Color=HpColor(hpPct)
        else
            if e.BarBG.Visible  then e.BarBG.Visible=false  end
            if e.BarFG.Visible  then e.BarFG.Visible=false  end
            if e.BarOut.Visible then e.BarOut.Visible=false  end
        end

        -- Font cache
        if e._font~=esp.Font then
            e._font=esp.Font
            for _,t in ipairs({e.Name,e.Uname,e.Dist,e.HP,e.Wep}) do t.Font=esp.Font end
        end

        -- Text cache reset on case change
        if e._tcase~=esp.TextCase then
            e._tcase=esp.TextCase; e._dint=-1; e._hint=-1
            e._wstr="\0"; e._nstr="\0"; e._ustr="\0"
        end

        local ty = by - esp.TextSize - 4
        local by2 = by + bh + 4
        local nCol = esp.CustomName and esp.NameColor or col

        if esp.Names then
            if esp.NameStyle=="Display Name" or esp.NameStyle=="Both" then
                local dn=pl.DisplayName
                if e._nstr~=dn then e._nstr=dn; e.Name.Text=Fmt(dn,esp.TextCase) end
                e.Name.Visible=true; e.Name.Position=V2(rsp.X,ty); e.Name.Color=nCol; e.Name.Size=esp.TextSize
                if esp.NameStyle=="Both" then ty=ty-(esp.TextSize-2) end
            else if e.Name.Visible then e.Name.Visible=false end end
            if esp.NameStyle=="Username" or esp.NameStyle=="Both" then
                local un="@"..pl.Name
                if e._ustr~=un then e._ustr=un; e.Uname.Text=Fmt(un,esp.TextCase) end
                e.Uname.Visible=true; e.Uname.Position=V2(rsp.X,ty)
                e.Uname.Color=esp.CustomName and C3(180,180,200) or col
                e.Uname.Size=mMax(10,esp.TextSize-2)
            else if e.Uname.Visible then e.Uname.Visible=false end end
        else
            if e.Name.Visible  then e.Name.Visible=false  end
            if e.Uname.Visible then e.Uname.Visible=false end
        end

        if esp.DistShow then
            local di=mFloor(dist)
            if e._dint~=di then
                e._dint=di; e.Dist.Text=Fmt(di.."m",esp.TextCase); e.Dist.Color=DistColor(di)
            end
            e.Dist.Visible=true; e.Dist.Position=V2(rsp.X,by2); e.Dist.Size=mMax(10,esp.TextSize-2)
            by2=by2+mMax(10,esp.TextSize-2)+2
        else if e.Dist.Visible then e.Dist.Visible=false end end

        if esp.HealthNums then
            local hi=mFloor(cd.Hum.Health)
            if e._hint~=hi then e._hint=hi; e.HP.Text=Fmt(hi.." HP",esp.TextCase) end
            e.HP.Visible=true; e.HP.Color=HpColor(hpPct); e.HP.Position=V2(rsp.X,by2); e.HP.Size=mMax(10,esp.TextSize-2)
            by2=by2+mMax(10,esp.TextSize-2)+2
        else if e.HP.Visible then e.HP.Visible=false end end

        if esp.WeaponShow and not isLOD then
            local tool=cd.Char:FindFirstChildOfClass("Tool")
            local ws=tool and tool.Name or "None"
            if e._wstr~=ws then e._wstr=ws; e.Wep.Text=Fmt(ws,esp.TextCase) end
            e.Wep.Visible=true; e.Wep.Color=C3(220,220,220); e.Wep.Position=V2(rsp.X,by2); e.Wep.Size=mMax(10,esp.TextSize-2)
        else if e.Wep.Visible then e.Wep.Visible=false end end
    end
end

-- ============================================================
--  HEARTBEAT LOOP
-- ============================================================
local function HeartbeatLoop(dt)
    HB_FRAME=HB_FRAME+1
    STAGGER=mClamp(mFloor(#PCache/6),3,15)

    -- Triggerbot
    if S.TB.On and VirtualInput then
        tbTimer=tbTimer-dt
        if tbTimer<=0 and mRandom(1,100)<=S.TB.HitChance then
            local cam=workspace.CurrentCamera
            if cam then
                local cx,cy=cam.ViewportSize.X*0.5, cam.ViewportSize.Y*0.5
                local origP, dir
                if S.FOV.Follow then
                    local mp=UserInputService:GetMouseLocation(); cx=mp.X; cy=mp.Y
                    local ur=cam:ViewportPointToRay(cx,cy); origP=ur.Origin; dir=ur.Direction*1000
                else origP=cam.CFrame.Position; dir=cam.CFrame.LookVector*1000 end

                local lc=LocalPlayer.Character
                if TBLastChr~=lc then
                    TBRayF[1]=cam; TBRayF[2]=lc
                    TBRayP.FilterDescendantsInstances=TBRayF; TBLastChr=lc
                end
                local res=S.TB.Sphere and workspace:Spherecast(origP,S.TB.Thick,dir,TBRayP)
                             or workspace:Raycast(origP,dir,TBRayP)
                if res and res.Instance then
                    local mdl=res.Instance:FindFirstAncestorOfClass("Model")
                    if mdl and mdl:FindFirstChild("Humanoid") then
                        local tp=Players:GetPlayerFromCharacter(mdl)
                        if tp and tp~=LocalPlayer and not (S.TB.TeamCheck and IsTeam(tp)) then
                            task.spawn(function()
                                pcall(function()
                                    VirtualInput:SendMouseButtonEvent(cx,cy,0,true,game,1)
                                    task.wait(0.01)
                                    VirtualInput:SendMouseButtonEvent(cx,cy,0,false,game,1)
                                end)
                            end)
                            tbTimer=S.TB.Delay
                        end
                    end
                end
            end
        end
    end

    -- Hitbox
    if S.HB.On then
        local ns=V3(S.HB.Size,S.HB.Size,S.HB.Size)
        local nt=S.HB.Trans
        for _,pl in ipairs(PCache) do
            if pl~=LocalPlayer and (not S.Aim.TeamCheck or not IsTeam(pl)) then
                local cd=CCache[pl]
                if cd and cd.Hum and cd.Hum.Health>0 then
                    local part=(S.HB.Part=="Head") and cd.Head
                        or (S.HB.Part=="HumanoidRootPart" and cd.HRP)
                        or cd.Char:FindFirstChild(S.HB.Part)
                    if part and part:IsA("BasePart") then
                        if not HBCache[pl] then HBCache[pl]={} end
                        if not HBCache[pl][part] then
                            HBCache[pl][part]={Sz=part.Size,Tr=part.Transparency,CC=part.CanCollide}
                        end
                        if part.Size~=ns    then part.Size=ns             end
                        if part.Transparency~=nt then part.Transparency=nt end
                        if part.CanCollide  then part.CanCollide=false     end
                    end
                end
            end
        end
    else
        for pl,parts in pairs(HBCache) do
            for part,d in pairs(parts) do
                if part and part.Parent then
                    if part.Size~=d.Sz          then part.Size=d.Sz           end
                    if part.Transparency~=d.Tr   then part.Transparency=d.Tr   end
                    if part.CanCollide~=d.CC     then part.CanCollide=d.CC     end
                end
            end
        end
        table.clear(HBCache)
    end

    -- World
    if S.World.On then
        if Lighting.ClockTime~=S.World.Time         then Lighting.ClockTime=S.World.Time         end
        if Lighting.Brightness~=S.World.Bright      then Lighting.Brightness=S.World.Bright      end
        if Lighting.GlobalShadows~=S.World.Shadows  then Lighting.GlobalShadows=S.World.Shadows  end
        if Lighting.Ambient~=S.World.Ambient        then Lighting.Ambient=S.World.Ambient        end
    else
        if Lighting.ClockTime~=OrigLit.Time         then Lighting.ClockTime=OrigLit.Time         end
        if Lighting.Brightness~=OrigLit.Bright      then Lighting.Brightness=OrigLit.Bright      end
        if Lighting.GlobalShadows~=OrigLit.Shadows  then Lighting.GlobalShadows=OrigLit.Shadows  end
        if Lighting.Ambient~=OrigLit.Ambient        then Lighting.Ambient=OrigLit.Ambient        end
    end

    -- Player mods
    local cam=workspace.CurrentCamera
    if cam and S.Mov.FOVOn and cam.FieldOfView~=S.Mov.CamFOV then cam.FieldOfView=S.Mov.CamFOV end
    local mc=CCache[LocalPlayer]
    if mc and mc.Hum then
        if S.Mov.SpeedOn and mc.Hum.WalkSpeed~=S.Mov.Speed then mc.Hum.WalkSpeed=S.Mov.Speed end
        if S.Mov.JumpOn  and mc.Hum.JumpPower~=S.Mov.Jump  then mc.Hum.JumpPower=S.Mov.Jump  end
    end
end

-- ============================================================
--  MASTER RENDER LOOP
-- ============================================================
local function RenderLoop(dt)
    local ok,e=pcall(function()
        RS_FRAME=RS_FRAME+1
        avgDT=avgDT*0.9+dt*0.1

        local cam=workspace.CurrentCamera
        if not cam then return end
        local vp=cam.ViewportSize
        if vp.X==0 or vp.Y==0 then return end

        local cp=cam.CFrame.Position
        local sw,sh=vp.X,vp.Y
        local sc=V2(sw*0.5,sh*0.5)

        local fovPos=UpdateFOV(sc)
        UpdateAim(cp,sw,sh,dt,fovPos,cam)
        UpdateESP(cp,sw,sh,cam)
        UpdateDmgNums(cam)
    end)
    if not ok then warn("KAIM Render Error: "..tostring(e)) end
end

tInsert(Conns, RunService.Heartbeat:Connect(HeartbeatLoop))
tInsert(Conns, RunService.RenderStepped:Connect(RenderLoop))

-- ============================================================
--  OBSIDIAN UI
-- ============================================================
local Win = Library:CreateWindow({
    Title         = "KAIM",
    Footer        = "v8.8 Obsidian",
    ToggleKeybind = Enum.KeyCode.K,
    NotifySide    = "Right",
})

local T = {
    Home    = Win:AddTab("Home",     "home"),
    Combat  = Win:AddTab("Combat",   "crosshair"),
    Visuals = Win:AddTab("Visuals",  "eye"),
    Player  = Win:AddTab("Movement", "person-standing"),
    Config  = Win:AddTab("Config",   "settings"),
}

-- ============================================================
--  HOME
-- ============================================================
local HomeL = T.Home:AddLeftGroupbox("KAIM v9.0")
local HomeR = T.Home:AddRightGroupbox("Stats")

HomeL:AddLabel({ Text="Obsidian Edition — Fixed chaos parts, stable ESP boxes, lean prediction, staggered raycasts.", DoesWrap=true })

local lFPS = HomeR:AddLabel({ Text="FPS: —" })
local lPL  = HomeR:AddLabel({ Text="Players: 0" })

task.spawn(function()
    while _env.KAIM_LOADED do
        local fps=mFloor(1/mMax(avgDT,0.001))
        pcall(function()
            lFPS:SetText("FPS: "..fps.."  ("..string.format("%.1f",avgDT*1000).."ms)")
            lPL:SetText("Players: "..#PCache.." tracked")
        end)
        task.wait(2)
    end
end)

-- ============================================================
--  COMBAT — Aimlock
-- ============================================================
local AimL = T.Combat:AddLeftGroupbox("Aimlock")
local AimR = T.Combat:AddRightGroupbox("Targeting")

AimL:AddToggle("AimOn",       { Text="Enable Aimlock",    Default=false,  Callback=function(v) S.Aim.On=v          end })
AimL:AddLabel("Aim Key"):AddKeyPicker("AimKey", { Default="RightClick", Text="Aim Key",
    Callback=function(v) S.Aim.Key=v end })
AimL:AddToggle("AimWall",     { Text="Wall Check",        Default=true,   Callback=function(v) S.Aim.WallCheck=v   end })
AimL:AddToggle("AimTeam",     { Text="Team Check",        Default=true,   Callback=function(v) S.Aim.TeamCheck=v   end })
AimL:AddSlider("AimHitChance",{ Text="Hit Chance %",      Default=100,    Min=1, Max=100, Rounding=0,
    Callback=function(v) S.Aim.HitChance=v end })
AimL:AddToggle("AimPred",     { Text="Prediction",        Default=true,   Callback=function(v) S.Aim.Prediction=v  end })
AimL:AddSlider("AimPredStr",  { Text="Prediction Strength",Default=0.135, Min=0, Max=0.3, Rounding=3,
    Callback=function(v) S.Aim.PredStrength=v end })
AimL:AddToggle("AimSmooth",   { Text="Smooth Aim",        Default=false,  Callback=function(v) S.Aim.Smooth=v      end })
AimL:AddSlider("AimSmoothSpd",{ Text="Smooth Speed",      Default=0.3,    Min=0.05, Max=1, Rounding=2,
    Callback=function(v) S.Aim.SmoothSpeed=v end })
AimL:AddToggle("AimNoise",    { Text="Perlin Noise",      Default=false,  Callback=function(v) S.Aim.Noise=v       end })
AimL:AddSlider("AimNoiseSpd", { Text="Noise Speed",       Default=1.0,    Min=0.1, Max=5, Rounding=1,
    Callback=function(v) S.Aim.NoiseSpd=v end })
AimL:AddSlider("AimNoiseAmt", { Text="Noise Amount",      Default=0.5,    Min=0, Max=2, Rounding=2,
    Callback=function(v) S.Aim.NoiseAmt=v end })

AimR:AddDropdown("AimPriority",{ Text="Priority", Values={"Crosshair","Distance"}, Default="Crosshair",
    Callback=function(v) S.Aim.Priority=v end })
AimR:AddDropdown("AimMode",    { Text="Aim Mode", Values={"Smart","Chaos","Head","Torso","Limbs","HRP"}, Default="Smart",
    Callback=function(v) S.Aim.Mode=v end })
AimR:AddSlider("AimOffX",     { Text="Offset X", Default=0, Min=-5, Max=5, Rounding=1,
    Callback=function(v) S.Aim.OffX=v end })
AimR:AddSlider("AimOffY",     { Text="Offset Y", Default=0, Min=-5, Max=5, Rounding=1,
    Callback=function(v) S.Aim.OffY=v end })
AimR:AddSlider("AimOffZ",     { Text="Offset Z", Default=0, Min=-5, Max=5, Rounding=1,
    Callback=function(v) S.Aim.OffZ=v end })

-- FOV
local FOVG = T.Combat:AddLeftGroupbox("FOV Circle")
FOVG:AddToggle("FOVShow",   { Text="Show FOV",         Default=true,  Callback=function(v) S.FOV.Show=v   end })
FOVG:AddToggle("FOVFollow", { Text="Follow Cursor",    Default=true,  Callback=function(v) S.FOV.Follow=v end })
FOVG:AddSlider("FOVRadius", { Text="Radius",           Default=150,   Min=20,  Max=600, Rounding=0, Suffix="px",
    Callback=function(v) S.FOV.Radius=v end })
FOVG:AddSlider("FOVThick",  { Text="Thickness",        Default=1.5,   Min=0.5, Max=5,   Rounding=1,
    Callback=function(v) S.FOV.Thick=v end })
FOVG:AddToggle("FOVPulse",  { Text="Pulse",            Default=false, Callback=function(v) S.FOV.Pulse=v  end })
FOVG:AddToggle("FOVFilled", { Text="Filled",           Default=false, Callback=function(v) S.FOV.Filled=v end })
FOVG:AddLabel("Color"):AddColorPicker("FOVColor",      { Default=COL_WHITE, Callback=function(v) S.FOV.Color=v  end })

-- Triggerbot / Hitbox
local TBG = T.Combat:AddRightGroupbox("Triggerbot")
TBG:AddToggle("TBOn",      { Text="Enable Triggerbot", Default=false, Callback=function(v) S.TB.On=v        end })
TBG:AddToggle("TBTeam",    { Text="Team Check",        Default=true,  Callback=function(v) S.TB.TeamCheck=v end })
TBG:AddToggle("TBSphere",  { Text="Spherecast",        Default=true,  Callback=function(v) S.TB.Sphere=v   end })
TBG:AddSlider("TBThick",   { Text="Ray Thickness",     Default=0.5,   Min=0.1, Max=3,    Rounding=1,
    Callback=function(v) S.TB.Thick=v end })
TBG:AddSlider("TBDelay",   { Text="Trigger Delay",     Default=0.05,  Min=0.01, Max=0.5, Rounding=2,
    Callback=function(v) S.TB.Delay=v end })
TBG:AddSlider("TBHit",     { Text="Hit Chance %",      Default=100,   Min=1, Max=100, Rounding=0,
    Callback=function(v) S.TB.HitChance=v end })

local HBG = T.Combat:AddRightGroupbox("Hitbox Expander")
HBG:AddToggle("HBOn",      { Text="Enable",            Default=false, Callback=function(v) S.HB.On=v      end })
HBG:AddDropdown("HBPart",  { Text="Part", Values={"Head","HumanoidRootPart","UpperTorso"}, Default="Head",
    Callback=function(v) S.HB.Part=v end })
HBG:AddSlider("HBSize",    { Text="Size",              Default=5,     Min=2, Max=30, Rounding=1,
    Callback=function(v) S.HB.Size=v end })
HBG:AddSlider("HBTrans",   { Text="Transparency",      Default=0.5,   Min=0, Max=1,  Rounding=2,
    Callback=function(v) S.HB.Trans=v end })

-- Anti-detect
local ADG = T.Combat:AddLeftGroupbox("Anti-Detect")
ADG:AddToggle("ADOn",       { Text="Periodic Disable", Default=false, Callback=function(v) S.Avoid.On=v       end })
ADG:AddSlider("ADChance",   { Text="Disable Chance",   Default=0.1,   Min=0.01, Max=1, Rounding=2,
    Callback=function(v) S.Avoid.Chance=v end })
ADG:AddSlider("ADDuration", { Text="Disable Duration", Default=0.2,   Min=0.05, Max=1, Rounding=2,
    Callback=function(v) S.Avoid.Duration=v end })

-- ============================================================
--  VISUALS
-- ============================================================
local VL = T.Visuals:AddLeftGroupbox("ESP Settings")
local VR = T.Visuals:AddRightGroupbox("Colors")

VL:AddToggle("ESPOn",       { Text="Enable ESP",        Default=false, Callback=function(v) S.ESP.On=v          end })
VL:AddSlider("ESPDist",     { Text="Max Distance",      Default=1000,  Min=100, Max=5000, Rounding=0, Suffix="m",
    Callback=function(v) S.ESP.MaxDist=v end })
VL:AddToggle("ESPTeam",     { Text="Team Check",        Default=true,  Callback=function(v) S.ESP.TeamCheck=v   end })
VL:AddToggle("ESPShowTeam", { Text="Show Teammates",    Default=false, Callback=function(v) S.ESP.ShowTeam=v    end })
VL:AddLabel("Teammate Color"):AddColorPicker("ESPTeamCol",{ Default=C3(0,200,255), Callback=function(v) S.ESP.TeamColor=v end })
VL:AddToggle("ESPBoxes",    { Text="Show Boxes",        Default=true,  Callback=function(v) S.ESP.Boxes=v       end })
VL:AddDropdown("ESPBoxStyle",{ Text="Box Style", Values={"Standard","Corner"}, Default="Corner",
    Callback=function(v) S.ESP.BoxStyle=v end })
VL:AddToggle("ESPOutline",  { Text="Box Outline",       Default=true,  Callback=function(v) S.ESP.Outline=v     end })
VL:AddToggle("ESPFill",     { Text="Box Fill",          Default=false, Callback=function(v) S.ESP.BoxFill=v     end })
VL:AddSlider("ESPFillTrans",{ Text="Fill Transparency", Default=0.2,   Min=0, Max=1, Rounding=2,
    Callback=function(v) S.ESP.BoxFillTrans=v end })
VL:AddToggle("ESPNames",    { Text="Show Names",        Default=true,  Callback=function(v) S.ESP.Names=v       end })
VL:AddDropdown("ESPNStyle", { Text="Name Style", Values={"Display Name","Username","Both"}, Default="Display Name",
    Callback=function(v) S.ESP.NameStyle=v end })
VL:AddDropdown("ESPCase",   { Text="Text Case", Values={"Normal","UPPERCASE"}, Default="UPPERCASE",
    Callback=function(v) S.ESP.TextCase=v end })
VL:AddSlider("ESPTxtSz",    { Text="Text Size",         Default=14,    Min=10, Max=22, Rounding=0,
    Callback=function(v) S.ESP.TextSize=v end })
VL:AddToggle("ESPHealthBar",{ Text="Health Bar",        Default=true,  Callback=function(v) S.ESP.HealthBar=v   end })
VL:AddToggle("ESPHealthNum",{ Text="Health Numbers",    Default=false, Callback=function(v) S.ESP.HealthNums=v  end })
VL:AddToggle("ESPDist2",    { Text="Distance",          Default=false, Callback=function(v) S.ESP.DistShow=v    end })
VL:AddToggle("ESPWeapon",   { Text="Weapon",            Default=false, Callback=function(v) S.ESP.WeaponShow=v  end })

VR:AddToggle("ESPVisCol",   { Text="Visibility Colors", Default=true,  Callback=function(v) S.ESP.VisColors=v   end })
VR:AddLabel("Visible Color"):AddColorPicker("ESPVCol",  { Default=C3(0,255,100), Callback=function(v) S.ESP.VisColor=v  end })
VR:AddLabel("Hidden Color"):AddColorPicker("ESPHCol",   { Default=COL_RED,       Callback=function(v) S.ESP.HideColor=v end })
VR:AddLabel("Static Color"):AddColorPicker("ESPSCol",   { Default=COL_WHITE,     Callback=function(v) S.ESP.StaticColor=v end })
VR:AddToggle("ESPCustName", { Text="Custom Name Color", Default=false, Callback=function(v) S.ESP.CustomName=v  end })
VR:AddLabel("Name Color"):AddColorPicker("ESPNCol",     { Default=COL_WHITE,     Callback=function(v) S.ESP.NameColor=v end })
VR:AddLabel("Damage Color"):AddColorPicker("ESPDCol",   { Default=C3(255,255,0), Callback=function(v) S.ESP.DmgColor=v end })

-- Indicators
local IL = T.Visuals:AddLeftGroupbox("Indicators")
IL:AddToggle("IndTracers",  { Text="Tracer Lines",      Default=false, Callback=function(v) S.ESP.Tracers=v     end })
IL:AddDropdown("IndTracOri",{ Text="Tracer Origin", Values={"Bottom","Center","Top"}, Default="Bottom",
    Callback=function(v) S.ESP.TracerOrigin=v end })
IL:AddLabel("Tracer Color"):AddColorPicker("IndTracCol",{ Default=C3(0,255,100), Callback=function(v) S.ESP.TracerColor=v end })
IL:AddToggle("IndLook",     { Text="Look Tracers",      Default=false, Callback=function(v) S.ESP.LookTrac=v    end })
IL:AddSlider("IndLookLen",  { Text="Look Length",       Default=5,     Min=1, Max=30, Rounding=0,
    Callback=function(v) S.ESP.LookLen=v end })
IL:AddToggle("IndArrows",   { Text="Off-Screen Arrows", Default=false, Callback=function(v) S.ESP.Arrows=v      end })
IL:AddToggle("IndDmgNums",  { Text="Damage Numbers",    Default=false, Callback=function(v) S.ESP.DmgNums=v     end })

-- Target HUD
local IR = T.Visuals:AddRightGroupbox("Target HUD")
IR:AddToggle("HUDOn",       { Text="Show Target HUD",  Default=true,  Callback=function(v) S.ESP.TargetHUD=v   end })
IR:AddDropdown("HUDStyle",  { Text="Style", Values={"Ascension","Valorant","Standard","Minimal","Apex"}, Default="Ascension",
    Callback=function(v) S.ESP.HUDStyle=v end })
IR:AddSlider("HUDScale",    { Text="Scale",            Default=1.0,   Min=0.5, Max=2, Rounding=2,
    Callback=function(v) S.ESP.HUDScale=v end })

-- Chams
local CG = T.Visuals:AddRightGroupbox("Chams")
CG:AddToggle("ChamsOn",     { Text="Enable Chams",     Default=false, Callback=function(v) S.ESP.Chams=v        end })
CG:AddToggle("ChamsVis",    { Text="Visibility Colors",Default=true,  Callback=function(v) S.ESP.ChamsVisCol=v  end })
CG:AddLabel("Fill"):AddColorPicker("ChamsFill",        { Default=COL_WHITE, Callback=function(v) S.ESP.ChamsFill=v  end })
CG:AddLabel("Outline"):AddColorPicker("ChamsOut",      { Default=COL_WHITE, Callback=function(v) S.ESP.ChamsOut=v   end })
CG:AddSlider("ChamsFT",     { Text="Fill Trans",       Default=0.5,   Min=0, Max=1, Rounding=2,
    Callback=function(v) S.ESP.ChamsFTrans=v end })
CG:AddSlider("ChamsOT",     { Text="Outline Trans",    Default=0,     Min=0, Max=1, Rounding=2,
    Callback=function(v) S.ESP.ChamsOTrans=v end })

-- World
local WG = T.Visuals:AddLeftGroupbox("World")
WG:AddToggle("WorldOn",     { Text="Override Lighting", Default=false, Callback=function(v) S.World.On=v       end })
WG:AddSlider("WorldTime",   { Text="Time",              Default=14,    Min=0, Max=24, Rounding=1,
    Callback=function(v) S.World.Time=v end })
WG:AddSlider("WorldBright", { Text="Brightness",        Default=2,     Min=0, Max=5,  Rounding=1,
    Callback=function(v) S.World.Bright=v end })
WG:AddToggle("WorldShad",   { Text="Global Shadows",   Default=false, Callback=function(v) S.World.Shadows=v  end })
WG:AddLabel("Ambient"):AddColorPicker("WorldAmb",      { Default=COL_WHITE, Callback=function(v) S.World.Ambient=v end })

-- ============================================================
--  MOVEMENT
-- ============================================================
local ML = T.Player:AddLeftGroupbox("Character")
local MR = T.Player:AddRightGroupbox("Physics")

ML:AddToggle("SpeedOn",  { Text="Speed Override",  Default=false, Callback=function(v) S.Mov.SpeedOn=v end })
ML:AddSlider("Speed",    { Text="Walk Speed",       Default=16,    Min=5,  Max=100, Rounding=0,
    Callback=function(v) S.Mov.Speed=v end })
ML:AddToggle("JumpOn",   { Text="Jump Override",   Default=false, Callback=function(v) S.Mov.JumpOn=v  end })
ML:AddSlider("Jump",     { Text="Jump Power",       Default=50,    Min=10, Max=250, Rounding=0,
    Callback=function(v) S.Mov.Jump=v end })
ML:AddToggle("CamFOVOn", { Text="FOV Override",    Default=false, Callback=function(v) S.Mov.FOVOn=v   end })
ML:AddSlider("CamFOV",   { Text="Camera FOV",       Default=70,    Min=30, Max=120, Rounding=0, Suffix="°",
    Callback=function(v) S.Mov.CamFOV=v end })
ML:AddToggle("InfJump",  { Text="Infinite Jump",   Default=false, Callback=function(v) S.Mov.InfJump=v end })

local noclipConn=nil; local noclipAddConn=nil; local noclipCache={}

local function BuildNC(char)
    noclipCache={}
    if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then tInsert(noclipCache,{p=p,cc=p.CanCollide}) end
    end
end
_G._KaimNC=BuildNC

local function SetNoclip(on)
    S.Mov.Noclip=on
    if noclipConn    then noclipConn:Disconnect();    noclipConn=nil    end
    if noclipAddConn then noclipAddConn:Disconnect(); noclipAddConn=nil end
    if on then
        BuildNC(LocalPlayer.Character)
        noclipConn=RunService.Stepped:Connect(function()
            for _,e in ipairs(noclipCache) do
                if e.p and e.p.Parent and e.p.CanCollide then e.p.CanCollide=false end
            end
        end)
        if LocalPlayer.Character then
            noclipAddConn=LocalPlayer.Character.DescendantAdded:Connect(function(p)
                if p:IsA("BasePart") then tInsert(noclipCache,{p=p,cc=p.CanCollide}); p.CanCollide=false end
            end)
        end
        tInsert(Conns,noclipConn); tInsert(Conns,noclipAddConn)
    else
        for _,e in ipairs(noclipCache) do
            if e.p and e.p.Parent and e.p.CanCollide~=e.cc then e.p.CanCollide=e.cc end
        end
        noclipCache={}
    end
end

MR:AddToggle("NCOn",   { Text="Noclip",        Default=false, Callback=function(v) SetNoclip(v) end })
MR:AddLabel("Noclip Key"):AddKeyPicker("NCKey", { Default="N", Text="Noclip Key",
    Callback=function(v)
        S.Mov.NoclipKey=v
        pcall(function() noclipKC=Enum.KeyCode[v] end)
    end })

tInsert(Conns, UserInputService.JumpRequest:Connect(function()
    if S.Mov.InfJump then
        local cd=CCache[LocalPlayer]
        if cd and cd.Hum then cd.Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- ============================================================
--  CONFIG
-- ============================================================
local CfgL = T.Config:AddLeftGroupbox("Save / Load")
local CfgR = T.Config:AddRightGroupbox("Performance")

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"AimKey","NCKey"})
SaveManager:SetFolder("KAIM_v8")
SaveManager:BuildConfigSection(T.Config)

ThemeMgr:SetLibrary(Library)
ThemeMgr:SetFolder("KAIM_v8")
ThemeMgr:ApplyToTab(T.Config)
ThemeMgr:LoadDefault()

CfgR:AddToggle("PerfSkip",  { Text="Frame Skip",       Default=true,  Callback=function(v) S.Perf.Skip=v        end })
CfgR:AddSlider("PerfMax",   { Text="Max ESP/Frame",     Default=20,    Min=5,  Max=50,   Rounding=0,
    Callback=function(v) S.Perf.MaxPerFrame=v end })
CfgR:AddSlider("LODDist",   { Text="LOD Distance",      Default=500,   Min=100,Max=1000, Rounding=0, Suffix="m",
    Callback=function(v) S.Perf.LODDist=v end })
CfgR:AddLabel({ Text="LOD: players past this distance get box+name+health only. Saves raycasts and draw calls.", DoesWrap=true })

-- Unload
local DG = T.Config:AddLeftGroupbox("Danger Zone")
DG:AddButton("Unload KAIM", function()
    for _,c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    for _,e in pairs(ESPObj) do DestroyESP(e) end; ESPObj={}
    for _,l in pairs(TracLine) do pcall(function() l:Remove() end) end; TracLine={}
    for _,l in pairs(LookLine) do pcall(function() l:Remove() end) end; LookLine={}
    for _,d in ipairs(ActiveDmg) do pcall(function() d.T:Remove() end) end; ActiveDmg={}
    for _,d in ipairs(DmgPool)   do pcall(function() d.T:Remove() end) end; DmgPool={}

    Lighting.ClockTime=OrigLit.Time; Lighting.Brightness=OrigLit.Bright
    Lighting.GlobalShadows=OrigLit.Shadows; Lighting.Ambient=OrigLit.Ambient

    for _,pts in pairs(HBCache) do
        for part,d in pairs(pts) do
            if part and part.Parent then part.Size=d.Sz; part.Transparency=d.Tr; part.CanCollide=d.CC end
        end
    end

    SetNoclip(false)
    pcall(function() FOVRing:Remove(); FOVFill:Remove() end)
    pcall(function() ChamsFolder:Destroy() end)
    pcall(function() for _,v in pairs(THUD) do v:Remove() end end)

    _env.KAIM_LOADED=false; _G._KaimNC=nil
    Library:Notify("KAIM unloaded. Safe to reload.", 4)
end)

-- ============================================================
--  INPUT
-- ============================================================
tInsert(Conns, UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode==noclipKC then
        local ns=not S.Mov.Noclip; SetNoclip(ns)
        Library:Notify("Noclip "..(ns and "ON" or "OFF"), 2)
    end
    local ak=S.Aim.Key
    if ak=="RightClick" then
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then S.Aim.IsAiming=true end
    else
        local ok,kc=pcall(function() return Enum.KeyCode[ak] end)
        if ok and kc and inp.KeyCode==kc then S.Aim.IsAiming=true end
    end
end))

tInsert(Conns, UserInputService.InputEnded:Connect(function(inp)
    local ak=S.Aim.Key
    if ak=="RightClick" then
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then S.Aim.IsAiming=false end
    else
        local ok,kc=pcall(function() return Enum.KeyCode[ak] end)
        if ok and kc and inp.KeyCode==kc then S.Aim.IsAiming=false end
    end
end))

T.Home:Select()
SaveManager:LoadAutoloadConfig()
Library:Notify("KAIM v9.0 loaded — Press K to toggle.", 4)

end, debug.traceback)
if not ok then warn("KAIM FATAL:\n"..tostring(err)) end
end)
