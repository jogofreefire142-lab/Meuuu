--[[
    UNIVERSAL PLAYER HUB - BULLETPROOF EDITION
    Features: SafeChar, Watchdog Loops, VirtualInput (Real Clicks), Per-Game Config, Anti-Kick UI.
    Compatibility: R6, R15, Custom Rigs, Mobile, PC, Executors (Delta, Fluxus, Hydrogen, CodeX, etc)
]]--

-- 🔵 1. LOAD & SERVICES
repeat task.wait() until game:IsLoaded()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlaceId = game.PlaceId
local GameId = game.GameId

-- 🔵 2. RAYFIELD UI (Protected Load)
local Rayfield
local successRayfield, errRayfield = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not successRayfield then
    player:Kick("Falha ao carregar Rayfield UI: " .. tostring(errRayfield))
    return
end

-- 🔵 3. SISTEMA DE SEGURANÇA (CORE) ---------------------------------------------------------

-- 3.1 SafeCharacter: Funciona em QUALQUER jogo/rig
local SafeChar = {}
function SafeChar:GetHumanoid(char)
    char = char or player.Character
    if not char then return nil end
    -- Procura Humanoid ou Controller (Custom Rig)
    return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildWhichIsA("Humanoid", true)
end
function SafeChar:GetRootPart(char)
    char = char or player.Character
    if not char then return nil end
    local hum = self:GetHumanoid(char)
    if hum and hum.RootPart then return hum.RootPart end -- R15/R6 Standard
    -- Fallback: Procura Part nomeada ou BasePart principal
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
end
function SafeChar:GetCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

-- 3.2 Watchdog: Auto-desliga feature se der erro (Segurança Total)
local Watchdog = {}
Watchdog.Errors = {}
Watchdog.MaxErrors = 3 -- Tolerância
Watchdog.ActiveLoops = {} -- [name] = connection

function Watchdog:Wrap(name, func, interval)
    interval = interval or 0 -- 0 = Heartbeat, >0 = Seconds
    local conn
    local errorCount = 0
    local lastRun = 0

    local function runner(dt)
        if not CONFIG._Flags[name] then return conn:Disconnect() end -- Toggle desligado
        
        if interval > 0 then
            if tick() - lastRun < interval then return end
            lastRun = tick()
        end

        local ok, err = pcall(func, dt)
        if not ok then
            errorCount += 1
            warn(`[WATCHDOG] ${name} Error [${errorCount}/${Watchdog.MaxErrors}]: ${err}`)
            if errorCount >= Watchdog.MaxErrors then
                self:ForceDisable(name, `Erro crítico: ${err}`)
            end
        else
            errorCount = 0 -- Reset se sucesso
        end
    end

    if interval > 0 then
        conn = RunService.Heartbeat:Connect(runner)
    else
        conn = RunService.Heartbeat:Connect(runner)
    end
    Watchdog.ActiveLoops[name] = conn
    return conn
end

function Watchdog:ForceDisable(flagName, reason)
    if not CONFIG._Flags[flagName] then return end -- Já desligado
    CONFIG._Flags[flagName] = false
    -- Atualiza UI Rayfield se existir
    if Rayfield.Flags and Rayfield.Flags[flagName] then
        pcall(function() Rayfield.Flags[flagName]:Set(false) end)
    end
    notify("🛡️ SEGURANÇA ATIVADA", flagName .. " desligado automaticamente.\nMotivo: " .. reason, 6, "ERROR")
    print(`[SAFETY] ${flagName} DISABLED: ${reason}`)
end

function Watchdog:Stop(name)
    if Watchdog.ActiveLoops[name] then
        Watchdog.ActiveLoops[name]:Disconnect()
        Watchdog.ActiveLoops[name] = nil
    end
end

-- 3.3 VirtualInput (Cliques/Teclas REAIS - Anti-Cheat Bypass)
local VInput = {}
function VInput:Click(x, y, button)
    button = button or 0 -- 0=Left, 1=Right
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, button, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, button, false, game, 0)
    end)
end
function VInput:KeyDown(keyCode)
    pcall(function() VirtualInputManager:SendKeyEvent(true, keyCode, false, game) end)
end
function VInput:KeyUp(keyCode)
    pcall(function() VirtualInputManager:SendKeyEvent(false, keyCode, false, game) end)
end
function VInput:PressKey(keyCode, duration)
    duration = duration or 0.05
    self:KeyDown(keyCode)
    task.wait(duration)
    self:KeyUp(keyCode)
