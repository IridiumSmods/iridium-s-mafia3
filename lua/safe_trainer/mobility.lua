-- Super run and jumps.
--
-- The game has no call that makes the player faster: SetMovementSpeedMult and
-- OverrideMoveSpeed drive AI movement, and ClampSprintSpeed / ClampMoveSpeed only
-- cap the speed (missions use them to slow Lincoln down). Super run therefore
-- scales the player's own stride: every tick it measures how far the animation
-- moved him since the last tick and adds (multiplier - 1) times that step with
-- SetPos. Direction, turns, stairs and walls stay the game's: a blocked step is
-- zero, so the boost is zero too. Height is never scaled, so falls stay normal.

local T = Hub.T
local say = Hub.say
local dbg = Hub.dbg
local activePlayer = Hub.activePlayer
local player = Hub.player
local btn = Hub.btn
local list = Hub.list
local Icon = Hub.Icon
local readBool = Hub.readBool

Mobility = {}

-- runIdx 1 is off; the others are stride multipliers.
local RunModes = { "run_off", "run_x15", "run_x2", "run_x3", "run_x5" }
local RunMult = { 1.0, 1.5, 2.0, 3.0, 5.0 }
local runIdx = 1
local jumpBusy = false

-- A step shorter than this is standing or turning on the spot (metres per tick).
local MIN_STEP = 0.004
-- Longer than this is a teleport, a cutscene cut or a ragdoll launch, not running.
local MAX_STEP = 0.6
-- The added distance per tick never exceeds this, so a wall is never skipped.
local MAX_BOOST = 0.45

local lastPos = nil
local lastOwner = false
local clampsCleared = false

local function runLabel()
	return T(RunModes[runIdx])
end

function Mobility.IsSuperRun()
	return runIdx > 1
end

function Mobility.GetRunIdx()
	return runIdx
end

function Mobility.GetMult()
	return RunMult[runIdx]
end

function Mobility.SetRunIdx(idx)
	idx = tonumber(idx) or 1
	if RunMult[idx] == nil then
		idx = 1
	end
	runIdx = idx
	lastPos = nil
end

local function readPos(p)
	local ok, v = pcall(function()
		local g = p:GetPos()
		return { x = g.x, y = g.y, z = g.z }
	end)
	if ok and v ~= nil and type(v.x) == "number" and v.x == v.x then
		return v
	end
	return nil
end

-- Earlier builds called the clamp and AI speed functions every frame; undo them once.
local function clearOldClamps(p)
	if clampsCleared then
		return
	end
	clampsCleared = true
	pcall(function() p:ResetMoveSpeed() end)
	pcall(function() p:ResetDisabledInputsMoveSpeed() end)
end

-- Called on a menu change and from the player menu sync. The stride itself is
-- tracked only by Maintain: a reset here would shorten the next measured step.
function Mobility.ApplyRun(p)
	if p == nil then
		return false
	end
	clearOldClamps(p)
	return true
end

-- Called every tick by Maintain while the player is on foot.
function Mobility.Maintain(p, tick)
	if runIdx <= 1 or p == nil or jumpBusy then
		lastPos = nil
		return
	end
	local okOwner, owner = pcall(function()
		return p:GetOwner()
	end)
	if okOwner and owner ~= nil then
		lastOwner = true
		lastPos = nil
		return
	end
	if lastOwner then
		lastOwner = false
		lastPos = nil
	end
	if readBool(function() return p:AreControlsLocked() end) == true then
		lastPos = nil
		return
	end
	local pos = readPos(p)
	if pos == nil then
		lastPos = nil
		return
	end
	local prev = lastPos
	lastPos = pos
	if prev == nil then
		return
	end
	local dx, dy = pos.x - prev.x, pos.y - prev.y
	local step = math.sqrt(dx * dx + dy * dy)
	if step < MIN_STEP or step > MAX_STEP then
		return
	end
	local extra = step * (RunMult[runIdx] - 1)
	if extra > MAX_BOOST then
		extra = MAX_BOOST
	end
	local k = extra / step
	local nx, ny = pos.x + dx * k, pos.y + dy * k
	local ok = pcall(function()
		p:SetPos(Math:newVector(nx, ny, pos.z))
	end)
	if ok then
		lastPos = { x = nx, y = ny, z = pos.z }
	end
