-- ============================================================
--  KAIM v8.8  |  Obsidian Edition — Final
--  ESP: screen-depth box, 1 WorldToViewport call per player,
--       staggered raycasts, full chams distance system
--  Aim: FOV-circle target lock, smooth lerp, chaos all parts
-- ============================================================
task.spawn(function()
local ok, err = xpcall(function()

local _env = (type(getgenv)=="function" and getgenv()) or _G
if _env.KAIM_LOADED then
    warn("KAIM | Already loaded. Press K to toggle UI."); return
end
if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================================
--  SERVICES
-- ============================================================
local RS  = game:GetService("RunService")
local Plr = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lit = game:GetService("Lighting")
local LP  = Plr.LocalPlayer

local VI; pcall(function() VI = game:GetService("VirtualInputManager") end)

local SafeGui = LP:FindFirstChild("PlayerGui") or workspace
pcall(function() local c=game:GetService("CoreGui"); if c then SafeGui=c end end)
pcall(function() local h=gethui and gethui(); if h and typeof(h)=="Instance" then SafeGui=h end end)

-- ============================================================
--  OBSIDIAN
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Lib  = loadstring(game:HttpGet(repo.."Library.lua"))()
local SM   = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()
local TM   = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
assert(Lib, "KAIM | Failed to load Obsidian Library.")
_env.KAIM_LOADED = true

-- ============================================================
--  FAST LOCALS
-- ============================================================
local mFloor, mClamp, mAbs, mMax, mMin, mSqrt = math.floor, math.clamp, math.abs, math.max, math.min, math.sqrt
local mSin, mCos, mAtan2, mExp, mRand, mNoise, mPi = math.sin, math.cos, math.atan2, math.exp, math.random, math.noise, math.pi
local sUp, sClock = string.upper, os.clock
local V2, V3, C3, CF = Vector2.new, Vector3.new, Color3.fromRGB, CFrame.new
local tIns, tRem = table.insert, table.remove

-- Static palette
local BLACK   = C3(0,0,0)
local WHITE   = C3(255,255,255)
local RED     = C3(255,50,50)
local HUD_BG  = C3(12,12,14)
local HUD_VAL = C3(17,17,17)
local BAR_BG  = C3(20,20,25)
local HP_PAL  = {C3(255,50,50),C3(255,130,0),C3(255,200,0),C3(100,255,50),C3(0,255,100)}
local D_PAL   = {C3(0,255,100),C3(100,255,100),C3(255,210,0),C3(255,140,0),C3(255,50,50)}

local function Grad(p, t)
    if p<=0 then return t[1] end; if p>=1 then return t[#t] end
    local s=p*(#t-1)+1; local i=mFloor(s); local f=s-i
    return (t[i] and t[i+1]) and t[i]:Lerp(t[i+1],f) or t[#t]
end
local function HPC(p) return Grad(p, HP_PAL) end
local function DC(d,mx) return Grad(1-mClamp(d/mMax(mx,1),0,1), D_PAL) end
local function Fmt(s,c) return c=="UPPERCASE" and sUp(s) or s end

-- ============================================================
--  DRAWING
-- ============================================================
local HAS_D = type(Drawing)=="table" and type(Drawing.new)=="function"
local function ND(t)
    if HAS_D then local ok,r=pcall(Drawing.new,t); if ok and r then r.Visible=false; return r end end
    local d=setmetatable({Visible=false,Thickness=1,Transparency=1,Color=Color3.new(),Filled=false,
        Text="",Size=12,Center=false,Outline=false,OutlineColor=Color3.new(),Font=1,
        From=V2(),To=V2(),Position=V2(),Radius=0},
        {__newindex=function(s,k,v) rawset(s,k,v) end, __index=function() return nil end})
    d.Remove=function()end; d.Destroy=function()end; return d
end

-- ============================================================
--  SETTINGS
-- ============================================================
local S = {
    Aim = {
        On=false, Mode="Smart", Priority="Crosshair", Key="RightClick",
        WallCheck=true, TeamCheck=true,
        Pred=true, PredStr=0.135,
        Smooth=false, SmoothSpd=0.3,
        HitChance=100,
        OffX=0, OffY=0, OffZ=0,
        Noise=false, NoiseSpd=1, NoiseAmt=0.5,
        IsAiming=false, Target=nil, _lastSearch=0,
    },
    TB = { On=false, Delay=0.05, HC=100, Team=true, Sphere=true, Thick=0.5 },
    HB = { On=false, Part="Head", Size=5, Trans=0.5 },
    FOV = { Show=true, Follow=true, Radius=150, Thick=1.5, Color=WHITE,
            Trans=0.8, Filled=false, FC=WHITE, FT=0.92, Pulse=false },
    ESP = {
        On=false, BoxStyle="Corner", Boxes=true, BoxFill=false, BoxFillT=0.2,
        Outline=true, Names=true, NStyle="Display Name", TCase="UPPERCASE",
        TSize=14, Font=2,
        TeamCheck=true, ShowTeam=false, TeamCol=C3(0,200,255),
        VisColors=true, VisCol=C3(0,255,100), HideCol=RED, StatCol=WHITE,
        HBar=true, HNums=false, DistShow=false, WepShow=false,
        Tracers=false, TracerOrg="Bottom", TracerCol=C3(0,255,100),
        LookTr=false, LookLen=5, LookCol=WHITE,
        Arrows=false, ArrowCol=C3(255,85,0), ArrowR=120, ArrowSz=15,
        DmgNums=false, DmgCol=C3(255,255,0),
        -- Chams — full distance system
        Chams=false, ChamsVisCol=true,
        ChamsFill=WHITE, ChamsOut=WHITE, ChamsFT=0.5, ChamsOT=0,
        ChamsMaxDist=1000,   -- separate max distance for chams
        ChamsLOD=300,        -- beyond this, chams use static LOD colors
        ChamsLODFill=C3(255,100,0), ChamsLODOut=C3(255,100,0),
        -- Chams per-team
        ChamsTeam=false, ChamsTeamFill=C3(0,200,255), ChamsTeamOut=C3(0,200,255),
        MaxDist=1000,
        HUD=true, HUDStyle="Ascension", HUDScale=1.0,
        CustomName=false, NameCol=WHITE,
    },
    World = { On=false, Time=14, Bright=2, Shadows=false, Ambient=WHITE },
    Mov = { SpeedOn=false, Speed=16, JumpOn=false, Jump=50,
            InfJump=false, FOVOn=false, CamFOV=70, Noclip=false },
    Avoid = { On=false, Chance=0.1, Dur=0.2 },
    Perf = { Skip=true, MaxPF=20, LOD=500 },
}

-- ============================================================
--  STATE
-- ============================================================
local Conns={}, PList={}, TC={}, ESPObj={}, CC={}, TrLine={}, LkLine={}, HBOrig={}, OrigLit={}
local DmgPool={}, ADmg={}
-- raycast params (reused, zero alloc)
local RP=RaycastParams.new(); RP.FilterType=Enum.RaycastFilterType.Exclude; RP.IgnoreWater=true; local RF={nil,nil}
local TRP=RaycastParams.new(); TRP.FilterType=Enum.RaycastFilterType.Exclude; TRP.IgnoreWater=true; local TRF={nil,nil}; local TBChar=nil
local CandP={}
-- Chaos
local CHAOS_NAMES={"Head","UpperTorso","LowerTorso","Torso",
    "LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftHand","RightHand",
    "LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot",
    "Left Arm","Right Arm","Left Leg","Right Leg"}
local chaosT=0; local CHAOS_INT=0.22; local chaosName="Head"
local perT=0; local perOff=false
local tbT=0; local RSF=0; local STAG=3; local ncKC=Enum.KeyCode.N
local avgDT=0.016
local thHP=100; local thAlpha=0; local thName=""; local thData=""; local hudVis=false
local PI4=0.7853981634

-- ============================================================
--  LIGHTING CACHE
-- ============================================================
local function CacheL()
    OrigLit={T=Lit.ClockTime,B=Lit.Brightness,S=Lit.GlobalShadows,A=Lit.Ambient}
end; CacheL()
tIns(Conns,LP:GetPropertyChangedSignal("Team"):Connect(function() table.clear(TC) end))

-- ============================================================
--  DRAWING OBJECTS
-- ============================================================
local FOVR=ND("Circle"); FOVR.Thickness=1.5; FOVR.Filled=false
local FOVF=ND("Circle"); FOVF.Thickness=1;   FOVF.Filled=true

local CFolder=Instance.new("Folder"); CFolder.Name="KaimChams"
pcall(function() CFolder.Parent=SafeGui end)

local THUD={
    Sh=ND("Square"),BG=ND("Square"),Out=ND("Square"),
    Ac=ND("Square"),Ac2=ND("Square"),
    N=ND("Text"),D=ND("Text"),
    BBG=ND("Square"),BFG=ND("Square"),
}
THUD.Sh.Filled=true;  THUD.Sh.Color=BLACK
THUD.BG.Filled=true;  THUD.BG.Color=HUD_BG
THUD.Out.Filled=false
THUD.Ac.Filled=true;  THUD.Ac2.Filled=true
THUD.N.Outline=true;  THUD.N.Color=WHITE;        THUD.N.Font=2
THUD.D.Outline=true;  THUD.D.Color=C3(180,180,200); THUD.D.Font=2
THUD.BBG.Filled=true; THUD.BBG.Color=BAR_BG
THUD.BFG.Filled=true

-- ============================================================
--  DAMAGE NUMBERS
-- ============================================================
local function SpawnDmg(dmg,pos)
    local d; if #DmgPool>0 then d=tRem(DmgPool) else
        d={T=ND("Text"),s="",sp=V3(),v=V3(),t0=0}
        d.T.Center=true; d.T.Outline=true; d.T.OutlineColor=BLACK; d.T.Font=3
    end
    d.s=tostring(mFloor(dmg)); local a=mRand()*mPi*2; local sp=mRand(15,30)/10
    d.v=V3(mCos(a)*sp,mRand(35,55)/10,mSin(a)*sp)
    d.sp=pos+V3((mRand()-0.5),1,(mRand()-0.5)); d.t0=sClock()
    tIns(ADmg,d)
end

local function TickDmg(cam)
    if not S.ESP.DmgNums and #ADmg==0 then return end
    local now=sClock()
    for i=#ADmg,1,-1 do
        local d=ADmg[i]; local el=now-d.t0
        if el>=1.5 or not S.ESP.DmgNums then
            d.T.Visible=false; tIns(DmgPool,d); tRem(ADmg,i)
        else
            local vv=d.v
            local cp=d.sp+V3(vv.X*el,(vv.Y*el)-(12.5*el*el),vv.Z*el)
            local sp,on=cam:WorldToViewportPoint(cp)
            if on then
                local sz=el<0.15 and (14+18*(el/0.15)) or (el<0.35 and (32-12*((el-0.15)/0.2)) or 20)
                if d.T.Text~=d.s then d.T.Text=d.s end
                local p2=V2(sp.X,sp.Y)
                if d.T.Position~=p2 then d.T.Position=p2 end
                if d.T.Size~=sz then d.T.Size=sz end
                if d.T.Color~=S.ESP.DmgCol then d.T.Color=S.ESP.DmgCol end
                local al=el>1 and (1-(el-1)*2) or 1
                if d.T.Transparency~=al then d.T.Transparency=al end
                if not d.T.Visible then d.T.Visible=true end
            else if d.T.Visible then d.T.Visible=false end end
        end
    end
end

-- ============================================================
--  TEAM / CHAR CACHE
-- ============================================================
local function IsTeam(p)
    if TC[p]==nil then TC[p]=(p.Team~=nil and p.Team==LP.Team) end; return TC[p]
end

local function BuildCC(pl,char)
    if not char then CC[pl]=nil; return end
    task.spawn(function()
        local hrp=char:WaitForChild("HumanoidRootPart",5)
        local head=char:WaitForChild("Head",5)
        local hum=char:WaitForChild("Humanoid",5)
        if not char.Parent or pl.Character~=char then return end
        if hrp and head and hum then
            local c=CC[pl] or {}
            c.Char=char; c.HRP=hrp; c.Head=head; c.Hum=hum
            CC[pl]=c
        else CC[pl]=nil end
    end)
end

-- ============================================================
--  VISIBILITY
-- ============================================================
local function IsVis(part,char,cam)
    if not part or not char then return false end
    local ok,pos=pcall(function() return part.Position end); if not ok then return false end
    RF[1]=char; RF[2]=LP.Character; RP.FilterDescendantsInstances=RF
    return workspace:Raycast(cam, pos-cam, RP)==nil
end

-- ============================================================
--  AIM PART — chaos picks from existing parts each interval
-- ============================================================
local SMART_P={"Head","UpperTorso","Torso","HumanoidRootPart"}

local function GetAimPart(cd,mode,camP)
    local ch=cd.Char
    if mode=="Smart" then
        for _,n in ipairs(SMART_P) do
            local p=ch:FindFirstChild(n)
            if p and IsVis(p,ch,camP) then return p,true end
        end
        return cd.HRP,false
    elseif mode=="Chaos" then
        return ch:FindFirstChild(chaosName) or cd.HRP, true
    elseif mode=="Head" then return cd.Head,true
    elseif mode=="Torso" then
        return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"),true
    elseif mode=="Limbs" then
        local opts={}
        for _,n in ipairs({"LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
            "Left Arm","Right Arm","Left Leg","Right Leg"}) do
            local p=ch:FindFirstChild(n); if p then tIns(opts,p) end
        end
        return #opts>0 and opts[mRand(#opts)] or cd.HRP, true
    else return cd.HRP,true end
end

-- chaos re-picker: builds list from char's actual existing parts
local function PickChaos(char)
    if not char then return end
    local f={}
    for _,n in ipairs(CHAOS_NAMES) do
        local p=char:FindFirstChild(n)
        if p and p:IsA("BasePart") then tIns(f,p) end
    end
    if #f>0 then chaosName=f[mRand(#f)].Name end
end

-- ============================================================
--  TARGET SELECTION  (no allocations)
-- ============================================================
local function GetTarget(camP,fovP,cam)
    local fSq=S.FOV.Radius*S.FOV.Radius
    local myC=CC[LP]; local myP=myC and myC.HRP and myC.HRP.Position or camP
    local n=0
    for i=1,#PList do
        local pl=PList[i]; local cd=CC[pl]
        if not cd or not cd.Hum or cd.Hum.Health<=0 then continue end
        if S.Aim.TeamCheck and IsTeam(pl) then continue end
        local sp,on=cam:WorldToViewportPoint(cd.HRP.Position)
        if not on then continue end
        local dx,dy=fovP.X-sp.X, fovP.Y-sp.Y; local dmSq=dx*dx+dy*dy
        if dmSq>fSq then continue end
        local rx=myP.X-cd.HRP.Position.X; local ry=myP.Y-cd.HRP.Position.Y; local rz=myP.Z-cd.HRP.Position.Z
        n=n+1; if not CandP[n] then CandP[n]={} end
        local c=CandP[n]; c.pl=pl; c.cd=cd; c.dm=dmSq; c.dp=rx*rx+ry*ry+rz*rz
    end
    for i=n+1,#CandP do CandP[i]=nil end
    if n==0 then return nil end
    local byD=S.Aim.Priority=="Distance"
    for i=2,n do
        local k=CandP[i]; local j=i-1
        if byD then while j>0 and CandP[j].dp>k.dp do CandP[j+1]=CandP[j];j=j-1 end
        else        while j>0 and CandP[j].dm>k.dm do CandP[j+1]=CandP[j];j=j-1 end end
        CandP[j+1]=k
    end
    for i=1,mMin(n,3) do
        local c=CandP[i]
        if not S.Aim.WallCheck then return c.pl end
        local p,vis=GetAimPart(c.cd,S.Aim.Mode,camP)
        if p and vis then return c.pl end
    end
    return nil
end

-- ============================================================
--  ESP OBJECTS
-- ============================================================
local function MkESP(pl)
    local e={
        Box=ND("Square"),BoxOut=ND("Square"),BoxFill=ND("Square"),
        CL={}, AL={},
        N=ND("Text"),UN=ND("Text"),Di=ND("Text"),H=ND("Text"),W=ND("Text"),
        BBG=ND("Square"),BFG=ND("Square"),BOut=ND("Square"),
        Hl=nil, vis=false, _lv=false, _stag=mRand(0,3),
        _hp=100, _font=-1, _tc="", _di=-1, _hi=-1, _ws="\0", _ns="\0", _us="\0",
    }
    e.Box.Thickness=1.5; e.BoxOut.Thickness=3.5; e.BoxFill.Thickness=1
    e.Box.Filled=false; e.BoxOut.Filled=false; e.BoxFill.Filled=true
    e.BoxOut.Transparency=0.7; e.BoxOut.Color=BLACK
    for i=1,8 do
        e.CL[i]={M=ND("Line"),O=ND("Line")}
        e.CL[i].M.Thickness=1.5
        e.CL[i].O.Thickness=3.5; e.CL[i].O.Color=BLACK; e.CL[i].O.Transparency=0.7
    end
    for i=1,4 do e.AL[i]=ND("Line") end
    for _,t in ipairs({e.N,e.UN,e.Di,e.H,e.W}) do
        t.Center=true; t.Outline=true; t.OutlineColor=BLACK
    end
    e.BBG.Filled=true; e.BBG.Color=C3(15,15,15)
    e.BFG.Filled=true
    e.BOut.Filled=false; e.BOut.Color=BLACK; e.BOut.Thickness=1
    ESPObj[pl]=e
end

local function HideE(e)
    if not e._lv then return end
    e.Box.Visible=false; e.BoxOut.Visible=false; e.BoxFill.Visible=false
    for i=1,8 do e.CL[i].M.Visible=false; e.CL[i].O.Visible=false end
    e.N.Visible=false; e.UN.Visible=false; e.Di.Visible=false
    e.H.Visible=false; e.W.Visible=false
    e.BBG.Visible=false; e.BFG.Visible=false; e.BOut.Visible=false
    for i=1,4 do e.AL[i].Visible=false end
    if e.Hl and e.Hl.Enabled then e.Hl.Enabled=false end
    e._lv=false
end

local function DelE(e)
    pcall(function()
        e.Box:Remove(); e.BoxOut:Remove(); e.BoxFill:Remove()
        for i=1,8 do e.CL[i].M:Remove(); e.CL[i].O:Remove() end
        e.N:Remove(); e.UN:Remove(); e.Di:Remove(); e.H:Remove(); e.W:Remove()
        e.BBG:Remove(); e.BFG:Remove(); e.BOut:Remove()
        for i=1,4 do e.AL[i]:Remove() end
        if e.Hl then e.Hl:Destroy() end
    end)
end

-- ============================================================
--  PLAYER REG
-- ============================================================
local function RegPl(pl)
    if pl==LP then return end
    tIns(PList,pl); MkESP(pl)
    tIns(Conns,pl:GetPropertyChangedSignal("Team"):Connect(function() TC[pl]=nil end))
    tIns(Conns,pl.CharacterAdded:Connect(function(c) BuildCC(pl,c) end))
    tIns(Conns,pl.CharacterRemoving:Connect(function() CC[pl]=nil; HBOrig[pl]=nil end))
    if pl.Character then BuildCC(pl,pl.Character) end
end

task.spawn(function()
    for _,p in ipairs(Plr:GetPlayers()) do
        if p~=LP then RegPl(p); task.wait() end
    end
end)
tIns(Conns,Plr.PlayerAdded:Connect(RegPl))
tIns(Conns,Plr.PlayerRemoving:Connect(function(pl)
    for i=1,#PList do if PList[i]==pl then tRem(PList,i); break end end
    local e=ESPObj[pl]; if e then task.defer(function() DelE(e) end) end
    ESPObj[pl]=nil; CC[pl]=nil; TC[pl]=nil; HBOrig[pl]=nil
    if TrLine[pl] then TrLine[pl]:Remove(); TrLine[pl]=nil end
    if LkLine[pl] then LkLine[pl]:Remove(); LkLine[pl]=nil end
end))
tIns(Conns,LP.CharacterAdded:Connect(function(c)
    BuildCC(LP,c)
    if S.Mov.Noclip then task.defer(function() if _G._KaimNC then _G._KaimNC(c) end end) end
end))
if LP.Character then BuildCC(LP,LP.Character) end

-- ============================================================
--  FOV
-- ============================================================
local function TickFOV(ctr)
    local pos=S.FOV.Follow and UIS:GetMouseLocation() or ctr
    local r=mMax(1, S.FOV.Radius+(S.FOV.Pulse and mSin(sClock()*4)*5 or 0))
    if FOVR.Visible~=S.FOV.Show then FOVR.Visible=S.FOV.Show end
    if FOVR.Position~=pos  then FOVR.Position=pos end
    if FOVR.Radius~=r      then FOVR.Radius=r    end
    if FOVR.Color~=S.FOV.Color  then FOVR.Color=S.FOV.Color end
    if FOVR.Transparency~=S.FOV.Trans then FOVR.Transparency=S.FOV.Trans end
    if FOVR.Thickness~=S.FOV.Thick    then FOVR.Thickness=S.FOV.Thick   end
    local fv=S.FOV.Show and S.FOV.Filled
    if FOVF.Visible~=fv   then FOVF.Visible=fv  end
    if fv then
        if FOVF.Position~=pos then FOVF.Position=pos end
        if FOVF.Radius~=r     then FOVF.Radius=r     end
        if FOVF.Color~=S.FOV.FC  then FOVF.Color=S.FOV.FC end
        if FOVF.Transparency~=S.FOV.FT then FOVF.Transparency=S.FOV.FT end
    end
    return pos
end

-- ============================================================
--  HUD HIDE
-- ============================================================
local function HideTHUD()
    if not hudVis then return end
    for _,v in pairs(THUD) do v.Visible=false end
    hudVis=false
end

-- ============================================================
--  AIMLOCK TICK
-- ============================================================
local function TickAim(camP,sw,sh,dt,fovP,cam)
    -- Periodic disable
    if S.Avoid.On and S.Aim.On then
        perT=perT-dt
        if perT<=0 then
            perOff=(mRand()<S.Avoid.Chance)
            perT=S.Avoid.Dur+mRand()*0.4
        end
    else perOff=false end

    -- Chaos re-pick
    if S.Aim.Mode=="Chaos" and S.Aim.IsAiming then
        chaosT=chaosT-dt
        if chaosT<=0 then
            chaosT=CHAOS_INT
            local tc=S.Aim.Target and CC[S.Aim.Target]
            if tc and tc.Char then PickChaos(tc.Char) end
        end
    end

    local showHUD=false

    if S.Aim.On and S.Aim.IsAiming and not perOff then
        if mRand(1,100)>S.Aim.HitChance then
            S.Aim.Target=nil
        else
            local tc=S.Aim.Target and CC[S.Aim.Target]
            if not tc or not tc.Hum or tc.Hum.Health<=0 then
                local now=sClock()
                if now-S.Aim._lastSearch>0.05 then
                    S.Aim.Target=GetTarget(camP,fovP,cam)
                    S.Aim._lastSearch=now
                end
            end
        end

        local tar=S.Aim.Target; local cd=tar and CC[tar]
        if cd then
            local part,lockVis=GetAimPart(cd,S.Aim.Mode,camP)
            if part then
                local ap=part.Position
                -- Clean single-order velocity prediction
                if S.Aim.Pred then
                    local vel=part.AssemblyLinearVelocity
                    if vel.Magnitude>300 then vel=vel.Unit*300 end
                    ap=ap+vel*S.Aim.PredStr
                end
                ap=ap+V3(S.Aim.OffX,S.Aim.OffY,S.Aim.OffZ)
                if S.Aim.Noise then
                    local tk=sClock()*S.Aim.NoiseSpd
                    ap=ap+V3(mNoise(tk,0,0)*S.Aim.NoiseAmt,
                              mNoise(0,tk,0)*S.Aim.NoiseAmt,
                              mNoise(0,0,tk)*S.Aim.NoiseAmt)
                end
                local tCF=CF(camP,ap)
                if S.Aim.Smooth then
                    -- Exponential decay smooth — feels natural, no overshoot
                    local sf=mClamp(1-mExp(-S.Aim.SmoothSpd*22*dt),0.01,1)
                    cam.CFrame=cam.CFrame:Lerp(tCF,sf)
                else cam.CFrame=tCF end

                -- HUD
                if S.ESP.HUD then
                    showHUD=true
                    local sc=S.ESP.HUDScale; local st=S.ESP.HUDStyle
                    local ac=lockVis and WHITE or RED
                    local aHP=cd.Hum.Health or 0
                    thHP=thHP+(aHP-thHP)*(dt*10)
                    if thHP~=thHP or thHP<0 then thHP=0 end
                    local hpPct=mClamp(thHP/mMax(1,cd.Hum.MaxHealth or 100),0,1)
                    local di=0; local mc=CC[LP]
                    if mc and mc.HRP then di=mFloor((mc.HRP.Position-cd.HRP.Position).Magnitude) end
                    local rN=tar.DisplayName
                    local rD="HP: "..mFloor(aHP).."  |  "..di.."m"
                    if S.Aim.Mode=="Chaos" then rD=rD.."  |  "..chaosName end
                    if thName~=rN then thName=rN; THUD.N.Text=Fmt(rN,S.ESP.TCase) end
                    if thData~=rD then thData=rD; THUD.D.Text=rD end
                    thAlpha=mClamp(thAlpha+dt*7,0,1)
                    local ea=1-mExp(-thAlpha*5); local ys=(1-ea)*35
                    for _,v in pairs(THUD) do v.Visible=false end
                    THUD.N.Outline=true; THUD.N.Center=false
                    THUD.D.Outline=true; THUD.D.Center=false

                    if st=="Ascension" then
                        local bw=mFloor(260*sc); local bh=mFloor(50*sc)
                        local hx=(sw/2)-(bw/2); local hy=mFloor(sh*0.12)-ys
                        THUD.Sh.Visible=true; THUD.Sh.Size=V2(bw+6,bh+6); THUD.Sh.Position=V2(hx-3,hy-3); THUD.Sh.Transparency=0.3*ea; THUD.Sh.Color=ac
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.9*ea; THUD.BG.Color=C3(5,5,10)
                        THUD.Out.Visible=true; THUD.Out.Size=V2(bw,bh); THUD.Out.Position=V2(hx,hy); THUD.Out.Color=ac; THUD.Out.Transparency=0.7*ea
                        THUD.Ac.Visible=true; THUD.Ac.Size=V2(mMax(1,mFloor(3*sc)),bh); THUD.Ac.Position=V2(hx,hy); THUD.Ac.Color=ac; THUD.Ac.Transparency=ea
                        THUD.N.Visible=true; THUD.N.Size=mMax(10,mFloor(18*sc)); THUD.N.Position=V2(hx+mFloor(15*sc),hy+mFloor(6*sc)); THUD.N.Transparency=ea
                        THUD.D.Visible=true; THUD.D.Size=mMax(10,mFloor(11*sc)); THUD.D.Position=V2(hx+mFloor(15*sc),hy+mFloor(26*sc)); THUD.D.Transparency=0.8*ea
                        THUD.BBG.Visible=true; THUD.BBG.Size=V2(bw-mFloor(30*sc),mMax(1,mFloor(2*sc))); THUD.BBG.Position=V2(hx+mFloor(15*sc),hy+bh-mFloor(8*sc)); THUD.BBG.Transparency=0.5*ea; THUD.BBG.Color=BLACK
                        THUD.BFG.Visible=true; THUD.BFG.Size=V2((bw-mFloor(30*sc))*hpPct,mMax(1,mFloor(2*sc))); THUD.BFG.Position=V2(hx+mFloor(15*sc),hy+bh-mFloor(8*sc)); THUD.BFG.Color=HPC(hpPct); THUD.BFG.Transparency=ea
                    elseif st=="Valorant" then
                        local bw=mFloor(280*sc); local bh=mFloor(45*sc)
                        local hx=(sw/2)-(bw/2); local hy=mFloor(sh*0.08)-ys
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.85*ea; THUD.BG.Color=HUD_VAL
                        THUD.Ac.Visible=true; THUD.Ac.Size=V2(bw,mMax(1,mFloor(2*sc))); THUD.Ac.Position=V2(hx,hy+bh); THUD.Ac.Color=ac; THUD.Ac.Transparency=ea
                        THUD.N.Visible=true; THUD.N.Size=mMax(10,mFloor(17*sc)); THUD.N.Position=V2(hx+mFloor(12*sc),hy+mFloor(6*sc)); THUD.N.Transparency=ea
                        THUD.D.Visible=true; THUD.D.Size=mMax(10,mFloor(12*sc)); THUD.D.Position=V2(hx+mFloor(12*sc),hy+mFloor(24*sc)); THUD.D.Transparency=ea
                        THUD.BBG.Visible=true; THUD.BBG.Size=V2(bw,mMax(1,mFloor(3*sc))); THUD.BBG.Position=V2(hx,hy+bh+mFloor(2*sc)); THUD.BBG.Transparency=ea; THUD.BBG.Color=BLACK
                        THUD.BFG.Visible=true; THUD.BFG.Size=V2(bw*hpPct,mMax(1,mFloor(3*sc))); THUD.BFG.Position=V2(hx,hy+bh+mFloor(2*sc)); THUD.BFG.Color=HPC(hpPct); THUD.BFG.Transparency=ea
                    elseif st=="Standard" then
                        local bw=mFloor(mMax(200,40+#thName*9)*sc); local bh=mFloor(56*sc)
                        local hx=(sw/2)-(bw/2); local hy=(sh-mFloor(140*sc))+ys
                        THUD.Sh.Visible=true; THUD.Sh.Size=V2(bw,bh); THUD.Sh.Position=V2(hx+3,hy+3); THUD.Sh.Transparency=0.5*ea; THUD.Sh.Color=BLACK
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.85*ea; THUD.BG.Color=HUD_BG
                        THUD.Out.Visible=true; THUD.Out.Size=V2(bw+2,bh+2); THUD.Out.Position=V2(hx-1,hy-1); THUD.Out.Transparency=ea
                        THUD.Ac.Visible=true; THUD.Ac.Size=V2(bw,mMax(1,mFloor(2*sc))); THUD.Ac.Position=V2(hx,hy); THUD.Ac.Color=ac; THUD.Ac.Transparency=ea
                        THUD.N.Visible=true; THUD.N.Size=mMax(10,mFloor(16*sc)); THUD.N.Position=V2(hx+mFloor(10*sc),hy+mFloor(8*sc)); THUD.N.Transparency=ea
                        THUD.D.Visible=true; THUD.D.Size=mMax(10,mFloor(13*sc)); THUD.D.Position=V2(hx+mFloor(10*sc),hy+mFloor(28*sc)); THUD.D.Transparency=ea
                        THUD.BBG.Visible=true; THUD.BBG.Size=V2(bw-mFloor(20*sc),mMax(1,mFloor(3*sc))); THUD.BBG.Position=V2(hx+mFloor(10*sc),hy+mFloor(46*sc)); THUD.BBG.Transparency=ea
                        THUD.BFG.Visible=true; THUD.BFG.Size=V2((bw-mFloor(20*sc))*hpPct,mMax(1,mFloor(3*sc))); THUD.BFG.Position=V2(hx+mFloor(10*sc),hy+mFloor(46*sc)); THUD.BFG.Color=HPC(hpPct); THUD.BFG.Transparency=ea
                    elseif st=="Minimal" then
                        local hx=(sw/2)-mFloor(100*sc); local hy=(sh-mFloor(130*sc))+ys
                        THUD.Ac.Visible=true; THUD.Ac.Size=V2(mMax(1,mFloor(3*sc)),mFloor(36*sc)); THUD.Ac.Position=V2(hx,hy); THUD.Ac.Color=ac; THUD.Ac.Transparency=ea
                        THUD.N.Visible=true; THUD.N.Size=mMax(10,mFloor(16*sc)); THUD.N.Position=V2(hx+mFloor(10*sc),hy); THUD.N.Transparency=ea
                        THUD.D.Visible=true; THUD.D.Size=mMax(10,mFloor(13*sc)); THUD.D.Position=V2(hx+mFloor(10*sc),hy+mFloor(20*sc)); THUD.D.Transparency=ea
                    elseif st=="Apex" then
                        local bw=mFloor(220*sc); local bh=mFloor(45*sc)
                        local hx=(sw/2)-(bw/2); local hy=(sh-mFloor(120*sc))+ys
                        THUD.BG.Visible=true; THUD.BG.Size=V2(bw,bh); THUD.BG.Position=V2(hx,hy); THUD.BG.Transparency=0.6*ea; THUD.BG.Color=HUD_BG
                        THUD.Ac.Visible=true; THUD.Ac.Size=V2(mMax(1,mFloor(4*sc)),bh); THUD.Ac.Position=V2(hx,hy); THUD.Ac.Color=ac; THUD.Ac.Transparency=ea
                        THUD.N.Visible=true; THUD.N.Size=mMax(10,mFloor(15*sc)); THUD.N.Position=V2(hx+mFloor(12*sc),hy+mFloor(6*sc)); THUD.N.Transparency=ea
                        THUD.D.Visible=true; THUD.D.Size=mMax(10,mFloor(11*sc)); THUD.D.Position=V2(hx+mFloor(12*sc),hy+mFloor(24*sc)); THUD.D.Transparency=ea
                        THUD.BBG.Visible=true; THUD.BBG.Size=V2(bw,mMax(1,mFloor(3*sc))); THUD.BBG.Position=V2(hx,hy+bh); THUD.BBG.Transparency=ea
                        THUD.BFG.Visible=true; THUD.BFG.Size=V2(bw*hpPct,mMax(1,mFloor(3*sc))); THUD.BFG.Position=V2(hx,hy+bh); THUD.BFG.Color=HPC(hpPct); THUD.BFG.Transparency=ea
                    end
                    hudVis=true
                end
            else S.Aim.Target=nil end
        end
    else S.Aim.Target=nil end

    if not showHUD then
        thAlpha=mClamp(thAlpha-dt*8,0,1)
        if thAlpha<=0 then HideTHUD()
        else
            local ea=1-mExp(-thAlpha*5)
            for _,v in pairs(THUD) do
                if v.Visible then v.Transparency=(v.Transparency or 1)*ea/(v.Transparency or 1)*ea end
            end
            -- simply fade all visible elements
            if THUD.Sh.Visible  then THUD.Sh.Transparency=0.5*ea   end
            if THUD.BG.Visible  then THUD.BG.Transparency=0.85*ea  end
            if THUD.Out.Visible then THUD.Out.Transparency=ea       end
            if THUD.Ac.Visible  then THUD.Ac.Transparency=ea        end
            if THUD.N.Visible   then THUD.N.Transparency=ea         end
            if THUD.D.Visible   then THUD.D.Transparency=ea         end
            if THUD.BBG.Visible then THUD.BBG.Transparency=ea       end
            if THUD.BFG.Visible then THUD.BFG.Transparency=ea       end
        end
    end
end

-- ============================================================
--  CORNER BOX
-- ============================================================
local function DrawCorner(e,x,y,w,h,col,outline,thick)
    local L=mFloor(w/3); local cl=e.CL
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
--  ESP TICK
--  Key perf changes vs old version:
--  • Single WorldToViewportPoint per player (was 4+)
--    Box H/W computed from depth using a fixed stud constant and
--    the camera's perspective FOV factor — zero extra VP calls
--  • Visibility raycast staggered across STAG frames
--  • Hard early-out before any draw if not onScreen
--  • All property writes guarded by ~= check
--  • Full chams distance system: MaxDist, LOD zone, team color
-- ============================================================
-- perspective scale: at depth d, 1 stud = (viewH/2) / (d * tan(fovY/2)) pixels
-- we cache tan(fovY/2) each frame — only recomputed on FOV change
local _camTan = 0.57 -- tan(35°) ≈ default 70° vFOV / 2
local _lastCamFOV = 0

local CHAR_H = 2.9  -- half-height studs (HRP centre to top/bottom)
local CHAR_W = 1.0  -- half-width studs

local function TickESP(camP,sw,sh,cam)
    local esp=S.ESP; local perf=S.Perf
    -- Update perspective tan if FOV changed
    local cfov=cam.FieldOfView
    if cfov~=_lastCamFOV then
        _lastCamFOV=cfov; _camTan=math.tan(math.rad(cfov*0.5))
    end
    local halfH=sh*0.5

    local maxD2=esp.MaxDist*esp.MaxDist
    local lodD2=perf.LOD*perf.LOD
    local chmMaxD2=esp.ChamsMaxDist*esp.ChamsMaxDist
    local chmLodD2=esp.ChamsLOD*esp.ChamsLOD
    local center=V2(sw*0.5,sh*0.5)
    local tY=sh; if esp.TracerOrg=="Top" then tY=0 elseif esp.TracerOrg=="Center" then tY=sh*0.5 end
    local tStart=V2(sw*0.5,tY)

    local proc=0
    for i=1,#PList do
        -- Frame budget: if over limit and frame time high, stop updating draws
        -- (last-drawn state persists, no flicker)
        if perf.Skip and proc>=perf.MaxPF and avgDT>0.02 then break end

        local pl=PList[i]; local e=ESPObj[pl]; if not e then continue end
        local cd=CC[pl]

        -- Fast validity check without pcall (only pcall on HRP.Parent once)
        if not cd or not cd.HRP or not cd.Hum or cd.Hum.Health<=0 then
            HideE(e)
            if TrLine[pl] and TrLine[pl].Visible then TrLine[pl].Visible=false end
            if LkLine[pl] and LkLine[pl].Visible then LkLine[pl].Visible=false end
            continue
        end
        -- Guard destroyed HRP (pcall only if HRP exists)
        local prOk,prP=pcall(function() return cd.HRP.Parent end)
        if not prOk or not prP then HideE(e); continue end

        local isTM=IsTeam(pl)
        if esp.TeamCheck and isTM and not esp.ShowTeam then HideE(e); continue end

        proc=proc+1

        local myC=CC[LP]; local myP=(myC and myC.HRP) and myC.HRP.Position or camP
        local hp=cd.HRP.Position
        local dx=hp.X-myP.X; local dy=hp.Y-myP.Y; local dz=hp.Z-myP.Z
        local d2=dx*dx+dy*dy+dz*dz
        if d2>maxD2 then HideE(e); continue end
        local dist=mSqrt(d2)
        local isLOD=d2>lodD2

        -- === SINGLE WorldToViewportPoint ===
        local rsp,onSc=cam:WorldToViewportPoint(hp)
        local depth=rsp.Z
        if depth<=0 then HideE(e); continue end

        -- Staggered visibility raycast
        if not isLOD and onSc and esp.VisColors then
            if e._stag==(RSF%STAG) then
                e.vis=IsVis(cd.HRP,cd.Char,camP)
            end
        else e.vis=true end

        -- ESP color
        local col
        if isTM and esp.ShowTeam then col=esp.TeamCol
        elseif esp.VisColors then col=e.vis and esp.VisCol or esp.HideCol
        else col=esp.StatCol end

        -- --------------------------------------------------------
        --  CHAMS — full distance system
        --  Zones: beyond ChamsMaxDist = off, beyond ChamsLOD = LOD
        --  color, within ChamsLOD = full vis/hidden color
        -- --------------------------------------------------------
        if esp.Chams and d2<=chmMaxD2 then
            if not e.Hl then
                e.Hl=Instance.new("Highlight"); e.Hl.Parent=CFolder
            end
            if e.Hl.Adornee~=cd.Char then e.Hl.Adornee=cd.Char; e.Hl.Enabled=true end

            local cFill, cOut
            if isTM and esp.ChamsTeam then
                cFill=esp.ChamsTeamFill; cOut=esp.ChamsTeamOut
            elseif d2>chmLodD2 then
                -- LOD zone: use the dedicated LOD colors (distance-faded solid color)
                local lp=mClamp(1-(d2-chmLodD2)/(chmMaxD2-chmLodD2+1),0,1)
                cFill=esp.ChamsLODFill; cOut=esp.ChamsLODOut
                -- Optional: lerp LOD color toward hidden/vis based on raycast
                if esp.ChamsVisCol and not isLOD then
                    local vc=e.vis and esp.VisCol or esp.HideCol
                    cFill=esp.ChamsLODFill:Lerp(vc,0.3*lp)
                    cOut=esp.ChamsLODOut:Lerp(vc,0.3*lp)
                end
            elseif esp.ChamsVisCol then
                cFill=e.vis and esp.VisCol or esp.HideCol
                cOut=e.vis and esp.VisCol or esp.HideCol
            else
                cFill=esp.ChamsFill; cOut=esp.ChamsOut
            end

            if e.Hl.FillColor~=cFill              then e.Hl.FillColor=cFill              end
            if e.Hl.OutlineColor~=cOut             then e.Hl.OutlineColor=cOut            end
            if e.Hl.FillTransparency~=esp.ChamsFT  then e.Hl.FillTransparency=esp.ChamsFT end
            if e.Hl.OutlineTransparency~=esp.ChamsOT then e.Hl.OutlineTransparency=esp.ChamsOT end
            if not e.Hl.Enabled then e.Hl.Enabled=true end
        else
            if e.Hl and e.Hl.Enabled then e.Hl.Enabled=false; e.Hl.Adornee=nil end
        end

        -- Damage tracking
        if not isLOD and cd.Hum.Health~=e._hp then
            local diff=e._hp-cd.Hum.Health
            if diff>0.5 and esp.DmgNums then SpawnDmg(diff,cd.Head.Position) end
            e._hp=cd.Hum.Health
        end

        -- Off-screen arrows
        if esp.Arrows and not isLOD and (not onSc or depth<=0) then
            local rel=cam.CFrame:PointToObjectSpace(hp)
            local ang=mAtan2(rel.X,-rel.Z)
            local sa=mSin(ang); local ca=mCos(ang)
            local ar=esp.ArrowR; local as=esp.ArrowSz
            local ac2=center+V2(sa*ar,-ca*ar)
            local p1=ac2+V2(sa*as,-ca*as)
            local p2=ac2+V2(mSin(ang-PI4)*as*0.75,-mCos(ang-PI4)*as*0.75)
            local p3=ac2+V2(sa*as*0.3,-ca*as*0.3)
            local p4=ac2+V2(mSin(ang+PI4)*as*0.75,-mCos(ang+PI4)*as*0.75)
            e.AL[1].From=p1;e.AL[1].To=p2;e.AL[1].Color=esp.ArrowCol;e.AL[1].Visible=true
            e.AL[2].From=p2;e.AL[2].To=p3;e.AL[2].Color=esp.ArrowCol;e.AL[2].Visible=true
            e.AL[3].From=p3;e.AL[3].To=p4;e.AL[3].Color=esp.ArrowCol;e.AL[3].Visible=true
            e.AL[4].From=p4;e.AL[4].To=p1;e.AL[4].Color=esp.ArrowCol;e.AL[4].Visible=true
        else if e.AL[1].Visible then for j=1,4 do e.AL[j].Visible=false end end end

        -- Tracers
        if esp.Tracers and not isLOD then
            if not TrLine[pl] then TrLine[pl]=ND("Line"); TrLine[pl].Thickness=1.5 end
            local tl=TrLine[pl]
            if tl.Color~=esp.TracerCol then tl.Color=esp.TracerCol end
            if tl.From~=tStart then tl.From=tStart end
            local tp=V2(rsp.X,rsp.Y); if tl.To~=tp then tl.To=tp end
            if tl.Visible~=onSc then tl.Visible=onSc end
        elseif TrLine[pl] and TrLine[pl].Visible then TrLine[pl].Visible=false end

        -- Look tracers
        if esp.LookTr and not isLOD then
            if not LkLine[pl] then LkLine[pl]=ND("Line"); LkLine[pl].Thickness=1.5 end
            local lk3=cd.Head.Position+(cd.Head.CFrame.LookVector*esp.LookLen)
            local hs=cam:WorldToViewportPoint(cd.Head.Position)
            local ls,lon=cam:WorldToViewportPoint(lk3)
            local lv=lon and onSc
            if LkLine[pl].Visible~=lv then LkLine[pl].Visible=lv end
            if lv then
                local f2=V2(hs.X,hs.Y); local t2=V2(ls.X,ls.Y)
                if LkLine[pl].From~=f2 then LkLine[pl].From=f2 end
                if LkLine[pl].To~=t2   then LkLine[pl].To=t2   end
                if LkLine[pl].Color~=esp.LookCol then LkLine[pl].Color=esp.LookCol end
            end
        elseif LkLine[pl] and LkLine[pl].Visible then LkLine[pl].Visible=false end

        if not esp.On or not onSc then HideE(e); continue end
        e._lv=true

        -- --------------------------------------------------------
        --  BOX  — perspective projection, no extra VP calls
        --  pixPerStud = (halfH / (depth * _camTan))
        --  bh = CHAR_H*2 * pixPerStud
        --  bw = CHAR_W*2 * pixPerStud
        -- --------------------------------------------------------
        local pps = halfH / (depth * _camTan)
        local bh  = mMax(4, CHAR_H * 2 * pps)
        local bw  = mMax(2, CHAR_W * 2 * pps)
        local bx  = rsp.X - bw * 0.5
        local by  = rsp.Y - bh * 0.5   -- rsp is already at HRP centre

        if esp.Boxes then
            if esp.BoxStyle=="Standard" then
                if e.Box.Visible~=true   then e.Box.Visible=true   end
                if e.Box.Color~=col      then e.Box.Color=col       end
                if e.Box.Size~=V2(bw,bh) then e.Box.Size=V2(bw,bh) end
                if e.Box.Position~=V2(bx,by) then e.Box.Position=V2(bx,by) end
                if esp.Outline then
                    if not e.BoxOut.Visible then e.BoxOut.Visible=true end
                    e.BoxOut.Size=V2(bw+3,bh+3); e.BoxOut.Position=V2(bx-1.5,by-1.5)
                else if e.BoxOut.Visible then e.BoxOut.Visible=false end end
                for j=1,8 do
                    if e.CL[j].M.Visible then e.CL[j].M.Visible=false end
                    if e.CL[j].O.Visible then e.CL[j].O.Visible=false end
                end
            else
                if e.Box.Visible    then e.Box.Visible=false    end
                if e.BoxOut.Visible then e.BoxOut.Visible=false  end
                DrawCorner(e,bx,by,bw,bh,col,esp.Outline,1.5)
            end
            if esp.BoxFill then
                if not e.BoxFill.Visible then e.BoxFill.Visible=true end
                e.BoxFill.Color=col; e.BoxFill.Transparency=esp.BoxFillT
                e.BoxFill.Size=V2(bw,bh); e.BoxFill.Position=V2(bx,by)
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

        -- Health bar (left side of box, 4px wide)
        if esp.HBar then
            local fh=mMax(1,bh*hpPct)
            if not e.BBG.Visible  then e.BBG.Visible=true  end
            if not e.BFG.Visible  then e.BFG.Visible=true  end
            if not e.BOut.Visible then e.BOut.Visible=true  end
            e.BBG.Size=V2(4,bh+2);   e.BBG.Position=V2(bx-7,by-1)
            e.BOut.Size=V2(6,bh+4);  e.BOut.Position=V2(bx-8,by-2)
            e.BFG.Size=V2(2,fh);     e.BFG.Position=V2(bx-6,by+bh-fh); e.BFG.Color=HPC(hpPct)
        else
            if e.BBG.Visible  then e.BBG.Visible=false  end
            if e.BFG.Visible  then e.BFG.Visible=false  end
            if e.BOut.Visible then e.BOut.Visible=false  end
        end

        -- Font cache
        if e._font~=esp.Font then
            e._font=esp.Font
            for _,t in ipairs({e.N,e.UN,e.Di,e.H,e.W}) do t.Font=esp.Font end
        end

        -- Invalidate string caches on TextCase change
        if e._tc~=esp.TCase then
            e._tc=esp.TCase; e._di=-1; e._hi=-1; e._ws="\0"; e._ns="\0"; e._us="\0"
        end

        local ty=by - esp.TSize - 4
        local by2=by + bh + 4
        local nCol=esp.CustomName and esp.NameCol or col

        -- Names
        if esp.Names then
            if esp.NStyle=="Display Name" or esp.NStyle=="Both" then
                local dn=pl.DisplayName
                if e._ns~=dn then e._ns=dn; e.N.Text=Fmt(dn,esp.TCase) end
                if not e.N.Visible then e.N.Visible=true end
                if e.N.Position~=V2(rsp.X,ty) then e.N.Position=V2(rsp.X,ty) end
                if e.N.Color~=nCol    then e.N.Color=nCol   end
                if e.N.Size~=esp.TSize then e.N.Size=esp.TSize end
                if esp.NStyle=="Both" then ty=ty-(esp.TSize-2) end
            else if e.N.Visible then e.N.Visible=false end end
            if esp.NStyle=="Username" or esp.NStyle=="Both" then
                local un="@"..pl.Name
                if e._us~=un then e._us=un; e.UN.Text=Fmt(un,esp.TCase) end
                if not e.UN.Visible then e.UN.Visible=true end
                if e.UN.Position~=V2(rsp.X,ty) then e.UN.Position=V2(rsp.X,ty) end
                local uc=esp.CustomName and C3(180,180,200) or col
                if e.UN.Color~=uc then e.UN.Color=uc end
                if e.UN.Size~=mMax(10,esp.TSize-2) then e.UN.Size=mMax(10,esp.TSize-2) end
            else if e.UN.Visible then e.UN.Visible=false end end
        else
            if e.N.Visible  then e.N.Visible=false  end
            if e.UN.Visible then e.UN.Visible=false end
        end

        if esp.DistShow then
            local di=mFloor(dist)
            if e._di~=di then e._di=di; e.Di.Text=Fmt(di.."m",esp.TCase); e.Di.Color=DC(di,esp.MaxDist) end
            if not e.Di.Visible then e.Di.Visible=true end
            if e.Di.Position~=V2(rsp.X,by2) then e.Di.Position=V2(rsp.X,by2) end
            if e.Di.Size~=mMax(10,esp.TSize-2) then e.Di.Size=mMax(10,esp.TSize-2) end
            by2=by2+mMax(10,esp.TSize-2)+2
        else if e.Di.Visible then e.Di.Visible=false end end

        if esp.HNums then
            local hi=mFloor(cd.Hum.Health)
            if e._hi~=hi then e._hi=hi; e.H.Text=Fmt(hi.." HP",esp.TCase) end
            if not e.H.Visible then e.H.Visible=true end
            if e.H.Color~=HPC(hpPct) then e.H.Color=HPC(hpPct) end
            if e.H.Position~=V2(rsp.X,by2) then e.H.Position=V2(rsp.X,by2) end
            if e.H.Size~=mMax(10,esp.TSize-2) then e.H.Size=mMax(10,esp.TSize-2) end
            by2=by2+mMax(10,esp.TSize-2)+2
        else if e.H.Visible then e.H.Visible=false end end

        if esp.WepShow and not isLOD then
            local tool=cd.Char:FindFirstChildOfClass("Tool")
            local ws=tool and tool.Name or "None"
            if e._ws~=ws then e._ws=ws; e.W.Text=Fmt(ws,esp.TCase) end
            if not e.W.Visible then e.W.Visible=true end
            if e.W.Color~=C3(220,220,220) then e.W.Color=C3(220,220,220) end
            if e.W.Position~=V2(rsp.X,by2) then e.W.Position=V2(rsp.X,by2) end
            if e.W.Size~=mMax(10,esp.TSize-2) then e.W.Size=mMax(10,esp.TSize-2) end
        else if e.W.Visible then e.W.Visible=false end end
    end
end

-- ============================================================
--  HEARTBEAT
-- ============================================================
local function TickHB(dt)
    STAG=mClamp(mFloor(#PList/6),3,15)

    -- Triggerbot
    if S.TB.On and VI then
        tbT=tbT-dt
        if tbT<=0 and mRand(1,100)<=S.TB.HC then
            local cam=workspace.CurrentCamera
            if cam then
                local cx,cy=cam.ViewportSize.X*0.5,cam.ViewportSize.Y*0.5
                local oP,dir
                if S.FOV.Follow then
                    local mp=UIS:GetMouseLocation(); cx=mp.X; cy=mp.Y
                    local ur=cam:ViewportPointToRay(cx,cy); oP=ur.Origin; dir=ur.Direction*1000
                else oP=cam.CFrame.Position; dir=cam.CFrame.LookVector*1000 end
                local lc=LP.Character
                if TBChar~=lc then TRF[1]=cam; TRF[2]=lc; TRP.FilterDescendantsInstances=TRF; TBChar=lc end
                local res=S.TB.Sphere and workspace:Spherecast(oP,S.TB.Thick,dir,TRP)
                              or workspace:Raycast(oP,dir,TRP)
                if res and res.Instance then
                    local mdl=res.Instance:FindFirstAncestorOfClass("Model")
                    if mdl and mdl:FindFirstChild("Humanoid") then
                        local tp=Plr:GetPlayerFromCharacter(mdl)
                        if tp and tp~=LP and not (S.TB.Team and IsTeam(tp)) then
                            task.spawn(function() pcall(function()
                                VI:SendMouseButtonEvent(cx,cy,0,true,game,1)
                                task.wait(0.01)
                                VI:SendMouseButtonEvent(cx,cy,0,false,game,1)
                            end) end)
                            tbT=S.TB.Delay
                        end
                    end
                end
            end
        end
    end

    -- Hitbox
    if S.HB.On then
        local ns=V3(S.HB.Size,S.HB.Size,S.HB.Size); local nt=S.HB.Trans
        for _,pl in ipairs(PList) do
            if pl~=LP and (not S.Aim.TeamCheck or not IsTeam(pl)) then
                local cd=CC[pl]
                if cd and cd.Hum and cd.Hum.Health>0 then
                    local part=(S.HB.Part=="Head") and cd.Head
                        or (S.HB.Part=="HumanoidRootPart" and cd.HRP)
                        or cd.Char:FindFirstChild(S.HB.Part)
                    if part and part:IsA("BasePart") then
                        if not HBOrig[pl] then HBOrig[pl]={} end
                        if not HBOrig[pl][part] then HBOrig[pl][part]={Sz=part.Size,Tr=part.Transparency,CC=part.CanCollide} end
                        if part.Size~=ns then part.Size=ns end
                        if part.Transparency~=nt then part.Transparency=nt end
                        if part.CanCollide then part.CanCollide=false end
                    end
                end
            end
        end
    else
        for pl,pts in pairs(HBOrig) do
            for part,d in pairs(pts) do
                if part and part.Parent then
                    if part.Size~=d.Sz then part.Size=d.Sz end
                    if part.Transparency~=d.Tr then part.Transparency=d.Tr end
                    if part.CanCollide~=d.CC then part.CanCollide=d.CC end
                end
            end
        end
        table.clear(HBOrig)
    end

    -- World lighting
    if S.World.On then
        if Lit.ClockTime~=S.World.Time       then Lit.ClockTime=S.World.Time       end
        if Lit.Brightness~=S.World.Bright    then Lit.Brightness=S.World.Bright    end
        if Lit.GlobalShadows~=S.World.Shadows then Lit.GlobalShadows=S.World.Shadows end
        if Lit.Ambient~=S.World.Ambient      then Lit.Ambient=S.World.Ambient      end
    else
        if Lit.ClockTime~=OrigLit.T    then Lit.ClockTime=OrigLit.T    end
        if Lit.Brightness~=OrigLit.B   then Lit.Brightness=OrigLit.B   end
        if Lit.GlobalShadows~=OrigLit.S then Lit.GlobalShadows=OrigLit.S end
        if Lit.Ambient~=OrigLit.A      then Lit.Ambient=OrigLit.A      end
    end

    -- Player mods
    local cam=workspace.CurrentCamera
    if cam and S.Mov.FOVOn and cam.FieldOfView~=S.Mov.CamFOV then cam.FieldOfView=S.Mov.CamFOV end
    local mc=CC[LP]
    if mc and mc.Hum then
        if S.Mov.SpeedOn and mc.Hum.WalkSpeed~=S.Mov.Speed then mc.Hum.WalkSpeed=S.Mov.Speed end
        if S.Mov.JumpOn  and mc.Hum.JumpPower~=S.Mov.Jump  then mc.Hum.JumpPower=S.Mov.Jump  end
    end
end

-- ============================================================
--  RENDER LOOP
-- ============================================================
local function TickRender(dt)
    local ok2,e2=pcall(function()
        RSF=RSF+1; avgDT=avgDT*0.9+dt*0.1
        local cam=workspace.CurrentCamera; if not cam then return end
        local vp=cam.ViewportSize; if vp.X==0 or vp.Y==0 then return end
        local cp=cam.CFrame.Position; local sw,sh=vp.X,vp.Y
        local fovP=TickFOV(V2(sw*0.5,sh*0.5))
        TickAim(cp,sw,sh,dt,fovP,cam)
        TickESP(cp,sw,sh,cam)
        TickDmg(cam)
    end)
    if not ok2 then warn("KAIM Render:"..tostring(e2)) end
end

tIns(Conns,RS.Heartbeat:Connect(TickHB))
tIns(Conns,RS.RenderStepped:Connect(TickRender))

-- ============================================================
--  OBSIDIAN UI
-- ============================================================
local Win=Lib:CreateWindow({
    Title="KAIM", Footer="v8.8 — Obsidian",
    ToggleKeybind=Enum.KeyCode.K, NotifySide="Right",
})

local T={
    Home   = Win:AddTab("Home",     "home"),
    Combat = Win:AddTab("Combat",   "crosshair"),
    Visual = Win:AddTab("Visuals",  "eye"),
    Player = Win:AddTab("Movement", "person-standing"),
    Config = Win:AddTab("Config",   "settings"),
}

-- ============================================================
--  HOME
-- ============================================================
local HL=T.Home:AddLeftGroupbox("KAIM v8.8")
local HR=T.Home:AddRightGroupbox("Live Stats")
HL:AddLabel({Text="Obsidian Edition — single VP call per player, perspective-exact box, full chams distance system.", DoesWrap=true})
local lFPS=HR:AddLabel({Text="FPS: —"})
local lPL =HR:AddLabel({Text="Players: 0"})
task.spawn(function()
    while _env.KAIM_LOADED do
        local fps=mFloor(1/mMax(avgDT,0.001))
        pcall(function()
            lFPS:SetText(("FPS: %d  (%.1fms)"):format(fps,avgDT*1000))
            lPL:SetText("Players: "..#PList.." tracked")
        end)
        task.wait(2)
    end
end)

-- ============================================================
--  COMBAT
-- ============================================================
local AL=T.Combat:AddLeftGroupbox("Aimlock")
local AR=T.Combat:AddRightGroupbox("Targeting")

AL:AddToggle("AimOn",     {Text="Enable Aimlock",   Default=false,  Callback=function(v) S.Aim.On=v          end})
AL:AddLabel("Aim Key"):AddKeyPicker("AimKey",{Default="RightClick", Text="Aim Key",
    Callback=function(v) S.Aim.Key=v end})
AL:AddToggle("AimWall",   {Text="Wall Check",        Default=true,   Callback=function(v) S.Aim.WallCheck=v   end})
AL:AddToggle("AimTeam",   {Text="Team Check",        Default=true,   Callback=function(v) S.Aim.TeamCheck=v   end})
AL:AddSlider("AimHC",     {Text="Hit Chance %",      Default=100, Min=1,   Max=100, Rounding=0,
    Callback=function(v) S.Aim.HitChance=v end})
AL:AddToggle("AimPred",   {Text="Velocity Prediction",Default=true,  Callback=function(v) S.Aim.Pred=v        end})
AL:AddSlider("AimPStr",   {Text="Pred Strength",     Default=0.135,Min=0,   Max=0.3, Rounding=3,
    Callback=function(v) S.Aim.PredStr=v end})
AL:AddToggle("AimSmooth", {Text="Smooth Aim",        Default=false,  Callback=function(v) S.Aim.Smooth=v      end})
AL:AddSlider("AimSSpd",   {Text="Smooth Speed",      Default=0.3,  Min=0.05,Max=1,   Rounding=2,
    Callback=function(v) S.Aim.SmoothSpd=v end})
AL:AddToggle("AimNoise",  {Text="Perlin Jitter",     Default=false,  Callback=function(v) S.Aim.Noise=v       end})
AL:AddSlider("AimNSpd",   {Text="Noise Speed",       Default=1,    Min=0.1, Max=5,   Rounding=1,
    Callback=function(v) S.Aim.NoiseSpd=v end})
AL:AddSlider("AimNAmt",   {Text="Noise Amount",      Default=0.5,  Min=0,   Max=2,   Rounding=2,
    Callback=function(v) S.Aim.NoiseAmt=v end})

AR:AddDropdown("AimPri",  {Text="Priority",  Values={"Crosshair","Distance"}, Default="Crosshair",
    Callback=function(v) S.Aim.Priority=v end})
AR:AddDropdown("AimMode", {Text="Aim Mode",  Values={"Smart","Chaos","Head","Torso","Limbs","HRP"}, Default="Smart",
    Callback=function(v) S.Aim.Mode=v end})
AR:AddSlider("AimOX",{Text="Offset X",Default=0,Min=-5,Max=5,Rounding=1,Callback=function(v) S.Aim.OffX=v end})
AR:AddSlider("AimOY",{Text="Offset Y",Default=0,Min=-5,Max=5,Rounding=1,Callback=function(v) S.Aim.OffY=v end})
AR:AddSlider("AimOZ",{Text="Offset Z",Default=0,Min=-5,Max=5,Rounding=1,Callback=function(v) S.Aim.OffZ=v end})

-- FOV
local FG=T.Combat:AddLeftGroupbox("FOV Circle")
FG:AddToggle("FOVShow",  {Text="Show FOV",      Default=true,  Callback=function(v) S.FOV.Show=v   end})
FG:AddToggle("FOVFol",   {Text="Follow Cursor", Default=true,  Callback=function(v) S.FOV.Follow=v end})
FG:AddSlider("FOVRad",   {Text="Radius",        Default=150,  Min=20,  Max=600, Rounding=0, Suffix="px",
    Callback=function(v) S.FOV.Radius=v end})
FG:AddSlider("FOVThk",   {Text="Thickness",     Default=1.5,  Min=0.5, Max=5,   Rounding=1,
    Callback=function(v) S.FOV.Thick=v end})
FG:AddToggle("FOVPulse", {Text="Pulse",         Default=false, Callback=function(v) S.FOV.Pulse=v  end})
FG:AddToggle("FOVFill",  {Text="Filled",        Default=false, Callback=function(v) S.FOV.Filled=v end})
FG:AddLabel("Color"):AddColorPicker("FOVCol",   {Default=WHITE,Callback=function(v) S.FOV.Color=v  end})

-- Triggerbot + Hitbox
local TBG=T.Combat:AddRightGroupbox("Triggerbot")
TBG:AddToggle("TBOn",  {Text="Enable",         Default=false, Callback=function(v) S.TB.On=v     end})
TBG:AddToggle("TBTeam",{Text="Team Check",     Default=true,  Callback=function(v) S.TB.Team=v   end})
TBG:AddToggle("TBSph", {Text="Spherecast",     Default=true,  Callback=function(v) S.TB.Sphere=v end})
TBG:AddSlider("TBThk", {Text="Ray Thickness",  Default=0.5,  Min=0.1,Max=3,   Rounding=1,
    Callback=function(v) S.TB.Thick=v end})
TBG:AddSlider("TBDly", {Text="Delay (s)",      Default=0.05, Min=0.01,Max=0.5, Rounding=2,
    Callback=function(v) S.TB.Delay=v end})
TBG:AddSlider("TBHC",  {Text="Hit Chance %",   Default=100,  Min=1,  Max=100, Rounding=0,
    Callback=function(v) S.TB.HC=v end})

local HBG=T.Combat:AddRightGroupbox("Hitbox Expander")
HBG:AddToggle("HBOn",  {Text="Enable",    Default=false,Callback=function(v) S.HB.On=v     end})
HBG:AddDropdown("HBPart",{Text="Part",    Values={"Head","HumanoidRootPart","UpperTorso"}, Default="Head",
    Callback=function(v) S.HB.Part=v end})
HBG:AddSlider("HBSz",  {Text="Size",      Default=5,    Min=2, Max=30, Rounding=1,
    Callback=function(v) S.HB.Size=v end})
HBG:AddSlider("HBTr",  {Text="Transparency",Default=0.5,Min=0, Max=1,  Rounding=2,
    Callback=function(v) S.HB.Trans=v end})

-- Anti-detect
local ADG=T.Combat:AddLeftGroupbox("Anti-Detect")
ADG:AddToggle("ADOn",  {Text="Periodic Aim Disable",Default=false,Callback=function(v) S.Avoid.On=v      end})
ADG:AddSlider("ADCh",  {Text="Disable Chance",    Default=0.1, Min=0.01,Max=1,  Rounding=2,
    Callback=function(v) S.Avoid.Chance=v end})
ADG:AddSlider("ADDur", {Text="Disable Duration",  Default=0.2, Min=0.05,Max=1,  Rounding=2,
    Callback=function(v) S.Avoid.Dur=v end})

-- ============================================================
--  VISUALS
-- ============================================================
local EL=T.Visual:AddLeftGroupbox("ESP")
local ER=T.Visual:AddRightGroupbox("Colors & Text")

EL:AddToggle("ESPOn",     {Text="Enable ESP",     Default=false, Callback=function(v) S.ESP.On=v        end})
EL:AddSlider("ESPDist",   {Text="Max Distance",   Default=1000, Min=100,Max=5000,Rounding=0,Suffix="m",
    Callback=function(v) S.ESP.MaxDist=v end})
EL:AddToggle("ESPTeam",   {Text="Team Check",     Default=true,  Callback=function(v) S.ESP.TeamCheck=v end})
EL:AddToggle("ESPShowTM", {Text="Show Teammates", Default=false, Callback=function(v) S.ESP.ShowTeam=v  end})
EL:AddLabel("Team Color"):AddColorPicker("ESPTCol",{Default=C3(0,200,255),Callback=function(v) S.ESP.TeamCol=v end})
EL:AddToggle("ESPBoxes",  {Text="Show Boxes",     Default=true,  Callback=function(v) S.ESP.Boxes=v     end})
EL:AddDropdown("ESPBStyle",{Text="Box Style",     Values={"Standard","Corner"},Default="Corner",
    Callback=function(v) S.ESP.BoxStyle=v end})
EL:AddToggle("ESPOutline",{Text="Box Outline",    Default=true,  Callback=function(v) S.ESP.Outline=v   end})
EL:AddToggle("ESPFill",   {Text="Box Fill",       Default=false, Callback=function(v) S.ESP.BoxFill=v   end})
EL:AddSlider("ESPFillT",  {Text="Fill Opacity",   Default=0.2,  Min=0, Max=1, Rounding=2,
    Callback=function(v) S.ESP.BoxFillT=v end})
EL:AddToggle("ESPHBar",   {Text="Health Bar",     Default=true,  Callback=function(v) S.ESP.HBar=v      end})
EL:AddToggle("ESPHNums",  {Text="HP Numbers",     Default=false, Callback=function(v) S.ESP.HNums=v     end})
EL:AddToggle("ESPDist2",  {Text="Distance",       Default=false, Callback=function(v) S.ESP.DistShow=v  end})
EL:AddToggle("ESPWep",    {Text="Weapon",         Default=false, Callback=function(v) S.ESP.WepShow=v   end})
EL:AddToggle("ESPNames",  {Text="Names",          Default=true,  Callback=function(v) S.ESP.Names=v     end})
EL:AddDropdown("ESPNSt",  {Text="Name Style",     Values={"Display Name","Username","Both"},Default="Display Name",
    Callback=function(v) S.ESP.NStyle=v end})
EL:AddDropdown("ESPCase", {Text="Text Case",      Values={"Normal","UPPERCASE"},Default="UPPERCASE",
    Callback=function(v) S.ESP.TCase=v end})
EL:AddSlider("ESPTSz",    {Text="Text Size",      Default=14, Min=10,Max=22,Rounding=0,
    Callback=function(v) S.ESP.TSize=v end})

ER:AddToggle("ESPVCol",   {Text="Visibility Colors",Default=true, Callback=function(v) S.ESP.VisColors=v end})
ER:AddLabel("Visible"):AddColorPicker("ESPVis",   {Default=C3(0,255,100), Callback=function(v) S.ESP.VisCol=v   end})
ER:AddLabel("Hidden"):AddColorPicker("ESPHid",    {Default=RED,           Callback=function(v) S.ESP.HideCol=v  end})
ER:AddLabel("Static"):AddColorPicker("ESPStat",   {Default=WHITE,         Callback=function(v) S.ESP.StatCol=v  end})
ER:AddToggle("ESPCName",  {Text="Custom Name Color",Default=false,Callback=function(v) S.ESP.CustomName=v end})
ER:AddLabel("Name Color"):AddColorPicker("ESPNCol",{Default=WHITE,        Callback=function(v) S.ESP.NameCol=v  end})
ER:AddLabel("Damage Color"):AddColorPicker("ESPDCol",{Default=C3(255,255,0),Callback=function(v) S.ESP.DmgCol=v end})

-- Indicators
local IL=T.Visual:AddLeftGroupbox("Indicators")
IL:AddToggle("IndTr",    {Text="Tracers",          Default=false, Callback=function(v) S.ESP.Tracers=v    end})
IL:AddDropdown("IndTrO", {Text="Tracer Origin",    Values={"Bottom","Center","Top"},Default="Bottom",
    Callback=function(v) S.ESP.TracerOrg=v end})
IL:AddLabel("Tracer Color"):AddColorPicker("IndTrC",{Default=C3(0,255,100),Callback=function(v) S.ESP.TracerCol=v end})
IL:AddToggle("IndLk",    {Text="Look Tracers",     Default=false, Callback=function(v) S.ESP.LookTr=v    end})
IL:AddSlider("IndLkLen", {Text="Look Length",      Default=5,  Min=1,Max=30,Rounding=0,
    Callback=function(v) S.ESP.LookLen=v end})
IL:AddLabel("Look Color"):AddColorPicker("IndLkC", {Default=WHITE,Callback=function(v) S.ESP.LookCol=v end})
IL:AddToggle("IndArr",   {Text="Off-Screen Arrows",Default=false, Callback=function(v) S.ESP.Arrows=v    end})
IL:AddLabel("Arrow Color"):AddColorPicker("IndAC", {Default=C3(255,85,0),Callback=function(v) S.ESP.ArrowCol=v end})
IL:AddToggle("IndDmg",   {Text="Damage Numbers",   Default=false, Callback=function(v) S.ESP.DmgNums=v   end})

-- Target HUD
local HG=T.Visual:AddRightGroupbox("Target HUD")
HG:AddToggle("HUDOn",  {Text="Enable HUD",  Default=true, Callback=function(v) S.ESP.HUD=v        end})
HG:AddDropdown("HUDSt",{Text="HUD Style",   Values={"Ascension","Valorant","Standard","Minimal","Apex"},
    Default="Ascension", Callback=function(v) S.ESP.HUDStyle=v end})
HG:AddSlider("HUDSc",  {Text="HUD Scale",   Default=1,  Min=0.5,Max=2,Rounding=2,
    Callback=function(v) S.ESP.HUDScale=v end})

-- Chams — full section with distance system
local CG=T.Visual:AddRightGroupbox("Chams")
CG:AddToggle("ChOn",    {Text="Enable Chams",       Default=false, Callback=function(v) S.ESP.Chams=v       end})
CG:AddSlider("ChMaxD",  {Text="Chams Max Distance", Default=1000, Min=100,Max=5000,Rounding=0,Suffix="m",
    Callback=function(v) S.ESP.ChamsMaxDist=v end})
CG:AddSlider("ChLOD",   {Text="LOD Distance",       Default=300,  Min=50, Max=1000,Rounding=0,Suffix="m",
    Tooltip="Beyond this: LOD colors. Below: full vis/hidden colors.",
    Callback=function(v) S.ESP.ChamsLOD=v end})
CG:AddToggle("ChVis",   {Text="Visibility Colors",  Default=true,  Callback=function(v) S.ESP.ChamsVisCol=v end})
CG:AddLabel("Full Fill"):AddColorPicker("ChFF",     {Default=WHITE,         Callback=function(v) S.ESP.ChamsFill=v     end})
CG:AddLabel("Full Outline"):AddColorPicker("ChFO",  {Default=WHITE,         Callback=function(v) S.ESP.ChamsOut=v      end})
CG:AddLabel("LOD Fill"):AddColorPicker("ChLF",      {Default=C3(255,100,0), Callback=function(v) S.ESP.ChamsLODFill=v  end})
CG:AddLabel("LOD Outline"):AddColorPicker("ChLO",   {Default=C3(255,100,0), Callback=function(v) S.ESP.ChamsLODOut=v   end})
CG:AddSlider("ChFT",    {Text="Fill Transparency",  Default=0.5, Min=0,Max=1,Rounding=2,
    Callback=function(v) S.ESP.ChamsFT=v end})
CG:AddSlider("ChOT",    {Text="Outline Transparency",Default=0,  Min=0,Max=1,Rounding=2,
    Callback=function(v) S.ESP.ChamsOT=v end})
CG:AddToggle("ChTeam",  {Text="Teammate Chams",     Default=false, Callback=function(v) S.ESP.ChamsTeam=v   end})
CG:AddLabel("Team Fill"):AddColorPicker("ChTF",     {Default=C3(0,200,255), Callback=function(v) S.ESP.ChamsTeamFill=v end})
CG:AddLabel("Team Outline"):AddColorPicker("ChTO",  {Default=C3(0,200,255), Callback=function(v) S.ESP.ChamsTeamOut=v  end})

-- World
local WG=T.Visual:AddLeftGroupbox("World")
WG:AddToggle("WOn",   {Text="Override Lighting",Default=false,Callback=function(v) S.World.On=v       end})
WG:AddSlider("WTime", {Text="Time",             Default=14,  Min=0,Max=24,Rounding=1,
    Callback=function(v) S.World.Time=v end})
WG:AddSlider("WBri",  {Text="Brightness",       Default=2,   Min=0,Max=5, Rounding=1,
    Callback=function(v) S.World.Bright=v end})
WG:AddToggle("WShad", {Text="Global Shadows",   Default=false,Callback=function(v) S.World.Shadows=v  end})
WG:AddLabel("Ambient"):AddColorPicker("WAmb",   {Default=WHITE,Callback=function(v) S.World.Ambient=v end})

-- ============================================================
--  MOVEMENT
-- ============================================================
local ML=T.Player:AddLeftGroupbox("Character")
local MR=T.Player:AddRightGroupbox("Physics")

ML:AddToggle("SpOn",  {Text="Speed Override",  Default=false,Callback=function(v) S.Mov.SpeedOn=v end})
ML:AddSlider("Sp",    {Text="Walk Speed",       Default=16,  Min=5,  Max=100,Rounding=0,Callback=function(v) S.Mov.Speed=v end})
ML:AddToggle("JpOn",  {Text="Jump Override",    Default=false,Callback=function(v) S.Mov.JumpOn=v  end})
ML:AddSlider("Jp",    {Text="Jump Power",       Default=50,  Min=10, Max=250,Rounding=0,Callback=function(v) S.Mov.Jump=v  end})
ML:AddToggle("FOn",   {Text="FOV Override",     Default=false,Callback=function(v) S.Mov.FOVOn=v   end})
ML:AddSlider("CFOV",  {Text="Camera FOV",       Default=70,  Min=30, Max=120,Rounding=0,Suffix="°",Callback=function(v) S.Mov.CamFOV=v end})
ML:AddToggle("IJ",    {Text="Infinite Jump",    Default=false,Callback=function(v) S.Mov.InfJump=v end})

local ncConn=nil; local ncAddConn=nil; local ncCache={}
local function BuildNC(char)
    ncCache={}; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then tIns(ncCache,{p=p,cc=p.CanCollide}) end
    end
end
_G._KaimNC=BuildNC

local function SetNC(on)
    S.Mov.Noclip=on
    if ncConn    then ncConn:Disconnect();    ncConn=nil    end
    if ncAddConn then ncAddConn:Disconnect(); ncAddConn=nil end
    if on then
        BuildNC(LP.Character)
        ncConn=RS.Stepped:Connect(function()
            for _,e in ipairs(ncCache) do
                if e.p and e.p.Parent and e.p.CanCollide then e.p.CanCollide=false end
            end
        end)
        if LP.Character then
            ncAddConn=LP.Character.DescendantAdded:Connect(function(p)
                if p:IsA("BasePart") then tIns(ncCache,{p=p,cc=p.CanCollide}); p.CanCollide=false end
            end)
        end
        tIns(Conns,ncConn); tIns(Conns,ncAddConn)
    else
        for _,e in ipairs(ncCache) do
            if e.p and e.p.Parent and e.p.CanCollide~=e.cc then e.p.CanCollide=e.cc end
        end
        ncCache={}
    end
end

MR:AddToggle("NCOn",{Text="Noclip",Default=false,Callback=function(v) SetNC(v) end})
MR:AddLabel("Noclip Key"):AddKeyPicker("NCKey",{Default="N",Text="Noclip Key",
    Callback=function(v) S.Mov.NoclipKey=v; pcall(function() ncKC=Enum.KeyCode[v] end) end})

tIns(Conns,UIS.JumpRequest:Connect(function()
    if S.Mov.InfJump then
        local cd=CC[LP]; if cd and cd.Hum then cd.Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- ============================================================
--  CONFIG
-- ============================================================
local CL2=T.Config:AddLeftGroupbox("Save / Load")
local CR=T.Config:AddRightGroupbox("Performance")

SM:SetLibrary(Lib); SM:IgnoreThemeSettings()
SM:SetIgnoreIndexes({"AimKey","NCKey"})
SM:SetFolder("KAIM_v8"); SM:BuildConfigSection(T.Config)

TM:SetLibrary(Lib); TM:SetFolder("KAIM_v8")
TM:ApplyToTab(T.Config); TM:LoadDefault()

CR:AddToggle("PerfSkip",{Text="Frame Skip (FPS Guard)",Default=true,Callback=function(v) S.Perf.Skip=v end})
CR:AddSlider("PerfMax", {Text="Max ESP / Frame",Default=20,Min=5,Max=50,Rounding=0,
    Callback=function(v) S.Perf.MaxPF=v end})
CR:AddSlider("PerfLOD", {Text="LOD Distance",   Default=500,Min=100,Max=2000,Rounding=0,Suffix="m",
    Tooltip="Players beyond this get box+name+health only (no tracers/weapon/dmg). Huge FPS gain.",
    Callback=function(v) S.Perf.LOD=v end})
CR:AddLabel({Text="Note: Chams have their own Max/LOD sliders in the Chams section.", DoesWrap=true})

-- Unload
local DG=T.Config:AddLeftGroupbox("Danger Zone")
DG:AddButton("Unload KAIM", function()
    for _,c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    for _,e in pairs(ESPObj) do DelE(e) end; ESPObj={}
    for _,l in pairs(TrLine) do pcall(function() l:Remove() end) end; TrLine={}
    for _,l in pairs(LkLine) do pcall(function() l:Remove() end) end; LkLine={}
    for _,d in ipairs(ADmg)   do pcall(function() d.T:Remove() end) end; ADmg={}
    for _,d in ipairs(DmgPool) do pcall(function() d.T:Remove() end) end; DmgPool={}
    Lit.ClockTime=OrigLit.T; Lit.Brightness=OrigLit.B
    Lit.GlobalShadows=OrigLit.S; Lit.Ambient=OrigLit.A
    for _,pts in pairs(HBOrig) do
        for part,d in pairs(pts) do
            if part and part.Parent then part.Size=d.Sz; part.Transparency=d.Tr; part.CanCollide=d.CC end
        end
    end
    SetNC(false)
    pcall(function() FOVR:Remove(); FOVF:Remove() end)
    pcall(function() CFolder:Destroy() end)
    pcall(function() for _,v in pairs(THUD) do v:Remove() end end)
    _env.KAIM_LOADED=false; _G._KaimNC=nil
    Lib:Notify("KAIM unloaded. Safe to reload.", 4)
end)

-- ============================================================
--  INPUT
-- ============================================================
tIns(Conns,UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==ncKC then
        local ns=not S.Mov.Noclip; SetNC(ns)
        Lib:Notify("Noclip "..(ns and "ON" or "OFF"), 2)
    end
    local ak=S.Aim.Key
    if ak=="RightClick" then
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then S.Aim.IsAiming=true end
    else
        local ok2,kc=pcall(function() return Enum.KeyCode[ak] end)
        if ok2 and kc and inp.KeyCode==kc then S.Aim.IsAiming=true end
    end
end))

tIns(Conns,UIS.InputEnded:Connect(function(inp)
    local ak=S.Aim.Key
    if ak=="RightClick" then
        if inp.UserInputType==Enum.UserInputType.MouseButton2 then S.Aim.IsAiming=false end
    else
        local ok2,kc=pcall(function() return Enum.KeyCode[ak] end)
        if ok2 and kc and inp.KeyCode==kc then S.Aim.IsAiming=false end
    end
end))

T.Home:Select()
SM:LoadAutoloadConfig()
Lib:Notify("KAIM v8.8 loaded — Press K to toggle.", 4)
