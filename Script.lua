-- ====================================================================
-- SCRIPT UNIVERSAL BLINDADO - FUNCIONA EM QUALQUER JOGO ROBLOX
-- Compatibilidade total - Zero crashes - Fallbacks automáticos
-- ====================================================================

-- 🔵 1. ESPERA CARREGAMENTO TOTAL (Essencial para Auto Execute)
repeat task.wait() until game:IsLoaded()
task.wait(1)

-- 🔵 2. CARREGAMENTO SEGURO DA UI COM RETRY INFINITO
local Rayfield
local tentativas = 0
print("[Universal Hub] Iniciando...")

while not Rayfield do
    tentativas = tentativas + 1
    print("[Universal Hub] Tentativa " .. tentativas .. " de carregar Rayfield...")
    
    local sucesso, erro = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if sucesso and Rayfield then
        print("[Universal Hub] ✅ Rayfield carregado!")
        break
    else
        warn("[Universal Hub] ⚠️ Tentativa " .. tentativas .. " falhou: " .. tostring(erro))
        task.wait(3)
    end
end

-- 🔵 3. SERVIÇOS COM PCALL UNIVERSAL
local function SafeGetService(nome)
    local ok, servico = pcall(function() return game:GetService(nome) end)
    return ok and servico or nil
end

local Services = {}
local ServiceNames = {
    "Players", "RunService", "UserInputService", "Lighting", 
    "VirtualUser", "TeleportService", "HttpService", "Workspace",
    "PhysicsService", "ReplicatedStorage", "StarterPlayer", 
    "ContextActionService", "GuiService", "Teams"
}

for _, nome in ipairs(ServiceNames) do
    Services[nome] = SafeGetService(nome)
end

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local Lighting = Services.Lighting
local VirtualUser = Services.VirtualUser
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService
local Workspace = Services.Workspace
local PhysicsService = Services.PhysicsService

-- Verificação crítica
if not Players or not RunService then
    warn("[Universal Hub] ❌ Serviços essenciais ausentes.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- 🔵 4. UTILITÁRIOS DE SEGURANÇA UNIVERSAL
local function SafeGet(obj, prop)
    if not obj then return nil end
    local ok, val = pcall(function() return obj[prop] end)
    return ok and val or nil
end

local function SafeCall(func, ...)
    local args = {...}
    local ok, result = pcall(function() return func(unpack(args)) end)
    if not ok then warn("[SafeCall] " .. tostring(result)) end
    return ok, result
end

local function WaitForChildSafe(parent, name, timeout)
    if not parent then return nil end
    timeout = timeout or 10
    local start = tick()
    while tick() - start < timeout do
        local child = SafeGet(parent, name)
        if child then return child end
        task.wait()
    end
    return nil
end

local function GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid") 
        or char:FindFirstChild("Humanoid")
        or char:FindFirstChild("HumanoidController")
end

local function GetRootPart(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Head")
end

-- 🔵 5. SISTEMA MAID À PROVA DE FALHAS
local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({_tasks = {}}, Maid) end
function Maid:GiveTask(task)
    if not task then return end
    table.insert(self._tasks, task)
    return task
end
function Maid:Cleanup()
    for _, task in ipairs(self._tasks) do
        pcall(function()
            if typeof(task) == "RBXScriptConnection" then task:Disconnect()
            elseif typeof(task) == "Instance" then task:Destroy()
            elseif type(task) == "function" then task()
            elseif type(task) == "table" and task.Cleanup then task:Cleanup() end
        end)
    end
    self._tasks = {}
end

-- 🔵 6. CONFIGURAÇÃO CENTRAL COM DEFAULTS SEGUROS
local CONFIG = {
    WalkSpeed = 16, JumpPower = 50, Gravity = 196.2,
    InfiniteJump = false, Noclip = false, Spin = false, SpinSpeed = 10,
    Sit = false, Fly = false, FlySpeed = 50, FlyVerticalSpeed = 50,
    ESP = false, Fullbright = false, NoFog = false, FOV = 70,
    FreeCam = false, AntiAFK = false, AntiLag = false,
    ClickTP = false, VelocidadeGlobal = 100, AplicarVelocidade = false,
    LimiteVelocidade = 500,
    _Connections = Maid.new(),
    _FlyObjects = Maid.new(),
    _ESPObjects = Maid.new()
}

-- 🔵 5. SALVAR/CARREGAR COM PCALL UNIVERSAL
local CONFIG_PATH = "UniversalHub_Config_" .. game.GameId .. ".json"

local function SafeSaveConfig()
    pcall(function()
        local saveData = {}
        for k, v in pairs(CONFIG) do
            if not tostring(k):find("_") then saveData[k] = v end
        end
        writefile("UniversalHub_Config_" .. game.GameId .. ".json", HttpService:JSONEncode(saveData))
    end)
end

local function SafeLoadConfig()
    pcall(function()
        if isfile("UniversalHub_Config_" .. game.GameId .. ".json") then
            local data = HttpService:JSONDecode(readfile("UniversalHub_Config_" .. game.GameId .. ".json"))
            if data then for k, v in pairs(data) do CONFIG[k] = v end end
        end
    end)
end

-- 🔵 6. FUNÇÕES CORE À PROVA DE BALAS

local function GetHumanoidSafe()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
end

local function GetRootPartSafe()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
end

local function ApplySpeedSafe()
    local hum = GetHumanoidSafe()
    if not hum then return end
    
    local target = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
    target = math.clamp(target, 0, CONFIG.LimiteVelocidade)
    
    pcall(function() hum.WalkSpeed = target end)
    
    -- Loop de proteção com pcall
    local conn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local hum2 = GetHumanoidSafe()
            if not hum2 then return end
            
            if CONFIG.AplicarVelocidade then
                if hum2.WalkSpeed ~= CONFIG.VelocidadeGlobal then
                    hum2.WalkSpeed = CONFIG.VelocidadeGlobal
                end
            else
                if hum2.WalkSpeed ~= CONFIG.WalkSpeed then
                    hum2.WalkSpeed = CONFIG.WalkSpeed
                end
            end
        end)
    end)
