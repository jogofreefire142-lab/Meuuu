-- 🔵 1. ESPERA O JOGO ESTAR CARREGADO
repeat task.wait() until game:IsLoaded()
task.wait(1)

-- 🔵 2. CARREGAMENTO SEGURO DA UI
local Rayfield
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not success or not Rayfield then
    warn("[Universal Hub] Falha ao carregar Rayfield: " .. tostring(err))
    return
end

-- 🔵 3. SERVIÇOS COM VERIFICAÇÃO COMPLETA
local function GetService(name)
    local ok, service = pcall(function() return game:GetService(name) end)
    return ok and service or nil
end

-- Lista completa de serviços com verificação
local Services = {}
local ServiceNames = {
    "Players", "RunService", "UserInputService", "Lighting", 
    "VirtualUser", "TeleportService", "HttpService", "Workspace",
    "PhysicsService", "ReplicatedStorage", "StarterPlayer", 
    "ContextActionService", "GuiService", "Teams", "Players"
}

for _, name in ipairs(ServiceNames) do
    Services[name] = GetService(name)
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
local ReplicatedStorage = Services.ReplicatedStorage
local StarterPlayer = Services.StarterPlayer
local ContextActionService = Services.ContextActionService
local GuiService = Services.GuiService

-- Verificação de serviços essenciais
if not Players or not RunService then
    warn("[Universal Hub] Serviços essenciais ausentes. Abortando.")
    return
end

local player = Players.LocalPlayer
if not player then return end

-- 🔵 4. UTILITÁRIOS DE SEGURANÇA COMPLETOS
local function SafeGet(obj, prop)
    if not obj then return nil end
    local ok, value = pcall(function() return obj[prop] end)
    return ok and value or nil
end

local function SafeCall(func, ...)
    local args = {...}
    local ok, result = pcall(function() return func(unpack(args)) end)
    return ok, result
end

local function WaitForChildSafe(parent, name, timeout)
    if not parent then return nil end
    timeout = timeout or 5
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
    -- Tentativa múltipla para diferentes tipos de humanoid
    return char:FindFirstChildOfClass("Humanoid") or 
           char:FindFirstChild("Humanoid") or
           char:FindFirstChild("HumanoidController")
end

local function GetRootPart(char)
    if not char then return nil end
    -- Tentativa múltipla para diferentes tipos de root parts
    return char:FindFirstChild("HumanoidRootPart") or 
           char:FindFirstChild("Torso") or
           char:FindFirstChild("UpperTorso") or
           char:FindFirstChild("Head") or
           char:FindFirstChild("RootPart") or
           char:FindFirstChild("PrimaryPart")
end

-- 🔵 5. SISTEMA MAID MELHORADO
local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({_tasks = {}}, Maid) end

function Maid:GiveTask(task)
    if not task then return end
    
    -- Tratamento para diferentes tipos de task
    if typeof(task) == "RBXScriptConnection" then
        table.insert(self._tasks, task)
        return task
    elseif typeof(task) == "Instance" then
        table.insert(self._tasks, task)
        return task
    elseif type(task) == "function" then
        table.insert(self._tasks, task)
        return task
    elseif type(task) == "table" and task.Cleanup then
        table.insert(self._tasks, task)
        return task
    else
        warn("[Maid] Tipo de task não suportado: " .. typeof(task))
        return nil
    end
end

function Maid:Cleanup()
    for _, task in ipairs(self._tasks) do
        SafeCall(function()
            if typeof(task) == "RBXScriptConnection" then
                task:Disconnect()
            elseif typeof(task) == "Instance" then
                task:Destroy()
            elseif type(task) == "function" then
                task()
            elseif type(task) == "table" and task.Cleanup then
                task:Cleanup()
            end
        end)
    end
    self._tasks = {}
end

-- 🔵 6. CONFIGURAÇÃO CENTRAL COM VALORES PADRÃO
local CONFIG = {
    -- Configurações básicas
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
    FlyVerticalSpeed = 50,
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
    LimiteVelocidade = 500,
    
    -- Configurações extras para diferentes tipos de jogo
    AutoFarm = false,
    AutoHeal = false,
    SpeedHack = false,
    NoClipMode = "CollisionGroup",
    FlyMode = "Constraints",
    AntiKick = false,
    AutoRejoin = false,
    ServerHopInterval = 300,
    DebugMode = false, -- Para debug
    
    -- Internos
    _Connections = Maid.new(),
    _FlyObjects = Maid.new(),
    _ESPObjects = Maid.new(),
    _FreeCamCFrame = nil
}

