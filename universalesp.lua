local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local UniversalLoaded = true
local Connections = {}

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("UniversalClient") then
	PlayerGui.UniversalClient:Destroy()
end

-- ==========================================
-- DYNAMIC SETTINGS & KEYBINDS
-- ==========================================
local Settings = {
	Binds = {
		MenuToggle = Enum.KeyCode.RightShift,
		AimbotKey = Enum.UserInputType.MouseButton2
	},
	Combat = {
		Aimbot = false,
		Part = "Head",
		Smoothness = 3,
		Prediction = 0.2,
		FOV = 120,
		ShowFOV = true,
		WallCheck = true,
		HitboxExpander = false,
		HitboxSize = 3
	},
	PlayerESP = {
		Enabled = true,
		Boxes = true,
		HealthBar = true,
		Names = true,
		Distance = true,
		Tracers = false,
		Radar = true,
		Chams = false,
		MaxDistance = 2000,
		TracerMaxDistance = 1000,
		Color = Color3.fromRGB(255, 60, 60)
	},
	World = {
		Crosshair = true,
		ThirdPerson = false,
		ThirdPersonDist = 12,
		Freecam = false,
		FreecamSpeed = 60,
		XRay = false,
		XRayTransparency = 0.7,
		AntiFog = false,
		AlwaysDay = false,
		Fullbright = false
	}
}

-- ==========================================
-- GUI INTERFACE SETUP
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalClient"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = PlayerGui

-- CROSSHAIR OVERLAY
local CrosshairContainer = Instance.new("Frame", ScreenGui)
CrosshairContainer.Name = "CrosshairContainer"
CrosshairContainer.Size = UDim2.new(0, 16, 0, 16)
CrosshairContainer.Position = UDim2.new(0.5, -8, 0.5, -8)
CrosshairContainer.BackgroundTransparency = 1
CrosshairContainer.Visible = Settings.World.Crosshair

local ChVertical = Instance.new("Frame", CrosshairContainer)
ChVertical.Size = UDim2.new(0, 2, 1, 0)
ChVertical.Position = UDim2.new(0.5, -1, 0, 0)
ChVertical.BackgroundColor3 = Color3.fromRGB(180, 75, 30)
ChVertical.BorderSizePixel = 0

local ChHorizontal = Instance.new("Frame", CrosshairContainer)
ChHorizontal.Size = UDim2.new(1, 0, 0, 2)
ChHorizontal.Position = UDim2.new(0, 0, 0.5, -1)
ChHorizontal.BackgroundColor3 = Color3.fromRGB(180, 75, 30)
ChHorizontal.BorderSizePixel = 0

-- FREECAM NOTIFICATION OVERLAY
local FreecamNotice = Instance.new("TextLabel", ScreenGui)
FreecamNotice.Size = UDim2.new(0, 320, 0, 30)
FreecamNotice.Position = UDim2.new(0.5, -160, 0, 15)
FreecamNotice.BackgroundTransparency = 0.3
FreecamNotice.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
FreecamNotice.TextColor3 = Color3.fromRGB(255, 100, 100)
FreecamNotice.Font = Enum.Font.Code
FreecamNotice.TextSize = 13
FreecamNotice.Text = "[FREECAM ACTIVE: WASD + Mouse Look]"
FreecamNotice.Visible = false
local NoticeCorner = Instance.new("UICorner", FreecamNotice) NoticeCorner.CornerRadius = UDim.new(0, 4)

-- TOP-RIGHT RADAR GUI
local RADAR_RADIUS = 55
local RADAR_RANGE = 300

local RadarFrame = Instance.new("Frame", ScreenGui)
RadarFrame.Name = "RadarFrame"
RadarFrame.Size = UDim2.new(0, RADAR_RADIUS * 2, 0, RADAR_RADIUS * 2)
RadarFrame.Position = UDim2.new(1, -135, 0, 15)
RadarFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
RadarFrame.BackgroundTransparency = 0.2
RadarFrame.BorderSizePixel = 1
RadarFrame.BorderColor3 = Color3.fromRGB(180, 75, 30)
RadarFrame.ClipsDescendants = true
RadarFrame.Visible = Settings.PlayerESP.Radar

