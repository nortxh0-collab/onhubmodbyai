-- ==============================================================================
--  VexxuzzZx HUB - ONHUB MASTER (PRESET 1200m/60m + FAILSAFE TRANSLATOR)
--  Default: TP 1200m | Hop 60m | Aliran terjemahan terisolasi 100% | Pertahankan tabel Pet
--  + Tampilan Kaca + Anime (Gaya Keren) & Bahasa Indonesia
--  + FITUR XENON: God Mode, Bypass Speed, Instant TP, Auto Return Instant
-- ==============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGuiService = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== 1. MUAT DEFAULT 2 SLIDER (MEMORI + ANTARMUKA) ====================
local presetMemoryDone = false
local presetUIDone = false

local function applyMemoryPresets()
    if presetMemoryDone then return end
    pcall(function()
        if getgc then
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    for k, v in pairs(obj) do
                        local lk = tostring(k):lower()
                        if type(v) == "number" then
                            if (lk:find("tp") and (lk:find("dist") or lk:find("min"))) and (v == 600 or v == 1200) then
                                rawset(obj, k, 1200)
                            elseif (lk:find("hop") and lk:find("step")) and (v == 80 or v == 60) then
                                rawset(obj, k, 60)
                            end
                        end
                    end
                end
            end
            presetMemoryDone = true
        end
    end)
end

local function applyUISliderPresets(root)
    if presetUIDone or not root then return end
    pcall(function()
        local tpFound = false
        local hopFound = false

        for _, label in ipairs(root:GetDescendants()) do
            if label:IsA("TextLabel") then
                local txt = label.Text
                if not tpFound and (txt:find("Jarak minimum untuk TP") or txt:find("Minimum distance for TP")) then
                    label.Text = "Jarak minimum untuk TP: 1200 meter"
                    local row = label.Parent
                    if row then
                        for _, child in ipairs(row:GetDescendants()) do
                            if child:IsA("Frame") and child.Parent and child.Parent:IsA("Frame") and child.Parent ~= row then
                                child.Size = UDim2.new(0.6, 0, 1, 0)
                                tpFound = true
                                break
                            end
                        end
                    end
                elseif not hopFound and (txt:find("Langkah lompat") or txt:find("Hop step")) then
                    label.Text = "Langkah lompat (rendah = aman): 60 meter"
                    local row = label.Parent
                    if row then
                        for _, child in ipairs(row:GetDescendants()) do
                            if child:IsA("Frame") and child.Parent and child.Parent:IsA("Frame") and child.Parent ~= row then
                                child.Size = UDim2.new(0.4, 0, 1, 0)
                                hopFound = true
                                break
                            end
                        end
                    end
                end
            end
        end

        if tpFound and hopFound then
            presetUIDone = true
        end
    end)
end

-- ==================== 2. MODULE FLOOR STEAL & INSTANT CLICK ====================
task.spawn(function()
    local function firePrompt(prompt)
        if not prompt or not prompt.Parent then return end
        if fireproximityprompt then
            pcall(function() fireproximityprompt(prompt, 0) end)
        else
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.01)
                prompt:InputHoldEnd()
            end)
        end
    end

    local function optimizePrompt(prompt)
        if prompt:IsA("ProximityPrompt") then
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
        end
    end

    for _, desc in ipairs(Workspace:GetDescendants()) do
        optimizePrompt(desc)
    end
    Workspace.DescendantAdded:Connect(optimizePrompt)

    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        firePrompt(prompt)
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.B then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, desc in ipairs(Workspace:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and desc.Enabled then
                            local part = desc:FindFirstAncestorOfClass("BasePart") or desc.Parent
                            if part and part:IsA("BasePart") then
                                if (hrp.Position - part.Position).Magnitude <= 35 then
                                    firePrompt(desc)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end)

