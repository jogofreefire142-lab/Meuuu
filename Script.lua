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

-- Configurações
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
    LimiteVelocidade = 1000
}

-- Funções de apoio
local function getHum()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Fly mais estável
local function toggleFly(enabled)
    CONFIG.Fly = enabled
    local hum = getHum()
    local root = getRoot()
    
    if not hum or not root then
        task.wait(0.5)
        hum = getHum()
        root = getRoot()
        if not hum or not root then return end
    end
    
    if enabled then
        hum.PlatformStand = true
        
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = root
        
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.Parent = root
        
        task.spawn(function()
            while CONFIG.Fly and root and root.Parent do
                local cam = workspace.CurrentCamera
                if not cam then task.wait() continue end
                
                bg.CFrame = cam.CFrame
                
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    local camLook = cam.CFrame.LookVector
                    local camRight = cam.CFrame.RightVector
                    local flatForward = Vector3.new(camLook.X, 0, camLook.Z).Unit
                    local flatRight = Vector3.new(camRight.X, 0, camRight.Z).Unit
                    
                    local forwardAmount = moveDir:Dot(flatForward)
                    local rightAmount = moveDir:Dot(flatRight)
                    
                    local finalDir = (camLook * forwardAmount) + (camRight * rightAmount)
                    bv.Velocity = finalDir * CONFIG.FlySpeed
                else
                    bv.Velocity = Vector3.zero
                end
                
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    bv.Velocity = bv.Velocity + Vector3.new(0, CONFIG.FlySpeed, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    bv.Velocity = bv.Velocity - Vector3.new(0, CONFIG.FlySpeed, 0)
                end
                
                RunService.Heartbeat:Wait()
            end
            
            bv:Destroy()
            bg:Destroy()
            if hum then hum.PlatformStand = false end
        end)
    else
        local bv = root:FindFirstChild("BodyVelocity")
        local bg = root:FindFirstChild("BodyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end

-- Noclip mais eficiente
local function toggleNoclip(enabled)
    CONFIG.Noclip = enabled
    local char = player.Character
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = not enabled
        end
    end
    
    if enabled then
        local noclipConn
        noclipConn = RunService.Stepped:Connect(function()
            if not CONFIG.Noclip then
                noclipConn:Disconnect()
                return
            end
            
            local currentChar = player.Character
            if not currentChar then return end
            
            for _, part in pairs(currentChar:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end
end

-- Aplicar velocidade com verificação
local function applySpeed()
    local hum = getHum()
    if not hum then return end
    
    local targetSpeed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
    hum.WalkSpeed = math.min(targetSpeed, CONFIG.LimiteVelocidade)
end

-- ESP mais estável
local function toggleESP(enabled)
    CONFIG.ESP = enabled
    
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local old = p.Character:FindFirstChild("ESP_Highlight")
            if old then old:Destroy() end
        end
    end
    
    if not enabled then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = p.Character
        end
    end
    
    local espConn
    espConn = Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function(char)
            if not CONFIG.ESP then return end
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = char
        end)
    end)
end

-- Configurações com verificação de permissões
local function saveConfig()
    local success, error = pcall(function()
        local configPath = "ScriptUniversal_Config.json"
        local data = HttpService:JSONEncode(CONFIG)
        writefile(configPath, data)
        return true
    end)
    
    if success then
        Rayfield:Notify("Configurações salvas!", 3, "SUCCESS")
    else
        Rayfield:Notify("Erro ao salvar: " .. tostring(error), 3, "ERROR")
    end
end

local function loadConfig()
    local success, data = pcall(function()
        local configPath = "ScriptUniversal_Config.json"
        if isfile(configPath) then
            local content = readfile(configPath)
            return HttpService:JSONDecode(content)
        end
        return nil
    end)
    
    if success and data then
        for key, value in pairs(data) do
            CONFIG[key] = value
        end
        Rayfield:Notify("Configurações carregadas!", 3, "SUCCESS")
        return true
    end
    return false
end

-- Criar Janela Rayfield
local Window = Rayfield:CreateWindow({
    Name = "Script Universal - Player",
    LoadingTitle = "Carregando Menu...",
    LoadingSubtitle = "Aba Player Completa",
    ConfigurationSaving = { Enabled = true },
    KeySystem = false
})

-- Aba Player
local PlayerTab = Window:CreateTab("Player", 4483362458)

-- === 1. MOVIMENTAÇÃO E FÍSICA ===
PlayerTab:CreateSection("🏃 Movimentação e Física")

PlayerTab:CreateSlider({
    Name = "Velocidade Universal",
    Range = {1, 1000},
    Increment = 1,
    CurrentValue = 1000,
    Callback = function(Value)
        CONFIG.VelocidadeGlobal = Value
        if CONFIG.AplicarVelocidade then applySpeed() end
        Rayfield:Notify("Velocidade universal definida para " .. Value, 3, "SUCCESS")
    end,
})

PlayerTab:CreateToggle({
    Name = "Ativar Velocidade Universal",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.AplicarVelocidade = Value
        applySpeed()
        Rayfield:Notify("Velocidade universal " .. (Value and "ATIVADA" or "DESATIVADA"), 3, Value and "SUCCESS" or "INFO")
    end,
})

PlayerTab:CreateSlider({
    Name = "WalkSpeed (Velocidade)",
    Range = {1, 1000},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        CONFIG.WalkSpeed = Value
        if not CONFIG.AplicarVelocidade then
            applySpeed()
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "JumpPower (Força do Pulo)",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(Value)
        CONFIG.JumpPower = Value
        local hum = getHum()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = Value
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump (Pulo Infinito)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.InfiniteJump = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip (Atravessar Paredes)",
    CurrentValue = false,
    Callback = function(Value)
        toggleNoclip(Value)
    end,
})

PlayerTab:CreateToggle({
    Name = "Spin (Girar Rápido)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.Spin = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "SpinSpeed (Velocidade do Giro)",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(Value)
        CONFIG.SpinSpeed = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "Sit (Sentar)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.Sit = Value
        local hum = getHum()
        if hum then hum.Sit = Value end
    end,
})

-- === 2. FLY (VOAR) ===
PlayerTab:CreateSection("✈️ Fly (Voar)")

PlayerTab:CreateToggle({
    Name = "Ativar Fly (Mobile/PC)",
    CurrentValue = false,
    Callback = function(Value)
        toggleFly(Value)
        Rayfield:Notify("Fly " .. (Value and "ATIVADO" or "DESATIVADO"), 3, Value and "SUCCESS" or "INFO")
    end,
})

PlayerTab:CreateSlider({
    Name = "Velocidade do Fly",
    Range = {1, 1000},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        CONFIG.FlySpeed = Value
    end,
})

-- === 3. VISUAL E CÂMERA ===
PlayerTab:CreateSection("👁️ Visual e Câmera")

PlayerTab:CreateToggle({
    Name = "ESP Players (Ver Jogadores)",
    CurrentValue = false,
    Callback = function(Value)
        toggleESP(Value)
        Rayfield:Notify("ESP " .. (Value and "ATIVADO" or "DESATIVADO"), 3, Value and "SUCCESS" or "INFO")
    end,
})

PlayerTab:CreateToggle({
    Name = "Fullbright (Brilho Máximo)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.Fullbright = Value
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.GlobalShadows = true
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "No Fog (Sem Neblina)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.NoFog = Value
        if Value then
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = 300
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "FOV (Campo de Visão)",
    Range = {50, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(Value)
        CONFIG.FOV = Value
        workspace.CurrentCamera.FieldOfView = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "FreeCam (Câmera Livre)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.FreeCam = Value
        local cam = workspace.CurrentCamera
        local root = getRoot()
        if Value and root then
            cam.CFrame = CFrame.new(root.Position + Vector3.new(10, 10, 10))
            cam.CameraSubject = nil
        else
            local hum = getHum()
            if hum then cam.CameraSubject = hum end
        end
    end,
})

-- === 4. JOGADORES E TELEPORTE ===
PlayerTab:CreateSection("👥 Jogadores e Teleporte")

local playerList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= player then table.insert(playerList, p.Name) end
end

PlayerTab:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = playerList,
    CurrentOption = playerList[1] or "Nenhum",
    Callback = function(Option) CONFIG.SelectedPlayer = Option end,
})

PlayerTab:CreateButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        local targetName = CONFIG.SelectedPlayer
        if targetName and targetName ~= "Nenhum" then
            local targetPlayer = Players:FindFirstChild(targetName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = getRoot()
                if root then root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame end
            end
        end
    end,
})

