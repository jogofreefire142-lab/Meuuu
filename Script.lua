-- 🔵 0. AUTO-CLEANUP TOPO
if getgenv()._UniversalScriptCleanup then pcall(getgenv()._UniversalScriptCleanup) end

-- 🔵 1. LOAD & SERVICES (WAIT 3s PARA AUTO-EXECUTE DELTA MOBILE)
repeat task.wait() until game:IsLoaded()
task.wait(3)

-- Rayfield via GitHub Raw
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting      = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService   = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlaceId = game.PlaceId

-- ============================================================
-- 🛡️ EXECUTOR CAPABILITIES DETECTION (SEM EXECUTAR HOOKS)
-- ============================================================
local ExecutorCaps = {}
ExecutorCaps.hasWriteFile  = pcall(function() writefile("__UniversalTestCap", "") delfile("__UniversalTestCap") end)
ExecutorCaps.hasRequest    = pcall(function() HttpService:RequestAsync({Url="https://roblox.com", Method="GET"}) end)
ExecutorCaps.hasHookFunc   = type(hookfunction) == "function"
ExecutorCaps.hasGetRawMeta = type(getrawmetatable) == "function"
ExecutorCaps.hasDrawing    = pcall(function() local d = Drawing.new("Line") d:Remove() end)

-- ============================================================
-- 📁 PASTA DEDICADA & CAMINHO DO CONFIG (MELHORIA 2)
-- ============================================================
local CONFIG_FOLDER = "UniversalLite_Configs"
local CONFIG_PATH = CONFIG_FOLDER .. "/Config_" .. PlaceId .. ".json"

pcall(function()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end)

-- ============================================================
-- ⚙️ CONFIG — TUDO FALSE POR PADRÃO (MELHORIA 1)
-- ============================================================
local CONFIG = {
    -- Visuais
    ESP = false, Fullbright = false, NoFog = false, FOV = 70,
    -- Movimento
    WalkSpeed = 16, JumpPower = 50, Gravity = 1, InfiniteJump = false, Spin = false, SpinSpeed = 10, Sit = false,
    -- Perigosos
    Fly = false, FlySpeed = 50, Noclip = false, ClickTP = false,
    -- Utils
    AntiAFK = false, AntiLag = false, Rejoin = false, ServerHop = false, SelectedPlayer = "Nenhum",
    -- Velocidade Global
    VelocidadeGlobal = 1000, AplicarVelocidade = false, LimiteVelocidade = 1000,
    -- Interno Watchdog
    _Flags = {}
}

-- ============================================================
-- 💾 AUTO-SAVE / AUTO-LOAD (MELHORIA 3)
-- ============================================================
local function saveConfig()
    local data = {}
    for k, v in pairs(CONFIG) do
        if type(v) ~= "function" and k:sub(1,1) ~= "_" then data[k] = v end
    end
    local json = HttpService:JSONEncode(data)
    pcall(function()
        writefile(CONFIG_PATH, json)
    end)
end

local function loadConfig()
    local success, data = pcall(function()
        if isfile(CONFIG_PATH) then
            return HttpService:JSONDecode(readfile(CONFIG_PATH))
        end
        return nil
    end)
    if success and data then
        for k, v in pairs(data) do
            if CONFIG[k] ~= nil then CONFIG[k] = v end
        end
        for k, v in pairs(CONFIG) do
            if type(v) == "boolean" then CONFIG._Flags[k] = v end
        end
    end
end

-- ============================================================
-- 🛡️ ANTI-KICK (BEST EFFORT)
-- ============================================================
pcall(function()
    if ExecutorCaps.hasGetRawMeta then
        local mt = getrawmetatable(game)
        if mt and setreadonly then
            local old = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                if self == player and (getnamecallmethod() == "Kick" or getnamecallmethod() == "kick") then
                    warn("[ANTI-KICK] Blocked:", ...)
                    if Rayfield and Rayfield.Notify then Rayfield:Notify({Title="🛡️ Anti-Kick", Content="Kick bloqueado (metatable)", Duration=5, Image="shield"}) end
                    return nil
                end
                return old(self, ...)
            end)
            setreadonly(mt, true)
        end
    end
