--!strict
--!native
--!optimize 2

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ExecutorSupport = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHunterSolo1/Scripts/refs/heads/main/ExecutorTest"))()

local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
repeat task.wait() until game:IsLoaded()

if game:GetService("Players").LocalPlayer:GetAttribute("SupremeLoaded") then
if getgenv().Library then
getgenv().Library:Notify("Supreme Hub 『 Already Loaded 』",4)
else
print("Supreme Hub 『 Already Loaded 』")
end
return end
game:GetService("Players").LocalPlayer:SetAttribute("SupremeLoaded",true)

local LibraryName = 'Supreme Hub'

local executionCount = 0

if isfile and writefile and readfile then
local filename = "ExecutionCount.txt"

if isfile(filename) then
    executionCount = tonumber(readfile(filename)) or 0
    executionCount = executionCount + 1
    writefile(filename, tostring(executionCount))
else
    executionCount = 1
    writefile(filename, "1")
end


end

-- STREAMING_CHUNK:Loading 99 Nights In Forest...
if game.PlaceId == 126509999114328 then

local repo = 'https://raw.githubusercontent.com/mstudio45/Obsidian/main/'
local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/ESPLibrary"))()

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()


local Options = Library.Options
local Toggles = Library.Toggles
local Connections = {}
local Window = Library:CreateWindow({
Title = LibraryName,
Center = true,
ToggleKeybind = Enum.KeyCode.RightControl,
AutoShow = true,
NotifySide = "Right",
ShowCustomCursor = true,
})
local PlaySound = true
local function Notify(txt,duration)
Library:Notify({
Title = LibraryName,
Description = txt .. "!",
Time = duration,
})
if PlaySound then
local Sound = Instance.new("Sound",game:GetService("SoundService"))
Sound.SoundId = "rbxassetid://101511361468852"

Sound.Volume = 2
Sound:Play()
game:GetService("Debris"):AddItem(Sound, 3)
end
end

local function AddESP(part,txt,color)
ESPLibrary:AddESP({
Object = part,
Text = txt,
Color = color
})
end

Notify("Loading | 99 Nights in Forest",2)

local AlreadyChanged = {}

local ChildrenNames = {
["Lost Child"] =  "dino Kid",
["Lost Child2"] = "kraken Kid",
["Lost Child3"] = "squid kid",
["Lost Child4"] = "koala Kid"
}

task.wait(2)

local Tabs = {
    Home = Window:AddTab('Home', 'house'),
    Main = Window:AddTab('Player', "star"),
    Visuals = Window:AddTab('Visuals',"eye"),
    Settings = Window:AddTab('Settings',"settings"),
} 


local HomeBox = Tabs.Home:AddLeftGroupbox('Home')

local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)

HomeBox:AddImage("PlayerFace", {
Image = content,
Height = 200,
})

HomeBox:AddDivider()
HomeBox:AddLabel('Execution Times ' .. (tonumber(executionCount) and tonumber(executionCount) >= 1 and executionCount or "Nan"))
local OPBox = Tabs.Main:AddRightGroupbox('Overpowered')
OPBox:AddLabel('Warning Abusing This Feature Can Cause Server Wide Crash or alot of lag',true)
OPBox:AddToggle('InfSapling',{
Text = "Plant Every Sapling",
Default = false,
Tooltip = "Automatically  Plant Sapling to the placed that selected in the drop"
})
OPBox:AddDropdown("SaplingPlace", {
Values = {"Scarp-Machine","Campfire","Player" },
Default = 2,
Multi = false,
Text = "Plant Sapling Place",
Tooltip = "Select the Place where you want Plant Saplings",
Callback = function(Value)
end,
})
OPBox:AddDivider()

-- STREAMING_CHUNK:Configuring Teleports and Aura...
local AuraBox = Tabs.Main:AddLeftGroupbox('Aura')
local TPBox = Tabs.Main:AddLeftGroupbox('Teleport')
TPBox:AddLabel('Please  Interact with the objective that get stuck in air so it shows to everyone and for it to work',true)
TPBox:AddButton('Teleport All Log to Player',function()
for _, v in pairs(workspace.Items:GetChildren()) do
if v.Name == "Log" then
v:PivotTo(LocalPlayer.Character.HumanoidRootPart.CFrame)
local Sack = LocalPlayer.Inventory:FindFirstChild("Old Sack") or
LocalPlayer.Inventory:FindFirstChild("Good Sack") or LocalPlayer.Inventory:FindFirstChild("Giant Sack")
local args = {
Sack,
v
}
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagStoreItem"):InvokeServer(unpack(args))

local args = {
Sack,
v,
false
}
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(args))
end
end
end)

TPBox:AddButton('Teleport All Food to Player',function()
for _, v in pairs(workspace.Items:GetChildren()) do
if not (v.Name == "Berry") then
if v:GetAttribute("RestoreHunger") then
v:PivotTo(LocalPlayer.Character.HumanoidRootPart.CFrame)
local Sack = LocalPlayer.Inventory:FindFirstChild("Old Sack") or
LocalPlayer.Inventory:FindFirstChild("Good Sack") or LocalPlayer.Inventory:FindFirstChild("Giant Sack")

local args = { Sack, v }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagStoreItem"):InvokeServer(unpack(args))

local args = { Sack, v, false }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(args))
end
end
end
end)

TPBox:AddButton('Teleport All Fuel to Player',function()
for _, v in pairs(workspace.Items:GetChildren()) do
if not (v.Name == "Log" or v.Name == "Sapling") then
if v:GetAttribute("BurnFuel") then
v:PivotTo(LocalPlayer.Character.HumanoidRootPart.CFrame)
local Sack = LocalPlayer.Inventory:FindFirstChild("Old Sack") or
LocalPlayer.Inventory:FindFirstChild("Good Sack")  or LocalPlayer.Inventory:FindFirstChild("Giant Sack")

local args = { Sack, v }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagStoreItem"):InvokeServer(unpack(args))

local args = { Sack, v, false }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(args))
end
end
end
end)

TPBox:AddButton('Teleport All Healings to Player',function()
for _, v in pairs(workspace.Items:GetChildren()) do
if v.Name == "Bandage" or v.Name == "Medkit" then
v:PivotTo(LocalPlayer.Character.HumanoidRootPart.CFrame)
local Sack = LocalPlayer.Inventory:FindFirstChild("Old Sack") or
LocalPlayer.Inventory:FindFirstChild("Good Sack") or LocalPlayer.Inventory:FindFirstChild("Giant Sack")
local args = { Sack, v }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagStoreItem"):InvokeServer(unpack(args))

local args = { Sack, v, false }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(args))
end
end
end)

TPBox:AddButton('Teleport All Metals (Scarppable) Player',function()
for _, v in pairs(workspace.Items:GetChildren()) do
if v:GetAttribute("Scrappable") then v:PivotTo(LocalPlayer.Character.HumanoidRootPart.CFrame)
local Sack = LocalPlayer.Inventory:FindFirstChild("Old Sack") or
LocalPlayer.Inventory:FindFirstChild("Good Sack") or LocalPlayer.Inventory:FindFirstChild("Giant Sack")
local args = { Sack, v }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagStoreItem"):InvokeServer(unpack(args))

local args = { Sack, v, false }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestBagDropItem"):FireServer(unpack(args))
end
end
end)

-- STREAMING_CHUNK:Setting up ESP logic for 99 Nights...
local LightingBox = Tabs.Visuals:AddLeftGroupbox('Lighting')

local ESPBox = Tabs.Visuals:AddRightGroupbox('ESP')
local ESPSettings = Tabs.Visuals:AddLeftGroupbox('ESP Settings')

ESPSettings:AddToggle('ShowMarker',{
Text = "Show ESP Distance Marker",
Default = false,
Tooltip = "Show you the distance Between  you and the objective",
Callback = function(Value)
ESPLibrary:SetShowDistance(Value)
end
})
ESPSettings:AddToggle('ShowTracers',{
Text = "Show ESP Tracers",
Default = false,
Tooltip = "Show you a (3d) line that connects from you to the objective",
Callback = function(Value)
ESPLibrary:SetTracers(Value)
end
})

ESPBox:AddToggle('Children',{
Text = "Children",
Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.Characters:GetChildren()) do
local Child = ChildrenNames[v.Name]
if Child then AddESP(v, Child, Color3.new(1, 1, 1)) end
end
else
for _, v in pairs(workspace.Characters:GetChildren()) do
local Child = ChildrenNames[v.Name]
if Child then ESPLibrary:RemoveESP(v) end
end
end
end
})
ESPBox:AddToggle('Monsters',{
Text = "Monsters",
Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.Characters:GetChildren()) do
if v.Name == "Wolf" or v.Name == "Alpha Wolf" or v.Name == "Mammoth" or v.Name == "Cultist" or v.Name == "Shadow Cultist" or v.Name == "Bear" or v.Name == "Crossbow Cultist" or v.Name == "Frog" or v.Name == "Brutal Cultist" then
AddESP(v, v.Name, Color3.new(1, 0, 0))
end
end
else
for _, v in pairs(workspace.Characters:GetChildren()) do
if v.Name == "Wolf" or v.Name == "Alpha Wolf" or v.Name == "Mammoth" or v.Name == "Cultist" or v.Name == "Shadow Cultist" or v.Name == "Bear" or v.Name == "Crossbow Cultist" or v.Name == "Frog" or v.Name == "Brutal Cultist" then
ESPLibrary:RemoveESP(v)
end
end
end
end
})
ESPBox:AddToggle('Chest',{
Text = "Chest",
Default = false,
Callback = function(Value)
if Value then
table.clear(AlreadyChanged)
for _, v in pairs(workspace.Items:GetChildren()) do
if string.match(v.Name, "Chest") then AddESP(v, "Chest", Color3.new(1, 0.85, 0)) end
end
else
for _, v in pairs(workspace.Items:GetChildren()) do
if string.match(v.Name, "Chest") then ESPLibrary:RemoveESP(v) end
end
end
end
})
ESPBox:AddToggle('Armor',{
Text = "Armor",
Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.Items:GetChildren()) do
if string.match(v.Name, "Body") or string.match(v.Name, "Armor") then
AddESP(v, v.Name, Color3.new(1, 0.85, 0))
end
end
else
for _, v in pairs(workspace.Items:GetChildren()) do
if string.match(v.Name, "Body") or string.match(v.Name, "Armor") then
ESPLibrary:RemoveESP(v)
end
end
end
end
})

ESPBox:AddToggle('Food',{
Text = "Food",
Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.Items:GetChildren()) do
if v:GetAttribute("RestoreHunger") then AddESP(v, v.Name, Color3.new(1, 0.7, 0.8)) end
end
else
for _, v in pairs(workspace.Items:GetChildren()) do
if v:GetAttribute("RestoreHunger") then ESPLibrary:RemoveESP(v) end
end
end
end
})

ESPBox:AddToggle('Metals',{
Text = "Metals (Scarpable)",
Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.Items:GetChildren()) do
if v:GetAttribute("Scrappable") then AddESP(v, v.Name, Color3.new(0.5, 0.5, 0.5)) end
end
else
for _, v in pairs(workspace.Items:GetChildren()) do
if v:GetAttribute("Scrappable") then ESPLibrary:RemoveESP(v) end
end
end
end
})

table.insert(Connections,workspace.Items.ChildAdded:Connect(function(v)
if Toggles.Metals.Value then
if v:GetAttribute("Scrappable") then AddESP(v, v.Name, Color3.new(0.5, 0.5, 0.5)) end
end
if Toggles.Food.Value then
if v:GetAttribute("RestoreHunger") then AddESP(v, v.Name, Color3.new(1, 0.7, 0.8)) end
end
if Toggles.Chest.Value then
if string.match(v.Name, "Chest") then AddESP(v, "Chest", Color3.new(1, 0.85, 0)) end
end
if Toggles.Armor.Value then
if string.match(v.Name, "Body") or string.match(v.Name, "Armor") then AddESP(v, v.Name, Color3.new(1, 0.85, 0)) end
end
end))

table.insert(Connections,workspace.Characters.ChildAdded:Connect(function(v)
if Toggles.Children.Value then
local Child = ChildrenNames[v.Name]
if Child then AddESP(v, Child, Color3.new(1, 1, 1)) end
end
if Toggles.Monsters.Value then
if v.Name == "Wolf" or v.Name == "Alpha Wolf" or v.Name == "Mammoth" or v.Name == "Cultist" or v.Name == "Shadow Cultist" or v.Name == "Bear" or v.Name == "Crossbow Cultist" or v.Name == "Frog" or v.Name == "Brutal Cultist"  then
AddESP(v, v.Name, Color3.new(1, 0, 0))
end
end
end))

LightingBox:AddToggle('NoFog',{
Text = "No Fog",
Tooltip = "Removes Fog",
Default = false,
Callback = function(Value)
if not Value then Notify("The Fog Would Restore after the weather changes",5) end
end
})
OPBox:AddToggle('InfJump',{
Text = "Infinite Jump",
Default = false,
Tooltip = "You Can jump as much as u want"
})

table.insert(Connections,UserInputService.JumpRequest:Connect(function()
if Toggles.InfJump.Value then
if not  Toggles.InfJump.Value then return end
LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end
end))
OPBox:AddToggle('InstantPr',{
Text = "Instant Interact",
Default = false,
Tooltip = "Instant Interact for every prompt",
Callback = function(Value)
if Value then
for _, v in pairs(workspace:GetDescendants()) do
if v:IsA("ProximityPrompt") then
v:SetAttribute("Duration",v.HoldDuration)
v.HoldDuration = 0
end
end
else
for _, v in pairs(workspace:GetDescendants()) do
if v:IsA("ProximityPrompt") then
v.HoldDuration = v:GetAttribute("Duration") or 5
v:SetAttribute("Duration",nil)
end
end
end
end
})
LightingBox:AddToggle('FullBright',{
Text = "Fullbright",
Tooltip = "Removes Darkness",
Default = false,
Callback = function(Value)
if not Value then Notify("The Brightness Would Restore after the weather changes",5) end
end
})

-- STREAMING_CHUNK:Configuring Aura Systems...
AuraBox:AddToggle('KillAura',{
Text = "Kill Aura",
Tooltip = "Attacks the Monster from far",
Default = false,
Callback = function(Value)
if Value then Notify("Equip an Axe for that to work",5) end
end
})
AuraBox:AddSlider("KillAuraRange", {
Text = "Kill Aura Range",
Default = 50,
Min = 50,
Max = 200,
Rounding = 1,
Compact = false,
Tooltip = "How much Should it need to start automatically  Attacking Monsters",
Callback = function(Value) end
})

AuraBox:AddToggle('TreeAura',{
Text = "Tree Aura",
Tooltip = "Cut Trees from a distance away",
Default = false,
Callback = function(Value)
if Value then Notify("Equip an Axe for that to work",5) end
end
})
AuraBox:AddSlider("TreeAuraRange", {
Text = "Tree Aura Range",
Default = 50,
Min = 50,
Max = 200,
Rounding = 1,
Compact = false,
Tooltip = "How much Should it need to start automatically cutting trees",
Callback = function(Value) end
})

OPBox:AddToggle('Reheal',{
Text = "Infinite Heal",
Tooltip = "Heals you everytime you get damaged",
Default = false
})
OPBox:AddButton({
Text = "Invincible",
Tooltip = "Gives you Infinite Health but cannot be reverted",
DoubleClick = true,
Func = function()
Notify("Can be reverted by using bandage or medkit",3)
game.ReplicatedStorage:FindFirstChild("DamagePlayer",true):FireServer(-math.huge)
end
})

table.insert(Connections,LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
if LocalPlayer.Character.Humanoid.Health < 100 then
local GainHP  = (LocalPlayer.Character.Humanoid.Health - LocalPlayer.Character.Humanoid.MaxHealth)
game.ReplicatedStorage:FindFirstChild("DamagePlayer",true):FireServer(GainHP)
end
end))

table.insert(Connections,LocalPlayer.CharacterAdded:Connect(function()
task.wait(1.5)
table.insert(Connections,LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
if LocalPlayer.Character.Humanoid.Health < 100 then
local GainHP  = (LocalPlayer.Character.Humanoid.Health - LocalPlayer.Character.Humanoid.MaxHealth)
game.ReplicatedStorage:FindFirstChild("DamagePlayer",true):FireServer(GainHP)
end
end))
end))

