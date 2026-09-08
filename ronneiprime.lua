-- ==============================================================================
--  RONNEI HUB - 100% EVENT-DRIVEN ARCHITECTURE (ZERO LAG & INSTANT MODE ADAPT)
--  Theme: Luxury Obsidian & Cyber Mint
-- ==============================================================================

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Dọn dẹp phiên bản cũ
if CoreGui:FindFirstChild("RonneiHub_Master") then
    CoreGui.RonneiHub_Master:Destroy()
end

local BRAND = {
    Name       = "Ronnei Hub",
    SubTitle   = "v1.0 • Steal An Egg",
    Avatar     = "rbxassetid://125111940452696",
    TikTokTag  = "TikTok: ronnei7.htk"
}

local THEME = {
    WindowBG    = Color3.fromRGB(14, 16, 22),       -- Nền Obsidian tối sâu
    SidebarBG   = Color3.fromRGB(10, 12, 16),       -- Nền Sidebar kính mờ
    CardBG      = Color3.fromRGB(22, 26, 36),       -- Nền thẻ tính năng
    Border      = Color3.fromRGB(45, 55, 75),       -- Viền kim loại mảnh
    AccentMint  = Color3.fromRGB(0, 230, 120),      -- Xanh ngọc lục bảo (Cyber Mint)
    TextMain    = Color3.fromRGB(245, 248, 255),    -- Chữ chính
    TextSub     = Color3.fromRGB(150, 160, 180),    -- Chữ phụ
    FontM       = Enum.Font.GothamMedium,
    FontB       = Enum.Font.GothamBold
}

-- Hàm kéo thả giao diện mượt mà
local function makeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==================== SCREEN GUI CHÍNH ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RonneiHub_Master"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Nút Avatar tròn mở Menu ngoài màn hình
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "RonneiAvatarToggle"
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 20, 0, 150)
ToggleBtn.BackgroundColor3 = THEME.WindowBG
ToggleBtn.Image = BRAND.Avatar
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = ScreenGui

Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = THEME.AccentMint
ToggleStroke.Thickness = 2.4
ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
makeDraggable(ToggleBtn, ToggleBtn)

-- Khung Menu Chính Ronnei Hub
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 380)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -190)
MainFrame.BackgroundColor3 = THEME.WindowBG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = THEME.Border
MainStroke.Thickness = 1.4
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Thanh Header
local Header = Instance.new("Frame", MainFrame)
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = THEME.SidebarBG
Header.BorderSizePixel = 0
Header.ZIndex = 20
makeDraggable(Header, MainFrame)

local HeaderLine = Instance.new("Frame", Header)
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 1, 0)
HeaderLine.BackgroundColor3 = THEME.Border

local HeaderAvatar = Instance.new("ImageLabel", Header)
HeaderAvatar.Size = UDim2.new(0, 32, 0, 32)
HeaderAvatar.Position = UDim2.new(0, 12, 0.5, 0)
HeaderAvatar.AnchorPoint = Vector2.new(0, 0.5)
HeaderAvatar.BackgroundTransparency = 1
HeaderAvatar.Image = BRAND.Avatar
Instance.new("UICorner", HeaderAvatar).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0, 130, 0, 18)
Title.Position = UDim2.new(0, 52, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = BRAND.Name
Title.Font = THEME.FontB
Title.TextSize = 15
Title.TextColor3 = THEME.AccentMint
Title.TextXAlignment = Enum.TextXAlignment.Left

local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size = UDim2.new(0, 130, 0, 14)
SubTitle.Position = UDim2.new(0, 52, 0, 26)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = BRAND.SubTitle
SubTitle.Font = THEME.FontM
SubTitle.TextSize = 10
SubTitle.TextColor3 = THEME.TextSub
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Huy hiệu TikTok phát sáng
local TikTokBadge = Instance.new("Frame", Header)
TikTokBadge.Name = "TikTokBadge"
TikTokBadge.Size = UDim2.new(0, 160, 0, 24)
TikTokBadge.Position = UDim2.new(0.53, 0, 0.5, 0)
TikTokBadge.AnchorPoint = Vector2.new(0.5, 0.5)
TikTokBadge.BackgroundColor3 = THEME.CardBG
TikTokBadge.BorderSizePixel = 0
TikTokBadge.ZIndex = 25
Instance.new("UICorner", TikTokBadge).CornerRadius = UDim.new(1, 0)

local BadgeStroke = Instance.new("UIStroke", TikTokBadge)
BadgeStroke.Color = THEME.AccentMint
BadgeStroke.Thickness = 1.4
BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local TikTokLabel = Instance.new("TextLabel", TikTokBadge)
TikTokLabel.Size = UDim2.new(1, 0, 1, 0)
TikTokLabel.BackgroundTransparency = 1
TikTokLabel.Text = BRAND.TikTokTag
TikTokLabel.Font = THEME.FontB
TikTokLabel.TextSize = 11
TikTokLabel.TextColor3 = THEME.TextMain
TikTokLabel.ZIndex = 26

-- Thước đo FPS
local StatBadge = Instance.new("TextLabel", Header)
StatBadge.Size = UDim2.new(0, 100, 0, 22)
StatBadge.Position = UDim2.new(1, -75, 0.5, 0)
StatBadge.AnchorPoint = Vector2.new(1, 0.5)
StatBadge.BackgroundColor3 = THEME.CardBG
StatBadge.Font = THEME.FontM
StatBadge.TextSize = 11
StatBadge.TextColor3 = THEME.TextSub
StatBadge.Text = "60 FPS"
Instance.new("UICorner", StatBadge).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0.5, 0)
CloseBtn.AnchorPoint = Vector2.new(0, 0.5)
CloseBtn.BackgroundColor3 = THEME.CardBG
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = THEME.TextSub
CloseBtn.Font = THEME.FontB
CloseBtn.TextSize = 12
CloseBtn.ZIndex = 25
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- Sidebar & Vùng nội dung
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = THEME.SidebarBG
Sidebar.BorderSizePixel = 0

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -140, 1, -48)
ContentArea.Position = UDim2.new(0, 140, 0, 48)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = false

