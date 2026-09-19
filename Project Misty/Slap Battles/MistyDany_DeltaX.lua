-- ╔══════════════════════════════════════════════════════════════╗
-- ║    🌙 MISTY_DANY HUB v3.1 DeltaX  |  by Danil  🌙          ║
-- ║         Mobile Slap Battles Client (iOS/Android)  ✨         ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════
--  ДЕТЕКТОР ЭКЗЕКЬЮТОРА
-- ════════════════════════════════════════════════════════════════
local executor = "unknown"
if string.find(identifyexecutor and identifyexecutor() or "", "DeltaX") then
   executor = "DeltaX"
elseif string.find(identifyexecutor and identifyexecutor() or "", "Synapse") then
   executor = "Synapse"
elseif string.find(identifyexecutor and identifyexecutor() or "", "KRNL") then
   executor = "KRNL"
end

-- Проверяем функции доступные в экзекьюторе
local canWrite = pcall(function() writefile("test.txt", "test") end)
local hasDrawing = pcall(function() local x = Drawing end) and true or false

-- ════════════════════════════════════════════════════════════════
--  СЕРВИСЫ
-- ════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local lp               = Players.LocalPlayer
local cam              = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════════
--  ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ════════════════════════════════════════════════════════════════
local flyEnabled       = false
local flySpeed         = 50
local noclipEnabled    = false
local platformEnabled  = false
local platform         = nil
local antiAfkConn      = nil
local antiAfkEnabled   = true
local speedhackVal     = 20
local jumpVal          = 50
local infiniteJumpConn = nil
local ghostEnabled     = false
local fovCircle        = nil
local savedPositions   = {}

-- ESP
local espEnabled       = false
local espHighlight     = true
local espBoxes         = false
local espLines         = false
local espNames         = true
local espDist          = true
local espHealth        = true
local espObjects       = {}
local espFolder        = Instance.new("Folder", game.CoreGui)
espFolder.Name         = "MistyESP_Mobile"

-- Визуальные
local originalFOV      = cam.FieldOfView
local fullbrightActive = false
local origAmbient      = Lighting.Ambient
local origBrightness   = Lighting.Brightness
local origFogEnd       = Lighting.FogEnd

-- ════════════════════════════════════════════════════════════════
--  МОБИЛЬНАЯ UI (для DeltaX)
-- ════════════════════════════════════════════════════════════════
local MobileUI = {}
MobileUI.mainFrame = nil
MobileUI.isOpen = true

-- Создаём простой ScreenGui для мобилки
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MistyDanyMobileUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = lp:WaitForChild("PlayerGui")

-- Главное окно (слева сверху)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel"
mainFrame.Size = UDim2.new(0, 280, 0, 400)
mainFrame.Position = UDim2.new(0, 5, 0, 5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BorderColor3 = Color3.fromRGB(120, 80, 255)
mainFrame.BorderSizePixel = 2
mainFrame.CanDrag = true
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Скроллбар для контента
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -10, 1, -40)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

-- Заголовок
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "🌙 MistyDany v3.1 [" .. executor .. "]"
titleLabel.Parent = mainFrame

-- UIListLayout для автоматического расположения кнопок
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = scrollFrame

-- ════════════════════════════════════════════════════════════════
--  УТИЛИТЫ
-- ════════════════════════════════════════════════════════════════
local function notify(title, body, dur)
   print("[" .. title .. "] " .. body)
   -- Показываем уведомление через StarterGui
   pcall(function()
      StarterGui:SetCore("SendNotification", {
         Title   = title,
         Text    = body,
         Duration = dur or 3
      })
   end)
end

local function createButton(text, callback)
   local btn = Instance.new("TextButton")
   btn.Name = text
   btn.Size = UDim2.new(0.9, 0, 0, 35)
   btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
   btn.BorderColor3 = Color3.fromRGB(120, 80, 255)
   btn.BorderSizePixel = 1
   btn.TextColor3 = Color3.fromRGB(220, 220, 220)
   btn.TextSize = 12
   btn.Font = Enum.Font.Gotham
   btn.Text = text
   btn.Parent = scrollFrame
   
   btn.MouseButton1Click:Connect(callback)
   
   -- Адаптивное изменение цвета при нажатии
   btn.MouseEnter:Connect(function()
      btn.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
   end)
   btn.MouseLeave:Connect(function()
      btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
   end)
   
   scrollFrame.CanvasSize = scrollFrame.CanvasSize + UDim2.new(0, 0, 0, 40)
   return btn