end)
pcall(function()
    if ExecutorCaps.hasHookFunc then
        local OldKick = hookfunction(player.Kick, function(self, msg)
            if self == player then
                warn("[ANTI-KICK] Blocked (hook):", msg)
                if Rayfield and Rayfield.Notify then Rayfield:Notify({Title="🛡️ Anti-Kick", Content="Kick bloqueado (hook)", Duration=5, Image="shield"}) end
                return
            end
            return OldKick(self, msg)
        end)
    end
end)

-- ============================================================
-- 🛡️ SAFE CHAR & VIRTUAL INPUT
-- ============================================================
local function SafeGetHum(char)
    char = char or player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildWhichIsA("Humanoid", true)
end
local function SafeGetRoot(char)
    char = char or player.Character
    if not char then return nil end
    local hum = SafeGetHum(char)
    if hum and hum.RootPart then return hum.RootPart end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
end
local function VInput_Click(x,y) pcall(function() VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0) task.wait(0.02) VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0) end) end
local function VInput_Key(k,down) pcall(function() VirtualInputManager:SendKeyEvent(down,k,false,game) end) end

-- ============================================================
-- 🛡️ WATCHDOG & UI_FLAGS
-- ============================================================
local UI_Flags = {}
local Watchdog = { Errors={}, MaxErrors=3, Connections={} }
function Watchdog:Wrap(name, func, interval)
    interval = interval or 0
    if self.Connections[name] then self.Connections[name]:Disconnect() end
    self.Errors[name] = 0
    local lastRun = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        if not CONFIG._Flags[name] then return conn:Disconnect() end
        if interval > 0 and tick() - lastRun < interval then return end
        if interval > 0 then lastRun = tick() end
        local ok, err = pcall(func, dt)
        if not ok then
            self.Errors[name] = (self.Errors[name] or 0) + 1
            warn(`[WATCHDOG] {name} Error [{self.Errors[name]}/{self.MaxErrors}]: {err}`)
            if self.Errors[name] >= self.MaxErrors then self:ForceDisable(name, tostring(err)) end
        else self.Errors[name] = 0 end
    end)
    self.Connections[name] = conn
    return conn
end
function Watchdog:ForceDisable(flagName, reason)
    if not CONFIG._Flags[flagName] then return end
    CONFIG._Flags[flagName] = false; CONFIG[flagName] = false
    if UI_Flags[flagName] then pcall(function() UI_Flags[flagName]:Set(false) end) end
    if Rayfield and Rayfield.Notify then Rayfield:Notify({Title="🛡️ WATCHDOG", Content=flagName.." desligado: "..reason, Duration=6, Image="alert-triangle"}) end
end

-- ============================================================
-- 🧠 HELPERS DE APLICAÇÃO DE FÍSICA/VISUAL
-- ============================================================
local function getHum() return SafeGetHum() end
local function getRoot() return SafeGetRoot() end
local function limitSpeed(s) return math.min(s, CONFIG.LimiteVelocidade) end

local function applyPhysics()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed)
        hum.JumpPower = CONFIG.JumpPower; hum.UseJumpPower = true
        if CONFIG.Sit then hum.Sit = true end
    end
    workspace.Gravity = CONFIG.Gravity * 196.2
end

local function applyVisuals()
    camera.FieldOfView = CONFIG.FOV
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end

local function applyAll()
    applyPhysics()
    applyVisuals()
end

-- ============================================================
-- 🟢 VISUALS LOOP (Watchdog)
-- ============================================================
Watchdog:Wrap("VisualsLoop", function()
    applyVisuals()
end, 1)

-- ============================================================
-- 🟢 ESP HIGHLIGHT (Watchdog)
-- ============================================================
local ESP_Highlights = {}
Watchdog:Wrap("ESPLoop", function()
    if not CONFIG.ESP then
        for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
        table.clear(ESP_Highlights)
        return
    end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr~=player and plr.Character and SafeGetRoot(plr.Character) then
            local hl = ESP_Highlights[plr]
            if not hl or not hl.Parent then
                hl=Instance.new("Highlight")
                hl.Name="ESP_HL"
                hl.FillTransparency=0.5
                hl.OutlineTransparency=0
                hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent=plr.Character
                ESP_Highlights[plr]=hl
            end
            hl.FillColor=plr.TeamColor.Color
            hl.OutlineColor=Color3.new(1,1,1)
        end
    end
    for plr,hl in pairs(ESP_Highlights) do
        if not Players:FindFirstChild(plr.Name) then
            pcall(function() hl:Destroy() end)
            ESP_Highlights[plr]=nil
        end
    end
end, 0.5)

