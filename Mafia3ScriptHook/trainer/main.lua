include("menu/Player.lua")
include("menu/Camera.lua")
include("menu/Weapons.lua")
include("menu/Police.lua")
include("menu/Vehicle.lua")
include("menu/Environment.lua")
include("menu/World.lua")

local function ClearDataStore()
	DatastoreSet("Noclip", false)
end

function OnLoad()
	ClearDataStore()
    print("Trainer loaded.")
end

function OnReload()
	ClearDataStore()
    print("Trainer reloaded.")
end

function OnTick()
	FreecamUpdate()
	AutoReloadWeapons()
end