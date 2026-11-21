--[[
	UNIVERSAL HUB - PROJETO FINAL (v2.0 Refatorada)
	Autor: Seu Projeto
	Requisitos: Arquivo 'rayfield.lua' na pasta Workspace do Executor.
	Funcionalidades: Speed, Fly (Constraints), Noclip, ESP, FreeCam, ClickTP, AntiAFK, Config JSON.
]]

repeat task.wait() until game:IsLoaded()
task.wait(0.5)

--// SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// CARREGAR RAYFIELD LOCAL (SEGURO)
local Rayfield
local success, err = pcall(function()
	-- AJUSTE AQUI SE O ARQUIVO TIVER OUTRO NOME/LOCAL:
	Rayfield = require(workspace:WaitForChild("rayfield", 10))
end)

if not success or not Rayfield then
	return player:Kick("❌ ERRO CRÍTICO: Coloque 'rayfield.lua' na pasta Workspace do executor.\nErro: "..tostring(err))
end

--// CONFIG PADRÃO E ESTADO
local CONFIG_PATH = "UniversalHub_Config.json"
local DEFAULT_CONFIG = {
	WalkSpeed = 16, JumpPower = 50, Gravity = 1,
	InfiniteJump = false, Noclip = false, Spin = false, SpinSpeed = 10, Sit = false,
	Fly = false, FlySpeed = 50,
	ESP = false, Fullbright = false, NoFog = false, FOV = 70, FreeCam = false,
	AntiAFK = false, AntiLag = false, ClickTP = false,
	GlobalSpeedEnabled = false, GlobalSpeedValue = 1000, SpeedLimit = 1000,
	SelectedPlayer = "Nenhum"
}

local CONFIG = table.clone(DEFAULT_CONFIG)
local CONNECTIONS = {}
local INSTANCES = {}
local espHighlights = {}
local noclipParts = {}
local flyLV, flyAO, flyAttach
local fcEnabled = false

--// HELPERS
local function clamp(v, min, max) return math.clamp(v, min, max) end
local function getChar() return player.Character end
local function getHum() local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local function trackConn(c) table.insert(CONNECTIONS, c) return c end
local function trackInst(i) table.insert(INSTANCES, i) return i end

local function cleanupAll()
	for _,c in pairs(CONNECTIONS) do if c.Connected then c:Disconnect() end end table.clear(CONNECTIONS)
	for _,i in pairs(INSTANCES) do if i and i.Parent then i:Destroy() end end table.clear(INSTANCES)
	table.clear(espHighlights); table.clear(noclipParts)
	flyLV=nil; flyAO=nil; flyAttach=nil; fcEnabled=false
	local h=getHum(); local r=getRoot()
	if h then h.WalkSpeed=16; h.JumpPower=50; h.UseJumpPower=true; h.PlatformStand=false; h.Sit=false end
	if r then r.CanCollide=true end
	Lighting.GlobalShadows=true; Lighting.FogEnd=300; Lighting.Brightness=1; Lighting.ClockTime=14
	camera.FieldOfView=70; camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=h
end

--// PERSISTÊNCIA JSON
local function saveConfig()
	local data={} for k,v in pairs(CONFIG) do data[k]=v end
	local ok,err=pcall(function() writefile(CONFIG_PATH, HttpService:JSONEncode(data)) end)
	Rayfield:Notify(ok and "✅ Config Salva!" or "❌ Erro: "..err, 3, ok and "SUCCESS" or "ERROR")
end

local function loadConfig()
	local ok,cont=pcall(function() return isfile(CONFIG_PATH) and readfile(CONFIG_PATH) end)
	if ok and cont then
		local ok2,data=pcall(function() return HttpService:JSONDecode(cont) end)
		if ok2 and type(data)=="table" then
			for k,v in pairs(data) do
				if DEFAULT_CONFIG[k]~=nil and type(v)==type(DEFAULT_CONFIG[k]) then
					if type(v)=="number" then
						if k:find("Speed") or k:find("Power") or k:find("Limit") or k:find("Value") then CONFIG[k]=clamp(v,0,10000)
						elseif k=="Gravity" then CONFIG[k]=clamp(v,0.1,10)
						elseif k=="FOV" then CONFIG[k]=clamp(v,30,120)
						elseif k=="SpinSpeed" then CONFIG[k]=clamp(v,1,100)
						else CONFIG[k]=v end
					else CONFIG[k]=v end
				end
			end
			Rayfield:Notify("📂 Config Carregada!", 3, "SUCCESS")
		end
	end