-- ============================================================
-- 🟡 MOVEMENT LOOPS (Watchdog)
-- ============================================================
Watchdog:Wrap("SpeedLoop", function()
    local hum = getHum()
    if hum then hum.WalkSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed) end
end, 0.1)

Watchdog:Wrap("SpinLoop", function(dt)
    if not CONFIG.Spin then return end
    local root = getRoot()
    if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed)*dt*60, 0) end
end)

Watchdog:Wrap("NoclipLoop", function()
    if not CONFIG.Noclip then return end
    local char = player.Character
    if char then for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end end end
end, 0.1)

-- ============================================================
-- 🔴 FLY STEALTH
-- ============================================================
local FlyConn
local function ToggleFly(state)
    CONFIG.Fly = state; CONFIG._Flags.Fly = state
    local hum = getHum(); local root = getRoot()
    if state and (not hum or not root) then CONFIG.Fly=false; CONFIG._Flags.Fly=false; if UI_Flags.Fly then UI_Flags.Fly:Set(false) end return end
    if state then
        hum.PlatformStand = true
        Rayfield:Notify({Title="Fly", Content="Ativado (Stealth CFrame)", Duration=2, Image="check-circle"})
        FlyConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.Fly then return ToggleFly(false) end
            hum = getHum(); root = getRoot(); if not hum or not root then return ToggleFly(false) end
            local moveDir = hum.MoveDirection
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed) * dt * 60
            local newCF = root.CFrame
            if moveDir.Magnitude > 0 then newCF = newCF + (moveDir * speed) end
            local camLook = camera.CFrame.LookVector
            local jump = UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA)
            local crouch = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2)
            if jump then newCF = newCF + Vector3.new(0,speed,0)
            elseif crouch then newCF = newCF - Vector3.new(0,speed,0)
            elseif math.abs(camLook.Y) > 0.15 then newCF = newCF + Vector3.new(0, camLook.Y * speed * 0.5, 0) end
            root.CFrame = newCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        if FlyConn then FlyConn:Disconnect(); FlyConn=nil end
        if hum then hum.PlatformStand=false end
        Rayfield:Notify({Title="Fly", Content="Desativado", Duration=2, Image="x-circle"})
    end
end

-- ============================================================
-- 🔴 FREECAM
-- ============================================================
local FreeCamConn
local function ToggleFreeCam(state)
    CONFIG.FreeCam = state; CONFIG._Flags.FreeCam = state
    local hum = getHum(); local root = getRoot()
    if state and root then
        camera.CameraType = Enum.CameraType.Scriptable; camera.CameraSubject = nil
        if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
        FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return ToggleFreeCam(false) end
            local move = Vector3.zero; local cf = camera.CFrame; local speed = 100*dt
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then camera.CFrame = camera.CFrame + move.Unit * speed end
        end)
    else
        if FreeCamConn then FreeCamConn:Disconnect(); FreeCamConn=nil end
        camera.CameraType = Enum.CameraType.Custom; camera.CameraSubject = hum
        if hum then applyPhysics() end
    end
end

-- ============================================================
-- 🟢 EVENTOS: INFINITE JUMP / ANTI-AFK / CLICK TP
-- ============================================================
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local h=getHum()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

player.Idled:Connect(function()
    if CONFIG.AntiAFK then
        VInput_Click(math.random(100,500),math.random(100,500))
        VInput_Key(Enum.KeyCode.Unknown,true)
        task.wait(0.05)
        VInput_Key(Enum.KeyCode.Unknown,false)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if CONFIG.ClickTP and not gp and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
        local root = getRoot(); if not root then return end
        local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
        local params = RaycastParams.new(); params.FilterDescendantsInstances={player.Character}; params.FilterType=Enum.RaycastFilterType.Exclude
        local hit = workspace:Raycast(ray.Origin, ray.Direction*1000, params)
        if hit then root.CFrame = CFrame.new(hit.Position + Vector3.new(0,3,0)) end
    end
end)

