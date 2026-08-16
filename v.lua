-- Vf1>Zaid - Modern Roblox Utility Script
-- Features: ESP, Aimbot, Hitbox Expander, WalkSpeed, Fly, Custom Modern UI
-- Compatible with standard Luau environments
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
-- Destroy existing UI if running to allow hot-reloading
local coreGui = game:GetService("CoreGui")
local oldGui = coreGui:FindFirstChild("vf1") or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("vf1"))
if oldGui then
    oldGui:Destroy()
end
-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "vf1"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
-- Try to parent to CoreGui for safety from game scripts, fallback to PlayerGui
local successParent, errParent = pcall(function()
    ScreenGui.Parent = coreGui
end)
if not successParent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
-- ==========================================
-- STATE MANAGEMENT
-- ==========================================
local State = {
    Aimbot = false,
    AimbotPart = "Head",
    AimbotFOV = 150,
    AimbotSmoothing = 0.1, -- 0.1 is smooth, 0 is instant
    
    ESP = false,
    ESPColor = Color3.fromRGB(56, 189, 248),
    
    HitboxExpander = false,
    HitboxSize = 10,
    
    SpeedEnabled = false,
    WalkSpeed = 16,
    
    Fly = false,
    FlySpeed = 50
}
_G.R4LState = State
-- Original player hitbox states
local OriginalHitboxData = {}
-- Active ESP highlights
local ActiveESPHighlights = {}
-- ==========================================
-- UTILS & DESIGN SYSTEM
-- ==========================================
local Theme = {
    Background = Color3.fromRGB(11, 12, 16),
    Sidebar = Color3.fromRGB(14, 16, 22),
    Header = Color3.fromRGB(16, 18, 26),
    Accent = Color3.fromRGB(56, 189, 248),
    AccentSoft = Color3.fromRGB(14, 116, 144),
    AccentSecondary = Color3.fromRGB(99, 102, 241),
    CardBg = Color3.fromRGB(20, 22, 30),
    CardHover = Color3.fromRGB(26, 29, 40),
    Track = Color3.fromRGB(36, 40, 54),
    ToggleOff = Color3.fromRGB(42, 46, 60),
    Border = Color3.fromRGB(42, 47, 64),
    TextActive = Color3.fromRGB(244, 247, 252),
    TextMuted = Color3.fromRGB(132, 142, 162),
    Danger = Color3.fromRGB(248, 113, 113),
    FontMain = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold
}
local TweenFast = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenSnap = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local function tween(obj, props, info)
    local t = TweenService:Create(obj, info or TweenFast, props)
    t:Play()
    return t