local RadarCorner = Instance.new("UICorner", RadarFrame)
RadarCorner.CornerRadius = UDim.new(1, 0)

local RadarCenter = Instance.new("Frame", RadarFrame)
RadarCenter.Size = UDim2.new(0, 6, 0, 6)
RadarCenter.Position = UDim2.new(0.5, -3, 0.5, -3)
RadarCenter.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
RadarCenter.BorderSizePixel = 0
RadarCenter.ZIndex = 3
local CenterCorner = Instance.new("UICorner", RadarCenter)
CenterCorner.CornerRadius = UDim.new(1, 0)

-- MAIN DASHBOARD
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 420)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(180, 75, 30)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
Title.Text = "  UNIVERSAL CLIENT  |  Press [RightShift] to Toggle"
Title.TextColor3 = Color3.fromRGB(180, 75, 30)
Title.Font = Enum.Font.Code
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
table.insert(Connections, Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end))
table.insert(Connections, Title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end))
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end))

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 140, 1, -35)
TabContainer.Position = UDim2.new(0, 0, 0, 35)
TabContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -140, 1, -35)
PageContainer.Position = UDim2.new(0, 140, 0, 35)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

local Tabs, Pages = {}, {}

local function CreateTab(name)
	local TabBtn = Instance.new("TextButton")
	TabBtn.Size = UDim2.new(1, 0, 0, 40)
	TabBtn.Position = UDim2.new(0, 0, 0, #Tabs * 40)
	TabBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	TabBtn.Text = name
	TabBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
	TabBtn.Font = Enum.Font.Code
	TabBtn.TextSize = 13
	TabBtn.BorderSizePixel = 0
	TabBtn.Parent = TabContainer

	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.new(1, -20, 1, -20)
	Page.Position = UDim2.new(0, 10, 0, 10)
	Page.BackgroundTransparency = 1
	Page.ScrollBarThickness = 3
	Page.Visible = false
	Page.Parent = PageContainer

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 8)
	UIListLayout.Parent = Page

	table.insert(Tabs, TabBtn)
	table.insert(Pages, Page)

	table.insert(Connections, TabBtn.MouseButton1Click:Connect(function()
		for i, v in ipairs(Tabs) do
			v.TextColor3 = Color3.fromRGB(120, 120, 120)
			v.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			Pages[i].Visible = false
		end
		TabBtn.TextColor3 = Color3.fromRGB(180, 75, 30)
		TabBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
		Page.Visible = true
	end))

	if #Tabs == 1 then
		TabBtn.TextColor3 = Color3.fromRGB(180, 75, 30)
		TabBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
		Page.Visible = true
	end
	return Page
end

local function CreateToggle(page, text, cat, key, callback)
	local ToggleFrame = Instance.new("Frame", page)
	ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
	ToggleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	
	local Label = Instance.new("TextLabel", ToggleFrame)
	Label.Size = UDim2.new(1, -50, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.Font = Enum.Font.Code
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left

	local ToggleBtn = Instance.new("TextButton", ToggleFrame)
	ToggleBtn.Size = UDim2.new(0, 40, 0, 16)
	ToggleBtn.Position = UDim2.new(1, -50, 0.5, -8)
	ToggleBtn.BackgroundColor3 = Settings[cat][key] and Color3.fromRGB(180, 75, 30) or Color3.fromRGB(40, 40, 40)
	ToggleBtn.Text = ""

	local Circle = Instance.new("Frame", ToggleBtn)
	Circle.Size = UDim2.new(0, 16, 0, 16)
	Circle.Position = Settings[cat][key] and UDim2.new(1, -16, 0, 0) or UDim2.new(0, 0, 0, 0)
	Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

	table.insert(Connections, ToggleBtn.MouseButton1Click:Connect(function()
		Settings[cat][key] = not Settings[cat][key]
		local state = Settings[cat][key]
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(180, 75, 30) or Color3.fromRGB(40, 40, 40)}):Play()
		TweenService:Create(Circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -16, 0, 0) or UDim2.new(0, 0, 0, 0)}):Play()
		if callback then callback(state) end
	end))
