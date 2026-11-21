```lua
-- 🔵 0. AUTO-CLEANUP TOPO
if getgenv()._UniversalScriptCleanup then pcall(getgenv()._UniversalScriptCleanup) end

-- 🔵 1. LOAD & SERVICES (WAIT 3s PARA AUTO-EXECUTE DELTA MOBILE)
repeat task.wait() until game:IsLoaded()
task.wait(3)

-- Rayfield via GitHub Raw
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting      = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService   = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace     = game:GetService("Workspace")
local Terrain       = Workspace:FindFirstChildOfClass("Terrain")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlaceId = game.PlaceId

-- ============================================================
-- 🛡️ EXECUTOR CAPABILITIES DETECTION (SEM EXECUTAR HOOKS)
-- ============================================================
local ExecutorCaps = {}
ExecutorCaps.hasWriteFile   = pcall(function() writefile("__UniversalTestCap", "") delfile("__UniversalTestCap") end)
ExecutorCaps.hasRequest     = pcall(function() HttpService:RequestAsync({Url="https://roblox.com", Method="GET"}) end)
ExecutorCaps.hasHookFunc    = type(hookfunction) == "function"
ExecutorCaps.hasGetRawMeta  = type(getrawmetatable) == "function"
ExecutorCaps.hasDrawing     = pcall(function() local d = Drawing.new("Line") d:Remove() end)
ExecutorCaps.hasSetFFlag    = type(setfflag) == "function" -- NOVO: Checagem segura

-- ============================================================
-- 📁 PASTA DEDICADA & CAMINHO DO CONFIG
-- ============================================================
local CONFIG_FOLDER = "UniversalLite_Configs"
local CONFIG_PATH = CONFIG_FOLDER .. "/Config_" .. PlaceId .. ".json"

pcall(function()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end)

-- ============================================================
-- ⚙️ CONFIG — TUDO FALSE POR PADRÃO
-- ============================================================
local CONFIG = {
    -- Visuais
    ESP = false, Fullbright = false, NoFog = false, FOV = 70,
    -- Movimento
    WalkSpeed = 16, JumpPower = 50, Gravity = 1, InfiniteJump = false, Spin = false, SpinSpeed = 10, Sit = false,
    -- Perigosos
    Fly = false, FlySpeed = 50, Noclip = false, ClickTP = false,
    -- Utils
    AntiAFK = false, AntiLag = false, Rejoin = false, ServerHop = false, SelectedPlayer = "Nenhum",
    -- Velocidade Global
    VelocidadeGlobal = 1000, AplicarVelocidade = false, LimiteVelocidade = 1000,
    -- Performance (NOVO)
    FPSBoost_Flags = false,
    -- Interno Watchdog
    _Flags = {}
}

-- ============================================================
-- 💾 AUTO-SAVE / AUTO-LOAD
-- ============================================================
local function saveConfig()
    local data = {}
    for k, v in pairs(CONFIG) do if type(v) ~= "function" and k:sub(1,1) ~= "_" then data[k] = v end end
    local json = HttpService:JSONEncode(data)
    pcall(function() writefile(CONFIG_PATH, json) end)
end

local function loadConfig()
    local success, data = pcall(function()
        if isfile(CONFIG_PATH) then return HttpService:JSONDecode(readfile(CONFIG_PATH)) end
        return nil
    end)
    if success and data then
        for k, v in pairs(data) do if CONFIG[k] ~= nil then CONFIG[k] = v end end
        for k, v in pairs(CONFIG) do if type(v) == "boolean" then CONFIG._Flags[k] = v end end
    end
end

-- ============================================================
-- 🛡️ ANTI-KICK (BEST EFFORT)
-- ============================================================
pcall(function()
    if ExecutorCaps.hasGetRawMeta then
        local mt = getrawmetatable(game)
        if mt and setreadonly then
            local old = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                if self == player and (getnamecallmethod() == "Kick" or getnamecallmethod() == "kick") then
                    warn("[ANTI-KICK] Blocked:", ...)
                    if Rayfield and Rayfield.Notify then Rayfield:Notify({Title="🛡️ Anti-Kick", Content="Kick bloqueado (metatable)", Duration=5, Image="shield"}) end
                    return nil
                end
                return old(self, ...)
            end)
            setreadonly(mt, true)
        end
    end
end)
pcall(function()
    if ExecutorCaps.hasHookFunc then
        local OldKick = hookfunction(player.Kick, function(self, msg)
            if self == player then warn("[ANTI-KICK] Blocked (hook):", msg); if Rayfield and Rayfield.Notify then Rayfield:Notify({Title="🛡️ Anti-Kick", Content="Kick bloqueado (hook)", Duration=5, Image="shield"}) end return end
            return OldKick(self, msg)
        end)
    end
end)

-- ============================================================
-- 🛡️ SAFE CHAR & VIRTUAL INPUT
-- ============================================================
local function SafeGetHum(char) char = char or player.Character; if not char then return nil end; return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildWhichIsA("Humanoid", true) end
local function SafeGetRoot(char) char = char or player.Character; if not char then return nil end; local hum = SafeGetHum(char); if hum and hum.RootPart then return hum.RootPart end; return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart") end
local function VInput_Click(x,y) pcall(function() VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0) task.wait(0.02) VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0) end) end
local function VInput_Key(k,down) pcall(function() VirtualInputManager:SendKeyEvent(down,k,false,game) end) end

-- ============================================================
-- 🛡️ WATCHDOG & UI_FLAGS
-- ============================================================
local UI_Flags = {}
local Watchdog = { Errors={}, MaxErrors=3, Connections={} }
function Watchdog:Wrap(name, func, interval)
    interval = interval or 0
    if self.Connections[name] then self.Connections[name]:Disconnect() end
    self.Errors[name] = 0
    local lastRun = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        if not CONFIG._Flags[name] then return conn:Disconnect() end
        if interval > 0 and tick() - lastRun < interval then return end
        if interval > 0 then lastRun = tick() end
        local ok, err = pcall(func, dt)
        if not ok then self.Errors[name] = (self.Errors[name] or 0) + 1; warn(`[WATCHDOG] {name} Error [{self.Errors[name]}/{self.MaxErrors}]: {err}`); if self.Errors[name] >= self.MaxErrors then self:ForceDisable(name, tostring(err)) end else self.Errors[name] = 0 end
    end)
    self.Connections[name] = conn
    return conn
end
function Watchdog:ForceDisable(flagName, reason)
    if not CONFIG._Flags[flagName] then return end
    CONFIG._Flags[flagName] = false; CONFIG[flagName] = false
    if UI_Flags[flagName] then pcall(function() UI_Flags[flagName]:Set(false) end) end
    if Rayfield and Rayfield.Notify then Rayfield:Notify({Title="🛡️ WATCHDOG", Content=flagName.." desligado: "..reason, Duration=6, Image="alert-triangle"}) end
end

-- ============================================================
// 🧠 ESTADOS INTERNOS PARA RESTAURAÇÃO (FULLBRIGHT / NOFOG / FPSBOOST)
// ============================================================
local OriginalLightingProps = {}
local OriginalAtmosphereProps = {}
local FPSBoost_TrackedChanges = { Materials = {}, Particles = {}, LightingProps = {} }

// ============================================================
// 🧠 HELPERS GERAIS
// ============================================================
local function getHum() return SafeGetHum() end
local function getRoot() return SafeGetRoot() end
local function limitSpeed(s) return math.min(s, CONFIG.LimiteVelocidade) end

local function applyPhysics()
    local hum = getHum()
    if hum then hum.WalkSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed); hum.JumpPower = CONFIG.JumpPower; hum.UseJumpPower = true; if CONFIG.Sit then hum.Sit = true end end
    workspace.Gravity = CONFIG.Gravity * 196.2
end

// ============================================================
// 1. ESP BLINDADO v2 (HIGHLIGHT + BILLBOARD + PERSISTÊNCIA)
// ============================================================
local ESP_Highlights = {}
local ESP_Billboards = {}
local ESP_Connections = {} // Guarda conexões PlayerAdded/CharAdded para cleanup

local function CreateBillboard(plr)
    if ESP_Billboards[plr] then pcall(function() ESP_Billboards[plr]:Destroy() end) end
    local char = plr.Character; if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"); if not head then return end
    
    local bill = Instance.new("BillboardGui")
    bill.Name = "ESP_Billboard"
    bill.Adornee = head
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.StudsOffset = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.MaxDistance = 5000
    bill.LightInfluence = 0
    
    local lbl = Instance.new("TextLabel")
    lbl.Name = "InfoLabel"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.Text = ""
    lbl.Parent = bill
    
    bill.Parent = head
    ESP_Billboards[plr] = bill
end

local function RemoveBillboard(plr)
    if ESP_Billboards[plr] then pcall(function() ESP_Billboards[plr]:Destroy() end); ESP_Billboards[plr] = nil end
end

local function UpdateESPVisuals(plr)
    if not CONFIG.ESP then return end
    local char = plr.Character; if not char then return end
    local root = SafeGetRoot(char); if not root then return end
    local hum = SafeGetHum(char); if not hum then return end

    // Highlight
    local hl = ESP_Highlights[plr]
    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.Name = "ESP_Highlight"
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        ESP_Highlights[plr] = hl
    end
    hl.FillColor = plr.TeamColor.Color
    hl.OutlineColor = Color3.new(1,1,1)

    // Billboard
    CreateBillboard(plr)
    local bill = ESP_Billboards[plr]
    if bill and bill:FindFirstChild("InfoLabel") then
        local dist = (camera.CFrame.Position - root.Position).Magnitude
        bill.InfoLabel.Text = plr.Name .. "\n[" .. math.floor(dist) .. "m]"
        bill.InfoLabel.TextColor3 = plr.TeamColor.Color
    end
end

local function CleanupPlayerESP(plr)
    if ESP_Highlights[plr] then pcall(function() ESP_Highlights[plr]:Destroy() end); ESP_Highlights[plr] = nil end
    RemoveBillboard(plr)
end

local function SetupESPPlayer(plr)
    if plr == player then return end
    
    // CharacterAdded
    local connChar = plr.CharacterAdded:Connect(function(char)
        task.wait(0.5) // Aguarda load
        if CONFIG.ESP then UpdateESPVisuals(plr) end
    end)
    table.insert(ESP_Connections, connChar)
    
    // CharacterRemoving
    local connRem = plr.CharacterRemoving:Connect(function()
        CleanupPlayerESP(plr)
    end)
    table.insert(ESP_Connections, connRem)
    
    // Se já tem char
    if plr.Character then UpdateESPVisuals(plr) end
end

Watchdog:Wrap("ESPLoop", function()
    if not CONFIG.ESP then
        for _, plr in pairs(Players:GetPlayers()) do CleanupPlayerESP(plr) end
        return
    end
    
    // Update Distance/Color for existing
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then UpdateESPVisuals(plr) end
    end
end, 0.5) // Update distance every 0.5s

// PlayerAdded Event (Fora do Watchdog para ser imediato)
local connPAdd = Players.PlayerAdded:Connect(SetupESPPlayer)
table.insert(ESP_Connections, connPAdd)

// Setup existing players
for _, plr in pairs(Players:GetPlayers()) do SetupESPPlayer(plr) end

// ============================================================
// 2. FULLBRIGHT PERSISTENTE v2 (WATCHDOG + PROPERTY CHANGED)
// ============================================================
local Fullbright_Connections = {}

local function CaptureOriginalLighting()
    OriginalLightingProps = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Ambient = Lighting.Ambient,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }
    // Capture Effects
    OriginalLightingProps.Effects = {}
    for _, eff in pairs(Lighting:GetChildren()) do
        if eff:IsA("PostEffect") then -- ColorCorrection, Bloom, SunRays, Blur
            OriginalLightingProps.Effects[eff.Name] = { Enabled = eff.Enabled, Class = eff.ClassName, Props = {} }
            // Salvar propriedades principais
            if eff:IsA("ColorCorrectionEffect") then OriginalLightingProps.Effects[eff.Name].Props = { Brightness = eff.Brightness, Contrast = eff.Contrast, Saturation = eff.Saturation, TintColor = eff.TintColor } end
            if eff:IsA("BloomEffect") then OriginalLightingProps.Effects[eff.Name].Props = { Intensity = eff.Intensity, Size = eff.Size, Threshold = eff.Threshold } end
            if eff:IsA("SunRaysEffect") then OriginalLightingProps.Effects[eff.Name].Props = { Intensity = eff.Intensity, Spread = eff.Spread } end
            if eff:IsA("BlurEffect") then OriginalLightingProps.Effects[eff.Name].Props = { Size = eff.Size } end
        end
    end
end

local function ApplyFullbrightState(enabled)
    if enabled then
        CaptureOriginalLighting()
        
        // Aplicar Valores
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.Ambient = Color3.new(1,1,1)
        
        // Desativar Effects Escuros
        for _, eff in pairs(Lighting:GetChildren()) do
            if eff:IsA("PostEffect") then
                if eff:IsA("ColorCorrectionEffect") then eff.Brightness = 0; eff.Contrast = 0; eff.Saturation = 1; eff.TintColor = Color3.new(1,1,1) end
                if eff:IsA("BloomEffect") then eff.Enabled = false end
                if eff:IsA("SunRaysEffect") then eff.Enabled = false end
                if eff:IsA("BlurEffect") then eff.Enabled = false end
            end
        end
        
        // Watchdog para impedir revert
        // Usamos conexões diretas PropertyChangedSignal para resposta instantânea
        local propsToWatch = {"Brightness", "ClockTime", "FogEnd", "FogStart", "GlobalShadows", "OutdoorAmbient", "Ambient"}
        for _, prop in pairs(propsToWatch) do
            local conn = Lighting:GetPropertyChangedSignal(prop):Connect(function()
                if not CONFIG.Fullbright then return end
                // Re-aplicar silenciosamente
                if prop == "Brightness" and Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
                if prop == "ClockTime" and Lighting.ClockTime ~= 14 then Lighting.ClockTime = 14 end
                if prop == "FogEnd" and Lighting.FogEnd ~= 100000 then Lighting.FogEnd = 100000 end
                if prop == "FogStart" and Lighting.FogStart ~= 0 then Lighting.FogStart = 0 end
                if prop == "GlobalShadows" and Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
                if prop == "OutdoorAmbient" and Lighting.OutdoorAmbient ~= Color3.new(1,1,1) then Lighting.OutdoorAmbient = Color3.new(1,1,1) end
                if prop == "Ambient" and Lighting.Ambient ~= Color3.new(1,1,1) then Lighting.Ambient = Color3.new(1,1,1) end
            end)
            table.insert(Fullbright_Connections, conn)
        end
        
        // Watch Children (Effects added at runtime)
        local connChild = Lighting.ChildAdded:Connect(function(child)
            if not CONFIG.Fullbright then return end
            task.wait()
            if child:IsA("PostEffect") then
                if child:IsA("BloomEffect") or child:IsA("SunRaysEffect") or child:IsA("BlurEffect") then child.Enabled = false end
                if child:IsA("ColorCorrectionEffect") then child.Brightness = 0; child.Contrast = 0; child.Saturation = 1; child.TintColor = Color3.new(1,1,1) end
            end
        end)
        table.insert(Fullbright_Connections, connChild)
        
    else
        // Desconectar tudo
        for _, conn in pairs(Fullbright_Connections) do pcall(function() conn:Disconnect() end) end
        table.clear(Fullbright_Connections)
        
        // Restaurar Original
        for prop, val in pairs(OriginalLightingProps) do
            if prop ~= "Effects" and Lighting[prop] ~= nil then pcall(function() Lighting[prop] = val end) end
        end
        
        // Restaurar Effects
        for _, eff in pairs(Lighting:GetChildren()) do
            if eff:IsA("PostEffect") then
                local orig = OriginalLightingProps.Effects[eff.Name]
                if orig then
                    pcall(function() eff.Enabled = orig.Enabled end)
                    for pName, pVal in pairs(orig.Props) do pcall(function() eff[pName] = pVal end) end
                else
                    // Se não existia originalmente, remover ou deixar? Vou deixar habilitado padrão.
                end
            end
        end
        OriginalLightingProps = {}
    end
end

// ============================================================
// 3. NOFOG PERSISTENTE v2 (ATMOSPHERE + PROPERTY CHANGED)
// ============================================================
local NoFog_Connections = {}

local function CaptureOriginalAtmosphere()
    OriginalAtmosphereProps = {}
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        OriginalAtmosphereProps = {
            Density = atmo.Density,
            Offset = atmo.Offset,
            Color = atmo.Color,
            Decay = atmo.Decay,
            Glare = atmo.Glare,
            Haze = atmo.Haze,
        }
    end
end

local function ApplyNoFogState(enabled)
    if enabled then
        CaptureOriginalAtmosphere()
        
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo then
            atmo.Density = 0
            atmo.Offset = 0
            atmo.Haze = 0
            atmo.Glare = 0
        end
        
        // Watchers
        local connEnd = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
            if CONFIG.NoFog and Lighting.FogEnd ~= 100000 then Lighting.FogEnd = 100000 end
        end)
        local connStart = Lighting:GetPropertyChangedSignal("FogStart"):Connect(function()
            if CONFIG.NoFog and Lighting.FogStart ~= 100000 then Lighting.FogStart = 100000 end
        end)
        table.insert(NoFog_Connections, connEnd)
        table.insert(NoFog_Connections, connStart)
        
        // Watch Atmosphere changes
        local connAtmoProp = Lighting:GetPropertyChangedSignal("Atmosphere"):Connect(function() end) // Não existe sinal direto pro objeto, vigiars children
        local connChild = Lighting.ChildAdded:Connect(function(child)
            if CONFIG.NoFog and child:IsA("Atmosphere") then
                task.wait()
                child.Density = 0; child.Offset = 0; child.Haze = 0; child.Glare = 0
            end
        end)
        table.insert(NoFog_Connections, connChild)
        
    else
        for _, conn in pairs(NoFog_Connections) do pcall(function() conn:Disconnect() end) end
        table.clear(NoFog_Connections)
        
        Lighting.FogEnd = OriginalAtmosphereProps.FogEnd or 100000 // Fallback
        Lighting.FogStart = OriginalAtmosphereProps.FogStart or 0
        
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo and next(OriginalAtmosphereProps) ~= nil then
            atmo.Density = OriginalAtmosphereProps.Density or 0.3
            atmo.Offset = OriginalAtmosphereProps.Offset or 0
            atmo.Haze = OriginalAtmosphereProps.Haze or 0
            atmo.Glare = OriginalAtmosphereProps.Glare or 0
            // Color/Decay não costuma mudar com fog, mas restauramos se salvamos
        end
        OriginalAtmosphereProps = {}
    end
end

// ============================================================
// 4. FPSBOOST EXTREME (FLAGS + FALLBACK + RASTREAMENTO)
// ============================================================

// Lista de FastFlags Seguras para FPS/Performance (Mobile/PC)
// Fonte: Documentação Roblox / Community Research (DFIntTaskSchedulerTargetFps, Rendering, etc)
local FastFlagsList = {
    // Rendering Quality
    { "FFlagDebugGraphicsDisableLocalLights", "True" },
    { "FFlagDebugGraphicsDisablePostEffects", "True" },
    { "FFlagDebugGraphicsDisableShadows", "True" },
    { "FFlagDebugDisableOTAMUpdate", "True" }, // Desativa One Time Asset Load updates pesados
    { "DFIntTaskSchedulerTargetFps", "60" }, // Trava scheduler em 60 (evita picos)
    { "DFIntRenderTargetPoolSize", "128" }, // Reduz pool de render targets (memória)
    { "FFlagDebugForceFutureIsShadowsDisabled", "True" }, // Desativa Future Shadows (Pesado)
    { "FFlagDebugRenderForceTechnologyVulkan", "False" }, // Força OpenGL/DX11 no mobile as vezes mais estável
    { "FFlagDebugDisableVoxelGrid", "True" }, // Desativa Voxel Grid (Iluminação global pesada)
    // Network/Physics
    { "DFIntPhysicsThrottleRate", "30" }, // Reduz taxa de física rede
    { "FFlagDebugNetworkPredictionDisabled", "True" },
}

local function ApplyFastFlags(enable)
    if not ExecutorCaps.hasSetFFlag then return false end
    local successCount = 0
    for _, flag in pairs(FastFlagsList) do
        local name, val = flag[1], flag[2]
        local ok = pcall(function() setfflag(name, val) end)
        if ok then successCount = successCount + 1 end
    end
    warn(`[FPSBoost] Applied {successCount}/{#FastFlagsList} FastFlags.`)
    return successCount > 0
end

// Fallback: Modificações no Workspace/Lighting/Terrain
local function ApplyFallbackOptimizations(enable)
    if enable then
        // Salvar estado original para restaurar
        FPSBoost_TrackedChanges.LightingProps = {
            GlobalShadows = Lighting.GlobalShadows,
            Brightness = Lighting.Brightness,
        }
        Lighting.GlobalShadows = false
        
        if Terrain then
            FPSBoost_TrackedChanges.TerrainProps = {
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed,
                WaterReflectance = Terrain.WaterReflectance,
                WaterTransparency = Terrain.WaterTransparency,
            }
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end
        
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        
        // Limpar Particulas/Trails e Trocar Materiais
        // Iterar Workspace (pode lagar 1 frame na ativação, aceitável)
        for _, obj in pairs(Workspace:GetDescendants()) do
            // Partículas/Trails/Beams
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
                if obj.Enabled ~= false then
                    table.insert(FPSBoost_TrackedChanges.Particles, {Obj = obj, Enabled = obj.Enabled})
                    obj.Enabled = false
                end
            end
            
            // Materiais BasePart
            if obj:IsA("BasePart") then
                local mat = obj.Material
                // Não mexer em ForceField, Neon, Glass (visuais importantes de gameplay/UI)
                if mat ~= Enum.Material.ForceField and mat ~= Enum.Material.Neon and mat ~= Enum.Material.Glass then
                    if mat ~= Enum.Material.SmoothPlastic then
                        table.insert(FPSBoost_TrackedChanges.Materials, {Obj = obj, Material = mat})
                        obj.Material = Enum.Material.SmoothPlastic
                    end
                end
            end
        end
        warn("[FPSBoost] Fallback Optimizations Applied (Particles cleaned, Materials set to SmoothPlastic).")
    else
        // RESTAURAR TUDO
        for _, data in pairs(FPSBoost_TrackedChanges.Materials) do
            if data.Obj and data.Obj.Parent then pcall(function() data.Obj.Material = data.Material end) end
        end
        for _, data in pairs(FPSBoost_TrackedChanges.Particles) do
            if data.Obj and data.Obj.Parent then pcall(function() data.Obj.Enabled = data.Enabled end) end
        end
        if FPSBoost_TrackedChanges.LightingProps then
            for k,v in pairs(FPSBoost_TrackedChanges.LightingProps) do pcall(function() Lighting[k] = v end) end
        end
        if FPSBoost_TrackedChanges.TerrainProps and Terrain then
            for k,v in pairs(FPSBoost_TrackedChanges.TerrainProps) do pcall(function() Terrain[k] = v end) end
        end
        // QualityLevel não tem "original" fácil, volta pro Auto
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        
        FPSBoost_TrackedChanges = { Materials = {}, Particles = {}, LightingProps = {}, TerrainProps = {} }
        warn("[FPSBoost] Fallback Optimizations Restored.")
    end
end

local function ToggleFPSBoost(state)
    CONFIG.FPSBoost_Flags = state
    CONFIG._Flags.FPSBoost_Flags = state
    
    local flagsApplied = false
    if ExecutorCaps.hasSetFFlag then
        flagsApplied = ApplyFastFlags(state)
        if flagsApplied then
            Rayfield:Notify({Title="FPSBoost", Content="FastFlags Aplicadas (setfflag ativo)", Duration=3, Image="check-circle"})
        else
            Rayfield:Notify({Title="FPSBoost", Content="Falha ao aplicar Flags, tentando Fallback...", Duration=3, Image="alert-triangle"})
        end
    end
    
    // Sempre aplicar Fallback como garantia (ou se flags falharam)
    // Se flags funcionaram, fallback ainda ajuda (QualityLevel, Particles, Materials)
    ApplyFallbackOptimizations(state)
    
    if not state then
        Rayfield:Notify({Title="FPSBoost", Content="Desativado - Configurações Restauradas", Duration=3, Image="x-circle"})
    end
    
    saveConfig()
end

// ============================================================
// VISUALS LOOP (FOV Only - Fullbright/NoFog são Event Driven)
// ============================================================
Watchdog:Wrap("VisualsLoop", function()
    camera.FieldOfView = CONFIG.FOV
end, 1)

// ============================================================
// MOVEMENT LOOPS
// ============================================================
Watchdog:Wrap("SpeedLoop", function()
    local hum = getHum()
    if hum then hum.WalkSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed) end
end, 0.1)

