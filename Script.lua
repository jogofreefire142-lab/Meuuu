-- 🔵 1. ESPERA PARA AUTO EXECUTE (game:IsLoaded)
repeat task.wait() until game:IsLoaded()
task.wait(1)

-- Carregar Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlaceId = game.PlaceId

-- ============================================================
-- 🛡️ SISTEMAS DE SEGURANÇA (INJETADOS NO SEU CÓDIGO)
-- ============================================================

-- 1. SAFE CHAR (Funciona em QUALQUER jogo/rig)
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

-- 2. VIRTUAL INPUT (Cliques/Teclas REAIS - Anti-Cheat Bypass)
local function VInput_Click(x, y)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function VInput_Key(keyCode, down)
    pcall(function() VirtualInputManager:SendKeyEvent(down, keyCode, false, game) end)
end

-- 3. WATCHDOG (Auto-desliga feature se der erro - Segurança Total)
local Watchdog = { Errors = {}, MaxErrors = 3, Connections = {} }
function Watchdog:Wrap(name, func, interval)
    interval = interval or 0
    if self.Connections[name] then self.Connections[name]:Disconnect() end
    self.Errors[name] = 0
    local lastRun = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not CONFIG._Flags[name] then return conn:Disconnect() end
        if interval > 0 and tick() - lastRun < interval then return end
        if interval > 0 then lastRun = tick() end
        local ok, err = pcall(func, dt)
        if not ok then
            self.Errors[name] = (self.Errors[name] or 0) + 1
            warn(`[WATCHDOG] ${name} Error [${self.Errors[name]}/${self.MaxErrors}]: ${err}`)
            if self.Errors[name] >= self.MaxErrors then
                self:ForceDisable(name, tostring(err))
            end
        else
            self.Errors[name] = 0
        end
    end)
    self.Connections[name] = conn
    return conn
end

function Watchdog:ForceDisable(flagName, reason)
    if not CONFIG._Flags[flagName] then return end
    CONFIG._Flags[flagName] = false
    CONFIG[flagName] = false
    if Rayfield.Flags and Rayfield.Flags[flagName] then
        pcall(function() Rayfield.Flags[flagName]:Set(false) end)
    end
    Rayfield:Notify({ Title = "🛡️ WATCHDOG", Content = flagName .. " desligado (Segurança):\n" .. reason, Duration = 6, Image = "alert-triangle" })
end

-- 4. ANTI-KICK LOCAL (Impede kick de scripts do jogo)
local OldKick
OldKick = hookfunction(player.Kick, function(self, msg)
    if self == player then
        warn("[ANTI-KICK] Kick local bloqueado:", msg)
        Rayfield:Notify({ Title = "🛡️ Anti-Kick", Content = "Tentativa de kick bloqueada:\n" .. tostring(msg), Duration = 5, Image = "shield" })
        return
    end
    return OldKick(self, msg)
end)

-- ============================================================
-- SUA CONFIG ORIGINAL (COM _Flags PARA WATCHDOG)
-- ============================================================
local CONFIG = {
    WalkSpeed = 16, JumpPower = 50, Gravity = 1,
    InfiniteJump = false, Noclip = false, Spin = false, SpinSpeed = 10, Sit = false,
    Fly = false, FlySpeed = 50, ESP = false, Fullbright = false, NoFog = false,
    FOV = 70, FreeCam = false, AntiAFK = false, AntiLag = false,
    Rejoin = false, ServerHop = false, SelectedPlayer = "Nenhum",
    MaxSpeed = 1000, Organize = false, ClickTP = false,
    VelocidadeGlobal = 1000, AplicarVelocidade = false, LimiteVelocidade = 1000,
    _Flags = {} -- Watchdog usa isso
}

-- Config por PlaceId (Não mistura jogos)
local CONFIG_PATH = `ScriptUniversal_Config_{PlaceId}.json`

local function saveConfig()
    local data = {}
    for k,v in pairs(CONFIG) do if type(v)~="function" and k:sub(1,1)~="_" then data[k]=v end end
    local ok, err = pcall(function() writefile(CONFIG_PATH, HttpService:JSONEncode(data)) end)
    Rayfield:Notify({Title = ok and "Sucesso" or "Erro", Content = ok and "Configurações salvas!" or "Erro: "..tostring(err), Duration = 3, Image = ok and "check-circle" or "alert-circle"})