end

local function CreateSlider(page, text, min, max, cat, key, isDecimal)
	local SliderFrame = Instance.new("Frame", page)
	SliderFrame.Size = UDim2.new(1, 0, 0, 45)
	SliderFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	local currentVal = Settings[cat][key]
	local displayValStr = isDecimal and string.format("%.1f", currentVal) or tostring(currentVal)

	local Label = Instance.new("TextLabel", SliderFrame)
	Label.Size = UDim2.new(1, -20, 0, 20)
	Label.Position = UDim2.new(0, 10, 0, 5)
	Label.BackgroundTransparency = 1
	Label.Text = text .. ": " .. displayValStr
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.Font = Enum.Font.Code
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left

	local Track = Instance.new("Frame", SliderFrame)
	Track.Size = UDim2.new(1, -20, 0, 4)
	Track.Position = UDim2.new(0, 10, 0, 30)
	Track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

	local Fill = Instance.new("Frame", Track)
	local pct = (currentVal - min) / (max - min)
	if isDecimal then
		pct = (currentVal * 10 - min) / (max - min)
	end
	Fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
	Fill.BackgroundColor3 = Color3.fromRGB(180, 75, 30)

	local sDragging = false
	local function updateSlider(input)
		local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		if isDecimal then
			local rawVal = math.floor(min + ((max - min) * pos))
			local value = rawVal / 10
			Settings[cat][key] = value
			Label.Text = text .. ": " .. string.format("%.1f", value)
		else
			local value = math.floor(min + ((max - min) * pos))
			Settings[cat][key] = value
			Label.Text = text .. ": " .. tostring(value)
		end
		TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
	end

	table.insert(Connections, Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then sDragging = true updateSlider(input) end
	end))
	table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then sDragging = false end
	end))
	table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
		if sDragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
	end))
end

local function CreateKeybind(page, text, cat, key)
	local BindFrame = Instance.new("Frame", page)
	BindFrame.Size = UDim2.new(1, 0, 0, 30)
	BindFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	local Label = Instance.new("TextLabel", BindFrame)
	Label.Size = UDim2.new(0.5, 0, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.Font = Enum.Font.Code
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left

	local BindBtn = Instance.new("TextButton", BindFrame)
	BindBtn.Size = UDim2.new(0, 100, 0, 20)
	BindBtn.Position = UDim2.new(1, -110, 0.5, -10)
	BindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	BindBtn.TextColor3 = Color3.fromRGB(180, 75, 30)
	BindBtn.Font = Enum.Font.Code
	BindBtn.TextSize = 12
	BindBtn.Text = Settings[cat][key].Name

	local binding = false
	table.insert(Connections, BindBtn.MouseButton1Click:Connect(function()
		BindBtn.Text = ". . ."
		binding = true
	end))

	table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
		if binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				Settings[cat][key] = input.KeyCode
				BindBtn.Text = input.KeyCode.Name
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
				Settings[cat][key] = input.UserInputType
				BindBtn.Text = input.UserInputType.Name
			end
			binding = false
		end
	end))
end

local function CreateButton(page, text, color, callback)
	local BtnFrame = Instance.new("Frame", page)
	BtnFrame.Size = UDim2.new(1, 0, 0, 35)
	BtnFrame.BackgroundTransparency = 1

	local Btn = Instance.new("TextButton", BtnFrame)
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundColor3 = color or Color3.fromRGB(30, 30, 30)
	Btn.Text = text
	Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	Btn.Font = Enum.Font.Code
	Btn.TextSize = 13
	Btn.BorderSizePixel = 0

	table.insert(Connections, Btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end))