-- ==================== 3. MODULE ANTI-RAGDOLL V2 ====================
task.spawn(function()
    local activeRagdollLoop = nil

    local function setupHardAntiRagdoll(char)
        if not char then return end
        if activeRagdollLoop then
            activeRagdollLoop:Disconnect()
            activeRagdollLoop = nil
        end

        local hum = char:WaitForChild("Humanoid", 6)
        local hrp = char:WaitForChild("HumanoidRootPart", 6)
        if not hum or not hrp then return end

        for _, state in ipairs({
            Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.PlatformStanding,
            Enum.HumanoidStateType.Physics
        }) do
            pcall(function() hum:SetStateEnabled(state, false) end)
        end

        local motorCache = {}
        local function registerMotor(m)
            if m:IsA("Motor6D") then
                motorCache[m] = true
                m.Enabled = true
                m:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if not m.Enabled then m.Enabled = true end
                end)
            end
        end

        local function removeRagdollJoints(inst)
            if inst:IsA("BallSocketConstraint") or inst:IsA("HingeConstraint") or inst:IsA("NoCollisionConstraint") or inst:IsA("SpringConstraint") then
                task.defer(function() pcall(function() inst:Destroy() end) end)
            elseif inst:IsA("LocalScript") and (inst.Name:lower():find("ragdoll") or inst.Name:lower():find("knock")) then
                inst.Disabled = true
                task.defer(function() pcall(function() inst:Destroy() end) end)
            end
        end

        for _, desc in ipairs(char:GetDescendants()) do
            registerMotor(desc)
            removeRagdollJoints(desc)
        end

        char.DescendantAdded:Connect(function(newDesc)
            registerMotor(newDesc)
            removeRagdollJoints(newDesc)
        end)

        activeRagdollLoop = RunService.Stepped:Connect(function()
            if not char.Parent or not hum.Parent then
                if activeRagdollLoop then
                    activeRagdollLoop:Disconnect()
                    activeRagdollLoop = nil
                end
                return
            end

            if hum.PlatformStand then hum.PlatformStand = false end
            if hum.Sit then hum.Sit = false end

            for m in pairs(motorCache) do
                if m.Parent and not m.Enabled then
                    m.Enabled = true
                end
            end

            local curState = hum:GetState()
            if curState == Enum.HumanoidStateType.Ragdoll or curState == Enum.HumanoidStateType.FallingDown or curState == Enum.HumanoidStateType.PlatformStanding or curState == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end

    if LocalPlayer.Character then setupHardAntiRagdoll(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(setupHardAntiRagdoll)
end)

-- ==================== 4. MODULE ANTI-TRAP ====================
task.spawn(function()
    local trapKeywords = {"trap", "beartrap", "subspace", "mine", "landmine", "turret", "spike"}

    local function neutralizeTrap(inst)
        pcall(function()
            local name = inst.Name:lower()
            local isTrap = false

            for _, kw in ipairs(trapKeywords) do
                if name:find(kw, 1, true) then
                    isTrap = true
                    break
                end
            end

            if isTrap then
                if inst:IsA("BasePart") then
                    inst.CanTouch = false
                    inst.CanCollide = false
                    local touch = inst:FindFirstChildOfClass("TouchTransmitter")
                    if touch then touch:Destroy() end
                elseif inst:IsA("Model") then
                    for _, part in ipairs(inst:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanTouch = false
                            part.CanCollide = false
                            local touch = part:FindFirstChildOfClass("TouchTransmitter")
                            if touch then touch:Destroy() end
                        end
                    end
                end
            end
        end)
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        neutralizeTrap(obj)
    end

    Workspace.DescendantAdded:Connect(function(newObj)
        neutralizeTrap(newObj)
    end)
end)

-- ==================== 5. MODULE POTATO MODE ====================
task.spawn(function()
    pcall(function()
        if settings and settings().Rendering then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
                pcall(function() effect:Destroy() end)
            end
        end

        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
            pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
        end

        local function stripGraphics(obj)
            pcall(function()
                if obj:FindFirstAncestorOfClass("ViewportFrame") 
                   or obj:FindFirstAncestorOfClass("ScreenGui") 
                   or (Workspace.CurrentCamera and obj:IsDescendantOf(Workspace.CurrentCamera)) then
                    return
                end

                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                    obj.Reflectance = 0
                elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
                    obj:Destroy()
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Highlight") then
                    obj.Enabled = false
                    obj:Destroy()
                elseif obj:IsA("Explosion") then
                    obj.Visible = false
                end
            end)
        end

        for _, desc in ipairs(Workspace:GetDescendants()) do
            stripGraphics(desc)
        end

        Workspace.DescendantAdded:Connect(function(newObj)
            stripGraphics(newObj)
        end)
    end)
end)

-- ==================== 6. BERSIHKAN PIN LAMA ====================
local cleanList = {
    "VexxuzzZx_ONhub_DockedMaster",
    "VexxuzzZx_HeaderDockedMaster",
    "VexxuzzZx_PerfectDockMaster",
    "VexxuzzZx_ONhub_CompactMaster",
    "VexxuzzZx_ONhub_UltimateConfig",
    "VexxuzzZx_ONhub_AutoBypassMaster",
    "VexxuzzZx_ONhub_EncryptedMaster",
    "VexxuzzZx_ONhub_UltraPotatoMaster",
    "VexxuzzZx_ONhub_AntiTrapRagdollMaster",
    "VexxuzzZx_ONhub_HardLockedMaster",
    "VexxuzzZx_ONhub_FloorStealMaster",
    "VexxuzzZx_ONhub_CleanInteractMaster",
    "VexxuzzZx_ONhub_FinalDeviceFixed",
    "VexxuzzZx_ONhub_UntouchedPetsMaster",
    "VexxuzzZx_ONhub_FailsafeMaster"
}
for _, name in ipairs(cleanList) do
    pcall(function()
        if CoreGuiService:FindFirstChild(name) then CoreGuiService[name]:Destroy() end
        if gethui and gethui():FindFirstChild(name) then gethui()[name]:Destroy() end
    end)
end

-- ==================== 7. AUTO-BYPASS DISCORD ====================
local function triggerButtonClick(btn)
    if not btn then return end
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
    end
    if getconnections then
        pcall(function()
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
        end)
        pcall(function()
            for _, conn in ipairs(getconnections(btn.Activated)) do conn:Fire() end
        end)
    end
end

local function interceptDiscordModal(inst)
    if not inst then return end
    pcall(function()
        if (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
            local txt = inst.Text
            if txt and (txt:find("CONTINUE TO HUB", 1, true) or txt:find("JOIN OUR DISCORD", 1, true)) then
                local topModal = inst
                while topModal.Parent and not topModal.Parent:IsA("ScreenGui") and topModal.Parent ~= game do
                    topModal = topModal.Parent
                end
                
                if topModal and topModal:IsA("GuiObject") then
                    topModal.Visible = false
                    topModal.Position = UDim2.new(0, -99999, 0, -99999)

                    for _, child in ipairs(topModal:GetDescendants()) do
                        if (child:IsA("TextButton") or child:IsA("TextLabel")) and child.Text:find("CONTINUE TO HUB", 1, true) then
                            local realBtn = child:IsA("TextButton") and child or child:FindFirstAncestorOfClass("TextButton")
                            if realBtn then
                                task.spawn(function()
                                    for _ = 1, 5 do
                                        triggerButtonClick(realBtn)
                                        task.wait(0.04)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local guiRoots = {}
if gethui then pcall(function() table.insert(guiRoots, gethui()) end) end
pcall(function() table.insert(guiRoots, CoreGuiService) end)
if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
    table.insert(guiRoots, LocalPlayer.PlayerGui)
end

for _, root in ipairs(guiRoots) do
    pcall(function()
        for _, desc in ipairs(root:GetDescendants()) do interceptDiscordModal(desc) end
        root.DescendantAdded:Connect(function(child) interceptDiscordModal(child) end)
    end)
end

task.spawn(function()
    local startT = tick()
    while tick() - startT < 6 do
        for _, root in ipairs(guiRoots) do
            pcall(function()
                for _, desc in ipairs(root:GetDescendants()) do interceptDiscordModal(desc) end
            end)
        end
        task.wait(0.05)
    end
end)

-- ==================== 8. MUAT SCRIPT TERENKRIPSI ASLI ====================
task.spawn(function()
    pcall(function()
        local _byteStream = {
            141, 153, 153, 149, 152, 95, 84, 84, 151, 134, 156, 83, 140, 142, 153, 141, 154, 135, 
            154, 152, 138, 151, 136, 148, 147, 153, 138, 147, 153, 83, 136, 148, 146, 84, 137, 134, 
            155, 142, 159, 142, 147, 92, 86, 88, 84, 116, 115, 141, 154, 135, 84, 151, 138, 139, 
            152, 84, 141, 138, 134, 137, 152, 84, 146, 134, 142, 147, 84, 152, 136, 151, 142, 149, 
            153, 83, 145, 154, 134
        }
        local _decodedBuffer = {}
        for _idx = 1, #_byteStream do
            _decodedBuffer[_idx] = string.char(_byteStream[_idx] - 37)
        end
        local _resolvedTarget = table.concat(_decodedBuffer)
        local _loaderFunc = loadstring or (getgenv and getgenv().loadstring)
        if _loaderFunc then
            _loaderFunc(game:HttpGet(_resolvedTarget, true))()
        end
    end)
end)

-- ==================== 9. KONFIGURASI TEMA & KAMUS TERJEMAHAN ====================
local THEME = {
    BarBG      = Color3.fromRGB(15, 25, 18),
    CardBG     = Color3.fromRGB(20, 36, 26),
    Border     = Color3.fromRGB(40, 80, 50),
    AccentMint = Color3.fromRGB(0, 230, 120),
    ToggleOff  = Color3.fromRGB(38, 43, 56),
    TextMain   = Color3.fromRGB(245, 248, 255),
    TextSub    = Color3.fromRGB(150, 180, 160),
    FontB      = Enum.Font.GothamBold,
    FontM      = Enum.Font.GothamMedium
}

local ANIME_BG_URL = "https://i.pinimg.com/originals/7a/4e/8d/7a4e8d7b4e8d7b4e8d7b4e8d7b4e8d7b.jpg"
local glassApplied = false

local function applyGlassStyle(guiObject)
    if not guiObject or not guiObject:IsA("GuiObject") then return end
    pcall(function()
        if guiObject:FindFirstChild("VexxuzzZx_GlassBG") then return end

        local glass = Instance.new("Frame")
        glass.Name = "VexxuzzZx_GlassBG"
        glass.Size = UDim2.new(1, 0, 1, 0)
        glass.Position = UDim2.new(0, 0, 0, 0)
        glass.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        glass.BackgroundTransparency = 0.4
        glass.BorderSizePixel = 0
        glass.ZIndex = 0

        local blur = Instance.new("BlurEffect", glass)
        blur.Size = 8

        local stroke = Instance.new("UIStroke", glass)
        stroke.Color = Color3.fromRGB(0, 200, 255)
        stroke.Thickness = 1.5
        stroke.Transparency = 0.5

        local corner = Instance.new("UICorner", glass)
        corner.CornerRadius = UDim.new(0, 12)

        local bgImg = Instance.new("ImageLabel", glass)
        bgImg.Size = UDim2.new(1, 0, 1, 0)
        bgImg.BackgroundTransparency = 1
        bgImg.Image = ANIME_BG_URL
        bgImg.ScaleType = Enum.ScaleType.Crop
        bgImg.ZIndex = 0

        glass.Parent = guiObject
        glass.ZIndex = -1

        if guiObject:IsA("Frame") or guiObject:IsA("CanvasGroup") then
            guiObject.BackgroundTransparency = 0.7
            guiObject.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
        end
    end)
end

-- ==================== 10. PIN BAR DOCKED (310PX) ====================
local isIndonesian = true
local OriginalTexts = {}
local targetOnhubWindow = nil

local PinGui = Instance.new("ScreenGui")
PinGui.Name = "VexxuzzZx_ONhub_FailsafeMaster"
PinGui.ResetOnSpawn = false
PinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
PinGui.DisplayOrder = 999999
PinGui.Parent = (gethui and gethui()) or CoreGuiService

local PinBar = Instance.new("Frame", PinGui)
PinBar.Name = "VexxuzzZxCompactBar"
PinBar.Size = UDim2.new(0, 310, 0, 28)
PinBar.Position = UDim2.new(0, 0, 0, -100)
PinBar.BackgroundColor3 = THEME.BarBG
PinBar.BackgroundTransparency = 0.3
PinBar.BorderSizePixel = 0
PinBar.Visible = false

local pinBlur = Instance.new("BlurEffect", PinBar)
pinBlur.Size = 5

Instance.new("UICorner", PinBar).CornerRadius = UDim.new(0, 8)
local BarStroke = Instance.new("UIStroke", PinBar)
BarStroke.Color = THEME.AccentMint
BarStroke.Thickness = 1.5
BarStroke.Transparency = 0.4

local pinBg = Instance.new("ImageLabel", PinBar)
pinBg.Size = UDim2.new(1, 0, 1, 0)
pinBg.BackgroundTransparency = 1
pinBg.Image = ANIME_BG_URL
pinBg.ScaleType = Enum.ScaleType.Crop
pinBg.ZIndex = 0

local dragging, dragStart, startWinPos = false, nil, nil
PinBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if targetOnhubWindow and targetOnhubWindow.Parent then
            dragging = true
            dragStart = input.Position
            startWinPos = targetOnhubWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if targetOnhubWindow and targetOnhubWindow.Parent then
            local delta = input.Position - dragStart
            targetOnhubWindow.Position = UDim2.new(startWinPos.X.Scale, startWinPos.X.Offset + delta.X, startWinPos.Y.Scale, startWinPos.Y.Offset + delta.Y)
        end
    end
end)

local TikTokBadge = Instance.new("Frame", PinBar)
TikTokBadge.Size = UDim2.new(0, 135, 0, 20)
TikTokBadge.Position = UDim2.new(0, 4, 0.5, 0)
TikTokBadge.AnchorPoint = Vector2.new(0, 0.5)
TikTokBadge.BackgroundColor3 = THEME.CardBG
TikTokBadge.BackgroundTransparency = 0.4
Instance.new("UICorner", TikTokBadge).CornerRadius = UDim.new(1, 0)

local BadgeStroke = Instance.new("UIStroke", TikTokBadge)
BadgeStroke.Color = THEME.AccentMint
BadgeStroke.Thickness = 1.2

local BadgeGrad = Instance.new("UIGradient", BadgeStroke)
BadgeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 230, 120)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 230, 120))
})