local KillAuraDelay = 0
local TreeAuraDelay = 0
local ChestCheckingDelay = 0
table.insert(Connections,RunService.Heartbeat:Connect(function(dt)
KillAuraDelay = KillAuraDelay + dt
TreeAuraDelay = TreeAuraDelay + dt
ChestCheckingDelay = ChestCheckingDelay + dt

if Toggles.Chest.Value then
if ChestCheckingDelay > 1 then
ChestCheckingDelay = 0
for _, v in pairs(workspace.Items:GetChildren()) do
if string.match(v.Name, "Chest") and not AlreadyChanged[v] then
if v:GetAttribute("LocalOpened") == true then
AlreadyChanged[v] = true
ESPLibrary:RemoveESP(v)
ESPLibrary:AddESP(v, "Opened Chest", Color3.new(1, 0.85, 0))
end
end
end
end
end

if KillAuraDelay > 0.3 then
KillAuraDelay = 0
if Toggles.KillAura.Value then
for i, v in pairs(workspace.Characters:GetChildren()) do
if not Toggles.KillAura.Value then return end
if v.Name == "Bunny" or v.Name == "Wolf" or v.Name == "Alpha Wolf" or v.Name == "Mammoth" or v.Name == "Cultist" or v.Name == "Bear" or v.Name == "Crossbow Cultist" or v.Name == "Shadow Cultist" or v.Name == "Frog" or v.Name == "Brutal Cultist"  then
local Dis = (LocalPlayer.Character.HumanoidRootPart.Position - v:GetPivot().Position).Magnitude
if Dis < Options.KillAuraRange.Value then
if LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Old Axe") then
local args = { v, LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Old Axe"), math.random(1, 100) .. "_10012952131", LocalPlayer.Character.HumanoidRootPart.CFrame }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
elseif LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Good Axe") then
local args = { v, LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Good Axe"), math.random(1, 100) .. "_10012952131", LocalPlayer.Character.HumanoidRootPart.CFrame }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
elseif LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Strong Axe") then
local args = { v, LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Strong Axe"), math.random(1, 100) .. "_10012952131", LocalPlayer.Character.HumanoidRootPart.CFrame }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
end
end
end
end
end
end

if Toggles.TreeAura.Value then
if TreeAuraDelay > 0.3 then
TreeAuraDelay = 0
for _, v in pairs(workspace.Map.Foliage:GetChildren()) do
if not Toggles.TreeAura.Value then return end
if string.match(v.Name, "Tree") or string.match(v.Name, "Pine")  then
local Dis = (LocalPlayer.Character.HumanoidRootPart.Position - v:GetPivot().Position).Magnitude
if Dis < Options.TreeAuraRange.Value then
if LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Old Axe") then
local args = { v, LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Old Axe"), math.random(1, 100) .. "_10012952131", LocalPlayer.Character.HumanoidRootPart.CFrame }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
elseif LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Good Axe") then
local args = { v, LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Good Axe"), math.random(1, 100) .. "_10012952131", LocalPlayer.Character.HumanoidRootPart.CFrame }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
elseif LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Strong Axe") then
local args = { v, LocalPlayer:FindFirstChild("Inventory"):FindFirstChild("Strong Axe"), math.random(1, 100) .. "_10012952131", LocalPlayer.Character.HumanoidRootPart.CFrame }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(unpack(args))
end
end
end
end
end
end

if Toggles.NoFog.Value and Lighting.FogEnd ~= 500000 then Lighting.FogEnd = 500000 end
if Toggles.FullBright.Value then
if Lighting.Brightness ~= 5 then Lighting.Brightness = 5 end
if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
end

if Toggles.InfSapling.Value then
if Options.SaplingPlace.Value == "Player" then
local args = { workspace:FindFirstChild("Items"):FindFirstChild("Sapling"), LocalPlayer.Character.HumanoidRootPart.Position }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestPlantItem"):InvokeServer(unpack(args))
elseif Options.SaplingPlace.Value == "Campfire" then
local args = { workspace:FindFirstChild("Items"):FindFirstChild("Sapling"), workspace.Map.Campground.MainFire:GetPivot().Position }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestPlantItem"):InvokeServer(unpack(args))
elseif Options.SaplingPlace.Value == "Scarp-Machine" then
local args = { workspace:FindFirstChild("Items"):FindFirstChild("Sapling"), workspace.Map.Campground.Scrapper.Movers.Right.GrindersRight.Position + Vector3.new(0, 2, 0) }
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestPlantItem"):InvokeServer(unpack(args))
end
end
end))

table.insert(Connections,workspace.DescendantAdded:Connect(function(v)
if v:IsA("ProximityPrompt") and Toggles.InstantPr.Value then
v:SetAttribute("Duration",v.HoldDuration)
v.HoldDuration = 0
end
end))

-- STREAMING_CHUNK:Finalizing 99 Nights Menu Options...
local MenuGroup = Tabs.Settings:AddLeftGroupbox('UI Settings')
local UtilityBox = Tabs.Settings:AddRightGroupbox('Hub Utilities')

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle("ShowKeybinds", { Text = "Show Keybinds Overlay", Default = false }):OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.ShowKeybinds.Value
end)


MenuGroup:AddToggle("ShowCustomCursor", {
Text = "Custom Cursor",
Default = true,
Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuGroup:AddDivider()
MenuGroup:AddToggle('PlayNotifySound',{
Text = "Play Notification Sound",
Default = true,
Callback = function(Value) PlaySound = Value end
})
MenuGroup:AddDropdown("NotificationSide", {
Values = { "Left", "Right" },
Default = "Right",
Text = "Notification Side",
Callback = function(Value) Library:SetNotifySide(Value) end,
})
MenuGroup:AddButton('Test Notification',function() Notify("Hello World",2) end)
MenuGroup:AddDivider()
MenuGroup:AddDropdown("DPIDropdown", {
Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
Default = "100%",
Text = "DPI Scale",
Callback = function(Value)
Value = Value:gsub("%%", "")
local DPI = tonumber(Value)
Library:SetDPIScale(DPI)
end,
})
UtilityBox:AddLabel('TheHunterSolo1 - Owner & Main Coder',true)

UtilityBox:AddButton({
    Text = "Unload Hub",
    Func = function()
        game.Players.LocalPlayer:SetAttribute("SupremeLoaded", nil)
        for _, con in pairs(Connections) do con:Disconnect() end
        Library:Unload()


ESPLibrary:Unload()
end
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder("SupremeHub")
SaveManager:SetFolder("SupremeHub/99-NightsinForest")
SaveManager:BuildConfigSection(Tabs['Settings'])
ThemeManager:ApplyToTab(Tabs['Settings'])

Notify("Successfully Loaded for Game |  99 Nights In forest",4)


end

-- STREAMING_CHUNK:Loading DOORS specific core mechanics...
if ReplicatedStorage:FindFirstChild("EntityInfo") or ReplicatedStorage:FindFirstChild("RemotesFolder") or ReplicatedStorage:FindFirstChild("Bricks") then

repeat task.wait() until LocalPlayer.Character

if   getgenv().ScriptLibrary ~= "Linoria" then
getgenv().ScriptLibrary = getgenv().ScriptLibrary or "Linoria"
end

local repo = getgenv().ScriptLibrary == "Obsidian" and 'https://raw.githubusercontent.com/mstudio45/Obsidian/main/' or getgenv().ScriptLibrary == "Linoria" and 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()


local NotifyLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Msdoors/Msdoors.gg/refs/heads/main/Scripts/Msdoors/Notification/Source.lua"))()
task.wait()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/ESPLibrary"))()

local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/projects/refs/heads/main/UI/NotificationLibrary/Source.luau"))()
local NotificationHandler = NotificationLibrary:New({
BackgroundColor = Color3.fromRGB(100, 100, 100),
VerticalPosition = "Top",
HorizontalPosition = "Right",
})

local Options = Library.Options
local Toggles = Library.Toggles
local Connections = {}
local Window = Library:CreateWindow({
Title = LibraryName,
Center = true,
ToggleKeybind = Enum.KeyCode.RightControl,
AutoShow = true,
NotifySide = "Right",
ShowCustomCursor = true,
})
local Notifying = "Library"
local PlaySound = true

local function Notify(txt,duration)
if Notifying == "Library" then
Library:Notify(txt, duration)
elseif Notifying == "Doors" then
NotifyLibrary({
Title = LibraryName,
Description = txt,
Reason = "",
Image = "rbxassetid://6023426923",
Color = Color3.fromRGB(0, 162, 255),
Style = "EVENT",
Duration = duration,
NotifyStyle = "Doors",
})
elseif Notifying == "Supreme" then
NotificationHandler:Create({
Title = "Supreme Hub",
Description = txt,
Duration = duration,
Image = "",
})
end

if PlaySound then
local Sound = Instance.new("Sound",game:GetService("SoundService"))
Sound.SoundId = "rbxassetid://101511361468852"
Sound.PlaybackSpeed = 0.77
Sound.Volume = 2
Sound:Play()
game:GetService("Debris"):AddItem(Sound, 3)
end
end

function AddESP(part,txt,color)
ESPLibrary:AddESP({ Object = part, Text = txt, Color = color })
end

function AddEntityESP(part,txt,color)
if part:IsA("Model") then
while not part.PrimaryPart do
for _, v in pairs(part:GetChildren()) do
if v:IsA("BasePart") then part.PrimaryPart = v end
end
task.wait()
end
if part.PrimaryPart then part.PrimaryPart.Transparency = 0.99 end
if not part:FindFirstChildOfClass("Humanoid") then Instance.new("Humanoid",part) end
end

if part.Name == "FigureRig" or part.Name == "FigureRagdoll" then
part:WaitForChild("Root").Size = Vector3.new(0.001, 0.001, 0.001)
end
ESPLibrary:AddESP({ Object = part, Text = txt, Color = color })
end

function GetLibraryCode()
local CodeLength = game.ReplicatedStorage.GameData.Floor.Value == "Fools" and 10 or 5
local Slot = table.create(CodeLength, "_")
local Paper

for _, plr in pairs(Players:GetPlayers()) do
    local char = plr.Character
    if char then
        Paper = char:FindFirstChild("LibraryHintPaper") or char:FindFirstChild("LibraryHintPaperHard") or 
                plr.Backpack:FindFirstChild("LibraryHintPaper") or plr.Backpack:FindFirstChild("LibraryHintPaperHard")
        if Paper then break end
    end
end

if not Paper then return table.concat(Slot) end

local Hints = LocalPlayer.PlayerGui.PermUI.Hints:GetChildren()

for _, i in pairs(Paper.UI:GetChildren()) do
    if i:IsA("ImageLabel") and i.Name ~= "Image" then
        local Pos = tonumber(i.Name)
        if Pos and Slot[Pos] then
            for _, v in pairs(Hints) do
                if v.Name == "Icon" and v.ImageRectOffset.X == i.ImageRectOffset.X then
                    local Label = v:FindFirstChild("TextLabel")
                    if Label then Slot[Pos] = Label.Text end
                    break
                end
            end
        end
    end
end
return table.concat(Slot)


end

-- STREAMING_CHUNK:Setting up DOORS Lobby Support...
if workspace:FindFirstChild("Lobby") then

local Tabs = {
Home = Window:AddTab('Home', 'house'),
Main = Window:AddTab('Game', "star"),
Settings = Window:AddTab('Settings',"settings"),
}

local HomeBox = Tabs.Home:AddLeftGroupbox('Home')
local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)

HomeBox:AddImage("PlayerFace", { Image = content, Height = 200, })
HomeBox:AddDivider()
HomeBox:AddLabel('Execution Times ' .. (tonumber(executionCount) and tonumber(executionCount) >= 1 and executionCount or "Nan"))

local Tp = Tabs.Main:AddLeftGroupbox("Teleport")
Tp:AddLabel('NO PROGRESS', true)
Tp:AddButton("Teleport Hotel", function()
local Event = game:GetService("ReplicatedStorage").RemotesFolder.CreateElevator
Event:FireServer({ Mods = { "AdminPanel" }, Settings = {}, Destination = "Hotel", FriendsOnly = false, MaxPlayers = "1" })
end)

Tp:AddButton("Teleport Mines", function()
local Event = game:GetService("ReplicatedStorage").RemotesFolder.CreateElevator
Event:FireServer({ Mods = { "AdminPanel" }, Settings = {}, Destination = "Mines", FriendsOnly = false, MaxPlayers = "1" })
end)

Tp:AddButton("Teleport Rooms (FREE)", function()
local Event = game:GetService("ReplicatedStorage").RemotesFolder.CreateElevator
Event:FireServer({ Mods = { "AdminPanel" }, Settings = {}, Destination = "Rooms", FriendsOnly = false, MaxPlayers = "1" })
end)

Tp:AddButton("Teleport Backdoor", function()
local Event = game:GetService("ReplicatedStorage").RemotesFolder.CreateElevator
Event:FireServer({ Mods = { "AdminPanel" }, Settings = {}, Destination = "Backdoor", FriendsOnly = false, MaxPlayers = "1" })
end)

Tp:AddButton("Teleport Outdoors (FREE)", function()
local Event = game:GetService("ReplicatedStorage").RemotesFolder.CreateElevator
Event:FireServer({ Mods = { "AdminPanel" }, Settings = {}, Destination = "Outdoors", FriendsOnly = false, MaxPlayers = "1" })
end)

local MenuGroup = Tabs.Settings:AddLeftGroupbox('UI Settings')
local UtilityBox = Tabs.Settings:AddRightGroupbox('Hub Utilities')

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle("ShowKeybinds", { Text = "Show Keybinds Overlay", Default = false }):OnChanged(function()
Library.KeybindFrame.Visible = Toggles.ShowKeybinds.Value
end)
MenuGroup:AddToggle("ShowCustomCursor", {
Text = "Custom Cursor",
Default = true,
Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuGroup:AddDivider()
MenuGroup:AddToggle('PlayNotifySound',{ Text = "Play Notification Sound", Default = true, Callback = function(Value) PlaySound = Value end })
MenuGroup:AddDropdown("NotificationSide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(Value) Library:SetNotifySide(Value) end, })
MenuGroup:AddDropdown("NotifyWay", { Values = { "Doors", "Library"}, Default = Notifying, Text = "Notification  Library", Callback = function(Value) Notifying = Value end, })
MenuGroup:AddButton('Test Notification',function() Notify("Hello World",2) end)

MenuGroup:AddDropdown("Library", {
Values = { "Obsidian", "Linoria" }, Default = 2, Text = "Library",
Callback = function(Value)
getgenv().ScriptLibrary = tostring(Value)
Notify('Please Unload Script and Execute Again to Take Effect',4)
end,
})

MenuGroup:AddDivider()
MenuGroup:AddDropdown("DPIDropdown", {
Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
Default = "100%", Text = "DPI Scale",
Callback = function(Value)
Value = Value:gsub("%%", "")
Library:SetDPIScale(tonumber(Value))
end,
})
UtilityBox:AddLabel('TheHunterSolo1 - Owner & Main Coder',true)
UtilityBox:AddLabel('rhyan57 - Doors Notification Creator',true)
UtilityBox:AddLabel('FireBacon - ESPLibrary Creator',true)
UtilityBox:AddButton({
Text = "Unload Hub",
Func = function()
LocalPlayer:SetAttribute("SupremeLoaded", nil)
for _, con in pairs(Connections) do con:Disconnect() end
Library:Unload()
ESPLibrary:Unload()
end
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder("SupremeHub")
SaveManager:SetFolder("SupremeHub/DOORSLOBBY")
SaveManager:BuildConfigSection(Tabs['Settings'])
ThemeManager:ApplyToTab(Tabs['Settings'])

Notify("Successfully Loaded for Game |  DOORS Lobby ",4)

else

-- STREAMING_CHUNK:Initializing main DOORS match logic...
local function GetDistanceToPlayer(Pos)
local DisA = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart").Position or workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or Vector3.new(0, 0, 0)
return (DisA - Pos).Magnitude
end

local PathFolder = Instance.new("Folder",workspace)
PathFolder.Name = "PathFolder"

function PathTo(Pos)
local Character = LocalPlayer.Character
local Root = Character and Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character and Character:FindFirstChild("Humanoid")
if not Root or not Humanoid then return end

local p = PathfindingService:CreatePath({
    AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 2, AgentCanSprint = false, AgentMaxSlope = 45, AgentJumpHeight = 0
})
local AdjustedPos = Pos and Pos +Vector3.new(0, 0, 1)

p:ComputeAsync(Root.Position, AdjustedPos)
if  p.Status ~= Enum.PathStatus.Success then return end

for _, waypoint in ipairs(p:GetWaypoints()) do
    if not Toggles.AutoRooms.Value or Library.Unloaded then break end
    local Dist = (Root.Position - waypoint.Position).Magnitude
    if Dist >= 2 then
        Humanoid:MoveTo(waypoint.Position)
        Humanoid.MoveToFinished:Wait()
    end
end


end

AutoClosetTable = { RushMoving = 150, AmbushMoving = 190, A60 = 210, A120 = 120, GlitchRush = 150, GlitchAmbush = 190, BackdoorRush = 160, }
InfCrucfixTable = { RushMoving = 90, AmbushMoving = 160, A60 = 140, A120 = 99, GlitchRush = 150, GlitchAmbush = 110, }

local Firepp = ExecutorSupport.fireproximityprompt
local Require = ExecutorSupport.require
local ReplicateSignal = ExecutorSupport.replicatesignal
local FireTouch = ExecutorSupport.firetouchinterest
local HookMeta = ExecutorSupport.hookmetamethod
local IsNetworkOwner = ExecutorSupport.isnetworkowner

Items = {
["Bandage"] = "Bandage", ["Flashlight"] = "Flash light", ["Battery"] = "Battery", ["BatteryPack"] = "Battery Pack",
["SkeletonKey"] = "Skeleton Key", ["Crucifix"] = "Crucifix", ["Straplight"] = "Strap Light", ["Lockpick"] = "Lockpick",
["Bulklight"] = "Bulk Light", ["Vitamins"] = "Vitamin", ["Shears"] = "Shears", ["LaserPointer"] = "Laser Pointer",
["Candle"] = "Candle", ["Smoothie"] = "Smoothie", ["StarJug"] = "Jug of Bottle", ["StardustPickup"] = "Stardust",
["ChestBoxLocked"] = "Locked Chest", ["ChestBox"] = "Chest", ["Chest_Vine"] = "Chest Vine", ["Toolbox_Locked"] = "Locked Toolbox",
["Toolshed_Small"] = "Toolshed", ["TimerLever"] = "Lever", ["HolyGrenade"] = "Holy Grenade", ["ShieldMini"] = "Mini Shield",
["ShieldBig"] = "Big Shield", ["CrucifixWall"] = "Crucifix", ["Glowsticks"] = "Glow Sticks", ["BandagePack"] = "Bandage Pack",
["AlarmClock"] = "Alarm Clock", ["MinesGenerator"] = "Generator", ["MinesGateButton"] = "Gate Button", ["MouseHole"] = "Louie Mouse",
["StarVial"] = "Star Vial", ["StarBottle"] = "Star Bottle", ["Compass"] = "Compass", ["Lantern"] = "Lantern",
["KeyIron"] = "Iron Key", ["GoldGun"] = "Golden Gun", ["Candy"] = "Candy", ["WaterPump"] = "Water Pump",
["VineGuillotine"] = "Vine Lever", ["Shakelight"] = "Shake Light", ["LibraryHintPaper"] = "Hint Paper", ["LotusPetalPickup"] = "Lotus Petal",
}

local Floor = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("Floor")
local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")
local MainGame = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainUI").Initiator:WaitForChild("Main_Game")
local RemoteListener = MainGame:WaitForChild("RemoteListener")

local RequiredMainGame
local ClientModules = ReplicatedStorage:FindFirstChild("ModulesClient") or ReplicatedStorage:FindFirstChild("ClientModules")

local RemotesFolder = ReplicatedStorage:FindFirstChild("EntityInfo") and ReplicatedStorage:FindFirstChild("EntityInfo")  or ReplicatedStorage:FindFirstChild("Bricks")  and ReplicatedStorage:FindFirstChild("Bricks") or ReplicatedStorage:FindFirstChild("RemotesFolder")
local MotorReplication = RemotesFolder:WaitForChild("MotorReplication")
local CollisionClone
local CamLock = RemotesFolder:WaitForChild("CamLock")

local AnchorArgs
local PL = RemotesFolder:WaitForChild("PL")
local ClutchHeartbeat = RemotesFolder:WaitForChild("ClutchHeartbeat")

local params = RaycastParams.new()
params.FilterDescendantsInstances = {LocalPlayer.Character}

local  SeekPath = Instance.new("Folder",workspace)
SeekPath.Name = "SeekPath"

function ShowSeekPath(v)
local Part = Instance.new("Part", SeekPath)
Part.Size = Vector3.new(1.5, 1.5, 1.5)
Part.Anchored = true
Part.Shape = "Ball"
Part.Position = v.Position
Part.CanCollide = false
Part.Color = Color3.new(0, 1, 0)
Debris:AddItem(Part, 60)
end

function FixBridge(v)
for _, i in pairs(v:GetChildren()) do
if i.Name == "PlayerBarrier" and i.Rotation.X == 180 then
local Barrier = i:Clone()
Barrier.CFrame = CFrame.new(i.Position.X, i.Position.Y, i.Position.Z)
Barrier.CFrame = Barrier.CFrame * CFrame.new(0, -7, 0)
Barrier.Size = Vector3.new(40, 0.1, 40)
Barrier.Transparency = 0.5
Barrier.Color = Color3.new(0.5, 0, 0.5)
Barrier.Material = "ForceField"
Barrier.Parent = v
Barrier.Name = "BridgeBarrier"
Barrier.Anchored = true
Barrier.CanCollide = true
end
end
end

if Require then RequiredMainGame = require(MainGame) end

local getcons = getconnections or get_signal_cons or get_relative_connections
if getcons then
for _, con in pairs(getcons(LocalPlayer.Idled)) do
if con.Disable then con:Disable() end
end
end

-- STREAMING_CHUNK:Configuring Character Respawning Logics...
table.insert(Connections,LocalPlayer.CharacterAdded:Connect(function()
task.wait(1.5)
if LocalPlayer.Character then
MainGame = LocalPlayer.PlayerGui.MainUI.Initiator:WaitForChild("Main_Game")
RemoteListener = MainGame.RemoteListener
params.FilterDescendantsInstances = {LocalPlayer.Character}

if Toggles.NoScenes.Value then
    local Cutscene = RemoteListener:FindFirstChild("Cutscenes") or RemoteListener:FindFirstChild("Cutscenes_")
    Cutscene.Name = "Cutscenes_"
end

if Require then RequiredMainGame = require(MainGame) end


end

if Toggles.Jamming.Value then
if ReplicatedStorage:FindFirstChild("LiveModifiers") and ReplicatedStorage:FindFirstChild("LiveModifiers"):FindFirstChild("Jammin") then
local Jam = LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game").Health.Jam
Jam.Playing = false
local Jamming = game:GetService("SoundService").Main.Jamming
Jamming.Enabled = false
end
end

if Toggles.Godmode.Value and RemotesFolder.Name ~= "RemotesFolder" then
LocalPlayer.Character.Collision.Position -= Vector3.new(0, 4, 0)
end

if Toggles.Dread.Value then
local Dread = LocalPlayer:FindFirstChild("Dread",true) or LocalPlayer:FindFirstChild("_Dread",true)
if Dread then Dread.Name = "_Dread" end
end

if Toggles.Halt.Value then
local Dread = ClientModules.EntityModules:FindFirstChild("Shade",true) or ClientModules.EntityModules:FindFirstChild("_Shade",true)
if Dread then Dread.Name = "_Shade" end
end
end))

local Tabs = {
Home = Window:AddTab('Home', 'house'),
Main = Window:AddTab('Player', "star"),
Bypass = Window:AddTab('Bypass', "ban"),
Visuals = Window:AddTab('Visuals',"eye"),
Floor = Window:AddTab('Floor', "sparkles"),
Settings = Window:AddTab('Settings',"settings"),
}

local PlayerBox = Tabs.Main:AddLeftGroupbox('Player')
local GameBox = Tabs.Main:AddLeftGroupbox('Game Management')
local HotelFloor = Tabs.Floor:AddLeftGroupbox('Hotel')
local MinesFloor = Tabs.Floor:AddRightGroupbox('Mines')
local FoolsFloor = Tabs.Floor:AddRightGroupbox('Fools')
local RoomsFloor = Tabs.Floor:AddLeftGroupbox('Rooms')
local RetroFloor = Tabs.Floor:AddLeftGroupbox('Retro')

local HomeBox = Tabs.Home:AddLeftGroupbox('Home')
local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
HomeBox:AddImage("PlayerFace", { Image = content, Height = 200, })
HomeBox:AddDivider()
HomeBox:AddLabel('Execution Times ' .. (tonumber(executionCount) and tonumber(executionCount) >= 1 and executionCount or "Nan"))

local AutoBox = Tabs.Main:AddRightGroupbox('Auto')
local ReachBox = Tabs.Main:AddRightGroupbox('Reach')
local CameraBox = Tabs.Visuals:AddLeftGroupbox('Camera')
local LightingBox = Tabs.Visuals:AddLeftGroupbox('Lighting')
local ESPBox = Tabs.Visuals:AddRightGroupbox('ESP')
local ESPSettings = Tabs.Visuals:AddRightGroupbox('Settings')
local NotifyBox = Tabs.Visuals:AddRightGroupbox('Notifying')
local BypassEntityBox = Tabs.Bypass:AddLeftGroupbox('Bypass Entities')
local BypassBox = Tabs.Bypass:AddRightGroupbox('Bypass')

-- STREAMING_CHUNK:Setting up ESP Toggles and Layouts...
RetroFloor:AddToggle('AntiLava',{
Text = "Anti Lava", Default = false, Disabled = Floor.Value ~= "Retro" and true or false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "Lava" then v.CanTouch = not Value end end
end
})

FoolsFloor:AddToggle('AntiBanana',{
Text = "Anti Banana", Default = false, Disabled = Floor.Value ~= "Fools" and true or false,
Callback = function(Value)
for _, v in pairs(workspace:GetChildren()) do if v.Name == "BananaPeel" then v.CanTouch = not Value end end
end
})

FoolsFloor:AddToggle('AntiJeff',{
Text = "Anti Jeff", Default = false, Disabled = Floor.Value ~= "Fools" and true or false,
Callback = function(Value)
local v = workspace:FindFirstChild("JeffTheKiller")
if v.Name == "JeffTheKiller" then
repeat task.wait() until v.PrimaryPart and isnetworkowner(v.PrimaryPart)
for _, i in pairs(v:GetChildren()) do if i:IsA("BasePart") then i.CanTouch = Value and false or true end end
v.Humanoid.Health = Value and 0 or 100
end
end
})

GameBox:AddButton({ Text = "Revive", DoubleClick = true, Func = function() RemotesFolder.Revive:FireServer() end })
GameBox:AddButton({ Text = "Play Again", DoubleClick = true, Func = function() RemotesFolder.PlayAgain:FireServer() end })

local Pressed = false
GameBox:AddButton({
Text = "Reset",
DoubleClick = true,
Func = function()
Pressed = not Pressed
if not Pressed then
if RemotesFolder:FindFirstChild("Underwater") then RemotesFolder.Underwater:FireServer(false) end
return
end
if ReplicateSignal then
replicatesignal(LocalPlayer.Kill)
else
Notify("Double Click to stop", 5)
task.spawn(function()
while Pressed and LocalPlayer:GetAttribute("Alive") ~= false do
if RemotesFolder:FindFirstChild("Underwater") then RemotesFolder.Underwater:FireServer(true) end
task.wait()
end
if RemotesFolder:FindFirstChild("Underwater") then RemotesFolder.Underwater:FireServer(false) end
Pressed = false
end)
end
end
})

GameBox:AddButton({ Text = "Lobby", DoubleClick = true, Func = function() RemotesFolder.Lobby:FireServer() end })

FoolsFloor:AddToggle('InfRevive',{ Text = "Infinite Revive", Disabled = Floor.Value ~= "Fools" and RemotesFolder.Name ~= "Bricks" and true or false, Default = false })
FoolsFloor:AddToggle('DeleteSeekFE',{
Text = "Delete Seek (FE)", Default = false, Disabled = Floor.Value ~= "Fools" and RemotesFolder.Name ~= "Bricks" and true or false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "TriggerEventCollision" then
Notify("Deleting Seek",3)
for _, i  in pairs(v:GetChildren()) do
if i.Name == "Collision" then
if FireTouch then firetouchinterest(LocalPlayer.Character.HumanoidRootPart, i, 0) end
end
end
task.wait(0.5)
if v:FindFirstChild("Collision") then Notify("Failed to remove Seek", 3) else Notify("Deleted Seek Successfully", 3) end
end
end
end
end
})

RetroFloor:AddToggle('AntiWall',{
Text = "Anti SeekWall", Default = false, Disabled = Floor.Value ~= "Retro" and true or false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "ScaryWall" then for _, i in pairs(v:GetChildren()) do if i:IsA("BasePart") then i.CanTouch = not Value end end end
end
end
})

RetroFloor:AddToggle('RealBridge',{
Text = "Show Real Bridge", Default = false, Disabled = Floor.Value ~= "Retro" and true or false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "Bridge" then if v.CanCollide == false then v.Transparency = Value and 1 or 0 end end
end
end
})

local Figures = {}
MinesFloor:AddToggle('DeleteFigureFE',{
Text = "Delete Figure (FE)", Default = false, Disabled = Floor.Value ~= "Mines" and RemotesFolder.Name ~= "Bricks" and true or false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "FigureRig" or v.Name == "FigureRagdoll" then table.insert(Figures,v) end
end
end
})

MinesFloor:AddToggle('ShowPath',{
Text = "Show Seek Path", Default = false, Disabled = Floor.Value ~= "Mines" and true or false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "SeekGuidingLight" then ShowSeekPath(v) end end
else SeekPath:ClearAllChildren() end
end
})

MinesFloor:AddToggle('FixBrokenBridge',{
Text = "Fix Broken Bridge", Default = false, Disabled = Floor.Value ~= "Mines" and true or false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "Bridge" then FixBridge(v) end end
else
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "BridgeBarrier" then v:Destroy() end end
end
end
})

local DuckBoards = {}
local Nodes = {}

if Require then
local Control = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls().GetMoveVector
end
MinesFloor:AddToggle('AutoMinecart',{
Text = "Auto Minecart", Risky = true, Default = false, Disabled = Floor.Value ~= "Mines" and true or false,
Callback = function(Value)
if Value then
for _, v in workspace.CurrentRooms:GetDescendants() do
if v.Name == "DuckBoard" then table.insert(DuckBoards, v) end
if string.find(v.Name, "MinecartNode") then table.insert(Nodes, v) end
end
else
require(LocalPlayer.PlayerScripts.PlayerModule):GetControls().GetMoveVector = Control
table.clear(Nodes)
table.clear(DuckBoards)
end
end
})

local Anchors = {}

MinesFloor:AddToggle('AutoAnchorSolver',{
Text = "Auto Anchor Solver", Default = false, Disabled = Floor.Value ~= "Mines" and true or false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "MinesAnchor" then table.insert(Anchors,v) end end
end
end
})

MinesFloor:AddToggle('AntiSeekFlood',{
Text = "Anti Seek Flood", Default = false, Disabled = Floor.Value ~= "Mines" and true or false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "SeekFloodline" then v.CanCollide = Value end end
end
})

RoomsFloor:AddToggle('AutoRooms',{
Text = "Auto A-1000", Disabled = Floor.Value ~= "Rooms" and true or false, Default = false,
Callback = function(Value)
if not Value then
PathFolder:ClearAllChildren()
if LocalPlayer.Character then
LocalPlayer.Character.Collision.Size = Vector3.new(5.5,3,3)
LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
PathActive = false
end
end
end
})

if (getrawmetatable or debug.getmetatable) and (setreadonly or make_writeable) and newcclosure then
local getmt = getrawmetatable or debug.getmetatable
local setro = setreadonly or (make_writeable and function(t, b) if b then make_writeable(t) else make_readonly(t) end end)
local mt = getmt(game)
local oldIndex = mt.__index
setro(mt, false)
mt.__index = newcclosure(function(t, k)
if not checkcaller() and k == "MoveDirection" and t:IsA("Humanoid") then
local char = LocalPlayer.Character
if char and Toggles.AutoRooms.Value and not char:GetAttribute("Hiding") then return Vector3.new(0, 0, 1) end
end
return oldIndex(t, k)
end)
setro(mt, true)
end

RoomsFloor:AddToggle('IgnoreA60',{ Text = "Ignore A-60", Disabled = Floor.Value ~= "Rooms" and true or false, })

ESPSettings:AddToggle('ShowDistance',{ Text = "Show ESP Distance", Default = true, Callback = function(Value) ESPLibrary:SetShowDistance(Value) end })
ESPSettings:AddToggle('ShowTracers',{ Text = "Show ESP Tracers", Default = true, Callback = function(Value) ESPLibrary:SetTracers(Value) end })
ESPSettings:AddToggle('ShowRainbow',{ Text = "Show ESP Rainbow", Default = false, Callback = function(Value) ESPLibrary:SetRainbow(Value) end })

ESPSettings:AddDropdown("SetESPMode", { Text = "Set ESP Mode", Values = {"Highlight/Text", "Text", "Highlight"}, Default = 1, Multi = false, Callback = function(Value) ESPLibrary:SetESPMode(Value) end })
ESPSettings:AddDropdown("SetFont", {
Text = "Set Font",
Values = { "Legacy", "Arial", "ArialBold", "SourceSans", "SourceSansBold", "SourceSansLight", "SourceSansItalic", "Bodoni", "Garamond", "Cartoon", "Code", "Highway", "SciFi", "Arcade", "Fantasy", "Antique", "Gotham", "GothamMedium", "GothamBold", "GothamBlack", "AmaticSC", "Bangers", "Creepster", "DenkOne", "FredokaOne", "IndieFlower", "LuckiestGuy", "Michroma", "Nunito", "Oswald", "PatrickHand", "PermanentMarker", "Roboto", "RobotoCondensed", "RobotoMono", "Sarpanch", "SpecialElite", "TitilliumWeb", "Ubuntu" },
Default = 35, Multi = false, Callback = function(Value) ESPLibrary:SetFont(Value) end
})

-- STREAMING_CHUNK:Configuring Player movement modifiers...
PlayerBox:AddSlider("MovementSpeed", { Text = "Movement Speed", Default = 15, Min = 15, Max = 21, Rounding = 1, Compact = false, Callback = function(Value) end, Tooltip = "Walking Speed", })
PlayerBox:AddToggle('EnableMovementSpeed',{ Text = "Enable Movement Speed", Default = false, Callback = function(Value) if not Value then LocalPlayer.Character.Humanoid.WalkSpeed = 15 end end })
PlayerBox:AddSlider("ClimbingSpeed", { Text = "Climbing Speed", Default = 15, Min = 15, Max = 30, Rounding = 1, Compact = false, Callback = function(Value) end, Tooltip = "Climbing Speed", })
PlayerBox:AddToggle('EnableClimbingSpeed',{ Text = "Enable Climbing Speed", Default = false, Callback = function(Value) if not Value then LocalPlayer.Character.Humanoid.WalkSpeed = 15 end end })
PlayerBox:AddDivider()

local OldAccel
PlayerBox:AddToggle('NoAcc',{
Text = "No Slipping", Default = false,
Callback = function(Value)
if Value then OldAccel = LocalPlayer.Character.HumanoidRootPart.CustomPhysicalProperties
else
if OldAccel then LocalPlayer.Character.HumanoidRootPart.CustomPhysicalProperties = OldAccel; OldAccel = nil end
end
end
})
PlayerBox:AddToggle('NoClip',{
Text = "No Clip", Default = false, Tooltip = "You Can Move Through Wall",
Callback = function(Value)
if not Value then
for _, v in pairs(LocalPlayer.Character:GetChildren()) do 
    if v.Name ~= "CollisionClone" and v.Name ~= "Collision" and v:IsA("BasePart") then 
        v.CanCollide = true 
    end 
end
if LocalPlayer.Character:FindFirstChild("Collision") then
    LocalPlayer.Character.Collision.CanCollide = true
    if LocalPlayer.Character.Collision:FindFirstChild("CollisionCrouch") then 
        LocalPlayer.Character.Collision.CollisionCrouch.CanCollide = true 
    end
end
end
end
}):AddKeyPicker("NoclipKeybind", { Default = "N", SyncToggleState = true, Mode ="Toggle", Text = "No Clip", NoUI = false, Callback = function(Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })

PlayerBox:AddToggle('Flight',{
Text = "Flight", Default = false,
Callback = function(Value)
if not Value then
if LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlightVelocity") then LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlightVelocity"):Destroy() end
end
end
}):AddKeyPicker("FlightKeybind", { Default = "F", SyncToggleState = true, Mode ="Toggle", Text = "Flight", NoUI = false, Callback = function(Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })

PlayerBox:AddSlider("FlightSpeed", { Text = "Flight Speed", Default = 15, Min = 15, Max = 21, Rounding = 1, Compact = false, Callback = function(Value) end, Tooltip = "Flight Speed", })
PlayerBox:AddDivider()
PlayerBox:AddToggle('EnableJump',{ Text = "Enable Jumping", Default = false, Tooltip = "You Can Move Jump", Callback = function(Value) if not Value then LocalPlayer.Character:SetAttribute("CanJump",false) end end })
PlayerBox:AddToggle('EnableSlide',{ Text = "Enable Sliding", Default = false, Tooltip = "You Can Slide", Callback = function(Value) if not Value then LocalPlayer.Character:SetAttribute("Sliding",false) end end })
PlayerBox:AddDivider()

PlayerBox:AddToggle('InstaInteract',{
Text = "Instant Interact", Default = false, Tooltip = "Interactions are Instantly",
Callback = function(Value)
if Value then
for _, v in ipairs(workspace:GetDescendants()) do
if v:IsA("ProximityPrompt") then v:SetAttribute("Duration",v.HoldDuration); v.HoldDuration = 0 end
end
else
for _, v in ipairs(workspace:GetDescendants()) do
if v:IsA("ProximityPrompt") then v.HoldDuration = v:GetAttribute("Duration") or 0 end
end
end
end
})
PlayerBox:AddToggle('InfJump',{ Text = "Infinite Jump", Default = false })

if UserInputService.KeyboardEnabled then
local d = false
table.insert(Connections, UserInputService.JumpRequest:Connect(function()
if Toggles.InfJump.Value and not d and LocalPlayer.Character then
d = true; LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping, true); task.wait(0.1); d = false
end
end))
elseif UserInputService.TouchEnabled then
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function()
task.wait(1)
if LocalPlayer.PlayerGui.MainUI.MainFrame.MobileButtons:FindFirstChild("JumpButton") then
table.insert(Connections, LocalPlayer.PlayerGui.MainUI.MainFrame.MobileButtons.JumpButton.MouseButton1Click:Connect(function()
if Toggles.InfJump.Value and LocalPlayer.Character then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping, true) end
end))
end
end))
if LocalPlayer.PlayerGui.MainUI.MainFrame.MobileButtons:FindFirstChild("JumpButton") then
table.insert(Connections, LocalPlayer.PlayerGui.MainUI.MainFrame.MobileButtons.JumpButton.MouseButton1Click:Connect(function()
if Toggles.InfJump.Value and LocalPlayer.Character then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping, true) end
end))
end
end

PlayerBox:AddDivider()
PlayerBox:AddToggle('FastClosetExit',{ Text = "Fast Closet Exit", Default = false })
PlayerBox:AddDivider()

PlayerBox:AddToggle('Godmode',{
Text = "Godmode", Default = false, Tooltip = "Can Lagback you or not work", Risky = true,
Callback = function(Value)
if Value and RemotesFolder.Name ~= "RemotesFolder" then LocalPlayer.Character.Collision.Position -= Vector3.new(0, 4, 0) end
if Value and RemotesFolder.Name == "RemotesFolder" then LocalPlayer.Character:PivotTo(LocalPlayer.Character.CollisionPart.CFrame * CFrame.new(0, -2,0)) end
if not Value and RemotesFolder.Name == "RemotesFolder" then
LocalPlayer.Character.Humanoid.HipHeight = 2.4
LocalPlayer.Character.Collision.Size = Vector3.new(5.5, 3, 3)
LocalPlayer.Character.LowerTorso.Root.C1 = CFrame.new(Vector3.new(0, 0, 0))
LocalPlayer.Character.Collision.CollisionCrouch.Size = Vector3.new(5.5, 3, 3)
LocalPlayer.Character:PivotTo(LocalPlayer.Character.CollisionPart.CFrame * CFrame.new(0, 2,0))
end
if not Value and RemotesFolder.Name ~= "RemotesFolder" then LocalPlayer.Character.Collision.Position = LocalPlayer.Character.HumanoidRootPart.Position end
end
}):AddKeyPicker("GodmodeKeybind", { Default = "G", SyncToggleState = true, Mode ="Toggle", Text = "Godmode", NoUI = false, Callback = function(Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })

local PromptIgnore = { HidePrompt = true, ClimbPrompt = true, PropPrompt = true, InteractPrompt = true, RiftPrompt = true, StarRiftPrompt = true, NoHidingLilBro = true, AnimatePrompt = true, RevivePrompt = true, }
Interactions = {}

AutoBox:AddToggle("AutoInteract",{
Text = "Auto Interact", Default = false, Tooltip = "Automatically Interacts with things when near",
Callback = function(Value)
if Value then
for _, v in ipairs(workspace.CurrentRooms:GetDescendants()) do
if v:IsA("ProximityPrompt") then
if not (PromptIgnore[v.Name] or v.Parent.Name == "Padlock" or v.Parent:GetAttribute("JeffShop")) or v.Parent.Name == "RetroWardrobe" or v.Parent.Name == "KeyObtainFake" then
table.insert(Interactions, v)
end
end
end
else table.clear(Interactions) end
end
}):AddKeyPicker("AutoInteractKeybind", { Default = "R", SyncToggleState = true, Mode = Library.IsMobile and "Toggle" or "Hold", Text = "Auto Interact", NoUI = false, Callback = function(Value) print("[cb] Keybind clicked!", Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })

HidingPlaces = {
["Wardrobe"] = "Closet", ["Rooms_Locker"] = "Locker", ["Rooms_Locker_Fridge"] = "Fridge", ["Locker_Large"] = "Locker",
["Backdoor_Wardrobe"] = "Closet", ["Bed"] = "Bed", ["Double_Bed"] = "Double Bed", ["Toolshed"] = "Closet",
["RetroWardrobe"] = "Closet", ["CircularVent"] = "Vent", ["Double_Bed"] = "Double_Bed",
}
Closets = {}

function GetNearestHidingSpot()
local Closest = nil
local MaxDistance = math.huge
if #Closets > 0 then
for _, v in pairs(Closets) do
if v:FindFirstChild("HiddenPlayer") and v.HiddenPlayer.Value == nil then
local Pivot = v:GetPivot()
if Pivot then
local Dis = GetDistanceToPlayer(Pivot.Position)
if Dis < MaxDistance then Closest = v; MaxDistance = Dis end
end
end
end
end
return Closest
end

AutoBox:AddSlider("AutoInteractDelay", { Text = "Auto Interact Delay", Default = 0.05, Min = 0, Max = 0.2, Rounding = 2, Compact = false, Callback = function(Value) end, })
AutoBox:AddSlider("AutoInteractreach", { Text = "Auto Interact Range", Default = 7, Min = 7, Max = 12, Rounding = 2, Compact = false, Callback = function(Value) end, })
AutoBox:AddDivider()

AutoBox:AddToggle('AutoLibraryCode',{ Text = "Auto Library Code", Disabled = Floor.Value ~= "Hotel" and RemotesFolder.Name ~= "Bricks" and Floor.Value ~= "Fools" and Floor.Value ~= "Fools26" and true or false, Default = false, })
AutoBox:AddToggle('BruteForceLibCode',{ Text = "Bruteforce Library Code", Disabled = Floor.Value ~= "Hotel" and RemotesFolder.Name ~= "Bricks" and Floor.Value ~= "Fools" and Floor.Value ~= "Fools26" and true or false, Default = false, })
AutoBox:AddToggle('AutoHeartbeat',{ Text = "Auto Heartbeat Minigame", Default = false })

local function Breaker(part)
local label = part:WaitForChild("SurfaceGui"):WaitForChild("Frame"):WaitForChild("Code")
local function run()
task.wait(0.05)
if not Toggles.AutoBreaker.Value then return end
if Method == "Exploit" then RemotesFolder.EBF:FireServer(); return end
if Method == "Legit" then
local target = tonumber(label.Text)
if target then
for _, v in part:GetChildren() do
if v.Name == "BreakerSwitch" and v:GetAttribute("ID") == target then
local trans = part:WaitForChild("SurfaceGui"):WaitForChild("Frame"):WaitForChild("Code"):WaitForChild("Frame").BackgroundTransparency
local pc = v:FindFirstChild("PrismaticConstraint")
local light = v:FindFirstChild("Light")
local sound = v:FindFirstChild("Sound")
if trans == 0 then
if v:GetAttribute("Enabled") then return end
v:SetAttribute("Enabled", true)
if pc then pc.TargetPosition = -0.2 end
if light then
light.Material = Enum.Material.Neon
local spark = light:FindFirstChild("Spark", true)
if spark then spark:Emit(1) end
end
if sound then sound:Play() end
elseif trans == 1 then
if not v:GetAttribute("Enabled") then return end
v:SetAttribute("Enabled", false)
if pc then pc.TargetPosition = 0.2 end
if light then light.Material = Enum.Material.Glass end
if sound then sound:Play() end
end
break
end
end
end
end
end
label:GetPropertyChangedSignal("Text"):Connect(run)
run()
end

AutoBox:AddDivider()
AutoBox:AddToggle('AutoBreaker',{
Text = "Auto Breaker Minigame", Disabled = Floor.Value == "Mines" and Floor.Value == "Retro" and Floor.Value == "Outdoors" and true or false, Default = false,
Callback = function(Value)
if Value then for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "ElevatorBreaker" then Breaker(v) end end end
end
})

AutoBox:AddDropdown("AutoBreakerBoxMethod", { Values = { "Legit", "Exploit" }, Default = Method, Disabled = Floor.Value == "Mines" and Floor.Value == "Retro" and Floor.Value == "Outdoors" and true or false, Text = "Auto Breaker Method", Callback = function(Value) Method = Value end, })
AutoBox:AddDivider()

AutoBox:AddToggle('AutoHiding',{ Text = "Auto Hiding Spot", Default = false }):AddKeyPicker("AutoHideKeybind", { Default = "Q", SyncToggleState = true, Mode = "Toggle", Text = "Auto Hiding Spot", NoUI = false, Callback = function(Value) print("[cb] Keybind clicked!", Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })

-- STREAMING_CHUNK:Configuring Visual Toggles...
local OldFogEnd
LightingBox:AddToggle('NoFog',{
Text = "No Fog", Default = false, Tooltip = "No fog",
Callback = function(Value)
if not Value then for _, v in pairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") then v.Density = 0.94 end end end
if Value then OldFogEnd = Lighting.FogEnd
else if OldFogEnd then Lighting.FogEnd = OldFogEnd; OldFogEnd = nil end end
end
})

LightingBox:AddToggle('FullBright',{
Text = "Fullbright", Default = false, Tooltip = "Make you see in darkness",
Callback = function(Value)
if not Value then
Lighting.Ambient = Color3.fromRGB(0, 0, 0)
Lighting.GlobalShadows = true
for _, v in pairs(workspace.CurrentRooms:GetChildren()) do v:SetAttribute("Ambient", v:GetAttribute("OldAmbient")) end
end
end
})

local DoorColor = Color3.new(0, 1, 1)
local HidingPlaceColor = Color3.new(0, 0.4, 0)
local LeverColor = Color3.new(0.5, 0.5, 0.5)
local BookColor = Color3.new(0, 0, 0.5)
local BreakerColor = Color3.new(0.5, 1, 0.5)
local ItemsColor = Color3.new(1, 0.5, 1)
local GoldColor = Color3.new(1,1,0)

ESPBox:AddToggle('Door',{
Text = "Door", Default = false,
Callback = function(Value)
if Value then
local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom")))
local nextRoom = workspace.CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom") + 1))
if nextRoom and nextRoom:FindFirstChild("Door") and nextRoom.Door:FindFirstChild("Door") then
local Doo = nextRoom.Door.Door
if Doo:FindFirstChild("CrossBoards") then AddESP(Doo.CrossBoards, "", DoorColor) end
AddESP(Doo, "Door " .. (Doo.Parent:GetAttribute("RoomID") or ""), DoorColor)
end
if currentRoom and currentRoom:FindFirstChild("Door") and currentRoom.Door:FindFirstChild("Door") then
if currentRoom.Door.Door:FindFirstChild("CrossBoards") then AddESP(currentRoom.Door.Door.CrossBoards, "", DoorColor) end
AddESP(currentRoom.Door.Door, "Door " .. (currentRoom.Door:GetAttribute("RoomID") or ""), DoorColor)
end
else
for _, v in ipairs(workspace.CurrentRooms:GetChildren()) do
if v:FindFirstChild("Door") and v.Door:FindFirstChild("Door") then
ESPLibrary:RemoveESP(v.Door.Door)
if v.Door.Door:FindFirstChild("CrossBoards") then ESPLibrary:RemoveESP(v.Door.Door.CrossBoards) end
end
end
end
end
}):AddColorPicker("ColorPicker2", { Default = DoorColor, Title = "Door ESP Color", Callback = function(Value) DoorColor = Value; Toggles.Door:SetValue(false); Toggles.Door:SetValue(true) end, })

ESPBox:AddToggle('Objective',{
Text = "Objective", Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
local Bro = Items[v.Name]
if Bro then AddESP(v, Bro,ItemsColor) end
if v.Name == "MinesAnchor" then AddESP(v, "Anchor " .. v:WaitForChild("Sign").TextLabel.Text, ItemsColor) end
if v.Name == "KeyObtain" then repeat task.wait() until v.PrimaryPart; AddESP(v, "Key", Color3.new(0, 1, 1)) end
end
else
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if Items[v.Name] then ESPLibrary:RemoveESP(v) end
if v.Name == "MinesAnchor" then ESPLibrary:RemoveESP(v) end
if v.Name == "KeyObtain" then ESPLibrary:RemoveESP(v) end
end
end
end
}):AddColorPicker("ColorPicker3", { Default = ItemsColor, Title = "Objective ESP Color", Callback = function(Value) ItemsColor = Value; Toggles.Objective:SetValue(false); Toggles.Objective:SetValue(true) end, })

for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if HidingPlaces[v.Name] then table.insert(Closets, v) end end

ESPBox:AddToggle('HidingPlace',{
Text = "Hiding Place", Default = false,
Callback = function(Value)
if Value then
local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom")))
for _, v in pairs(Closets) do
local Nam = HidingPlaces[v.Name]
if Nam and currentRoom and v:IsDescendantOf(currentRoom) then AddESP(v, Nam, HidingPlaceColor) end
end
else
for _, v in pairs(Closets) do if HidingPlaces[v.Name] then ESPLibrary:RemoveESP(v) end end
end
end
}):AddColorPicker("ColorPicker3", { Default = HidingPlaceColor, Title = "Hiding Place ESP Color", Callback = function(Value) HidingPlaceColor = Value; Toggles.HidingPlace:SetValue(false); Toggles.HidingPlace:SetValue(true) end, })

ESPBox:AddToggle('GateLever',{
Text = "Gate Lever", Default = false,
Callback = function(Value)
local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom")))
if Value and currentRoom then
local Lever = currentRoom:FindFirstChild("LeverForGate",true)
if Lever then AddESP(Lever, "Gate Lever", LeverColor) end
elseif currentRoom then
local Lever = currentRoom:FindFirstChild("LeverForGate",true)
if Lever then ESPLibrary:RemoveESP(Lever) end
end
end
}):AddColorPicker("ColorPicker3", { Default = LeverColor, Title = "Gate Lever ESP Color", Callback = function(Value) LeverColor = Value; Toggles.GateLever:SetValue(false); Toggles.GateLever:SetValue(true) end, })

ESPBox:AddToggle('Books',{
Text = "Library Book", Default = false,
Callback = function(Value)
if Value then for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "LiveHintBook" then AddESP(v, "Library Book",BookColor) end end
else for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "LiveHintBook" then ESPLibrary:RemoveESP(v) end end end
end
}):AddColorPicker("ColorPicker3", { Default = BookColor, Title = "Library ESP Color", Callback = function(Value) BookColor = Value; Toggles.Books:SetValue(false); Toggles.Books:SetValue(true) end, })

ESPBox:AddToggle('Breakers',{
Text = "Breaker", Default = false,
Callback = function(Value)
if Value then for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "LiveBreakerPolePickup" then AddESP(v, "Breaker",BreakerColor) end end
else for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "LiveBreakerPolePickup" then ESPLibrary:RemoveESP(v) end end end
end
}):AddColorPicker("ColorPicker3", { Default = BreakerColor, Title = "Breaker ESP Color", Callback = function(Value) BreakerColor = Value; Toggles.Breakers:SetValue(false); Toggles.Breakers:SetValue(true) end, })

ESPBox:AddToggle('Gold',{
Text = "Gold", Default = false,
Callback = function(Value)
if Value then for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "GoldPile" then AddESP(v, "Gold " .. (v:GetAttribute("GoldValue") or ""), GoldColor) end end
else for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "GoldPile" then ESPLibrary:RemoveESP(v) end end end
end
}):AddColorPicker("ColorPicker3", { Default = GoldColor, Title = "Gold ESP Color", Callback = function(Value) GoldColor = Value; Toggles.Gold:SetValue(false); Toggles.Gold:SetValue(true) end, })

local EntityColor = Color3.new(1, 0, 0)
local roomEntities = { ["Snare"] = "Snare", ["FigureRig"] = "Figure", ["FigureRagdoll"] = "Figure", ["GrumbleRig"] = "Grumble", ["Groundskeeper"] = "Ground Keeper", ["MandrakeLive"] = "Man Drake", ["LiveEntityBramble"] = "Bramble" }
local workspaceEntities = { ["RushMoving"] = "Rush", ["AmbushMoving"] = "Ambush", ["A60"] = "A-60", ["A120"] = "A-120", ["GlitchRush"] = "Glitch Rush", ["GlitchAmbush"] = "Glitch Ambush", ["Eyes"] = "Eyes", ["Lookman"] = "Eyes", ["BackdoorRush"] = "Blitz", ["BackdoorLookman"] = "Lookman", ["JeffTheKiller"] = "Jeff" }

ESPBox:AddToggle('Entity', {
Text = "Entity", Default = false,
Callback = function(Value)
task.spawn(function()
if Value then
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
local label = roomEntities[v.Name]
if label then
if v.Name == "Snare" then if v:FindFirstChild("Hitbox") then AddEntityESP(v, label, EntityColor) end
else AddEntityESP(v, label, EntityColor) end
elseif v.Name == "DoorFake" and v.Parent and v.Parent.Name == "SideroomDupe" then AddEntityESP(v:WaitForChild("Door", 3), "Dupe", EntityColor)
elseif v.Name == "GiggleCeiling" then
task.spawn(function()
local t = 0
repeat task.wait(0.1) t = t + 0.1 until t > 2 or v:FindFirstChild("Hitbox")
if v:FindFirstChild("Hitbox") then AddEntityESP(v, "Giggle", EntityColor) end
end)
end
end
for _, v in pairs(workspace:GetChildren()) do
local label = workspaceEntities[v.Name]
if label then AddEntityESP(v, label, EntityColor) end
end
else
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if roomEntities[v.Name] or v.Name == "GiggleCeiling" or v.Name == "DoorFake" then
if v.Name == "DoorFake" then
local door = v:FindFirstChild("Door")
if door then ESPLibrary:RemoveESP(door) end
end
ESPLibrary:RemoveESP(v)
end
end
for _, v in pairs(workspace:GetChildren()) do
if workspaceEntities[v.Name] then ESPLibrary:RemoveESP(v) end
end
end
end)
end
}):AddColorPicker("ColorPicker3", { Default = EntityColor, Title = "Entity ESP Color", Callback = function(Value) EntityColor = Value; if Toggles.Entity.Value then Toggles.Entity:SetValue(false); Toggles.Entity:SetValue(true) end end, })

CameraBox:AddSlider("FOV", { Text = "FOV", Default = 70, Min = 70, Max = 120, Rounding = 1, Compact = false, Callback = function(Value) end, Tooltip = "Field of View", })
CameraBox:AddDivider()
CameraBox:AddToggle('ThirdPerson',{ Text = "Third Person", Default = false }):AddKeyPicker("ThirdpersonKeybind", { Default = "T", SyncToggleState = true, Mode = "Toggle", Text = "Third Person", NoUI = false, Callback = function(Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })
CameraBox:AddSlider("X", { Text = "X", Default = 2, Min = -10, Max = 10, Rounding = 1, Compact = false, Callback = function(Value) end, Tooltip = "X", })
CameraBox:AddSlider("Y", { Text = "Y", Default = 0, Min = -10, Max = 10, Rounding = 1, Compact = false, Callback = function(Value) end, Tooltip = "Y", })
CameraBox:AddSlider("Z", { Text = "Z", Default = 4, Min = -10, Max = 10, Rounding = 1, Compact = false, Callback = function(Value) end, Tooltip = "Z", })

CameraBox:AddToggle('NoCamShake',{ Text = "No Camera Shake", Disabled = not require and true or false, })

local OldMinZoom = LocalPlayer.CameraMinZoomDistance
local OldMaxZoom  = LocalPlayer.CameraMaxZoomDistance

CameraBox:AddToggle('Freecam',{
Text = "Freecam", Default = false,
Callback = function(Value)
if not Value then
local fcPart = workspace:FindFirstChild("FreecamPart")
if fcPart then
fcPart:Destroy()
local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if root then root.Anchored = false end
LocalPlayer.CameraMinZoomDistance = LocalPlayer:GetAttribute("fc_om") or 0.5
LocalPlayer.CameraMaxZoomDistance = LocalPlayer:GetAttribute("fc_ox") or 128
end
end
end
}):AddKeyPicker("FreecamKeybind", { Default = "B", SyncToggleState = true, Mode ="Toggle" , Text = "Freecam", NoUI = false, Callback = function(Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })

CameraBox:AddToggle('NoScenes',{
Text = "No Cutscenes", Default = false,
Callback = function(Value)
local Cutscene = RemoteListener:FindFirstChild("Cutscenes") or RemoteListener:FindFirstChild("Cutscenes_")
if Value then Cutscene.Name = "Cutscenes_" else Cutscene.Name = "Cutscenes" end
end
})

NotifyBox:AddDropdown("Notify", { Values = { "Rush","Ambush","GlitchRush","GlitchAmbush","A-60","A-120","Eyes","Blitz","Lookman","Jeff"}, Default = 1, Multi = true, Text = "Choose to Notify", Callback = function(Value) end, })
NotifyBox:AddToggle('NotifySpawn',{
Text = "Notify Entity", Default = false, Tooltip = "Notify Entity In Spawn",
Callback = function(Value)
if Value then
if workspace:FindFirstChild("RushMoving") and Options.Notify.Value == "Rush" then Notify("Rush has Spawned",5) end
if workspace:FindFirstChild("AmbushMoving") and Options.Notify.Value["Ambush"] then Notify("Ambush has Spawned",5) end
if workspace:FindFirstChild("A60") and Options.Notify.Value["A-60"] then Notify("A-60 has Spawned",5) end
if workspace:FindFirstChild("GlitchRush") and Options.Notify.Value["GlitchRush"] then Notify("Glitch Rush has Spawned",5) end
if workspace:FindFirstChild("GlitchAmbush") and Options.Notify.Value["GlitchAmbush"] then Notify("Glitch Ambush has Spawned",5) end
if workspace:FindFirstChild("Eyes") and Options.Notify.Value["Eyes"] then Notify("Eyes has Spawned",5) end
if workspace:FindFirstChild("Lookman") and Options.Notify.Value["Eyes"] then Notify("Eyes has Spawned",5) end
if workspace:FindFirstChild("BackdoorRush") and Options.Notify.Value["Blitz"] then Notify("Blitz has Spawned",5) end
if workspace:FindFirstChild("BackdoorLookman") and Options.Notify.Value["Lookman"] then Notify("Lookman has Spawned",5) end
if workspace:FindFirstChild("A120") and Options.Notify.Value["A-120"] then Notify("A-120 has Spawned",5) end
if workspace:FindFirstChild("JeffTheKiller") and Options.Notify.Value["Jeff"] then Notify("Jeff has Spawned",5) end
end
end
})

local FakeScreech = Instance.new("RemoteEvent",RemotesFolder)
FakeScreech.Name = "Screech_"
local FakeA90 = Instance.new("RemoteEvent",RemotesFolder)
FakeA90.Name = "A90_"

local gotToggled = false
local gotToggled2 = false

BypassEntityBox:AddToggle('Screech',{
Text = "Anti Screech Damage", Default = false,
Callback = function(Value)
if Value then gotToggled = true; RemotesFolder.Screech.Name = "Screech_"; FakeScreech.Name = "Screech"
else if gotToggled then RemotesFolder["Screech_"].Name = "Screech"; FakeScreech.Name = "Screech_" end end
end
})
BypassEntityBox:AddToggle('A90',{
Text = "Anti A90 Damage", Default = false,
Callback = function(Value)
if Value then gotToggled2 = true; RemotesFolder.A90.Name = "A90_"; FakeA90.Name = "A90"
else if gotToggled2 then RemotesFolder["A90_"].Name = "A90"; FakeA90.Name = "A90_" end end
end
})
BypassEntityBox:AddToggle('Dread',{
Text = "Anti Dread", Default = false,
Callback = function(Value)
if Value then local Dread = LocalPlayer:FindFirstChild("Dread",true) or LocalPlayer:FindFirstChild("_Dread",true); if Dread then Dread.Name = "_Dread" end
else local Dread = LocalPlayer:FindFirstChild("Dread",true) or LocalPlayer:FindFirstChild("_Dread",true); if Dread then Dread.Name = "Dread" end end
end
})

BypassEntityBox:AddToggle('Halt',{
Text = "Anti Halt", Default = false,
Callback = function(Value)
if Value then local Dread = ClientModules.EntityModules:FindFirstChild("Shade",true) or ClientModules.EntityModules:FindFirstChild("_Shade",true); if Dread then Dread.Name = "_Shade" end
else local Dread = ClientModules.EntityModules:FindFirstChild("Shade",true) or ClientModules.EntityModules:FindFirstChild("_Shade",true); if Dread then Dread.Name = "Shade" end end
end
})

BypassEntityBox:AddToggle('Jamming',{
Text = "Anti Jammimg", Default = false,
Callback = function(Value)
if ReplicatedStorage:FindFirstChild("LiveModifiers") and ReplicatedStorage:FindFirstChild("LiveModifiers"):FindFirstChild("Jammin") then
local Jam = LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game").Health.Jam
Jam.Playing = not Value
local Jamming = game:GetService("SoundService").Main.Jamming
Jamming.Enabled = not Value
end
end
})

local Surge = Instance.new("RemoteEvent",ReplicatedStorage)
Surge.Name = "SurgeRemote"

BypassEntityBox:AddToggle('BypassSurgeDamage',{
Text = "Anti Surge Damage", Default = false,
Callback = function(Value)
if Value then
if RemotesFolder:FindFirstChild("SurgeRemote") then RemotesFolder.SurgeRemote.Parent = ReplicatedStorage; Surge.Parent = RemotesFolder end
else
if RemotesFolder:FindFirstChild("SurgeRemote") then ReplicatedStorage.SurgeRemote.Parent = RemotesFolder; Surge.Parent = ReplicatedStorage end
end
end
})

BypassEntityBox:AddToggle('Snare',{
Text = "Anti Snare", Default = false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "Snare" then
local wait = 0
repeat task.wait(0.01) wait = wait  + 0.01 until wait > 2 or v:FindFirstChild("Hitbox")
if v:FindFirstChild("Hitbox") then v.Hitbox.CanTouch = not Value end
end
end
end
})

BypassEntityBox:AddToggle('Giggle',{
Text = "Anti Giggle", Default = false, Disabled = Floor.Value == "Fools" and RemotesFolder.Name == "Bricks" and true or false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "GiggleCeiling" then
local wait = 0
repeat task.wait(0.01) wait = wait  + 0.01 until wait > 2 or v:FindFirstChild("Hitbox")
if v:FindFirstChild("Hitbox") then v.Hitbox.CanTouch = not Value end
end
end
end
})

BypassEntityBox:AddToggle('Dupe',{
Text = "Anti Dupe", Default = false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "DoorFake" and v.Parent and v.Parent.Name == "SideroomDupe" then v:WaitForChild("Hidden", 3).CanTouch = not Value end
end
end
})

BypassBox:AddToggle('BypassSpeed',{ Text = "Speed Bypass", Default = false, Callback = function(Value) Options.MovementSpeed:SetMax(Value and 75 or 21); Options.FlightSpeed:SetMax(Value and 75 or 21) end })
BypassBox:AddDropdown("SpeedBypassMethod", { Values = { "Method 1", "Method 2" }, Default = 1, Text = "Speed Bypass Method", Callback = function(Value) end, })
BypassBox:AddDivider()
BypassBox:AddDropdown("AntiCheatManiMethod", { Values = { "Velocity", "Anticheat" }, Default = 1, Text = "Manipulation Method", Callback = function(Value) end, })

BypassBox:AddToggle('AntiCheatMani',{
Text = "Manipulation", Default = false,
Callback = function(Value)
if not Value then
if LocalPlayer.Character.HumanoidRootPart:FindFirstChild("VelocityMani") then LocalPlayer.Character.HumanoidRootPart:FindFirstChild("VelocityMani"):Destroy() end
if Toggles.NoClip.Value then Toggles.NoClip:SetValue(false) end
end
end
}):AddKeyPicker("AntiCheatMan", { Default = "V", SyncToggleState = true, Mode = Library.IsMobile and "Toggle" or "Hold", Text = " Manipulation", NoUI = false, Callback = function(Value) print("[cb] Keybind clicked!", Value) end, ChangedCallback = function(NewKey, NewModifiers) end, })

BypassBox:AddLabel("Fake Revive When Toggled On there is no back so Toggle it based on your own Risk and if your Character Get Invisible This Mean you Lost Network OwnerShip which means its broke your Fake Revive",true)
BypassBox:AddToggle('FakeRevive',{ Text = "Fake Revive", Default = false, Disabled = Floor.Value == "Fools" and true or RemotesFolder.Name =="Bricks" and true or false, Risky = true, })

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude
local Direction = Vector3.new(0, -100, 0)

-- OPTIMIZED: Switched from un-throttled task.wait(0) to safe interval execution
task.spawn(function()
while true do
    local waitTime = (Options.SpeedBypassMethod and Options.SpeedBypassMethod.Value == "Method 1") and 0.25 or 0.209
    task.wait(waitTime)
    if Library.Unloaded then break end
    if Options.SpeedBypassMethod.Value == "Method 1" then
        if Toggles.BypassSpeed.Value then
            if CollisionClone then CollisionClone.Massless = true end
            RemotesFolder.Crouch:FireServer(true, true)
        end
    elseif Options.SpeedBypassMethod.Value == "Method 2" then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if LocalPlayer:GetAttribute("Alive") and hrp and CollisionClone and CollisionClone.Parent then
            Params.FilterDescendantsInstances = {char, CollisionClone}
            if not workspace:Raycast(hrp.Position, Direction, Params) or not Toggles.BypassSpeed.Value then
                CollisionClone.Massless = true
            else
                local cp = char:FindFirstChild("CollisionPart")
                if cp and (cp.Anchored or Passed) then
                    CollisionClone.Massless = true
                    repeat task.wait() until not cp.Anchored or not cp.Parent
                    if CollisionClone and CollisionClone.Parent then
                        CollisionClone.Massless = true
                        task.wait(0.5)
                        if CollisionClone and CollisionClone.Parent then CollisionClone.Massless = false end
                    end
                else
                    if LocalPlayer:GetAttribute("Alive") then CollisionClone.Massless = true end
                    task.wait(0.209)
                    if LocalPlayer:GetAttribute("Alive") and CollisionClone and CollisionClone.Parent then CollisionClone.Massless = false end
                end
            end
        end
    end
end
end)

table.insert(Connections,workspace.ChildAdded:Connect(function(v)
if Toggles.AntiBanana.Value and v.Name == "BananaPeel" then v.CanTouch = false end
if Toggles.AntiJeff.Value and v.Name == "JeffTheKiller" then
repeat task.wait() until v.PrimaryPart and isnetworkowner(v.PrimaryPart)
for _, i in pairs(v:GetChildren()) do if i:IsA("BasePart") then i.CanTouch = false end end
v.Humanoid.Health = 0
end

if Toggles.NotifySpawn.Value then
if v.Name == "RushMoving" and Options.Notify.Value["Rush"] then Notify("Rush has Spawned",5) end
if v.Name == "AmbushMoving"  and Options.Notify.Value["Ambush"] then Notify("Ambush has Spawned",5) end
if v.Name == "A60"  and Options.Notify.Value["A-60"] then Notify("A-60 has Spawned",5) end
if v.Name == "A120"  and Options.Notify.Value["A-120"] then Notify("A-120 has Spawned",5) end
if v.Name == "GlitchRush"  and Options.Notify.Value["GlitchRush"] then Notify("Glitch Rush has Spawned",5) end
if v.Name == "GlitchAmbush"  and Options.Notify.Value["GlitchAmbush"] then Notify("Glitch Ambush has Spawned",5) end
if v.Name == "Eyes"  and Options.Notify.Value["Eyes"] then Notify("Eyes has Spawned",5) end
if v.Name == "Lookman"  and Options.Notify.Value["Eyes"] then Notify("Eyes has Spawned",5) end
if v.Name == "BackdoorRush"  and Options.Notify.Value["Blitz"] then Notify("Blitz has Spawned",5) end
if v.Name == "BackdoorLookman"  and Options.Notify.Value["Lookman"] then Notify("Lookman has Spawned",5) end
if v.Name == "JeffTheKiller"  and Options.Notify.Value["Jeff"] then Notify("Jeff has Spawned",5) end
end

if Toggles.Entity.Value then
if v.Name == "RushMoving"  then AddEntityESP(v, "Rush", EntityColor) end
if v.Name == "AmbushMoving"  then AddEntityESP(v, "Ambush", EntityColor) end
if v.Name == "A60"  then AddEntityESP(v, "A-60", EntityColor); IsMoving = false end
if v.Name == "A120"  then AddEntityESP(v, "A-120", EntityColor); IsMoving = false end
if v.Name == "GlitchRush"  then AddEntityESP(v, "Glitch Rush", EntityColor) end
if v.Name == "GlitchAmbush"  then AddEntityESP(v, "Glitch Ambush", EntityColor) end
if v.Name == "Eyes" or v.Name == "Lookman" then AddEntityESP(v, "Eyes", EntityColor) end
if v.Name == "BackdoorRush"   then AddEntityESP(v, "Blitz", EntityColor) end
if v.Name == "BackdoorLookman" then AddEntityESP(v, "Lookman", EntityColor) end
if v.Name == "JeffTheKiller" then AddEntityESP(v, "Jeff", EntityColor) end
end
end))

-- STREAMING_CHUNK:Safe Room transition logics...
table.insert(Connections,LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
local currentRoomNum = LocalPlayer:GetAttribute("CurrentRoom")
if not currentRoomNum then return end

local currentRoomStr = tostring(currentRoomNum)
local prevRoomStr = tostring(currentRoomNum - 1)
local nextRoomStr = tostring(currentRoomNum + 1)

local prevRoom = workspace.CurrentRooms:FindFirstChild(prevRoomStr)
local currentRoom = workspace.CurrentRooms:FindFirstChild(currentRoomStr)
local nextRoom = workspace.CurrentRooms:FindFirstChild(nextRoomStr)

if Toggles.GateLever.Value then
    if prevRoom then
        local OldLever = prevRoom:FindFirstChild("LeverForGate",true)
        if OldLever then ESPLibrary:RemoveESP(OldLever) end
    end
    if nextRoom then
        local OldLever = nextRoom:FindFirstChild("LeverForGate",true)
        if OldLever then ESPLibrary:RemoveESP(OldLever) end
    end
    if currentRoom then
        local Lever = currentRoom:FindFirstChild("LeverForGate",true)
        if Lever then AddESP(Lever, "Gate Lever", LeverColor) end
    end
end

if Toggles.Objective.Value then
    if prevRoom then
        local OldKey = prevRoom:FindFirstChild("KeyObtain",true)
        if OldKey then ESPLibrary:RemoveESP(OldKey) end
        local OldEKey = prevRoom:FindFirstChild("ElectrialKeyObtain",true)
        if OldEKey then ESPLibrary:RemoveESP(OldEKey) end
    end
    if nextRoom then
        local OldKey = nextRoom:FindFirstChild("KeyObtain",true)
        if OldKey then ESPLibrary:RemoveESP(OldKey) end
        local OldEKey = nextRoom:FindFirstChild("ElectrialKeyObtain",true)
        if OldEKey then ESPLibrary:RemoveESP(OldEKey) end
    end
    if currentRoom then
        local Key = currentRoom:FindFirstChild("KeyObtain",true)
        if Key then AddESP(Key, "Key", Color3.new(0, 1, 1)) end
        local EKey = currentRoom:FindFirstChild("ElectrialKeyObtain",true)
        if EKey then AddESP(EKey, "Electrial Key", Color3.new(0, 1, 1)) end
    end
end

if Toggles.HidingPlace.Value then
    for _, v in pairs(Closets) do
        if prevRoom and v:IsDescendantOf(prevRoom) then ESPLibrary:RemoveESP(v) end
        if nextRoom and v:IsDescendantOf(nextRoom) then ESPLibrary:RemoveESP(v) end
        
        local Nam = HidingPlaces[v.Name]
        if Nam and currentRoom and v:IsDescendantOf(currentRoom) then
            AddESP(v, Nam, HidingPlaceColor)
        end
    end
end

if Toggles.Door.Value then 
    if prevRoom then
        local prevDoor = prevRoom:FindFirstChild("Door")
        if prevDoor and prevDoor:FindFirstChild("Door") then
            ESPLibrary:RemoveESP(prevDoor.Door)
            if prevDoor.Door:FindFirstChild("CrossBoards") then ESPLibrary:RemoveESP(prevDoor.Door.CrossBoards) end
        end
    end
    if nextRoom then
        local nextDoor = nextRoom:FindFirstChild("Door")
        if nextDoor and nextDoor:FindFirstChild("Door") then
            if nextDoor.Door:FindFirstChild("CrossBoards") then AddESP(nextDoor.Door.CrossBoards, "", DoorColor) end
            AddESP(nextDoor.Door, "Door " .. (nextDoor:GetAttribute("RoomID") or nextRoomStr), DoorColor)
        end
    end
    if currentRoom then
        local cDoor = currentRoom:FindFirstChild("Door")
        if cDoor and cDoor:FindFirstChild("Door") then
            if cDoor.Door:FindFirstChild("CrossBoards") then AddESP(cDoor.Door.CrossBoards, "", DoorColor) end
            AddESP(cDoor.Door, "Door " .. (cDoor:GetAttribute("RoomID") or currentRoomStr), DoorColor)
        end
    end
end


end))

BypassEntityBox:AddToggle('EyesDamage',{ Text = "Anti Eyes Damage", Default = false })
BypassEntityBox:AddToggle('LookmanDamage',{ Text = "Anti Lookman Damage", Default = false })
BypassEntityBox:AddToggle('GloomEggDamage',{
Text = "Anti Gloom Egg", Default = false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "GloomEgg" then
for _, i in pairs(v:GetChildren()) do if i:IsA("BasePart") then i.CanTouch = not Value end end
end
end
end
})

HotelFloor:AddToggle('NotifyLibraryCode',{ Text = "Notify Library Code", Disabled = Floor.Value ~= "Hotel" and RemotesFolder.Name ~= "Bricks" and Floor.Value ~= "Fools" and Floor.Value ~= "Fools26" and true or false, Default = false, })
HotelFloor:AddToggle('SeekObf',{
Text = "Anti Seek Obstacles", Default = false, Disabled = Floor.Value == "Retro" and true or false,
Callback = function(Value)
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v.Name == "Seek_Arm" or v.Name == "ChandelierObstruction" then
for _, i in pairs(v:GetChildren()) do if i:IsA("BasePart") then i.CanTouch = not Value end end
end
end
end
})

BypassEntityBox:AddToggle('FigureHearing',{
Text = "Anti Figure Hearing", Default = false, Disabled = Floor.Value == "Fools" and true or false, DisabledTooltip = "This floor wont support this feature",
Callback = function(Value)
if not Value then RemotesFolder.Crouch:FireServer(false) else RemotesFolder.Crouch:FireServer(true) end
end
})

BypassEntityBox:AddToggle('AntiLag',{
Text = "Anti Lag ", Default = false,
Callback = function(Value)
if Value then
for _, v in workspace.CurrentRooms:GetDescendants() do
if v:IsA("BasePart") then v:SetAttribute("Mat", v.Material); v.Material = "Plastic" end
end
else
for _, v in workspace.CurrentRooms:GetDescendants() do
if v:IsA("BasePart") then if v:GetAttribute("Mat") then v.Material = v:GetAttribute("Mat") or "Plastic" end end
end
end
end
})
BypassEntityBox:AddLabel('Anti Lag if it Lags you Turn it off',true)

ReachBox:AddToggle('PromptReach',{
Text = "Prompt Reach", Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v:SetAttribute("Range", v.MaxActivationDistance); v.MaxActivationDistance = v.MaxActivationDistance * 2 end end
else
for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v.MaxActivationDistance = v:GetAttribute("Range") or v.MaxActivationDistance end end
end
end
})

ReachBox:AddToggle('PromptClip',{
Text = "Prompt Clip", Default = false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v:SetAttribute("Clip", v.RequiresLineOfSight); v.RequiresLineOfSight = false end end
else
for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then v.RequiresLineOfSight = v:GetAttribute("Clip") or true end end
end
end
})

ReachBox:AddToggle('DoorReach',{ Text = "Door Reach", Default = false })

ladderColor = Color3.new(0, 0, 1)
fuseColor = Color3.new(0.2, 0.5, 0.3)
ESPBox:AddToggle('Ladder',{
Text = "Ladder", Default = false,
Callback = function(Value)
if Value then for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "Ladder" then AddESP(v, "Ladder",ladderColor) end end
else for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "Ladder" then ESPLibrary:RemoveESP(v) end end end
end
}):AddColorPicker("ColorPicker2", { Default = ladderColor, Title = "Ladder ESP Color", Callback = function(Value) ladderColor = Value; Toggles.Ladder:SetValue(false); Toggles.Ladder:SetValue(true) end, })

ESPBox:AddToggle('Fuse',{
Text = "Fuse", Default = false,
Callback = function(Value)
if Value then for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "FuseObtain" then AddESP(v, "Fuse",fuseColor) end end
else for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do if v.Name == "FuseObtain" then ESPLibrary:RemoveESP(v) end end end
end
}):AddColorPicker("ColorPicker2", { Default = fuseColor, Title = "Fuse ESP Color", Callback = function(Value) fuseColor = Value; Toggles.Fuse:SetValue(false); Toggles.Fuse:SetValue(true) end, })

PlayerColor = Color3.new(1, 1, 1)
ESPBox:AddToggle('Player', {
Text = "Player", Default = false,
Callback = function(Value)
for _, v in pairs(Players:GetPlayers()) do
if v ~= LocalPlayer and v.Character then
ESPLibrary:RemoveESP(v.Character)
if Value then
local hum = v.Character:FindFirstChildOfClass("Humanoid")
if hum and hum.Health > 0 then AddESP(v.Character, v.Name .. " [" .. math.floor((hum.Health / hum.MaxHealth) * 100) .. "%]", PlayerColor) end
end
end
end
end
}):AddColorPicker("ColorPicker99", { Default = PlayerColor, Title = "Player ESP Color", Callback = function(Value) PlayerColor = Value; Toggles.Player:SetValue(false); Toggles.Player:SetValue(true) end, })

BypassBox:AddToggle('LadderBypass',{
Text = "Ladder Bypass", Default = false,
Callback = function(Value) if not Value then RemotesFolder:FindFirstChild("ClimbLadder"):FireServer() end end
})

BypassBox:AddDivider()
BypassBox:AddLabel("Infinite Crucfix Only Works on A-60 A-120 Rush And Ambush and it have a chance to fail so take it at your own risk",true)
BypassBox:AddToggle('InfCrucifix',{ Text = "Infinite Crucifix ", Risky = true, Disabled = Floor.Value == "Rooms" and Floor.Value == "Outdoors" and true or false, })
BypassBox:AddDivider()

local Stored = {}
local Names = { Lock = true, ChestBoxLocked = true, Cellar = true, Chest_Vine = true, CuttableVines = true, SkullLock = true, Toolbox_Locked = true, Lock1 = true, Lock2 = true, }

local function InfPrompt(Prompt)
local Char = LocalPlayer.Character
if not Char then return end

local RootPart = Char:FindFirstChild("HumanoidRootPart")
if not RootPart then return end

local Tool = Char:FindFirstChild("Lockpick") or Char:FindFirstChild("SkeletonKey") or Char:FindFirstChild("Shears")
local Name = Tool and Tool.Name

if Tool then
    if Prompt:GetAttribute("InfItems") and Prompt:GetAttribute("Tool") ~= Name then 
        if Prompt.Parent then
            local ExistingPrompt = Prompt.Parent:FindFirstChild("InfPrompt")
            if ExistingPrompt then ExistingPrompt:Destroy() end
            Prompt:SetAttribute("InfItems", nil)
            Prompt.Enabled = true
        end
    end

    if not Prompt:GetAttribute("InfItems") then
        Prompt.Enabled = false
        Prompt:SetAttribute("InfItems", true)
        Prompt:SetAttribute("Tool", Name)
        Prompt.ClickablePrompt = false
        
        local Clone = Prompt:Clone()
        Clone.Name = "InfPrompt"
        Clone.MaxActivationDistance = Prompt.MaxActivationDistance * 0.5
        Clone.Parent = Prompt.Parent
        Clone.Enabled = true
        Clone.ClickablePrompt = true

        local Con
        Con = Clone.Triggered:Connect(function()
            Con:Disconnect()
            Clone:Destroy()
            if Char:FindFirstChild(Name) then
                task.spawn(function()
                    local Drop = nil
                    local StartTime = tick()
                    repeat
                        RemotesFolder.DropItem:FireServer(Tool)
                        task.wait(0.01)
                        local ClosestDist = 15
                        for _, v in ipairs(workspace.Drops:GetChildren()) do
                            if v.Name == Name then
                                local Dist = GetDistanceToPlayer(v:GetPivot().Position)
                                if Dist < ClosestDist then ClosestDist = Dist; Drop = v end
                            end
                        end
                    until Drop or not Char:FindFirstChild(Name) or (tick() - StartTime) > 3
                    
                    if Name == "Shears" then
                        fireproximityprompt(Prompt)
                        if Drop then
                            local DropPrompt = Drop:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if DropPrompt then fireproximityprompt(DropPrompt) end
                        end
                    else
                        if Drop then
                            local DropPrompt = Drop:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if DropPrompt then fireproximityprompt(DropPrompt) end
                        end
                        fireproximityprompt(Prompt)
                    end
                    Prompt:SetAttribute("InfItems", nil)
                    Prompt:SetAttribute("Tool", nil)
                    Prompt.Enabled = true
                    Prompt.ClickablePrompt = true
                end)
            else
                Prompt:SetAttribute("InfItems", nil)
                Prompt:SetAttribute("Tool", nil)
                Prompt.Enabled = true
                Prompt.ClickablePrompt = true
            end
        end)
    end
elseif (Char:FindFirstChild("Key") or Char:FindFirstChild("Fuse")) and Prompt:GetAttribute("InfItems") then
    if Prompt.Parent then
        local ExistingPrompt = Prompt.Parent:FindFirstChild("InfPrompt")
        if ExistingPrompt then ExistingPrompt:Destroy() end
    end
    Prompt:SetAttribute("InfItems", nil)
    Prompt:SetAttribute("Tool", nil)
    Prompt.Enabled = true
    Prompt.ClickablePrompt = true
end


end

BypassBox:AddToggle('InfItems',{
Text = "Infinite Items ", Disabled = Floor.Value == "Fools" and RemotesFolder.Name == "Bricks" and not Firepp and true or false,
Callback = function(Value)
if Value then
for _, v in pairs(workspace.CurrentRooms:GetDescendants()) do
if v:IsA("ProximityPrompt") then
if Names[v.Parent.Name] or v.Name == "FusesPrompt" or (v.Parent.Parent and v.Parent.Parent.Name == "Locker_Small_Locked") then table.insert(Stored, v) end
end
end
else
for _, Prompt in pairs(workspace.CurrentRooms:GetDescendants()) do
if Prompt:IsA("ProximityPrompt") then
if Prompt.Parent and Names[Prompt.Parent.Name] then
if Prompt:GetAttribute("InfItems") then
local Fake = Prompt.Parent:FindFirstChild("InfPrompt")
if Fake then Fake:Destroy() end
Prompt:SetAttribute("InfItems", nil)
Prompt.Enabled = true
end
end
end
end
table.clear(Stored)
end
end
})

local InfParams = RaycastParams.new()
InfParams.FilterType = Enum.RaycastFilterType.Exclude

local AutoInteract = 0
local NotifyCode = 0
local AutoAnchorSolver  = 0
local InfItemsDelay = 0
local PlayerESP = 0
local DoorReach = 0

-- TRACKING: Added explicit debounce variables to prevent frame-rate flooding
local EyesDelay = 0
local AutoHidingDelay = 0
local AestheticsDelay = 0
local FullBrightDelay = 0

table.insert(Connections,RunService.RenderStepped:Connect(function(dt)
AutoInteract += dt
NotifyCode += dt
AutoAnchorSolver += dt
InfItemsDelay += dt
PlayerESP += dt
AutoLibrary += dt
DoorReach += dt
EyesDelay += dt
AutoHidingDelay += dt
AestheticsDelay += dt
FullBrightDelay += dt

if Toggles.FakeRevive.Value then
local Char = LocalPlayer.Character
if Char.Humanoid.Health == 0 then
Char.Humanoid.Health = 100
Notify("You Need Any Healing Source so you can Interact", 5)
Char.HumanoidRootPart.Anchored = true
Camera.CameraType = "Custom"
LocalPlayer:SetAttribute("Alive", true)
if not Char:GetAttribute("FakeRevived") then Char:SetAttribute("FakeRevived",true) end
end

if Char:GetAttribute("FakeRevived") then
if Char.Humanoid.BreakJointsOnDeath ~= false then Char.Humanoid.BreakJointsOnDeath = false end
if Char.Humanoid.RequiresNeck ~= false then Char.Humanoid.RequiresNeck = false end
if Char.Humanoid.PlatformStand ~= false then Char.Humanoid.PlatformStand = false end
if Char.Humanoid.Health <= 0 then Char.Humanoid.Health = 0.1 end
Char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
Char.Humanoid.Sit = false
if Char:FindFirstChild("HumanoidRootPart") then Char.HumanoidRootPart.Anchored = false end
if Char:FindFirstChild("CollisionPart") and Char.CollisionPart.Anchored ~= false then Char.CollisionPart.Anchored = false end
if LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Death") then LocalPlayer.PlayerGui.MainUI.Initiator.Death:Destroy() end
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

Char.Humanoid.AutomaticScalingEnabled = true
Char:SetAttribute("Stunned", false)
LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game").Health.Enabled = not LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game").Health.Enabled
end
end

if not LocalPlayer:GetAttribute("Alive") then
if Toggles.InfRevive.Value then RemotesFolder.Revive:FireServer() end
if CollisionClone then CollisionClone = nil end
return
end

if Camera ~= workspace.CurrentCamera then Camera = workspace.CurrentCamera end

if not LocalPlayer.Character:GetAttribute("Climbing") and Toggles.EnableMovementSpeed.Value then
if LocalPlayer.Character.Humanoid.WalkSpeed ~= Options.MovementSpeed.Value then LocalPlayer.Character.Humanoid.WalkSpeed = Options.MovementSpeed.Value end
elseif LocalPlayer.Character:GetAttribute("Climbing") and Toggles.EnableClimbingSpeed.Value then
if LocalPlayer.Character.Humanoid.WalkSpeed ~= Options.ClimbingSpeed.Value then LocalPlayer.Character.Humanoid.WalkSpeed = Options.ClimbingSpeed.Value end
end

if Toggles.ThirdPerson.Value then
Camera.CFrame = Camera.CFrame * CFrame.new(Options.X.Value, Options.Y.Value, Options.Z.Value)
end

-- OPTIMIZED: Aesthetic logic no longer updates character models every single frame
if AestheticsDelay > 0.1 then
    AestheticsDelay = 0
    for _, v in pairs(LocalPlayer.Character:GetChildren()) do
        if v:IsA("BasePart") and (v.Name == "Head" or v.Name == "FakeHead") then
            v.Transparency = Toggles.ThirdPerson.Value and 0 or 1
            v.LocalTransparencyModifier = Toggles.ThirdPerson.Value and 0 or 1
        end
        if v:IsA("Accessory") then
            local handle = v:FindFirstChild("Handle")
            if handle then
                handle.Transparency = Toggles.ThirdPerson.Value and 0 or 1
                handle.LocalTransparencyModifier = Toggles.ThirdPerson.Value and 0 or 1
            end
        end
    end
end
Camera.FieldOfView = Options.FOV.Value

if Toggles.Freecam.Value then
local char = LocalPlayer.Character
local hum = char and char:FindFirstChild("Humanoid")
local root = char and char:FindFirstChild("HumanoidRootPart")
if root and not root.Anchored then root.Anchored = true end

if not workspace:FindFirstChild("FreecamPart") then
    local part = Instance.new("Part")
    part.Name = "FreecamPart"
    part.Size = Vector3.new(0.01, 0.01, 0.01)
    part.Transparency = 1
    part.CanCollide = false
    part.Anchored = true
    part.CFrame = Camera.CFrame
    part.Parent = workspace
    
    LocalPlayer:SetAttribute("fc_om", LocalPlayer.CameraMinZoomDistance)
    LocalPlayer:SetAttribute("fc_ox", LocalPlayer.CameraMaxZoomDistance)
    LocalPlayer.CameraMinZoomDistance = 0
    LocalPlayer.CameraMaxZoomDistance = 0
    
    local rx, ry, rz = Camera.CFrame:ToOrientation()
    LocalPlayer:SetAttribute("fc_p", math.deg(rx))
    LocalPlayer:SetAttribute("fc_y", math.deg(ry))
end

local fcPart = workspace:FindFirstChild("FreecamPart")
local curCam = Camera

if fcPart and curCam then
    local delta = UserInputService:GetMouseDelta()
    local sensitivity = UserInputService.KeyboardEnabled and 0.3 or 0.6
    
    local pitch = (LocalPlayer:GetAttribute("fc_p") or 0) - (delta.Y * sensitivity)
    local yaw = (LocalPlayer:GetAttribute("fc_y") or 0) - (delta.X * sensitivity)
    pitch = math.clamp(pitch, -80, 80)
    
    LocalPlayer:SetAttribute("fc_p", pitch)
    LocalPlayer:SetAttribute("fc_y", yaw)
    
    fcPart.CFrame = CFrame.new(fcPart.Position) * CFrame.fromOrientation(math.rad(pitch), math.rad(yaw), 0)
    curCam.CFrame = fcPart.CFrame
    curCam.Focus = curCam.CFrame * CFrame.new(0, 0, -10)

    if hum and hum.MoveDirection.Magnitude > 0 then
        local speed = 75
        local moveVec = hum.MoveDirection
        local localMove = curCam.CFrame:VectorToObjectSpace(moveVec)
        local finalMove = (curCam.CFrame.RightVector * localMove.X) + (curCam.CFrame.LookVector * -localMove.Z)
        fcPart.Position = fcPart.Position + (finalMove * speed * dt)
    end
end


end

if Toggles.DeleteFigureFE.Value and Figures then
for _, v in pairs(Figures) do
local Root = v:FindFirstChild("Root")
if not IsNetworkOwner then
Notify("Sorry your executor wont support Delete Figure Because isnetworkowner", 5)
Toggles.DeleteFigureFE:SetValue(false)
end
if Root and isnetworkowner(Root) then
if Root:FindFirstChild("BodyForce") then Root.BodyForce.Force = Vector3.new(0, -50000, 0) else Root:PivotTo(CFrame.new(0, -50000, 0)) end
for _, part in pairs(v:GetDescendants()) do
if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false; part.Anchored = false end
end
if Root.Position.Y < -1000 and not v:GetAttribute("Deleted") then
Notify("Deleted Figure Successfully", 4)
v:SetAttribute("Deleted", true)
end
end
end
end

if Toggles.AutoAnchorSolver.Value and LatestRoom.Value == 50 and AutoAnchorSolver > 0.5  then
AutoAnchorSolver = 0
local Hint = LocalPlayer.PlayerGui.MainUI:FindFirstChild("AnchorHintFrame")
if Anchors and Hint and Hint.Visible then
local ID = Hint.AnchorCode.Text
for _, v in pairs(Anchors) do
if v:FindFirstChild("Sign") and v.Sign.TextLabel.Text == ID then
local Code = Hint.Code.Text
local Note = v:FindFirstChild("Note")
local NoteText = Note and Note.SurfaceGui.TextLabel.Text or ""
local Mod = tonumber(string.match(NoteText, "%d+")) or 0
local Final = ""
for i = 1, #Code do
local Digit = tonumber(string.sub(Code, i, i)) or 0
local Res = string.find(NoteText, "+") and (Digit + Mod) % 10 or (Digit - Mod) % 10
Final = Final .. tostring(Res < 0 and Res + 10 or Res)
end
local Dis = (LocalPlayer.Character.HumanoidRootPart.Position - v:GetPivot().Position).Magnitude
if Dis < 20 then
local AnchorRemote = v:FindFirstChildOfClass("RemoteFunction")
if AnchorRemote then AnchorRemote:InvokeServer(tostring(Code)) end
Notify("Anchor " .. Final, 1)
end
end
end
end
end

if Toggles.AutoMinecart.Value and Camera:FindFirstChild("MinecartRig") then
if LatestRoom.Value < 49 then
if not LocalPlayer:GetAttribute("NotifyMinecart") then
Notify("[Auto Minecart] DONT MOVE", 5)
LocalPlayer:SetAttribute("NotifyMinecart", true)
end
local Root = LocalPlayer.Character.HumanoidRootPart
local ClosestDuckDist = math.huge
for _, v in pairs(DuckBoards) do
local Dist = GetDistanceToPlayer(v:GetPivot().Position)
if Dist < ClosestDuckDist then ClosestDuckDist = Dist end
end
if RequiredMainGame.crouching ~= (ClosestDuckDist < 30) then RequiredMainGame.crouching = (ClosestDuckDist < 30) end

    local CurrentNode = nil
    local MinDist = math.huge
    for _, Node in pairs(Nodes) do
        if Node:GetAttribute("ForceConnect") then
        local Dist = (Root.Position - Node.Position).Magnitude
        if Dist < MinDist then MinDist = Dist; CurrentNode = Node end
    end


end
if CurrentNode then
local CurrentNum = tonumber(string.match(CurrentNode.Name, "%d+"))
if CurrentNum then
local Node1
for _, Node in pairs(Nodes) do
if Node.Name == "MinecartNode" .. tostring(CurrentNum + 3) then Node1 = Node; break end
end
if Node1 then
local DistToNode = GetDistanceToPlayer(CurrentNode.Position)
if DistToNode > 30 then
require(LocalPlayer.PlayerScripts.PlayerModule):GetControls().GetMoveVector = function() return Vector3.new(0, 0, -1) end
else
local DirectionToNode = (CurrentNode.Position - Node1.Position).Unit
local Dot = DirectionToNode:Dot(CurrentNode.CFrame.RightVector)
require(LocalPlayer.PlayerScripts.PlayerModule):GetControls().GetMoveVector = function()
if Dot > 0.15 then return Vector3.new(1, 0, 0)
elseif Dot < -0.15 then return Vector3.new(1, 0, 0) end
return Vector3.new(0, 0, -1)
end
end
end
end
end
elseif LatestRoom.Value >= 50 then
if LocalPlayer:GetAttribute("NotifyMinecart") then Notify("[Auto Minecart] YOU CAN MOVE", 5); LocalPlayer:SetAttribute("NotifyMinecart", false) end
Toggles.AutoMinecart:SetValue(false)
require(LocalPlayer.PlayerScripts.PlayerModule):GetControls().GetMoveVector = Control
end
end

if Toggles.InfItems.Value and InfItemsDelay > 0.15 then
InfItemsDelay = 0
for _, Prompt in pairs(Stored) do InfPrompt(Prompt) end
end

if Toggles.NotifyLibraryCode.Value and NotifyCode >  5 then
NotifyCode = 0
local Code = GetLibraryCode()
if Code and LatestRoom.Value == 50 then Notify("Code " .. Code) end
end

if Toggles.Flight.Value then
if not LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlightVelocity") then
local Velocity = Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart)
Velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
Velocity.Velocity = Vector3.zero
Velocity.Name = "FlightVelocity"
Velocity.P = math.huge
end
if OldAccel then LocalPlayer.Character.HumanoidRootPart.CustomPhysicalProperties = OldAccel end

local moveDir = LocalPlayer.Character.Humanoid.MoveDirection
local flatLook = Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
if flatLook.Magnitude < 0.001 then flatLook = Camera.CFrame.UpVector * Vector3.new(1, 0, 1) * math.sign(-Camera.CFrame.LookVector.Y) end
local flatCam = CFrame.lookAt(Vector3.zero, flatLook)
local localInput = flatCam:VectorToObjectSpace(moveDir)
LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlightVelocity").Velocity = Camera.CFrame:VectorToWorldSpace(localInput) * Options.FlightSpeed.Value


end

-- OPTIMIZED: AutoHiding environment scans now run on a healthy interval loop instead of every frame
if Toggles.AutoHiding.Value and AutoHidingDelay > 0.1 then
AutoHidingDelay = 0
local Closet = GetNearestHidingSpot()
if Closet then
for _, v in pairs(workspace:GetChildren()) do
local Monster = AutoClosetTable[v.Name]
if Monster then
local MainPart = v:FindFirstChildWhichIsA("BasePart")
if not MainPart then LocalPlayer.Character:SetAttribute("Hiding", false)
else
local Dis = GetDistanceToPlayer(MainPart.Position)
if Dis < Monster then
if not LocalPlayer.Character.PrimaryPart.Anchored then
local hidePrompt = Closet:FindFirstChildOfClass("ProximityPrompt", true)
if hidePrompt then fireproximityprompt(hidePrompt) end
end
else
LocalPlayer.Character:SetAttribute("Hiding", false)
end
end
end
end
end
end

if Toggles.Godmode.Value then
if RemotesFolder.Name == "RemotesFolder" then
if not Toggles.FigureHearing.Value then Notify("Enabled Figure Hearing Automatically cause Godmode needs it", 3); Toggles.FigureHearing:SetValue(true) end
if LocalPlayer.Character.LowerTorso.Root.C1 ~= CFrame.new(0, -2.3, 0) then LocalPlayer.Character.LowerTorso.Root.C1 = CFrame.new(0, -2.3, 0) end
if LocalPlayer.Character.Humanoid.HipHeight ~= 0.22 then LocalPlayer.Character.Humanoid.HipHeight = 0.22 end
if LocalPlayer.Character.Collision.Size ~= Vector3.new(1, 1, 4) then LocalPlayer.Character.Collision.Size = Vector3.new(1, 1, 4) end
if LocalPlayer.Character.Collision.CollisionCrouch.Size ~= Vector3.new(1, 1, 4) then LocalPlayer.Character.Collision.CollisionCrouch.Size = Vector3.new(1, 1, 4) end
end
if (Floor.Value == "Fools" or RemotesFolder.Name == "Bricks") and not Toggles.NoClip.Value then Toggles.NoClip:SetValue(true) end
end

if not LocalPlayer.Character:FindFirstChild("CollisionClone") then
if LocalPlayer.Character:FindFirstChild("CollisionPart") then
CollisionClone = LocalPlayer.Character.CollisionPart:Clone()
CollisionClone.Parent = LocalPlayer.Character
CollisionClone.Name = "CollisionClone"
CollisionClone.RootPriority = 127
CollisionClone.Anchored = false
CollisionClone.CanCollide = false
if CollisionClone:FindFirstChild("CollisionCrouch") then CollisionClone:FindFirstChild("CollisionCrouch"):Destroy() end
end
end

if Toggles.NoScenes.Value and LatestRoom.Value == 100 then Toggles.NoScenes:SetValue(false) end
if not HookMeta then
if Toggles.FigureHearing.Value then
if RemotesFolder:FindFirstChild("Crouch") then RemotesFolder.Crouch:FireServer(true) end
end
end

if Toggles.InfCrucifix.Value and not Toggles.Godmode.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
local Origin = LocalPlayer.Character.HumanoidRootPart.Position
for _, Entity in pairs(workspace:GetChildren()) do
local Range = InfCrucfixTable[Entity.Name]
if Range and Entity.PrimaryPart then
local Target = Entity.PrimaryPart.Position
if (Origin - Target).Magnitude < Range then
InfParams.FilterDescendantsInstances = {LocalPlayer.Character, Entity}
if not workspace:Raycast(Origin, Target - Origin, InfParams) then
local Tool = LocalPlayer.Character:FindFirstChild("Crucifix")
if Tool then
RemotesFolder.DropItem:FireServer(Tool)
repeat task.wait()
local Drop = workspace.Drops:FindFirstChild("Crucifix")
if Drop and Drop:FindFirstChildOfClass("ProximityPrompt") then fireproximityprompt(Drop:FindFirstChildOfClass("ProximityPrompt")) end
until LocalPlayer.Character:FindFirstChild("Crucifix")
end
end
end
end
end
end

if Toggles.AutoLibraryCode.Value then
if LatestRoom.Value == 50 then
local Code = GetLibraryCode()
if Code then
if Toggles.BruteForceLibCode.Value and string.find(Code, "") then
local Bruted = ""
for i = 1, #Code do
local char = string.sub(Code, i, i)
Bruted ..= (char == "" and math.random(0, 9) or char)
end
Code = Bruted
end
PL:FireServer(Code)
end
end
end

if Toggles.DoorReach.Value and DoorReach > 0.2 then
DoorReach = 0
local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
if currentRoom then
local doorContainer = currentRoom:FindFirstChild("Door")
if doorContainer and doorContainer:FindFirstChild("Door") then
local Door = doorContainer.Door
if doorContainer.Parent and doorContainer.Parent.Name ~= "101" and GetDistanceToPlayer(Door.Position) < 30 then
if doorContainer:FindFirstChild("ClientOpen") then
doorContainer.ClientOpen:FireServer()
end
end
end
end
end

if Toggles.NoAcc.Value then
if not Toggles.Flight.Value then
if LocalPlayer.Character.HumanoidRootPart.CustomPhysicalProperties ~= PhysicalProperties.new(100, 0.1, 0.1, 0.1, 0.1) then LocalPlayer.Character.HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0.1, 0.1, 0.1, 0.1) end
end
end

if Toggles.EnableJump.Value then
if not LocalPlayer.Character:GetAttribute("CanJump") then LocalPlayer.Character:SetAttribute("CanJump",true) end
end

if Toggles.EnableSlide.Value then
if not LocalPlayer.Character:GetAttribute("Sliding") then LocalPlayer.Character:SetAttribute("Sliding",true) end
end

if Toggles.AutoInteract.Value then
if AutoInteract > Options.AutoInteractDelay.Value then
AutoInteract = 0
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
for i = #Interactions, 1, -1 do
local prompt = Interactions[i]
if not prompt.Parent then continue end
if (prompt.Parent.Name == "GoldPile" and Floor.Value == "Fools") or prompt.Parent.Name == "KeyObtainFake" then continue end
if prompt.Parent.Parent and prompt.Parent.Parent.Parent and prompt.Parent.Parent.Parent.Name == "ItemSpawns" then continue end
if prompt:GetAttribute("InfItems") and prompt.Name ~= "InfPrompt" then continue end
if prompt.Parent.Name == "Mandrake" then continue end

        if prompt:GetAttribute("Interactions") and prompt:GetAttribute("Interactions") > 0 then
            table.remove(Interactions, i)
        end
        
        if prompt.Parent:IsA("BasePart") or prompt.Parent:IsA("Model") then
            local TargetPart = prompt.Parent:IsA("BasePart") and prompt.Parent or (prompt.Parent.PrimaryPart or prompt.Parent:FindFirstChildWhichIsA("BasePart"))
            if TargetPart then
                if (LocalPlayer.Character.HumanoidRootPart.Position - TargetPart.Position).Magnitude <= Options.AutoInteractreach.Value then
                    if not prompt.Enabled then prompt.Enabled = true end
                    if Firepp then fireproximityprompt(prompt) else prompt:InputHoldBegin(); prompt:InputHoldEnd(prompt.HoldDuration or 0) end
                end
            end
        end
    end
end


end

if Toggles.NoFog.Value then
if Lighting.FogEnd < 100000 then Lighting.FogEnd = 100000 end
for _, v in pairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") and v.Density > 0 then v.Density = 0 end end
end

if Toggles.NoCamShake.Value then
if RequiredMainGame then RequiredMainGame.csgo = CFrame.new(0,0,0) end
end

if Toggles.Player.Value and PlayerESP > 1 then
PlayerESP = 0
for _, v in pairs(Players:GetPlayers()) do
if v ~= LocalPlayer and v.Character then
local hum = v.Character:FindFirstChildOfClass("Humanoid")
if hum then
if hum.Health > 0 then AddESP(v.Character, v.Name .. " [" .. math.floor((hum.Health / hum.MaxHealth) * 100) .. "%]", PlayerColor)
else ESPLibrary:RemoveESP(v.Character) end
end
end
end
end

if Toggles.LadderBypass.Value then
if LocalPlayer.Character:GetAttribute("Climbing") then LocalPlayer.Character:SetAttribute("Climbing",false); Notify("Anticheat Bypassed this only works until you get a cutscene or Halt",5) end
end

-- OPTIMIZED: Network flooding resolved. Entity bypass calls are throttled to safe intervals
if EyesDelay > 0.2 then
    EyesDelay = 0
    if Toggles.EyesDamage.Value then
        if (workspace:FindFirstChild("Eyes") or workspace:FindFirstChild("Lookman")) and not LocalPlayer.Character:GetAttribute("Hiding") then
            if RemotesFolder.Name ~= "RemotesFolder" then MotorReplication:FireServer(0, -650, 0, false) else MotorReplication:FireServer(-650) end
        end
    end

    if Toggles.LookmanDamage.Value then
        if workspace:FindFirstChild("BackdoorLookman") and not LocalPlayer.Character:GetAttribute("Hiding") then 
            MotorReplication:FireServer(-650) 
        end
    end
end

-- OPTIMIZED: FullBright checks are scheduled rather than running frame-by-frame
if Toggles.FullBright.Value and FullBrightDelay > 0.3 then
    FullBrightDelay = 0
    if Lighting.Ambient ~= Color3.new(1, 1, 1) then Lighting.Ambient = Color3.new(1, 1, 1) end
    local currentRoom = workspace.CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom") or 0))
    local nextRoom = workspace.CurrentRooms:FindFirstChild(tostring((LocalPlayer:GetAttribute("CurrentRoom") or 0) + 1))

    if currentRoom then
        if not currentRoom:GetAttribute("OldAmbient") then currentRoom:SetAttribute("OldAmbient", currentRoom:GetAttribute("Ambient")) end
        if currentRoom:GetAttribute("Ambient") ~= Color3.new(1, 1, 1) then currentRoom:SetAttribute("Ambient", Color3.new(1, 1, 1)) end
    end

    if LatestRoom.Value < 100 and nextRoom then
        if not nextRoom:GetAttribute("OldAmbient") then nextRoom:SetAttribute("OldAmbient", nextRoom:GetAttribute("Ambient")) end
        if nextRoom:GetAttribute("Ambient") ~= Color3.new(1, 1, 1) then nextRoom:SetAttribute("Ambient", Color3.new(1, 1, 1)) end
    end
end

if Toggles.AntiCheatMani.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
if Options.AntiCheatManiMethod.Value == "Velocity" then
if not Toggles.NoClip.Value then Toggles.NoClip:SetValue(true) end
local BodyVelocity = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("VelocityMani") or Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart)
local LookingVector = LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 2
BodyVelocity.Velocity = Vector3.new(LookingVector.X, LookingVector.Y, LookingVector.Z)
BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
BodyVelocity.Name = "VelocityMani"
else
local currentPivot = LocalPlayer.Character:GetPivot()
LocalPlayer.Character:PivotTo(currentPivot  * CFrame.new(0, 0, 10000))
end
end

if Options.AutoInteractKeybind:GetState() and not Toggles.AutoInteract.Value then Toggles.AutoInteract:SetValue(true) end
if not Options.AutoInteractKeybind:GetState() and  Toggles.AutoInteract.Value then Toggles.AutoInteract:SetValue(false) end
if Options.NoclipKeybind:GetState() and not Toggles.NoClip.Value then Toggles.NoClip:SetValue(true) end
if not Options.NoclipKeybind:GetState() and  Toggles.NoClip.Value then Toggles.NoClip:SetValue(false) end
if Options.ThirdpersonKeybind:GetState() and not Toggles.ThirdPerson.Value then Toggles.ThirdPerson:SetValue(true) end
if not Options.ThirdpersonKeybind:GetState() and  Toggles.ThirdPerson.Value then Toggles.ThirdPerson:SetValue(false) end
if Options.AutoHideKeybind:GetState() and not Toggles.AutoHiding.Value then Toggles.AutoHiding:SetValue(true) end
if not Options.AutoHideKeybind:GetState() and  Toggles.AutoHiding.Value then Toggles.AutoHiding:SetValue(false) end
if Options.AntiCheatMan:GetState() and not Toggles.AntiCheatMani.Value then Toggles.AntiCheatMani:SetValue(true) end
if not Options.AntiCheatMan:GetState() and  Toggles.AntiCheatMani.Value then Toggles.AntiCheatMani:SetValue(false) end

if Toggles.NoClip.Value then
for _, v in ipairs(LocalPlayer.Character:GetChildren()) do
if v:IsA("BasePart") and v.Name ~= "CollisionClone" and v.CanCollide then v.CanCollide = false end
end
if LocalPlayer.Character:FindFirstChild("Collision") then
LocalPlayer.Character.Collision.CanCollide = false
if LocalPlayer.Character.Collision:FindFirstChild("CollisionCrouch") then LocalPlayer.Character.Collision.CollisionCrouch.CanCollide = false end
end
end

-- OPTIMIZED: Removed heavy frame-by-frame collision setter from the inactive loop branches

if Toggles.FastClosetExit.Value then
if LocalPlayer.Character:GetAttribute("Hiding") and LocalPlayer.Character.Humanoid.MoveDirection.Magnitude > 0.45 then CamLock:FireServer() end
end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
if Toggles.AutoRooms.Value then
if IsMoving then return end
if Toggles.IgnoreA60.Value and not Toggles.Godmode.Value then Toggles.Godmode:SetValue(true); Notify("Godmode Enabled Automatically For Ignore A-60", 5) end

    LocalPlayer.Character.Collision.Size = Vector3.new(1, 1, 3)
    local DangerousEntity = workspace:FindFirstChild("A120") or workspace:FindFirstChild("GlitchRush") or workspace:FindFirstChild("GlitchAmbush")
    local A60 = workspace:FindFirstChild("A60")
    
    local ShouldHide = false

    if DangerousEntity and DangerousEntity.PrimaryPart and DangerousEntity.PrimaryPart.Position.Y > -4 then ShouldHide = true
    elseif A60 and A60.PrimaryPart and A60.PrimaryPart.Position.Y > -4 then
        if not Toggles.IgnoreA60.Value then ShouldHide = true end
    end

    if ShouldHide then
        local Closet = GetNearestHidingSpot()
        if Closet then
            Closet.Base.CanCollide = false
            PathTo(Closet.Base.Position)
            if not LocalPlayer.Character.CollisionPart.Anchored then
                local prompt = Closet:FindFirstChildOfClass("ProximityPrompt", true)
                if prompt then fireproximityprompt(prompt) end
            end
        end
    else
        LocalPlayer.Character:SetAttribute("Hiding", false)
        local CurrentRoom = workspace.CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
        if CurrentRoom then
            local TargetDoor = CurrentRoom:FindFirstChild("Door")
            if TargetDoor and TargetDoor:FindFirstChild("Door") then PathTo(TargetDoor.Door.Position) end
        end
    end
end


end))

table.insert(Connections, LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
if LocalPlayer.Character:GetAttribute("FakeRevived") then
task.wait(0.3)
LocalPlayer:SetAttribute("CurrentRoom", tonumber(LatestRoom.Value))
end
IsMoving = false
end))

if HookMeta then
local Old
Old = hookmetamethod(game, "__namecall", function(Self, ...)
if Library.Unloaded then return Old(Self, ...) end
local Method = getnamecallmethod()
if Method == "FireServer" or Method == "InvokeServer" then
if Toggles.AutoHeartbeat.Value and Self.Name == "ClutchHeartbeat" then return Old(Self, true) end
if Method == "FireServer" and Toggles.FigureHearing.Value and Self.Name == "Crouch" then return Old(Self, true,true) end
end
return Old(Self, ...)
end)
end

-- STREAMING_CHUNK:Optimized Workspace Instance Creation...
table.insert(Connections, workspace.DescendantAdded:Connect(function(v)
task.spawn(function()
if not v.Parent then
local timeout = 0
repeat
timeout += task.wait(0.03)
until v.Parent or timeout > 0.5
end
if not v.Parent then return end

    if v.Parent:FindFirstChildOfClass("Humanoid") then return end
    if (v.Name == "Candle" and v.Parent.Name == "Candle" or v.Parent.Parent and v.Parent.Parent.Name == "Candle") then return end

    local vName = v.Name

    if HidingPlaces[vName] then table.insert(Closets, v) end
    if Toggles.Ladder.Value and vName == "Ladder" then AddESP(v, "Ladder", ladderColor) end
    if Toggles.Fuse.Value and vName == "FuseObtain" then AddESP(v, "Fuse", fuseColor) end

    if Toggles.AntiLag.Value and v:IsA("BasePart") then
        v:SetAttribute("Mat", v.Material)
        v.Material = Enum.Material.Plastic
    end

    if Toggles.InfItems.Value and v:IsA("ProximityPrompt") then
        if Names[v.Parent.Name] or vName == "FusesPrompt" or (v.Parent.Parent and v.Parent.Parent.Name == "Locker_Small_Locked") then
            table.insert(Stored, v)
        end
    end

    if Toggles.DeleteSeekFE.Value and vName == "TriggerEventCollision" then
        Notify("Deleting Seek", 3)
        local Part = v:FindFirstChild("Collision") or v.ChildAdded:Wait()
        if Part then
            Notify("DONT OPEN NEXT DOOR", 1)
            task.wait(0.1)
            for _, Item in pairs(v:GetChildren()) do
                if Item.Name == "Collision" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if FireTouch then
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, Item, 0)
                        task.wait()
                        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, Item, 1)
                    end
                end
            end
            task.wait(0.5)
            local Success = true
            for _, Item in pairs(v:GetChildren()) do
                if Item.Name == "Collision" then Success = false; break end
            end
            if Success then Notify("Deleted Seek Successfully Open Next Door", 3) else Notify("Failed To Delete Seek Open Next Door", 3) end
        end
    end

    if Toggles.SeekObf.Value and (vName == "Seek_Arm" or vName == "ChandelierObstruction") then
        for _, i in pairs(v:GetChildren()) do if i:IsA("BasePart") then i.CanTouch = false end end
    end

    if Toggles.Breakers.Value and vName == "LiveBreakerPolePickup" then AddESP(v, "Breaker", BreakerColor) end

    if Toggles.AutoMinecart.Value then
        if vName == "DuckBoard" then table.insert(DuckBoards, v) end
        if string.find(vName, "MinecartNode") then table.insert(Nodes, v) end
    end

    if Toggles.AntiSeekFlood.Value and vName == "SeekFloodline" then v.CanCollide = true end
    if Toggles.ShowPath.Value and vName == "SeekGuidingLight" then ShowSeekPath(v) end
    if Toggles.DeleteFigureFE.Value and (vName == "FigureRig" or vName == "FigureRagdoll") then table.insert(Figures, v) end

    if Toggles.PromptClip.Value and v:IsA("ProximityPrompt") then
        v:SetAttribute("Clip", v.RequiresLineOfSight)
        v.RequiresLineOfSight = false
    end

    if Toggles.Gold.Value and vName == "GoldPile" then AddESP(v, "Gold " .. (v:GetAttribute("GoldValue") or ""), GoldColor) end
    if Toggles.AutoBreaker.Value and vName == "ElevatorBreaker" then Breaker(v) end

    if Toggles.PromptReach.Value and v:IsA("ProximityPrompt") then
        v:SetAttribute("Range", v.MaxActivationDistance)
        v.MaxActivationDistance = v.MaxActivationDistance * 2
    end

    if Toggles.Books.Value and vName == "LiveHintBook" then AddESP(v, "Library Book", BookColor) end

    if Toggles.Snare.Value and vName == "Snare" then
        local waitTime = 0
        repeat task.wait(0.01); waitTime += 0.01 until waitTime > 1 or v:FindFirstChild("Hitbox")
        if v:FindFirstChild("Hitbox") then v.Hitbox.CanTouch = false end
    end

    if Toggles.Objective.Value then
        local Bro = Items[vName]
        if Bro then AddESP(v, Bro, ItemsColor) end
        if vName == "MinesAnchor" then
            local sign = v:WaitForChild("Sign", 3)
            if sign then AddESP(v, "Anchor " .. sign.TextLabel.Text, ItemsColor) end
        end
    end

    if Toggles.AntiLava.Value and vName == "Lava" then v.CanTouch = false end
    if Toggles.AntiWall.Value and vName == "ScaryWall" then
        for _, i in pairs(v:GetChildren()) do if i:IsA("BasePart") then i.CanTouch = false end end
    end
    if Toggles.RealBridge.Value and vName == "Bridge" and v.CanCollide == false then
        v.Transparency = Toggles.RealBridge.Value and 0 or 1
    end

    if Toggles.Entity.Value then
        if vName == "Snare" and v:FindFirstChild("Hitbox") then AddEntityESP(v, "Snare", EntityColor) end
        if vName == "DoorFake" and v.Parent and v.Parent.Name == "SideroomDupe" then AddEntityESP(v:WaitForChild("Door", 3), "Dupe", EntityColor) end
        if vName == "GrumbleRig" then AddEntityESP(v, "Grumble", EntityColor) end
        if vName == "Groundskeeper" then AddEntityESP(v, "Ground Keeper", EntityColor) end
        if vName == "MandrakeLive" then AddEntityESP(v, "Man Drake", EntityColor) end
        if vName == "LiveEntityBramble" then AddEntityESP(v, "Bramble", EntityColor) end
        if vName == "GiggleCeiling" then
            local waitTime = 0
            repeat task.wait(0.01); waitTime += 0.01 until waitTime > 2 or v:FindFirstChild("Hitbox")
            if v:FindFirstChild("Hitbox") then AddEntityESP(v, "Giggle", EntityColor) end
        end
        if vName == "FigureRig" or vName == "FigureRagdoll" then AddEntityESP(v, "Figure", EntityColor) end
    end

    if Toggles.Dupe.Value and vName == "DoorFake" and v.Parent and v.Parent.Name == "SideroomDupe" then
        local hidden = v:WaitForChild("Hidden", 3)
        if hidden then hidden.CanTouch = false end
    end

    if Toggles.FixBrokenBridge.Value and vName == "Bridge" then FixBridge(v) end
    if Toggles.AutoAnchorSolver.Value and vName == "MinesAnchor" then table.insert(Anchors, v) end
    if Toggles.GloomEggDamage.Value and vName == "GloomEgg" then
        repeat task.wait(0.1) until v:FindFirstChildWhichIsA("BasePart")
        for _, i in pairs(v:GetChildren()) do
            if i:IsA("BasePart") then i.CanTouch = false end
        end
    end

    if v:IsA("ProximityPrompt") then
        if not (PromptIgnore[vName] or (v.Parent and v.Parent.Name == "Padlock") or (v.Parent and v.Parent:GetAttribute("JeffShop")) or (v.Parent and v.Parent.Parent and v.Parent.Parent.Name == "RetroWardrobe")) then
            table.insert(Interactions, v)
        end
        if Toggles.InstaInteract.Value then
            v:SetAttribute("Duration", v.HoldDuration)
            v.HoldDuration = 0
        end
    end

    if Toggles.Giggle.Value and vName == "GiggleCeiling" then
        local hitbox = v:WaitForChild("Hitbox", 3)
        if hitbox then hitbox.CanTouch = false end
    end
end)


end))

-- STREAMING_CHUNK:Optimized Memory Collection System...
table.insert(Connections, workspace.DescendantRemoving:Connect(function(v)
if v:IsA("ProximityPrompt") then
for i = #Interactions, 1, -1 do
if Interactions[i] == v then table.remove(Interactions, i); break end
end
for i = #Stored, 1, -1 do
if Stored[i] == v then table.remove(Stored, i); break end
end
elseif HidingPlaces[v.Name] then
for i = #Closets, 1, -1 do
if Closets[i] == v then table.remove(Closets, i); break end
end
end
end))

local MenuGroup = Tabs.Settings:AddLeftGroupbox('UI Settings')
local UtilityBox = Tabs.Settings:AddRightGroupbox('Hub Utilities')

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle("ShowKeybinds", { Text = "Show Keybinds Overlay", Default = false }):OnChanged(function() Library.KeybindFrame.Visible = Toggles.ShowKeybinds.Value end)
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(Value) Library.ShowCustomCursor = Value end, })
MenuGroup:AddDivider()
MenuGroup:AddToggle('PlayNotifySound',{ Text = "Play Notification Sound", Default = true, Callback = function(Value) PlaySound = Value end })

MenuGroup:AddDropdown("NotificationSide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(Value) Library:SetNotifySide(Value) end, })
MenuGroup:AddDropdown("NotifyWay", { Values = { "Doors", "Library", "Supreme"}, Default = Notifying, Text = "Notification  Library", Callback = function(Value) Notifying = Value end, })
MenuGroup:AddButton('Test Notification',function() Notify("Hello World",2) end)

MenuGroup:AddDropdown("Library", { Values = { "Obsidian", "Linoria" }, Default = getgenv().ScriptLibrary, Text = "Library", Callback = function(Value) getgenv().ScriptLibrary = tostring(Value); Notify('Please Unload Script and Execute Again to Take Effect',4) end, })
MenuGroup:AddDropdown("RenderESPSpeed", { Values = { "10", "30", "60", "90", "120","144", "240"}, Default = Library.IsMobile and 2 or 6, Text = "ESP Rendering Speed", Callback = function(Value) ESPLibrary:SetRenderingSpeed(Value) end, })
MenuGroup:AddDivider()
MenuGroup:AddDropdown("DPIDropdown", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale", Callback = function(Value) Value = Value:gsub("%%", ""); local DPI = tonumber(Value); Library:SetDPIScale(DPI) end, })
UtilityBox:AddLabel('TheHunterSolo1 - Owner & Main Coder',true)
UtilityBox:AddLabel('nahhthatscrazy - Method 1 Speed Bypass',true)
UtilityBox:AddLabel('rhyan57 - Doors Notification Creator',true)
UtilityBox:AddLabel('FireBacon - ESPLibrary Creator',true)
UtilityBox:AddButton({
Text = "Unload Hub",
Func = function()
LocalPlayer:SetAttribute("SupremeLoaded", nil)
for _, con in pairs(Connections) do con:Disconnect() end

    local Dread = LocalPlayer:FindFirstChild("Dread",true) or LocalPlayer:FindFirstChild("_Dread",true)
    if Dread then Dread.Name = "Dread" end
    local Shade = ClientModules.EntityModules:FindFirstChild("Shade",true) or ClientModules.EntityModules:FindFirstChild("_Shade",true)
    if Shade then Shade.Name = "Shade" end

    FakeA90:Destroy()
    FakeScreech:Destroy()

    if ReplicatedStorage:FindFirstChild("Screech") then ReplicatedStorage:FindFirstChild("Screech").Parent = RemotesFolder end

    local getcons = getconnections or get_signal_cons or get_relative_connections
    if getcons then
        for _, con in pairs(getcons(LocalPlayer.Idled)) do
            if con.Enable then con:Enable() end
        end
    end

    local fcPart = workspace:FindFirstChild("FreecamPart")
    if fcPart then
        fcPart:Destroy()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
        LocalPlayer.CameraMinZoomDistance = LocalPlayer:GetAttribute("fc_om") or 0.5
        LocalPlayer.CameraMaxZoomDistance = LocalPlayer:GetAttribute("fc_ox") or 128
    end

    if ReplicatedStorage:FindFirstChild("A90") then ReplicatedStorage:FindFirstChild("A90").Parent = RemotesFolder end

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.CanTouch = true end
        if v.Name == "BridgeBarrier" then v:Destroy() end
    end

    if LocalPlayer.Character then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
        LocalPlayer.Character:SetAttribute("CanJump",false)
        for _, v in pairs(LocalPlayer.Character:GetChildren()) do
            if not (v.Name == "CollisionClone") and v:IsA("BasePart") then v.CanCollide = true end
        end
        if OldAccel then LocalPlayer.Character.HumanoidRootPart.CustomPhysicalProperties = OldAccel; OldAccel = nil end
        LocalPlayer.Character:SetAttribute("Sliding",false)
    end

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then v.HoldDuration = v:GetAttribute("Duration") or v.HoldDuration end
    end

    if OldFogEnd then Lighting.FogEnd = OldFogEnd; OldFogEnd = nil end
    for _, v in pairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") then v.Density = 0.94 end end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("VelocityMani") then
        LocalPlayer.Character.HumanoidRootPart:FindFirstChild("VelocityMani"):Destroy()
    end

    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    Lighting.GlobalShadows = true
    for _, v in pairs(workspace.CurrentRooms:GetChildren()) do
        v:SetAttribute("Ambient", v:GetAttribute("OldAmbient") and v:GetAttribute("OldAmbient") or Color3.new(0, 0, 0))
    end

    task.wait()
    if RemotesFolder:FindFirstChild("A90_") then RemotesFolder:FindFirstChild("A90_").Name = "A90" end
    if RemotesFolder:FindFirstChild("Screech_") then
        local Cutscene = RemoteListener:FindFirstChild("Cutscenes") or RemoteListener:FindFirstChild("Cutscenes_")
        if Cutscene then Cutscene.Name = "Cutscenes" end
        RemotesFolder:FindFirstChild("Screech_").Name = "Screech"
    end

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then v.MaxActivationDistance = v:GetAttribute("Range") or v.MaxActivationDistance end
        if v.Name == "SeekFloodline" then v.CanCollide = false end
    end

    for _, Prompt in pairs(workspace.CurrentRooms:GetDescendants()) do
        if Prompt:IsA("ProximityPrompt") then
            if Prompt.Parent and Names[Prompt.Parent.Name] and Prompt:GetAttribute("InfItems") then
                local Fake = Prompt.Parent:FindFirstChild("InfPrompt")
                if Fake then Fake:Destroy() end
                Prompt:SetAttribute("InfItems", nil)
                Prompt.Enabled = true
                Prompt.ClickablePrompt = true
            end
        end
    end

    for _, v in workspace.CurrentRooms:GetDescendants() do
        if v:IsA("BasePart") and v:GetAttribute("Mat") then v.Material = v:GetAttribute("Mat") or "Plastic" end
    end

    if CollisionClone then CollisionClone:Destroy(); CollisionClone = nil end

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then v.RequiresLineOfSight = v:GetAttribute("Clip") or true end
    end

    if PathFolder then PathFolder:Destroy() end
    if LocalPlayer.Character then
        LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
        LocalPlayer.Character.LowerTorso.Root.C1 = CFrame.new(Vector3.new(0, 0, 0))
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlightVelocity") then
        LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FlightVelocity"):Destroy()
    end

    if RemotesFolder:FindFirstChild("Crouch") then RemotesFolder.Crouch:FireServer(false) end
    if LocalPlayer.Character then
        LocalPlayer.Character.Collision.Position = LocalPlayer.Character.HumanoidRootPart.Position
        LocalPlayer.Character.Humanoid.HipHeight = 2.4
        if RemotesFolder.Name ~= "RemotesFolder" then LocalPlayer.Character.Collision.Position = LocalPlayer.Character.HumanoidRootPart.Position end
    end

    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetChildren()) do
            if v.Name ~= "CollisionClone" and v.Name ~= "Collision" and v.Name ~= "HumanoidRootPart" and v.Name ~= "CollisionPart" then
                if v:IsA("BasePart") then v.Transparency = 0 end
            end
        end
    end

    if ReplicatedStorage:FindFirstChild("LiveModifiers") and ReplicatedStorage:FindFirstChild("LiveModifiers"):FindFirstChild("Jammin") then
        local Jam = LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game").Health.Jam
        if Jam then Jam.Playing = true end
        local Jamming = game:GetService("SoundService").Main.Jamming
        if Jamming then Jamming.Enabled = true end
    end

    Library:Unload()
    ESPLibrary:Unload()
    ShouldStop = true
end


})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder("SupremeHub")
SaveManager:SetFolder("SupremeHub/DOORS")
SaveManager:BuildConfigSection(Tabs['Settings'])
ThemeManager:ApplyToTab(Tabs['Settings'])

Notify("Successfully Loaded for Game |  DOORS ",4)

end
end
