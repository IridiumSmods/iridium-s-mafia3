----------------
-- Game Speed --
----------------
local function ChangeGameSpeed(speed_value)
	game.game:ModifyGameTime(speed_value,1)
end

local function GameSpeedMenu()
	UI.SimpleTextInput("Enter speed value 0-1", function(success, text)
		if success then
			ChangeGameSpeed(text)
		else
			print("Dialog was canceled")
		end
	end)
end

---------------------------
-- Clear Weapons in Area --
---------------------------
local function ClearWeaponsInArea()
	game.game:ClearWeaponsInRadius(game.game:GetActivePlayer():GetPos(), 20)
end

-------------------
-- Count Corpses --
-------------------
local function CountCorpsesInArea()
	var = game.game:GetCorpseCountAroundPos(game.game:GetActivePlayer():GetPos(), 100)
	print(var)
end

-------------
-- Traffic --
-------------
local function TrafficMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Traffic Menu")
	
    menu:AddButton("Close Season", function()
		game.traffic:CloseSeason()
	end)
	menu:AddButton("Open Season", function()
		game.traffic:CloseSeason()
		game.traffic:OpenSeason(1)
	end)
	
	return menu
end

---------
-- HUD --
---------
local function WorldMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Game World")
	
	menu:AddButton("Change Game Speed", GameSpeedMenu)
	menu:AddButton("Traffic Menu", TrafficMenu)
	menu:AddButton("Count Corpses in Area", CountCorpsesInArea)
	menu:AddButton("Clear Weapons in Area", ClearWeaponsInArea)
	
	return menu
end

table.insert(TrainerMenuItems, { "Game World", "Modify game parameters", WorldMenu })