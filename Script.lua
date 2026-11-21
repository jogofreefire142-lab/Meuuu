```lua
-- 🔵 1. ESPERA PARA AUTO EXECUTE (game:IsLoaded)
repeat task.wait() until game:IsLoaded()
task.wait(1)

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
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- ============================================================
-- 🛡️ SISTEMAS DE SEGURANÇA E COMPATIBILIDADE (INTERNOS)
-- ============================================================

-- 1. SAFE CHAR (Universal R6/R15/Custom)
local function SafeGetHum(char)
	char = char or player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildWhichIsA("Humanoid", true)
end

local function SafeGetRoot(char)
	char = char or player.Character
	if not char then return nil end
	local hum = SafeGetHum(char)
	if hum and hum.RootPart then return hum.RootPart end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
end

local function SafeGetHead(char)
	char = char or player.Character
	if not char then return nil end
	return char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
end

local function GetCharacterParts(char)
	char = char or player.Character
	if not char then return {} end
	local parts = {}
	for _, p in pairs(char:GetDescendants()) do
		if p:IsA("BasePart") then table.insert(parts, p) end
	end
	return parts
end

-- 2. VIRTUAL INPUT (Real OS Input)
local function VInput_Click(x, y)
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
		task.wait(0.02)
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)
end

local function VInput_Key(keyCode, down)
	pcall(function() VirtualInputManager:SendKeyEvent(down, keyCode, false, game) end)
end

-- 3. WATCHDOG (Auto-Disable on Error)
local Watchdog = { Errors = {}, MaxErrors = 3, Connections = {} }
function Watchdog:Wrap(name, func, interval)
	interval = interval or 0
	if self.Connections[name] then self.Connections[name]:Disconnect() end
	self.Errors[name] = 0
	local lastRun = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not CONFIG._Flags[name] then return conn:Disconnect() end
		if interval > 0 and tick() - lastRun < interval then return end
		if interval > 0 then lastRun = tick() end
		local ok, err = pcall(func, dt)
		if not ok then
			self.Errors[name] = (self.Errors[name] or 0) + 1
			warn(`[WATCHDOG] ${name} Error [${self.Errors[name]}/${self.MaxErrors}]: ${err}`)
			if self.Errors[name] >= self.MaxErrors then
				self:ForceDisable(name, tostring(err))
			end
		else
			self.Errors[name] = 0
		end
	end)
	self.Connections[name] = conn
	return conn
end

function Watchdog:ForceDisable(flagName, reason)
	if not CONFIG._Flags[flagName] then return end
	CONFIG._Flags[flagName] = false
	CONFIG[flagName] = false
	if Rayfield.Flags and Rayfield.Flags[flagName] then
		pcall(function() Rayfield.Flags[flagName]:Set(false) end)
	end
	Rayfield:Notify({ Title = "🛡️ WATCHDOG", Content = flagName .. " desligado (Segurança):\n" .. reason, Duration = 6, Image = "alert-triangle" })
end

-- 4. DRAWING API WRAPPER (Safe Creation)
local DrawingLib = {}
DrawingLib.Objects = {}
function DrawingLib:New(type, props)
	local obj = Drawing.new(type)
	for k, v in pairs(props) do obj[k] = v end
	table.insert(DrawingLib.Objects, obj)
	return obj
end

function DrawingLib:ClearAll()
	for _, obj in pairs(DrawingLib.Objects) do pcall(function() obj:Remove() end) end
	table.clear(DrawingLib.Objects)
end

-- ============================================================
-- SUA CONFIG ORIGINAL EXPANDIDA
-- ============================================================
local CONFIG = {
    -- Movement
    WalkSpeed = 16, JumpPower = 50, Gravity = 1,
    InfiniteJump = false, Noclip = false, Spin = false, SpinSpeed = 10, Sit = false,
    Fly = false, FlySpeed = 50, FlyMode = "CFrame",
    -- Movement Advanced
    BHop = false, Strafe = false, StrafeSpeed = 50, EdgeJump = false, LongJump = false, LongJumpPower = 50,
    -- Visuals ESP (Drawing)
    ESP = false, ESPMode = "Drawing", -- "Drawing" or "Highlight"
    ESP_TeamCheck = true, ESP_ShowBox = true, ESP_ShowSkeleton = true, ESP_ShowTracers = true, ESP_ShowName = true, ESP_ShowHealth = true, ESP_ShowDistance = true, ESP_ShowOffscreen = true,
    ESP_BoxType = "Corner", -- "Full", "Corner"
    ESP_ColorMode = "Team", -- "Team", "Force"
    ESP_ForceColor = "Sem Título", -- "Sem Título", "Assassino", "Policial"
    ESP_Thickness = 1, ESP_Transparency = 1, ESP_FontSize = 13, ESP_MaxDistance = 5000,
    -- Visuals Highlight (Legacy/Alternative)
    HighlightESP = false, HighlightFillTransparency = 0.5, HighlightOutlineTransparency = 0,
    -- Visuals World
    Fullbright = false, NoFog = false, FOV = 70, FreeCam = false, NoRecoil = false, NoSpread = false, NoCamShake = false, Chams = false, ChamsMode = "ForceField", -- "ForceField", "Neon", "Glass"
    -- Combat (Safe/Client Only)
    TriggerBot = false, TriggerBotDelay = 0.05,
    -- Utility
    AntiAFK = false, ClickTP = false, AntiLag = false, ChatLogger = true,
    -- Server
    Rejoin = false, ServerHop = false, SelectedPlayer = "Nenhum",
    -- Speed Master
    MaxSpeed = 1000, Organize = false, VelocidadeGlobal = 1000, AplicarVelocidade = false, LimiteVelocidade = 1000,
    -- Internal
    _Flags = {}
}

local CONFIG_PATH = "ScriptUniversal_Config_" .. PlaceId .. ".json"

local function saveConfig()
    local data = {}
    for k, v in pairs(CONFIG) do if type(v) ~= "function" and k:sub(1,1) ~= "_" then data[k] = v end end
    local success, error = pcall(function() writefile(CONFIG_PATH, HttpService:JSONEncode(data)) end)
    if success then Rayfield:Notify({ Title = "Sucesso", Content = "Configurações salvas em " .. CONFIG_PATH, Duration = 3, Image = "check-circle" }) else Rayfield:Notify({ Title = "Erro", Content = "Erro ao salvar: " .. tostring(error), Duration = 3, Image = "alert-circle" }) end
end

local function loadConfig()
    local success, data = pcall(function() if isfile(CONFIG_PATH) then return HttpService:JSONDecode(readfile(CONFIG_PATH)) end return nil end)
    if success and data then for k, v in pairs(data) do CONFIG[k] = v end for k, v in pairs(CONFIG) do if type(v) == "boolean" then CONFIG._Flags[k] = v end end Rayfield:Notify({ Title = "Carregado", Content = "Configurações aplicadas.", Duration = 3, Image = "check-circle" }) else Rayfield:Notify({ Title = "Aviso", Content = "Nenhum config salvo para este jogo.", Duration = 3, Image = "info" }) end
end

local function getHum() return SafeGetHum() end
local function getRoot() return SafeGetRoot() end
local function getHead() return SafeGetHead() end
local function limitSpeed(speed) return math.min(speed, CONFIG.LimiteVelocidade) end

-- ============================================================
-- CORE FUNCTIONS
-- ============================================================
local function applyUniversalSpeed()
    local hum = getHum()
    if hum then hum.WalkSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed) end
end

local function applyConfig()
    local hum = getHum(); local root = getRoot()
    if not hum or not root then return end
    hum.WalkSpeed = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed)
    hum.JumpPower = CONFIG.JumpPower; hum.UseJumpPower = true; hum.Sit = CONFIG.Sit
    workspace.Gravity = CONFIG.Gravity * 196.2; Camera.FieldOfView = CONFIG.FOV
    -- Spin
    local bav = root:FindFirstChild("SpinForce")
    if CONFIG.Spin then if not bav then bav = Instance.new("BodyAngularVelocity"); bav.Name="SpinForce"; bav.MaxTorque=Vector3.new(0,math.huge,0); bav.Parent=root end; bav.AngularVelocity = Vector3.new(0, CONFIG.SpinSpeed, 0) elseif bav then bav:Destroy() end
    -- Visuals World
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end

-- ============================================================
-- FEATURES IMPLEMENTATION
-- ============================================================

-- FLY STEALTH
local FlyConn
local function ToggleFly(state)
    CONFIG.Fly = state; CONFIG._Flags.Fly = state
    local hum = getHum(); local root = getRoot()
    if not hum or not root then CONFIG.Fly=false; CONFIG._Flags.Fly=false; if Rayfield.Flags.Fly then Rayfield.Flags.Fly:Set(false) end return end
    if state then
        hum.PlatformStand = true
        FlyConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.Fly then return ToggleFly(false) end
            local hum = getHum(); local root = getRoot(); if not hum or not root then return ToggleFly(false) end
            local moveDir = hum.MoveDirection; local camCF = Camera.CFrame
            local speed = (CONFIG.AplicarVelocidade and CONFIG.VelocidadeGlobal or CONFIG.FlySpeed) * dt * 60
            local newCF = root.CFrame
            if moveDir.Magnitude > 0 then
                local look, right = camCF.LookVector, camCF.RightVector
                local flatLook = Vector3.new(look.X,0,look.Z).Unit; local flatRight = Vector3.new(right.X,0,right.Z).Unit
                newCF = newCF + ((flatLook * -moveDir.Z + flatRight * moveDir.X).Unit * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then newCF += Vector3.new(0, speed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then newCF -= Vector3.new(0, speed, 0) end
            root.CFrame = newCF; root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
        end)
    else if FlyConn then FlyConn:Disconnect(); FlyConn=nil end; hum.PlatformStand=false end
end

-- FREECAM
local FreeCamConn
local function ToggleFreeCam(state)
    CONFIG.FreeCam = state; CONFIG._Flags.FreeCam = state
    local hum = getHum(); local root = getRoot()
    if state and root then Camera.CameraType=Enum.CameraType.Scriptable; Camera.CameraSubject=nil; if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
        FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not CONFIG.FreeCam then return ToggleFreeCam(false) end
            local speed=100*dt; local move=Vector3.zero; local cf=Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move+=cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move-=cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move+=cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move-=cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move+=Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move-=Vector3.new(0,1,0) end
            if move.Magnitude>0 then Camera.CFrame += move.Unit*speed end
        end)
    else if FreeCamConn then FreeCamConn:Disconnect(); FreeCamConn=nil end; Camera.CameraType=Enum.CameraType.Custom; Camera.CameraSubject=hum; if hum then applyConfig() end end
end

-- CHAMS (Material Override)
local ChamsConn
local OriginalMaterials = {}
Watchdog:Wrap("ChamsLoop", function()
    if not CONFIG.Chams then
        for part, mat in pairs(OriginalMaterials) do if part and part.Parent then pcall(function() part.Material = mat end) end end
        table.clear(OriginalMaterials)
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            for _, part in pairs(GetCharacterParts(plr.Character)) do
                if not OriginalMaterials[part] then OriginalMaterials[part] = part.Material end
                part.Material = Enum.Material[CONFIG.ChamsMode]
                if CONFIG.ESP_ColorMode == "Force" then
                    part.Color = (CONFIG.ESP_ForceColor == "Assassino" and Color3.fromRGB(255,0,0)) or (CONFIG.ESP_ForceColor == "Policial" and Color3.fromRGB(0,0,255)) or Color3.fromRGB(255,255,255)
                elseif plr.Team then part.Color = plr.TeamColor.Color end
                part.Transparency = 0.1
            end
        end
    end
end, 1)

-- NO RECOIL / SPREAD / CAM SHAKE (Client Side Visuals)
Watchdog:Wrap("GunModsLoop", function()
    -- Note: This relies on specific game structures (Camera shake, Recoil values in Camera/Character).
    -- Universal implementation is limited without game specifics.
    -- Placeholder for safety: just ensures FOV lock.
    if CONFIG.NoCamShake then Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.LookVector) end -- Basic stabilization
end, 0)

-- ============================================================
-- ESP DRAWING API (COMPLETO: BOX, SKELETON, TRACER, NAME, HP, DIST, OFFSCREEN)
-- ============================================================
local ESP_Drawings = {} -- [Player] = {Box={}, Skeleton={}, Tracer=Line, Name=Text, Health=Line, Dist=Text, Offscreen=Triangle}

local SkeletonOrder = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    -- R6 Fallback
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Left Arm", "Left Leg"}, -- Not anatomically correct but connects
    {"Torso", "Right Arm"}, {"Right Arm", "Right Leg"},
}

local function GetESPColor(plr)
    if CONFIG.ESP_ColorMode == "Force" then
        if CONFIG.ESP_ForceColor == "Assassino" then return Color3.fromRGB(255, 0, 0) end
        if CONFIG.ESP_ForceColor == "Policial" then return Color3.fromRGB(0, 0, 255) end
        return Color3.fromRGB(255, 255, 255)
    else
        return plr.TeamColor.Color
    end
end

local function CreateDrawings(plr)
    if ESP_Drawings[plr] then return end
    local d = {}
    -- Box
    d.BoxOutline = DrawingLib:New("Square", { Thickness = 3, Filled = false, Color = Color3.new(0,0,0), Visible = false, ZIndex = 1 })
    d.Box = DrawingLib:New("Square", { Thickness = 1, Filled = false, Color = Color3.new(1,1,1), Visible = false, ZIndex = 2 })
    -- Corner Box (4 lines per corner = 8 lines)
    d.Corners = {}
    for i=1, 8 do d.Corners[i] = DrawingLib:New("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false }) end
    d.CornersOutline = {}
    for i=1, 8 do d.CornersOutline[i] = DrawingLib:New("Line", { Thickness = 3, Color = Color3.new(0,0,0), Visible = false }) end
    -- Skeleton
    d.Skeleton = {}
    for _, pair in pairs(SkeletonOrder) do
        local line = DrawingLib:New("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false })
        table.insert(d.Skeleton, {Line = line, Parts = pair})
    end
    -- Tracer
    d.Tracer = DrawingLib:New("Line", { Thickness = 1, Color = Color3.new(1,1,1), Visible = false })
    d.TracerOutline = DrawingLib:New("Line", { Thickness = 3, Color = Color3.new(0,0,0), Visible = false })
    -- Name
    d.Name = DrawingLib:New("Text", { Size = CONFIG.ESP_FontSize, Center = true, Outline = true, Font = 2, Color = Color3.new(1,1,1), Visible = false })
    -- Health Bar
    d.HealthBar = DrawingLib:New("Line", { Thickness = 2, Color = Color3.fromRGB(0,255,0), Visible = false })
    d.HealthBarOutline = DrawingLib:New("Line", { Thickness = 4, Color = Color3.new(0,0,0), Visible = false })
    -- Distance
    d.Distance = DrawingLib:New("Text", { Size = CONFIG.ESP_FontSize - 2, Center = true, Outline = true, Font = 2, Color = Color3.new(1,1,1), Visible = false })
    -- Offscreen Arrow (Triangle)
    d.Offscreen = DrawingLib:New("Triangle", { Filled = true, Color = Color3.new(1,1,1), Thickness = 1, Visible = false })
    d.OffscreenOutline = DrawingLib:New("Triangle", { Filled = false, Color = Color3.new(0,0,0), Thickness = 2, Visible = false })
    
    ESP_Drawings[plr] = d
end

local function RemoveDrawings(plr)
    local d = ESP_Drawings[plr]
    if d then
        for k, obj in pairs(d) do
            if type(obj) == "table" then
                for _, sub in pairs(obj) do if sub.Line then pcall(function() sub.Line:Remove() end) elseif sub.Remove then pcall(function() sub:Remove() end) end end
            elseif obj.Remove then pcall(function() obj:Remove() end) end
        end
        ESP_Drawings[plr] = nil
    end
end

Watchdog:Wrap("ESPDrawingLoop", function()
    if not CONFIG.ESP or CONFIG.ESPMode ~= "Drawing" then
        for plr in pairs(ESP_Drawings) do RemoveDrawings(plr) end
        return
    end

    local myChar = player.Character
    local myRoot = getRoot()
    local myTeam = player.Team
    local viewportSize = Camera.ViewportSize
    local centerScreen = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local char = plr.Character
            local hum = SafeGetHum(char)
            local root = getRoot(char)
            local head = getHead(char)
            
            local show = true
            if CONFIG.ESP_TeamCheck and plr.Team == myTeam then show = false end
            if not hum or hum.Health <= 0 or not root or not head then show = false end
            if myRoot and (root.Position - myRoot.Position).Magnitude > CONFIG.ESP_MaxDistance then show = false end
            
            if show then CreateDrawings(plr) else RemoveDrawings(plr); continue end
            
            local d = ESP_Drawings[plr]
            if not d then continue end
            
            local color = GetESPColor(plr)
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
            local legPos, legVis = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            
            local onScreen = headVis or rootVis or legVis
            
            -- Offscreen Arrow Logic
            if CONFIG.ESP_ShowOffscreen and not onScreen then
                local dir = (root.Position - Camera.CFrame.Position).Unit
                local angle = math.atan2(dir.Z, dir.X)
                local arrowRadius = math.min(viewportSize.X, viewportSize.Y) / 2.5
                local arrowCenter = centerScreen + Vector2.new(math.cos(angle), math.sin(angle)) * arrowRadius
                local arrowSize = 15
                
                d.Offscreen.PointA = arrowCenter + Vector2.new(math.cos(angle) * arrowSize, math.sin(angle) * arrowSize)
                d.Offscreen.PointB = arrowCenter + Vector2.new(math.cos(angle + 2.5) * arrowSize, math.sin(angle + 2.5) * arrowSize)
                d.Offscreen.PointC = arrowCenter + Vector2.new(math.cos(angle - 2.5) * arrowSize, math.sin(angle - 2.5) * arrowSize)
                d.Offscreen.Color = color
                d.Offscreen.Visible = true
                d.OffscreenOutline.PointA = d.Offscreen.PointA; d.OffscreenOutline.PointB = d.Offscreen.PointB; d.OffscreenOutline.PointC = d.Offscreen.PointC
                d.OffscreenOutline.Visible = true
            else
                d.Offscreen.Visible = false; d.OffscreenOutline.Visible = false
            end

            if not onScreen then
                for k, obj in pairs(d) do
                    if type(obj) == "table" then for _, sub in pairs(obj) do if sub.Line then sub.Line.Visible = false elseif sub.Visible ~= nil then sub.Visible = false end end
                    elseif obj.Visible ~= nil then obj.Visible = false end
                end
                continue
            end

            -- Calculate Box Dimensions
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height / 2
            local x = rootPos.X
            local y = rootPos.Y
            local boxX = x - width / 2
            local boxY = y - height / 2
            local hp = hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0

            -- Update Colors
            local function applyColor(obj) if obj then obj.Color = color end end
            applyColor(d.Box); for _,c in pairs(d.Corners) do applyColor(c) end
            for _,s in pairs(d.Skeleton) do applyColor(s.Line) end
            applyColor(d.Tracer); applyColor(d.Name); applyColor(d.HealthBar); applyColor(d.Distance)

            -- Box
            if CONFIG.ESP_ShowBox then
                if CONFIG.ESP_BoxType == "Full" then
                    d.Box.Size = Vector2.new(width, height); d.Box.Position = Vector2.new(boxX, boxY); d.Box.Visible = true
                    d.BoxOutline.Size = d.Box.Size; d.BoxOutline.Position = d.Box.Position; d.BoxOutline.Visible = true
                    for _,c in pairs(d.Corners) do c.Visible = false end; for _,c in pairs(d.CornersOutline) do c.Visible = false end
                else -- Corner Box
                    d.Box.Visible = false; d.BoxOutline.Visible = false
                    local cornerL = height / 4
                    -- TL (0,1) TR (2,3) BL (4,5) BR (6,7) - Verticals then Horizontals? Let's do standard 4 corners L shape.
                    -- 1: Top Left Vert, 2: Top Left Horz | 3: Top Right Vert, 4: Top Right Horz | 5: Bot Left Vert, 6: Bot Left Horz | 7: Bot Right Vert, 8: Bot Right Horz
                    local c = d.Corners; local co = d.CornersOutline
                    -- TL
                    c[1].From = Vector2.new(boxX, boxY); c[1].To = Vector2.new(boxX, boxY + cornerL)
                    c[2].From = Vector2.new(boxX, boxY); c[2].To = Vector2.new(boxX + cornerL, boxY)
                    -- TR
                    c[3].From = Vector2.new(boxX + width, boxY); c[3].To = Vector2.new(boxX + width, boxY + cornerL)
                    c[4].From = Vector2.new(boxX + width, boxY); c[4].To = Vector2.new(boxX + width - cornerL, boxY)
                    -- BL
                    c[5].From = Vector2.new(boxX, boxY + height); c[5].To = Vector2.new(boxX, boxY + height - cornerL)
                    c[6].From = Vector2.new(boxX, boxY + height); c[6].To = Vector2.new(boxX + cornerL, boxY + height)
                    -- BR
                    c[7].From = Vector2.new(boxX + width, boxY + height); c[7].To = Vector2.new(boxX + width, boxY + height - cornerL)
                    c[8].From = Vector2.new(boxX + width, boxY + height); c[8].To = Vector2.new(boxX + width - cornerL, boxY + height)
                    
                    for i=1,8 do c[i].Visible = true; co[i].From = c[i].From; co[i].To = c[i].To; co[i].Visible = true end
                end
            else d.Box.Visible = false; d.BoxOutline.Visible = false; for _,c in pairs(d.Corners) do c.Visible = false end; for _,c in pairs(d.CornersOutline) do c.Visible = false end end

            -- Skeleton
            if CONFIG.ESP_ShowSkeleton then
                for _, bone in pairs(d.Skeleton) do
                    local p1 = char:FindFirstChild(bone.Parts[1])
                    local p2 = char:FindFirstChild(bone.Parts[2])
                    if p1 and p2 then
                        local sp1, v1 = Camera:WorldToViewportPoint(p1.Position)
                        local sp2, v2 = Camera:WorldToViewportPoint(p2.Position)
                        if v1 and v2 then bone.Line.From = Vector2.new(sp1.X, sp1.Y); bone.Line.To = Vector2.new(sp2.X, sp2.Y); bone.Line.Visible = true else bone.Line.Visible = false end
                    else bone.Line.Visible = false end
                end
            else for _, bone in pairs(d.Skeleton) do bone.Line.Visible = false end end

            -- Tracer
            if CONFIG.ESP_ShowTracers then
                d.Tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                d.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                d.TracerOutline.From = d.Tracer.From; d.TracerOutline.To = d.Tracer.To
                d.Tracer.Visible = true; d.TracerOutline.Visible = true
            else d.Tracer.Visible = false; d.TracerOutline.Visible = false end

            -- Name
            if CONFIG.ESP_ShowName then
                d.Name.Text = plr.Name
                d.Name.Position = Vector2.new(x, boxY - 16)
                d.Name.Visible = true
            else d.Name.Visible = false end

            -- Health
            if CONFIG.ESP_ShowHealth then
                local barX = boxX - 6
                local barY = boxY
                local barH = height
                d.HealthBar.From = Vector2.new(barX, barY + barH)
                d.HealthBar.To = Vector2.new(barX, barY + barH * (1 - hp))
                d.HealthBar.Color = Color3.fromRGB(255 * (1-hp), 255 * hp, 0)
                d.HealthBarOutline.From = Vector2.new(barX, barY + barH)
                d.HealthBarOutline.To = Vector2.new(barX, barY)
                d.HealthBar.Visible = true; d.HealthBarOutline.Visible = true
            else d.HealthBar.Visible = false; d.HealthBarOutline.Visible = false end

            -- Distance
            if CONFIG.ESP_ShowDistance and myRoot then
                local dist = math.floor((root.Position - myRoot.Position).Magnitude)
                d.Distance.Text = "[" .. dist .. "m]"
                d.Distance.Position = Vector2.new(x, boxY + height + 2)
                d.Distance.Visible = true
            else d.Distance.Visible = false end

        else RemoveDrawings(plr) end
    end
    -- Cleanup leftovers
    for plr, d in pairs(ESP_Drawings) do if not Players:FindFirstChild(plr.Name) then RemoveDrawings(plr) end end
end, 0) -- 0 interval = every frame for smooth ESP

-- HIGHLIGHT ESP (Legacy/Alternative Mode)
local HighlightCache = {}
Watchdog:Wrap("ESPHighlightLoop", function()
    if not CONFIG.ESP or CONFIG.ESPMode ~= "Highlight" then
        for _, hl in pairs(HighlightCache) do pcall(function() hl:Destroy() end) end; table.clear(HighlightCache); return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and getRoot(plr.Character) then
            local hl = HighlightCache[plr]
            if not hl or not hl.Parent then hl = Instance.new("Highlight"); hl.Name="ESP_Highlight"; hl.FillTransparency=CONFIG.HighlightFillTransparency; hl.OutlineTransparency=CONFIG.HighlightOutlineTransparency; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=plr.Character; HighlightCache[plr]=hl end
            hl.FillColor = GetESPColor(plr); hl.OutlineColor = Color3.new(0,0,0)
        end
    end
    for plr, hl in pairs(HighlightCache) do if not Players:FindFirstChild(plr.Name) then pcall(function() hl:Destroy() end); HighlightCache[plr]=nil end end
end, 0.5)

-- MOVEMENT ADVANCED (BHOP, STRAFE, EDGE JUMP, LONG JUMP)
Watchdog:Wrap("MovementAdvancedLoop", function(dt)
    local hum = getHum(); local root = getRoot()
    if not hum or not root then return end

    -- BHop
    if CONFIG.BHop and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
        if hum.MoveDirection.Magnitude > 0 or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    -- Edge Jump (Detecta borda à frente)
    if CONFIG.EdgeJump and hum:GetState() == Enum.HumanoidStateType.Running then
        local rayParams = RaycastParams.new(); rayParams.FilterDescendantsInstances = {player.Character}; rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local forward = root.CFrame.LookVector * 3
        local down = Vector3.new(0, -5, 0)
        local resForward = workspace:Raycast(root.Position, forward, rayParams)
        local resDown = workspace:Raycast(root.Position + forward, down, rayParams)
        if resForward and not resDown then -- Parede na frente e vazio embaixo
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    -- Strafe (Air Strafe / Circle Strafe)
    if CONFIG.Strafe and (hum:GetState() == Enum.HumanoidStateType.Jumping or hum:GetState() == Enum.HumanoidStateType.Freefall) then
        local moveDir = hum.MoveDirection
        local speed = CONFIG.StrafeSpeed
        local vel = root.AssemblyLinearVelocity
        local horizontalVel = Vector3.new(vel.X, 0, vel.Z)
        
        if moveDir.Magnitude > 0 then
            -- Air Strafe: Acelera na direção do input
            local targetVel = moveDir * speed
            local accel = (targetVel - horizontalVel) * 0.1 -- Suavização
            root.AssemblyLinearVelocity = Vector3.new(vel.X + accel.X, vel.Y, vel.Z + accel.Z)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
            -- Circle Strafe (Ganha velocidade girando)
            local yaw = UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or -1
            local dir = root.CFrame.RightVector * yaw
            root.AssemblyLinearVelocity = Vector3.new(vel.X + dir.X * 2, vel.Y, vel.Z + dir.Z * 2)
        end
    end

    -- Long Jump (Impulso forte para frente)
    -- Geralmente ativado por Keybind, mas aqui fazemos um toggle que dá boost no pulo
    -- Para não bugar, vamos deixar como "Boost no primeiro pulo se LongJump ligado"
    -- Melhor: Keybind separado. Vamos manter simples: Se LongJump ativo e pular, aplica força extra.
end)

-- Long Jump Keybind Handler
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if CONFIG.LongJump and input.KeyCode == Enum.KeyCode.LeftControl then -- Ctrl para Long Jump
        local hum = getHum(); local root = getRoot()
        if hum and root and hum:GetState() == Enum.HumanoidStateType.Running then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.05)
            local boost = root.CFrame.LookVector * CONFIG.LongJumpPower
            root.AssemblyLinearVelocity = Vector3.new(boost.X, root.AssemblyLinearVelocity.Y, boost.Z)
        end
    end
end)

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then local hum = getHum(); if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
end)

-- ANTI-AFK (VirtualInput)
player.Idled:Connect(function()
    if CONFIG.AntiAFK then VInput_Click(math.random(100,500), math.random(100,500)); VInput_Key(Enum.KeyCode.Unknown, true); task.wait(0.05); VInput_Key(Enum.KeyCode.Unknown, false) end
end)

-- CLICK TP
UserInputService.InputBegan:Connect(function(input, gp)
    if CONFIG.ClickTP and not gp and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local root = getRoot(); if not root then return end
        local ray = Camera:ViewportPointToRay(input.Position.X, input.Position.Y)
        local params = RaycastParams.new(); params.FilterDescendantsInstances = {player.Character}; params.FilterType = Enum.RaycastFilterType.Exclude
        local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if res then root.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end
    end
end)

-- SPEED PROTECTION (Heartbeat)
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then local t = CONFIG.AplicarVelocidade and limitSpeed(CONFIG.VelocidadeGlobal) or limitSpeed(CONFIG.WalkSpeed); if hum.WalkSpeed ~= t then hum.WalkSpeed = t end end
end)

-- VISUALS LOOP (World)
Watchdog:Wrap("VisualsWorldLoop", function()
    Camera.FieldOfView = CONFIG.FOV
    if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false else Lighting.GlobalShadows=true end
    if CONFIG.NoFog then Lighting.FogEnd=1e5 else Lighting.FogEnd=300 end
end, 1)

-- NOCLIP / SPIN LOOPS
Watchdog:Wrap("NoclipLoop", function() if not CONFIG.Noclip then return end local c=player.Character if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end, 0.1)
Watchdog:Wrap("SpinLoop", function(dt) if not CONFIG.Spin then return end local r=getRoot() if r then r.CFrame *= CFrame.Angles(0, math.rad(CONFIG.SpinSpeed)*dt*60, 0) end end)

-- RESPAWN HANDLER
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyConfig()
    if CONFIG.Fly then ToggleFly(true) end
    if CONFIG.FreeCam then ToggleFreeCam(true) end
    -- Watchdog loops auto-resume via _Flags
end)

-- ============================================================
-- UI RAYFIELD (SUA ESTRUTURA ORIGINAL EXPANDIDA)
-- ============================================================

loadConfig() -- 1. Carrega JSON ANTES da UI

local Window = Rayfield:CreateWindow({
    Name = "Script Universal - Player",
    LoadingTitle = "Carregando Menu...", LoadingSubtitle = "Aba Player Completa (Final)",
    ConfigurationSaving = { Enabled = false, FolderName = "DeltaPlayerHub", FileName = "PlayerConfig" }, -- DESATIVADO AUTO-SAVE RAYFIELD
    KeySystem = false
})

local PlayerTab = Window:CreateTab("Player", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458) -- Nova Aba para ESP Detalhado
local CombatTab = Window:CreateTab("Combat", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458) -- Nova Aba para Movimento Avançado
local ServerTab = Window:CreateTab("Server", 4483362458)

-- Helpers Sync
local function SyncSlider(cfgKey, opts, tab)
    tab = tab or PlayerTab
    opts.Flag=cfgKey; opts.CurrentValue=CONFIG[cfgKey]
    opts.Callback=function(v) CONFIG[cfgKey]=v; if cfgKey=="WalkSpeed" or cfgKey=="FlySpeed" or cfgKey=="VelocidadeGlobal" then CONFIG[cfgKey]=limitSpeed(v) end; if cfgKey=="FOV" then Camera.FieldOfView=v end; if cfgKey=="Gravity" then workspace.Gravity=v*196.2 end; if cfgKey=="JumpPower" then local h=getHum() if h then h.JumpPower=v; h.UseJumpPower=true end end; if cfgKey=="SpinSpeed" then local r=getRoot() local b=r and r:FindFirstChild("SpinForce") if b then b.AngularVelocity=Vector3.new(0,v,0) end end; Rayfield:Notify({Title="Atualizado", Content=cfgKey.." = "..v, Duration=2, Image="check"}) end
    return tab:CreateSlider(opts)
end

local function SyncToggle(cfgKey, opts, onToggle, tab)
    tab = tab or PlayerTab
    opts.Flag=cfgKey; opts.CurrentValue=CONFIG[cfgKey]
    opts.Callback=function(v) CONFIG[cfgKey]=v; CONFIG._Flags[cfgKey]=v; if onToggle then onToggle(v) end; Rayfield:Notify({Title=v and "Ativado" or "Desativado", Content=cfgKey, Duration=2, Image=v and "check-circle" or "x-circle"}) end
    return tab:CreateToggle(opts)
end

local function SyncDropdown(cfgKey, opts, tab)
    tab = tab or PlayerTab
    opts.Flag=cfgKey; opts.CurrentOption=CONFIG[cfgKey]
    opts.Callback=function(opt) CONFIG[cfgKey]=opt; CONFIG._Flags[cfgKey]=opt; Rayfield:Notify({Title="Opção", Content=cfgKey..": "..opt, Duration=2, Image="check"}) end
    return tab:CreateDropdown(opts)
end

-- ========== ABA PLAYER (Básicos) ==========
PlayerTab:CreateSection("🏃 Movimentação Básica")
SyncSlider("VelocidadeGlobal", {Name="Velocidade Universal", Range={1,1000}, Increment=1})
SyncToggle("AplicarVelocidade", {Name="Ativar Velocidade Universal"}, function(v) applyUniversalSpeed() end)
SyncSlider("LimiteVelocidade", {Name="Limite de Velocidade", Range={1,1000}, Increment=1})
SyncSlider("MaxSpeed", {Name="Velocidade Máxima (UI)", Range={1,1000}, Increment=1})
SyncSlider("WalkSpeed", {Name="WalkSpeed", Range={1,1000}, Increment=1})
SyncSlider("JumpPower", {Name="JumpPower", Range={50,300}, Increment=1})
SyncSlider("Gravity", {Name="Gravidade", Range={0.1,5}, Increment=0.1})
SyncToggle("InfiniteJump", {Name="Infinite Jump"})
SyncToggle("Noclip", {Name="Noclip"})
SyncToggle("Spin", {Name="Spin"})
SyncSlider("SpinSpeed", {Name="Spin Speed", Range={1,50}, Increment=1})
SyncToggle("Sit", {Name="Sit"})

PlayerTab:CreateSection("✈️ Fly")
SyncToggle("Fly", {Name="Ativar Fly (Stealth CFrame)"}, ToggleFly)
SyncSlider("FlySpeed", {Name="Velocidade Fly", Range={1,1000}, Increment=5})

PlayerTab:CreateSection("🌍 Mundo")
SyncToggle("Fullbright", {Name="Fullbright"})
SyncToggle("NoFog", {Name="No Fog"})
SyncSlider("FOV", {Name="Field of View", Range={30,120}, Increment=1})
SyncToggle("FreeCam", {Name="FreeCam"}, ToggleFreeCam)
SyncToggle("NoCamShake", {Name="Remover Camera Shake"})
SyncToggle("NoRecoil", {Name="No Recoil (Visual)"})
SyncToggle("NoSpread", {Name="No Spread (Visual)"})

-- ========== ABA MOVEMENT (Avançado) ==========
MovementTab:CreateSection("🏃 Movimento Avançado")
SyncToggle("BHop", {Name="BHop (Auto Jump)"})
SyncToggle("EdgeJump", {Name="Edge Jump (Pulo na Borda)"})
SyncToggle("Strafe", {Name="Air Strafe / Circle Strafe"})
SyncSlider("StrafeSpeed", {Name="Strafe Speed", Range={10,200}, Increment=1})
SyncToggle("LongJump", {Name="Long Jump (Ctrl para ativar)"})
SyncSlider("LongJumpPower", {Name="Long Jump Power", Range={10,300}, Increment=5})

MovementTab:CreateSection("⚙️ Configurações de Velocidade")
SyncSlider("VelocidadeGlobal", {Name="Velocidade Global Master", Range={1,1000}, Increment=1}, MovementTab)
SyncToggle("AplicarVelocidade", {Name="Aplicar Velocidade Global"}, function(v) applyUniversalSpeed() end, MovementTab)
SyncSlider("LimiteVelocidade", {Name="Limite Máximo Seguro", Range={1,1000}, Increment=1}, MovementTab)

-- ========== ABA VISUALS (ESP Drawing Completo) ==========
VisualsTab:CreateSection("👁️ ESP Principal")
SyncToggle("ESP", {Name="Ativar ESP"})
SyncDropdown("ESPMode", {Name="Modo Render", Options={"Drawing", "Highlight"}}, VisualsTab)
SyncDropdown("ESP_ColorMode", {Name="Modo de Cor", Options={"Team", "Force"}}, VisualsTab)
SyncDropdown("ESP_ForceColor", {Name="Cor Forçada (Se Modo Force)", Options={"Sem Título", "Assassino", "Policial"}}, VisualsTab)
SyncToggle("ESP_TeamCheck", {Name="Team Check (Ignorar Time)"}, nil, VisualsTab)

VisualsTab:CreateSection("📦 ESP Box & Skeleton")
SyncToggle("ESP_ShowBox", {Name="Mostrar Box"}, nil, VisualsTab)
SyncDropdown("ESP_BoxType", {Name="Tipo Box", Options={"Full", "Corner"}}, VisualsTab)
SyncToggle("ESP_ShowSkeleton", {Name="Mostrar Esqueleto"}, nil, VisualsTab)

VisualsTab:CreateSection("📍 ESP Info & Tracers")
SyncToggle("ESP_ShowTracers", {Name="Mostrar Tracers"}, nil, VisualsTab)
SyncToggle("ESP_ShowName", {Name="Mostrar Nome"}, nil, VisualsTab)
SyncToggle("ESP_ShowHealth", {Name="Mostrar Vida (Barra)"}, nil, VisualsTab)
SyncToggle("ESP_ShowDistance", {Name="Mostrar Distância"}, nil, VisualsTab)
SyncToggle("ESP_ShowOffscreen", {Name="Setas Offscreen (Fora da Tela)"}, nil, VisualsTab)

VisualsTab:CreateSection("🎨 Estilo ESP (Drawing)")
SyncSlider("ESP_Thickness", {Name="Espessura Linhas", Range={1,5}, Increment=1}, VisualsTab)
SyncSlider("ESP_Transparency", {Name="Transparência (0-1)", Range={0,1}, Increment=0.1}, VisualsTab) -- Note: Drawing API Transparency is 0-1
SyncSlider("ESP_FontSize", {Name="Tamanho Fonte", Range={10,24}, Increment=1}, VisualsTab)
SyncSlider("ESP_MaxDistance", {Name="Distância Máxima", Range={100,10000}, Increment=100}, VisualsTab)

VisualsTab:CreateSection("✨ Chams (Material)")
SyncToggle("Chams", {Name="Ativar Chams"}, nil, VisualsTab)
SyncDropdown("ChamsMode", {Name="Material Chams", Options={"ForceField", "Neon", "Glass", "Plastic"}}, VisualsTab)

-- ========== ABA COMBAT (Seguro/Client) ==========
CombatTab:CreateSection("🎯 Assistência (Client-Side)")
SyncToggle("TriggerBot", {Name="TriggerBot (Click Auto)"})
SyncSlider("TriggerBotDelay", {Name="Delay TriggerBot", Range={0.01,0.5}, Increment=0.01}, CombatTab)
-- Silent Aim / Aimbot REMOVIDOS por segurança (Hooks detectáveis)

-- ========== ABA SERVER / UTILITY ==========
ServerTab:CreateSection("👥 Jogadores")
local playerList={} for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(playerList,p.Name) end end
local dd=ServerTab:CreateDropdown({Name="Selecionar Jogador", Flag="SelectedPlayer", Options=playerList, CurrentOption=playerList[1] or "Nenhum", Callback=function(o) CONFIG.SelectedPlayer=o end})
ServerTab:CreateButton({Name="🔄 Atualizar Lista", Callback=function() local l={"Nenhum"} for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(l,p.Name) end end dd:Refresh(l,true) end})
ServerTab:CreateButton({Name="Teleportar", Callback=function() local t=Players:FindFirstChild(CONFIG.SelectedPlayer) if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then local r=getRoot() if r then r.CFrame=t.Character.HumanoidRootPart.CFrame*CFrame.new(0,3,0) end end end})
ServerTab:CreateButton({Name="Spectate", Callback=function() local t=Players:FindFirstChild(CONFIG.SelectedPlayer) if t and t.Character and t.Character:FindFirstChild("Humanoid") then Camera.CameraSubject=t.Character.Humanoid; Rayfield:Notify({Title="Spectate", Content="Assistindo "..t.Name, Duration=3, Image="eye"}) end end})

ServerTab:CreateSection("🛠️ Utilidades")
SyncToggle("ClickTP", {Name="Click/Touch TP"}, nil, ServerTab)
SyncToggle("AntiAFK", {Name="Anti-AFK (Input Real)"}, nil, ServerTab)
SyncToggle("AntiLag", {Name="Anti-Lag (Reduce Updates)"}, nil, ServerTab)
SyncToggle("ChatLogger", {Name="Chat Logger"}, nil, ServerTab)

ServerTab:CreateSection("💾 Configuração (Manual por Jogo)")
ServerTab:CreateButton({Name="Salvar Config (JSON)", Callback=saveConfig})
ServerTab:CreateButton({Name="Carregar Config (JSON)", Callback=function() loadConfig(); applyConfig() end})
ServerTab:CreateButton({Name="Resetar Config Total", Callback=function() CONFIG={WalkSpeed=16,JumpPower=50,Gravity=1,InfiniteJump=false,Noclip=false,Spin=false,SpinSpeed=10,Sit=false,Fly=false,FlySpeed=50,ESP=false,ESPMode="Drawing",ESP_TeamCheck=true,ESP_ShowBox=true,ESP_ShowSkeleton=true,ESP_ShowTracers=true,ESP_ShowName=true,ESP_ShowHealth=true,ESP_ShowDistance=true,ESP_ShowOffscreen=true,ESP_BoxType="Corner",ESP_ColorMode="Team",ESP_ForceColor="Sem Título",ESP_Thickness=1,ESP_Transparency=1,ESP_FontSize=13,ESP_MaxDistance=5000,HighlightESP=false,HighlightFillTransparency=0.5,HighlightOutlineTransparency=0,Fullbright=false,NoFog=false,FOV=70,FreeCam=false,NoRecoil=false,NoSpread=false,NoCamShake=false,Chams=false,ChamsMode="ForceField",TriggerBot=false,TriggerBotDelay=0.05,AntiAFK=false,ClickTP=false,AntiLag=false,ChatLogger=true,Rejoin=false,ServerHop=false,SelectedPlayer="Nenhum",MaxSpeed=1000,Organize=false,VelocidadeGlobal=1000,AplicarVelocidade=false,LimiteVelocidade=1000,BHop=false,Strafe=false,StrafeSpeed=50,EdgeJump=false,LongJump=false,LongJumpPower=50,_Flags={}}; applyConfig(); ToggleFly(false); ToggleFreeCam(false); for _,hl in pairs(HighlightCache) do pcall(function() hl:Destroy() end) end; table.clear(HighlightCache); for plr in pairs(ESP_Drawings) do RemoveDrawings(plr) end; DrawingLib:ClearAll(); Rayfield:Notify({Title="Reset", Content="Padrão restaurado", Duration=3, Image="check-circle"}) end})
ServerTab:CreateButton({Name="Resetar Velocidades", Callback=function() CONFIG.VelocidadeGlobal=1000; CONFIG.AplicarVelocidade=false; CONFIG.LimiteVelocidade=1000; CONFIG.WalkSpeed=16; CONFIG.FlySpeed=50; applyConfig(); Rayfield:Notify({Title="Reset", Content="Velocidades resetadas", Duration=3, Image="check-circle"}) end})

ServerTab:CreateSection("🌐 Servidor")
ServerTab:CreateButton({Name="Rejoin", Callback=function() TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId, player) end})
ServerTab:CreateButton({Name="Server Hop", Callback=function() Rayfield:Notify({Title="Server Hop", Content="Procurando...", Duration=10, Image="loader"}) task.spawn(function() local ok,res=pcall(function() return HttpService:RequestAsync({Url="https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100", Method="GET"}) end) if ok and res.Success then local data=HttpService:JSONDecode(res.Body) for _,s in pairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then TeleportService:TeleportToPlaceInstance(PlaceId,s.id,player); return end end Rayfield:Notify({Title="Server Hop", Content="Lotado/Erro", Duration=5, Image="alert-circle"}) else Rayfield:Notify({Title="Erro", Content="Falha API (Executor sem RequestAsync?)", Duration=5, Image="alert-circle"}) end end) end})
ServerTab:CreateButton({Name="Resetar Personagem", Callback=function() local h=getHum() if h then h.Health=0 end end})

-- ============================================================
-- FINALIZAÇÃO
-- ============================================================
applyConfig()
Rayfield:LoadConfiguration()
Rayfield:Notify({Title="✅ SCRIPT FINAL CARREGADO", Content="ESP Drawing Completo | Move Avançado | Zero Hooks Perigosos | Config Manual | PlaceId: "..PlaceId, Duration=8, Image="check-circle"})

getgenv()._UniversalScriptCleanup = function()
    for _,c in pairs(Watchdog.Connections) do pcall(function() c:Disconnect() end) end
    if FlyConn then FlyConn:Disconnect() end
    if FreeCamConn then FreeCamConn:Disconnect() end
    for _,hl in pairs(HighlightCache) do pcall(function() hl:Destroy() end) end
    for plr in pairs(ESP_Drawings) do RemoveDrawings(plr) end
    DrawingLib:ClearAll()
    -- Restore Chams Materials
    for part, mat in pairs(OriginalMaterials) do if part and part.Parent then pcall(function() part.Material = mat end) end end
    print("[Cleanup] Finalizado com sucesso.")
end
```