-- 🔵 7. SALVAR / CARREGAR CONFIGURAÇÕES COM TRATAMENTO DE ERRO
local CONFIG_PATH = "UniversalHub_Config_" .. game.GameId .. ".json"

local function saveConfig()
    local success, err = pcall(function()
        -- Remove propriedades internas antes de salvar
        local saveData = {}
        for k, v in pairs(CONFIG) do
            if not k:find("_") then -- Não salva propriedades que começam com _
                saveData[k] = v
            end
        end
        local data = HttpService:JSONEncode(saveData)
        writefile(CONFIG_PATH, data)
        return true
    end)
    
    if success then
        if CONFIG.DebugMode then
            Rayfield:Notify("Configurações salvas!", 3, "SUCCESS")
        end
    else
        Rayfield:Notify("Erro ao salvar: " .. tostring(err), 3, "ERROR")
    end
end

local function loadConfig()
    local success, data = pcall(function()
        if isfile(CONFIG_PATH) then
            local content = readfile(CONFIG_PATH)
            return HttpService:JSONDecode(content)
        end
        return nil
    end)
    
    if success and data then
        for k, v in pairs(data) do
            CONFIG[k] = v
        end
        if CONFIG.DebugMode then
            Rayfield:Notify("Configurações carregadas!", 3, "SUCCESS")
        end
        return true
    end
    return false
end

-- 🔵 8. FUNÇÕES CORE COM TRATAMENTO DE ERRO COMPLETO

-- 8.1 Aplicar Velocidade
local function ApplySpeed()
    local char = player.Character
    if not char then return end
    
    local hum = GetHumanoid(char)
    if not hum then return end
    
    local target = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed
    target = math.clamp(target, 0, CONFIG.LimiteVelocidade)
    
    SafeCall(function() hum.WalkSpeed = target end)
    
    -- Loop de proteção
    local conn = RunService.Heartbeat:Connect(function()
        local currentChar = player.Character
        if not currentChar then return end
        local currentHum = GetHumanoid(currentChar)
        if not currentHum then return end
        
        if CONFIG.AplicarVelocidade then
            if currentHum.WalkSpeed ~= CONFIG.VelocidadeGlobal then
                currentHum.WalkSpeed = CONFIG.VelocidadeGlobal
            end
        else
            if currentHum.WalkSpeed ~= CONFIG.WalkSpeed then
                currentHum.WalkSpeed = CONFIG.WalkSpeed
            end
        end
    end)
    CONFIG._Connections:GiveTask(conn)
end

-- 8.2 Aplicar JumpPower
local function ApplyJump()
    local hum = GetHumanoid(player.Character)
    if not hum then return end
    SafeCall(function()
        hum.UseJumpPower = true
        hum.JumpPower = CONFIG.JumpPower
    end)
end

-- 8.3 Aplicar Gravidade
local function ApplyGravity()
    SafeCall(function()
        if Workspace then
            Workspace.GlobalGravity = CONFIG.Gravity
        end
    end)
end

