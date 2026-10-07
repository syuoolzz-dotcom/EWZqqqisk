--[[
    Сделано Наумовым Максимом  |  MaximMenu v7
    LocalScript → StarterPlayer > StarterPlayerScripts
    Меню для тестирования СВОЕЙ игры. Телефон + ПК (на ПК: RightShift — открыть/закрыть).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer

local BANNER_TEXT = "Женя дотер вонючий хахаахахах"
local DEFAULT_WALK, DEFAULT_JUMP = 16, 50
local DEFAULT_GRAVITY = Workspace.Gravity
local viewport = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 400)
local startScale = (viewport.Y < 500) and 0.85 or 1

-- соединения сервисов (чтобы можно было полностью выгрузить скрипт)
local conns = {}
local function conn(sig, fn)
	local c = sig:Connect(fn)
	table.insert(conns, c)
	return c
end

---------------------------------------------------------------------
-- НАСТРОЙКИ / СОСТОЯНИЕ
---------------------------------------------------------------------
local S = {
	-- движение
	fly = false, flySpeed = 60, flyVSpeed = 50, flyAccel = 0.25,
	noclip = false, ncTransp = 0.4,
	speed = false, speedVal = 50,
	jump = false, jumpVal = 100,
	infJump = false, infJumpPower = 55,
	-- бой
	aim = false, aimFov = 150, aimSmooth = 0.3, aimDist = 600,
	aimHead = true, teamCheck = true, wallCheck = false, showFov = true, aimHold = false, aimDot = true,
	-- вид
	esp = false, espColorIdx = 1, espFill = 0.65, espNames = true, espDist = true, espHealth = true,
	espMaxDist = 1500, espTracers = false,
	fullbright = false, fbBright = 2,
	customTime = false, clock = 14,
	customFov = false, fov = 70,
	-- игроки
	tpOffset = 3, tpSmooth = true, tpTime = 0.4,
	attachMode = false, attachPos = 1, attachDist = 5, attachSmooth = 0.4, orbitSpeed = 2, attachFace = true, attachNoclip = true,
	-- обычные (новые)
	clickTp = false, autoJump = false, antiVoid = false, voidY = -100, hipOn = false, hipHeight = 4,
	spin = false, spinSpeed = 10, antiRagdoll = false, zoomOn = false, zoomMax = 400, respawnDeath = false, spectate = false,
	-- жёсткие
	turbo = false, turboMult = 3, rampOn = false, rampMax = 150, rampRate = 25, hardBtns = false,
	dashPower = 120, rocketPower = 200, tour = false, tourDelay = 3,
	-- визуальные (новые)
	crosshair = false, chSize = 12, chGap = 4, chColorIdx = 1,
	cc = false, ccContrast = 0.2, ccSat = 0.3, ccBright = 0, bloom = false, bloomInt = 1, sunrays = false, sunInt = 0.25,
	vignette = false, vigInt = 0.5, tint = false, tintColorIdx = 2, tintInt = 0.3,
	rainbow = false, rainbowSpeed = 1, trail = false, trailLife = 1, trailColorIdx = 1, aura = false, auraRate = 30, hideCore = false,
	-- ещё
	gravity = DEFAULT_GRAVITY, antiAfk = true,
	-- меню
	menuScale = startScale, animSpeed = 1, particles = true, toasts = true, banner = true, bannerTime = 3.5,
	menuTransp = 0.45, blurSize = 10, hud = true,
}
local DEFAULTS = {}
for k, v in pairs(S) do DEFAULTS[k] = v end

local function tw(obj, t, props, style, dir)
	local tween = TweenService:Create(
		obj,
		TweenInfo.new(t / S.animSpeed, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

local function getChar() return lp.Character end
local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- UI ХЕЛПЕРЫ
---------------------------------------------------------------------
local C = {
	bg = Color3.fromRGB(8, 8, 8),
	panel = Color3.fromRGB(22, 22, 22),
	panelHover = Color3.fromRGB(34, 34, 34),
	text = Color3.fromRGB(255, 255, 255),
	dim = Color3.fromRGB(150, 150, 150),
	line = Color3.fromRGB(70, 70, 70),
}
local WHITE = Color3.new(1, 1, 1)
local SPIN_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, WHITE),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 30, 30)),
	ColorSequenceKeypoint.new(1, WHITE),
})

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end
local function corner(p, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p) end
local function stroke(p, t, c)
	return new("UIStroke", {Thickness = t or 1, Color = c or C.text, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p)
end

local function bar(parent, rot, x, y, len, thick)
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, x, 0.5, y),
		Size = UDim2.fromOffset(len, thick), Rotation = rot, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, parent)
	corner(f, thick / 2)
	return f
end
local function drawX(parent)
	bar(parent, 45, 0, 0, 14, 2.5)
	bar(parent, -45, 0, 0, 14, 2.5)
end
local function drawChevron(parent, up)
	if up then
		bar(parent, -45, -5.5, 0, 16, 4)
		bar(parent, 45, 5.5, 0, 16, 4)
	else
		bar(parent, 45, -5.5, 0, 16, 4)
		bar(parent, -45, 5.5, 0, 16, 4)
	end
end

local old = lp:WaitForChild("PlayerGui"):FindFirstChild("MaximMenu")
if old then old:Destroy() end

local gui = new("ScreenGui", {
	Name = "MaximMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, lp.PlayerGui)

local espLayer = new("Frame", {Name = "ESPLayer", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = false}, gui)

local function makeDraggable(handle, target)
	local state = {moved = false}
	local dragging, startInput, startPos = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, state.moved = true, false
			startInput, startPos = i.Position, target.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	conn(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startInput
			if d.Magnitude > 8 then state.moved = true end
			if state.moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end)
	return state
end

---------------------------------------------------------------------
-- ТОСТ (уведомления сверху)
---------------------------------------------------------------------
local toast = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -60),
	Size = UDim2.new(0, 240, 0, 34), BackgroundColor3 = C.bg,
}, gui)
corner(toast, 17); stroke(toast, 1.5)
local toastLabel = new("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, Text = "",
}, toast)
local toastToken = 0
local function showToast(text)
	if not S.toasts then return end
	toastToken += 1
	local my = toastToken
	toastLabel.Text = text
	tw(toast, 0.35, {Position = UDim2.new(0.5, 0, 0, 12)}, Enum.EasingStyle.Back)
	task.delay(1.8, function()
		if my == toastToken then
			tw(toast, 0.3, {Position = UDim2.new(0.5, 0, 0, -60)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end)
end

---------------------------------------------------------------------
-- БАННЕР СНИЗУ
---------------------------------------------------------------------
local banner = new("Frame", {
	Name = "Banner", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 90),
	Size = UDim2.new(0, 330, 0, 48), BackgroundColor3 = C.bg, Visible = false,
}, gui)
corner(banner, 24)
local bannerStroke = stroke(banner, 2)
local bannerGrad = new("UIGradient", {Color = SPIN_SEQ}, bannerStroke)
local bannerScale = new("UIScale", {Scale = 0.85}, banner)
local bannerLabel = new("TextLabel", {
	Size = UDim2.new(1, -24, 1, -8), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
	Text = BANNER_TEXT, Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = C.text, MaxVisibleGraphemes = 0,
}, banner)
local bannerBar = new("Frame", {
	Position = UDim2.new(0, 22, 1, -9), Size = UDim2.new(1, -44, 0, 2),
	BackgroundColor3 = Color3.fromRGB(50, 50, 50), BorderSizePixel = 0,
}, banner)
corner(bannerBar, 1)
local bannerFill = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.text, BorderSizePixel = 0}, bannerBar)
corner(bannerFill, 1)

local bannerToken = 0
local function showBanner()
	if not S.banner then return end
	bannerToken += 1
	local my = bannerToken
	bannerLabel.MaxVisibleGraphemes = 0
	bannerFill.Size = UDim2.new(1, 0, 1, 0)
	banner.Position = UDim2.new(0.5, 0, 1, 90)
	bannerScale.Scale = 0.85
	banner.Visible = true
	tw(banner, 0.55, {Position = UDim2.new(0.5, 0, 1, -22)}, Enum.EasingStyle.Back)
	tw(bannerScale, 0.55, {Scale = 1}, Enum.EasingStyle.Back)
	task.spawn(function()
		task.wait(0.4 / S.animSpeed)
		local total = utf8.len(BANNER_TEXT)
		for i = 1, total do
			if my ~= bannerToken then return end
			bannerLabel.MaxVisibleGraphemes = i
			task.wait(0.035 / S.animSpeed)
		end
		TweenService:Create(bannerFill, TweenInfo.new(S.bannerTime, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
		task.wait(S.bannerTime)
		if my ~= bannerToken then return end
		tw(banner, 0.45, {Position = UDim2.new(0.5, 0, 1, 90)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tw(bannerScale, 0.45, {Scale = 0.85}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	end)
end

---------------------------------------------------------------------
-- ГЛАВНОЕ ОКНО
---------------------------------------------------------------------
local W = 380
local H = math.clamp((viewport.Y - 40) / startScale, 240, 440)

local main = new("Frame", {
	Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, W, 0, H), BackgroundColor3 = WHITE, BackgroundTransparency = S.menuTransp, Visible = false, ClipsDescendants = true,
}, gui)
corner(main, 14)
new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(22, 22, 22), Color3.fromRGB(4, 4, 4)), Rotation = 90}, main)
local mainStroke = stroke(main, 2)
local mainGrad = new("UIGradient", {Color = SPIN_SEQ}, mainStroke)
local mainScale = new("UIScale", {Scale = 0}, main)

local function isInMain(inst) return main:IsAncestorOf(inst) end

-- частицы (пыль на фоне)
local fx = new("Frame", {Name = "FX", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, main)
local particles = {}
for _ = 1, 20 do
	local sz = math.random(2, 3)
	local f = new("Frame", {
		Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.4 + math.random() * 0.5, BorderSizePixel = 0,
	}, fx)
	corner(f, 2)
	table.insert(particles, {
		f = f, x = math.random() * W, y = math.random() * H,
		vx = (math.random() - 0.5) * 10, vy = -(5 + math.random() * 14),
	})
end

-- ripple-эффект при нажатии
local function ripple(btn)
	btn.ClipsDescendants = true
	btn.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		local sc = isInMain(btn) and math.max(mainScale.Scale, 0.05) or 1
		local p = (Vector2.new(i.Position.X, i.Position.Y) - btn.AbsolutePosition) / sc
		local size = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) / sc * 2.4
		local r = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y),
			Size = UDim2.fromOffset(0, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.75, ZIndex = 5,
		}, btn)
		corner(r, 9999)
		tw(r, 0.5, {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1})
		task.delay(0.6 / S.animSpeed + 0.05, function() r:Destroy() end)
	end)