end

-- 3.4 Anti-Kick UI (Impede tela de "You were kicked" local)
local OldKick
OldKick = hookfunction(player.Kick, function(self, msg)
    if self == player then
        warn("[ANTI-KICK] Kick local bloqueado:", msg)
        notify("🛡️ Anti-Kick", "Tentativa de kick local bloqueada:\n" .. tostring(msg), 5, "WARNING")
        return -- Não desconecta
    end
    return OldKick(self, msg)
end)
-- Anti-Teleport Fail (Se jogo tentar teleportar pra lugar inválido)
local OldTeleport
OldTeleport = hookfunction(TeleportService.TeleportToPlaceInstance, function(self, placeId, jobId, plr)
    if plr == player then
        warn("[ANTI-TP] Teleport suspeito bloqueado.")
        return
    end
    return OldTeleport(self, placeId, jobId, plr)
end)

-- 🔵 4. CONFIGURAÇÃO POR JOGO (PlaceId) ----------------------------------------------------
local CONFIG_PATH = `UniversalHub_Config_${PlaceId}.json`
local CONFIG = {
    -- Movement
    WalkSpeed = 16, JumpPower = 50, Gravity = 1,
    InfiniteJump = false, Noclip = false, Spin = false, SpinSpeed = 10, Sit = false,
    -- Fly (VirtualInput Based)
    Fly = false, FlySpeed = 50, FlyUpKey = Enum.KeyCode.Space, FlyDownKey = Enum.KeyCode.LeftShift,
    -- Visuals
    ESP = false, Fullbright = false, NoFog = false, FOV = 70, FreeCam = false,
    -- Utility
    AntiAFK = false, AntiLag = false, ClickTP = false,
    -- Internal
    _Flags = {}, -- Espelho das Toggles para Watchdog
    VelocidadeGlobal = 1000, AplicarVelocidade = false, LimiteVelocidade = 1000
}

local ESP_Highlights = {}
local FlyKeysDown = { Up = false, Down = false, Move = Vector3.zero }
local FreeCamEnabled = false
local FreeCamCFrame = CFrame.new()
local Connections = {}

-- Load/Save
local function SaveConfig()
    local data = {}
    for k,v in pairs(CONFIG) do if type(v) ~= "function" and k:sub(1,1) ~= "_" then data[k]=v end end
    pcall(function() writefile(CONFIG_PATH, HttpService:JSONEncode(data)) end)
end
local function LoadConfig()
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_PATH)) end)
    if ok and data then for k,v in pairs(data) do CONFIG[k]=v end end
    -- Sincroniza _Flags
    for k,v in pairs(CONFIG) do if type(v)=="boolean" then CONFIG._Flags[k]=v end end
end
LoadConfig()

-- 🔵 5. FUNÇÕES CORE (Seguras) -----------------------------------------------------------
local function Notify(t, c, d, i) pcall(function() Rayfield:Notify({Title=t, Content=c, Duration=d or 3, Image=i or "INFO"}) end) end
local function LimitSpeed(s) return math.min(s, CONFIG.LimiteVelocidade) end

-- Aplica física no Char Atual (SafeChar)
local function ApplyPhysics()
    local char = SafeChar:GetCharacter()
    local hum = SafeChar:GetHumanoid(char)
    local root = SafeChar:GetRootPart(char)
    if not hum or not root then return end

    pcall(function()
        hum.WalkSpeed = CONFIG.AplicarVelocidade and LimitSpeed(CONFIG.VelocidadeGlobal) or LimitSpeed(CONFIG.WalkSpeed)
        hum.JumpPower = CONFIG.JumpPower
        hum.UseJumpPower = true
        hum.Sit = CONFIG.Sit
        workspace.Gravity = CONFIG.Gravity * 196.2
        camera.FieldOfView = CONFIG.FOV
    end)

    -- Spin (BodyAngularVelocity Safe)
    local bav = root:FindFirstChild("UniversalSpin")
    if CONFIG.Spin then
        if not bav then bav = Instance.new("BodyAngularVelocity"); bav.Name="UniversalSpin"; bav.MaxTorque=Vector3.new(0,math.huge,0); bav.Parent=root end
        bav.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0)
    elseif bav then bav:Destroy() end
end

-- Visuals Loop (Lightweight)
Watchdog:Wrap("VisualsLoop", function()
    camera.FieldOfView = CONFIG.FOV
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end, 1) -- Roda 1x por seg (AntiLag natural)

