-- Top-level Time of Day menu (easy access; also still under Environment)

local function getHour()
	local ok, t = pcall(function()
		return game.gfx:GetTime()
	end)
	if ok and t ~= nil then
		return tonumber(t) or 0
	end
	return 0
end

local function setHour(h)
	h = tonumber(h)
	if h == nil then
		print("Time: bad hour")
		return
	end
	-- wrap 0..24
	while h < 0 do
		h = h + 24
	end
	while h >= 24 do
		h = h - 24
	end
	pcall(function()
		game.gfx:SetTime(h, 0.0)
	end)
	print(string.format("Time set to %.2f (GetTime=%.2f)", h, getHour()))
end

local function addHours(delta)
	setHour(getHour() + delta)
end

local function SetTimeInput()
	UI.SimpleTextInput("Hour 0-23 (e.g. 12 = noon, 22 = night)", function(success, text)
		if success then
			setHour(text)
		end
	end)
end

local function TimeFlowSpeedInput()
	UI.SimpleTextInput("Time flow speed (1 = normal, 0 = freeze, 10 = fast)", function(success, text)
		if success then
			local v = tonumber(text)
			if v ~= nil then
				pcall(function()
					game.gfx:SetTimeFlowSpeed(v)
				end)
				print("TimeFlowSpeed=" .. tostring(v))
			end
		end
	end)
end

function TimeOfDayMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Time of Day")

	local nowBtn = menu:AddButton("Current: ...", function()
		print("GetTime=" .. tostring(getHour()))
	end)

	menu:AddButton("+1 Hour", function()
		addHours(1)
	end)
	menu:AddButton("-1 Hour", function()
		addHours(-1)
	end)
	menu:AddButton("+3 Hours", function()
		addHours(3)
	end)
	menu:AddButton("-3 Hours", function()
		addHours(-3)
	end)

	menu:AddButton("Preset: Dawn (6)", function()
		setHour(6)
	end)
	menu:AddButton("Preset: Morning (9)", function()
		setHour(9)
	end)
	menu:AddButton("Preset: Noon (12)", function()
		setHour(12)
	end)
	menu:AddButton("Preset: Afternoon (16)", function()
		setHour(16)
	end)
	menu:AddButton("Preset: Sunset (19)", function()
		setHour(19)
	end)
	menu:AddButton("Preset: Night (22)", function()
		setHour(22)
	end)
	menu:AddButton("Preset: Midnight (0)", function()
		setHour(0)
	end)

	menu:AddButton("Set exact hour...", SetTimeInput)
	menu:AddButton("Time flow speed...", TimeFlowSpeedInput)
	menu:AddButton("Freeze time (speed 0)", function()
		pcall(function()
			game.gfx:SetTimeFlowSpeed(0)
		end)
		print("Time frozen")
	end)
	menu:AddButton("Normal time flow (speed 1)", function()
		pcall(function()
			game.gfx:SetTimeFlowSpeed(1)
		end)
		print("Time flow normal")
	end)

	menu:OnUpdate(function()
		menu:SetEntryText(nowBtn, string.format("Current hour: %.2f", getHour()))
	end)

	return menu
end

-- Time now lives in the hub (World → Time); this file stays for TimeOfDayMenu only.