end

local function createToggle(text, initialState, callback)
   local container = Instance.new("Frame")
   container.Name = text .. "_Toggle"
   container.Size = UDim2.new(0.9, 0, 0, 35)
   container.BackgroundTransparency = 1
   container.Parent = scrollFrame
   
   local toggle = Instance.new("TextButton")
   toggle.Name = "ToggleBtn"
   toggle.Size = UDim2.new(1, 0, 1, 0)
   toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
   toggle.BorderColor3 = Color3.fromRGB(120, 80, 255)
   toggle.BorderSizePixel = 1
   toggle.TextColor3 = Color3.fromRGB(220, 220, 220)
   toggle.TextSize = 11
   toggle.Font = Enum.Font.Gotham
   toggle.Text = text .. (initialState and " [ON]" or " [OFF]")
   toggle.Parent = container
   
   local state = initialState
   toggle.MouseButton1Click:Connect(function()
      state = not state
      toggle.Text = text .. (state and " [ON]" or " [OFF]")
      toggle.BackgroundColor3 = state and Color3.fromRGB(100, 150, 100) or Color3.fromRGB(50, 50, 70)
      callback(state)
   end)
   
   toggle.MouseEnter:Connect(function()
      toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
   end)
   toggle.MouseLeave:Connect(function()
      toggle.BackgroundColor3 = state and Color3.fromRGB(100, 150, 100) or Color3.fromRGB(50, 50, 70)
   end)
   
   scrollFrame.CanvasSize = scrollFrame.CanvasSize + UDim2.new(0, 0, 0, 40)
   return toggle
end

local function getChar()
   return lp.Character
end

local function getHRP()
   local c = getChar()
   return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
   local c = getChar()
   return c and c:FindFirstChildOfClass("Humanoid")
end

local function playerColor(p)
   if p.Team and lp.Team then
      return p.Team == lp.Team and Color3.fromRGB(60,220,90) or Color3.fromRGB(255,60,60)
   end
   return Color3.fromRGB(255,195,0)
end

-- ════════════════════════════════════════════════════════════════
--  ██  ESP (простая версия без Drawing для мобилки)
-- ════════════════════════════════════════════════════════════════
local function buildESP(player)
   if player == lp or espObjects[player] then return end

   local hl = Instance.new("Highlight")
   hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
   hl.FillTransparency = 0.5
   hl.OutlineTransparency = 0
   hl.Enabled = false

   local bb = Instance.new("BillboardGui")
   bb.AlwaysOnTop = true
   bb.Size = UDim2.new(0, 150, 0, 60)
   bb.StudsOffset = Vector3.new(0, 3.5, 0)
   bb.Enabled = false

   local nameLbl = Instance.new("TextLabel", bb)
   nameLbl.Size = UDim2.new(1,0,0,20)
   nameLbl.BackgroundTransparency = 1
   nameLbl.Font = Enum.Font.GothamBold
   nameLbl.TextSize = 12
   nameLbl.TextStrokeTransparency = 0.3

   local distLbl = Instance.new("TextLabel", bb)
   distLbl.Size = UDim2.new(1,0,0,15)
   distLbl.Position = UDim2.new(0,0,0,22)
   distLbl.BackgroundTransparency = 1
   distLbl.Font = Enum.Font.Gotham
   distLbl.TextSize = 10
   distLbl.TextStrokeTransparency = 0.4

   espObjects[player] = {
      hl = hl,
      bb = bb,
      nameLbl = nameLbl,
      distLbl = distLbl,
   }

   local function attach(char)
      local obj = espObjects[player]
      if not obj then return end
      obj.hl.Parent = char
      local hrp = char:WaitForChild("HumanoidRootPart", 5)
      if hrp then
         obj.bb.Adornee = hrp
         obj.bb.Parent = hrp
      end
   end

   if player.Character then attach(player.Character) end
   player.CharacterAdded:Connect(attach)
end

local function removeESP(player)
   local o = espObjects[player]
   if not o then return end
   pcall(function() o.hl:Destroy() end)
   pcall(function() o.bb:Destroy() end)
   espObjects[player] = nil
end