end
local function createRound(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end
local function createStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end
local function createGradient(parent, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end
local function createPadding(parent, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end
-- ==========================================
-- MAIN FRAME CREATION
-- ==========================================
local WIN_W, WIN_H = 580, 430
local Holder = Instance.new("Frame")
Holder.Name = "WindowHolder"
Holder.Size = UDim2.new(0, WIN_W, 0, WIN_H)
Holder.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
Holder.BackgroundTransparency = 1
Holder.Parent = ScreenGui
-- Soft drop shadow (sibling so it is not clipped)
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 10)
Shadow.Size = UDim2.new(1, 80, 1, 80)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.42
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
Shadow.ZIndex = 0
Shadow.Parent = Holder
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = Holder
createRound(MainFrame, 16)
createStroke(MainFrame, Theme.Border, 1, 0.15)
local windowScale = Instance.new("UIScale")
windowScale.Scale = 1
windowScale.Parent = Holder
-- Accent hairline at top
local TopAccent = Instance.new("Frame")
TopAccent.Name = "TopAccent"
TopAccent.Size = UDim2.new(1, 0, 0, 2)
TopAccent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopAccent.BorderSizePixel = 0
TopAccent.ZIndex = 6
TopAccent.Parent = MainFrame
createGradient(TopAccent, Theme.Accent, Theme.AccentSecondary, 0)
local function setUIOpen(open)
    if open then
        Holder.Visible = true
        MainFrame.Visible = true
        windowScale.Scale = 0.94
        tween(windowScale, {Scale = 1}, TweenSnap)
    else
        local t = tween(windowScale, {Scale = 0.94}, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        t.Completed:Connect(function()
            if windowScale.Scale < 0.97 then
                Holder.Visible = false
                windowScale.Scale = 1
            end
        end)
    end
end
-- Floating Toggle Button
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.new(0, 52, 0, 52)
FloatingToggle.Position = UDim2.new(0, 22, 0.5, -26)
FloatingToggle.BackgroundColor3 = Theme.Sidebar
FloatingToggle.Text = ""
FloatingToggle.AutoButtonColor = false
FloatingToggle.Visible = false
FloatingToggle.Parent = ScreenGui
createRound(FloatingToggle, 16)
createStroke(FloatingToggle, Theme.Accent, 1.2, 0.25)
local FloatLabel = Instance.new("TextLabel")
FloatLabel.BackgroundTransparency = 1
FloatLabel.Size = UDim2.new(1, 0, 1, 0)
FloatLabel.Text = "VZ"
FloatLabel.TextColor3 = Theme.Accent
FloatLabel.Font = Theme.FontBold
FloatLabel.TextSize = 16
FloatLabel.Parent = FloatingToggle
FloatingToggle.MouseButton1Click:Connect(function()
    FloatingToggle.Visible = false
    setUIOpen(true)
end)
FloatingToggle.MouseEnter:Connect(function()
    tween(FloatingToggle, {BackgroundColor3 = Theme.CardHover})
end)
FloatingToggle.MouseLeave:Connect(function()
    tween(FloatingToggle, {BackgroundColor3 = Theme.Sidebar})
end)
local function hideWindow()
    setUIOpen(false)
    task.delay(0.16, function()
        if not Holder.Visible then
            FloatingToggle.Visible = true
        end
    end)
end
-- Hotkey to toggle UI
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        if Holder.Visible then
            hideWindow()
        else
            FloatingToggle.Visible = false
            setUIOpen(true)
        end
    end
end)
-- ==========================================
-- HEADER (drag handle)
-- ==========================================
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Theme.Header
Header.BorderSizePixel = 0
Header.ZIndex = 4
Header.Parent = MainFrame
local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 16)
HeaderCover.Position = UDim2.new(0, 0, 1, -16)
HeaderCover.BackgroundColor3 = Theme.Header
HeaderCover.BorderSizePixel = 0
HeaderCover.ZIndex = 4
HeaderCover.Parent = Header
-- Logo badge
local Logo = Instance.new("Frame")
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 30, 0, 30)
Logo.Position = UDim2.new(0, 14, 0.5, -15)
Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Logo.BorderSizePixel = 0
Logo.ZIndex = 5
Logo.Parent = Header
createRound(Logo, 8)
createGradient(Logo, Theme.Accent, Theme.AccentSecondary, 135)
local LogoText = Instance.new("TextLabel")
LogoText.BackgroundTransparency = 1
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.Text = "VZ"
LogoText.TextColor3 = Color3.fromRGB(8, 10, 16)
LogoText.Font = Theme.FontBold
LogoText.TextSize = 11
LogoText.ZIndex = 6
LogoText.Parent = Logo
local TitleCol = Instance.new("Frame")
TitleCol.BackgroundTransparency = 1
TitleCol.Position = UDim2.new(0, 52, 0, 8)
TitleCol.Size = UDim2.new(0, 220, 1, -10)
TitleCol.ZIndex = 5
TitleCol.Parent = Header
local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, 0, 0, 20)
TitleLabel.Text = "Vf1 > Zaid"
TitleLabel.TextColor3 = Theme.TextActive
TitleLabel.Font = Theme.FontBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 5
TitleLabel.Parent = TitleCol
local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 0, 0, 20)
Subtitle.Size = UDim2.new(1, 0, 0, 16)
Subtitle.Text = "Right Ctrl  ·  toggle menu"
Subtitle.TextColor3 = Theme.TextMuted
Subtitle.Font = Theme.FontMain
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 5
Subtitle.Parent = TitleCol
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -15)
CloseBtn.BackgroundColor3 = Theme.CardBg
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.TextMuted
CloseBtn.Font = Theme.FontBold
CloseBtn.TextSize = 18
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 6
CloseBtn.Parent = Header
createRound(CloseBtn, 8)
createStroke(CloseBtn, Theme.Border, 1, 0.35)
CloseBtn.MouseEnter:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(60, 22, 28), TextColor3 = Theme.Danger})
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseBtn, {BackgroundColor3 = Theme.CardBg, TextColor3 = Theme.TextMuted})
end)
CloseBtn.MouseButton1Click:Connect(hideWindow)
-- Drag from header only
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    Holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Holder.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)
-- ==========================================
-- SIDEBAR
-- ==========================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 148, 1, -52)
Sidebar.Position = UDim2.new(0, 0, 0, 52)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
local SideLine = Instance.new("Frame")
SideLine.Size = UDim2.new(0, 1, 1, 0)
SideLine.Position = UDim2.new(1, -1, 0, 0)
SideLine.BackgroundColor3 = Theme.Border
SideLine.BackgroundTransparency = 0.45
SideLine.BorderSizePixel = 0
SideLine.Parent = Sidebar
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 1, -48)
TabContainer.Position = UDim2.new(0, 0, 0, 10)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar
createPadding(TabContainer, 10, 0, 10, 0)
local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabContainer
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)
local SideFooter = Instance.new("TextLabel")
SideFooter.BackgroundTransparency = 1
SideFooter.Size = UDim2.new(1, -16, 0, 32)
SideFooter.Position = UDim2.new(0, 8, 1, -40)
SideFooter.Text = "v2  ·  UI"
SideFooter.TextColor3 = Theme.TextMuted
SideFooter.Font = Theme.FontMain
SideFooter.TextSize = 11
SideFooter.TextXAlignment = Enum.TextXAlignment.Left
SideFooter.Parent = Sidebar
-- ==========================================
-- CONTAINER FOR TABS
-- ==========================================
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -160, 1, -68)
Container.Position = UDim2.new(0, 154, 0, 60)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame
-- Tab pages list
local Tabs = {}
local TabButtons = {}
local function createTabPage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Tab"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.ScrollBarImageTransparency = 0.35
    Page.Visible = false
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.CanvasPosition = Vector2.new(0, 0)
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.Parent = Container
    createPadding(Page, 2, 4, 10, 12)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = Page
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    Tabs[name] = Page
    return Page
