-- The trainer hub: one root with six sections. No noclip or time-stop here.
-- Maintain.OnTick (via trainer/main.lua) only re-applies sprint, brawl, and high FX
-- the game clears every frame.
-- Menus of the old trainer mod are reused through TrainerParts.

include("i18n.lua")
include("i18n_more.lua")

---------------
-- Language --
---------------

-- English (I18n.Languages[1]) until the player picks a language in Settings >
-- Language, which is saved.
local LangIdx = 1

local function langCode()
	return I18n.Languages[LangIdx].code
end

local function T(key, ...)
	local row = I18n.S[key]
	local s = row and (row[I18n.Languages[LangIdx].col] or row[I18n.EnCol]) or key
	if select("#", ...) > 0 then
		local ok, r = pcall(string.format, s, ...)
		if ok then
			return r
		end
	end
	return s
end

-- Called by the menu bootstrap for every label, title and prompt it shows.
function _SH_translate(s)
	local li = I18n.Languages[LangIdx].legacy
	if li == nil then
		return s
	end
	local row = I18n.Legacy[s]
	if row ~= nil then
		return row[li] or s
	end
	for _, p in ipairs(I18n.LegacyPrefixes) do
		local pre = p[1]
		if s:sub(1, #pre) == pre then
			local rest = s:sub(#pre + 1)
			local word = I18n.LegacyWords[rest]
			return (p[2][li] or pre) .. (word and word[li] or rest)
		end
	end
	return s
end

do
	-- Each language's column in I18n.S rows and in I18n.Legacy rows (none for
	-- English: a Legacy key is the English text itself).
	local function column(list, code)
		for i, c in ipairs(list) do
			if c == code then
				return i
			end
		end
	end
	I18n.EnCol = column(I18n.Columns, "en")
	local saved = _ui_get_setting and _ui_get_setting("Language")
	for i, l in ipairs(I18n.Languages) do
		l.col = column(I18n.Columns, l.code)
		l.legacy = column(I18n.LegacyColumns, l.code)
		if l.code == saved then
			LangIdx = i
		end
	end
	if _ui_set_language then
		_ui_set_language(langCode())
	end
end

-------------
-- Helpers --
-------------

-- Notify draws a notice at the top of the screen; print only reaches the F1 console.
-- Labels like "Grenades  ·  +2" carry a right-aligned value; a notice reads them as one phrase.
local function say(msg)
	msg = tostring(msg):gsub("  ·  ", " ")
	if Notify ~= nil then
		Notify(msg)
	else
		print("Trainer: " .. msg)
	end
end

local function dbg(msg)
	print("Trainer dbg: " .. tostring(msg))
end

local function activePlayer()
	local ok, p = pcall(function()
		return game.game:GetActivePlayer()
	end)
	if ok then
		return p
	end
	return nil
end

local function player()
	local p = activePlayer()
	if p ~= nil then
		return p
	end
	say(T("no_player"))
	return nil
end

-- Runs fn(p); on success says `done` (if given), on error says what failed.
local function call(label, fn, done)
	local p = player()
	if p == nil then
		return
	end
	local ok, err = pcall(fn, p)
	if not ok then
		say(T("failed", label or T("action"), tostring(err)))
	elseif done ~= nil then
		say(done)
	end
end

local function readNum(fn)
	local ok, v = pcall(fn)
	if ok and type(v) == "number" then
		return v
	end
	return nil
end

local function readBool(fn)
	local ok, v = pcall(fn)
	if ok and type(v) == "boolean" then
		return v
	end
	return nil
end

local function onOff(b)
	return b and T("on") or T("off")
end

-- Wait(so) with a timeout. Must run inside StartThread. Returns done, waitedMs.
-- No pcall around Wait: yielding through pcall breaks HavokScript threads.
local function waitFor(so, ms)
	local state = { done = false }
	StartThread(function()
		Wait(so)
		state.done = true
	end)
	local waited = 0
	while not state.done and waited < ms do
		Sleep(100)
		waited = waited + 100
	end
	return state.done, waited
end

-- Runs fn once the calls with the same key stop for ms; lists fire on every step.
local debounceTokens = {}
local function debounce(key, ms, fn)
	local token = (debounceTokens[key] or 0) + 1
	debounceTokens[key] = token
	StartThread(function()
		Sleep(ms)
		if debounceTokens[key] == token then
			fn()
		end
	end)
end

-- Parts of the old trainer mod (ScriptHook\lua\trainer).
local function part(name)
	local f = TrainerParts and TrainerParts[name]
	if f == nil then
		say(T("need_trainer"))
	end
	return f
end

local function partMenu(name, prepare)
	return function()
		local f = part(name)
		if f == nil then
			return nil
		end
		if prepare ~= nil then
			prepare()
		end
		return f()
	end
end

local function partCall(name, label, ...)
	local f = part(name)
	if f == nil then
		return false
	end
	local ok, err = pcall(f, ...)
	if not ok then
		say(T("failed", label, tostring(err)))
	end
	return ok
end

-- Menu rows. Labels are looked up when the menu is built, so a language switch
-- shows up the next time a menu opens. A row whose game calls do not work is
-- greyed out with the reason in its label (checks.lua), never left out.
local function gate(menu, i, key, kind)
	if Checks ~= nil and Checks.Gate ~= nil then
		Checks.Gate(menu, i, key, T(key), kind)
	end
end

local function btn(menu, key, cb, icon, hintKey)
	local i = menu:AddButton(T(key), cb)
	menu:Decorate(i, hintKey and T(hintKey) or nil, icon)
	gate(menu, i, key, "button")
	return i
end

local function sub(menu, key, builder, icon, hintKey)
	local i = menu:AddButton(T(key), builder)
	menu:Decorate(i, hintKey and T(hintKey) or nil, icon, true)
	gate(menu, i, key, "button")
	return i
end

local function chk(menu, key, cb, icon, hintKey)
	local i = menu:AddCheckbox(T(key), cb)
	menu:Decorate(i, hintKey and T(hintKey) or nil, icon)
	gate(menu, i, key, "check")
	return i
end

local function list(menu, key, items, selected, cb, icon, hintKey)
	local i = menu:AddList(T(key), cb)
	for _, item in ipairs(items) do
		menu:AddListEntry(i, item)
	end
	if selected ~= nil and items[selected] ~= nil then
		menu:SelectListEntryByValue(i, items[selected])
	end
	menu:Decorate(i, hintKey and T(hintKey) or nil, icon)
	gate(menu, i, key, "list")
	return i
end

-- Segoe MDL2 Assets code points.
local Icon = {
	player = 0xE77B, car = 0xE804, people = 0xE716, world = 0xE774, camera = 0xE722, settings = 0xE713,
	heal = 0xE95E, shield = 0xEA18, weapon = 0xECAD, ammo = 0xE8F1, grenade = 0xE7BA, trash = 0xE74D,
	money = 0xE8C7, relay = 0xE720, smoke = 0xE753, outfit = 0xE771, eye = 0xE890, plane = 0xE709,
	gamepad = 0xE7FC, lock = 0xE72E, bolt = 0xE945, info = 0xE946, boat = 0xE7E3, wrench = 0xE90F,
	sliders = 0xE9E9, gauge = 0xEC4A, light = 0xE781, power = 0xE7E8, badge = 0xEC1B, music = 0xE7F6,
	box = 0xE7B8, palette = 0xE790, up = 0xE898, exit = 0xE8A7, clock = 0xE823, cloud = 0xE753,
	chart = 0xE9D9, horizon = 0xED39, reset = 0xE81C, language = 0xE775, gears = 0xE9F5, stop = 0xE71A,
	zoom = 0xE8A3, dock = 0xE90D, stopwatch = 0xE916, layers = 0xE81E,
}

Hub = {
	T = T, say = say, dbg = dbg, activePlayer = activePlayer, player = player, btn = btn, list = list, chk = chk,
	Icon = Icon, readBool = readBool,
}

-- Same idea as god mode: the game resets sprint/style every frame — re-apply from menu sync too.
function SafeTrainerSyncPlayer(p)
	if p == nil then
		return
	end
	if Mobility ~= nil and Mobility.IsSuperRun ~= nil and Mobility.IsSuperRun() and Mobility.ApplyRun ~= nil then
		Mobility.ApplyRun(p)
	end
	if StreetFight ~= nil and StreetFight.IsOn ~= nil and StreetFight.IsOn() and StreetFight.Maintain ~= nil then
		StreetFight.Maintain(p, 0)
	elseif Brawl ~= nil and Brawl.IsOn ~= nil and Brawl.IsOn() and Brawl.Maintain ~= nil then
		Brawl.Maintain(p, 0)
	end
end
include("mobility.lua")
include("brawl.lua")
include("street_fight.lua")
include("maintain.lua")
include("checks.lua")

function SafeTrainerOnTick()
	if Maintain ~= nil and Maintain.OnTick ~= nil then
		Maintain.OnTick()
	end
end

------------
-- Player --
------------

local function Heal()
	call(nil, function(p)
		p:SetMaxHealth()
		local h = readNum(function() return p.health end)
		local hm = readNum(function() return p.healthmax end)
		if h ~= nil and hm ~= nil and hm > 0 then
			say(T("healed_n", math.floor(h + 0.5), math.floor(hm + 0.5)))
		else
			say(T("healed"))
		end
	end)
end

local function ammoInHands(p)
	return readNum(function()
		return p:DbgTesting_HelperFire_GetAmmoCountInEquipedWeapon()
	end)
end

local function RefillAmmo()
	call(nil, function(p)
		local before = ammoInHands(p)
		p:InventoryLoadWeapons()
		local after = ammoInHands(p)
		if before ~= nil and after ~= nil then
			say(T("ammo_n", after, before))
		else
			say(T("ammo_ok"))
		end
	end)
end

-- Kept here when the old trainer is missing; with it, its OnTick reloads too.
local unlimitedAmmo = false

local function unlimitedAmmoOn()
	local f = TrainerParts and TrainerParts.UnlimitedAmmo
	if f ~= nil then
		local ok, v = pcall(f)
		if ok then
			return v == true
		end
	end
	return unlimitedAmmo
end

local function ToggleUnlimitedAmmo()
	call(T("infammo"), function(p)
		local f = TrainerParts and TrainerParts.ToggleUnlimitedAmmo
		if f ~= nil then
			f()
		else
			unlimitedAmmo = not unlimitedAmmo
			p:InventorySetUnlimitedAmmo(unlimitedAmmo)
		end
	end)
end

local function Grenades()
	call(T("grenades"), function(p) p:InventoryAddGrenades(2) end, T("done_fmt", T("grenades")))
end

local function Molotovs()
	call(T("molotovs"), function(p) p:InventoryAddAmmoByCategory(71, 2) end, T("done_fmt", T("molotovs")))
end

local function ClearInventory()
	call(T("clearinv"), function(p) p:ClearInventory() end, T("done_fmt", T("clearinv")))
end

local function Money()
	if player() ~= nil and partCall("GiveMoney", T("money")) then
		say(T("done_fmt", T("money")))
	end
end

local function Relays()
	if player() ~= nil and partCall("GiveRelays", T("relays")) then
		say(T("done_fmt", T("relays")))
	end
end

-- Invulnerability: the Human `invulnerability` property blocks damage; SetDemigod
-- keeps health from reaching zero and EnableInjury(false) stops limping.
-- godWanted is what the player asked for; the checkbox shows the game's real value.
local godWanted = false

local function readGod(p)
	local v = readBool(function() return p.invulnerability end)
	if v == nil then
		return godWanted
	end
	return v
end

local function applyGod(p, on)
	pcall(function() p.invulnerability = on end)
	pcall(function() p:SetDemigod(on) end)
	pcall(function() p:EnableInjury(not on) end)
	if on then
		pcall(function() p:SetMaxHealth() end)
	end
end

local function SetGod(on, quiet)
	local p = quiet and activePlayer() or player()
	if p == nil then
		godWanted = false
		return
	end
	applyGod(p, on)
	godWanted = on
	if quiet then
		return
	end
	local real = readBool(function() return p.invulnerability end)
	if real == nil then
		say(on and T("god_on_unk") or T("god_off"))
	elseif real == on then
		say(on and T("god_on_ok") or T("god_off"))
	else
		say(T("god_refused", onOff(real)))
	end
end

local function ToggleGod()
	local p = player()
	if p == nil then
		return
	end
	SetGod(not readGod(p))
end

local function playerToggle(partName, label)
	return function()
		if player() ~= nil then
			partCall(partName, label)
		end
	end
end

-------------
-- Smoking --
-------------

-- AnimPlay looks the name up in the human's animation graph; a name the graph
-- lacks is refused within a frame or two. Old Mafia 2 names (sc_man_smoke_stat_*)
-- are accepted but have no data and leave a T-pose, so only Mafia III clips from
-- the city pack are used. Which name form the graph uses is not known, so the
-- first press probes the forms and remembers the one that plays. On the player
-- AnimPlay needs the controls locked; the lock is always released afterwards.
local SmokeFamilies = {
	{ key = "fam_cig", dir = "global/stand/sc_stand_smoke_male_02/",
		enter = "sc_stand_male_01_to_stand_smoke_02", idle = "sc_stand_smoke_male_02_idle",
		inhale = { "sc_stand_smoke_male_02_inhale", "sc_stand_smoke_male_02_inhale_v02", "sc_stand_smoke_male_02_tap" },
		exit = "sc_stand_smoke_male_02_to_stand_01" },
	{ key = "fam_think", dir = "global/stand/sc_stand_smoke_m_01/",
		enterDir = "global/stand/stand_smoke_m_01/", enter = "sc_stand_m_01_to_smoke_01", idle = "sc_stand_smoke_m_01_idle",
		inhale = { "sc_stand_smoke_m_01_inhale", "sc_stand_smoke_m_01_think", "sc_stand_smoke_m_01_memory" },
		exit = "sc_stand_smoke_m_01_to_stand_01" },
	{ key = "fam_foreman", dir = "global/smuggling/", idle = "sc_foreman_smoke_male_01_idle",
		inhale = { "sc_foreman_smoke_male_01_inhale", "sc_foreman_smoke_male_01_inhale_v02", "sc_foreman_smoke_male_01_look" } },
	{ key = "fam_joint", dir = "global/junkie/", idle = "sc_stand_junkie_weed_male_idle",
		inhale = { "sc_stand_junkie_weed_male_inhale", "sc_stand_junkie_weed_male_inhale_v02" } },
	{ key = "fam_bum", dir = "global/patrol/", enter = "sc_patrol_delay_bum_a_cig_enter", idle = "sc_patrol_delay_bum_a_cig_idle",
		inhale = { "sc_patrol_delay_bum_a_cig_check", "sc_patrol_delay_bum_a_cig_idle_look_v1" } },
	{ key = "fam_guard", dir = "global/stand/", enter = "sc_stand_to_smoke_start_lod_shotgunner",
		idle = "sc_stand_smoke_shot_nw_idle_shotgunner",
		inhale = { "sc_stand_smoke_shot_nw_inhale_shotgunner", "sc_stand_smoke_shot_nw_inhale_v02_shotgunner",
			"sc_stand_smoke_shot_nw_tap_shotgunner" },
		exit = "sc_stand_smoke_shot_nw_to_stand_01_shotgunner" },
}

local SitSmoke = { key = "fam_sitjoint", dir = "global/junkie/sc_sit_ground_junkie_weed/",
	idle = "sc_sit_ground_junkie_weed_m_01_young",
	exitDir = "global/getup/", exit = "sc_sit_ground_junkie_weed_male_01_getup_quick" }

local function nameForms(dir, name)
	local rel = "script_anims/" .. dir .. name
	return {
		name,
		rel,
		"/generated/anims/" .. rel,
		"generated/anims/" .. rel,
		"/generated/anims/" .. rel .. ".hkx",
		rel .. ".hkx",
	}
end
local FormCount = #nameForms("", "")

-- A refused request finishes within a frame or two (the log showed 100-200 ms).
local RefuseMs = 300

-- Starts a clip on h. Returns a state table while it plays, nil if refused.
local function startClip(h, name, loop)
	local ok, so = pcall(function()
		return h:AnimPlay(name, loop == true)
	end)
	if not ok or so == nil then
		dbg("AnimPlay(" .. name .. ") error: " .. tostring(so))
		return nil
	end
	local st = { done = false }
	StartThread(function()
		Wait(so)
		st.done = true
	end)
	Sleep(RefuseMs)
	if st.done then
		return nil
	end
	return st
end

local function awaitClip(h, st, ms)
	local waited = RefuseMs
	while not st.done and waited < ms do
		Sleep(100)
		waited = waited + 100
	end
	if not st.done then
		pcall(function() h:AnimStop() end)
	end
	return waited
end

local playerForm = nil    -- index into nameForms() that the player's graph accepts
local playerFamily = nil
local playerNoSmoke = false
-- For the check: the smoking rows are switched off once the graph had none.
Hub.noSmoke = function() return playerNoSmoke end
local smoking = false
local smokeLocked = false
local smokeToken = 0

-- Clears a drunk view and a camera shake left on the player. Smoking no longer
-- gives a high (removed 2026-10-22, asked); Stop and a reload still clear what
-- an older version may have left.
local function stopHigh()
	if Maintain ~= nil then
		Maintain.SetHighActive(false)
		local p = activePlayer()
		if p ~= nil then
			Maintain.ClearHighFx(p)
		end
		return
	end
	pcall(function()
		local cam = game.cameramanager:GetPlayerCamera()
		cam:SetShakeOverrideEnabled(false)
	end)
end

local function controlsLocked(p)
	return readBool(function() return p:AreControlsLocked() end) == true
end

local function waitLocked(p, ms)
	local waited = 0
	while not controlsLocked(p) and waited < ms do
		Sleep(100)
		waited = waited + 100
	end
	return controlsLocked(p), waited
end

local function releaseControls(p)
	if not smokeLocked then
		return
	end
	smokeLocked = false
	pcall(function()
		p:LockControls(false)
	end)
end

-- Takes the player for an animation: LockControlsToPlayAnim first, full LockControls if that never shows up.
local function lockForAnim(p)
	pcall(function()
		p:LockControlsToPlayAnim()
	end)
	smokeLocked = true
	local locked, waited = waitLocked(p, 1500)
	dbg(string.format("LockControlsToPlayAnim: locked=%s after %d ms", tostring(locked), waited))
	if locked then
		return true
	end
	pcall(function()
		p:LockControls(true)
	end)
	locked, waited = waitLocked(p, 1500)
	dbg(string.format("LockControls(true): locked=%s after %d ms", tostring(locked), waited))
	return locked
end

local function clipName(fam, step, form)
	local dir, name = fam.dir, nil
	if step == "enter" then
		dir, name = fam.enterDir or fam.dir, fam.enter
	elseif step == "idle" then
		name = fam.idle
	elseif step == "exit" then
		dir, name = fam.exitDir or fam.dir, fam.exit
	else
		local n = tonumber(step:match("^inhale(%d)$") or "1")
		name = fam.inhale and (fam.inhale[n] or fam.inhale[1])
	end
	if name == nil then
		return nil
	end
	return nameForms(dir, name)[form]
end

-- Finds a family and name form h's graph accepts, starting with its idle clip.
-- Returns family, form, state of the idle clip now playing.
local function probeSmoke(h, families, form, token, loop)
	for _, fam in ipairs(families) do
		local first, last = 1, FormCount
		if form ~= nil then
			first, last = form, form
		end
		for f = first, last do
			if token ~= nil and token ~= smokeToken then
				return nil
			end
			local name = nameForms(fam.dir, fam.idle)[f]
			local st = startClip(h, name, loop)
			dbg("probe " .. name .. ": " .. (st and "plays" or "refused"))
			if st ~= nil then
				return fam, f, st
			end
		end
	end
	return nil
end

local function playSteps(h, fam, form, steps, token, playing)
	local played = 0
	if playing ~= nil then
		awaitClip(h, playing, 20000)
		played = 1
	end
	for _, step in ipairs(steps) do
		if token ~= smokeToken then
			break
		end
		local name = clipName(fam, step, form)
		if name ~= nil then
			local st = startClip(h, name, false)
			if st ~= nil then
				awaitClip(h, st, 20000)
				played = played + 1
			else
				dbg("smoke step refused: " .. name)
			end
		end
	end
	return played
end

local function Smoke(steps, doneKey, sitting)
	return function()
		local p = player()
		if p == nil then
			return
		end
		local okOwner, owner = pcall(function() return p:GetOwner() end)
		if okOwner and owner ~= nil then
			say(T("smoke_in_car"))
			return
		end
		if smoking then
			say(T("smoke_busy"))
			return
		end
		if playerNoSmoke and not sitting then
			say(T("smoke_none_known"))
			return
		end
		if controlsLocked(p) then
			say(T("smoke_scripted"))
			return
		end
		smoking = true
		smokeToken = smokeToken + 1
		local token = smokeToken
		if playerFamily == nil and not sitting then
			say(T("smoke_probing"))
		end
		StartThread(function()
			local played, famKey = 0, nil
			local locked = lockForAnim(p)
			if locked then
				local fam, form, playing = nil, playerForm, nil
				if sitting then
					fam, form, playing = probeSmoke(p, { SitSmoke }, playerForm, token)
				elseif playerFamily ~= nil then
					fam = playerFamily
				else
					fam, form, playing = probeSmoke(p, SmokeFamilies, nil, token)
					if fam ~= nil then
						playerFamily, playerForm = fam, form
						dbg("smoke family for player: " .. fam.key .. ", form " .. tostring(form))
					elseif token == smokeToken then
						playerNoSmoke = true
					end
				end
				if fam ~= nil then
					famKey = fam.key
					played = playSteps(p, fam, form, steps, token, playing)
				end
			end
			if token ~= smokeToken then
				return
			end
			releaseControls(p)
			smoking = false
			if played > 0 then
				say(T(doneKey) .. " (" .. T(famKey) .. ")")
			elseif not locked then
				say(T("smoke_nolock"))
			elseif sitting then
				say(T("smoke_nosit"))
			elseif playerNoSmoke then
				say(T("smoke_nosmoke"))
			else
				say(T("smoke_unknown"))
			end
		end)
	end
end

local function StopSmoke()
	smokeToken = smokeToken + 1
	stopHigh()
	local p = activePlayer()
	smoking = false
	if p == nil then
		smokeLocked = false
		return
	end
	pcall(function()
		p:AnimStop()
	end)
	releaseControls(p)
	say(T("smoke_stopped"))
end

local function SmokeMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("smoke"))
	btn(menu, "smoke_puff", Smoke({ "inhale1" }, "smoked_puff"), Icon.smoke)
	btn(menu, "smoke_stand", Smoke({ "enter", "idle", "inhale1", "idle", "inhale2", "idle", "inhale3", "exit" }, "smoked_stand"), Icon.smoke)
	btn(menu, "smoke_sit", Smoke({ "idle", "exit" }, "smoked_sit", true), Icon.smoke)
	btn(menu, "smoke_stop", StopSmoke, Icon.stop, "smoke_stop_d")
	return menu