PlayerTab:CreateButton({
    Name = "Assistir Jogador (Spectate)",
    Callback = function()
        local targetName = CONFIG.SelectedPlayer
        if targetName and targetName ~= "Nenhum" then
            local targetPlayer = Players:FindFirstChild(targetName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                workspace.CurrentCamera.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Click/Touch TP (Teleporte por Clique)",
    CurrentValue = false,
    Callback = function(Value) CONFIG.ClickTP = Value end,
})

-- === 5. UTILIDADES E SERVIDOR ===
PlayerTab:CreateSection("⚙️ Utilidades e Servidor")

PlayerTab:CreateButton({
    Name = "Organizar",
    Callback = function()
        CONFIG.Organize = not CONFIG.Organize
        Rayfield:Notify("Organização " .. (CONFIG.Organize and "ativada" or "desativada"), 3, "INFO")
    end,
})

PlayerTab:CreateToggle({
    Name = "Anti-Lag (Estabilizar FPS)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.AntiLag = Value
        Rayfield:Notify("Anti-Lag " .. (Value and "ATIVADO" or "DESATIVADO"), 3, Value and "SUCCESS" or "INFO")
    end,
})

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(Value) CONFIG.AntiAFK = Value end,
})

PlayerTab:CreateButton({
    Name = "Salvas Configurações",
    Callback = function()
        saveConfig()
    end,
})

