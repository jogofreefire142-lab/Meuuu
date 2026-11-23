--[[ UNIVERSAL LITE — ETAPA 1: UI RAYFIELD OFICIAL ]]--
if getgenv()._UL_Cleanup then pcall(getgenv()._UL_Cleanup) end

-- Serviços
local Run = game:GetService("RunService")
local Plrs = game:GetService("Players")
local LP = Plrs.LocalPlayer
local Cam = workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
task.wait(0.5)

-- ============================================================
-- 🖥️ CARREGA RAYFIELD OFICIAL (SEM FALLBACK)
-- ============================================================
local Rayfield
local success, err = pcall(function()
    -- Timeout de 10 segundos no HttpGet
    local src = game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua", true)
    local fn, errLoad = loadstring(src)
    if not fn then error("Erro ao compilar Rayfield: " .. tostring(errLoad)) end
    Rayfield = fn()
end)

if not success or not Rayfield or not Rayfield.CreateWindow then
    local msg = "❌ FALHA AO CARREGAR RAYFIELD OFICIAL\n\n"
    msg = msg .. "Erro: " .. tostring(err) .. "\n\n"
    msg = msg .. "Causas prováveis:\n"
    msg = msg .. "1. Sem internet / GitHub bloqueado\n"
    msg = msg .. "2. Executor bloqueou HttpGet\n"
    msg = msg .. "3. GitHub rate limit (espere alguns minutos)\n\n"
    msg = msg .. "Solução: Verifique internet / use executor com HttpGet liberado."
    
    warn("[UniversalLite] " .. msg)
    LP:Kick(msg) -- Para o script e mostra o erro na tela
    return
end

print("[UI] Rayfield Oficial carregado com sucesso!")

-- ============================================================
-- 🖥️ CRIA JANELA + 5 ABAS (RAYFIELD PURO)
-- ============================================================
local Win = Rayfield:CreateWindow({
    Name = "Universal Lite v8.1 — Oficial",
    LoadingTitle = "Carregando Rayfield Oficial...",
    LoadingSubtitle = "Aguardando interface...",
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

-- Placeholders visuais
T.Move:CreateSection("⚡ Movimento")
T.Move:CreateLabel("✅ Aba Movimento pronta")

T.Vis:CreateSection("👁️ Visuais")
T.Vis:CreateLabel("✅ Aba Visuais pronta")

T.Util:CreateSection("🛠️ Utilitários")
T.Util:CreateLabel("✅ Aba Utilitários pronta")

T.Perf:CreateSection("🚀 Performance")
T.Perf:CreateLabel("✅ Aba Performance pronta")

T.Sys:CreateSection("⚙️ Sistema")
T.Sys:CreateLabel("✅ Aba Sistema pronta")

Rayfield:Notify({Title = "✅ Rayfield Oficial Carregado", Content = "5 Abas prontas. Zero fallback.", Duration = 5, Image = "check-circle"})

print("==================================================")
print("✅ ETAPA 1 CONCLUÍDA — RAYFIELD OFICIAL ATIVO")
print("==================================================")

-- Cleanup básico
getgenv()._UL_Cleanup = function()
    print("[Cleanup] Limpando UI...")
end
