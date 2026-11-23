--[[ UNIVERSAL LITE v8.1 — ETAPA 2: MOVIMENTAÇÃO + SUPORTE/WATCHDOG ]]--
if getgenv()._UL_Cleanup then pcall(getgenv()._UL_Cleanup) end

-- ============================================================
-- 🛡️ SERVIÇOS & VARIÁVEIS
-- ============================================================
local Run = game:GetService("RunService")
local Plrs = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Light = game:GetService("Lighting")
local TP = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")
local CAS = game:GetService("ContextActionService")
local Tween = game:GetService("TweenService")
local LP = Plrs.LocalPlayer
local Cam = workspace.CurrentCamera
local PlaceId, JobId = game.PlaceId, game.JobId
local Mouse = LP:GetMouse()

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
task.wait(0.5)

-- ============================================================
-- 🖥️ RAYFIELD OFICIAL (SEM FALLBACK)
-- ============================================================
local Rayfield
local success, err = pcall(function()
    local src = game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", true)
    local fn, errLoad = loadstring(src)
    if not fn then error("Erro ao compilar Rayfield: " .. tostring(errLoad)) end
    Rayfield = fn()
end)

if not success or not Rayfield or not Rayfield.CreateWindow then
    local msg = "❌ FALHA AO CARREGAR RAYFIELD OFICIAL\n\nErro: " .. tostring(err) .. "\n\nVerifique internet / HttpGet liberado."
    warn("[UniversalLite] " .. msg)
    LP:Kick(msg)
    return
end

print("[UI] Rayfield Oficial carregado.")

-- ============================================================
-- ⚙️ CONFIG & PERSISTÊNCIA (JSON POR PLACEID)
-- ============================================================
local Folder, File = "UL_Movement_v1", "UL_Movement_v1/Cfg_" .. game.PlaceId .. ".json"
local SaveDeb = false
pcall(function() if not isfolder("UL_Movement_v1") then makefolder("UL_Movement_v1") end end)

local C = {
    -- Movement
    WS = 16, JP = 50, Grav = 196.2, InfJ = false,
    Fly = false, FlySpd = 100, FlyV = 1, FlyKey = "F", FlyBtn = true,
    Noclip = false, NoclipKey = "N",
    ClickTP = false, ClickKey = "LeftControl", ClickMethod = "CFrame", TouchTP = false,
    Spin = false, SpinSpd = 20, AutoSit = false,
    GlobalSpd = false, GVal = 100, Cap = 1000,
    -- Interno
    _Flags = {}
}

local SaveDeb = false
local function Save(now)
    if now then local d = {} for k, v in pairs(C) do if type(v) ~= "function" and k:sub(1,1) ~= "_" then if typeof(v) == "Color3" then d[k] = {R=v.R,G=v.G,B=v.B} elseif typeof(v) == "EnumItem" then d[k] = v.Name else d[k] = v end end end pcall(function() writefile("UL_Movement_v1/Cfg_"..game.PlaceId..".json", game:GetService("HttpService"):JSONEncode(d)) end) return end
    if SaveDeb then return end SaveDeb = true task.delay(1, function() SaveDeb = false Save(true) end)
end

local function Load()
    local ok, d = pcall(function() if isfile("UL_Movement_v1/Cfg_"..game.PlaceId..".json") then return game:GetService("HttpService"):JSONDecode(readfile("UL_Movement_v1/Cfg_"..game.PlaceId..".json")) end end)
    if ok and d then for k, v in pairs(d) do if C[k] ~= nil then if type(v) == "table" and v.R then C[k] = Color3.new(v.R,v.G,v.B) elseif type(v) == "string" and Enum.KeyCode[v] and (k:find("Key") or k:find("bind")) then C[k] = Enum.KeyCode[v] else C[k] = v end end end for k, v in pairs(C) do if type(v) == "boolean" then C._Flags[k] = v end end end
end
pcall(function() if not isfolder("UL_Movement_v1") then makefolder("UL_Movement_v1") end end)
pcall(Load)

-- ============================================================
-- 🛡️ HELPERS & WATCHDOG
-- =============================================================
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Clamp(v) return math.clamp(v, 0, C.Cap) end
local Alive = function(plr) plr = plr or LP local c = plr.Character local h = Hum(c) local r = Root(c) return c and h and r and h.Health > 0 end