end

local function hover(btn, base, over)
	btn.MouseEnter:Connect(function() tw(btn, 0.15, {BackgroundColor3 = over}) end)
	btn.MouseLeave:Connect(function() tw(btn, 0.15, {BackgroundColor3 = base}) end)
end

-- шапка
local header = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1}, main)
local title = new("TextLabel", {
	Size = UDim2.new(0, 208, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1,
	Text = "Сделано Наумовым Максимом", Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = WHITE,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)
local titleGrad = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 190, 190)),
		ColorSequenceKeypoint.new(0.5, WHITE),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 190)),
	}),
}, title)
local closeBtn = new("TextButton", {
	Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -38, 0, 6),
	BackgroundColor3 = C.panel, Text = "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.text,
	AutoButtonColor = false,
}, header)
corner(closeBtn, 8)
drawX(closeBtn)
ripple(closeBtn); hover(closeBtn, C.panel, C.panelHover)

-- ник справа сверху
local nickPill = new("Frame", {
	Size = UDim2.new(0, 112, 0, 24), Position = UDim2.new(1, -154, 0, 8),
	BackgroundColor3 = C.panel, BackgroundTransparency = 0.3, Visible = false,
}, header)
corner(nickPill, 12)
local nickStroke = stroke(nickPill, 1, WHITE)
nickStroke.Transparency = 0.6
local nickDot = new("Frame", {
	Size = UDim2.fromOffset(6, 6), Position = UDim2.new(0, 9, 0.5, -3), BackgroundColor3 = WHITE, BorderSizePixel = 0,
}, nickPill)
corner(nickDot, 3)
local nickLabel = new("TextLabel", {
	Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -26, 1, 0), BackgroundTransparency = 1, Text = "",
	Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = WHITE,
	TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, nickPill)
local divider = new("Frame", {Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 40), BackgroundColor3 = C.text, BorderSizePixel = 0}, main)
new("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1),
	}),
}, divider)
makeDraggable(header, main)

-- вкладки
local tabBar = new("Frame", {Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 48), BackgroundTransparency = 1}, main)
-- (вкладки раскладываются вручную, без UIListLayout)

local pageHolder = new("Frame", {
	Size = UDim2.new(1, -24, 1, -92), Position = UDim2.new(0, 12, 0, 84), BackgroundTransparency = 1, ClipsDescendants = true,
}, main)

local pages, tabButtons = {}, {}
local function selectTab(name)
	for n, pg in pairs(pages) do
		if n == name then
			pg.Visible = true
			pg.Position = UDim2.new(0, 0, 0, 16)
			tw(pg, 0.3, {Position = UDim2.new(0, 0, 0, 0)})
		else
			pg.Visible = false
		end
	end
	for n, b in pairs(tabButtons) do
		local on = (n == name)
		tw(b, 0.2, {BackgroundColor3 = on and C.text or C.panel, TextColor3 = on and C.bg or C.text})
	end
end

local function addTab(name, order)
	local b = new("TextButton", {
		Position = UDim2.new((order - 1) / 7, 0, 0, 0), Size = UDim2.new(1 / 7, -4, 1, 0), BackgroundColor3 = C.panel, Text = name,
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.text, AutoButtonColor = false, LayoutOrder = order,
	}, tabBar)
	corner(b, 8)
	ripple(b)
	local pg = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.text,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
	}, pageHolder)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, pg)
	new("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8)}, pg)
	pages[name], tabButtons[name] = pg, b
	b.Activated:Connect(function() selectTab(name) end)
	return pg
end

---------------------------------------------------------------------
-- ЭЛЕМЕНТЫ ИНТЕРФЕЙСА
---------------------------------------------------------------------
local function addHeader(page, text)
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "  " .. text,
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left,
	}, page)
end

local function addToggle(page, text, key, cb)
	local row = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel, Text = "", AutoButtonColor = false}, page)
	corner(row, 10)
	local rs = stroke(row, 1, WHITE)
	rs.Transparency = S[key] and 0.5 or 1
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -74, 1, 0),
		Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local sw = new("Frame", {Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -56, 0.5, -11), BackgroundColor3 = C.bg}, row)
	corner(sw, 11); stroke(sw, 1, C.line)
	local knob = new("Frame", {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = C.text}, sw)
	corner(knob, 8)
	local function render()
		local on = S[key]
		tw(sw, 0.2, {BackgroundColor3 = on and C.text or C.bg})
		tw(knob, 0.25, {
			Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
			BackgroundColor3 = on and C.bg or C.text,
		}, Enum.EasingStyle.Back)
		tw(rs, 0.2, {Transparency = on and 0.5 or 1})
	end
	render()
	ripple(row); hover(row, C.panel, C.panelHover)
	row.Activated:Connect(function()
		S[key] = not S[key]
		render()
		showToast(text .. ": " .. (S[key] and "ВКЛ" or "ВЫКЛ"))
		if cb then cb(S[key]) end
	end)
end

local activeSlider
conn(UIS.InputChanged, function(i)
	if activeSlider and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		activeSlider(i.Position.X)
	end
end)

local sliderSetters = {}
local function addSlider(page, text, key, min, max, step, cb, unit)
	local row = new("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.panel}, page)
	corner(row, 10)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 4), Size = UDim2.new(1, -90, 0, 22),
		Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local val = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.new(1, -78, 0, 4), Size = UDim2.new(0, 66, 0, 22),
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local track = new("Frame", {Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = C.bg}, row)
	corner(track, 3); stroke(track, 1, C.line)
	local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.text, BorderSizePixel = 0}, track)
	corner(fill, 3)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = C.text,
	}, track)
	corner(knob, 9999); stroke(knob, 2, C.bg)
	local hit = new("TextButton", {Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = ""}, row)

	local function render()
		local rel = (S[key] - min) / (max - min)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		local v = S[key]
		val.Text = (step >= 1 and tostring(math.floor(v + 0.5)) or string.format("%.2f", v)) .. (unit or "")
	end
	local function setValue(v, fire)
		v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
		v = math.floor(v * 1000 + 0.5) / 1000
		S[key] = v
		render()
		if fire and cb then cb(v) end
	end
	local function fromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		setValue(min + rel * (max - min), true)
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			activeSlider = fromX
			page.ScrollingEnabled = false
			tw(knob, 0.15, {Size = UDim2.new(0, 20, 0, 20)}, Enum.EasingStyle.Back)
			fromX(i.Position.X)
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					activeSlider = nil
					page.ScrollingEnabled = true
					tw(knob, 0.15, {Size = UDim2.new(0, 14, 0, 14)})
				end
			end)
		end
	end)
	render()
	sliderSetters[key] = function(v) setValue(v, true) end
end

local function addCycle(page, text, key, options, cb)
	local row = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel}, page)
	corner(row, 10)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -134, 1, 0),
		Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local b = new("TextButton", {
		Size = UDim2.new(0, 108, 0, 26), Position = UDim2.new(1, -118, 0.5, -13), BackgroundColor3 = C.bg,
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text, Text = "", AutoButtonColor = false,
	}, row)
	corner(b, 8); stroke(b, 1, C.line)
	ripple(b)
	local function render() b.Text = options[S[key]][1] end
	render()
	b.Activated:Connect(function()
		S[key] = S[key] % #options + 1
		render()
		if cb then cb(S[key]) end
	end)
end

local function addButton(page, text, cb)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.text, Text = text,
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.bg, AutoButtonColor = false,
	}, page)
	corner(b, 10)
	ripple(b); hover(b, C.text, Color3.fromRGB(215, 215, 215))
	b.Activated:Connect(cb)
	return b
end

---------------------------------------------------------------------
-- МЕНЮ: ОТКРЫТЬ / ЗАКРЫТЬ
---------------------------------------------------------------------
local blur = new("BlurEffect", {Name = "MaximBlur", Size = 0}, Lighting)
local menuOpen = false
local loggedIn = false
local function openMenu()
	if menuOpen then return end
	menuOpen = true
	main.Visible = true
	mainScale.Scale = 0.5
	tw(mainScale, 0.45, {Scale = S.menuScale}, Enum.EasingStyle.Back)
	tw(blur, 0.4, {Size = S.blurSize})
	showBanner()