end

-- ==========================================
-- POPULATE DASHBOARD TABS
-- ==========================================
local CombatTab = CreateTab("Combat")
CreateToggle(CombatTab, "Enable Aimbot", "Combat", "Aimbot")
CreateToggle(CombatTab, "Visibility Check", "Combat", "WallCheck")
CreateToggle(CombatTab, "Show FOV Circle", "Combat", "ShowFOV")
CreateSlider(CombatTab, "Aimbot FOV", 10, 600, "Combat", "FOV", false)
CreateSlider(CombatTab, "Smoothing (1=Instant)", 1, 20, "Combat", "Smoothness", false)
CreateSlider(CombatTab, "Velocity Prediction", 0, 30, "Combat", "Prediction", true)
CreateToggle(CombatTab, "Hitbox Expander", "Combat", "HitboxExpander")
CreateSlider(CombatTab, "Hitbox Size Multiplier", 1, 10, "Combat", "HitboxSize", false)

local PlayerESPTab = CreateTab("Player ESP")
CreateToggle(PlayerESPTab, "Master Player ESP", "PlayerESP", "Enabled")
CreateToggle(PlayerESPTab, "2D Bounding Boxes", "PlayerESP", "Boxes")
CreateToggle(PlayerESPTab, "Side Health Bar", "PlayerESP", "HealthBar")
CreateToggle(PlayerESPTab, "Show Player Names", "PlayerESP", "Names")
CreateToggle(PlayerESPTab, "Show Distance Text", "PlayerESP", "Distance")
CreateToggle(PlayerESPTab, "360° Mouse Snaplines", "PlayerESP", "Tracers")
CreateToggle(PlayerESPTab, "Top-Right Mini Radar", "PlayerESP", "Radar")
CreateToggle(PlayerESPTab, "Solid Chams Highlight", "PlayerESP", "Chams")
CreateSlider(PlayerESPTab, "ESP Max Distance", 50, 5000, "PlayerESP", "MaxDistance", false)
CreateSlider(PlayerESPTab, "Tracer Max Distance", 10, 2000, "PlayerESP", "TracerMaxDistance", false)

local function applyCleanXRay(state)
	for _, v in ipairs(workspace:GetDescendants()) do
		if v and v.Parent and v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass("Humanoid") and v.Name ~= "Terrain" then
			if state then
				if not v:GetAttribute("OrigTrans") then
					v:SetAttribute("OrigTrans", v.Transparency)
				end
				v.Transparency = Settings.World.XRayTransparency
			else
				if v:GetAttribute("OrigTrans") then
					v.Transparency = v:GetAttribute("OrigTrans")
				end
			end
		end
	end
end

local WorldTab = CreateTab("Visuals & Lighting")
CreateToggle(WorldTab, "Screen Crosshair", "World", "Crosshair", function(state)
	CrosshairContainer.Visible = state
end)
CreateToggle(WorldTab, "Third-Person Mode", "World", "ThirdPerson")
CreateSlider(WorldTab, "Third-Person Distance", 4, 30, "World", "ThirdPersonDist", false)
CreateToggle(WorldTab, "Stealth Freecam", "World", "Freecam", function(state)
	FreecamNotice.Visible = state
end)
CreateSlider(WorldTab, "Freecam Speed", 10, 150, "World", "FreecamSpeed", false)
CreateToggle(WorldTab, "X-Ray Transparency Mode", "World", "XRay", applyCleanXRay)
CreateSlider(WorldTab, "X-Ray Transparency Level", 1, 10, "World", "XRayTransparency", true)
CreateToggle(WorldTab, "Anti-Fog (Clear Vision)", "World", "AntiFog")
CreateToggle(WorldTab, "Always Day (Time Changer)", "World", "AlwaysDay")
CreateToggle(WorldTab, "Fullbright", "World", "Fullbright")

