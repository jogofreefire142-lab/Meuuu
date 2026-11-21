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

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlaceId = game.PlaceId

-- ============================================================
-- 🛡️ SISTEMAS DE SEGURANÇA E COMPATIBILIDADE (INTERNOS)
-- ============================================================

-- 1. SAFE CHAR (Funciona em QUALQUER jogo: R6, R15, Custom, StarterCharacter)
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

-- 2. VIRTUAL INPUT (Cliques/Teclas REAIS - Bypass Heurística / Funciona Mobile)
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

-- 3. WATCHDOG (Auto-desliga feature se der erro 3x - Evita Kick/Script Timeout/Console Spam)
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

-- 4. ANTI-KICK LOCAL (Impede kick de LocalScripts do jogo)
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
-- SUA CONFIG ORIGINAL (MANTIDA) + ESPTipo + _Flags
-- ============================================================
local CONFIG = {
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = 1,
    InfiniteJump = false,
    Noclip = false,
    Spin = false,
    SpinSpeed = 10,
    Sit = false,
    Fly = false,
    FlySpeed = 50,
    ESP = false,
    ESPTipo = "Sem Título", -- NOVO: "Sem Título", "Assassino", "Policial"
    Fullbright = false,
    NoFog = false,
    FOV = 70,
    FreeCam = false,
    AntiAFK = false,
    AntiLag = false,
    Rejoin = false,
    ServerHop = false,
    SelectedPlayer = "Nenhum",
    MaxSpeed = 1000,
    Organize = false,
    ClickTP = false,
    VelocidadeGlobal = 1000,
    AplicarVelocidade = false,
    LimiteVelocidade = 1000,
    _Flags = {} -- Watchdog usa isso
}

-- Config por PlaceId (Não mistura jogos diferentes)
local CONFIG_PATH = "ScriptUniversal_Config_" .. PlaceId .. ".json"

-- Função para salvar configurações (Botão Manual)
local function saveConfig()
    local data = {}
    for k, v in pairs(CONFIG) do if type(v) ~= "function" and k:sub(1,1) ~= "_" then data[k] = v end end
    local success, error = pcall(function()
        writefile(CONFIG_PATH, HttpService:JSONEncode(data))
    end)
    if success then
        Rayfield:Notify({ Title = "Sucesso", Content = "Configurações salvas em " .. CONFIG_PATH, Duration = 3, Image = "check-circle" })
    else
        Rayfield:Notify({ Title = "Erro", Content = "Erro ao salvar: " .. tostring(error), Duration = 3, Image = "alert-circle" })
    end
end

-- Função para carregar configurações (Botão Manual)
local function loadConfig()
    local success, data = pcall(function()
        if isfile(CONFIG_PATH) then
            local content = readfile(CONFIG_PATH)
            return HttpService:JSONDecode(content)
        end
        return nil
    end)
    
    if success and data then
        for key, value in pairs(data) do
            CONFIG[key] = value
        end
        -- Sincroniza _Flags para Watchdog
        for key, value in pairs(CONFIG) do
            if type(value) == "boolean" then CONFIG._Flags[key] = value end
        end
        Rayfield:Notify({ Title = "Carregado", Content = "Configurações aplicadas.", Duration = 3, Image = "check-circle" })
    else
        Rayfield:Notify({ Title = "Aviso", Content = "Nenhum config salvo encontrado para este jogo.", Duration = 3, Image = "info" })
    end
end

-- Funções seguras (Agora usam SafeChar)
local function getHum() return SafeGetHum() end
local function getRoot() return SafeGetRoot() end

-- Função para aplicar velocidade universal
local function applyUniversalSpeed()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
    end
end

-- Função para aplicar todas as configurações (Physics + Visuals + Spin)
local function applyConfig()
    local hum = getHum()
    local root = getRoot()
    if not hum or not root then return end
    
    -- Movement
    hum.WalkSpeed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
    hum.JumpPower = CONFIG.JumpPower
    hum.UseJumpPower = true
    hum.Sit = CONFIG.Sit -- Corrige: Liga/Desliga Sit corretamente
    
    -- Gravity (Corrigido: workspace.Gravity)
    workspace.Gravity = CONFIG.Gravity * 196.2
    camera.FieldOfView = CONFIG.FOV
    
    -- Spin
    local bav = root:FindFirstChild("SpinForce")
    if CONFIG.Spin then
        if not bav then bav = Instance.new("BodyAngularVelocity"); bav.Name="SpinForce"; bav.MaxTorque=Vector3.new(0,math.huge,0); bav.Parent=root end
        bav.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0)
    elseif bav then bav:Destroy() end
    
    -- Visuals
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end

local function limitSpeed(speed) return math.min(speed, CONFIG.LimiteVelocidade) end