end

local function PlayerMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("sec_player"))
	menu:AddSection(T("grp_quick"))
	btn(menu, "heal", Heal, Icon.heal, "heal_d")
	sub(menu, "mobility", Mobility.Menu, Icon.chart, "mobility_d")
	local god = chk(menu, "god", ToggleGod, Icon.shield, "god_d")
	btn(menu, "ammo", RefillAmmo, Icon.ammo, "ammo_d")
	local inf = chk(menu, "infammo", ToggleUnlimitedAmmo, Icon.ammo, "infammo_d")

	menu:AddSection(T("grp_arsenal"))
	sub(menu, "giveweapon", partMenu("GiveWeaponMenu"), Icon.weapon, "giveweapon_d")
	btn(menu, "grenades", Grenades, Icon.grenade)
	btn(menu, "molotovs", Molotovs, Icon.weapon)
	btn(menu, "clearinv", ClearInventory, Icon.trash, "clearinv_d")

	menu:AddSection(T("grp_res"))
	btn(menu, "money", Money, Icon.money)
	btn(menu, "relays", Relays, Icon.relay, "relays_d")

	menu:AddSection(T("grp_look"))
	sub(menu, "smoke", SmokeMenu, Icon.smoke, "smoke_d")
	sub(menu, "model", partMenu("ChangeModelMenu"), Icon.outfit, "model_d")
	local vis = chk(menu, "visible", playerToggle("ToggleModelVisibility", T("visible")), Icon.eye)

	menu:AddSection(T("grp_extra"))
	sub(menu, "noclip", partMenu("NoclipMenu"), Icon.plane, "noclip_d")
	btn(menu, "aimcar", function()
		if player() ~= nil then
			partCall("TeleportIntoAimedVehicle", T("aimcar"))
		end
	end, Icon.car, "aimcar_d")
	btn(menu, "unlock", function()
		if player() ~= nil and partCall("RestoreInput", T("unlock")) then
			say(T("done_fmt", T("unlock")))
		end
	end, Icon.gamepad, "unlock_d")
	local lock = chk(menu, "lockctl", playerToggle("ToggleControlsLock", T("lockctl")), Icon.lock)
	local cloth = chk(menu, "cloth", playerToggle("ToggleCloth", T("cloth")), Icon.outfit)
	local phys = chk(menu, "physics", playerToggle("TogglePhysics", T("physics")), Icon.bolt)
	sub(menu, "pinfo", partMenu("PlayerInfoMenu"), Icon.info)
	local brawlRow = nil
	if StreetFight ~= nil and StreetFight.AttachPlayerMenu ~= nil then
		brawlRow = StreetFight.AttachPlayerMenu(menu)
	elseif Brawl ~= nil and Brawl.AttachPlayerMenu ~= nil then
		brawlRow = Brawl.AttachPlayerMenu(menu)
	end

	-- Death, a checkpoint or a cutscene can reset invulnerability; put it back.
	local p = activePlayer()
	if godWanted and p ~= nil and readBool(function() return p.invulnerability end) == false then
		applyGod(p, true)
	end
	local function sync()
		local cur = activePlayer()
		if cur == nil then
			return
		end
		SafeTrainerSyncPlayer(cur)
		menu:SetChecked(god, readGod(cur))
		menu:SetChecked(inf, unlimitedAmmoOn())
		menu:SetChecked(vis, readBool(function() return cur:IsModelVisible() end) ~= false)
		menu:SetChecked(lock, readBool(function() return cur:AreControlsLocked() end) == true)
		menu:SetChecked(cloth, readBool(function() return cur:IsClothSimulated() end) == true)
		local physOn = TrainerParts and TrainerParts.PhysicsActive
		if physOn ~= nil then
			local ok, v = pcall(physOn)
			menu:SetChecked(phys, ok and v == true)
		end
		if brawlRow ~= nil then
			if StreetFight ~= nil and StreetFight.IsOn ~= nil then
				menu:SetChecked(brawlRow, StreetFight.IsOn())
			elseif Brawl ~= nil and Brawl.IsOn ~= nil then
				menu:SetChecked(brawlRow, Brawl.IsOn())
			end
		end
	end
	sync()
	menu:OnUpdate(sync)
	return menu