end
-- ==========================================
-- UI CONTROLS CREATION FUNCTIONS
-- ==========================================
local function bindCardHover(frame, stroke)
    frame.Active = true
    frame.MouseEnter:Connect(function()
        tween(frame, {BackgroundColor3 = Theme.CardHover})
        if stroke then tween(stroke, {Color = Color3.fromRGB(70, 80, 110)}) end
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, {BackgroundColor3 = Theme.CardBg})
        if stroke then tween(stroke, {Color = Theme.Border}) end
    end)
end
local function createSection(page, text)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, -4, 0, 26)
    Section.BackgroundTransparency = 1
    Section.LayoutOrder = #page:GetChildren()
    Section.Parent = page
    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 3, 0, 12)
    AccentBar.Position = UDim2.new(0, 2, 0.5, -6)
    AccentBar.BackgroundColor3 = Theme.Accent
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Section
    createRound(AccentBar, 2)
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(1, -12, 1, 0)
    Label.Text = string.upper(text)
    Label.TextColor3 = Theme.TextMuted
    Label.Font = Theme.FontBold
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Section
end
local function createToggle(page, text, defaultState, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -4, 0, 48)
    ToggleFrame.BackgroundColor3 = Theme.CardBg
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.LayoutOrder = #page:GetChildren()
    ToggleFrame.Parent = page
    createRound(ToggleFrame, 12)
    local stroke = createStroke(ToggleFrame, Theme.Border, 1, 0.25)
    bindCardHover(ToggleFrame, stroke)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -78, 1, 0)
    Label.Position = UDim2.new(0, 16, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextActive
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Theme.FontMain
    Label.TextSize = 14
    Label.Parent = ToggleFrame
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 46, 0, 24)
    Button.Position = UDim2.new(1, -62, 0.5, -12)
    Button.BackgroundColor3 = defaultState and Theme.Accent or Theme.ToggleOff
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = ToggleFrame
    createRound(Button, 12)
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = UDim2.new(0, defaultState and 25 or 3, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.Parent = Button
    createRound(Circle, 9)
    local active = defaultState
    local function apply(state, animate)
        local targetPos = state and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local targetColor = state and Theme.Accent or Theme.ToggleOff
        if animate then
            tween(Circle, {Position = targetPos})
            tween(Button, {BackgroundColor3 = targetColor})
        else
            Circle.Position = targetPos
            Button.BackgroundColor3 = targetColor
        end
    end
    Button.MouseButton1Click:Connect(function()
        active = not active
        apply(active, true)
        callback(active)
    end)
end
local function createSlider(page, text, min, max, defaultVal, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, -4, 0, 64)
    SliderFrame.BackgroundColor3 = Theme.CardBg
    SliderFrame.BorderSizePixel = 0
    SliderFrame.LayoutOrder = #page:GetChildren()
    SliderFrame.Parent = page
    createRound(SliderFrame, 12)
    local stroke = createStroke(SliderFrame, Theme.Border, 1, 0.25)
    bindCardHover(SliderFrame, stroke)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.62, 0, 0, 22)
    Label.Position = UDim2.new(0, 16, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextActive
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Theme.FontMain
    Label.TextSize = 13
    Label.Parent = SliderFrame
    local ValueChip = Instance.new("Frame")
    ValueChip.Size = UDim2.new(0, 52, 0, 22)
    ValueChip.Position = UDim2.new(1, -68, 0, 8)
    ValueChip.BackgroundColor3 = Color3.fromRGB(14, 32, 44)
    ValueChip.BorderSizePixel = 0
    ValueChip.Parent = SliderFrame
    createRound(ValueChip, 7)
    createStroke(ValueChip, Theme.Accent, 1, 0.65)
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(1, 0, 1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(defaultVal)
    ValueLabel.TextColor3 = Theme.Accent
    ValueLabel.Font = Theme.FontBold
    ValueLabel.TextSize = 12
    ValueLabel.Parent = ValueChip
    local Track = Instance.new("TextButton")
    Track.Size = UDim2.new(1, -32, 0, 8)
    Track.Position = UDim2.new(0, 16, 0, 40)
    Track.BackgroundColor3 = Theme.Track
    Track.BorderSizePixel = 0
    Track.Text = ""
    Track.AutoButtonColor = false
    Track.Parent = SliderFrame
    createRound(Track, 4)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    createRound(Fill, 4)
    createGradient(Fill, Theme.Accent, Theme.AccentSecondary, 0)
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new((defaultVal - min) / (max - min), -7, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 2
    Knob.Parent = Track
    createRound(Knob, 7)
    createStroke(Knob, Theme.Accent, 2, 0.15)
    local draggingSlider = false
    local function updateSlider(input)
        local relativeX = input.Position.X - Track.AbsolutePosition.X
        local percentage = math.clamp(relativeX / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + percentage * (max - min))
        ValueLabel.Text = tostring(val)
        Fill.Size = UDim2.new(percentage, 0, 1, 0)
        Knob.Position = UDim2.new(percentage, -7, 0.5, -7)
        callback(val)
    end
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            updateSlider(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
end
local function createDropdown(page, text, options, defaultOpt, callback)
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Size = UDim2.new(1, -4, 0, 48)
    DropdownFrame.BackgroundColor3 = Theme.CardBg
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.LayoutOrder = #page:GetChildren()
    DropdownFrame.Parent = page
    DropdownFrame.ClipsDescendants = false
    DropdownFrame.ZIndex = 8
    createRound(DropdownFrame, 12)
    local stroke = createStroke(DropdownFrame, Theme.Border, 1, 0.25)
    bindCardHover(DropdownFrame, stroke)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.48, 0, 1, 0)
    Label.Position = UDim2.new(0, 16, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextActive
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Theme.FontMain
    Label.TextSize = 14
    Label.Parent = DropdownFrame
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 138, 0, 28)
    Button.Position = UDim2.new(1, -152, 0, 10)
    Button.BackgroundColor3 = Theme.Track
    Button.Text = defaultOpt
    Button.TextColor3 = Theme.TextActive
    Button.Font = Theme.FontMain
    Button.TextSize = 12
    Button.AutoButtonColor = false
    Button.ZIndex = 9
    Button.Parent = DropdownFrame
    createRound(Button, 8)
    createStroke(Button, Theme.Border, 1, 0.3)
    local Chevron = Instance.new("TextLabel")
    Chevron.BackgroundTransparency = 1
    Chevron.Size = UDim2.new(0, 16, 1, 0)
    Chevron.Position = UDim2.new(1, -18, 0, 0)
    Chevron.Text = "▾"
    Chevron.TextColor3 = Theme.TextMuted
    Chevron.Font = Theme.FontBold
    Chevron.TextSize = 12
    Chevron.ZIndex = 10
    Chevron.Parent = Button
    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(1, 0, 0, 0)
    ListFrame.Position = UDim2.new(0, 0, 1, 6)
    ListFrame.BackgroundColor3 = Theme.Header
    ListFrame.BorderSizePixel = 0
    ListFrame.Visible = false
    ListFrame.ZIndex = 20
    ListFrame.Parent = Button
    createRound(ListFrame, 8)
    createStroke(ListFrame, Theme.Accent, 1, 0.55)
    local optionLayout = Instance.new("UIListLayout")
    optionLayout.Parent = ListFrame
    optionLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local open = false
    local function rebuildOptions()
        for _, child in ipairs(ListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local count = 0
        for _, opt in ipairs(options) do
            count = count + 1
            local OptBtn = Instance.new("TextButton")
            OptBtn.Size = UDim2.new(1, 0, 0, 28)
            OptBtn.BackgroundColor3 = Color3.fromRGB(36, 42, 58)
            OptBtn.BackgroundTransparency = (opt == Button.Text) and 0.35 or 1
            OptBtn.BorderSizePixel = 0
            OptBtn.Text = "  " .. opt
            OptBtn.TextColor3 = (opt == Button.Text) and Theme.Accent or Theme.TextMuted
            OptBtn.Font = Theme.FontMain
            OptBtn.TextSize = 12
            OptBtn.TextXAlignment = Enum.TextXAlignment.Left
            OptBtn.AutoButtonColor = false
            OptBtn.ZIndex = 21
            OptBtn.Parent = ListFrame
            OptBtn.MouseButton1Click:Connect(function()
                Button.Text = opt
                open = false
                ListFrame.Visible = false
                DropdownFrame.Size = UDim2.new(1, -4, 0, 48)
                Chevron.Text = "▾"
                callback(opt)
            end)
            OptBtn.MouseEnter:Connect(function()
                OptBtn.BackgroundTransparency = 0.25
                OptBtn.TextColor3 = Theme.TextActive
            end)
            OptBtn.MouseLeave:Connect(function()
                local selected = (opt == Button.Text)
                OptBtn.BackgroundTransparency = selected and 0.35 or 1
                OptBtn.TextColor3 = selected and Theme.Accent or Theme.TextMuted
            end)
        end
        ListFrame.Size = UDim2.new(1, 0, 0, count * 28)
    end
    Button.MouseButton1Click:Connect(function()
        open = not open
        if open then
            rebuildOptions()
            DropdownFrame.Size = UDim2.new(1, -4, 0, 48 + ListFrame.AbsoluteSize.Y + 10)
            ListFrame.Visible = true
            Chevron.Text = "▴"
        else
            ListFrame.Visible = false
            DropdownFrame.Size = UDim2.new(1, -4, 0, 48)
            Chevron.Text = "▾"
        end
    end)
end
-- ==========================================
-- TAB SELECTION SYSTEM
-- ==========================================
local TabMeta = {
    Combat = {icon = "C", color = Color3.fromRGB(248, 113, 113)},
    Visuals = {icon = "V", color = Color3.fromRGB(56, 189, 248)},
    Movement = {icon = "M", color = Color3.fromRGB(52, 211, 153)}
}
local function showTab(name)
    for tabName, page in pairs(Tabs) do
        page.Visible = (tabName == name)
    end
    for btnName, tab in pairs(TabButtons) do
        local on = (btnName == name)
        tween(tab.Button, {BackgroundColor3 = on and Theme.CardBg or Theme.Sidebar})
        tween(tab.Label, {TextColor3 = on and Theme.TextActive or Theme.TextMuted})
        tween(tab.Indicator, {BackgroundTransparency = on and 0 or 1})
        tween(tab.IconStroke, {Transparency = on and 0.15 or 0.55})
    end
end
local function addTab(name)
    local Page = createTabPage(name)
    local meta = TabMeta[name] or {icon = string.sub(name, 1, 1), color = Theme.Accent}
    local Button = Instance.new("TextButton")
    Button.Name = name .. "TabBtn"
    Button.Size = UDim2.new(1, 0, 0, 40)
    Button.BackgroundColor3 = Theme.Sidebar
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.ZIndex = 2
    Button.Parent = TabContainer
    createRound(Button, 10)
    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 3, 0, 18)
    Indicator.Position = UDim2.new(0, 4, 0.5, -9)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BackgroundTransparency = 1
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Button
    createRound(Indicator, 2)
    local Icon = Instance.new("Frame")
    Icon.Size = UDim2.new(0, 22, 0, 22)
    Icon.Position = UDim2.new(0, 14, 0.5, -11)
    Icon.BackgroundColor3 = meta.color
    Icon.BackgroundTransparency = 0.82
    Icon.BorderSizePixel = 0
    Icon.Parent = Button
    createRound(Icon, 6)
    local IconStroke = createStroke(Icon, meta.color, 1, 0.55)
    local IconText = Instance.new("TextLabel")
    IconText.BackgroundTransparency = 1
    IconText.Size = UDim2.new(1, 0, 1, 0)
    IconText.Text = meta.icon
    IconText.TextColor3 = meta.color
    IconText.Font = Theme.FontBold
    IconText.TextSize = 11
    IconText.Parent = Icon
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 42, 0, 0)
    Label.Size = UDim2.new(1, -48, 1, 0)
    Label.Text = name
    Label.TextColor3 = Theme.TextMuted
    Label.Font = Theme.FontMain
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button
    TabButtons[name] = {
        Button = Button,
        Label = Label,
        Indicator = Indicator,
        IconStroke = IconStroke
    }
    Button.MouseEnter:Connect(function()
        if not Tabs[name].Visible then
            tween(Button, {BackgroundColor3 = Theme.CardBg})
        end
    end)
    Button.MouseLeave:Connect(function()
        if not Tabs[name].Visible then
            tween(Button, {BackgroundColor3 = Theme.Sidebar})
        end
    end)
    Button.MouseButton1Click:Connect(function()
        showTab(name)
    end)
end
-- Create Tabs
addTab("Combat")
addTab("Visuals")
addTab("Movement")
-- Default to Combat
showTab("Combat")
-- ==========================================
-- MOVEMENT FEATURES LOGIC
-- ==========================================
local MovementTab = Tabs["Movement"]
createSection(MovementTab, "Walk")
createToggle(MovementTab, "WalkSpeed", State.SpeedEnabled, function(val)
    State.SpeedEnabled = val
end)
createSlider(MovementTab, "Speed", 16, 200, State.WalkSpeed, function(val)
    State.WalkSpeed = val
end)
-- WalkSpeed Loop (RenderStepped-based to bypass game resets)
local speedConnection
speedConnection = RunService.RenderStepped:Connect(function()
    pcall(function()
        if not ScreenGui.Parent then
            if speedConnection then speedConnection:Disconnect() end
            return
        end
        if State.SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = State.WalkSpeed
        end
    end)
end)
createSection(MovementTab, "Flight")
local flyVelocity = nil
local flyGyro = nil
local flyConnection = nil
local function stopFlying()
    pcall(function()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if flyVelocity then
            flyVelocity:Destroy()
            flyVelocity = nil
        end
        if flyGyro then
            flyGyro:Destroy()
            flyGyro = nil
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end)
end
local function startFlying()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid then return end
    stopFlying()
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyVelocity.Parent = root
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyGyro.CFrame = root.CFrame
    flyGyro.Parent = root
    humanoid.PlatformStand = true
    local camera = workspace.CurrentCamera
    flyConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            if not State.Fly or not LocalPlayer.Character or not root or not humanoid then
                stopFlying()
                return
            end
            humanoid.PlatformStand = true
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            flyGyro.CFrame = camera.CFrame
            if moveDirection.Magnitude > 0 then
                flyVelocity.Velocity = moveDirection.Unit * State.FlySpeed
            else
                flyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    end)
end
createToggle(MovementTab, "Fly", State.Fly, function(val)
    State.Fly = val
    if val then
        startFlying()
    else
        stopFlying()
    end
end)
createSlider(MovementTab, "Fly Speed", 10, 300, State.FlySpeed, function(val)
    State.FlySpeed = val
end)
-- Re-run flying when player character respawns
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.Fly then
        startFlying()
    end
end)
-- ==========================================
-- VISUALS FEATURES LOGIC (ESP)
-- ==========================================
local VisualsTab = Tabs["Visuals"]
local function applyHighlight(plr)
    if plr == LocalPlayer then return end
    
    local function setupChar(char)
        if not char then return end
        
        -- Wait a bit for parts to load
        char:WaitForChild("HumanoidRootPart", 5)
        
        if not State.ESP then return end
        
        if ActiveESPHighlights[plr] then
            pcall(function() ActiveESPHighlights[plr]:Destroy() end)
        end
        
        local hl = Instance.new("Highlight")
        hl.Name = "R4L_ESP_Highlight"
        hl.FillColor = State.ESPColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
        
        ActiveESPHighlights[plr] = hl
    end
    
    plr.CharacterAdded:Connect(setupChar)
    if plr.Character then
        setupChar(plr.Character)
    end
