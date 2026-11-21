-- 🔵 1. ESPERA PARA AUTO EXECUTE
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

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==========================================
-- CONFIGURAÇÕES CENTRAIS (Tabela Única)
-- ==========================================
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
    AntiLag = false, -- Reduz frequência de loops pesados
    Rejoin = false,
    ServerHop = false,
    SelectedPlayer = "Nenhum",
    MaxSpeed = 1000,
    Organize = false,
    ClickTP = false,
    VelocidadeGlobal = 1000,
    AplicarVelocidade = false,
    LimiteVelocidade = 1000
}

local CONFIG_PATH = "ScriptUniversal_Config.json"
local Connections = {} -- Para gerenciar conexões e dar disconnect limpo
local ESP_Highlights = {} -- Cache de highlights do ESP
local flyThread = nil -- Controle da thread do Fly
local freeCamConnection = nil

-- ==========================================
-- FUNÇÕES UTILITÁRIAS
-- ==========================================
local function notify(title, content, duration, image)
    Rayfield:Notify({ Title = title, Content = content, Duration = duration or 3, Image = image or "INFO" })
end

local function getHum()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function limitSpeed(speed)
    return math.min(speed, CONFIG.LimiteVelocidade)
end

-- ==========================================
-- SISTEMA DE CONFIG (JSON + Rayfield)
-- ==========================================
local function saveConfig()
    local success, err = pcall(function()
        writefile(CONFIG_PATH, HttpService:JSONEncode(CONFIG))
    end)
    notify(success and "Sucesso" or "Erro", success and "Configurações salvas!" or ("Erro ao salvar: " .. tostring(err)), 3, success and "SUCCESS" or "ERROR")
end

local function loadConfig()
    local success, data = pcall(function()
        if isfile(CONFIG_PATH) then
            return HttpService:JSONDecode(readfile(CONFIG_PATH))
        end
    end)
    if success and data then
        -- Atualiza tabela existente (mantém referências)
        for k, v in pairs(data) do CONFIG[k] = v end
        notify("Carregado", "Configurações do arquivo aplicadas.", 3, "SUCCESS")
    end
end

-- Aplica física no character atual
local function applyPhysics(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    hum.WalkSpeed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
    hum.JumpPower = CONFIG.JumpPower
    hum.UseJumpPower = true
    hum.Sit = CONFIG.Sit
    
    workspace.GlobalGravity = CONFIG.Gravity * 196.2
    camera.FieldOfView = CONFIG.FOV

    -- Spin (BodyAngularVelocity)
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

-- ==========================================
-- LÓGICA DAS FEATURES (Fly, Noclip, ESP, etc)
-- ==========================================

-- --- FLY ---
local function toggleFly(state)
    CONFIG.Fly = state
    local hum = getHum()
    local root = getRoot()
    if not hum or not root then return end

    if state then
        hum.PlatformStand = true
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = root

        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.CFrame = camera.CFrame
        bg.Parent = root

        -- Loop do Fly em Heartbeat
        flyThread = RunService.Heartbeat:Connect(function(dt)
            if not CONFIG.Fly or not root.Parent then return toggleFly(false) end
            
            bg.CFrame = camera.CFrame
            local moveDir = hum.MoveDirection
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed)
            local vel = Vector3.zero

            if moveDir.Magnitude > 0 then
                -- Movimento relativo à câmera (Flat)
                local look = camera.CFrame.LookVector
                local right = camera.CFrame.RightVector
                local flatLook = Vector3.new(look.X, 0, look.Z).Unit
                local flatRight = Vector3.new(right.X, 0, right.Z).Unit
                vel = (flatLook * moveDir.Z + flatRight * moveDir.X) * speed
            end

            -- Vertical (Space / Shift)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0, speed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.new(0, speed, 0) end

            bv.Velocity = vel
        end)
    else
        if flyThread then flyThread:Disconnect(); flyThread = nil end
        local bv = root:FindFirstChild("FlyVelocity")
        local bg = root:FindFirstChild("FlyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        hum.PlatformStand = false
    end
end

-- --- NOCLIP ---
local function handleNoclip(dt)
    if not CONFIG.Noclip then return end
    local char = player.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

-- --- ESP ---
local function handleESP(dt)
    if not CONFIG.ESP then 
        -- Limpa se desligou
        for _, hl in pairs(ESP_Highlights) do if hl then hl:Destroy() end end
        table.clear(ESP_Highlights)
        return 
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local hl = ESP_Highlights[plr]
            
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = char
                ESP_Highlights[plr] = hl
            end
            -- Cor por Time ou Rainbow
            hl.FillColor = plr.TeamColor.Color
            hl.OutlineColor = Color3.new(1,1,1)
        end
    end
    -- Remove highlights de players que saíram
    for plr, hl in pairs(ESP_Highlights) do
        if not Players:FindFirstChild(plr.Name) or not plr.Character then
            hl:Destroy()
            ESP_Highlights[plr] = nil
        end
    end
end

-- --- FREECAM ---
local function toggleFreeCam(state)
    CONFIG.FreeCam = state
    local hum = getHum()
    local root = getRoot()
    
    if state and root then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = root.CFrame * CFrame.new(0, 5, 10)
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end -- Trava player
        
        freeCamConnection = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return toggleFreeCam(false) end
            local speed = 50 * dt
            local move = Vector3.zero
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            
            if move.Magnitude > 0 then
                camera.CFrame += move.Unit * speed
            end
        end)
    else
        if freeCamConnection then freeCamConnection:Disconnect(); freeCamConnection = nil end
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = hum
        if hum then hum.WalkSpeed = CONFIG.WalkSpeed; hum.JumpPower = CONFIG.JumpPower end
    end