end

--------------
-- Vehicles --
--------------

local QuickCars = {
	{ "quick_police", "police_patrol" },
	{ "quick_military", "hank_compact_military" },
	{ "quick_truck", "samson_truck" },
	{ nil, "samson_duke", "Samson Duke" },
	{ nil, "potomac_champion", "Potomac Champion" },
}

local function flatDir(p)
	local dir = p:GetDir()
	local fx, fy = dir.x, dir.y
	local len = math.sqrt(fx * fx + fy * fy)
	if len < 0.001 then
		return 0, 1
	end
	return fx / len, fy / len
end

local function placeAhead(p, forward, side, lift)
	local base = p:GetPos()
	local fx, fy = flatDir(p)
	return Math:newVector(
		base.x + fx * forward + (-fy) * side,
		base.y + fy * forward + fx * side,
		base.z + (lift or 0.4)
	), Math:newVector(fx, fy, 0)
end

local function prettyName(id)
	return (id:gsub("_", " "))
end

-- Requests the model, places it ahead and hands it over. Nobody is put inside.
local function spawnVehicle(name, boat)
	if player() == nil then
		return
	end
	StartThread(function()
		local ok, so, id = pcall(function()
			if boat then
				return game.traffic:ObtainSpecificBoat(name)
			end
			return game.traffic:ObtainSpecificCar(name)
		end)
		if not ok or so == nil then
			say(T("car_fail", tostring(so)))
			return
		end
		if not waitFor(so, 30000) then
			pcall(function() game.traffic:DespawnEntity(id) end)
			say(T("car_timeout", prettyName(name)))
			return
		end
		local p = activePlayer()
		if p == nil then
			say(T("player_gone"))
			return
		end
		local pos, face = placeAhead(p, boat and 10 or 8, 0, boat and 0.8 or 0.5)
		local spawned
		if boat then
			spawned = game.traffic:SpawnBoat(id, pos, face)
		else
			spawned = game.traffic:SpawnCar(id, pos, face)
		end
		if spawned ~= nil then
			waitFor(spawned, 10000)
		end
		local veh = game.traffic:GetSpawnedEntity(id)
		if veh == nil then
			say(T("no_entity"))
			return
		end
		if not boat then
			pcall(function()
				p:MakeCarOwnership(veh)
			end)
		end
		say(T("ahead", prettyName(name)))
	end)
