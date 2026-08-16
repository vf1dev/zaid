-- R4L HUB - Modern Roblox Utility Script
-- Features: ESP, Aimbot, Hitbox Expander, WalkSpeed, Fly, Custom Modern UI
-- Compatible with standard Luau environments
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
-- Destroy existing UI if running to allow hot-reloading
local coreGui = game:GetService("CoreGui")
local oldGui = coreGui:FindFirstChild("R4LHubGui") or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("R4LHubGui"))
if oldGui then
    oldGui:Destroy()
end
-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "vf1"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
    ESPColor = Color3.fromRGB(0, 190, 255),
    
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
    Background = Color3.fromRGB(15, 15, 18),
    Sidebar = Color3.fromRGB(10, 10, 12),
    Accent = Color3.fromRGB(0, 190, 255),
    AccentSecondary = Color3.fromRGB(0, 120, 255),
    CardBg = Color3.fromRGB(22, 22, 26),
    Border = Color3.fromRGB(35, 35, 40),
    TextActive = Color3.fromRGB(255, 255, 255),
    TextMuted = Color3.fromRGB(140, 140, 145),
    FontMain = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold
}
local function createRound(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end
local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end
-- ==========================================
-- MAIN FRAME CREATION
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 360)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
createRound(MainFrame, 12)
createStroke(MainFrame, Theme.Border, 1.5)
-- Drop shadow / Glow border simulation using UIStroke
local glowStroke = Instance.new("UIStroke")
glowStroke.Color = Theme.Accent
glowStroke.Thickness = 0.5
glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
glowStroke.Transparency = 0.5
glowStroke.Parent = MainFrame
-- Floating Toggle Button (in case they don't have RightControl)
local FloatingToggle = Instance.new("TextButton")
FloatingToggle.Name = "FloatingToggle"
FloatingToggle.Size = UDim2.new(0, 50, 0, 50)
FloatingToggle.Position = UDim2.new(0, 20, 0, 20)
FloatingToggle.BackgroundColor3 = Theme.Sidebar
FloatingToggle.Text = "R4L"
FloatingToggle.TextColor3 = Theme.Accent
FloatingToggle.Font = Theme.FontBold
FloatingToggle.TextSize = 14
FloatingToggle.Parent = ScreenGui
FloatingToggle.Visible = false -- Initially hidden, can be toggled via Hotkey or set active
createRound(FloatingToggle, 25)
createStroke(FloatingToggle, Theme.Accent, 1)
FloatingToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
-- Hotkey to toggle UI
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
-- Make Main Frame Draggable
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
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
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 12)
sideCorner.Parent = Sidebar
-- Hide right corner of sidebar to blend into Main Frame
local SidebarCover = Instance.new("Frame")
SidebarCover.Name = "SidebarCover"
SidebarCover.Size = UDim2.new(0, 20, 1, 0)
SidebarCover.Position = UDim2.new(1, -20, 0, 0)
SidebarCover.BackgroundColor3 = Theme.Sidebar
SidebarCover.BorderSizePixel = 0
SidebarCover.ZIndex = 1
SidebarCover.Parent = Sidebar
-- Title Label
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.Position = UDim2.new(0, 0, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "R4L HUB"
TitleLabel.TextColor3 = Theme.TextActive
TitleLabel.Font = Theme.FontBold
TitleLabel.TextSize = 18
TitleLabel.ZIndex = 2
TitleLabel.Parent = Sidebar
-- Separator
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(0.8, 0, 0, 1)
Sep.Position = UDim2.new(0.1, 0, 0, 55)
Sep.BackgroundColor3 = Theme.Border
Sep.BorderSizePixel = 0
Sep.ZIndex = 2
Sep.Parent = Sidebar
-- Sidebar Button Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 1, -70)
TabContainer.Position = UDim2.new(0, 0, 0, 70)
TabContainer.BackgroundTransparency = 1
TabContainer.ZIndex = 2
TabContainer.Parent = Sidebar
local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Parent = TabContainer
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 8)
-- ==========================================
-- CONTAINER FOR TABS
-- ==========================================
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -150, 1, -20)
Container.Position = UDim2.new(0, 145, 0, 10)
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
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.Visible = false
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.CanvasPosition = Vector2.new(0, 0)
    Page.Parent = Container
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = Page
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    Tabs[name] = Page
    return Page