end

-- --- VISUAIS (Fullbright / NoFog / FOV) ---
local function updateVisuals()
    camera.FieldOfView = CONFIG.FOV
    if CONFIG.Fullbright then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1e5; Lighting.GlobalShadows = false
    else
        Lighting.GlobalShadows = true
    end
    if CONFIG.NoFog then Lighting.FogEnd = 1e5 else Lighting.FogEnd = 300 end
end

-- --- CLICK TP ---
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not CONFIG.ClickTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local root = getRoot()
        if not root then return end
        
        local ray
        if input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            ray = camera:ViewportPointToRay(pos.X, pos.Y)
        else
            ray = camera:ViewportPointToRay(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        end
        
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {player.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        
        if result then root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
    end
end)

-- --- INFINITE JUMP ---
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- --- ANTI-AFK ---
player.Idled:Connect(function()
    if CONFIG.AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

-- ==========================================
-- LOOP PRINCIPAL UNIFICADO (Otimização Anti-Lag)
-- ==========================================
local lastHeavyUpdate = 0
RunService.Heartbeat:Connect(function(dt)
    -- 1. Proteção de Velocidade (Leve, roda sempre)
    local hum = getHum()
    if hum then
        local targetSpeed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
        if hum.WalkSpeed ~= targetSpeed then hum.WalkSpeed = targetSpeed end
    end

    -- 2. Loops Pesados (Noclip, ESP, Spin) - Controlados por AntiLag
    local now = tick()
    local interval = CONFIG.AntiLag and 0.1 or 0 -- 100ms se AntiLag ligado
    
    if now - lastHeavyUpdate >= interval then
        lastHeavyUpdate = now
        
        -- Noclip
        handleNoclip(dt)
        
        -- ESP
        handleESP(dt)
        
        -- Spin (CFrame method fallback se BodyAngularVelocity bugar)
        if CONFIG.Spin then
            local root = getRoot()
            if root then root.CFrame *= CFrame.Angles(0, math.rad(CONFIG.SpinSpeed) * dt * 60, 0) end
        end
    end
    
    -- 3. Visuals (Leve)
    updateVisuals()
end)

-- ==========================================
-- EVENTOS DE VIDA DO PERSONAGEM
-- ==========================================
player.CharacterAdded:Connect(function(char)
    task.wait(0.5) -- Espera carregar
    applyPhysics(char)
    
    -- Reativar features que dependem de character
    if CONFIG.Fly then toggleFly(true) end
    if CONFIG.FreeCam then toggleFreeCam(true) end
    -- Noclip/ESP/Spin são tratados no Heartbeat automaticamente
end)

-- ==========================================
-- CARREGAMENTO INICIAL
-- ==========================================
loadConfig() -- 1. Carrega JSON primeiro

-- ==========================================
-- UI RAYFIELD
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "Script Universal - Player",
    LoadingTitle = "Carregando Menu...",
    LoadingSubtitle = "Otimizado & Corrigido",
    ConfigurationSaving = { Enabled = true, FolderName = "DeltaPlayerHub", FileName = "PlayerConfig" },
    KeySystem = false
})

local PlayerTab = Window:CreateTab("Player", 4483362458)