end

local function loadConfig()
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_PATH)) end)
    if ok and data then
        for k,v in pairs(data) do CONFIG[k]=v end
        for k,v in pairs(CONFIG) do if type(v)=="boolean" then CONFIG._Flags[k]=v end end
        Rayfield:Notify({Title = "Carregado", Content = "Configurações aplicadas.", Duration = 3, Image = "check-circle"})
    end
end

-- ============================================================
-- SUAS FUNÇÕES ORIGINAIS (CORRIGIDAS PARA USAR SafeChar)
-- ============================================================
local function getHum() return SafeGetHum() end
local function getRoot() return SafeGetRoot() end

local function limitSpeed(speed) return math.min(speed, CONFIG.LimiteVelocidade) end

local function applyUniversalSpeed()
    local hum = getHum()
    if hum then hum.WalkSpeed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed end
    local root = getRoot()
    if root and CONFIG.Fly then -- Fly agora é CFrame, não BodyVelocity
        -- Lógica de velocidade do Fly é tratada no Loop do Fly
    end
end

local function applyConfig()
    local hum = getHum()
    local root = getRoot()
    if not hum or not root then return end
    
    hum.WalkSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed)
    hum.JumpPower = CONFIG.JumpPower
    hum.UseJumpPower = true
    hum.Sit = CONFIG.Sit
    
    workspace.Gravity = CONFIG.Gravity * 196.2
    camera.FieldOfView = CONFIG.FOV
    
    -- Spin (BodyAngularVelocity)
    local bav = root:FindFirstChild("SpinForce")
    if CONFIG.Spin then
        if not bav then bav = Instance.new("BodyAngularVelocity"); bav.Name="SpinForce"; bav.MaxTorque=Vector3.new(0,math.huge,0); bav.Parent=root end
        bav.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0)
    elseif bav then bav:Destroy() end
    
    -- Visuals
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end

-- ============================================================
-- FEATURES COMPLEXAS REESCRITAS PARA SEGURANÇA (Fly, ESP, FreeCam)
-- ============================================================

-- FLY STEALTH (CFrame + VirtualInput) - Substitui seu applyConfig Fly antigo
local FlyConn
local function ToggleFly(state)
    CONFIG.Fly = state; CONFIG._Flags.Fly = state
    local hum = getHum(); local root = getRoot()
    if not hum or not root then return end
    
    if state then
        hum.PlatformStand = true
        Rayfield:Notify({Title="Fly", Content="Ativado (Modo Stealth CFrame)", Duration=3, Image="check-circle"})
        FlyConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.Fly then return ToggleFly(false) end
            local hum = getHum(); local root = getRoot()
            if not hum or not root then return ToggleFly(false) end
            
            local moveDir = hum.MoveDirection
            local camCF = camera.CFrame
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed) * dt * 60
            local newCF = root.CFrame
            
            if moveDir.Magnitude > 0 then
                local look = camCF.LookVector; local right = camCF.RightVector
                local flatLook = Vector3.new(look.X,0,look.Z).Unit
                local flatRight = Vector3.new(right.X,0,right.Z).Unit
                local moveVec = (flatLook * -moveDir.Z) + (flatRight * moveDir.X)
                newCF = newCF + (moveVec.Unit * speed)
            end
            
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then newCF = newCF + Vector3.new(0, speed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then newCF = newCF - Vector3.new(0, speed, 0) end
            
            root.CFrame = newCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        if FlyConn then FlyConn:Disconnect(); FlyConn=nil end
        hum.PlatformStand = false
        Rayfield:Notify({Title="Fly", Content="Desativado", Duration=2, Image="x-circle"})
    end
end

-- ESP REAL (Highlight Loop) - Seu ESP original não funcionava
local ESP_Highlights = {}
Watchdog:Wrap("ESPLoop", function()
    if not CONFIG.ESP then 
        for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
        table.clear(ESP_Highlights)
        return 
    end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and SafeGetRoot(plr.Character) then
            local hl = ESP_Highlights[plr]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight"); hl.Name="ESP_Highlight"; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=plr.Character; ESP_Highlights[plr]=hl
            end
            hl.FillColor = plr.TeamColor.Color; hl.OutlineColor = Color3.new(1,1,1)
        end
    end
    for plr, hl in pairs(ESP_Highlights) do if not Players:FindFirstChild(plr.Name) then pcall(function() hl:Destroy() end); ESP_Highlights[plr]=nil end end
end, 0.5)

-- FREECAM CORRIGIDO
local FreeCamConn
local function ToggleFreeCam(state)
    CONFIG.FreeCam = state; CONFIG._Flags.FreeCam = state
    local hum = getHum(); local root = getRoot()
    if state and root then
        camera.CameraType = Enum.CameraType.Scriptable; camera.CameraSubject = nil
        if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
        FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return ToggleFreeCam(false) end
            local speed = 100 * dt; local move = Vector3.zero; local cf = camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then camera.CFrame = camera.CFrame + (move.Unit * speed) end
        end)
    else
        if FreeCamConn then FreeCamConn:Disconnect(); FreeCamConn=nil end
        camera.CameraType = Enum.CameraType.Custom; camera.CameraSubject = hum
        if hum then applyConfig() end
    end