end

local function SpawnNamedCar(_, _, name)
	spawnVehicle(name, false)
end

local function SpawnNamedBoat(_, _, name)
	spawnVehicle(name, true)
end

local function modelList(title, ids, cb, icon)
	local menu = UI.SimpleMenu()
	menu:SetTitle(title)
	menu:AddSearch(T("cars"), T("search_part"))
	if ids == nil then
		menu:AddButton(T("list_not_loaded"), function() end)
		return menu
	end
	for _, id in ipairs(ids) do
		menu:Decorate(menu:AddButton(prettyName(id), id, cb), nil, icon)
	end
	return menu
end

local function AllCarsMenu()
	return modelList(T("allcars"), VehicleModelIDs, SpawnNamedCar, Icon.car)
end

local function BoatsMenu()
	return modelList(T("boats"), BoatModelIDs, SpawnNamedBoat, Icon.boat)
end

local function CarsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("cars"))
	menu:AddSection(T("grp_popular"))
	for _, item in ipairs(QuickCars) do
		local label = item[1] and T(item[1]) or item[3]
		menu:Decorate(menu:AddButton(label, item[2], SpawnNamedCar), nil, Icon.car)
	end
	menu:AddSection(T("grp_all"))
	sub(menu, "allcars", AllCarsMenu, Icon.car)
	return menu
end

local function currentCar()
	local p = activePlayer()
	if p == nil then
		return nil
	end
	local ok, veh = pcall(function() return p:GetOwner() end)
	if ok then
		return veh
	end
	return nil
end

local function RepairCar()
	call(nil, function(p)
		local veh = p:GetOwner()
		if veh == nil then
			say(T("not_in_car"))
			return
		end
		veh:Repair(true)
		veh:SetMotorDamage(0)
		say(T("repaired"))
	end)
end

-- Switch states the game cannot report, remembered per car.
local carFlags = { veh = nil }

local function flagsFor(veh)
	if carFlags.veh ~= veh then
		carFlags = { veh = veh }
	end
	return carFlags
end

-- A toggle on the car the menu was opened for; does nothing once the player left it.
local function carToggle(veh, flag, label, apply)
	return function()
		if currentCar() ~= veh then
			say(T("not_in_car"))
			return
		end
		local f = flagsFor(veh)
		local on = not f[flag]
		local ok, err = pcall(apply, veh, on)
		if ok then
			f[flag] = on
		else
			say(T("failed", label, tostring(err)))
		end
	end
end

local function engineOn(veh)
	local rot = readNum(function() return veh:GetEngineRotations() end)
	if rot ~= nil then
		return rot > 0
	end
	return readBool(function() return veh:IsEngineOn() end) == true
end

local function DoorsMenu(veh)
	return function()
		local menu = UI.SimpleMenu()
		menu:SetTitle(T("doors"))
		local seats = readNum(function() return veh:GetSeatCount() end) or 2
		local rows = {
			chk(menu, "hood", carToggle(veh, "hood", T("hood"), function(v, on)
				if on then v:OpenHood() else v:CloseHood() end
			end), Icon.box),
			chk(menu, "trunk", carToggle(veh, "trunk", T("trunk"), function(v, on)
				if on then v:OpenTrunk() else v:CloseTrunk() end
			end), Icon.box),
		}
		local windows = { { "win_fl", 1 }, { "win_fr", 2 }, { "win_rl", 3 }, { "win_rr", 4 } }
		local winRows = {}
		for _, w in ipairs(windows) do
			local seat = w[2]
			local i = chk(menu, w[1], carToggle(veh, w[1], T(w[1]), function(v, on)
				v:OpenSeatWindow(seat, on, false)
			end), Icon.box)
			table.insert(winRows, { i, w[1], seat })
		end
		local function sync()
			local f = flagsFor(veh)
			menu:SetChecked(rows[1], f.hood == true)
			menu:SetChecked(rows[2], f.trunk == true)
			for _, r in ipairs(winRows) do
				menu:SetChecked(r[1], f[r[2]] == true)
				menu:SetEntryEnabled(r[1], r[3] <= 2 or seats >= 4)
			end
		end
		sync()
		menu:OnUpdate(sync)
		return menu
	end