end
local function closeMenu()
	if not menuOpen then return end
	menuOpen = false
	tw(blur, 0.25, {Size = 0})
	local t = tw(mainScale, 0.25, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	t.Completed:Connect(function()
		if not menuOpen then main.Visible = false end
	end)
end
local function toggleMenu()
	if not loggedIn then return end
	if menuOpen then closeMenu() else openMenu() end
end

closeBtn.Activated:Connect(closeMenu)

conn(UIS.InputBegan, function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end)

-- круглая кнопка M
local openBtn = new("TextButton", {
	Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(1, -64, 0.25, 0),
	BackgroundColor3 = C.bg, Text = "M", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = C.text, AutoButtonColor = false, Visible = false,
}, gui)
corner(openBtn, 24)
local openStroke = stroke(openBtn, 2)
local openGrad = new("UIGradient", {Color = SPIN_SEQ}, openStroke)
local ring = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 1,
}, openBtn)
corner(ring, 9999)
local ringStroke = stroke(ring, 2)
ripple(openBtn)
local openDrag = makeDraggable(openBtn, openBtn)
openBtn.Activated:Connect(function()
	if openDrag.moved then return end
	toggleMenu()
end)

---------------------------------------------------------------------
-- ПОЛЁТ
---------------------------------------------------------------------
local bv, bgyro
local curVel = Vector3.zero
local flyUp, flyDown = false, false

local flyBtns = new("Frame", {
	Size = UDim2.new(0, 56, 0, 116), Position = UDim2.new(1, -72, 0.55, 0), BackgroundTransparency = 1, Visible = false,
}, gui)
local function holdBtn(sym, y, setter)
	local b = new("TextButton", {
		Size = UDim2.new(0, 56, 0, 54), Position = UDim2.new(0, 0, 0, y), BackgroundColor3 = C.bg,
		Text = "", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = C.text, AutoButtonColor = false,
	}, flyBtns)
	corner(b, 14); stroke(b, 2)
	drawChevron(b, sym == "up")
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			setter(true)
			tw(b, 0.1, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
		end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			setter(false)
			tw(b, 0.2, {BackgroundColor3 = C.bg})
		end
	end)
end
holdBtn("up", 0, function(v) flyUp = v end)
holdBtn("down", 62, function(v) flyDown = v end)

local function stopFly()
	if bv then bv:Destroy() bv = nil end
	if bgyro then bgyro:Destroy() bgyro = nil end
	local hum = getHum()
	if hum then hum.PlatformStand = false end
	flyBtns.Visible = false
	flyUp, flyDown = false, false
	curVel = Vector3.zero
end

local function startFly()
	local root, hum = getRoot(), getHum()
	if not root or not hum then return end
	stopFly()
	bv = new("BodyVelocity", {MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero}, root)
	bgyro = new("BodyGyro", {MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 9e4, CFrame = root.CFrame}, root)
	hum.PlatformStand = true
	flyBtns.Visible = true
end

---------------------------------------------------------------------
-- ESP
---------------------------------------------------------------------
local ESP_COLORS = {
	{"Белый", Color3.fromRGB(255, 255, 255)},
	{"Красный", Color3.fromRGB(255, 60, 60)},
	{"Зелёный", Color3.fromRGB(60, 255, 120)},
	{"Синий", Color3.fromRGB(70, 140, 255)},
	{"Фиолетовый", Color3.fromRGB(170, 90, 255)},
	{"Золотой", Color3.fromRGB(255, 200, 50)},
}
local esp = {}

local function styleESP(o)
	local c = ESP_COLORS[S.espColorIdx][2]
	o.hl.FillColor = c
	o.hl.OutlineColor = c
	o.hl.FillTransparency = S.espFill
	o.label.TextColor3 = c
	o.tracer.BackgroundColor3 = c
end
local function restyleAll()
	for _, o in pairs(esp) do styleESP(o) end
end

local function clearESP(plr)
	local o = esp[plr]
	if o then
		if o.hl then o.hl:Destroy() end
		if o.bb then o.bb:Destroy() end
		if o.tracer then o.tracer:Destroy() end
		esp[plr] = nil
	end
end

local function applyESP(plr)
	if plr == lp then return end
	clearESP(plr)
	local ch = plr.Character
	if not ch then return end
	local head = ch:FindFirstChild("Head") or ch:FindFirstChildWhichIsA("BasePart")
	if not head then return end
	local hl = new("Highlight", {
		Name = "MaximESP", FillColor = WHITE, FillTransparency = S.espFill, OutlineColor = WHITE,
		OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	}, ch)
	local bb = new("BillboardGui", {
		Name = "MaximESPTag", Adornee = head, Size = UDim2.new(0, 170, 0, 30),
		StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true,
	}, head)
	local lbl = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = plr.DisplayName,
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE,
		TextStrokeTransparency = 0, TextStrokeColor3 = Color3.new(0, 0, 0),
	}, bb)
	local tracer = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.2, Size = UDim2.fromOffset(0, 1.5), Visible = false,
	}, espLayer)
	local o = {
		hl = hl, bb = bb, label = lbl, tracer = tracer, head = head,
		hum = ch:FindFirstChildOfClass("Humanoid"), name = plr.DisplayName,
	}
	esp[plr] = o
	styleESP(o)
end

local function refreshESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if S.esp then applyESP(p) else clearESP(p) end
	end
end

local function hookPlayer(p)
	if p == lp then return end
	p.CharacterAdded:Connect(function()
		if S.esp then task.wait(0.6) applyESP(p) end
	end)
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
conn(Players.PlayerAdded, hookPlayer)
conn(Players.PlayerRemoving, clearESP)

---------------------------------------------------------------------
-- АИМБОТ
---------------------------------------------------------------------
local fovCircle = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, S.aimFov * 2, 0, S.aimFov * 2), BackgroundTransparency = 1, Visible = false,
}, gui)
corner(fovCircle, 9999); stroke(fovCircle, 1.5)

local aimDot = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = WHITE, Visible = false,
}, gui)
corner(aimDot, 5); stroke(aimDot, 2, C.bg)

local aimHeld = false
local aimBtn = new("TextButton", {
	Size = UDim2.new(0, 66, 0, 66), Position = UDim2.new(0, 30, 0.3, 0), BackgroundColor3 = C.bg,
	Text = "AIM", Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = C.text, Visible = false, AutoButtonColor = false,
}, gui)
corner(aimBtn, 33); stroke(aimBtn, 2)
aimBtn.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		aimHeld = true
		tw(aimBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(70, 70, 70)})
	end
end)
aimBtn.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		aimHeld = false
		tw(aimBtn, 0.2, {BackgroundColor3 = C.bg})
	end
end)

local function visibleCheck(part, ch)
	local cam = Workspace.CurrentCamera
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {lp.Character, ch}
	local o = cam.CFrame.Position
	return Workspace:Raycast(o, part.Position - o, params) == nil
end

local function getTarget()
	local cam = Workspace.CurrentCamera
	local center = cam.ViewportSize / 2
	local camPos = cam.CFrame.Position
	local best, bestDist = nil, S.aimFov
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		if p ~= lp and ch and not (S.teamCheck and p.Team ~= nil and p.Team == lp.Team) then
			local hum = ch:FindFirstChildOfClass("Humanoid")
			local part = ch:FindFirstChild(S.aimHead and "Head" or "HumanoidRootPart")
			if hum and hum.Health > 0 and part and (part.Position - camPos).Magnitude <= S.aimDist then
				local v, on = cam:WorldToViewportPoint(part.Position)
				if on then
					local d = (Vector2.new(v.X, v.Y) - center).Magnitude
					if d < bestDist and (not S.wallCheck or visibleCheck(part, ch)) then
						best, bestDist = part, d
					end
				end
			end
		end
	end
	return best
end

RunService:BindToRenderStep("MaximAim", Enum.RenderPriority.Camera.Value + 1, function()
	fovCircle.Visible = S.aim and S.showFov
	aimBtn.Visible = S.aim and S.aimHold
	local cam = Workspace.CurrentCamera
	local active = S.aim and (not S.aimHold or aimHeld)
	if not active or not cam then
		aimDot.Visible = false
		return
	end
	local t = getTarget()
	if t then
		cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, t.Position), S.aimSmooth)
		if S.aimDot then
			local v = cam:WorldToViewportPoint(t.Position)
			aimDot.Position = UDim2.fromOffset(v.X, v.Y)
			aimDot.Visible = true
		else
			aimDot.Visible = false
		end
	else
		aimDot.Visible = false
	end
end)

---------------------------------------------------------------------
-- ОСВЕЩЕНИЕ
---------------------------------------------------------------------
local origLight = {
	Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ClockTime = Lighting.ClockTime,
}
local function restoreLight()
	for k, v in pairs(origLight) do Lighting[k] = v end
end

---------------------------------------------------------------------
-- СТЕКЛО (прозрачность панелей)
---------------------------------------------------------------------
local glassItems, glassSet = {}, {}
local function glassAdd(inst)
	if glassSet[inst] then return end
	glassSet[inst] = true
	table.insert(glassItems, inst)
	inst.BackgroundTransparency = S.menuTransp * 0.95
end
local function applyGlass()
	main.BackgroundTransparency = S.menuTransp
	for i = #glassItems, 1, -1 do
		local g = glassItems[i]
		if g.Parent then
			g.BackgroundTransparency = S.menuTransp * 0.95
		else
			table.remove(glassItems, i)
			glassSet[g] = nil
		end
	end
end

---------------------------------------------------------------------
-- ПРИЛИПАНИЕ К ИГРОКУ + HUD
---------------------------------------------------------------------
local ATTACH_POS = {
	{"Сверху", Vector3.new(0, 1, 0)},
	{"Снизу", Vector3.new(0, -1, 0)},
	{"Справа", Vector3.new(1, 0, 0)},
	{"Слева", Vector3.new(-1, 0, 0)},
	{"Спереди", Vector3.new(0, 0, -1)},
	{"Сзади", Vector3.new(0, 0, 1)},
	{"Орбита (кружит)", Vector3.zero},
}
local attachTarget = nil
local orbitAngle = 0
local hudTimer, fpsSmooth = 0, 60

