-- 🤖 SCRIPT UNIVERSAL COM IA - AUTO DETECÇÃO
-- IA que analisa o ambiente e se adapta automaticamente

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Configurações da IA
local CONFIG = {
    -- IA
    IAEnabled = true,
    AutoDetect = true,
    DetectionRange = 100,
    AdaptivityLevel = 3, -- 1-5 (5 = máxima adaptação)
    
    -- Auto Farm
    AutoFarm = true,
    AttackRange = 30,
    FarmDelay = 0.5,
    
    -- Auto Collect
    AutoCollect = true,
    CollectRange = 50,
    
    -- Interface
    ShowGUI = true,
    GUIKey = Enum.KeyCode.RightControl,
    Theme = "Neon"
}

-- Sistema de IA para detecção e aprendizado
local IASystem = {}

-- Banco de dados de padrões detectados
local GamePatterns = {
    Enemies = {},
    Fruits = {},
    Items = {},
    Buttons = {},
    LastUpdate = 0
}

-- Função para analisar o jogo e detectar padrões
function IASystem:AnalyzeGame()
    local analysis = {
        GameType = "Unknown",
        Enemies = {},
        Collectibles = {},
        Interactive = {},
        Recommendations = {},
        Timestamp = tick()
    }
    
    -- Analisar todos os objetos no workspace
    for _, obj in pairs(Workspace:GetChildren()) do
        -- Detectar inimigos
        if obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local humanoid = obj.Humanoid
            local rootPart = obj.HumanoidRootPart
            
            -- Verificar se é um inimigo (tem health baixa ou é hostil)
            if humanoid.MaxHealth > 0 and humanoid.Health > 0 then
                local distance = (humanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                if distance <= CONFIG.DetectionRange then
                    -- Analisar comportamento do inimigo
                    local enemyType = self:ClassifyEnemy(obj)
                    
                    table.insert(analysis.Enemies, {
                        Model = obj,
                        Distance = distance,
                        Type = enemyType,
                        Position = rootPart.Position,
                        Health = humanoid.Health,
                        MaxHealth = humanoid.MaxHealth,
                        Threat = self:CalculateThreat(obj)
                    })
                end
            end
        end
        
        -- Detectar items coletáveis
        if obj:FindFirstChild("Fruit") or obj:FindFirstChild("Item") or obj:FindFirstChild("Money") then
            local distance = (humanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
            if distance <= CONFIG.DetectionRange then
                table.insert(analysis.Collectibles, {
                    Model = obj,
                    Distance = distance,
                    Type = self:ClassifyCollectible(obj),
                    Position = obj.HumanoidRootPart.Position,
                    Value = self:CalculateValue(obj)
                })
            end
        end
        
        -- Detectar objetos interativos
        if obj:FindFirstChild("ClickDetector") or obj:FindFirstChild("ProximityPrompt") then
            local distance = (humanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
            if distance <= CONFIG.DetectionRange then
                table.insert(analysis.Interactive, {
                    Model = obj,
                    Distance = distance,
                    Type = self:ClassifyInteractive(obj),
                    Position = obj.Position
                })
            end
        end
    end
    
    -- Determinar tipo de jogo
    analysis.GameType = self:DetermineGameType(analysis)
    
    -- Gerar recomendações personalizadas
    analysis.Recommendations = self:GenerateRecommendations(analysis)
    
    -- Aprender com os padrões
    self:LearnPatterns(analysis)
    
    return analysis
end

-- Classificar tipo de inimigo
function IASystem:ClassifyEnemy(enemy)
    local humanoid = enemy:FindFirstChild("Humanoid")
    if not humanoid then return "Unknown" end
    
    -- Verificar por nome
    local name = enemy.Name:lower()
    if name:find("boss") then return "Boss" end
    if name:find("sea") then return "SeaEnemy" end
    if name:find("sky") then return "SkyEnemy" end
    if name:find("ice") then return "IceEnemy" end
    if name:find("fire") then return "FireEnemy" end
    
    -- Verificar por comportamento
    if humanoid.WalkSpeed > 20 then return "Fast" end
    if humanoid.MaxHealth > 1000 then return "Tank" end
    
    return "Normal"
end

-- Classificar tipo de item coletável
function IASystem:ClassifyCollectible(item)
    local name = item.Name:lower()
    
    if item:FindFirstChild("Fruit") then return "Fruit" end
    if name:find("money") or name:find("beli") then return "Money" end
    if name:find("xp") or name:find("experience") then return "XP" end
    if name:find("fragment") then return "Fragment" end
    
    return "Item"
end

-- Classificar objeto interactivo
function IASystem:ClassifyInteractive(obj)
    local name = obj.Name:lower()
    
    if name:find("door") then return "Door" end
    if name:find("button") or name:find("switch") then return "Button" end
    if name:find("portal") then return "Portal" end
    if name:find("npc") then return "NPC" end
    
    return "Interactive"
end

-- Calcular ameaça do inimigo
function IASystem:CalculateThreat(enemy)
    local humanoid = enemy:FindFirstChild("Humanoid")
    if not humanoid then return 0 end
    
    local threat = 0
    
    -- Fatores de ameaça
    threat = threat + (humanoid.MaxHealth / 100)
    threat = threat + (humanoid.WalkSpeed / 5)
    
    -- Verificar se é boss
    if enemy:FindFirstChild("Boss") then
        threat = threat * 3
    end
    
    return math.min(threat, 100)
end

-- Calcular valor do item
function IASystem:CalculateValue(item)
    local value = 100
    
    -- Verificar tipo de item
    if item:FindFirstChild("Fruit") then
        value = value * 10
    elseif item:FindFirstChild("Money") then
        value = value * 5
    end
    
    -- Verificar raridade
    if item:FindFirstChild("Rarity") then
        local rarity = item.Rarity.Value
        if rarity == "Legendary" then
            value = value * 5
        elseif rarity == "Epic" then
            value = value * 3
        end
    end
    
    return value
end

-- Determinar tipo de jogo baseado na análise
function IASystem:DetermineGameType(analysis)
    local enemyCount = #analysis.Enemies
    local collectibleCount = #analysis.Collectibles
    local interactiveCount = #analysis.Interactive
    
    -- Lógica para determinar tipo de jogo
    if enemyCount > 10 and collectibleCount > 5 then
        return "ActionRPG"
    elseif enemyCount > 5 then
        return "Combat"
    elseif collectibleCount > 10 then
        return "Collector"
    elseif interactiveCount > 5 then
        return "Adventure"
    else
        return "Generic"
    end
end

-- Gerar recomendações personalizadas
function IASystem:GenerateRecommendations(analysis)
    local recommendations = {}
    
    -- Recomendações baseadas no tipo de jogo
    if analysis.GameType == "ActionRPG" then
        -- Jogo de ação: priorizar inimigos
        if #analysis.Enemies > 0 then
            local closestEnemy = self:FindClosest(analysis.Enemies)
            if closestEnemy.Distance <= CONFIG.AttackRange then
                table.insert(recommendations, {
                    Type = "Attack",
                    Target = closestEnemy,
                    Priority = 100 - closestEnemy.Distance
                })
            end
        end
        
        -- Coletar items próximos
        if #analysis.Collectibles > 0 then
            local closestItem = self:FindClosest(analysis.Collectibles)
            if closestItem.Distance <= CONFIG.CollectRange then
                table.insert(recommendations, {
                    Type = "Collect",
                    Target = closestItem,
                    Priority = 80 - closestItem.Distance
                })
            end
        end
        
    elseif analysis.GameType == "Collector" then
        -- Jogo de coleta: priorizar items
        if #analysis.Collectibles > 0 then
            local closestItem = self:FindClosest(analysis.Collectibles)
            table.insert(recommendations, {
                Type = "Collect",
                Target = closestItem,
                Priority = 100 - closestItem.Distance
            })
        end
    end
    
    -- Ordenar por prioridade
    table.sort(recommendations, function(a, b)
        return a.Priority > b.Priority
    end)
    
    return recommendations
end

-- Encontrar objeto mais próximo
function IASystem:FindClosest(objects)
    local closest = nil
    local minDistance = math.huge
    
    for _, obj in pairs(objects) do
        if obj.Distance < minDistance then
            minDistance = obj.Distance
            closest = obj
        end
    end
    
    return closest or {Distance = math.huge}
end

-- Aprender com os padrões
function IASystem:LearnPatterns(analysis)
    -- Atualizar banco de dados de padrões
    GamePatterns.Enemies = analysis.Enemies
    GamePatterns.Fruits = analysis.Collectibles
    GamePatterns.Items = analysis.Interactive
    GamePatterns.LastUpdate = analysis.Timestamp
    
    -- Ajustar configurações automaticamente
    self:AdaptConfiguration(analysis)
end

-- Adaptar configurações baseado na análise
function IASystem:AdaptConfiguration(analysis)
    if CONFIG.AdaptivityLevel < 3 then return end -- Nível de adaptação
    
    -- Ajustar range de ataque baseado em inimigos comuns
    if #analysis.Enemies > 0 then
        local avgDistance = 0
        for _, enemy in pairs(analysis.Enemies) do
            avgDistance = avgDistance + enemy.Distance
        end
        avgDistance = avgDistance / #analysis.Enemies
        
        -- Ajustar range de ataque
        CONFIG.AttackRange = math.max(20, math.min(50, avgDistance * 1.5))
    end
    
    -- Ajustar range de coleta
    if #analysis.Collectibles > 0 then
        local avgDistance = 0
        for _, item in pairs(analysis.Collectibles) do
            avgDistance = avgDistance + item.Distance
        end
        avgDistance = avgDistance / #analysis.Collectibles
        
        CONFIG.CollectRange = math.max(30, math.min(100, avgDistance * 2))
    end
end

-- Executar ações baseadas nas recomendações
function IASystem:ExecuteRecommendations(analysis)
    for _, recommendation in pairs(analysis.Recommendations) do
        if recommendation.Type == "Attack" then
            self:AttackEnemy(recommendation.Target)
        elseif recommendation.Type == "Collect" then
            self:CollectItem(recommendation.Target)
        end
    end
end

-- Atacar inimigo
function IASystem:AttackEnemy(enemy)
    if not enemy or not enemy.Model then return end
    
    -- Mover para o inimigo
    humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, enemy.Position)
    
    -- Atacar via RemoteEvents
    local attackRemote = ReplicatedStorage:FindRemoteEvent("Attack")
    if attackRemote then
        attackRemote:FireServer(enemy.Position)
    end
    
    -- Usar habilidades se disponíveis
    local useSkillRemote = ReplicatedStorage:FindRemoteEvent("UseSkill")
    if useSkillRemote then
        useSkillRemote:FireServer("BasicAttack")
    end
end

-- Coletar item
function IASystem:CollectItem(item)
    if not item or not item.Model then return end
    
    -- Mover para o item
    humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, item.Position)
    
    -- Coletar via RemoteEvents
    local clickRemote = ReplicatedStorage:FindRemoteEvent("ClickFruit")
    if clickRemote then
        clickRemote:FireServer(item.Position)
    end
    
    -- Alternar para ClickDetector se disponível
    local clickDetector = item.Model:FindFirstChild("ClickDetector")
    if clickDetector then
        fireclickdetector(clickDetector)
    end
end

-- Loop principal da IA
local function IALoop()
    if not CONFIG.IAEnabled then return end
    
    spawn(function()
        while CONFIG.IAEnabled do
            local success, error = pcall(function()
                -- Analisar o jogo
                local analysis = IASystem:AnalyzeGame()
                
                -- Executar recomendações
                IASystem:ExecuteRecommendations(analysis)
                
                -- Atualizar GUI
                if GUISystem then
                    GUISystem:UpdateAnalysis(analysis)
                end
                
                -- Ajustar delay baseado na adaptação
                local delay = CONFIG.FarmDelay
                if CONFIG.AdaptivityLevel >= 4 then
                    -- Delay dinâmico baseado na atividade
                    delay = math.max(0.1, CONFIG.FarmDelay - (#analysis.Enemies * 0.05))
                end
                
                wait(delay)
            end)
            
            if not success then
                print("Erro na IA: " .. error)
                wait(1) -- Pausa em caso de erro
            end
        end
    end)
end

-- Sistema de Interface Gráfica (GUI)
local GUISystem = {}

function GUISystem:CreateGUI()
    if not CONFIG.ShowGUI then return end
    
    -- Remover GUI existente
    local existingGUI = player.PlayerGui:FindFirstChild("UniversalIAGUI")
    if existingGUI then existingGUI:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UniversalIAGUI"
    screenGui.Parent = player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.backgroundColor3 = self:GetThemeColor("Background")
    mainFrame.Parent = screenGui
    
    -- Borda
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Color = self:GetThemeColor("Accent")
    stroke.Parent = mainFrame
    
    -- Título
    local title = Instance.new("TextButton")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "🤖 IA UNIVERSAL ADAPTATIVA"
    title.TextColor3 = self:GetThemeColor("Text")
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.BackgroundTransparency = 0.3
    title.backgroundColor3 = self:GetThemeColor("Primary")
    title.Parent = mainFrame
    
    -- Status da IA
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 40)
    statusFrame.Position = UDim2.new(0, 0, 0, 50)
    statusFrame.BackgroundTransparency = 0.8
    statusFrame.backgroundColor3 = self:GetThemeColor("Secondary")
    statusFrame.Parent = mainFrame
    
    local statusText = Instance.new("TextButton")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.Text = "IA: Ativada | Tipo: Desconhecido"
    statusText.TextColor3 = self:GetThemeColor("Text")
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 14
    statusText.BackgroundTransparency = 1
    statusText.Parent = statusFrame
    
    -- Área de análise em tempo real
    local analysisFrame = Instance.new("ScrollingFrame")
    analysisFrame.Name = "AnalysisFrame"
    analysisFrame.Size = UDim2.new(0.95, 0, 0, 200)
    analysisFrame.Position = UDim2.new(0.025, 0, 0.15, 0)
    analysisFrame.BackgroundTransparency = 0.8
    analysisFrame.backgroundColor3 = Color3.fromRGB(30, 30, 30)
    analysisFrame.Parent = mainFrame
    
    local analysisLayout = Instance.new("UIListLayout")
    analysisLayout.Name = "AnalysisLayout"
    analysisLayout.Parent = analysisFrame
    analysisLayout.Padding = UDim2.new(0, 5, 0, 5)
    
    -- Labels para análise
    local gameTypeLabel = Instance.new("TextButton")
    gameTypeLabel.Name = "GameTypeLabel"
    gameTypeLabel.Size = UDim2.new(1, 0, 0, 30)
    gameTypeLabel.Text = "Tipo de Jogo: Analisando..."
    gameTypeLabel.TextColor3 = self:GetThemeColor("Text")
    gameTypeLabel.Font = Enum.Font.Gotham
    gameTypeLabel.TextSize = 16
    gameTypeLabel.BackgroundTransparency = 0.5
    gameTypeLabel.backgroundColor3 = self:GetThemeColor("Accent")
    gameTypeLabel.Parent = analysisFrame
    
    local enemiesLabel = Instance.new("TextButton")
    enemiesLabel.Name = "EnemiesLabel"
    enemiesLabel.Size = UDim2.new(1, 0, 0, 25)
    enemiesLabel.Text = "Inimigos: 0"
    enemiesLabel.TextColor3 = self:GetThemeColor("Text")
    enemiesLabel.Font = Enum.Font.Gotham