local BindsTab = CreateTab("Settings/Binds")
CreateKeybind(BindsTab, "Menu Toggle Key", "Binds", "MenuToggle")
CreateKeybind(BindsTab, "Aimbot Key", "Binds", "AimbotKey")

-- ==========================================
-- SYSTEM CONTAINERS & UNLOAD ENGINE
-- ==========================================
local PlayerESPObjects = {}
local ChamsFolder = Instance.new("Folder", ScreenGui)
ChamsFolder.Name = "UniversalChams"

local FOVCircle = nil
local fFrame = Instance.new("Frame", ScreenGui)
fFrame.BackgroundTransparency = 1
local stroke = Instance.new("UIStroke", fFrame) stroke.Color = Color3.fromRGB(180, 75, 30) stroke.Thickness = 1
local corner = Instance.new("UICorner", fFrame) corner.CornerRadius = UDim.new(1, 0)

FOVCircle = {
	Visible = false, Radius = 100, Position = Vector2.new(), fFrame = fFrame,
	Update = function(self)
		self.fFrame.Visible = self.Visible
		self.fFrame.Size = UDim2.new(0, self.Radius*2, 0, self.Radius*2)
		self.fFrame.Position = UDim2.new(0, self.Position.X - self.Radius, 0, self.Position.Y - self.Radius)
	end
}

CreateButton(BindsTab, "⚠ UNLOAD CLIENT & REVERT ⚠", Color3.fromRGB(150, 30, 30), function()
	UniversalLoaded = false
	for _, conn in ipairs(Connections) do conn:Disconnect() end
	
	applyCleanXRay(false)
	Camera.CameraType = Enum.CameraType.Custom
	
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(127, 127, 127)
	Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
	Lighting.FogEnd = 100000
	if Lighting:FindFirstChildOfClass("Atmosphere") then Lighting:FindFirstChildOfClass("Atmosphere").Density = 0.3 end
	
	for player, esp in pairs(PlayerESPObjects) do
		if player.Character and player.Character:FindFirstChild("Head") then
			player.Character.Head.Size = Vector3.new(1.2, 1, 1.2)
			player.Character.Head.Transparency = 0
		end
		for _, v in pairs(esp) do if typeof(v) == "Instance" then v:Destroy() end end
	end
	
	if FOVCircle and FOVCircle.fFrame then FOVCircle.fFrame:Destroy() end
	if ScreenGui then ScreenGui:Destroy() end
end)

-- ==========================================
-- FREECAM & CAMERA ENGINE STATE
-- ==========================================
local freecamPos = nil
table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
	if not UniversalLoaded then return end
	
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	
	if Settings.World.Freecam then
		Camera.CameraType = Enum.CameraType.Scriptable
		if not freecamPos and hrp then freecamPos = Camera.CFrame end
		
		local rot = Camera.CFrame - Camera.CFrame.Position
		local moveDir = Vector3.new(0,0,0)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + rot.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - rot.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rot.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rot.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
		
		freecamPos = (freecamPos + (moveDir * Settings.World.FreecamSpeed * dt))
		Camera.CFrame = CFrame.new(freecamPos.Position) * rot
	else
		if freecamPos then
			freecamPos = nil
			Camera.CameraType = Enum.CameraType.Custom
		end
		
		if Settings.World.ThirdPerson and hrp then
			Camera.CameraType = Enum.CameraType.Scriptable
			local camTarget = hrp.Position + Vector3.new(0, 1.5, 0)
			local camRotation = Camera.CFrame - Camera.CFrame.Position
			local idealCF = CFrame.new(camTarget) * camRotation * CFrame.new(0, 0, Settings.World.ThirdPersonDist)
			
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {char}
			local rayRes = workspace:Raycast(camTarget, (idealCF.Position - camTarget), rayParams)
			
			if rayRes then
				Camera.CFrame = CFrame.new(rayRes.Position) * camRotation
			else
				Camera.CFrame = idealCF
			end
		end
	end