local hud = new("TextLabel", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.new(0, 190, 0, 18),
	BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Right, TextStrokeTransparency = 0.5, Text = "",
}, gui)

local attachBtn = new("TextButton", {
	Size = UDim2.new(0, 140, 0, 40), Position = UDim2.new(0, 20, 0.5, 0), BackgroundColor3 = C.bg,
	Text = "ОТЛИПНУТЬ", Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = C.text,
	Visible = false, AutoButtonColor = false,
}, gui)
corner(attachBtn, 20); stroke(attachBtn, 2)
ripple(attachBtn)

local function detach()
	if attachTarget then showToast("Отлип от " .. attachTarget.DisplayName) end
	attachTarget = nil
	attachBtn.Visible = false
	local r = getRoot()
	if r then r.AssemblyLinearVelocity = Vector3.zero end
end
local function attachTo(p)
	if attachTarget == p then
		detach()
		return
	end
	attachTarget = p
	orbitAngle = 0
	attachBtn.Visible = true
	showToast("Прилип к " .. p.DisplayName)
end
attachBtn.Activated:Connect(detach)
conn(Players.PlayerRemoving, function(p)
	if attachTarget == p then detach() end
end)

---------------------------------------------------------------------
-- ОСНОВНЫЕ ЦИКЛЫ
---------------------------------------------------------------------
---------------------------------------------------------------------
-- ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ (обычные / жёсткие / визуальные)
---------------------------------------------------------------------
local X = {}
do
	local StarterGui = game:GetService("StarterGui")
	local origZoom = lp.CameraMaxZoomDistance
	local origHip = nil
	local lastSafe, lastAlive, savedSpot = nil, nil, nil
	local rampCur = DEFAULT_WALK
	local rainbowOrig = {}
	local tourToken = 0
	X.specTarget = nil

	local function others()
		local t = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp then table.insert(t, p) end
		end
		return t
	end

	-------------------- ОБЫЧНЫЕ --------------------
	-- 1. Телепорт по тапу / Ctrl+клик
	local function clickTpAt(pos)
		local cam = Workspace.CurrentCamera
		local r = getRoot()
		if not cam or not r then return end
		local ray = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {lp.Character}
		local res = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
		if res then
			r.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0))
			r.AssemblyLinearVelocity = Vector3.zero
		end
	end
	conn(UIS.InputBegan, function(i, gp)
		if gp or not S.clickTp then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			clickTpAt(UIS:GetMouseLocation())
		end
	end)
	conn(UIS.TouchTapInWorld, function(pos, processed)
		if processed or not S.clickTp then return end
		clickTpAt(pos)
	end)

	-- 2-4, 6, 7 (авто-прыжок, анти-войд, высота, анти-рэгдолл) + разгон
	conn(RunService.Heartbeat, function(dt)
		local hum, r = getHum(), getRoot()
		if not hum or not r then return end
		if hum.Health > 0 then lastAlive = r.CFrame end
		if S.autoJump and hum.FloorMaterial ~= Enum.Material.Air then
			hum.Jump = true
		end
		if S.antiVoid then
			if r.Position.Y > S.voidY + 30 and hum.FloorMaterial ~= Enum.Material.Air then
				lastSafe = r.CFrame
			end
			if r.Position.Y < S.voidY and lastSafe then
				r.CFrame = lastSafe + Vector3.new(0, 5, 0)
				r.AssemblyLinearVelocity = Vector3.zero
				showToast("Анти-войд: возврат")
			end
		end
		if S.hipOn then hum.HipHeight = S.hipHeight end
		if S.antiRagdoll then
			local st = hum:GetState()
			if st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		if S.rampOn then
			if hum.MoveDirection.Magnitude > 0.1 then
				rampCur = math.min(S.rampMax, rampCur + S.rampRate * dt)
			else
				rampCur = DEFAULT_WALK
			end
			hum.WalkSpeed = rampCur
		end
	end)

	function X.hipToggle(on)
		local h = getHum()
		if not h then return end
		if on then
			origHip = h.HipHeight
		else
			h.HipHeight = origHip or 2
		end
	end

	function X.applyRagdoll(on)
		local h = getHum()
		if not h then return end
		pcall(function()
			h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not on)
			h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not on)
		end)
	end

	function X.applyZoom()
		lp.CameraMaxZoomDistance = S.zoomOn and S.zoomMax or origZoom
	end

	-- 5. Сохранённая точка
	function X.saveSpot()
		local r = getRoot()
		if r then
			savedSpot = r.CFrame
			showToast("Точка сохранена")
		end
	end
	function X.loadSpot()
		local r = getRoot()
		if r and savedSpot then
			r.CFrame = savedSpot
			r.AssemblyLinearVelocity = Vector3.zero
			showToast("Возврат к точке")
		else
			showToast("Точка не сохранена")
		end
	end

	-- 8. Наблюдение за игроком
	function X.spectateToggle(on)
		local cam = Workspace.CurrentCamera
		if on then
			X.specTarget = others()[1]
			if X.specTarget then
				showToast("Наблюдаю: " .. X.specTarget.DisplayName)
			else
				showToast("Нет других игроков")
			end
		else
			X.specTarget = nil
			local h = getHum()
			if cam and h then cam.CameraSubject = h end
		end
	end
	function X.nextSpectate()
		local list = others()
		if #list == 0 then
			showToast("Нет других игроков")
			return
		end
		local idx = table.find(list, X.specTarget) or 0
		X.specTarget = list[idx % #list + 1]
		showToast("Наблюдаю: " .. X.specTarget.DisplayName)
	end
	conn(Players.PlayerRemoving, function(p)
		if X.specTarget == p then X.specTarget = nil end
	end)

	-------------------- ЖЁСТКИЕ --------------------
	function X.rampToggle(on)
		rampCur = DEFAULT_WALK
		if not on then
			local h = getHum()
			if h then h.WalkSpeed = DEFAULT_WALK end
		end
	end

	function X.dash()
		local r, h = getRoot(), getHum()
		local cam = Workspace.CurrentCamera
		if not r or not cam then return end
		local dir = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		if h and h.MoveDirection.Magnitude > 0.1 then dir = h.MoveDirection end
		if dir.Magnitude < 0.01 then return end
		r.AssemblyLinearVelocity = dir.Unit * S.dashPower + Vector3.new(0, 15, 0)
	end

	function X.rocket()
		local r = getRoot()
		if r then
			local v = r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity = Vector3.new(v.X, S.rocketPower, v.Z)
		end
	end

	-- экранные кнопки Рывок / Ракета
	local hb = new("Frame", {
		Size = UDim2.new(0, 124, 0, 40), Position = UDim2.new(1, -136, 0, 34), BackgroundTransparency = 1, Visible = false,
	}, gui)
	local function hbBtn(text, x, cb)
		local b = new("TextButton", {
			Position = UDim2.new(0, x, 0, 0), Size = UDim2.new(0, 60, 1, 0), BackgroundColor3 = C.bg,
			Text = text, Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = C.text, AutoButtonColor = false,
		}, hb)
		corner(b, 12)
		stroke(b, 2)
		ripple(b)
		b.Activated:Connect(cb)
	end
	hbBtn("РЫВОК", 0, X.dash)
	hbBtn("РАКЕТА", 64, X.rocket)
	function X.applyHardBtns()
		hb.Visible = S.hardBtns
	end

	-- тур по игрокам (перемещает только тебя)
	function X.tourToggle(on)
		tourToken += 1
		if not on then return end
		local my = tourToken
		task.spawn(function()
			local i = 0
			while S.tour and my == tourToken do
				local list = others()
				if #list > 0 then
					i = i % #list + 1
					local p = list[i]
					local r = getRoot()
					local t = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if r and t then
						r.CFrame = t.CFrame * CFrame.new(0, 0, S.tpOffset)
						r.AssemblyLinearVelocity = Vector3.zero
						showToast("Тур: " .. p.DisplayName)
					end
				end
				task.wait(S.tourDelay)
			end
		end)
	end

	-------------------- ВИЗУАЛЬНЫЕ --------------------
	-- эффекты освещения: цветокоррекция, bloom, лучи
	local ccFx = new("ColorCorrectionEffect", {Name = "MaximCC", Enabled = false}, Lighting)
	local bloomFx = new("BloomEffect", {Name = "MaximBloom", Enabled = false, Size = 24, Threshold = 0.8}, Lighting)
	local sunFx = new("SunRaysEffect", {Name = "MaximSun", Enabled = false}, Lighting)
	function X.applyFx()
		ccFx.Enabled = S.cc
		ccFx.Contrast = S.ccContrast
		ccFx.Saturation = S.ccSat
		ccFx.Brightness = S.ccBright
		bloomFx.Enabled = S.bloom
		bloomFx.Intensity = S.bloomInt
		sunFx.Enabled = S.sunrays
		sunFx.Intensity = S.sunInt
	end
	X.applyFx()

	-- цветной фильтр и виньетка
	local tintFrame = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, BorderSizePixel = 0,
	}, espLayer)
	local vig = {}
	local function vigEdge(pos, anchor, size, rot, a, b)
		local f = new("Frame", {
			Position = pos, AnchorPoint = anchor, Size = size, BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0, Visible = false,
		}, espLayer)
		new("UIGradient", {Rotation = rot, Transparency = NumberSequence.new(a, b)}, f)
		table.insert(vig, f)
		return f
	end
	local vTop = vigEdge(UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), UDim2.new(1, 0, 0.3, 0), 90, 0, 1)
	local vBot = vigEdge(UDim2.new(0, 0, 1, 0), Vector2.new(0, 1), UDim2.new(1, 0, 0.3, 0), 90, 1, 0)
	local vLeft = vigEdge(UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), UDim2.new(0.2, 0, 1, 0), 0, 0, 1)
	local vRight = vigEdge(UDim2.new(1, 0, 0, 0), Vector2.new(1, 0), UDim2.new(0.2, 0, 1, 0), 0, 1, 0)
	function X.applyScreen()
		local t = S.vigInt
		vTop.Size = UDim2.new(1, 0, 0.1 + 0.3 * t, 0)
		vBot.Size = UDim2.new(1, 0, 0.1 + 0.3 * t, 0)
		vLeft.Size = UDim2.new(0.08 + 0.2 * t, 0, 1, 0)
		vRight.Size = UDim2.new(0.08 + 0.2 * t, 0, 1, 0)
		for _, f in ipairs(vig) do
			f.Visible = S.vignette
			f.BackgroundTransparency = 0.5 * (1 - t)
		end
		tintFrame.Visible = S.tint
		tintFrame.BackgroundColor3 = ESP_COLORS[S.tintColorIdx][2]
		tintFrame.BackgroundTransparency = 1 - S.tintInt
	end
	X.applyScreen()

	-- прицел
	local chFrame = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false}, espLayer)
	local chBars = {}
	for i = 1, 4 do
		chBars[i] = new("Frame", {BorderSizePixel = 0, BackgroundColor3 = WHITE}, chFrame)
	end
	local chDot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(3, 3),
		BorderSizePixel = 0, BackgroundColor3 = WHITE,
	}, chFrame)
	function X.applyCrosshair()
		chFrame.Visible = S.crosshair
		local col = ESP_COLORS[S.chColorIdx][2]
		local s, g = S.chSize, S.chGap
		local top, bot, lef, rig = chBars[1], chBars[2], chBars[3], chBars[4]
		top.AnchorPoint = Vector2.new(0.5, 1)
		top.Position = UDim2.new(0.5, 0, 0.5, -g)
		top.Size = UDim2.fromOffset(2, s)
		bot.AnchorPoint = Vector2.new(0.5, 0)
		bot.Position = UDim2.new(0.5, 0, 0.5, g)
		bot.Size = UDim2.fromOffset(2, s)
		lef.AnchorPoint = Vector2.new(1, 0.5)
		lef.Position = UDim2.new(0.5, -g, 0.5, 0)
		lef.Size = UDim2.fromOffset(s, 2)
		rig.AnchorPoint = Vector2.new(0, 0.5)
		rig.Position = UDim2.new(0.5, g, 0.5, 0)
		rig.Size = UDim2.fromOffset(s, 2)
		for _, b in ipairs(chBars) do b.BackgroundColor3 = col end
		chDot.BackgroundColor3 = col
	end
	X.applyCrosshair()

	-- радужный персонаж
	conn(RunService.RenderStepped, function(dt)
		local cam = Workspace.CurrentCamera
		local r = getRoot()
		if S.spin and r then
			r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(S.spinSpeed) * dt * 60, 0)
		end
		if S.spectate and cam then
			local plr = X.specTarget
			local ch = plr and plr.Character
			local h = ch and ch:FindFirstChildOfClass("Humanoid")
			cam.CameraSubject = h or getHum()
		end
		if S.rainbow then
			local ch = getChar()
			if ch then
				local col = Color3.fromHSV((os.clock() * S.rainbowSpeed * 0.3) % 1, 1, 1)
				for _, p in ipairs(ch:GetDescendants()) do
					if p:IsA("BasePart") then
						if not rainbowOrig[p] then rainbowOrig[p] = p.Color end
						p.Color = col
					end
				end
			end
		end
	end)
	function X.rainbowToggle(on)
		if not on then
			for p, c in pairs(rainbowOrig) do
				if p.Parent then p.Color = c end
			end
			rainbowOrig = {}
		end
	end

	-- след и аура
	local trailObj, trailA0, trailA1, auraObj
	function X.applyTrail()
		if trailObj then
			trailObj:Destroy()
			trailObj = nil
		end
		if trailA0 then
			trailA0:Destroy()
			trailA0 = nil
		end
		if trailA1 then
			trailA1:Destroy()
			trailA1 = nil
		end
		local r = getRoot()
		if not (S.trail and r) then return end
		local col = ESP_COLORS[S.trailColorIdx][2]
		trailA0 = new("Attachment", {Name = "MaximTrailA0", Position = Vector3.new(0, 1, 0)}, r)
		trailA1 = new("Attachment", {Name = "MaximTrailA1", Position = Vector3.new(0, -1, 0)}, r)
		trailObj = new("Trail", {
			Attachment0 = trailA0, Attachment1 = trailA1, Lifetime = S.trailLife,
			Color = ColorSequence.new(col), LightEmission = 1, Transparency = NumberSequence.new(0, 1),
		}, r)
	end
	function X.applyAura()
		if auraObj then
			auraObj:Destroy()
			auraObj = nil
		end
		local r = getRoot()
		if not (S.aura and r) then return end
		local col = ESP_COLORS[S.trailColorIdx][2]
		auraObj = new("ParticleEmitter", {
			Rate = S.auraRate, Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(2, 5),
			SpreadAngle = Vector2.new(180, 180), Color = ColorSequence.new(col), LightEmission = 1,
			Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}),
			Transparency = NumberSequence.new(0, 1),
		}, r)
	end
	function X.applyColors()
		X.applyTrail()
		X.applyAura()
	end

	-- скрыть интерфейс Roblox
	function X.applyCore()
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not S.hideCore)
		end)
	end

	-------------------- ПЕРЕРОЖДЕНИЕ --------------------
	conn(lp.CharacterAdded, function(char)
		local deathCF = lastAlive
		rainbowOrig = {}
		task.wait(0.6)
		if S.antiRagdoll then X.applyRagdoll(true) end
		if S.trail then X.applyTrail() end
		if S.aura then X.applyAura() end
		if S.hipOn then origHip = nil end
		if S.respawnDeath and deathCF then
			local r = char:FindFirstChild("HumanoidRootPart")
			if r then r.CFrame = deathCF end
		end
	end)

	-------------------- ОЧИСТКА --------------------
	function X.cleanup()
		for _, o in ipairs({ccFx, bloomFx, sunFx}) do o:Destroy() end
		if trailObj then trailObj:Destroy() end
		if trailA0 then trailA0:Destroy() end
		if trailA1 then trailA1:Destroy() end
		if auraObj then auraObj:Destroy() end
		X.rainbowToggle(false)
		local cam = Workspace.CurrentCamera
		local h = getHum()
		if cam and h then cam.CameraSubject = h end
		lp.CameraMaxZoomDistance = origZoom
		if S.hipOn and h then h.HipHeight = origHip or h.HipHeight end
		S.tour = false
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
	end