end
-- ==========================================
-- UI CONTROLS CREATION FUNCTIONS
-- ==========================================
local function createToggle(page, text, defaultState, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -10, 0, 42)
    ToggleFrame.BackgroundColor3 = Theme.CardBg
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.LayoutOrder = #page:GetChildren()
    ToggleFrame.Parent = page
    createRound(ToggleFrame, 8)
    createStroke(ToggleFrame, Theme.Border, 1)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextActive
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Theme.FontMain
    Label.TextSize = 14
    Label.Parent = ToggleFrame
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 44, 0, 22)
    Button.Position = UDim2.new(1, -56, 0.5, -11)
    Button.BackgroundColor3 = defaultState and Theme.Accent or Color3.fromRGB(50, 50, 55)
    Button.Text = ""
    Button.Parent = ToggleFrame
    createRound(Button, 11)
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = UDim2.new(0, defaultState and 24 or 2, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.Parent = Button
    createRound(Circle, 9)
    local active = defaultState
    Button.MouseButton1Click:Connect(function()
        active = not active
        local targetPos = active and UDim2.new(0, 24, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local targetColor = active and Theme.Accent or Color3.fromRGB(50, 50, 55)
        
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        
        callback(active)
    end)
end
local function createSlider(page, text, min, max, defaultVal, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, -10, 0, 55)
    SliderFrame.BackgroundColor3 = Theme.CardBg
    SliderFrame.BorderSizePixel = 0
    SliderFrame.LayoutOrder = #page:GetChildren()
    SliderFrame.Parent = page
    createRound(SliderFrame, 8)
    createStroke(SliderFrame, Theme.Border, 1)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 25)
    Label.Position = UDim2.new(0, 12, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextActive
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Theme.FontMain
    Label.TextSize = 13
    Label.Parent = SliderFrame
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.3, 0, 0, 25)
    ValueLabel.Position = UDim2.new(0.7, -12, 0, 5)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(defaultVal)
    ValueLabel.TextColor3 = Theme.Accent
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Font = Theme.FontBold
    ValueLabel.TextSize = 13
    ValueLabel.Parent = SliderFrame
    local Track = Instance.new("TextButton")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 38)
    Track.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Track.BorderSizePixel = 0
    Track.Text = ""
    Track.Parent = SliderFrame
    createRound(Track, 3)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((defaultVal - min)/(max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    createRound(Fill, 3)
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.Position = UDim2.new((defaultVal - min)/(max - min), -6, 0.5, -6)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Track
    createRound(Knob, 6)
    local draggingSlider = false
    local function updateSlider(input)
        local relativeX = input.Position.X - Track.AbsolutePosition.X
        local percentage = math.clamp(relativeX / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + percentage * (max - min))
        
        ValueLabel.Text = tostring(val)
        Fill.Size = UDim2.new(percentage, 0, 1, 0)
        Knob.Position = UDim2.new(percentage, -6, 0.5, -6)
        
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
    DropdownFrame.Size = UDim2.new(1, -10, 0, 42)
    DropdownFrame.BackgroundColor3 = Theme.CardBg
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.LayoutOrder = #page:GetChildren()
    DropdownFrame.Parent = page
    DropdownFrame.ClipsDescendants = false
    DropdownFrame.ZIndex = 5
    createRound(DropdownFrame, 8)
    createStroke(DropdownFrame, Theme.Border, 1)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.TextActive
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Theme.FontMain
    Label.TextSize = 14
    Label.Parent = DropdownFrame
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 120, 0, 26)
    Button.Position = UDim2.new(1, -132, 0.5, -13)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Button.Text = defaultOpt
    Button.TextColor3 = Theme.TextActive
    Button.Font = Theme.FontMain
    Button.TextSize = 12
    Button.Parent = DropdownFrame
    createRound(Button, 6)
    createStroke(Button, Theme.Border, 1)
    local ListFrame = Instance.new("Frame")
    ListFrame.Size = UDim2.new(1, 0, 0, 0)
    ListFrame.Position = UDim2.new(0, 0, 1, 4)
    ListFrame.BackgroundColor3 = Theme.CardBg
    ListFrame.BorderSizePixel = 0
    ListFrame.Visible = false
    ListFrame.ZIndex = 10
    ListFrame.Parent = Button
    createRound(ListFrame, 6)
    createStroke(ListFrame, Theme.Border, 1)
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
            OptBtn.Size = UDim2.new(1, 0, 0, 26)
            OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            OptBtn.BackgroundTransparency = 1
            OptBtn.BorderSizePixel = 0
            OptBtn.Text = opt
            OptBtn.TextColor3 = Theme.TextMuted
            OptBtn.Font = Theme.FontMain
            OptBtn.TextSize = 12
            OptBtn.ZIndex = 11
            OptBtn.Parent = ListFrame
            OptBtn.MouseButton1Click:Connect(function()
                Button.Text = opt
                open = false
                ListFrame.Visible = false
                DropdownFrame.Size = UDim2.new(1, -10, 0, 42)
                callback(opt)
            end)
            
            OptBtn.MouseEnter:Connect(function()
                OptBtn.BackgroundTransparency = 0.5
                OptBtn.TextColor3 = Theme.TextActive
            end)
            OptBtn.MouseLeave:Connect(function()
                OptBtn.BackgroundTransparency = 1
                OptBtn.TextColor3 = Theme.TextMuted
            end)
        end
        ListFrame.Size = UDim2.new(1, 0, 0, count * 26)
    end
    Button.MouseButton1Click:Connect(function()
        open = not open
        if open then
            rebuildOptions()
            DropdownFrame.Size = UDim2.new(1, -10, 0, 42 + ListFrame.AbsoluteSize.Y + 5)
            ListFrame.Visible = true
        else
            ListFrame.Visible = false
            DropdownFrame.Size = UDim2.new(1, -10, 0, 42)
        end
    end)
end
-- ==========================================
-- TAB SELECTION SYSTEM
-- ==========================================
local function showTab(name)
    for tabName, page in pairs(Tabs) do
        page.Visible = (tabName == name)
    end
    for btnName, btn in pairs(TabButtons) do
        if btnName == name then
            btn.TextColor3 = Theme.TextActive
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            btn.Indicator.BackgroundColor3 = Theme.Accent
        else
            btn.TextColor3 = Theme.TextMuted
            btn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
            btn.Indicator.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        end
    end
end
local function addTab(name)
    local Page = createTabPage(name)
    
    local Button = Instance.new("TextButton")
    Button.Name = name .. "TabBtn"
    Button.Size = UDim2.new(0.9, 0, 0, 32)
    Button.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    Button.BorderSizePixel = 0
    Button.Text = "  " .. name
    Button.TextColor3 = Theme.TextMuted
    Button.Font = Theme.FontMain
    Button.TextSize = 13
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.ZIndex = 2
    Button.Parent = TabContainer
    createRound(Button, 6)
    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 3, 0.6, 0)
    Indicator.Position = UDim2.new(0, 0, 0.2, 0)
    Indicator.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Button
    createRound(Indicator, 2)
    TabButtons[name] = Button
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
-- Custom Speed Toggle and Slider
createToggle(MovementTab, "Enable WalkSpeed Hack", State.SpeedEnabled, function(val)
    State.SpeedEnabled = val
end)
createSlider(MovementTab, "WalkSpeed Value", 16, 200, State.WalkSpeed, function(val)
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
-- Fly Toggle and Slider
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
createToggle(MovementTab, "Enable Fly", State.Fly, function(val)
    State.Fly = val
    if val then
        startFlying()
    else
        stopFlying()
    end
end)
createSlider(MovementTab, "Fly Speed Value", 10, 300, State.FlySpeed, function(val)
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
createToggle(VisualsTab, "Enable Player Highlight ESP", State.ESP, function(val)
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
-- Aimbot UI Controls
createToggle(CombatTab, "Enable Aimbot (Hold Right Mouse)", State.Aimbot, function(val)
    State.Aimbot = val
end)
createDropdown(CombatTab, "Aimbot Target Part", {"Head", "HumanoidRootPart"}, State.AimbotPart, function(val)
    State.AimbotPart = val
end)
createSlider(CombatTab, "Aimbot FOV Radius", 50, 400, State.AimbotFOV, function(val)
    State.AimbotFOV = val
end)
createSlider(CombatTab, "Aimbot Smoothness (%)", 0, 95, math.floor(State.AimbotSmoothing * 100), function(val)
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
-- Hitbox Expander Control
createToggle(CombatTab, "Enable Hitbox Expander", State.HitboxExpander, function(val)
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
createSlider(CombatTab, "Hitbox Size", 2, 30, State.HitboxSize, function(val)
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
        Title = "R4L HUB",
        Text = "Successfully Loaded! Press Right Control to toggle UI.",
        Duration = 5
    })
end)
