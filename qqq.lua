-- ============================================
-- ROBLOX MOBILE GUI SCRIPT
-- Автор: наумов максим
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- ============================================
-- ПЕРЕМЕННЫЕ СОСТОЯНИЯ
-- ============================================

local featureStates = {
	flight = false,
	parkour = false,
	aimbot = false,
	speedActive = false,
	jumpActive = false,
	nightVision = false
}

local settings = {
	flightSpeed = 50,
	walkSpeed = 16,
	sprintSpeed = 32,
	jumpPower = 50,
	aimbotFOV = 100,
	aimbotSensitivity = 0.5
}

-- ============================================
-- ФУНКЦИЯ СОЗДАНИЯ GUI
-- ============================================

local function createGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MobileGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- ====== ЗАГОЛОВОК ======
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	header.BorderSizePixel = 0
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextScaled = true
	header.Font = Enum.Font.GothamBold
	header.Text = "⚡ Сделано: НАУМОВ МАКСИМ ⚡"
	header.Parent = screenGui

	-- Декоративная полоса
	local headerBorder = Instance.new("Frame")
	headerBorder.Size = UDim2.new(1, 0, 0, 3)
	headerBorder.Position = UDim2.new(0, 0, 0, 50)
	headerBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	headerBorder.BorderSizePixel = 0
	headerBorder.Parent = screenGui

	-- ====== ОСНОВНОЕ МЕНЮ ======
	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(1, 0, 1, -53)
	menuFrame.Position = UDim2.new(0, 0, 0, 53)
	menuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	menuFrame.BorderSizePixel = 0
	menuFrame.Parent = screenGui

	-- ====== PADDING FRAME ======
	local paddingFrame = Instance.new("Frame")
	paddingFrame.Name = "PaddingFrame"
	paddingFrame.Size = UDim2.new(1, -20, 1, -20)
	paddingFrame.Position = UDim2.new(0, 10, 0, 10)
	paddingFrame.BackgroundTransparency = 1
	paddingFrame.Parent = menuFrame

	-- ====== СКРОЛЛ ЛИСТ ======
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.ScrollBarThickness = 8
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollingFrame.Parent = paddingFrame

	-- Layout для скролла
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Padding = UDim.new(0, 12)
	uiListLayout.Parent = scrollingFrame

	-- ====== ФУНКЦИЯ СОЗДАНИЯ КОНТЕЙНЕРА С КНОПКОЙ И СЛАЙДЕРОМ ======
	local function createFeatureContainer(title, hasSlider, sliderMin, sliderMax, sliderValue, sliderLabel, onToggle, onSliderChange, color)
		color = color or Color3.fromRGB(30, 30, 30)
		
		-- Основной контейнер
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, hasSlider and 130 or 60)
		container.BackgroundColor3 = color
		container.BorderSizePixel = 2
		container.BorderColor3 = Color3.fromRGB(255, 255, 255)
		container.Parent = scrollingFrame

		-- КНОПКА
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 60)
		button.Position = UDim2.new(0, 0, 0, 0)
		button.BackgroundTransparency = 0
		button.BackgroundColor3 = color
		button.BorderSizePixel = 0
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Text = title
		button.Parent = container

		-- Эффект при наведении
		local originalColor = button.BackgroundColor3
		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = originalColor
		end)

		-- Эффект нажатия
		button.MouseButton1Click:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			onToggle()
			task.wait(0.1)
			button.BackgroundColor3 = originalColor
		end)

		-- СЛАЙДЕР (если нужен)
		if hasSlider then
			-- Фон слайдера
			local sliderBackground = Instance.new("Frame")
			sliderBackground.Size = UDim2.new(1, -20, 0, 50)
			sliderBackground.Position = UDim2.new(0, 10, 0, 65)
			sliderBackground.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			sliderBackground.BorderSizePixel = 1
			sliderBackground.BorderColor3 = Color3.fromRGB(100, 100, 100)
			sliderBackground.Parent = container

			-- Лейбл значения
			local valueLabel = Instance.new("TextLabel")
			valueLabel.Size = UDim2.new(1, -20, 0, 20)
			valueLabel.Position = UDim2.new(0, 10, 0, 65)
			valueLabel.BackgroundTransparency = 1
			valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			valueLabel.TextScaled = true
			valueLabel.Font = Enum.Font.Gotham
			valueLabel.Text = sliderLabel .. ": " .. tostring(math.floor(sliderValue))
			valueLabel.Parent = container

			-- Сам слайдер
			local slider = Instance.new("Frame")
			slider.Name = "Slider"
			slider.Size = UDim2.new(1, -20, 0, 10)
			slider.Position = UDim2.new(0, 10, 0, 100)
			slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			slider.BorderSizePixel = 1
			slider.BorderColor3 = Color3.fromRGB(100, 100, 100)
			slider.Parent = container

			-- Ползунок
			local handle = Instance.new("Frame")
			handle.Name = "Handle"
			handle.Size = UDim2.new(0, 15, 1, 0)
			handle.Position = UDim2.new((sliderValue - sliderMin) / (sliderMax - sliderMin), -7, 0, 0)
			handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			handle.BorderSizePixel = 1
			handle.BorderColor3 = Color3.fromRGB(200, 200, 200)
			handle.Parent = slider

			-- Логика слайдера
			local dragging = false
			
			handle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			RunService.RenderStepped:Connect(function()
				if dragging then
					local mousePos = mouse.X
					local sliderPos = slider.AbsolutePosition.X
					local sliderSize = slider.AbsoluteSize.X
					
					local relativePos = math.max(0, math.min(mousePos - sliderPos, sliderSize))
					local percentage = relativePos / sliderSize
					
					sliderValue = sliderMin + (percentage * (sliderMax - sliderMin))
					sliderValue = math.floor(sliderValue)
					
					handle.Position = UDim2.new(percentage, -7, 0, 0)
					valueLabel.Text = sliderLabel .. ": " .. tostring(sliderValue)
					
					onSliderChange(sliderValue)
				end
			end)
		end

		return container
	end

	-- ====== СОЗДАНИЕ СТАТУС ЛАБЕЛЫ ======
	local function createStatusLabel(text)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 35)
		label.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		label.BorderSizePixel = 1
		label.BorderColor3 = Color3.fromRGB(100, 100, 100)
		label.TextColor3 = Color3.fromRGB(150, 150, 150)
		label.TextScaled = true
		label.Font = Enum.Font.Gotham
		label.Text = text
		label.Parent = scrollingFrame
		return label
	end

	-- ====== ПОЛЕТ С РЕГУЛИРОВКОЙ СКОРОСТИ ======
	createFeatureContainer(
		"✈️ ПОЛЕТ",
		true,
		10,
		150,
		settings.flightSpeed,
		"Скорость полета",
		function()
			featureStates.flight = not featureStates.flight
			if featureStates.flight then
				activateFlight()
			else
				deactivateFlight()
			end
		end,
		function(value)
			settings.flightSpeed = value
		end,
		Color3.fromRGB(40, 30, 30)
	)

	-- ====== ПРИПРЫЖКА (ПАРКУР) С РЕГУЛИРОВКОЙ ======
	createFeatureContainer(
		"🏃 ПРИПРЫЖКА (ПАРКУР)",
		true,
		50,
		150,
		settings.jumpPower,
		"Сила прыжка",
		function()
			featureStates.parkour = not featureStates.parkour
			if featureStates.parkour then
				activateParkour()
			end
		end,
		function(value)
			settings.jumpPower = value
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.JumpPower = value
			end
		end,
		Color3.fromRGB(30, 40, 30)
	)

	-- ====== AIMBOT С РЕГУЛИРОВКОЙ FOV И ЧУВСТВИТЕЛЬНОСТИ ======
	createFeatureContainer(
		"🎯 AIMBOT",
		true,
		30,
		200,
		settings.aimbotFOV,
		"Дальность видения (FOV)",
		function()
			featureStates.aimbot = not featureStates.aimbot
			if featureStates.aimbot then
				activateAimbot()
			else
				deactivateAimbot()
			end
		end,
		function(value)
			settings.aimbotFOV = value
		end,
		Color3.fromRGB(40, 35, 30)
	)

	-- ====== СКОРОСТЬ С РЕГУЛИРОВКОЙ МНОЖИТЕЛЯ ======
	createFeatureContainer(
		"⚡ УСКОРЕНИЕ",
		true,
		1.5,
		5,
		2,
		"Множитель скорости",
		function()
			featureStates.speedActive = not featureStates.speedActive
			if featureStates.speedActive then
				activateSpeed()
			else
				deactivateSpeed()
			end
		end,
		function(value)
			settings.sprintSpeed = settings.walkSpeed * value
			if featureStates.speedActive then
				local humanoid = player.Character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = settings.sprintSpeed
				end
			end
		end,
		Color3.fromRGB(35, 35, 40)
	)

	-- ====== СУПЕРПРЫЖОК С РЕГУЛИРОВКОЙ ======
	createFeatureContainer(
		"🚀 СУПЕРПРЫЖОК",
		true,
		30,
		200,
		100,
		"Сила прыжка",
		function()
			activateSuperJump()
		end,
		function(value)
			-- Параметр для суперпрыжка
		end,
		Color3.fromRGB(40, 30, 35)
	)

	-- ====== ТЕЛЕПОРТ К ИГРОКУ ======
	createFeatureContainer(
		"📍 ТЕЛЕПОРТ К ИГРОКУ",
		false,
		0,
		0,
		0,
		"",
		function()
			showPlayerTeleportMenu(screenGui)
		end,
		function() end,
		Color3.fromRGB(30, 35, 40)
	)

	-- ====== НОЧНОЕ ВИДЕНИЕ ======
	createFeatureContainer(
		"🌙 НОЧНОЕ ВИДЕНИЕ",
		false,
		0,
		0,
		0,
		"",
		function()
			featureStates.nightVision = not featureStates.nightVision
			toggleNightVision()
		end,
		function() end,
		Color3.fromRGB(35, 30, 40)
	)

	-- ====== НЕВИДИМОСТЬ (НОВАЯ ФИЧА) ======
	createFeatureContainer(
		"👻 НЕВИДИМОСТЬ",
		true,
		0.1,
		1,
		0.3,
		"Прозрачность",
		function()
			toggleInvisibility()
		end,
		function(value)
			setInvisibilityAlpha(value)
		end,
		Color3.fromRGB(35, 25, 35)
	)

	-- ====== СКОРОСТЬ ПОЛЕТА (ДОПОЛНИТЕЛЬНАЯ ЛЕЙБА) ======
	createStatusLabel("📊 СОСТОЯНИЕ: OK | FPS: 60")

	-- ====== КНОПКА ЗАКРЫТИЯ (СКРЫТИЯ) ======
	local hideButton = Instance.new("TextButton")
	hideButton.Name = "HideButton"
	hideButton.Size = UDim2.new(0, 50, 0, 50)
	hideButton.Position = UDim2.new(1, -60, 1, -60)
	hideButton.BackgroundColor3 = Color3.fromRGB