-- ============================================================
-- 🔄 RESPAWN HANDLER
-- ============================================================
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyAll()
    if CONFIG.Fly then ToggleFly(true) end
    if CONFIG.FreeCam then ToggleFreeCam(true) end
end)

-- ============================================================
-- 🖥️ UI RAYFIELD + AUTO-SAVE/LOAD HOOKS (MELHORIA 3)
-- ============================================================

-- 1. CARREGA CONFIG ANTES DE CRIAR UI (Para CurrentValue pegar o valor salvo)
loadConfig()

local Window = Rayfield:CreateWindow({
    Name = "Universal Lite • "..(ExecutorCaps.hasWriteFile and "💾" or "📋").." • "..(ExecutorCaps.hasRequest and "🌐" or "🚫"),
    LoadingTitle = "Carregando...", LoadingSubtitle = "Modo Seguro Ativado",
    ConfigurationSaving = {Enabled=false}, KeySystem=false
})

local MoveTab = Window:CreateTab("Movimento ⚠️", 4483362458)
local VisualTab = Window:CreateTab("Visuais ✅", 4483362458)
local UtilTab = Window:CreateTab("Utilitários", 4483362458)

-- Helpers UI COM AUTO-SAVE EM CADA CALLBACK
local function Slider(tab, cfg, opts)
    opts.Flag = cfg
    opts.CurrentValue = CONFIG[cfg]
    opts.Callback = function(v)
        CONFIG[cfg] = v
        if cfg == "WalkSpeed" or cfg == "FlySpeed" or cfg == "VelocidadeGlobal" then CONFIG[cfg] = limitSpeed(v) end
        if cfg == "FOV" then camera.FieldOfView = v end
        if cfg == "Gravity" then workspace.Gravity = v * 196.2 end
        if cfg == "JumpPower" then local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end
        if cfg == "SpinSpeed" then local r=getRoot(); local b=r and r:FindFirstChild("SpinForce"); if b then b.AngularVelocity=Vector3.new(0,v,0) end end
        
        -- 💾 AUTO-SAVE IMEDIATO
        saveConfig()
        
        Rayfield:Notify({Title="Set", Content=cfg.." = "..v, Duration=1, Image="check"})
    end
    local o = tab:CreateSlider(opts)
    UI_Flags[cfg] = o
    return o
end

local function Toggle(tab, cfg, opts, cb)
    opts.Flag = cfg
    opts.CurrentValue = CONFIG[cfg]
    opts.Callback = function(v)
        CONFIG[cfg] = v
        CONFIG._Flags[cfg] = v
        if cb then cb(v) end
        
        -- 💾 AUTO-SAVE IMEDIATO
        saveConfig()
        
        Rayfield:Notify({Title=v and "ON" or "OFF", Content=cfg, Duration=1, Image=v and "check-circle" or "x-circle"})
    end
    local o = tab:CreateToggle(opts)
    UI_Flags[cfg] = o
    return o
end

-- ========== VISUAIS ==========
VisualTab:CreateSection("🟢 Seguros — Funcionam Quase Sempre")
Toggle(VisualTab, "ESP", {Name="ESP Players (Highlight)"})
Toggle(VisualTab, "Fullbright", {Name="Fullbright (Brilho Total)"})
Toggle(VisualTab, "NoFog", {Name="No Fog (Sem Neblina)"})
Slider(VisualTab, "FOV", {Name="FOV", Range={50,120}, Increment=1})

-- ========== MOVIMENTO ==========
MoveTab:CreateSection("🟡 Arriscados — Podem Rubberband/Kick em Jogos Protegidos")
MoveTab:CreateLabel("⚠️ Use só em Obby/Tycoon/RP Leve. Desligue em BedWars, Arsenal, MM2, etc.")
Slider(MoveTab, "WalkSpeed", {Name="WalkSpeed", Range={16,500}, Increment=1})
Toggle(MoveTab, "AplicarVelocidade", {Name="Usar Velocidade Global"}, function(v) applyPhysics() end)
Slider(MoveTab, "VelocidadeGlobal", {Name="Velocidade Global", Range={1,1000}, Increment=1})
Slider(MoveTab, "LimiteVelocidade", {Name="Limite Máximo", Range={1,1000}, Increment=1})
Slider(MoveTab, "JumpPower", {Name="JumpPower", Range={50,300}, Increment=1})
Slider(MoveTab, "Gravity", {Name="Gravidade", Range={0.1,5}, Increment=0.1})
Toggle(MoveTab, "InfiniteJump", {Name="Infinite Jump"})
Toggle(MoveTab, "Spin", {Name="Spin"})
Slider(MoveTab, "SpinSpeed", {Name="Spin Speed", Range={1,50}, Increment=1})
Toggle(MoveTab, "Sit", {Name="Sit"})