-- Função helper para criar elementos ligados ao CONFIG
local function syncSlider(cfgKey, opts)
    opts.Flag = cfgKey
    opts.Callback = function(v)
        CONFIG[cfgKey] = v
        if cfgKey == "WalkSpeed" or cfgKey == "FlySpeed" or cfgKey == "VelocidadeGlobal" then
            CONFIG[cfgKey] = limitSpeed(v)
        end
        -- Aplicação instantânea comum
        if cfgKey == "FOV" then camera.FieldOfView = v end
        if cfgKey == "Gravity" then workspace.GlobalGravity = v * 196.2 end
        if cfgKey == "JumpPower" then local h=getHum() if h then h.JumpPower=v; h.UseJumpPower=true end end
        if cfgKey == "SpinSpeed" then local r=getRoot() local b=r and r:FindFirstChild("SpinForce") if b then b.AngularVelocity=Vector3.new(0,v,0) end end
    end
    return PlayerTab:CreateSlider(opts)
end

local function syncToggle(cfgKey, opts)
    opts.Flag = cfgKey
    opts.Callback = function(v)
        CONFIG[cfgKey] = v
        -- Lógica específica de toggle
        if cfgKey == "Fly" then toggleFly(v) end
        if cfgKey == "FreeCam" then toggleFreeCam(v) end
        if cfgKey == "Fullbright" or cfgKey == "NoFog" then updateVisuals() end
        if cfgKey == "AplicarVelocidade" then local h=getHum() if h then h.WalkSpeed = v and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed end end
        if cfgKey == "Sit" then local h=getHum() if h then h.Sit = v end end
        if cfgKey == "ESP" and not v then for _,hl in pairs(ESP_Highlights) do hl:Destroy() end table.clear(ESP_Highlights) end
    end
    return PlayerTab:CreateToggle(opts)
end

-- --- SEÇÕES ---
PlayerTab:CreateSection("🏃 Movimentação e Física")

syncSlider("VelocidadeGlobal", {Name="Velocidade Universal", Range={1,1000}, Increment=1, CurrentValue=CONFIG.VelocidadeGlobal})
syncToggle("AplicarVelocidade", {Name="Ativar Velocidade Universal", CurrentValue=CONFIG.AplicarVelocidade})
syncSlider("LimiteVelocidade", {Name="Limite de Velocidade", Range={1,1000}, Increment=1, CurrentValue=CONFIG.LimiteVelocidade})
syncSlider("MaxSpeed", {Name="Velocidade Máxima (UI)", Range={1,1000}, Increment=1, CurrentValue=CONFIG.MaxSpeed}) -- Apenas visual/UI limit
syncSlider("WalkSpeed", {Name="WalkSpeed", Range={1,1000}, Increment=1, CurrentValue=CONFIG.WalkSpeed})
syncSlider("JumpPower", {Name="JumpPower", Range={50,300}, Increment=1, CurrentValue=CONFIG.JumpPower})
syncSlider("Gravity", {Name="Gravidade", Range={0.1,5}, Increment=0.1, CurrentValue=CONFIG.Gravity})

syncToggle("InfiniteJump", {Name="Infinite Jump", CurrentValue=CONFIG.InfiniteJump})
syncToggle("Noclip", {Name="Noclip", CurrentValue=CONFIG.Noclip})
syncToggle("Spin", {Name="Spin", CurrentValue=CONFIG.Spin})
syncSlider("SpinSpeed", {Name="Spin Speed", Range={1,50}, Increment=1, CurrentValue=CONFIG.SpinSpeed})
syncToggle("Sit", {Name="Sit (Sentar)", CurrentValue=CONFIG.Sit})

PlayerTab:CreateSection("✈️ Fly")
syncToggle("Fly", {Name="Ativar Fly", CurrentValue=CONFIG.Fly})
syncSlider("FlySpeed", {Name="Fly Speed", Range={1,1000}, Increment=5, CurrentValue=CONFIG.FlySpeed})

PlayerTab:CreateSection("👁️ Visual e Câmera")
syncToggle("ESP", {Name="ESP Players", CurrentValue=CONFIG.ESP})
syncToggle("Fullbright", {Name="Fullbright", CurrentValue=CONFIG.Fullbright})
syncToggle("NoFog", {Name="No Fog", CurrentValue=CONFIG.NoFog})
syncSlider("FOV", {Name="FOV", Range={50,120}, Increment=1, CurrentValue=CONFIG.FOV})
syncToggle("FreeCam", {Name="FreeCam", CurrentValue=CONFIG.FreeCam})

PlayerTab:CreateSection("👥 Jogadores e Teleporte")

-- Dropdown Players (Atualiza automaticamente via Flag não é trivial no Rayfield sem refresh manual, mantendo botão refresh)
local selectedPlayerDropdown = PlayerTab:CreateDropdown({
    Name = "Selecionar Jogador",
    Flag = "SelectedPlayer",
    Options = {"Carregando..."},
    CurrentOption = "Nenhum",
    Callback = function(opt) CONFIG.SelectedPlayer = opt end,
})

