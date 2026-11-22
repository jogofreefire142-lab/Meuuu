
```lua
--[[ UNIVERSAL LITE v7.3 "IRONCLAD MOBILE" — ZERO NIL ERRORS, AUTO FALLBACK UI ]]--
if getgenv()._UL_Cleanup then pcall(getgenv()._UL_Cleanup) end

-- ============================================================
-- 🛡️ SERVIÇOS & VARIÁVEIS (SEMPRE DEFINIDOS ANTES DE USAR)
-- ============================================================
local S = setmetatable({}, {__index = function(t, k) local v = game:GetService(k); t[k] = v; return v end})
local Plrs, Run, UIS, Light, TP, HS, VIM, CAS, Tween = S.Players, S.RunService, S.UserInputService, S.Lighting, S.TeleportService, S.HttpService, S.VirtualInputManager, S.ContextActionService, S.TweenService
local Cam, LP, PlaceId, JobId, Mouse = workspace.CurrentCamera, Plrs.LocalPlayer, game.PlaceId, game.JobId, Plrs.LocalPlayer:GetMouse()
if not game:IsLoaded() then game.Loaded:Wait() end
repeat Run.Heartbeat:Wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
task.wait(0.2)

-- ============================================================
-- 🛡️ CAPS & ANTI-KICK (SEGURO)
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
-- ⚙️ CONFIG & PERSISTÊNCIA
-- ============================================================
local Folder, File = "UL_v7_Ironclad", "UL_v7_Ironclad/Cfg_" .. PlaceId .. ".json"
local SaveDeb = false
pcall(function() if not isfolder(Folder) then makefolder(Folder) end end)

local C = {
    WS = 16, JP = 50, Grav = 196.2, InfJ = false, Fly = false, FlySpd = 100, FlyV = 1, FlyKey = "F", FlyBtn = true,
    Noclip = false, NoclipKey = "N", ClickTP = false, ClickKey = "LeftControl", ClickMethod = "CFrame", TouchTP = false,
    Bhop = false, EdgeJ = false, AirWalk = false, SwimFly = false, Spin = false, SpinSpd = 20, AutoSit = false,
    GlobalSpd = false, GVal = 100, Cap = 1000,
    ESP = false, ESP_HL = true, ESP_N = true, ESP_D = true, ESP_H = true, ESP_HB = true, ESP_TC = true, ESP_Max = 5000,
    FB = false, NoFog = false, NoShad = false, FOV = 70,
    SelPlr = "Nenhum", Spec = false,
    AntiAFK = false, AntiVoid = false, LowGFX = false, NoTex = false, NoPart = false, NoDec = false,
    Hitbox = false, HitSize = 10, HitTrans = 0.7, HitCol = Color3.fromRGB(255, 0, 0),
    AntiAFK = false, _Flags = {}
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
-- 🛡️ HELPERS & POOLS (BLINDADOS)
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
        if not ok then errs = errs + 1 warn("[WD] " .. n .. ": " .. err) if errs >= 3 then C._Flags[n] = false; C[n] = false; if UI[n] then pcall(function() UI[n]:Set(false) end) end end else errs = 0 end
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
local Fin = {X = 0, Y = 0, Z = 0}
UIS.InputBegan:Connect(function(i, gp) if gp then return end if i.KeyCode == Enum.KeyCode.W then P.FIn.Z = -1 elseif i.KeyCode == Enum.KeyCode.S then P.FIn.Z = 1 elseif i.KeyCode == Enum.KeyCode.A then P.FIn.X = -1 elseif i.KeyCode == Enum.KeyCode.D then P.FIn.X = 1 elseif i.KeyCode == Enum.KeyCode.Space then P.FIn.Y = 1 elseif i.KeyCode == Enum.KeyCode.LeftShift then P.FIn.Y = -1 end end)
UIS.InputEnded:Connect(function(i) if i.KeyCode == Enum.KeyCode.W and P.FIn.Z == -1 then P.FIn.Z = 0 elseif i.KeyCode == Enum.KeyCode.S and P.FIn.Z == 1 then P.FIn.Z = 0 elseif i.KeyCode == Enum.KeyCode.A and P.FIn.X == -1 then P.FIn.X = 0 elseif i.KeyCode == Enum.KeyCode.D and P.FIn.X == 1 then P.FIn.X = 0 elseif i.KeyCode == Enum.KeyCode.Space and P.FIn.Y == 1 then P.FIn.Y = 0 elseif i.KeyCode == Enum.KeyCode.LeftShift and P.FIn.Y == -1 then P.FIn.Y = 0 end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.Gamepad1 then if i.KeyCode == Enum.KeyCode.Thumbstick1 then P.FIn.X = i.Position.X P.FIn.Z = i.Position.Y elseif i.KeyCode == Enum.KeyCode.Thumbstick2 then P.FIn.Y = i.Position.Y end end end)

local function ToggleFly(st)
    C.Fly = st C._Flags.Fly = st
    local h = Hum() local r = Root()
    if st and (not h or not r) then C.Fly = false C._Flags.Fly = false return end
    if st then
        P.FlyCol = {} for _, p in pairs((LP.Character or {}):GetDescendants()) do if p:IsA("BasePart") then P.FlyCol[p] = p.CanCollide p.CanCollide = false end end
        pcall(function() h.PlatformStand = true h.WalkSpeed = 0 h.JumpPower = 0 end)
        P.Fly = Run.RenderStepped:Connect(function(dt)
            if not C.Fly then ToggleFly(false) return end
            h = Hum() r = Root() if not h or not r then ToggleFly(false) return end
            local cf = Cam.CFrame local mv = Vector3.zero
            mv = mv + (cf.RightVector * P.FIn.X) + (cf.LookVector * P.FIn.Z) + (Vector3.new(0, 1, 0) * P.FIn.Y)
            if mv.Magnitude > 0 then local spd = (C.GlobalSpd and C.GVal or C.FlySpd) * C.FlyV r.CFrame = r.CFrame + (mv.Unit * spd * dt) else r.AssemblyLinearVelocity = Vector3.new(0, 0.001, 0) end
            pcall(function() r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero r.CFrame = CFrame.new(r.CFrame.Position, r.CFrame.Position + cf.LookVector) end)
        end)
    else
        if P.Fly then P.Fly:Disconnect() P.Fly = nil end
        pcall(function() h.PlatformStand = false end)
        for p, s in pairs(P.FlyCol) do if p and p.Parent then pcall(function() p.CanCollide = s end) end end P.FlyCol = {}
        if P.Spin then P.Spin:Destroy() P.Spin = nil end
    end
    Save(true)
end

local function ToggleNoclip(st) C.Noclip = st C._Flags.Noclip = st Save(true) end
local function ToggleFreecam(st)
    C.Freecam = st C._Flags.Freecam = st
    local h = Hum()
    if st then Cam.CameraType = Enum.CameraType.Scriptable Cam.CameraSubject = nil if h then h.WalkSpeed = 0 h.JumpPower = 0 end P.FC = Run.RenderStepped:Connect(function(dt) if not C.Freecam then ToggleFreecam(false) return end local cf = Cam.CFrame local v = Vector3.zero local s = 100 * dt if UIS:IsKeyDown(Enum.KeyCode.W) then v += cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.S) then v -= cf.LookVector end if UIS:IsKeyDown(Enum.KeyCode.D) then v += cf.RightVector end if UIS:IsKeyDown(Enum.KeyCode.A) then v -= cf.RightVector end if UIS:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.new(0, 1, 0) end if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then v -= Vector3.new(0, 1, 0) end if v.Magnitude > 0 then Cam.CFrame = cf + v.Unit * s end end) else if P.FC then P.FC:Disconnect() P.FC = nil end Cam.CameraType = Enum.CameraType.Custom Cam.CameraSubject = h if h then ApplyPhys() end end Save(true) end

UIS.InputBegan:Connect(function(i, gp) if gp then return end if i.KeyCode == Enum.KeyCode.W then P.FIn.Z = -1 elseif i.KeyCode == Enum.KeyCode.S then P.FIn.Z = 1 elseif i.KeyCode == Enum.KeyCode.A then P.FIn.X = -1 elseif i.KeyCode == Enum.KeyCode.D then P.FIn.X = 1 elseif i.KeyCode == Enum.KeyCode.Space then P.FIn.Y = 1 elseif i.KeyCode == Enum.KeyCode.LeftShift then P.FIn.Y = -1 end if i.KeyCode == C.FlyKey then ToggleFly(not C.Fly) end if i.KeyCode == C.NoclipKey then ToggleNoclip(not C.Noclip) end end)

-- Mobile Button
if C.FlyBtn then pcall(function() CAS:BindAction("UL_Fly", function(n, s, i) if s == Enum.UserInputState.Begin then ToggleFly(not C.Fly) end end, true, Enum.KeyCode.ButtonR3) CAS:SetTitle("UL_Fly", "Fly") CAS:SetPosition("UL_Fly", UDim2.new(1, -110, 1, -110)) end) end

-- ============================================================
-- 👁️ ESP / PLAYER SELECTOR / TOUCH TP
-- =============================================================
local function GetDraw(t, pr) local o = Drawing.new(t) for k, v in pairs(pr) do o[k] = v end return o end
local function ClrESP(plr) for _, t in pairs({P.HL, P.BB, P.HB}) do if t[plr] then pcall(function() t[plr]:Destroy() end) t[plr] = nil end end end
local function UpdESP(plr)
    if not C.ESP or plr == LP or not Alive(plr) then ClrESP(plr) return end
    local myR = Root() local tR = Root(plr.Character) if myR and tR and (myR.Position - tR.Position).Magnitude > C.ESPMax then ClrESP(plr) return end
    local ch = plr.Character local hm = Hum(ch) local hd = Head(ch) local tr = Torso(ch) if not hm or hm.Health <= 0 or not hd or not tr then ClrESP(plr) return end
    local ec = C.ESPTc and plr.TeamColor.Color or Color3.new(1, 0, 0)
    if C.ESPHl then local hl = P.HL[plr] if not hl or not hl.Parent or hl.Adornee ~= ch then if hl then pcall(function() hl:Destroy() end) end hl = Instance.new("Highlight") hl.Adornee = ch hl.FillTransparency = 0.5 hl.OutlineTransparency = 0 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop hl.Parent = ch P.HL[plr] = hl end hl.FillColor = ec hl.OutlineColor = Color3.new(1, 1, 1) elseif P.HL[plr] then ClrESP(plr) end
    if C.ESP_N or C.ESP_D or C.ESP_H then local bg = P.BB[plr] if not bg or not bg.Parent or bg.Adornee ~= hd then if bg then pcall(function() bg:Destroy() end) end bg = Instance.new("BillboardGui") bg.Adornee = hd bg.Size = UDim2.new(0, 200, 0, 70) bg.StudsOffset = Vector3.new(0, 3.5, 0) bg.AlwaysOnTop = true bg.Parent = hd local tl = Instance.new("TextLabel") tl.Size = UDim2.new(1, 0, 1, 0) tl.BackgroundTransparency = 1 tl.TextColor3 = Color3.new(1, 1, 1) tl.TextStrokeTransparency = 0 tl.TextScaled = true tl.Font = Enum.Font.GothamBold tl.Parent = bg P.BB[plr] = bg end local myR = Root() local d = myR and (myR.Position - Root(plr.Character).Position).Magnitude or 0 local t = {} if C.ESP_N then table.insert(t, plr.Name) end if C.ESP_D then table.insert(t, "[" .. math.floor(d) .. "m]") end if C.ESP_H then table.insert(t, "❤️" .. math.floor(Hum(plr.Character).Health) .. "/" .. math.floor(Hum(plr.Character).MaxHealth)) end P.BB[plr].I.Text = table.concat(t, " ") P.BB[plr].I.TextColor = C.ESPTc and BrickColor.new(plr.TeamColor.Color) or BrickColor.new("Really red") elseif P.BB[plr] then ClrESP(plr) end
    if C.ESP_HB then local hb = P.HB[plr] if not hb or not hb.Parent or hb.Adornee ~= hd then if hb then pcall(function() hb:Destroy() end) end hb = Instance.new("BillboardGui") hb.Adornee = hd hb.Size = UDim2.new(4, 0, 0.5, 0) hb.StudsOffset = Vector3.new(0, 5.5, 0) hb.AlwaysOnTop = true hb.Parent = hd local bf = Instance.new("Frame") bf.Size = UDim2.new(1, 0, 1, 0) bf.BackgroundColor3 = Color3.new(0, 0, 0) bf.BackgroundTransparency = 0.5 bf.BorderSizePixel = 0 bf.Parent = hb local fl = Instance.new("Frame") fl.Size = UDim2.new(1, 0, 1, 0) fl.BackgroundColor3 = Color3.new(0, 1, 0) fl.BorderSizePixel = 0 fl.Parent = bf Instance.new("UICorner", bf).CornerRadius = UDim.new(0, 2) P.HB[plr] = hb end local pct = Hum(plr.Character).Health / Hum(plr.Character).MaxHealth P.HB[plr].F.Size = UDim2.new(pct, 0, 1, 0) P.HB[plr].F.BackgroundColor3 = Color3.new(1 - pct, pct, 0) elseif P.HB[plr] then pcall(function() P.HB[plr]:Destroy() end) P.HB[plr] = nil end
end

Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(function() task.wait(0.3) UpdESP(plr) UpdateDD() end) end)
Players.PlayerRemoving:Connect(function(plr) ClrESP(plr) UpdateDD() end)
for _, plr in pairs(Plrs:GetPlayers()) do if plr ~= LP then plr.CharacterAdded:Connect(function() task.wait(0.3) UpdESP(plr) UpdateDD() end) task.spawn(function() if plr.Character then UpdESP(plr) end end) end end
task.spawn(function() while true do task.wait(1/30) if C.ESP then for _, plr in pairs(Plrs:GetPlayers()) do if plr ~= LP then UpdESP(plr) end end else for plr in pairs(P.HL) do ClrESP(plr) end end end end)

-- Player Selector
local function UpdateDD() if not UI.DDPlr then return end local opts = {"Nenhum"} for _, plr in pairs(Plrs:GetPlayers()) do if plr ~= LP then table.insert(opts, plr.Name) end end UI.DDPlr:Refresh(opts, false) end
local function TPTo(plrName) if plrName == "Nenhum" then return end local plr = Plrs:FindFirstChild(plrName) if plr and Alive(plr) then local myR = Root() local tR = Root(plr.Character) if myR and tR then myR.CFrame = tR.CFrame * CFrame.new(0, 3, 2) end end end
local function Spec(st, name) if not st or name == "Nenhum" then Cam.CameraSubject = Hum() return end local plr = Plrs:FindFirstChild(name) if plr and Alive(plr) then Cam.CameraSubject = Hum(plr.Character) end end

-- Touch TP
UIS.TouchStarted:Connect(function(t, gp) if C.ClickTP and C.TouchTP and not gp then local r = Root() if r then local ray = Cam:ViewportPointToRay(t.Position.X, t.Position.Y) local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, p) if hit then r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end end end end)
UIS.InputBegan:Connect(function(i, gp) if C.ClickTP and not C.TouchTP and not gp and i.KeyCode == C.ClickKey then local r = Root() if r then local ray = Cam:ViewportPointToRay(Mouse.X, Mouse.Y) local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, p) if hit then r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end end end end)

UIS.JumpRequest:Connect(function() if C.InfJ then local h = Hum() if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)
LP.Idled:Connect(function() if C.AntiAFK then VIM:SendMouseButtonEvent(100, 100, 0, true, game, 0) task.wait(0.02) VIM:SendMouseButtonEvent(100, 100, 0, false, game, 0) VIM:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game) task.wait(0.05) VIM:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game) end end)
LP.CharacterAdded:Connect(function() task.wait(0.5) ApplyAll() if C.Fly then ToggleFly(true) end if C.Freecam then ToggleFreecam(true) end if C.Noclip then ToggleNoclip(true) end if C.Spec and C.SelPlr ~= "Nenhum" then Spec(true, C.SelPlr) end UpdateDD() end)

-- Hitbox
Run.Heartbeat:Connect(function()
    if C.Hitbox then for _, plr in pairs(Plrs:GetPlayers()) do if plr ~= LP and Alive(plr) then local r = Root(plr.Character) if r then r.Size = Vector3.new(C.HitSize, C.HitSize, C.HitSize) r.Transparency = C.HitTrans r.Color = C.HitCol r.Material = Enum.Material.ForceField r.CanCollide = false r.Massless = true end end end else for _, plr in pairs(Plrs:GetPlayers()) do if plr ~= LP and Alive(plr) then local r = Root(plr.Character) if r then r.Size = Vector3.new(2, 2, 1) r.Transparency = 1 r.CanCollide = false r.Massless = true r.Color = Color3.new(1, 1, 1) r.Material = Enum.Material.Plastic end end end end
end)

-- ============================================================
-- 🖥️ UI: RAYFIELD EMBEDDED MINIMAL + FALLBACK NATIVO
-- =============================================================
local Rayfield = nil
local RayfieldErr = nil

-- 1. Tenta Carregar Rayfield Oficiais (HttpGet) com Timeout
task.spawn(function()
    local ok, res = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", true)
    end)
    if ok and res and #res > 1000 then
        local fn, err = loadstring(res)
        if fn then
            local ok2, lib = pcall(fn)
            if ok2 and lib then Rayfield = lib end
        end
    end
end)

-- 2. Aguarda 3s pelo HttpGet. Se falhar, usa UI Nativa (Fallback Imediato)
task.wait(3)
if not Rayfield then
    print("[UniversalLite] HttpGet Falhou/Timeout. Carregando UI Nativa (Fallback)...")
    Rayfield = {
        CreateWindow = function(self, settings)
            local self = setmetatable({}, {__index = self})
            self.ScreenGui = Instance.new("ScreenGui")
            self.ScreenGui.Name = "UniversalLite_Native"
            self.ScreenGui.ResetOnSpawn = false
            self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            pcall(function() self.ScreenGui.Parent = game:GetService("CoreGui") end)
            if not self.ScreenGui.Parent then self.ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

            local Main = Instance.new("Frame")
            Main.Name = "Main"
            Main.Size = UDim2.new(0, 500, 0, 400)
            Main.Position = UDim2.new(0.5, -250, 0.5, -200)
            Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            Main.BorderSizePixel = 0
            Main.Active = true
            Main.Draggable = true
            Main.Parent = self.ScreenGui
            Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
            Instance.new("UIStroke", Main).Color = Color3.fromRGB(0, 170, 255)

            local Top = Instance.new("Frame", Main)
            Top.Size = UDim2.new(1, 0, 0, 40)
            Top.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 6)
            local Title = Instance.new("TextLabel", Top)
            Title.Text = settings.Name or "Universal Lite"
            Title.Size = UDim2.new(1, -20, 1, 0)
            Title.Position = UDim2.new(0, 15, 0, 0)
            Title.BackgroundTransparency = 1
            Title.TextColor3 = Color3.new(1, 1, 1)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 16
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local TabBar = Instance.new("Frame", Main)
            TabBar.Name = "TabBar"
            TabBar.Size = UDim2.new(0, 120, 1, -40)
            TabBar.Position = UDim2.new(0, 0, 0, 40)
            TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            Instance.new("UIListLayout", TabBar).Padding = UDim.new(0, 5)

            local Pages = Instance.new("Folder", Main)
            Pages.Name = "Pages"

            function self:Notify(d)
                local N = Instance.new("Frame")
                N.Size = UDim2.new(0, 300, 0, 80)
                N.Position = UDim2.new(1, -310, 1, -90)
                N.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                N.Parent = self.ScreenGui
                Instance.new("UICorner", N).CornerRadius = UDim.new(0, 6)
                local L = Instance.new("TextLabel", N)
                L.Text = (d.Title or "") .. "\n" .. (d.Content or "")
                L.Size = UDim2.new(1, -20, 1, -20)
                L.Position = UDim2.new(0, 10, 0, 10)
                L.BackgroundTransparency = 1
                L.TextColor3 = Color3.new(1, 1, 1)
                L.Font = Enum.Font.Gotham
                L.TextSize = 14
                L.TextWrapped = true
                L.TextXAlignment = Enum.TextXAlignment.Left
                Tween:Create(N, TweenInfo.new(0.5), {Position = UDim2.new(1, -310, 1, -90)}):Play()
                task.delay(d.Duration or 5, function() N:Destroy() end)
            end

            function self:CreateTab(name, icon)
                local tab = {}
                local Btn = Instance.new("TextButton", TabBar)
                Btn.Text = name
                Btn.Size = UDim2.new(1, -10, 0, 30)
                Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                Btn.TextColor3 = Color3.new(1, 1, 1)
                Btn.Font = Enum.Font.Gotham
                Btn.TextSize = 14
                Btn.AutoButtonColor = false
                Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

                local Page = Instance.new("ScrollingFrame", Pages)
                Page.Name = name
                Page.Size = UDim2.new(1, -130, 1, -50)
                Page.Position = UDim2.new(0, 130, 0, 40)
                Page.BackgroundTransparency = 1
                Page.ScrollBarThickness = 3
                Page.Visible = false
                Page.CanvasSize = UDim2.new(0, 0, 0, 0)
                local PList = Instance.new("UIListLayout", Page)
                PList.Padding = UDim.new(0, 8)
                PList.HorizontalAlignment = Enum.HorizontalAlignment.Center
                PList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Page.CanvasSize = UDim2.new(0, 0, 0, PList.AbsoluteContentSize.Y + 20) end)

                local first = (#Pages:GetChildren() == 0)
                if first then Page.Visible = true Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end

                Btn.MouseButton1Click:Connect(function()
                    for _, p in pairs(Pages:GetChildren()) do p.Visible = false end
                    for _, b in pairs(TabBar:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(35, 35, 40) end end
                    Page.Visible = true
                    Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                end)

                function tab:CreateSection(n)
                    local L = Instance.new("TextLabel", Page)
                    L.Text = "  " .. n
                    L.Size = UDim2.new(1, -20, 0, 25)
                    L.BackgroundTransparency = 1
                    L.TextColor3 = Color3.fromRGB(150, 150, 150)
                    L.Font = Enum.Font.GothamBold
                    L.TextSize = 13
                    L.TextXAlignment = Enum.TextXAlignment.Left
                    return L
                end

                function tab:CreateToggle(p)
                    local F = Instance.new("Frame", Page)
                    F.Size = UDim2.new(1, -20, 0, 40)
                    F.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 4)
                    local L = Instance.new("TextLabel", F)
                    L.Text = p.Name
                    L.Size = UDim2.new(1, -60, 1, 0)
                    L.Position = UDim2.new(0, 15, 0, 0)
                    L.BackgroundTransparency = 1
                    L.TextColor3 = Color3.new(1, 1, 1)
                    L.Font = Enum.Font.Gotham
                    L.TextSize = 14
                    L.TextXAlignment = Enum.TextXAlignment.Left
                    local B = Instance.new("TextButton", F)
                    B.Size = UDim2.new(0, 40, 0, 20)
                    B.Position = UDim2.new(1, -50, 0.5, -10)
                    B.BackgroundColor3 = p.CurrentValue and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)
                    B.Text = ""
                    Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
                    local C = Instance.new("Frame", B)
                    C.Size = UDim2.new(0, 18, 0, 18)
                    C.Position = p.CurrentValue and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)
                    C.BackgroundColor3 = Color3.new(1, 1, 1)
                    Instance.new("UICorner", C).CornerRadius = UDim.new(1, 0)
                    local st = p.CurrentValue
                    local function Set(v)
                        st = v
                        game:GetService("TweenService"):Create(B, TweenInfo.new(0.2), {BackgroundColor3 = v and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)}):Play()
                        game:GetService("TweenService"):Create(C, TweenInfo.new(0.2), {Position = v and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)}):Play()
                    end
                    B.MouseButton1Click:Connect(function() Set(not st) if p.Callback then p.Callback(st) end end)
                    return {Set = Set}
                end

                function tab:CreateSlider(p)
                    local F = Instance.new("Frame", Page)
                    F.Size = UDim2.new(1, -20, 0, 50)
                    F.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 4)
                    local L = Instance.new("TextLabel", F)
                    L.Text = p.Name .. " : " .. p.CurrentValue
                    L.Size = UDim2.new(1, -20, 0, 25)
                    L.Position = UDim2.new(0, 15, 0, 0)
                    L.BackgroundTransparency = 1
                    L.TextColor3 = Color3.new(1, 1, 1)
                    L.Font = Enum.Font.Gotham
                    L.TextSize = 14
                    L.TextXAlignment = Enum.TextXAlignment.Left
                    local B = Instance.new("Frame", F)
                    B.Size = UDim2.new(1, -30, 0, 6)
                    B.Position = UDim2.new(0, 15, 0, 35)
                    B.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                    Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
                    local Fll = Instance.new("Frame", B)
                    Fll.Size = UDim2.new((p.CurrentValue - p.Range[1]) / (p.Range[2] - p.Range[1]), 1, 0)
                    Fll.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                    Instance.new("UICorner", Fll).CornerRadius = UDim.new(1, 0)
                    local K = Instance.new("Frame", B)
                    K.Size = UDim2.new(0, 14, 0, 14)
                    K.Position = UDim2.new(Fll.Size.X.Scale, -7, 0.5, -7)
                    K.BackgroundColor3 = Color3.new(1, 1, 1)
                    K.ZIndex = 2
                    Instance.new("UICorner", K).CornerRadius = UDim.new(1, 0)
                    local drag = false
                    local function Upd(i)
                        local p = math.clamp((i.Position.X - B.AbsolutePosition.X) / B.AbsoluteSize.X, 0, 1)
                        local v = math.floor(p.Range[1] + p * (p.Range[2] - p.Range[1]))
                        Fll.Size = UDim2.new(p, 0, 1, 0)
                        K.Position = UDim2.new(p, -7, 0.5, -7)
                        L.Text = p.Name .. " : " .. v
                        if p.Callback then p.Callback(v) end
                    end
                    B.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true Upd(i) end end)
                    game:GetService("UserInputService").InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
                    game:GetService("UserInputService").InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Upd(i) end end)
                    return {Set = function(v) L.Text = p.Name .. " : " .. v local p = (v - p.Range[1]) / (p.Range[2] - p.Range[1]) Fll.Size = UDim2.new(p, 0, 1, 0) K.Position = UDim2.new(p, -7, 0.5, -7) end}
                end

                function tab:CreateButton(p)
                    local B = Instance.new("TextButton", Page)
                    B.Text = p.Name
                    B.Size = UDim2.new(1, -20, 0, 35)
                    B.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                    B.TextColor3 = Color3.new(1, 1, 1)
                    B.Font = Enum.Font.GothamBold
                    B.TextSize = 14
                    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
                    B.MouseButton1Click:Connect(function() if p.Callback then p.Callback() end end)
                    return B
                end

                function tab:CreateDropdown(p)
                    local B = Instance.new("TextButton", Page)
                    B.Text = p.Name .. ": " .. tostring(p.CurrentOption)
                    B.Size = UDim2.new(1, -20, 0, 35)
                    B.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                    B.TextColor3 = Color3.new(1, 1, 1)
                    B.Font = Enum.Font.Gotham
                    B.TextSize = 14
                    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
                    local idx = 1
                    B.MouseButton1Click:Connect(function()
                        idx = idx + 1
                        if idx > #p.Options then idx = 1 end
                        local v = p.Options[idx]
                        B.Text = p.Name .. ": " .. tostring(v)
                        if p.Callback then p.Callback({v}) end
                    end)
                    return {Refresh = function(opts, cur) p.Options = opts if cur then B.Text = p.Name .. ": " .. tostring(cur) end end, Set = function(v) B.Text = p.Name .. ": " .. tostring(v) end}
                end

                function tab:CreateColorPicker(p)
                    local B = Instance.new("TextButton", Page)
                    B.Text = p.Name
                    B.Size = UDim2.new(1, -20, 0, 35)
                    B.BackgroundColor3 = p.Color
                    B.TextColor3 = Color3.new(1, 1, 1)
                    B.Font = Enum.Font.Gotham
                    B.TextSize = 14
                    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
                    B.MouseButton1Click:Connect(function() if p.Callback then p.Callback(p.Color) end end)
                    return {Set = function(v) B.BackgroundColor3 = v end}
                end

                function tab:CreateLabel(t)
                    local L = Instance.new("TextLabel", Page)
                    L.Text = t
                    L.Size = UDim2.new(1, -20, 0, 25)
                    L.BackgroundTransparency = 1
                    L.TextColor3 = Color3.fromRGB(150, 150, 150)
                    L.Font = Enum.Font.Gotham
                    L.TextSize = 13
                    L.TextXAlignment = Enum.TextXAlignment.Left
                    return L
                end

                return tab
            end

            return self
        end
    }
end

-- ============================================================
-- 🖥️ UI BUILD (RAYFIELD OU NATIVO)
-- =============================================================
local Win = Rayfield:CreateWindow({Name = "Universal Lite v7.3 Ironclad", LoadingTitle = "Ironclad Mobile", LoadingSubtitle = "Auto Fallback UI • Zero Errors", ConfigurationSaving = {Enabled = false}, KeySystem = false})
local T = {M = Win:CreateTab("1. Movimento", 4483362458), V = Win:CreateTab("2. Visuais", 4483362458), U = Win:CreateTab("3. Utilitários", 4483362458), P = Win:CreateTab("4. Performance", 4483362458), S = Win:CreateTab("5. Sistema", 4483362458)}

local function Sec(t, n) t:CreateSection(n) end
local function Tg(t, k, n, s, c, kb) if s then t:CreateSection(s) end local o = t:CreateToggle({Name = n, CurrentValue = C[k], Flag = k, Callback = function(v) C[k] = v C._Flags[k] = v if c then c(v) end local d = k:find("Enabled") or k:find("Fly") or k:find("Noclip") or k:find("Click") or k:find("Freecam") or k:find("LowGFX") Save(d) Win:Notify({Title = v and "ON" or "OFF", Content = n, Duration = 1}) end, Keybind = kb}) UI[k] = o return o end
local function Sl(t, k, n, s, mi, ma, inc, c) t:CreateSection(s) local o = t:CreateSlider({Name = n, Range = {mi, ma}, Increment = inc, CurrentValue = C[k], Flag = k, Callback = function(v) C[k] = v if k:find("Speed") or k:find("Walk") or k:find("FlySpd") or k:find("GVal") then C[k] = Clamp(v) end if k == "FOV" then Cam.FieldOfView = v end if k == "Grav" then workspace.Gravity = v end if k == "JP" then local h = Hum() if h then h.JumpPower = v h.UseJumpPower = true end end if k == "SpinSpd" and P.Spin then P.Spin.AngularVelocity = Vector3.new(0, math.rad(v) * 60, 0) end if c then c(v) end Save(false) end}) UI[k] = o return o end
local function Dd(t, k, n, s, o, c) t:CreateSection(s) local o = t:CreateDropdown({Name = n, Options = o, CurrentOption = C[k], Flag = k, Callback = function(v) local val = v[1] or v C[k] = val if Enum.KeyCode[val] then C[k] = Enum.KeyCode[val] end Save(true) if c then c(val) end end}) UI[k] = o return o end
local function Cp(t, k, n, s, c) t:CreateSection(s) local o = t:CreateColorPicker({Name = n, Color = C[k], Flag = k, Callback = function(v) C[k] = v if c then c(v) end Save(true) end}) UI[k] = o return o end
local function Btn(t, n, s, c) t:CreateSection(s) return t:CreateButton({Name = n, Callback = c}) end

-- TABS (Mantidos do v7.2)
Sec(T.M, "⚡ Física Per-Frame (Cap 1000)")
Tg(T.M, "GlobalSpd", "Velocidade Global", "⚡ Física")
Sl(T.M, "GVal", "Speed Global", "⚡ Física", 16, 1000, 1)
Sl(T.M, "Cap", "Cap Máximo", "⚡ Física", 16, 1000, 1)
Sl(T.M, "WS", "WalkSpeed", "⚡ Física", 16, 1000, 1)
Sl(T.M, "JP", "JumpPower", "⚡ Física", 50, 300, 1)
Sl(T.M, "Grav", "Gravidade", "⚡ Física", 0, 500, 1)
Sec(T.M, "🌀 Extras")
Tg(T.M, "InfJ", "Pulo Infinito", "🌀 Extras", nil, Enum.KeyCode.F3)
Tg(T.M, "Spin", "Spin", "🌀 Extras")
Sl(T.M, "SpinSpd", "Vel Spin", "🌀 Extras", 1, 100, 1)
Tg(T.M, "AutoSit", "Auto Sit", "🌀 Extras")
Sec(T.M, "🏃 Tech")
Tg(T.M, "Bhop", "Bhop", "🏃 Tech")
Tg(T.M, "EdgeJ", "Edge Jump", "🏃 Tech")
Tg(T.M, "AirWalk", "Air Walk", "🏃 Tech")
Tg(T.M, "SwimFly", "Swim Fly", "🏃 Tech")
Sec(T.M, "🕊️ Fly (CanCollide Fix)")
Tg(T.M, "Fly", "Ativar Fly", "🕊️ Fly", ToggleFly, Enum.KeyCode.F5)
Sl(T.M, "FlySpd", "Speed Fly", "🕊️ Fly", 1, 1000, 5)
Sl(T.M, "FlyV", "Mult Vertical", "🕊️ Fly", 0.1, 3, 0.1)
Dd(T.M, "FlyKey", "Tecla Toggle", "🕊️ Fly", {"F", "G", "H", "J", "K", "L", "Z", "X", "C", "V"})
Tg(T.M, "FlyBtn", "Botão Mobile (R3)", "🕊️ Fly")
T.M:CreateLabel("WASD/L-Stick Mover | Space/R-StickY Subir/Descer")
Sec(T.M, "🚫 Noclip & ClickTP")
Tg(T.M, "Noclip", "Noclip (Stepped)", "🚫 Noclip", ToggleNoclip, Enum.KeyCode.F4)
Tg(T.M, "ClickTP", "ClickTP", "🚫 ClickTP")
Dd(T.M, "ClickKey", "Tecla", "🚫 ClickTP", {"LeftControl", "RightControl", "C", "V", "X", "Z"})
Dd(T.M, "ClickMethod", "Método", "🚫 ClickTP", {"CFrame", "Tween"})
Tg(T.M, "TouchTP", "👆 Touch TP Mode", "🚫 ClickTP")

Sec(T.V, "👁️ ESP")
Tg(T.V, "ESP", "Ativar ESP", "👁️ ESP", nil, Enum.KeyCode.F1)
Sl(T.V, "ESPMax", "Dist Máx", "👁️ ESP", 100, 10000, 100)
Sec(T.V, "✨ Highlight")
Tg(T.V, "ESPHl", "Highlight", "✨ Highlight")
Sl(T.V, "ESPHlFill", "Fill Transp", "✨ Highlight", 0, 1, 0.05)
Sl(T.V, "ESPHlOut", "Outline Transp", "✨ Highlight", 0, 1, 0.05)
Sec(T.V, "📝 Billboard")
Tg(T.V, "ESP_N", "Nomes", "📝 Billboard")
Tg(T.V, "ESP_D", "Distância", "📝 Billboard")
Tg(T.V, "ESP_H", "Vida", "📝 Billboard")
Tg(T.V, "ESP_HB", "Barra Vida", "📝 Billboard")
Tg(T.V, "ESP_TC", "Cor Time", "📝 Billboard")
Sec(T.V, "🌍 Mundo")
Tg(T.V, "FB", "Fullbright", "🌍 Mundo", nil, Enum.KeyCode.F2)
Tg(T.V, "NoFog", "Sem Neblina", "🌍 Mundo")
Tg(T.V, "NoShad", "Sem Sombras", "🌍 Mundo")
Sl(T.V, "FOV", "FOV", "🌍 Mundo", 50, 120, 1)

Sec(T.U, "👥 Player Selector")
UI.DDPlr = T.U:CreateDropdown({Name = "Selecionar Jogador", Options = {"Nenhum"}, CurrentOption = "Nenhum", Flag = "PDD", Callback = function(v) local val = v[1] or v C.SelPlr = val Spec(C.Spec, val) end})
T.U:CreateButton({Name = "🔄 Atualizar Lista", Callback = UpdateDD})
T.U:CreateButton({Name = "⚡ TP para Selecionado", Callback = function() TPTo(C.SelPlr) end})
Tg(T.U, "Spec", "👁️ Spectate", "👥 Player Selector", function(v) C.Spec = v Spec(v, C.SelPlr) end)

Sec(T.U, "👆 ClickTP / TouchTP")
Tg(T.U, "TouchTP", "👆 Touch TP Mode", "👆 ClickTP")
T.U:CreateLabel("ClickTP: Segure tecla + Click | TouchTP: Toque na tela")

Sec(T.U, "🔄 Server")
Btn(T.U, "Rejoin", "🔄 Server", function() Save(true) TP:TeleportToPlaceInstance(PlaceId, JobId, LP) end)
if Cap.Net then Btn(T.U, "Server Hop", "🔄 Server", function() Win:Notify({Title = "Hop", Content = "Buscando...", Duration = 10}) task.spawn(function() local ok, res = pcall(function() return HS:RequestAsync({Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET"}) end) if ok and res.Success then local d = HS:JSONDecode(res.Body) for _, s in pairs(d.data) do if s.id ~= JobId and s.playing < s.maxPlayers then TP:TeleportToPlaceInstance(PlaceId, s.id, LP) return end end end Win:Notify({Title = "Erro", Content = "Sem server", Duration = 5}) end) end) else T.U:CreateLabel("🚫 Server Hop: Sem RequestAsync") end
Btn(T.U, "Rejoin + QueueTP", "🔄 Server", function() if Cap.Queue then queue_on_teleport('game:GetService("TeleportService"):TeleportToPlaceInstance(' .. PlaceId .. ', "' .. JobId .. '")') end TP:TeleportToPlaceInstance(PlaceId, JobId, LP) end)

Sec(T.P, "🚀 FPS Boost")
Tg(T.P, "LowGFX", "LowGFX Mode", "🚀 FPS Boost")
Tg(T.P, "NoTex", "Remover Texturas", "🚀 FPS Boost")
Tg(T.P, "NoPart", "Remover Partículas", "🚀 FPS Boost")
Tg(T.P, "NoDec", "Remover Decals", "🚀 FPS Boost")
Sec(T.P, "🛡️ Sobrevivência")
Tg(T.P, "AntiAFK", "Anti-AFK", "🛡️ Sobrevivência")
Tg(T.P, "AntiVoid", "Anti-Void", "🛡️ Sobrevivência")
Tg(T.P, "NoFall", "No Fall Damage", "🛡️ Sobrevivência")
Tg(T.P, "Hitbox", "Hitbox Expander", "🛡️ Sobrevivência")
Sl(T.P, "HitSize", "Tamanho Hitbox", "🛡️ Sobrevivência", 2, 50, 0.5)
Sl(T.P, "HitTrans", "Transparência", "🛡️ Sobrevivência", 0, 1, 0.05)
Cp(T.P, "HitCol", "Cor Hitbox", "🛡️ Sobrevivência")

Sec(T.S, "💾 Persistência")
Btn(T.S, "Forçar Salvar", "💾 Persistência", function() Save(true) Win:Notify({Title = "OK", Content = "Salvo!", Duration = 1}) end)
Sec(T.S, "🔴 Reset Total")
Btn(T.S, "🔴 RESET TOTAL", "🔴 Perigo", function()
    for _, c in pairs(PConns) do pcall(function() c:Disconnect() end) end PConns = {}
    if P.Fly then P.Fly:Disconnect() P.Fly = nil end if P.FC then P.FC:Disconnect() P.FC = nil end if P.Spin then P.Spin:Destroy() P.Spin = nil end if P.Air then P.Air:Destroy() P.Air = nil end
    if Cap.Meta and P.OrigNC then local mt = getrawmetatable(game) setreadonly(mt, false) mt.__namecall = P.OrigNC setreadonly(mt, true) end
    for _, v in pairs(P.HL) do pcall(function() v:Destroy() end) end table.clear(P.HL) for _, v in pairs(P.BB) do pcall(function() v:Destroy() end) end table.clear(P.BB) for _, v in pairs(P.HB) do pcall(function() v:Destroy() end) end table.clear(P.HB)
    for _, plr in pairs(Plrs:GetPlayers()) do if plr ~= LP and Alive(plr) then local r = Root(plr.Character) if r then r.Size = Vector3.new(2, 2, 1) r.Transparency = 1 r.CanCollide = false r.Massless = true r.Color = Color3.new(1, 1, 1) r.Material = Enum.Material.Plastic end end end
    for p, s in pairs(P.FlyCol) do if p and p.Parent then pcall(function() p.CanCollide = s end) end end table.clear(P.FlyCol)
    Cam.FieldOfView = 70 Light.GlobalShadows = true Light.FogEnd = 1e5 Light.ClockTime = 14 Light.Brightness = 2 Light.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5) Light.Ambient = Color3.new(0.5, 0.5, 0.5) for _, v in pairs(Light:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end ApplyLow()
    local h = Hum() local r = Root() if h then h.PlatformStand = false h.WalkSpeed = 16 h.JumpPower = 50 h.UseJumpPower = true end if r then r.CanCollide = true r.Size = Vector3.new(2, 2, 1) r.Transparency = 1 end
    pcall(function() CAS:UnbindAction("UL_Fly") end)
    local def = {WS = 16, JP = 50, Grav = 196.2, InfJ = false, Fly = false, FlySpd = 100, FlyV = 1, FlyKey = "F", FlyBtn = true, Noclip = false, NoclipKey = "N", ClickTP = false, ClickKey = "LeftControl", ClickMethod = "CFrame", TouchTP = false, ESP = false, ESP_HL = true, ESP_N = true, ESP_D = true, ESP_H = true, ESP_HB = true, ESP_TC = true, ESPMax = 5000, FB = false, NoFog = false, NoShad = false, FOV = 70, SelPlr = "Nenhum", Spec = false, AntiAFK = false, AntiVoid = false, LowGFX = false, NoTex = false, NoPart = false, NoDec = false, GlobalSpd = false, GVal = 100, Cap = 1000, Bhop = false, EdgeJ = false, AirWalk = false, SwimFly = false, Spin = false, SpinSpd = 20, AutoSit = false, Hitbox = false, HitSize = 10, HitTrans = 0.7, HitCol = Color3.fromRGB(255, 0, 0), AntiAFK = false, _Flags = {}} for k in pairs(C) do C[k] = nil end for k, v in pairs(def) do C[k] = v end for fl, ob in pairs(UI) do pcall(function() ob:Set(C[fl]) end) end Save(true) Win:Notify({Title = "RESET", Content = "Defaults", Duration = 3}) end)

-- ============================================================
-- 🚀 STARTUP
-- =============================================================
ApplyAll()
UpdateDD()
print("==================================================") print("🚀 UNIVERSAL LITE v7.3 IRONCLAD MOBILE READY") print("==================================================")
Win:Notify({Title = "Universal Lite v7.3", Content = "Ironclad Mobile Loaded.", Duration = 5})

-- ============================================================
-- 🛡️ CLEANUP
-- =============================================================
getgenv()._UL_Cleanup = function()
    for _, c in pairs(PConns) do pcall(function() c:Disconnect() end) end PConns = {}
    if P.Fly then P.Fly:Disconnect() P.Fly = nil end if P.FC then P.FC:Disconnect() P.FC = nil end if P.Spin then P.Spin:Destroy() P.Spin = nil end if P.Air then P.Air:Destroy() P.Air = nil end
    if Cap.Meta and P.OrigNC then local mt = getrawmetatable(game) setreadonly(mt, false) mt.__namecall = P.OrigNC setreadonly(mt, true) end
    for _, v in pairs(P.HL) do pcall(function() v:Destroy() end) end table.clear(P.HL) for _, v in pairs(P.BB) do pcall(function() v:Destroy() end) end table.clear(P.BB) for _, v in pairs(P.HB) do pcall(function() v:Destroy() end) end table.clear(P.HB)
    for _, plr in pairs(Plrs:GetPlayers()) do if plr ~= LP and Alive(plr) then local r = Root(plr.Character) if r then r.Size = Vector3.new(2, 2, 1) r.Transparency = 1 r.CanCollide = false r.Massless = true r.Color = Color3.new(1, 1, 1) r.Material = Enum.Material.Plastic end end end
    for p, s in pairs(P.FlyCol) do if p and p.Parent then pcall(function() p.CanCollide = s end) end end table.clear(P.FlyCol)
    Cam.FieldOfView = 70 Light.GlobalShadows = true Light.FogEnd = 1e5 Light.ClockTime = 14 Light.Brightness = 2 Light.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5) Light.Ambient = Color3.new(0.5, 0.5, 0.5) for _, v in pairs(Light:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end ApplyLow()
    local h = Hum() local r = Root() if h then h.PlatformStand = false h.WalkSpeed = 16 h.JumpPower = 50 h.UseJumpPower = true end if r then r.CanCollide = true r.Size = Vector3.new(2, 2, 1) r.Transparency = 1 end
    pcall(function() CAS:UnbindAction("UL_Fly") end)
    print("✅ Cleanup OK")
end
```