end

local function resetTransparency()
	local ch = getChar()
	if ch then
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
		end
	end
end

conn(RunService.RenderStepped, function(dt)
	local t = os.clock()
	local cam = Workspace.CurrentCamera

	hudTimer += dt
	fpsSmooth += (1 / math.max(dt, 0.001) - fpsSmooth) * 0.05
	hud.Visible = S.hud
	if S.hud and hudTimer > 0.4 then
		hudTimer = 0
		hud.Text = string.format("FPS %d  •  PING %d ms", math.floor(fpsSmooth + 0.5), math.floor(lp:GetNetworkPing() * 1000))
	end

	-- анимации интерфейса
	mainGrad.Rotation = (t * 60) % 360
	openGrad.Rotation = (t * 120) % 360
	bannerGrad.Rotation = (t * 100) % 360
	titleGrad.Offset = Vector2.new(((t * 0.6) % 2) - 1, 0)
	local ph = (t % 2) / 2
	ring.Size = UDim2.fromOffset(48 + 28 * ph, 48 + 28 * ph)
	ringStroke.Transparency = ph

	if S.particles and main.Visible then
		for _, p in ipairs(particles) do
			p.x += p.vx * dt
			p.y += p.vy * dt
			if p.y < -4 then p.y = H + 4; p.x = math.random() * W end
			if p.x < -4 then p.x = W + 4 elseif p.x > W + 4 then p.x = -4 end
			p.f.Position = UDim2.fromOffset(p.x, p.y)
		end
	end

	if not cam then return end

	-- полёт
	if S.fly then
		local root, hum = getRoot(), getHum()
		if root and hum then
			if not bv or bv.Parent ~= root then startFly() end
			if bv and bgyro then
				local lv = cam.CFrame:VectorToObjectSpace(hum.MoveDirection)
				local horiz = cam.CFrame.LookVector * (-lv.Z) + cam.CFrame.RightVector * lv.X
				local mult = S.turbo and S.turboMult or 1
				local target = horiz * S.flySpeed * mult
				if flyUp then target += Vector3.yAxis * S.flyVSpeed * mult end
				if flyDown then target -= Vector3.yAxis * S.flyVSpeed * mult end
				curVel = curVel:Lerp(target, math.clamp(S.flyAccel * dt * 60, 0, 1))
				bv.Velocity = curVel
				bgyro.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
			end
		end
	end

	-- прилипание к игроку
	if attachTarget then
		local root = getRoot()
		local tr = attachTarget.Character and attachTarget.Character:FindFirstChild("HumanoidRootPart")
		if root and tr then
			local goalPos
			if S.attachPos == 7 then
				orbitAngle += dt * S.orbitSpeed
				goalPos = tr.Position + Vector3.new(math.cos(orbitAngle) * S.attachDist, 0, math.sin(orbitAngle) * S.attachDist)
			else
				goalPos = (tr.CFrame * CFrame.new(ATTACH_POS[S.attachPos][2] * S.attachDist)).Position
			end
			local lookAt = Vector3.new(tr.Position.X, goalPos.Y, tr.Position.Z)
			local goal
			if S.attachFace and (lookAt - goalPos).Magnitude > 0.1 then
				goal = CFrame.new(goalPos, lookAt)
			else
				goal = CFrame.new(goalPos) * root.CFrame.Rotation
			end
			root.CFrame = root.CFrame:Lerp(goal, math.clamp(S.attachSmooth * dt * 60, 0, 1))
			root.AssemblyLinearVelocity = tr.AssemblyLinearVelocity
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end

	-- прозрачность при ноклипе
	if S.noclip and S.ncTransp > 0 then
		local ch = getChar()
		if ch then
			for _, p in ipairs(ch:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					p.LocalTransparencyModifier = S.ncTransp
				end
			end
		end
	end

	-- ESP
	if S.esp then
		local camPos = cam.CFrame.Position
		local from = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
		for _, o in pairs(esp) do
			if o.head and o.head.Parent then
				local d = (camPos - o.head.Position).Magnitude
				local show = d <= S.espMaxDist
				o.hl.Enabled = show
				local txt = S.espNames and o.name or ""
				if S.espDist then txt = txt .. (txt ~= "" and "  " or "") .. "[" .. math.floor(d) .. "m]" end
				if S.espHealth and o.hum then
					txt = txt .. (txt ~= "" and "  " or "") .. math.floor(o.hum.Health) .. "HP"
				end
				o.label.Text = txt
				o.bb.Enabled = show and txt ~= ""
				if S.espTracers and show then
					local v, on = cam:WorldToViewportPoint(o.head.Position)
					if on then
						local to = Vector2.new(v.X, v.Y)
						local dv = to - from
						local mid = from + dv / 2
						o.tracer.Position = UDim2.fromOffset(mid.X, mid.Y)
						o.tracer.Size = UDim2.fromOffset(dv.Magnitude, 1.5)
						o.tracer.Rotation = math.deg(math.atan2(dv.Y, dv.X))
						o.tracer.Visible = true
					else
						o.tracer.Visible = false
					end
				else
					o.tracer.Visible = false
				end
			else
				o.tracer.Visible = false
			end
		end
	end

	-- свет / время / FOV
	if S.fullbright then
		Lighting.Brightness = S.fbBright
		Lighting.FogEnd = 1e6
		Lighting.GlobalShadows = false
		Lighting.Ambient = WHITE
		Lighting.OutdoorAmbient = WHITE
	end
	if S.customTime then Lighting.ClockTime = S.clock end
	if S.customFov then cam.FieldOfView = S.fov end
end)

conn(RunService.Stepped, function()
	if S.noclip or (attachTarget and S.attachNoclip) then
		local ch = getChar()
		if ch then
			for _, p in ipairs(ch:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end
	end
end)

conn(RunService.Heartbeat, function()
	local hum = getHum()
	if not hum then return end
	if S.speed then hum.WalkSpeed = S.speedVal end
	if S.jump then
		hum.UseJumpPower = true
		hum.JumpPower = S.jumpVal
	end
end)

conn(UIS.JumpRequest, function()
	if S.infJump then
		local root = getRoot()
		if root then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, S.infJumpPower, v.Z)
		end
	end
end)

conn(lp.CharacterAdded, function()
	task.wait(0.5)
	if S.fly then startFly() end
end)

conn(lp.Idled, function()
	if S.antiAfk then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

---------------------------------------------------------------------
-- ВЫГРУЗКА СКРИПТА
---------------------------------------------------------------------
local function destroyAll()
	stopFly()
	for p in pairs(esp) do clearESP(p) end
	RunService:UnbindFromRenderStep("MaximAim")
	for _, c in ipairs(conns) do c:Disconnect() end
	local h = getHum()
	if h then
		h.WalkSpeed = DEFAULT_WALK
		h.JumpPower = DEFAULT_JUMP
	end
	Workspace.Gravity = DEFAULT_GRAVITY
	restoreLight()
	resetTransparency()
	local cam = Workspace.CurrentCamera
	if cam then cam.FieldOfView = 70 end
	X.cleanup()
	if blur then blur:Destroy() end
	gui:Destroy()
end

---------------------------------------------------------------------
-- ВКЛАДКИ
---------------------------------------------------------------------
-- ДВИЖЕНИЕ
local pMove = addTab("Движ", 1)
addHeader(pMove, "ПОЛЁТ")
addToggle(pMove, "Полёт", "fly", function(on) if on then startFly() else stopFly() end end)
addSlider(pMove, "Скорость полёта", "flySpeed", 10, 300, 5)
addSlider(pMove, "Скорость вверх/вниз", "flyVSpeed", 10, 200, 5)
addSlider(pMove, "Плавность разгона (1 = мгновенно)", "flyAccel", 0.05, 1, 0.05)
addHeader(pMove, "НОКЛИП")
addToggle(pMove, "Ноклип (сквозь стены)", "noclip", function(on) if not on then resetTransparency() end end)
addSlider(pMove, "Прозрачность персонажа", "ncTransp", 0, 0.9, 0.05)
addHeader(pMove, "БЕГ И ПРЫЖОК")
addToggle(pMove, "Скорость бега", "speed", function(on)
	if not on then local h = getHum() if h then h.WalkSpeed = DEFAULT_WALK end end
end)
addSlider(pMove, "Значение скорости", "speedVal", 16, 300, 2)
addToggle(pMove, "Высокий прыжок", "jump", function(on)
	if not on then local h = getHum() if h then h.JumpPower = DEFAULT_JUMP end end
end)
addSlider(pMove, "Сила прыжка", "jumpVal", 50, 400, 5)
addToggle(pMove, "Бесконечный прыжок", "infJump")
addSlider(pMove, "Сила бесконечного прыжка", "infJumpPower", 20, 200, 5)
addHeader(pMove, "ДОПОЛНИТЕЛЬНО")
addToggle(pMove, "Телепорт по тапу (Click TP)", "clickTp")
addToggle(pMove, "Авто-прыжок (bunnyhop)", "autoJump")
addToggle(pMove, "Анти-войд (возврат при падении)", "antiVoid")
addSlider(pMove, "Порог падения (высота Y)", "voidY", -1000, 200, 10)
addToggle(pMove, "Высота персонажа (HipHeight)", "hipOn", X.hipToggle)
addSlider(pMove, "Значение высоты", "hipHeight", 0, 30, 0.5)
addToggle(pMove, "Вращение персонажа", "spin")
addSlider(pMove, "Скорость вращения", "spinSpeed", 1, 60, 1)
addToggle(pMove, "Анти-рэгдолл (не падать)", "antiRagdoll", X.applyRagdoll)
addToggle(pMove, "Дальний зум камеры", "zoomOn", X.applyZoom)
addSlider(pMove, "Макс. зум камеры", "zoomMax", 50, 1000, 10, X.applyZoom)

-- БОЙ
local pCombat = addTab("Бой", 2)
addHeader(pCombat, "АИМБОТ")
addToggle(pCombat, "Аимбот", "aim")
addToggle(pCombat, "Режим кнопки AIM (удерживать)", "aimHold")
addSlider(pCombat, "Радиус захвата (FOV)", "aimFov", 30, 600, 5, function(v)
	fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end, "px")
addSlider(pCombat, "Плавность (меньше = плавнее)", "aimSmooth", 0.02, 1, 0.02)
addSlider(pCombat, "Макс. дистанция", "aimDist", 50, 3000, 50, nil, "m")
addHeader(pCombat, "ЦЕЛЬ")
addToggle(pCombat, "Целиться в голову (выкл = тело)", "aimHead")
addToggle(pCombat, "Игнорировать свою команду", "teamCheck")
addToggle(pCombat, "Проверка стен", "wallCheck")
addToggle(pCombat, "Показывать круг FOV", "showFov")
addToggle(pCombat, "Точка на цели", "aimDot")

-- ВИД
local pVisual = addTab("Вид", 3)
addHeader(pVisual, "ESP / WH")
addToggle(pVisual, "ESP (подсветка игроков)", "esp", refreshESP)
addCycle(pVisual, "Цвет ESP", "espColorIdx", ESP_COLORS, restyleAll)
addSlider(pVisual, "Прозрачность заливки", "espFill", 0, 1, 0.05, restyleAll)
addSlider(pVisual, "Макс. дистанция ESP", "espMaxDist", 100, 5000, 100, nil, "m")
addToggle(pVisual, "Показывать имена", "espNames")
addToggle(pVisual, "Показывать дистанцию", "espDist")
addToggle(pVisual, "Показывать здоровье", "espHealth")
addToggle(pVisual, "Линии к игрокам (трейсеры)", "espTracers")
addHeader(pVisual, "СВЕТ И КАМЕРА")
addToggle(pVisual, "Fullbright (без темноты)", "fullbright", function(on)
	if not on then
		for k, v in pairs(origLight) do
			if k ~= "ClockTime" then Lighting[k] = v end
		end
	end
end)
addSlider(pVisual, "Яркость", "fbBright", 0, 5, 0.25)
addToggle(pVisual, "Своё время суток", "customTime", function(on)
	if not on then Lighting.ClockTime = origLight.ClockTime end
end)
addSlider(pVisual, "Время (часы)", "clock", 0, 24, 0.25)
addToggle(pVisual, "Своё поле зрения (FOV)", "customFov", function(on)
	if not on and Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = 70 end
end)
addSlider(pVisual, "Значение FOV", "fov", 30, 120, 1)
addHeader(pVisual, "ПРИЦЕЛ")
addToggle(pVisual, "Прицел на экране", "crosshair", X.applyCrosshair)
addSlider(pVisual, "Размер прицела", "chSize", 4, 40, 1, X.applyCrosshair)
addSlider(pVisual, "Зазор прицела", "chGap", 0, 20, 1, X.applyCrosshair)
addCycle(pVisual, "Цвет прицела", "chColorIdx", ESP_COLORS, X.applyCrosshair)
addHeader(pVisual, "ЭФФЕКТЫ ЭКРАНА")
addToggle(pVisual, "Цветокоррекция", "cc", X.applyFx)
addSlider(pVisual, "Контраст", "ccContrast", -1, 1, 0.05, X.applyFx)
addSlider(pVisual, "Насыщенность", "ccSat", -1, 2, 0.05, X.applyFx)
addSlider(pVisual, "Яркость картинки", "ccBright", -0.5, 0.5, 0.05, X.applyFx)
addToggle(pVisual, "Свечение (Bloom)", "bloom", X.applyFx)
addSlider(pVisual, "Сила свечения", "bloomInt", 0, 5, 0.1, X.applyFx)
addToggle(pVisual, "Солнечные лучи", "sunrays", X.applyFx)
addSlider(pVisual, "Сила лучей", "sunInt", 0, 1, 0.05, X.applyFx)
addToggle(pVisual, "Виньетка (тёмные края)", "vignette", X.applyScreen)
addSlider(pVisual, "Сила виньетки", "vigInt", 0, 1, 0.05, X.applyScreen)
addToggle(pVisual, "Цветной фильтр экрана", "tint", X.applyScreen)
addCycle(pVisual, "Цвет фильтра", "tintColorIdx", ESP_COLORS, X.applyScreen)
addSlider(pVisual, "Сила фильтра", "tintInt", 0, 0.8, 0.05, X.applyScreen)
addHeader(pVisual, "ПЕРСОНАЖ")
addToggle(pVisual, "Радужный персонаж", "rainbow", X.rainbowToggle)
addSlider(pVisual, "Скорость радуги", "rainbowSpeed", 0.2, 5, 0.1)
addToggle(pVisual, "След за персонажем", "trail", X.applyTrail)
addSlider(pVisual, "Длина следа", "trailLife", 0.2, 5, 0.1, X.applyTrail)
addToggle(pVisual, "Аура из частиц", "aura", X.applyAura)
addSlider(pVisual, "Плотность ауры", "auraRate", 5, 200, 5, X.applyAura)
addCycle(pVisual, "Цвет следа и ауры", "trailColorIdx", ESP_COLORS, X.applyColors)
addHeader(pVisual, "ИНТЕРФЕЙС")
addToggle(pVisual, "Скрыть интерфейс Roblox", "hideCore", X.applyCore)

-- ИГРОКИ
local pPlayers = addTab("Игроки", 4)
addHeader(pPlayers, "РЕЖИМ ПО НАЖАТИЮ НА ИГРОКА")
addToggle(pPlayers, "Нажатие = прилипнуть (выкл = телепорт)", "attachMode")
addHeader(pPlayers, "ПРИЛИПАНИЕ")
addCycle(pPlayers, "Позиция", "attachPos", ATTACH_POS)
addSlider(pPlayers, "Расстояние", "attachDist", 0, 25, 0.5, nil, " st")
addSlider(pPlayers, "Плавность прилипания", "attachSmooth", 0.05, 1, 0.05)
addSlider(pPlayers, "Скорость орбиты", "orbitSpeed", 0.2, 10, 0.2)
addToggle(pPlayers, "Смотреть на игрока", "attachFace")
addToggle(pPlayers, "Авто-ноклип при прилипании", "attachNoclip")
addButton(pPlayers, "Отлипнуть", detach)
addHeader(pPlayers, "НАБЛЮДЕНИЕ")
addToggle(pPlayers, "Наблюдать за игроком", "spectate", X.spectateToggle)
addButton(pPlayers, "Следующая цель", X.nextSpectate)
addHeader(pPlayers, "НАСТРОЙКИ ТЕЛЕПОРТА")
addSlider(pPlayers, "Отступ от игрока", "tpOffset", 0, 20, 0.5, nil, " st")
addToggle(pPlayers, "Плавный телепорт", "tpSmooth")
addSlider(pPlayers, "Время перелёта", "tpTime", 0.1, 3, 0.1, nil, " c")
addHeader(pPlayers, "ИГРОКИ (нажми — телепорт)")

local function tpTo(p)
	local r = getRoot()
	local t = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not (r and t) then
		showToast("Игрок недоступен")
		return
	end
	local goal = t.CFrame * CFrame.new(0, 0, S.tpOffset)
	r.AssemblyLinearVelocity = Vector3.zero
	if S.tpSmooth then
		TweenService:Create(r, TweenInfo.new(S.tpTime, Enum.EasingStyle.Quad), {CFrame = goal}):Play()
	else
		r.CFrame = goal
	end
	showToast("Телепорт к " .. p.DisplayName)
end

local function rebuildPlayers()
	for _, c in ipairs(pPlayers:GetChildren()) do
		if c:IsA("TextButton") and c.Name == "PL" then c:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			local b = new("TextButton", {
				Name = "PL", Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.panel,
				Text = p.DisplayName .. "  (@" .. p.Name .. ")",
				Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 100, AutoButtonColor = false,
			}, pPlayers)
			corner(b, 10); stroke(b, 1, C.line)
			new("UIPadding", {PaddingLeft = UDim.new(0, 12)}, b)
			glassAdd(b)
			ripple(b); hover(b, C.panel, C.panelHover)
			b.Activated:Connect(function()
				if S.attachMode then attachTo(p) else tpTo(p) end
			end)
		end
	end
end
addButton(pPlayers, "Обновить список", rebuildPlayers)
conn(Players.PlayerAdded, function() task.wait(0.3) rebuildPlayers() end)
conn(Players.PlayerRemoving, function() task.wait(0.1) rebuildPlayers() end)
rebuildPlayers()

-- ЕЩЁ
local pMisc = addTab("Ещё", 5)
addHeader(pMisc, "МИР")
addSlider(pMisc, "Гравитация", "gravity", 0, 400, 5, function(v) Workspace.Gravity = v end)
addToggle(pMisc, "Анти-АФК", "antiAfk")
addHeader(pMisc, "ТОЧКИ И ВОЗРОЖДЕНИЕ")
addButton(pMisc, "Сохранить точку", X.saveSpot)
addButton(pMisc, "Вернуться к точке", X.loadSpot)
addToggle(pMisc, "Возрождение на месте смерти", "respawnDeath")
addHeader(pMisc, "ДЕЙСТВИЯ")
addButton(pMisc, "Сбросить персонажа", function()
	local h = getHum()
	if h then h.Health = 0 end
end)
addButton(pMisc, "Вернуться на спавн", function()
	local r = getRoot()
	local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if r and sp then
		r.CFrame = sp.CFrame + Vector3.new(0, 5, 0)
		showToast("Возврат на спавн")
	end
end)

-- МЕНЮ (настройки интерфейса)
local pHard = addTab("Хард", 6)
addHeader(pHard, "ТУРБО")
addToggle(pHard, "Турбо-полёт (множитель)", "turbo")
addSlider(pHard, "Множитель турбо", "turboMult", 1.5, 10, 0.5, nil, "x")
addHeader(pHard, "РАЗГОН (не включай вместе со скоростью бега)")
addToggle(pHard, "Разгон при беге", "rampOn", X.rampToggle)
addSlider(pHard, "Максимальная скорость разгона", "rampMax", 30, 400, 5)
addSlider(pHard, "Скорость набора", "rampRate", 5, 200, 5)
addHeader(pHard, "РЫВОК И РАКЕТА")
addToggle(pHard, "Кнопки Рывок/Ракета на экране", "hardBtns", X.applyHardBtns)
addSlider(pHard, "Сила рывка", "dashPower", 30, 400, 10)
addSlider(pHard, "Сила ракеты", "rocketPower", 50, 600, 10)
addButton(pHard, "Рывок вперёд", X.dash)
addButton(pHard, "Ракета вверх", X.rocket)
addHeader(pHard, "ТУР ПО ИГРОКАМ")
addToggle(pHard, "Авто-телепорт к каждому по очереди", "tour", X.tourToggle)
addSlider(pHard, "Пауза между игроками", "tourDelay", 1, 15, 0.5, nil, " c")

local pMenu = addTab("Меню", 7)
addHeader(pMenu, "ВНЕШНИЙ ВИД")
addSlider(pMenu, "Прозрачность меню", "menuTransp", 0, 0.95, 0.05, applyGlass)
addSlider(pMenu, "Размытие фона", "blurSize", 0, 40, 1, function(v)
	if menuOpen then blur.Size = v end
end)
addToggle(pMenu, "HUD (FPS / пинг)", "hud")
addSlider(pMenu, "Размер меню", "menuScale", 0.6, 1.4, 0.05, function(v)
	if menuOpen then tw(mainScale, 0.2, {Scale = v}) end
end)
addSlider(pMenu, "Скорость анимаций", "animSpeed", 0.5, 2.5, 0.1, nil, "x")
addToggle(pMenu, "Частицы на фоне", "particles", function(on) fx.Visible = on end)
addToggle(pMenu, "Уведомления сверху", "toasts")
addHeader(pMenu, "БАННЕР")
addToggle(pMenu, "Показывать баннер", "banner")
addSlider(pMenu, "Время показа баннера", "bannerTime", 1, 10, 0.5, nil, " c")
addButton(pMenu, "Показать баннер сейчас", showBanner)
addHeader(pMenu, "СИСТЕМА")
addButton(pMenu, "Сбросить все значения", function()
	for key, setter in pairs(sliderSetters) do setter(DEFAULTS[key]) end
	showToast("Значения сброшены")
end)
addButton(pMenu, "Выгрузить скрипт", destroyAll)

---------------------------------------------------------------------
-- СТАРТ
---------------------------------------------------------------------
-- стеклянный эффект: регистрируем все панели
glassAdd(closeBtn)
for _, d in ipairs(pageHolder:GetDescendants()) do
	if d:IsA("GuiObject") and d.BackgroundColor3 == C.panel and d.BackgroundTransparency == 0 then glassAdd(d) end
end
for _, b in pairs(tabButtons) do glassAdd(b) end
applyGlass()
selectTab("Движ")
---------------------------------------------------------------------
-- ЭКРАН РЕГИСТРАЦИИ (ник + пароль)
---------------------------------------------------------------------
local function runLoginInner()
	local PASSWORD = "qpq"
	local NICK_MAX, PASS_MAX = 12, 24
	local ERR = Color3.fromRGB(255, 110, 110)
	local fit = math.clamp((viewport.Y - 24) / 262, 0.55, 1)

	local overlay = new("Frame", {
		Name = "Login", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, Active = true, ZIndex = 100,
	}, gui)
	tw(overlay, 0.5, {BackgroundTransparency = 0.45})
	tw(blur, 0.6, {Size = 18})

	local card = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 310, 0, 250), BackgroundColor3 = C.bg, BackgroundTransparency = 0.15,
	}, overlay)
	corner(card, 16)
	local cStroke = stroke(card, 2)
	local cGrad = new("UIGradient", {Color = SPIN_SEQ}, cStroke)
	local cScale = new("UIScale", {Scale = 0.9}, card)
	local rot = conn(RunService.RenderStepped, function()
		cGrad.Rotation = (os.clock() * 100) % 360
	end)

	new("TextLabel", {
		Position = UDim2.new(0, 20, 0, 16), Size = UDim2.new(1, -40, 0, 22), BackgroundTransparency = 1,
		Text = "Сделано Наумовым Максимом", Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)
	new("TextLabel", {
		Position = UDim2.new(0, 20, 0, 40), Size = UDim2.new(1, -40, 0, 18), BackgroundTransparency = 1,
		Text = "Регистрация", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local function field(y, placeholder, maxLen)
		local holder = new("Frame", {
			Position = UDim2.new(0, 20, 0, y), Size = UDim2.new(1, -40, 0, 44),
			BackgroundColor3 = C.panel, BackgroundTransparency = 0.2,
		}, card)
		corner(holder, 10)
		local st = stroke(holder, 1, C.line)
		local box = new("TextBox", {
			Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -66, 1, 0), BackgroundTransparency = 1,
			Text = "", PlaceholderText = placeholder, PlaceholderColor3 = C.dim, TextColor3 = C.text,
			Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
		}, holder)
		local cnt = new("TextLabel", {
			Position = UDim2.new(1, -52, 0, 0), Size = UDim2.new(0, 42, 1, 0), BackgroundTransparency = 1,
			Text = "0/" .. maxLen, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.dim,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, holder)
		box.Focused:Connect(function() tw(st, 0.2, {Color = WHITE, Thickness = 2}) end)
		box.FocusLost:Connect(function() tw(st, 0.2, {Color = C.line, Thickness = 1}) end)
		return box, cnt
	end

	local nickBox, nickCnt = field(72, "Ник (до " .. NICK_MAX .. " символов)", NICK_MAX)
	local passBox, passCnt = field(124, "Пароль", PASS_MAX)

	nickBox:GetPropertyChangedSignal("Text"):Connect(function()
		local txt = nickBox.Text
		local len = utf8.len(txt) or #txt
		if len > NICK_MAX then
			nickBox.Text = txt:sub(1, utf8.offset(txt, NICK_MAX + 1) - 1)
			return
		end
		nickCnt.Text = len .. "/" .. NICK_MAX
	end)

	-- пароль скрыт точками, настоящий текст хранится отдельно
	local chars, updating = {}, false
	passBox:GetPropertyChangedSignal("Text"):Connect(function()
		if updating then return end
		local typed = {}
		for _, cp in utf8.codes(passBox.Text) do table.insert(typed, utf8.char(cp)) end
		local n, m = #typed, #chars
		local onlyDots = true
		for i = 1, math.min(n, m) do
			if typed[i] ~= "•" then onlyDots = false break end
		end
		if not onlyDots then
			chars = typed
		elseif n > m then
			for i = m + 1, n do table.insert(chars, typed[i]) end
		elseif n < m then
			for i = m, n + 1, -1 do table.remove(chars, i) end
		end
		while #chars > PASS_MAX do table.remove(chars) end
		updating = true
		passBox.Text = string.rep("•", #chars)
		updating = false
		passCnt.Text = #chars .. "/" .. PASS_MAX
	end)

	local errLabel = new("TextLabel", {
		Position = UDim2.new(0, 20, 0, 174), Size = UDim2.new(1, -40, 0, 18), BackgroundTransparency = 1,
		Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = ERR,
	}, card)

	local loginBtn = new("TextButton", {
		Position = UDim2.new(0, 20, 0, 196), Size = UDim2.new(1, -40, 0, 42), BackgroundColor3 = C.text,
		Text = "ВОЙТИ", Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = C.bg, AutoButtonColor = false,
	}, card)
	corner(loginBtn, 10)
	ripple(loginBtn)
	hover(loginBtn, C.text, Color3.fromRGB(215, 215, 215))

	local busy = false
	local function fail(msg)
		errLabel.Text = msg
		errLabel.TextTransparency = 1
		tw(errLabel, 0.2, {TextTransparency = 0})
		task.spawn(function()
			for _, dx in ipairs({10, -10, 7, -7, 3, 0}) do
				TweenService:Create(card, TweenInfo.new(0.05), {Position = UDim2.new(0.5, dx, 0.5, 0)}):Play()
				task.wait(0.05)
			end
		end)
	end

	local function success(nick)
		busy = true
		errLabel.Text = ""
		loginBtn.Text = "Добро пожаловать, " .. nick .. "!"
		loginBtn.TextSize = 12
		nickLabel.Text = nick
		task.wait(0.7)
		tw(cScale, 0.4, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tw(overlay, 0.45, {BackgroundTransparency = 1})
		tw(blur, 0.4, {Size = 0})
		task.wait(0.45)
		rot:Disconnect()
		overlay:Destroy()
		loggedIn = true
		openBtn.Visible = true
		nickPill.Visible = true
		openMenu()
	end

	local function submit()
		if busy then return end
		local nick = nickBox.Text
		nick = nick:gsub("^%s+", "")
		nick = nick:gsub("%s+$", "")
		if nick == "" then
			fail("Введи ник")
			return
		end
		if table.concat(chars) ~= PASSWORD then
			fail("Неверный пароль")
			return
		end
		task.spawn(function()
			local ok, e = pcall(success, nick)
			if not ok then
				busy = false
				errLabel.Text = "Ошибка: " .. tostring(e)
			en
		end)
	end

	loginBtn.Activated:Connect(function()
		local ok, e = pcall(submit)
		if not ok then errLabel.Text = "Ошибка: " .. tostring(e) end
	end)
	nickBox.FocusLost:Connect(function(enter)
		if enter then passBox:CaptureFocus() end
	end)
	passBox.FocusLost:Connect(function(enter)
		if enter then
			local ok, e = pcall(submit)
			if not ok then errLabel.Text = "Ошибка: " .. tostring(e) end
		end
	end)

	task.wait(0.15)
	tw(cScale, 0.6, {Scale = fit}, Enum.EasingStyle.Back)
end
local function runLogin()
	local ok, err = xpcall(runLoginInner, function(e) return tostring(e) end)
	if ok then return end
	warn("MaximMenu: ошибка экрана входа: " .. tostring(err))
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 430, 0, 190), BackgroundColor3 = C.bg, ZIndex = 200,
	}, gui)
	corner(panel, 14)
	stroke(panel, 2, Color3.fromRGB(255, 110, 110))
	new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 10), Size = UDim2.new(1, -28, 0, 20), BackgroundTransparency = 1,
		Text = "Ошибка запуска меню (сделай скриншот этого окна)", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 110, 110), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
	}, panel)
	new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(1, -28, 0, 110), BackgroundTransparency = 1,
		Text = tostring(err), Font = Enum.Font.Code, TextSize = 12, TextColor3 = WHITE, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 201,
	}, panel)
	local closeErr = new("TextButton", {
		Position = UDim2.new(0, 14, 1, -40), Size = UDim2.new(1, -28, 0, 30), BackgroundColor3 = C.text,
		Text = "Закрыть", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.bg, ZIndex = 201,
	}, panel)
	corner(closeErr, 8)
	closeErr.Activated:Connect(function()
		local lg = gui:FindFirstChild("Login")
		if lg then lg:Destroy() end
		panel:Destroy()
		tw(blur, 0.3, {Size = 0})
	end)
end
task.delay(0.3, runLogin)

