-- The self-check (Settings), and what the menus ask before they offer a row (2026-10-21).
--
-- Every row of the trainer has a check under its own key (the key of its label,
-- or an alias): the game calls the row needs, and where a call can be tried
-- without changing the game for good, a probe that makes it and reads the
-- answer back. A row whose calls are missing, or whose probe failed in the last
-- check, stays in its menu greyed out with "does not work"; nothing is removed.
-- "Switched off" is a part known not to work here or no longer used: it stays in
-- the list with the reason. The old check asked only whether a call existed,
-- for part of the rows, and its side mouse button check was deleted when the
-- button was dropped.
--
-- Needs: "player:Method" on the player, "car:Method" on the car he sits in
-- (not checked on foot), "traffic:", "police:", "gfx:", "radio:", "game:"
-- (game.game), "camera:" (the player's camera), "physics:" the same way,
-- "player.prop" a readable property, "parts:Name" a part of the old trainer,
-- "fn:Name" a global function and "data:Name" a global table with entries
-- (both looked up in Globals: no _G in the game's Lua).
-- Probes return ok (true / false / nil = could not tell) and a detail text;
-- `slow` probes wait for the game and run one after another in a thread. They
-- are called without pcall and guard each game call themselves: yielding
-- through pcall breaks the game's Lua threads (see waitFor in main.lua).

local T = Hub.T
local say = Hub.say
local dbg = Hub.dbg
local activePlayer = Hub.activePlayer

Checks = {}

local Globals = {
	Notify = function() return Notify end,
	StartThread = function() return StartThread end,
	Sleep = function() return Sleep end,
	Wait = function() return Wait end,
	SetTrafficDensity = function() return SetTrafficDensity end,
	SetTrafficLimits = function() return SetTrafficLimits end,
	_ui_set_enabled = function() return _ui_set_enabled end,
	_ui_update_entry = function() return _ui_update_entry end,
	_ui_update_hint = function() return _ui_update_hint end,
	_ui_set_checked = function() return _ui_set_checked end,
	_ui_select_list_live = function() return _ui_select_list_live end,
	_ui_text_input = function() return _ui_text_input end,
	_ui_get_setting = function() return _ui_get_setting end,
	_ui_set_setting = function() return _ui_set_setting end,
	_ui_set_language = function() return _ui_set_language end,
	_ui_set_theme = function() return _ui_set_theme end,
	_ui_set_look = function() return _ui_set_look end,
	_input_aim_held = function() return _input_aim_held end,
	_input_melee_age = function() return _input_melee_age end,
	_input_key_down = function() return _input_key_down end,
	_input_block_melee = function() return _input_block_melee end,
	_input_has_mouse4 = function() return _input_has_mouse4 end,
	FpsLikeToggle = function() return FpsLikeToggle end,
	FpsLikeOnTick = function() return FpsLikeOnTick end,
	SafeTrainerOnTick = function() return SafeTrainerOnTick end,
	VehicleModelIDs = function() return VehicleModelIDs end,
	BoatModelIDs = function() return BoatModelIDs end,
	HashDatabase = function() return HashDatabase end,
	enums = function() return enums end,
}

-- Needs that are the trainer's own: missing, their file did not load. The game
-- compiles each file itself and skips one it refuses, with only "include() LOAD
-- ERROR" in ScriptHook.log, so the row names the file rather than the game
-- (FpsLike.lua, 2026-10-22: "The game lacks: fn:FpsLikeToggle").
local OwnFile = { ["fn:FpsLikeToggle"] = "FpsLike.lua", ["fn:FpsLikeOnTick"] = "FpsLike.lua",
	["parts:EyeCameraMenu"] = "FpsLike.lua", ["fn:SafeTrainerOnTick"] = "safe_trainer\\main.lua" }

local function needText(m)
	return OwnFile[m] and T("chk_unloaded", OwnFile[m]) or T("chk_need", m)
end

local function has(obj, name)
	if obj == nil then
		return false
	end
	local ok, v = pcall(function()
		return obj[name]
	end)
	return ok and v ~= nil
end

local function carOf(p)
	local ok, v = pcall(function()
		return p:GetOwner()
	end)
	return ok and v or nil
end

local Objects = {
	player = function(p) return p end,
	car = carOf,
	traffic = function() return game and game.traffic end,
	police = function() return game and game.police end,
	gfx = function() return game and game.gfx end,
	radio = function() return game and game.radio end,
	game = function() return game and game.game end,
	physics = function() return game and game.physics end,
	camera = function()
		local ok, c = pcall(function()
			return game.cameramanager:GetPlayerCamera()
		end)
		return ok and c or nil
	end,
}

-- nil when every need is there; "skip" when the car is needed and he is on
-- foot; else the first need that is missing.
local function missing(needs, p)
	for _, n in ipairs(needs or {}) do
		local kind, name = n:match("^([%a_]+):(.+)$")
		if kind == "parts" then
			if TrainerParts == nil or TrainerParts[name] == nil then
				return n
			end
		elseif kind == "fn" then
			local get = Globals[name]
			if get == nil or type(get()) ~= "function" then
				return n
			end
		elseif kind == "data" then
			local get = Globals[name]
			local t = get and get()
			if type(t) ~= "table" or next(t) == nil then
				return n
			end
		elseif kind ~= nil then
			local get = Objects[kind]
			local obj = get and get(p)
			if obj == nil then
				if kind == "car" then
					return "skip"
				end
				return n
			end
			if not has(obj, name) then
				return n
			end
		else
			local o, prop = n:match("^(%a+)%.(.+)$")
			local get = o and Objects[o]
			local obj = get and get(p)
			local ok, v = pcall(function()
				return obj[prop]
			end)
			if not ok or v == nil then
				return n
			end
		end
	end
	return nil
end

local function readNum(fn)
	local ok, v = pcall(fn)
	if ok and type(v) == "number" then
		return v
	end
	return nil
end

local function fp(name)
	return FpsLikeProbe ~= nil and FpsLikeProbe[name] or nil
end

local function fmt1(v)
	return v and string.format("%.1f", v) or "?"
end

---------------
-- The checks --
---------------

-- Order and groups are those of the menus; `label` is the row's key when it differs.
local List = {
	-- the base the rest stands on
	{ id = "chk_notify", group = "chk_grp_base", needs = { "fn:Notify" } },
	{ id = "chk_threads", group = "chk_grp_base", needs = { "fn:StartThread", "fn:Sleep", "fn:Wait" } },
	{ id = "chk_menu_api", group = "chk_grp_base",
		needs = { "fn:_ui_set_enabled", "fn:_ui_update_entry", "fn:_ui_update_hint", "fn:_ui_set_checked", "fn:_ui_select_list_live" } },
	{ id = "chk_text_input", group = "chk_grp_base", needs = { "fn:_ui_text_input" } },
	{ id = "chk_settings", group = "chk_grp_base", needs = { "fn:_ui_get_setting", "fn:_ui_set_setting" },
		probe = function()
			local stamp = tostring(os.time())
			_ui_set_setting("CheckStamp", stamp)
			return _ui_get_setting("CheckStamp") == stamp, T("chk_settings_d")
		end },
	{ id = "chk_input_aim", group = "chk_grp_base", needs = { "fn:_input_aim_held" },
		probe = function()
			local ok, v = pcall(_input_aim_held)
			return ok and (type(v) == "number" or type(v) == "boolean"), T("chk_input_aim_d")
		end },
	{ id = "chk_input_q", group = "chk_grp_base", needs = { "fn:_input_melee_age" },
		probe = function()
			local ok, v = pcall(_input_melee_age)
			return ok and type(v) == "number", T("chk_input_q_d")
		end },
	{ id = "chk_input_keys", group = "chk_grp_base", needs = { "fn:_input_key_down" },
		probe = function()
			local ok, v = pcall(_input_key_down, 0x74)
			return ok and (type(v) == "number" or type(v) == "boolean"), T("chk_input_keys_d")
		end },
	{ id = "chk_input_melee", group = "chk_grp_base", needs = { "fn:_input_block_melee" },
		probe = function()
			return (pcall(_input_block_melee, 0)), T("chk_input_melee_d")
		end },
	{ id = "chk_mouse4", group = "chk_grp_base", needs = { "fn:_input_has_mouse4" },
		off = function() return T("chk_mouse4_off") end },
	{ id = "chk_data", group = "chk_grp_base", needs = { "data:VehicleModelIDs", "data:BoatModelIDs", "data:HashDatabase", "data:enums" } },
	{ id = "chk_modules", group = "chk_grp_base", needs = { "fn:SafeTrainerOnTick", "fn:FpsLikeToggle", "fn:FpsLikeOnTick" },
		probe = function()
			local ok = Mobility ~= nil and Mobility.Maintain ~= nil and Brawl ~= nil and Brawl.Maintain ~= nil
				and StreetFight ~= nil and StreetFight.Set ~= nil and Maintain ~= nil and Maintain.OnTick ~= nil
			return ok, T("chk_modules_d")
		end },
	{ id = "chk_tick", group = "chk_grp_base", needs = { "fn:SafeTrainerOnTick" },
		probe = function()
			local ok, err = pcall(SafeTrainerOnTick)
			return ok, ok and T("chk_tick_d") or tostring(err)
		end },

	-- player
	{ id = "heal", group = "sec_player", needs = { "player:SetMaxHealth" },
		probe = function(p)
			local h, hm = readNum(function() return p.health end), readNum(function() return p.healthmax end)
			return h ~= nil and hm ~= nil, T("chk_health_d", fmt1(h), fmt1(hm))
		end },
	{ id = "mobility", group = "sec_player", needs = { "player:GetPos", "player:SetPos", "player:GetDir", "player:GetOwner" } },
	{ id = "jump", group = "sec_player", needs = { "player:GetPos", "player:SetPos", "player:GetDir", "fn:StartThread" } },
	{ id = "god", group = "sec_player", needs = { "player.invulnerability", "player:SetDemigod", "player:EnableInjury" },
		probe = function(p)
			local inv = Hub.readBool(function() return p.invulnerability end)
			if inv == nil then
				return false, T("chk_need", "player.invulnerability")
			end
			pcall(function() p.invulnerability = not inv end)
			local flipped = Hub.readBool(function() return p.invulnerability end)
			pcall(function() p.invulnerability = inv end)
			return flipped == (not inv), T("chk_god_d")
		end },
	{ id = "ammo", group = "sec_player", needs = { "player:InventoryLoadWeapons" } },
	{ id = "infammo", group = "sec_player", needs = { "player:InventorySetUnlimitedAmmo" } },
	{ id = "giveweapon", group = "sec_player", needs = { "parts:GiveWeaponMenu" } },
	{ id = "grenades", group = "sec_player", needs = { "player:InventoryAddGrenades" } },
	{ id = "molotovs", group = "sec_player", needs = { "player:InventoryAddAmmoByCategory" } },
	{ id = "clearinv", group = "sec_player", needs = { "player:ClearInventory" } },
	{ id = "money", group = "sec_player", needs = { "parts:GiveMoney" } },
	{ id = "relays", group = "sec_player", needs = { "parts:GiveRelays" } },
	{ id = "smoke", group = "sec_player",
		needs = { "player:AnimPlay", "player:AnimStop", "player:LockControlsToPlayAnim", "player:LockControls", "player:AreControlsLocked",
			"fn:StartThread" } },
	-- standing: switched off once the player's graph had none of the clips; sitting is a clip of its own
	{ id = "smoke_stand", group = "sec_player", needs = { "player:AnimPlay", "player:LockControlsToPlayAnim", "fn:StartThread" },
		off = function() return Hub.noSmoke ~= nil and Hub.noSmoke() and T("test_smoke_no") or nil end },
	{ id = "smoke_sit", group = "sec_player", needs = { "player:AnimPlay", "player:LockControlsToPlayAnim", "fn:StartThread" } },
	{ id = "model", group = "sec_player", needs = { "parts:ChangeModelMenu" } },
	{ id = "visible", group = "sec_player", needs = { "parts:ToggleModelVisibility", "player:IsModelVisible" } },
	{ id = "noclip", group = "sec_player", needs = { "parts:NoclipMenu" } },
	{ id = "aimcar", group = "sec_player", needs = { "parts:TeleportIntoAimedVehicle" } },
	{ id = "unlock", group = "sec_player", needs = { "parts:RestoreInput" } },
	{ id = "lockctl", group = "sec_player", needs = { "parts:ToggleControlsLock", "player:AreControlsLocked" } },
	{ id = "cloth", group = "sec_player", needs = { "parts:ToggleCloth", "player:IsClothSimulated" } },
	{ id = "physics", group = "sec_player", needs = { "parts:TogglePhysics" } },
	{ id = "pinfo", group = "sec_player", needs = { "parts:PlayerInfoMenu" } },
	-- the street fight is switched off until it works right (asked 2026-10-21):
	-- greyed in the menu with the reason, the code kept
	{ id = "brawl_mode", group = "sec_player",
		needs = { "player:GetControlStyleStr", "player:SetControlStyleStr", "player:IsMeleeFighting", "physics:GetActorInScreenCenter" },
		off = function() return T("chk_brawl_off") end,
		probe = function(p)
			local ok, s = pcall(function() return p:GetControlStyleStr() end)
			return ok and type(s) == "string" and s ~= "", T("chk_style_d", tostring(s))
		end },
	{ id = "brawl_hits", group = "sec_player", needs = { "player.health", "fn:_input_block_melee" },
		off = function() return T("chk_brawl_off") end,
		probe = function(p)
			-- the count works through a target's health: write it, read it back, put it back
			local h = readNum(function() return p.health end)
			if h == nil or h <= 1 then
				return nil, T("chk_health_low")
			end
			pcall(function() p.health = h - 0.5 end)
			local got = readNum(function() return p.health end)
			pcall(function() p.health = h end)
			return got ~= nil and math.abs(got - (h - 0.5)) < 0.01, T("chk_health_write_d")
		end },

	-- vehicles
	{ id = "spawncar", group = "sec_vehicle",
		needs = { "traffic:ObtainSpecificCar", "traffic:SpawnCar", "traffic:GetSpawnedEntity", "traffic:DespawnEntity",
			"player:MakeCarOwnership", "data:VehicleModelIDs", "fn:StartThread", "fn:Wait" } },
	{ id = "spawnboat", group = "sec_vehicle",
		needs = { "traffic:ObtainSpecificBoat", "traffic:SpawnBoat", "traffic:GetSpawnedEntity", "data:BoatModelIDs", "fn:StartThread" } },
	{ id = "repair", group = "sec_vehicle", needs = { "car:Repair", "car:SetMotorDamage" } },
	{ id = "boost", group = "sec_vehicle", needs = { "car:SetSpeed", "car:GetSpeedFloat" } },
	{ id = "engine", group = "sec_vehicle", needs = { "car:SetEngineOn" } },
	{ id = "lights", group = "sec_vehicle", needs = { "car:SetLightState" } },
	{ id = "siren", group = "sec_vehicle", needs = { "car:SetSirenOn" } },
	{ id = "radio", group = "sec_vehicle", needs = { "radio:SetOn" } },
	{ id = "vgod", group = "sec_vehicle", needs = { "car:SetResistance" } },
	{ id = "noexplode", group = "sec_vehicle", needs = { "car:DisableExplosion", "car:IsDisableExplosion" } },
	{ id = "nodespawn", group = "sec_vehicle", needs = { "car:SetDespawnImmunity" } },
	{ id = "tires", group = "sec_vehicle", needs = { "car:SetWheelsProtected" } },
	{ id = "doors", group = "sec_vehicle", needs = { "car:OpenHood", "car:CloseHood", "car:OpenTrunk", "car:CloseTrunk", "car:OpenSeatWindow" } },
	{ id = "looks", group = "sec_vehicle", needs = { "parts:SetAffectedVehicle" } },
	{ id = "colors", group = "sec_vehicle", needs = { "parts:VehicleColorsMenu" } },
	{ id = "tint", group = "sec_vehicle", needs = { "parts:WindowTintMenu" } },
	{ id = "wheels_f", group = "sec_vehicle", needs = { "parts:FrontWheelsMenu" } },
	{ id = "wheels_r", group = "sec_vehicle", needs = { "parts:RearWheelsMenu" } },
	{ id = "plate", group = "sec_vehicle", needs = { "parts:PlateTextInput" } },
	{ id = "fuel", group = "sec_vehicle", needs = { "parts:FuelInput" } },
	{ id = "rust", group = "sec_vehicle", needs = { "parts:RustInput" } },
	{ id = "dirt", group = "sec_vehicle", needs = { "parts:DirtInput" } },
	{ id = "steerplay", group = "sec_vehicle", needs = { "parts:SteeringPlayInput" } },
	{ id = "steeroff", group = "sec_vehicle", needs = { "parts:SteeringOffsetInput" } },
	{ id = "handling", group = "sec_vehicle", needs = { "parts:HandlingInput" } },
	{ id = "vinfo", group = "sec_vehicle", needs = { "parts:VehicleInfoMenu" } },
	{ id = "launch", group = "sec_vehicle", needs = { "parts:LaunchVehicleUp" } },
	{ id = "leave", group = "sec_vehicle", needs = { "parts:LeaveVehicle" } },

	-- people
	{ id = "squad", label = "chk_squad", group = "sec_people",
		needs = { "traffic:ObtainCarWithCrew", "traffic:SpawnCar", "traffic:GetSpawnedEntity", "traffic:DespawnEntity",
			"player:GetOffVehicle", "fn:StartThread", "fn:Wait" } },
	{ id = "squad_smoke", group = "sec_people", needs = { "player:AnimPlay", "player:IsDeath", "fn:StartThread" } },
	{ id = "clear_squad", group = "sec_people", needs = { "traffic:DespawnEntity" } },

	-- world
	{ id = "hour", group = "sec_world", needs = { "gfx:SetTime", "gfx:GetTime" },
		slow = function()
			-- a quarter of an hour on and back: the hour reads back a moment later
			local t = readNum(function() return game.gfx:GetTime() end)
			if t == nil then
				return false, T("chk_need", "gfx:GetTime")
			end
			local want = (t + 0.25) % 24
			pcall(function() game.gfx:SetTime(want, 0.0) end)
			Sleep(400)
			local got = readNum(function() return game.gfx:GetTime() end)
			pcall(function() game.gfx:SetTime(t, 0.0) end)
			local d = got and math.abs(got - want) or 99
			return math.min(d, 24 - d) < 0.1, T("chk_hour_d", fmt1(want), fmt1(got))
		end },
	{ id = "flow", group = "sec_world", needs = { "gfx:SetTimeFlowSpeed" } },
	{ id = "exact", group = "sec_world", needs = { "gfx:SetTime", "fn:_ui_text_input" } },
	{ id = "weather", group = "sec_world", needs = { "parts:WeatherMenu" } },
	{ id = "density", group = "sec_world",
		needs = { "fn:SetTrafficDensity", "fn:SetTrafficLimits", "traffic:SwitchGenerators", "traffic:SetEnableAmbientTrafficSpawning",
			"traffic:Populate", "traffic:GetIsAmbientTrafficOn" },
		probe = function()
			local on = Hub.readBool(function() return game.traffic:GetIsAmbientTrafficOn() end)
			return on ~= nil, T("chk_traffic_d", tostring(on))
		end },
	{ id = "clear_wanted", group = "sec_world", needs = { "police:PreventZonesDecay", "police:ZoneDeleteAll" } },
	{ id = "wanted", group = "sec_world", needs = { "police:ZoneDeleteAll", "police:ZoneCreate", "data:enums" } },
	{ id = "wanted_hold", group = "sec_world", needs = { "police:PreventZonesDecay" } },
	{ id = "nooffence", group = "sec_world", needs = { "police:DisableOffencesGlobal" } },
	{ id = "nodispatch", group = "sec_world", needs = { "police:PreventDispatchSpeech" } },
	{ id = "police_off", group = "sec_world", needs = { "police:Disable", "police:Enable" } },
	{ id = "water", group = "sec_world", needs = { "game:SetWaterVisibility" } },
	{ id = "clearweap", group = "sec_world", needs = { "game:ClearWeaponsInRadius" } },
	{ id = "corpses", group = "sec_world", needs = { "game:GetCorpseCountAroundPos" },
		probe = function(p)
			local n = readNum(function() return game.game:GetCorpseCountAroundPos(p:GetPos(), 1) end)
			return n ~= nil, T("chk_corpses_d")
		end },

	-- camera
	{ id = "eyecam", group = "sec_camera",
		needs = { "fn:FpsLikeToggle", "camera:ScriptLock", "camera:ScriptUnlock", "camera:ScriptForcedOffsetStart",
			"camera:ScriptForcedOffsetStop", "camera:ScriptForcedFOVStart", "camera:ScriptForcedFOVStop", "camera:GetPos",
			"camera:GetDir", "player:GetBonePos", "game:CreateCleanEntity" } },
	{ id = "chk_fp_eyes", group = "sec_camera", needs = { "player:GetBonePos" },
		probe = function()
			local f = fp("eyes")
			if f == nil then
				return nil, T("chk_no_fp")
			end
			local ok, src, h, inCar = f()
			return ok, ok and T(inCar and "chk_fp_eyes_car_d" or "chk_fp_eyes_d", tostring(src), string.format("%.2f", h or 0))
				or T("chk_fp_eyes_none")
		end },
	{ id = "chk_fp_offset", group = "sec_camera", needs = { "camera:ScriptForcedOffsetStart", "camera:GetPos" },
		slow = function()
			local f = fp("offset")
			if f == nil then
				return nil, T("chk_no_fp")
			end
			local ok, moved = f()
			return ok, T("chk_fp_offset_d", string.format("%.2f", moved or 0))
		end },
	{ id = "chk_fp_fov", group = "sec_camera", needs = { "camera:ScriptForcedFOVStart" },
		slow = function()
			local f = fp("fov")
			if f == nil then
				return nil, T("chk_no_fp")
			end
			local ok, before, want, after = f()
			if ok == nil then
				return nil, T("chk_fp_fov_noread")
			end
			return ok, T("chk_fp_fov_d", fmt1(before), fmt1(want), fmt1(after))
		end },
	{ id = "chk_fp_anchor_fov", group = "sec_camera", needs = { "game:CreateCleanEntity" },
		probe = function()
			local f = fp("anchorFov")
			if f == nil then
				return nil, T("chk_no_fp")
			end
			local ok, before, want, after = f()
			if ok == nil then
				return nil, T("chk_fp_anchor_noapi")
			end
			return ok, T("chk_fp_fov_d", fmt1(before), fmt1(want), fmt1(after))
		end },
	{ id = "chk_fp_config", group = "sec_camera",
		probe = function()
			local f = fp("config")
			if f == nil then
				return nil, T("chk_no_fp")
			end
			local installed = f()
			if installed == nil then
				return nil, T("chk_fp_config_unknown")
			end
			return installed, T(installed and "chk_fp_config_on" or "chk_fp_config_off")
		end },
	{ id = "chk_fp_carshoot", group = "sec_camera",
		off = function()
			local f = fp("carShoot")
			local off = f and f()
			return off and T("chk_fp_carshoot_off") or nil
		end,
		probe = function()
			local f = fp("carShoot")
			if f == nil then
				return nil, T("chk_no_fp")
			end
			local _, aimOk = f()
			if aimOk ~= true then
				return nil, T("chk_fp_carshoot_unknown")
			end
			return true, T("chk_fp_carshoot_ok")
		end },
	{ id = "fps_submenu", group = "sec_camera", needs = { "parts:EyeCameraMenu" } },
	{ id = "freecam", group = "sec_camera", needs = { "parts:CameraControlsMenu", "game:CreateCleanEntity" } },
	{ id = "camreset", group = "sec_camera", needs = { "parts:ResetCamera" } },

	-- settings: kept usable with an old ASI (the choice is saved and applies with
	-- the new one), so these are reported but never greyed out
	{ id = "language", group = "sec_settings", needs = { "fn:_ui_set_language" }, keep = true },
	{ id = "theme", group = "sec_settings", needs = { "fn:_ui_set_theme" }, keep = true },
	{ id = "transparency", group = "sec_settings", needs = { "fn:_ui_set_look" }, keep = true },
	{ id = "ui_scale", group = "sec_settings", needs = { "fn:_ui_set_look" }, keep = true },
	{ id = "panel_side", group = "sec_settings", needs = { "fn:_ui_set_look" }, keep = true },
	{ id = "motion", group = "sec_settings", needs = { "fn:_ui_set_look" }, keep = true },
}

-- Rows that share a check.
local Alias = {
	allcars = "spawncar", super_run = "mobility", super_jump = "jump", smoke_puff = "smoke_stand",
	hood = "doors", trunk = "doors", win_fl = "doors", win_fr = "doors", win_rl = "doors", win_rr = "doors",
	w_pistol = "squad", w_shotgun = "squad", w_smg = "squad", w_rifle = "squad", w_sniper = "squad", w_melee = "squad",
	w_fists = "squad", w_mixed = "squad",
}

local byId = {}
for _, c in ipairs(List) do
	byId[c.id] = c
end

local results = {}

-- "ok", "fail" (with why), "off" (with why), "skip" (the car is not at hand) or
-- nil (no check for this key, or no player). A failed probe of the last check
-- counts; the needs are looked at now.
function Checks.Status(key)
	local c = byId[Alias[key] or key]
	if c == nil then
		return nil
	end
	local why = c.off and c.off()
	if why then
		return "off", why
	end
	local r = results[c.id]
	if r ~= nil and r.state == "fail" then
		return "fail", r.detail
	end
	local p = activePlayer()
	if p == nil then
		return nil
	end
	local m = missing(c.needs, p)
	if m == "skip" then
		return "skip"
	elseif m ~= nil then
		return "fail", needText(m)
	end
	return "ok"
end

-- Greys out a row that does not work, and says so in its label. kind: "button"
-- shows the word on the right, a switch or a list in brackets after the name.
function Checks.Gate(menu, row, key, label, kind)
	local c = byId[Alias[key] or key]
	if c == nil or c.keep then
		return
	end
	local st = Checks.Status(key)
	if st ~= "fail" and st ~= "off" then
		return
	end
	menu:SetEntryEnabled(row, false)
	local word = T(st == "off" and "chk_off" or "chk_fail")
	if kind == "button" then
		menu:SetEntryText(row, label .. "  ·  " .. word)
	else
		menu:SetEntryText(row, label .. " (" .. word .. ")")
	end
end

----------------
-- The report --
----------------

local Icons = { ok = 0xE73E, fail = 0xE711, off = 0xE738, skip = 0xE897, wait = 0xE823, run = 0xE768 }

-- running: slow checks still out in their thread; version: bumped on every
-- change of the results, so an open report redraws only then.
local running, version = false, 0

local function nameOf(c)
	return (T(c.label or c.id):gsub("  ·  .*$", ""))
end

local function stateWord(state)
	return T(state == "ok" and "chk_ok" or state == "fail" and "chk_fail" or state == "off" and "chk_off"
		or state == "wait" and "chk_wait" or "chk_skip")
end

-- One check now; slow probes are left for the thread ("wait").
local function runOne(c, p)
	local why = c.off and c.off()
	if why then
		return "off", why
	end
	local m = missing(c.needs, p)
	if m == "skip" then
		return "skip", T("chk_no_car")
	elseif m ~= nil then
		return "fail", needText(m)
	end
	if c.slow ~= nil then
		return "wait", T("chk_wait_d")
	end
	if c.probe ~= nil then
		local okCall, ok, detail = pcall(c.probe, p)
		if not okCall then
			return "fail", tostring(ok)
		elseif ok == nil then
			return "skip", detail or T("chk_skip")
		end
		return ok and "ok" or "fail", detail
	end
	return "ok", T("chk_needs_ok", #(c.needs or {}))
end

local function counts()
	local n = { ok = 0, fail = 0, off = 0, skip = 0, wait = 0 }
	local bad = {}
	for _, c in ipairs(List) do
		local r = results[c.id]
		if r ~= nil then
			n[r.state] = (n[r.state] or 0) + 1
			if r.state == "fail" then
				bad[#bad + 1] = nameOf(c)
			end
		end
	end
	return n, bad
end

local function summary()
	if next(results) == nil then
		return T("chk_never")
	end
	local n = counts()
	return T("chk_summary_fmt", n.ok, n.ok + n.fail + n.skip + n.wait, n.fail, n.off, n.skip)
end

-- A check's row in the report: label, description, icon.
local function rowLook(c)
	local r = results[c.id]
	if r == nil then
		return nameOf(c) .. "  ·  " .. stateWord("skip"), T("chk_press_d"), Icons.skip
	end
	return nameOf(c) .. "  ·  " .. stateWord(r.state), r.detail or "", Icons[r.state]
end

local function finish()
	local n, bad = counts()
	local total = n.ok + n.fail
	if #bad == 0 then
		say(T("test_ok", n.ok, total))
	else
		say(T("test_bad", n.ok, total, table.concat(bad, ", ", 1, math.min(#bad, 6))))
	end
	for _, c in ipairs(List) do
		local r = results[c.id]
		dbg("check " .. c.id .. ": " .. r.state .. " - " .. tostring(r.detail))
	end
end

-- Runs every check; the slow ones finish in a thread. False when it did not
-- start: no player, or a run is still going.
function Checks.Run()
	if running then
		say(T("chk_running"))
		return false
	end
	local p = activePlayer()
	if p == nil then
		say(T("no_player"))
		return false
	end
	results = {}
	local slow = {}
	for _, c in ipairs(List) do
		local state, detail = runOne(c, p)
		results[c.id] = { state = state, detail = detail }
		if state == "wait" then
			slow[#slow + 1] = c
		end
	end
	version = version + 1
	if #slow == 0 or StartThread == nil or Sleep == nil then
		for _, c in ipairs(slow) do
			results[c.id] = { state = "skip", detail = T("chk_no_threads") }
		end
		finish()
		return true
	end
	running = true
	StartThread(function()
		for _, c in ipairs(slow) do
			local ok, detail = c.slow(activePlayer())
			results[c.id] = { state = ok == nil and "skip" or ok and "ok" or "fail", detail = detail }
			version = version + 1
		end
		running = false
		version = version + 1
		finish()
	end)
	return true
end

-- The report: "Check everything" on top, the summary under it, then a row per
-- check by section, with the last results (none yet: "not checked"). It used
-- to run every check as soon as it opened, so there was no button to press,
-- only the list (2026-10-21). The rows follow the results from OnUpdate, which
-- runs only while the report is on top: the ASI's live calls change the rows
-- of whatever menu is on top, and a thread writing them after the report had
-- been left would have renamed rows of another menu.
function Checks.Menu()
	local function btnLabel()
		return running and T("chk_run") .. "  ·  " .. stateWord("wait") or T("chk_run")
	end
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("selftest"))
	local btn = menu:AddButton(btnLabel(), function()
		Checks.Run()
	end)
	menu:Decorate(btn, T("chk_run_d"), Icons.run)
	local head = menu:AddSection(summary())
	local rows, looks = {}, {}
	local group = nil
	for _, c in ipairs(List) do
		if c.group ~= group then
			group = c.group
			menu:AddSection(T(group))
		end
		local label, hint, icon = rowLook(c)
		local i = menu:AddButton(label, function() end)
		menu:Decorate(i, hint, icon)
		rows[c.id] = i
		looks[c.id] = { label, hint, icon }
	end
	local seen = version
	menu:OnUpdate(function()
		if seen == version then
			return
		end
		seen = version
		menu:SetEntryText(btn, btnLabel())
		menu:SetEntryText(head, summary())
		for _, c in ipairs(List) do
			local label, hint, icon = rowLook(c)
			local was = looks[c.id]
			if label ~= was[1] then
				menu:SetEntryText(rows[c.id], label)
			end
			if hint ~= was[2] then
				menu:SetEntryHint(rows[c.id], hint)
			end
			if icon ~= was[3] and menu.SetEntryIcon ~= nil then
				menu:SetEntryIcon(rows[c.id], icon)
			end
			looks[c.id] = { label, hint, icon }
		end
	end)
	return menu
end

-- For the tests: the check list and the last results.
function Checks.List()
	return List
end

function Checks.Result(id)
	return results[id]
end