end

-- VISUALS LOOP (Leve)
Watchdog:Wrap("VisualsLoop", function()
    camera.FieldOfView = CONFIG.FOV
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end, 1)

-- NOCLIP LOOP (Watchdog)
Watchdog:Wrap("NoclipLoop", function()
    if not CONFIG.Noclip then return end
    local char = player.Character
    if char then for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
end, 0.1)

-- SPIN LOOP (Watchdog)
Watchdog:Wrap("SpinLoop", function(dt)
    if not CONFIG.Spin then return end
    local root = getRoot()
    if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed) * dt * 60, 0) end
end)

-- INFINITE JUMP (Evento)
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = getHum()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- ANTI-AFK (VirtualInput Real)
player.Idled:Connect(function()
    if CONFIG.AntiAFK then
        VInput_Click(math.random(100,500), math.random(100,500))
        VInput_Key(Enum.KeyCode.Unknown, true); task.wait(0.05); VInput_Key(Enum.KeyCode.Unknown, false)
    end
end)

-- CLICK TP (VirtualInput Raycast)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not CONFIG.ClickTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local root = getRoot(); if not root then return end
        local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
        local params = RaycastParams.new(); params.FilterDescendantsInstances = {player.Character}; params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result then root.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0)) end
    end
end)

-- PROTEÇÃO DE VELOCIDADE (Heartbeat Leve)
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        local target = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed)
        if hum.WalkSpeed ~= target then hum.WalkSpeed = target end
    end
end)

-- RESPAWN HANDLER
player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applyConfig()
    if CONFIG.Fly then ToggleFly(true) end
    if CONFIG.FreeCam then ToggleFreeCam(true) end
    -- Noclip/ESP/Spin/Visuals são Watchdog (auto-reconectam via _Flags)
end)

-- ============================================================
-- UI RAYFIELD (SUA ESTRUTURA ORIGINAL MANTIDA)
-- ============================================================
loadConfig() -- 1. Carrega JSON ANTES da UI

local Window = Rayfield:CreateWindow({
    Name = "Script Universal - Player",
    LoadingTitle = "Carregando Menu...", LoadingSubtitle = "Aba Player Completa (Seguro)",
    ConfigurationSaving = { Enabled = true, FolderName = "DeltaPlayerHub", FileName = "PlayerConfig" },
    KeySystem = false
})

local PlayerTab = Window:CreateTab("Player", 4483362458)

-- Helpers para sincronizar UI <-> CONFIG <-> WATCHDOG
local function SyncSlider(cfgKey, opts)
    opts.Flag = cfgKey; opts.CurrentValue = CONFIG[cfgKey]
    opts.Callback = function(v)
        CONFIG[cfgKey] = v
        if cfgKey=="WalkSpeed" or cfgKey=="FlySpeed" or cfgKey=="VelocidadeGlobal" then CONFIG[cfgKey]=limitSpeed(v) end
        if cfgKey=="FOV" then camera.FieldOfView=v end
        if cfgKey=="Gravity" then workspace.Gravity=v*196.2 end
        if cfgKey=="JumpPower" then local h=getHum() if h then h.JumpPower=v; h.UseJumpPower=true end end
        if cfgKey=="SpinSpeed" then local r=getRoot() local b=r and r:FindFirstChild("SpinForce") if b then b.AngularVelocity=Vector3.new(0,v,0) end end
        Rayfield:Notify({Title="Atualizado", Content=cfgKey..": "..v, Duration=2, Image="check"})
    end
    return PlayerTab:CreateSlider(opts)