Watchdog:Wrap("SpinLoop", function(dt)
    if not CONFIG.Spin then return end
    local root = getRoot()
    if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CONFIG.SpinSpeed)*dt*60, 0) end
end)

Watchdog:Wrap("NoclipLoop", function()
    if not CONFIG.Noclip then return end
    local char = player.Character
    if char then for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end end end
end, 0.1)

// ============================================================
// FLY / FREECAM / EVENTS (Mantidos da v2)
// ============================================================
local FlyConn
local function ToggleFly(state)
    CONFIG.Fly = state; CONFIG._Flags.Fly = state
    local hum = getHum(); local root = getRoot()
    if state and (not hum or not root) then CONFIG.Fly=false; CONFIG._Flags.Fly=false; if UI_Flags.Fly then UI_Flags.Fly:Set(false) end return end
    if state then
        hum.PlatformStand = true
        Rayfield:Notify({Title="Fly", Content="Ativado (Stealth CFrame)", Duration=2, Image="check-circle"})
        FlyConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.Fly then return ToggleFly(false) end
            hum = getHum(); root = getRoot(); if not hum or not root then return ToggleFly(false) end
            local moveDir = hum.MoveDirection
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed) * dt * 60
            local newCF = root.CFrame
            if moveDir.Magnitude > 0 then newCF = newCF + (moveDir * speed) end
            local camLook = camera.CFrame.LookVector
            local jump = UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA)
            local crouch = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2)
            if jump then newCF = newCF + Vector3.new(0,speed,0)
            elseif crouch then newCF = newCF - Vector3.new(0,speed,0)
            elseif math.abs(camLook.Y) > 0.15 then newCF = newCF + Vector3.new(0, camLook.Y * speed * 0.5, 0) end
            root.CFrame = newCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        if FlyConn then FlyConn:Disconnect(); FlyConn=nil end
        if hum then hum.PlatformStand=false end
        Rayfield:Notify({Title="Fly", Content="Desativado", Duration=2, Image="x-circle"})
    end
    saveConfig()
