--[[
╔══════════════════════════════════════════════╗
║   MISTY · GOD + HITBOX TP (Camera Fixed)     ║
║   Камера остаётся на месте при TP хитбокса  ║
╚══════════════════════════════════════════════╝
--]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local LP           = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

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
    Enabled         = false,
    Offset          = Vector3.new(0, 1e9, 0),
    KeepToolInPlace = true,
    KeepCameraInPlace = true,   -- НОВОЕ: не тащить камеру за хитбоксом
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

    if God.ForceField and not char:FindFirstChildOfClass("ForceField") then
        local ff = Instance.new("ForceField")
        ff.Visible = false
        ff.Parent = char
    end

    if God.HP_Restore then
        table.insert(godConns, hum.HealthChanged:Connect(function(hp)
            if not God.Enabled then return end
            if hp < lastHP then
                hum.Health = hum.MaxHealth
            end
            lastHP = hum.Health
        end))
    end

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
--  HITBOX TP (камера остаётся на месте)
-- ═══════════════════════════════════════════════
local hitboxConn = nil
local camAnchor = nil
local origHRP = nil
local origHandleCF = nil
local origBodyParts = {}
local origCameraType = nil
local origCameraSubject = nil
local origCameraCF = nil

local function EnableHitboxTP()
    local char = GetChar()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    origHRP = hrp.CFrame

    -- Запоминаем Handle
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle")
        if handle then origHandleCF = handle.CFrame end
    end

    -- Запоминаем всё тело
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

    -- ═══ ФИКС КАМЕРЫ ═══
    -- Сохраняем состояние камеры и переключаем на якорь
    if HitboxTP.KeepCameraInPlace then
        origCameraType = Camera.CameraType
        origCameraSubject = Camera.CameraSubject
        origCameraCF = Camera.CFrame

        -- Создаём невидимый якорь камеры на оригинальной позиции
        camAnchor = Instance.new("Part")
        camAnchor.Name = "MistyCamAnchor"
        camAnchor.Size = Vector3.new(1, 1, 1)
        camAnchor.Transparency = 1
        camAnchor.CanCollide = false
        camAnchor.Anchored = true
        camAnchor.CFrame = origHRP
        camAnchor.Parent = Workspace

        -- Привязываем камеру к якорю
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = camAnchor
    end

    if hitboxConn then hitboxConn:Disconnect() end
    hitboxConn = RunService.RenderStepped:Connect(function()
        if not HitboxTP.Enabled then return end
        local c = GetChar()
        if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not r or not origHRP then return end

        -- Телепорт хитбокса вверх
        r.CFrame = origHRP + HitboxTP.Offset
        pcall(function()
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
        end)

        -- Handle на месте
        if HitboxTP.KeepToolInPlace then
            local tool = c:FindFirstChildOfClass("Tool")
            if tool then
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    if not origHandleCF then origHandleCF = handle.CFrame end
                    handle.CFrame = origHandleCF
                    pcall(function()
                        handle.AssemblyLinearVelocity = Vector3.zero
                        handle.AssemblyAngularVelocity = Vector3.zero
                    end)
                end
            end
        end

        -- Держим камерный якорь на месте (на случай если он сдвинулся)
        if camAnchor and camAnchor.Parent then
            camAnchor.CFrame = origHRP
        end
    end)
end

local function DisableHitboxTP()
    if hitboxConn then hitboxConn:Disconnect(); hitboxConn = nil end

    -- Восстанавливаем тело
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

    -- ═══ ВОССТАНАВЛИВАЕМ КАМЕРУ ═══
    if HitboxTP.KeepCameraInPlace then
        if camAnchor then
            camAnchor:Destroy()
            camAnchor = nil
        end
        -- Возвращаем камеру к персонажу
        local hum = GetHum()
        if hum then
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = hum
        elseif origCameraSubject then
            Camera.CameraType = origCameraType or Enum.CameraType.Custom
            Camera.CameraSubject = origCameraSubject
        end
    end

    origHRP = nil
    origHandleCF = nil
    origBodyParts = {}
    origCameraType = nil
    origCameraSubject = nil
    origCameraCF = nil
end

-- ═══════════════════════════════════════════════
--  Респавн
-- ═══════════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if God.Enabled then
        ClearGodConns()
        EnableGod(LP.Character)
    end
    if HitboxTP.Enabled then
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
godStroke.Color = Color3.fromRGB(90, 95, 120); godStroke.Thickness = 1.5

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
hitboxStroke.Color = Color3.fromRGB(90, 95, 120); hitboxStroke.Thickness = 1.5

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
    if God.Enabled then EnableGod(LP.Character) else DisableGod() end
    UpdateUI()
end

local function ToggleHitbox()
    HitboxTP.Enabled = not HitboxTP.Enabled
    if HitboxTP.Enabled then EnableHitboxTP() else DisableHitboxTP() end
    UpdateUI()
end

GodBtn.MouseButton1Click:Connect(ToggleGod)
HitboxBtn.MouseButton1Click:Connect(ToggleHitbox)
UpdateUI()

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then ToggleGod() end
    if input.KeyCode == Enum.KeyCode.H then ToggleHitbox() end
end)

print("[Misty God + Hitbox] Загружено. G = God, H = Hitbox TP (camera fixed).")
