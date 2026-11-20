-- Script Universal Player Hub v3.0 (2026)
-- Código completo e funcional para Roblox 2026

repeat task.wait() until game:IsLoaded()
task.wait(2)

local Rayfield
local tentativas = 0
local max_tentativas = 5

print("[Script] Iniciando...")

while not Rayfield and tentativas < max_tentativas do
    tentativas = tentativas + 1
    print("[Script] Tentativa " .. tentativas)
    
    local sucesso, erro = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if sucesso and Rayfield then
        print("[Script] Rayfield carregado!")
        break
    else
        warn("[Script] Tentativa falhou: " .. tostring(erro))
        if tentativas < max_tentativas then task.wait(2) end
    end
end

if not Rayfield then
    warn("[Script] FALHA CRÍTICA")
    return
end

local function ObterServico(nome)
    local ok, servico = pcall(function()
        return game:GetService(nome)
    end)
    return ok and servico or nil
end

local Players = ObterServico("Players")
local RunService = ObterServico("RunService")
local UserInputService = ObterServico("UserInputService")
local Lighting = ObterServico("Lighting")
local VirtualUser = ObterServico("VirtualUser")
local TeleportService = ObterServico("TeleportService")
local HttpService = ObterServico("HttpService")
local Workspace = ObterServico("Workspace")
local PhysicsService = ObterServico("PhysicsService")

if not Players or not RunService then
    warn("[Script] Serviços essenciais indisponíveis")
    return
end

local player = Players.LocalPlayer
if not player then return end

print("[Script] Serviços carregados!")

local function SafeCall(func, ...)
    local args = {...}
    local ok, resultado = pcall(function()
        return func(unpack(args))
    end)
    if not ok then warn("[Script] Erro: " .. tostring(resultado)) end
    return ok, resultado
end

local function GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
end

local function GetRootPart(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

local CONFIG = {
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = 196.2,
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
    ClickTP = false,
    VelocidadeGlobal = 1000,
    AplicarVelocidade = false,
    LimiteVelocidade = 500
}

local function ApplySpeed()
    local hum = GetHumanoid(player.Character)
    if hum then
        local speed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
        hum.WalkSpeed = math.clamp(speed, 0, CONFIG.LimiteVelocidade)
    end
end

local function ToggleFly(enabled)
    CONFIG.Fly = enabled
    local hum = GetHumanoid(player.Character)
    local root = GetRootPart(player.Character)
    
    if not hum or not root then return end
    
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
            while CONFIG.Fly do
                local cam = workspace.CurrentCamera
                if not cam then task.wait() continue end
                
                bg.CFrame = cam.CFrame
                
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0 then
                    bv.Velocity = moveDir * CONFIG.FlySpeed
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
            hum.PlatformStand = false
        end)
    else
        local bv = root:FindFirstChild("BodyVelocity")
        local bg = root:FindFirstChild("BodyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        hum.PlatformStand = false
    end
end

local function ToggleNoclip(enabled)
    CONFIG.Noclip = enabled
    local char = player.Character
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

local function ToggleESP(enabled)
    CONFIG.ESP = enabled
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p ~= player then
            local hl = p.Character:FindFirstChild("ESP_Highlight")
            if enabled then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ESP_Highlight"
                    hl.Parent = p.Character
                end
            elseif hl then
                hl:Destroy()
            end
        end
    end
end

print("[Script] Criando interface...")

local Window = Rayfield:CreateWindow({
    Name = "Script Universal - Player 2026",
    LoadingTitle = "Carregando Menu...",
    LoadingSubtitle = "Versão Atualizada",
    ConfigurationSaving = { Enabled = true },
    KeySystem = false
})

local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("🏃 Movimento")

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {1, 1000},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        CONFIG.WalkSpeed = Value
        local hum = GetHumanoid(player.Character)
        if hum then hum.WalkSpeed = Value end
        Rayfield:Notify("WalkSpeed: " .. Value, 3, "SUCCESS")
    end
})

PlayerTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(Value)
        CONFIG.JumpPower = Value
        local hum = GetHumanoid(player.Character)
        if hum then hum.JumpPower = Value end
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value) CONFIG.InfiniteJump = Value end
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        ToggleNoclip(Value)
        Rayfield:Notify("Noclip " .. (Value and "ON" or "OFF"), 3, "SUCCESS")
    end
})

PlayerTab:CreateSection("✈️ Fly")

PlayerTab:CreateToggle({
    Name = "Ativar Fly",
    CurrentValue = false,
    Callback = function(Value)
        ToggleFly(Value)
        Rayfield:Notify("Fly " .. (Value and "ON" or "OFF"), 3, "SUCCESS")
    end
})

PlayerTab:CreateSlider({
    Name = "FlySpeed",
    Range = {1, 1000},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value) CONFIG.FlySpeed = Value end
})

PlayerTab:CreateSection("👁️ Visual")

PlayerTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(Value)
        ToggleESP(Value)
        Rayfield:Notify("ESP " .. (Value and "ON" or "OFF"), 3, "SUCCESS")
    end
})

PlayerTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(Value)
        CONFIG.Fullbright = Value
        if Value then
            Lighting.Brightness = 2
            Lighting.FogEnd = 100000
        else
            Lighting.Brightness = 1
            Lighting.FogEnd = 300
        end
    end
})

PlayerTab:CreateSlider({
    Name = "FOV",
    Range = {50, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(Value)
        CONFIG.FOV = Value
        workspace.CurrentCamera.FieldOfView = Value
    end
})

PlayerTab:CreateSection("⚙️ Utilidades")

PlayerTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(Value) CONFIG.AntiAFK = Value end
})

PlayerTab:CreateToggle({
    Name = "Click TP",
    CurrentValue = false,
    Callback = function(Value) CONFIG.ClickTP = Value end
})

PlayerTab:CreateSection("👥 Teleporte")

local playerList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= player then table.insert(playerList, p.Name) end
end

PlayerTab:CreateDropdown({
    Name = "Selecionar Player",
    Options = playerList,
    CurrentOption = playerList[1] or "Nenhum",
    Callback = function(Option) CONFIG.SelectedPlayer = Option end
})

PlayerTab:CreateButton({
    Name = "Teleportar",
    Callback = function()
        local target = Players:FindFirstChild(CONFIG.SelectedPlayer)
        if target and target.Character then
            local root = GetRootPart(player.Character)
            local troot = GetRootPart(target.Character)
            if root and troot then
                root.CFrame = troot.CFrame * CFrame.new(0, 0, 3)
                Rayfield:Notify("Teleportado!", 3, "SUCCESS")
            end
        end
    end
})

player.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.5)
    ApplySpeed()
end)

RunService.Stepped:Connect(function()
    local hum = GetHumanoid(player.Character)
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

UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = GetHumanoid(player.Character)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

player.Idled:Connect(function()
    if CONFIG.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

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
            local root = GetRootPart(player.Character)
            if root then root.CFrame = CFrame.new(position) end
        end
    end
end)

ApplySpeed()
Rayfield:LoadConfiguration()
Rayfield:Notify("Script Universal 2026 carregado!", 5, "SUCCESS")