-- ============================================================
-- FEATURES COMPLEXAS (Fly, ESP, FreeCam, Loops)
-- ============================================================

-- FLY STEALTH (CFrame RenderStepped)
local FlyConn
local function ToggleFly(state)
    CONFIG.Fly = state; CONFIG._Flags.Fly = state
    local hum = getHum(); local root = getRoot()
    if not hum or not root then CONFIG.Fly=false; CONFIG._Flags.Fly=false; if Rayfield.Flags.Fly then Rayfield.Flags.Fly:Set(false) end; return end
    if state then
        hum.PlatformStand = true
        FlyConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.Fly then return ToggleFly(false) end
            local hum = getHum(); local root = getRoot(); if not hum or not root then return ToggleFly(false) end
            local moveDir = hum.MoveDirection; local camCF = camera.CFrame
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed) * dt * 60
            local newCF = root.CFrame
            if moveDir.Magnitude > 0 then
                local look, right = camCF.LookVector, camCF.RightVector
                local flatLook = Vector3.new(look.X,0,look.Z).Unit
                local flatRight = Vector3.new(right.X,0,right.Z).Unit
                newCF = newCF + ((flatLook * -moveDir.Z + flatRight * moveDir.X).Unit * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then newCF += Vector3.new(0, speed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then newCF -= Vector3.new(0, speed, 0) end
            root.CFrame = newCF; root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        if FlyConn then FlyConn:Disconnect(); FlyConn=nil end; hum.PlatformStand=false
    end
end

-- ESP 3 MODOS (Highlight + Watchdog)
local ESP_Highlights = {}
local function GetESPColor(plr)
    if CONFIG.ESPTipo == "Assassino" then return Color3.fromRGB(255, 0, 0) end -- Vermelho
    if CONFIG.ESPTipo == "Policial" then return Color3.fromRGB(0, 0, 255) end   -- Azul
    return Color3.fromRGB(255, 255, 255) -- Sem Título (Branco/Neutro)
end

Watchdog:Wrap("ESPLoop", function()
    if not CONFIG.ESP then for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end; table.clear(ESP_Highlights); return end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and SafeGetRoot(plr.Character) then
            local hl = ESP_Highlights[plr]
            if not hl or not hl.Parent then hl = Instance.new("Highlight"); hl.Name="ESP_Highlight"; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=plr.Character; ESP_Highlights[plr]=hl end
            hl.FillColor = GetESPColor(plr); hl.OutlineColor = Color3.new(0,0,0)
        end
    end
    for plr,hl in pairs(ESP_Highlights) do if not Players:FindFirstChild(plr.Name) then pcall(function() hl:Destroy() end); ESP_Highlights[plr]=nil end end
end, 0.5)

-- FREECAM CORRIGIDO
local FreeCamConn
local function ToggleFreeCam(state)
    CONFIG.FreeCam = state; CONFIG._Flags.FreeCam = state
    local hum = getHum(); local root = getRoot()
    if state and root then camera.CameraType=Enum.CameraType.Scriptable; camera.CameraSubject=nil; if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
        FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return ToggleFreeCam(false) end
            local speed=100*dt; local move=Vector3.zero; local cf=camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move+=cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move-=cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move+=cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move-=cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move+=Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move-=Vector3.new(0,1,0) end
            if move.Magnitude>0 then camera.CFrame += move.Unit*speed end
        end)
    else if FreeCamConn then FreeCamConn:Disconnect(); FreeCamConn=nil end; camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=hum; if hum then applyConfig() end end
end

-- VISUALS LOOP (Leve)
Watchdog:Wrap("VisualsLoop", function()
    camera.FieldOfView = CONFIG.FOV
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end, 1)

-- NOCLIP / SPIN LOOPS (Watchdog)
Watchdog:Wrap("NoclipLoop", function() if not CONFIG.Noclip then return end local c=player.Character if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end, 0.1)
Watchdog:Wrap("SpinLoop", function(dt) if not CONFIG.Spin then return end local r=getRoot() if r then r.CFrame *= CFrame.Angles(0, math.rad(CONFIG.SpinSpeed)*dt*60, 0) end end)

-- INFINITE JUMP / ANTI-AFK / CLICK TP / SPEED PROTECTION
UserInputService.JumpRequest:Connect(function() if CONFIG.InfiniteJump then local h=getHum() if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)
player.Idled:Connect(function() if CONFIG.AntiAFK then VInput_Click(math.random(100,500),math.random(100,500)); VInput_Key(Enum.KeyCode.Unknown,true); task.wait(0.05); VInput_Key(Enum.KeyCode.Unknown,false) end end)
UserInputService.InputBegan:Connect(function(i,g) if CONFIG.ClickTP and not g and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then local r=getRoot() if r then local ray=camera:ViewportPointToRay(i.Position.X,i.Position.Y); local p=RaycastParams.new(); p.FilterDescendantsInstances={player.Character}; p.FilterType=Enum.RaycastFilterType.Exclude; local res=workspace:Raycast(ray.Origin,ray.Direction*1000,p) if res then r.CFrame=CFrame.new(res.Position+Vector3.new(0,3,0)) end end end end)
RunService.Heartbeat:Connect(function() local h=getHum() if h then local t=CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed) if h.WalkSpeed~=t then h.WalkSpeed=t end end end)

