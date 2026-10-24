-- Street fight (the brawl mode): fists only. Q punches everybody. An enemy can be
-- finished with Q, the game's own stun takedown, only after N hits (the menu's
-- few / medium / many), counted from his health. Civilians can no longer be
-- taken down with one Q: APPLY_STREET_MELEE.bat switches their instant
-- takedowns off in temp_tables.sds. Fists never take anybody below 1 health,
-- so a civilian goes down after a beating, through the same stun takedown.
--
-- How the game ends a fight (2026-10-21 log, gangsters with 75, 95 and 115
-- health): a punch takes 9, the combo's heavy blow 50. A blow that lands low
-- puts him at 1 and stuns him, and Q on a stunned enemy is the takedown: three
-- to six hits, whatever the count said. IsStunned never answered, and the melee
-- tag tried before held back only the "locked" takedowns, not the open ones.
--
-- So the count works through his health: until he has taken his N hits he is
-- put back to the health he came in with after every blow, too high to be
-- stunned; on the N-th hit he is put at a quarter, so the next blow stuns him
-- and Q finishes him. Should a blow stun him early all the same, the ASI keeps
-- Q from the game while he comes round (_input_block_melee).

local T = Hub.T
local say = Hub.say
local dbg = Hub.dbg
local activePlayer = Hub.activePlayer
local chk = Hub.chk
local list = Hub.list
local Icon = Hub.Icon

StreetFight = {}

local enabled = false
local maxRange = 6.0
-- Ticks between two hits counted on one target: one punch can take health twice.
local hitGapTicks = 12
-- Hits an enemy takes before Q may finish him: few / medium / many in the menu.
local HIT_LEVELS = { 4, 7, 10 }
local hitLevel = 2
local combatByTarget = {}
-- Fists stop at 1: a stunned enemy has 1 health.
local STUN_HP = 1.01
-- His share of health after the last counted hit: 28.75 of 115 was stunned by
-- the next punch, 26.75 of 95 was not (2026-10-21).
local READY_SHARE = 0.25
-- Ticks (about three seconds) Q stays with the ASI after an early stun, for the
-- stun to wear off.
local EARLY_HOLD_TICKS = 180
-- Frames the ASI keeps Q back after each renewal: it lapses by itself when the
-- mode stops renewing it.
local Q_BLOCK_FRAMES = 10
local qHoldUntil = -1
local qBlocked = false
local noGateTold = false
local healthWriteTold = false

do
	local saved = tonumber(_ui_get_setting and _ui_get_setting("BrawlHits") or "")
	if saved ~= nil and HIT_LEVELS[saved] ~= nil then
		hitLevel = saved
	end
end

function StreetFight.IsOn()
	return enabled
end

function StreetFight.GetHitProgress(target)
	if target == nil then
		return 0, 0
	end
	local st = combatByTarget[target]
	if st == nil then
		return 0, 0
	end
	return st.hits, st.need
end

local function readStyleStr(p)
	if p == nil then
		return nil
	end
	local ok, s = pcall(function()
		return p:GetControlStyleStr()
	end)
	if ok and type(s) == "string" and s ~= "" then
		return s
	end
	return nil
end

local function readNumField(obj, name)
	local ok, v = pcall(function()
		return obj[name]
	end)
	if ok and type(v) == "number" then
		return v
	end
	return nil
end

local function vec3(ent)
	local ok, pos = pcall(function()
		return ent:GetPos()
	end)
	if not ok or pos == nil then
		return nil
	end
	local x = pos.x or pos[1]
	local y = pos.y or pos[2]
	local z = pos.z or pos[3]
	if x == nil or y == nil or z == nil then
		return nil
	end
	return x, y, z
end

local function dist3(p, ent)
	local px, py, pz = vec3(p)
	local ex, ey, ez = vec3(ent)
	if px == nil or ex == nil then
		return nil
	end
	local dx, dy, dz = ex - px, ey - py, ez - pz
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function isVehicle(ent)
	if ent == nil then
		return false
	end
	local ok = pcall(function()
		ent:GetPassengers()
	end)
	return ok
end