-- 8.4 Fly - Múltiplos modos com tratamento de erro
local function ToggleFly(enabled)
    CONFIG.Fly = enabled
    local hum = GetHumanoid(player.Character)
    local root = GetRootPart(player.Character)
    local maid = CONFIG._FlyObjects
    maid:Cleanup()

    if not enabled or not hum or not root then
        SafeCall(function() hum.PlatformStand = false end)
        return
    end

    SafeCall(function() hum.PlatformStand = true end)

    -- MODO 1: Constraints (LinearVelocity + AlignOrientation)
    if CONFIG.FlyMode == "Constraints" then
        local attachment = Instance.new("Attachment")
        attachment.Name = "FlyAttachment"
        maid:GiveTask(attachment)
        attachment.Parent = root

        local lv = Instance.new("LinearVelocity")
        lv.Name = "FlyVelocity"
        lv.Attachment0 = attachment
        lv.MaxForce = math.huge
        lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lv.VectorVelocity = Vector3.zero
        maid:GiveTask(lv)
        lv.Parent = root

        local ao = Instance.new("AlignOrientation")
        ao.Name = "FlyGyro"
        ao.Attachment0 = attachment
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.RigidityEnabled = true
        ao.MaxTorque = math.huge
        maid:GiveTask(ao)
        ao.Parent = root

        local flyConn = RunService.Heartbeat:Connect(function()
            if not CONFIG.Fly or not root.Parent or not hum.Parent then
                ToggleFly(false)
                return
            end

            local cam = Workspace.CurrentCamera
            if not cam then return end
            SafeCall(function() ao.CFrame = cam.CFrame end)

            local moveDir = hum.MoveDirection
            local speed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed
            local vSpeed = CONFIG.FlyVerticalSpeed

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

            SafeCall(function() lv.VectorVelocity = targetVel end)
        end)
        maid:GiveTask(flyConn)
    
    -- MODO 2: BodyVelocity (compatível com jogos mais antigos)
    else
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        maid:GiveTask(bv)
        bv.Parent = root
        
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        maid:GiveTask(bg)
        bg.Parent = root
        
        local flyConn = RunService.Heartbeat:Connect(function()
            if not CONFIG.Fly or not root.Parent or not hum.Parent then
                ToggleFly(false)
                return
            end
            
            local cam = Workspace.CurrentCamera
            if not cam then return end
            bg.CFrame = cam.CFrame
            
            local moveDir = hum.MoveDirection
            local speed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed
            local vSpeed = CONFIG.FlyVerticalSpeed
            
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
                targetVel = targetVel + Vector3.new(0, vSpeed, 0)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                targetVel = targetVel - Vector3.new(0, vSpeed, 0)
            end
            
            bv.Velocity = targetVel
        end)
        maid:GiveTask(flyConn)
    end
end

-- 8.5 Noclip - Múltiplos modos com tratamento de erro
local NoclipGroupName = "UniversalHub_NoclipGroup_" .. game.GameId

local function SetupNoclipPhysics()
    if not PhysicsService then return false end
    if not Workspace:FindFirstChild(NoclipGroupName) then
        local group = Instance.new("CollisionGroup")
        group.Name = NoclipGroupName
        group.Parent = Workspace
        PhysicsService:CollisionGroupSetCollidable(NoclipGroupName, "Default", false)
        PhysicsService:CollisionGroupSetCollidable(NoclipGroupName, NoclipGroupName, false)
    end
    return true
end

local function ToggleNoclip(enabled)
    CONFIG.Noclip = enabled
    local char = player.Character
    if not char then return end

    -- MODO 1: CollisionGroup
    if CONFIG.NoClipMode == "CollisionGroup" and PhysicsService then
        if SetupNoclipPhysics() then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    SafeCall(function() part.CollisionGroup = enabled and NoclipGroupName or "Default" end)
                end
            end
            
            if enabled then
                local noclipConn = RunService.Stepped:Connect(function()
                    if not CONFIG.Noclip then
                        noclipConn:Disconnect()
                        return
                    end
                    local curChar = player.Character
                    if not curChar then return end
                    for _, part in ipairs(curChar:GetDescendants()) do
                        if part:IsA("BasePart") then
                            SafeCall(function() part.CollisionGroup = NoclipGroupName end)
                        end
                    end
                end)
                CONFIG._Connections:GiveTask(noclipConn)
            end
            return
        end
    end
    
    -- MODO 2: CanCollide (fallback)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            SafeCall(function() part.CanCollide = not enabled end)
        end
    end
    
    if enabled then
        local noclipConn = RunService.Stepped:Connect(function()
            if not CONFIG.Noclip then
                noclipConn:Disconnect()
                return
            end
            local curChar = player.Character
            if not curChar then return end
            for _, part in ipairs(curChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    SafeCall(function() part.CanCollide = false end)
                end
            end
        end)
        CONFIG._Connections:GiveTask(noclipConn)
    end
end

-- 8.6 ESP - Com tratamento de erro
local function ToggleESP(enabled)
    CONFIG.ESP = enabled
    local maid = CONFIG._ESPObjects
    maid:Cleanup()

    if not enabled then return end

    local function applyESP(plr)
        if plr == player then return end
        local char = plr.Character
        if not char then return end
        
        local root = GetRootPart(char)
        if not root then return end
        
        local hl = char:FindFirstChild("UniversalESP_Highlight")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "UniversalESP_Highlight"
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = char
            hl.Parent = char
            maid:GiveTask(hl)
        end
        
        SafeCall(function()
            if plr.TeamColor then
                hl.FillColor = plr.TeamColor.Color
            elseif plr.Team then
                hl.FillColor = plr.TeamColor.Color
            else
                hl.FillColor = Color3.new(1, 0, 0)
            end
            hl.OutlineColor = Color3.new(1, 1, 1)
        end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        applyESP(p)
    end

    local espConn = Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function(char)
            if not CONFIG.ESP then return end
            applyESP(newPlayer)
        end)
    end)
    maid:GiveTask(espConn)