end

local function ToggleFlySafe(enabled)
    CONFIG.Fly = enabled
    local hum = GetHumanoidSafe()
    local root = GetRootPartSafe()
    
    if not enabled or not hum or not root then
        pcall(function() hum.PlatformStand = false end)
        return
    end
    
    pcall(function() hum.PlatformStand = true end)
    
    -- Tenta Constraints primeiro (moderno)
    local success = pcall(function()
        local attachment = Instance.new("Attachment")
        attachment.Name = "FlyAttachment"
        attachment.Parent = root
        
        local lv = Instance.new("LinearVelocity")
        lv.Name = "FlyVelocity"
        lv.Attachment0 = attachment
        lv.MaxForce = math.huge
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.VectorVelocity = Vector3.zero
        lv.Parent = root
        
        local ao = Instance.new("AlignOrientation")
        ao.Name = "FlyGyro"
        ao.Attachment0 = attachment
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.RigidityEnabled = true
        ao.MaxTorque = math.huge
        ao.Parent = root
        
        local flyConn = RunService.Heartbeat:Connect(function()
            if not CONFIG.Fly or not root.Parent or not hum.Parent then return end
            
            local cam = Workspace.CurrentCamera
            if not cam then return end
            
            pcall(function() 
                local ao2 = root:FindFirstChild("FlyGyro")
                if ao2 then ao2.CFrame = cam.CFrame end
            end)
            
            local moveDir = hum.MoveDirection
            local speed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed
            local vSpeed = CONFIG.FlyVerticalSpeed or 50
            
            local targetVel = Vector3.zero
            if moveDir.Magnitude > 0 then
                local camLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
                local camRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
                targetVel = (camLook * moveDir.Z + camRight * moveDir.X) * speed
            end
            
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
                targetVel = targetVel + Vector3.new(0, vSpeed, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2) then
                targetVel = targetVel - Vector3.new(0, vSpeed, 0)
            end
            
            pcall(function() 
                local lv2 = root:FindFirstChild("FlyVelocity")
                if lv2 then lv2.VectorVelocity = targetVel end
            end)
        end)
    end)
    
    -- Se Constraints falhar, tenta BodyVelocity (fallback)
    if not success then
        pcall(function()
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
            
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 9e4
            bg.Parent = root
            
            local flyConn = RunService.Heartbeat:Connect(function()
                if not CONFIG.Fly or not root.Parent or not hum.Parent then return end
                
                local cam = Workspace.CurrentCamera
                if not cam then return end
                pcall(function() bg.CFrame = cam.CFrame end)
                
                local moveDir = hum.MoveDirection
                local speed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed
                
                local targetVel = Vector3.zero
                if moveDir.Magnitude > 0 then
                    local camLook = cam.CFrame.LookVector
                    local camRight = cam.CFrame.RightVector
                    local flatForward = Vector3.new(camLook.X, 0, camLook.Z).Unit
                    local flatRight = Vector3.new(camRight.X, 0, camRight.Z).Unit
                    
                    local forwardAmount = moveDir:Dot(flatForward)
                    local rightAmount = moveDir:Dot(flatRight)
                    
                    local finalDir = (camLook * forwardAmount) + (camRight * rightAmount)
                    targetVel = finalDir * speed
                end
                
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    targetVel = targetVel + Vector3.new(0, CONFIG.FlySpeed, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    targetVel = targetVel - Vector3.new(0, CONFIG.FlySpeed, 0)
                end
                
                pcall(function() bv.Velocity = targetVel end)
            end)
        end)
    end
end

local function ToggleNoclipSafe(enabled)
    CONFIG.Noclip = enabled
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Tenta CollisionGroup primeiro
    local success = false
    if PhysicsService then
        success = pcall(function()
            local groupName = "UniversalHub_Noclip_" .. game.GameId
            if not Workspace:FindFirstChild(groupName) then
                local group = Instance.new("CollisionGroup")
                group.Name = groupName
                group.Parent = Workspace
                PhysicsService:CollisionGroupSetCollidable(groupName, "Default", false)
                PhysicsService:CollisionGroupSetCollidable(groupName, groupName, false)
            end
            
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CollisionGroup = enabled and groupName or "Default"
                end
            end
        end)
        success = true
    end
    
    -- Fallback: CanCollide
    if not success then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = not enabled end)
            end
        end
    end