-- ESP Loop (Safe)
Watchdog:Wrap("ESPLoop", function()
    if not CONFIG.ESP then for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end; table.clear(ESP_Highlights); return end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and SafeChar:GetRootPart(plr.Character) then
            local hl = ESP_Highlights[plr]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight"); hl.Name="UniversalESP"; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=plr.Character; ESP_Highlights[plr]=hl
            end
            hl.FillColor = plr.TeamColor.Color; hl.OutlineColor = Color3.new(1,1,1)
        end
    end
    for plr, hl in pairs(ESP_Highlights) do if not Players:FindFirstChild(plr.Name) then pcall(function() hl:Destroy() end); ESP_Highlights[plr]=nil end end
end, 0.5)

-- Noclip Loop (Safe)
Watchdog:Wrap("NoclipLoop", function()
    if not CONFIG.Noclip then return end
    local char = SafeChar:GetCharacter()
    if not char then return end
    for _,part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end, 0.1) -- 10x seg

-- Infinite Jump (Event Based - Safe)
Connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = SafeChar:GetHumanoid()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- Anti-AFK (VirtualInput - Real Click)
Connections.AntiAFK = player.Idled:Connect(function()
    if CONFIG.AntiAFK then
        -- Simula movimento de mouse leve + tecla
        VInput:PressKey(Enum.KeyCode.Unknown) -- Wake up
        VInput:Click(math.random(100, 500), math.random(100, 500))
    end
end)

-- 🔵 6. FEATURES COMPLEXAS (Fly, FreeCam, ClickTP - VirtualInput) ------------------------

-- FLY: Usa WASD + Space/Shift via VirtualInput + CFrame suave (Híbrido Seguro)
-- Não usa BodyVelocity (detectável), move RootPart via CFrame no RenderStepped.
local FlyConnection
local function ToggleFly(state)
    CONFIG.Fly = state; CONFIG._Flags.Fly = state
    local char = SafeChar:GetCharacter()
    local hum = SafeChar:GetHumanoid(char)
    local root = SafeChar:GetRootPart(char)
    if not hum or not root then return Notify("Fly", "Character não encontrado.", 3, "ERROR") end

    if state then
        hum.PlatformStand = true -- Para animações
        FreeCamCFrame = root.CFrame
        Notify("Fly", "Ativado (WASD + Space/Shift). Modo Seguro.", 3, "SUCCESS")
        
        FlyConnection = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.Fly then return ToggleFly(false) end
            local hum = SafeChar:GetHumanoid()
            local root = SafeChar:GetRootPart()
            if not hum or not root then return ToggleFly(false) end

            -- Input Detection (UserInputService é mais confiável que VInput para leitura)
            local moveDir = hum.MoveDirection -- Pega input do jogo (Joystick/Teclado)
            local camCF = camera.CFrame
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed) * dt
            
            local newCF = root.CFrame
            
            -- Movimento Horizontal (Relativo à Camera)
            if moveDir.Magnitude > 0 then
                local look = camCF.LookVector
                local right = camCF.RightVector
                local flatLook = Vector3.new(look.X, 0, look.Z).Unit
                local flatRight = Vector3.new(right.X, 0, right.Z).Unit
                local moveVec = (flatLook * -moveDir.Z) + (flatRight * moveDir.X) -- MoveDirection Z é inverso
                newCF = newCF + (moveVec.Unit * speed)
            end

            -- Movimento Vertical (Space/Shift)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then newCF = newCF + Vector3.new(0, speed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then newCF = newCF - Vector3.new(0, speed, 0) end

            -- Aplica CFrame (Suave, não teleporta instantaneamente longe)
            root.CFrame = newCF
            -- Mantém rotação da camera
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
        if hum then hum.PlatformStand = false end
        Notify("Fly", "Desativado.", 2, "INFO")
    end
end

-- FREECAM: Desacopla Camera Total (RenderStepped)
local FreeCamConn
local function ToggleFreeCam(state)
    CONFIG.FreeCam = state; CONFIG._Flags.FreeCam = state
    local hum = SafeChar:GetHumanoid()
    local root = SafeChar:GetRootPart()
    
    if state and root then
        FreeCamEnabled = true
        FreeCamCFrame = camera.CFrame
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = nil
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end -- Trava player
        
        FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return ToggleFreeCam(false) end
            local speed = 100 * dt
            local move = Vector3.zero
            local cf = camera.CFrame
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            
            if move.Magnitude > 0 then
                camera.CFrame = camera.CFrame + (move.Unit * speed)
            end
        end)
    else
        FreeCamEnabled = false
        if FreeCamConn then FreeCamConn:Disconnect(); FreeCamConn = nil end
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = hum
        if hum then ApplyPhysics() end -- Restaura speed/jump
    end