end

local function LooksMenu(veh)
	return function()
		local menu = UI.SimpleMenu()
		menu:SetTitle(T("looks"))
		local function prep()
			if TrainerParts and TrainerParts.SetAffectedVehicle then
				TrainerParts.SetAffectedVehicle(veh)
			end
		end
		sub(menu, "colors", partMenu("VehicleColorsMenu", prep), Icon.palette)
		sub(menu, "tint", partMenu("WindowTintMenu", prep), Icon.palette)
		sub(menu, "wheels_f", partMenu("FrontWheelsMenu", prep), Icon.car)
		sub(menu, "wheels_r", partMenu("RearWheelsMenu", prep), Icon.car)
		btn(menu, "plate", partMenu("PlateTextInput", prep), Icon.info)
		return menu
	end
end

local function StateMenu(veh)
	return function()
		local menu = UI.SimpleMenu()
		menu:SetTitle(T("state"))
		local function prep()
			if TrainerParts and TrainerParts.SetAffectedVehicle then
				TrainerParts.SetAffectedVehicle(veh)
			end
		end
		btn(menu, "fuel", partMenu("FuelInput", prep), Icon.gauge)
		btn(menu, "rust", partMenu("RustInput", prep), Icon.sliders)
		btn(menu, "dirt", partMenu("DirtInput", prep), Icon.sliders)
		btn(menu, "steerplay", partMenu("SteeringPlayInput", prep), Icon.sliders)
		btn(menu, "steeroff", partMenu("SteeringOffsetInput", prep), Icon.sliders)
		btn(menu, "handling", partMenu("HandlingInput", prep), Icon.sliders)
		return menu
	end
end

local function CurrentCarMenu()
	local veh = currentCar()
	if veh == nil then
		say(T("not_in_car"))
		return nil
	end
	if TrainerParts and TrainerParts.SetAffectedVehicle then
		pcall(TrainerParts.SetAffectedVehicle, veh)
	end
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("curcar"))

	menu:AddSection(T("grp_drive"))
	btn(menu, "boost", function()
		if currentCar() ~= veh then
			say(T("not_in_car"))
			return
		end
		local ok, err = pcall(function() veh:SetSpeed(veh:GetSpeedFloat() + 10) end)
		if not ok then
			say(T("failed", T("boost"), tostring(err)))
		end
	end, Icon.gauge)
	local engine = chk(menu, "engine", function()
		if currentCar() ~= veh then
			say(T("not_in_car"))
			return
		end
		local on = not engineOn(veh)
		local ok, err = pcall(function() veh:SetEngineOn(on, on) end)
		if not ok then
			say(T("failed", T("engine"), tostring(err)))
		end
	end, Icon.power)
	local lights = chk(menu, "lights", carToggle(veh, "lights", T("lights"), function(v, on) v:SetLightState(true, on) end), Icon.light)
	local siren = chk(menu, "siren", carToggle(veh, "siren", T("siren"), function(v, on) v:SetSirenOn(on) end), Icon.badge)
	local radio = chk(menu, "radio", carToggle(veh, "radio", T("radio"), function(v, on) game.radio:SetOn(v, on) end), Icon.music)

	menu:AddSection(T("grp_protect"))
	local vgod = chk(menu, "vgod", carToggle(veh, "vgod", T("vgod"), function(v, on)
		v:SetResistance(on and 1e22 or 0)
	end), Icon.shield)
	local noexplode = chk(menu, "noexplode", function()
		if currentCar() ~= veh then
			say(T("not_in_car"))
			return
		end
		local on = readBool(function() return veh:IsDisableExplosion() end) ~= true
		local ok, err = pcall(function() veh:DisableExplosion(on) end)
		if not ok then
			say(T("failed", T("noexplode"), tostring(err)))
		end
	end, Icon.shield)
	local nodespawn = chk(menu, "nodespawn", carToggle(veh, "nodespawn", T("nodespawn"), function(v, on)
		v:SetDespawnImmunity(on)
	end), Icon.lock, "nodespawn_d")
	local tires = chk(menu, "tires", carToggle(veh, "tires", T("tires"), function(v, on) v:SetWheelsProtected(on) end), Icon.shield)

	menu:AddSection(T("grp_body"))
	sub(menu, "doors", DoorsMenu(veh), Icon.box)
	sub(menu, "looks", LooksMenu(veh), Icon.palette)
	sub(menu, "state", StateMenu(veh), Icon.sliders)
	sub(menu, "vinfo", partMenu("VehicleInfoMenu"), Icon.info)
	btn(menu, "launch", function()
		if currentCar() == veh then
			partCall("LaunchVehicleUp", T("launch"), veh)
		else
			say(T("not_in_car"))
		end
	end, Icon.up)
	btn(menu, "leave", function()
		if currentCar() == veh then
			partCall("LeaveVehicle", T("leave"))
		end
	end, Icon.exit)

	local function sync()
		local f = flagsFor(veh)
		menu:SetChecked(engine, engineOn(veh))
		menu:SetChecked(lights, f.lights == true)
		menu:SetChecked(siren, f.siren == true)
		menu:SetChecked(radio, f.radio == true)
		menu:SetChecked(vgod, f.vgod == true)
		menu:SetChecked(noexplode, readBool(function() return veh:IsDisableExplosion() end) == true)
		menu:SetChecked(nodespawn, f.nodespawn == true)
		menu:SetChecked(tires, f.tires == true)
	end
	sync()
	menu:OnUpdate(sync)
	return menu
end

local function VehicleMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("sec_vehicle"))
	sub(menu, "spawncar", CarsMenu, Icon.car, "spawncar_d")
	sub(menu, "spawnboat", BoatsMenu, Icon.boat, "spawnboat_d")
	btn(menu, "repair", RepairCar, Icon.wrench, "repair_d")
	local cur = sub(menu, "curcar", CurrentCarMenu, Icon.sliders, "curcar_d")
	local function sync()
		menu:SetEntryEnabled(cur, currentCar() ~= nil)
	end
	sync()
	menu:OnUpdate(sync)
	return menu
end

------------
-- People --
------------

-- ObtainCarWithCrew(car, { spawn profiles }) loads the exact profiles on demand,
-- unlike ObtainHuman, which only matches models already streamed in. The profile
-- decides the weapon: triggerman pistol, shotgunner shotgun, machinegunner SMG,
-- rifleman rifle, sniper sniper rifle.
local WeaponClasses = {
	{ role = "triggerman", key = "w_pistol" },
	{ role = "shotgunner", key = "w_shotgun" },
	{ role = "machinegunner", key = "w_smg" },
	{ role = "rifleman", key = "w_rifle" },
	{ role = "sniper", key = "w_sniper" },
	{ role = "bruiser", key = "w_melee" },
	{ role = "enforcer", key = "w_fists" },
}

local ALL5 = { "triggerman", "shotgunner", "machinegunner", "rifleman", "sniper" }
local MELEE3 = { "bruiser", "enforcer", "blade" }