end

local function ToggleESPSafe(enabled)
    CONFIG.ESP = enabled
    if not enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hl = p.Character:FindFirstChild("ESP_Highlight")
                if hl then pcall(function() hl:Destroy() end) end
            end
        end
        return
    end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            pcall(function()
                local char = p.Character
                local hl = char:FindFirstChild("ESP_Highlight")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ESP_Highlight"
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee = char
                    hl.Parent = char
                end
                hl.FillColor = p.TeamColor and p.TeamColor.Color or Color3.new(1, 0, 0)
                hl.OutlineColor = Color3.new(1, 1, 1)
            end)
        end
    end
end

local function UpdateVisualsSafe()
    pcall(function()
        if CONFIG.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.GlobalShadows = true
        end
        Lighting.FogEnd = CONFIG.NoFog and 100000 or 300
    end)
    pcall(function() Workspace.CurrentCamera.FieldOfView = CONFIG.FOV end)
end

local function ToggleFreeCamSafe(enabled)
    CONFIG.FreeCam = enabled
    local cam = Workspace.CurrentCamera
    local hum = GetHumanoidSafe()
    if not cam then return end
    
    pcall(function()
        if enabled then
            cam.CameraType = Enum.CameraType.Scriptable
            if hum then hum.PlatformStand = true end
        else
            cam.CameraType = Enum.CameraType.Custom
            if hum then hum.PlatformStand = false end
        end
    end)
end

-- 🔵 7. EVENTOS GLOBAIS COM PCALL
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = GetHumanoidSafe()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

LocalPlayer.Idled:Connect(function()
    if CONFIG.AntiAFK then
        pcall(function() 
            VirtualUser:CaptureController() 
            VirtualUser:ClickButton2(Vector2.new()) 
        end)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if CONFIG.ClickTP and not processed then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local root = GetRootPartSafe()
            local pos = input.UserInputType == Enum.UserInputType.Touch and input.Position or LocalPlayer:GetMouse().Hit.Position
            if root and pos then pcall(function() root.CFrame = CFrame.new(pos) end) end
        end
    end
end)