end
local function cleanESP(plr)
    if ActiveESPHighlights[plr] then
        pcall(function() ActiveESPHighlights[plr]:Destroy() end)
        ActiveESPHighlights[plr] = nil
    end
end
local function updateESPState()
    if State.ESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            applyHighlight(plr)
        end
    else
        for plr, hl in pairs(ActiveESPHighlights) do
            pcall(function() hl:Destroy() end)
        end
        table.clear(ActiveESPHighlights)
    end
end
createSection(VisualsTab, "Players")
createToggle(VisualsTab, "Player Highlight ESP", State.ESP, function(val)
    State.ESP = val
    updateESPState()
end)
Players.PlayerAdded:Connect(function(plr)
    if State.ESP then
        applyHighlight(plr)
    end
end)
Players.PlayerRemoving:Connect(function(plr)
    cleanESP(plr)
end)
-- ==========================================
-- COMBAT FEATURES LOGIC (AIMBOT & HITBOX)
-- ==========================================
local CombatTab = Tabs["Combat"]
createSection(CombatTab, "Aim")
createToggle(CombatTab, "Aimbot  ·  hold RMB", State.Aimbot, function(val)
    State.Aimbot = val
end)
createDropdown(CombatTab, "Target part", {"Head", "HumanoidRootPart"}, State.AimbotPart, function(val)
    State.AimbotPart = val
end)
createSlider(CombatTab, "FOV radius", 50, 400, State.AimbotFOV, function(val)
    State.AimbotFOV = val
end)
createSlider(CombatTab, "Smoothness", 0, 95, math.floor(State.AimbotSmoothing * 100), function(val)
    State.AimbotSmoothing = val / 100
end)
-- Drawing FOV circle on screen if supported
local fovCircle = nil
local drawingSuccess, fovResult = pcall(function()
    local circle = Drawing.new("Circle")
    circle.Visible = false
    circle.Color = Theme.Accent
    circle.Thickness = 1
    pcall(function() circle.NumSides = 64 end)
    circle.Radius = State.AimbotFOV
    circle.Filled = false
    return circle
end)
if drawingSuccess then
    fovCircle = fovResult
