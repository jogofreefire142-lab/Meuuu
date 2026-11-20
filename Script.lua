
Adiciona isso no meu repositório do Git Hub
-- 🍎 BLOX FRUITS SCRIPT - DELTA EXECUTOR
-- Versão: 2.0.0 - Completo e Otimizado

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Configurações Avançadas
local CONFIG = {
-- Auto Farm
AutoFarm = true,
FarmLevel = 50,
AttackRange = 25,
FarmMode = "Level", -- "Level" ou "Nearby"

-- Auto Collect  
AutoCollect = true,  
CollectRange = 40,  
  
-- Auto Buy  
AutoBuy = true,  
PreferredFruits = {"Gomu Gomu", "Bara Bara", "Suke Suke"},  
AutoBuyMoney = 1000,  
  
-- Auto Quest  
AutoQuest = true,  
QuestRange = 50,  
  
-- Auto Raid  
AutoRaid = false,  
RaidBosses = {"Sea Beast", "Skull", "Ice Admiral"},  
  
-- Combate  
UseFruit = true,  
FruitSkill = true,  
Auto Dodge = true,  
  
-- Interface  
ShowGUI = true,  
GUIKey = Enum.KeyCode.RightControl,  
  
-- Anti-AFK  
AntiAFK = true,  
  
-- Outros  
FarmDelay = 0.5,  
CollectDelay = 0.3

}

-- Banco de dados de frutas
local FRUTAS = {
["Gomu Gomu"] = {Dano = 100, Cooldown = 5, Preco = 1000},
["Bara Bara"] = {Dano = 120, Cooldown = 5, Preco = 1200},
["Suke Suke"] = {Dano = 80, Cooldown = 4, Preco = 800},
["Mero Mero"] = {Dano = 90, Cooldown = 6, Preco = 900},
["Hie Hie"] = {Dano = 110, Cooldown = 5, Preco = 1100},
["Magma Magma"] = {Dano = 130, Cooldown = 7, Preco = 1300},
["Pika Pika"] = {Dano = 150, Cooldown = 8, Preco = 1500},
["Yomi Yomi"] = {Dano = 140, Cooldown = 7, Preco = 1400}
}

-- RemoteEvents
local Remotes = {
Attack = ReplicatedStorage:FindRemoteEvent("Attack"),
ClickFruit = ReplicatedStorage:FindRemoteEvent("ClickFruit"),
BuyFruit = ReplicatedStorage:FindRemoteEvent("BuyFruit"),
UseFruit = ReplicatedStorage:FindRemoteEvent("UseFruit"),
SellFruit = ReplicatedStorage:FindRemoteEvent("SellFruit"),
Quest = ReplicatedStorage:FindRemoteEvent("Quest"),
AcceptQuest = ReplicatedStorage:FindRemoteEvent("AcceptQuest"),
CompleteQuest = ReplicatedStorage:FindRemoteEvent("CompleteQuest"),
Raid = ReplicatedStorage:FindRemoteEvent("Raid"),
SummonBoss = ReplicatedStorage:FindRemoteEvent("SummonBoss")
}

-- Sistema de Automação de Farm
local AutoFarmSystem = {}

function AutoFarmSystem:FindBestEnemy()
local enemies = {}

for _, npc in pairs(workspace:GetChildren()) do  
    if npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then  
        if npc:FindFirstChild("Boss") and npc:FindFirstChild("Level") then  
            local distance = (humanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude  
              
            if distance <= CONFIG.AttackRange then  
                table.insert(enemies, {  
                    Model = npc,  
                    Distance = distance,  
                    Level = npc.Level.Value,  
                    Name = npc.Name  
                })  
            end  
        end  
    end  
end  
  
if #enemies > 0 then  
    -- Ordenar por nível (menor primeiro para farmar mais rápido)  
    table.sort(enemies, function(a, b)  
        return a.Level < b.Level  
    end)  
      
    return enemies[1]  
end  
  
return nil

end

function AutoFarmSystem:AttackEnemy(enemy)
if enemy and enemy.Model and humanoidRootPart then
local direction = (enemy.Model.HumanoidRootPart.Position - humanoidRootPart.Position).Unit
humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + direction)

-- Ataque principal  
    if Remotes.Attack then  
        Remotes.Attack:FireServer(enemy.Model.HumanoidRootPart.Position)  
    end  
      
    -- Usar fruta se configurado  
    if CONFIG.UseFruit and Remotes.UseFruit then  
        Remotes.UseFruit:FireServer(CONFIG.PreferredFruits[1])  
    end  
      
    return true  
end  
return false

end

-- Sistema de Auto Collect
local AutoCollectSystem = {}

