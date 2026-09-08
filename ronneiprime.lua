-- VexxuzzZx HUB - Purple Glass UI Shell
-- UI-only shell: separates FARM / EGG / SYSTEM content and styles discovered panels.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local BRAND = {
    Name = "VexxuzzZx",
    Subtitle = "Purple Glass Hub",
    Version = "v1.0",
    Avatar = "rbxassetid://125111940452696",
    CardJpgUrl = "https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=1200&q=80",
}

local THEME = {
    Window = Color3.fromRGB(18, 10, 30),
    Panel = Color3.fromRGB(28, 15, 46),
    Card = Color3.fromRGB(42, 22, 68),
    Purple = Color3.fromRGB(154, 92, 255),
    Purple2 = Color3.fromRGB(104, 56, 196),
    Text = Color3.fromRGB(248, 244, 255),
    Muted = Color3.fromRGB(190, 170, 214),
    Stroke = Color3.fromRGB(129, 76, 220),
    Off = Color3.fromRGB(66, 45, 86),
}

local function resolveFont(weight)
    local ok, font = pcall(function()
        if getcustomasset then
            local asset = getcustomasset("MADEEvolveSansEVO.ttf")
            return Font.new(asset, weight, Enum.FontStyle.Normal)
        end
    end)
    if ok and font then return font end
    return weight == Enum.FontWeight.Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
end

local FONT_B = resolveFont(Enum.FontWeight.Bold)
local FONT_M = resolveFont(Enum.FontWeight.Medium)

for _, name in ipairs({"VexxuzzZx_Hub_UI", "VexxuzzZxHub_Master"}) do
    pcall(function()
        local old = CoreGui:FindFirstChild(name)
        if old then old:Destroy() end
        if gethui and gethui():FindFirstChild(name) then gethui()[name]:Destroy() end
    end)
end

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = obj
    return c
end

local function stroke(obj, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Stroke
    s.Transparency = transparency or 0
    s.Thickness = 1
    s.Parent = obj
    return s
end

local function glass(obj, bg, alpha)
    obj.BackgroundColor3 = bg or THEME.Card
    obj.BackgroundTransparency = alpha or 0.16
    obj.BorderSizePixel = 0
    corner(obj, 12)
    stroke(obj, THEME.Stroke, 0.18)
end

local function makeDraggable(handle, object)
    local dragging, start, startPos, inputRef
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            startPos = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            inputRef = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == inputRef then
            local d = input.Position - start
            object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function downloadCardJpg()
    if not (writefile and getcustomasset and game.HttpGet) then return nil end
    local path = "VexxuzzZx_card_bg.jpg"
    local ok, data = pcall(function()
        return game:HttpGet(BRAND.CardJpgUrl, true)
    end)
    if not ok or type(data) ~= "string" or #data < 100 then return nil end
    pcall(function() writefile(path, data) end)
    local assetOk, asset = pcall(function() return getcustomasset(path) end)
    if assetOk then return asset end
    return nil
end

local CARD_ASSET = downloadCardJpg()

local Gui = Instance.new("ScreenGui")
Gui.Name = "VexxuzzZx_Hub_UI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999999
Gui.Parent = CoreGui

local Toggle = Instance.new("ImageButton")
Toggle.Name = "VexxuzzZxToggle"
Toggle.Size = UDim2.fromOffset(52, 52)
Toggle.Position = UDim2.new(0, 18, 0, 160)
Toggle.Image = BRAND.Avatar
Toggle.AutoButtonColor = false
Toggle.Parent = Gui
glass(Toggle, THEME.Panel, 0.08)
local toggleStroke = stroke(Toggle, THEME.Purple, 0)
toggleStroke.Thickness = 2
corner(Toggle, 26)
makeDraggable(Toggle, Toggle)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(720, 460)
Main.Position = UDim2.new(0.5, -360, 0.5, -230)
Main.Parent = Gui
glass(Main, THEME.Window, 0.08)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 58)
Header.BackgroundTransparency = 1
Header.Parent = Main
makeDraggable(Header, Main)

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.fromOffset(38, 38)
Logo.Position = UDim2.fromOffset(12, 10)
Logo.BackgroundTransparency = 1
Logo.Image = BRAND.Avatar
Logo.Parent = Header
corner(Logo, 19)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.fromOffset(220, 25)
Title.Position = UDim2.fromOffset(60, 8)
Title.BackgroundTransparency = 1
Title.Text = BRAND.Name
Title.Font = FONT_B
Title.TextSize = 18
Title.TextColor3 = THEME.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.fromOffset(250, 18)
Subtitle.Position = UDim2.fromOffset(60, 31)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = BRAND.Subtitle .. " • " .. BRAND.Version
Subtitle.Font = FONT_M
Subtitle.TextSize = 11
Subtitle.TextColor3 = THEME.Muted
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 30)
Close.Position = UDim2.new(1, -42, 0, 14)
Close.Text = "×"
Close.Font = FONT_B
Close.TextSize = 18
Close.TextColor3 = THEME.Text
Close.AutoButtonColor = false
Close.Parent = Header
glass(Close, THEME.Card, 0.1)
Close.MouseButton1Click:Connect(function() Main.Visible = false end)
Toggle.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, -70)
Sidebar.Position = UDim2.fromOffset(10, 64)
Sidebar.Parent = Main
glass(Sidebar, THEME.Panel, 0.12)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -172, 1, -70)
Content.Position = UDim2.fromOffset(162, 64)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Parent = Main