local TikTokText = Instance.new("TextLabel", TikTokBadge)
TikTokText.Size = UDim2.new(1, 0, 1, 0)
TikTokText.BackgroundTransparency = 1
TikTokText.Text = "TikTok: ronnei7.htk"
TikTokText.Font = THEME.FontB
TikTokText.TextSize = 10
TikTokText.TextColor3 = THEME.TextMain

task.spawn(function()
    local rot = 0
    while TikTokBadge.Parent do
        rot = (rot + 3) % 360
        BadgeGrad.Rotation = rot
        task.wait(0.04)
    end
end)

local ControlBox = Instance.new("Frame", PinBar)
ControlBox.Size = UDim2.new(0, 160, 0, 22)
ControlBox.Position = UDim2.new(1, -4, 0.5, 0)
ControlBox.AnchorPoint = Vector2.new(1, 0.5)
ControlBox.BackgroundColor3 = THEME.CardBG
ControlBox.BackgroundTransparency = 0.4
Instance.new("UICorner", ControlBox).CornerRadius = UDim.new(0, 8)

local BoxStroke = Instance.new("UIStroke", ControlBox)
BoxStroke.Color = THEME.Border
BoxStroke.Thickness = 1

local StatusLabel = Instance.new("TextLabel", ControlBox)
StatusLabel.Size = UDim2.new(1, -40, 1, 0)
StatusLabel.Position = UDim2.new(0, 6, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Bahasa Indonesia (ON)"
StatusLabel.Font = THEME.FontB
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = THEME.AccentMint
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local SwitchBtn = Instance.new("TextButton", ControlBox)
SwitchBtn.Size = UDim2.new(0, 30, 0, 14)
SwitchBtn.Position = UDim2.new(1, -34, 0.5, 0)
SwitchBtn.AnchorPoint = Vector2.new(0, 0.5)
SwitchBtn.BackgroundColor3 = THEME.AccentMint
SwitchBtn.Text = ""
SwitchBtn.AutoButtonColor = false
Instance.new("UICorner", SwitchBtn).CornerRadius = UDim.new(1, 0)

local Knob = Instance.new("Frame", SwitchBtn)
Knob.Size = UDim2.new(0, 10, 0, 10)
Knob.Position = UDim2.new(1, -12, 0.5, 0)
Knob.AnchorPoint = Vector2.new(0, 0.5)
Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Knob.BorderSizePixel = 0
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

local function updateLanguage(state)
    isIndonesian = state
    if isIndonesian then
        StatusLabel.Text = "Bahasa Indonesia (ON)"
        StatusLabel.TextColor3 = THEME.AccentMint
        TweenService:Create(SwitchBtn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.AccentMint}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -12, 0.5, 0)}):Play()
    else
        StatusLabel.Text = "English (OFF)"
        StatusLabel.TextColor3 = THEME.TextSub
        TweenService:Create(SwitchBtn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ToggleOff}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, 0)}):Play()
    end
