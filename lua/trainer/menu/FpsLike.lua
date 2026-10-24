-- First-person view.
--
-- "Head camera" (default) is how first-person mods for third-person games do it
-- (GTA SA/IV, Skyrim, Mafia II): the player camera is locked to a dummy entity
-- that is moved onto Lincoln's eyes every frame. The position comes from the eye
-- bones with the head bob filtered; the view direction comes from the mouse, not
-- from the head, so walking does not shake the view. The camera sits a few
-- centimetres along the view in front of the eyes, so the head is always behind
-- it, whichever way you look. If the game keeps turning its own camera under the
-- lock (cam:GetDir() then differs from the direction we set while the mouse is
-- idle), the view follows that camera instead, so mouse feel stays native.
--
-- "Game camera" pulls the game's own orbit camera toward the eyes with
-- ScriptForcedOffsetStart. The offset is relative to the camera rig: x slides it
-- along the horizontal right of the view, y along the view axis, z straight up.
-- Measured in game (2026-10-20 log): the orbit arm cannot get shorter than zero,
-- so on foot the camera stops on the vertical plane through Lincoln's root,
-- ~0.12 m behind the eyes. The target is clamped to that plane; pushing past it
-- only wound the offset up until the guard reset it (the camera "fell off").
-- In a car the driver sits behind the car's pivot, so there it reaches the eyes.
--
-- Standing still, Lincoln turns to face where the view points, like the
-- first-person mode of GTA; moving and aiming already turn him natively.
--
-- Steering (2026-10-20 test): under the lock Lincoln still walks relative to
-- the game's own camera, which keeps its old direction. Every frame the head
-- camera therefore turns that hidden camera to where the picture looks. Which
-- camera call does it is not documented, so on first use the trainer tries
-- ScriptUnlockResetDir, ScriptPointAtVec, ScriptLookAtDir and
-- ScriptResetCamBehindPlayer while Lincoln stands still, keeps the ones that
-- really turned the camera (FpSteer in ScriptHook.ini), and while walking checks
-- that the steps go where the view looks, moving on to the next one if not.
--
-- "Game camera config" is the main path now: APPLY_FP_CAMERA.bat rewrites the
-- game's own camera configs in tables.sds (no orbit distance, no shoulder
-- offset, 0.28 m ahead along the view at eye height and 0.38 on the move, a
-- short spring), like the
-- Nexus first-person mod. Mouse, walking where the view points, aiming and
-- collision are then all the game's. The trainer notices it on foot (the game's
-- third-person camera never comes that close to the eyes) and only adds what a
-- config cannot: the body turning with the view, hiding the body, following the
-- eyes down while crouched, the camera height and head bob settings, the menu's
-- field of view while no gun is in hand, riding stairs smoothly, and moving the
-- camera toward the weapon while a gun is in hand but not aimed down the sights
-- (the right mouse button, read by the ASI). Vehicles keep the modes above.

local wasOn = FpsLikeEnabled == true
FpsLikeEnabled = false

--------------
-- Settings --
--------------

-- Numbers and lists that are only read, as fields of one table. The game's
-- HavokScript does not compile a main chunk this close to 200 locals: at 197
-- the file was not loaded at all ("include() LOAD ERROR (code -4)" in
-- ScriptHook.log, 2026-10-22), while the stock Lua of the tests took it. New
-- file-level state goes into tables too; _luacheck.py counts the locals.
local K = {}

local VIEWS = { "Head camera", "Game camera" }
local BOBS = { "Off", "Low", "Full" }
-- Share of the head's vertical motion followed per frame.
K.BOB_K = { 0.08, 0.3, 1.0 }
-- Share of the head's own motion added where the camera is otherwise fixed: on
-- foot with the game camera config, and on the driver's seat.
K.BOB_SHARE = { 0, 0.35, 1.0 }
local FOVS = { "Game", "70", "80", "90" }
K.FOV_VAL = { false, 70, 80, 90 }
-- Metres along the view in front of the eyes (head camera on foot; vehicles: CAR.fwdv).
local FWDS = { "0.00", "0.04", "0.08", "0.12", "0.16" }
K.FWD_VAL = { 0.0, 0.04, 0.08, 0.12, 0.16 }
local LIFTS = { "-0.06", "-0.03", "0.00", "+0.03", "+0.06" }
K.LIFT_VAL = { -0.06, -0.03, 0.0, 0.03, 0.06 }
local SENS = { "0.5x", "0.75x", "1x", "1.25x", "1.5x", "2x" }
K.SENS_VAL = { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0 }
local ONOFF = { "Off", "On" }
-- The view key and the look-back key in a vehicle: Windows virtual-key codes the
-- ASI reads (_input_key_down); false = none. F5 by default: the game binds no F keys.
K.VIEW_KEYS, K.VIEW_VK = { "Off", "F5", "F6", "V", "B", "N" }, { false, 0x74, 0x75, 0x56, 0x42, 0x4E }
K.BACK_KEYS, K.BACK_VK = { "Off", "Mouse 3", "C", "X" }, { false, 0x04, 0x43, 0x58 }
K.FOOT_VIEWS = { "First person", "Third person" }
K.CAR_CAMS = { "At the driver's eyes", "On the hood" }
K.FXS = { "Off", "Light", "Strong" }
-- Presets: several rows at once (nil leaves a row as it is).
K.PRESETS = { "Choose", "Standard", "Steady", "Immersive" }
K.PRESET_VAL = { false, { bob = 2, fx = 2, steps = true, headHide = true }, { bob = 1, fx = 1, steps = true, headHide = true },
	{ bob = 3, fx = 3, steps = true, headHide = true } }
-- The camera's place in the sights is kept per kind of gun (asked 2026-10-22:
-- some guns covered the target): names, the setting keys' ends, and the kind
-- by the class at the start of the weapon's name (p_mast_sa: "p").
K.AIM_KINDS = { "Pistols and revolvers", "Submachine guns", "Shotguns", "Rifles", "Sniper rifles", "Other guns" }
K.AIM_KEYS = { "Pistol", "Smg", "Shotgun", "Rifle", "Sniper", "Other" }
K.AIM_KIND_OF = { p = 1, rev = 1, smg = 2, sg = 3, rif = 4, ar = 4, sn = 5 }

-- Keys differ from the 2026-10 build (FpMode/FpPush/FpSync) on purpose: their
-- meaning changed, old values must not carry over.
-- The game camera is the default: under the head camera's lock Lincoln walks
-- relative to the game's hidden camera, and no camera call turned it reliably
-- (2026-10-20: walking stayed 27-60 degrees off the view).
local Cfg = { view = 2, body = true, bob = 2, fov = 1, fwd = 3, lift = 3, lead = true, sens = 3, vehicles = true, turn = true,
	carFov = 4, carFwd = 10, gunX = 4, gunZ = 3, aimX = 5, aimZ = 4, aimFov = 1, steps = true, takedowns = 2,
	on = true, headHide = true, footView = 1, viewKey = 2, backKey = 2, fx = 2, carCam = 1, coverFollow = true,
	hideHat = true, carLean = true, aimXs = {}, aimZs = {} }
local cfgLoaded = false

local function getSetting(key)
	if _ui_get_setting then
		return _ui_get_setting(key)
	end
	return nil
end

local function setSetting(key, value)
	if _ui_set_setting then
		_ui_set_setting(key, tostring(value))
	end
end

local function loadIndex(key, count, default)
	local v = tonumber(getSetting(key) or "")
	if v ~= nil and v >= 1 and v <= count and v == math.floor(v) then
		return v
	end
	return default
end

local function loadBool(key, default)
	local v = getSetting(key)
	if v == "1" then
		return true
	elseif v == "0" then
		return false
	end
	return default
end