end

local FreeCamConn
local function ToggleFreeCam(state)
    CONFIG.FreeCam = state; CONFIG._Flags.FreeCam = state
    local hum = getHum(); local root = getRoot()
    if state and root then
        camera.CameraType = Enum.CameraType.Scriptable; camera.CameraSubject = nil
        if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
        FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return ToggleFreeCam(false) end
            local move = Vector3.zero; local cf = camera.CFrame; local speed = 100*dt
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then camera.CFrame = camera.CFrame + move.Unit * speed end
        end)
    else
        if FreeCamConn then FreeCamConn:Disconnect(); FreeCamConn=nil end
        camera.CameraType = Enum.CameraType.Custom; camera.CameraSubject = hum
        if hum then applyPhysics() end
    end
    saveConfig()
end

UserInputService.JumpRequest:Connect(function() if CONFIG.InfiniteJump then local h=getHum() if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)
player.Idled:Connect(function() if CONFIG.AntiAFK then VInput_Click(math.random(100,500),math.random(100,500)) VInput_Key(Enum.KeyCode.Unknown,true) task.wait(0.05) VInput_Key(Enum.KeyCode.Unknown,false) end end)
UserInputService.InputBegan:Connect(function(input, gp) if CONFIG.ClickTP and not gp and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then local root = getRoot(); if not root then return end local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y) local params = RaycastParams.new(); params.FilterDescendantsInstances={player.Character}; params.FilterType=Enum.RaycastFilterType.Exclude local hit = workspace:Raycast(ray.Origin, ray.Direction*1000, params) if hit then root.CFrame = CFrame.new(hit.Position + Vector3.new(0,3,0)) end end end)