end

-- 8.7 Fullbright / NoFog / FOV
local LightingDefaults = {Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows}

local function UpdateVisuals()
    SafeCall(function()
        if CONFIG.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = LightingDefaults.Brightness
            Lighting.ClockTime = LightingDefaults.ClockTime
            Lighting.GlobalShadows = LightingDefaults.GlobalShadows
        end
        Lighting.FogEnd = CONFIG.NoFog and 100000 or LightingDefaults.FogEnd
    end)
    SafeCall(function() Workspace.CurrentCamera.FieldOfView = CONFIG.FOV end)
end

-- 8.8 FreeCam
local function ToggleFreeCam(enabled)
    CONFIG.FreeCam = enabled
    local cam = Workspace.CurrentCamera
    local hum = GetHumanoid(player.Character)
    if not cam then return end

    if enabled then
        CONFIG._FreeCamCFrame = cam.CFrame
        SafeCall(function() cam.CameraType = Enum.CameraType.Scriptable end)
        SafeCall(function() if hum then hum.PlatformStand = true end end)
    else
        SafeCall(function() cam.CameraType = Enum.CameraType.Custom end)
        SafeCall(function() if hum then hum.PlatformStand = false end end)
    end
end

local freeCamConn = RunService.RenderStepped:Connect(function(dt)
    if not CONFIG.FreeCam then return end
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

    if move.Magnitude > 0 then
        cam.CFrame = cf + move.Unit * speed
    end
end)
CONFIG._Connections:GiveTask(freeCamConn)

-- 8.9 Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        local hum = GetHumanoid(player.Character)
        if hum then SafeCall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- 8.10 Anti-AFK
player.Idled:Connect(function()
    if CONFIG.AntiAFK then
        SafeCall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
    end
end)

-- 8.11 Click TP
UserInputService.InputBegan:Connect(function(input, processed)
    if CONFIG.ClickTP and not processed then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local root = GetRootPart(player.Character)
            local pos = input.UserInputType == Enum.UserInputType.Touch and input.Position or player:GetMouse().Hit.Position
            if root and pos then SafeCall(function() root.CFrame = CFrame.new(pos) end) end
        end
    end
end)

-- 8.12 Spin
RunService.Heartbeat:Connect(function()
    if CONFIG.Spin then
        local root = GetRootPart(player.Character)
        if root then SafeCall(function() root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed), 0) end) end
    end
end)

-- 8.13 Sit
RunService.Heartbeat:Connect(function()
    local hum = GetHumanoid(player.Character)
    if hum and CONFIG.Sit and not hum.Sit then SafeCall(function() hum.Sit = true end) end
end)

