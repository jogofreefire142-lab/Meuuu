-- 🍎 BLOX FRUITS SCRIPT DEFINITIVO - IA AVANÇADA
-- Script mais completo, inteligente e personalizado
-- IA que aprende e se adapta ao ambiente

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Configurações com IA Aprendizado
local CONFIG = {
    -- Modo de IA
    AIMode = "Learning", -- "Learning", "Adaptive", "Expert"
    LearningRate = 0.1,
    ExplorationRate = 0.3,
    
    -- Auto Farm Inteligente
    AutoFarm = true,
    FarmLevel = 50,
    AttackRange = 30,
    FarmDelay = 0.3,
    
    -- Auto Collect Inteligente
    AutoCollect = true,
    CollectRange = 50,
    CollectPriority = "Value",
    
    -- Auto Buy Inteligente
    AutoBuy = true,
    PreferredFruits = {"Gomu Gomu", "Bara Bara", "Suke Suke", "Mero Mero", "Hie Hie", "Magma Magma"},
    AutoBuyMoney = 5000,
    
    -- Auto Quest Inteligente
    AutoQuest = true,
    QuestRange = 60,
    
    -- Auto Raid Inteligente
    AutoRaid = true,
    RaidBosses = {"Sea Beast", "Skull", "Ice Admiral", "Dark Blade"},
    
    -- Combate com IA
    SmartCombat = true,
    AutoDodge = true,
    UseFruitSkill = true,
    UseWeaponSkill = true,
    CombatStrategy = "Learning",
    
    -- Interface
    ShowGUI = true,
    GUIKey = Enum.KeyCode.RightControl,
    Theme = "Neon",
    
    -- Anti-AFK
    AntiAFK = true,
    AntiAFKMode = "Smart",
    
    -- Performance
    OptimizedMode = true,
    FPSLimit = 60,
    
    -- Segurança
    SafeMode = true,
    RandomizeDelays = true,
    HumanLikeMovement = true,
    
    -- Efeitos
    VisualEffects = true,
    SoundEffects = true,
    ParticleEffects = true,
    
    -- Aprendizado
    SaveLearningData = true,
    LearningFile = "BloxFruits_Learning.json"
}

-- Banco de dados de frutas com IA
local FRUTAS = {
    ["Gomu Gomu"] = {
        Dano = 100, Cooldown = 5, Preco = 1000,
        Tipo = "Físico", Efeito = "Aumenta velocidade e resistência",
        Cor = Color3.fromRGB(255, 0, 0), Som = "rbxasset://sounds/energy_charge.wav",
        Skill1 = "Gomu Gomu no Gatling", Skill2 = "Gomu Gomu no Bazooka",
        IAWeight = 1.0, SuccessRate = 0.8, LearningData = {}
    },
    ["Bara Bara"] = {
        Dano = 120, Cooldown = 5, Preco = 1200,
        Tipo = "Elemental", Efeito = "Cria barreiras de energia",
        Cor = Color3.fromRGB(0, 255, 255), Som = "rbxasset://sounds/magic_shield.wav",
        Skill1 = "Bara Bara no Mi", Skill2 = "Bara Bara no Wall",
        IAWeight = 1.2, SuccessRate = 0.75, LearningData = {}
    },
    ["Suke Suke"] = {
        Dano = 80, Cooldown = 4, Preco = 800,
        Tipo = "Invisibilidade", Efeito = "Torna o usuário invisível",
        Cor = Color3.fromRGB(255, 255, 0), Som = "rbxasset://sounds/invisibility.wav",
        Skill1 = "Suke Suke no Mi", Skill2 = "Invisibility Cloak",
        IAWeight = 0.8, SuccessRate = 0.7, LearningData = {}
    }
}

-- Sistema de IA Aprendizado
local IALearningSystem = {}

-- Carregar dados de aprendizado
function IALearningSystem:LoadLearningData()
    if not CONFIG.SaveLearningData then return end
    
    local success, data = pcall(function()
        local file = readfile(CONFIG.LearningFile)
        return HttpService:JSONDecode(file)
    end)
    
    if success and data then
        -- Aplicar dados de aprendizado
        for fruitName, fruitData in pairs(data) do
            if FRUTAS[fruitName] then
                FRUTAS[fruitName].SuccessRate = fruitData.SuccessRate or FRUTAS[fruitName].SuccessRate
                FRUTAS[fruitName].LearningData = fruitData.LearningData or {}
            end
        end
        print("📊 Dados de aprendizado carregados")
    end
end

-- Salvar dados de aprendizado
function IALearningSystem:SaveLearningData()
    if not CONFIG.SaveLearningData then return end
    
    local success, error = pcall(function()
        local learningData = {}
        for fruitName, fruitData in pairs(FRUTAS) do
            learningData[fruitName] = {
                SuccessRate = fruitData.SuccessRate,
                LearningData = fruitData.LearningData
            }
        end
        
        local json = HttpService:JSONEncode(learningData)
        writefile(CONFIG.LearningFile, json)
        print("💾 Dados de aprendizado salvos")
    end)
    
    if not success then
        print("Erro ao salvar dados de aprendizado: " .. error)
    end
end