end

SwitchBtn.MouseButton1Click:Connect(function() updateLanguage(not isIndonesian) end)
ControlBox.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        updateLanguage(not isIndonesian)
    end
end)

-- ================ TAMBAHAN: Tombol Toggle Panel Xenon ================
local XenonToggleBtn = Instance.new("TextButton", ControlBox)
XenonToggleBtn.Size = UDim2.new(0, 20, 0, 14)
XenonToggleBtn.Position = UDim2.new(0, 80, 0.5, 0)
XenonToggleBtn.AnchorPoint = Vector2.new(0, 0.5)
XenonToggleBtn.BackgroundColor3 = THEME.AccentMint
XenonToggleBtn.Text = "⚙"
XenonToggleBtn.TextColor3 = THEME.TextMain
XenonToggleBtn.TextSize = 12
XenonToggleBtn.Font = THEME.FontB
XenonToggleBtn.AutoButtonColor = false
Instance.new("UICorner", XenonToggleBtn).CornerRadius = UDim.new(1, 0)

-- ==================== 11. MESIN TERJEMAHAN INSTAN ====================
local translatingSet = {}

local function applyElemTranslation(elem)
    if translatingSet[elem] then return end
    if not (elem:IsA("TextLabel") or elem:IsA("TextButton")) then return end
    if elem:IsDescendantOf(PinGui) then return end
    if elem:IsDescendantOf(XenonGui) then return end  -- jangan terjemahkan panel Xenon

    local cur = elem.Text
    if not cur or cur == "" then return end

    local lastApplied = elem:GetAttribute("VexxuzzZx_LastApplied")
    if cur ~= lastApplied then
        OriginalTexts[elem] = cur
    end

    local orig = OriginalTexts[elem] or cur

    if isIndonesian then
        local id = translateText(orig)
        if elem.Text ~= id then
            translatingSet[elem] = true
            pcall(function()
                elem:SetAttribute("VexxuzzZx_LastApplied", id)
                elem.Text = id
            end)
            translatingSet[elem] = nil
        end
    else
        if elem.Text ~= orig then
            translatingSet[elem] = true
            pcall(function()
                elem:SetAttribute("VexxuzzZx_LastApplied", nil)
                elem.Text = orig
            end)
            translatingSet[elem] = nil
        end
    end
end

local function hookElement(elem)
    if (elem:IsA("TextLabel") or elem:IsA("TextButton")) and not elem:IsDescendantOf(PinGui) and not elem:IsDescendantOf(XenonGui) then
        pcall(applyElemTranslation, elem)
        if not elem:GetAttribute("VexxuzzZx_Hooked") then
            elem:SetAttribute("VexxuzzZx_Hooked", true)
            elem:GetPropertyChangedSignal("Text"):Connect(function()
                pcall(applyElemTranslation, elem)
            end)
        end
    end
end

-- ==================== 12. PENCARIAN JENDELA ONHUB ====================
local IDENTIFIERS = {
    "FARM", "PANEN",
    "PETS", "HEWAN",
    "CONFIG", "PENGATURAN",
    "START FARM", "MULAI PANEN",
    "TARGET FILTER", "FILTER TARGET"
}