end

function Mobility.ClearRun()
	runIdx = 1
	lastPos = nil
end

local function horizontalDir(p)
	local ok, dir = pcall(function()
		return p:GetDir()
	end)
	if not ok or dir == nil then
		return nil
	end
	local len = math.sqrt(dir.x * dir.x + dir.y * dir.y)
	if len < 0.001 then
		return Math:newVector(0, 1, 0)
	end
	return Math:newVector(dir.x / len, dir.y / len, 0)
end

local function jumpPos(base, fwd, forwardDist, z)
	return Math:newVector(base.x + fwd.x * forwardDist, base.y + fwd.y * forwardDist, base.z + z)
end

local function tryVelocityJump(p, fwd, upVel, fwdVel)
	return pcall(function()
		p:SetVelocity(Math:newVector(fwd.x * fwdVel, fwd.y * fwdVel, upVel))
	end)
end

local function tryImpulseJump(p, fwd, up, forward)
	local ok = pcall(function()
		p:SetImpulse(Math:newVector(fwd.x * forward, fwd.y * forward, up), Math:newVector(0, 0, 1))
	end)
	if ok then
		return true
	end
	return pcall(function()
		p:ApplyActivationImpulse(up + forward, Math:newVector(fwd.x, fwd.y, up))
	end)
end

local function arcJump(p, peak, forward)
	local okBase, base = pcall(function()
		return p:GetPos()
	end)
	if not okBase or base == nil then
		return false
	end
	local fwd = horizontalDir(p)
	if fwd == nil then
		return false
	end
	for i = 1, 24 do
		local t = i / 24
		local z = 4 * peak * t * (1 - t)
		local pos = jumpPos(base, fwd, forward * t, z)
		if not pcall(function()
			p:SetPos(pos)
		end) then
			return false
		end
		Sleep(16)
	end
	return true
end

local function doJump(labelKey, peak, forward, upVel, fwdVel, impulseUp, impulseFwd)
	return function()
		local p = player()
		if p == nil then
			return
		end
		if jumpBusy then
			return
		end
		local okOwner, owner = pcall(function()
			return p:GetOwner()
		end)
		if okOwner and owner ~= nil then
			say(T("jump_in_car"))
			return
		end
		if readBool(function()
			return p:AreControlsLocked()
		end) == true then
			say(T("jump_locked"))
			return
		end
		StartThread(function()
			-- Super run must not stretch the steps of the jump arc.
			jumpBusy = true
			lastPos = nil
			local fwd = horizontalDir(p)
			if fwd == nil then
				jumpBusy = false
				say(T("failed", T(labelKey), "?"))
				return
			end
			local moved = false
			if tryVelocityJump(p, fwd, upVel, fwdVel) then
				Sleep(120)
				moved = true
			elseif tryImpulseJump(p, fwd, impulseUp, impulseFwd) then
				Sleep(120)
				moved = true
			elseif arcJump(p, peak, forward) then
				moved = true
			end
			lastPos = nil
			jumpBusy = false
			if moved then
				say(T(labelKey))
			else
				say(T("failed", T(labelKey), T("jump_fail")))
			end
		end)
	end
end

function Mobility.Menu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(T("mobility"))
	menu:AddSection(T("grp_mobility_run"))
	local runLabels = {}
	for i, k in ipairs(RunModes) do
		runLabels[i] = T(k)
	end
	list(menu, "super_run", runLabels, runIdx, function(_, _, _, _, idx)
		Mobility.SetRunIdx(idx)
		local p = activePlayer()
		if p ~= nil then
			Mobility.ApplyRun(p)
		end
		say(T("super_run_set", runLabel()))
		dbg("super run: stride x" .. tostring(RunMult[runIdx]))
	end, Icon.chart, "super_run_d")
	menu:AddSection(T("grp_mobility_jump"))
	btn(menu, "jump", doJump("jump", 0.65, 0.45, 7.5, 4.0, 520, 180), Icon.up, "jump_d")
	btn(menu, "super_jump", doJump("super_jump", 1.55, 1.05, 14.0, 7.5, 980, 320), Icon.up, "super_jump_d")
	return menu
end