-- RESPAWN
player.CharacterAdded:Connect(function() task.wait(0.5); applyConfig(); if CONFIG.Fly then ToggleFly(true) end; if CONFIG.FreeCam then ToggleFreeCam(true) end end)

-- ============================================================
-- UI RAYFIELD (SUA ESTRUTURA ORIGINAL + ESPTipo Dropdown)
-- ============================================================

loadConfig() -- 1. Carrega JSON ANTES da UI

local Window = Rayfield:CreateWindow({
    Name = "Script Universal - Player",
    LoadingTitle = "Carregando Menu...", LoadingSubtitle = "Aba Player Completa",
    ConfigurationSaving = { Enabled = false, FolderName = "DeltaPlayerHub", FileName = "PlayerConfig" }, -- DESATIVADO AUTO-SAVE RAYFIELD
    KeySystem = false
})

local PlayerTab = Window:CreateTab("Player", 4483362458)

-- Helpers Sync
local function SyncSlider(cfgKey, opts)
    opts.Flag=cfgKey; opts.CurrentValue=CONFIG[cfgKey]
    opts.Callback=function(v) CONFIG[cfgKey]=v; if cfgKey=="WalkSpeed" or cfgKey=="FlySpeed" or cfgKey=="VelocidadeGlobal" then CONFIG[cfgKey]=limitSpeed(v) end; if cfgKey=="FOV" then camera.FieldOfView=v end; if cfgKey=="Gravity" then workspace.Gravity=v*196.2 end; if cfgKey=="JumpPower" then local h=getHum() if h then h.JumpPower=v; h.UseJumpPower=true end end; if cfgKey=="SpinSpeed" then local r=getRoot() local b=r and r:FindFirstChild("SpinForce") if b then b.AngularVelocity=Vector3.new(0,v,0) end end; Rayfield:Notify({Title="Atualizado", Content=cfgKey.." = "..v, Duration=2, Image="check"}) end
    return PlayerTab:CreateSlider(opts)
end

local function SyncToggle(cfgKey, opts, onToggle)
    opts.Flag=cfgKey; opts.CurrentValue=CONFIG[cfgKey]
    opts.Callback=function(v) CONFIG[cfgKey]=v; CONFIG._Flags[cfgKey]=v; if onToggle then onToggle(v) end; Rayfield:Notify({Title=v and "Ativado" or "Desativado", Content=cfgKey, Duration=2, Image=v and "check-circle" or "x-circle"}) end
    return PlayerTab:CreateToggle(opts)
end

-- === SEÇÕES ===
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
SyncToggle("Fly", {Name="Ativar Fly (Mobile/PC)"}, ToggleFly)
SyncSlider("FlySpeed", {Name="Velocidade do Fly", Range={1,1000}, Increment=5})

PlayerTab:CreateSection("👁️ Visual e Câmera")
SyncToggle("ESP", {Name="ESP Players (Ver Jogadores)"})
-- NOVO: Dropdown Tipo ESP
PlayerTab:CreateDropdown({Name="Tipo de ESP", Flag="ESPTipo", Options={"Sem Título","Assassino","Policial"}, CurrentOption=CONFIG.ESPTipo, Callback=function(opt) CONFIG.ESPTipo=opt; CONFIG._Flags.ESPTipo=opt; for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end; table.clear(ESP_Highlights) end})
SyncToggle("Fullbright", {Name="Fullbright (Brilho Máximo)"})
SyncToggle("NoFog", {Name="No Fog (Sem Neblina)"})
SyncSlider("FOV", {Name="FOV (Campo de Visão)", Range={50,120}, Increment=1})
SyncToggle("FreeCam", {Name="FreeCam (Câmera Livre)"}, ToggleFreeCam)