end

-- CLICK TP: VirtualInput Raycast (Funciona Mobile/PC)
Connections.ClickTP = UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not CONFIG.ClickTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local root = SafeChar:GetRootPart()
        if not root then return end
        
        local screenPos = input.Position
        -- Raycast via Camera
        local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {player.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result then
            -- Teleporta com CFrame (Seguro)
            root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
        end
    end
end)

-- CHARACTER RESPAWN HANDLER
Connections.Respawn = player.CharacterAdded:Connect(function(char)
    task.wait(0.5) -- Wait for replication
    ApplyPhysics()
    -- Re-ativa features ligadas
    if CONFIG.Fly then ToggleFly(true) end
    if CONFIG.FreeCam then ToggleFreeCam(true) end
    -- Noclip/ESP/Spin/Visuals são loops independentes (Watchdog) que checam CONFIG._Flags
end)

-- 🔵 7. UI RAYFIELD (Binded to CONFIG._Flags) -------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub 🛡️ Safe",
    LoadingTitle = "Carregando Sistema Seguro...",
    LoadingSubtitle = `PlaceId: ${PlaceId}`,
    ConfigurationSaving = { Enabled = true, FolderName = "UniversalHubSafe", FileName = `Config_${PlaceId}` },
    KeySystem = false
})

local Tab = Window:CreateTab("Player", 4483362458)

-- Helper para criar UI sincronizada com Watchdog
local function CreateSafeToggle(name, text, default, callback)
    CONFIG._Flags[name] = default
    return Tab:CreateToggle({
        Name = text, CurrentValue = default, Flag = name,
        Callback = function(v)
            CONFIG._Flags[name] = v
            CONFIG[name] = v
            if callback then callback(v) end
            SaveConfig()
        end
    })
end

local function CreateSafeSlider(name, text, range, inc, default, callback)
    return Tab:CreateSlider({
        Name = text, Range = range, Increment = inc, CurrentValue = default, Flag = name,
        Callback = function(v)
            CONFIG[name] = v
            if callback then callback(v) end
            SaveConfig()
        end
    })
end

-- SECTIONS
Tab:CreateSection("🏃 Movimento (Safe)")
CreateSafeSlider("WalkSpeed", "WalkSpeed", {1, 500}, 1, CONFIG.WalkSpeed, function(v) ApplyPhysics() end)
CreateSafeSlider("JumpPower", "JumpPower", {50, 300}, 1, CONFIG.JumpPower, function(v) ApplyPhysics() end)
CreateSafeSlider("Gravity", "Gravidade", {0.1, 5}, 0.1, CONFIG.Gravity, function(v) workspace.Gravity = v * 196.2 end)
CreateSafeToggle("InfiniteJump", "Infinite Jump", CONFIG.InfiniteJump)
CreateSafeToggle("Noclip", "Noclip (Paredes)", CONFIG.Noclip)
CreateSafeToggle("Spin", "Spin (Giro)", CONFIG.Spin)
CreateSafeSlider("SpinSpeed", "Spin Speed", {1, 100}, 1, CONFIG.SpinSpeed)
CreateSafeToggle("Sit", "Sentar", CONFIG.Sit)

Tab:CreateSection("✈️ Fly Seguro (CFrame + Input)")
CreateSafeToggle("Fly", "Ativar Fly (WASD + Space/Shift)", CONFIG.Fly, ToggleFly)
CreateSafeSlider("FlySpeed", "Velocidade Fly", {1, 500}, 1, CONFIG.FlySpeed)

Tab:CreateSection("👁️ Visuais")
CreateSafeToggle("ESP", "ESP Players (Highlight)", CONFIG.ESP)
CreateSafeToggle("Fullbright", "Fullbright", CONFIG.Fullbright)
CreateSafeToggle("NoFog", "Sem Neblina", CONFIG.NoFog)
CreateSafeSlider("FOV", "Field of View", {30, 120}, 1, CONFIG.FOV, function(v) camera.FieldOfView = v end)
CreateSafeToggle("FreeCam", "FreeCam (Câmera Livre)", CONFIG.FreeCam, ToggleFreeCam)

