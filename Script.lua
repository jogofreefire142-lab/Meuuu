--[[ UNIVERSAL LITE — ETAPA 1: APENAS UI (TESTE) ]]--
if getgenv()._UL_Cleanup then pcall(getgenv()._UL_Cleanup) end

-- Serviços básicos
local Run = game:GetService("RunService")
local Plrs = game:GetService("Players")
local LP = Plrs.LocalPlayer
local Cam = workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game:IsLoaded() and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
task.wait(0.5)

-- ============================================================
-- 🖥️ RAYFIELD OFICIAL (COM FALLBACK NATIVO SE FALHAR)
-- ============================================================
local Rayfield = nil
local RayfieldLoaded = false

-- Tenta baixar Rayfield Oficial (Timeout 5s)
task.spawn(function()
    local ok, res = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", true)
    end)
    if ok and res and #res > 1000 then
        local fn, err = loadstring(res)
        if fn then
            local ok2, lib = pcall(fn)
            if ok2 and lib then
                Rayfield = lib
                print("[UI] Rayfield Oficial carregado via HttpGet")
            end
        end
    end
end)

-- Aguarda 3s. Se falhar, carrega UI Nativa (Fallback) idêntica visualmente.
task.wait(3)
if not Rayfield then
    print("[UI] HttpGet falhou/timeout. Carregando UI Nativa (Fallback)...")
    local Tween = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local LP = game:GetService("Players").LocalPlayer
    local CoreGui = game:GetService("CoreGui")

    local function Protect(gui)
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
        if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
    end

    Rayfield = {}
    function Rayfield:CreateWindow(settings)
        local self = setmetatable({}, {__index = self})
        self.ScreenGui = Instance.new("ScreenGui")
        self.ScreenGui.Name = "UniversalLite_Standard"
        self.ScreenGui.ResetOnSpawn = false
        self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        Protect(self.ScreenGui)

        local Main = Instance.new("Frame")
        Main.Name = "Main"
        Main.Size = UDim2.new(0, 500, 0, 400)
        Main.Position = UDim2.new(0.5, -250, 0.5, -200)
        Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        Main.BorderSizePixel = 0
        Main.Active = true
        Main.Draggable = true
        Main.Parent = self.ScreenGui
        Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Main).Color = Color3.fromRGB(0, 170, 255)

        local Top = Instance.new("Frame", Main)
        Top.Size = UDim2.new(1, 0, 0, 40)
        Top.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 6)
        local Title = Instance.new("TextLabel", Top)
        Title.Text = settings.Name or "Universal Lite"
        Title.Size = UDim2.new(1, -20, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.BackgroundTransparency = 1
        Title.TextColor3 = Color3.new(1, 1, 1)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 16
        Title.TextXAlignment = Enum.TextXAlignment.Left

        local TabBar = Instance.new("Frame", Main)
        TabBar.Name = "TabBar"
        TabBar.Size = UDim2.new(0, 120, 1, -40)
        TabBar.Position = UDim2.new(0, 0, 0, 40)
        TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        Instance.new("UIListLayout", TabBar).Padding = UDim.new(0, 5)

        local Pages = Instance.new("Folder", Main)
        Pages.Name = "Pages"

        function self:Notify(d)
            local N = Instance.new("Frame")
            N.Size = UDim2.new(0, 300, 0, 80)
            N.Position = UDim2.new(1, -310, 1, -90)
            N.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            N.Parent = self.ScreenGui
            Instance.new("UICorner", N).CornerRadius = UDim.new(0, 6)
            local L = Instance.new("TextLabel", N)
            L.Text = (d.Title or "") .. "\n" .. (d.Content or "")
            L.Size = UDim2.new(1, -20, 1, -20)
            L.Position = UDim2.new(0, 10, 0, 10)
            L.BackgroundTransparency = 1
            L.TextColor3 = Color3.new(1, 1, 1)
            L.Font = Enum.Font.Gotham
            L.TextSize = 14
            L.TextWrapped = true
            L.TextXAlignment = Enum.TextXAlignment.Left
            game:GetService("TweenService"):Create(N, TweenInfo.new(0.5), {Position = UDim2.new(1, -310, 1, -90)}):Play()
            task.delay(d.Duration or 5, function() N:Destroy() end)
        end

        function self:CreateTab(name, icon)
            local tab = {}
            local Btn = Instance.new("TextButton", TabBar)
            Btn.Text = name
            Btn.Size = UDim2.new(1, -10, 0, 30)
            Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            Btn.TextColor3 = Color3.new(1, 1, 1)
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 14
            Btn.AutoButtonColor = false
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

            local Page = Instance.new("ScrollingFrame", Pages)
            Page.Name = name
            Page.Size = UDim2.new(1, -130, 1, -50)
            Page.Position = UDim2.new(0, 130, 0, 40)
            Page.BackgroundTransparency = 1
            Page.ScrollBarThickness = 3
            Page.Visible = false
            Page.CanvasSize = UDim2.new(0, 0, 0, 0)
            local PList = Instance.new("UIListLayout", Page)
            PList.Padding = UDim.new(0, 8)
            PList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            PList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Page.CanvasSize = UDim2.new(0, 0, 0, PList.AbsoluteContentSize.Y + 20) end)

            local first = (#Pages:GetChildren() == 0)
            if first then Page.Visible = true Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end

            Btn.MouseButton1Click:Connect(function()
                for _, p in pairs(Pages:GetChildren()) do p.Visible = false end
                for _, b in pairs(TabBar:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(35, 35, 40) end end
                Page.Visible = true
                Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            end)

            function tab:CreateSection(n)
                local L = Instance.new("TextLabel", Page)
                L.Text = "  " .. n
                L.Size = UDim2.new(1, -20, 0, 25)
                L.BackgroundTransparency = 1
                L.TextColor3 = Color3.fromRGB(150, 150, 150)
                L.Font = Enum.Font.GothamBold
                L.TextSize = 13
                L.TextXAlignment = Enum.TextXAlignment.Left
                return L
            end

            function tab:CreateToggle(p)
                local F = Instance.new("Frame", Page)
                F.Size = UDim2.new(1, -20, 0, 40)
                F.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                Instance.new("UICorner", F).CornerRadius = UDim.new(0, 4)
                local L = Instance.new("TextLabel", F)
                L.Text = p.Name
                L.Size = UDim2.new(1, -60, 1, 0)
                L.Position = UDim2.new(0, 15, 0, 0)
                L.BackgroundTransparency = 1
                L.TextColor3 = Color3.new(1, 1, 1)
                L.Font = Enum.Font.Gotham
                L.TextSize = 14
                L.TextXAlignment = Enum.TextXAlignment.Left
                local B = Instance.new("TextButton", F)
                B.Size = UDim2.new(0, 40, 0, 20)
                B.Position = UDim2.new(1, -50, 0.5, -10)
                B.BackgroundColor3 = p.CurrentValue and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)
                B.Text = ""
                Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
                local C = Instance.new("Frame", B)
                C.Size = UDim2.new(0, 18, 0, 18)
                C.Position = p.CurrentValue and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)
                C.BackgroundColor3 = Color3.new(1, 1, 1)
                Instance.new("UICorner", C).CornerRadius = UDim.new(1, 0)
                local st = p.CurrentValue
                local function Set(v)
                    st = v
                    game:GetService("TweenService"):Create(B, TweenInfo.new(0.2), {BackgroundColor3 = v and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)}):Play()
                    game:GetService("TweenService"):Create(C, TweenInfo.new(0.2), {Position = v and UDim2.new(1, -19, 0.5, -9) or UDim2.new(0, 1, 0.5, -9)}):Play()
                end
                B.MouseButton1Click:Connect(function() Set(not st) if p.Callback then p.Callback(st) end end)
                return {Set = Set}
            end

            function tab:CreateSlider(p)
                local F = Instance.new("Frame", Page)
                F.Size = UDim2.new(1, -20, 0, 50)
                F.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                Instance.new("UICorner", F).CornerRadius = UDim.new(0, 4)
                local L = Instance.new("TextLabel", F)
                L.Text = p.Name .. " : " .. p.CurrentValue
                L.Size = UDim2.new(1, -20, 0, 25)
                L.Position = UDim2.new(0, 15, 0, 0)
                L.BackgroundTransparency = 1
                L.TextColor3 = Color3.new(1, 1, 1)
                L.Font = Enum.Font.Gotham
                L.TextSize = 14
                L.TextXAlignment = Enum.TextXAlignment.Left
                local B = Instance.new("Frame", F)
                B.Size = UDim2.new(1, -30, 0, 6)
                B.Position = UDim2.new(0, 15, 0, 35)
                B.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
                local Fll = Instance.new("Frame", B)
                Fll.Size = UDim2.new((p.CurrentValue - p.Range[1]) / (p.Range[2] - p.Range[1]), 1, 0)
                Fll.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                Instance.new("UICorner", Fll).CornerRadius = UDim.new(1, 0)
                local K = Instance.new("Frame", B)
                K.Size = UDim2.new(0, 14, 0, 14)
                K.Position = UDim2.new(Fll.Size.X.Scale, -7, 0.5, -7)
                K.BackgroundColor3 = Color3.new(1, 1, 1)
                K.ZIndex = 2
                Instance.new("UICorner", K).CornerRadius = UDim.new(1, 0)
                local drag = false
                local function Upd(i)
                    local p = math.clamp((i.Position.X - B.AbsolutePosition.X) / B.AbsoluteSize.X, 0, 1)
                    local v = math.floor(p.Range[1] + p * (p.Range[2] - p.Range[1]))
                    Fll.Size = UDim2.new(p, 0, 1, 0)
                    K.Position = UDim2.new(p, -7, 0.5, -7)
                    L.Text = p.Name .. " : " .. v
                    if p.Callback then p.Callback(v) end
                end
                B.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true Upd(i) end end)
                game:GetService("UserInputService").InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
                game:GetService("UserInputService").InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Upd(i) end end)
                return {Set = function(v) L.Text = p.Name .. " : " .. v local p = (v - p.Range[1]) / (p.Range[2] - p.Range[1]) Fll.Size = UDim2.new(p, 0, 1, 0) K.Position = UDim2.new(p, -7, 0.5, -7) end}
            end

            function tab:CreateButton(p)
                local B = Instance.new("TextButton", Page)
                B.Text = p.Name
                B.Size = UDim2.new(1, -20, 0, 35)
                B.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                B.TextColor3 = Color3.new(1, 1, 1)
                B.Font = Enum.Font.GothamBold
                B.TextSize = 14
                Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
                B.MouseButton1Click:Connect(function() if p.Callback then p.Callback() end end)
                return B
            end

            function tab:CreateDropdown(p)
                local B = Instance.new("TextButton", Page)
                B.Text = p.Name .. ": " .. tostring(p.CurrentOption)
                B.Size = UDim2.new(1, -20, 0, 35)
                B.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                B.TextColor3 = Color3.new(1, 1, 1)
                B.Font = Enum.Font.Gotham
                B.TextSize = 14
                Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
                local idx = 1
                B.MouseButton1Click:Connect(function()
                    idx = idx + 1
                    if idx > #p.Options then idx = 1 end
                    local v = p.Options[idx]
                    B.Text = p.Name .. ": " .. tostring(v)
                    if p.Callback then p.Callback({v}) end
                end)
                return {Refresh = function(opts, cur) p.Options = opts if cur then B.Text = p.Name .. ": " .. tostring(cur) end end, Set = function(v) B.Text = p.Name .. ": " .. tostring(v) end}
            end

            function tab:CreateColorPicker(p)
                local B = Instance.new("TextButton", Page)
                B.Text = p.Name
                B.Size = UDim2.new(1, -20, 0, 35)
                B.BackgroundColor3 = p.Color
                B.TextColor3 = Color3.new(1, 1, 1)
                B.Font = Enum.Font.Gotham
                B.TextSize = 14
                Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
                B.MouseButton1Click:Connect(function() if p.Callback then p.Callback(p.Color) end end)
                return {Set = function(v) B.BackgroundColor3 = v end}
            end

            function tab:CreateLabel(t)
                local L = Instance.new("TextLabel", Page)
                L.Text = t
                L.Size = UDim2.new(1, -20, 0, 25)
                L.BackgroundTransparency = 1
                L.TextColor3 = Color3.fromRGB(150, 150, 150)
                L.Font = Enum.Font.Gotham
                L.TextSize = 13
                L.TextXAlignment = Enum.TextXAlignment.Left
                return L
            end

            return tab
        end

        return self
    end