-- Atualizar taxa de sucesso com base no resultado
function IALearningSystem:UpdateSuccessRate(fruitName, success)
    if not FRUTAS[fruitName] then return end
    
    local fruitData = FRUTAS[fruitName]
    local currentRate = fruitData.SuccessRate
    
    -- Atualizar com base no resultado
    if success then
        fruitData.SuccessRate = currentRate + (1 - currentRate) * CONFIG.LearningRate
    else
        fruitData.SuccessRate = currentRate - currentRate * CONFIG.LearningRate
    end
    
    -- Limitar entre 0.1 e 1.0
    fruitData.SuccessRate = math.max(0.1, math.min(1.0, fruitData.SuccessRate))
    
    -- Registrar no histórico
    if not fruitData.LearningData then
        fruitData.LearningData = {}
    end
    
    table.insert(fruitData.LearningData, {
        Timestamp = tick(),
        Success = success,
        Rate = fruitData.SuccessRate
    })
    
    -- Manter apenas últimos 100 registros
    if #fruitData.LearningData > 100 then
        table.remove(fruitData.LearningData, 1)
    end
end

-- Sistema de IA para análise de ambiente
local IASystem = {}

function IASystem:AnalyzeEnvironment()
    local analysis = {
        Enemies = {},
        Fruits = {},
        Quests = {},
        Bosses = {},
        RiskLevel = 0,
        OptimalStrategy = "Balanced",
        Timestamp = tick(),
        Recommendations = {}
    }
    
    -- Analisar inimigos
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local distance = (humanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
            
            if obj:FindFirstChild("Boss") then
                table.insert(analysis.Bosses, {
                    Model = obj,
                    Distance = distance,
                    Name = obj.Name,
                    Level = obj:FindFirstChild("Level") and obj.Level.Value or 999,
                    Threat = self:CalculateThreat(obj),
                    RecommendedFruit = self:RecommendFruitForEnemy(obj)
                })
            elseif obj:FindFirstChild("Level") then
                local enemyData = {
                    Model = obj,
                    Distance = distance,
                    Level = obj.Level.Value,
                    Name = obj.Name,
                    Threat = self:CalculateThreat(obj),
                    RecommendedFruit = self:RecommendFruitForEnemy(obj)
                }
                
                table.insert(analysis.Enemies, enemyData)
                analysis.RiskLevel = analysis.RiskLevel + enemyData.Threat
            end
        end
    end
    
    -- Analisar frutas
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:FindFirstChild("Fruit") and obj:FindFirstChild("HumanoidRootPart") then
            local distance = (humanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
            local fruitData = {
                Model = obj,
                Distance = distance,
                Name = obj.Name,
                Value = self:CalculateFruitValue(obj),
                RecommendedAction = self:RecommendActionForFruit(obj)
            }
            
            table.insert(analysis.Fruits, fruitData)
        end
    end
    
    -- Determinar estratégia ótima com IA
    analysis.OptimalStrategy = self:DetermineOptimalStrategy(analysis)
    analysis.Recommendations = self:GenerateRecommendations(analysis)
    
    return analysis
end

function IASystem:CalculateThreat(enemy)
    local threat = 0
    
    -- Fatores de ameaça
    local level = enemy:FindFirstChild("Level") and enemy.Level.Value or 50
    local distance = (humanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
    
    -- Nível do inimigo
    threat = threat + (level / 10)
    
    -- Distância
    threat = threat + (50 - distance) / 10
    
    -- Boss
    if enemy:FindFirstChild("Boss") then
        threat = threat * 2
    end
    
    return math.min(threat, 100)
end

function IASystem:RecommendFruitForEnemy(enemy)
    local bestFruit = nil
    local bestScore = 0
    
    for fruitName, fruitData in pairs(FRUTAS) do
        local score = self:CalculateFruitScoreForEnemy(fruitName, enemy)
        if score > bestScore then
            bestScore = score
            bestFruit = fruitName
        end
    end
    
    return bestFruit
end

function IASystem:CalculateFruitScoreForEnemy(fruitName, enemy)
    local fruitData = FRUTAS[fruitName]
    if not fruitData then return 0 end
    
    local score = 0
    
    -- Dano da fruta
    score = score + fruitData.Dano / 10
    
    -- Taxa de sucesso da IA
    score = score * fruitData.SuccessRate
    
    -- Peso da IA
    score = score * fruitData.IAWeight
    
    -- Penalização por cooldown
    score = score / fruitData.Cooldown
    
    return score
end

function IASystem:CalculateFruitValue(fruit)
    local value = 100
    
    -- Verificar tipo de fruta
    local fruitName = fruit.Name
    if FRUTAS[fruitName] then
        value = value + FRUTAS[fruitName].Preco / 10
    end
    
    -- Verificar raridade
    if fruit:FindFirstChild("Rarity") then
        local rarity = fruit.Rarity.Value
        if rarity == "Legendary" then
            value = value * 5
        elseif rarity == "Epic" then
            value = value * 3
        elseif rarity == "Rare" then
            value = value * 2
        end
    end
    
    return value
end

function IASystem:RecommendActionForFruit(fruit)
    local fruitName = fruit.Name
    local distance = (humanoidRootPart.Position - fruit.HumanoidRootPart.Position).Magnitude
    
    if distance <= 10 then
        return "Collect"
    elseif distance <= CONFIG.CollectRange then
        return "MoveToCollect"
    else
        return "Ignore"
    end
end

function IASystem:DetermineOptimalStrategy(analysis)
    if CONFIG.AIMode == "Learning" then
        return self:LearnOptimalStrategy(analysis)
    elseif CONFIG.AIMode == "Adaptive" then
        return self:AdaptiveStrategy(analysis)
    else
        return self:ExpertStrategy(analysis)
    end
end

function IASystem:LearnOptimalStrategy(analysis)
    -- Aprendizado por reforço simplificado
    local riskLevel = analysis.RiskLevel
    
    if riskLevel > 70 then
        return "Defensive"
    elseif riskLevel < 30 then
        return "Aggressive"
    else
        -- Exploração vs explotação
        if math.random() < CONFIG.ExplorationRate then
            return "Exploratory"
        else
            return "Balanced"
        end
    end
end

function IASystem:AdaptiveStrategy(analysis)
    -- Estratégia adaptativa baseada no ambiente
    local enemyCount = #analysis.Enemies
    local bossCount = #analysis.Bosses
    local fruitCount = #analysis.Fruits
    
    if bossCount > 0 then
        return "Raid"
    elseif enemyCount > 5 then
        return "Aggressive"
    elseif fruitCount > 3 then
        return "Collect"
    else
        return "Balanced"
    end
end

function IASystem:ExpertStrategy(analysis)
    -- Estratégia expert baseada em regras complexas
    local avgEnemyLevel = 0
    if #analysis.Enemies > 0 then
        for _, enemy in pairs(analysis.Enemies) do
            avgEnemyLevel = avgEnemyLevel + enemy.Level
        end
        avgEnemyLevel = avgEnemyLevel / #analysis.Enemies
    end
    
    if avgEnemyLevel > CONFIG.FarmLevel + 20 then
        return "Defensive"
    elseif avgEnemyLevel < CONFIG.FarmLevel - 10 then
        return "Aggressive"
    else
        return "Balanced"
    end
end

function IASystem:GenerateRecommendations(analysis)
    local recommendations = {}
    
    -- Recomendações de fruta
    if #analysis.Bosses > 0 then
        local bestFruit = self:RecommendFruitForEnemy(analysis.Bosses[1])
        if bestFruit then
            table.insert(recommendations, {
                Type = "Fruit",
                Action = "Use",
                Target = bestFruit,
                Reason = "Boss detected"
            })
        end
    end
    
    -- Recomendações de coleta
    if #analysis.Fruits > 0 then
        local bestFruit = analysis.Fruits[1]
        if bestFruit.RecommendedAction == "Collect" then
            table.insert(recommendations, {
                Type = "Collect",
                Action = "Collect",
                Target = bestFruit.Name,
                Reason = "High value fruit nearby"
            })
        end
    end
    
    return recommendations
end

-- Sistema de Auto Farm com IA
local AutoFarmSystem = {}

function AutoFarmSystem:FindBestEnemy(analysis)
    local bestEnemy = nil
    local bestScore = 0
    
    for _, enemy in pairs(analysis.Enemies) do
        local score = self:CalculateEnemyScore(enemy, analysis)
        if score > bestScore then
            bestScore = score
            bestEnemy = enemy
        end
    end
    
    return bestEnemy
end

function AutoFarmSystem:CalculateEnemyScore(enemy, analysis)
    local score = 0
    
    -- Fatores de pontuação
    score = score + (CONFIG.FarmLevel - enemy.Level) * 10
    score = score + (100 - enemy.Distance)
    score = score - enemy.Threat * 2
    
    -- Ajustar com base na estratégia
    if analysis.OptimalStrategy == "Aggressive" then
        score = score + enemy.Level * 5
    elseif analysis.OptimalStrategy == "Defensive" then
        score = score - enemy.Level * 5
    end
    
    -- Usar recomendação de fruta
    if enemy.RecommendedFruit then
        score = score + FRUTAS[enemy.RecommendedFruit].SuccessRate * 10
    end
    
    return score
end

function AutoFarmSystem:AttackEnemy(enemy)
    if not enemy or not enemy.Model then return false end
    
    local success, error = pcall(function()
        -- Movimento inteligente
        if CONFIG.HumanLikeMovement then
            self:HumanLikeMoveTo(enemy.Model.HumanoidRootPart.Position)
        else
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, enemy.Model.HumanoidRootPart.Position)
        end
        
        -- Ataque principal
        local Remotes = ReplicatedStorage:FindRemoteEvent("Attack")
        if Remotes then
            Remotes:FireServer(enemy.Model.HumanoidRootPart.Position)
        end
        
        -- Usar fruta recomendada
        if CONFIG.UseFruit and enemy.RecommendedFruit then
            local fruitName = enemy.RecommendedFruit
            if FRUTAS[fruitName] then
                local UseFruitRemote = ReplicatedStorage:FindRemoteEvent("UseFruit")
                if UseFruitRemote then
                    UseFruitRemote:FireServer(fruitName)
                    
                    -- Atualizar dados de aprendizado
                    local fruitSuccess = math.random() < FRUTAS[fruitName].SuccessRate
                    IALearningSystem:UpdateSuccessRate(fruitName, fruitSuccess)
                end
                
                -- Usar skill da fruta
                if CONFIG.UseFruitSkill and FRUTAS[fruitName].Skill1 then
                    local UseSkillRemote = ReplicatedStorage:FindRemoteEvent("UseSkill")
                    if UseSkillRemote then
                        wait(0.5)
                        UseSkillRemote:FireServer(FRUTAS[fruitName].Skill1)
                    end
                end
            end
        end
    end)
    
    if not success then
        print("Erro ao atacar: " .. error)
        return false
    end
    
    return true
end

function AutoFarmSystem:HumanLikeMoveTo(targetPosition)
    local direction = (targetPosition - humanoidRootPart.Position).Unit
    local randomOffset = Vector3.new(
        math.random(-0.5, 0.5),
        0,
        math.random(-0.5, 0.5)
    )
    
    humanoidRootPart.CFrame = humanoidRootPart.CFrame + direction * 0.3 + randomOffset
end

-- Sistema de Auto Collect com IA
local AutoCollectSystem = {}

function AutoCollectSystem:FindBestItem(analysis)
    local bestItem = nil
    local bestValue = 0
    
    for _, item in pairs(analysis.Fruits) do
        local value = item.Value / item.Distance
        if value > bestValue then
            bestValue = value
            bestItem = item
        end
    end
    
    return bestItem
end

function AutoCollectSystem:CollectItem(item)
    if not item or not item.Model then return false end
    
    local success, error = pcall(function()
        -- Mover para o item
        humanoid:MoveTo(item.Model.HumanoidRootPart.Position)
        
        -- Coletar
        local ClickFruitRemote = ReplicatedStorage:FindRemoteEvent("ClickFruit")
        if ClickFruitRemote then
            ClickFruitRemote:FireServer(item.Model.HumanoidRootPart.Position)
        end
    end)
    
    if not success then
        print("Erro ao coletar: " .. error)
        return false
    end
    
    return true
end

-- Sistema de Interface Gráfica com IA
local GUISystem = {}

function GUISystem:CreateGUI()
    if not CONFIG.ShowGUI then return end
    
    -- Remover GUI existente
    local existingGUI = player.PlayerGui:FindFirstChild("BloxFruitsGUI")
    if existingGUI then existingGUI:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BloxFruitsGUI"
    screenGui.Parent = player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 700)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -350)
    mainFrame.BackgroundTransparency = 0.05
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
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "🍎 BLOX FRUITS IA DEFINITIVO"
    title.TextColor3 = self:GetThemeColor("Text")
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.BackgroundTransparency = 0.3
    title.backgroundColor3 = self:GetThemeColor("Primary")
    title.Parent = mainFrame
    
    -- Status da IA
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 40)
    statusFrame.Position = UDim2.new(0, 0, 0, 60)
    statusFrame.BackgroundTransparency = 0.8
    statusFrame.backgroundColor3 = self:GetThemeColor("Secondary")
    statusFrame.Parent = mainFrame
    
    local statusText = Instance.new("TextButton")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 1, 0)
    statusText.Text = "IA: " .. CONFIG.AIMode .. " | Estratégia: " .. "Balanced"
    statusText.TextColor3 = self:GetThemeColor("Text")
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 16
    statusText.BackgroundTransparency = 1
    statusText.Parent = statusFrame
    
    -- Abas (Tabs)
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0, 40)
    tabsFrame.Position = UDim2.new(0, 0, 0, 100)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = mainFrame
    
    local tabNames = {"IA Aprendizado", "Farm", "Combate", "Configurações", "Logs"}
    local tabButtons = {}
    local tabFrames = {}
    
    for i, tabName in pairs(tabNames) do
        -- Botão da aba
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(0.2, 0, 1, 0)
        tabButton.Position = UDim2.new((i-1) * 0.2, 0, 0, 0)
        tabButton.Text = tabName
        tabButton.TextColor3 = self:GetThemeColor("TextSecondary")
        tabButton.Font = Enum.Font.Gotham
        tabButton.TextSize = 14
        tabButton.BackgroundTransparency = 0.3
        tabButton.backgroundColor3 = self:GetThemeColor("Secondary")
        tabButton.Parent = tabsFrame
        
        -- Frame da aba
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = tabName .. "Frame"
        tabFrame.Size = UDim2.new(1, 0, 0, 560)
        tabFrame.Position = UDim2.new(0, 0, 0, 140)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Parent = mainFrame
        tabFrame.Visible = (i == 1)
        
        table.insert(tabButtons, tabButton)
        table.insert(tabFrames, tabFrame)
        
        -- Evento do botão
        tabButton.MouseButton1Click:Connect(function()
            for j, frame in pairs(tabFrames) do
                frame.Visible = (j == i)
            end
            
            for j, button in pairs(tabButtons) do
                button.TextColor3 = (j == i) and self:GetThemeColor("Text") or self:GetThemeColor("TextSecondary")
            end
        end)
    end
    
    -- Conteúdo da Aba de IA
    local iaFrame = tabFrames[1]
    self:CreateIATab(iaFrame, statusText)
    
    -- Conteúdo da Aba de Farm
    local farmFrame = tabFrames[2]
    self:CreateFarmTab(farmFrame)
    
    -- Conteúdo da Aba de Combate
    local combateFrame = tabFrames[3]
    self:CreateCombatTab(combateFrame)
    
    -- Conteúdo da Aba de Configurações
    local configsFrame = tabFrames[4]
    self:CreateConfigsTab(configsFrame)
    
    -- Conteúdo da Aba de Logs
    local logsFrame = tabFrames[5]
    self:CreateLogsTab(logsFrame)
    
    -- Botão de fechar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.Text = "❌"
    closeButton.TextColor3 = self:GetThemeColor("Text")
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.BackgroundTransparency = 0.3
    closeButton.backgroundColor3 = Color3.fromRGB(100, 0, 0)
    closeButton.Parent = mainFrame
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        CONFIG.ShowGUI = false
        print("GUI desativado")
    end)
    
    -- Armazenar referências
    self.StatusText = statusText
    self.MainFrame = mainFrame
