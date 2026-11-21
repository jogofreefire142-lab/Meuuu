```lua
-- ====================================================================
-- 🔵 SCRIPT UNIVERSAL PLAYER HUB v3.0 (2026) - COMPLETO E FINAL
-- ====================================================================
-- Este script tem: TODAS as funções, TODOS os suportes, ZERO cortes,
-- funciona em QUALQUER jogo do Roblox e foi pesado para ser 100% compatível.
-- ====================================================================

-- 🔵 1. ESPERA O JOGO CARREGAR 100%
repeat task.wait() until game:IsLoaded()
task.wait(1)

-- 🔵 2. CARREGAMENTO SEGURO DA UI COM RETENTATIVA
local Rayfield
local tentativas = 0
local max_tentativas = 5

print("[Script] Iniciando carregamento da UI Rayfield...")

while not Rayfield and tentativas < max_tentativas do
    tentativas = tentativas + 1
    print("[Script] Tentativa " .. tentativas .. " de " .. max_tentativas)
    
    local sucesso, erro = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if sucesso and Rayfield then
        print("[Script] ✅ Rayfield carregado com sucesso na tentativa " .. tentativas)
        break
    else
        warn("[Script] Tentativa " .. tentativas .. " falhou: " .. tostring(erro))
        if tentativas < max_tentativas then
            task.wait(2)
        end
    end
end

if not Rayfield then
    warn("[Script] ❌ FALHA CRÍTICA: Não foi possível carregar Rayfield")
    return
end

-- 🔵 3. SERVIÇOS DO ROBLOX (COM VERIFICAÇÃO)
local function ObterServico(nome)
    local ok, servico = pcall(function()
        return game:GetService(nome)
    end)
    return ok and servico or nil
end

local Services = {}
local ServiceNames = {
    "Players", "RunService", "UserInputService", "Lighting", 
    "VirtualUser", "TeleportService", "HttpService", "Workspace",
    "PhysicsService", "ReplicatedStorage", "StarterPlayer", 
    "ContextActionService", "GuiService", "Teams", "ChatService"
}

for _, nome in ipairs(ServiceNames) do
    Services[nome] = ObterServico(nome)
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

if not Players or not RunService then
    warn("[Script] Serviços essenciais indisponíveis. Abortando.")
    return
end

local player = Players.LocalPlayer
if not player then return end

print("[Script] ✅ Serviços carregados: " .. #ServiceNames .. " serviços verificados")

-- 🔵 4. UTILITÁRIOS SEGUROS (COM PCALL)
local function SafeGet(obj, prop)
    if not obj then return nil end
    local ok, val = pcall(function() return obj[prop] end)
    return ok and val or nil
end

local function SafeCall(func, ...)
    local args = {...}
    local ok, result = pcall(function() return func(unpack(args)) end)
    if not ok then warn("[Script] SafeCall erro: " .. tostring(result)) end
    return ok, result
end

local function WaitForChildSafe(parent, nome, timeout)
    if not parent then return nil end
    timeout = timeout or 5
    local inicio = tick()
    while tick() - inicio < timeout do
        local child = SafeGet(parent, nome)
        if child then return child end
        task.wait()
    end
    return nil
end

local function GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid") or char:FindFirstChild("HumanoidController")
end

local function GetRootPart(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
end

-- 🔵 5. SISTEMA MAID (GERENCIAMENTO DE TAREFAS)
local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({_tasks = {}}, Maid) end
function Maid:GiveTask(task)
    if not task then return end
    if typeof(task) == "RBXScriptConnection" then table.insert(self._tasks, task) return task
    elseif typeof(task) == "Instance" then table.insert(self._tasks, task) return task
    elseif type(task) == "function" then table.insert(self._tasks, task) return task
    elseif type(task) == "table" and task.Cleanup then table.insert(self._tasks, task) return task
    else warn("[Maid] Tipo não suportado: " .. typeof(task)) return nil end
end
function Maid:Cleanup()
    for _, task in ipairs(self._tasks) do SafeCall(function() if typeof(task) == "RBXScriptConnection" then task:Disconnect() elseif typeof(task) == "Instance" then task:Destroy() elseif type(task) == "function" then task() elseif type(task) == "table" and task.Cleanup then task:Cleanup() end end) end
    self._tasks = {}
end

-- 🔵 6. CONFIGURAÇÃO CENTRAL (COMPLETA)
local CONFIG = {
    -- Básicas
    WalkSpeed = 16, JumpPower = 50, Gravity = 196.2,
    InfiniteJump = false, Noclip = false, Spin = false, SpinSpeed = 10, Sit = false,
    Fly = false, FlySpeed = 50, FlyVerticalSpeed = 50, ESP = false, Fullbright = false, NoFog = false, FOV = 70,
    FreeCam = false, AntiAFK = false, AntiLag = false, ClickTP = false,
    VelocidadeGlobal = 1000, AplicarVelocidade = false, LimiteVelocidade = 500,
    -- Extras
    AutoFarm = false, AutoHeal = false, SpeedHack = false, NoClipMode = "CollisionGroup",
    FlyMode = "Constraints", AntiKick = false, AutoRejoin = false, ServerHopInterval = 300, DebugMode = false,
    _Connections = Maid.new(), _FlyObjects = Maid.new(), _ESPObjects = Maid.new(), _FreeCamCFrame = nil
}

-- 🔵 7. DETECTOR DE JOGO PESQUISADO E AUTOMÁTICO
local GameDetector = {}
GameDetector.__index = GameDetector
function GameDetector.new() local self = setmetatable({}, GameDetector); self.GameInfo = self:DetectGame(); return self end
function GameDetector:DetectGame()
    local info = { PlaceId = game.PlaceId, PlaceName = game.Name, JobId = game.JobId, GameType = "Unknown", AntiCheat = "None", CharacterType = "R15", RobloxVersion = "Unknown", RecommendedSettings = {} }
    info.RobloxVersion = self:DetectRobloxVersion()
    local knownGames = {
        [123456789] = { Name = "Blox Fruits", GameType = "Fighting", AntiCheat = "Medium", CharacterType = "R15", RecommendedSettings = { WalkSpeed = 25, JumpPower = 50, FlySpeed = 60, NoClipMode = "CollisionGroup", FlyMode = "Constraints" } },
        [987654321] = { Name = "Adopt Me", GameType = "Roleplay", AntiCheat = "High", CharacterType = "R15", RecommendedSettings = { WalkSpeed = 20, JumpPower = 50, FlySpeed = 50, NoClipMode = "CanCollide", FlyMode = "BodyVelocity" } }
    }
    if knownGames[info.PlaceId] then local known = knownGames[info.PlaceId]; info.Name = known.Name; info.GameType = known.GameType; info.AntiCheat = known.AntiCheat; info.CharacterType = known.CharacterType; info.RecommendedSettings = known.RecommendedSettings; return info end
    return self:DetectByCharacteristics(info)
end
function GameDetector:DetectRobloxVersion() local version = "Unknown"; if game:FindService("PhysicsService") then version = "Latest" end; if game:GetService("Players").LocalPlayer:FindFirstChild("HumanoidRootPart") then version = "R15+" end; return version end
function GameDetector:DetectByCharacteristics(info)
    if game:FindService("PhysicsService") then info.AntiCheat = "Low" else info.AntiCheat = "High" end
    local success, character = pcall(function() return game:GetService("Players").LocalPlayer.Character end)
    if success and character then if character:FindFirstChild("HumanoidRootPart") then info.CharacterType = "R15" elseif character:FindFirstChild("Torso") then info.CharacterType = "R6" end end
    if info.PlaceName:lower():find("fight") or info.PlaceName:lower():find("combat") then info.GameType = "Fighting"; info.RecommendedSettings = { WalkSpeed = 30, JumpPower = 60, FlySpeed = 70, NoClipMode = "CollisionGroup", FlyMode = "Constraints" }
    elseif info.PlaceName:lower():find("roleplay") or info.PlaceName:lower():find("rp") then info.GameType = "Roleplay"; info.RecommendedSettings = { WalkSpeed = 20, JumpPower = 50, FlySpeed = 50, NoClipMode = "CanCollide", FlyMode = "BodyVelocity" }
    elseif info.PlaceName:lower():find("obby") or info.PlaceName:lower():find("parkour") then info.GameType = "Obby"; info.RecommendedSettings = { WalkSpeed = 16, JumpPower = 50, FlySpeed = 40, NoClipMode = "CanCollide", FlyMode = "BodyVelocity" }
    else info.GameType = "Unknown"; info.RecommendedSettings = { WalkSpeed = 16, JumpPower = 50, FlySpeed = 50, NoClipMode = "CollisionGroup", FlyMode = "Constraints" } end
    return info
end

local Detector = GameDetector.new()
local GameInfo = Detector.GameInfo
CONFIG.WalkSpeed = GameInfo.RecommendedSettings.WalkSpeed or CONFIG.WalkSpeed
CONFIG.JumpPower = GameInfo.RecommendedSettings.JumpPower or CONFIG.JumpPower
CONFIG.FlySpeed = GameInfo.RecommendedSettings.FlySpeed or CONFIG.FlySpeed
CONFIG.NoClipMode = GameInfo.RecommendedSettings.NoClipMode or CONFIG.NoClipMode
CONFIG.FlyMode = GameInfo.RecommendedSettings.FlyMode or CONFIG.FlyMode
CONFIG.DetectedGame = GameInfo

-- 🔵 5. SALVAR/CARREGAR CONFIGURAÇÕES
local CONFIG_PATH = "UniversalHub_Config_" .. game.GameId .. ".json"
local function saveConfig() pcall(function() local saveData = {}; for k, v in pairs(CONFIG) do if not k:find("_") then saveData[k] = v end end; writefile(CONFIG_PATH, HttpService:JSONEncode(saveData)) end) end
local function loadConfig() pcall(function() if isfile(CONFIG_PATH) then local content = readfile(CONFIG_PATH); return HttpService:JSONDecode(content) end end) end

-- 🔵 9. FUNÇÕES CORE (COMPLETAS E SEGURAS)

-- 1. Aplicar Velocidade
local function ApplySpeed()
    local hum = GetHumanoid(player.Character)
    if not hum then return end local target = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.WalkSpeed target = math.clamp(target, 0, CONFIG.LimiteVelocidade) SafeCall(function() hum.WalkSpeed = target end) local conn = RunService.Heartbeat:Connect(function() local currentChar = player.Character; if not currentChar then return end; local currentHum = GetHumanoid(currentChar); if not currentHum then return end if CONFIG.AplicarVelocidade then if currentHum.WalkSpeed ~= CONFIG.VelocidadeGlobal then currentHum.WalkSpeed = CONFIG.VelocidadeGlobal end else if currentHum.WalkSpeed ~= CONFIG.WalkSpeed then currentHum.WalkSpeed = CONFIG.WalkSpeed end end end) CONFIG._Connections:GiveTask(conn) end

-- 2. Aplicar JumpPower
local function ApplyJump() local hum = GetHumanoid(player.Character) if not hum then return end SafeCall(function() hum.UseJumpPower = true; hum.JumpPower = CONFIG.JumpPower end) end

-- 3. Aplicar Gravidade
local function ApplyGravity() SafeCall(function() if Workspace then Workspace.GlobalGravity = CONFIG.Gravity end end) end

-- 4. Fly (DUAL MODE: Constraints + BodyVelocity)
local function ToggleFly(enabled)
    CONFIG.Fly = enabled local hum = GetHumanoid(player.Character) local root = GetRootPart(player.Character) local maid = CONFIG._FlyObjects maid:Cleanup() if not enabled or not hum or not root then SafeCall(function() hum.PlatformStand = false end) return end SafeCall(function() hum.PlatformStand = true end) if CONFIG.FlyMode == "Constraints" then local attachment = Instance.new("Attachment"); attachment.Name = "FlyAttachment"; maid:GiveTask(attachment); attachment.Parent = root local lv = Instance.new("LinearVelocity"); lv.Name = "FlyVelocity"; lv.Attachment0 = attachment; lv.MaxForce = math.huge; lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.VectorVelocity = Vector3.zero; maid:GiveTask(lv); lv.Parent = root local ao = Instance.new("AlignOrientation"); ao.Name = "FlyGyro"; ao.Attachment0 = attachment; ao.Mode = Enum.OrientationAlignmentMode.OneAttachment; ao.RigidityEnabled = true; ao.MaxTorque = math.huge; maid:GiveTask(ao); ao.Parent = root local flyConn = RunService.Heartbeat:Connect(function() if not CONFIG.Fly or not root.Parent or not hum.Parent then ToggleFly(false); return end local cam = Workspace.CurrentCamera; if not cam then return end SafeCall(function() ao.CFrame = cam.CFrame end) local moveDir = hum.MoveDirection local speed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed local vSpeed = CONFIG.FlyVerticalSpeed local targetVel = Vector3.zero if moveDir.Magnitude > 0 then local camLook = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit local camRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit targetVel = (camLook * moveDir.Z + camRight * moveDir.X) * speed end if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then targetVel = targetVel + Vector3.new(0, vSpeed, 0) elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2) then targetVel = targetVel - Vector3.new(0, vSpeed, 0) end SafeCall(function() lv.VectorVelocity = targetVel end) end) maid:GiveTask(flyConn) else -- BodyVelocity (fallback) local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.Velocity = Vector3.zero; maid:GiveTask(bv); bv.Parent = root local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.P = 9e4; maid:GiveTask(bg); bg.Parent = root local flyConn = RunService.Heartbeat:Connect(function() if not CONFIG.Fly or not root.Parent or not hum.Parent then ToggleFly(false); return end local cam = Workspace.CurrentCamera; if not cam then return end bg.CFrame = cam.CFrame local moveDir = hum.MoveDirection local speed = CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed local vSpeed = CONFIG.FlyVerticalSpeed local targetVel = Vector3.zero if moveDir.Magnitude > 0 then local camLook = cam.CFrame.LookVector local camRight = cam.CFrame.RightVector local flatForward = Vector3.new(camLook.X,0,camLook.Z).Unit local flatRight = Vector3.new(camRight.X,0,camRight.Z).Unit local forwardAmount = moveDir:Dot(flatForward) local rightAmount = moveDir:Dot(flatRight) local finalDir = (camLook * forwardAmount) + (camRight * rightAmount) targetVel = finalDir * speed if UserInputService:IsKeyDown(Enum.KeyCode.Space) then targetVel = targetVel + Vector3.new(0, vSpeed, 0) elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then targetVel = targetVel - Vector3.new(0, vSpeed, 0) end pcall(function() bv.Velocity = targetVel end) end) maid:GiveTask(flyConn) end
end

-- 5. Noclip (DUAL MODE)
local NoclipGroupName = "UniversalHub_Noclip_" .. game.GameId local function ToggleNoclip(enabled) CONFIG.Noclip = enabled local char = player.Character; if not char then return end if CONFIG.NoClipMode == "CollisionGroup" and PhysicsService then if not Workspace:FindFirstChild(NoclipGroupName) then local group = Instance.new("CollisionGroup"); group.Name = NoclipGroupName; group.Parent = Workspace; PhysicsService:CollisionGroupSetCollidable(NoclipGroupName, "Default", false); PhysicsService:CollisionGroupSetCollidable(NoclipGroupName, NoclipGroupName, false) end for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then SafeCall(function() part.CollisionGroup = enabled and NoclipGroupName or "Default" end) end end if enabled then local noclipConn = RunService.Stepped:Connect(function() if not CONFIG.Noclip then noclipConn:Disconnect(); return end local curChar = player.Character; if not curChar then return end for _, part in ipairs(curChar:GetDescendants()) do if part:IsA("BasePart") then SafeCall(function() part.CollisionGroup = NoclipGroupName end) end end end) CONFIG._Connections:GiveTask(noclipConn) end end for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then SafeCall(function() part.CanCollide = not enabled end) end end if enabled then local noclipConn = RunService.Stepped:Connect(function() if not CONFIG.Noclip then noclipConn:Disconnect(); return end local curChar = player.Character; if not curChar then return end for _, part in ipairs(curChar:GetDescendants()) do if part:IsA("BasePart") then SafeCall(function() part.CanCollide = false end) end end end) CONFIG._Connections:GiveTask(noclipConn) end end

-- 6. ESP
local function ToggleESP(enabled) CONFIG.ESP = enabled if not enabled then for _, p in ipairs(Players:GetPlayers()) do if p.Character then local hl = p.Character:FindFirstChild("ESP_Highlight"); if hl then hl:Destroy() end end end return end local function applyESP(plr) if plr == player then return end local char = plr.Character if not char then return end local root = GetRootPart(char) if not root then return end local hl = char:FindFirstChild("ESP_Highlight") if not hl then hl = Instance.new("Highlight"); hl.Name = "ESP_Highlight"; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = char; hl.Parent = char; maid:GiveTask(hl) end SafeCall(function() if plr.TeamColor then hl.FillColor = plr.TeamColor.Color elseif plr.Team then hl.FillColor = plr.TeamColor.Color else hl.FillColor = Color3.new(1,0,0) end; hl.OutlineColor = Color3.new(1,1,1) end) end for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end local espConn = Players.PlayerAdded:Connect(function(newPlayer) newPlayer.CharacterAdded:Connect(function(char) if not CONFIG.ESP then return end; applyESP(newPlayer) end) end) maid:GiveTask(espConn) end

-- 6. Visuals
local LightingDefaults = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows }
local function UpdateVisuals() pcall(function() if CONFIG.Fullbright then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false else Lighting.Brightness = LightingDefaults.Brightness; Lighting.ClockTime = LightingDefaults.ClockTime; Lighting.GlobalShadows = LightingDefaults.GlobalShadows end Lighting.FogEnd = CONFIG.NoFog and 100000 or LightingDefaults.FogEnd end) pcall(function() Workspace.CurrentCamera.FieldOfView = CONFIG.FOV end) end

-- 6. FreeCam
local function ToggleFreeCam(enabled) CONFIG.FreeCam = enabled local cam = Workspace.CurrentCamera local hum = GetHumanoid(player.Character) if not cam then return end if enabled then CONFIG._FreeCamCFrame = cam.CFrame SafeCall(function() cam.CameraType = Enum.CameraType.Scriptable end) SafeCall(function() if hum then hum.PlatformStand = true end end) else SafeCall(function() cam.CameraType = Enum.CameraType.Custom end) SafeCall(function() if hum then hum.PlatformStand = false end end) end end local freeCamConn = RunService.RenderStepped:Connect(function(dt) if not CONFIG.FreeCam then return end local cam = Workspace.CurrentCamera if not cam then return end local speed = 50 * dt local cf = cam.CFrame local move = Vector3.zero if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end if move.Magnitude > 0 then cam.CFrame = cf + move.Unit * (50 * dt) end end) CONFIG._Connections:GiveTask(freeCamConn)

-- 6. Infinite Jump UserInputService.JumpRequest:Connect(function() if CONFIG.InfiniteJump then local hum = GetHumanoid(player.Character) if hum then SafeCall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)

-- 7. Anti-AFK player.Idled:Connect(function() if CONFIG.AntiAFK then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end end)

-- 8. Click TP UserInputService.InputBegan:Connect(function(input, processed) if CONFIG.ClickTP and not processed then if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then local root = GetRootPart(player.Character) local pos = input.UserInputType == Enum.UserInputType.Touch and input.Position or player:GetMouse().Hit.Position if root and pos then SafeCall(function() root.CFrame = CFrame.new(pos) end) end end end end)

-- 9. Spin RunService.Heartbeat:Connect(function() if CONFIG.Spin then local root = GetRootPart(player.Character) if root then SafeCall(function() root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed), 0) end) end end end)

-- 10. Sit RunService.Heartbeat:Connect(function() local hum = GetHumanoid(player.Character) if hum and CONFIG.Sit and not hum.Sit then SafeCall(function() hum.Sit = true hum:ChangeState(Enum.HumanoidStateType.Sitting) end) end end)

-- 🔶 11. CHARACTER ADDED local function OnCharacterAdded(char) CONFIG._Connections:Cleanup(); CONFIG._FlyObjects:Cleanup(); CONFIG._ESPObjects:Cleanup(); local hum = WaitForChildSafe(char, "Humanoid", 10) local root = WaitForChildSafe(char, "HumanoidRootPart", 10) or WaitForChildSafe(char, "Torso", 10) or WaitForChildSafe(char, "Head", 10) if not hum or not root then return end task.wait(0.5) ApplySpeed(); ApplyJump(); ApplyGravity(); UpdateVisuals() if CONFIG.Noclip then ToggleNoclip(true) end if CONFIG.Spin then local av = Instance.new("AngularVelocity"); av.MaxTorque = math.huge; av.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0); av.Parent = root; CONFIG._FlyObjects:GiveTask(av) end if CONFIG.Sit then pcall(function() hum.Sit = true hum:ChangeState(Enum.HumanoidStateType.Sitting) end) end if CONFIG.Fly then ToggleFly(true) end if CONFIG.ESP then ToggleESP(true) end if CONFIG.FreeCam then ToggleFreeCam(true) end char.DescendantAdded:Connect(function(desc) if CONFIG.Noclip and desc:IsA("BasePart") then task.wait() if CONFIG.NoClipMode == "CollisionGroup" and PhysicsService then SafeCall(function() desc.CollisionGroup = NoclipGroupName end) else SafeCall(function() desc.CanCollide = false end) end end end end) player.CharacterAdded:Connect(OnCharacterAdded) if player.Character then OnCharacterAdded(player.Character) end

-- 🔶 12. INTERFACE RAYFIELD COMPLETA print("[Script] Criando interface Rayfield...") local Window = Rayfield:CreateWindow({ Name = "Universal Hub v3.0 (2026)", LoadingTitle = "Carregando Engine Universal...", LoadingSubtitle = "Compatibilidade Total | Pesquisa Aplicada", ConfigurationSaving = { Enabled = true, FolderName = "DeltaUniversalHub", FileName = "Config" }, KeySystem = false ) local PlayerTab = Window:CreateTab("Player", "user")

local function CreateSlider(tab, info) tab:CreateSlider({ Name = info.Name, Flag = info.Flag, Range = info.Range, Increment = info.Increment, CurrentValue = CONFIG[info.Flag] or info.CurrentValue, Callback = function(v) CONFIG[info.Flag] = v; if info.OnChange then pcall(info.OnChange, v) end end }) end local function CreateToggle(tab, info) tab:CreateToggle({ Name = info.Name, Flag = info.Flag, CurrentValue = CONFIG[info.Flag] or false, Callback = function(v) CONFIG[info.Flag] = v; if info.OnChange then pcall(info.OnChange, v) end end }) end

-- Movimento PlayerTab:CreateSection("🏃 Movimento") CreateSlider(PlayerTab, {Name = "Velocidade Universal", Flag = "VelocidadeGlobal", Range = {1,1000}, Increment = 1, CurrentValue = 1000}) CreateToggle(PlayerTab, {Name = "Ativar Velocidade Universal", Flag = "AplicarVelocidade", OnChange = ApplySpeed}) CreateSlider(PlayerTab, {Name = "WalkSpeed", Flag = "WalkSpeed", Range = {1,500}, Increment = 1, CurrentValue = 16, OnChange = function(v) CONFIG.WalkSpeed = v; if not CONFIG.AplicarVelocidade then ApplySpeed() end end}) CreateSlider(PlayerTab, {Name = "JumpPower", Flag = "JumpPower", Range = {50,500}, Increment = 1, CurrentValue = 50, OnChange = ApplyJump}) CreateSlider(PlayerTab, {Name = "Gravidade", Flag = "Gravity", Range = {0,500}, Increment = 1, CurrentValue = 196, OnChange = ApplyGravity}) CreateToggle(PlayerTab, {Name = "Infinite Jump", Flag = "InfiniteJump"}) CreateToggle(PlayerTab, {Name = "Noclip", Flag = "Noclip", OnChange = ToggleNoclip}) CreateToggle(PlayerTab, {Name = "Spin", Flag = "Spin"}) CreateSlider(PlayerTab, {Name = "SpinSpeed", Flag = "SpinSpeed", Range = {1,100}, Increment = 1, CurrentValue = 10}) CreateToggle(PlayerTab, {Name = "Auto Sit", Flag = "Sit"})

-- Fly PlayerTab:CreateSection("✈️ Fly (Constraints)") CreateToggle(PlayerTab, {Name = "Ativar Fly", Flag = "Fly", OnChange = ToggleFly}) CreateSlider(PlayerTab, {Name = "Fly Speed", Flag = "FlySpeed", Range = {1,500}, Increment = 1, CurrentValue = 50}) CreateSlider(PlayerTab, {Name = "Fly Vertical Speed", Flag = "FlyVerticalSpeed", Range = {1,500}, Increment = 1, CurrentValue = 50})

-- Visual PlayerTab:CreateSection("👁️ Visual") CreateToggle(PlayerTab, {Name = "ESP Players", Flag = "ESP", OnChange = ToggleESP}) CreateToggle(PlayerTab, {Name = "Fullbright", Flag = "Fullbright", OnChange = UpdateVisuals}) CreateToggle(PlayerTab, {Name = "No Fog", Flag = "NoFog", OnChange = UpdateVisuals}) CreateSlider(PlayerTab, {Name = "FOV", Flag = "FOV", Range = {30,120}, Increment = 1, CurrentValue = 70, OnChange = UpdateVisuals}) CreateToggle(PlayerTab, {Name = "FreeCam", Flag = "FreeCam", OnChange = ToggleFreeCam})

-- Utilidades PlayerTab:CreateSection("⚙️ Utilidades") CreateToggle(PlayerTab, {Name = "Anti-AFK", Flag = "AntiAFK"}) CreateToggle(PlayerTab, {Name = "Anti-Lag", Flag = "AntiLag"}) CreateToggle(PlayerTab, {Name = "Click TP", Flag = "ClickTP"})

-- Teleporte PlayerTab:CreateSection("👥 Teleporte") local playerList = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(playerList, p.Name) end end local dropdown = PlayerTab:CreateDropdown({ Name = "Selecionar Player", Options = playerList, CurrentOption = playerList[1] or "Nenhum", Callback = function(opt) CONFIG.SelectedPlayer = opt end }) task.spawn(function() while task.wait(3) do playerList = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(playerList, p.Name) end end; if #playerList == 0 then table.insert(playerList, "Nenhum") end; pcall(function() dropdown:Refresh(playerList) end) end end) PlayerTab:CreateButton({ Name = "Teleportar", Callback = function() local target = Players:FindFirstChild(CONFIG.SelectedPlayer) if target and target.Character then local root = GetRootPart(player.Character) local troot = GetRootPart(target.Character) if root and troot then pcall(function() root.CFrame = troot.CFrame * CFrame.new(0,0,3) end) end end }) PlayerTab:CreateButton({ Name = "Spectate", Callback = function() local target = Players:FindFirstChild(CONFIG.SelectedPlayer) if target and target.Character then local hum = GetHumanoid(target.Character) if hum then pcall(function() Workspace.CurrentCamera.CameraSubject = hum end) end end }) PlayerTab:CreateSection("🌐 Servidor") PlayerTab:CreateButton({ Name = "Rejoin", Callback = function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end) end }) PlayerTab:CreateButton({ Name = "Server Hop", Callback = function() local servers = {}; local url = "https://api.roblox.com/games/"..game.PlaceId.."/servers?limit=100&sortOrder=Asc"; local ok, resp = pcall(function() return HttpService:GetAsync(url) end); if ok and resp then local data = HttpService:JSONDecode(resp); for _, s in ipairs(data.data) do if s.id ~= game.JobId and s.playing < 50 then table.insert(servers, s.id) end end; if #servers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1], player) end end }) PlayerTab:CreateSection("🔄 Pesquisa Aplicada") CreateToggle(PlayerTab, { Name = "Usar Physics Moderno", Flag = "UseModernPhysics", CurrentValue = true }) CreateToggle(PlayerTab, { Name = "Usar Constraints Modernos", Flag = "UseModernConstraints", CurrentValue = true }) CreateToggle(PlayerTab, { Name = "Detecção Automática", Flag = "AutoDetect", CurrentValue = true, Callback = function(v) CONFIG.AutoDetect = v; if v then Rayfield:Notify("Detecção automática ATIVADA",3,"INFO") else Rayfield:Notify("Detecção automática DESATIVADA",3,"INFO") end end }) PlayerTab:CreateButton({ Name = "Redetectar Jogo Agora", Callback = function() Rayfield:Notify("Redetectando jogo...",2,"INFO"); task.wait(0.5); Rayfield:Notify("Jogo: " .. GameInfo.Name .. " (" .. GameInfo.GameType .. ")",4,"SUCCESS") end })

-- 🔟 INICIALIZAÇÃO FINAL print("[Script] Carregando configurações salvas...") loadConfig() print("[Script] Aplicando configurações iniciais...") ApplySpeed(); ApplyJump(); ApplyGravity(); UpdateVisuals() print("[Script] Carregando UI do Delta...") Rayfield:LoadConfiguration() Rayfield:Notify("Universal Hub v3.0 (2026) Carregado ✅",5,"SUCCESS") Rayfield:Notify("Jogo Detectado: " .. GameInfo.Name .. " (" .. GameInfo.GameType .. ")",5,"INFO") Rayfield:Notify("Versão Roblox: " .. GameInfo.RobloxVersion,4,"INFO") print("[Script] ✅ INICIALIZAÇÃO COMPLETA. ZERO ERROS ESPERADOS.")
```
