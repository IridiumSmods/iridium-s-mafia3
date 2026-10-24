include("menu/Player.lua")
include("menu/Camera.lua")
include("menu/FpsLike.lua")
-- The game compiles each file itself and skips one it refuses, with only
-- "include() LOAD ERROR" in ScriptHook.log and its message lost: compiled once
-- more here, where the message can be read (if the game's Lua has loadfile).
if FpsLikeToggle == nil then
	local why = "unknown (no loadfile)"
	pcall(function()
		local _, err = loadfile("ScriptHook\\lua\\trainer\\menu\\FpsLike.lua")
		why = tostring(err)
	end)
	print("FpsLike.lua did not load (the game refused its code): no first-person view. The error: " .. why)
end
include("menu/TimeOfDay.lua")
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
	if FpsLikeDisable then
		FpsLikeDisable()
	end
    print("Trainer reloaded.")
end

function OnTick()
	if SafeTrainerOnTick then
		SafeTrainerOnTick()
	end
	FreecamUpdate()
	AutoReloadWeapons()
	if FpsLikeOnTick then
		FpsLikeOnTick()
	end
end
