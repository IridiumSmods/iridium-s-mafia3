-- Brawl style is reset like invulnerability — Maintain + menu sync. Finisher scenes need SDS edits.

local T = Hub.T
local say = Hub.say
local dbg = Hub.dbg
local activePlayer = Hub.activePlayer
local player = Hub.player
local chk = Hub.chk
local Icon = Hub.Icon

Brawl = {}

local brawlMode = false

local STYLE_ON = {
	"CONTROLSTYLE_CLOSECOMBAT",
	"CloseCombat",
}
local STYLE_OFF = {
	"CS_NORMAL",
	"CONTROLSTYLE_ALL",
}

function Brawl.IsOn()
	return brawlMode
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

local function styleLooksBrawl(s)
	if s == nil then
		return false
	end
	local u = string.upper(s)
	return u:find("CLOSE") ~= nil or u:find("COMBAT") ~= nil or u:find("MELEE") ~= nil
end

local function trySetStyleStr(p, name)
	if p == nil or type(name) ~= "string" then
		return false
	end
	local ok = pcall(function()
		p:SetControlStyleStr(name)
	end)
	if not ok then
		return false
	end
	return styleLooksBrawl(readStyleStr(p))
end

local function trySetStyleEnum(p, value)
	if p == nil or value == nil then
		return false
	end
	local ok = pcall(function()
		p:SetControlStyle(value)
	end)
	if not ok then
		return false
	end
	return styleLooksBrawl(readStyleStr(p))
end

local function enumStyleValues(on)
	if enums == nil then
		return nil
	end
	local e = enums.ControlStyle or enums.EControlStyle
	if e == nil then
		return nil
	end
	if not on then
		local off = {}
		if e.CONTROLSTYLE_ALL ~= nil then
			off[#off + 1] = e.CONTROLSTYLE_ALL
		end
		return off
	end
	local cc = e.CONTROLSTYLE_CLOSECOMBAT
	if cc == nil then
		return nil
	end
	local mov = e.CONTROLSTYLE_MOVEMENT
	local list = { cc }
	if mov ~= nil then
		list[#list + 1] = cc + mov
	end
	return list
end

local function applyBrawlStyle(p)
	if p == nil then
		return false
	end
	for _, name in ipairs(STYLE_ON) do
		if trySetStyleStr(p, name) then
			return true
		end
	end
	local nums = enumStyleValues(true)
	if nums ~= nil then
		for _, v in ipairs(nums) do
			if trySetStyleEnum(p, v) then
				return true
			end
		end
	end
	for _, name in ipairs(STYLE_ON) do
		pcall(function()
			p:SetControlStyleStr(name)
		end)
	end
	return styleLooksBrawl(readStyleStr(p))
end

local function applyNormalStyle(p)
	if p == nil then
		return false
	end
	for _, name in ipairs(STYLE_OFF) do
		local ok = pcall(function()
			p:SetControlStyleStr(name)
		end)
		if ok then
			local s = readStyleStr(p)
			if s == nil or not styleLooksBrawl(s) then
				return true
			end
		end
	end
	local nums = enumStyleValues(false)
	if nums ~= nil then
		for _, v in ipairs(nums) do
			if pcall(function()
				p:SetControlStyle(v)
			end) then
				local s = readStyleStr(p)
				if s == nil or not styleLooksBrawl(s) then
					return true
				end
			end
		end
	end
	return not styleLooksBrawl(readStyleStr(p))
end

local function afterBrawlApplied(p)
	pcall(function()
		p:SetMeleeGod(false)
	end)
end

function Brawl.Set(on, quiet)
	brawlMode = on == true
	local p = activePlayer()
	if p == nil then
		if not quiet and on then
			say(T("brawl_fail", "?"))
		elseif not quiet then
			say(T("brawl_off"))
		end
		return
	end
	if on then
		local ok = applyBrawlStyle(p)
		afterBrawlApplied(p)
		if quiet then
			return
		end
		local s = readStyleStr(p)
		if ok and styleLooksBrawl(s) then
			say(T("brawl_on_ok", s or "?"))
		elseif ok then
			say(T("brawl_on"))
		else
			say(T("brawl_fail", s or "?"))
			if dbg ~= nil then
				dbg("brawl apply failed, style=" .. tostring(s))
			end
		end
	else
		applyNormalStyle(p)
		if not quiet then
			say(T("brawl_off"))
		end
	end
end

function Brawl.Maintain(p, tick)
	if not brawlMode or p == nil then
		return
	end
	local s = readStyleStr(p)
	if styleLooksBrawl(s) then
		return
	end
	if applyBrawlStyle(p) then
		afterBrawlApplied(p)
	elseif dbg ~= nil and tick ~= nil and tick % 120 == 0 then
		dbg("brawl maintain: still not close combat (" .. tostring(s) .. ")")
	end
end

function Brawl.Toggle()
	local p = player()
	if p == nil then
		return
	end
	Brawl.Set(not brawlMode)
end

function Brawl.AttachPlayerMenu(menu)
	menu:AddSection(T("grp_brawl"))
	local br = chk(menu, "brawl_mode", function()
		local p = player()
		if p == nil then
			return
		end
		Brawl.Set(not brawlMode)
	end, Icon.badge, "brawl_mode_d")
	return br
end