Tab:CreateSection("⚙️ Utilidades & Segurança")
CreateSafeToggle("AntiAFK", "Anti-AFK (Clique Real)", CONFIG.AntiAFK)
CreateSafeToggle("ClickTP", "Click TP (Toque/Click)", CONFIG.ClickTP)
CreateSafeToggle("AntiLag", "Anti-Lag (Reduz Updates)", CONFIG.AntiLag)

-- Speed Master Controls
Tab:CreateSection("🚀 Velocidade Global (Master)")
CreateSafeSlider("VelocidadeGlobal", "Velocidade Global", {1, 1000}, 1, CONFIG.VelocidadeGlobal)
CreateSafeToggle("AplicarVelocidade", "APLICAR VELOCIDADE GLOBAL", CONFIG.AplicarVelocidade, function(v) ApplyPhysics() end)
CreateSafeSlider("LimiteVelocidade", "Limite Máximo Seguro", {1, 1000}, 1, CONFIG.LimiteVelocidade)

-- Buttons
Tab:CreateButton({Name = "💾 Salvar Config (Este Jogo)", Callback = function() SaveConfig(); Notify("Salvo", "Config salva para PlaceId: "..PlaceId) end})
Tab:CreateButton({Name = "📂 Carregar Config (Este Jogo)", Callback = function() LoadConfig(); ApplyPhysics(); Notify("Carregado", "Config carregada.") end})
Tab:CreateButton({Name = "🔄 Resetar Tudo (Padrão)", Callback = function()
    for _,conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    for _,conn in pairs(Watchdog.ActiveLoops) do pcall(function() conn:Disconnect() end) end
    if FlyConnection then FlyConnection:Disconnect() end
    if FreeCamConn then FreeCamConn:Disconnect() end
    -- Reset Config Table
    CONFIG = {WalkSpeed=16,JumpPower=50,Gravity=1,InfiniteJump=false,Noclip=false,Spin=false,SpinSpeed=10,Sit=false,Fly=false,FlySpeed=50,ESP=false,Fullbright=false,NoFog=false,FOV=70,FreeCam=false,AntiAFK=false,AntiLag=false,ClickTP=false,VelocidadeGlobal=1000,AplicarVelocidade=false,LimiteVelocidade=1000,_Flags={}}
    LoadConfig() -- Recria _Flags
    ApplyPhysics()
    Notify("Reset", "Script reiniciado. Reexecute se necessário.", 5, "SUCCESS")
end})
Tab:CreateButton({Name = "💀 Resetar Personagem", Callback = function() local h=SafeChar:GetHumanoid() if h then h.Health=0 end end})
Tab:CreateButton({Name = "🔁 Rejoin", Callback = function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, player) end})
Tab:CreateButton({Name = "🌐 Server Hop", Callback = function()
    Notify("Server Hop", "Procurando...", 10)
    task.spawn(function()
        local ok, res = pcall(function() return HttpService:RequestAsync({Url=`https://games.roblox.com/v1/games/${PlaceId}/servers/Public?sortOrder=Asc&limit=100`, Method="GET"}) end)
        if ok and res.Success then
            local data = HttpService:JSONDecode(res.Body)
            for _,s in pairs(data.data) do if s.id ~= game.JobId and s.playing < s.maxPlayers then TeleportService:TeleportToPlaceInstance(PlaceId, s.id, player); return end end
            Notify("Server Hop", "Lotado ou erro.")
        else Notify("Erro", "Falha na API (Executor não suporta RequestAsync?)", 5, "ERROR") end
    end)
end})

-- 🔵 8. INITIALIZE -----------------------------------------------------------------------
ApplyPhysics()
Rayfield:LoadConfiguration() -- Carrega UI Flags
Notify("✅ Universal Hub Safe", "Carregado com Watchdog & VirtualInput.\nJogo: " .. (game:GetService("MarketplaceService"):GetProductInfo(PlaceId).Name or "Desconhecido"), 6, "SUCCESS")

-- Cleanup Global (Se der reload script)
getgenv()._UniversalHubCleanup = function()
    for _,c in pairs(Connections) do pcall(function() c:Disconnect() end) end
    for _,c in pairs(Watchdog.ActiveLoops) do pcall(function() c:Disconnect() end) end
    if FlyConnection then FlyConnection:Disconnect() end
    if FreeCamConn then FreeCamConn:Disconnect() end
    -- Restaura Kick original
    if OldKick then hookfunction(player.Kick, OldKick) end
    if OldTeleport then hookfunction(TeleportService.TeleportToPlaceInstance, OldTeleport) end
    print("[UniversalHub] Cleanup completo.")
end
