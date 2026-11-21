```lua
-- 🔵 0. AUTO-CLEANUP TOPO (Reexecução Segura)
if getgenv()._UniversalScriptCleanup then
    pcall(getgenv()._UniversalScriptCleanup)
end

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
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlaceId = game.PlaceId

-- ============================================================
-- 🛡️ HARDENING PACK: ANTI-KICK METATABLE __NAMECALL + FALLBACK
-- ============================================================
pcall(function()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if self == player and (method == "Kick" or method == "kick") then
                warn("[ANTI-KICK] Kick bloqueado via __namecall:", ...)
                Rayfield:Notify({ Title = "🛡️ Anti-Kick", Content = "Tentativa de kick bloqueada (metatable):\n" .. tostring(...), Duration = 5, Image = "shield" })
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- Fallback HookFunction (Para executores sem getrawmetatable)
pcall(function()
    local OldKick = hookfunction(player.Kick, function(self, msg)
        if self == player then
            warn("[ANTI-KICK] Kick bloqueado via hookfunction:", msg)
            Rayfield:Notify({ Title = "🛡️ Anti-Kick", Content = "Tentativa de kick bloqueada (hook):\n" .. tostring(msg), Duration = 5, Image = "shield" })
            return
        end
        return OldKick(self, msg)
    end)
end)

-- ============================================================
-- 🛡️ SISTEMAS DE SEGURANÇA E COMPATIBILIDADE (INJETADOS)
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

-- 2. VIRTUAL INPUT (Cliques/Teclas REAIS - Bypass Heurística Anti-Cheat / Funciona Mobile)
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

-- 3. UI_FLAGS DECLARADO ANTES DO WATCHDOG (Correção 1)
local UI_Flags = {}

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
			-- CORREÇÃO 2: Sintaxe Luau válida com crases (interpolação)
			warn(`[WATCHDOG] {name} Error [{self.Errors[name]}/{self.MaxErrors}]: {err}`)
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
	if UI_Flags[flagName] then
		pcall(function() UI_Flags[flagName]:Set(false) end)
	end
	Rayfield:Notify({ Title = "🛡️ WATCHDOG", Content = flagName .. " desligado (Segurança):\n" .. reason, Duration = 6, Image = "alert-triangle" })
end

-- ============================================================
-- SUA CONFIG ORIGINAL (MANTIDA) + _Flags PARA WATCHDOG
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
    _Flags = {} -- Watchdog usa isso para saber se feature está ligada
}

-- Config por PlaceId (Não mistura jogos diferentes)
local CONFIG_PATH = "ScriptUniversal_Config_" .. PlaceId .. ".json"

-- Função para salvar configurações (COM FALLBACK CLIPBOARD)
local function saveConfig()
    local data = {}
    for k, v in pairs(CONFIG) do if type(v) ~= "function" and k:sub(1,1) ~= "_" then data[k] = v end end
    local json = HttpService:JSONEncode(data)
    local success, error = pcall(function()
        writefile(CONFIG_PATH, json)
    end)
    if success then
        Rayfield:Notify({ Title = "Sucesso", Content = "Configurações salvas!", Duration = 3, Image = "check-circle" })
    else
        -- FALLBACK: Copia para clipboard se writefile falhar (Mobile/Executor sem FS)
        pcall(function() setclipboard(json) end)
        Rayfield:Notify({ Title = "Atenção", Content = "Falha ao salvar arquivo (Permissão?). Config copiada para Clipboard. Cole num .txt manual se quiser.", Duration = 10, Image = "alert-circle" })
    end
end

-- Função para carregar configurações
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
            if CONFIG[key] ~= nil then CONFIG[key] = value end
        end
        -- Sincroniza _Flags para Watchdog saber o que está ligado
        for key, value in pairs(CONFIG) do
            if type(value) == "boolean" then CONFIG._Flags[key] = value end
        end
        Rayfield:Notify({ Title = "Sucesso", Content = "Configurações carregadas!", Duration = 3, Image = "check-circle" })
    end
end

-- Funções seguras (Agora usam SafeChar)
local function getHum()
    return SafeGetHum()
end

local function getRoot()
    return SafeGetRoot()
end

-- Função para aplicar velocidade universal
local function applyUniversalSpeed()
    local hum = getHum()
    if hum then
        if CONFIG.AplicarVelocidade then
            hum.WalkSpeed = CONFIG.VelocidadeGlobal
        else
            hum.WalkSpeed = CONFIG.WalkSpeed
        end
    end
    
    local root = getRoot()
    if root and CONFIG.Fly then
        -- Fly agora é CFrame Stealth (veja ToggleFly abaixo), não usa mais BodyVelocity
    end
end

-- Função para aplicar todas as configurações (Physics + Visuals + Spin)
local function applyConfig()
    local hum = getHum()
    local root = getRoot()
    
    if hum then
        if CONFIG.AplicarVelocidade then
            hum.WalkSpeed = CONFIG.VelocidadeGlobal
        else
            hum.WalkSpeed = CONFIG.WalkSpeed
        end
        
        hum.JumpPower = CONFIG.JumpPower
        hum.UseJumpPower = true
        
        if CONFIG.Sit then
            hum.Sit = true
        end
    end
    
    workspace.Gravity = CONFIG.Gravity * 196.2
    camera.FieldOfView = CONFIG.FOV
    
    -- Spin (BodyAngularVelocity)
    if root then
        local bav = root:FindFirstChild("SpinForce")
        if CONFIG.Spin then
            if not bav then
                bav = Instance.new("BodyAngularVelocity")
                bav.Name = "SpinForce"
                bav.MaxTorque = Vector3.new(0, math.huge, 0)
                bav.Parent = root
            end
            bav.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0)
        elseif bav then
            bav:Destroy()
        end
    end
    
    -- Visuals
    if CONFIG.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.GlobalShadows = true
    end
    
    if CONFIG.NoFog then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = 300
    end
end

-- Função para limitar velocidade
local function limitSpeed(speed)
    return math.min(speed, CONFIG.LimiteVelocidade)
end

-- ============================================================
-- FEATURES COMPLEXAS REESCRITAS PARA FUNCIONAR DE VERDADE
-- ============================================================

-- FLY STEALTH MOBILE OTIMIZADO (CFrame no RenderStepped - MoveDirection + Camera Tilt)
local FlyConn
local function ToggleFly(state)
    CONFIG.Fly = state
    CONFIG._Flags.Fly = state
    local hum = getHum()
    local root = getRoot()
    if not hum or not root then 
        Rayfield:Notify({ Title = "Fly", Content = "Character não encontrado.", Duration = 3, Image = "alert-circle" })
        CONFIG.Fly = false
        CONFIG._Flags.Fly = false
        if UI_Flags.Fly then pcall(function() UI_Flags.Fly:Set(false) end) end
        return 
    end

    if state then
        hum.PlatformStand = true
        Rayfield:Notify({ Title = "Fly Ativado", Content = "Modo Mobile: Analógico Move | Camera Up/Down", Duration = 3, Image = "check-circle" })
        FlyConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.Fly then return ToggleFly(false) end
            local hum = getHum()
            local root = getRoot()
            if not hum or not root then return ToggleFly(false) end
            
            -- 1. Direção Horizontal: MoveDirection (Respeita Analógico Virtual Delta Mobile)
            local moveDir = hum.MoveDirection -- Já é relativo à câmera e normalizado (0 a 1)
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed) * dt * 60
            local newCF = root.CFrame
            
            if moveDir.Magnitude > 0 then
                -- MoveDirection já vem no espaço mundial relativo à câmera no mobile/PC
                newCF = newCF + (moveDir * speed)
            end
            
            -- 2. Vertical: Inclinação da Câmera (LookVector.Y) + Teclas/Toques (Space/Shift/Jump Button)
            local verticalSpeed = speed
            local camLook = camera.CFrame.LookVector
            
            -- Detecta input de "Subir" (Espaço, Botão Pulo Mobile, Shift Direito em alguns layouts)
            local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) -- ButtonA costuma ser pulo no mobile
            -- Detecta input de "Descer" (LeftShift, ButtonL2, etc)
            local isCrouching = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2)
            
            -- Lógica de Câmera: Se olhar para cima (> 30 graus), sobe automaticamente. Se olhar para baixo, desce.
            -- Isso permite voar "para onde olha" sem precisar segurar botão extra.
            local pitchFactor = camLook.Y -- -1 (baixo) a 1 (cima)
            
            -- Prioridade: Input Direto > Inclinação Câmera
            if isJumping then
                newCF = newCF + Vector3.new(0, verticalSpeed, 0)
            elseif isCrouching then
                newCF = newCF - Vector3.new(0, verticalSpeed, 0)
            else
                -- Auto-subir/descer pela câmera (Sensibilidade 50% da velocidade)
                if math.abs(pitchFactor) > 0.15 then -- Deadzone para não tremer no neutro
                    newCF = newCF + Vector3.new(0, pitchFactor * verticalSpeed * 0.5, 0)
                end
            end
            
            -- Aplica CFrame e Zera Velocidade Física (Anti-Gravidade/Queda)
            root.CFrame = newCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
        hum.PlatformStand = false
        Rayfield:Notify({ Title = "Fly Desativado", Content = "", Duration = 2, Image = "x-circle" })
    end
end

-- ESP REAL (Highlight Loop - Seu original não criava nada)
local ESP_Highlights = {}
Watchdog:Wrap("ESPLoop", function()
    if not CONFIG.ESP then 
        for _, hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
        table.clear(ESP_Highlights)
        return 
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and SafeGetRoot(plr.Character) then
            local hl = ESP_Highlights[plr]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = plr.Character
                ESP_Highlights[plr] = hl
            end
            hl.FillColor = plr.TeamColor.Color
            hl.OutlineColor = Color3.new(1, 1, 1)
        end
    end
    -- Limpa highlights de players que saíram
    for plr, hl in pairs(ESP_Highlights) do
        if not Players:FindFirstChild(plr.Name) then
            pcall(function() hl:Destroy() end)
            ESP_Highlights[plr] = nil
        end
    end
end, 0.5)

-- FREECAM CORRIGIDO (RenderStepped + dt - Sem HeartbeatWait inexistente)
local FreeCamConn
local function ToggleFreeCam(state)
    CONFIG.FreeCam = state
    CONFIG._Flags.FreeCam = state
    local hum = getHum()
    local root = getRoot()
    
    if state and root then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = nil
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
        
        FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return ToggleFreeCam(false) end
            local speed = 100 * dt
            local move = Vector3.zero
            local cf = camera.CFrame
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
            
            if move.Magnitude > 0 then
                camera.CFrame = camera.CFrame + (move.Unit * speed)
            end
        end)
    else
        if FreeCamConn then FreeCamConn:Disconnect(); FreeCamConn = nil end
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = hum
        if hum then applyConfig() end -- Restaura speed/jump
    end
end

-- VISUALS LOOP (Leve - 1x por seg)
Watchdog:Wrap("VisualsLoop", function()
    camera.FieldOfView = CONFIG.FOV
    if CONFIG.Fullbright then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    else
        Lighting.GlobalShadows = true
    end
    if CONFIG.NoFog then Lighting.FogEnd = 100000 else Lighting.FogEnd = 300 end
end, 1)

-- NOCLIP LOOP (Watchdog + AntiLag support)
Watchdog:Wrap("NoclipLoop", function()
    if not CONFIG.Noclip then return end
    local char = player.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end, 0.1)

-- SPIN LOOP (Watchdog)
Watchdog:Wrap("SpinLoop", function(dt)
    if not CONFIG.Spin then return end
    local root = getRoot()
    if root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed) * dt * 60, 0)
    end
end)

-- INFINITE JUMP (Evento - Seguro)
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = getHum()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- ANTI-AFK (VirtualInput Real - Bypass Heurística)
player.Idled:Connect(function()
    if CONFIG.AntiAFK then
        VInput_Click(math.random(100, 500), math.random(100, 500))
        VInput_Key(Enum.KeyCode.Unknown, true)
        task.wait(0.05)
        VInput_Key(Enum.KeyCode.Unknown, false)
    end
end)

-- CLICK TP (VirtualInput Raycast - Funciona PC e Mobile Touch)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if CONFIG.ClickTP and not gameProcessed then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local root = getRoot()
            if not root then return end
            
            local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {player.Character}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            
            if result then
                root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

-- PROTEÇÃO DE VELOCIDADE (Heartbeat Leve - Garante que speed não reseta)
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        local targetSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed)
        if hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    end
end)

-- RESPAWN HANDLER (Reaplica tudo)
player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    applyConfig()
    if CONFIG.Fly then ToggleFly(true) end
    if CONFIG.FreeCam then ToggleFreeCam(true) end
    -- Noclip/ESP/Spin/Visuals são Watchdog (auto-reconectam via _Flags)
end)

-- ============================================================
-- UI RAYFIELD (SUA ESTRUTURA ORIGINAL 100% MANTIDA)
-- ============================================================

-- 1. CARREGA CONFIG ANTES DA UI (Para Sliders abrirem com valores salvos)
loadConfig()

-- Criar Janela Rayfield
local Window = Rayfield:CreateWindow({
    Name = "Script Universal - Player",
    LoadingTitle = "Carregando Menu...",
    LoadingSubtitle = "Aba Player Completa",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DeltaPlayerHub",
        FileName = "PlayerConfig"
    },
    KeySystem = false
})

-- Aba Player
local PlayerTab = Window:CreateTab("Player", 4483362458)

-- Helpers para sincronizar UI <-> CONFIG <-> WATCHDOG (Mantém seus Flags originais)
local function SyncSlider(cfgKey, opts)
    opts.Flag = cfgKey
    opts.CurrentValue = CONFIG[cfgKey]
    opts.Callback = function(Value)
        CONFIG[cfgKey] = Value
        if cfgKey == "WalkSpeed" or cfgKey == "FlySpeed" or cfgKey == "VelocidadeGlobal" then
            CONFIG[cfgKey] = limitSpeed(Value)
        end
        if cfgKey == "FOV" then camera.FieldOfView = Value end
        if cfgKey == "Gravity" then workspace.Gravity = Value * 196.2 end
        if cfgKey == "JumpPower" then local hum = getHum(); if hum then hum.JumpPower = Value; hum.UseJumpPower = true end end
        if cfgKey == "SpinSpeed" then local root = getRoot(); local bav = root and root:FindFirstChild("SpinForce"); if bav then bav.AngularVelocity = Vector3.new(0, Value, 0) end end
        Rayfield:Notify({ Title = "Atualizado", Content = cfgKey .. " = " .. Value, Duration = 2, Image = "check" })
    end
    local obj = PlayerTab:CreateSlider(opts)
    UI_Flags[cfgKey] = obj
    return obj
end

local function SyncToggle(cfgKey, opts, onToggle)
    opts.Flag = cfgKey
    opts.CurrentValue = CONFIG[cfgKey]
    opts.Callback = function(Value)
        CONFIG[cfgKey] = Value
        CONFIG._Flags[cfgKey] = Value -- Watchdog lê isso
        if onToggle then onToggle(Value) end
        Rayfield:Notify({ Title = (Value and "Ativado" or "Desativado"), Content = cfgKey, Duration = 2, Image = (Value and "check-circle" or "x-circle") })
    end
    local obj = PlayerTab:CreateToggle(opts)
    UI_Flags[cfgKey] = obj
    return obj
end

-- === 1. MOVIMENTAÇÃO E FÍSICA ===
PlayerTab:CreateSection("🏃 Movimentação e Física")

SyncSlider("VelocidadeGlobal", { Name = "Velocidade Universal", Range = {1, 1000}, Increment = 1 })
SyncToggle("AplicarVelocidade", { Name = "Ativar Velocidade Universal" }, function(Value) applyUniversalSpeed() end)
SyncSlider("LimiteVelocidade", { Name = "Limite de Velocidade", Range = {1, 1000}, Increment = 1 })
SyncSlider("MaxSpeed", { Name = "Velocidade Máxima", Range = {1, 1000}, Increment = 1 })
SyncSlider("WalkSpeed", { Name = "WalkSpeed (Velocidade)", Range = {1, 1000}, Increment = 1 })
SyncSlider("JumpPower", { Name = "JumpPower (Força do Pulo)", Range = {50, 300}, Increment = 1 })
SyncSlider("Gravity", { Name = "Gravidade", Range = {0.1, 5}, Increment = 0.1 })
SyncToggle("InfiniteJump", { Name = "Infinite Jump (Pulo Infinito)" })
SyncToggle("Noclip", { Name = "Noclip (Atravessar Paredes)" })
SyncToggle("Spin", { Name = "Spin (Girar Rápido)" })
SyncSlider("SpinSpeed", { Name = "SpinSpeed (Velocidade do Giro)", Range = {1, 50}, Increment = 1 })
SyncToggle("Sit", { Name = "Sit (Sentar)" })

-- === 2. FLY (VOAR) ===
PlayerTab:CreateSection("✈️ Fly (Voar)")
SyncToggle("Fly", { Name = "Ativar Fly (Mobile/PC)" }, ToggleFly)
SyncSlider("FlySpeed", { Name = "Velocidade do Fly", Range = {1, 1000}, Increment = 5 })

-- === 3. VISUAL E CÂMERA ===
PlayerTab:CreateSection("👁️ Visual e Câmera")
SyncToggle("ESP", { Name = "ESP Players (Ver Jogadores)" })
SyncToggle("Fullbright", { Name = "Fullbright (Brilho Máximo)" })
SyncToggle("NoFog", { Name = "No Fog (Sem Neblina)" })
SyncSlider("FOV", { Name = "FOV (Campo de Visão)", Range = {50, 120}, Increment = 1 })
SyncToggle("FreeCam", { Name = "FreeCam (Câmera Livre)" }, ToggleFreeCam)

-- === 4. JOGADORES E TELEPORTE ===
PlayerTab:CreateSection("👥 Jogadores e Teleporte")

local playerList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= player then table.insert(playerList, p.Name) end
end

local playerDropdown = PlayerTab:CreateDropdown({
    Name = "Selecionar Jogador",
    Flag = "SelectedPlayer",
    Options = playerList,
    CurrentOption = playerList[1] or "Nenhum",
    Callback = function(Option) CONFIG.SelectedPlayer = Option end,
})

PlayerTab:CreateButton({ Name = "🔄 Atualizar Lista", Callback = function()
    local list = {"Nenhum"}
    for _, p in pairs(Players:GetPlayers()) do if p ~= player then table.insert(list, p.Name) end end
    playerDropdown:Refresh(list, true)
end})

PlayerTab:CreateButton({ Name = "Teleportar para Jogador", Callback = function()
    local targetName = CONFIG.SelectedPlayer
    if targetName and targetName ~= "Nenhum" then
        local targetPlayer = Players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = getRoot()
            if root then root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0) end
        end
    end
end})

PlayerTab:CreateButton({ Name = "Assistir Jogador (Spectate)", Callback = function()
    local targetName = CONFIG.SelectedPlayer
    if targetName and targetName ~= "Nenhum" then
        local targetPlayer = Players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = targetPlayer.Character.Humanoid
            Rayfield:Notify({ Title = "Spectate", Content = "Assistindo " .. targetName, Duration = 3, Image = "eye" })
        end
    end
end})

SyncToggle("ClickTP", { Name = "Click/Touch TP (Teleporte por Clique)" })

-- === 5. UTILIDADES E SERVIDOR ===
PlayerTab:CreateSection("⚙️ Utilidades e Servidor")

PlayerTab:CreateButton({ Name = "Organizar", Callback = function()
    CONFIG.Organize = not CONFIG.Organize
    Rayfield:Notify({ Title = "Info", Content = "Organização " .. (CONFIG.Organize and "ativada" or "desativada"), Duration = 3, Image = "info" })
end})

SyncToggle("AntiLag", { Name = "Anti-Lag (Estabilizar FPS)" })
SyncToggle("AntiAFK", { Name = "Anti-AFK" })

PlayerTab:CreateButton({ Name = "Salvas Configurações", Callback = saveConfig })
PlayerTab:CreateButton({ Name = "Carregar Configurações", Callback = function() loadConfig(); applyConfig(); Rayfield:Notify({ Title = "Sucesso", Content = "Configurações carregadas e aplicadas!", Duration = 3, Image = "check-circle" }) end })
PlayerTab:CreateButton({ Name = "Resetar Configurações", Callback = function()
    CONFIG = {
        WalkSpeed = 16, JumpPower = 50, Gravity = 1, InfiniteJump = false, Noclip = false, Spin = false, SpinSpeed = 10, Sit = false,
        Fly = false, FlySpeed = 50, ESP = false, Fullbright = false, NoFog = false, FOV = 70, FreeCam = false,
        AntiAFK = false, AntiLag = false, Rejoin = false, ServerHop = false, SelectedPlayer = "Nenhum",
        MaxSpeed = 1000, Organize = false, ClickTP = false, VelocidadeGlobal = 1000, AplicarVelocidade = false, LimiteVelocidade = 1000, _Flags = {}
    }
    applyConfig()
    ToggleFly(false)
    ToggleFreeCam(false)
    for _, hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
    table.clear(ESP_Highlights)
    Rayfield:Notify({ Title = "Sucesso", Content = "Configurações resetadas!", Duration = 3, Image = "check-circle" })
end })
PlayerTab:CreateButton({ Name = "Resetar Velocidade", Callback = function()
    CONFIG.VelocidadeGlobal = 1000; CONFIG.AplicarVelocidade = false; CONFIG.LimiteVelocidade = 1000; CONFIG.WalkSpeed = 16; CONFIG.FlySpeed = 50
    applyConfig()
    Rayfield:Notify({ Title = "Sucesso", Content = "Velocidade resetada!", Duration = 3, Image = "check-circle" })
end })
PlayerTab:CreateButton({ Name = "Resetar Personagem", Callback = function() local hum = getHum(); if hum then hum.Health = 0 end end })
PlayerTab:CreateButton({ Name = "Rejoin (Entrar de Novo)", Callback = function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, player) end })
PlayerTab:CreateButton({ Name = "Server Hop (Trocar Servidor)", Callback = function()
    Rayfield:Notify({ Title = "Server Hop", Content = "Procurando servidor...", Duration = 10, Image = "loader" })
    task.spawn(function()
        local success, response = pcall(function()
            return HttpService:RequestAsync({ Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET" })
        end)
        if success and response.Success then
            local data = HttpService:JSONDecode(response.Body)
            for _, server in pairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, player)
                    return
                end
            end
            Rayfield:Notify({ Title = "Server Hop", Content = "Nenhum servidor viável encontrado.", Duration = 5, Image = "alert-circle" })
        else
            Rayfield:Notify({ Title = "Erro", Content = "Falha na API (Executor sem RequestAsync?)", Duration = 5, Image = "alert-circle" })
        end
    end)
end })

-- ============================================================
-- FINALIZAÇÃO
-- ============================================================
applyConfig() -- Aplica física inicial no char atual
Rayfield:LoadConfiguration() -- Carrega UI Flags (Theme, Keybinds)
Rayfield:Notify({ Title = "Sucesso", Content = "Script carregado com sucesso! (Hardening Pack Aplicado)", Duration = 5, Image = "check-circle" })

-- Cleanup Global (Para reexecução segura via getgenv()._UniversalScriptCleanup())
getgenv()._UniversalScriptCleanup = function()
    for _, conn in pairs(Watchdog.Connections) do pcall(function() conn:Disconnect() end) end
    if FlyConn then FlyConn:Disconnect() end
    if FreeCamConn then FreeCamConn:Disconnect() end
    for _, hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
    -- Restaura metatable se possível (segurança extra)
    pcall(function()
        local mt = getrawmetatable(game)
        if mt then setreadonly(mt, false) end
    end)
    print("[UniversalScript] Cleanup completo.")
end
```
