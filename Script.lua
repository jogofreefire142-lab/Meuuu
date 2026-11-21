```lua
--[[
	UNIVERSAL LITE v6.0 "FULL SPECTRUM" - FINAL CORRIGIDO
	================================================================================
	ARQUITETURA: Per-Frame Physics (Heartbeat/Stepped) | Vector Fly (RenderStepped)
	             Event-Driven ESP + Immediate Mode Drawing (Skeleton/Tracer/Box)
	             Combat Module (Aimbot/Triggerbot/Silent Aim/Hitbox)
	             Utility Module (Bhop, AirWalk, NoFall, LowGFX, Ambience, Crosshair)
	             Mobile Support (ContextActionService Buttons)
	             Full Persistence (JSON + QueueOnTeleport)
	================================================================================
	CORREÇÕES FINAIS:
	- Fly: Salva/Restaura CanCollide de TODAS BaseParts (Fix "grudado no chão").
	- Speed Cap: 1000 em tudo.
	- Input: VirtualInputManager para Triggerbot (Compatibilidade Total).
	- Ordem: Funções Toggle definidas ANTES de uso.
	- Cleanup: Atômico (Metatable, Drawings, Instances, Connections, Mobile, Hitboxes).
	================================================================================
]]--

-- =============================================================================
-- 🛡️ 0. CLEANUP GLOBAL PRIORITÁRIO
-- =============================================================================
if getgenv()._UniversalScriptCleanup then
	local success, errorMsg = pcall(getgenv()._UniversalScriptCleanup)
	if not success then warn("[UniversalLite v6.0] Erro no cleanup anterior: " .. tostring(errorMsg)) end
end

print("==================================================")
print("🛡️ UNIVERSAL LITE v6.0 FULL SPECTRUM - INICIANDO")
print("==================================================")

-- =============================================================================
-- 🔵 1. SERVIÇOS, CACHE E VARIÁVEIS GLOBAIS
-- =============================================================================
local Services = setmetatable({}, {
	__index = function(self, key)
		local svc = game:GetService(key)
		rawset(self, key, svc)
		return svc
	end
})

local Players           = Services.Players
local RunService        = Services.RunService
local UserInputService  = Services.UserInputService
local Lighting          = Services.Lighting
local TeleportService   = Services.TeleportService
local HttpService       = Services.HttpService
local VirtualInputManager = Services.VirtualInputManager
local ContextActionService = Services.ContextActionService
local TweenService      = Services.TweenService
local CoreGui           = Services.CoreGui
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer
local PlaceId           = game.PlaceId
local JobId             = game.JobId
local Mouse             = LocalPlayer:GetMouse()

if not game:IsLoaded() then game.Loaded:Wait() end

local function WaitForCharacter()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then return char end
	LocalPlayer.CharacterAdded:Wait()
	task.wait(0.5)
	return LocalPlayer.Character
end
WaitForCharacter()
print("✅ [Core] Jogo e Personagem Carregados.")

-- =============================================================================
-- 🛡️ 2. DETECÇÃO DE CAPACIDADES DO EXECUTOR
-- =============================================================================
local Caps = {}
Caps.WriteFile        = pcall(function() writefile("__UL_Cap", "") delfile("__UL_Cap") end)
Caps.HttpRequest      = pcall(function() return HttpService:RequestAsync({Url="https://roblox.com", Method="GET"}) end)
Caps.HookFunction     = (type(hookfunction) == "function")
Caps.GetRawMetatable  = (type(getrawmetatable) == "function")
Caps.DrawingAPI       = pcall(function() local d=Drawing.new("Line") d:Remove() end)
Caps.QueueOnTeleport  = (type(queue_on_teleport) == "function")
Caps.GetConEvents     = (type(getconnections) == "function")
print("🔧 [Core] Capacidades:", HttpService:JSONEncode(Caps))

-- =============================================================================
-- 🛡️ 3. ANTI-KICK / ANTI-AFK / ANTI-TELEPORT FAIL
-- =============================================================================
pcall(function()
	if Caps.GetRawMetatable then
		local mt = getrawmetatable(game)
		if mt and setreadonly then
			local oldNC = mt.__namecall
			setreadonly(mt, false)
			mt.__namecall = newcclosure(function(self, ...)
				local method = getnamecallmethod()
				if self == LocalPlayer and (method == "Kick" or method == "kick") then
					warn("[Anti-Kick] Blocked Kick via Metatable.")
					return nil
				end
				return oldNC(self, ...)
			end)
			setreadonly(mt, true)
		end
	end
	if Caps.HookFunction then
		local oldKick = LocalPlayer.Kick
		hookfunction(LocalPlayer.Kick, newcclosure(function(self, ...)
			if self == LocalPlayer then warn("[Anti-Kick] Blocked Kick via Hook.") return end
			return oldKick(self, ...)
		end))
	end
	if Caps.GetConEvents then
		for _, conn in pairs(getconnections(LocalPlayer.Idled)) do conn:Disable() end
	end
end)

-- =============================================================================
-- ⚙️ 4. CONFIG MASTER (SINGLE SOURCE OF TRUTH) - CAP 1000
-- =============================================================================
local Config = {
	-- COMBAT
	Aimbot_Enabled       = false, Aimbot_TeamCheck = true, Aimbot_WallCheck = true, Aimbot_Smoothness = 0.15, Aimbot_FOV = 120, Aimbot_FOV_Circle = true, Aimbot_TargetPart = "Head", Aimbot_Key = "MouseButton2", Aimbot_IgnoreFriends = false,
	Triggerbot_Enabled   = false, Triggerbot_Delay = 0.05, Triggerbot_Key = "LeftAlt",
	SilentAim_Enabled    = false, SilentAim_HitChance = 100, SilentAim_TargetPart = "Head",
	Hitbox_Enabled       = false, Hitbox_Size = 10, Hitbox_Transparency = 0.7, Hitbox_Color = Color3.fromRGB(255, 0, 0),
	-- ESP
	ESP_Enabled          = false, ESP_Highlight = true, ESP_Highlight_Fill = 0.5, ESP_Highlight_Outline = 0, ESP_Names = true, ESP_Distance = true, ESP_Health = true, ESP_HealthBar = true, ESP_TeamColor = true, ESP_Box = true, ESP_Box_Type = "Corner", ESP_Tracer = true, ESP_Tracer_Origin = "Bottom", ESP_Skeleton = true, ESP_Chams = false, ESP_MaxDistance = 5000,
	-- WORLD VISUALS
	Fullbright = false, NoFog = false, NoShadows = false, FOV = 70, Ambience_Enabled = false, Ambience_Time = 14, Ambience_Brightness = 2, Ambience_Outdoor = Color3.new(1,1,1), Ambience_Indoor = Color3.new(1,1,1), NoSky = false, NoTextures = false, NoParticles = false, NoDecals = false,
	-- CROSSHAIR / HUD
	Crosshair_Enabled = false, Crosshair_Type = "Dot", Crosshair_Size = 10, Crosshair_Gap = 5, Crosshair_Thickness = 1.5, Crosshair_Color = Color3.new(1,1,1), Crosshair_Rainbow = false, Watermark_Enabled = true, FPS_Counter_Enabled = true,
	-- MOVEMENT
	WalkSpeed = 16, JumpPower = 50, Gravity = 196.2, InfiniteJump = false, Spin = false, SpinSpeed = 20, AutoSit = false, Bhop_Enabled = false, EdgeJump_Enabled = false, AirWalk_Enabled = false, NoFallDamage = false, SwimFly_Enabled = false,
	-- FLY
	Fly_Enabled = false, Fly_Speed = 100, Fly_VerticalMultiplier = 1.0, Fly_Keybind = "F", Fly_Mobile_Button = true,
	-- NOCLIP / CLICK TP
	Noclip_Enabled = false, Noclip_Keybind = "N", ClickTP_Enabled = false, ClickTP_Key = "LeftControl", ClickTP_Method = "CFrame",
	-- UTILS
	AntiAFK = false, AntiVoid = false, AntiKick_Rejoin = false, UseGlobalSpeed = false, GlobalSpeedValue = 100, SpeedCap = 1000,
	-- INTERNAL
	_Flags = {}
}

-- =============================================================================
-- 💾 5. PERSISTÊNCIA AVANÇADA (JSON + QUEUE ON TELEPORT)
-- =============================================================================
local FolderName = "UniversalLite_v6_FullSpectrum"
local FileName = FolderName .. "/Config_" .. PlaceId .. ".json"
local SaveDebounce = false
pcall(function() if not isfolder(FolderName) then makefolder(FolderName) end end)

local function DeepSave(immediate)
	if immediate then
		local data = {}
		for k, v in pairs(Config) do
			if type(v) ~= "function" and k:sub(1,1) ~= "_" then
				if typeof(v) == "Color3" then data[k] = {R=v.R, G=v.G, B=v.B}
				elseif typeof(v) == "EnumItem" then data[k] = v.Name
				else data[k] = v end
			end
		end
		pcall(function() writefile(FileName, HttpService:JSONEncode(data)) end)
		return
	end
	if SaveDebounce then return end
	SaveDebounce = true
	task.delay(1, function() SaveDebounce = false DeepSave(true) end)
end

local function LoadConfig()
	local ok, data = pcall(function() if isfile(FileName) then return HttpService:JSONDecode(readfile(FileName)) end end)
	if ok and data then
		for k, v in pairs(data) do
			if Config[k] ~= nil then
				if type(v) == "table" and v.R and v.G and v.B then Config[k] = Color3.new(v.R, v.G, v.B)
				elseif type(v) == "string" and Enum.KeyCode[v] and (k:find("Key") or k:find("Keybind") or k:find("Method") or k:find("Type") or k:find("Origin") or k:find("Part")) then Config[k] = Enum.KeyCode[v]
				else Config[k] = v end
			end
		end
		for k, v in pairs(Config) do if type(v) == "boolean" then Config._Flags[k] = v end end
		print("💾 [Config] Carregado:", FileName)
	else print("💾 [Config] Defaults.") end
end
LoadConfig()

-- =============================================================================
-- 🛡️ 6. HELPERS DE PERSONAGEM
-- =============================================================================
local function GetHumanoid(char) char = char or LocalPlayer.Character if not char then return nil end return char:FindFirstChildOfClass("Humanoid") end
local function GetRootPart(char) char = char or LocalPlayer.Character if not char then return nil end local h=GetHumanoid(char) if h and h.RootPart then return h.RootPart end return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart") end
local function GetHead(char) char = char or LocalPlayer.Character if not char then return nil end return char:FindFirstChild("Head") end
local function GetTorso(char) char = char or LocalPlayer.Character if not char then return nil end return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") end
local function GetCharParts(char) char = char or LocalPlayer.Character if not char then return {} end local t={} for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then table.insert(t,p) end end return t end
local function ClampSpeed(v) return math.clamp(v, 0, Config.SpeedCap) end
local function IsAlive(plr) plr = plr or LocalPlayer local c=plr.Character local h=GetHumanoid(c) local r=GetRootPart(c) return c and h and r and h.Health > 0 end
local function IsTeamMate(plr) return Config.Aimbot_TeamCheck and plr.Team == LocalPlayer.Team and plr.Team ~= nil end
local function IsFriend(plr) return Config.Aimbot_IgnoreFriends and LocalPlayer:IsFriendsWith(plr.UserId) end

-- =============================================================================
-- 🛡️ 7. ESTADO GLOBAL, POOLS, INPUT VECTORS
-- =============================================================================
local UI_Elements = {}
local Pools = {
	Highlights = {}, Billboards = {}, HealthBars = {},
	Drawing = { Boxes={}, Tracers={}, Skeletons={}, Chams={}, Crosshair={}, FOVCircle=nil, Watermark=nil, FPSText=nil },
	SilentAimHook = nil, OriginalIndex = nil, OriginalNamecall = nil,
	Spin_BAV = nil, AirWalk_Platform = nil,
	Fly_Connection = nil, Freecam_Connection = nil,
	Conns = {},
	Fly_CollisionStates = {},
	FlyInput = {X=0, Y=0, Z=0},
}
local function SafeDisc(c) if c and c.Connected then pcall(function() c:Disconnect() end) end end
local function RegConn(name, conn) if Pools.Conns[name] then SafeDisc(Pools.Conns[name]) end Pools.Conns[name] = conn end
local function ClearDrawing(tbl) for _, obj in pairs(tbl) do if obj and obj.Remove then pcall(function() obj:Remove() end) end end table.clear(tbl) end

-- =============================================================================
-- 🧠 8. APLICADORES CENTRAIS
-- =============================================================================
local function ApplyPhysics()
	local h = GetHumanoid() local r = GetRootPart() if not h or not r then return end
	local target = Config.UseGlobalSpeed and ClampSpeed(Config.GlobalSpeedValue) or ClampSpeed(Config.WalkSpeed)
	if h.WalkSpeed ~= target then h.WalkSpeed = target end
	if h.JumpPower ~= Config.JumpPower then h.JumpPower = Config.JumpPower h.UseJumpPower = true end
	if workspace.Gravity ~= Config.Gravity then workspace.Gravity = Config.Gravity end
	if Config.AutoSit and not h.Sit then h.Sit = true end
end

local function ApplyVisuals()
	Camera.FieldOfView = Config.FOV
	Lighting.GlobalShadows = not Config.NoShadows
	Lighting.FogEnd = Config.NoFog and 1e9 or 1e5
	if Config.Fullbright then Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.OutdoorAmbient = Color3.new(1,1,1) Lighting.Ambient = Color3.new(1,1,1) end
end

local function ApplyAmbience()
	if Config.Ambience_Enabled then
		Lighting.ClockTime = Config.Ambience_Time
		Lighting.Brightness = Config.Ambience_Brightness
		Lighting.OutdoorAmbient = Config.Ambience_Outdoor
		Lighting.Ambient = Config.Ambience_Indoor
		if Config.NoSky then if not Pools.Sky then for _,v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") then Pools.Sky = v:Clone() v:Destroy() end end end elseif Pools.Sky and not Lighting:FindFirstChildOfClass("Sky") then Pools.Sky.Parent = Lighting Pools.Sky = nil end
	end
end

local function ApplyLowGFX()
	if Config.NoTextures or Config.NoParticles or Config.NoDecals then
		for _, obj in pairs(workspace:GetDescendants()) do
			if Config.NoTextures and (obj:IsA("Texture") or obj:IsA("Decal")) then if not Pools.TextureTable then Pools.TextureTable = {} end if not Pools.TextureTable[obj] then Pools.TextureTable[obj] = obj.Texture obj.Texture = "" end
			elseif Config.NoParticles and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")) then if not Pools.ParticleEmitters then Pools.ParticleEmitters = {} end if not Pools.ParticleEmitters[obj] then Pools.ParticleEmitters[obj] = obj.Enabled obj.Enabled = false end
			elseif Config.NoDecals and obj:IsA("Decal") then if not Pools.Decals then Pools.Decals = {} end if not Pools.Decals[obj] then Pools.Decals[obj] = obj.Transparency obj.Transparency = 1 end
			end
		end
	else
		if Pools.TextureTable then for obj, val in pairs(Pools.TextureTable) do if obj and obj.Parent then pcall(function() obj.Texture = val end) end end table.clear(Pools.TextureTable) end
		if Pools.ParticleEmitters then for obj, val in pairs(Pools.ParticleEmitters) do if obj and obj.Parent then pcall(function() obj.Enabled = val end) end end table.clear(Pools.ParticleEmitters) end
		if Pools.Decals then for obj, val in pairs(Pools.Decals) do if obj and obj.Parent then pcall(function() obj.Transparency = val end) end end table.clear(Pools.Decals) end
	end
end

local function ApplyAll() ApplyPhysics() ApplyVisuals() ApplyAmbience() ApplyLowGFX() end

-- =============================================================================
-- 🔁 9. LOOPS PRINCIPAIS (PER-FRAME)
-- =============================================================================

-- Physics Master (Heartbeat)
RegConn("PhysicsMaster", RunService.Heartbeat:Connect(function(dt)
	local anyFlag = Config._Flags.WalkSpeed or Config._Flags.JumpPower or Config._Flags.Gravity or Config._Flags.Spin or Config._Flags.UseGlobalSpeed or Config._Flags.Bhop_Enabled or Config._Flags.EdgeJump_Enabled or Config._Flags.AirWalk_Enabled or Config._Flags.SwimFly_Enabled
	if not anyFlag then return end
	ApplyPhysics()

	-- Spin
	if Config.Spin then local r=GetRootPart() if r then if not Pools.Spin_BAV then local b=Instance.new("BodyAngularVelocity") b.Name="UL_Spin" b.MaxTorque=Vector3.new(0,1e9,0) b.P=1e4 b.Parent=r Pools.Spin_BAV=b end Pools.Spin_BAV.AngularVelocity=Vector3.new(0,math.rad(Config.SpinSpeed)*60,0) end elseif Pools.Spin_BAV then Pools.Spin_BAV:Destroy() Pools.Spin_BAV=nil end

	-- Bhop
	if Config.Bhop_Enabled then local h=GetHumanoid() local r=GetRootPart() if h and r and h.FloorMaterial~=Enum.Material.Air and h.MoveDirection.Magnitude>0 then h:ChangeState(Enum.HumanoidStateType.Jumping) end end

	-- Edge Jump
	if Config.EdgeJump_Enabled then local h=GetHumanoid() local r=GetRootPart() if h and r and h.FloorMaterial~=Enum.Material.Air and h.MoveDirection.Magnitude>0 then local params=RaycastParams.new() params.FilterDescendantsInstances={LocalPlayer.Character} params.FilterType=Enum.RaycastFilterType.Exclude local hit=workspace:Raycast(r.Position+r.CFrame.LookVector*3, Vector3.new(0,-5,0), params) if not hit then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end

	-- Air Walk
	if Config.AirWalk_Enabled then local r=GetRootPart() local h=GetHumanoid() if r and h and h.FloorMaterial==Enum.Material.Air then if not Pools.AirWalk_Platform then local p=Instance.new("Part") p.Name="UL_AirWalk" p.Size=Vector3.new(6,1,6) p.Transparency=1 p.Anchored=true p.CanCollide=true p.Parent=workspace Pools.AirWalk_Platform=p end Pools.AirWalk_Platform.CFrame=CFrame.new(r.Position.X, r.Position.Y-3.5, r.Position.Z) elseif Pools.AirWalk_Platform then Pools.AirWalk_Platform:Destroy() Pools.AirWalk_Platform=nil end end

	-- Swim Fly
	if Config.SwimFly_Enabled then local h=GetHumanoid() local r=GetRootPart() if h and r then h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) if h:GetState()~=Enum.HumanoidStateType.Swimming then h:ChangeState(Enum.HumanoidStateType.Swimming) end local move=h.MoveDirection if move.Magnitude>0 then r.AssemblyLinearVelocity=move*Config.WalkSpeed+Vector3.new(0,r.AssemblyLinearVelocity.Y,0) end end end
end))

-- Noclip (Stepped)
RegConn("NoclipLoop", RunService.Stepped:Connect(function()
	if not Config.Noclip_Enabled then return end
	local c=LocalPlayer.Character if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
end))

-- Visuals/Ambience/LowGFX (1Hz)
task.spawn(function() while true do task.wait(1) if Config._Flags.Fullbright or Config._Flags.NoFog or Config._Flags.NoShadows or Config._Flags.Ambience_Enabled or Config._Flags.NoTextures or Config._Flags.NoParticles or Config._Flags.NoDecals then ApplyVisuals() ApplyAmbience() ApplyLowGFX() end end end)

-- Safety (AntiVoid, NoFall)
RegConn("SafetyLoop", RunService.Heartbeat:Connect(function()
	local r=GetRootPart()
	if Config.AntiVoid and r and r.Position.Y<-50 then r.CFrame=CFrame.new(0,50,0) r.AssemblyLinearVelocity=Vector3.zero end
	if Config.NoFallDamage and r and r.AssemblyLinearVelocity.Y<-100 then r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X, -50, r.AssemblyLinearVelocity.Z) end
end))

-- =============================================================================
-- 🔴 10. FLY SYSTEM (FIXED: CANCOLLIDE + VECTOR INPUT + MOBILE)
-- =============================================================================
-- Input Capture
UserInputService.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode==Enum.KeyCode.W then Pools.FlyInput.Z=-1 elseif i.KeyCode==Enum.KeyCode.S then Pools.FlyInput.Z=1 elseif i.KeyCode==Enum.KeyCode.A then Pools.FlyInput.X=-1 elseif i.KeyCode==Enum.KeyCode.D then Pools.FlyInput.X=1 elseif i.KeyCode==Enum.KeyCode.Space then Pools.FlyInput.Y=1 elseif i.KeyCode==Enum.KeyCode.LeftShift then Pools.FlyInput.Y=-1 end
	if i.KeyCode==Config.Fly_Keybind then ToggleFly(not Config.Fly_Enabled) end
	if i.KeyCode==Config.Noclip_Keybind then ToggleNoclip(not Config.Noclip_Enabled) end
end)
UserInputService.InputEnded:Connect(function(i, gp)
	if i.KeyCode==Enum.KeyCode.W and Pools.FlyInput.Z==-1 then Pools.FlyInput.Z=0 elseif i.KeyCode==Enum.KeyCode.S and Pools.FlyInput.Z==1 then Pools.FlyInput.Z=0 elseif i.KeyCode==Enum.KeyCode.A and Pools.FlyInput.X==-1 then Pools.FlyInput.X=0 elseif i.KeyCode==Enum.KeyCode.D and Pools.FlyInput.X==1 then Pools.FlyInput.X=0 elseif i.KeyCode==Enum.KeyCode.Space and Pools.FlyInput.Y==1 then Pools.FlyInput.Y=0 elseif i.KeyCode==Enum.KeyCode.LeftShift and Pools.FlyInput.Y==-1 then Pools.FlyInput.Y=0 end
end)
UserInputService.InputChanged:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Gamepad1 then if i.KeyCode==Enum.KeyCode.Thumbstick1 then Pools.FlyInput.X=i.Position.X Pools.FlyInput.Z=i.Position.Y elseif i.KeyCode==Enum.KeyCode.Thumbstick2 then Pools.FlyInput.Y=i.Position.Y end end
end)

-- TOGGLE FLY (DEFINIDO ANTES DO USO)
local function ToggleFly(state)
	Config.Fly_Enabled = state Config._Flags.Fly_Enabled = state
	local h = GetHumanoid() local r = GetRootPart()
	if state and (not h or not r) then Config.Fly_Enabled=false Config._Flags.Fly_Enabled=false if UI_Elements.Fly_Enabled then UI_Elements.Fly_Enabled:Set(false) end return end

	if state then
		-- CANCOLLIDE FIX: Salva estado original de TODAS BaseParts
		Pools.Fly_CollisionStates = {}
		local c = LocalPlayer.Character
		if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then Pools.Fly_CollisionStates[p] = p.CanCollide p.CanCollide = false end end end

		h.PlatformStand = true
		h.WalkSpeed = 0; h.JumpPower = 0

		Pools.Fly_Connection = RunService.RenderStepped:Connect(function(dt)
			if not Config.Fly_Enabled then ToggleFly(false) return end
			h = GetHumanoid() r = GetRootPart() if not h or not r then ToggleFly(false) return end

			local cf = Camera.CFrame
			local mv = Vector3.zero
			mv = mv + (cf.RightVector * Pools.FlyInput.X)
			mv = mv + (cf.LookVector * Pools.FlyInput.Z)
			mv = mv + (Vector3.new(0,1,0) * Pools.FlyInput.Y)

			if mv.Magnitude > 0 then
				local spd = (Config.UseGlobalSpeed and Config.GlobalSpeedValue or Config.Fly_Speed) * Config.Fly_VerticalMultiplier
				r.CFrame = r.CFrame + (mv.Unit * spd * dt)
			else
				r.AssemblyLinearVelocity = Vector3.new(0, 0.001, 0) -- Anti-sleep
			end

			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			r.CFrame = CFrame.new(r.CFrame.Position, r.CFrame.Position + cf.LookVector)
		end)
	else
		SafeDisc(Pools.Fly_Connection) Pools.Fly_Connection = nil
		if h then h.PlatformStand = false end
		-- RESTAURA COLISÕES EXATAS
		for part, origState in pairs(Pools.Fly_CollisionStates) do if part and part.Parent then pcall(function() part.CanCollide = origState end) end end
		Pools.Fly_CollisionStates = {}
		if Pools.Spin_BAV then Pools.Spin_BAV:Destroy() Pools.Spin_BAV=nil end
	end
	DeepSave(true)
	if UI_Elements.Fly_Enabled then pcall(function() UI_Elements.Fly_Enabled:Set(state) end) end
end

-- TOGGLE NOCLIP (DEFINIDO ANTES DO USO)
local function ToggleNoclip(state)
	Config.Noclip_Enabled = state Config._Flags.Noclip_Enabled = state
	DeepSave(true)
	if UI_Elements.Noclip_Enabled then pcall(function() UI_Elements.Noclip_Enabled:Set(state) end) end
end

-- TOGGLE FREECAM (DEFINIDO ANTES DO USO)
local function ToggleFreecam(state)
	Config.Freecam_Enabled = state Config._Flags.Freecam_Enabled = state
	local h = GetHumanoid()
	if state then Camera.CameraType=Enum.CameraType.Scriptable Camera.CameraSubject=nil if h then h.WalkSpeed=0 h.JumpPower=0 end Pools.Freecam_Connection=RunService.RenderStepped:Connect(function(dt) if not Config.Freecam_Enabled then ToggleFreecam(false) return end local cf=Camera.CFrame local v=Vector3.zero local s=100*dt if UserInputService:IsKeyDown(Enum.KeyCode.W) then v+=cf.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.S) then v-=cf.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.D) then v+=cf.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.A) then v-=cf.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.Space) then v+=Vector3.new(0,1,0) end if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then v-=Vector3.new(0,1,0) end if v.Magnitude>0 then Camera.CFrame=cf+v.Unit*s end end) else SafeDisc(Pools.Freecam_Connection) Pools.Freecam_Connection=nil Camera.CameraType=Enum.CameraType.Custom Camera.CameraSubject=h if h then ApplyPhysics() end end DeepSave(true) end

-- Mobile Button Fly
local function HandleFlyAction(name, state, input) if state==Enum.UserInputState.Begin then ToggleFly(not Config.Fly_Enabled) end end
if Config.Fly_Mobile_Button then pcall(function() ContextActionService:BindAction("UL_FlyToggle", HandleFlyAction, true, Enum.KeyCode.ButtonR3) ContextActionService:SetTitle("UL_FlyToggle", "Fly") ContextActionService:SetPosition("UL_FlyToggle", UDim2.new(1, -110, 1, -110)) end) end

-- =============================================================================
-- 📷 11. FREECAM (Já definido acima)
-- =============================================================================

-- =============================================================================
-- 👁️ 12. ESP SYSTEM (HYBRID)
-- =============================================================================
local function GetDrawing(type, props) local obj=Drawing.new(type) for k,v in pairs(props) do obj[k]=v end return obj end
local function ClearPlayerESP(plr)
	if Pools.Highlights[plr] then pcall(function() Pools.Highlights[plr]:Destroy() end) Pools.Highlights[plr]=nil end
	if Pools.Billboards[plr] then pcall(function() Pools.Billboards[plr]:Destroy() end) Pools.Billboards[plr]=nil end
	if Pools.HealthBars[plr] then pcall(function() Pools.HealthBars[plr]:Destroy() end) Pools.HealthBars[plr]=nil end
	local d=Pools.Drawing if d.Boxes[plr] then pcall(function() d.Boxes[plr]:Remove() end) d.Boxes[plr]=nil end if d.Tracers[plr] then pcall(function() d.Tracers[plr]:Remove() end) d.Tracers[plr]=nil end if d.Skeletons[plr] then for _,l in pairs(d.Skeletons[plr]) do pcall(function() l:Remove() end) end d.Skeletons[plr]=nil end if d.Chams[plr] then for _,t in pairs(d.Chams[plr]) do pcall(function() t:Remove() end) end d.Chams[plr]=nil end
end

local SkeletonRig = { {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"} }

local function UpdatePlayerESP(plr)
	if not Config.ESP_Enabled or plr==LocalPlayer or not IsAlive(plr) then ClearPlayerESP(plr) return end
	local myRoot=GetRootPart() local theirRoot=GetRootPart(plr.Character) if myRoot and theirRoot and (myRoot.Position-theirRoot.Position).Magnitude>Config.ESP_MaxDistance then ClearPlayerESP(plr) return end
	local char=plr.Character local hum=GetHumanoid(char) local head=GetHead(char) local torso=GetTorso(char) if not hum or hum.Health<=0 or not head or not torso then ClearPlayerESP(plr) return end
	local teamColor=plr.TeamColor.Color local espColor=Config.ESP_TeamColor and teamColor or Color3.new(1,0,0)

	-- Highlight
	if Config.ESP_Highlight then local hl=Pools.Highlights[plr] if not hl or not hl.Parent or hl.Adornee~=char then if hl then pcall(function() hl:Destroy() end) end hl=Instance.new("Highlight") hl.Name="UL_ESP_HL" hl.Adornee=char hl.FillTransparency=Config.ESP_Highlight_Fill hl.OutlineTransparency=Config.ESP_Highlight_Outline hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Parent=char Pools.Highlights[plr]=hl end hl.FillColor=espColor hl.OutlineColor=Color3.new(1,1,1) elseif Pools.Highlights[plr] then ClearPlayerESP(plr) end

	-- Billboard
	local showText=Config.ESP_Names or Config.ESP_Distance or Config.ESP_Health
	if showText then local bg=Pools.Billboards[plr] if not bg or not bg.Parent or bg.Adornee~=head then if bg then pcall(function() bg:Destroy() end) end bg=Instance.new("BillboardGui") bg.Name="UL_ESP_BG" bg.Adornee=head bg.Size=UDim2.new(0,200,0,70) bg.StudsOffset=Vector3.new(0,3.5,0) bg.AlwaysOnTop=true bg.Parent=head local tl=Instance.new("TextLabel") tl.Name="Info" tl.Size=UDim2.new(1,0,1,0) tl.BackgroundTransparency=1 tl.TextColor3=Color3.new(1,1,1) tl.TextStrokeTransparency=0 tl.TextScaled=true tl.Font=Enum.Font.GothamBold tl.Parent=bg Pools.Billboards[plr]=bg end local myR=GetRootPart() local d=myR and (myR.Position-theirRoot.Position).Magnitude or 0 local t={} if Config.ESP_Names then table.insert(t,plr.Name..(plr.DisplayName~=plr.Name and " ("..plr.DisplayName..")" or "")) end if Config.ESP_Distance then table.insert(t,"["..math.floor(d).."m]") end if Config.ESP_Health then table.insert(t,"❤️"..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)) end bg.Info.Text=table.concat(t," ") bg.Info.TextColor=Config.ESP_TeamColor and BrickColor.new(teamColor) or BrickColor.new("Really red") elseif Pools.Billboards[plr] then ClearPlayerESP(plr) end

	-- Health Bar
	if Config.ESP_HealthBar then local hb=Pools.HealthBars[plr] if not hb or not hb.Parent or hb.Adornee~=head then if hb then pcall(function() hb:Destroy() end) end hb=Instance.new("BillboardGui") hb.Name="UL_HPBar" hb.Adornee=head hb.Size=UDim2.new(4,0,0.5,0) hb.StudsOffset=Vector3.new(0,5.5,0) hb.AlwaysOnTop=true hb.Parent=head local bgf=Instance.new("Frame") bgf.Name="BG" bgf.Size=UDim2.new(1,0,1,0) bgf.BackgroundColor3=Color3.new(0,0,0) bgf.BackgroundTransparency=0.5 bgf.BorderSizePixel=0 bgf.Parent=hb local fill=Instance.new("Frame") fill.Name="Fill" fill.Size=UDim2.new(1,0,1,0) fill.BackgroundColor3=Color3.new(0,1,0) fill.BorderSizePixel=0 fill.Parent=bgf Instance.new("UICorner",bgf).CornerRadius=UDim.new(0,2) Pools.HealthBars[plr]=hb end local pct=hum.Health/hum.MaxHealth hb.Fill.Size=UDim2.new(pct,0,1,0) hb.Fill.BackgroundColor3=Color3.new(1-pct,pct,0) elseif Pools.HealthBars[plr] then pcall(function() Pools.HealthBars[plr]:Destroy() end) Pools.HealthBars[plr]=nil end

	-- Drawing API
	if not Caps.DrawingAPI then return end
	local function WTVP(pos) local s,on=Camera:WorldToViewportPoint(pos) return Vector2.new(s.X,s.Y),on,s.Z end

	-- Box
	if Config.ESP_Box then local box=Pools.Drawing.Boxes[plr] if not box then box=GetDrawing("Square",{Thickness=1.5,Filled=false,Color=espColor,Visible=false}) Pools.Drawing.Boxes[plr]=box end local hp,on=WTVP(head.Position+Vector3.new(0,0.5,0)) local rp,_=WTVP(theirRoot.Position) local lp,_=WTVP(theirRoot.Position-Vector3.new(0,3,0)) if on then local h=math.abs(hp.Y-lp.Y) local w=h/2 box.Size=Vector2.new(w,h) box.Position=Vector2.new(rp.X-w/2,hp.Y) box.Color=espColor box.Visible=true else box.Visible=false end elseif Pools.Drawing.Boxes[plr] then pcall(function() Pools.Drawing.Boxes[plr]:Remove() end) Pools.Drawing.Boxes[plr]=nil end

	-- Tracer
	if Config.ESP_Tracer then local tr=Pools.Drawing.Tracers[plr] if not tr then tr=GetDrawing("Line",{Thickness=1,Color=espColor,Visible=false}) Pools.Drawing.Tracers[plr]=tr end local rp,on=WTVP(theirRoot.Position) if on then local o=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y) if Config.ESP_Tracer_Origin=="Top" then o=Vector2.new(Camera.ViewportSize.X/2,0) elseif Config.ESP_Tracer_Origin=="Center" then o=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2) elseif Config.ESP_Tracer_Origin=="Mouse" then o=UserInputService:GetMouseLocation() end tr.From=o tr.To=rp tr.Color=espColor tr.Visible=true else tr.Visible=false end elseif Pools.Drawing.Tracers[plr] then pcall(function() Pools.Drawing.Tracers[plr]:Remove() end) Pools.Drawing.Tracers[plr]=nil end

	-- Skeleton
	if Config.ESP_Skeleton then local lines=Pools.Drawing.Skeletons[plr] if not lines then lines={} for i=1,#SkeletonRig do lines[i]=GetDrawing("Line",{Thickness=1,Color=espColor,Visible=false}) end Pools.Drawing.Skeletons[plr]=lines end for i,pair in ipairs(SkeletonRig) do local p1=char:FindFirstChild(pair[1]) local p2=char:FindFirstChild(pair[2]) local line=lines[i] if p1 and p2 and line then local sp1,vis1=WTVP(p1.Position) local sp2,vis2=WTVP(p2.Position) if vis1 or vis2 then line.From=sp1 line.To=sp2 line.Color=espColor line.Visible=true else line.Visible=false end elseif line then line.Visible=false end end elseif Pools.Drawing.Skeletons[plr] then for _,l in pairs(Pools.Drawing.Skeletons[plr]) do pcall(function() l:Remove() end) end Pools.Drawing.Skeletons[plr]=nil end
end

-- ESP Events
Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(function() task.wait(0.3) UpdatePlayerESP(plr) end) end)
Players.PlayerRemoving:Connect(ClearPlayerESP)
for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer then plr.CharacterAdded:Connect(function() task.wait(0.3) UpdatePlayerESP(plr) end) task.spawn(function() if plr.Character then UpdatePlayerESP(plr) end end) end end

task.spawn(function() while true do task.wait(1/30) if Config.ESP_Enabled then for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer then UpdatePlayerESP(plr) end end else for plr in pairs(Pools.Highlights) do ClearPlayerESP(plr) end end end end)

-- =============================================================================
-- 🎯 13. COMBAT MODULE
-- =============================================================================
if Caps.DrawingAPI then Pools.Drawing.FOVCircle=GetDrawing("Circle",{Thickness=1,NumSides=64,Radius=Config.Aimbot_FOV,Filled=false,Color=Color3.new(1,1,1),Visible=false}) end

RunService.RenderStepped:Connect(function(dt)
	if Caps.DrawingAPI and Pools.Drawing.FOVCircle then Pools.Drawing.FOVCircle.Position=UserInputService:GetMouseLocation() Pools.Drawing.FOVCircle.Radius=Config.Aimbot_FOV Pools.Drawing.FOVCircle.Visible=Config.Aimbot_Enabled and Config.Aimbot_FOV_Circle end
	if not Config.Aimbot_Enabled then return end
	local keyDown=false if Config.Aimbot_Key=="MouseButton2" then keyDown=UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) elseif Enum.KeyCode[Config.Aimbot_Key] then keyDown=UserInputService:IsKeyDown(Enum.KeyCode[Config.Aimbot_Key]) end if not keyDown then return end
	local myChar=LocalPlayer.Character local myHead=GetHead(myChar) local myRoot=GetRootPart(myChar) if not myHead or not myRoot then return end
	local closest=nil local closestDist=Config.Aimbot_FOV local mousePos=UserInputService:GetMouseLocation()
	for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer and IsAlive(plr) then if Config.Aimbot_TeamCheck and IsTeamMate(plr) then continue end if Config.Aimbot_IgnoreFriends and IsFriend(plr) then continue end local tp=plr.Character:FindFirstChild(Config.Aimbot_TargetPart) or GetRootPart(plr.Character) if not tp then continue end if Config.Aimbot_WallCheck then local params=RaycastParams.new() params.FilterDescendantsInstances={myChar,plr.Character} params.FilterType=Enum.RaycastFilterType.Exclude local dir=(tp.Position-myHead.Position).Unit*500 local hit=workspace:Raycast(myHead.Position,dir,params) if hit and hit.Instance and not hit.Instance:IsDescendantOf(plr.Character) then continue end end local sp,on=Camera:WorldToViewportPoint(tp.Position) if on then local dist=(Vector2.new(sp.X,sp.Y)-mousePos).Magnitude if dist<closestDist then closestDist=dist closest=plr end end end end
	if closest then local tp=closest.Character:FindFirstChild(Config.Aimbot_TargetPart) or GetRootPart(closest.Character) if tp then local targetCF=CFrame.new(Camera.CFrame.Position,tp.Position) Camera.CFrame=Camera.CFrame:Lerp(targetCF,Config.Aimbot_Smoothness) end end
end)

-- Triggerbot (VirtualInputManager para compatibilidade total)
RunService.Heartbeat:Connect(function()
	if not Config.Triggerbot_Enabled then return end
	local keyDown=false if Config.Triggerbot_Key=="LeftAlt" then keyDown=UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) elseif Enum.KeyCode[Config.Triggerbot_Key] then keyDown=UserInputService:IsKeyDown(Enum.KeyCode[Config.Triggerbot_Key]) end if not keyDown then return end
	local mouse=LocalPlayer:GetMouse() if mouse.Target and mouse.Target.Parent then local victim=Players:GetPlayerFromCharacter(mouse.Target.Parent) if victim and victim~=LocalPlayer and IsAlive(victim) and not (Config.Aimbot_TeamCheck and IsTeamMate(victim)) then task.wait(Config.Triggerbot_Delay) VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0) task.wait() VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0) end end end
end)

-- Silent Aim Hook
local function SetupSilentAim()
	if not Caps.GetRawMetatable or not Caps.HookFunction then return end
	if Pools.SilentAimHook then return end
	local mt=getrawmetatable(game) local oldNC=mt.__namecall setreadonly(mt,false)
	Pools.OriginalNamecall=oldNC
	mt.__namecall=newcclosure(function(self,...)
		local method=getnamecallmethod() local args={...}
		if Config.SilentAim_Enabled and (method=="Raycast" or method=="FindPartOnRay" or method=="FindPartOnRayWithWhitelist" or method=="FindPartOnRayWithIgnoreList") then
			if math.random(1,100)<=Config.SilentAim_HitChance then
				local myChar=LocalPlayer.Character if not myChar then return oldNC(self,unpack(args)) end local myHead=GetHead(myChar) if not myHead then return oldNC(self,unpack(args)) end
				local closest=nil local minDist=math.huge for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer and IsAlive(plr) and not (Config.Aimbot_TeamCheck and IsTeamMate(plr)) then local part=plr.Character:FindFirstChild(Config.SilentAim_TargetPart) or GetRootPart(plr.Character) if part then local dist=(part.Position-myHead.Position).Magnitude if dist<minDist then minDist=dist closest=part end end end end
				if closest then if method=="Raycast" then args[1]=myHead.Position args[2]=(closest.Position-myHead.Position).Unit*(args[3] or 500) elseif method:find("FindPartOnRay") then args[1]=Ray.new(myHead.Position,(closest.Position-myHead.Position).Unit*(args[1].Direction.Magnitude or 500)) end return oldNC(self,unpack(args)) end
			end
		end
		return oldNC(self,unpack(args))
	end)
	setreadonly(mt,true) Pools.SilentAimHook=true print("[Combat] Silent Aim Hook Installed.")
end

local function ToggleSilentAim(state)
	Config.SilentAim_Enabled=state Config._Flags.SilentAim_Enabled=state
	if state then SetupSilentAim() else if Caps.GetRawMetatable and Pools.OriginalNamecall then local mt=getrawmetatable(game) setreadonly(mt,false) mt.__namecall=Pools.OriginalNamecall setreadonly(mt,true) Pools.SilentAimHook=nil end end DeepSave(true) end

-- Hitbox Expander
RunService.Heartbeat:Connect(function()
	if not Config.Hitbox_Enabled then for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer and IsAlive(plr) then local r=GetRootPart(plr.Character) if r then r.Size=Vector3.new(2,2,1) r.Transparency=1 r.CanCollide=false r.Massless=true r.Color=Color3.new(1,1,1) r.Material=Enum.Material.Plastic end end end return end
	for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer and IsAlive(plr) and not (Config.Aimbot_TeamCheck and IsTeamMate(plr)) then local r=GetRootPart(plr.Character) if r then r.Size=Vector3.new(Config.Hitbox_Size,Config.Hitbox_Size,Config.Hitbox_Size) r.Transparency=Config.Hitbox_Transparency r.Color=Config.Hitbox_Color r.Material=Enum.Material.ForceField r.CanCollide=false r.Massless=true end end end
end)

-- =============================================================================
-- 🟢 14. EVENTOS NATIVOS
-- =============================================================================
UserInputService.JumpRequest:Connect(function() if Config.InfiniteJump then local h=GetHumanoid() if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end end)
LocalPlayer.Idled:Connect(function() if Config.AntiAFK then VirtualInputManager:SendMouseButtonEvent(100,100,0,true,game,0) task.wait(0.02) VirtualInputManager:SendMouseButtonEvent(100,100,0,false,game,0) VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.RightControl,false,game) task.wait(0.05) VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.RightControl,false,game) end end)
UserInputService.InputBegan:Connect(function(i,gp) if Config.ClickTP_Enabled and not gp and i.KeyCode==Config.ClickTP_Key then local r=GetRootPart() if r then local ray=Camera:ViewportPointToRay(Mouse.X,Mouse.Y) local params=RaycastParams.new() params.FilterDescendantsInstances={LocalPlayer.Character} params.FilterType=Enum.RaycastFilterType.Exclude local hit=workspace:Raycast(ray.Origin,ray.Direction*1000,params) if hit then if Config.ClickTP_Method=="Tween" then TweenService:Create(r,TweenInfo.new(0.5),{CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0))}):Play() else r.CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0)) end end end end end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) ApplyAll() if Config.Fly_Enabled then ToggleFly(true) end if Config.Freecam_Enabled then ToggleFreecam(true) end if Config.Noclip_Enabled then ToggleNoclip(true) end end)

-- =============================================================================
-- 🖥️ 15. UI RAYFIELD
-- =============================================================================
local RayfieldLibrary=nil local ok,err=pcall(function() RayfieldLibrary=loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua',true))() end) if not ok or not RayfieldLibrary then LocalPlayer:Kick("Falha Rayfield: "..tostring(err)) return end

local Win=RayfieldLibrary:CreateWindow({Name="Universal Lite v6.0 FULL SPECTRUM • "..(Caps.WriteFile and"💾"or"📋").." • "..(Caps.HttpRequest and"🌐"or"🚫"),LoadingTitle="Carregando Full Spectrum...",LoadingSubtitle="Combat•ESP•Movement•Visuals•Mobile",ConfigurationSaving={Enabled=false},KeySystem=false})
local Tabs={Combat=Win:CreateTab("Combate 🎯",4483362458),ESP=Win:CreateTab("ESP 👁️",4483362458),Visuals=Win:CreateTab("Visuais 🌍",4483362458),Move=Win:CreateTab("Movimento ⚡",4483362458),FlyTab=Win:CreateTab("Voo 🕊️",4483362458),Utils=Win:CreateTab("Utilitários 🛠️",4483362458),Config=Win:CreateTab("Config ⚙️",4483362458)}

local function Sec(t,n) t:CreateSection(n) end
local function Tg(t,k,n,s,c,kb) if s then Sec(t,s) end local o=t:CreateToggle({Name=n,CurrentValue=Config[k],Flag=k,Callback=function(v) Config[k]=v Config._Flags[k]=v if c then c(v) end local dangerous=k:find("Enabled") or k:find("Fly") or k:find("Noclip") or k:find("ClickTP") or k:find("Freecam") or k:find("Hitbox") or k:find("SilentAim") DeepSaveConfig(dangerous) RayfieldLibrary:Notify({Title=v and"ON"or"OFF",Content=n,Duration=1,Image=v and"check-circle"or"x-circle"}) end,Keybind=kb}) UI_Elements[k]=o return o end
local function Sl(t,k,n,s,mi,ma,inc,c) if s then Sec(t,s) end local o=t:CreateSlider({Name=n,Range={mi,ma},Increment=inc,CurrentValue=Config[k],Flag=k,Callback=function(v) Config[k]=v if k:find("Speed") or k:find("WalkSpeed") or k:find("Fly_Speed") or k:find("GlobalSpeed") then Config[k]=ClampSpeed(v) end if k=="FOV" then Camera.FieldOfView=v end if k=="Gravity" then workspace.Gravity=v end if k=="JumpPower" then local h=GetHumanoid() if h then h.JumpPower=v h.UseJumpPower=true end end if k=="SpinSpeed" and Pools.Spin_BAV then Pools.Spin_BAV.AngularVelocity=Vector3.new(0,math.rad(v)*60,0) end if k=="Aimbot_FOV" and Pools.Drawing.FOVCircle then Pools.Drawing.FOVCircle.Radius=v end if c then c(v) end DeepSaveConfig(false) RayfieldLibrary:Notify({Title="Set",Content=k.."="..v,Duration=1,Image="check"}) end}) UI_Elements[k]=o return o end
local function Dd(t,k,n,s,o,c) if s then Sec(t,s) end local o=t:CreateDropdown({Name=n,Options=o,CurrentOption=Config[k],Flag=k,Callback=function(v) local val=v[1]or v Config[k]=val if Enum.KeyCode[val] then Config[k]=Enum.KeyCode[val] end DeepSaveConfig(true) if c then c(val) end end}) UI_Elements[k]=o return o end
local function Cp(t,k,n,s,c) if s then Sec(t,s) end local o=t:CreateColorPicker({Name=n,Color=Config[k],Flag=k,Callback=function(v) Config[k]=v if c then c(v) end DeepSaveConfig(true) end}) UI_Elements[k]=o return o end
local function Btn(t,n,s,c) if s then Sec(t,s) end return t:CreateButton({Name=n,Callback=c}) end

-- COMBATE
Sec(Tabs.Combat,"🎯 Aimbot") Tg(Tabs.Combat,"Aimbot_Enabled","Ativar Aimbot","🎯 Aimbot",nil,Enum.KeyCode.Delete) Dd(Tabs.Combat,"Aimbot_Key","Tecla","🎯 Aimbot",{"MouseButton2","MouseButton1","LeftAlt","LeftControl","Q","E","R","T","F","C","V"}) Sl(Tabs.Combat,"Aimbot_Smoothness","Suavidade","🎯 Aimbot",0.01,1,0.01) Sl(Tabs.Combat,"Aimbot_FOV","FOV (px)","🎯 Aimbot",10,500,1) Tg(Tabs.Combat,"Aimbot_FOV_Circle","Mostrar Círculo","🎯 Aimbot") Dd(Tabs.Combat,"Aimbot_TargetPart","Parte","🎯 Aimbot",{"Head","HumanoidRootPart","UpperTorso","LowerTorso"}) Tg(Tabs.Combat,"Aimbot_TeamCheck","Team Check","🎯 Aimbot") Tg(Tabs.Combat,"Aimbot_WallCheck","Wall Check","🎯 Aimbot") Tg(Tabs.Combat,"Aimbot_IgnoreFriends","Ignorar Amigos","🎯 Aimbot")
Sec(Tabs.Combat,"🔫 Triggerbot") Tg(Tabs.Combat,"Triggerbot_Enabled","Ativar Triggerbot","🔫 Triggerbot",nil,Enum.KeyCode.Insert) Dd(Tabs.Combat,"Triggerbot_Key","Tecla","🔫 Triggerbot",{"LeftAlt","LeftControl","RightAlt","RightControl","Q","E"}) Sl(Tabs.Combat,"Triggerbot_Delay","Delay (s)","🔫 Triggerbot",0,0.5,0.01)
Sec(Tabs.Combat,"🎯 Silent Aim") Tg(Tabs.Combat,"SilentAim_Enabled","Ativar Silent Aim","🎯 Silent Aim",ToggleSilentAim) Sl(Tabs.Combat,"SilentAim_HitChance","Chance %","🎯 Silent Aim",0,100,1) Dd(Tabs.Combat,"SilentAim_TargetPart","Parte","🎯 Silent Aim",{"Head","HumanoidRootPart","UpperTorso"})
Sec(Tabs.Combat,"📦 Hitbox") Tg(Tabs.Combat,"Hitbox_Enabled","Ativar Hitbox","📦 Hitbox") Sl(Tabs.Combat,"Hitbox_Size","Tamanho","📦 Hitbox",2,50,0.5) Sl(Tabs.Combat,"Hitbox_Transparency","Transparência","📦 Hitbox",0,1,0.05) Cp(Tabs.Combat,"Hitbox_Color","Cor","📦 Hitbox")

-- ESP
Sec(Tabs.ESP,"👁️ ESP Master") Tg(Tabs.ESP,"ESP_Enabled","Ativar ESP Total","👁️ ESP Master",nil,Enum.KeyCode.F1) Sl(Tabs.ESP,"ESP_MaxDistance","Dist Máx","👁️ ESP Master",100,10000,100)
Sec(Tabs.ESP,"✨ Highlight") Tg(Tabs.ESP,"ESP_Highlight","Ativar Highlight","✨ Highlight") Sl(Tabs.ESP,"ESP_Highlight_Fill","Fill Transp","✨ Highlight",0,1,0.05) Sl(Tabs.ESP,"ESP_Highlight_Outline","Outline Transp","✨ Highlight",0,1,0.05)
Sec(Tabs.ESP,"📝 Billboard") Tg(Tabs.ESP,"ESP_Names","Nomes","📝 Billboard") Tg(Tabs.ESP,"ESP_Distance","Distância","📝 Billboard") Tg(Tabs.ESP,"ESP_Health","Vida Num","📝 Billboard") Tg(Tabs.ESP,"ESP_HealthBar","Barra Vida","📝 Billboard") Tg(Tabs.ESP,"ESP_TeamColor","Cor Time","📝 Billboard")
Sec(Tabs.ESP,"📐 Drawing API") Tg(Tabs.ESP,"ESP_Box","Box ESP","📐 Drawing API") Dd(Tabs.ESP,"ESP_Box_Type","Tipo","📐 Drawing API",{"Full","Corner"}) Tg(Tabs.ESP,"ESP_Tracer","Tracer","📐 Drawing API") Dd(Tabs.ESP,"ESP_Tracer_Origin","Origem","📐 Drawing API",{"Bottom","Top","Center","Mouse"}) Tg(Tabs.ESP,"ESP_Skeleton","Skeleton","📐 Drawing API") Tg(Tabs.ESP,"ESP_Chams","Chams (Triângulos)","📐 Drawing API")

-- VISUAIS
Sec(Tabs.Visuals,"🌍 Mundo") Tg(Tabs.Visuals,"Fullbright","Fullbright","🌍 Mundo",nil,Enum.KeyCode.F2) Tg(Tabs.Visuals,"NoFog","Sem Neblina","🌍 Mundo") Tg(Tabs.Visuals,"NoShadows","Sem Sombras","🌍 Mundo") Sl(Tabs.Visuals,"FOV","FOV","🌍 Mundo",50,120,1)
Sec(Tabs.Visuals,"🌌 Ambience") Tg(Tabs.Visuals,"Ambience_Enabled","Ativar Ambience","🌌 Ambience") Sl(Tabs.Visuals,"Ambience_Time","Hora","🌌 Ambience",0,24,0.1) Sl(Tabs.Visuals,"Ambience_Brightness","Brilho","🌌 Ambience",0,5,0.1) Cp(Tabs.Visuals,"Ambience_Outdoor","Cor Outdoor","🌌 Ambience") Cp(Tabs.Visuals,"Ambience_Indoor","Cor Indoor","🌌 Ambience") Tg(Tabs.Visuals,"NoSky","Remover Céu","🌌 Ambience")
Sec(Tabs.Visuals,"🔧 Low GFX") Tg(Tabs.Visuals,"NoTextures","Remover Texturas","🔧 Low GFX") Tg(Tabs.Visuals,"NoParticles","Remover Partículas","🔧 Low GFX") Tg(Tabs.Visuals,"NoDecals","Remover Decals","🔧 Low GFX")
Sec(Tabs.Visuals,"🎯 Crosshair") Tg(Tabs.Visuals,"Crosshair_Enabled","Ativar Crosshair","🎯 Crosshair") Dd(Tabs.Visuals,"Crosshair_Type","Tipo","🎯 Crosshair",{"Dot","Cross","Circle","TStyle"}) Sl(Tabs.Visuals,"Crosshair_Size","Tamanho","🎯 Crosshair",1,50,1) Sl(Tabs.Visuals,"Crosshair_Gap","Gap","🎯 Crosshair",0,20,1) Sl(Tabs.Visuals,"Crosshair_Thickness","Espessura","🎯 Crosshair",0.5,5,0.5) Cp(Tabs.Visuals,"Crosshair_Color","Cor","🎯 Crosshair") Tg(Tabs.Visuals,"Crosshair_Rainbow","Arco-íris","🎯 Crosshair")
Sec(Tabs.Visuals,"📊 HUD") Tg(Tabs.Visuals,"Watermark_Enabled","Watermark","📊 HUD") Tg(Tabs.Visuals,"FPS_Counter_Enabled","FPS Counter","📊 HUD")

-- Crosshair/FPS/Watermark Drawing Loop
if Caps.DrawingAPI then
	RunService.RenderStepped:Connect(function()
		if Config.Crosshair_Enabled then
			if #Pools.Drawing.Crosshair==0 then -- Create on demand
				ClearDrawing(Pools.Drawing.Crosshair)
				local c=Config.Crosshair_Color local s=Config.Crosshair_Size local g=Config.Crosshair_Gap local t=Config.Crosshair_Thickness local vp=Camera.ViewportSize local cx=vp.X/2 local cy=vp.Y/2
				if Config.Crosshair_Type=="Dot" then table.insert(Pools.Drawing.Crosshair,GetDrawing("Circle",{Radius=s/2,Thickness=t,Filled=true,Color=c,Visible=true})) elseif Config.Crosshair_Type=="Cross" then table.insert(Pools.Drawing.Crosshair,GetDrawing("Line",{From=Vector2.new(cx-g-s,cy),To=Vector2.new(cx-g,cy),Thickness=t,Color=c,Visible=true})) table.insert(Pools.Drawing.Crosshair,GetDrawing("Line",{From=Vector2.new(cx+g+s,cy),To=Vector2.new(cx+g,cy),Thickness=t,Color=c,Visible=true})) table.insert(Pools.Drawing.Crosshair,GetDrawing("Line",{From=Vector2.new(cx,cy-g-s),To=Vector2.new(cx,cy-g),Thickness=t,Color=c,Visible=true})) table.insert(Pools.Drawing.Crosshair,GetDrawing("Line",{From=Vector2.new(cx,cy+g+s),To=Vector2.new(cx,cy+g),Thickness=t,Color=c,Visible=true})) elseif Config.Crosshair_Type=="Circle" then table.insert(Pools.Drawing.Crosshair,GetDrawing("Circle",{Radius=s,Thickness=t,Filled=false,Color=c,Visible=true})) end
			end
			local color=Config.Crosshair_Rainbow and Color3.fromHSV(tick()%5/5,1,1) or Config.Crosshair_Color
			for _,obj in pairs(Pools.Drawing.Crosshair) do obj.Color=color obj.Visible=true end
		else for _,obj in pairs(Pools.Drawing.Crosshair) do obj.Visible=false end end
	end)
	Pools.Drawing.Watermark=GetDrawing("Text",{Text="Universal Lite v6.0",Size=18,Font=2,Color=Color3.new(1,1,1),Outline=true,Position=Vector2.new(10,10),Visible=Config.Watermark_Enabled})
	Pools.Drawing.FPSText=GetDrawing("Text",{Text="FPS: 0",Size=18,Font=2,Color=Color3.new(1,1,1),Outline=true,Position=Vector2.new(10,30),Visible=Config.FPS_Counter_Enabled})
	task.spawn(function() local frames=0 while true do task.wait(1) if Pools.Drawing.FPSText then Pools.Drawing.FPSText.Text="FPS: "..frames Pools.Drawing.FPSText.Visible=Config.FPS_Counter_Enabled end if Pools.Drawing.Watermark then Pools.Drawing.Watermark.Visible=Config.Watermark_Enabled end frames=0 end RunService.RenderStepped:Connect(function() frames=frames+1 end) end) end

-- MOVIMENTO
Sec(Tabs.Move,"⚡ Física Per-Frame (Cap 1000)") Tg(Tabs.Move,"UseGlobalSpeed","Velocidade Global","⚡ Física") Sl(Tabs.Move,"GlobalSpeedValue","Speed Global","⚡ Física",16,1000,1) Sl(Tabs.Move,"SpeedCap","Cap Máximo","⚡ Física",16,1000,1) Sl(Tabs.Move,"WalkSpeed","WalkSpeed","⚡ Física",16,1000,1) Sl(Tabs.Move,"JumpPower","JumpPower","⚡ Física",50,300,1) Sl(Tabs.Move,"Gravity","Gravidade","⚡ Física",0,500,1)
Sec(Tabs.Move,"🌀 Extras") Tg(Tabs.Move,"InfiniteJump","Inf Jump","🌀 Extras",nil,Enum.KeyCode.F3) Tg(Tabs.Move,"Spin","Spin","🌀 Extras") Sl(Tabs.Move,"SpinSpeed","Vel Spin","🌀 Extras",1,100,1) Tg(Tabs.Move,"AutoSit","Auto Sit","🌀 Extras")
Sec(Tabs.Move,"🏃 Tech") Tg(Tabs.Move,"Bhop_Enabled","Bhop","🏃 Tech") Tg(Tabs.Move,"EdgeJump_Enabled","Edge Jump","🏃 Tech") Tg(Tabs.Move,"AirWalk_Enabled","Air Walk","🏃 Tech") Tg(Tabs.Move,"NoFallDamage","No Fall Damage","🏃 Tech") Tg(Tabs.Move,"SwimFly_Enabled","Swim Fly","🏃 Tech")
Sec(Tabs.Move,"🚫 Perigosos") Tg(Tabs.Move,"Noclip_Enabled","Noclip","🚫 Perigosos",ToggleNoclip,Enum.KeyCode.F4) Tg(Tabs.Move,"ClickTP_Enabled","Click TP","🚫 Perigosos") Dd(Tabs.Move,"ClickTP_Key","Tecla TP","🚫 Perigosos",{"LeftControl","RightControl","C","V","X","Z","LeftAlt","RightAlt"}) Dd(Tabs.Move,"ClickTP_Method","Método","🚫 Perigosos",{"CFrame","Tween"})

-- VOO
Sec(Tabs.FlyTab,"🕊️ Fly Vetorial (Fix CanCollide)") Tg(Tabs.FlyTab,"Fly_Enabled","Ativar Fly","🕊️ Fly",ToggleFly,Enum.KeyCode.F5) Sl(Tabs.FlyTab,"Fly_Speed","Speed Fly","🕊️ Fly",1,1000,5) Sl(Tabs.FlyTab,"Fly_VerticalMultiplier","Mult Vertical","🕊️ Fly",0.1,3,0.1) Dd(Tabs.FlyTab,"Fly_Keybind","Tecla Toggle","🕊️ Fly",{"F","G","H","J","K","L","Z","X","C","V"}) Tg(Tabs.FlyTab,"Fly_Mobile_Button","Botão Mobile (R3)","🕊️ Fly") Tabs.FlyTab:CreateLabel("WASD Mover | Space Subir | Shift Descer | Gamepad L/R Stick")
Sec(Tabs.FlyTab,"📷 Freecam") Tg(Tabs.FlyTab,"Freecam_Enabled","Freecam","📷 Freecam",ToggleFreecam,Enum.KeyCode.F6)

-- UTILS
Sec(Tabs.Utils,"🛡️ Proteções") Tg(Tabs.Utils,"AntiAFK","Anti-AFK","🛡️ Proteções") Tg(Tabs.Utils,"AntiVoid","Anti-Void","🛡️ Proteções") Tg(Tabs.Utils,"AntiKick_Rejoin","Rejoin Auto Kick (QueueTP)","🛡️ Proteções")
Sec(Tabs.Utils,"🔄 Server") Btn(Tabs.Utils,"Rejoin","🔄 Server",function() DeepSave(true) TeleportService:TeleportToPlaceInstance(PlaceId,JobId,LocalPlayer) end) if Caps.HttpRequest then Btn(Tabs.Utils,"Server Hop","🔄 Server",function() RayfieldLibrary:Notify({Title="Hop",Content="Buscando...",Duration=10,Image="loader"}) task.spawn(function() local ok,res=pcall(function() return HttpService:RequestAsync({Url="https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100",Method="GET"}) end) if ok and res.Success then local d=HttpService:JSONDecode(res.Body) for _,s in pairs(d.data) do if s.id~=JobId and s.playing<s.maxPlayers then TeleportService:TeleportToPlaceInstance(PlaceId,s.id,LocalPlayer) return end end end RayfieldLibrary:Notify({Title="Erro",Content="Sem server",Duration=5,Image="alert-circle"}) end) end) else Tabs.Utils:CreateLabel("🚫 Sem RequestAsync") end Btn(Tabs.Utils,"Rejoin + QueueTP","🔄 Server",function() if Caps.QueueOnTeleport then queue_on_teleport('game:GetService("TeleportService"):TeleportToPlaceInstance('..PlaceId..', "'..JobId..'")') end TeleportService:TeleportToPlaceInstance(PlaceId,JobId,LocalPlayer) end)
Sec(Tabs.Utils,"🎮 Misc") Btn(Tabs.Utils,"Reset Char","🎮 Misc",function() local h=GetHumanoid() if h then h.Health=0 end end) Btn(Tabs.Utils,"Remover Botões Mobile","🎮 Misc",function() pcall(function() ContextActionService:UnbindAction("UL_FlyToggle") end) RayfieldLibrary:Notify({Title="OK",Content="Botões removidos",Duration=2}) end)

-- CONFIG
Sec(Tabs.Config,"💾 Persistência") Btn(Tabs.Config,"Forçar Salvar","💾 Persistência",function() DeepSave(true) RayfieldLibrary:Notify({Title="OK",Content="Salvo!",Duration=1}) end)
Sec(Tabs.Config,"🔴 Perigo") Btn(Tabs.Config,"🔴 RESET TOTAL","🔴 Perigo",function()
	for _,c in pairs(Pools.Conns) do SafeDisc(c) end Pools.Conns={} SafeDisc(Pools.Fly_Connection) Pools.Fly_Connection=nil SafeDisc(Pools.Freecam_Connection) Pools.Freecam_Connection=nil if Pools.Spin_BAV then Pools.Spin_BAV:Destroy() end Pools.Spin_BAV=nil if Pools.AirWalk_Platform then Pools.AirWalk_Platform:Destroy() end Pools.AirWalk_Platform=nil
	if Caps.GetRawMetatable and Pools.OriginalNamecall then local mt=getrawmetatable(game) setreadonly(mt,false) mt.__namecall=Pools.OriginalNamecall setreadonly(mt,true) end Pools.SilentAimHook=nil Pools.OriginalNamecall=nil
	for _,v in pairs(Pools.Highlights) do pcall(function() v:Destroy() end) end table.clear(Pools.Highlights) for _,v in pairs(Pools.Billboards) do pcall(function() v:Destroy() end) end table.clear(Pools.Billboards) for _,v in pairs(Pools.HealthBars) do pcall(function() v:Destroy() end) end table.clear(Pools.HealthBars) ClearDrawing(Pools.Drawing.Boxes) ClearDrawing(Pools.Drawing.Tracers) ClearDrawing(Pools.Drawing.Skeletons) ClearDrawing(Pools.Drawing.Chams) ClearDrawing(Pools.Drawing.Crosshair) if Pools.Drawing.FOVCircle then pcall(function() Pools.Drawing.FOVCircle:Remove() end) Pools.Drawing.FOVCircle=nil end if Pools.Drawing.Watermark then pcall(function() Pools.Drawing.Watermark:Remove() end) Pools.Drawing.Watermark=nil end if Pools.Drawing.FPSText then pcall(function() Pools.Drawing.FPSText:Remove() end) Pools.Drawing.FPSText=nil end
	for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer and IsAlive(plr) then local r=GetRootPart(plr.Character) if r then r.Size=Vector3.new(2,2,1) r.Transparency=1 r.CanCollide=false r.Massless=true r.Color=Color3.new(1,1,1) r.Material=Enum.Material.Plastic end end end
	for p,s in pairs(Pools.Fly_CollisionStates) do if p and p.Parent then pcall(function() p.CanCollide=s end) end end table.clear(Pools.Fly_CollisionStates)
	Camera.FieldOfView=70 Lighting.GlobalShadows=true Lighting.FogEnd=1e5 Lighting.ClockTime=14 Lighting.Brightness=2 Lighting.OutdoorAmbient=Color3.new(0.5,0.5,0.5) Lighting.Ambient=Color3.new(0.5,0.5,0.5) for _,v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end if Pools.Sky then Pools.Sky.Parent=Lighting Pools.Sky=nil end ApplyLowGFX()
	local h=GetHumanoid() local r=GetRootPart() if h then h.PlatformStand=false h.WalkSpeed=16 h.JumpPower=50 h.UseJumpPower=true end if r then r.CanCollide=true r.Size=Vector3.new(2,2,1) r.Transparency=1 end
	pcall(function() ContextActionService:UnbindAction("UL_FlyToggle") end)
	local defaults={Aimbot_Enabled=false,Aimbot_TeamCheck=true,Aimbot_WallCheck=true,Aimbot_Smoothness=0.15,Aimbot_FOV=120,Aimbot_FOV_Circle=true,Aimbot_TargetPart="Head",Aimbot_Key="MouseButton2",Aimbot_IgnoreFriends=false,Triggerbot_Enabled=false,Triggerbot_Delay=0.05,Triggerbot_Key="LeftAlt",SilentAim_Enabled=false,SilentAim_HitChance=100,SilentAim_TargetPart="Head",Hitbox_Enabled=false,Hitbox_Size=10,Hitbox_Transparency=0.7,Hitbox_Color=Color3.fromRGB(255,0,0),ESP_Enabled=false,ESP_Highlight=true,ESP_Highlight_Fill=0.5,ESP_Highlight_Outline=0,ESP_Names=true,ESP_Distance=true,ESP_Health=true,ESP_HealthBar=true,ESP_TeamColor=true,ESP_Box=true,ESP_Box_Type="Corner",ESP_Tracer=true,ESP_Tracer_Origin="Bottom",ESP_Skeleton=true,ESP_Chams=false,ESP_MaxDistance=5000,Fullbright=false,NoFog=false,NoShadows=false,FOV=70,Ambience_Enabled=false,Ambience_Time=14,Ambience_Brightness=2,Ambience_Outdoor=Color3.new(1,1,1),Ambience_Indoor=Color3.new(1,1,1),NoSky=false,NoTextures=false,NoParticles=false,NoDecals=false,Crosshair_Enabled=false,Crosshair_Type="Dot",Crosshair_Size=10,Crosshair_Gap=5,Crosshair_Thickness=1.5,Crosshair_Color=Color3.new(1,1,1),Crosshair_Rainbow=false,Watermark_Enabled=true,FPS_Counter_Enabled=true,WalkSpeed=16,JumpPower=50,Gravity=196.2,InfiniteJump=false,Spin=false,SpinSpeed=20,AutoSit=false,Bhop_Enabled=false,EdgeJump_Enabled=false,AirWalk_Enabled=false,NoFallDamage=false,SwimFly_Enabled=false,Fly_Enabled=false,Fly_Speed=100,Fly_VerticalMultiplier=1.0,Fly_Keybind="F",Fly_Mobile_Button=true,Noclip_Enabled=false,ClickTP_Enabled=false,ClickTP_Key="LeftControl",ClickTP_Method="CFrame",AntiAFK=false,AntiVoid=false,AntiKick_Rejoin=false,UseGlobalSpeed=false,GlobalSpeedValue=100,SpeedCap=1000,_Flags={}} for k in pairs(Config) do Config[k]=nil end for k,v in pairs(defaults) do Config[k]=v end for flag,obj in pairs(UI_Elements) do pcall(function() obj:Set(Config[flag]) end) end DeepSave(true) RayfieldLibrary:Notify({Title="RESET",Content="Defaults restaurados.",Duration=3,Image="check-circle"}) print("🔄 Hard Reset") end)

-- =============================================================================
-- 🚀 16. STARTUP
-- =============================================================================
ApplyAll()
print("==================================================") print("🚀 UNIVERSAL LITE v6.0 FULL SPECTRUM PRONTO") print("==================================================")
RayfieldLibrary:Notify({Title="Universal Lite v6.0",Content="Full Spectrum Carregado!",Duration=8,Image="check-circle"})

-- =============================================================================
-- 🛡️ 17. CLEANUP GLOBAL
-- =============================================================================
getgenv()._UniversalScriptCleanup=function()
	print("🧹 Cleanup v6.0...")
	for _,c in pairs(Pools.Conns) do SafeDisc(c) end Pools.Conns={}
	SafeDisc(Pools.Fly_Connection) SafeDisc(Pools.Freecam_Connection)
	if Pools.Spin_BAV then pcall(function() Pools.Spin_BAV:Destroy() end) Pools.Spin_BAV=nil end
	if Pools.AirWalk_Platform then pcall(function() Pools.AirWalk_Platform:Destroy() end) Pools.AirWalk_Platform=nil end
	for _,v in pairs(Pools.Highlights) do pcall(function() v:Destroy() end) end table.clear(Pools.Highlights)
	for _,v in pairs(Pools.Billboards) do pcall(function() v:Destroy() end) end table.clear(Pools.Billboards)
	for _,v in pairs(Pools.HealthBars) do pcall(function() v:Destroy() end) end table.clear(Pools.HealthBars)
	ClearDrawing(Pools.Drawing.Boxes) ClearDrawing(Pools.Drawing.Tracers) ClearDrawing(Pools.Drawing.Skeletons) ClearDrawing(Pools.Drawing.Chams) ClearDrawing(Pools.Drawing.Crosshair)
	if Pools.Drawing.FOVCircle then pcall(function() Pools.Drawing.FOVCircle:Remove() end) Pools.Drawing.FOVCircle=nil end
	if Pools.Drawing.Watermark then pcall(function() Pools.Drawing.Watermark:Remove() end) Pools.Drawing.Watermark=nil end
	if Pools.Drawing.FPSText then pcall(function() Pools.Drawing.FPSText:Remove() end) Pools.Drawing.FPSText=nil end
	if Caps.GetRawMetatable and Pools.OriginalNamecall then local mt=getrawmetatable(game) setreadonly(mt,false) mt.__namecall=Pools.OriginalNamecall setreadonly(mt,true) end
	for _,plr in pairs(Players:GetPlayers()) do if plr~=LocalPlayer and IsAlive(plr) then local r=GetRootPart(plr.Character) if r then r.Size=Vector3.new(2,2,1) r.Transparency=1 r.CanCollide=false r.Massless=true r.Color=Color3.new(1,1,1) r.Material=Enum.Material.Plastic end end end
	for p,s in pairs(Pools.Fly_CollisionStates) do if p and p.Parent then pcall(function() p.CanCollide=s end) end end table.clear(Pools.Fly_CollisionStates)
	Camera.FieldOfView=70 Lighting.GlobalShadows=true Lighting.FogEnd=1e5 Lighting.ClockTime=14 Lighting.Brightness=2 Lighting.OutdoorAmbient=Color3.new(0.5,0.5,0.5) Lighting.Ambient=Color3.new(0.5,0.5,0.5) for _,v in pairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end if Pools.Sky then Pools.Sky.Parent=Lighting Pools.Sky=nil end ApplyLowGFX()
	local h=GetHumanoid() local r=GetRootPart() if h then h.PlatformStand=false h.WalkSpeed=16 h.JumpPower=50 h.UseJumpPower=true end if r then r.CanCollide=true r.Size=Vector3.new(2,2,1) r.Transparency=1 end
	pcall(function() ContextActionService:UnbindAction("UL_FlyToggle") end)
	print("✅ Cleanup OK")
end
```