-- 🔵 9. GERENCIAMENTO DE VIDA DO PERSONAGEM
local function OnCharacterAdded(char)
    -- Limpa tudo da vida anterior
    CONFIG._Connections:Cleanup()
    CONFIG._FlyObjects:Cleanup()
    CONFIG._ESPObjects:Cleanup()

    -- Espera componentes vitais
    local hum = WaitForChildSafe(char, "Humanoid", 10)
    local root = WaitForChildSafe(char, "HumanoidRootPart", 10) or 
                 WaitForChildSafe(char, "Torso", 10) or 
                 WaitForChildSafe(char, "Head", 10)
    if not hum or not root then return end

    -- Reaplica config salva
    task.wait(0.5)
    ApplySpeed()
    ApplyJump()
    ApplyGravity()
    UpdateVisuals()

    if CONFIG.Noclip then ToggleNoclip(true) end
    if CONFIG.Spin then
        local av = Instance.new("AngularVelocity")
        av.Attachment0 = root:FindFirstChild("FlyAttachment") or Instance.new("Attachment", root)
        av.MaxTorque = math.huge
        av.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0)
        CONFIG._FlyObjects:GiveTask(av)
        av.Parent = root
    end
    if CONFIG.Sit then SafeCall(function() hum.Sit = true end) end
    if CONFIG.Fly then ToggleFly(true) end
    if CONFIG.ESP then ToggleESP(true) end
    if CONFIG.FreeCam then ToggleFreeCam(true) end

    -- Reconecta Noclip para partes que nascem depois
    char.DescendantAdded:Connect(function(desc)
        if CONFIG.Noclip and desc:IsA("BasePart") then
            task.wait()
            if CONFIG.NoClipMode == "CollisionGroup" and PhysicsService then
                SafeCall(function() desc.CollisionGroup = NoclipGroupName end)
            else
                SafeCall(function() desc.CanCollide = false end)
            end
        end
    end)
end

player.CharacterAdded:Connect(OnCharacterAdded)
if player.Character then OnCharacterAdded(player.Character) end

-- 🔵 10. UI – ABA PLAYER
local PlayerTab = Window:CreateTab("Player", "user")

-- Helper: cria Slider com Flag e Callback seguro
local function CreateSlider(tab, info)
    tab:CreateSlider({
        Name = info.Name,
        Flag = info.Flag,
        Range = info.Range,
        Increment = info.Increment,
        CurrentValue = CONFIG[info.Flag] or info.CurrentValue,
        Callback = function(v)
            CONFIG[info.Flag] = v
            if info.OnChange then SafeCall(info.OnChange, v) end
        end
    })
end

-- Helper: cria Toggle com Flag e Callback seguro
local function CreateToggle(tab, info)
    tab:CreateToggle({
        Name = info.Name,
        Flag = info.Flag,
        CurrentValue = CONFIG[info.Flag] or false,
        Callback = function(v)
            CONFIG[info.Flag] = v
            if info.OnChange then SafeCall(info.OnChange, v) end
        end
    })
end

-- 10.1 Movimento
PlayerTab:CreateSection("🏃 Movimento")
CreateSlider(PlayerTab, {Name = "Velocidade Universal", Flag = "VelocidadeGlobal", Range = {1,1000}, Increment = 1, CurrentValue = 1000})
CreateToggle(PlayerTab, {Name = "Ativar Velocidade Universal", Flag = "AplicarVelocidade", OnChange = ApplySpeed})
CreateSlider(PlayerTab, {Name = "WalkSpeed", Flag = "WalkSpeed", Range = {1,500}, Increment = 1, CurrentValue = 16, OnChange = function(v) CONFIG.WalkSpeed = v; if not CONFIG.AplicarVelocidade then ApplySpeed() end})
CreateSlider(PlayerTab, {Name = "JumpPower", Flag = "JumpPower", Range = {50,500}, Increment = 1, CurrentValue = 50, OnChange = ApplyJump})
CreateSlider(PlayerTab, {Name = "Gravidade", Flag = "Gravity", Range = {0,500}, Increment = 1, CurrentValue = 196, OnChange = ApplyGravity})
CreateToggle(PlayerTab, {Name = "Infinite Jump", Flag = "InfiniteJump"})
CreateToggle(PlayerTab, {Name = "Noclip", Flag = "Noclip", OnChange = ToggleNoclip})
CreateToggle(PlayerTab, {Name = "Spin", Flag = "Spin"})
CreateSlider(PlayerTab, {Name = "SpinSpeed", Flag = "SpinSpeed", Range = {1,100}, Increment = 1, CurrentValue = 10})
CreateToggle(PlayerTab, {Name = "Auto Sit", Flag = "Sit"})