function AutoCollectSystem:CollectNearbyFruits()
for _, fruit in pairs(workspace:GetChildren()) do
if fruit:FindFirstChild("Fruit") and fruit:FindFirstChild("HumanoidRootPart") then
local distance = (humanoidRootPart.Position - fruit.HumanoidRootPart.Position).Magnitude

if distance <= CONFIG.CollectRange then  
            -- Mover para a fruta  
            humanoid:MoveTo(fruit.HumanoidRootPart.Position)  
              
            -- Coletar  
            if Remotes.ClickFruit then  
                Remotes.ClickFruit:FireServer(fruit.HumanoidRootPart.Position)  
            end  
              
            wait(CONFIG.CollectDelay)  
        end  
    end  
end

end

-- Sistema de Auto Buy
local AutoBuySystem = {}

function AutoBuySystem:BuyPreferredFruits()
if not CONFIG.AutoBuy then return end

for _, fruitName in pairs(CONFIG.PreferredFruits) do  
    if FRUTAS[fruitName] and player.Leaderstats.Money.Value >= FRUTAS[fruitName].Preco then  
        if Remotes.BuyFruit then  
            Remotes.BuyFruit:FireServer(fruitName)  
            print("🍎 Comprando: " .. fruitName)  
            wait(0.5)  
        end  
    end  
end

end

-- Sistema de Auto Quest
local AutoQuestSystem = {}

function AutoQuestSystem:FindAndAcceptQuests()
if not CONFIG.AutoQuest then return end

-- Procurar NPCs de quest  
for _, npc in pairs(workspace:GetChildren()) do  
    if npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then  
        if npc:FindFirstChild("Quest") and npc:FindFirstChild("QuestNPC") then  
            local distance = (humanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude  
              
            if distance <= CONFIG.QuestRange then  
                -- Aceitar quest  
                if Remotes.AcceptQuest then  
                    Remotes.AcceptQuest:FireServer(npc.Name)  
                    print("📋 Aceitando quest: " .. npc.Name)  
                    wait(0.5)  
                end  
                  
                -- Completar quest  
                if Remotes.CompleteQuest then  
                    Remotes.CompleteQuest:FireServer(npc.Name)  
                    print("✅ Quest completada: " .. npc.Name)  
                    wait(0.5)  
                end  
            end  
        end  
    end  
end

end

-- Sistema de Auto Raid
local AutoRaidSystem = {}

function AutoRaidSystem:SummonAndDefeatBosses()
if not CONFIG.AutoRaid then return end

for _, bossName in pairs(CONFIG.RaidBosses) do  
    -- Procurar pelo boss  
    for _, boss in pairs(workspace:GetChildren()) do  
        if boss:FindFirstChild("Humanoid") and boss:FindFirstChild("HumanoidRootPart") then  
            if boss.Name:find(bossName) then  
                local distance = (humanoidRootPart.Position - boss.HumanoidRootPart.Position).Magnitude  
                  
                if distance <= CONFIG.AttackRange then  
                    -- Atacar o boss  
                    AutoFarmSystem:AttackEnemy({  
                        Model = boss,  
                        Level = 999,  
                        Name = bossName  
                    })  
                      
                    -- Usar skills de fruta  
                    if CONFIG.FruitSkill and Remotes.UseFruit then  
                        Remotes.UseFruit:FireServer(CONFIG.PreferredFruits[1])  
                    end  
                      
                    wait(0.5)  
                end  
            end  
        end  
    end  
end

end

-- Sistema de Anti-AFK
local AntiAFKSystem = {}

function AntiAFKSystem:KeepAlive()
if not CONFIG.AntiAFK then return end

-- Movimento aleatório para evitar AFK  
spawn(function()  
    while wait(10) do  
        if humanoidRootPart then  
            local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))  
            humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(randomOffset)  
        end  
    end  
end)

end

-- Sistema de Interface (GUI)
local GUISystem = {}

function GUISystem:CreateGUI()
if not CONFIG.ShowGUI then return end

local screenGui = Instance.new("ScreenGui")  
screenGui.Name = "BloxFruitsGUI"  
screenGui.Parent = player.PlayerGui  
  
local mainFrame = Instance.new("Frame")  
mainFrame.Name = "MainFrame"  
mainFrame.Size = UDim2.new(0, 400, 0, 300)  
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)  
mainFrame.BackgroundTransparency = 0.2  
mainFrame.backgroundColor3 = Color3.fromRGB(20, 20, 20)  
mainFrame.Parent = screenGui  
  
-- Título  
local title = Instance.new("TextButton")  
title.Name = "Title"  
title.Size = UDim2.new(1, 0, 0, 40)  
title.Position = UDim2.new(0, 0, 0, 0)  
title.Text = "🍎 BLOX FRUITS SCRIPT"  
title.TextColor3 = Color3.fromRGB(255, 255, 255)  
title.Font = Enum.Font.GothamBold  
title.TextSize = 20  
title.BackgroundTransparency = 0.5  
title.backgroundColor3 = Color3.fromRGB(50, 0, 0)  
title.Parent = mainFrame  
  