local function withMelee(roles)
	local out = {}
	for _, r in ipairs(roles) do
		out[#out + 1] = r
	end
	for _, r in ipairs(MELEE3) do
		out[#out + 1] = r
	end
	return out
end

local Factions = {
	{ key = "f_marcano", group = "grp_enemies", car = "smith_mainline", prefix = "characters/ai/marcano/ai_enemy_marcano_", roles = withMelee(ALL5) },
	{ key = "f_italian", group = "grp_enemies", car = "smith_mainline", prefix = "characters/ai/ai_enemy_italian_",
		roles = withMelee({ "triggerman", "shotgunner", "machinegunner", "sniper" }) },
	{ key = "f_dixie", group = "grp_enemies", car = "smith_mainline", prefix = "characters/ai/dixie/ai_enemy_dixie_", roles = withMelee(ALL5) },
	{ key = "f_klan", group = "grp_enemies", car = "smith_mainline", prefix = "characters/ai/klan/ai_enemy_klan_", roles = withMelee(ALL5) },
	{ key = "f_merc", note = "n_military", group = "grp_enemies", car = "smith_mainline", prefix = "characters/ai/merc/ai_enemy_merc_",
		roles = withMelee({ "triggerman", "shotgunner", "machinegunner", "rifleman" }) },
	{ key = "f_police", group = "grp_law", car = "smith_mainline_p", prefix = "characters/ai/police/ai_police_",
		roles = { "triggerman", "shotgunner", "machinegunner", "sniper" } },
	{ key = "f_sheriff", note = "n_county", group = "grp_law", car = "smith_mainline_sheriff", prefix = "characters/ai/sheriff/ai_enemy_sheriff_",
		roles = { "triggerman", "shotgunner", "machinegunner", "rifleman" } },
	{ key = "f_vito", group = "grp_allies", car = "smith_mainline", prefix = "characters/ai/vito/ai_ally_vito_", roles = withMelee(ALL5) },
	{ key = "f_irish", group = "grp_allies", car = "smith_mainline", prefix = "characters/ai/irish/ai_ally_irish_", roles = withMelee(ALL5) },
	{ key = "f_haitian", group = "grp_allies", car = "smith_mainline", prefix = "characters/ai/haitian/ai_ally_haitian_", roles = withMelee(ALL5) },
}

-- How many people one press brings; the choice is kept in ScriptHook.ini.
local SquadSizes = { 1, 2, 4, 7 }
local SquadSize = 7
local SeatsPerCar = 4

do
	local saved = tonumber(_ui_get_setting and _ui_get_setting("PeopleCount") or "")
	for _, n in ipairs(SquadSizes) do
		if n == saved then
			SquadSize = n
		end
	end
end
local spawnedIds = {}
local spawnedHumans = {}
local squadBusy = false
local busySince = 0

-- DespawnEntity takes the obtain id, not the entity; it also cancels a pending request.
local function despawnId(id)
	return pcall(function()
		game.traffic:DespawnEntity(id)
	end)
end

local function ForgetHumans()
	local removed = 0
	for _, id in ipairs(spawnedIds) do
		if despawnId(id) then
			removed = removed + 1
		end
	end
	spawnedIds = {}
	spawnedHumans = {}
	return removed
end

local function ClearSquad()
	say(T("removed", ForgetHumans()))
end

-- GetPassengers returns one value per seat, nil for an empty seat.
local function nonNil(...)
	local out = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then
			table.insert(out, v)
		end
	end
	return out
end

local function requestCrewCar(car, profiles)
	local ok, so, id = pcall(function()
		return game.traffic:ObtainCarWithCrew(car, profiles)
	end)
	if not ok then
		return nil, nil, tostring(so)
	end
	if so == nil or id == nil then
		return nil, nil, T("err_refused")
	end
	return so, id
end

local function spawnCrewCar(so, id, side)
	if not waitFor(so, 30000) then
		despawnId(id)
		return nil, T("err_models")
	end
	local p = activePlayer()
	if p == nil then
		despawnId(id)
		return nil, T("player_gone")
	end
	local pos, face = placeAhead(p, 11, side, 0.6)
	local ok, spawned = pcall(function()
		return game.traffic:SpawnCar(id, pos, face)
	end)
	if not ok or spawned == nil then
		despawnId(id)
		return nil, T("err_nocar", tostring(spawned))
	end
	if not waitFor(spawned, 10000) then
		despawnId(id)
		return nil, T("err_noappear")
	end
	local car = game.traffic:GetSpawnedEntity(id)
	if car == nil then
		despawnId(id)
		return nil, T("no_entity")
	end
	table.insert(spawnedIds, id)
	local okP, crew = pcall(function()
		return nonNil(car:GetPassengers())
	end)
	if not okP then
		dbg("GetPassengers: " .. tostring(crew))
		return {}
	end
	return crew
end

local function SpawnSquad(faction, roles, labelKey)
	return function()
		if player() == nil then
			return
		end
		if squadBusy and os.time() - busySince < 90 then
			say(T("squad_busy"))
			return
		end
		squadBusy = true
		busySince = os.time()

		local size = SquadSize
		local crews = { {}, {} }
		for i = 1, size do
			local profile = faction.prefix .. roles[(i - 1) % #roles + 1] .. "_lvl1"
			table.insert(crews[i <= SeatsPerCar and 1 or 2], profile)
		end
		local name = T(faction.key)
		say(T("squad_coming", name, T(labelKey), size))

		StartThread(function()
			local requests = {}
			local fail = nil
			local cars = #crews[2] > 0 and 2 or 1
			for c = 1, cars do
				local so, id, err = requestCrewCar(faction.car, crews[c])
				if so ~= nil then
					local side = cars == 1 and 0 or ((c == 1) and -3.4 or 3.4)
					table.insert(requests, { so = so, id = id, side = side })
				else
					fail = err
					dbg("ObtainCarWithCrew(" .. faction.car .. "): " .. tostring(err))
				end
			end

			local placed = 0
			for _, r in ipairs(requests) do
				local crew, err = spawnCrewCar(r.so, r.id, r.side)
				if crew == nil then
					fail = err
				else
					for _, hum in ipairs(crew) do
						local okOff, offErr = pcall(function()
							hum:GetOffVehicle(false, false)
						end)
						if not okOff then
							dbg("GetOffVehicle: " .. tostring(offErr))
						end
						table.insert(spawnedHumans, hum)
						placed = placed + 1
					end
				end
			end
			squadBusy = false

			if placed == 0 then
				say(T("squad_none", name, tostring(fail or T("err_nopeople"))))
			elseif fail ~= nil then
				say(T("squad_partial", name, placed, tostring(fail)))
			else
				say(T("squad_ok", name, placed))
			end
		end)
	end
end

local function hasRole(faction, role)
	for _, r in ipairs(faction.roles) do
		if r == role then
			return true
		end
	end
	return false
end

-- Spawned people are ordinary NPCs whose graph has the ambient smoking clips.
local npcForm = nil
local function SquadSmoke()
	if #spawnedHumans == 0 then
		say(T("squad_first"))
		return
	end
	StartThread(function()
		local count = 0
		for _, hum in ipairs(spawnedHumans) do
			local alive = readBool(function() return hum:IsDeath() end) ~= true
			if alive then
				local fam, form = probeSmoke(hum, SmokeFamilies, npcForm, nil, true)
				if fam ~= nil then
					npcForm = form
					count = count + 1
				end
			end
		end
		if count > 0 then
			say(T("squad_smoking", count))
		else
			say(T("squad_nosmoke"))
		end
	end)
end

local function arrivalHint()
	return T(SquadSize <= SeatsPerCar and "arrive_one" or "arrive_two", SquadSize)
end

-- One screen per faction: how many, then with what. Squad actions (smoke,
-- remove) live once, on the People screen.
local function FactionMenu(faction)
	return function()
		local menu = UI.SimpleMenu()
		menu:SetTitle(T(faction.key))
		local rows = {}
		local items, sel = {}, 1
		for i, n in ipairs(SquadSizes) do
			items[i] = tostring(n)
			if n == SquadSize then
				sel = i
			end
		end
		list(menu, "people_count", items, sel, function(_, _, _, _, idx)
			SquadSize = SquadSizes[tonumber(idx) or 1] or SquadSize
			if _ui_set_setting then
				_ui_set_setting("PeopleCount", tostring(SquadSize))
			end
			for _, r in ipairs(rows) do
				menu:SetEntryHint(r, arrivalHint())
			end
		end, Icon.people, "people_count_d")
		menu:AddSection(T("grp_weapon"))
		for _, w in ipairs(WeaponClasses) do
			if hasRole(faction, w.role) then
				rows[#rows + 1] = btn(menu, w.key, SpawnSquad(faction, { w.role }, w.key), Icon.weapon)
			end
		end
		rows[#rows + 1] = btn(menu, "w_mixed", SpawnSquad(faction, faction.roles, "w_mixed"), Icon.people)
		for _, r in ipairs(rows) do
			menu:Decorate(r, arrivalHint())
		end
		return menu
	end
end

local function PeopleMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("sec_people"))
	local group = nil
	for _, f in ipairs(Factions) do
		if f.group ~= group then
			group = f.group
			menu:AddSection(T(group))
		end
		local label = T(f.key)
		if f.note ~= nil then
			label = label .. "  ·  " .. T(f.note)
		end
		menu:Decorate(menu:AddButton(label, FactionMenu(f)), T("faction_d"), Icon.people, true)
	end
	menu:AddSection(T("grp_squad"))
	btn(menu, "squad_smoke", SquadSmoke, Icon.smoke, "squad_smoke_d")
	btn(menu, "clear_squad", ClearSquad, Icon.trash, "clear_squad_d")
	return menu
end

-----------
-- World --
-----------

local function readHour()
	return readNum(function() return game.gfx:GetTime() end)
end

local function reportHour(want)
	local now = readHour()
	if now == nil then
		return
	end
	if want ~= nil and math.abs(now - want) >= 0.5 and math.abs(now - want) <= 23.5 then
		say(T("time_refused", now))
	else
		say(T("time_ok", math.floor(now), math.floor((now % 1) * 60)))
	end
end

local function setHour(h)
	if player() == nil then
		return false
	end
	local ok, err = pcall(function()
		game.gfx:SetTime(h, 0.0)
	end)
	if not ok then
		say(T("failed", T("hour"), tostring(err)))
	end
	return ok
end

local function ExactTime()
	UI.SimpleTextInput(T("exact_prompt"), function(success, text)
		if not success then
			return
		end
		local h = tonumber((tostring(text):gsub(",", ".")))
		if h == nil or h < 0 or h > 24 then
			say(T("time_bad"))
			return
		end
		if setHour(h % 24) then
			StartThread(function()
				Sleep(300)
				reportHour(h % 24)
			end)
		end
	end)
end

local FlowSpeeds = { 1, 2, 5, 10 }
local flowSpeed = 1

-- Density is the traffic manager multiplier (SetTrafficDensity). Above x1 the
-- game's vehicle limits are the cap, so SetTrafficLimits raises moving and
-- translocated cars through the game's own setter, at most x1.5; past that the
-- car pool overflows. Populate fills the streets at once, so it only runs when
-- traffic comes back from x0; otherwise cars arrive the normal way.
local TrafficLevels = { { 0, "t0" }, { 0.5, "t05" }, { 1.0, "t1" }, { 1.5, "t15" }, { 2.0, "t2" } }
local trafficMult = 1.0

local function trafficState()
	local on = readBool(function() return game.traffic:GetIsAmbientTrafficOn() end)
	local gameDensity = readNum(function() return game.traffic:GetGlobalCarDensityMultiplier() end)
	return on, gameDensity
end

local function trafficStatusText()
	local on = trafficState()
	return T("traffic_status", trafficMult, on == false and T("off") or T("on"))
end

-- Applies at once; the notice waits until the list stops moving.
local function SetTraffic(mult)
	local wasOff = trafficMult <= 0
	local effective, cars = nil, nil
	local ok, err = pcall(function()
		if SetTrafficDensity ~= nil then
			effective = SetTrafficDensity(mult)
		end
		if SetTrafficLimits ~= nil then
			cars = SetTrafficLimits(math.max(1, math.min(mult, 1.5)))
		end
		if mult <= 0 then
			game.traffic:SetEnableAmbientTrafficSpawning(false)
			game.traffic:SwitchGenerators(false)
		else
			game.traffic:SwitchGenerators(true)
			game.traffic:SetEnableAmbientTrafficSpawning(true)
			if wasOff then
				game.traffic:Populate()
			end
		end
	end)
	if not ok then
		say(T("failed", T("density"), tostring(err)))
		return
	end
	trafficMult = mult
	local on, gameDensity = trafficState()
	dbg(string.format("traffic x%.2f: effective=%s cars=%s ambientOn=%s gameDensity=%s",
		mult, tostring(effective), tostring(cars), tostring(on), tostring(gameDensity)))
	debounce("traffic", 600, function()
		if SetTrafficDensity == nil then
			say(T("traffic_noapi"))
		elseif effective == nil then
			say(T("traffic_refused"))
		elseif mult <= 0 then
			say(T("traffic_empty"))
		elseif mult > 1 and cars ~= nil then
			say(T("traffic_more", effective, cars))
		else
			say(T("traffic_set", effective))
		end
	end)
end

local wantedLevel = 1
local policeFlags = { hold = false, nooffence = false, nodispatch = false, off = false }
local waterVisible = true

local function ClearWanted()
	call(nil, function()
		game.police:PreventZonesDecay(false)
		game.police:ZoneDeleteAll()
		policeFlags.hold = false
	end, T("wanted_cleared"))
end

local function SetWanted(level)
	wantedLevel = level
	debounce("wanted", 600, function()
		call(T("wanted"), function(p)
			game.police:ZoneDeleteAll()
			game.police:ZoneCreate(p:GetPos(), enums.PoliceZoneType.HUNT, level)
		end, T("wanted_set", level))
	end)
end

local function policeToggle(flag, label, apply)
	return function()
		local on = not policeFlags[flag]
		call(label, function()
			apply(on)
			policeFlags[flag] = on
		end)
	end
end

local function WorldMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("sec_world"))

	menu:AddSection(T("grp_time"))
	local hours = {}
	for h = 0, 23 do
		hours[h + 1] = string.format("%d:00", h)
	end
	local nowHour = readHour()
	local hourHold = 0
	local hourIdx = list(menu, "hour", hours, nowHour and (math.floor(nowHour) % 24 + 1) or nil, function(_, _, _, _, idx)
		local h = (tonumber(idx) or 1) - 1
		hourHold = 45
		if setHour(h) then
			debounce("hour", 700, function() reportHour(h) end)
		end
	end, Icon.clock, "hour_d")
	local flows = {}
	local flowSel = 1
	for i, v in ipairs(FlowSpeeds) do
		flows[i] = "x" .. v
		if v == flowSpeed then
			flowSel = i
		end
	end
	list(menu, "flow", flows, flowSel, function(_, _, _, _, idx)
		local v = FlowSpeeds[tonumber(idx) or 1] or 1
		local ok, err = pcall(function() game.gfx:SetTimeFlowSpeed(v) end)
		if ok then
			flowSpeed = v
			debounce("flow", 600, function() say(T("flow_set", v)) end)
		else
			say(T("failed", T("flow"), tostring(err)))
		end
	end, Icon.gauge, "flow_d")
	btn(menu, "exact", ExactTime, Icon.clock)
	sub(menu, "weather", partMenu("WeatherMenu"), Icon.cloud, "weather_d")

	menu:AddSection(T("grp_traffic"))
	local levels, levelSel = {}, 3
	for i, l in ipairs(TrafficLevels) do
		levels[i] = T(l[2]) .. "  x" .. tostring(l[1]):gsub("%.0$", "")
		if l[1] == trafficMult then
			levelSel = i
		end
	end
	local density = list(menu, "density", levels, levelSel, function(_, _, _, _, idx)
		local l = TrafficLevels[tonumber(idx) or 3]
		if l ~= nil then
			SetTraffic(l[1])
		end
	end, Icon.chart)

	menu:AddSection(T("grp_police"))
	btn(menu, "clear_wanted", ClearWanted, Icon.badge)
	list(menu, "wanted", { "1", "2", "3", "4", "5" }, wantedLevel, function(_, _, _, _, idx)
		SetWanted(tonumber(idx) or 1)
	end, Icon.badge, "wanted_d")
	local hold = chk(menu, "wanted_hold", policeToggle("hold", T("wanted_hold"), function(on)
		game.police:PreventZonesDecay(on)
	end), Icon.lock)
	local nooffence = chk(menu, "nooffence", policeToggle("nooffence", T("nooffence"), function(on)
		game.police:DisableOffencesGlobal(on)
	end), Icon.eye, "nooffence_d")
	local nodispatch = chk(menu, "nodispatch", policeToggle("nodispatch", T("nodispatch"), function(on)
		game.police:PreventDispatchSpeech(on)
	end), Icon.relay)
	local off = chk(menu, "police_off", policeToggle("off", T("police_off"), function(on)
		if on then game.police:Disable() else game.police:Enable() end
	end), Icon.power)

	menu:AddSection(T("grp_misc"))
	local water = chk(menu, "water", function()
		local on = not waterVisible
		call(T("water"), function()
			game.game:SetWaterVisibility(on)
			waterVisible = on
		end)
	end, Icon.horizon)
	btn(menu, "clearweap", function()
		call(T("clearweap"), function(p)
			game.game:ClearWeaponsInRadius(p:GetPos(), 20)
		end, T("done_fmt", T("clearweap")))
	end, Icon.trash, "clearweap_d")
	btn(menu, "corpses", function()
		call(T("corpses"), function(p)
			local n = game.game:GetCorpseCountAroundPos(p:GetPos(), 100)
			say(T("corpses_n", tonumber(n) or 0))
		end)
	end, Icon.chart, "corpses_d")

	-- The game is asked for the hour and traffic state twice a second, not every frame.
	local tick = 0
	local function sync()
		tick = tick + 1
		if hourHold > 0 then
			hourHold = hourHold - 1
		elseif tick % 15 == 0 then
			local h = readHour()
			if h ~= nil then
				menu:SelectListEntryLive(hourIdx, math.floor(h) % 24 + 1)
			end
		end
		if tick % 15 == 1 then
			menu:SetEntryHint(density, trafficStatusText())
		end
		menu:SetChecked(hold, policeFlags.hold)
		menu:SetChecked(nooffence, policeFlags.nooffence)
		menu:SetChecked(nodispatch, policeFlags.nodispatch)
		menu:SetChecked(off, policeFlags.off)
		menu:SetChecked(water, waterVisible)
	end
	sync()
	menu:OnUpdate(sync)
	return menu
end

------------
-- Camera --
------------

local function CameraMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("sec_camera"))
	local fpsRow = nil
	if type(FpsLikeToggle) == "function" then
		fpsRow = chk(menu, "eyecam", function()
			FpsLikeToggle()
			if FpsLikeEnabled == true then
				say(T("fps_on"))
			else
				say(T("fps_off"))
			end
		end, Icon.eye, "fps_quick_d")
		btn(menu, "fps_submenu", function()
			local fn = TrainerParts and TrainerParts.EyeCameraMenu
			if fn == nil then
				say(T("failed", T("fps_submenu"), "?"))
				return nil
			end
			return fn()
		end, Icon.sliders, "eyecam_d")
	else
		sub(menu, "eyecam", partMenu("EyeCameraMenu"), Icon.eye, "eyecam_d")
	end
	sub(menu, "freecam", partMenu("CameraControlsMenu"), Icon.camera, "freecam_d")
	btn(menu, "camreset", function()
		if partCall("ResetCamera", T("camreset")) then
			say(T("done_fmt", T("camreset")))
		end
	end, Icon.reset)
	if fpsRow ~= nil then
		menu:OnUpdate(function()
			menu:SetChecked(fpsRow, FpsLikeEnabled == true)
		end)
	end
	return menu
end

--------------
-- Settings --
--------------

local SettingsMenu, LanguageMenu

local function rootIndexOf(builder)
	for i, item in ipairs(TrainerMenuItems) do
		if item[3] == builder then
			return i
		end
	end
	return 1
end

-- Rebuilds the open menus in the new language and keeps the player where they were.
local function SetLanguage(i)
	if I18n.Languages[i] == nil then
		return
	end
	LangIdx = i
	if _ui_set_language then
		_ui_set_language(langCode())
	end
	if _ui_set_setting then
		_ui_set_setting("Language", langCode())
	end
	if _SH_finalizeMenus and _ui_reset_to_root then
		_SH_finalizeMenus()
		_ui_reset_to_root(rootIndexOf(SettingsMenu))
		_SH_pushMenuToCpp(SettingsMenu())
		_SH_pushMenuToCpp(LanguageMenu())
	end
	say(T("lang_set", I18n.Languages[i].name))
end

LanguageMenu = function()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("language"))
	local rows = {}
	for i, l in ipairs(I18n.Languages) do
		rows[i] = menu:AddCheckbox(l.name, function()
			SetLanguage(i)
		end)
		menu:Decorate(rows[i], nil, Icon.language)
	end
	menu:SetSelected(rows[LangIdx])
	local function sync()
		for i, row in ipairs(rows) do
			menu:SetChecked(row, i == LangIdx)
		end
	end
	sync()
	menu:OnUpdate(sync)
	return menu
end

-- Panel look, drawn by the ASI; the ASI also reads these keys from ScriptHook.ini at start.
local Themes = { "dark", "light" }
-- key in the ini, key for _ui_set_look, the values, the default
local Looks = {
	transparency = { "Transparency", "transparency", { "none", "low", "medium", "high", "max" }, 3 },
	ui_scale = { "UiScale", "scale", { "90", "100", "115", "130" }, 2 },
	panel_side = { "PanelSide", "side", { "left", "right" }, 1 },
	motion = { "Motion", "motion", { "full", "reduced" }, 1 },
}

local function themeIndex()
	local saved = _ui_get_setting and _ui_get_setting("Theme")
	return saved == "light" and 2 or 1
end

local function lookList(menu, key, names, icon)
	local ini, code, values, default = Looks[key][1], Looks[key][2], Looks[key][3], Looks[key][4]
	local saved = _ui_get_setting and _ui_get_setting(ini)
	local cur = default
	for i, v in ipairs(values) do
		if v == saved then
			cur = i
		end
	end
	list(menu, key, names, cur, function(_, _, _, _, idx)
		local v = values[tonumber(idx) or default] or values[default]
		if _ui_set_setting then
			_ui_set_setting(ini, v)
		end
		if _ui_set_look then
			_ui_set_look(code, v)
		else
			say(T("theme_need_asi"))
		end
	end, icon, key .. "_d")
end

SettingsMenu = function()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("sec_settings"))
	local i = menu:AddButton(T("language") .. "  ·  " .. I18n.Languages[LangIdx].name, LanguageMenu)
	menu:Decorate(i, T("language_d"), Icon.language, true)
	list(menu, "theme", { T("theme_dark"), T("theme_light") }, themeIndex(), function(_, _, _, _, idx)
		local code = Themes[tonumber(idx) or 1] or "dark"
		if _ui_set_setting then
			_ui_set_setting("Theme", code)
		end
		if _ui_set_theme then
			_ui_set_theme(code)
		else
			say(T("theme_need_asi"))
		end
	end, Icon.palette, "theme_d")
	-- how much of the blurred game shows through the panel; "medium" is the look it always had
	lookList(menu, "transparency", { T("glass_none"), T("glass_low"), T("glass_medium"), T("glass_high"), T("glass_max") },
		Icon.layers)
	lookList(menu, "ui_scale", { "90%", "100%", "115%", "130%" }, Icon.zoom)
	lookList(menu, "panel_side", { T("side_left"), T("side_right") }, Icon.dock)
	lookList(menu, "motion", { T("motion_full"), T("motion_reduced") }, Icon.stopwatch)
	-- every row of the trainer, its game calls tried where that changes nothing for good (checks.lua)
	sub(menu, "selftest", function() return Checks.Menu() end, Icon.gears, "selftest_d")
	return menu