local function ensureCfg()
	if cfgLoaded then
		return
	end
	cfgLoaded = true
	Cfg.view = loadIndex("FpView", #VIEWS, Cfg.view)
	Cfg.bob = loadIndex("FpBob", #BOBS, Cfg.bob)
	Cfg.fov = loadIndex("FpFov", #FOVS, Cfg.fov)
	Cfg.fwd = loadIndex("FpForward", #FWDS, Cfg.fwd)
	Cfg.lift = loadIndex("FpLift", #LIFTS, Cfg.lift)
	Cfg.sens = loadIndex("FpSens", #SENS, Cfg.sens)
	Cfg.lead = loadBool("FpLead", Cfg.lead)
	Cfg.body = loadBool("FpBody", Cfg.body)
	Cfg.vehicles = loadBool("FpVehicles", Cfg.vehicles)
	Cfg.turn = loadBool("FpTurn", Cfg.turn)
	Cfg.carFov = loadIndex("FpCarFov", 5, Cfg.carFov) -- entries of CAR.fovs
	-- FpCarFwd: an entry of CAR.fwds (14) since the list got places behind the
	-- eyes (2026-10-21); FpCarForward held one of the old list, five shorter.
	local old = tonumber(getSetting("FpCarForward") or "")
	if (getSetting("FpCarFwd") or "") ~= "" then
		Cfg.carFwd = loadIndex("FpCarFwd", 14, Cfg.carFwd)
	elseif old ~= nil and old >= 1 and old <= 9 then
		Cfg.carFwd = math.floor(old) + 5
	end
	Cfg.gunX = loadIndex("FpGunRight", 8, Cfg.gunX) -- entries of GUN.xs
	Cfg.gunZ = loadIndex("FpGunDown", 8, Cfg.gunZ) -- entries of GUN.zs
	Cfg.aimX = loadIndex("FpAimRight", 10, Cfg.aimX) -- entries of GUN.axs
	Cfg.aimZ = loadIndex("FpAimDown", 8, Cfg.aimZ) -- entries of GUN.azs
	Cfg.aimFov = loadIndex("FpAimFov", 9, Cfg.aimFov) -- entries of forcedFov.aims
	Cfg.steps = loadBool("FpSteps", Cfg.steps)
	Cfg.takedowns = loadIndex("FpTakedowns", 4, Cfg.takedowns) -- entries of TKD.names
	-- on by default; "0" once turned off in the menu (FpsLikeToggle)
	Cfg.on = loadBool("FpOn", Cfg.on)
	Cfg.headHide = loadBool("FpHeadHide", Cfg.headHide)
	Cfg.footView = loadIndex("FpFootView", #K.FOOT_VIEWS, Cfg.footView)
	Cfg.viewKey = loadIndex("FpViewKey", #K.VIEW_KEYS, Cfg.viewKey)
	Cfg.backKey = loadIndex("FpBackKey", #K.BACK_KEYS, Cfg.backKey)
	Cfg.fx = loadIndex("FpEffects", #K.FXS, Cfg.fx)
	Cfg.carCam = loadIndex("FpCarCam", #K.CAR_CAMS, Cfg.carCam)
	Cfg.coverFollow = loadBool("FpCoverFollow", Cfg.coverFollow)
	Cfg.hideHat = loadBool("FpHideHat", Cfg.hideHat)
	Cfg.carLean = loadBool("FpCarLean", Cfg.carLean)
	-- per kind of gun; one not set yet starts from the old single pair above
	for k, key in ipairs(K.AIM_KEYS) do
		Cfg.aimXs[k] = loadIndex("FpAimRight" .. key, 10, Cfg.aimX)
		Cfg.aimZs[k] = loadIndex("FpAimDown" .. key, 8, Cfg.aimZ)
	end
end

local function saveCfg()
	setSetting("FpView", Cfg.view)
	setSetting("FpBob", Cfg.bob)
	setSetting("FpFov", Cfg.fov)
	setSetting("FpForward", Cfg.fwd)
	setSetting("FpLift", Cfg.lift)
	setSetting("FpSens", Cfg.sens)
	setSetting("FpLead", Cfg.lead and 1 or 0)
	setSetting("FpBody", Cfg.body and 1 or 0)
	setSetting("FpVehicles", Cfg.vehicles and 1 or 0)
	setSetting("FpTurn", Cfg.turn and 1 or 0)
	setSetting("FpCarFov", Cfg.carFov)
	setSetting("FpCarFwd", Cfg.carFwd)
	setSetting("FpGunRight", Cfg.gunX)
	setSetting("FpGunDown", Cfg.gunZ)
	setSetting("FpAimRight", Cfg.aimX)
	setSetting("FpAimDown", Cfg.aimZ)
	setSetting("FpAimFov", Cfg.aimFov)
	setSetting("FpSteps", Cfg.steps and 1 or 0)
	setSetting("FpTakedowns", Cfg.takedowns)
	setSetting("FpOn", Cfg.on and 1 or 0)
	setSetting("FpHeadHide", Cfg.headHide and 1 or 0)
	setSetting("FpFootView", Cfg.footView)
	setSetting("FpViewKey", Cfg.viewKey)
	setSetting("FpBackKey", Cfg.backKey)
	setSetting("FpEffects", Cfg.fx)
	setSetting("FpCarCam", Cfg.carCam)
	setSetting("FpCoverFollow", Cfg.coverFollow and 1 or 0)
	setSetting("FpHideHat", Cfg.hideHat and 1 or 0)
	setSetting("FpCarLean", Cfg.carLean and 1 or 0)
	for k, key in ipairs(K.AIM_KEYS) do
		setSetting("FpAimRight" .. key, Cfg.aimXs[k] or Cfg.aimX)
		setSetting("FpAimDown" .. key, Cfg.aimZs[k] or Cfg.aimZ)
	end
end

local function log(msg)
	print("FP: " .. msg)
end

local function toast(msg)
	local text = _SH_translate and _SH_translate(msg) or msg
	if Notify ~= nil then
		pcall(Notify, text)
	end
	log(msg)
end

------------
-- Vectors --
------------

local function vec(x, y, z)
	return { x = x, y = y, z = z }
end

local ZERO = vec(0, 0, 0)
local UP = vec(0, 0, 1)

local function add(a, b)
	return vec(a.x + b.x, a.y + b.y, a.z + b.z)
end

local function sub(a, b)
	return vec(a.x - b.x, a.y - b.y, a.z - b.z)
end

local function scale(a, s)
	return vec(a.x * s, a.y * s, a.z * s)
end

local function dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

local function cross(a, b)
	return vec(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

local function len(a)
	return math.sqrt(dot(a, a))
end

local function norm(a)
	local l = len(a)
	if l < 1e-6 then
		return nil
	end
	return scale(a, 1 / l)
end

local function clampLen(a, maxLen)
	local l = len(a)
	if l > maxLen then
		return scale(a, maxLen / l)
	end
	return a
end

local function finite(v)
	for _, c in ipairs({ v.x, v.y, v.z }) do
		if type(c) ~= "number" or c ~= c or c > 1e7 or c < -1e7 then
			return false
		end
	end
	return true
end

local function fmt(v)
	return string.format("(%.2f,%.2f,%.2f)", v.x, v.y, v.z)
end

-- Reads a game vector into a plain table; nil when the call fails.
local function readVec(fn)
	local ok, v = pcall(function()
		local g = fn()
		return vec(g.x, g.y, g.z)
	end)
	if ok and v ~= nil and finite(v) then
		return v
	end
	return nil
end

local function atan2(y, x)
	if math.atan2 then
		return math.atan2(y, x)
	end
	return math.atan(y, x)
end

-- Camera axes: right, forward, up. Right = (fy, -fx) like the free camera strafe.
local function basis(dir)
	local f = norm(dir) or vec(1, 0, 0)
	local r = norm(cross(f, UP)) or vec(0, -1, 0)
	return { r = r, f = f, u = cross(r, f) }
end

-- Rig axes of the game camera: the horizontal right of the view, the view itself
-- and world up. They are not orthogonal; toRig solves e = a*r + b*f + c*up.
local function rig(dir)
	local B = basis(dir)
	local sp = math.max(-0.95, math.min(0.95, B.f.z))
	B.sp = sp
	B.cp = math.sqrt(1 - sp * sp)
	B.fh = norm(vec(B.f.x, B.f.y, 0)) or vec(-B.r.y, B.r.x, 0)
	return B
end

local function toRig(B, e)
	local b = dot(e, B.fh) / B.cp
	return vec(dot(e, B.r), b, e.z - b * B.sp)
end

K.PITCH_MAX = 1.25

local function clampPitch(v)
	return math.max(-K.PITCH_MAX, math.min(K.PITCH_MAX, v))
end

local function dirFromAngles(y, pt)
	return vec(math.cos(pt) * math.cos(y), math.cos(pt) * math.sin(y), math.sin(pt))
end

local function wrapAngle(a)
	while a > math.pi do
		a = a - 2 * math.pi
	end
	while a < -math.pi do
		a = a + 2 * math.pi
	end
	return a
end

local function angleOf(a, b)
	local na, nb = norm(a), norm(b)
	if na == nil or nb == nil then
		return 0
	end
	return math.acos(math.max(-1, math.min(1, dot(na, nb))))
end

-- 3x3 matrices are row tables.
local function mulMV(m, v)
	return vec(
		m[1][1] * v.x + m[1][2] * v.y + m[1][3] * v.z,
		m[2][1] * v.x + m[2][2] * v.y + m[2][3] * v.z,
		m[3][1] * v.x + m[3][2] * v.y + m[3][3] * v.z
	)
end

local function column(m, c)
	return vec(m[1][c], m[2][c], m[3][c])
end

local function det3(m)
	return m[1][1] * (m[2][2] * m[3][3] - m[2][3] * m[3][2])
		- m[1][2] * (m[2][1] * m[3][3] - m[2][3] * m[3][1])
		+ m[1][3] * (m[2][1] * m[3][2] - m[2][2] * m[3][1])
end

local function inv3(m)
	local d = det3(m)
	if math.abs(d) < 0.02 then
		return nil
	end
	local i = 1 / d
	return {
		{ (m[2][2] * m[3][3] - m[2][3] * m[3][2]) * i, (m[1][3] * m[3][2] - m[1][2] * m[3][3]) * i, (m[1][2] * m[2][3] - m[1][3] * m[2][2]) * i },
		{ (m[2][3] * m[3][1] - m[2][1] * m[3][3]) * i, (m[1][1] * m[3][3] - m[1][3] * m[3][1]) * i, (m[1][3] * m[2][1] - m[1][1] * m[2][3]) * i },
		{ (m[2][1] * m[3][2] - m[2][2] * m[3][1]) * i, (m[1][2] * m[3][1] - m[1][1] * m[3][2]) * i, (m[1][1] * m[2][2] - m[1][2] * m[2][1]) * i },
	}
end

local function matToString(m)
	local t = {}
	for r = 1, 3 do
		for c = 1, 3 do
			t[#t + 1] = string.format("%.3f", m[r][c])
		end
	end
	return table.concat(t, ",")
end

local function matFromString(s)
	local n = {}
	for x in string.gmatch(s or "", "[^,]+") do
		n[#n + 1] = tonumber(x)
	end
	if #n ~= 9 then
		return nil
	end
	for i = 1, 9 do
		if n[i] == nil then
			return nil
		end
	end
	return { { n[1], n[2], n[3] }, { n[4], n[5], n[6] }, { n[7], n[8], n[9] } }
end

----------
-- Game --
----------

local function getPlayer()
	local ok, p = pcall(function()
		return game.game:GetActivePlayer()
	end)
	if ok then
		return p
	end
	return nil
end

local function getCam()
	local ok, c = pcall(function()
		return game.cameramanager:GetPlayerCamera()
	end)
	if ok then
		return c
	end
	return nil
end

local function vehicleOf(p)
	local ok, owner = pcall(function()
		return p:GetOwner()
	end)
	if ok then
		return owner
	end
	return nil
end

local function controlsLocked(p)
	local ok, v = pcall(function()
		return p:AreControlsLocked()
	end)
	return ok and v == true
end

-- A yes/no method of the human wrapper (IsStealthMove, IsInCover ...); false when missing.
local function humanFlag(p, name)
	local ok, v = pcall(function()
		return p[name](p)
	end)
	return ok and v == true
end

local function showModel(p, visible)
	pcall(function()
		if p:IsModelVisible() ~= visible then
			p:ShowModel(visible)
		end
	end)
end

local offsetHash = nil

local function hashId()
	if offsetHash == nil then
		offsetHash = game.game:ToHashName("text")
	end
	return offsetHash
end

local function applyOffset(cam, o)
	return pcall(function()
		local h = hashId()
		cam:ScriptForcedOffsetStart(h, h, Math:newVector(o.x, o.y, o.z), 0.01, 0.01, 100000, true)
	end)
end

local function stopOffset(cam)
	pcall(function()
		cam:ScriptForcedOffsetStop()
	end)
end

-- The forced field of view: `now` the angle in effect (false: the game's own),
-- `resend` to send it again after a context change (a camera switch may drop it),
-- `age` calls since it was last sent, `want` the angle asked this frame (the head
-- camera gives it to its anchor: forcedFov.anchor), `probe` true while the check
-- tries the camera (FpsLikeProbe): the tick keeps its hands off meanwhile.
local forcedFov = { now = false, resend = false, age = 0, want = false, probe = false }
-- In the sights with the game camera config: the game's zoom (the config's own
-- per weapon), the angle on foot (true: no zoom at all), or one of its own.
forcedFov.aims = { "Game", "On foot", "50", "55", "60", "65", "70", "75", "80" }
forcedFov.aimv = { false, true, 50, 55, 60, 65, 70, 75, 80 }
-- The first-person camera config in tables.sds. One table: the game does not
-- load this file with its main chunk near 200 locals (see K above).
--   installed  true / false, nil until it was looked at on foot
--   detect     the running check; loud: report its answer either way
--   crouchZ    metres the camera is lowered to the crouched eyes
--   eyeZ       the eyes' slow average height above the feet (the head bob is the rest)
--   rootZ      the feet's height as the camera follows it over a step
--   gun, ads   0..1, how far the camera has moved to its place with a gun from the
--              hip and in the sights (noAim: logged that the ASI cannot tell aiming)
--   idle       frames the camera has needed no offset (crouchOn: offset sent)
--   coverX/Z   metres the camera follows the eyes sideways and up in cover
local gcfg = { installed = nil, detect = nil, loud = false, crouchZ = 0, crouchOn = false, eyeZ = nil, rootZ = nil,
	gun = 0, ads = 0, noAim = false, idle = 1e9, coverX = 0, coverZ = 0 }

-- Forces the angle v, or gives the game its own back (false). The game is
-- called when that changes, and once a second again: a camera switch of the
-- game can drop a forced angle without a word, and it would never come back.
local function setFov(cam, v, blend)
	forcedFov.want = v
	forcedFov.age = forcedFov.age + 1
	local again = (forcedFov.resend or forcedFov.age >= 60) and v
	forcedFov.resend = false
	if v == forcedFov.now and not again then
		return
	end
	forcedFov.age = 0
	if v then
		pcall(function()
			local h = hashId()
			cam:ScriptForcedFOVStart(h, h, blend or 0.3, blend or 0.3, v, 100000, true, true)
		end)
	else
		pcall(function()
			cam:ScriptForcedFOVStop()
		end)
	end
	forcedFov.now = v
end

local function stopFov(cam)
	setFov(cam, false)
end

---------
-- Eyes --
---------

-- Where the eyes are read, best first: the eye bones, else a head bone with the
-- lift that brings it to eye level (standing: bent over it lifts too much).
-- `low`: below it a bone is read wrongly. On foot that is under a crouch: the
-- eyes were 0.85-0.95 m above the feet crouched (2026-10-21 log), not 1.25 as
-- guessed, and with 0.9 here the crouch fell back to a head bone or to nothing,
-- and the camera hung over the head. Seated in a car the eyes are 0.95 m above
-- its origin. EYE_L/EYE_R was a fallback pair: on Lincoln it is no eye bone, it
-- gave the feet or the car's origin (-0.29 to +0.02 m above it, 0.77 m above
-- the feet, 2026-10-21 log), and once a frame without the eye bones had picked
-- it, the camera sat at the height of the suspension for the rest of the ride.
local EYES = { pairs = { { "LeftEye", "RightEye" } }, heads = { { "Head", 0.08 }, { "Neck1", 0.17 } },
	low = { foot = 0.5, car = 0.45 } }

local eyeSource = nil
local devS = nil

local function bone(p, name)
	return readVec(function()
		return p:GetBonePos(name)
	end)
end

-- A bone that was not found comes back as a default vector far from the body.
local function nearRoot(v, root)
	if v == nil then
		return false
	end
	local d = sub(v, root)
	return d.x * d.x + d.y * d.y < 4.0 and math.abs(d.z) < 2.6 and len(v) > 0.01
end

local function eyeFrom(p, root, src)
	if src.b ~= nil then
		local a, b = bone(p, src.a), bone(p, src.b)
		if nearRoot(a, root) and nearRoot(b, root) then
			return scale(add(a, b), 0.5)
		end
		return nil
	end
	local h = bone(p, src.a)
	if nearRoot(h, root) then
		return vec(h.x, h.y, h.z + src.lift)
	end
	return nil
end

-- The first source in EYES that gives eyes at least `low` above the root, and
-- those eyes.
local function findEye(p, root, low)
	for _, pair in ipairs(EYES.pairs) do
		local src = { a = pair[1], b = pair[2] }
		local e = eyeFrom(p, root, src)
		if e ~= nil and e.z - root.z >= low then
			return src, e
		end
	end
	for _, hb in ipairs(EYES.heads) do
		local src = { a = hb[1], lift = hb[2] }
		local e = eyeFrom(p, root, src)
		if e ~= nil and e.z - root.z >= low then
			return src, e
		end
	end
	return nil
end

-- Asked in order every frame, so a moment without the eye bones (getting in or
-- out of a car) does not leave the camera on a lesser source afterwards.
local function rawEye(p, root)
	local inCar = vehicleOf(p) ~= nil
	local src, e = findEye(p, root, inCar and EYES.low.car or EYES.low.foot)
	if src == nil then
		return nil
	end
	if eyeSource == nil or eyeSource.a ~= src.a then
		log(string.format("eyes from %s%s, %.2f m above %s", src.a, src.b and ("/" .. src.b) or "",
			e.z - root.z, inCar and "the vehicle origin" or "the feet"))
	end
	eyeSource = src
	return e
end

local function playerFacing(p)
	local d = readVec(function()
		return p:GetDir()
	end)
	if d == nil then
		return nil
	end
	return norm(vec(d.x, d.y, 0))
end

-- The eyes, with the head's offset from the body low-passed: up and down by the
-- head bob setting, sideways lightly. Camera height is added here. A frame
-- without believable eyes keeps the last offset from the body.
local function eyePoint(p, root)
	local e = rawEye(p, root)
	if e ~= nil then
		local d = sub(e, root)
		if devS == nil then
			devS = d
		else
			local kz = K.BOB_K[Cfg.bob]
			local kxy = math.max(kz, 0.5)
			devS = vec(devS.x + (d.x - devS.x) * kxy, devS.y + (d.y - devS.y) * kxy, devS.z + (d.z - devS.z) * kz)
		end
	elseif devS == nil then
		return nil
	end
	return vec(root.x + devS.x, root.y + devS.y, root.z + devS.z + K.LIFT_VAL[Cfg.lift])
end

-- Head camera target: in front of the eyes along the view, so the head stays
-- behind the camera whichever way it looks.
local function headTarget(eye, dir)
	local h = norm(vec(dir.x, dir.y, 0)) or vec(1, 0, 0)
	return add(eye, scale(h, K.FWD_VAL[Cfg.fwd]))
end

-- Game camera target: the eyes, but never in front of the vertical plane through
-- the root along the view: the orbit arm cannot get shorter than zero.
K.PIVOT_MARGIN = 0.03

local function reachable(target, root, B)
	local along = dot(sub(target, root), B.fh)
	if along > -K.PIVOT_MARGIN then
		return sub(target, scale(B.fh, along + K.PIVOT_MARGIN))
	end
	return target
end

------------------
-- Offset model --
------------------

-- calib[ctx] = { frame = "rig" | "world", M, Mi, delay, measured }
-- M maps an offset to the camera's displacement: in rig axes (right, view, up)
-- for "rig", in world axes for "world".
K.DEFAULT_M = {
	foot = { { 1.0, 0.0, 0.0 }, { 0.0, -0.47, 0.0 }, { 0.0, 0.0, 0.87 } },
	car = { { 1.0, 0.0, 0.0 }, { 0.0, -0.46, 0.0 }, { 0.0, 0.0, 1.0 } },
}
K.CTX_KEY = { foot = "FpCam2Foot", car = "FpCam2Car" }
-- Per-frame share of the miss added to the offset, by the measured delay in frames.
K.GAIN = { 0.85, 0.45, 0.3 }

local calib = {}
local measureWanted = {}

local function makeCalib(frame, M, delay, measured)
	local Mi = inv3(M)
	if Mi == nil then
		return nil
	end
	return { frame = frame, M = M, Mi = Mi, delay = math.max(1, math.floor(delay or 1)), measured = measured == true }
end

local function defaultCalib(ctx)
	return makeCalib("rig", K.DEFAULT_M[ctx], 1, false)
end

local function gainOf(c)
	return K.GAIN[math.min(c.delay, #K.GAIN)]
end

local function saveCalib(ctx, c)
	if c == nil then
		setSetting(K.CTX_KEY[ctx], "")
		return
	end
	setSetting(K.CTX_KEY[ctx], string.format("v2;%s;%d;%s", c.frame, c.delay, matToString(c.M)))
end

local function loadCalib(ctx)
	local s = getSetting(K.CTX_KEY[ctx])
	if s == nil or s == "" then
		return nil
	end
	local f = {}
	for x in string.gmatch(s, "[^;]+") do
		f[#f + 1] = x
	end
	if f[1] ~= "v2" or (f[2] ~= "rig" and f[2] ~= "world") then
		return nil
	end
	local M = matFromString(f[4])
	if M == nil then
		return nil
	end
	return makeCalib(f[2], M, tonumber(f[3]) or 1, true)
end

-----------------
-- Calibration --
-----------------

local cal = nil
K.AMP = 0.4
K.HOLD = 10

local function calibrationSteps()
	local steps = { { o = ZERO, n = 15 } }
	local axes = { vec(1, 0, 0), vec(0, 1, 0), vec(0, 0, 1) }
	for i, a in ipairs(axes) do
		steps[#steps + 1] = { o = scale(a, K.AMP), n = K.HOLD, key = "p1", axis = i }
		steps[#steps + 1] = { o = scale(a, -K.AMP), n = K.HOLD, key = "m", axis = i }
		steps[#steps + 1] = { o = scale(a, K.AMP), n = K.HOLD, key = "p2", axis = i, track = i == 1 }
	end
	-- back at zero, so the end view can be compared with the start
	steps[#steps + 1] = { o = ZERO, n = K.HOLD }
	return steps
end

local function startCalibration(ctx, tries)
	cal = { ctx = ctx, steps = calibrationSteps(), i = 1, f = 0, samples = {}, tries = tries or 1 }
end

-- How much of a column lies along one axis: 1 when it is that axis.
local function along(col, axis)
	local l = len(col)
	if l < 1e-6 then
		return 0
	end
	return math.abs(dot(col, axis)) / l
end

local function worldAxisScore(col)
	local l = len(col)
	if l < 1e-6 then
		return 0
	end
	return math.max(math.abs(col.x), math.abs(col.y), math.abs(col.z)) / l
end

-- Returns a calibration, or nil, the reason and whether it was only the player moving.
local function solveCalibration(endDir, endRoot)
	if dot(cal.d0, norm(endDir) or cal.d0) < 0.995 then
		return nil, "the view turned", true
	end
	if len(sub(endRoot, cal.root0)) > 0.3 then
		return nil, "the player moved", true
	end
	local Mw = { {}, {}, {} }
	for i = 1, 3 do
		local p1, m, p2 = cal.samples[i .. "p1"], cal.samples[i .. "m"], cal.samples[i .. "p2"]
		local d = scale(sub(scale(add(p1, p2), 0.5), m), 0.5 / K.AMP)
		Mw[1][i], Mw[2][i], Mw[3][i] = d.x, d.y, d.z
		local l = len(d)
		if l < 0.15 or l > 4 then
			return nil, string.format("offset axis %d moved the camera %.2f m per unit", i, l)
		end
	end
	local B = cal.B0
	local Mr = { {}, {}, {} }
	for c = 1, 3 do
		local col = toRig(B, column(Mw, c))
		Mr[1][c], Mr[2][c], Mr[3][c] = col.x, col.y, col.z
	end
	local delay = 1
	local tr = cal.trace
	if tr ~= nil and #tr > 0 then
		local total = len(sub(tr[#tr], cal.trBefore))
		for j = 1, #tr do
			if total > 1e-3 and len(sub(tr[j], cal.trBefore)) >= 0.5 * total then
				delay = j
				break
			end
		end
	end
	-- An orbit camera moves along the view's horizontal right for offset x; a
	-- camera with world-fixed offsets moves along a world axis that the view's
	-- right does not follow. Only a clear world answer picks world axes.
	local x = column(Mw, 1)
	local rigScore = along(x, B.r)
	local worldScore = worldAxisScore(x)
	local frame = (worldScore > 0.97 and rigScore < 0.85) and "world" or "rig"
	log(string.format("calibration %s: x along the view's right %.2f, along a world axis %.2f -> %s, delay %d",
		cal.ctx, rigScore, worldScore, frame, delay))
	log("  world matrix " .. matToString(Mw))
	log("  rig matrix   " .. matToString(Mr))
	local c = makeCalib(frame, frame == "world" and Mw or Mr, delay, true)
	if c == nil then
		return nil, "the offset matrix is singular"
	end
	return c
end

---------------------
-- Per-frame state --
---------------------

local tick = 0
local curCtx = nil
local method = nil -- "head", "native", "wait", "calibrating"
local waitFrames = 0
local stillFrames = 0
local retryTries = 1
local attempts = 0
local lastDir = nil
local hinted = {}
local warned = {}
local suspended = false
local lastRoot = nil
local lastRes = 0
local offset = ZERO
local ctxSettle = 0
local growFrames = 0
local farFrames = 0
local satFrames = 0
local missPrev = 0
local turning = false
local gainNow = nil
local lastErr = nil
local yStand = nil -- game camera: view-axis offset that held the camera at the target standing
local lastFwd = 0 -- game camera: metres the last step moved the camera forward along the view

K.MISS_DEADZONE = 0.004
K.ERR_CLAMP = 3.0
-- In offset units; one unit along the view axis is only ~0.26-0.47 m, and the
-- car camera sits ~5.5 m behind the driver, so the car needs ~12 units.
K.MAX_STEP = 3.0
K.MAX_OFFSET = 20.0
-- Standing still, Lincoln turns once the view is `start` radians off his
-- facing, by `ease` of what is left per frame but at most `rate`, until he is
-- within `stop`. After the view has rested `rest` frames, a turn smaller than
-- `start` but larger than `settle` is finished too.
-- Only while the camera is within `eyes` metres (sideways) of his eyes: the
-- game's cameras for picking a lock or tapping a junction box sit behind him
-- and turn with him, so turning him toward one spun him and the camera round
-- and round (2026-10-21). A turn that stays `start` or more off for over
-- `spinMax` frames (a real one closes that in under a second) is such a camera
-- too, closer in: `stuck` leaves him alone until he walks. `spin` counts those
-- frames.
local TURN = { start = 0.6, stop = 0.07, rate = 0.08, ease = 0.25, rest = 20, settle = 0.10, eyes = 0.45, spinMax = 120,
	spin = 0, stuck = false }
local lastViewYaw = nil
local viewRest = 0

local function resetTracking()
	devS = nil
	eyeSource = nil
	lastRoot = nil
	lastRes = 0
	offset = ZERO
	growFrames = 0
	farFrames = 0
	satFrames = 0
	missPrev = 0
	turning = false
	gainNow = nil
	lastErr = nil
	yStand = nil
	lastFwd = 0
	gcfg.crouchZ = 0
	gcfg.eyeZ = nil
	gcfg.rootZ = nil
	gcfg.gun = 0
	gcfg.ads = 0
	gcfg.idle = 1e9
	gcfg.coverX, gcfg.coverZ = 0, 0
	lastViewYaw = nil
	viewRest = 0
	TURN.spin = 0
	TURN.stuck = false
end

-- Head camera

local anchor = _FpAnchor
local locked = false
local yaw, pitch = 0, 0
local lookYaw, lookPitch, lookIdle = 0, 0, 0
-- Radians per unit of GetAimDiff at 1x, tuned in the 2026-08 locked camera.
K.ROT = 0.38
local lastSetDir = nil
local nativeVotes = 0
local followNative = {}
local viewDir = nil
local lastTarget = nil

local function playerFacingYaw(p)
	local d = playerFacing(p)
	if d == nil then
		return nil
	end
	return atan2(d.y, d.x)
end

local function vehicleYaw(veh)
	local d = readVec(function()
		return veh:GetDir()
	end)
	if d == nil then
		return yaw
	end
	return atan2(d.y, d.x)
end

local function seedLook(cd, veh)
	local d = norm(cd) or vec(1, 0, 0)
	yaw = atan2(d.y, d.x)
	pitch = clampPitch(math.asin(math.max(-1, math.min(1, d.z))))
	lookYaw, lookPitch, lookIdle = 0, 0, 0
	if veh ~= nil then
		lookYaw = wrapAngle(yaw - vehicleYaw(veh))
		lookPitch = pitch
	end
	lastSetDir = nil
	nativeVotes = 0
end

local function anchorReady()
	if anchor ~= nil then
		return true
	end
	local p = getPlayer()
	local pos = readVec(function()
		return p:GetPos()
	end) or ZERO
	local ok, ent = pcall(function()
		local e = game.game:CreateCleanEntity(Math:newVector(pos.x, pos.y, pos.z + 1.7), 0, false, false, true)
		local wrap = e:GetComponent("C_EntityWrapperComponent")
		if wrap ~= nil then
			pcall(function()
				wrap:SetGameEntityType(enums.EntityType.ENTITY_DUMMY)
			end)
		end
		pcall(function()
			e:AddComponent("C_CameraComponent")
		end)
		return e
	end)
	if not ok or ent == nil then
		log("could not create the camera anchor: " .. tostring(ent))
		return false
	end
	anchor = ent
	_FpAnchor = ent
	return true
end

local function lockedLeave(cam)
	if locked then
		pcall(function()
			cam:ScriptUnlock(1)
		end)
		locked = false
	end
end

local function readAim(p)
	local ok, a = pcall(function()
		local d = p:GetAimDiff(true)
		return vec(d.x, d.y, 0)
	end)
	if ok and a ~= nil and finite(a) then
		return a.x, a.y
	end
	return 0, 0
end

-- The anchor's state: where it was put last (`pos`). After a death or a load
-- the world can be built anew and the anchor gone with it: ScriptLock then
-- holds nothing and the game's own camera shows (the next car was third
-- person, 2026-10-21) while the trainer took itself for locked. So a death, or
-- a moment without a player, makes the anchor `stale` (a new one on resuming),
-- and an anchor that took an error, or reads back over `far` m from where it
-- was just put, is `broken` (a new one at once). Where the camera is cannot
-- tell: in a car GetDir under the lock can be the game's camera, and GetPos
-- may be too. At most `tries` new ones a ride (`made`), so a lock the game
-- refuses does not make entities without end.
local anchorHold = { pos = nil, made = 0, stale = false, broken = false, far = 3.0, tries = 2 }

-- Lets the anchor go; the next lock makes a new one (anchorReady). The old one
-- is left alone: a call on an entity the game has dropped could crash it.
function anchorHold.forget()
	anchor, _FpAnchor = nil, nil
	anchorHold.pos, anchorHold.stale, anchorHold.broken = nil, false, false
	forcedFov.anchorNow, forcedFov.anchorBase = nil, nil
end

-- A new anchor in place of a broken one: the context starts over and makes it
-- (enterContext). After `tries` in a ride the game's camera stays until the next.
function anchorHold.renew(cam)
	lockedLeave(cam)
	anchorHold.forget()
	anchorHold.made = anchorHold.made + 1
	if anchorHold.made > anchorHold.tries then
		method = nil
		log("head camera: a new anchor does not take either, the game's camera for this ride")
		return
	end
	log("head camera: the anchor does not answer (gone after a death or a load?), making a new one")
	curCtx = nil
end

-- Vehicle head camera. Once the driver's eyes have held still for half a second
-- the camera is fixed to that point of the car, so the steering and bump
-- animations of the driver no longer shake it. The view follows the car's own
-- pitch and part of its roll (from GetRot, a quaternion: v = x, y, z, s = w,
-- checked against GetDir once; without it only the heading, as before).
-- One table: the game does not load this file with its main chunk near 200 locals (see K).
-- `fwds`/`fwdv`: the menu's metres in front of the driver's eyes (0.05 asked
-- 2026-10-20; on foot 0.08), minus behind them (asked 2026-10-21; the head is
-- then around the camera, the near clip hides it).
-- `resettle`: the eyes coming to rest this far from the seat move the camera
-- there at once (sliding over from the passenger's side; a seat taken in the
-- middle of getting in, (0.02,0.10,0.87) against (-0.36,-0.05,1.01) later,
-- 2026-10-21 log).
-- `hoodY`, `hoodZ`: the camera on the hood (Cfg.carCam 2) sits on the car's
-- middle line this far ahead of the measured seat and lower than the eyes.
-- `leanFrom`, `leanMax`, `leanIn`, `leanOut`: the driver leaning forward
-- (car.track, Cfg.carLean): eyes over `leanFrom` m ahead of the seat take the
-- camera along, at most `leanMax` m, eased by `leanIn` a frame forward and
-- `leanOut` back.
local CAR = { fovs = { "Game", "70", "75", "80", "90" }, fov = { false, 70, 75, 80, 90 },
	fwds = { "-0.10", "-0.08", "-0.06", "-0.04", "-0.02", "0.00", "0.02", "0.03", "0.04", "0.05", "0.06", "0.08", "0.10", "0.12" },
	fwdv = { -0.10, -0.08, -0.06, -0.04, -0.02, 0.0, 0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.10, 0.12 },
	window = 30, spread = 0.06, drift = 0.35, resettle = 0.25, roll = 0.5, aimAsk = 1.3, hoodY = 1.3, hoodZ = -0.1,
	leanFrom = 0.04, leanMax = 0.35, leanIn = 0.35, leanOut = 0.12 }
-- `shootOff`: first person while shooting did not work this session (car.aimCheck).
-- `lean`: metres the camera follows the driver leaning forward, along the car.
local car = { veh = nil, seat = nil, samples = {}, drift = 0, sign = nil, qorder = nil, rollOk = nil, shootOff = false, aim = nil,
	lean = 0 }

-- Third person on foot with the game camera config (Cfg.footView 2, asked
-- 2026-10-22). The config's camera stands 2 cm behind its look point, and the
-- forced offset along the view lengthens that arm by 0.47 m a unit, as it did
-- for the game's own orbit camera (2026-10-20 log): so the camera goes back
-- behind Lincoln's right shoulder, while the mouse, walking and aiming stay the
-- game's. `y`, `x`, `z`: the offset in third person, `aimY`, `aimX` in the
-- sights (closer over the shoulder); `blend` how far it is there, eased by
-- `rate` a frame both ways. `check`: frames at full blend, not aiming, after
-- which the camera must be `minBack` m behind the eyes, else the game did not
-- take it (`broken`: first person for the session). The view key toggles the
-- view where Lincoln is (on foot, in a vehicle); `keyWas`, `backWas`: its key
-- was down last frame. `backAng`: looking back in a vehicle, eased by
-- `backRate` to `backTo` radians over the right shoulder while its key is held.
local VIEW = { y = 5.6, x = 0.45, z = -0.1, aimY = 1.6, aimX = 0.5, blend = 0, rate = 0.08, check = 40,
	minBack = 1.0, held = 0, broken = false, told = false, keyWas = false, backAng = 0, backTo = 2.9, backRate = 0.25,
	hatHidden = false, hatAt = 0, hatEvery = 120 }

-- A key held (Windows virtual-key code), as the ASI reads it: never while a
-- trainer menu is open; false without the ASI function (an old ASI).
function VIEW.keyDown(vk)
	if not vk or _input_key_down == nil then
		return false
	end
	local ok, v = pcall(_input_key_down, vk)
	return ok and v ~= nil and v ~= 0 and v ~= false
end

-- Lincoln's hat (Cfg.hideHat, asked 2026-10-22): its brim came into the view
-- in first person, on foot and at the wheel. Hidden while the view is first
-- person, shown again as it leaves it (third person, the game's camera, a
-- pause, off, a reload). Only a hat this hid is shown again; while hidden the
-- call is renewed every `hatEvery` ticks (a change of clothes can bring one
-- back). Glasses have no such call (the human's methods: ShowModel, ShowHat).
function VIEW.hat(p, hide)
	if p == nil then
		return
	end
	if hide then
		if not VIEW.hatHidden or tick - VIEW.hatAt >= VIEW.hatEvery then
			pcall(function()
				p:ShowHat(false)
			end)
			VIEW.hatHidden, VIEW.hatAt = true, tick
		end
	elseif VIEW.hatHidden then
		pcall(function()
			p:ShowHat(true)
		end)
		VIEW.hatHidden = false
	end
end

-- v rotated by the quaternion q (sign -1: by its conjugate).
function car.qrot(q, v, sign)
	local qx, qy, qz, s = q.x * sign, q.y * sign, q.z * sign, q.s
	local cx, cy, cz = qy * v.z - qz * v.y, qz * v.x - qx * v.z, qx * v.y - qy * v.x
	local dx, dy, dz = qy * cz - qz * cy, qz * cx - qx * cz, qx * cy - qy * cx
	return vec(v.x + 2 * (s * cx + dx), v.y + 2 * (s * cy + dy), v.z + 2 * (s * cz + dz))
end

-- The car's axes: forward f, right r, up u.
function car.basis(veh)
	local d = readVec(function()
		return veh:GetDir()
	end) or vec(math.cos(yaw), math.sin(yaw), 0)
	local q = nil
	pcall(function()
		local r = veh:GetRot()
		q = { x = r.v.x, y = r.v.y, z = r.v.z, s = r.s }
	end)
	if q ~= nil and type(q.s) == "number" and finite(vec(q.x, q.y, q.z)) and car.sign ~= false then
		local fd = norm(d) or vec(1, 0, 0)
		if car.sign == nil then
			-- Which way the engine turns local +y into the car's forward; decided
			-- only when the two answers differ clearly (they agree near a few headings).
			local a = dot(norm(car.qrot(q, vec(0, 1, 0), 1)) or ZERO, fd)
			local b = dot(norm(car.qrot(q, vec(0, 1, 0), -1)) or ZERO, fd)
			if a > 0.99 and b < 0.9 then
				car.sign = 1
			elseif b > 0.99 and a < 0.9 then
				car.sign = -1
			elseif a < 0.9 and b < 0.9 then
				car.sign = false
				log("vehicle: GetRot does not match GetDir, following the heading only")
			end
			if car.sign then
				log("vehicle: following the car's pitch and roll (quaternion sign " .. car.sign .. ")")
			end
		end
		if car.sign then
			local f = norm(car.qrot(q, vec(0, 1, 0), car.sign))
			local u = norm(car.qrot(q, vec(0, 0, 1), car.sign))
			local r = f and u and norm(cross(f, u))
			if r ~= nil then
				return { f = f, r = r, u = norm(cross(r, f)) or u }
			end
		end
	end
	local f = norm(vec(d.x, d.y, 0)) or vec(1, 0, 0)
	return { f = f, r = vec(f.y, -f.x, 0), u = UP }
end

-- The mean of the last CAR.window eye points (car axes) once they are all in,
-- hold still and lie inside the car's body (not still at the door); nil otherwise.
function car.still(w)
	if #w < CAR.window then
		return nil
	end
	local mean = ZERO
	for _, v in ipairs(w) do
		mean = add(mean, scale(v, 1 / #w))
	end
	for _, v in ipairs(w) do
		if len(sub(v, mean)) > CAR.spread then
			return nil
		end
	end
	if math.abs(mean.x) > 0.9 or math.abs(mean.y) > 2.5 or mean.z < 0.3 or mean.z > 2.0 then
		return nil
	end
	return mean
end

-- The point of the car the camera is fixed to (nil while the seat is measured:
-- the camera follows the eyes meanwhile, through the getting-in animation).
-- Head bob adds none of the driver's head motion at Off, part or all of it
-- above; the camera height goes along the car's up. A frame without believable
-- eyes keeps the camera on the seat.
function car.track(veh, B, root, eye)
	if car.veh ~= veh then
		car.veh, car.seat, car.samples, car.drift, car.lean = veh, nil, {}, 0, 0
	end
	local s
	if eye ~= nil then
		local d = sub(eye, root)
		local loc = vec(dot(d, B.r), dot(d, B.f), dot(d, B.u))
		local w = car.samples
		w[#w + 1] = loc
		if #w > CAR.window then
			table.remove(w, 1)
		end
		local rest = car.still(w)
		if car.seat == nil then
			if rest == nil then
				return nil
			end
			car.seat = rest
			log("vehicle: camera fixed to the seat at " .. fmt(rest) .. " (car axes)")
		elseif rest ~= nil and len(sub(rest, car.seat)) > CAR.resettle then
			car.seat, car.drift = rest, 0
			log("vehicle: the driver settled elsewhere, camera moved to " .. fmt(rest) .. " (car axes)")
		elseif len(sub(loc, car.seat)) > CAR.drift then
			car.drift = car.drift + 1
			if car.drift > 30 then
				car.seat, car.samples, car.drift = nil, {}, 0
				log("vehicle: the driver moved, measuring the seat again")
				return nil
			end
		else
			car.drift = 0
		end
		s = add(car.seat, scale(sub(loc, car.seat), K.BOB_SHARE[Cfg.bob]))
		-- Leaning forward (braking, a turn) the head came off the seat point toward
		-- the windscreen, in front of the camera: hair, the moustache, the head.
		-- Along the car the
		-- camera follows the eyes once they are over CAR.leanFrom ahead of the
		-- seat, eased, so the small shakes stay out (Cfg.carLean). A frame without
		-- the eyes holds it.
		local want = Cfg.carLean and math.max(0, math.min(CAR.leanMax, loc.y - car.seat.y - CAR.leanFrom)) or 0
		car.lean = car.lean + (want - car.lean) * (want > car.lean and CAR.leanIn or CAR.leanOut)
	elseif car.seat ~= nil then
		s = car.seat
	else
		return nil
	end
	if car.lean > 0.001 then
		s = vec(s.x, math.max(s.y, car.seat.y + car.lean), s.z)
	end
	if Cfg.carCam == 2 and car.seat ~= nil then
		-- on the hood: no head bob, the car's middle line ahead of the seat
		s = vec(0, car.seat.y + CAR.hoodY, car.seat.z + CAR.hoodZ)
	end
	return add(root, add(add(scale(B.r, s.x), scale(B.f, s.y)), scale(B.u, s.z + K.LIFT_VAL[Cfg.lift])))
end

-- Shooting from the car (ctx "carshoot"): the game fires along its own camera,
-- so the camera stays at the eyes and looks where that camera looks, read from
-- GetDir. Under the lock GetDir is the anchor's on foot (2026-10); whether the
-- game's camera for shooting from a car reports itself is not known. So once
-- the mouse has asked for CAR.aimAsk (GetAimDiff units, ~0.5 rad at 1x), the
-- view must have turned with it; if it has not, false: the game's camera takes
-- over while a gun is in hand, for the rest of the session, as before.
function car.aimCheck(ax, ay, cd)
	local a = car.aim
	a.frames = a.frames + 1
	-- the first frames are the lock settling
	if a.frames > 10 then
		a.mouse = a.mouse + math.abs(ax) + math.abs(ay)
		a.turn = a.turn + angleOf(cd, a.last)
	end
	a.last = cd
	if a.ok or a.mouse < CAR.aimAsk then
		return true
	end
	if a.turn > 0.05 then
		a.ok = true
		log("vehicle: shooting: the game's camera turns with the mouse, first person while shooting")
		return true
	end
	return false
end

function car.shootFail(cam, p)
	car.shootOff = true
	lockedLeave(cam)
	stopFov(cam)
	showModel(p, true)
	method = nil
	log("vehicle: shooting: the view does not turn with the game's aim under the lock, the game's camera aims from now on")
	toast("First-person: shooting from a car uses the game's camera (it does not aim from the eyes here)")
end

-- Camera up: between world up and the car's up, at right angles to the view.
function car.up(dir, B)
	if B == nil or car.rollOk == false or not car.sign then
		return nil
	end
	local up = add(scale(B.u, CAR.roll), scale(UP, 1 - CAR.roll))
	return norm(sub(up, scale(dir, dot(up, dir))))
end

-- Math:newQuat with x, y, z, w in whichever order the engine takes them.
function car.quat(x, y, z, w)
	if car.qorder == nil then
		car.qorder = false
		local tw = math.sqrt(1 - 0.14)
		pcall(function()
			local q = Math:newQuat(0.1, 0.2, 0.3, tw)
			if math.abs(q.s - tw) < 1e-3 and math.abs(q.v.x - 0.1) < 1e-3 then
				car.qorder = "xyzw"
			elseif math.abs(q.s - 0.1) < 1e-3 and math.abs(q.v.x - 0.2) < 1e-3 then
				car.qorder = "wxyz"
			end
		end)
		log("vehicle roll: Math:newQuat " .. tostring(car.qorder or "not usable"))
	end
	if car.qorder == "xyzw" then
		return Math:newQuat(x, y, z, w)
	elseif car.qorder == "wxyz" then
		return Math:newQuat(w, x, y, z)
	end
	return nil
end

-- Turns the entity to look along f with its top toward u (rolls it); false when
-- the engine does not take it, then the caller falls back to SetDir.
function car.setRot(ent, f, u)
	local r = norm(cross(f, u))
	if r == nil then
		return false
	end
	u = cross(r, f)
	-- columns: local x -> r, local y -> f, local z -> u
	local m00, m01, m02 = r.x, f.x, u.x
	local m10, m11, m12 = r.y, f.y, u.y
	local m20, m21, m22 = r.z, f.z, u.z
	local tr = m00 + m11 + m22
	local x, y, z, w
	if tr > 0 then
		local s = math.sqrt(tr + 1) * 2
		w, x, y, z = 0.25 * s, (m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s
	elseif m00 > m11 and m00 > m22 then
		local s = math.sqrt(1 + m00 - m11 - m22) * 2
		w, x, y, z = (m21 - m12) / s, 0.25 * s, (m01 + m10) / s, (m02 + m20) / s
	elseif m11 > m22 then
		local s = math.sqrt(1 + m11 - m00 - m22) * 2
		w, x, y, z = (m02 - m20) / s, (m01 + m10) / s, 0.25 * s, (m12 + m21) / s
	else
		local s = math.sqrt(1 + m22 - m00 - m11) * 2
		w, x, y, z = (m10 - m01) / s, (m02 + m20) / s, (m12 + m21) / s, 0.25 * s
	end
	local sg = car.sign == -1 and -1 or 1
	local q = car.quat(x * sg, y * sg, z * sg, w)
	if q == nil then
		car.rollOk = false
		return false
	end
	local ok = pcall(function()
		ent:SetRot(q)
	end)
	if car.rollOk == nil then
		local d = nil
		if ok then
			d = readVec(function()
				return ent:GetDir()
			end)
		end
		car.rollOk = d ~= nil and dot(norm(d) or ZERO, f) > 0.995
		log("vehicle roll: " .. (car.rollOk and "on" or "the camera entity does not take a rotation, pitch only"))
	end
	return ok and car.rollOk
end

-- The field of view where the player is: the car's own in a vehicle, the menu's
-- on foot. With the game camera config and a gun in hand it stays the menu's
-- from the hip, and in the sights is the one for the sights (by default the
-- game's, where the config's zoom is): giving it back as soon as a gun came out
-- dropped 90 to the config's 65, and the view seemed to shrink (2026-10-21).
-- Without the aim button (an old ASI) a gun in hand gives the game's angle.
local function fovWanted(p, ctx)
	if ctx == "car" or ctx == "carshoot" then
		return CAR.fov[Cfg.carFov]
	end
	if ctx ~= "foot" then
		return false
	end
	-- third person on foot keeps the game's angle (the menu's is for the eyes)
	if Cfg.footView == 2 and not VIEW.broken then
		return false
	end
	if gcfg.installed == true and humanFlag(p, "HaveFireWeaponInHand") then
		local ok, aim = pcall(function()
			return _input_aim_held()
		end)
		if not ok or aim == nil then
			return false
		end
		if aim ~= 0 and aim ~= false then
			local v = forcedFov.aimv[Cfg.aimFov]
			if v == true then
				return K.FOV_VAL[Cfg.fov]
			end
			return v
		end
	end
	return K.FOV_VAL[Cfg.fov]
end

-- The head camera draws through the anchor's own camera component, as the old
-- trainer's free camera did (it set that component's angle and locked again),
-- so ScriptForcedFOVStart on the player's camera does not reach it: the angle
-- in a car never changed (2026-10-21). The menu's angles, like the game's, are
-- taken as vertical degrees; the component wants horizontal radians (the free
-- camera's 60 -> pi/2 is about that at 16:9). false gives it back its own.
function forcedFov.anchor(v)
	if forcedFov.anchorNow == v or anchor == nil then
		return
	end
	local comp = nil
	pcall(function()
		comp = anchor:GetComponent("C_CameraComponent")
	end)
	if comp == nil then
		return
	end
	if forcedFov.anchorBase == nil then
		local ok, r = pcall(function()
			return comp:GetFOV()
		end)
		forcedFov.anchorBase = ok and type(r) == "number" and r or false
	end
	local rad = v and 2 * math.atan(math.tan(v * math.pi / 360) * 16 / 9) or forcedFov.anchorBase
	if rad then
		pcall(function()
			comp:SetFOV(rad)
		end)
	end
	forcedFov.anchorNow = v
	if not forcedFov.anchorTold then
		forcedFov.anchorTold = true
		local ok, r = pcall(function()
			return comp:GetFOV()
		end)
		log(string.format("head camera field of view: %s (sets %s rad on the anchor camera; it had %s, reads %s)", tostring(v),
			rad and string.format("%.3f", rad) or "-", tostring(forcedFov.anchorBase), ok and tostring(r) or "?"))
	end
end

local function lockAnchor(cam, pos, dir, up)
	forcedFov.anchor(forcedFov.want)
	local ok = pcall(function()
		anchor:SetPos(Math:newVector(pos.x, pos.y, pos.z))
		if not (up and car.setRot(anchor, dir, up)) then
			anchor:SetDir(Math:newVector(dir.x, dir.y, dir.z))
		end
		cam:ScriptLock(anchor, 0)
	end)
	locked = true
	anchorHold.pos = pos
	-- an anchor the game has dropped takes an error or answers from elsewhere
	-- (no GetPos on it tells nothing)
	local back = ok and readVec(function()
		return anchor:GetPos()
	end) or nil
	if not ok or (back ~= nil and len(sub(back, pos)) > anchorHold.far) then
		anchorHold.broken = true
	end
end

--------------
-- Steering --
--------------

-- Ways to turn the hidden game camera toward a direction. Each form is one
-- guess at the arguments; a wrong guess raises a Lua error and is skipped.
local STEER_FORMS = {
	resetdir = {
		function(cam) cam:ScriptUnlockResetDir() end,
		function(cam) cam:ScriptUnlockResetDir(0) end,
		function(cam) cam:ScriptUnlockResetDir(1) end,
	},
	pointat = {
		function(cam, v) cam:ScriptPointAtVec(v, 0.05, 1, 0.3) end,
		function(cam, v) cam:ScriptPointAtVec(v, 0, 1, 0) end,
		function(cam, v) cam:ScriptPointAtVec(v) end,
	},
	lookatdir = {
		function(cam, v, d) cam:ScriptLookAtDir(d, 0.05) end,
		function(cam, v, d) cam:ScriptLookAtDir(d) end,
	},
	behind = {
		function(cam) cam:ScriptResetCamBehindPlayer() end,
		function(cam) cam:ScriptResetCamBehindPlayer(0) end,
	},
}
K.STEER_ORDER = { "resetdir", "pointat", "lookatdir", "behind" }

local steerList = nil -- calls that turned the camera, best first; {} = none did
local steerIdx = 1
local steerBad = 0    -- smoothed angle between where Lincoln walks and where the view looks
local steerFrames = 0
local steerWarned = false

local function steerToString(list)
	if list == nil or #list == 0 then
		return "none"
	end
	local t = {}
	for _, s in ipairs(list) do
		t[#t + 1] = s.m .. ":" .. s.f
	end
	return table.concat(t, ",")
end

local function steerFromString(str)
	if str == nil or str == "" then
		return nil
	end
	if str == "none" then
		return {}
	end
	local list = {}
	for m, f in string.gmatch(str, "(%a+):(%d+)") do
		f = tonumber(f)
		if STEER_FORMS[m] ~= nil and STEER_FORMS[m][f] ~= nil then
			list[#list + 1] = { m = m, f = f }
		end
	end
	if #list == 0 then
		return nil
	end
	return list
end

local function currentSteer()
	if steerList == nil then
		return nil
	end
	return steerList[steerIdx]
end

local function steerCall(cam, s, dir, eye)
	local tgt = add(eye, scale(dir, 30))
	local v = Math:newVector(tgt.x, tgt.y, tgt.z)
	local d = Math:newVector(dir.x, dir.y, dir.z)
	return pcall(STEER_FORMS[s.m][s.f], cam, v, d)
end

local function faceTo(p, dir)
	local h = norm(vec(dir.x, dir.y, 0))
	if h ~= nil then
		pcall(function()
			p:SetDir(Math:newVector(h.x, h.y, 0))
		end)
	end
end

-- While walking, compares where the steps go with where the view looks; when
-- the current steering does not hold, moves on to the next call that worked
-- in the test, then tells the player.
local function watchSteer(p, vel, speed)
	if steerList == nil or viewDir == nil then
		return
	end
	local mv = readVec(function()
		return p:GetMoveDir(true)
	end)
	if mv == nil or math.sqrt(mv.x * mv.x + mv.y * mv.y) < 0.5 or speed < 0.03 then
		return
	end
	local h = norm(vec(viewDir.x, viewDir.y, 0))
	if h == nil then
		return
	end
	local want = atan2(h.y, h.x) + atan2(-mv.x, mv.y)
	local err = math.abs(wrapAngle(atan2(vel.y, vel.x) - want))
	steerBad = steerBad * 0.95 + err * 0.05
	steerFrames = steerFrames + 1
	if steerFrames < 60 or steerBad < 0.45 then
		return
	end
	local s = currentSteer()
	log(string.format("walking goes %.0f deg off the view with steering %s", math.deg(steerBad),
		s and (s.m .. ":" .. s.f) or "none"))
	steerFrames, steerBad = 0, 0
	if steerList[steerIdx + 1] ~= nil then
		table.remove(steerList, steerIdx)
		setSetting("FpSteer", steerToString(steerList))
		s = currentSteer()
		log("steering: now " .. s.m .. ":" .. s.f)
	elseif not steerWarned then
		steerWarned = true
		toast("First-person: walking does not follow the head camera here — use the game camera mode")
	end
end

-- The test: with Lincoln standing, each call is asked to turn the game camera
-- 57 degrees aside; it passes if the unlocked camera then points there.
local probe = nil
K.PROBE_TURN = 1.0
K.PROBE_SETTLE = 12

local function probeList()
	local list = {}
	for _, m in ipairs(K.STEER_ORDER) do
		for f = 1, #STEER_FORMS[m] do
			list[#list + 1] = { m = m, f = f }
		end
	end
	return list
end

-- The anchor set now is drawn this frame, after the body has moved on: "frame
-- lead" adds this frame's travel so the camera does not trail the head.
local function headTick(p, cam, veh, root, cd, vel)
	local ax, ay = readAim(p)
	local idle = math.abs(ax) < 1e-4 and math.abs(ay) < 1e-4
	-- shooting from the car: the view is the game's aim (car.aimCheck)
	local shooting = curCtx == "carshoot"
	if shooting and not car.aimCheck(ax, ay, cd) then
		car.shootFail(cam, p)
		return
	end
	if not followNative[curCtx] and not shooting then
		-- The mouse rests and the camera still points elsewhere than we set it:
		-- the game turns its own camera under the lock. Follow it from now on.
		if idle and lastSetDir ~= nil and angleOf(cd, lastSetDir) > 0.05 then
			nativeVotes = nativeVotes + 1
			if nativeVotes >= 10 then
				followNative[curCtx] = true
				log("head camera (" .. curCtx .. "): the game turns its own camera under the lock, following it")
			end
		else
			nativeVotes = 0
		end
	end
	local k = K.ROT * K.SENS_VAL[Cfg.sens]
	local B = nil -- the car's axes, when the view is set in them
	if followNative[curCtx] or shooting then
		local d = norm(cd) or vec(1, 0, 0)
		yaw = atan2(d.y, d.x)
		pitch = clampPitch(math.asin(math.max(-1, math.min(1, d.z))))
	elseif veh ~= nil then
		if not idle then
			lookYaw = wrapAngle(lookYaw - ax * k)
			lookPitch = clampPitch(lookPitch + ay * k)
			lookIdle = 0
		else
			lookIdle = lookIdle + 1
		end
		-- In a car the view drifts back to the road after ~1.2 s without the mouse.
		if lookIdle > 75 then
			lookYaw = lookYaw * 0.92
			lookPitch = lookPitch * 0.92 - 0.06 * 0.08
		end
		B = car.basis(veh)
	else
		yaw = wrapAngle(yaw - ax * k)
		pitch = clampPitch(pitch + ay * k)
	end
	local dir
	if B ~= nil then
		-- Looking back while its key is held (Cfg.backKey): over the right shoulder, eased.
		local back = VIEW.keyDown(K.BACK_VK[Cfg.backKey]) and -VIEW.backTo or 0
		VIEW.backAng = VIEW.backAng + (back - VIEW.backAng) * VIEW.backRate
		-- Mouse look in the car's own axes: the view pitches with the car on a hill.
		local yw = lookYaw + VIEW.backAng
		local h = add(scale(B.f, math.cos(yw)), scale(B.r, -math.sin(yw)))
		dir = norm(add(scale(h, math.cos(lookPitch)), scale(B.u, math.sin(lookPitch)))) or B.f
		yaw = atan2(dir.y, dir.x)
		pitch = clampPitch(math.asin(math.max(-1, math.min(1, dir.z))))
	else
		dir = dirFromAngles(yaw, pitch)
	end
	local eye = eyePoint(p, root)
	if B ~= nil then
		-- fixed to the seat once measured; the eyes until then (getting in)
		eye = car.track(veh, B, root, rawEye(p, root)) or eye
	end
	if eye == nil then
		eye = vec(root.x, root.y, root.z + (veh and 1.05 or 1.70))
	end
	local target = headTarget(eye, dir)
	if veh ~= nil then
		target = add(eye, scale(norm(vec(dir.x, dir.y, 0)) or ZERO, CAR.fwdv[Cfg.carFwd]))
	end
	-- Not in a vehicle: the game hands over the car's position of this very frame,
	-- so the lead pushed the camera a frame's travel ahead, onto the hood at
	-- speed (screenshots 2026-10-20).
	if Cfg.lead and veh == nil then
		target = add(target, vel)
	end
	-- Lincoln walks relative to the game's own camera: turn it to the view.
	local s = veh == nil and currentSteer() or nil
	if s ~= nil and s.m == "resetdir" and lastSetDir ~= nil then
		-- Unlocking hands the game camera the direction the lock had; relocked below.
		steerCall(cam, s, lastSetDir, eye)
	elseif s ~= nil and s.m == "behind" then
		faceTo(p, dir)
	end
	lockAnchor(cam, target, dir, B and car.up(dir, B))
	if s ~= nil and s.m ~= "resetdir" then
		steerCall(cam, s, dir, eye)
	end
	lastSetDir = dir
	viewDir = dir
	lastTarget = target
end

local function finishProbe(p, cam, cd)
	steerList = probe.found
	steerIdx = 1
	steerBad, steerFrames = 0, 0
	probe = nil
	setSetting("FpSteer", steerToString(steerList))
	pcall(function()
		cam:ScriptUnlock(1)
	end)
	locked = false
	log("steering test done: " .. steerToString(steerList))
	if #steerList == 0 then
		toast("First-person: walking does not follow the head camera here — use the game camera mode")
		steerWarned = true
	else
		toast("First-person: ready")
	end
	seedLook(cd, nil)
	method = "head"
end

local function probeTick(p, cam, root, cp, cd)
	if probe.f < 0 then
		-- the camera is settling after the previous try
		probe.f = probe.f + 1
		return
	end
	local c = probe.list[probe.i]
	if c == nil then
		finishProbe(p, cam, cd)
		return
	end
	local ax, ay = readAim(p)
	local idle = math.abs(ax) < 1e-4 and math.abs(ay) < 1e-4
	local eye = eyePoint(p, root) or vec(root.x, root.y, root.z + 1.7)
	if probe.f == 0 then
		if not idle then
			return
		end
		local h = norm(vec(cd.x, cd.y, 0)) or vec(1, 0, 0)
		probe.target = atan2(h.y, h.x) + K.PROBE_TURN * probe.sign
		probe.callAt = (c.m == "resetdir" and 4) or (c.m == "behind" and 2) or 0
		probe.ok = nil
		probe.disturbed = false
		if c.m == "resetdir" then
			lockAnchor(cam, eye, dirFromAngles(probe.target, 0))
		elseif c.m == "behind" then
			faceTo(p, dirFromAngles(probe.target, 0))
		end
	end
	if probe.f == probe.callAt then
		if not steerCall(cam, c, dirFromAngles(probe.target, 0), eye) then
			probe.ok = false
		end
	end
	if not idle then
		probe.disturbed = true
	end
	if probe.ok == nil and probe.f > probe.callAt + 2 then
		local stillLocked = anchorHold.pos ~= nil and len(sub(cp, anchorHold.pos)) < 0.05
		local h = norm(vec(cd.x, cd.y, 0))
		if not stillLocked and h ~= nil and math.abs(wrapAngle(atan2(h.y, h.x) - probe.target)) < 0.2 then
			probe.ok = true
		end
	end
	probe.f = probe.f + 1
	if probe.ok == nil and probe.f <= probe.callAt + 16 then
		return
	end
	-- One try is over: record it, put the camera and Lincoln back.
	local retry = probe.disturbed and probe.retries < 2
	if probe.ok == true and not probe.disturbed then
		probe.found[#probe.found + 1] = { m = c.m, f = c.f }
		log(string.format("steering test: %s form %d turns the game camera", c.m, c.f))
	elseif not retry then
		log(string.format("steering test: %s form %d %s", c.m, c.f, probe.ok == false and "is not accepted" or "does not turn it"))
	end
	pcall(function()
		cam:ScriptUnlock(1)
	end)
	pcall(function()
		cam:ScriptLookAtStop()
	end)
	locked = false
	anchorHold.pos = nil
	if probe.face ~= nil then
		faceTo(p, dirFromAngles(probe.face, 0))
	end
	if retry then
		probe.retries = probe.retries + 1
	else
		probe.retries = 0
		local passed = probe.ok == true and not probe.disturbed
		probe.i = probe.i + 1
		-- One working form per call is enough.
		while passed and probe.list[probe.i] ~= nil and probe.list[probe.i].m == c.m do
			probe.i = probe.i + 1
		end
	end
	probe.sign = -probe.sign
	probe.f = -K.PROBE_SETTLE
end

local function startProbe(p)
	probe = { list = probeList(), i = 1, f = -K.PROBE_SETTLE, found = {}, sign = 1, retries = 0, face = playerFacingYaw(p) }
	method = "probe"
	toast("First-person: stand still for a few seconds, setting up walking")
	log("steering test: which camera call makes Lincoln walk where the head camera looks")
end

-- Game camera

local function beginMeasure(ctx, why)
	method = "wait"
	waitFrames = ctx == "car" and 45 or 6
	stillFrames = 0
	retryTries = 1
	attempts = 0
	if not hinted[ctx] then
		hinted[ctx] = true
		toast(ctx == "car" and "First-person: stop the car and hold the mouse still for a second to set up the camera"
			or "First-person: stand still and hold the mouse still for a second to set up the camera")
	end
	log("measuring the " .. ctx .. " camera: " .. why)
end

-- A wrong model pushes the camera a little further away every frame; a camera
-- that ignores the offset never gets closer. Returns true when it gave up on
-- the current offset.
local function watchDivergence(cam, miss)
	if miss > 0.6 and miss > missPrev * 1.01 + 0.002 then
		growFrames = growFrames + 1
	elseif miss < 0.3 then
		growFrames = 0
	end
	if miss > 1.0 then
		farFrames = farFrames + 1
	elseif miss < 0.5 then
		farFrames = 0
	end
	-- The real camera never needs more than ~13 units (the car); pinned at the
	-- limit means the model pushes the wrong way.
	if miss > 1.0 and len(offset) > K.MAX_OFFSET * 0.98 then
		satFrames = satFrames + 1
	else
		satFrames = 0
	end
	missPrev = miss
	if growFrames < 10 and farFrames < 120 and satFrames < 10 then
		return false
	end
	log(string.format("the camera ran away from the eyes (%.2f m, %s model) — offset reset", miss,
		calib[curCtx] and calib[curCtx].frame or "?"))
	stopOffset(cam)
	resetTracking()
	local c = calib[curCtx]
	if c == nil or not c.measured then
		beginMeasure(curCtx, "the default model does not fit this camera")
	elseif not warned[curCtx] then
		warned[curCtx] = true
		toast("First-person: the game camera did not follow — try Recalibrate or the head camera")
	end
	return true
end

-- "Frame lead" on means the bones read here are the last frame's, like the
-- camera position: nothing to correct. Off means the body is already this
-- frame's while the camera read is the last one: aim at the eyes minus this
-- frame's travel, the rig follows the body by itself.
-- On the move the game camera trails the body like on a spring, so it cannot
-- reach the root plane; pushing further along the view only wound the offset
-- up (2026-10-20 log: y pinned at -19.99 while walking). The view-axis offset
-- learned while standing at the target, plus K.Y_SLACK, is the most it may take.
K.Y_SLACK = 1.5

local function nativeTick(p, cam, root, cp, cd, vel, speed)
	local c = calib[curCtx]
	if c == nil then
		return
	end
	local B = rig(cd)
	local eye = eyePoint(p, root)
	if eye == nil then
		return
	end
	if curCtx == "car" then
		-- in front of the driver's eyes, as the head camera in a car
		eye = add(eye, scale(B.fh, CAR.fwdv[Cfg.carFwd]))
	end
	local target = reachable(eye, root, B)
	if not Cfg.lead then
		target = sub(target, vel)
	end
	local err = sub(target, cp)
	local miss = len(err)
	lastRes = miss
	lastTarget = target
	if watchDivergence(cam, miss) then
		return
	end
	if miss > K.MISS_DEADZONE then
		err = clampLen(err, K.ERR_CLAMP)
		-- A miss that flips sign means the camera answers later than the model
		-- thinks: the gain backs off, and creeps back while the miss keeps its sign.
		local g = gainNow or gainOf(c)
		if lastErr ~= nil and miss > 0.02 then
			if dot(err, lastErr) < 0 then
				g = math.max(0.25, g * 0.8)
			else
				g = math.min(gainOf(c), g * 1.02)
			end
		end
		gainNow, lastErr = g, err
		-- Misses of a centimetre or two are mostly the game camera's own small
		-- moves (spring, collision probe): chasing them at full gain shook the
		-- view, so they get a quarter of it; from ~9 cm on the gain is full.
		local k = math.max(0, math.min(1, (miss - 0.01) / 0.08))
		local gEff = g * (0.25 + 0.75 * k)
		-- Forward along the view the orbit arm stops at zero: a step past the
		-- target is not seen (the camera just sits on the root plane) and only
		-- winds the offset up, which then takes seconds to unwind. So forward
		-- steps never go past the target, counting the last one as still on its
		-- way, as it is when the camera answers a frame later than the model.
		local a = dot(err, B.fh)
		if a > 0 then
			local room = math.max(0, a - math.max(0, lastFwd))
			if gEff * a > room then
				err = add(err, scale(B.fh, room / gEff - a))
			end
		end
		local want = c.frame == "world" and err or toRig(B, err)
		local raw = scale(mulMV(c.Mi, want), gEff)
		local step = clampLen(raw, K.MAX_STEP)
		local cut = len(raw) > 1e-9 and len(step) / len(raw) or 1
		lastFwd = cut * gEff * dot(err, B.fh)
		offset = clampLen(add(offset, step), K.MAX_OFFSET)
	else
		lastFwd = 0
	end
	if c.frame == "rig" and math.abs(c.M[2][2]) > 0.05 then
		local fwd = c.M[2][2] > 0 and 1 or -1 -- sign of y that moves the camera forward
		if speed < 0.01 and miss < 0.03 then
			yStand = yStand and (yStand + (offset.y - yStand) * 0.1) or offset.y
		end
		if yStand ~= nil and (offset.y - yStand) * fwd > K.Y_SLACK then
			offset = vec(offset.x, yStand + fwd * K.Y_SLACK, offset.z)
		end
	end
	-- Sent every frame: the forced offset lives only while it is renewed.
	applyOffset(cam, offset)
	viewDir = cd
end

-- Standing still, Lincoln turns toward the view like the first-person mode of
-- GTA: at once when the view swings far, and fully once the mouse rests. `cp`
-- is where the game camera is, `root` his feet (TURN.eyes); without them the
-- camera is not checked.
local function turnBody(p, cd, speed, root, cp)
	local h = norm(vec(cd.x, cd.y, 0))
	if h == nil then
		return
	end
	local viewYaw = atan2(h.y, h.x)
	if lastViewYaw ~= nil and math.abs(wrapAngle(viewYaw - lastViewYaw)) < 0.003 then
		viewRest = viewRest + 1
	else
		viewRest = 0
	end
	lastViewYaw = viewYaw
	if speed > 0.015 then
		TURN.stuck = false
	end
	local e = cp ~= nil and rawEye(p, root) or nil
	local away = e ~= nil and (cp.x - e.x) * (cp.x - e.x) + (cp.y - e.y) * (cp.y - e.y) > TURN.eyes * TURN.eyes
	-- With a gun out the game turns Lincoln itself when he aims, and in cover or
	-- a fight it holds his facing: turning him there fought the game and the
	-- weapon jerked (2026-10-20).
	if not Cfg.turn or speed > 0.015 or away or TURN.stuck or humanFlag(p, "HaveFireWeaponInHand")
		or humanFlag(p, "IsInCover") or humanFlag(p, "IsMeleeFighting") then
		turning = false
		TURN.spin = 0
		return
	end
	local face = playerFacingYaw(p)
	if face == nil then
		return
	end
	local d = wrapAngle(viewYaw - face)
	if not turning and math.abs(d) < TURN.start and not (viewRest >= TURN.rest and math.abs(d) > TURN.settle) then
		return
	end
	turning = math.abs(d) > TURN.stop
	if not turning then
		TURN.spin = 0
		return
	end
	-- Panning the mouse leaves him a little behind the view; the camera that
	-- turns with him keeps him as far off as it is.
	TURN.spin = math.abs(d) >= TURN.start and TURN.spin + 1 or 0
	if TURN.spin > TURN.spinMax then
		TURN.stuck = true
		turning = false
		log("body turn: the camera turns along with Lincoln (an action camera?), stopped until he walks")
		return
	end
	-- Eases in and out: a fixed step a frame showed as jerks of the arms and the
	-- weapon in first person.
	local y = face + math.max(-TURN.rate, math.min(TURN.rate, d * TURN.ease))
	pcall(function()
		p:SetDir(Math:newVector(math.cos(y), math.sin(y), 0))
	end)
end

-- Game camera config

-- The trainer cannot read tables.sds from inside the game, so it looks where
-- the game camera is with nothing applied to it: the game's third-person camera
-- never comes within ~0.6 m of the eyes (its look point sits over the right
-- shoulder), the first-person config keeps it a few centimetres from them.
-- Far away decides at once. Near must hold still for `frames`: a camera
-- blending back from an old lock at the eyes passes near the head too, moving.
-- `eye` is the config's camera height standing (fp_rules.json), `crouch` how
-- fast the camera follows the eyes down into a crouch and back up, `crouchMax`
-- the most it goes down. `bobAvg` is how fast the eyes' average height follows
-- them (the head bob is what is left), but a change of `posture` m or more
-- (crouching, getting up) is followed by `postureRate`; `bobMax` is the most the
-- bob moves the camera, `release` the frames without any offset before it is
-- let go (the bob crosses zero every step). `crouchTell`: frames a crouch holds
-- still before the camera's place against the eyes is logged. `lowAt`: the eyes
-- this far under standing height are a crouch. `hideAt`: the eyes this far
-- ahead of the camera along the view hide the body (gcfg.hideHead), under
-- `showAt` for `showHold` frames show it again; a camera `farAt` or more behind
-- them is one of the game's own.
-- Steps: the camera follows the feet up and down by `stepRate` a frame (~0.1 s),
-- at most `stepMax` behind; a jump of `stepReset` or more is a teleport.
-- `gunRate`: the move toward the weapon takes ~0.3 s. `behind`: on the move, a
-- camera this far behind the eyes along the view is logged (gcfg.trail), at
-- most once every `trailGap` frames; `trailLead`: the most a frame's step puts
-- the camera read forward. Cover: the camera follows the eyes sideways and in
-- height by `coverRate` of the gap a frame, at most `coverMax` m, while it is
-- within `coverNear` m of them (the config's cover camera, not a game one).
local GC = { frames = 45, timeout = 180, nearXY = 0.4, nearZ = 0.3, farXY = 0.9, still = 0.03, eye = 1.78, crouch = 0.6,
	crouchMax = 1.2, bobAvg = 0.12, posture = 0.06, postureRate = 0.6, bobMax = 0.06, release = 15, stepRate = 0.2,
	stepMax = 0.12, stepReset = 1.0, gunRate = 0.055, behind = 0.05, trailGap = 600, trailLead = 0.3, crouchTell = 30,
	lowAt = 0.25, hideAt = 0.12, showAt = 0.07, showHold = 15, farAt = 0.5, coverRate = 0.3, coverMax = 0.6, coverNear = 0.9 }

-- With a gun in hand the camera moves toward the weapon so it is in view:
-- metres right and down from the menu, one pair from the hip (xs, zs) and one
-- in the sights (axs, azs), eased over ~0.3 s from one to the other. In the
-- sights it comes on top of the config's own place per weapon (fp_rules.json),
-- hence the small default and the negative entries. It used to ease out in the
-- sights, which looked like the setting being lost (2026-10-21). Aiming is the
-- right mouse button as the ASI reads it; an ASI too old to tell gives no shift.
local GUN = { xs = { "0.00", "0.04", "0.06", "0.08", "0.10", "0.12", "0.15", "0.20" },
	xv = { 0.0, 0.04, 0.06, 0.08, 0.10, 0.12, 0.15, 0.20 },
	zs = { "0.00", "0.02", "0.03", "0.05", "0.08", "0.10", "0.12", "0.15" },
	zv = { 0.0, 0.02, 0.03, 0.05, 0.08, 0.10, 0.12, 0.15 },
	axs = { "-0.04", "-0.02", "0.00", "0.02", "0.04", "0.06", "0.08", "0.10", "0.12", "0.15" },
	axv = { -0.04, -0.02, 0.0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.15 },
	azs = { "-0.04", "-0.02", "0.00", "0.02", "0.03", "0.05", "0.08", "0.10" },
	azv = { -0.04, -0.02, 0.0, 0.02, 0.03, 0.05, 0.08, 0.10 } }

-- true / false while the game's aim button is held or not; nil when the ASI cannot tell.
function GUN.aiming()
	if _input_aim_held == nil then
		return nil
	end
	local ok, v = pcall(_input_aim_held)
	if not ok or v == nil then
		return nil
	end
	return v ~= 0 and v ~= false
end

-- The kind of gun in hand for the sights' place (K.AIM_KINDS): by the class at
-- the start of its name; an unknown one is "Other guns".
function GUN.kindOf(p)
	local name = nil
	pcall(function()
		name = p:InventoryGetSelected()
	end)
	local class = type(name) == "string" and name:match("^(%a+)_") or nil
	return class and K.AIM_KIND_OF[class] or #K.AIM_KINDS
end

-- Camera effects in first person with the config (Cfg.fx: off, light, strong;
-- asked 2026-10-22), by the forced offset like the rest. The game's own shake
-- from the recoil animation stays off in the config: made for an orbit camera,
-- it jerked the view at the eyes (fp_rules.json).
--   recoil  a kick on each shot: the camera back `back` m and up `up` m a unit,
--           settling by `decay` a frame (~0.15 s), `kick` units by the class in
--           the weapon's name (p_mast_sa: "p"), `kickOther` for the rest. A shot
--           is the ammo in the gun going down (as the old trainer's auto reload
--           reads it); with unlimited ammo it does not, so a press of the left
--           mouse button with a gun in hand is one too, and a drop of the ammo
--           within `dedupe` frames of a press is that same shot
--   sway    in the sights, `sway` m of slow drift
--   landing two frames or more of a fall of `fallFrom` m a frame or faster
--           (`fallFrames`; one frame is a step down) end in a dip of the camera,
--           at most `dipMax` m, rising back by `rise` a frame. The fall is
--           counted whatever the setting: while it lasts the steps' lag melts
--           (configTick), else it held the camera up and swallowed the landing
-- `mul`: the strength by the setting. `k`, `dip`: the kick and the dip now.
local FX = { mul = { 0, 1, 2 }, kick = { p = 0.6, rev = 1.2, sg = 1.6, smg = 0.5, rif = 1.3, ar = 0.8, sn = 1.4, rpg = 2.0 },
	kickOther = 0.8, back = 0.03, up = 0.012, decay = 0.7, dedupe = 2, sway = 0.004, fallFrom = 0.08, dipMax = 0.06,
	rise = 0.85, k = 0, dip = 0, fall = 0, fallFrames = 0, ammo = nil, fire = false, kickAt = nil }

function FX.kickOf(p)
	local name = nil
	pcall(function()
		name = p:InventoryGetSelected()
	end)
	local class = type(name) == "string" and name:match("^(%a+)_") or nil
	return class and FX.kick[class] or FX.kickOther
end

-- This frame's offset of the effects: right, back (offset units), up.
function FX.tick(p, gun, aiming, vel)
	local landed = false
	if vel.z < -FX.fallFrom then
		FX.fall = math.max(FX.fall, -vel.z)
		FX.fallFrames = FX.fallFrames + 1
	elseif FX.fallFrames > 0 and vel.z > -0.02 then
		landed = FX.fallFrames >= 2
		FX.fallFrames = 0
	end
	local m = FX.mul[Cfg.fx] or 0
	if landed and m > 0 then
		FX.dip = math.min(FX.dipMax * m, FX.fall * 0.5 * m)
	end
	if FX.fallFrames == 0 then
		FX.fall = 0
	end
	if m == 0 then
		FX.k, FX.dip, FX.ammo = 0, 0, nil
		return 0, 0, 0
	end
	if gun then
		local ammo = nil
		pcall(function()
			ammo = tonumber(p:DbgTesting_HelperFire_GetAmmoCountInEquipedWeapon())
		end)
		local shots = (ammo ~= nil and FX.ammo ~= nil and ammo < FX.ammo and FX.ammo - ammo <= 5) and FX.ammo - ammo or 0
		FX.ammo = ammo
		local fire = VIEW.keyDown(0x01)
		local pressed = fire and not FX.fire and not humanFlag(p, "IsReloading") and (ammo == nil or ammo > 0)
		FX.fire = fire
		if pressed then
			FX.k, FX.kickAt = FX.k + FX.kickOf(p), tick
		elseif shots > 0 and (FX.kickAt == nil or tick - FX.kickAt > FX.dedupe) then
			FX.k, FX.kickAt = FX.k + FX.kickOf(p) * shots, tick
		end
	else
		FX.ammo, FX.fire = nil, false
	end
	FX.k = math.min(3, FX.k) * FX.decay
	FX.dip = FX.dip * FX.rise
	local x, z = 0, FX.k * FX.up * m - FX.dip
	if aiming == true then
		x = FX.sway * m * math.sin(tick * 0.05)
		z = z + FX.sway * m * 0.6 * math.sin(tick * 0.083)
	end
	return x, FX.k * FX.back * m / 0.47, z
end

-- Returns true once it has decided.
local function detectTick(p, root, cp)
	local det = gcfg.detect
	-- Cover and melee keep the game's third-person cameras even with the config.
	if humanFlag(p, "IsInCover") or humanFlag(p, "IsMeleeFighting") then
		det.near = 0
		return false
	end
	local eye = rawEye(p, root) or vec(root.x, root.y, root.z + GC.eye)
	local d = sub(cp, eye)
	local xy = math.sqrt(d.x * d.x + d.y * d.y)
	local rel = sub(cp, root)
	local still = det.rel ~= nil and len(sub(rel, det.rel)) < GC.still
	det.rel = rel
	det.frames = det.frames + 1
	if xy < GC.nearXY and math.abs(d.z) < GC.nearZ and still then
		det.near = det.near + 1
	else
		det.near = 0
	end
	if det.near >= GC.frames then
		gcfg.installed = true
	elseif xy > GC.farXY or det.frames >= GC.timeout then
		gcfg.installed = false
	else
		return false
	end
	log(string.format("game camera config (tables.sds): %s, camera %s from the eyes, after %d frames",
		gcfg.installed and "first person installed" or "not installed", fmt(d), det.frames))
	-- Turned on by itself (autoStart): one note once this is known, that it is on
	-- and how to turn it off, or the way to the patch (FpsLikeOnTick turns it off).
	if gcfg.installed then
		toast(gcfg.auto and "First-person view is on (F4 - Camera turns it off)"
			or "First-person: the game's own first-person camera is installed (tables.sds)")
	elseif gcfg.auto and Cfg.footView == 2 then
		-- third person on foot was asked: the patch is not needed for vehicles
		toast("First-person view is on in vehicles; on foot the game's camera (F4 - Camera)")
	elseif det.loud or gcfg.auto then
		toast("First-person: the camera patch is not installed — IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat with the game closed")
	end
	gcfg.detect = nil
	gcfg.loud = false
	return true
end

-- On the move the config keeps the camera ahead of the eyes: 0.38 m ahead of
-- the body walking (0.48 sprinting) against the eyes' ~0.12 plus the lean,
-- while its spring trails by about speed x 0.045 s. Starting off, it took the
-- camera 0.5 s to get from the standing place (0.28) to the walking one while
-- the trail grew and the head leaned forward: for a moment the camera was
-- behind the eyes and the eyes and mouth showed (2026-10-21; transitions 10
-- and 11 in fp_rules.json now take 0.2 and 0.3 s). The trainer cannot push the
-- config's camera forward (the offset along the view only shortens its 2 cm
-- arm), so it writes down a stretch with the camera over GC.behind behind the
-- eyes once it ends: the worst gap, its frames and the top speed. `speed` 0
-- (cover, a fight: the eyes are ahead of those cameras anyway) ends a stretch.
-- The camera read is a frame older than the bones (the frame lead of the game
-- camera mode is there for it), so it is put forward by the body's step `vel`
-- (at most GC.trailLead): else every run read as 7-10 cm behind.
function gcfg.trail(e, cp, cd, vel, speed)
	local f = norm(cd)
	local ahead = 0
	if e ~= nil and f ~= nil then
		ahead = dot(sub(cp, e), f) + math.max(0, math.min(GC.trailLead, dot(vel, f)))
	end
	if ahead < -GC.behind and speed > 0.005 then
		gcfg.trailWorst = math.min(gcfg.trailWorst or 0, ahead)
		gcfg.trailFrames = (gcfg.trailFrames or 0) + 1
		gcfg.trailSpeed = math.max(gcfg.trailSpeed or 0, speed)
		return
	end
	if gcfg.trailFrames == nil then
		return
	end
	if gcfg.trailLog == nil or tick - gcfg.trailLog >= GC.trailGap then
		gcfg.trailLog = tick
		log(string.format("on the move the camera fell %.2f m behind the eyes for %d frames (up to %.3f m/frame)",
			-gcfg.trailWorst, gcfg.trailFrames, gcfg.trailSpeed))
	end
	gcfg.trailWorst, gcfg.trailFrames, gcfg.trailSpeed = nil, nil, nil
end

-- The head ahead of the camera. The config's camera trails the body on the
-- move (its spring: speed x 0.045 s) and nothing moves it forward, while the
-- head leans ahead: starting off sharply, crouching and getting up it fell up
-- to 0.25 m behind the eyes (2026-10-22 log), past the 0.2 m near clip, and
-- the eyes and mouth showed from inside. ShowModel hides only the whole body,
-- so the body is hidden while the eyes are over GC.hideAt ahead of the camera
-- along the view (the camera read a frame late, put forward by the body's step
-- as in gcfg.trail) and shown once they have stayed under GC.showAt for
-- GC.showHold frames. A camera GC.farAt or more behind them is one of the
-- game's own (picking a lock, a ladder) and is left alone, like cover, a fight
-- and the sights (`off`: the gun must show). This worked crouched only, from
-- 8 cm: late going down, early getting up, and it flickered (2026-10-22 log).
function gcfg.hideHead(p, e, cp, cd, vel, low, off)
	local was = gcfg.headHidden == true
	local hide, ahead = false, nil
	local f = norm(cd)
	if Cfg.body and Cfg.headHide and not off and f ~= nil then
		if e == nil then
			-- a frame without the eyes changes nothing
			hide = was
		else
			ahead = dot(sub(e, cp), f) - math.max(0, math.min(GC.trailLead, dot(vel, f)))
			if ahead >= GC.farAt then
				hide = false
			elseif ahead > GC.hideAt then
				gcfg.clear = 0
				hide = true
			elseif was then
				gcfg.clear = ahead < GC.showAt and (gcfg.clear or 0) + 1 or 0
				hide = gcfg.clear < GC.showHold
			end
		end
	end
	if hide and not was then
		gcfg.hideFrom, gcfg.hideWorst, gcfg.hideLow = tick, ahead or 0, low
	elseif hide then
		gcfg.hideWorst = math.max(gcfg.hideWorst or 0, ahead or 0)
		gcfg.hideLow = gcfg.hideLow or low
	end
	if hide == was then
		return
	end
	gcfg.headHidden = hide
	showModel(p, Cfg.body and not hide)
	if not hide then
		log(string.format("the head was up to %.2f m ahead of the camera for %d frames%s: the body was hidden meanwhile",
			gcfg.hideWorst or 0, tick - (gcfg.hideFrom or tick), gcfg.hideLow and " (crouching)" or ""))
	end
end

-- First-person takedowns (asked 2026-10-21). The config leaves takedowns to the
-- game's cameras (a melee camera 2-3 m behind, a kill camera for some). Where
-- Lincoln hardly changes his stance and the victim stands right before him,
-- the trainer keeps the camera at his eyes instead, turning to the victim's
-- neck. Nothing tells a script that a takedown runs, or which: the controls
-- lock for one (2.6-4 s in the 2026-10-21 log), but for a scene too. So it is
-- one when the lock comes within `window` frames of Q (read by the ASI) with a
-- living man in the middle of the screen a moment before (`candAge`, within
-- `view` m) and now within `range` m. Its kind comes from what was going on
-- (TKD.kindOf): in cover within `recent` frames (from cover, over cover), or
-- sprinting (on the run), or fighting within `fight` frames with the victim not
-- stunned (the brutal ones), or a victim sitting on the floor (eyes under
-- `floor` m above his feet) keep the game's camera. Eyes under `seat` m are a
-- seated man, `stunHp` health or less a stunned one, the rest a takedown from
-- behind, on the phone or at a mounted gun (and a civilian's own one). `allow`:
-- the lowest menu level (Cfg.takedowns, `names`) that takes each kind; the
-- fourth (2026-10-22, experimental) adds from cover, on the run and on the
-- floor, where Lincoln moves more: only the brutal ones keep the game's camera. The
-- camera follows the eyes by `follow` a frame, turns to the neck by `aim`
-- (not nearer than `near` m), sits `fwd` m ahead along the view. Over when the
-- controls are back (after `minFrames`), at `maxFrames` (an interrogation, a
-- scene) or with the eyes lost for `lostMax` frames. `on`: the running one.
local TKD = { names = { "Off", "Quiet ones", "Quiet and stunned", "All but the brutal (experimental)" },
	allow = { behind = 2, seated = 2, stunned = 3, ["from cover"] = 4, ["on the run"] = 4, ["sitting on the floor"] = 4 },
	window = 45, candAge = 45, view = 3.0, range = 1.8, recent = 30, fight = 60, floor = 0.95, seat = 1.45,
	stunHp = 1.05, follow = 0.5, aim = 0.12, near = 0.25, fwd = 0.07, minFrames = 20, maxFrames = 300, lostMax = 10,
	on = nil }

-- Every frame of the config on foot: what a takedown starting now is made of.
-- `away`: the game's camera from the eyes; gone off them just after Q next to
-- a man, without the controls locking, is a takedown this cannot catch: logged
-- (at most once in `trailGap` frames, not in a fight).
function TKD.watch(p, root, cover, melee, cd, away)
	TKD.seenAt = tick
	TKD.lastDir = cd
	if cover then
		TKD.coverAt = tick
	end
	if melee then
		TKD.fightAt = tick
	end
	if humanFlag(p, "IsSprinting") then
		TKD.sprintAt = tick
	end
	if TKD.endDir ~= nil then
		log(string.format("takedown in first person: the game's camera came back %.0f degrees off the view",
			math.deg(angleOf(cd, TKD.endDir))))
		TKD.endDir = nil
	end
	if Cfg.takedowns <= 1 then
		return
	end
	local ok, v = pcall(function()
		return game.physics:GetActorInScreenCenter()
	end)
	local vr = ok and v ~= nil and readVec(function()
		return v:GetPos()
	end) or nil
	if vr == nil then
		return
	end
	local d = len(sub(vr, root))
	-- (not Lincoln himself, nor anybody dead)
	if d > 0.3 and d <= TKD.view and not humanFlag(v, "IsDeath") then
		TKD.cand, TKD.candAt = v, tick
	end
	if away > 0.6 and not melee and not cover and d > 0.3 and d <= TKD.range and _input_melee_age ~= nil
		and (TKD.noLockLog == nil or tick - TKD.noLockLog >= GC.trailGap) then
		local okAge, age = pcall(_input_melee_age)
		age = okAge and tonumber(age) or nil
		if age ~= nil and age <= TKD.window then
			TKD.noLockLog = tick
			log(string.format("takedown? the game's camera left the eyes %d frames after Q next to a man %.2f m away, the controls did not lock: the game's camera", age, d))
		end
	end
end

-- With the config the game camera does everything itself, at standing eye
-- height. The trainer only moves it with a forced offset (1 unit = 1 m, x to
-- the right of the view, z up; the config has no orbit): down to the eyes when
-- crouched (stealth, ~0.9 m lower), by the camera height setting, with the
-- eyes' quick up and down for the head bob setting, smoothly up and down steps,
-- and toward the weapon with a gun in hand. The bob is left out with a gun in
-- hand (the aim stays steady), in cover and in a fight.
local function configTick(p, cam, root, cd, speed, cp, vel)
	local cover = humanFlag(p, "IsInCover")
	local gun = humanFlag(p, "HaveFireWeaponInHand")
	local melee = humanFlag(p, "IsMeleeFighting")
	local e = rawEye(p, root)
	local bob = 0
	if e ~= nil then
		local dz = e.z - root.z
		-- The eyes' average height above the feet; the head bob is what is left.
		-- Crouching or getting up is followed at once: averaged slowly, the camera
		-- stayed above the head while he went down.
		local d = gcfg.eyeZ and dz - gcfg.eyeZ or 0
		gcfg.eyeZ = gcfg.eyeZ and gcfg.eyeZ + d * (math.abs(d) > GC.posture and GC.postureRate or GC.bobAvg) or dz
		if not cover and not gun and not melee then
			bob = K.BOB_SHARE[Cfg.bob] * math.max(-GC.bobMax, math.min(GC.bobMax, dz - gcfg.eyeZ))
		end
	end
	-- A crouch is told by the eyes, GC.lowAt under standing height, or sooner by
	-- the game's stealth or stalk flag where it gives one (not in cover, whose
	-- camera is the game's, nor in a fight). IsStealthMove alone never answered
	-- for Lincoln's crouch: the camera stayed at standing height over his head,
	-- and no crouch was ever logged (screenshot and log, 2026-10-21).
	local low = not cover and not melee and gcfg.eyeZ ~= nil
		and (gcfg.eyeZ < GC.eye - GC.lowAt or humanFlag(p, "IsStealthMove") or humanFlag(p, "IsStalkMove"))
	-- Crouched the camera goes down to the eyes; getting up it comes back up
	-- with them, never above them, until they are nearly at standing height. A
	-- frame without believable eyes holds it where it is. It used to take a
	-- fixed 0.5 m, or a head bone lifted as if standing, whenever the crouched
	-- eyes were not believed (EYES.low): it hung over the head.
	local want = 0
	if gcfg.eyeZ ~= nil and (low or (gcfg.crouchZ < -0.01 and gcfg.eyeZ < GC.eye - GC.posture)) then
		want = math.max(-GC.crouchMax, math.min(0, gcfg.eyeZ - GC.eye))
		if not low then
			want = math.max(want, gcfg.crouchZ)
		end
	end
	gcfg.crouchZ = gcfg.crouchZ + (want - gcfg.crouchZ) * GC.crouch
	-- Once a crouch has settled, where the camera is against the eyes, for the
	-- log: the config cannot move it forward, so this tells if the head is ahead.
	if low and e ~= nil and speed < 0.005 and math.abs(want - gcfg.crouchZ) < 0.01 then
		gcfg.crouchStill = (gcfg.crouchStill or 0) + 1
		if gcfg.crouchStill == GC.crouchTell and (gcfg.crouchLog == nil or tick - gcfg.crouchLog >= GC.trailGap) then
			gcfg.crouchLog = tick
			local h = norm(vec(cd.x, cd.y, 0)) or vec(1, 0, 0)
			local c = sub(cp, e)
			log(string.format("crouched: eyes %.2f m above the feet, the camera %+.2f m from their height and %+.2f m ahead of them",
				e.z - root.z, c.z, c.x * h.x + c.y * h.y))
		end
	elseif not low then
		gcfg.crouchStill = 0
	end
	-- The camera rides on the feet, which go up a stair at a time: it follows
	-- them over ~0.1 s instead, never more than GC.stepMax behind.
	local stair = 0
	if Cfg.steps and not cover and gcfg.rootZ ~= nil and math.abs(root.z - gcfg.rootZ) < GC.stepReset then
		stair = math.max(-GC.stepMax, math.min(GC.stepMax, (gcfg.rootZ - root.z) * (1 - GC.stepRate)))
		-- a fall (FX.fallFrames, last frame's): the lag melts instead of growing,
		-- so the camera comes down with him and the landing is not swallowed
		if FX.fallFrames >= 2 then
			stair = math.min(stair, (gcfg.stairWas or 0) * 0.6)
		end
	end
	gcfg.stairWas = stair
	gcfg.rootZ = root.z + stair
	local aiming = GUN.aiming()
	if gun and aiming == nil and not gcfg.noAim then
		gcfg.noAim = true
		log("camera with a gun: this ASI cannot tell aiming (rebuild it: BUILD_STREET_FIGHT_ASI.bat), no move toward the weapon")
	end
	-- Third person on foot (VIEW), eased in and out; not in a fight, whose camera
	-- is the game's third-person one already. `tp` how far, `fp` the rest: what
	-- is for the eyes (head bob, the gun, the effects) fades with it.
	local third = Cfg.footView == 2 and not VIEW.broken and not melee
	VIEW.blend = math.max(0, math.min(1, VIEW.blend + (third and VIEW.rate or -VIEW.rate)))
	local tp = VIEW.blend
	local fp = 1 - tp
	gcfg.hideHead(p, e, cp, cd, vel or ZERO, low, cover or melee or aiming == true or tp > 0)
	local armed = gun and aiming ~= nil and not cover and not melee
	gcfg.gun = math.max(0, math.min(1, gcfg.gun + ((armed and aiming == false) and GC.gunRate or -GC.gunRate)))
	gcfg.ads = math.max(0, math.min(1, gcfg.ads + ((armed and aiming == true) and GC.gunRate or -GC.gunRate)))
	-- eased in and out; from the hip into the sights one fades out as the other comes in
	local g = gcfg.gun * gcfg.gun * (3 - 2 * gcfg.gun)
	local a = gcfg.ads * gcfg.ads * (3 - 2 * gcfg.ads)
	-- Peeking from cover: the config's cover camera stands on the body's axis at
	-- a fixed height (1.75 high, 1.05 low) while the head leans out and ducks.
	-- It follows the eyes sideways and in height; the camera is read a frame
	-- late, so a part of the gap a frame (gcfg.coverX/Z). A camera far from the
	-- eyes is the game's own third-person cover camera, and a gap of over
	-- GC.coverMax in height is a camera switching (the first frame in cover
	-- still reads the camera before it); both let the follow go, as the sights
	-- do (the aim camera has its own place). It used to hold what it had taken:
	-- crouching into cover, that first frame lowered the camera 0.27 m for good.
	local h = norm(vec(cd.x, cd.y, 0))
	local follow = cover and Cfg.coverFollow and aiming ~= true and tp == 0
	if not (follow and e == nil) then
		local gap = (follow and h ~= nil) and sub(e, cp) or nil
		if gap ~= nil and len(vec(gap.x, gap.y, 0)) < GC.coverNear and math.abs(gap.z) < GC.coverMax then
			gcfg.coverX = math.max(-GC.coverMax, math.min(GC.coverMax, gcfg.coverX + dot(gap, vec(h.y, -h.x, 0)) * GC.coverRate))
			gcfg.coverZ = math.max(-GC.coverMax, math.min(GC.coverMax, gcfg.coverZ + gap.z * GC.coverRate))
		else
			gcfg.coverX, gcfg.coverZ = gcfg.coverX * 0.8, gcfg.coverZ * 0.8
		end
	end
	local fx, fy, fz = FX.tick(p, gun and not melee, aiming, vel or ZERO)
	local tpX = VIEW.x + (VIEW.aimX - VIEW.x) * a
	local tpY = VIEW.y + (VIEW.aimY - VIEW.y) * a
	-- the sights' place of the kind of gun in hand, kept while it eases out
	if gun and a > 0 then
		gcfg.aimKind = GUN.kindOf(p)
	end
	local kind = gcfg.aimKind or 1
	local aimX = GUN.axv[Cfg.aimXs[kind] or Cfg.aimX]
	local aimZ = GUN.azv[Cfg.aimZs[kind] or Cfg.aimZ]
	local x = fp * (g * GUN.xv[Cfg.gunX] + a * aimX + fx) + tp * tpX + gcfg.coverX
	local y = fp * fy + tp * tpY
	local z = gcfg.crouchZ + fp * bob + stair + K.LIFT_VAL[Cfg.lift] + gcfg.coverZ + tp * VIEW.z
		+ fp * (fz - g * GUN.zv[Cfg.gunZ] - a * aimZ)
	if want ~= 0 or math.abs(z) > 0.005 or math.abs(x) > 0.005 or math.abs(y) > 0.005 then
		gcfg.idle = 0
	else
		gcfg.idle = gcfg.idle + 1
	end
	if gcfg.idle < GC.release then
		-- Sent every frame: the forced offset lives only while it is renewed.
		applyOffset(cam, vec(x, y, z))
		gcfg.crouchOn = true
	elseif gcfg.crouchOn then
		stopOffset(cam)
		gcfg.crouchOn = false
		gcfg.crouchZ = 0
	end
	-- Third person, once a session: at full blend and not aiming, the camera
	-- must stand behind the eyes, else the game does not lengthen the arm here.
	if tp >= 1 and a < 0.01 and not VIEW.told and e ~= nil and h ~= nil then
		VIEW.held = VIEW.held + 1
		if VIEW.held >= VIEW.check then
			local back = dot(sub(e, cp), h)
			VIEW.told = true
			if back < VIEW.minBack then
				VIEW.broken = true
				Cfg.footView = 1
				saveCfg()
				log(string.format("third person on foot: the camera only %.2f m behind the eyes, the game does not take the offset back: first person for this session", back))
				toast("First-person: third person on foot does not work here (the camera does not move back); first person stays")
			else
				log(string.format("third person on foot: the camera %.2f m behind the eyes", back))
			end
		end
	elseif tp < 1 then
		VIEW.held = 0
	end
	lastTarget = nil
	gcfg.trail(e, cp, cd, vel or ZERO, (cover or melee or tp > 0) and 0 or speed)
	TKD.watch(p, root, cover, melee, cd, (e ~= nil and tp == 0) and len(sub(cp, e)) or 0)
	-- in third person Lincoln turns as the game turns him
	if tp == 0 then
		turnBody(p, cd, speed, root, cp)
	end
end

-- Contexts

local function leaveContext(cam)
	if method == "native" or method == "wait" or cal ~= nil or gcfg.crouchOn then
		stopOffset(cam)
	end
	gcfg.crouchOn = false
	gcfg.detect = nil
	if method == "head" then
		lockedLeave(cam)
	end
	if method == "probe" then
		-- An interrupted steering test starts over next time.
		pcall(function()
			cam:ScriptUnlock(1)
		end)
		pcall(function()
			cam:ScriptLookAtStop()
		end)
		locked = false
		local p = getPlayer()
		if p ~= nil and probe ~= nil and probe.face ~= nil then
			faceTo(p, dirFromAngles(probe.face, 0))
		end
		probe = nil
		steerList = nil
	end
	cal = nil
	method = nil
end

local function ensureGameCameraUnlocked(cam)
	pcall(function()
		cam:ScriptUnlock(1)
	end)
	locked = false
	stopOffset(cam)
end

local function enterContext(cam, ctx, cd, veh)
	resetTracking()
	-- third person glides back from the eyes again; no kick or dip carried over
	VIEW.blend, VIEW.held, VIEW.backAng = 0, 0, 0
	FX.k, FX.dip, FX.fall, FX.fallFrames, FX.ammo = 0, 0, 0, 0, nil
	curCtx = ctx
	if ctx == "foot" then
		car.veh = nil -- the seat is measured again on the next ride
		anchorHold.made = 0 -- and a new anchor may be tried again
	end
	if ctx == "foot" and gcfg.installed ~= false then
		ensureGameCameraUnlocked(cam)
		if gcfg.installed == nil then
			-- Look first, before anything moves the camera.
			gcfg.detect = { frames = 0, near = 0, loud = gcfg.loud, rel = nil }
			method = "detect"
			return
		end
		method = "config"
		log("on foot: the game's own first-person camera (tables.sds), the trainer turns the body, follows a crouch and adds the camera height and head bob")
		return
	end
	-- The config covers the camera on foot only: driver seats differ per car, so
	-- in a vehicle the head camera sits on the driver's eyes, whatever the car.
	-- There the view never steers anything, so its walking problem does not exist.
	-- Shooting from the car always uses it: the game's camera did not reach the
	-- driver's eyes by an offset (game camera mode in a car, 2026-10-21). So does
	-- third person on foot (first person in vehicles only, with or without the
	-- patch): the camera mode in the menu is about walking.
	local inCar = ctx == "car" and (gcfg.installed == true or Cfg.footView == 2)
	local view = (inCar or ctx == "carshoot") and 1 or Cfg.view
	if view == 1 then
		stopOffset(cam)
		if anchorReady() then
			seedLook(cd, veh)
			if ctx == "carshoot" then
				car.aim = { frames = 0, mouse = 0, turn = 0, last = cd, ok = false }
				method = "head"
				log("vehicle: shooting, the camera stays at the eyes and looks where the game's camera aims")
				return
			end
			if veh == nil and steerList == nil then
				steerList = steerFromString(getSetting("FpSteer"))
				steerIdx = 1
				if steerList == nil then
					startProbe(getPlayer())
					return
				end
				log("steering: " .. steerToString(steerList))
			end
			method = "head"
			log("head camera at the eyes (" .. ctx .. ")" .. (followNative[ctx] and ", following the game's camera" or ""))
			return
		end
		log("head camera unavailable, using the game camera")
		if ctx == "carshoot" then
			-- no method: the game's own camera aims
			ensureGameCameraUnlocked(cam)
			return
		end
	end
	ensureGameCameraUnlocked(cam)
	if measureWanted[ctx] then
		measureWanted[ctx] = nil
		beginMeasure(ctx, "asked from the menu")
		return
	end
	if calib[ctx] == nil then
		calib[ctx] = loadCalib(ctx) or defaultCalib(ctx)
	end
	method = "native"
	local c = calib[ctx]
	log(string.format("game camera (%s), %s %s model, delay %d", ctx, c.measured and "measured" or "default", c.frame, c.delay))
end

local function calibrationTick(cam, root, cp, cd)
	local st = cal.steps[cal.i]
	if cal.f == 0 then
		if cal.i == 1 then
			cal.B0 = rig(cd)
			cal.d0 = cal.B0.f
			cal.root0 = root
		end
		if st.track then
			cal.trace = {}
			cal.trBefore = cp
		end
		applyOffset(cam, st.o)
		cal.f = 1
		return
	end
	if st.track then
		cal.trace[cal.f] = cp
	end
	if cal.f < st.n then
		cal.f = cal.f + 1
		return
	end
	if st.key ~= nil then
		cal.samples[st.axis .. st.key] = cp
	end
	cal.i = cal.i + 1
	cal.f = 0
	if cal.i <= #cal.steps then
		return
	end

	stopOffset(cam)
	local c, why, moving = solveCalibration(cd, root)
	local ctx, tries = cal.ctx, cal.tries
	cal = nil
	if c ~= nil then
		calib[ctx] = c
		saveCalib(ctx, c)
		method = "native"
		resetTracking()
		toast("First-person: ready")
		return
	end
	log(string.format("calibration %s try %d failed: %s", ctx, tries, why))
	attempts = attempts + 1
	if attempts < 10 and (moving or tries < 2) then
		-- wait for the player to stand still again before the next try
		method = "wait"
		waitFrames = 30
		stillFrames = 0
		retryTries = moving and tries or tries + 1
		return
	end
	-- Keep the camera usable with the model measured in the game.
	calib[ctx] = defaultCalib(ctx)
	calib[ctx].measured = true
	method = "native"
	resetTracking()
	warned[ctx] = true
	toast("First-person: the game camera did not follow — try Recalibrate or the head camera")
end

-- First-person takedowns (see TKD above)

-- The kind of takedown starting on `victim`, what told it, and where he stands.
function TKD.kindOf(root, victim)
	local vr = readVec(function()
		return victim:GetPos()
	end)
	if vr == nil then
		return nil, "the victim has no position"
	end
	local _, ve = findEye(victim, vr, 0.3)
	if ve == nil then
		-- a car or a thing in the middle of the screen
		return nil, string.format("what was in the middle of the screen (%.2f m away) has no eyes", len(sub(vr, root)))
	end
	local h = ve.z - vr.z
	local hp = nil
	pcall(function()
		hp = tonumber(victim.health)
	end)
	local told = string.format("victim %.2f m away, its eyes %.2f m above its feet, health %s", len(sub(vr, root)), h,
		hp and string.format("%.0f", hp) or "?")
	local function since(at)
		return at ~= nil and tick - at or 1e9
	end
	if since(TKD.coverAt) <= TKD.recent then
		return "from cover", told, vr
	elseif since(TKD.sprintAt) <= TKD.recent then
		return "on the run", told, vr
	elseif hp ~= nil and hp <= TKD.stunHp then
		return "stunned", told, vr
	elseif since(TKD.fightAt) <= TKD.fight then
		return "brutal", told, vr
	elseif h < TKD.floor then
		return "sitting on the floor", told, vr
	elseif h < TKD.seat then
		return "seated", told, vr
	end
	return "behind", told, vr
end

-- Where the camera looks during a takedown: the victim's neck, else under his eyes.
function TKD.neckOf(victim)
	local vr = readVec(function()
		return victim:GetPos()
	end)
	if vr == nil then
		return nil
	end
	local n = bone(victim, "Neck1")
	if nearRoot(n, vr) then
		return n
	end
	local _, ve = findEye(victim, vr, 0.3)
	return ve and vec(ve.x, ve.y, ve.z - 0.1) or nil
end

-- The controls have just locked: a first-person takedown if it is one of the
-- chosen kinds. False leaves the lock to the usual pause (the game's camera).
function TKD.begin(p, cam)
	-- (in third person on foot the game's own camera shows every takedown)
	if Cfg.takedowns <= 1 or Cfg.footView == 2 or TKD.seenAt == nil or tick - TKD.seenAt > 3 or vehicleOf(p) ~= nil then
		return false
	end
	if _input_melee_age == nil then
		if not TKD.noQTold then
			TKD.noQTold = true
			log("takedowns in first person: this ASI cannot tell Q (rebuild it: BUILD_STREET_FIGHT_ASI.bat), the game's camera")
		end
		return false
	end
	local ok, age = pcall(_input_melee_age)
	age = ok and tonumber(age) or nil
	if age == nil or age > TKD.window then
		-- not just after Q: a scene, a dialogue
		return false
	end
	local victim = TKD.cand
	if victim == nil or TKD.candAt == nil or tick - TKD.candAt > TKD.candAge then
		log(string.format("takedown? the controls locked %d frames after Q, nobody in the middle of the screen: the game's camera", age))
		return false
	end
	local root = readVec(function()
		return p:GetPos()
	end)
	if root == nil then
		return false
	end
	local kind, told, vr = TKD.kindOf(root, victim)
	if kind == nil or len(sub(vr, root)) > TKD.range then
		log(string.format("takedown? %s, not one: the game's camera", told))
		return false
	end
	local need = TKD.allow[kind]
	if need == nil or Cfg.takedowns < need then
		log(string.format("takedown %s (%s, Q %d frames before): the game's camera", kind, told, age))
		return false
	end
	local e = rawEye(p, root)
	if e == nil or not anchorReady() then
		log("takedown " .. kind .. ": no eyes or no camera anchor, the game's camera")
		return false
	end
	leaveContext(cam)
	curCtx = nil
	TKD.on = { kind = kind, victim = victim, frames = 0, lost = 0, pos = e, dir = norm(TKD.lastDir or ZERO) or vec(1, 0, 0) }
	log(string.format("takedown in first person: %s (%s, Q %d frames before)", kind, told, age))
	TKD.drive(p, cam)
	return true
end

-- A frame of a first-person takedown: the anchor at the eyes, turning to the
-- victim's neck.
function TKD.drive(p, cam)
	local t = TKD.on
	t.frames = t.frames + 1
	local root = readVec(function()
		return p:GetPos()
	end)
	local e = root and rawEye(p, root) or nil
	t.lost = e and 0 or t.lost + 1
	local why = nil
	if t.frames > TKD.minFrames and not controlsLocked(p) then
		why = "the controls are back"
	elseif t.frames > TKD.maxFrames then
		why = "too long for a takedown (an interrogation or a scene?)"
	elseif t.lost > TKD.lostMax then
		why = "the eyes are not found"
	elseif anchorHold.broken then
		why = "the camera anchor does not answer"
	elseif vehicleOf(p) ~= nil then
		why = "in a vehicle"
	end
	if why ~= nil then
		TKD.stop(cam, why)
		return
	end
	if e ~= nil then
		t.pos = add(t.pos, scale(sub(e, t.pos), TKD.follow))
	end
	local neck = TKD.neckOf(t.victim)
	if neck ~= nil and len(sub(neck, t.pos)) > TKD.near then
		local want = norm(sub(neck, t.pos))
		t.dir = norm(add(t.dir, scale(sub(want, t.dir), TKD.aim))) or t.dir
	end
	lockAnchor(cam, add(t.pos, scale(t.dir, TKD.fwd)), t.dir)
end

-- Gives the camera back to the game; the config comes back next frame.
function TKD.stop(cam, why)
	local t = TKD.on
	TKD.on = nil
	lockedLeave(cam)
	if anchorHold.broken then
		anchorHold.forget()
	end
	curCtx = nil
	TKD.endDir = t and t.dir or nil
	log(string.format("takedown in first person: over after %d frames (%s)", t and t.frames or 0, why))
end

-- True while a first-person takedown has the camera, from the frame it starts.
function TKD.tick(p, cam)
	if TKD.on ~= nil then
		TKD.drive(p, cam)
		return true
	end
	if suspended or not controlsLocked(p) then
		return false
	end
	return TKD.begin(p, cam)
end

----------------
-- Public API --
----------------

local function suspend(cam, p, why)
	leaveContext(cam)
	-- a first-person takedown cut short (a death) lets the camera go too
	TKD.on = nil
	lockedLeave(cam)
	gcfg.headHidden = false
	stopFov(cam)
	showModel(p, true)
	VIEW.hat(p, false)
	curCtx = nil
	suspended = true
	log("paused: " .. why)
end

function FpsLikeDisable()
	if not FpsLikeEnabled then
		return
	end
	FpsLikeEnabled = false
	TKD.on = nil
	gcfg.headHidden = false
	local cam = getCam()
	if cam ~= nil then
		leaveContext(cam)
		lockedLeave(cam)
		stopFov(cam)
	end
	local p = getPlayer()
	if p ~= nil then
		showModel(p, true)
		VIEW.hat(p, false)
	end
	curCtx = nil
	suspended = false
	log("off")
	if gcfg.installed == true then
		toast("First person stays: it is in the game camera config. Third person again: IRIDIUM\\fp_camera\\UNINSTALL_FP_CAMERA.bat")
	end
end

function FpsLikeEnable()
	if FpsLikeEnabled then
		return
	end
	ensureCfg()
	local p = getPlayer()
	local cam = getCam()
	if p == nil or cam == nil then
		log("no player or camera yet")
		return
	end
	pcall(function()
		cam:ScriptUnlock(1)
	end)
	locked = false
	stopOffset(cam)
	FpsLikeEnabled = true
	curCtx = nil
	suspended = false
	warned = {}
	followNative = {}
	steerBad, steerFrames, steerWarned = 0, 0, false
	if Cfg.body then
		showModel(p, true)
	end
	log(string.format("on: %s, body %s, turn %s, bob %s, fov %s, forward %s, height %s, lead %s, mouse %s, vehicles %s, car fov %s, car forward %s",
		VIEWS[Cfg.view], tostring(Cfg.body), tostring(Cfg.turn), BOBS[Cfg.bob], FOVS[Cfg.fov], FWDS[Cfg.fwd],
		LIFTS[Cfg.lift], tostring(Cfg.lead), SENS[Cfg.sens], tostring(Cfg.vehicles), CAR.fovs[Cfg.carFov], CAR.fwds[Cfg.carFwd]))
	local sights = {}
	for k, key in ipairs(K.AIM_KEYS) do
		sights[k] = string.format("%s %s/%s", key, GUN.axs[Cfg.aimXs[k]] or "?", GUN.azs[Cfg.aimZs[k]] or "?")
	end
	log(string.format("on: smooth steps %s, with a gun %s right / %s down, in the sights (right/down) %s, fov %s, aim button %s, takedowns %s, body hidden while the head is ahead %s",
		tostring(Cfg.steps), GUN.xs[Cfg.gunX], GUN.zs[Cfg.gunZ], table.concat(sights, ", "),
		forcedFov.aims[Cfg.aimFov], GUN.aiming() == nil and "unknown (old ASI)" or "read", TKD.names[Cfg.takedowns],
		tostring(Cfg.headHide)))
	log(string.format("on: on foot %s, view key %s, look back %s, vehicle camera %s, driver's lean %s, effects %s, cover follow %s, hat hidden %s, keys %s",
		K.FOOT_VIEWS[Cfg.footView], K.VIEW_KEYS[Cfg.viewKey], K.BACK_KEYS[Cfg.backKey], K.CAR_CAMS[Cfg.carCam],
		tostring(Cfg.carLean), K.FXS[Cfg.fx], tostring(Cfg.coverFollow), tostring(Cfg.hideHat),
		_input_key_down ~= nil and "read" or "unknown (old ASI)"))
end

-- The menu's switch: the choice is remembered (Cfg.on, FpOn). The view is on by
-- default; turned off here it stays off in the next sessions too.
function FpsLikeToggle()
	ensureCfg()
	if FpsLikeEnabled then
		FpsLikeDisable()
	else
		FpsLikeEnable()
	end
	Cfg.on = FpsLikeEnabled
	gcfg.auto = false
	saveCfg()
end

-- On by default (asked 2026-10-21): turned on once a session, as soon as there
-- is a living player with free controls. `gcfg.auto` marks a view turned on so:
-- without the camera patch it goes off again on foot (FpsLikeOnTick), rather
-- than leave the script camera, whose walking can drift, to a player who never
-- asked for it. The player is told once the config check on foot has decided
-- (detectTick), so it is one note, not "on" followed by "no patch, off".
local function autoStart()
	ensureCfg()
	if not Cfg.on or gcfg.autoDone then
		return
	end
	gcfg.autoWait = (gcfg.autoWait or 0) - 1
	if gcfg.autoWait > 0 then
		return
	end
	gcfg.autoWait = 30
	local p = getPlayer()
	if p == nil or getCam() == nil or controlsLocked(p) or humanFlag(p, "IsDeath") then
		return
	end
	gcfg.autoDone = true
	FpsLikeEnable()
	gcfg.auto = FpsLikeEnabled
end

function FpsLikeOnTick()
	VIEW.hotkey()
	if not FpsLikeEnabled then
		autoStart()
		return
	end
	-- a try of the check has the camera; one that broke off lets go after ~2 s
	if forcedFov.probe then
		forcedFov.probeTicks = (forcedFov.probeTicks or 0) + 1
		if forcedFov.probeTicks < 120 then
			return
		end
		forcedFov.probe = false
	end
	forcedFov.probeTicks = 0
	tick = tick + 1
	local p = getPlayer()
	-- Death, and the load after it: a dead player, or for a moment none at all.
	-- Paused, not turned off: off, the trainer stayed off after the respawn (on
	-- foot the camera config hid that) and the next car was third person; and the
	-- world built anew can take the anchor with it, so it is made anew (2026-10-21).
	if p == nil or humanFlag(p, "IsDeath") then
		anchorHold.stale = true
		if not suspended then
			suspend(getCam(), p, p == nil and "no player (a load)" or "Lincoln is dead")
		end
		return
	end
	local cam = getCam()
	if cam == nil then
		return
	end
	-- a takedown in first person has the camera (TKD); one starts as the controls lock
	if TKD.tick(p, cam) then
		return
	end
	if controlsLocked(p) then
		if not suspended then
			suspend(cam, p, "controls locked")
		end
		return
	end
	if suspended then
		suspended = false
		log("resumed")
	end
	if anchorHold.stale then
		anchorHold.forget()
	end

	local veh = vehicleOf(p)
	local ctx = veh ~= nil and "car" or "foot"
	if ctx == "car" and not Cfg.vehicles then
		ctx = "off"
	end
	-- Third person on foot: with the camera config the offset takes the camera
	-- back (configTick, VIEW); without it the game's own camera is third person.
	if ctx == "foot" and Cfg.footView == 2 and gcfg.installed == false then
		ctx = "off"
	end
	-- Shooting from a vehicle: the game fires along its own camera. The head
	-- camera looks where that camera looks (car.aimCheck); where it cannot, the
	-- game's camera takes over while a gun is in hand (car.shootOff).
	if ctx == "car" and humanFlag(p, "HaveFireWeaponInHand") then
		ctx = "carshoot"
	end
	-- Lincoln's hat off while the view here is first person (VIEW.hat)
	VIEW.hat(p, Cfg.hideHat and ((ctx == "foot" and Cfg.footView ~= 2) or ctx == "car"
		or (ctx == "carshoot" and not car.shootOff)))
	local root = readVec(function()
		return (veh or p):GetPos()
	end)
	local cp = readVec(function()
		return cam:GetPos()
	end)
	local cd = readVec(function()
		return cam:GetDir()
	end)
	if root == nil or cp == nil or cd == nil then
		return
	end

	if ctx ~= curCtx then
		leaveContext(cam)
		forcedFov.resend = true
		if gcfg.headHidden then
			-- hidden for the head ahead of the camera on foot: shown again as the context changes
			gcfg.headHidden = false
			showModel(p, Cfg.body)
		end
		if ctx == "off" or (ctx == "carshoot" and car.shootOff) then
			curCtx = ctx
			stopFov(cam)
			showModel(p, true)
			log(ctx == "carshoot" and "vehicle: shooting, the game's own camera aims"
				or veh ~= nil and "vehicle: game camera (first person in vehicles is off)"
				or "on foot: the game's own camera (third person on foot)")
			return
		end
		enterContext(cam, ctx, cd, veh)
		ctxSettle = method == "head" and 0 or 2
	end
	if ctx == "off" or (ctx == "carshoot" and method ~= "head") then
		return
	end
	-- Every frame, so a gun drawn or put away on foot shows at once.
	setFov(cam, fovWanted(p, ctx), (ctx == "car" or ctx == "carshoot") and 0.5 or 0.3)

	if ctxSettle > 0 then
		ctxSettle = ctxSettle - 1
		lastRoot = root
		lastDir = cd
		return
	end

	local vel = lastRoot and sub(root, lastRoot) or ZERO
	if len(vel) > 2 then
		vel = ZERO
	end
	local speed = len(vec(vel.x, vel.y, 0))
	lastRoot = root
	local turn = lastDir and dot(norm(lastDir) or cd, norm(cd) or cd) or 1
	lastDir = cd

	if method == "detect" and detectTick(p, root, cp) then
		if gcfg.installed == false and Cfg.footView == 2 then
			-- Third person on foot and no camera patch: first person in vehicles
			-- only (asked 2026-10-22). No reason to turn the view off, nor to start a
			-- script camera on foot: the game's own one from the next frame.
			gcfg.auto = false
			leaveContext(cam)
			curCtx = nil
			return
		end
		if gcfg.installed == false and gcfg.auto then
			-- turned on by default, but without the camera patch (detectTick told
			-- the way to it): off again; the menu still turns the script camera on
			gcfg.auto = false
			FpsLikeDisable()
			return
		end
		-- decided: the chosen way starts in this same frame
		enterContext(cam, ctx, cd, veh)
	end
	if method == "config" then
		configTick(p, cam, root, cd, speed, cp, vel)
	elseif method == "head" then
		if anchorHold.broken then
			anchorHold.renew(cam)
			return
		end
		headTick(p, cam, veh, root, cd, vel)
		if ctx == "foot" then
			local s = currentSteer()
			-- "behind" steering already faces Lincoln along the view every frame.
			-- The picture is the trainer's own at the eyes: no camera to check.
			if s == nil or s.m ~= "behind" then
				turnBody(p, viewDir, speed)
			end
			watchSteer(p, vel, speed)
		end
	elseif method == "probe" then
		probeTick(p, cam, root, cp, cd)
	elseif method == "wait" then
		waitFrames = waitFrames - 1
		if speed < 0.01 and turn > 0.9998 then
			stillFrames = stillFrames + 1
		else
			stillFrames = 0
		end
		if waitFrames <= 0 and stillFrames >= 8 then
			method = "calibrating"
			log(string.format("calibrating %s, try %d", ctx, retryTries))
			startCalibration(ctx, retryTries)
		end
	elseif method == "calibrating" and cal ~= nil then
		calibrationTick(cam, root, cp, cd)
	elseif method == "native" then
		nativeTick(p, cam, root, cp, cd, vel, speed)
		if ctx == "foot" then
			turnBody(p, cd, speed, root, cp)
		end
	end

	-- (no method: the game's camera took over this frame, the body stays shown)
	if not Cfg.body and method ~= nil then
		showModel(p, false)
	end
	if tick % 600 == 0 then
		log(string.format("%s %s: miss %.3f m, speed %.2f m/frame, offset %s",
			ctx, tostring(method), lastRes, speed, fmt(offset)))
	end
end

-- Short state for the menu: what drives the camera.
function FpsLikeStatus()
	if not FpsLikeEnabled then
		return "off"
	end
	if suspended then
		return "paused"
	end
	if method == "native" then
		return lastRes < 0.05 and "eyes" or "pulling"
	end
	if method == "config" then
		return "game config"
	end
	return tostring(method or "starting")
end

local function writeState()
	ensureCfg()
	local p = getPlayer()
	local cam = getCam()
	if p == nil or cam == nil then
		log("state: no player or camera")
		return
	end
	local veh = vehicleOf(p)
	local root = readVec(function()
		return (veh or p):GetPos()
	end) or ZERO
	local cp = readVec(function()
		return cam:GetPos()
	end) or ZERO
	local cd = readVec(function()
		return cam:GetDir()
	end) or vec(1, 0, 0)
	log(string.format("state: on %s, %s, view %s, method %s, in vehicle %s, follows game camera %s, offset %s",
		tostring(FpsLikeEnabled), tostring(curCtx), VIEWS[Cfg.view], tostring(method), tostring(veh ~= nil),
		tostring(curCtx ~= nil and followNative[curCtx] == true), fmt(offset)))
	log(string.format("state: game camera config %s, crouch offset %.2f m, stealth %s, cover %s, along the view %.2f m",
		gcfg.installed == nil and "not checked yet" or (gcfg.installed and "installed" or "not installed"), gcfg.crouchZ,
		tostring(humanFlag(p, "IsStealthMove")), tostring(humanFlag(p, "IsInCover")),
		dot(sub(cp, root), norm(vec(cd.x, cd.y, 0)) or vec(1, 0, 0))))
	log(string.format("state: field of view %s, gun in hand %s, settings: bob %s, height %s, mouse %s, car fov %s, car forward %s",
		forcedFov.now and tostring(forcedFov.now) or "the game's", tostring(humanFlag(p, "HaveFireWeaponInHand")),
		BOBS[Cfg.bob], LIFTS[Cfg.lift], SENS[Cfg.sens], CAR.fovs[Cfg.carFov], CAR.fwds[Cfg.carFwd]))
	log(string.format("state: aiming %s, gun place: hip %.2f, sights %.2f, behind on a step %.3f m, smooth steps %s",
		tostring(GUN.aiming()), gcfg.gun, gcfg.ads, gcfg.rootZ and gcfg.rootZ - root.z or 0, tostring(Cfg.steps)))
	log(string.format("state: steering %s (now %s), walking off the view %.0f deg", steerToString(steerList),
		currentSteer() and (currentSteer().m .. ":" .. currentSteer().f) or "-", math.deg(steerBad)))
	log(string.format("state: root %s, camera %s, view %s, target %s, camera to target %.3f m", fmt(root), fmt(cp), fmt(cd),
		lastTarget and fmt(lastTarget) or "-", lastTarget and len(sub(lastTarget, cp)) or -1))
	for _, name in ipairs({ "LeftEye", "RightEye", "EYE_L", "EYE_R", "camera_headpos", "Head", "Neck1", "RightHand", "GunHand_R" }) do
		local b = bone(p, name)
		log(string.format("state: bone %-14s %s", name, b and fmt(sub(b, root)) or "-"))
	end
	for _, ctx in ipairs({ "foot", "car" }) do
		local c = calib[ctx] or loadCalib(ctx) or defaultCalib(ctx)
		log(string.format("state: model %s %s %s delay %d: %s", ctx, c.measured and "measured" or "default", c.frame, c.delay,
			matToString(c.M)))
	end
end

local function recalibrate()
	calib = {}
	saveCalib("foot", nil)
	saveCalib("car", nil)
	steerList = nil
	steerWarned = false
	setSetting("FpSteer", "")
	measureWanted = { foot = true, car = true }
	hinted = {}
	warned = {}
	if FpsLikeEnabled then
		local cam = getCam()
		if cam ~= nil then
			leaveContext(cam)
		end
		curCtx = nil
	end
	log("calibration cleared, measuring on the next frame (game camera)")
end

-- A changed angle shows at once, also while the menu is open.
local function refreshFov()
	local cam, p = getCam(), getPlayer()
	if FpsLikeEnabled and not suspended and cam ~= nil and p ~= nil and method ~= nil
		and (curCtx == "foot" or curCtx == "car" or curCtx == "carshoot") then
		setFov(cam, fovWanted(p, curCtx), curCtx == "foot" and 0.3 or 0.5)
	end
end

-- Settings that change how the camera is driven take effect by re-entering the context.
local function restartContext()
	if FpsLikeEnabled then
		local cam = getCam()
		if cam ~= nil then
			leaveContext(cam)
			lockedLeave(cam)
		end
		curCtx = nil
	end
end

-- The view key (Cfg.viewKey, read every tick from FpsLikeOnTick): first or
-- third person where Lincoln is. On foot it switches Cfg.footView (with the
-- camera config the camera goes back behind him, VIEW; without it the game's
-- own camera), in a vehicle first person there (Cfg.vehicles); with the view
-- off it turns it on. Remembered like the menu's rows.
function VIEW.hotkey()
	ensureCfg()
	local down = Cfg.viewKey > 1 and VIEW.keyDown(K.VIEW_VK[Cfg.viewKey])
	local pressed = down and not VIEW.keyWas
	VIEW.keyWas = down
	if not pressed then
		return
	end
	local p = getPlayer()
	if p == nil or controlsLocked(p) then
		return
	end
	if not FpsLikeEnabled then
		FpsLikeToggle()
		if FpsLikeEnabled then
			toast("First-person view is on (F4 - Camera turns it off)")
		end
		return
	end
	if vehicleOf(p) ~= nil then
		Cfg.vehicles = not Cfg.vehicles
		restartContext()
		toast(Cfg.vehicles and "First-person view: first person in vehicles" or "First-person view: the game's camera in vehicles")
	elseif VIEW.broken and gcfg.installed == true then
		toast("First-person: third person on foot does not work here (the camera does not move back); first person stays")
		return
	else
		Cfg.footView = Cfg.footView == 2 and 1 or 2
		toast(Cfg.footView == 2 and "First-person view: third person on foot" or "First-person view: first person on foot")
	end
	saveCfg()
end

----------
-- Menu --
----------

local function onList(fn)
	return function(_, _, _, _, idx)
		idx = tonumber(idx)
		if idx ~= nil then
			fn(idx)
			saveCfg()
		end
	end
end

local function addList(menu, label, items, selected, cb, hint, icon)
	local i = menu:AddList(label, onList(cb))
	for _, item in ipairs(items) do
		menu:AddListEntry(i, item)
	end
	menu:SelectListEntryByValue(i, items[selected])
	menu:Decorate(i, hint, icon)
	return i
end

function FpsLikeMenu()
	ensureCfg()
	local menu = UI.SimpleMenu()
	menu:SetTitle("First-person view")

	local tog = menu:AddCheckbox("First-person view", function()
		FpsLikeToggle()
	end)
	menu:Decorate(tog, "Camera in Lincoln's eyes: you see hands, weapon and the steering wheel. On by default, the choice is remembered", 0xE890)

	local body = menu:AddCheckbox("Show body, hands and weapon", function()
		Cfg.body = not Cfg.body
		saveCfg()
		local p = getPlayer()
		if p ~= nil and FpsLikeEnabled then
			showModel(p, Cfg.body and not gcfg.headHidden)
		end
	end)
	menu:Decorate(body, "Off hides the whole model, weapon included", 0xE77B)

	local turnRow = menu:AddCheckbox("Body turns with the view", function()
		Cfg.turn = not Cfg.turn
		turning = false
		saveCfg()
	end)
	menu:Decorate(turnRow, "Standing still, Lincoln turns to where you look, like in GTA", 0xE7AD)

	local veh = menu:AddCheckbox("Also in vehicles", function()
		Cfg.vehicles = not Cfg.vehicles
		saveCfg()
		restartContext()
	end)
	menu:Decorate(veh, "Driver's seat view; the camera follows the car", 0xE804)

	-- rows a preset sets, filled below (the preset is picked once they exist)
	local rows = {}
	addList(menu, "View on foot", K.FOOT_VIEWS, Cfg.footView, function(i)
		Cfg.footView = i
	end, "Third person: with the camera patch the camera moves back behind Lincoln's shoulder on the fly (mouse, walking and aiming stay the game's). Without the patch it is the game's own camera on foot and first person in vehicles only, the patch is not needed for that. The view key switches it", 0xE7C3)
	addList(menu, "View key", K.VIEW_KEYS, Cfg.viewKey, function(i)
		Cfg.viewKey = i
	end, "Switches first and third person where you are: on foot the row above, in a vehicle «Also in vehicles»; turns the view on when it is off. Needs the current ASI", 0xE765)
	addList(menu, "Look back in a vehicle", K.BACK_KEYS, Cfg.backKey, function(i)
		Cfg.backKey = i
	end, "Hold the key to look back over your shoulder from the driver's seat. Needs the current ASI", 0xE804)
	addList(menu, "Camera in vehicles", K.CAR_CAMS, Cfg.carCam, function(i)
		Cfg.carCam = i
	end, "At the driver's eyes, or on the hood (experimental: the hood is longer or shorter by car)", 0xE804)
	addList(menu, "Camera follows the driver's lean", ONOFF, Cfg.carLean and 2 or 1, function(i)
		Cfg.carLean = i == 2
	end, "The camera at the driver's eyes is fixed to the seat. Leaning forward (braking, a turn) his head came in front of it. On: along the car the camera follows his eyes forward once they are over 4 cm off the seat, without the small shakes", 0xE804)
	addList(menu, "Preset", K.PRESETS, 1, function(i)
		local set = K.PRESET_VAL[i]
		if not set then
			return
		end
		for key, v in pairs(set) do
			Cfg[key] = v
		end
		if menu.SelectListEntryLive ~= nil then
			menu:SelectListEntryLive(rows.bob, Cfg.bob)
			menu:SelectListEntryLive(rows.fx, Cfg.fx)
			menu:SelectListEntryLive(rows.steps, Cfg.steps and 2 or 1)
			menu:SelectListEntryLive(rows.headHide, Cfg.headHide and 2 or 1)
		end
		toast("First-person: preset applied")
	end, "Several rows at once. Standard: low head bob, light effects. Steady: no head bob, no effects. Immersive: full head bob, strong effects", 0xE771)

	menu:AddSection("Camera")
	local modeRow = addList(menu, "Camera mode", VIEWS, Cfg.view, function(i)
		Cfg.view = i
		restartContext()
	end, "Only without the game camera config (with it vehicles always use the head camera). Head camera: held at the eyes. Game camera: the game's own, stops just behind the head on foot", 0xE722)
	addList(menu, "Mouse sensitivity", SENS, Cfg.sens, function(i)
		Cfg.sens = i
	end, "How fast the head camera turns with the mouse: in vehicles, and on foot in the head camera mode without the game camera config. Elsewhere the game's own mouse setting applies", 0xE962)
	rows.bob = addList(menu, "Head bob", BOBS, Cfg.bob, function(i)
		Cfg.bob = i
	end, "Off keeps the view steady. On foot: the eyes' up and down while walking (not with a gun in hand, in cover or a fight). In a vehicle: the driver's head", 0xE9E9)
	rows.fx = addList(menu, "Camera effects", K.FXS, Cfg.fx, function(i)
		Cfg.fx = i
	end, "With the game camera config, in first person: a kick of the camera on each shot (stronger for shotguns, rifles and revolvers), a slow sway in the sights, a dip on landing after a fall", 0xE9E9)
	local fovRow = addList(menu, "Field of view", FOVS, Cfg.fov, function(i)
		Cfg.fov = i
		refreshFov()
	end, "On foot. With the game camera config also with a gun from the hip; in the sights the next row applies", 0xE71E)
	local aimFovRow = addList(menu, "Field of view in the sights", forcedFov.aims, Cfg.aimFov, function(i)
		Cfg.aimFov = i
		refreshFov()
	end, "With the game camera config, aiming down the sights (right mouse button). Game: the config's zoom for each weapon; On foot: no zoom, the angle above", 0xE71E)
	local carFovRow = addList(menu, "Field of view in vehicles", CAR.fovs, Cfg.carFov, function(i)
		Cfg.carFov = i
		refreshFov()
	end, "Wider in a car for the sense of speed; on foot the field of view above applies", 0xE804)
	local fwdRow = addList(menu, "Camera forward", FWDS, Cfg.fwd, function(i)
		Cfg.fwd = i
	end, "Head camera on foot (without the game camera config, which places the camera itself): metres in front of the eyes; more if you see the inside of the head", 0xE898)
	addList(menu, "Camera forward in vehicles", CAR.fwds, Cfg.carFwd, function(i)
		Cfg.carFwd = i
	end, "Metres in front of the driver's eyes, minus behind them; more if you see the inside of the head", 0xE804)
	addList(menu, "Camera height", LIFTS, Cfg.lift, function(i)
		Cfg.lift = i
	end, "Metres above or below the eyes, on foot and in vehicles", 0xE898)
	rows.steps = addList(menu, "Smooth steps", ONOFF, Cfg.steps and 2 or 1, function(i)
		Cfg.steps = i == 2
	end, "With the game camera config: on stairs the camera rises and sinks smoothly instead of jumping with the feet (at most 12 cm behind)", 0xE898)
	rows.headHide = addList(menu, "Hide the body when the head is ahead of the camera", ONOFF, Cfg.headHide and 2 or 1, function(i)
		Cfg.headHide = i == 2
	end, "With the game camera config: starting off sharply, crouching and getting up, Lincoln's head leans ahead of the camera, which cannot move forward, and his eyes and mouth would show from inside. On: the body is hidden for that moment. Off: it stays", 0xE7C3)
	addList(menu, "Camera follows the head in cover", ONOFF, Cfg.coverFollow and 2 or 1, function(i)
		Cfg.coverFollow = i == 2
	end, "With the game camera config: peeking out of cover and ducking, the camera goes with the head sideways and in height", 0xE7C3)
	addList(menu, "Hide the hat", ONOFF, Cfg.hideHat and 2 or 1, function(i)
		Cfg.hideHat = i == 2
	end, "In first person, on foot and at the wheel, Lincoln's hat is hidden: its brim came into the view. Shown again in third person, with the game's camera and when the view is off. Glasses cannot be hidden this way", 0xE7C3)
	addList(menu, "Camera with a gun: right", GUN.xs, Cfg.gunX, function(i)
		Cfg.gunX = i
	end, "With the game camera config and a gun in hand, not aiming down the sights: metres to the right toward the weapon, so it is in view. Needs the current ASI (right mouse button = aiming)", 0xE7C8)
	addList(menu, "Camera with a gun: down", GUN.zs, Cfg.gunZ, function(i)
		Cfg.gunZ = i
	end, "With a gun in hand, not aiming down the sights: metres down toward the weapon", 0xE7C8)
	-- The two rows after it show and set the place of the kind of gun picked
	-- here, at first the one in hand (Cfg.aimXs/aimZs, per K.AIM_KINDS).
	local p0 = getPlayer()
	local aimKind = (p0 ~= nil and humanFlag(p0, "HaveFireWeaponInHand")) and GUN.kindOf(p0) or 1
	addList(menu, "Camera in the sights for", K.AIM_KINDS, aimKind, function(i)
		aimKind = i
		if menu.SelectListEntryLive ~= nil then
			menu:SelectListEntryLive(rows.aimX, Cfg.aimXs[i])
			menu:SelectListEntryLive(rows.aimZ, Cfg.aimZs[i])
		end
	end, "With the game camera config the place in the sights below is kept for each kind of gun; this row picks the kind the two rows show, at first the one in hand. Move it where the gun does not cover the target", 0xE7C8)
	rows.aimX = addList(menu, "Camera in the sights: right", GUN.axs, Cfg.aimXs[aimKind], function(i)
		Cfg.aimXs[aimKind] = i
	end, "With the game camera config, aiming down the sights (right mouse button): metres to the right, on top of the config's place for each weapon; minus is to the left. Needs the current ASI", 0xE7C8)
	rows.aimZ = addList(menu, "Camera in the sights: down", GUN.azs, Cfg.aimZs[aimKind], function(i)
		Cfg.aimZs[aimKind] = i
	end, "Aiming down the sights: metres down; minus is up", 0xE7C8)
	local tkdRow = addList(menu, "Takedowns in first person", TKD.names, Cfg.takedowns, function(i)
		Cfg.takedowns = i
	end, "With the game camera config: the camera stays at the eyes in a takedown from behind, of a seated man, of one on the phone or at a mounted gun. With stunned: also finishing a stunned one (a civilian after a beating too). All but the brutal (experimental): also from cover, over cover, on the run and of a man on the floor. The brutal ones keep the game's camera. Needs the current ASI", 0xE890)
	local leadRow = addList(menu, "Frame lead", ONOFF, Cfg.lead and 2 or 1, function(i)
		Cfg.lead = i == 2
	end, "Only without the game camera config: switch it if at speed the camera trails the head or runs ahead. The head camera in a vehicle never uses it", 0xEC4A)
	-- With the game camera config these change nothing: the config places the
	-- camera on foot (tables.sds, not movable while playing) and a vehicle always
	-- gets the head camera. Greyed out, so they do not look broken.
	if gcfg.installed == true and menu.SetEntryEnabled ~= nil then
		for _, row in ipairs({ modeRow, fwdRow, leadRow }) do
			menu:SetEntryEnabled(row, false)
		end
	end
	-- the takedowns ride on the config; without it they are the game's anyway
	if gcfg.installed == false and menu.SetEntryEnabled ~= nil then
		menu:SetEntryEnabled(tkdRow, false)
	end
	-- What the last self-check found not to work (safe_trainer/checks.lua):
	-- greyed out, not left out.
	if Checks ~= nil and Checks.Status ~= nil and menu.SetEntryEnabled ~= nil then
		for _, rc in ipairs({ { fovRow, "chk_fp_fov" }, { aimFovRow, "chk_fp_fov" }, { carFovRow, "chk_fp_anchor_fov" } }) do
			if Checks.Status(rc[2]) == "fail" then
				menu:SetEntryEnabled(rc[1], false)
			end
		end
	end

	menu:AddSection("Service")
	local chk = menu:AddButton("Check the game camera config", function()
		if not FpsLikeEnabled then
			toast("First-person: turn the view on, then check")
			return
		end
		gcfg.installed = nil
		gcfg.loud = true
		restartContext()
	end)
	menu:Decorate(chk, "First person inside the game's own camera (the camera patch, IRIDIUM\\fp_camera): native mouse, walking and aiming", 0xE9D9)
	local rc = menu:AddButton("Recalibrate the camera", function()
		recalibrate()
		toast("First-person: calibration cleared")
	end)
	menu:Decorate(rc, "Tests again how walking follows the view and how the game camera moves (stand still ~4 s)", 0xE81C)
	local st = menu:AddButton("Write camera state to the log", writeState)
	menu:Decorate(st, "ScriptHook.log: bones, camera, calibration", 0xE946)

	menu:OnUpdate(function()
		menu:SetChecked(tog, FpsLikeEnabled)
		menu:SetChecked(body, Cfg.body)
		menu:SetChecked(turnRow, Cfg.turn)
		menu:SetChecked(veh, Cfg.vehicles)
	end)

	return menu
end

-- A reload drops the old state; release whatever it held on the camera.
if wasOn then
	pcall(function()
		local cam = game.cameramanager:GetPlayerCamera()
		cam:ScriptForcedOffsetStop()
		cam:ScriptUnlock(1)
		cam:ScriptForcedFOVStop()
	end)
	pcall(function()
		game.game:GetActivePlayer():ShowModel(true)
	end)
	-- the hat the old state may have hidden (the reload's FpsLikeDisable shows it first)
	if getSetting("FpHideHat") ~= "0" then
		pcall(function()
			game.game:GetActivePlayer():ShowHat(true)
		end)
	end
end

-- For the self-check (safe_trainer/checks.lua): each try puts back what it
-- changed. The slow ones wait with Sleep, so they run in the check's thread,
-- and keep the tick off the camera meanwhile (forcedFov.probe).
FpsLikeProbe = {}

-- An angle a camera reports, in degrees (a small number is radians); nil if none.
function FpsLikeProbe.readFov(obj)
	for _, m in ipairs({ "GetFOVDeg", "GetFOV", "GetFov" }) do
		local ok, v = pcall(function()
			return obj[m](obj)
		end)
		if ok and type(v) == "number" then
			return v > 3.5 and v or v * 180 / math.pi
		end
	end
	return nil
end

-- ok, the bones the eyes came from, their height above the root, in a car
function FpsLikeProbe.eyes()
	local p = getPlayer()
	if p == nil then
		return false
	end
	local veh = vehicleOf(p)
	local root = readVec(function()
		return (veh or p):GetPos()
	end)
	local e = root and rawEye(p, root)
	if e == nil or eyeSource == nil then
		return false
	end
	return true, eyeSource.a .. (eyeSource.b and ("/" .. eyeSource.b) or ""), e.z - root.z, veh ~= nil
end

-- ok (nil: the head camera holds the picture, an offset cannot show), metres moved
function FpsLikeProbe.offset()
	local cam = getCam()
	local p0 = cam and readVec(function()
		return cam:GetPos()
	end)
	if p0 == nil then
		return false, 0
	end
	if locked then
		return nil, 0
	end
	forcedFov.probe = true
	for _ = 1, 12 do
		applyOffset(cam, vec(0, 0, 0.3))
		Sleep(30)
	end
	local p1 = readVec(function()
		return cam:GetPos()
	end)
	stopOffset(cam)
	gcfg.crouchOn = false
	forcedFov.probe = false
	local moved = p1 and p1.z - p0.z or 0
	return moved > 0.1, moved
end

-- ok (nil: the camera reports no angle), before, asked, after. The angle may be
-- reported another way than it is asked (horizontal), so a move toward the
-- asked one counts.
function FpsLikeProbe.fov()
	local cam = getCam()
	local before = cam and FpsLikeProbe.readFov(cam)
	if before == nil then
		return nil
	end
	local want = before > 55 and 40 or 75
	forcedFov.probe = true
	pcall(function()
		local h = hashId()
		cam:ScriptForcedFOVStart(h, h, 0.05, 0.05, want, 100000, true, true)
	end)
	Sleep(500)
	local after = FpsLikeProbe.readFov(cam)
	pcall(function()
		cam:ScriptForcedFOVStop()
	end)
	local had = forcedFov.now
	forcedFov.now = false
	forcedFov.probe = false
	if had then
		setFov(cam, had, 0.05)
	end
	return after ~= nil and (want - before) * (after - before) > 0 and math.abs(after - before) > 3, before, want, after
end

-- ok (nil: no angle to set on the head camera's anchor), before, asked, after (degrees)
function FpsLikeProbe.anchorFov()
	if not anchorReady() then
		return nil
	end
	local comp = nil
	pcall(function()
		comp = anchor:GetComponent("C_CameraComponent")
	end)
	local before = comp and FpsLikeProbe.readFov(comp)
	if before == nil then
		return nil
	end
	local want = before > 75 and 60 or 90
	pcall(function()
		comp:SetFOV(want * math.pi / 180)
	end)
	local after = FpsLikeProbe.readFov(comp)
	pcall(function()
		comp:SetFOV(before * math.pi / 180)
	end)
	return after ~= nil and math.abs(after - want) < 1, before, want, after
end

-- true / false: the game camera config installed (nil until looked at on foot)
function FpsLikeProbe.config()
	return gcfg.installed
end

-- first person while shooting from a car switched off this session; it was seen to work
function FpsLikeProbe.carShoot()
	return car.shootOff == true, car.aim ~= nil and car.aim.ok or nil
end

TrainerParts = TrainerParts or {}
TrainerParts.EyeCameraMenu = FpsLikeMenu