player.CharacterAdded:Connect(function() task.wait(0.5) applyPhysics() if CONFIG.Fly then ToggleFly(true) end if CONFIG.FreeCam then ToggleFreeCam(true) end end)

// ============================================================
// UI RAYFIELD + AUTO-SAVE HOOKS
// ============================================================
loadConfig()

local Window = Rayfield:CreateWindow({
    Name = "Universal Lite v3.0 • "..(ExecutorCaps.hasWriteFile and "💾" or "📋").." • "..(ExecutorCaps.hasRequest and "🌐" or "🚫").." • "..(ExecutorCaps.hasSetFFlag and "⚡FF" or "🛠️FB"),
    LoadingTitle = "Carregando...", LoadingSubtitle = "Sistemas Blindados Ativos",
    ConfigurationSaving = {Enabled=false}, KeySystem=false
})

local MoveTab = Window:CreateTab("Movimento ⚠️", 4483362458)
local VisualTab = Window:CreateTab("Visuais ✅", 4483362458)
local PerfTab = Window:CreateTab("Desempenho 🚀", 4483362458) // NOVA ABA
local UtilTab = Window:CreateTab("Utilitários", 4483362458)

local function Slider(tab, cfg, opts)
    opts.Flag = cfg; opts.CurrentValue = CONFIG[cfg]
    opts.Callback = function(v)
        CONFIG[cfg] = v
        if cfg == "WalkSpeed" or cfg == "FlySpeed" or cfg == "VelocidadeGlobal" then CONFIG[cfg] = limitSpeed(v) end
        if cfg == "FOV" then camera.FieldOfView = v end
        if cfg == "Gravity" then workspace.Gravity = v * 196.2 end
        if cfg == "JumpPower" then local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end
        if cfg == "SpinSpeed" then local r=getRoot(); local b=r and r:FindFirstChild("SpinForce"); if b then b.AngularVelocity=Vector3.new(0,v,0) end end
        saveConfig()
        Rayfield:Notify({Title="Set", Content=cfg.." = "..v, Duration=1, Image="check"})
    end
    local o = tab:CreateSlider(opts); UI_Flags[cfg] = o; return o