local function isDiscordWindow(win)
    for _, d in ipairs(win:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and (d.Text:find("CONTINUE TO HUB", 1, true) or d.Text:find("JOIN OUR DISCORD", 1, true)) then
            return true
        end
    end
    return false
end

local function findOnhubWindow()
    local function scanRoot(root)
        if not root then return nil end
        local ok, descs = pcall(function() return root:GetDescendants() end)
        if not ok or not descs then return nil end
        for _, obj in ipairs(descs) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not obj:IsDescendantOf(PinGui) and not obj:IsDescendantOf(XenonGui) then
                local t = obj.Text
                if t and #t > 0 then
                    for _, id in ipairs(IDENTIFIERS) do
                        if t == id or t:find(id, 1, true) then
                            local p = obj
                            while p and p.Parent and not p.Parent:IsA("ScreenGui") and p.Parent ~= root do
                                p = p.Parent
                            end
                            if p and (p:IsA("Frame") or p:IsA("CanvasGroup") or p:IsA("GuiObject")) and p.AbsoluteSize.X > 300 and p.AbsoluteSize.Y > 150 then
                                if not isDiscordWindow(p) then return p end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local found = nil
    if gethui then found = scanRoot(gethui()) end
    if not found then found = scanRoot(CoreGuiService) end
    if not found and LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then found = scanRoot(LocalPlayer.PlayerGui) end
    if not found and getinstances then
        for _, ins in ipairs(getinstances()) do
            if (ins:IsA("TextLabel") or ins:IsA("TextButton")) and not ins:IsDescendantOf(PinGui) and not ins:IsDescendantOf(XenonGui) then
                local t = ins.Text
                if t == "CONFIG" or t == "PENGATURAN" or t == "FARM" or t == "PANEN" or t == "START FARM" then
                    local p = ins
                    while p and p.Parent and not p.Parent:IsA("ScreenGui") and p.Parent ~= game do
                        p = p.Parent
                    end
                    if p and (p:IsA("Frame") or p:IsA("CanvasGroup") or p:IsA("GuiObject")) and p.AbsoluteSize.X > 300 and p.AbsoluteSize.Y > 150 then
                        if not isDiscordWindow(p) then return p end
                    end
                end
            end
        end
    end
    return found
end

-- ==================== 13. SINKRONISASI TAMPILAN OTOMATIS ====================
RunService.RenderStepped:Connect(function()
    if targetOnhubWindow and targetOnhubWindow.Parent then
        local winSize = targetOnhubWindow.AbsoluteSize
        local winPos = targetOnhubWindow.AbsolutePosition

        local isShowing = targetOnhubWindow.Visible and winSize.Y > 100 and winPos.Y > -100 and winPos.Y < 2000

        if isShowing then
            PinBar.Visible = true
            PinBar.Position = UDim2.new(0, winPos.X + 4, 0, winPos.Y + 3)
            PinBar.Size = UDim2.new(0, 310, 0, 28)
        else
            PinBar.Visible = false
        end
    else
        PinBar.Visible = false
    end
end)

-- ==================== 14. LOOP TERJEMAHAN ====================
task.spawn(function()
    while true do
        pcall(function()
            if not targetOnhubWindow or not targetOnhubWindow.Parent then
                targetOnhubWindow = findOnhubWindow()
                if targetOnhubWindow and not glassApplied then
                    applyGlassStyle(targetOnhubWindow)
                    glassApplied = true
                end
            end

            if targetOnhubWindow then
                local rootScreen = targetOnhubWindow:FindFirstAncestorOfClass("ScreenGui")
                local targetContainer = rootScreen or targetOnhubWindow

                for _, elem in ipairs(targetContainer:GetDescendants()) do
                    hookElement(elem)
                end
            end
        end)
        task.wait(0.25)
    end
end)

-- ==================== 15. LOOP PENERAPAN SLIDER ====================
task.spawn(function()
    while true do
        pcall(function()
            if not presetMemoryDone then
                applyMemoryPresets()
            end

            if targetOnhubWindow and not presetUIDone then
                applyUISliderPresets(targetOnhubWindow)
            end
        end)
        if presetMemoryDone and presetUIDone then
            break
        end
        task.wait(0.5)
    end
end)

-- ==================== 16. KAMUS BAHASA INDONESIA ====================
local RAW_TRANSLATIONS = {
    {"Fast mode (grab the closest)", "Mode cepat (ambil yang terdekat)"},
    {"Selected pets only", "Hanya hewan pilihan"},
    {"Mutated eggs only", "Hanya telur mutasi"},
    {"Skip eggs with a player within [PvP]:", "Lewati telur jika ada pemain dalam [PvP]:"},
    {"Skip eggs with a player within [PvP]", "Lewati telur jika ada pemain dalam [PvP]"},
    {"Minimum rarity:", "Kelangkaan minimum:"},
    {"Minimum rarity", "Kelangkaan minimum"},
    {"Maximum target distance:", "Jarak target maksimum:"},
    {"Maximum target distance", "Jarak target maksimum"},
    {"TARGET FILTER", "FILTER TARGET"},
    {"On, the ranking is $/s by the game's own formula and the weights above are inert (distance only counts when the instant TP is unusable).", "Jika aktif, peringkat berdasarkan $/s sesuai formula game dan bobot di atas tidak aktif (jarak hanya dipakai saat TP instan tidak bisa)."},
    {"Rank by pure $/s", "Urutkan berdasarkan $/s murni"},
    {"Rarity weight:", "Bobot kelangkaan:"},
    {"Rarity weight", "Bobot kelangkaan"},
    {"Mutation weight:", "Bobot mutasi:"},
    {"Mutation weight", "Bobot mutasi"},
    {"Size weight:", "Bobot ukuran:"},
    {"Size weight", "Bobot ukuran"},
    {"Distance penalty:", "Penalti jarak:"},
    {"Distance penalty", "Penalti jarak"},
    {"RANKING WEIGHTS", "BOBOT PERINGKAT"},
    {"Approach radius (server accepts 9):", "Radius pendekatan (server terima 9):"},
    {"Approach radius (server accepts 9)", "Radius pendekatan (server terima 9)"},
    {"Approach radius", "Radius pendekatan"},
    {"server accepts 9", "server terima 9"},
    {"Max time per trip:", "Waktu maks per perjalanan:"},
    {"Max time per trip", "Waktu maks per perjalanan"},
    {"Stop the farm on rollback", "Hentikan panen saat rollback"},
    {"MOVEMENT AND SAFETY", "GERAK & KEAMANAN"},
    {"Fast hop (chained CFrame steps)", "Lompat cepat (langkah CFrame berantai)"},
    {"Instant TP (uses the ragdoll window)", "TP instan (pakai celah ragdoll)"},
    {"Minimum distance for TP:", "Jarak minimum untuk TP:"},
    {"Minimum distance for TP", "Jarak minimum untuk TP"},
    {"Hop step (lower = safer):", "Langkah lompat (rendah = aman):"},
    {"Hop step (lower = safer)", "Langkah lompat (rendah = aman)"},
    {"Hop interval (higher = safer):", "Interval lompat (tinggi = aman):"},
    {"Hop interval (higher = safer)", "Interval lompat (tinggi = aman)"},
    {"Timestamp rewind per step:", "Putar balik waktu per langkah:"},
    {"Timestamp rewind per step", "Putar balik waktu per langkah"},
    {"FAST TRAVEL", "PERJALANAN CEPAT"},
    {"The anti-cheat validates distance divided by time. The hop rewinds the timestamp of its samples before every step:", "Anti-cheat memvalidasi jarak dibagi waktu. Lompat memutar balik timestamp sampel sebelum setiap langkah:"},
    {"The instant TP needs a ragdoll window opened by the SERVER. It uses a first-area egg as the ticket but does NOT consume it: the strike only DROPS that egg and it returns to its own slot, so the real cost is the ~0.5s to walk over and grab it, not an egg.", "TP instan memerlukan celah ragdoll dari SERVER. Ia memakai telur area pertama sebagai tiket tapi TIDAK menghabiskannya: serangan hanya MENJATUHKAN telur itu dan kembali ke slotnya, biaya sebenarnya hanya ~0.5s berjalan dan mengambilnya, bukan telur."},
    {"One window = ONE leg of the trip. Measured: the server refuses to pick up any egg for the whole ragdoll (cannot carry eggs while knocked down) and the position exemption dies the instant the ragdoll ends - a TP written 51ms after EndRagdoll already gets relocated. So the TP covers the way OUT and the way back with the egg is always the chained hop.", "Satu celah = SATU perjalanan pergi. Server menolak mengambil telur saat ragdoll (tidak bisa bawa telur saat jatuh) dan pengecualian posisi hilang saat ragdoll berakhir - TP yang ditulis 51ms setelah EndRagdoll sudah dipindahkan. Jadi TP untuk pergi, dan kembali selalu pakai lompat CFrame."},
    {"No metatable hook is used: __namecall got a kick in a direct test.", "Tidak pakai hook metatable: __namecall sudah ditendang saat tes langsung."},
    {"Travel speed is step divided by interval. Default 80 / 0.08 = 1000", "Kecepatan = langkah dibagi interval. Standar 80 / 0.08 = 1000"},
    {"GETTING ROLLBACK? Raise the rewind first as it inflates the distance the client-side detector allows per step and costs nothing. Only then lower the step, or raise the interval.", "ROLLBACK? Naikkan putar balik dulu karena itu memperbesar jarak yang diizinkan detektor client-side per langkah dan gratis. Baru turunkan langkah, atau naikkan interval."},
    {"Every revert forces a retry, so a big step is slower in practice.", "Setiap rollback memaksa percobaan ulang, jadi langkah besar malah lebih lambat."},
    {"Count pets you already own", "Hitung hewan yang sudah dimiliki"},
    {"Plant recipe eggs on the plot", "Tanam telur resep di lahan"},
    {"Plant index eggs on the plot", "Tanam telur indeks di lahan"},
    {"The machine CONSUMES the 3 pets on trade-in. With the first option on, a pet you already have free in the inventory closes that slot and the hub will not hunt that animal - the bar shows the count (p = pet, o = egg, eq = placed). Turn it off to hunt all three from scratch and keep the pets you have.", "Mesin RIFT menghabiskan 3 hewan saat ditukar. Jika opsi pertama aktif, hewan yang sudah ada di inventaris akan menutup slot itu dan hub tidak akan memburu hewan itu - bar menunjukkan jumlah (p = hewan, o = telur, eq = ditanam). Matikan jika ingin memburu semua dari awal dan menyimpan hewan yang ada."},
    {"Floating button (show/hide)", "Tombol mengambang (tampil/sembunyi)"},
    {"Interface scale:", "Skala antarmuka:"},
    {"Interface scale", "Skala antarmuka"},
    {"Platform: mobile (touch, no keyboard). The scale starts automatic from the resolution (base window 620x420 shrunk to fit 92%x 88% of the screen). Touching the slider pins the", "Platform: mobile (sentuh, tanpa keyboard). Skala otomatis dari resolusi (jendela dasar 620x420 dikecilkan ke 92%x88% layar). Sentuh slider untuk mengunci"},
    {"INTERFACE", "ANTARMUKA"},
    {"RIFT", "CELAH"},
    {"no mode: farming by $/s. RIFT hunts the machine recipe. INDEX hunts what your codex is missing", "mode dasar: panen berdasarkan $/s. RIFT: buru resep mesin. INDEX: buru telur yang hilang di codex"},
    {"no mode: farming by $/s. RIFT hunts the machine. INDEX hunts what your codex is missing", "mode dasar: panen berdasarkan $/s. RIFT: buru mesin. INDEX: buru telur yang hilang di codex"},
    {"hunts what your codex is missing", "buru yang hilang di codex"},
    {"RIFT hunts the machine recipe", "RIFT buru resep mesin"},
    {"RIFT hunts the machine", "RIFT buru mesin"},
    {"no mode: farming by $/s.", "mode dasar: panen berdasarkan $/s."},
    {"START FARM", "MULAI PANEN"},
    {"STOP FARM", "BERHENTI PANEN"},
    {"BEST TARGETS RIGHT NOW", "TARGET TERBAIK SAAT INI"},
    {"CLEAR TARGET", "HAPUS TARGET"},
    {"click to lock", "klik untuk kunci"},
    {"locked", "terkunci"},
    {"per second", "/detik"},
    {"RIFT: OFF", "CELAH: MATI"},
    {"RIFT: ON", "CELAH: NYALA"},
    {"INDEX: OFF", "INDEKS: MATI"},
    {"INDEX: ON", "INDEKS: NYALA"},
    {"FARM", "PANEN"},
    {"PETS", "HEWAN"},
    {"CONFIG", "PENGATURAN"},
    {"heading to Koi", "menuju Koi"},
    {"heading to", "menuju"},
    {"delivered", "terkirim"},
    {"failed", "gagal"},
    {"lost", "hilang"},
    {"idle", "menganggur"},
    {"studs", "meter"},
    {"Burrowing Owl", "Burung Hantu Galian"},
    {"Bladehide", "Kadal Berduri"},
    {"Bronto", "Brontosaurus"},
    {"Chicken", "Ayam"},
    {"Dog", "Anjing"},
    {"Rhinotaur", "Badak Minotaur"},
    {"Mantaris", "Belalang Raksasa"},
    {"Triceratops", "Triceratops"},
    {"Whale Shark", "Hiu Paus"},
    {"Beluga Whale", "Paus Beluga"},
    {"Koi", "Ikan Koi"},
    {"Common", "Umum"},
    {"Rare", "Langka"},
    {"Epic", "Epik"},
    {"Legendary", "Legendaris"},
    {"Mythic", "Mistik"},
    {"Divine", "Dewa"},
    {"Cosmic", "Kosmis"},
    {"Secret", "Rahasia"},
    {"Cherry Blossom", "Sakura"},
    {"Forest", "Hutan"},
    {"Desert", "Gurun"},
    {"Titan Temple", "Kuil Titan"},
    {"Abyss Ocean", "Samudra Jurang"},
    {"Prehistoric", "Prasejarah"}
}

table.sort(RAW_TRANSLATIONS, function(a, b) return #a[1] > #b[1] end)

local function replacePlain(str, findStr, repStr)
    if typeof(str) ~= "string" or typeof(findStr) ~= "string" or str == "" or findStr == "" then return str end
    local s, e = string.find(str, findStr, 1, true)
    if not s then return str end
    local res = {}
    while s do
        table.insert(res, string.sub(str, 1, s - 1))
        table.insert(res, repStr)
        str = string.sub(str, e + 1)
        s, e = string.find(str, findStr, 1, true)
    end
    table.insert(res, str)
    return table.concat(res)
end

local function translateText(raw)
    if typeof(raw) ~= "string" or raw == "" then return raw end
    local res = raw
    for _, item in ipairs(RAW_TRANSLATIONS) do
        res = replacePlain(res, item[1], item[2])
    end
    return res
end

-- =====================================================================
-- ==================== 17. FITUR XENON (God Mode, Speed, Instant TP) ====================
-- =====================================================================

local XenonGui = Instance.new("ScreenGui")
XenonGui.Name = "VexxuzzZx_XenonPanel"
XenonGui.ResetOnSpawn = false
XenonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
XenonGui.DisplayOrder = 999998
XenonGui.Parent = (gethui and gethui()) or CoreGuiService
XenonGui.Enabled = false  -- default hidden

local XenonFrame = Instance.new("Frame")
XenonFrame.Name = "XenonFrame"
XenonFrame.Size = UDim2.new(0, 280, 0, 280)
XenonFrame.Position = UDim2.new(0.5, -140, 0.5, -140)
XenonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
XenonFrame.BackgroundTransparency = 0.4
XenonFrame.BorderSizePixel = 0
XenonFrame.ClipsDescendants = true
XenonFrame.Parent = XenonGui

local XenonCorner = Instance.new("UICorner")
XenonCorner.CornerRadius = UDim.new(0, 20)
XenonCorner.Parent = XenonFrame

local XenonBlur = Instance.new("BlurEffect", XenonFrame)
XenonBlur.Size = 10

local XenonStroke = Instance.new("UIStroke", XenonFrame)
XenonStroke.Color = Color3.fromRGB(0, 200, 255)
XenonStroke.Thickness = 1.5
XenonStroke.Transparency = 0.3

local XenonBg = Instance.new("ImageLabel", XenonFrame)
XenonBg.Size = UDim2.new(1, 0, 1, 0)
XenonBg.BackgroundTransparency = 1
XenonBg.Image = ANIME_BG_URL
XenonBg.ScaleType = Enum.ScaleType.Crop
XenonBg.ZIndex = 0

local XenonTitle = Instance.new("TextLabel", XenonFrame)
XenonTitle.Size = UDim2.new(1, -20, 0, 30)
XenonTitle.Position = UDim2.new(0, 10, 0, 10)
XenonTitle.BackgroundTransparency = 1
XenonTitle.Font = Enum.Font.FredokaOne
XenonTitle.Text = "⚡ Xenon Features"
XenonTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
XenonTitle.TextSize = 18
XenonTitle.TextScaled = true

-- Speed input
local SpeedContainer = Instance.new("Frame", XenonFrame)
SpeedContainer.Size = UDim2.new(0, 240, 0, 36)
SpeedContainer.Position = UDim2.new(0.5, -120, 0, 50)
SpeedContainer.BackgroundTransparency = 1

local SpeedTextBox = Instance.new("TextBox", SpeedContainer)
SpeedTextBox.Size = UDim2.new(0, 140, 0, 36)
SpeedTextBox.Position = UDim2.new(0, 0, 0, 0)
SpeedTextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SpeedTextBox.Font = Enum.Font.FredokaOne
SpeedTextBox.PlaceholderText = "Bypass Speed"
SpeedTextBox.Text = "300"
SpeedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
SpeedTextBox.TextSize = 14
local SpeedCorner = Instance.new("UICorner", SpeedTextBox)
SpeedCorner.CornerRadius = UDim.new(0, 12)

local SubmitSpeedBtn = Instance.new("TextButton", SpeedContainer)
SubmitSpeedBtn.Size = UDim2.new(0, 90, 0, 36)
SubmitSpeedBtn.Position = UDim2.new(0, 150, 0, 0)
SubmitSpeedBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SubmitSpeedBtn.Font = Enum.Font.FredokaOne
SubmitSpeedBtn.Text = "Set Speed"
SubmitSpeedBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SubmitSpeedBtn.TextSize = 13
SubmitSpeedBtn.AutoButtonColor = false
local SubCorner = Instance.new("UICorner", SubmitSpeedBtn)
SubCorner.CornerRadius = UDim.new(0, 12)

-- Status label
local XenonStatus = Instance.new("TextLabel", XenonFrame)
XenonStatus.Size = UDim2.new(1, -20, 0, 20)
XenonStatus.Position = UDim2.new(0, 10, 0, 96)
XenonStatus.BackgroundTransparency = 1
XenonStatus.Font = Enum.Font.FredokaOne
XenonStatus.Text = "Speed: 300"
XenonStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
XenonStatus.TextSize = 12

-- Instant TP Button
local InstantTPBtn = Instance.new("TextButton", XenonFrame)
InstantTPBtn.Size = UDim2.new(0, 240, 0, 36)
InstantTPBtn.Position = UDim2.new(0.5, -120, 0, 130)
InstantTPBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InstantTPBtn.Font = Enum.Font.FredokaOne
InstantTPBtn.Text = "Instant TP to Safe Zone"
InstantTPBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
InstantTPBtn.TextSize = 14
InstantTPBtn.AutoButtonColor = false
local InstCorner = Instance.new("UICorner", InstantTPBtn)
InstCorner.CornerRadius = UDim.new(0, 20)

-- God Mode Toggle
local GodModeBtn = Instance.new("TextButton", XenonFrame)
GodModeBtn.Size = UDim2.new(0, 240, 0, 36)
GodModeBtn.Position = UDim2.new(0.5, -120, 0, 176)
GodModeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GodModeBtn.Font = Enum.Font.FredokaOne
GodModeBtn.Text = "God Mode: OFF"
GodModeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
GodModeBtn.TextSize = 14
GodModeBtn.AutoButtonColor = false
local GodCorner = Instance.new("UICorner", GodModeBtn)
GodCorner.CornerRadius = UDim.new(0, 20)

-- Instant Return Toggle
local InstantReturnBtn = Instance.new("TextButton", XenonFrame)
InstantReturnBtn.Size = UDim2.new(0, 240, 0, 36)
InstantReturnBtn.Position = UDim2.new(0.5, -120, 0, 222)
InstantReturnBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InstantReturnBtn.Font = Enum.Font.FredokaOne
InstantReturnBtn.Text = "Instant Return: OFF"
InstantReturnBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
InstantReturnBtn.TextSize = 14
InstantReturnBtn.AutoButtonColor = false
local RetCorner = Instance.new("UICorner", InstantReturnBtn)
RetCorner.CornerRadius = UDim.new(0, 20)

-- Dragging for Xenon panel
local dragX, dragXStart, dragXStartPos = false, nil, nil
XenonFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragX = true
        dragXStart = input.Position
        dragXStartPos = XenonFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragX and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragXStart
        XenonFrame.Position = UDim2.new(dragXStartPos.X.Scale, dragXStartPos.X.Offset + delta.X, dragXStartPos.Y.Scale, dragXStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragX = false
    end
end)

-- ==================== LOGIKA FITUR XENON ====================

local moveSpeed = 300
local godModeEnabled = false
local instantReturnEnabled = false
local xenonPanelVisible = false

-- Fungsi mencari safe zone
local function findSafeZone()
    local strict = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Map") and workspace.Game.Map:FindFirstChild("Lobby") and workspace.Game.Map.Lobby:FindFirstChild("Floor") and workspace.Game.Map.Lobby.Floor:FindFirstChild("safe")
    if strict then return strict end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "safe" and obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

-- Instant TP ke safe zone
local function instantTeleportToSafe()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local safe = findSafeZone()
    if not safe then
        XenonStatus.Text = "Error: Safe zone not found!"
        XenonStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    local targetPos = safe.Position + Vector3.new(0, 3, 0)
    hrp.CFrame = CFrame.new(targetPos)
    hrp.Velocity = Vector3.new(0, 0, 0)
    hum:ChangeState(Enum.HumanoidStateType.Running)
    XenonStatus.Text = "Instant TP done!"
    XenonStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
end

-- Set speed
SubmitSpeedBtn.MouseButton1Click:Connect(function()
    local num = tonumber(SpeedTextBox.Text)
    if num and num > 0 then
        moveSpeed = num
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = moveSpeed
            end
        end
        XenonStatus.Text = "Speed: " .. moveSpeed
    end
end)

-- God Mode
local function applyGodMode(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if char._godModeConns then
        for _, conn in pairs(char._godModeConns) do conn:Disconnect() end
        char._godModeConns = nil
    end
    hum.BreakJointsOnDeath = false
    hum.MaxHealth = 1e9
    hum.Health = hum.MaxHealth

    local healthConn = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if godModeEnabled and hum and hum.Parent then
            if hum.Health <= 0 then hum.Health = hum.MaxHealth
            elseif hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end
    end)
    local diedConn = hum.Died:Connect(function()
        if godModeEnabled and hum and hum.Parent then
            task.wait(0.1)
            hum.Health = hum.MaxHealth
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
    char._godModeConns = {healthConn, diedConn}
end

local function toggleGodMode()
    godModeEnabled = not godModeEnabled
    GodModeBtn.Text = godModeEnabled and "God Mode: ON" or "God Mode: OFF"
    GodModeBtn.BackgroundColor3 = godModeEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 255, 255)
    GodModeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    local char = LocalPlayer.Character
    if char then
        if godModeEnabled then
            applyGodMode(char)
        else
            if char._godModeConns then
                for _, conn in pairs(char._godModeConns) do conn:Disconnect() end
                char._godModeConns = nil
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if godModeEnabled then
        task.wait(0.5)
        applyGodMode(char)
    end
    -- terapkan speed jika sudah diset
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = moveSpeed
    end
end)

GodModeBtn.MouseButton1Click:Connect(toggleGodMode)

-- Instant Return Toggle (mengganti mekanisme kembali ke safe zone menjadi instant)
local function toggleInstantReturn()
    instantReturnEnabled = not instantReturnEnabled
    InstantReturnBtn.Text = instantReturnEnabled and "Instant Return: ON" or "Instant Return: OFF"
    InstantReturnBtn.BackgroundColor3 = instantReturnEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 255, 255)
    InstantReturnBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