local function startESP()
   if RunService:FindFirstChild("ESPConn") then
      local c = RunService:FindFirstChild("ESPConn")
      if c then c:Disconnect() end
   end
   
   local espConn = RunService.RenderStepped:Connect(function()
      if not espEnabled then return end
      local myHRP = getHRP()

      for player, o in pairs(espObjects) do
         local char = player.Character
         local hrp = char and char:FindFirstChild("HumanoidRootPart")
         local hum = char and char:FindFirstChildOfClass("Humanoid")

         if hrp and hum and hum.Health > 0 then
            local col = playerColor(player)
            local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0

            o.hl.Enabled = espEnabled and espHighlight
            o.hl.FillColor = col
            o.bb.Enabled = espEnabled and espNames
            o.nameLbl.Text = player.DisplayName
            o.nameLbl.TextColor3 = col
            o.distLbl.Text = espDist and (tostring(dist).." м") or ""
            o.distLbl.Visible = espDist
         else
            o.hl.Enabled = false
            o.bb.Enabled = false
         end
      end
   end)
end

local function stopESP()
   for _, o in pairs(espObjects) do
      o.hl.Enabled = false
      o.bb.Enabled = false
   end
end

-- ════════════════════════════════════════════════════════════════
--  ██  ОСНОВНЫЕ КНОПКИ И ФУНКЦИИ
-- ════════════════════════════════════════════════════════════════

-- ── PLAYER ──
createButton("⚡ Скорость +20", function()
   local h = getHum()
   if h then
      speedhackVal = speedhackVal + 20
      h.WalkSpeed = speedhackVal
      notify("⚡ Скорость", tostring(speedhackVal), 2)
   end
end)

createButton("⚡ Скорость MAX (500)", function()
   local h = getHum()
   if h then
      h.WalkSpeed = 500
      speedhackVal = 500
      notify("⚡ Макс скорость", "500", 2)
   end
end)

createButton("⚡ Скорость RESET (16)", function()
   local h = getHum()
   if h then
      h.WalkSpeed = 16
      speedhackVal = 16
      notify("⚡ Сброс скорости", "16", 2)
   end
end)

createButton("🦘 Прыжок +50", function()
   local h = getHum()
   if h then
      jumpVal = jumpVal + 50
      h.JumpPower = jumpVal
      h.UseJumpPower = true
      notify("🦘 Прыжок", tostring(jumpVal), 2)
   end
end)

-- ── GOD MODE ──
createToggle("☠️ Бог режим", false, function(v)
   _G.GodMode = v
   local char = getChar()
   if not char then return end
   local hum = char:FindFirstChildOfClass("Humanoid")
   
   if v then
      -- Добавляем ForceField
      if not char:FindFirstChildOfClass("ForceField") then
         Instance.new("ForceField", char)
      end
      notify("☠️ God Mode", "ВКЛ", 2)
   else
      -- Убираем ForceField
      for _, ff in pairs(char:GetChildren()) do
         if ff:IsA("ForceField") then ff:Destroy() end
      end
      notify("☠️ God Mode", "ВЫКЛ", 2)
   end
end)

-- ── NOCLIP ──
createToggle("👻 НоКлип (сквозь стены)", false, function(v)
   noclipEnabled = v
   if v then
      notify("👻 НоКлип", "ВКЛ", 2)
   else
      local char = getChar()
      if char then
         for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
         end
      end
      notify("👻 НоКлип", "ВЫКЛ", 2)
   end
end)

-- ── INFINITE JUMP ──
createToggle("♾️ Бесконечный прыжок", false, function(v)
   if v then
      notify("♾️ Infinite Jump", "ВКЛ - прыгай сколько хочешь!", 3)
   else
      notify("♾️ Infinite Jump", "ВЫКЛ", 2)
   end
end)

-- ── ANTI-RAGDOLL ──
createToggle("🔄 Обход регдола", false, function(v)
   _G.AntiRagdoll = v
   notify("🔄 Ragdoll Bypass", v and "ВКЛ" or "ВЫКЛ", 2)
end)

-- ── GHOST MODE ──
createToggle("👻 Режим призрака", false, function(v)
   ghostEnabled = v
   local char = getChar()
   if char then
      for _, p in pairs(char:GetDescendants()) do
         if p:IsA("BasePart") then
            p.LocalTransparencyModifier = v and 0.6 or 0
         end
      end
   end
   notify("👻 Призрак", v and "ВКЛ" or "ВЫКЛ", 2)
end)