end

-- ============================================================
-- 🖥️ CRIA A JANELA E AS 5 ABAS
-- ============================================================
local Win = Rayfield:CreateWindow({
    Name = "Universal Lite v8.1 — ETAPA 1 (UI Only)",
    LoadingTitle = "Carregando Interface...",
    LoadingSubtitle = "Teste de UI — Rayfield Oficial / Fallback",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local T = {
    Move = Win:CreateTab("1. Movimento", 4483362458),
    Vis  = Win:CreateTab("2. Visuais", 4483362458),
    Util = Win:CreateTab("3. Utilitários", 4483362458),
    Perf = Win:CreateTab("4. Performance", 4483362458),
    Sys  = Win:CreateTab("5. Sistema", 4483362458)
}

-- Labels de placeholder nas abas (para confirmar que abriram)
T.Move:CreateSection("⚡ Movimento (Vazio — Teste UI)")
T.Move:CreateLabel("Aba Movimento OK")

T.Vis:CreateSection("👁️ Visuais (Vazio — Teste UI)")
T.Vis:CreateLabel("Aba Visuais OK")

T.Util:CreateSection("🛠️ Utilitários (Vazio — Teste UI)")
T.Util:CreateLabel("Aba Utilitários OK")

T.Perf:CreateSection("🚀 Performance (Vazio — Teste UI)")
T.Perf:CreateLabel("Aba Performance OK")

T.Sys:CreateSection("⚙️ Sistema (Vazio — Teste UI)")
T.Sys:CreateLabel("Aba Sistema OK")

-- Notificação final
if Win and Win.Notify then
    Win:Notify({Title = "✅ ETAPA 1 OK", Content = "UI Carregada! 5 Abas prontas.", Duration = 5})
end

print("==================================================")
print("✅ ETAPA 1 CONCLUÍDA — UI CARREGADA COM SUCESSO")
print("==================================================")