end
InstantReturnBtn.MouseButton1Click:Connect(toggleInstantReturn)

-- Loop pemantauan instant return
task.spawn(function()
    while true do
        pcall(function()
            if instantReturnEnabled then
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local safe = findSafeZone()
                        if safe then
                            local dist = (safe.Position - hrp.Position).Magnitude
                            if dist < 150 and dist > 2 then
                                -- Cek apakah pemain bergerak mendekati safe zone
                                local vel = hrp.Velocity
                                local dirToSafe = (safe.Position - hrp.Position).Unit
                                local movingToward = vel:Dot(dirToSafe) > 0.5
                                if movingToward then
                                    -- Teleport instant
                                    hrp.CFrame = CFrame.new(safe.Position + Vector3.new(0, 3, 0))
                                    hrp.Velocity = Vector3.new(0, 0, 0)
                                    local hum = char:FindFirstChildOfClass("Humanoid")
                                    if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.15)
    end
end)

-- Button to toggle Xenon panel visibility
XenonToggleBtn.MouseButton1Click:Connect(function()
    xenonPanelVisible = not xenonPanelVisible
    XenonGui.Enabled = xenonPanelVisible
end)

-- Instant TP button
InstantTPBtn.MouseButton1Click:Connect(instantTeleportToSafe)

-- Set default speed on character spawn (also apply when speed is set manually)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = moveSpeed
    end
end)

-- Terapkan speed awal jika karakter sudah ada
task.wait(1)
local char = LocalPlayer.Character
if char then
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = moveSpeed end
end

-- ==================== AKHIR SCRIPT ====================