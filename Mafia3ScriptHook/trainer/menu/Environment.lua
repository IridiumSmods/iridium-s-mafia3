include("menu/WeatherIDs.lua")

-------------
-- Weather --
-------------
local function SetWeather(menu, text, name)
	game.gfx:SetWeatherSet(name, 0, 0);
end

local function SetWeatherMenu()
	local menu = UI.SimpleMenu()
    menu:SetTitle("Set Weather")
	menu:AddSearch("Search", "Start typing to filter")

	for k,v in pairsByKeys(WeatherIDs) do
		menu:AddButton(k, v, SetWeather)
	end

	return menu
end

-----------------
-- Time of day --
-----------------
local function ChangeTimeFlowSpeed(time_speed_value)
	game.gfx:SetTimeFlowSpeed(time_speed_value)
end

local function TimeSetHour(time_value)
	game.gfx:SetTime(time_value, 0.0)
end

local function TimeFlowSpeedMenu()
	UI.SimpleTextInput("Enter speed value (Use only integers)", function(success, text)
		if success then
			ChangeTimeFlowSpeed(text)
		else
			print("Dialog was canceled")
		end
	end)
end

local function TimeSetHourMenu()
	UI.SimpleTextInput("Enter time value (Use only integers)", function(success, time_text)
		if success then
			TimeSetHour(time_text)
		else
			print("Dialog was canceled")
		end
	end)
end

local function TimeAddHour()
	dayTime = game.gfx:GetTime()
	if dayTime > 23 then
		dayTime = dayTime - 23
	end
	game.gfx:SetTime(dayTime + 1, 0.0)
end

local function TimeRemoveHour()
	dayTime = game.gfx:GetTime()
	if dayTime < 1 then
		dayTime = dayTime + 23
	end
	game.gfx:SetTime(dayTime - 1, 0.0)
end

local function GetRealTime()
	local realTime = os.date("*t")
	local realSeconds = realTime.sec / 60
	local realMinutes = (realTime.min + realSeconds) / 60
	local realHours = realTime.hour + realMinutes
	
	return realHours
end

local function PrintCurrentTime()
	print(game.gfx:GetTime())
	
	StartThread(function()
		local i = 0
		local diff = 0
		while i < 10 do
			local t = game.gfx:GetTime()
			Sleep(1000)
			diff = diff + (game.gfx:GetTime() - t)
			i = i + 1
		end
		print(diff / 10)
	end)
end

local function AddRemoveHourMenu()
	local menu = UI.SimpleMenu()
    menu:SetTitle("Change time of day")

	menu:AddButton("Add Hour", TimeAddHour)
	menu:AddButton("Remove Hour", TimeRemoveHour)
	menu:AddButton("Set Time of Day", TimeSetHourMenu)
	menu:AddButton("Change Timeflow Speed", TimeFlowSpeedMenu)
	menu:AddButton("Print Current Time", PrintCurrentTime)

	return menu
end

-------------
-- Spawner --
-------------
local function SetSpawnerStateMenu()
	local menu = UI.SimpleMenu()
    menu:SetTitle("Set Spawner State")

    menu:AddButton("Enable Population", function() 
        game.traffic:SwitchGenerators(true)
        game.traffic:Populate(100)
    end)

    menu:AddButton("Disable Population", function() 
        game.traffic:SwitchGenerators(false)
    end)

	return menu
end

---------------------
-- Water Visiblity --
---------------------
local function SetWaterVisibilityMenu()
	local menu = UI.SimpleMenu()
    menu:SetTitle("Set Water Visibility")

    menu:AddButton("Visible", function() 
        game.game:SetWaterVisibility(true)
    end)

    menu:AddButton("Hidden", function() 
        game.game:SetWaterVisibility(false)
    end)

	return menu
end

---------
-- HUD --
---------
local function EnvironmentMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Environment - World")
	
    menu:AddButton("Set Spawner State", SetSpawnerStateMenu)
    menu:AddButton("Set Weather", SetWeatherMenu)
	menu:AddButton("Change time of day", AddRemoveHourMenu)
    menu:AddButton("Set Water Visibility", SetWaterVisibilityMenu)
    
	return menu
end

table.insert(TrainerMenuItems, { "Environment", "Modify the world", EnvironmentMenu })