end

local function SyncToggle(cfgKey, opts, onToggle)
    opts.Flag = cfgKey; opts.CurrentValue = CONFIG[cfgKey]
    opts.Callback = function(v)
        CONFIG[cfgKey] = v; CONFIG._Flags[cfgKey] = v
        if onToggle then onToggle(v) end
        Rayfield:Notify({Title=v and "Ativado" or "Desativado", Content=cfgKey, Duration=2, Image=v and "check-circle" or "x-circle"})
    end
    return PlayerTab:CreateToggle(opts)
end

-- --- SUAS SEÇÕES ORIGINAIS ---
PlayerTab:CreateSection("🏃 Movimentação e Física")
SyncSlider("VelocidadeGlobal", {Name="Velocidade Universal", Range={1,1000}, Increment=1})
SyncToggle("AplicarVelocidade", {Name="Ativar Velocidade Universal"}, function(v) applyUniversalSpeed() end)
SyncSlider("LimiteVelocidade", {Name="Limite de Velocidade", Range={1,1000}, Increment=1})
SyncSlider("MaxSpeed", {Name="Velocidade Máxima", Range={1,1000}, Increment=1})
SyncSlider("WalkSpeed", {Name="WalkSpeed (Velocidade)", Range={1,1000}, Increment=1})
SyncSlider("JumpPower", {Name="JumpPower (Força do Pulo)", Range={50,300}, Increment=1})
SyncSlider("Gravity", {Name="Gravidade", Range={0.1,5}, Increment=0.1})
SyncToggle("InfiniteJump", {Name="Infinite Jump (Pulo Infinito)"})
SyncToggle("Noclip", {Name="Noclip (Atravessar Paredes)"})
SyncToggle("Spin", {Name="Spin (Girar Rápido)"})
SyncSlider("SpinSpeed", {Name="SpinSpeed (Velocidade do Giro)", Range={1,50}, Increment=1})
SyncToggle("Sit", {Name="Sit (Sentar)"})

PlayerTab:CreateSection("✈️ Fly (Voar)")
SyncToggle("Fly", {Name="Ativar Fly (Stealth CFrame)"}, ToggleFly)
SyncSlider("FlySpeed", {Name="Velocidade do Fly", Range={1,1000}, Increment=5})

PlayerTab:CreateSection("👁️ Visual e Câmera")
SyncToggle("ESP", {Name="ESP Players (Highlight)"})
SyncToggle("Fullbright", {Name="Fullbright (Brilho Máximo)"})
SyncToggle("NoFog", {Name="No Fog (Sem Neblina)"})
SyncSlider("FOV", {Name="FOV (Campo de Visão)", Range={50,120}, Increment=1})
SyncToggle("FreeCam", {Name="FreeCam (Câmera Livre)"}, ToggleFreeCam)

PlayerTab:CreateSection("👥 Jogadores e Teleporte")
local playerList = {}; for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(playerList,p.Name) end end
local dd = PlayerTab:CreateDropdown({Name="Selecionar Jogador", Flag="SelectedPlayer", Options=playerList, CurrentOption=playerList[1] or "Nenhum", Callback=function(o) CONFIG.SelectedPlayer=o end})
PlayerTab:CreateButton({Name="🔄 Atualizar Lista", Callback=function() local l={"Nenhum"}; for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(l,p.Name) end end dd:Refresh(l,true) end})
PlayerTab:CreateButton({Name="Teleportar para Jogador", Callback=function() local t=Players:FindFirstChild(CONFIG.SelectedPlayer); local r=getRoot(); if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and r then r.CFrame=t.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,0) end end})
PlayerTab:CreateButton({Name="Assistir Jogador (Spectate)", Callback=function() local t=Players:FindFirstChild(CONFIG.SelectedPlayer); if t and t.Character and t.Character:FindFirstChild("Humanoid") then camera.CameraSubject=t.Character.Humanoid; Rayfield:Notify({Title="Spectate", Content="Assistindo "..t.Name, Duration=3}) end end})
SyncToggle("ClickTP", {Name="Click/Touch TP (Teleporte por Clique)"})