local tabs = {
    {id="FARM", label="FARM", desc="Panel panen & otomatisasi"},
    {id="EGG", label="EGG", desc="Panel telur saja"},
    {id="SYSTEM", label="SISTEM", desc="Konfigurasi & informasi"},
}

local activeTab = "FARM"
local tabButtons = {}
local pages = {}

local function newPage(id)
    local page = Instance.new("ScrollingFrame")
    page.Name = id .. "Page"
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = THEME.Purple
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = Content
    pages[id] = page
    return page
end

for i, tab in ipairs(tabs) do
    local b = Instance.new("TextButton")
    b.Name = tab.id .. "Tab"
    b.Size = UDim2.new(1, -16, 0, 46)
    b.Position = UDim2.fromOffset(8, 12 + (i - 1) * 54)
    b.Text = tab.label
    b.Font = FONT_B
    b.TextSize = 13
    b.TextColor3 = THEME.Muted
    b.AutoButtonColor = false
    b.Parent = Sidebar
    glass(b, THEME.Card, 0.18)
    tabButtons[tab.id] = b
    newPage(tab.id)
end

local function addCard(page, title, description, keywordType)
    local card = Instance.new("Frame")
    card.Name = "Card_" .. title:gsub("%W", "_")
    card.Size = UDim2.new(1, -10, 0, 88)
    card.BackgroundColor3 = THEME.Card
    card.BackgroundTransparency = 0.16
    card.BorderSizePixel = 0
    card.Parent = page
    corner(card, 14)
    stroke(card, THEME.Stroke, 0.25)

    if CARD_ASSET then
        local bg = Instance.new("ImageLabel")
        bg.Name = "JpgBackground"
        bg.Size = UDim2.fromScale(1, 1)
        bg.BackgroundTransparency = 1
        bg.Image = CARD_ASSET
        bg.ImageTransparency = 0.78
        bg.ScaleType = Enum.ScaleType.Crop
        bg.ZIndex = 0
        bg.Parent = card
        corner(bg, 14)
    end

    local accent = Instance.new("Frame")
    accent.Size = UDim2.fromOffset(4, 54)
    accent.Position = UDim2.fromOffset(12, 17)
    accent.BackgroundColor3 = THEME.Purple
    accent.BorderSizePixel = 0
    accent.Parent = card
    corner(accent, 2)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -38, 0, 24)
    t.Position = UDim2.fromOffset(28, 13)
    t.BackgroundTransparency = 1
    t.Text = title
    t.Font = FONT_B
    t.TextSize = 14
    t.TextColor3 = THEME.Text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 2
    t.Parent = card

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -38, 0, 38)
    d.Position = UDim2.fromOffset(28, 38)
    d.BackgroundTransparency = 1
    d.Text = description
    d.Font = FONT_M
    d.TextSize = 11
    d.TextWrapped = true
    d.TextColor3 = THEME.Muted
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.ZIndex = 2
    d.Parent = card

    return card
end

local farmPage = pages.FARM
local eggPage = pages.EGG
local sysPage = pages.SYSTEM