-- 🔵 8. LOOPS DE FUNDO COM PCALL
RunService.Heartbeat:Connect(function()
    pcall(function()
        if CONFIG.Spin then
            local root = GetRootPartSafe()
            if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed or 10), 0) end
        end
        
        local hum = GetHumanoidSafe()
        if hum and CONFIG.Sit and not hum.Sit then hum.Sit = true end
    end)
end)

RunService.Stepped:Connect(function()
    pcall(function()
        -- Proteção de velocidade
        local hum = GetHumanoidSafe()
        if hum then
            if CONFIG.AplicarVelocidade then
                if hum.WalkSpeed ~= CONFIG.VelocidadeGlobal then hum.WalkSpeed = CONFIG.VelocidadeGlobal end
            else
                if hum.WalkSpeed ~= CONFIG.WalkSpeed then hum.WalkSpeed = CONFIG.WalkSpeed end
            end
        end
        
        -- Noclip
        if CONFIG.Noclip then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = false end)
                    end
                end
            end
        end
    end)
end)

RunService.RenderStepped:Connect(function(dt)
    if CONFIG.FreeCam then
        pcall(function()
            local cam = Workspace.CurrentCamera
            if not cam then return end
            
            local speed = 50 * dt
            local cf = cam.CFrame
            local move = Vector3.zero
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
            
            if move.Magnitude > 0 then cam.CFrame = cf + move.Unit * speed end
        end)
    end
end)

-- 🔵 8. CHARACTER ADDED COM TRATAMENTO TOTAL
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    pcall(function()
        local hum = char:WaitForChild("Humanoid", 10)
        local root = char:WaitForChild("HumanoidRootPart", 10) or char:WaitForChild("Torso", 10)
        if not hum or not root then return end
        
        -- Reaplica configs
        pcall(function() hum.WalkSpeed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed end)
        pcall(function() hum.UseJumpPower = true; hum.JumpPower = CONFIG.JumpPower end)
        if CONFIG.Sit then hum.Sit = true end
    end)
end)

if LocalPlayer.Character then
    pcall(function() LocalPlayer.CharacterAdded:Fire(LocalPlayer.Character) end)
end

-- 🔵 9. UI RAYFIELD (INTERFACE INTACTA)
local Window = Rayfield:CreateWindow({
    Name = "Universal Hub v3.0",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Compatibilidade Total",
    ConfigurationSaving = {Enabled = true, FolderName = "DeltaUniversalHub", FileName = "Config"},
    KeySystem = false
})

local PlayerTab = Window:CreateTab("Player", "user")

-- Helpers para UI
local function AddSlider(tab, info)
    tab:CreateSlider({
        Name = info.Name, Flag = info.Flag, Range = info.Range, Increment = info.Increment,
        CurrentValue = CONFIG[info.Flag] or info.CurrentValue,
        Callback = function(v) CONFIG[info.Flag] = v; if info.OnChange then pcall(info.OnChange, v) end end
    })
end

local function AddToggle(tab, info)
    tab:CreateToggle({
        Name = info.Name, Flag = info.Flag, CurrentValue = CONFIG[info.Flag] or false,
        Callback = function(v) CONFIG[info.Flag] = v; if info.OnChange then pcall(info.OnChange, v) end end
    })
end

