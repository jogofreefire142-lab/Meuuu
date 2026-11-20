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
    Rejoin = false,
    ServerHop = false,
    SelectedPlayer = "Nenhum",
    MaxSpeed = 1000,
    Organize = false,
    ClickTP = false
}

-- Caminho para salvar configurações
local CONFIG_PATH = "ScriptUniversal_Config.json"

-- Função para salvar configurações
local function saveConfig()
    local success, error = pcall(function()
        local data = HttpService:JSONEncode(CONFIG)
        writefile(CONFIG_PATH, data)
    end)
    if success then
        Rayfield:Notify("Configurações salvas!", 3, "SUCCESS")
    else
        Rayfield:Notify("Erro ao salvar: " .. error, 3, "ERROR")
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
            CONFIG[key] = value
        end
        Rayfield:Notify("Configurações carregadas!", 3, "SUCCESS")
    end
end

-- Funções seguras
local function getHum()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Função para aplicar todas as configurações
local function applyConfig()
    local hum = getHum()
    local root = getRoot()
    
    if hum then
        hum.WalkSpeed = CONFIG.WalkSpeed
        hum.JumpPower = CONFIG.JumpPower
        hum.UseJumpPower = true
        
        if CONFIG.Sit then
            hum.Sit = true
        end
    end
    
    if root and CONFIG.Fly then
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
            local currentHum = getHum()
            if currentHum then currentHum.PlatformStand = false end
        end)
    end
    
    workspace.CurrentCamera.FieldOfView = CONFIG.FOV
    
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
    return math.min(speed, CONFIG.MaxSpeed)
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
    Name = "Velocidade Máxima",
    Range = {16, 1000},
    Increment = 1,
    CurrentValue = 1000,
    Callback = function(Value)
        CONFIG.MaxSpeed = Value
        CONFIG.WalkSpeed = limitSpeed(CONFIG.WalkSpeed)
        CONFIG.FlySpeed = limitSpeed(CONFIG.FlySpeed)
        local hum = getHum()
        if hum then hum.WalkSpeed = CONFIG.WalkSpeed end
    end,
})

PlayerTab:CreateSlider({
    Name = "WalkSpeed (Velocidade)",
    Range = {16, 1000},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        CONFIG.WalkSpeed = limitSpeed(Value)
        local hum = getHum()
        if hum then hum.WalkSpeed = CONFIG.WalkSpeed end
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

PlayerTab:CreateSlider({
    Name = "Gravidade",
    Range = {0.1, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(Value)
        CONFIG.Gravity = Value
        workspace.GlobalGravity = Value * 196.2
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
        CONFIG.Noclip = Value
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
        if hum and Value then
            hum.Sit = true
        elseif hum then
            hum.Sit = false
        end
    end,
})

-- === 2. FLY (VOAR) ===
PlayerTab:CreateSection("✈️ Fly (Voar)")

PlayerTab:CreateToggle({
    Name = "Ativar Fly (Mobile/PC)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.Fly = Value
        if Value then
            applyConfig()
        else
            local root = getRoot()
            if root then
                local bv = root:FindFirstChild("BodyVelocity")
                local bg = root:FindFirstChild("BodyGyro")
                if bv then bv:Destroy() end
                if bg then bg:Destroy() end
                local hum = getHum()
                if hum then hum.PlatformStand = false end
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Velocidade do Fly",
    Range = {10, 1000},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        CONFIG.FlySpeed = limitSpeed(Value)
    end,
})

-- === 3. VISUAL E CÂMERA ===
PlayerTab:CreateSection("👁️ Visual e Câmera")

PlayerTab:CreateToggle({
    Name = "ESP Players (Ver Jogadores)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.ESP = Value
        if not Value then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("ESP_Highlight") then
                    p.Character.ESP_Highlight:Destroy()
                end
            end
        end
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
            if hum then
                cam.CameraSubject = hum
            end
        end
    end,
})

-- === 4. JOGADORES E TELEPORTE ===
PlayerTab:CreateSection("👥 Jogadores e Teleporte")

-- Lista de jogadores
local playerList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= player then
        table.insert(playerList, p.Name)
    end
end

-- Dropdown para selecionar jogador
PlayerTab:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = playerList,
    CurrentOption = playerList[1] or "Nenhum",
    Callback = function(Option)
        CONFIG.SelectedPlayer = Option
    end,
})

-- Botão para teleportar para jogador
PlayerTab:CreateButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        local targetName = CONFIG.SelectedPlayer
        if targetName and targetName ~= "Nenhum" then
            local targetPlayer = Players:FindFirstChild(targetName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = getRoot()
                if root then
                    root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end,
})

-- Botão para spectar jogador
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

-- Toggle de Teleporte por Clique
PlayerTab:CreateToggle({
    Name = "Click/Touch TP (Teleporte por Clique)",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.ClickTP = Value
    end,
})

-- === 5. UTILIDADES E SERVIDOR ===
PlayerTab:CreateSection("⚙️ Utilidades e Servidor")

-- Botão de Organizar
PlayerTab:CreateButton({
    Name = "Organizar",
    Callback = function()
        CONFIG.Organize = not CONFIG.Organize
        Rayfield:Notify("Organização " .. (CONFIG.Organize and "ativada" or "desativada"), 3, "INFO")
    end,
})

-- Botão para salvar configurações
PlayerTab:CreateButton({
    Name = "Salvas Configurações",
    Callback = function()
        saveConfig()
    end,
})

-- Botão para carregar configurações
PlayerTab:CreateButton({
    Name = "Carregar Configurações",
    Callback = function()
        loadConfig()
        applyConfig()
        Rayfield:Notify("Configurações carregadas e aplicadas!", 3, "SUCCESS")
    end,
})

-- Botão para resetar configurações
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
            Rejoin = false,
            ServerHop = false,
            SelectedPlayer = "Nenhum",
            MaxSpeed = 1000,
            Organize = false,
            ClickTP = false
        }
        applyConfig()
        Rayfield:Notify("Configurações resetadas!", 3, "SUCCESS")
    end,
})

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.AntiAFK = Value
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
        CONFIG.Rejoin = true
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end,
})

PlayerTab:CreateButton({
    Name = "Server Hop (Trocar Servidor)",
    Callback = function()
        CONFIG.ServerHop = true
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
    applyConfig()
end)

-- === LOOPS DE FUNDO ===

-- Loop de Noclip, Spin e FreeCam
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
applyConfig()

-- Carregar configurações salvas
loadConfig()

-- Notificação de sucesso
Rayfield:Notify("Script carregado com sucesso!", 5, "SUCCESS")