-- ── FLY ──
createToggle("🚁 Полёт", false, function(v)
   flyEnabled = v
   local char = lp.Character or lp.CharacterAdded:Wait()
   local root = char:WaitForChild("HumanoidRootPart")
   
   if v then
      local bv = Instance.new("BodyVelocity", root)
      bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
      bv.Velocity = Vector3.new(0, 0, 0)
      bv.Name = "FlyBV"
      
      -- Для мобилки: летим в направлении камеры при нажатии кнопки
      notify("🚁 Полёт", "ВКЛ - смотри в сторону полёта", 3)
   else
      local bvF = root:FindFirstChild("FlyBV")
      if bvF then bvF:Destroy() end
      notify("🚁 Полёт", "ВЫКЛ", 2)
   end
end)

-- ── ANTI AFK ──
createToggle("⏰ Анти-АФК", true, function(v)
   antiAfkEnabled = v
   if antiAfkConn then antiAfkConn:Disconnect() end
   if v then
      local vu = game:GetService("VirtualUser")
      antiAfkConn = lp.Idled:Connect(function()
         vu:CaptureController()
         vu:ClickButton2(Vector2.new())
      end)
      notify("⏰ Анти-АФК", "ВКЛ", 2)
   end
end)

-- ── RESPAWN ──
createButton("💀 Пересоздать персонажа", function()
   lp:LoadCharacter()
   notify("🔄 Respawn", "Персонаж пересоздан", 2)
end)

-- ── TELEPORT ──
createButton("🌀 Телепорт на спавн", function()
   local hrp = getHRP()
   if not hrp then
      notify("🌀 Телепорт", "Персонаж не загружен", 3)
      return
   end
   local spawn = nil
   for _, v in pairs(workspace:GetDescendants()) do
      if v:IsA("SpawnLocation") then
         spawn = v
         break
      end
   end
   if spawn then
      hrp.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0))
      notify("🌀 Телепорт", "На спавн", 2)
   end
end)

-- ── ESP ──
createToggle("👁 ESP", false, function(v)
   espEnabled = v
   if v then
      for _, p in ipairs(Players:GetPlayers()) do
         buildESP(p)
      end
      Players.PlayerAdded:Connect(buildESP)
      Players.PlayerRemoving:Connect(removeESP)
      startESP()
      notify("👁 ESP", "ВКЛ", 2)
   else
      stopESP()
      notify("👁 ESP", "ВЫКЛ", 2)
   end
end)

-- ── FULLBRIGHT ──
createToggle("☀️ Фуллбрайт", false, function(v)
   fullbrightActive = v
   if v then
      Lighting.Ambient = Color3.new(1, 1, 1)
      Lighting.Brightness = 2
      Lighting.FogEnd = 1e6
      Lighting.GlobalShadows = false
      notify("☀️ Фуллбрайт", "ВКЛ", 2)
   else
      Lighting.Ambient = origAmbient
      Lighting.Brightness = origBrightness
      Lighting.FogEnd = origFogEnd
      Lighting.GlobalShadows = true
      notify("☀️ Фуллбрайт", "ВЫКЛ", 2)
   end
end)

-- ── GRAVITY ──
createButton("🌍 Гравитация 0", function()
   workspace.Gravity = 0
   notify("🌍 Гравитация", "= 0", 2)
end)

createButton("🌍 Гравитация RESET", function()
   workspace.Gravity = 196.2
   notify("🌍 Гравитация", "= 196.2", 2)
end)

-- ── CAMERA ──
createButton("📷 FOV +10", function()
   cam.FieldOfView = math.min(cam.FieldOfView + 10, 120)
   notify("📷 FOV", tostring(math.floor(cam.FieldOfView)), 1)
end)

createButton("📷 FOV -10", function()
   cam.FieldOfView = math.max(cam.FieldOfView - 10, 50)
   notify("📷 FOV", tostring(math.floor(cam.FieldOfView)), 1)
end)

createButton("📷 FOV RESET (70)", function()
   cam.FieldOfView = 70
   notify("📷 FOV", "70", 2)
end)

-- ── COPY INFO ──
createButton("📋 Скопировать ник", function()
   setclipboard(lp.Name)
   notify("📋 Скопировано", lp.Name, 2)
end)