end))

-- ==========================================
-- AIMBOT, RADAR & PLAYER ESP SYSTEM
-- ==========================================
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Settings.Binds.MenuToggle then MainFrame.Visible = not MainFrame.Visible end
end))

local isAiming = false
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and (input.UserInputType == Settings.Binds.AimbotKey or input.KeyCode == Settings.Binds.AimbotKey) then isAiming = true end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Settings.Binds.AimbotKey or input.KeyCode == Settings.Binds.AimbotKey then isAiming = false end
end))

local function isVisible(targetPart)
	if not Settings.Combat.WallCheck then return true end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
	local res = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, ray)
	return res == nil or res.Instance:IsDescendantOf(targetPart.Parent)
end

local function CreatePlayerESP(player)
	local esp = {
		Box = Instance.new("Frame", ScreenGui),
		HealthBG = Instance.new("Frame", ScreenGui),
		HealthFill = Instance.new("Frame"),
		Tracer = Instance.new("Frame", ScreenGui),
		Label = Instance.new("TextLabel", ScreenGui),
		Highlight = Instance.new("Highlight", ChamsFolder),
		Blip = Instance.new("Frame", RadarFrame)
	}
	
	esp.Box.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke", esp.Box) stroke.Color = Settings.PlayerESP.Color stroke.Thickness = 1.5
	
	esp.HealthBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	esp.HealthBG.BorderSizePixel = 0
	esp.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	esp.HealthFill.BorderSizePixel = 0
	esp.HealthFill.Size = UDim2.new(1, 0, 1, 0)
	esp.HealthFill.AnchorPoint = Vector2.new(0, 1)
	esp.HealthFill.Position = UDim2.new(0, 0, 1, 0)
	esp.HealthFill.Parent = esp.HealthBG

	esp.Tracer.BackgroundColor3 = Settings.PlayerESP.Color
	esp.Tracer.BorderSizePixel = 0
	esp.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	
	esp.Label.BackgroundTransparency = 1
	esp.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	esp.Label.TextStrokeTransparency = 0.2
	esp.Label.Font = Enum.Font.Code
	esp.Label.TextSize = 12
	
	esp.Highlight.FillColor = Settings.PlayerESP.Color
	esp.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	
	esp.Blip.Size = UDim2.new(0, 4, 0, 4)
	esp.Blip.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	esp.Blip.BorderSizePixel = 0
	esp.Blip.Visible = false
	local blipCorner = Instance.new("UICorner", esp.Blip)
	blipCorner.CornerRadius = UDim.new(1, 0)

	PlayerESPObjects[player] = esp
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreatePlayerESP(p) end end
table.insert(Connections, Players.PlayerAdded:Connect(function(p) CreatePlayerESP(p) end))
table.insert(Connections, Players.PlayerRemoving:Connect(function(p)
	if PlayerESPObjects[p] then
		for _, v in pairs(PlayerESPObjects[p]) do if typeof(v) == "Instance" then v:Destroy() end end
		PlayerESPObjects[p] = nil
	end
end))