end

--// MÓDULOS LÓGICOS
local function updateMovement()
	local h=getHum() if not h then return end
	local target = CONFIG.GlobalSpeedEnabled and CONFIG.GlobalSpeedValue or CONFIG.WalkSpeed
	target = clamp(target, 0, CONFIG.SpeedLimit)
	if h.WalkSpeed~=target then h.WalkSpeed=target end
	if h.JumpPower~=CONFIG.JumpPower then h.JumpPower=CONFIG.JumpPower; h.UseJumpPower=true end
	if h.Sit~=CONFIG.Sit then h.Sit=CONFIG.Sit end
end

local function updateGravity() workspace.GlobalGravity = CONFIG.Gravity * 196.2 end

local function refreshNoclip()
	table.clear(noclipParts)
	local c=getChar() if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then table.insert(noclipParts,p) end end end
end

local function setNoclip(state)
	CONFIG.Noclip=state
	if state then refreshNoclip(); trackConn(getChar().DescendantAdded:Connect(function(d) if d:IsA("BasePart") then table.insert(noclipParts,d) end end)) end
end

local function setSpin(state)
	CONFIG.Spin=state
	local r=getRoot()
	if state and r then
		local av=trackInst(Instance.new("AngularVelocity"))
		av.Name="SpinAV"; av.Attachment0=r:FindFirstChild("RootAttachment") or Instance.new("Attachment",r)
		av.RelativeTo=Enum.ActuatorRelativeTo.World; av.AngularVelocity=Vector3.new(0,CONFIG.SpinSpeed,0); av.MaxTorque=1e9; av.Parent=r
	elseif r then local av=r:FindFirstChild("SpinAV") if av then av:Destroy() end end
end