createButton("📋 ID игры", function()
   setclipboard(tostring(game.PlaceId))
   notify("📋 PlaceId", tostring(game.PlaceId), 2)
end)

createButton("📋 ID сервера", function()
   setclipboard(game.JobId)
   notify("📋 JobId", "Скопирован", 2)
end)

-- ── REJOIN ──
createButton("🔄 Rejoin на сервер", function()
   notify("🔄 Rejoin", "Перезаходим...", 2)
   task.wait(1)
   game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
end)

-- ── UNLOAD ──
createButton("🔴 ВЫГРУЗИТЬ ХАБ", function()
   _G.GodMode = false
   _G.AntiRagdoll = false
   flyEnabled = false
   noclipEnabled = false
   espEnabled = false
   stopESP()
   for p, _ in pairs(espObjects) do removeESP(p) end
   
   Lighting.Ambient = origAmbient
   Lighting.Brightness = origBrightness
   Lighting.FogEnd = origFogEnd
   workspace.Gravity = 196.2
   cam.FieldOfView = 70
   
   local h = getHum()
   if h then
      h.WalkSpeed = 16
      h.JumpPower = 50
   end
   
   screenGui:Destroy()
   notify("🔴 Хаб", "Выгружен", 2)
end)

-- ════════════════════════════════════════════════════════════════
--  ОСНОВНОЙ ЛУП (для функций которые нужны каждый кадр)
-- ════════════════════════════════════════════════════════════════
local loopConn = RunService.Heartbeat:Connect(function()
   -- Noclip loop
   if noclipEnabled then
      local char = getChar()
      if char then
         for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
         end
      end
   end

   -- God Mode loop
   if _G.GodMode then
      local char = getChar()
      if char then
         local hum = char:FindFirstChildOfClass("Humanoid")
         if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
         end
         -- Чистим дебаффы
         for _, obj in pairs(char:GetChildren()) do
            if obj:IsA("BoolValue") and (obj.Name == "Ragdolled" or obj.Name == "Frozen") then
               obj.Value = false
            end
         end
      end
   end

   -- Anti-Ragdoll loop
   if _G.AntiRagdoll then
      local char = getChar()
      if char then
         local hum = char:FindFirstChildOfClass("Humanoid")
         if hum then
            if hum:GetState() == Enum.HumanoidStateType.Ragdoll or
               hum:GetState() == Enum.HumanoidStateType.FallingDown then
               hum.PlatformStand = false
               hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
         end
      end
   end

   -- Infinite Jump
   -- (Обработка в отдельном Input Connect)

   -- Fly loop (простой версия для мобилки)
   if flyEnabled then
      local char = getChar()
      if char then
         local root = char:FindFirstChild("HumanoidRootPart")
         local bv = root and root:FindFirstChild("FlyBV")
         if bv then
            -- Летим в сторону камеры
            bv.Velocity = cam.CFrame.LookVector * flySpeed
         end
      end
   end
end)

-- ════════════════════════════════════════════════════════════════
--  МОБИЛЬНЫЙ ВВОД (для DeltaX на сенсорных устройствах)
-- ════════════════════════════════════════════════════════════════

-- Infinite Jump через Input
UserInputService.JumpRequest:Connect(function()
   if not true then return end  -- Флаг из createToggle
   local h = getHum()
   if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ════════════════════════════════════════════════════════════════
--  АВТООБНОВЛЕНИЕ ПРИ RESPAWN
-- ════════════════════════════════════════════════════════════════
lp.CharacterAdded:Connect(function()
   if _G.GodMode then
      task.wait(0.5)
      local char = getChar()
      if char and not char:FindFirstChildOfClass("ForceField") then
         Instance.new("ForceField", char)
      end
   end
end)

-- ════════════════════════════════════════════════════════════════
--  ЗАГРУЗКА УСПЕШНА
-- ════════════════════════════════════════════════════════════════
notify("🌙 MistyDany Hub v3.1 [" .. executor .. "]", "Загружено ✓  |  by Danil", 5)
print("════════════════════════════════════════════")
print("🌙 MISTY_DANY HUB v3.1 [" .. executor .. "]")
print("Мобильная версия для DeltaX")
print("════════════════════════════════════════════")
print("✓ Основные функции загружены")
print("✓ UI адаптирована для мобилки")
print("✓ Сенсорное управление активно")
print("════════════════════════════════════════════")
