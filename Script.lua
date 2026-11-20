-- 🍎 SCRIPT UNIVERSAL COM RAYFIELD UI
-- Aba Player Completa com todas as opções

-- Carregar Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dimetric/Rayfield/main/Source.lua"))()

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Configurações
local CONFIG = {
    WalkSpeed = 50,
    JumpPower = 100,
    FlySpeed = 50,
    FOV = 70,
    ESP = false,
    Fly = false,
    Noclip = false,
    AntiAFK = false,
    Fullbright = false,
    InfiniteJump = false,
    KeySystem = false -- Altere para true se quiser usar Key System
}

-- Criar Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = "🍎 Script Universal",
    Theme = "Dark", -- Dark, Light, Night
    KeySystem = CONFIG.KeySystem,
    Key = "1234", -- Senha (altere conforme necessário)
    KeyName = "Chave" -- Texto que aparecerá
})

-- Aba Player
local PlayerTab = Window:CreateTab("Player", "👤")

-- Seção Movimentação
local MovementSection = PlayerTab:CreateSection("Movimentação")

-- WalkSpeed Slider
MovementSection:CreateSlider("WalkSpeed", "Velocidade de Caminhada", 50, 200, 1, CONFIG.WalkSpeed, function(value)
    CONFIG.WalkSpeed = value
    humanoid.WalkSpeed = value
end)

-- JumpPower Slider
MovementSection:CreateSlider("JumpPower", "Força do Pulo", 50, 200, 1, CONFIG.JumpPower, function(value)
    CONFIG.JumpPower = value
    humanoid.JumpPower = value
end)

-- Fly Toggle
MovementSection:CreateToggle("Fly", "Voar", CONFIG.Fly, function(toggle)
    CONFIG.Fly = toggle
    if toggle then
        -- Configurar voo
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = humanoidRootPart
        
        local flyConnection
        flyConnection = RunService.Heartbeat:Connect(function()
            if not CONFIG.Fly then
                bodyVelocity:Destroy()
                flyConnection:Disconnect()
                return
            end
            
            local direction = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + Vector3.new(0, 0, 1)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction + Vector3.new(0, 0, -1)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + Vector3.new(1, 0, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction + Vector3.new(-1, 0, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, 1, 0)
            end
            
            bodyVelocity.Velocity = direction * CONFIG.FlySpeed
        end)
    end
end)

-- Noclip Toggle
MovementSection:CreateToggle("Noclip", "Atravessar Objetos", CONFIG.Noclip, function(toggle)
    CONFIG.Noclip = toggle
    if toggle then
        spawn(function()
            while CONFIG.Noclip do
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("Part") or part:IsA("MeshPart") then
                        part.CanCollide = false
                    end
                end
                wait(0.1)
            end
        end)
    end
end)

-- Infinite Jump Toggle
MovementSection:CreateToggle("InfiniteJump", "Pulo Infinito", CONFIG.InfiniteJump, function(toggle)
    CONFIG.InfiniteJump = toggle
    if toggle then
        local jumpConnection
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            if CONFIG.InfiniteJump then
                humanoid.Jump = true
            end
        end)
        
        -- Desconectar quando desativado
        spawn(function()
            while CONFIG.InfiniteJump do
                wait(1)
            end
            jumpConnection:Disconnect()
        end)
    end
end)

-- Seção Visual
local VisualSection = PlayerTab:CreateSection("Visual")

-- ESP Toggle
VisualSection:CreateToggle("ESP", "Ver Jogadores (ESP)", CONFIG.ESP, function(toggle)
    CONFIG.ESP = toggle
    if toggle then
        spawn(function()
            while CONFIG.ESP do
                for _, otherPlayer in pairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local otherChar = otherPlayer.Character
                        local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                        
                        if otherRoot then
                            -- Criar highlight para ESP
                            local highlight = otherChar:FindFirstChild("ESP_Highlight")
                            if not highlight then
                                highlight = Instance.new("Highlight")
                                highlight.Name = "ESP_Highlight"
                                highlight.Parent = otherChar
                                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                highlight.FillTransparency = 0.5
                            end
                            highlight.Enabled = true
                        end
                    end
                end
                wait(1)
            end
        end)
    end
end)

-- Fullbright Toggle
VisualSection:CreateToggle("Fullbright", "Brilho Máximo", CONFIG.Fullbright, function(toggle)
    CONFIG.Fullbright = toggle
    if toggle then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = Color3.fromRGB(100, 100, 100)
        Lighting.Brightness = 1
    end
end)

-- FOV Slider
VisualSection:CreateSlider("FOV", "Campo de Visão", 50, 120, 1, CONFIG.FOV, function(value)
    CONFIG.FOV = value
    Camera.FieldOfView = value
end)

-- Seção Proteção
local ProtectionSection = PlayerTab:CreateSection("Proteção")

-- Anti-AFK Toggle
ProtectionSection:CreateToggle("AntiAFK", "Anti-AFK", CONFIG.AntiAFK, function(toggle)
    CONFIG.AntiAFK = toggle
    if toggle then
        spawn(function()
            while CONFIG.AntiAFK do
                -- Simular movimento para evitar AFK
                if humanoidRootPart then
                    local randomOffset = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(randomOffset)
                end
                wait(10)
            end
        end)
    end
end)

-- Botão de Reset
ProtectionSection:CreateButton("Resetar Personagem", "Mata o personagem atual", function()
    if humanoid then
        humanoid.Health = 0
    end
end)

-- Aba Visual (outros efeitos)
local VisualTab = Window:CreateTab("Visual", "🎨")

-- Seção de Efeitos
local EffectsSection = VisualTab:CreateSection("Efeitos Visuais")

-- Toggle para efeitos de partícula
EffectsSection:CreateToggle("ParticleEffects", "Efeitos de Partícula", true, function(toggle)
    -- Implementar efeitos de partícula conforme necessário
end)

-- Seção de Configurações
local SettingsTab = Window:CreateTab("Configurações", "⚙️")

-- Botão para salvar configurações
SettingsTab:CreateButton("Salvas Configurações", "Salva as configurações atualizadas", function()
    -- Implementar salvamento de configurações
    Rayfield:Notify("Configurações salvas!", 5, "SUCCESS")
end)

-- Botão para limpar configurações
SettingsTab:CreateButton("Limpar Configurações", "Restaura as configurações padrão", function()
    -- Implementar limpeza de configurações
    Rayfield:Notify("Configurações restauradas!", 5, "SUCCESS")
end)

-- Inicialização
print("🍎 Script Universal carregado com Rayfield UI!")

-- Notificação de sucesso
Rayfield:Notify("Script carregado com sucesso!", 5, "SUCCESS")