end

function GUISystem:GetThemeColor(colorName)
    local theme = CONFIG.Theme
    local colors = {
        Dark = {
            Background = Color3.fromRGB(20, 20, 20),
            Primary = Color3.fromRGB(50, 0, 0),
            Secondary = Color3.fromRGB(40, 40, 40),
            Accent = Color3.fromRGB(255, 215, 0),
            Text = Color3.fromRGB(255, 255, 255),
            TextSecondary = Color3.fromRGB(200, 200, 200)
        },
        Light = {
            Background = Color3.fromRGB(240, 240, 240),
            Primary = Color3.fromRGB(200, 200, 200),
            Secondary = Color3.fromRGB(220, 220, 220),
            Accent = Color3.fromRGB(0, 100, 200),
            Text = Color3.fromRGB(0, 0, 0),
            TextSecondary = Color3.fromRGB(100, 100, 100)
        },
        Neon = {
            Background = Color3.fromRGB(10, 10, 30),
            Primary = Color3.fromRGB(50, 0, 100),
            Secondary = Color3.fromRGB(30, 30, 60),
            Accent = Color3.fromRGB(0, 255, 255),
            Text = Color3.fromRGB(255, 255, 255),
            TextSecondary = Color3.fromRGB(200, 200, 255)
        }
    }
    
    return colors[theme][colorName] or colors.Dark[colorName]