end

----------
-- Root --
----------

local function section(key, icon, builder)
	table.insert(TrainerMenuItems, {
		function() return T(key) end,
		function() return T(key .. "_d") end,
		builder,
		icon = icon,
	})
end

section("sec_player", Icon.player, PlayerMenu)
section("sec_vehicle", Icon.car, VehicleMenu)
section("sec_people", Icon.people, PeopleMenu)
section("sec_world", Icon.world, WorldMenu)
section("sec_camera", Icon.camera, CameraMenu)
section("sec_settings", Icon.settings, SettingsMenu)

function OnLoad()
	godWanted = false
	say(T("loaded"))
end

-- Called from ASI before reloadall tears down callbacks (FPS/camera must stop first).
function SafeTrainerPreReload()
	if type(FpsLikeDisable) == "function" then
		pcall(FpsLikeDisable)
	end
	stopHigh()
	if Mobility ~= nil and Mobility.ClearRun ~= nil then
		Mobility.ClearRun()
	end
	if StreetFight ~= nil and StreetFight.OnReload ~= nil then
		StreetFight.OnReload()
	elseif Brawl ~= nil and Brawl.Set ~= nil then
		Brawl.Set(false, true)
	end
	smokeToken = smokeToken + 1
	if smokeLocked then
		pcall(function()
			game.game:GetActivePlayer():LockControls(false)
		end)
	end
	smokeLocked = false
	smoking = false
	pcall(ForgetHumans)
end

function OnReload()
	if godWanted then
		SetGod(false, true)
	end
	godWanted = false
	squadBusy = false
	stopHigh()
	if Mobility ~= nil and Mobility.ClearRun ~= nil then
		Mobility.ClearRun()
	end
	if StreetFight ~= nil and StreetFight.OnReload ~= nil then
		StreetFight.OnReload()
	elseif Brawl ~= nil and Brawl.Set ~= nil then
		Brawl.Set(false)
	end
	smokeToken = smokeToken + 1
	if smokeLocked then
		pcall(function()
			game.game:GetActivePlayer():LockControls(false)
		end)
	end
	smokeLocked = false
	smoking = false
	playerFamily, playerForm, playerNoSmoke, npcForm = nil, nil, false, nil
	pcall(ForgetHumans)
	say(T("reloaded"))
end