addCard(farmPage, "Kontrol Farm", "Semua kontrol farming ditempatkan di menu FARM. Tidak ada panel telur di sini.", "farm")
addCard(farmPage, "Status Farming", "Status, target, dan konfigurasi farming tampil terpisah dari menu EGG.", "farm")
addCard(eggPage, "Egg Center", "Semua pengaturan dan informasi telur hanya berada di menu EGG.", "egg")
addCard(eggPage, "Daftar Telur", "Panel telur dipisahkan dari FARM agar navigasi tidak tercampur.", "egg")
addCard(sysPage, "Pengaturan Sistem", "Konfigurasi tampilan, font, notifikasi, dan status hub.", "system")
addCard(sysPage, "VexxuzzZx", "Purple Glass UI • MADE Evolve Sans EVO • Bahasa Indonesia", "system")

local function setPage(id)
    activeTab = id
    for key, page in pairs(pages) do page.Visible = key == id end
    for key, b in pairs(tabButtons) do
        local selected = key == id
        b.TextColor3 = selected and THEME.Text or THEME.Muted
        b.BackgroundColor3 = selected and THEME.Purple2 or THEME.Card
        local s = b:FindFirstChildOfClass("UIStroke")
        if s then s.Color = selected and THEME.Purple or THEME.Stroke end
    end
end

for id, b in pairs(tabButtons) do
    b.MouseButton1Click:Connect(function() setPage(id) end)
end
setPage(activeTab)

-- ---------------------------------------------------------------------------
-- Styling / isolation layer for an already-running game UI.
-- This deliberately does not execute remote scripts or add game exploits.
-- It only classifies visible GUI containers by their labels.
-- ---------------------------------------------------------------------------
local EGG_WORDS = {"egg", "eggs", "telur", "trứng", "mutation", "mutasi", "hatch"}
local FARM_WORDS = {"farm", "farming", "panen", "cày", "cash", "money", "income"}
local SYSTEM_WORDS = {"config", "pengaturan", "setting", "system", "sistem", "pet", "thú cưng"}

local function lower(s) return string.lower(tostring(s or "")) end
local function containsAny(text, words)
    text = lower(text)
    for _, w in ipairs(words) do if text:find(w, 1, true) then return true end end
    return false
end

local function guiText(root)
    local out = {}
    if root:IsA("TextLabel") or root:IsA("TextButton") or root:IsA("TextBox") then table.insert(out, root.Text) end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            local text = d.Text
            if text and text ~= "" then table.insert(out, text) end
        end
    end
    return table.concat(out, " ")
end

local function classify(root)
    local text = guiText(root)
    if containsAny(text, EGG_WORDS) then return "EGG" end
    if containsAny(text, FARM_WORDS) then return "FARM" end
    if containsAny(text, SYSTEM_WORDS) then return "SYSTEM" end
    return nil
end

local tracked = {}
local function trackGui(root)
    if not root or root == Gui or root:IsDescendantOf(Gui) then return end
    if not root:IsA("Frame") and not root:IsA("CanvasGroup") then return end
    local cls = classify(root)
    if not cls then return end
    tracked[root] = cls
end

local function scan()
    local roots = {CoreGui}
    if gethui then table.insert(roots, gethui()) end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then table.insert(roots, LocalPlayer.PlayerGui) end
    for _, root in ipairs(roots) do
        for _, obj in ipairs(root:GetDescendants()) do trackGui(obj) end
    end
end

local function applyIsolation()
    for obj, cls in pairs(tracked) do
        if not obj.Parent then tracked[obj] = nil else
            -- Only isolate obvious standalone containers. Never hide arbitrary controls.
            if obj.AbsoluteSize.X >= 260 and obj.AbsoluteSize.Y >= 100 then
                obj:SetAttribute("VexxuzzZxSection", cls)
            end
        end
    end
end

scan()
task.spawn(function()
    while Gui.Parent do
        pcall(function()
            scan()
            applyIsolation()
        end)
        task.wait(1)
    end
end)

-- Keep the shell responsive to spawn/resize without touching gameplay logic.
RunService.RenderStepped:Connect(function()
    if not Main.Parent then return end
    local camera = workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        if viewport.X < 760 then
            Main.Size = UDim2.new(1, -24, 0, math.min(460, viewport.Y - 40))
            Main.Position = UDim2.new(0, 12, 0.5, -Main.AbsoluteSize.Y / 2)
        else
            Main.Size = UDim2.fromOffset(720, 460)
            Main.Position = UDim2.new(0.5, -360, 0.5, -230)
        end
    end
end)