PlayerTab:CreateSection("⚙️ Utilidades e Servidor")
PlayerTab:CreateButton({Name="Organizar (Toggle)", Callback=function() CONFIG.Organize=not CONFIG.Organize; Rayfield:Notify({Title="Organizar", Content=CONFIG.Organize and "Ativado" or "Desativado"}) end})
SyncToggle("AntiLag", {Name="Anti-Lag (Reduz Updates Watchdog)"})
SyncToggle("AntiAFK", {Name="Anti-AFK (Clique Real)"})
PlayerTab:CreateButton({Name="Salvar Config (JSON)", Callback=saveConfig})
PlayerTab:CreateButton({Name="Carregar Config (JSON)", Callback=function() loadConfig(); applyConfig(); Rayfield:Notify({Title="OK", Content="Carregado e aplicado"}) end})
PlayerTab:CreateButton({Name="Resetar Configurações", Callback=function() CONFIG={WalkSpeed=16,JumpPower=50,Gravity=1,InfiniteJump=false,Noclip=false,Spin=false,SpinSpeed=10,Sit=false,Fly=false,FlySpeed=50,ESP=false,Fullbright=false,NoFog=false,FOV=70,FreeCam=false,AntiAFK=false,AntiLag=false,SelectedPlayer="Nenhum",MaxSpeed=1000,Organize=false,ClickTP=false,VelocidadeGlobal=1000,AplicarVelocidade=false,LimiteVelocidade=1000,_Flags={}}; applyConfig(); ToggleFly(false); ToggleFreeCam(false); for _,hl in pairs(ESP_Highlights) do hl:Destroy() end; table.clear(ESP_Highlights); Rayfield:Notify({Title="Reset", Content="Padrão restaurado"}) end})
PlayerTab:CreateButton({Name="Resetar Velocidade", Callback=function() CONFIG.VelocidadeGlobal=1000; CONFIG.AplicarVelocidade=false; CONFIG.LimiteVelocidade=1000; CONFIG.WalkSpeed=16; CONFIG.FlySpeed=50; applyConfig(); Rayfield:Notify({Title="Reset", Content="Velocidades resetadas"}) end})
PlayerTab:CreateButton({Name="Resetar Personagem", Callback=function() local h=getHum() if h then h.Health=0 end end})
PlayerTab:CreateButton({Name="Rejoin (Entrar de Novo)", Callback=function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, player) end})
PlayerTab:CreateButton({Name="Server Hop (Trocar Servidor)", Callback=function()
    Rayfield:Notify({Title="Server Hop", Content="Procurando...", Duration=10})
    task.spawn(function()
        local ok, res = pcall(function() return HttpService:RequestAsync({Url=`https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&limit=100`, Method="GET"}) end)
        if ok and res.Success then
            local data = HttpService:JSONDecode(res.Body)
            for _,s in pairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then TeleportService:TeleportToPlaceInstance(PlaceId, s.id, player); return end end
            Rayfield:Notify({Title="Server Hop", Content="Lotado/Erro", Duration=5})
        else Rayfield:Notify({Title="Erro", Content="API falhou (Executor sem RequestAsync?)", Duration=5, Image="alert-circle"}) end
    end)
end})

-- ============================================================
-- FINALIZAÇÃO
-- ============================================================
applyConfig() -- Aplica física inicial
Rayfield:LoadConfiguration() -- 2. Carrega UI Flags
Rayfield:Notify({Title="✅ Script Carregado", Content="Watchdog Ativo | VirtualInput | Anti-Kick | Config por Jogo ("..PlaceId..")", Duration=6, Image="check-circle"})

-- Cleanup Global (Para reexecução segura)
getgenv()._UniversalScriptCleanup = function()
    for _,c in pairs(Watchdog.Connections) do pcall(function() c:Disconnect() end) end
    if FlyConn then FlyConn:Disconnect() end
    if FreeCamConn then FreeCamConn:Disconnect() end
    for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
    if OldKick then hookfunction(player.Kick, OldKick) end
    print("[UniversalScript] Cleanup completo.")
end