PlayerTab:CreateButton({Name="🔄 Atualizar Lista", Callback=function()
    local list = {"Nenhum"}
    for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(list, p.Name) end end
    selectedPlayerDropdown:Refresh(list, true)
end})

PlayerTab:CreateButton({Name="Teleportar para Jogador", Callback=function()
    local target = Players:FindFirstChild(CONFIG.SelectedPlayer)
    local root = getRoot()
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and root then
        root.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
    end
end})

PlayerTab:CreateButton({Name="Spectate Jogador", Callback=function()
    local target = Players:FindFirstChild(CONFIG.SelectedPlayer)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        camera.CameraSubject = target.Character:FindFirstChild("Humanoid")
        notify("Spectate", "Assistindo "..target.Name..". Pressione FreeCam ou Reset para voltar.", 5)
    end
end})

syncToggle("ClickTP", {Name="Click/Touch TP", CurrentValue=CONFIG.ClickTP})

PlayerTab:CreateSection("⚙️ Utilidades e Servidor")

PlayerTab:CreateButton({Name="Organizar (Toggle)", Callback=function() CONFIG.Organize = not CONFIG.Organize notify("Organizar", CONFIG.Organize and "Ativado" or "Desativado") end})
syncToggle("AntiLag", {Name="Anti-Lag (Reduz updates pesados)", CurrentValue=CONFIG.AntiLag})
syncToggle("AntiAFK", {Name="Anti-AFK", CurrentValue=CONFIG.AntiAFK})

PlayerTab:CreateButton({Name="Salvar Config (JSON)", Callback=saveConfig})
PlayerTab:CreateButton({Name="Carregar Config (JSON)", Callback=function() loadConfig() applyPhysics(player.Character) notify("OK", "Config carregada e aplicada.") end})

PlayerTab:CreateButton({Name="Resetar Config Total", Callback=function()
    -- Reseta tabela mantendo referência
    local defaults = {WalkSpeed=16,JumpPower=50,Gravity=1,InfiniteJump=false,Noclip=false,Spin=false,SpinSpeed=10,Sit=false,Fly=false,FlySpeed=50,ESP=false,Fullbright=false,NoFog=false,FOV=70,FreeCam=false,AntiAFK=false,AntiLag=false,SelectedPlayer="Nenhum",MaxSpeed=1000,Organize=false,ClickTP=false,VelocidadeGlobal=1000,AplicarVelocidade=false,LimiteVelocidade=1000}
    for k,v in pairs(defaults) do CONFIG[k]=v end
    -- Desliga features ativas
    toggleFly(false); toggleFreeCam(false)
    for _,hl in pairs(ESP_Highlights) do hl:Destroy() end table.clear(ESP_Highlights)
    updateVisuals()
    applyPhysics(player.Character)
    notify("Reset", "Tudo voltado ao padrão.", 3, "SUCCESS")
end})

PlayerTab:CreateButton({Name="Resetar Velocidades", Callback=function()
    CONFIG.WalkSpeed=16; CONFIG.FlySpeed=50; CONFIG.VelocidadeGlobal=1000; CONFIG.AplicarVelocidade=false; CONFIG.LimiteVelocidade=1000
    applyPhysics(player.Character)
    notify("Reset", "Velocidades resetadas.")
end})

PlayerTab:CreateButton({Name="Resetar Personagem", Callback=function() local h=getHum() if h then h.Health=0 end end})

PlayerTab:CreateButton({Name="Rejoin", Callback=function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end})

PlayerTab:CreateButton({Name="Server Hop", Callback=function()
    notify("Server Hop", "Procurando servidor...", 10)
    task.spawn(function()
        local success, res = pcall(function()
            return HttpService:RequestAsync({Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method="GET"})
        end)
        if success and res.Success then
            local data = HttpService:JSONDecode(res.Body)
            for _,srv in pairs(data.data) do
                if srv.id ~= game.JobId and srv.playing < srv.maxPlayers - 2 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player)
                    return
                end
            end
            notify("Server Hop", "Nenhum servidor viável encontrado.")
        else
            notify("Erro", "Falha na API do Roblox.", 5, "ERROR")
        end
    end)
end})

-- ==========================================
-- FINALIZAÇÃO
-- ==========================================
applyPhysics(player.Character) -- Aplica física inicial
Rayfield:LoadConfiguration() -- 2. Carrega UI (Flags) por cima se existir
notify("Sucesso", "Script Universal carregado com correções!", 5, "SUCCESS")

-- Cleanup ao sair (Opcional, bom para reexecução)
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Rayfield" then
        for _, conn in pairs(Connections) do if conn.Disconnect then conn:Disconnect() end end
        if flyThread then flyThread:Disconnect() end
        if freeCamConnection then freeCamConnection:Disconnect() end
    end
end)