-- Botões de controle  
local buttons = {  
    {Name = "AutoFarm", Text = "Auto Farm: ON", Y = 0.2},  
    {Name = "AutoCollect", Text = "Auto Collect: ON", Y = 0.3},  
    {Name = "AutoBuy", Text = "Auto Buy: ON", Y = 0.4},  
    {Name = "AutoQuest", Text = "Auto Quest: ON", Y = 0.5},  
    {Name = "AutoRaid", Text = "Auto Raid: OFF", Y = 0.6}  
}  
  
for _, buttonData in pairs(buttons) do  
    local button = Instance.new("TextButton")  
    button.Name = buttonData.Name .. "Button"  
    button.Size = UDim2.new(0.8, 0, 0, 40)  
    button.Position = UDim2.new(0.1, 0, buttonData.Y, 0)  
    button.Text = buttonData.Text  
    button.TextColor3 = Color3.fromRGB(255, 255, 255)  
    button.Font = Enum.Font.Gotham  
    button.TextSize = 16  
    button.BackgroundTransparency = 0.3  
    button.backgroundColor3 = Color3.fromRGB(0, 100, 0)  
    button.Parent = mainFrame  
      
    -- Evento do botão  
    button.MouseButton1Click:Connect(function()  
        if buttonData.Name == "AutoFarm" then  
            CONFIG.AutoFarm = not CONFIG.AutoFarm  
            button.Text = "Auto Farm: " .. (CONFIG.AutoFarm and "ON" or "OFF")  
            button.backgroundColor3 = CONFIG.AutoFarm and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)  
        elseif buttonData.Name == "AutoCollect" then  
            CONFIG.AutoCollect = not CONFIG.AutoCollect  
            button.Text = "Auto Collect: " .. (CONFIG.AutoCollect and "ON" or "OFF")  
            button.backgroundColor3 = CONFIG.AutoCollect and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)  
        -- Adicione outros controles conforme necessário  
        end  
    end)  
end  
  
-- Botão de fechar  
local closeButton = Instance.new("TextButton")  
closeButton.Name = "CloseButton"  
closeButton.Size = UDim2.new(0.2, 0, 0, 30)  
closeButton.Position = UDim2.new(0.8, 0, 0.9, 0)  
closeButton.Text = "❌ Fechar"  
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)  
closeButton.Font = Enum.Font.Gotham  
closeButton.TextSize = 14  
closeButton.BackgroundTransparency = 0.3  
closeButton.backgroundColor3 = Color3.fromRGB(100, 0, 0)  
closeButton.Parent = mainFrame  
  
closeButton.MouseButton1Click:Connect(function()  
    screenGui:Destroy()  
end)

end

-- Loop principal
local function mainLoop()
while wait(CONFIG.FarmDelay) do
if CONFIG.AutoFarm then
local enemy = AutoFarmSystem:FindBestEnemy()
if enemy then
AutoFarmSystem:AttackEnemy(enemy)
end
end

if CONFIG.AutoCollect then  
        AutoCollectSystem:CollectNearbyFruits()  
    end  
      
    if CONFIG.AutoBuy then  
        AutoBuySystem:BuyPreferredFruits()  
    end  
      
    if CONFIG.AutoQuest then  
        AutoQuestSystem:FindAndAcceptQuests()  
    end  
      
    if CONFIG.AutoRaid then  
        AutoRaidSystem:SummonAndDefeatBosses()  
    end  
end

end

-- Inicialização
print("🍎 Blox Fruits Script carregado!")
print("Versão: 2.0.0 - Delta Executor")
print("Funcionalidades: Auto Farm, Auto Collect, Auto Buy, Auto Quest, Auto Raid")

-- Inicializar sistemas
AntiAFKSystem:KeepAlive()
GUISystem:CreateGUI()

-- Iniciar loop principal
spawn(mainLoop)

-- Comandos de teclado
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end

if input.KeyCode == CONFIG.GUIKey then  
    CONFIG.ShowGUI = not CONFIG.ShowGUI  
    if CONFIG.ShowGUI then  
        GUISystem:CreateGUI()  
    else  
        local existingGUI = player.PlayerGui:FindFirstChild("BloxFruitsGUI")  
        if existingGUI then  
            existingGUI:Destroy()  
        end  
    end  
end

end)

-- Limpeza ao sair
player.CharacterRemoving:Connect(function()
CONFIG.AutoFarm = false
CONFIG.AutoCollect = false
CONFIG.AutoBuy = false
CONFIG.AutoQuest = false
CONFIG.AutoRaid = false
print("Script desativado")
end)