local UI, P = {}, {Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X=0,Y=0,Z=0}, Spin = nil}
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end

-- WATCHDOG: Loop seguro que desliga sozinho se der erro 3x
local PConns = {}
local function RegLoop(name, fn, evt, interval)
    if PConns[name] then pcall(function() PConns[name]:Disconnect() end) end
    local errs, last = 0, 0
    PConns[name] = evt:Connect(function(dt)
        if not C._Flags[name] then return end
        if interval and interval > 0 then if os.clock() - last < interval then return end last = os.clock() end
        local ok, err = pcall(fn, dt)
        if not ok then
            warn("[WATCHDOG] " .. name .. " erro: " .. tostring(err))
            errs = errs + 1
            if errs >= 3 then
                C._Flags[name] = false
                C[name] = false
                warn("[WATCHDOG] " .. name .. " DESLIGADO automaticamente (3 erros).")
                if Rayfield then Rayfield:Notify({Title="⚠️ Watchdog", Content=name.." desligado (erros)", Duration=5, Image="alert-triangle"}) end
            end
        else
            errs = 0
        end
    end)
end

-- ============================================================
-- 🧠 FUNÇÕES APLICADORAS
-- =============================================================
local function ApplyPhys()
    local h = Hum() local r = Root()
    if not h or not r then return end
    local t = C.GlobalSpd and math.clamp(C.GVal, 0, C.Cap) or math.clamp(C.WS, 0, C.Cap)
    pcall(function() h.WalkSpeed = t end)
    pcall(function() h.JumpPower = C.JP; h.UseJumpPower = true end)
    pcall(function() workspace.Gravity = C.Grav end)
    if C.AutoSit then pcall(function() Hum().Sit = true end) end
end

local function ApplyAll()
    pcall(function() workspace.Gravity = C.Grav end)
    ApplyPhys()
end

-- ============================================================
-- 🔁 LOOPS COM WATCHDOG
-- =============================================================
local Plrs = game:GetService("Players")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Light = game:GetService("Lighting")
local TP = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")
local CAS = game:GetService("ContextActionService")
local Tween = game:GetService("TweenService")
local LP = game:GetService("Players").LocalPlayer
local Cam = workspace.CurrentCamera
local PlaceId, JobId = game.PlaceId, game.JobId
local Mouse = LP:GetMouse()
local P = {Fly = nil, FC = nil, Conns = {}, FlyCol = {}, FIn = {X=0,Y=0,Z=0}, Spin = nil}

-- Physics Master (Heartbeat) - WalkSpeed, JumpPower, Gravity, Spin
RegLoop("Phys", function(dt)
    -- Aplica física base
    local h = Hum() local r = Root()
    if h and r then
        local t = C.GlobalSpd and math.clamp(C.GVal, 0, C.Cap) or math.clamp(C.WS, 0, C.Cap)
        if h.WalkSpeed ~= t then pcall(function() h.WalkSpeed = t end) end
        if h.JumpPower ~= C.JP then pcall(function() h.JumpPower = C.JP; h.UseJumpPower = true end) end
        if workspace.Gravity ~= C.Grav then workspace.Gravity = C.Grav end
    end
    -- Spin
    if C.Spin then local r = Root() if r then if not P.Spin then local b = Instance.new("BodyAngularVelocity") b.MaxTorque = Vector3.new(0, 1e9, 0) b.P = 1e4 b.Parent = r P.Spin = b end P.Spin.AngularVelocity = Vector3.new(0, math.rad(C.SpinSpd) * 60, 0) end elseif P.Spin then P.Spin:Destroy() P.Spin = nil end
end, game:GetService("RunService").Heartbeat, 0)

-- Noclip (Stepped)
RegLoop("Noclip", function()
    if C.Noclip then
        local c = LP.Character
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
            end
        end
    end
end, game:GetService("RunService").Stepped, 0)