end

local function Toggle(tab, cfg, opts, cb)
    opts.Flag = cfg; opts.CurrentValue = CONFIG[cfg]
    opts.Callback = function(v)
        CONFIG[cfg] = v; CONFIG._Flags[cfg] = v
        if cb then cb(v) else saveConfig() end // Callbacks customizados (Fly, FPSBoost) já salvam
        Rayfield:Notify({Title=v and "ON" or "OFF", Content=cfg, Duration=1, Image=v and "check-circle" or "x-circle"})
    end
    local o = tab:CreateToggle(opts); UI_Flags[cfg] = o; return o
end

// ========== VISUAIS (BLINDADOS) ==========
VisualTab:CreateSection("🟢 Blindados — Funcionam Em Qualquer Jogo")
Toggle(VisualTab, "ESP", {Name="ESP Players (Highlight + Nome/Distância)"}, function(v) 
    // ESP Loop gerencia via Watchdog, mas precisamos limpar/criar即时
    if not v then for _, plr in pairs(Players:GetPlayers()) do CleanupPlayerESP(plr) end else for _, plr in pairs(Players:GetPlayers()) do UpdateESPVisuals(plr) end end 
    saveConfig() 
end)
Toggle(VisualTab, "Fullbright", {Name="Fullbright Persistente (Anti-Escurecer)"}, function(v) ApplyFullbrightState(v) end)
Toggle(VisualTab, "NoFog", {Name="NoFog Persistente (Anti-Névoa/Atmosphere)"}, function(v) ApplyNoFogState(v) end)
Slider(VisualTab, "FOV", {Name="FOV", Range={50,120}, Increment=1})