local function setFly(state)
	CONFIG.Fly=state
	local h=getHum(); local r=getRoot() if not h or not r then return end
	if state then
		h.PlatformStand=true
		flyAttach=trackInst(Instance.new("Attachment")); flyAttach.Name="FlyAttach"; flyAttach.Parent=r
		flyLV=trackInst(Instance.new("LinearVelocity")); flyLV.Name="FlyLV"; flyLV.Attachment0=flyAttach; flyLV.MaxForce=1e9; flyLV.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; flyLV.VectorVelocity=Vector3.zero; flyLV.Parent=r
		flyAO=trackInst(Instance.new("AlignOrientation")); flyAO.Name="FlyAO"; flyAO.Attachment0=flyAttach; flyAO.Mode=Enum.OrientationAlignmentMode.OneAttachment; flyAO.RigidityEnabled=true; flyAO.MaxTorque=1e9; flyAO.CFrame=camera.CFrame; flyAO.Parent=r
		trackConn(RunService.Heartbeat:Connect(function()
			if not CONFIG.Fly or not flyLV.Parent then return end
			local moveDir=h.MoveDirection; local camCF=camera.CFrame; flyAO.CFrame=camCF
			local speed=clamp(CONFIG.GlobalSpeedEnabled and CONFIG.GlobalSpeedValue or CONFIG.FlySpeed, 0, CONFIG.SpeedLimit)
			if moveDir.Magnitude>0 then
				local look,right=camCF.LookVector,camCF.RightVector
				local flatLook=Vector3.new(look.X,0,look.Z).Unit; local flatRight=Vector3.new(right.X,0,right.Z).Unit
				local fwd=moveDir:Dot(flatLook); local rgt=moveDir:Dot(flatRight)
				local dir=(flatLook*fwd+flatRight*rgt).Unit; flyLV.VectorVelocity=dir*speed
			else flyLV.VectorVelocity=Vector3.zero end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then flyLV.VectorVelocity+=Vector3.new(0,speed,0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then flyLV.VectorVelocity-=Vector3.new(0,speed,0) end
		end))
	else
		h.PlatformStand=false
		if flyLV then flyLV:Destroy() flyLV=nil end
		if flyAO then flyAO:Destroy() flyAO=nil end
		if flyAttach then flyAttach:Destroy() flyAttach=nil end
	end
end

local function updateESP()
	if CONFIG.ESP then
		for _,plr in pairs(Players:GetPlayers()) do
			if plr~=player and plr.Character and not espHighlights[plr] then
				local hl=trackInst(Instance.new("Highlight")); hl.Name="ESP_HL"; hl.FillTransparency=0.5; hl.OutlineTransparency=0
				hl.FillColor=plr.Team and plr.Team.TeamColor.Color or Color3.new(1,0,0); hl.OutlineColor=Color3.new(1,1,1)
				hl.Adornee=plr.Character; hl.Parent=plr.Character; espHighlights[plr]=hl
			elseif espHighlights[plr] then espHighlights[plr].Adornee=plr.Character end
		end
	else for _,hl in pairs(espHighlights) do if hl then hl:Destroy() end end; table.clear(espHighlights) end
end

local function updateLighting()
	if CONFIG.Fullbright then Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=1e5; Lighting.GlobalShadows=false
	else Lighting.GlobalShadows=true; Lighting.FogEnd=CONFIG.NoFog and 1e5 or 300 end
	if CONFIG.NoFog and not CONFIG.Fullbright then Lighting.FogEnd=1e5 end
end

local function updateFOV() camera.FieldOfView=CONFIG.FOV end

local function setFreeCam(state)
	CONFIG.FreeCam=state; fcEnabled=state
	local h=getHum(); local r=getRoot()
	if state and r and h then
		camera.CameraType=Enum.CameraType.Scriptable; camera.CFrame=r.CFrame*CFrame.new(0,2,10); h.PlatformStand=true
		trackConn(RunService.RenderStepped:Connect(function(dt)
			if not fcEnabled then return end
			local sp=50*dt; local cf=camera.CFrame
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then camera.CFrame+=cf.LookVector*sp end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then camera.CFrame-=cf.LookVector*sp end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then camera.CFrame+=cf.RightVector*sp end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then camera.CFrame-=cf.RightVector*sp end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then camera.CFrame+=Vector3.new(0,sp,0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then camera.CFrame-=Vector3.new(0,sp,0) end
		end))
	else camera.CameraType=Enum.CameraType.Custom; camera.CameraSubject=h; if h then h.PlatformStand=false end end
end

local function setClickTP(state) CONFIG.ClickTP=state end

local function applyAll()
	updateMovement(); updateGravity(); setNoclip(CONFIG.Noclip); setSpin(CONFIG.Spin)
	setFly(CONFIG.Fly); updateESP(); updateLighting(); updateFOV(); setFreeCam(CONFIG.FreeCam); setClickTP(CONFIG.ClickTP)
end

--// LOOPS OTIMIZADOS
trackConn(RunService.Stepped:Connect(function()
	local c=getChar() if not c then return end
	updateMovement()
	if CONFIG.Noclip then for _,p in ipairs(noclipParts) do if p and p.Parent and p.CanCollide then p.CanCollide=false end end end
	if CONFIG.Spin then local r=getRoot() local av=r and r:FindFirstChild("SpinAV") if av and av.AngularVelocity.Y~=CONFIG.SpinSpeed then av.AngularVelocity=Vector3.new(0,CONFIG.SpinSpeed,0) end end
end))

local espTimer=0
trackConn(RunService.Heartbeat:Connect(function(dt)
	espTimer+=dt
	if espTimer>=0.1 then espTimer=0; updateESP() end
end))

--// EVENTOS VIDA/MORTE
local function onCharAdded(char)
	cleanupAll()
	local h=char:WaitForChild("Humanoid",5); local r=char:WaitForChild("HumanoidRootPart",5) if not h or not r then return end
	if CONFIG.Noclip then trackConn(char.DescendantAdded:Connect(function(d) if d:IsA("BasePart") then table.insert(noclipParts,d) end end)) end
	if CONFIG.AntiAFK then trackConn(player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)) end
	task.wait(0.2); applyAll()
end

trackConn(player.CharacterAdded:Connect(onCharAdded))
if player.Character then onCharAdded(player.Character) end

trackConn(Players.PlayerRemoving:Connect(function(plr) if espHighlights[plr] then espHighlights[plr]:Destroy() espHighlights[plr]=nil end end))

--// INPUTS
trackConn(UserInputService.JumpRequest:Connect(function() if CONFIG.InfiniteJump then local h=getHum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))

trackConn(UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if CONFIG.ClickTP and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
		local r=getRoot() if r then local pos=input.UserInputType==Enum.UserInputType.Touch and input.Position or player:GetMouse().Hit.Position if typeof(pos)=="Vector3" then r.CFrame=CFrame.new(pos) end end
	end
end))