-- ============================================================
-- 🔴 FLY / NOCLIP / INPUT (CANCOLLIDE FIX + MOBILE)
-- =============================================================
local P = {Fly = nil, FC = nil, FlyCol = {}, FIn = {X=0,Y=0,Z=0}, Spin = nil}
local UI = {}
local function Hum(c) c = c or LP.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid") end
local function Root(c) c = c or LP.Character if not c then return nil end local h = Hum(c) if h and h.RootPart then return h.RootPart end return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") or c:FindFirstChildWhichIsA("BasePart") end
local function Clamp(v) return math.clamp(v, 0, C.Cap) end
local function Disc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end

-- Input Capture (Teclado + Gamepad)
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.W then P.FIn.Z = -1 elseif i.KeyCode == Enum.KeyCode.S then P.FIn.Z = 1 elseif i.KeyCode == Enum.KeyCode.A then P.FIn.X = -1 elseif i.KeyCode == Enum.KeyCode.D then P.FIn.X = 1 elseif i.KeyCode == Enum.KeyCode.Space then P.FIn.Y = 1 elseif i.KeyCode == Enum.KeyCode.LeftShift then P.FIn.Y = -1 end
    if i.KeyCode == C.FlyKey then ToggleFly(not C.Fly) end
    if i.KeyCode == C.NoclipKey then ToggleNoclip(not C.Noclip) end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W and P.FIn.Z == -1 then P.FIn.Z = 0 elseif i.KeyCode == Enum.KeyCode.S and P.FIn.Z == 1 then P.FIn.Z = 0 elseif i.KeyCode == Enum.KeyCode.A and P.FIn.X == -1 then P.FIn.X = 0 elseif i.KeyCode == Enum.KeyCode.D and P.FIn.X == 1 then P.FIn.X = 0 elseif i.KeyCode == Enum.KeyCode.Space and P.FIn.Y == 1 then P.FIn.Y = 0 elseif i.KeyCode == Enum.KeyCode.LeftShift and P.FIn.Y == -1 then P.FIn.Y = 0 end
end)
UIS.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Gamepad1 then
        if i.KeyCode == Enum.KeyCode.Thumbstick1 then P.FIn.X = i.Position.X P.FIn.Z = i.Position.Y
        elseif i.KeyCode == Enum.KeyCode.Thumbstick2 then P.FIn.Y = i.Position.Y end
    end
end)

local function ToggleFly(st)
    C.Fly = st C._Flags.Fly = st
    local h = Hum() local r = Root()
    if st and (not h or not r) then C.Fly = false C._Flags.Fly = false if UI.Fly then UI.Fly:Set(false) end return end
    if st then
        -- CANCOLLIDE FIX: Salva e desliga colisão de TODAS as partes
        P.FlyCol = {}
        for _, p in pairs((LP.Character or {}):GetDescendants()) do
            if p:IsA("BasePart") then P.FlyCol[p] = p.CanCollide p.CanCollide = false end
        end
        pcall(function() h.PlatformStand = true h.WalkSpeed = 0 h.JumpPower = 0 end)
        P.Fly = game:GetService("RunService").RenderStepped:Connect(function(dt)
            if not C.Fly then ToggleFly(false) return end
            h = Hum() r = Root() if not h or not r then ToggleFly(false) return end
            local cf = Cam.CFrame local mv = Vector3.zero
            mv = mv + (cf.RightVector * P.FIn.X) + (cf.LookVector * P.FIn.Z) + (Vector3.new(0,1,0) * P.FIn.Y)
            if mv.Magnitude > 0 then
                local spd = (C.GlobalSpd and C.GVal or C.FlySpd) * C.FlyV
                r.CFrame = r.CFrame + (mv.Unit * spd * dt)
            else
                r.AssemblyLinearVelocity = Vector3.new(0, 0.001, 0)
            end
            pcall(function() r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero r.CFrame = CFrame.new(r.CFrame.Position, r.CFrame.Position + cf.LookVector) end)
        end)
    else
        if P.Fly then P.Fly:Disconnect() P.Fly = nil end
        pcall(function() h.PlatformStand = false end)
        for p, s in pairs(P.FlyCol) do if p and p.Parent then pcall(function() p.CanCollide = s end) end end
        if P.Spin then P.Spin:Destroy() P.Spin = nil end
    end
    Save(true)
end

local function ToggleNoclip(st)
    C.Noclip = st C._Flags.Noclip = st Save(true) end