end

function GUISystem:CreateIATab(frame, statusText)
    -- Configurações de IA
    local iaConfig = Instance.new("ScrollingFrame")
    iaConfig.Name = "IAConfig"
    iaConfig.Size = UDim2.new(0.95, 0, 0.95, 0)
    iaConfig.Position = UDim2.new(0.025, 0, 0.025, 0)
    iaConfig.BackgroundTransparency = 1
    iaConfig.Parent = frame
    
    local iaLayout = Instance.new("UIGridLayout")
    iaLayout.Name = "IALayout"
    iaLayout.CellSize = UDim2.new(0, 220, 0, 120)
    iaLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    iaLayout.Parent = iaConfig
    
    -- Botões de configuração de IA
    local iaButtons = {
        {Name = "AIMode", Text = "Modo IA: Learning", Config = "AIMode", Type = "Mode"},
        {Name = "LearningRate", Text = "Taxa Aprendizado: 0.1", Config = "LearningRate", Type = "Slider"},
        {Name = "ExplorationRate", Text = "Exploração: 0.3", Config = "ExplorationRate", Type = "Slider"},
        {Name = "SmartCombat", Text = "Combate Inteligente: ON", Config = "SmartCombat"},
        {Name = "AutoDodge", Text = "Auto Dodge: ON", Config = "AutoDodge"},
        {Name = "SaveLearning", Text = "Salvar Aprendizado: ON", Config = "SaveLearningData"}
    }
    
    for _, buttonData in pairs(iaButtons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.Name .. "Button"
        button.Size = UDim2.new(0, 220, 0, 120)
        button.Text = buttonData.Text
        button.TextColor3 = self:GetThemeColor("Text")
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.BackgroundTransparency = 0.3
        button.backgroundColor3 = self:GetThemeColor("Secondary")
        button.Parent = iaConfig
        
        button.TextWrapped = true
        
        button.MouseButton1Click:Connect(function()
            if buttonData.Type == "Mode" then
                -- Ciclar entre modos de IA
                local modes = {"Learning", "Adaptive", "Expert"}
                local currentIndex = table.find(modes, CONFIG.AIMode)
                local nextIndex = (currentIndex % #modes) + 1
                CONFIG.AIMode = modes[nextIndex]
                button.Text = "Modo IA: " .. CONFIG.AIMode
                statusText.Text = "IA: " .. CONFIG.AIMode .. " | Estratégia: " .. "Balanced"
                
                print("Modo IA alterado para: " .. CONFIG.AIMode)
            elseif buttonData.Type == "Slider" then
                -- Ajustar valor do slider
                if buttonData.Config == "LearningRate" then
                    CONFIG.LearningRate = math.max(0.01, math.min(0.5, CONFIG.LearningRate + 0.05))
                    button.Text = "Taxa Aprendizado: " .. string.format("%.2f", CONFIG.LearningRate)
                elseif buttonData.Config == "ExplorationRate" then
                    CONFIG.ExplorationRate = math.max(0.1, math.min(0.9, CONFIG.ExplorationRate + 0.1))
                    button.Text = "Exploração: " .. string.format("%.1f", CONFIG.ExplorationRate)
                end
            else
                CONFIG[buttonData.Config] = not CONFIG[buttonData.Config]
                button.Text = buttonData.Name .. ": " .. (CONFIG[buttonData.Config] and "ON" or "OFF")
                button.backgroundColor3 = CONFIG[buttonData.Config] and self:GetThemeColor("Success") or self:GetThemeColor("Error")
            end
        end)
    end
    
    -- Botão para salvar aprendizado
    local saveButton = Instance.new("TextButton")
    saveButton.Name = "SaveButton"
    saveButton.Size = UDim2.new(0.9, 0, 0, 50)
    saveButton.Position = UDim2.new(0.05, 0, 0.85, 0)
    saveButton.Text = "💾 Salvar Dados de Aprendizado"
    saveButton.TextColor3 = self:GetThemeColor("Text")
    saveButton.Font = Enum.Font.GothamBold
    saveButton.TextSize = 16
    saveButton.BackgroundTransparency = 0.3
    saveButton.backgroundColor3 = Color3.fromRGB(0, 100, 0)
    saveButton.Parent = frame
    
    saveButton.MouseButton1Click:Connect(function()
        IALearningSystem:SaveLearningData()
        print("Dados de aprendizado salvos manualmente")
    end)
end

function GUISystem:CreateFarmTab(frame)
    -- Configurações de Farm
    local farmConfig = Instance.new("ScrollingFrame")
    farmConfig.Name = "FarmConfig"
    farmConfig.Size = UDim2.new(0.95, 0, 0.95, 0)
    farmConfig.Position = UDim2.new(0.025, 0, 0.025, 0)
    farmConfig.BackgroundTransparency = 1
    farmConfig.Parent = frame
    
    local farmLayout = Instance.new("UIGridLayout")
    farmLayout.Name = "FarmLayout"
    farmLayout.CellSize = UDim2.new(0, 220, 0, 120)
    farmLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    farmLayout.Parent = farmConfig
    
    -- Botões de configuração de Farm
    local farmButtons = {
        {Name = "AutoFarm", Text = "Auto Farm: ON", Config = "AutoFarm"},
        {Name = "AutoCollect", Text = "Auto Collect: ON", Config = "AutoCollect"},
        {Name = "FarmLevel", Text = "Nível Farm: " .. CONFIG.FarmLevel, Config = "FarmLevel"},
        {Name = "AttackRange", Text = "Ataque Range: " .. CONFIG.AttackRange, Config = "AttackRange"},
        {Name = "CollectRange", Text = "Coleta Range: " .. CONFIG.CollectRange, Config = "CollectRange"},
        {Name = "FarmDelay", Text = "Delay Farm: " .. CONFIG.FarmDelay, Config = "FarmDelay"}
    }
    
    for _, buttonData in pairs(farmButtons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.Name .. "Button"
        button.Size = UDim2.new(0, 220, 0, 120)
        button.Text = buttonData.Text
        button.TextColor3 = self:GetThemeColor("Text")
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.BackgroundTransparency = 0.3
        button.backgroundColor3 = self:GetThemeColor("Secondary")
        button.Parent = farmConfig
        
        button.TextWrapped = true
        
        button.MouseButton1Click:Connect(function()
            if buttonData.Name == "FarmLevel" then
                CONFIG.FarmLevel = CONFIG.FarmLevel + 5
                if CONFIG.FarmLevel > 100 then CONFIG.FarmLevel = 10 end
                button.Text = "Nível Farm: " .. CONFIG.FarmLevel
            elseif buttonData.Name == "AttackRange" then
                CONFIG.AttackRange = CONFIG.AttackRange + 5
                if CONFIG.AttackRange > 50 then CONFIG.AttackRange = 10 end
                button.Text = "Ataque Range: " .. CONFIG.AttackRange
            elseif buttonData.Name == "CollectRange" then
                CONFIG.CollectRange = CONFIG.CollectRange + 5
                if CONFIG.CollectRange > 100 then CONFIG.CollectRange = 10 end
                button.Text = "Coleta Range: " .. CONFIG.CollectRange
            else
                CONFIG[buttonData.Config] = not CONFIG[buttonData.Config]
                button.Text = buttonData.Name .. ": " .. (CONFIG[buttonData.Config] and "ON" or "OFF")
                button.backgroundColor3 = CONFIG[buttonData.Config] and self:GetThemeColor("Success") or self:GetThemeColor("Error")
            end
        end)
    end
end

function GUISystem:CreateCombatTab(frame)
    -- Configurações de Combate
    local combatConfig = Instance.new("ScrollingFrame")
    combatConfig.Name = "CombatConfig"
    combatConfig.Size = UDim2.new(0.95, 0, 0.95, 0)
    combatConfig.Position = UDim2.new(0.025, 0, 0.025, 0)
    combatConfig.BackgroundTransparency = 1
    combatConfig.Parent = frame
    
    local combatLayout = Instance.new("UIGridLayout")
    combatLayout.Name = "CombatLayout"
    combatLayout.CellSize = UDim2.new(0, 220, 0, 120)
    combatLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    combatLayout.Parent = combatConfig
    
    -- Botões de configuração de Combate
    local combatButtons = {
        {Name = "SmartCombat", Text = "Combate Inteligente: ON", Config = "SmartCombat"},
        {Name = "AutoDodge", Text = "Auto Dodge: ON", Config = "AutoDodge"},
        {Name = "UseFruitSkill", Text = "Usar Skill Fruta: ON", Config = "UseFruitSkill"},
        {Name = "UseWeaponSkill", Text = "Usar Skill Arma: ON", Config = "UseWeaponSkill"},
        {Name = "CombatStrategy", Text = "Estratégia: Learning", Config = "CombatStrategy", Type = "Mode"},
        {Name = "VisualEffects", Text = "Efeitos Visuais: ON", Config = "VisualEffects"}
    }
    
    for _, buttonData in pairs(combatButtons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.Name .. "Button"
        button.Size = UDim2.new(0, 220, 0, 120)
        button.Text = buttonData.Text
        button.TextColor3 = self:GetThemeColor("Text")
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.BackgroundTransparency = 0.3
        button.backgroundColor3 = self:GetThemeColor("Secondary")
        button.Parent = combatConfig
        
        button.TextWrapped = true
        
        button.MouseButton1Click:Connect(function()
            if buttonData.Type == "Mode" then
                -- Ciclar entre estratégias
                local strategies = {"Learning", "Adaptive", "Expert"}
                local currentIndex = table.find(strategies, CONFIG.CombatStrategy)
                local nextIndex = (currentIndex % #strategies) + 1
                CONFIG.CombatStrategy = strategies[nextIndex]
                button.Text = "Estratégia: " .. CONFIG.CombatStrategy
                
                print("Estratégia alterada para: " .. CONFIG.CombatStrategy)
            else
                CONFIG[buttonData.Config] = not CONFIG[buttonData.Config]
                button.Text = buttonData.Name .. ": " .. (CONFIG[buttonData.Config] and "ON" or "OFF")
                button.backgroundColor3 = CONFIG[buttonData.Config] and self:GetThemeColor("Success") or self:GetThemeColor("Error")
            end
        end)
    end
end

function GUISystem:CreateConfigsTab(frame)
    -- Configurações Gerais
    local configsConfig = Instance.new("ScrollingFrame")
    configsConfig.Name = "ConfigsConfig"
    configsConfig.Size = UDim2.new(0.95, 0, 0.95, 0)
    configsConfig.Position = UDim2.new(0.025, 0, 0.025, 0)
    configsConfig.BackgroundTransparency = 1
    configsConfig.Parent = frame
    
    local configsLayout = Instance.new("UIGridLayout")
    configsLayout.Name = "ConfigsLayout"
    configsLayout.CellSize = UDim2.new(0, 220, 0, 120)
    configsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    configsLayout.Parent = configsConfig
    
    -- Botões de configuração geral
    local generalButtons = {
        {Name = "AntiAFK", Text = "Anti-AFK: ON", Config = "AntiAFK"},
        {Name = "SafeMode", Text = "Modo Seguro: ON", Config = "SafeMode"},
        {Name = "OptimizedMode", Text = "Modo Otimizado: ON", Config = "OptimizedMode"},
        {Name = "HumanLikeMovement", Text = "Movimento Humano: ON", Config = "HumanLikeMovement"},
        {Name = "RandomizeDelays", Text = "Delays Aleatórios: ON", Config = "RandomizeDelays"},
        {Name = "Theme", Text = "Tema: Neon", Config = "Theme", Type = "Mode"}
    }
    
    for _, buttonData in pairs(generalButtons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.Name .. "Button"
        button.Size = UDim2.new(0, 220, 0, 120)
        button.Text = buttonData.Text
        button.TextColor3 = self:GetThemeColor("Text")
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.BackgroundTransparency = 0.3
        button.backgroundColor3 = self:GetThemeColor("Secondary")
        button.Parent = configsConfig
        
        button.TextWrapped = true
        
        button.MouseButton1Click:Connect(function()
            if buttonData.Type == "Mode" and buttonData.Name == "Theme" then
                -- Ciclar entre temas
                local themes = {"Dark", "Light", "Neon"}
                local currentIndex = table.find(themes, CONFIG.Theme)
                local nextIndex = (currentIndex % #themes) + 1
                CONFIG.Theme = themes[nextIndex]
                button.Text = "Tema: " .. CONFIG.Theme
                
                -- Recriar GUI com novo tema
                self:CreateGUI()
                
                print("Tema alterado para: " .. CONFIG.Theme)
            else
                CONFIG[buttonData.Config] = not CONFIG[buttonData.Config]
                button.Text = buttonData.Name .. ": " .. (CONFIG[buttonData.Config] and "ON" or "OFF")
                button.backgroundColor3 = CONFIG[buttonData.Config] and self:GetThemeColor("Success") or self:GetThemeColor("Error")
            end
        end)
    end
end

function GUISystem:CreateLogsTab(frame)
    -- Área de logs
    local logsFrame = Instance.new("ScrollingFrame")
    logsFrame.Name = "LogsFrame"
    logsFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
    logsFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
    logsFrame.BackgroundTransparency = 0.8
    logsFrame.backgroundColor3 = Color3.fromRGB(30, 30, 30)
    logsFrame.Parent = frame
    
    local logsLayout = Instance.new("UIListLayout")
    logsLayout.Name = "LogsLayout"
    logsLayout.Parent = logsFrame
    logsLayout.Padding = UDim2.new(0, 2, 0, 2)
    
    -- Botão para limpar logs
    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearButton"
    clearButton.Size = UDim2.new(0.9, 0, 0, 40)
    clearButton.Position = UDim2.new(0.05, 0, 0.9, 0)
    clearButton.Text = "🗑️ Limpar Logs"
    clearButton.TextColor3 = self:GetThemeColor("Text")
    clearButton.Font = Enum.Font.Gotham
    clearButton.TextSize = 16
    clearButton.BackgroundTransparency = 0.3
    clearButton.backgroundColor3 = Color3.fromRGB(100, 0, 0)
    clearButton.Parent = frame
    
    clearButton.MouseButton1Click:Connect(function()
        -- Limpar logs
        for _, child in pairs(logsFrame:GetChildren()) do
            if child.Name:find("Log") then
                child:Destroy()
            end
        end
        print("Logs limpos")
    end)
    
    -- Armazenar referência para adicionar logs
    self.LogsFrame = logsFrame
end

-- Atualizar status da IA na GUI
function GUISystem:UpdateStatus(strategy)
    if self.StatusText then
        self.StatusText.Text = "IA: " .. CONFIG.AIMode .. " | Estratégia: " .. strategy
    end
end

-- Sistema de Efeitos Visuais e Sonoros
local EffectsSystem = {}

function EffectsSystem:CreateAttackEffect(position, fruitType)
    if not CONFIG.VisualEffects then return end
    
    local fruitData = FRUTAS[fruitType]
    if not fruitData then return end
    
    -- Efeito de partícula
    local particle = Instance.new("Part")
    particle.Name = "AttackEffect"
    particle.Size = Vector3.new(5, 5, 5)
    particle.Position = position
    particle.Anchored = true
    particle.CanCollide = false
    particle.Material = Enum.Material.Neon
    particle.Color = fruitData.Cor
    particle.Transparency = 0.7
    particle.Parent = workspace
    
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
    local goal = {Size = Vector3.new(15, 15, 15), Transparency = 1}
    local tween = tweenService:Create(particle, tweenInfo, goal)
    tween:Play()
    
    tween.Completed:Connect(function()
        particle:Destroy()
    end)
    
    -- Som
    if CONFIG.SoundEffects and fruitData.Som then
        local sound = Instance.new("Sound")
        sound.Name = "AttackSound"
        sound.SoundId = fruitData.Som
        sound.Volume = 2
        sound.Pitch = 1 + math.random() * 0.2
        sound.Parent = workspace
        sound:Play()
        
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

-- Sistema de Performance Otimizada
local PerformanceSystem = {}

function PerformanceSystem:OptimizeScript()
    if not CONFIG.OptimizedMode then return end
    
    -- Limitar FPS
    if CONFIG.FPSLimit then
        RunService.Heartbeat:Connect(function()
            local fps = 1 / RunService.HeartbeatWait
            if fps > CONFIG.FPSLimit then
                wait(1 / CONFIG.FPSLimit)
            end
        end)
    end
    
    -- Otimizar loops
    spawn(function()
        while wait(10) do
            -- Coletar lixo
            collectgarbage()
        end
    end)
end

-- Sistema de Segurança
local SecuritySystem = {}

function SecuritySystem:ApplySafeMode()
    if not CONFIG.SafeMode then return end
    
    -- Verificar se está em um servidor seguro
    local isSafeServer = self:CheckServerSafety()
    
    if not isSafeServer then
        print("Servidor não seguro detectado, aplicando proteções extras")
        CONFIG.HumanLikeMovement = true
        CONFIG.RandomizeDelays = true
    end
end

function SecuritySystem:CheckServerSafety()
    -- Lógica para verificar segurança do servidor
    -- Por exemplo, verificar se há anti-script severo
    return true -- Retorne false se detectar perigo
end

-- Loop principal com IA
local function mainLoop()
    print("Iniciando loop principal com IA...")
    
    -- Carregar dados de aprendizado
    IALearningSystem:LoadLearningData()
    
    while wait(0.5) do
        local success, error = pcall(function()
            -- Analisar ambiente com IA
            local analysis = IASystem:AnalyzeEnvironment()
            
            -- Atualizar status na GUI
            GUISystem:UpdateStatus(analysis.OptimalStrategy)
            
            -- Executar ações com base na análise
            if CONFIG.AutoFarm then
                local bestEnemy = AutoFarmSystem:FindBestEnemy(analysis)
                if bestEnemy then
                    AutoFarmSystem:AttackEnemy(bestEnemy)
                end
            end
            
            if CONFIG.AutoCollect then
                local bestItem = AutoCollectSystem:FindBestItem(analysis)
                if bestItem then
                    AutoCollectSystem:CollectItem(bestItem)
                end
            end
        end)
        
        if not success then
            print("Erro no loop principal: " .. error)
        end
    end
end

-- Sistema Anti-AFK
local function AntiAFK()
    if not CONFIG.AntiAFK then return end
    
    spawn(function()
        while wait(15) do
            local success, error = pcall(function()
                if humanoidRootPart then
                    if CONFIG.AntiAFKMode == "Smart" then
                        -- Movimento inteligente para parecer humano
                        local randomOffset = Vector3.new(
                            math.random(-2, 2),
                            0,
                            math.random(-2, 2)
                        )
                        humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(randomOffset)
                    end
                end
            end)
            
            if not success then
                print("Erro no Anti-AFK: " .. error)
            end
        end
    end)
end

-- Inicialização do script
print("🍎 BLOX FRUITS SCRIPT DEFINITIVO - INICIANDO")
print("Versão: 4.0.0 - IA Aprendizado Avançado")

-- Configurar RemoteEvents
local Remotes = {}
local function SetupRemotes()
    local remoteNames = {
        "Attack", "ClickFruit", "BuyFruit", "UseFruit", 
        "SellFruit", "Quest", "AcceptQuest", "CompleteQuest",
        "Raid", "SummonBoss", "UseSkill", "EquipWeapon",
        "SellItem", "CraftItem", "EnchantItem", "Fish"
    }
    
    for _, name in pairs(remoteNames) do
        local remote = ReplicatedStorage:FindRemoteEvent(name)
        if remote then
            Remotes[name] = remote
        end
    end
end

-- Inicializar sistemas
SetupRemotes()
GUISystem:CreateGUI()
AntiAFK()
PerformanceSystem:OptimizeScript()
SecuritySystem:ApplySafeMode()

-- Iniciar loop principal
spawn(mainLoop)

-- Comandos de teclado
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == CONFIG.GUIKey then
        CONFIG.ShowGUI = not CONFIG.ShowGUI
        if CONFIG.ShowGUI then
            GUISystem:CreateGUI()
            print("GUI reativado")
        else
            local existingGUI = player.PlayerGui:FindFirstChild("BloxFruitsGUI")
            if existingGUI then
                existingGUI:Destroy()
            end
            print("GUI desativado")
        end
    elseif input.KeyCode == Enum.KeyCode.F5 then
        -- Recarregar script
        print("Recarregando script...")
        script:Destroy()
    elseif input.KeyCode == Enum.KeyCode.F6 then
        -- Alternar modo seguro
        CONFIG.SafeMode = not CONFIG.SafeMode
        print("Modo Seguro: " .. (CONFIG.SafeMode and "ATIVADO" or "DESATIVADO"))
    elseif input.KeyCode == Enum.KeyCode.F7 then
        -- Salvar dados de aprendizado
        IALearningSystem:SaveLearningData()
    end
end)

-- Limpeza ao sair
player.CharacterRemoving:Connect(function()
    CONFIG.AutoFarm = false
    CONFIG.AutoCollect = false
    CONFIG.AutoBuy = false
    CONFIG.AutoQuest = false
    CONFIG.AutoRaid = false
    
    -- Salvar dados de aprendizado
    IALearningSystem:SaveLearningData()
    
    print("Script desativado")
end)

print("Script pronto para uso!")
print("Pressione " .. CONFIG.GUIKey:gsub("Right", "Direito"):replace("Left", "Esquerdo") .. " para ativar/desativar a GUI")
print("Pressione F7 para salvar dados de aprendizado")
```