-- Main Render Stepped Loop
table.insert(Connections, RunService.RenderStepped:Connect(function()
	if not UniversalLoaded then return end
	local mouseLoc = UserInputService:GetMouseLocation()
	local screenSize = Camera.ViewportSize
	local localChar = LocalPlayer.Character
	local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
	
	RadarFrame.Visible = Settings.PlayerESP.Radar and Settings.PlayerESP.Enabled
	CrosshairContainer.Visible = Settings.World.Crosshair

	FOVCircle.Visible = Settings.Combat.ShowFOV and Settings.Combat.Aimbot
	FOVCircle.Radius = Settings.Combat.FOV
	FOVCircle.Position = mouseLoc
	FOVCircle:Update()

	local closestDist = Settings.Combat.FOV
	local closestTarget = nil

	for player, esp in pairs(PlayerESPObjects) do
		local char = player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")

		if char and humanoid and hrp and head and humanoid.Health > 0 then
			local rawPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			local distToPlayer = (Camera.CFrame.Position - hrp.Position).Magnitude
			local inGeneralRange = distToPlayer <= Settings.PlayerESP.MaxDistance
			local inTracerRange = distToPlayer <= Settings.PlayerESP.TracerMaxDistance

			if Settings.PlayerESP.Radar and Settings.PlayerESP.Enabled and localHRP and inGeneralRange then
				local diff = hrp.Position - localHRP.Position
				local cameraLook = Camera.CFrame.LookVector
				local cameraYaw = math.atan2(-cameraLook.X, -cameraLook.Z)
				local relX = diff.X * math.cos(cameraYaw) - diff.Z * math.sin(cameraYaw)
				local relY = diff.X * math.sin(cameraYaw) + diff.Z * math.cos(cameraYaw)

				local scaledX = (relX / RADAR_RANGE) * RADAR_RADIUS
				local scaledY = (relY / RADAR_RANGE) * RADAR_RADIUS
				local distFromCenter = math.sqrt(scaledX^2 + scaledY^2)
				if distFromCenter > RADAR_RADIUS - 4 then
					scaledX = (scaledX / distFromCenter) * (RADAR_RADIUS - 4)
					scaledY = (scaledY / distFromCenter) * (RADAR_RADIUS - 4)
				end

				esp.Blip.Position = UDim2.new(0.5, scaledX - 2, 0.5, scaledY - 2)
				esp.Blip.Visible = true
			else
				esp.Blip.Visible = false
			end

			if Settings.Combat.HitboxExpander then
				head.Size = Vector3.new(Settings.Combat.HitboxSize, Settings.Combat.HitboxSize, Settings.Combat.HitboxSize)
				head.Transparency = 0.7
				head.CanCollide = false
				head.Massless = true
			else
				if head.Size.X > 2 then
					head.Size = Vector3.new(1.2, 1, 1.2)
					head.Transparency = 0
				end
			end

			if onScreen and Settings.Combat.Aimbot and inGeneralRange then
				local aimScreenPos, aimOnScreen = Camera:WorldToViewportPoint(head.Position)
				local fovDist = (Vector2.new(aimScreenPos.X, aimScreenPos.Y) - mouseLoc).Magnitude
				if fovDist < closestDist and isVisible(head) then
					closestDist = fovDist
					closestTarget = head
				end
			end

			if Settings.PlayerESP.Enabled and inGeneralRange then
				local screenPos = Vector2.new(rawPos.X, rawPos.Y)
				
				if onScreen then
					local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
					local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
					local height = math.abs(headPos.Y - legPos.Y)
					local width = height * 0.6
					
					esp.Box.Visible = Settings.PlayerESP.Boxes
					esp.Box.Size = UDim2.new(0, width, 0, height)
					esp.Box.Position = UDim2.new(0, screenPos.X - width/2, 0, headPos.Y)
					
					if Settings.PlayerESP.HealthBar then
						local hpPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
						esp.HealthBG.Size = UDim2.new(0, 4, 0, height)
						esp.HealthBG.Position = UDim2.new(0, screenPos.X - (width/2) - 7, 0, headPos.Y)
						esp.HealthBG.Visible = true
						
						esp.HealthFill.Size = UDim2.new(1, 0, hpPct, 0)
						esp.HealthFill.BackgroundColor3 = hpPct > 0.5 
							and Color3.fromRGB(255, 255, 0):Lerp(Color3.fromRGB(0, 255, 100), (hpPct - 0.5) * 2) 
							or Color3.fromRGB(255, 30, 30):Lerp(Color3.fromRGB(255, 140, 0), hpPct * 2)
					else
						esp.HealthBG.Visible = false
					end
					
					esp.Label.Visible = Settings.PlayerESP.Names or Settings.PlayerESP.Distance
					local nameStr = Settings.PlayerESP.Names and player.Name or ""
					local hpStr = Settings.PlayerESP.HealthBar and (" [" .. math.floor(humanoid.Health) .. "HP]") or ""
					local distStr = Settings.PlayerESP.Distance and (" " .. math.floor(distToPlayer) .. "m") or ""
					esp.Label.Text = nameStr .. hpStr .. distStr
					esp.Label.Position = UDim2.new(0, screenPos.X - 100, 0, headPos.Y - 18)
					esp.Label.Size = UDim2.new(0, 200, 0, 15)
					
					esp.Highlight.Enabled = Settings.PlayerESP.Chams
					esp.Highlight.Adornee = char
				else
					esp.Box.Visible = false esp.HealthBG.Visible = false esp.Label.Visible = false esp.Highlight.Enabled = false
				end

				if Settings.PlayerESP.Tracers and inTracerRange then
					local tracerEnd
					if rawPos.Z < 0 then
						local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
						local inverted = screenCenter - (Vector2.new(rawPos.X, rawPos.Y) - screenCenter)
						local clampedX = math.clamp(inverted.X, 15, screenSize.X - 15)
						local clampedY = math.clamp(inverted.Y, 15, screenSize.Y - 15)
						tracerEnd = Vector2.new(clampedX, clampedY)
					else
						local clampedX = math.clamp(rawPos.X, 15, screenSize.X - 15)
						local clampedY = math.clamp(rawPos.Y, 15, screenSize.Y - 15)
						tracerEnd = Vector2.new(clampedX, clampedY)
					end

					local tracerStart = mouseLoc
					esp.Tracer.Size = UDim2.new(0, 1.5, 0, (tracerStart - tracerEnd).Magnitude)
					esp.Tracer.Position = UDim2.new(0, (tracerStart.X + tracerEnd.X)/2, 0, (tracerStart.Y + tracerEnd.Y)/2)
					esp.Tracer.Rotation = math.deg(math.atan2(tracerEnd.Y - tracerStart.Y, tracerEnd.X - tracerStart.X)) - 90
					esp.Tracer.Visible = true
				else
					esp.Tracer.Visible = false
				end
			else
				esp.Box.Visible = false esp.HealthBG.Visible = false esp.Tracer.Visible = false esp.Label.Visible = false esp.Highlight.Enabled = false esp.Blip.Visible = false
			end
		else
			esp.Box.Visible = false esp.HealthBG.Visible = false esp.Tracer.Visible = false esp.Label.Visible = false esp.Highlight.Enabled = false esp.Blip.Visible = false
		end
	end

	if isAiming and closestTarget and Settings.Combat.Aimbot then
		local rawVel = closestTarget.AssemblyLinearVelocity
		local horizPred = Vector3.new(rawVel.X, rawVel.Y * 0.1, rawVel.Z) * Settings.Combat.Prediction
		local goalCFrame = CFrame.new(Camera.CFrame.Position, closestTarget.Position + horizPred)
		
		if Settings.Combat.Smoothness <= 1 then
			Camera.CFrame = goalCFrame
		else
			Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, 1 / Settings.Combat.Smoothness)
		end
	end

	if Settings.World.AlwaysDay then Lighting.ClockTime = 12 end
	if Settings.World.Fullbright then
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	end
	if Settings.World.AntiFog then
		Lighting.FogEnd = 1000000
		if Lighting:FindFirstChildOfClass("Atmosphere") then Lighting:FindFirstChildOfClass("Atmosphere").Density = 0 end
	end
end))

print("[Universal Client] Loaded successfully. Press Right Shift to toggle.")