-- 10.2 Fly
PlayerTab:CreateSection("✈️ Fly (Constraints)")
CreateToggle(PlayerTab, {Name = "Ativar Fly", Flag = "Fly", OnChange = ToggleFly})
CreateSlider(PlayerTab, {Name = "Fly Speed", Flag = "FlySpeed", Range = {1,500}, Increment = 1, CurrentValue = 50})
CreateSlider(PlayerTab, {Name = "Fly Vertical Speed", Flag = "FlyVerticalSpeed", Range = {1,500}, Increment = 1, CurrentValue = 50})

-- 10.3 Visual
PlayerTab:CreateSection("👁️ Visual")
CreateToggle(PlayerTab, {Name = "ESP Players", Flag = "ESP", OnChange = ToggleESP})
CreateToggle(PlayerTab, {Name = "Fullbright", Flag = "Fullbright", OnChange = UpdateVisuals})
CreateToggle(PlayerTab, {Name = "No Fog", Flag = "NoFog", OnChange = UpdateVisuals})
CreateSlider(PlayerTab, {Name = "FOV", Flag = "FOV", Range = {30,120}, Increment = 1, CurrentValue = 70, OnChange = UpdateVisuals})
CreateToggle(PlayerTab, {Name = "FreeCam", Flag = "FreeCam", OnChange = ToggleFreeCam})

-- 10.4 Utilidades
PlayerTab:CreateSection("⚙️ Utilidades")
CreateToggle(PlayerTab, {Name = "Anti-AFK", Flag = "AntiAFK"})
CreateToggle(PlayerTab, {Name = "Anti-Lag", Flag = "AntiLag"})
CreateToggle(PlayerTab, {Name = "Click TP", Flag = "ClickTP"})

-- 10.5 Teleporte
PlayerTab:CreateSection("👥 Teleporte")
local playerList = {}
local dropdown = PlayerTab:CreateDropdown({
    Name = "Selecionar Player",
    Options = {"Carregando..."},
    CurrentOption = "Carregando...",
    Callback = function(opt) CONFIG.SelectedPlayer = opt end
})
task.spawn(function()
    while task.wait(3) do
        playerList = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then table.insert(playerList, p.Name) end
        end
        if #playerList == 0 then table.insert(playerList, "Nenhum") end
        SafeCall(function() dropdown:Refresh(playerList) end)
    end
end)

PlayerTab:CreateButton({Name = "Teleportar", Callback = function()
    local target = Players:FindFirstChild(CONFIG.SelectedPlayer)
    if target and target.Character then
        local root = GetRootPart(player.Character)
        local troot = GetRootPart(target.Character)
        if root and troot then SafeCall(function() root.CFrame = troot.CFrame * CFrame.new(0,0,3) end) end
    end
end})

PlayerTab:CreateButton({Name = "Spectate", Callback = function()
    local target = Players:FindFirstChild(CONFIG.SelectedPlayer)
    if target and target.Character then
        local hum = GetHumanoid(target.Character)
        if hum then SafeCall(function() Workspace.CurrentCamera.CameraSubject = hum end) end
    end
end})

PlayerTab:CreateSection("🌐 Servidor")
PlayerTab:CreateButton({Name = "Rejoin", Callback = function()
    SafeCall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
end})

PlayerTab:CreateButton({Name = "Server Hop", Callback = function()
    local servers = {}
    local url = "https://api.roblox.com/games/" .. game.PlaceId .. "/servers?limit=100&sortOrder=Asc"
    local success, response = pcall(function() return HttpService:GetAsync(url) end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing < 50 then
                table.insert(servers, s.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1], player)
        end
    end
end})

-- 🔵 11. CARREGAR CONFIGURAÇÕES SALVAS
loadConfig()

-- 🔵 12. APLICAR CONFIGURAÇÕES INICIAIS
ApplySpeed()
ApplyJump()
ApplyGravity()
UpdateVisuals()

-- 🔵 13. CARREGAR UI DO DELTA
Rayfield:LoadConfiguration()

Rayfield:Notify("Universal Hub v3.0 Carregado ✅", 5, "SUCCESS")
print("[Universal Hub] Inicialização completa. Zero erros esperados.")