// ========== MOVIMENTO ==========
MoveTab:CreateSection("🟡 Arriscados — Rubberband/Kick em Comp.")
MoveTab:CreateLabel("⚠️ Use só em Obby/Tycoon/RP Leve.")
Slider(MoveTab, "WalkSpeed", {Name="WalkSpeed", Range={16,500}, Increment=1})
Toggle(MoveTab, "AplicarVelocidade", {Name="Usar Velocidade Global"}, function(v) applyPhysics() saveConfig() end)
Slider(MoveTab, "VelocidadeGlobal", {Name="Velocidade Global", Range={1,1000}, Increment=1})
Slider(MoveTab, "LimiteVelocidade", {Name="Limite Máximo", Range={1,1000}, Increment=1})
Slider(MoveTab, "JumpPower", {Name="JumpPower", Range={50,300}, Increment=1})
Slider(MoveTab, "Gravity", {Name="Gravidade", Range={0.1,5}, Increment=0.1})
Toggle(MoveTab, "InfiniteJump", {Name="Infinite Jump"})
Toggle(MoveTab, "Spin", {Name="Spin"})
Slider(MoveTab, "SpinSpeed", {Name="Spin Speed", Range={1,50}, Increment=1})
Toggle(MoveTab, "Sit", {Name="Sit"})