--// UI RAYFIELD
local Window = Rayfield:CreateWindow({
	Name = "Universal Hub | Projeto Final", LoadingTitle = "Carregando...", LoadingSubtitle = "v2.0 Estável",
	ConfigurationSaving = { Enabled=true, FolderName="UniversalHub", FileName="UIConfig" }, KeySystem=false
})

local PlayerTab = Window:CreateTab("Player", 4483362458)
local ServerTab = Window:CreateTab("Servidor", 6023426915)
local ConfigTab = Window:CreateTab("Config", 6031280882)

-- ABA PLAYER
PlayerTab:CreateSection("🏃 Movimento")
PlayerTab:CreateSlider({Name="WalkSpeed", Range={1,1000}, Increment=1, CurrentValue=16, Flag="WS", Callback=function(v) CONFIG.WalkSpeed=clamp(v,0,CONFIG.SpeedLimit); updateMovement() end})
PlayerTab:CreateSlider({Name="JumpPower", Range={50,500}, Increment=10, CurrentValue=50, Flag="JP", Callback=function(v) CONFIG.JumpPower=v; updateMovement() end})
PlayerTab:CreateSlider({Name="Gravidade", Range={0.1,10}, Increment=0.1, CurrentValue=1, Flag="Grav", Callback=function(v) CONFIG.Gravity=v; updateGravity() end})
PlayerTab:CreateToggle({Name="Infinite Jump", CurrentValue=false, Flag="InfJ", Callback=function(v) CONFIG.InfiniteJump=v end})
PlayerTab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=setNoclip})
PlayerTab:CreateToggle({Name="Spin", CurrentValue=false, Flag="Spin", Callback=setSpin})
PlayerTab:CreateSlider({Name="Spin Speed", Range={1,100}, Increment=1, CurrentValue=10, Flag="SS", Callback=function(v) CONFIG.SpinSpeed=v end})
PlayerTab:CreateToggle({Name="Sit", CurrentValue=false, Flag="Sit", Callback=function(v) CONFIG.Sit=v; updateMovement() end})

PlayerTab:CreateSection("✈️ Fly")
PlayerTab:CreateToggle({Name="Ativar Fly (WASD + Space/Shift)", CurrentValue=false, Flag="Fly", Callback=setFly})
PlayerTab:CreateSlider({Name="Fly Speed", Range={1,1000}, Increment=5, CurrentValue=50, Flag="FS", Callback=function(v) CONFIG.FlySpeed=clamp(v,0,CONFIG.SpeedLimit) end})

PlayerTab:CreateSection("👁️ Visual")
PlayerTab:CreateToggle({Name="ESP Players", CurrentValue=false, Flag="ESP", Callback=function(v) CONFIG.ESP=v; updateESP() end})
PlayerTab:CreateToggle({Name="Fullbright", CurrentValue=false, Flag="FB", Callback=function(v) CONFIG.Fullbright=v; updateLighting() end})
PlayerTab:CreateToggle({Name="No Fog", CurrentValue=false, Flag="NF", Callback=function(v) CONFIG.NoFog=v; updateLighting() end})
PlayerTab:CreateSlider({Name="FOV", Range={30,120}, Increment=1, CurrentValue=70, Flag="FOV", Callback=function(v) CONFIG.FOV=v; updateFOV() end})
PlayerTab:CreateToggle({Name="FreeCam", CurrentValue=false, Flag="FC", Callback=setFreeCam})