local MainTabBtn = Instance.new("TextButton", Sidebar)
MainTabBtn.Size = UDim2.new(1, -16, 0, 36)
MainTabBtn.Position = UDim2.new(0, 8, 0, 12)
MainTabBtn.BackgroundColor3 = THEME.CardBG
MainTabBtn.Text = "  ⚡ Chức Năng"
MainTabBtn.Font = THEME.FontB
MainTabBtn.TextSize = 13
MainTabBtn.TextColor3 = THEME.AccentMint
MainTabBtn.TextXAlignment = Enum.TextXAlignment.Left
MainTabBtn.AutoButtonColor = false
Instance.new("UICorner", MainTabBtn).CornerRadius = UDim.new(0, 6)

-- Khởi chạy Lennon Hub gốc
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/lennonxscripts/lennonhub/main/stealaegg.lua"))()
    end)
end)

-- ==================== HỆ THỐNG XỬ LÝ SỰ KIỆN THỜI GIAN THỰC (EVENT-DRIVEN) ====================
local function applyLennonWindow(window)
    if not window or not window:IsA("Frame") then return end

    -- Ẩn Topbar cũ của Lennon (Logo Lennon, tiêu đề, nút Discord)
    for _, ch in ipairs(window:GetChildren()) do
        if ch:IsA("GuiObject") then
            local isOldHeader = false
            for _, s in ipairs(ch:GetDescendants()) do
                if s:IsA("TextLabel") and (s.Text == "BEST EGG SYSTEM" or s.Text == "LENNON HUB") then
                    isOldHeader = true
                    break
                end
            end
            if isOldHeader then
                ch.Visible = false
                ch.Size = UDim2.new(0, 0, 0, 0)
            end
        end
    end

    local stroke = window:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Enabled = false end

    window.Parent = ContentArea
    window.Draggable = false
    window.Active = false
    window.BackgroundTransparency = 1
    window.BorderSizePixel = 0
    window.ClipsDescendants = false
    window.Position = UDim2.new(0, 8, 0, 10)
    window.Size = UDim2.new(1, -16, 1, -20)
    window.Visible = MainFrame.Visible

    -- Định dạng các thẻ con tiệp với theme Obsidian
    for _, card in ipairs(window:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible and card.Size.Y.Offset > 25 then
            card.BackgroundColor3 = THEME.CardBG
            local cardStroke = card:FindFirstChildOfClass("UIStroke")
            if cardStroke then
                cardStroke.Color = THEME.Border
                cardStroke.Thickness = 1
            end
        end
    end

    -- Lắng nghe khi Ronnei Hub bật/tắt
    if not window:GetAttribute("Synced") then
        window:SetAttribute("Synced", true)
        MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
            if window.Parent == ContentArea then
                window.Visible = MainFrame.Visible
            end
        end)
    end
end

-- Lắng nghe mọi khung mới sinh ra (Xử lý triệt để việc đổi chế độ ⇄ tái tạo khung)
local function hookContainer(container)
    container.DescendantAdded:Connect(function(desc)
        if desc:IsA("TextLabel") and (desc.Text == "BEST EGG SYSTEM" or desc.Text == "TELEGUIADO" or desc.Text == "TELEPORT") then
            local cur = desc
            while cur and cur.Parent and cur.Parent ~= container do
                cur = cur.Parent
            end
            if cur and cur:IsA("Frame") then
                task.defer(applyLennonWindow, cur)
            end
        elseif (desc:IsA("GuiButton") or desc:IsA("ImageLabel")) and desc.AbsoluteSize.X <= 90 and desc.AbsoluteSize.Y <= 90 then
            desc.Visible = false
            desc.Position = UDim2.new(0, -9999, 0, -9999)
        end
    end)
end

-- Kích hoạt bộ quét sự kiện trên mọi kho chứa GUI
local function initWatchers()
    local containers = {CoreGui}
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        table.insert(containers, LocalPlayer.PlayerGui)
    end
    if gethui then table.insert(containers, gethui()) end

    for _, cont in ipairs(containers) do
        for _, g in ipairs(cont:GetChildren()) do
            hookContainer(g)
        end
        cont.ChildAdded:Connect(function(newGui)
            task.wait(0.02)
            hookContainer(newGui)
        end)
    end
end

initWatchers()