MoveTab:CreateSection("🔴 Perigosos — Kick Quase Certo")
Toggle(MoveTab, "Fly", {Name="Fly (Stealth CFrame)"}, ToggleFly)
Slider(MoveTab, "FlySpeed", {Name="Fly Speed", Range={1,1000}, Increment=5})
Toggle(MoveTab, "Noclip", {Name="Noclip"})
Toggle(MoveTab, "ClickTP", {Name="Click/Touch TP (Teleporte)"})

// ========== DESEMPENHO (NOVA ABA) ==========
PerfTab:CreateSection("⚡ FPSBoost Extreme")
PerfTab:CreateLabel("Modo 1: FastFlags (setfflag) - " .. (ExecutorCaps.hasSetFFlag and "✅ Disponível" or "❌ Indisponível (Usará Fallback)"))
PerfTab:CreateLabel("Modo 2: Fallback Garantido - QualityLevel 1, Sem Sombras, Sem Partículas, Materiais Simples.")
Toggle(PerfTab, "FPSBoost_Flags", {Name="Ativar FPSBoost Extreme"}, ToggleFPSBoost)

PerfTab:CreateSection("🛠️ Otimizações Manuais (Se FPSBoost Falhar)")
PerfTab:CreateButton({Name="Limpar Partículas/Trilhas Agora", Callback=function()
    for _, obj in pairs(Workspace:GetDescendants()) do if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then obj.Enabled = false end end
    Rayfield:Notify({Title="Limpeza", Content="Partículas/Trilhas desativadas.", Duration=2, Image="check"})
end})
PerfTab:CreateButton({Name="Materiais -> SmoothPlastic", Callback=function()
    for _, obj in pairs(Workspace:GetDescendants()) do if obj:IsA("BasePart") and obj.Material ~= Enum.Material.ForceField and obj.Material ~= Enum.Material.Neon and obj.Material ~= Enum.Material.Glass then obj.Material = Enum.Material.SmoothPlastic end end
    Rayfield:Notify({Title="Materiais", Content="Convertidos para SmoothPlastic.", Duration=2, Image="check"})
end})

