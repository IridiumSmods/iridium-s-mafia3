-------------------------------------------------------
-- Scripthook Revamped by Kamzik123 - Police Submenu --
-------------------------------------------------------
-----------
-- Utils --
-----------
local function GetPlayer()
	player = game.game:GetActivePlayer()
	return player
end

local function GetPlayerPos()
	playerpos = GetPlayer():GetPos()
	return playerpos
end

local function GetPlayerDir()
	playerdir = GetPlayer():GetDir()
	return playerdir
end

local function SetWanted(Level)
	game.police:ZoneDeleteAll()
	game.police:ZoneCreate(GetPlayerPos(), enums.PoliceZoneType.HUNT, Level)
end

---------------------
-- Wanted Settings --
---------------------
local WantedLevel = 1

local function WantedLevelMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Wanted Level Settings")
	menu:AddButton("0", function()
        game.police:ZoneDeleteAll()
    end)
	menu:AddButton("1", function()
        SetWanted(1)
    end)
	menu:AddButton("2", function()
        SetWanted(2)
    end)
	menu:AddButton("3", function()
        SetWanted(3)
    end)
	menu:AddButton("4", function()
        SetWanted(4)
    end)
	menu:AddButton("5", function()
        SetWanted(5)
    end)
	menu:AddButton("Set Current Level as Max Wanted Level", function()
        game.police:ClampEscalationLevel(WantedLevel)
    end)
	menu:AddButton("Lock Wanted Level", function()
		game.police:PreventZonesDecay(true)
	end)
	menu:AddButton("Unlock Wanted Level", function()
		game.police:PreventZonesDecay(false)
	end)
	return menu
end

local function OffencesMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Enable/Disable Offences")
	
	menu:AddButton("Enable Offences", function()
        game.police:DisableOffencesGlobal(false)
    end)
	
	menu:AddButton("Disable Offences", function()
        game.police:DisableOffencesGlobal(true)
    end)
	
	return menu
end

local function DispatchMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Enable/Disable Dispatch")
	
	menu:AddButton("Enable Dispatch", function()
        game.police:PreventDispatchSpeech(false)
    end)
	
	menu:AddButton("Disable Dispatch", function()
        game.police:PreventDispatchSpeech(true)
    end)
	
	return menu
end

local function PoliceMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Police")
	
	menu:AddButton("Wanted Settings", WantedLevelMenu)
	menu:AddButton("Enable/Disable Dispatch", DispatchMenu)
	menu:AddButton("Enable/Disable Offences","Doesn't prevent police spawn", OffencesMenu)
	
    menu:AddButton("Enable", function()
        game.police:Enable()
    end)
    
    menu:AddButton("Disable", function()
        game.police:Disable()
    end)
    

	return menu
end

table.insert(TrainerMenuItems, { "Police", "Mess with the police", PoliceMenu })