PlayerTab:CreateSection("⚡ Velocidade Global (Override)")
PlayerTab:CreateToggle({Name="Ativar Velocidade Global", CurrentValue=false, Flag="GSE", Callback=function(v) CONFIG.GlobalSpeedEnabled=v; updateMovement() end})
PlayerTab:CreateSlider({Name="Valor Global", Range={1,10000}, Increment=10, CurrentValue=1000, Flag="GSV", Callback=function(v) CONFIG.GlobalSpeedValue=clamp(v,0,CONFIG.SpeedLimit); updateMovement() end})
PlayerTab:CreateSlider({Name="Limite Máximo (Segurança)", Range={1,10000}, Increment=10, CurrentValue=1000, Flag="SL", Callback=function(v) CONFIG.SpeedLimit=v; updateMovement() end})

-- ABA SERVIDOR
ServerTab:CreateSection("👥 Jogadores")
local pList={"Nenhum"}; for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(pList,p.Name) end end
local dd = ServerTab:CreateDropdown({Name="Selecionar Jogador", Options=pList, CurrentOption="Nenhum", Flag="SelPlr", Callback=function(opt) CONFIG.SelectedPlayer=opt end})
task.spawn(function() while task.wait(5) do local t={"Nenhum"} for _,p in pairs(Players:GetPlayers()) do if p~=player then table.insert(t,p.Name) end end if dd.Refresh then dd:Refresh(t) end end end)

ServerTab:CreateButton({Name="Teleportar para Jogador", Callback=function()
	local tn=CONFIG.SelectedPlayer if tn and tn~="Nenhum" then local tp=Players:FindFirstChild(tn) if tp and tp.Character and tp.Character:FindFirstChild("HumanoidRootPart") then getRoot().CFrame=tp.Character.HumanoidRootPart.CFrame end end end})
ServerTab:CreateButton({Name="Spectate Jogador", Callback=function()
	local tn=CONFIG.SelectedPlayer if tn and tn~="Nenhum" then local tp=Players:FindFirstChild(tn) if tp and tp.Character and tp.Character:FindFirstChild("HumanoidRootPart") then camera.CFrame=tp.Character.HumanoidRootPart.CFrame end end end})
ServerTab:CreateToggle({Name="Click TP (Mouse/Touch)", CurrentValue=false, Flag="CTP", Callback=setClickTP})

ServerTab:CreateSection("⚙️ Utilidades")
ServerTab:CreateToggle({Name="Anti-AFK", CurrentValue=false, Flag="AAFK", Callback=function(v) CONFIG.AntiAFK=v; if v then trackConn(player.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)) end end})
ServerTab:CreateToggle({Name="Anti-Lag (Reduz Updates)", CurrentValue=false, Flag="ALag", Callback=function(v) CONFIG.AntiLag=v end})
ServerTab:CreateButton({Name="Resetar Personagem", Callback=function() local h=getHum() if h then h.Health=0 end end})
ServerTab:CreateButton({Name="Rejoin", Callback=function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end})
ServerTab:CreateButton({Name="Server Hop", Callback=function() Rayfield:Notify("Server Hop precisa de Proxy externo.", 5, "WARNING") end})

-- ABA CONFIG
ConfigTab:CreateSection("💾 Persistência (Arquivo JSON)")
ConfigTab:CreateButton({Name="💾 Salvar Config (JSON)", Callback=saveConfig})
ConfigTab:CreateButton({Name="📂 Carregar Config (JSON)", Callback=function() loadConfig(); applyAll(); Rayfield:Notify("Config aplicada!", 3, "SUCCESS") end})
ConfigTab:CreateButton({Name="🔄 Resetar Tudo (Padrão)", Callback=function() CONFIG=table.clone(DEFAULT_CONFIG); cleanupAll(); applyAll(); Rayfield:Notify("Resetado!", 3, "SUCCESS") end})

--// INICIALIZAÇÃO FINAL
loadConfig()
applyAll()
Rayfield:LoadConfiguration()
Rayfield:Notify("✅ Universal Hub Pronto!", 5, "SUCCESS")
print("[Universal Hub] Carregado com sucesso.")