local function callMaybe(obj, name)
	if obj == nil then
		return nil
	end
	local ok, v = pcall(function()
		local fn = obj[name]
		if type(fn) ~= "function" then
			return nil
		end
		return fn(obj)
	end)
	if ok and v ~= nil and v ~= obj then
		return v
	end
	return nil
end

local function isDead(ent)
	local ok, dead = pcall(function()
		return ent:IsDeath()
	end)
	return ok and dead == true
end

local function isHuman(ent)
	if ent == nil or isVehicle(ent) or isDead(ent) then
		return false
	end
	return vec3(ent) ~= nil
end

local function isFighting(p)
	local ok, fighting = pcall(function()
		return p:IsMeleeFighting()
	end)
	return ok and fighting == true
end

-- The game has no IsCivilian on humans (not in its method table), so this asks
-- whatever answers: IsCivilian, an AI type named civilian, or a civilian
-- archetype (by its hash in HashDatabase). nil when nothing tells; the answers
-- are logged once per target, to see in ScriptHook.log what the game gives.
local function civilianOf(ent)
	local ok, v = pcall(function()
		return ent:IsCivilian()
	end)
	if ok and type(v) == "boolean" then
		return v, "IsCivilian " .. tostring(v)
	end
	local seen = {}
	for _, name in ipairs({ "GetAIType", "GetCivilArchetype", "GetBattleArchetype" }) do
		local r = callMaybe(ent, name)
		if r ~= nil then
			local text = tostring(r)
			-- the game hands 64-bit hashes over whole: tostring keeps every digit, %.0f does not
			if type(HashDatabase) == "table" then
				text = HashDatabase[text] or (type(r) == "number" and HashDatabase[string.format("%.0f", r)]) or text
			end
			seen[#seen + 1] = name .. " " .. text
			if string.lower(text):find("civil") then
				return true, table.concat(seen, ", ")
			end
		end
	end
	return nil, #seen > 0 and table.concat(seen, ", ") or "no answer"
end

local function targetInCrosshair(p)
	local physics = game and game.physics
	if physics == nil then
		return nil
	end
	for _, name in ipairs({ "GetHumanInScreenCenter", "GetCharacterInScreenCenter", "GetActorInScreenCenter" }) do
		local ent = callMaybe(physics, name)
		if ent ~= nil and ent ~= p and isHuman(ent) then
			local d = dist3(p, ent)
			if d ~= nil and d <= maxRange then
				return ent
			end
		end
	end
	return nil
end

local function resolveTarget(p)
	if p == nil then
		return nil
	end
	local t = targetInCrosshair(p)
	if t ~= nil then
		return t
	end
	for _, name in ipairs({ "GetMeleeTarget", "GetAttackTarget", "GetFocusedHuman", "GetCurrentTarget" }) do
		local ent = callMaybe(p, name)
		if ent ~= nil and ent ~= p and isHuman(ent) then
			local d = dist3(p, ent)
			if d ~= nil and d <= maxRange then
				return ent
			end
		end
	end
	return nil
end

local function stateFor(target)
	local st = combatByTarget[target]
	if st == nil then
		local civ, why = civilianOf(target)
		st = { hits = 0, need = HIT_LEVELS[hitLevel], civilian = civ == true, full = nil, lastHp = nil,
			lastHitTick = -9999, edged = false, told = false }
		combatByTarget[target] = st
		dbg("brawl target: civilian " .. tostring(civ) .. " (" .. why .. ")")
	end
	return st
end

-- Puts the target at hp; false when the game ignores it (logged once).
local function setHealth(target, hp)
	pcall(function()
		target.health = hp
	end)
	local now = readNumField(target, "health")
	if now ~= nil and math.abs(now - hp) < 0.5 then
		return true
	end
	if not healthWriteTold then
		healthWriteTold = true
		dbg("brawl: the game ignores the target's health (wrote " .. hp .. ", reads " .. tostring(now) .. ")")
	end
	return false
end

-- A hit is the target's health dropping. An enemy short of his hits is put back
-- to his health after every blow, and at a quarter on the last one; he is told
-- how far along he is, and when Q can finish him.
local function recordHits(p, tick)
	if not isFighting(p) then
		return
	end
	local target = resolveTarget(p)
	if target == nil then
		return
	end
	if isDead(target) then
		combatByTarget[target] = nil
		return
	end
	local st = stateFor(target)
	local h = readNumField(target, "health")
	if h == nil then
		return
	end
	if st.full == nil or h >= st.lastHp - 0.25 then
		st.full = st.full or h
		st.lastHp = h
		return
	end
	if tick - st.lastHitTick >= hitGapTicks then
		st.hits = st.hits + 1
		st.lastHitTick = tick
		if not st.civilian and st.hits <= st.need then
			say(T("brawl_hit_fmt", st.hits, st.need))
		end
	end
	if not st.civilian then
		local stunned = h <= STUN_HP
		if st.hits >= st.need then
			if stunned and not st.told then
				st.told = true
				say(T("brawl_ready"))
			elseif not stunned and not st.edged then
				st.edged = true
				local edge = st.full * READY_SHARE
				if h > edge and setHealth(target, edge) then
					h = edge
				end
			end
			dbg(string.format("brawl: hit %d/%d, health %.2f", st.hits, st.need, h))
		else
			if stunned then
				qHoldUntil = tick + EARLY_HOLD_TICKS
				say(T("brawl_early_fmt", st.hits, st.need))
			end
			if setHealth(target, st.full) then
				h = st.full
			end
			dbg(string.format("brawl: hit %d/%d, health back to %.2f%s", st.hits, st.need, h,
				stunned and " (stunned early, Q held)" or ""))
		end
	end
	st.lastHp = h
end

local function blockQ(on)
	if on then
		if _input_block_melee == nil then
			if not noGateTold then
				noGateTold = true
				print("Trainer: brawl mode: this ASI cannot hold Q back (rebuild it: BUILD_STREET_FIGHT_ASI.bat)")
			end
			return
		end
		pcall(_input_block_melee, Q_BLOCK_FRAMES)
		qBlocked = true
	elseif qBlocked then
		if _input_block_melee ~= nil then
			pcall(_input_block_melee, 0)
		end
		qBlocked = false
	end
end

function StreetFight.Set(on, quiet)
	local want = on == true
	enabled = want
	if Brawl ~= nil and Brawl.Set ~= nil then
		Brawl.Set(want, true)
	end
	local p = activePlayer()
	if not want then
		combatByTarget = {}
		qHoldUntil = -1
		qBlocked = true
		blockQ(false)
		if not quiet then
			say(T("brawl_off"))
		end
		return
	end
	if quiet then
		return
	end
	local s = readStyleStr(p)
	if s ~= nil and (string.upper(s):find("CLOSE") or string.upper(s):find("COMBAT")) then
		say(T("brawl_on_ok", s))
	else
		say(T("brawl_on"))
		if s ~= nil then
			say(T("brawl_fail", s))
		end
	end
	say(T("brawl_rules_fmt", HIT_LEVELS[hitLevel]))
end

function StreetFight.ToggleFromMenu()
	StreetFight.Set(not StreetFight.IsOn())
end

function StreetFight.Maintain(p, tick)
	if not enabled or p == nil then
		return
	end
	tick = tick or 0
	recordHits(p, tick)
	-- held for every target: the crosshair loses the stunned one now and then
	blockQ(tick < qHoldUntil)
	if Brawl ~= nil and Brawl.Maintain ~= nil then
		Brawl.Maintain(p, tick)
	end
end

function StreetFight.AttachPlayerMenu(menu)
	menu:AddSection(T("grp_brawl"))
	local br = chk(menu, "brawl_mode", function()
		StreetFight.ToggleFromMenu()
	end, Icon.badge, "brawl_mode_d")
	local names = { T("brawl_hits_few"), T("brawl_hits_mid"), T("brawl_hits_many") }
	list(menu, "brawl_hits", names, hitLevel, function(_, _, _, _, idx)
		local i = tonumber(idx)
		if i ~= nil and HIT_LEVELS[i] ~= nil then
			hitLevel = i
			-- the book starts over, so every target counts to the new number
			combatByTarget = {}
			if _ui_set_setting then
				_ui_set_setting("BrawlHits", tostring(i))
			end
		end
	end, Icon.gauge, "brawl_hits_d")
	return br
end

function StreetFight.OnReload()
	combatByTarget = {}
	StreetFight.Set(false, true)
end