PlayerTab:CreateButton({
    Name = "Carregar Configurações",
    Callback = function()
        loadConfig()
        applySpeed()
        Rayfield:Notify("Configurações carregadas e aplicadas!", 3, "SUCCESS")
    end,
})

PlayerTab:CreateButton({
    Name = "Resetar Configurações",
    Callback = function()
        CONFIG = {
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
            LimiteVelocidade = 1000
        }
        applySpeed()
        Rayfield:Notify("Configurações resetadas!", 3, "SUCCESS")
    end,
})

PlayerTab:CreateButton({
    Name = "Resetar Velocidade",
    Callback = function()
        CONFIG.VelocidadeGlobal = 1000
        CONFIG.AplicarVelocidade = false
        CONFIG.LimiteVelocidade = 1000
        CONFIG.WalkSpeed = 16
        CONFIG.FlySpeed = 50
        applySpeed()
        Rayfield:Notify("Velocidade resetada!", 3, "SUCCESS")
    end,
})

PlayerTab:CreateButton({
    Name = "Resetar Personagem",
    Callback = function()
        local hum = getHum()
        if hum then hum.Health = 0 end
    end,
})

PlayerTab:CreateButton({
    Name = "Rejoin (Entrar de Novo)",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end,
})

PlayerTab:CreateButton({
    Name = "Server Hop (Trocar Servidor)",
    Callback = function()
        local servers = {}
        local url = "https://api.roblox.com/games/" .. game.PlaceId .. "/servers?limit=100&sortOrder=Asc"
        
        local success, response = pcall(function()
            return HttpService:GetAsync(url)
        end)
        
        if success and response then
            local data = HttpService:JSONDecode(response)
            for _, server in pairs(data.data) do
                if server.id ~= game.JobId and server.playing < 50 then
                    table.insert(servers, server.id)
                end
            end
            
            if #servers > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1], player)
            end
        end
    end,
})

-- === GERENCIAMENTO DE RESPAWN ===
player.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.5)
    applySpeed()
end)

-- === LOOP DE PROTEÇÃO CONTRA RESET ===
RunService.Stepped:Connect(function()
    local hum = getHum()
    if hum then
        if CONFIG.AplicarVelocidade then
            if hum.WalkSpeed ~= CONFIG.VelocidadeGlobal then
                hum.WalkSpeed = CONFIG.VelocidadeGlobal
            end
        else
            if hum.WalkSpeed ~= CONFIG.WalkSpeed then
                hum.WalkSpeed = CONFIG.WalkSpeed
            end
        end
    end
end)

-- === LOOPS DE FUNDO ===

RunService.Stepped:Connect(function()
    local char = player.Character
    if not char then return end
    
    if CONFIG.Noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
    
    if CONFIG.Spin then
        local root = getRoot()
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed), 0)
        end
    end
    
    if CONFIG.FreeCam then
        local cam = workspace.CurrentCamera
        local moveSpeed = 50
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            cam.CFrame = cam.CFrame + cam.CFrame.LookVector * moveSpeed * RunService.HeartbeatWait
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            cam.CFrame = cam.CFrame - cam.CFrame.LookVector * moveSpeed * RunService.HeartbeatWait
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            cam.CFrame = cam.CFrame + cam.CFrame.RightVector * moveSpeed * RunService.HeartbeatWait
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            cam.CFrame = cam.CFrame - cam.CFrame.RightVector * moveSpeed * RunService.HeartbeatWait
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            cam.CFrame = cam.CFrame + Vector3.new(0, moveSpeed, 0) * RunService.HeartbeatWait
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            cam.CFrame = cam.CFrame - Vector3.new(0, moveSpeed, 0) * RunService.HeartbeatWait
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Anti-AFK
player.Idled:Connect(function()
    if CONFIG.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Teleporte por Clique
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if CONFIG.ClickTP and not gameProcessed then
        if input.UserInputState == Enum.UserInputState.Begin then
            local position
            if input.UserInputType == Enum.UserInputType.Touch then
                position = input.Position
            else
                local mouse = player:GetMouse()
                position = mouse.Hit.Position
            end
            local root = getRoot()
            if root then
                root.CFrame = CFrame.new(position)
            end
        end
    end
end)

-- Atualizar lista de jogadores
task.spawn(function()
    while task.wait(5) do
        playerList = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(playerList, p.Name)
            end
        end
    end
end)

-- Aplicar configurações iniciais
applySpeed()

-- Carregar configurações salvas
loadConfig()

-- Notificação de sucesso
Rayfield:Notify("Script Universal Carregado com sucesso!", 5, "SUCCESS")
