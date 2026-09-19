--[[
╔══════════════════════════════════════════════╗
║   MISTY · GOD + HITBOX TP                    ║
║   Бессмертие + телепорт хитбокса             ║
╚══════════════════════════════════════════════╝
--]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer

-- ═══════════════════════════════════════════════
--  НАСТРОЙКИ
-- ═══════════════════════════════════════════════
local God = {
    Enabled       = false,
    ForceField    = true,
    HP_Restore    = true,
    AntiDebuff    = true,
    AntiRagdoll   = true,
}

local HitboxTP = {
    Enabled       = false,
    Offset        = Vector3.new(0, 1e9, 0),  -- 1 миллиард studs вверх
    KeepToolInPlace = true,                   -- Handle инструмента остаётся на месте
    OriginalHRP   = nil,
    OriginalToolCF = nil,
}

-- ═══════════════════════════════════════════════
--  GOD MODE
-- ═══════════════════════════════════════════════
local godConns = {}
local lastHP = nil

local DEBUFFS = {
    "Plague", "Infected", "Burn", "Burning", "Frozen", "Freeze",
    "Stun", "Stunned", "Slow", "Slowed", "Poison", "Poisoned",
    "Bleeding", "Ragdolled", "Ragdoll",
}

local function ClearGodConns()
    for _, c in ipairs(godConns) do
        pcall(function() c:Disconnect() end)
    end
    godConns = {}
end

local function GetChar() return LP.Character end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function EnableGod(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    lastHP = hum.Health

    -- ForceField
    if God.ForceField and not char:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = char
    end

    -- HP restore
    if God.HP_Restore then
        table.insert(godConns, hum.HealthChanged:Connect(function(hp)
            if not God.Enabled then return end
            if hp < lastHP then
                hum.Health = hum.MaxHealth
            end
            lastHP = hum.Health
        end))
    end

    -- Anti-debuff loop
    if God.AntiDebuff then
        table.insert(godConns, RunService.Heartbeat:Connect(function()
            if not God.Enabled then return end
            local c = GetChar()
            if not c then return end
            for _, name in ipairs(DEBUFFS) do
                local d = c:FindFirstChild(name)
                if d then
                    if d:IsA("BoolValue") then
                        d.Value = false
                    else
                        pcall(function() d:Destroy() end)
                    end
                end
            end
            if God.ForceField and not c:FindFirstChildOfClass("ForceField") then
                local ff = Instance.new("ForceField")
                ff.Visible = false
                ff.Parent = c
            end
        end))
    end

    -- Anti-ragdoll
    if God.AntiRagdoll then
        table.insert(godConns, RunService.Heartbeat:Connect(function()
            if not God.Enabled then return end
            local c = GetChar()
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            if not h then return end
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint") then
                    if d.Enabled then d.Enabled = false end
                end
            end
            local state = h:GetState()
            if state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown then
                h.PlatformStand = false
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            local rag = c:FindFirstChild("Ragdolled")
            if rag and rag:IsA("BoolValue") and rag.Value then
                rag.Value = false
            end
        end))
    end
end

local function DisableGod()
    ClearGodConns()
    local char = GetChar()
    if char then
        for _, ff in ipairs(char:GetChildren()) do
            if ff:IsA("ForceField") then pcall(function() ff:Destroy() end) end
        end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint") then
                d.Enabled = true
            end
        end
    end
end

-- ═══════════════════════════════════════════════
--  HITBOX TP (хитбокс вверх, Handle на месте)
-- ═══════════════════════════════════════════════
local hitboxConn = nil
local origHRP = nil
local origHandleCF = nil
local origBodyParts = {}  -- { [part] = {cframe=..., anchored=..., canCollide=...} }

local function EnableHitboxTP()
    local char = GetChar()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Запоминаем оригинальные позиции
    origHRP = hrp.CFrame

    -- Запоминаем Handle инструмента (если экипирован)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle")
        if handle then
            origHandleCF = handle.CFrame
        end
    end

    -- Запоминаем все части тела (для восстановления)
    origBodyParts = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            origBodyParts[part] = {
                anchored = part.Anchored,
                canCollide = part.CanCollide,
                cframe = part.CFrame,
            }
        end
    end

    -- Цикл: каждый кадр гоним HRP вверх, но Handle возвращаем назад
    if hitboxConn then hitboxConn:Disconnect() end
    hitboxConn = RunService.RenderStepped:Connect(function()
        if not HitboxTP.Enabled then return end
        local c = GetChar()
        if not c then return end

        local r = c:FindFirstChild("HumanoidRootPart")
        if not r or not origHRP then return end

        -- 1. ТЕЛЕПОРТ ХИТБОКСА (HRP) — на 1e9 studs вверх
        r.CFrame = origHRP + HitboxTP.Offset

        -- 2. Гасим скорость чтобы физика не дёргала
        pcall(function()
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end)

        -- 3. Остальные части тела следуют за HRP через weld
        --    (ничего делать не надо, они welded)

        -- 4. HANDLE ИНСТРУМЕНТА — оставляем на месте
        if HitboxTP.KeepToolInPlace then
            local tool = c:FindFirstChildOfClass("Tool")
            if tool then
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    if not origHandleCF then
                        origHandleCF = handle.CFrame
                    end
                    -- Жёстко ставим Handle на оригинальную позицию
                    handle.CFrame = origHandleCF
                    -- Гасим Handle физику
                    pcall(function()
                        handle.AssemblyLinearVelocity = Vector3.zero
                        handle.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            end
        end
    end)
end

local function DisableHitboxTP()
    if hitboxConn then hitboxConn:Disconnect(); hitboxConn = nil end

    -- Восстанавливаем части
    local char = GetChar()
    if char then
        for part, data in pairs(origBodyParts) do
            if part and part.Parent then
                pcall(function()
                    part.CFrame = data.cframe
                    part.Anchored = data.anchored
                    part.CanCollide = data.canCollide
                end)
            end
        end
    end

    origHRP = nil
    origHandleCF = nil
    origBodyParts = {}
end

-- ═══════════════════════════════════════════════
--  Перезапуск при респавне
-- ═══════════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if God.Enabled then
        ClearGodConns()
        EnableGod(LP.Character)
    end
    if HitboxTP.Enabled then
        -- Перезапускаем заново с новыми позициями
        DisableHitboxTP()
        task.wait(0.2)
        EnableHitboxTP()
    end
end)

-- ═══════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MistyGodHitbox"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
pcall(function()
    if gethui then ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = game:GetService("CoreGui")
    else ScreenGui.Parent = game:GetService("CoreGui") end
end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

-- Кнопка GOD
local GodBtn = Instance.new("TextButton")
GodBtn.Size = UDim2.new(0, 110, 0, 44)
GodBtn.Position = UDim2.new(1, -130, 0, 80)
GodBtn.BackgroundColor3 = Color3.fromRGB(60, 62, 80)
GodBtn.Text = "GOD OFF"
GodBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
GodBtn.Font = Enum.Font.GothamBold
GodBtn.TextSize = 12
GodBtn.AutoButtonColor = false
GodBtn.Parent = ScreenGui
Instance.new("UICorner", GodBtn).CornerRadius = UDim.new(0, 8)
local godStroke = Instance.new("UIStroke", GodBtn)
godStroke.Color = Color3.fromRGB(90, 95, 120)
godStroke.Thickness = 1.5

-- Кнопка HITBOX TP
local HitboxBtn = Instance.new("TextButton")
HitboxBtn.Size = UDim2.new(0, 110, 0, 44)
HitboxBtn.Position = UDim2.new(1, -130, 0, 132)
HitboxBtn.BackgroundColor3 = Color3.fromRGB(60, 62, 80)
HitboxBtn.Text = "HITBOX OFF"
HitboxBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
HitboxBtn.Font = Enum.Font.GothamBold
HitboxBtn.TextSize = 11
HitboxBtn.AutoButtonColor = false
HitboxBtn.Parent = ScreenGui
Instance.new("UICorner", HitboxBtn).CornerRadius = UDim.new(0, 8)
local hitboxStroke = Instance.new("UIStroke", HitboxBtn)
hitboxStroke.Color = Color3.fromRGB(90, 95, 120)
hitboxStroke.Thickness = 1.5

local function UpdateUI()
    if God.Enabled then
        GodBtn.Text = "GOD ON"
        GodBtn.BackgroundColor3 = Color3.fromRGB(75, 130, 220)
        GodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        godStroke.Color = Color3.fromRGB(120, 170, 250)
    else
        GodBtn.Text = "GOD OFF"
        GodBtn.BackgroundColor3 = Color3.fromRGB(60, 62, 80)
        GodBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
        godStroke.Color = Color3.fromRGB(90, 95, 120)
    end

    if HitboxTP.Enabled then
        HitboxBtn.Text = "HITBOX ON"
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(75, 130, 220)
        HitboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        hitboxStroke.Color = Color3.fromRGB(120, 170, 250)
    else
        HitboxBtn.Text = "HITBOX OFF"
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(60, 62, 80)
        HitboxBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
        hitboxStroke.Color = Color3.fromRGB(90, 95, 120)
    end
end

local function ToggleGod()
    God.Enabled = not God.Enabled
    if God.Enabled then
        EnableGod(LP.Character)
    else
        DisableGod()
    end
    UpdateUI()
end

local function ToggleHitbox()
    HitboxTP.Enabled = not HitboxTP.Enabled
    if HitboxTP.Enabled then
        EnableHitboxTP()
    else
        DisableHitboxTP()
    end
    UpdateUI()
end

GodBtn.MouseButton1Click:Connect(ToggleGod)
HitboxBtn.MouseButton1Click:Connect(ToggleHitbox)
UpdateUI()

-- Горячие клавиши
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then ToggleGod() end
    if input.KeyCode == Enum.KeyCode.H then ToggleHitbox() end
end)

print("[Misty God + Hitbox] Загружено. G = God, H = Hitbox TP.")
