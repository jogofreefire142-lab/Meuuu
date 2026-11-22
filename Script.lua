
```lua
--[[ UNIVERSAL LITE v8.0 "DELTA EDITION" — FUNCIONA NO DELTA MOBILE ]]--
if getgenv()._UL_Cleanup then pcall(getgenv()._UL_Cleanup) end

-- ============================================================
-- 🛡️ SERVIÇOS & VARIÁVEIS GLOBAIS
-- ============================================================
local S = setmetatable({}, {__index = function(t, k) local v = game:GetService(k); t[k] = v; return v end})
local Plrs, Run, UIS, Light, TP, HS, VIM, CAS, Tween = S.Players, S.RunService, S.UserInputService, S.Lighting, S.TeleportService, S.HttpService, S.VirtualInputManager, S.ContextActionService, S.TweenService
local Cam, LP, PlaceId, JobId, Mouse = workspace.CurrentCamera, Plrs.LocalPlayer, game.PlaceId, game.JobId, Plrs.LocalPlayer:GetMouse()
if not game:IsLoaded() then game.Loaded:Wait() end
repeat Run.Heartbeat:Wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
task.wait(0.2)

-- ============================================================
-- 🛡️ CAPS & ANTI-KICK
-- ============================================================
local Cap = {}
Cap.File = pcall(function() writefile("__UL","") delfile("__UL") end)
Cap.Net = pcall(function() return HS:RequestAsync({Url="https://roblox.com", Method="GET"}) end)
Cap.Draw = pcall(function() local d = Drawing.new("Line"); d:Remove() end)
Cap.Hook = type(hookfunction) == "function"
Cap.Meta = type(getrawmetatable) == "function"
Cap.Queue = type(queue_on_teleport) == "function"

pcall(function()
    if Cap.Meta then local mt = getrawmetatable(game); local o = mt.__namecall; setreadonly(mt, false); mt.__namecall = newcclosure(function(s, ...) if s == LP and ({getnamecallmethod()})[1]:lower() == "kick" then return nil end return o(s, ...) end); setreadonly(mt, true) end
    if Cap.Hook then hookfunction(LP.Kick, function(s, ...) if s == LP then return end end) end
    if type(getconnections) == "function" then for _, c in pairs(getconnections(LP.Idled)) do c:Disable() end end
end)

-- ============================================================
-- ⚙️ CONFIG & PERSISTÊNCIA (JSON POR PLACEID)
-- ============================================================
local Folder, File = "UL_v8_Delta", "UL_v8_Delta/Cfg_" .. PlaceId .. ".json"
local SaveDeb = false
pcall(function() if not isfolder(Folder) then makefolder(Folder) end end)

local C = {
    -- Movement
    WS = 16, JP = 50, Grav = 196.2, InfJ = false, Fly = false, FlySpd = 100, FlyV = 1, FlyKey = "F", FlyBtn = true,
    Noclip = false, NoclipKey = "N", ClickTP = false, ClickKey = "LeftControl", ClickMethod = "CFrame", TouchTP = false,
    Bhop = false, EdgeJ = false, AirWalk = false, SwimFly = false, Spin = false, SpinSpd = 20, AutoSit = false,
    GlobalSpd = false, GVal = 100, Cap = 1000,
    -- Visuals
    ESP = false, ESP_HL = true, ESP_N = true, ESP_D = true, ESP_H = true, ESP_HB = true, ESP_TC = true, ESP_Max = 5000,
    FB = false, NoFog = false, NoShad = false, FOV = 70,
    -- Player Selector
    SelPlr = "Nenhum", Spec = false,
    -- Performance
    AntiAFK = false, AntiVoid = false, LowGFX = false, NoTex = false, NoPart = false, NoDec = false,
    Hitbox = false, HitSize = 10, HitTrans = 0.7, HitCol = Color3.fromRGB(255, 0, 0),
    _Flags = {}
}

local function Save(now)
    if now then local d = {} for k, v in pairs(C) do if type(v) ~= "function" and k:sub(1,1) ~= "_" then if typeof(v) == "Color3" then d[k] = {R = v.R, G = v.G, B = v.B} elseif typeof(v) == "EnumItem" then d[k] = v.Name else d[k] = v end end end pcall(function() writefile(File, HS:JSONEncode(d)) end) return end
    if SaveDeb then return end SaveDeb = true task.delay(1, function() SaveDeb = false Save(true) end)
end

local function Load()
    local ok, d = pcall(function() if isfile(File) then return HS:JSONDecode(readfile(File)) end end)
    if ok and d then for k, v in pairs(d) do if C[k] ~= nil then if type(v) == "table" and v.R then C[k] = Color3.new(v.R, v.G, v.B) elseif type(v) == "string" and Enum.KeyCode[v] and (k:find("Key") or k:find("bind") or k:find("Method") or k:find("Type") or k:find("Origin") or k:find("Part")) then C[k] = Enum.KeyCode[v] else C[k] = v end end end for k, v in pairs(C) do if type(v) == "boolean" then C._Flags[k] = v end end end
end
pcall(Load)

-- ============================================================
-- 🛡️ HELPERS & POOLS
-- =============================================================
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(p) p = p or LP local c = p.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end

local UI, P = {}, {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function Reg(n, fn, evt, int)
    if P.Conns[n] then Disc(P.Conns[n]) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- ============================================================
-- 🧠 APPLY FUNCTIONS
-- =============================================================
local function ApplyPhys()
    local h = Hum() local r = Root() if not h or not r then return end
    local t = C.GlobalSpd and math.clamp(C.GVal, 0, C.Cap) or math.clamp(C.WS, 0, C.Cap)
    pcall(function() h.WalkSpeed = t end)
    pcall(function() h.JumpPower = C.JP; h.UseJumpPower = true end)
    pcall(function() workspace.Gravity = C.Grav end)
    if C.AutoSit then pcall(function() Hum().Sit = true end) end
end

local function ApplyVis()
    pcall(function() Cam.FieldOfView = C.FOV end)
    pcall(function() Light.GlobalShadows = not C.NoShad end)
    pcall(function() Light.FogEnd = C.NoFog and 1e9 or 1e5 end)
    if C.FB then pcall(function() Light.Brightness = 2 Light.ClockTime = 14 Light.OutdoorAmbient = Color3.new(1,1,1) Light.Ambient = Color3.new(1,1,1) end) end
end

local function ApplyLow()
    if C.LowGFX then
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        if C.NoTex then for _, o in pairs(workspace:GetDescendants()) do if o:IsA("Texture") or o:IsA("Decal") then if not P.Tex then P.Tex = {} end if not P.Tex[o] then P.Tex[o] = o.Texture o.Texture = "" end end end end
        if C.NoPart then for _, o in pairs(workspace:GetDescendants()) do if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then if not P.Part then P.Part = {} end if not P.Part[o] then P.Part[o] = o.Enabled o.Enabled = false end end end end
        if C.NoDec then for _, o in pairs(workspace:GetDescendants()) do if o:IsA("Decal") then if not P.Dec then P.Dec = {} end if not P.Dec[o] then P.Dec[o] = o.Transparency o.Transparency = 1 end end end end
        for _, o in pairs(workspace:GetDescendants()) do if o:IsA("BasePart") and not o:IsA("MeshPart") and not o:IsA("UnionOperation") then if not P.Mat then P.Mat = {} end if not P.Mat[o] then P.Mat[o] = o.Material o.Material = Enum.Material.SmoothPlastic end end end
    else
        pcall(function() settings().Rendering.QualityLevel = 5 end)
        if P.Tex then for o, v in pairs(P.Tex) do if o and o.Parent then pcall(function() o.Texture = v end) end end table.clear(P.Tex) end
        if P.Part then for o, v in pairs(P.Part) do if o and o.Parent then pcall(function() o.Enabled = v end) end end table.clear(P.Part) end
        if P.Dec then for o, v in pairs(P.Dec) do if o and o.Parent then pcall(function() o.Transparency = v end) end end table.clear(P.Dec) end
        if P.Mat then for o, v in pairs(P.Mat) do if o and o.Parent then pcall(function() o.Material = v end) end end table.clear(P.Mat) end
    end
end

local ApplyAll = function() ApplyPhys() ApplyVis() ApplyLow() end

-- ============================================================
-- 🔁 LOOPS COM WATCHDOG
-- =============================================================
local PConns = {}
local function SafeLoop(n, fn, evt, int)
    if PConns[n] then pcall(function() PConns[n]:Disconnect() end) end
    local errs, last = 0, 0
    PConns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master (Heartbeat)
Reg("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

Reg("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
Reg("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function Reg(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- (Repetindo Reg para escopo local correto)
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false C[n] = false if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
    end)
end

-- Physics Master
RegLoop("Phys", function(dt)
    ApplyPhys()
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Bhop then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
    if C.EdgeJ then local h = Hum() local r = Root() if h and r and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > 0 then local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude if not workspace:Raycast(r.Position + r.CFrame.LookVector * 3, Vector3.new(0, -5, 0), p) then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end
    if C.AirWalk then local r = Root() local h = Hum() if r and h and h.FloorMaterial == Enum.Material.Air then if not P.Air then local pa = Instance.new("Part") pa.Name = "UL_Air" pa.Size = Vector3.new(6, 1, 6) pa.Transparency = 1 pa.Anchored = true pa.CanCollide = true pa.Parent = workspace P.Air = pa end pcall(function() P.Air.CFrame = CFrame.new(r.Position.X, r.Position.Y - 3.5, r.Position.Z) end) elseif P.Air then P.Air:Destroy() P.Air = nil end end
    if C.SwimFly then local h = Hum() local r = Root() if h and r then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState() ~= Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local m = h.MoveDirection if m.Magnitude > 0 then r.AssemblyLinearVelocity = m * C.WS + Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end end) end end
end, Run.Heartbeat, 0)

RegLoop("Noclip", function() if C.Noclip then local c = LP.Character if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end end end end end, Run.Stepped, 0)
RegLoop("Safety", function() local r = Root() if C.AntiVoid and r and r.Position.Y < -50 then r.CFrame = CFrame.new(0, 50, 0) r.AssemblyLinearVelocity = Vector3.zero end if C.AntiVoid and r and r.AssemblyLinearVelocity.Y < -100 then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end end, Run.Heartbeat, 0)

task.spawn(function() while true do task.wait(1) if C._Flags.FB or C._Flags.NoFog or C._Flags.NoShad or C._Flags.LowGFX then ApplyVis() ApplyLow() end end end)

-- ============================================================
-- 🔴 FLY / NOCLIP / FREECAM / INPUT (CANCOLLIDE FIX)
-- =============================================================
local P = {HL = {}, BB = {}, HB = {}, Spin = nil, Air = nil, Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X = 0, Y = 0, Z = 0}}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Head(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Head") end
local function Torso(c) c = c or LP.Character if not c then return nil end return c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local Clamp = function(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegLoop(n, fn, evt, int)
    if P.Conns[n] then pcall(function() P.Conns[n]:Disconnect() end) end
    local errs, last = 0, 0
    P.Conns[n] = evt:Connect(function(dt)
        if not C._Flags[n] then return end
        if int and int > 0 then if os.clock() - last < int then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then errs = errs + 1 warn("[WD] " .. n ..