local function ToggleFreecam(st)
    C.Freecam = st C._Flags.Freecam = st
    local h = Hum()
    if st then
        Cam.CameraType = Enum.CameraType.Scriptable Cam.CameraSubject = nil
        if h then h.WalkSpeed = 0 h.JumpPower = 0 end
        P.FC = game:GetService("RunService").RenderStepped:Connect(function(dt)
            if not C.Freecam then ToggleFreecam(false) return end
            local cf = Cam.CFrame local v = Vector3.zero local s = 100 * dt
            if UIS:IsKeyDown(Enum.KeyCode.W) then v += cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then v -= cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then v += cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then v -= cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then v -= Vector3.new(0,1,0) end
            if v.Magnitude > 0 then Cam.CFrame = cf + v.Unit * s end
        end)
    else
        if P.FC then P.FC:Disconnect() P.FC = nil end
        Cam.CameraType = Enum.CameraType.Custom Cam.CameraSubject = h
        if h then ApplyPhys() end
    end
    Save(true)
end

-- Input Capture (Teclado + Gamepad)
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.W then P.FIn.Z = -1 elseif i.KeyCode == Enum.KeyCode.S then P.FIn.Z = 1 elseif i.KeyCode == Enum.KeyCode.A then P.FIn.X = -1 elseif i.KeyCode == Enum.KeyCode.D then P.FIn.X = 1 elseif i.KeyCode == Enum.KeyCode.Space then P.FIn.Y = 1 elseif i.KeyCode == Enum.KeyCode.LeftShift then P.FIn.Y = -1 end
    if i.KeyCode == C.FlyKey then ToggleFly(not C.Fly) end
    if i.KeyCode == C.NoclipKey then ToggleNoclip(not C.Noclip) end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W and P.FIn.Z == -1 then P.FIn.Z = 0 elseif i.KeyCode == Enum.KeyCode.S and P.FIn.Z == 1 then P.FIn.Z = 0 elseif i.KeyCode == Enum.KeyCode.A and P.FIn.X == -1 then P.FIn.X = 0 elseif i.KeyCode == Enum.KeyCode.D and P.FIn.X == 1 then P.FIn.X = 0 elseif i.KeyCode == Enum.KeyCode.Space and P.FIn.Y == 1 then P.FIn.Y = 0 elseif i.KeyCode == Enum.KeyCode.LeftShift and P.FIn.Y == -1 then P.FIn.Y = 0 end
end)
UIS.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Gamepad1 then
        if i.KeyCode == Enum.KeyCode.Thumbstick1 then P.FIn.X = i.Position.X P.FIn.Z = i.Position.Y
        elseif i.KeyCode == Enum.KeyCode.Thumbstick2 then P.FIn.Y = i.Position.Y end
    end
end)

-- Mobile Button (ContextActionService)
if C.FlyBtn then pcall(function() CAS:BindAction("UL_Fly", function(n, s, i) if s == Enum.UserInputState.Begin then ToggleFly(not C.Fly) end end, true, Enum.KeyCode.ButtonR3) CAS:SetTitle("UL_Fly", "Fly") CAS:SetPosition("UL_Fly", UDim2.new(1, -110, 1, -110)) end) end

-- ============================================================
-- 👆 CLICK TP / TOUCH TP
-- =============================================================
UIS.InputBegan:Connect(function(i, gp)
    if C.ClickTP and not C.TouchTP and not gp and i.KeyCode == C.ClickKey then
        local r = Root() if r then
            local ray = Cam:ViewportPointToRay(Mouse.X, Mouse.Y)
            local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, p)
            if hit then r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end
        end
    end
end)

UIS.TouchStarted:Connect(function(t, gp)
    if C.ClickTP and C.TouchTP and not gp then
        local r = Root() if r then
            local ray = Cam:ViewportPointToRay(t.Position.X, t.Position.Y)
            local p = RaycastParams.new() p.FilterDescendantsInstances = {LP.Character} p.FilterType = Enum.RaycastFilterType.Exclude
            local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, p)
            if hit then r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end
        end
    end
end)

UIS.JumpRequest:Connect(function() if C.InfJ then local h = Hum() if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    ApplyAll()
    if C.Fly then ToggleFly(true) end
    if C.Noclip then ToggleNoclip(true) end
end)