MoveTab:CreateSection("🔴 Perigosos — Kick Quase Certo em Comp. (OFF por padrão)")
Toggle(MoveTab, "Fly", {Name="Fly (Stealth CFrame)"}, ToggleFly)
Slider(MoveTab, "FlySpeed", {Name="Fly Speed", Range={1,1000}, Increment=5})
Toggle(MoveTab, "Noclip", {Name="Noclip"})
Toggle(MoveTab, "ClickTP", {Name="Click/Touch TP (Teleporte)"})

-- ========== UTILITÁRIOS ==========
UtilTab:CreateSection("🟢 Utils Seguros")
Toggle(UtilTab, "AntiAFK", {Name="Anti-AFK (VirtualInput)"})
UtilTab:CreateButton({Name="Rejoin", Callback=function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, player) end})

if ExecutorCaps.hasRequest then
    UtilTab:CreateButton({Name="Server Hop", Callback=function()
        Rayfield:Notify({Title="Server Hop", Content="Procurando...", Duration=10, Image="loader"})
        task.spawn(function()
            local ok, res = pcall(function() return HttpService:RequestAsync({Url="https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method="GET"}) end)
            if ok and res.Success then
                local data = HttpService:JSONDecode(res.Body)
                for _,s in pairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then TeleportService:TeleportToPlaceInstance(PlaceId,s.id,player) return end end
            end
            Rayfield:Notify({Title="Erro", Content="Sem servidor ou API falhou", Duration=5, Image="alert-circle"})
        end)
    end})
else
    UtilTab:CreateLabel("🚫 Server Hop indisponível (Executor sem RequestAsync)")
end

UtilTab:CreateSection("💾 Config (Auto-Save Ativo)")
UtilTab:CreateButton({Name="Forçar Salvar Agora", Callback=function() saveConfig() Rayfield:Notify({Title="Config", Content="Salvo manualmente!", Duration=2, Image="check-circle"}) end})
UtilTab:CreateButton({Name="Resetar Tudo (Padrão)", Callback=function()
    CONFIG = {ESP=false,Fullbright=false,NoFog=false,FOV=70,AntiAFK=false,WalkSpeed=16,JumpPower=50,Gravity=1,InfiniteJump=false,Spin=false,SpinSpeed=10,Sit=false,Fly=false,FlySpeed=50,Noclip=false,ClickTP=false,AntiLag=false,Rejoin=false,ServerHop=false,SelectedPlayer="Nenhum",VelocidadeGlobal=1000,AplicarVelocidade=false,LimiteVelocidade=1000,_Flags={}}
    applyAll(); ToggleFly(false); ToggleFreeCam(false)
    for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end; table.clear(ESP_Highlights)
    saveConfig() -- Salva o reset
    Rayfield:Notify({Title="Reset", Content="Defaults restaurados e salvos", Duration=2, Image="check-circle"})
end})

-- ========== FINALIZAÇÃO ==========
applyAll() -- Aplica estado carregado (ou defaults false) no character atual
Rayfield:LoadConfiguration()
Rayfield:Notify({Title="Universal Lite", Content="Carregado — Auto-Save Ativo • Pasta: "..CONFIG_FOLDER, Duration=5, Image="check-circle"})

getgenv()._UniversalScriptCleanup = function()
    for _,c in pairs(Watchdog.Connections) do pcall(function() c:Disconnect() end) end
    if FlyConn then FlyConn:Disconnect() end
    if FreeCamConn then FreeCamConn:Disconnect() end
    for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
    print("[UniversalLite] Cleanup OK")
end