PlayerTab:CreateSection("👥 Jogadores e Teleporte")
local playerList={} for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(playerList,p.Name) end end
local dd=PlayerTab:CreateDropdown({Name="Selecionar Jogador", Flag="SelectedPlayer", Options=playerList, CurrentOption=playerList[1] or "Nenhum", Callback=function(o) CONFIG.SelectedPlayer=o end})
PlayerTab:CreateButton({Name="🔄 Atualizar Lista", Callback=function() local l={"Nenhum"} for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(l,p.Name) end end dd:Refresh(l,true) end})
PlayerTab:CreateButton({Name="Teleportar para Jogador", Callback=function() local t=Players:FindFirstChild(CONFIG.SelectedPlayer) if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then local r=getRoot() if r then r.CFrame=t.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,0) end end end})
PlayerTab:CreateButton({Name="Assistir Jogador (Spectate)", Callback=function() local t=Players:FindFirstChild(CONFIG.SelectedPlayer) if t and t.Character and t.Character:FindFirstChild("Humanoid") then camera.CameraSubject=t.Character.Humanoid; Rayfield:Notify({Title="Spectate", Content="Assistindo "..t.Name, Duration=3, Image="eye"}) end end})
SyncToggle("ClickTP", {Name="Click/Touch TP (Teleporte por Clique)"})

PlayerTab:CreateSection("⚙️ Utilidades e Servidor")
PlayerTab:CreateButton({Name="Organizar", Callback=function() CONFIG.Organize=not CONFIG.Organize; Rayfield:Notify({Title="Organizar", Content=CONFIG.Organize and "Ativado" or "Desativado", Duration=3, Image="info"}) end})
SyncToggle("AntiLag", {Name="Anti-Lag (Estabilizar FPS)"})
SyncToggle("AntiAFK", {Name="Anti-AFK (Clique Real)"})
PlayerTab:CreateButton({Name="Salvas Configurações", Callback=saveConfig})
PlayerTab:CreateButton({Name="Carregar Configurações", Callback=function() loadConfig(); applyConfig() end})
PlayerTab:CreateButton({Name="Resetar Configurações", Callback=function() CONFIG={WalkSpeed=16,JumpPower=50,Gravity=1,InfiniteJump=false,Noclip=false,Spin=false,SpinSpeed=10,Sit=false,Fly=false,FlySpeed=50,ESP=false,ESPTipo="Sem Título",Fullbright=false,NoFog=false,FOV=70,FreeCam=false,AntiAFK=false,AntiLag=false,SelectedPlayer="Nenhum",MaxSpeed=1000,Organize=false,ClickTP=false,VelocidadeGlobal=1000,AplicarVelocidade=false,LimiteVelocidade=1000,_Flags={}}; applyConfig(); ToggleFly(false); ToggleFreeCam(false); for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end; table.clear(ESP_Highlights); Rayfield:Notify({Title="Reset", Content="Padrão restaurado", Duration=3, Image="check-circle"}) end})
PlayerTab:CreateButton({Name="Resetar Velocidade", Callback=function() CONFIG.VelocidadeGlobal=1000; CONFIG.AplicarVelocidade=false; CONFIG.LimiteVelocidade=1000; CONFIG.WalkSpeed=16; CONFIG.FlySpeed=50; applyConfig(); Rayfield:Notify({Title="Reset", Content="Velocidades resetadas", Duration=3, Image="check-circle"}) end})
PlayerTab:CreateButton({Name="Resetar Personagem", Callback=function() local h=getHum() if h then h.Health=0 end end})
PlayerTab:CreateButton({Name="Rejoin (Entrar de Novo)", Callback=function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, player) end})
PlayerTab:CreateButton({Name="Server Hop (Trocar Servidor)", Callback=function() Rayfield:Notify({Title="Server Hop", Content="Procurando...", Duration=10, Image="loader"}) task.spawn(function() local ok,res=pcall(function() return HttpService:RequestAsync({Url="https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method="GET"}) end) if ok and res.Success then local data=HttpService:JSONDecode(res.Body) for _,s in pairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then TeleportService:TeleportToPlaceInstance(PlaceId,s.id,player); return end end Rayfield:Notify({Title="Server Hop", Content="Lotado/Erro", Duration=5, Image="alert-circle"}) else Rayfield:Notify({Title="Erro", Content="Falha API (Executor sem RequestAsync?)", Duration=5, Image="alert-circle"}) end end) end})

-- ============================================================
-- FINALIZAÇÃO
-- ============================================================
applyConfig()
Rayfield:LoadConfiguration() -- Carrega só Theme/Keybinds da UI
Rayfield:Notify({Title="✅ Script Carregado", Content="ESP 3 Modos | Config Manual | Seguro | PlaceId: "..PlaceId, Duration=6, Image="check-circle"})

getgenv()._UniversalScriptCleanup = function() for _,c in pairs(Watchdog.Connections) do pcall(function() c:Disconnect() end) end; if FlyConn then FlyConn:Disconnect() end; if FreeCamConn then FreeCamConn:Disconnect() end; for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end; if OldKick then hookfunction(player.Kick, OldKick) end; print("[Cleanup] OK") end