-- ============================================================
-- 🖥️ RAYFIELD OFICIAL + UI
-- =============================================================
local Rayfield
local success, err = pcall(function()
    local src = game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", true)
    local fn, errLoad = loadstring(src)
    if not fn then error("Erro ao compilar Rayfield: " .. tostring(errLoad)) end
    Rayfield = fn()
end)

if not success or not Rayfield or not Rayfield.CreateWindow then
    local msg = "❌ FALHA AO CARREGAR RAYFIELD OFICIAL\n\nErro: " .. tostring(err) .. "\n\nVerifique internet / HttpGet liberado."
    warn("[UniversalLite] " .. msg)
    LP:Kick(msg)
    return
end

local Win = Rayfield:CreateWindow({
    Name = "Universal Lite v8.1 — Movimento",
    LoadingTitle = "Carregando Movimento...",
    LoadingSubtitle = "Watchdog Ativo • Fly Fix • Mobile Ready",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local T = {
    Move = Win:CreateTab("1. Movimento", 4483362458),
    Sys  = Win:CreateTab("2. Sistema", 4483362458)
}

local function Sec(t, n) t:CreateSection(n) end
local function Tg(t, k, n, s, c, kb) if s then t:CreateSection(s) end local o = t:CreateToggle({Name = n, CurrentValue = C[k], Flag = k, Callback = function(v) C[k] = v C._Flags[k] = v if c then c(v) end local d = k:find("Enabled") or k:find("Fly") or k:find("Noclip") or k:find("Click") or k:find("Freecam") Save(d) Rayfield:Notify({Title = v and "ON" or "OFF", Content = n, Duration = 1}) end, Keybind = kb}) return o end
local function Sl(t, k, n, s, mi, ma, inc, c) t:CreateSection(s) local o = t:CreateSlider({Name = n, Range = {mi, ma}, Increment = inc, CurrentValue = C[k], Flag = k, Callback = function(v) C[k] = v if k:find("Speed") or k:find("Walk") or k:find("FlySpd") or k:find("GVal") then C[k] = math.clamp(v, 0, C.Cap) end if k == "FOV" then Cam.FieldOfView = v end if k == "Grav" then workspace.Gravity = v end if k == "JP" then local h = Hum() if h then h.JumpPower = v h.UseJumpPower = true end end if c then c(v) end Save(false) end}) return o end
local function Dd(t, k, n, s, o, c) t:CreateSection(s) local o = t:CreateDropdown({Name = n, Options = o, CurrentOption = C[k], Flag = k, Callback = function(v) local val = v[1] or v C[k] = val if Enum.KeyCode[val] then C[k] = Enum.KeyCode[val] end Save(true) if c then c(val) end end}) return o end
local function Btn(t, n, s, c) t:CreateSection(s) return t:CreateButton({Name = n, Callback = c}) end

-- ========== ABA 1: MOVIMENTO ==========
Sec(T.Move, "⚡ Física Per-Frame (Cap 1000)")
Tg(T.Move, "GlobalSpd", "Velocidade Global", "⚡ Física")
Sl(T.Move, "GVal", "Speed Global", "⚡ Física", 16, 1000, 1)
Sl(T.Move, "Cap", "Cap Máximo", "⚡ Física", 16, 1000, 1)
Sl(T.Move, "WS", "WalkSpeed", "⚡ Física", 16, 1000, 1)
Sl(T.Move, "JP", "JumpPower", "⚡ Física", 50, 300, 1)
Sl(T.Move, "Grav", "Gravidade", "⚡ Física", 0, 500, 1)

Sec(T.Move, "🌀 Extras")
Tg(T.Move, "InfJ", "Pulo Infinito", "🌀 Extras", nil, Enum.KeyCode.F3)
Tg(T.Move, "Spin", "Spin", "🌀 Extras")
Sl(T.Move, "SpinSpd", "Vel Spin", "🌀 Extras", 1, 100, 1)
Tg(T.Move, "AutoSit", "Auto Sit", "🌀 Extras")

Sec(T.Move, "🕊️ Fly (CanCollide Fix + Mobile)")
Tg(T.Move, "Fly", "Ativar Fly", "🕊️ Fly", ToggleFly, Enum.KeyCode.F5)
Sl(T.Move, "FlySpd", "Speed Fly", "🕊️ Fly", 1, 1000, 5)
Sl(T.Move, "FlyV", "Mult Vertical", "🕊️ Fly", 0.1, 3, 0.1)
Dd(T.Move, "FlyKey", "Tecla Toggle", "🕊️ Fly", {"F", "G", "H", "J", "K", "L", "Z", "X", "C", "V"})
Tg(T.Move, "FlyBtn", "Botão Mobile (R3)", "🕊️ Fly")
T.Move:CreateLabel("WASD / L-Stick Mover | Space / R-Stick Y Subir/Descer")

Sec(T.Move, "🚫 Noclip & ClickTP")
Tg(T.Move, "Noclip", "Noclip (Stepped)", "🚫 Noclip", ToggleNoclip, Enum.KeyCode.F4)
Tg(T.Move, "ClickTP", "ClickTP (Tecla)", "🚫 ClickTP")
Dd(T.Move, "ClickKey", "Tecla", "🚫 ClickTP", {"LeftControl", "RightControl", "C", "V", "X", "Z"})
Dd(T.Move, "ClickMethod", "Método", "🚫 ClickTP", {"CFrame", "Tween"})
Tg(T.Move, "TouchTP", "👆 Touch TP (Toque Tela)", "🚫 ClickTP")

-- ========== ABA 2: SISTEMA ==========
Sec(T.Sys, "💾 Persistência")
Btn(T.Sys, "Forçar Salvar", "💾 Persistência", function() Save(true) Rayfield:Notify({Title = "OK", Content = "Salvo!", Duration = 1}) end)

Sec(T.Sys, "🔴 Reset Total")
Btn(T.Sys, "🔴 RESET TOTAL", "🔴 Perigo", function()
    for _, c in pairs(PConns) do pcall(function() c:Disconnect() end) end PConns = {}
    if P.Fly then P.Fly:Disconnect() P.Fly = nil end if P.FC then P.FC:Disconnect() P.FC = nil end if P.Spin then P.Spin:Destroy() P.Spin = nil end
    if C.Fly then ToggleFly(false) end if C.Noclip then ToggleNoclip(false) end
    local def = {WS=16, JP=50, Grav=196.2, InfJ=false, Fly=false, FlySpd=100, FlyV=1, FlyKey="F", FlyBtn=true, Noclip=false, NoclipKey="N", ClickTP=false, ClickKey="LeftControl", ClickMethod="CFrame", TouchTP=false, Spin=false, SpinSpd=20, AutoSit=false, GlobalSpd=false, GVal=100, Cap=1000, _Flags={}} for k in pairs(C) do C[k]=nil end for k,v in pairs(def) do C[k]=v end
    ApplyAll()
    Rayfield:Notify({Title="RESET", Content="Defaults restaurados.", Duration=3})
end)

-- ============================================================
-- 🚀 STARTUP
-- =============================================================
local function ApplyAll()
    pcall(function() workspace.Gravity = C.Grav end)
    local h = Hum() local r = Root()
    if h and r then
        local t = C.GlobalSpd and math.clamp(C.GVal, 0, C.Cap) or math.clamp(C.WS, 0, C.Cap)
        pcall(function() h.WalkSpeed = t end)
        pcall(function() h.JumpPower = C.JP; h.UseJumpPower = true end)
        pcall(function() workspace.Gravity = C.Grav end)
    end
end

ApplyAll()
print("==================================================") print("✅ ETAPA 2 PRONTA — MOVIMENTAÇÃO + WATCHDOG ATIVO") print("==================================================")
Rayfield:Notify({Title = "✅ Etapa 2 Pronta", Content = "Movimento + Watchdog ativo", Duration = 5, Image = "check-circle"})

-- Cleanup
getgenv()._UL_Cleanup = function()
    for _, c in pairs(PConns) do pcall(function() c:Disconnect() end) end
    if P.Fly then P.Fly:Disconnect() end if P.FC then P.FC:Disconnect() end
    pcall(function() game:GetService("ContextActionService"):UnbindAction("UL_Fly") end)
    print("[Cleanup] Etapa 2 limpa.")
end