end
local function getClosestPlayerToMouse()
    local targetPlr = nil
    local shortestDist = math.huge
    local camera = workspace.CurrentCamera
    local mouse = LocalPlayer:GetMouse()
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(State.AimbotPart) and plr.Character:FindFirstChild("Humanoid") then
            if plr.Character.Humanoid.Health > 0 then
                local part = plr.Character[State.AimbotPart]
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist and dist <= State.AimbotFOV then
                        shortestDist = dist
                        targetPlr = plr
                    end
                end
            end
        end
    end
    return targetPlr
end
-- Aimbot RenderStepped Connection
RunService.RenderStepped:Connect(function()
    pcall(function()
        local camera = workspace.CurrentCamera
        local mouse = LocalPlayer:GetMouse()
        
        -- Update FOV circle
        if fovCircle then
            fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
            fovCircle.Radius = State.AimbotFOV
            fovCircle.Visible = State.Aimbot and true or false
        end
        if State.Aimbot then
            -- Only aim when Right Mouse Button is pressed
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local target = getClosestPlayerToMouse()
                if target and target.Character and target.Character:FindFirstChild(State.AimbotPart) then
                    local targetPos = target.Character[State.AimbotPart].Position
                    local currentLook = camera.CFrame
                    local targetCFrame = CFrame.new(currentLook.Position, targetPos)
                    
                    -- Smooth lerping: 1 - Smoothing (so 0 smoothing is instant, 0.9 is very slow/smooth)
                    local lerpFactor = 1 - State.AimbotSmoothing
                    camera.CFrame = currentLook:Lerp(targetCFrame, math.clamp(lerpFactor, 0.01, 1))
                end
            end
        end
    end)
end)
createSection(CombatTab, "Hitbox")
createToggle(CombatTab, "Hitbox expander", State.HitboxExpander, function(val)
    State.HitboxExpander = val
    if not val then
        -- Restore original hitboxes when disabled
        for plr, original in pairs(OriginalHitboxData) do
            pcall(function()
                if plr and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = original.Size
                        hrp.Transparency = original.Transparency
                        hrp.CanCollide = original.CanCollide
                    end
                end
            end)
        end
        table.clear(OriginalHitboxData)
    end
end)
createSlider(CombatTab, "Hitbox size", 2, 30, State.HitboxSize, function(val)
    State.HitboxSize = val
end)
-- Loop to continuously apply Hitbox expansion
task.spawn(function()
    while true do
        task.wait(1)
        if not ScreenGui.Parent then break end
        pcall(function()
            if State.HitboxExpander then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            -- Save original data if not already saved
                            if not OriginalHitboxData[plr] then
                                OriginalHitboxData[plr] = {
                                    Size = hrp.Size,
                                    Transparency = hrp.Transparency,
                                    CanCollide = hrp.CanCollide
                                }
                            end
                            -- Set expanded values
                            hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                            hrp.Transparency = 0.6
                            hrp.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
end)
-- Cleanup original sizes when player leaves
Players.PlayerRemoving:Connect(function(plr)
    OriginalHitboxData[plr] = nil
end)
-- Notify client UI loaded
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Vf1 > Zaid",
        Text = "Loaded. Right Control to toggle UI.",
        Duration = 5
    })
end)