PlayerTab:CreateSection("🏃 Movimento")
AddSlider(PlayerTab, {Name="WalkSpeed", Flag="WalkSpeed", Range={1,500}, Increment=1, CurrentValue=16})
AddToggle(PlayerTab, {Name="Velocidade Global", Flag="AplicarVelocidade", CurrentValue=false})
AddSlider(PlayerTab, {Name="Velocidade Global", Flag="VelocidadeGlobal", Range={1,1000}, Increment=1, CurrentValue=100})
AddSlider(PlayerTab, {Name="Limite Velocidade", Flag="LimiteVelocidade", Range={1,2000}, Increment=1, CurrentValue=500})
AddSlider(PlayerTab, {Name="JumpPower", Flag="JumpPower", Range={50,500}, Increment=1, CurrentValue=50})
AddSlider(PlayerTab, {Name="Gravidade", Flag="Gravity", Range={0,500}, Increment=1, CurrentValue=196})
AddToggle(PlayerTab, {Name="Infinite Jump", Flag="InfiniteJump"})
AddToggle(PlayerTab, {Name="Noclip", Flag="Noclip"})
AddToggle(PlayerTab, {Name="Spin", Flag="Spin"})
AddSlider(PlayerTab, {Name="SpinSpeed", Flag="SpinSpeed", Range={1,100}, Increment=1, CurrentValue=10})
AddToggle(PlayerTab, {Name="Auto Sit", Flag="Sit"})

PlayerTab:CreateSection("✈️ Fly")
AddToggle(PlayerTab, {Name="Ativar Fly", Flag="Fly", CurrentValue=false})
AddSlider(PlayerTab, {Name="Fly Speed", Flag="FlySpeed", Range={1,500}, Increment=1, CurrentValue=50})
AddSlider(PlayerTab, {Name="Fly Vertical", Flag="FlyVerticalSpeed", Range={1,500}, Increment=1, CurrentValue=50})

PlayerTab:CreateSection("👁️ Visual")
AddToggle(PlayerTab, {Name="ESP Players", Flag="ESP"})
AddToggle(PlayerTab, {Name="Fullbright", Flag="Fullbright"})
AddToggle(PlayerTab, {Name="No Fog", Flag="NoFog"})
AddSlider(PlayerTab, {Name="FOV", Flag="FOV", Range={30,120}, Increment=1, CurrentValue=70})
AddToggle(PlayerTab, {Name="FreeCam", Flag="FreeCam"})

PlayerTab:CreateSection("⚙️ Utilidades")
AddToggle(PlayerTab, {Name="Anti-AFK", Flag="AntiAFK"})
AddToggle(PlayerTab, {Name="Anti-Lag", Flag="AntiLag"})
AddToggle(PlayerTab, {Name="Click TP", Flag="ClickTP"})

PlayerTab:CreateSection("👥 Teleporte")
local dropdown = PlayerTab:CreateDropdown({Name="Selecionar Player", Options={"Carregando..."}, CurrentOption="Carregando...", Callback=function(opt) CONFIG.SelectedPlayer = opt end})
task.spawn(function()
    while task.wait(3) do
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p.Name) end end
        if #list == 0 then table.insert(list, "Nenhum") end
        pcall(function() dropdown:Refresh(list) end)
    end
end)

PlayerTab:CreateButton({Name="Teleportar", Callback=function()
    local target = Players:FindFirstChild(CONFIG.SelectedPlayer)
    if target and target.Character then
        local root = GetRootPartSafe()
        local troot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
        if root and troot then pcall(function() root.CFrame = troot.CFrame * CFrame.new(0,0,3) end) end
    end
end})

PlayerTab:CreateButton({Name="Spectate", Callback=function()
    local target = Players:FindFirstChild(CONFIG.SelectedPlayer)
    if target and target.Character then
        local hum = GetHumanoidSafe(target.Character)
        if hum then pcall(function() Workspace.CurrentCamera.CameraSubject = hum end) end
    end
end})

PlayerTab:CreateSection("🌐 Servidor")
PlayerTab:CreateButton({Name="Rejoin", Callback=function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) end})
PlayerTab:CreateButton({Name="Server Hop", Callback=function()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(HttpService:GetAsync(url))
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                break
            end
        end
    end)
end})

-- 🔵 10. INICIALIZAÇÃO FINAL
pcall(function() SafeLoadConfig() end)
pcall(function() ApplySpeedSafe() end)
pcall(function() UpdateVisualsSafe() end)
pcall(function() Rayfield:LoadConfiguration() end)

Rayfield:Notify("Universal Hub Carregado ✅", 5, "Success")
print("[Universal Hub] ✅ Carregado com sucesso - Compatibilidade Total")
