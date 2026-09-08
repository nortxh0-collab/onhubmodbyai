-- ==============================================================================
--  RONNEI HUB - ONHUB MASTER (PRESET 1200m/60m + FAILSAFE TRANSLATOR)
--  Mặc định: TP 1200m | Hop 60m | Luồng dịch cách ly 100% | Giữ nguyên bảng Pet
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

-- ==================== 1. NẠP MẶC ĐỊNH 2 THANH TRƯỢT (BỘ NHỚ + GIAO DIỆN) ====================
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
                -- Thanh TP: 1200 mét
                if not tpFound and (txt:find("Khoảng cách tối thiểu để TP") or txt:find("Minimum distance for TP")) then
                    label.Text = "Khoảng cách tối thiểu để TP: 1200 mét"
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
                -- Thanh Hop: 60 mét
                elseif not hopFound and (txt:find("Độ dài bước nhảy") or txt:find("Hop step")) then
                    label.Text = "Độ dài bước nhảy (thấp = an toàn): 60 mét"
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

    -- Phím tắt B chủ động kích hoạt
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

-- ==================== 5. MODULE POTATO MODE (KHÔNG CAN THIỆP GIAO DIỆN PET) ====================
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

-- ==================== 6. DỌN SẠCH BẢN GHIM CŨ ====================
local cleanList = {
    "Ronnei_ONhub_DockedMaster",
    "Ronnei_HeaderDockedMaster",
    "Ronnei_PerfectDockMaster",
    "Ronnei_ONhub_CompactMaster",
    "Ronnei_ONhub_UltimateConfig",
    "Ronnei_ONhub_AutoBypassMaster",
    "Ronnei_ONhub_EncryptedMaster",
    "Ronnei_ONhub_UltraPotatoMaster",
    "Ronnei_ONhub_AntiTrapRagdollMaster",
    "Ronnei_ONhub_HardLockedMaster",
    "Ronnei_ONhub_FloorStealMaster",
    "Ronnei_ONhub_CleanInteractMaster",
    "Ronnei_ONhub_FinalDeviceFixed",
    "Ronnei_ONhub_UntouchedPetsMaster",
    "Ronnei_ONhub_FailsafeMaster"
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

-- ==================== 8. NẠP MÃ HÓA SCRIPT GỐC ====================
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

-- ==================== 9. CẤU HÌNH GIAO DIỆN & TỪ ĐIỂN DỊCH ====================
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

local RAW_TRANSLATIONS = {
    {"Fast mode (grab the closest)", "Chế độ nhanh (nhặt trứng gần nhất)"},
    {"Selected pets only", "Chỉ nhặt thú cưng đã chọn"},
    {"Mutated eggs only", "Chỉ nhặt trứng đột biến"},
    {"Skip eggs with a player within [PvP]:", "Bỏ qua trứng có người gần [PvP]:"},
    {"Skip eggs with a player within [PvP]", "Bỏ qua trứng có người gần [PvP]"},
    {"Minimum rarity:", "Độ hiếm tối thiểu:"},
    {"Minimum rarity", "Độ hiếm tối thiểu"},
    {"Maximum target distance:", "Khoảng cách mục tiêu tối đa:"},
    {"Maximum target distance", "Khoảng cách mục tiêu tối đa"},
    {"TARGET FILTER", "BỘ LỌC MỤC TIÊU"},
    {"On, the ranking is $/s by the game's own formula and the weights above are inert (distance only counts when the instant TP is unusable).", "Khi bật, mục tiêu xếp theo $/s theo công thức của game và các trọng số trên sẽ tắt (khoảng cách chỉ tính khi không thể dùng TP tức thì)."},
    {"Rank by pure $/s", "Ưu tiên thuần theo $/giây"},
    {"Rarity weight:", "Trọng số độ hiếm:"},
    {"Rarity weight", "Trọng số độ hiếm"},
    {"Mutation weight:", "Trọng số đột biến:"},
    {"Mutation weight", "Trọng số đột biến"},
    {"Size weight:", "Trọng số kích thước:"},
    {"Size weight", "Trọng số kích thước"},
    {"Distance penalty:", "Phạt khoảng cách:"},
    {"Distance penalty", "Phạt khoảng cách"},
    {"RANKING WEIGHTS", "TRỌNG SỐ ƯU TIÊN MỤC TIÊU"},
    {"Approach radius (server accepts 9):", "Bán kính tiếp cận (server nhận 9):"},
    {"Approach radius (server accepts 9)", "Bán kính tiếp cận (server nhận 9)"},
    {"Approach radius", "Bán kính tiếp cận"},
    {"server accepts 9", "server nhận 9"},
    {"Max time per trip:", "Thời gian tối đa mỗi chuyến:"},
    {"Max time per trip", "Thời gian tối đa mỗi chuyến"},
    {"Stop the farm on rollback", "Dừng cày khi bị giật lùi (rollback)"},
    {"MOVEMENT AND SAFETY", "DI CHUYỂN & AN TOÀN"},
    {"Fast hop (chained CFrame steps)", "Nhảy nhanh (bước CFrame liên tục)"},
    {"Instant TP (uses the ragdoll window)", "TP tức thì (dùng khe hở ragdoll)"},
    {"Minimum distance for TP:", "Khoảng cách tối thiểu để TP:"},
    {"Minimum distance for TP", "Khoảng cách tối thiểu để TP"},
    {"Hop step (lower = safer):", "Độ dài bước nhảy (thấp = an toàn):"},
    {"Hop step (lower = safer)", "Độ dài bước nhảy (thấp = an toàn)"},
    {"Hop interval (higher = safer):", "Thời gian chờ mỗi bước (cao = an toàn):"},
    {"Hop interval (higher = safer)", "Thời gian chờ mỗi bước (cao = an toàn)"},
    {"Timestamp rewind per step:", "Tua ngược thời gian mỗi bước:"},
    {"Timestamp rewind per step", "Tua ngược thời gian mỗi bước"},
    {"FAST TRAVEL", "DI CHUYỂN NHANH (TELEPORT)"},
    {"The anti-cheat validates distance divided by time. The hop rewinds the timestamp of its samples before every step:", "Chống hack kiểm tra khoảng cách chia cho thời gian. Bước nhảy tua lại mốc thời gian trước mỗi bước:"},
    {"The instant TP needs a ragdoll window opened by the SERVER. It uses a first-area egg as the ticket but does NOT consume it: the strike only DROPS that egg and it returns to its own slot, so the real cost is the ~0.5s to walk over and grab it, not an egg.", "TP tức thì cần khe hở ragdoll do SERVER mở. Nó dùng trứng khu 1 làm vé nhưng KHÔNG mất: đòn đánh chỉ làm RƠI trứng về chỗ cũ, chi phí thực chỉ là ~0.5s đi lại nhặt, không mất trứng."},
    {"One window = ONE leg of the trip. Measured: the server refuses to pick up any egg for the whole ragdoll (cannot carry eggs while knocked down) and the position exemption dies the instant the ragdoll ends - a TP written 51ms after EndRagdoll already gets relocated. So the TP covers the way OUT and the way back with the egg is always the chained hop.", "Một khe hở = 1 lượt đi. Server từ chối nhặt trứng khi đang ragdoll (không thể cầm trứng khi ngã) và quyền miễn trừ vị trí mất ngay khi hết ragdoll. TP dùng cho lượt ĐI, lượt VỀ luôn là nhảy CFrame."},
    {"No metatable hook is used: __namecall got a kick in a direct test.", "Không dùng hook metatable: __namecall đã bị kick khi thử nghiệm."},
    {"Travel speed is step divided by interval. Default 80 / 0.08 = 1000", "Tốc độ di chuyển = bước chia cho thời gian chờ. Mặc định 80 / 0.08 = 1000"},
    {"GETTING ROLLBACK? Raise the rewind first as it inflates the distance the client-side detector allows per step and costs nothing. Only then lower the step, or raise the interval.", "BỊ GIẬT LÙI? Hãy tăng tua ngược thời gian trước vì nó mở rộng khoảng cách cho phép mỗi bước. Sau đó mới giảm bước hoặc tăng thời gian chờ."},
    {"Every revert forces a retry, so a big step is slower in practice.", "Mỗi lần lùi phải thử lại nên bước lớn thực tế lại chậm hơn."},
    {"Count pets you already own", "Tính cả thú cưng bạn đã có"},
    {"Plant recipe eggs on the plot", "Đặt trứng công thức lên khu đất"},
    {"Plant index eggs on the plot", "Đặt trứng sưu tập lên khu đất"},
    {"The machine CONSUMES the 3 pets on trade-in. With the first option on, a pet you already have free in the inventory closes that slot and the hub will not hunt that animal - the bar shows the count (p = pet, o = egg, eq = placed). Turn it off to hunt all three from scratch and keep the pets you have.", "Máy RIFT sẽ TIÊU THỤ 3 thú cưng khi đổi. Bật tùy chọn đầu, thú cưng có sẵn trong túi sẽ lấp ô đó và hub không cần săn con đó nữa. Tắt đi nếu muốn săn mới cả 3 và giữ lại thú cưng đang có."},
    {"Floating button (show/hide)", "Nút tròn nổi (hiện/ẩn)"},
    {"Interface scale:", "Tỷ lệ giao diện:"},
    {"Interface scale", "Tỷ lệ giao diện"},
    {"Platform: mobile (touch, no keyboard). The scale starts automatic from the resolution (base window 620x420 shrunk to fit 92%x 88% of the screen). Touching the slider pins the", "Nền tảng: di động (cảm ứng, không phím). Tỷ lệ tự động theo độ phân giải màn hình (cửa sổ 620x420 thu gọn vừa 92%x 88% màn hình). Chạm thanh trượt để cố định"},
    {"INTERFACE", "GIAO DIỆN"},
    {"RIFT", "MÁY RIFT"},
    {"no mode: farming by $/s. RIFT hunts the machine recipe. INDEX hunts what your codex is missing", "Cơ bản: cày theo $/s. RIFT: săn công thức máy. SƯU TẬP: săn trứng thiếu"},
    {"no mode: farming by $/s. RIFT hunts the machine. INDEX hunts what your codex is missing", "Cơ bản: cày theo $/s. RIFT: săn máy. SƯU TẬP: săn trứng thiếu"},
    {"hunts what your codex is missing", "săn trứng còn thiếu"},
    {"RIFT hunts the machine recipe", "RIFT săn công thức máy"},
    {"RIFT hunts the machine", "RIFT săn máy"},
    {"no mode: farming by $/s.", "Cơ bản: cày theo $/s."},
    {"START FARM", "BẮT ĐẦU CÀY"},
    {"STOP FARM", "DỪNG CÀY"},
    {"BEST TARGETS RIGHT NOW", "MỤC TIÊU TỐT NHẤT HIỆN TẠI"},
    {"CLEAR TARGET", "HỦY MỤC TIÊU"},
    {"click to lock", "bấm để khóa"},
    {"locked", "đã khóa"},
    {"per second", "/giây"},
    {"RIFT: OFF", "RIFT: TẮT"},
    {"RIFT: ON", "RIFT: BẬT"},
    {"INDEX: OFF", "SƯU TẬP: TẮT"},
    {"INDEX: ON", "SƯU TẬP: BẬT"},
    {"FARM", "CÀY TIỀN"},
    {"PETS", "THÚ CƯNG"},
    {"CONFIG", "CẤU HÌNH"},
    {"heading to Koi", "Đang tới Cá Koi"},
    {"heading to", "Đang tới"},
    {"delivered", "đã giao"},
    {"failed", "thất bại"},
    {"lost", "mất"},
    {"idle", "đang chờ"},
    {"studs", "mét"},
    {"Burrowing Owl", "Cú Hang"},
    {"Bladehide", "Thằn Lằn Gai"},
    {"Bronto", "Khủng Long Cổ Dài"},
    {"Chicken", "Gà"},
    {"Dog", "Chó"},
    {"Rhinotaur", "Tê Giác Quái"},
    {"Mantaris", "Bọ Ngựa Quái"},
    {"Triceratops", "Khủng Long 3 Sừng"},
    {"Whale Shark", "Cá Mập Voi"},
    {"Beluga Whale", "Cá Voi Trắng"},
    {"Koi", "Cá Koi"},
    {"Common", "Thường"},
    {"Rare", "Hiếm"},
    {"Epic", "Sử Thi"},
    {"Legendary", "Huyền Thoại"},
    {"Mythic", "Thần Thoại"},
    {"Divine", "Thần Thánh"},
    {"Cosmic", "Vũ Trụ"},
    {"Secret", "Bí Mật"},
    {"Cherry Blossom", "Hoa Anh Đào"},
    {"Forest", "Rừng Rậm"},
    {"Desert", "Sa Mạc"},
    {"Titan Temple", "Đền Titan"},
    {"Abyss Ocean", "Biển Vực Sâu"},
    {"Prehistoric", "Tiền Sử"}
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

-- ==================== 10. TẠO THANH GHIM DOCKED (310PX) ====================
local isVietnamese = true
local OriginalTexts = {}
local targetOnhubWindow = nil

local PinGui = Instance.new("ScreenGui")
PinGui.Name = "Ronnei_ONhub_FailsafeMaster"
PinGui.ResetOnSpawn = false
PinGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
PinGui.DisplayOrder = 999999
PinGui.Parent = (gethui and gethui()) or CoreGuiService

local PinBar = Instance.new("Frame", PinGui)
PinBar.Name = "RonneiCompactBar"
PinBar.Size = UDim2.new(0, 310, 0, 28)
PinBar.Position = UDim2.new(0, 0, 0, -100)
PinBar.BackgroundColor3 = THEME.BarBG
PinBar.BorderSizePixel = 0
PinBar.Visible = false

Instance.new("UICorner", PinBar).CornerRadius = UDim.new(0, 6)
local BarStroke = Instance.new("UIStroke", PinBar)
BarStroke.Color = THEME.AccentMint
BarStroke.Thickness = 1.2

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
Instance.new("UICorner", ControlBox).CornerRadius = UDim.new(0, 6)

local BoxStroke = Instance.new("UIStroke", ControlBox)
BoxStroke.Color = THEME.Border
BoxStroke.Thickness = 1

local StatusLabel = Instance.new("TextLabel", ControlBox)
StatusLabel.Size = UDim2.new(1, -40, 1, 0)
StatusLabel.Position = UDim2.new(0, 6, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Tiếng Việt (ON)"
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
    isVietnamese = state
    if isVietnamese then
        StatusLabel.Text = "Tiếng Việt (ON)"
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

SwitchBtn.MouseButton1Click:Connect(function() updateLanguage(not isVietnamese) end)
ControlBox.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        updateLanguage(not isVietnamese)
    end
end)

-- ==================== 11. BỘ DỊCH TỨC THỜI (CÁCH LY AN TOÀN TUYỆT ĐỐI) ====================
local translatingSet = {}

local function applyElemTranslation(elem)
    if translatingSet[elem] then return end
    if not (elem:IsA("TextLabel") or elem:IsA("TextButton")) then return end
    if elem:IsDescendantOf(PinGui) then return end

    local cur = elem.Text
    if not cur or cur == "" then return end

    local lastApplied = elem:GetAttribute("Ronnei_LastApplied")
    if cur ~= lastApplied then
        OriginalTexts[elem] = cur
    end

    local orig = OriginalTexts[elem] or cur

    if isVietnamese then
        local vi = translateText(orig)
        if elem.Text ~= vi then
            translatingSet[elem] = true
            pcall(function()
                elem:SetAttribute("Ronnei_LastApplied", vi)
                elem.Text = vi
            end)
            translatingSet[elem] = nil
        end
    else
        if elem.Text ~= orig then
            translatingSet[elem] = true
            pcall(function()
                elem:SetAttribute("Ronnei_LastApplied", nil)
                elem.Text = orig
            end)
            translatingSet[elem] = nil
        end
    end
end

local function hookElement(elem)
    if (elem:IsA("TextLabel") or elem:IsA("TextButton")) and not elem:IsDescendantOf(PinGui) then
        pcall(applyElemTranslation, elem)
        if not elem:GetAttribute("Ronnei_Hooked") then
            elem:SetAttribute("Ronnei_Hooked", true)
            elem:GetPropertyChangedSignal("Text"):Connect(function()
                pcall(applyElemTranslation, elem)
            end)
        end
    end
end

-- ==================== 12. BỘ TÌM KIẾM CỬA SỔ ONHUB ====================
local IDENTIFIERS = {
    "FARM", "CÀY TIỀN",
    "PETS", "THÚ CƯNG",
    "CONFIG", "CẤU HÌNH",
    "START FARM", "BẮT ĐẦU CÀY",
    "TARGET FILTER", "BỘ LỌC MỤC TIÊU"
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
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not obj:IsDescendantOf(PinGui) then
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
            if (ins:IsA("TextLabel") or ins:IsA("TextButton")) and not ins:IsDescendantOf(PinGui) then
                local t = ins.Text
                if t == "CONFIG" or t == "CẤU HÌNH" or t == "FARM" or t == "CÀY TIỀN" or t == "START FARM" then
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

-- ==================== 13. ĐỒNG BỘ HIỂN THỊ TỰ ĐỘNG ====================
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

-- ==================== 14. VÒNG LẶP DỊCH RIÊNG BIỆT (KHÔNG BAO GIỜ BỊ CRASH) ====================
task.spawn(function()
    while true do
        pcall(function()
            if not targetOnhubWindow or not targetOnhubWindow.Parent then
                targetOnhubWindow = findOnhubWindow()
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

-- ==================== 15. VÒNG LẶP ÁP DỤNG THÔNG SỐ SLIDERS (ĐỘC LẬP) ====================
task.spawn(function()
    while true do
        pcall(function()
            -- Ép bộ nhớ bot chạy 1200 và 60
            if not presetMemoryDone then
                applyMemoryPresets()
            end

            -- Ép giao diện khi cửa sổ được mở
            if targetOnhubWindow and not presetUIDone then
                applyUISliderPresets(targetOnhubWindow)
            end
        end)
        if presetMemoryDone and presetUIDone then
            break -- Đã cài đặt xong hoàn toàn, tự giải phóng vòng lặp
        end
        task.wait(0.5)
    end
end)