// ========== UTILITÁRIOS ==========
UtilTab:CreateSection("🟢 Utils Seguros")
Toggle(UtilTab, "AntiAFK", {Name="Anti-AFK (VirtualInput)"})
UtilTab:CreateButton({Name="Rejoin", Callback=function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, player) end})

if ExecutorCaps.hasRequest then
    UtilTab:CreateButton({Name="Server Hop", Callback=function()
        Rayfield:Notify({Title="Server Hop", Content="Procurando...", Duration=10, Image="loader"})
        task.spawn(function()
            local ok, res = pcall(function() return HttpService:RequestAsync({Url="https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method="GET"}) end)
            if ok and res.Success then local data = HttpService:JSONDecode(res.Body); for _,s in pairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then TeleportService:TeleportToPlaceInstance(PlaceId,s.id,player) return end end end
            Rayfield:Notify({Title="Erro", Content="Sem servidor ou API falhou", Duration=5, Image="alert-circle"})
        end)
    end})
else UtilTab:CreateLabel("🚫 Server Hop indisponível") end

UtilTab:CreateSection("💾 Config (Auto-Save Ativo)")
UtilTab:CreateButton({Name="Forçar Salvar Agora", Callback=function() saveConfig() Rayfield:Notify({Title="Config", Content="Salvo!", Duration=2, Image="check-circle"}) end})
UtilTab:CreateButton({Name="Resetar Tudo (Padrão)", Callback=function()
    CONFIG = {ESP=false,Fullbright=false,NoFog=false,FOV=70,AntiAFK=false,WalkSpeed=16,JumpPower=50,Gravity=1,InfiniteJump=false,Spin=false,SpinSpeed=10,Sit=false,Fly=false,FlySpeed=50,Noclip=false,ClickTP=false,AntiLag=false,Rejoin=false,ServerHop=false,SelectedPlayer="Nenhum",VelocidadeGlobal=1000,AplicarVelocidade=false,LimiteVelocidade=1000,FPSBoost_Flags=false,_Flags={}}
    applyPhysics()
    ApplyFullbrightState(false)
    ApplyNoFogState(false)
    ToggleFPSBoost(false)
    ToggleFly(false)
    ToggleFreeCam(false)
    for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end; table.clear(ESP_Highlights)
    for _,bill in pairs(ESP_Billboards) do pcall(function() bill:Destroy() end) end; table.clear(ESP_Billboards)
    saveConfig()
    Rayfield:Notify({Title="Reset", Content="Defaults restaurados e salvos", Duration=2, Image="check-circle"})
end})

// ========== FINALIZAÇÃO ==========
applyPhysics() // Aplica WalkSpeed/JumpPower/Gravity iniciais
// Aplica estados visuais carregados do config
if CONFIG.Fullbright then ApplyFullbrightState(true) end
if CONFIG.NoFog then ApplyNoFogState(true) end
if CONFIG.FPSBoost_Flags then ToggleFPSBoost(true) end
// ESP é gerenciado pelo Watchdog/Eventos automaticamente ao setar _Flags

Rayfield:LoadConfiguration()
Rayfield:Notify({Title="Universal Lite v3.0", Content="Carregado — Sistemas Blindados + FPSBoost Ativos", Duration=5, Image="check-circle"})

getgenv()._UniversalScriptCleanup = function()
    for _,c in pairs(Watchdog.Connections) do pcall(function() c:Disconnect() end) end
    for _,c in pairs(Fullbright_Connections) do pcall(function() c:Disconnect() end) end
    for _,c in pairs(NoFog_Connections) do pcall(function() c:Disconnect() end) end
    for _,c in pairs(ESP_Connections) do pcall(function() c:Disconnect() end) end // Limpa PlayerAdded/CharAdded
    if FlyConn then FlyConn:Disconnect() end
    if FreeCamConn then FreeCamConn:Disconnect() end
    for _,hl in pairs(ESP_Highlights) do pcall(function() hl:Destroy() end) end
    for _,bill in pairs(ESP_Billboards) do pcall(function() bill:Destroy() end) end
    // Restaurar FPSBoost se ligado
    if CONFIG.FPSBoost_Flags then ToggleFPSBoost(false) end
    // Restaurar Visuais
    ApplyFullbrightState(false)
    ApplyNoFogState(false)
    print("[UniversalLite v3.0] Cleanup OK")
end
```
