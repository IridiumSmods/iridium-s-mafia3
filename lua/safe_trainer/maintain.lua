-- Re-applies player toggles the game resets every frame (sprint, brawl, high FX).
-- Called from trainer/main.lua OnTick only — not from the hub menu loop.

Maintain = {}

local tick = 0
local highActive = false

function Maintain.SetHighActive(on)
	highActive = on == true
end

function Maintain.IsHighActive()
	return highActive
end

local function tryDrunk(p, on)
	if on then
		if pcall(function() p:SetDrunk(true) end) then
			return true
		end
		if pcall(function() p:SetDrunk(1) end) then
			return true
		end
		return pcall(function() p:SetDrunk(1.0) end)
	end
	if pcall(function() p:SetDrunk(false) end) then
		return true
	end
	return pcall(function() p:SetDrunk(0) end)
end

function Maintain.ClearHighFx(p)
	if p == nil then
		return
	end
	tryDrunk(p, false)
	pcall(function()
		local cam = game.cameramanager:GetPlayerCamera()
		cam:SetShakeOverrideEnabled(false)
	end)
end

function Maintain.ApplyHighFx(p)
	if p == nil then
		return
	end
	tryDrunk(p, true)
	pcall(function()
		local cam = game.cameramanager:GetPlayerCamera()
		cam:SetShakeOverrideEnabled(true)
		cam:SetShakeOverrideSineWaveEasyParams(1.35, 2.8, Math:newVector(0, 0, 0), 0.22, 0.16, 0.11)
	end)
end

local function playerForTick()
	if Hub ~= nil and Hub.activePlayer ~= nil then
		return Hub.activePlayer()
	end
	local ok, p = pcall(function()
		return game.game:GetActivePlayer()
	end)
	if ok then
		return p
	end
	return nil
end

function Maintain.OnTick()
	tick = tick + 1
	local p = playerForTick()
	if p == nil then
		return
	end
	local okOwner, owner = pcall(function()
		return p:GetOwner()
	end)
	if okOwner and owner ~= nil then
		return
	end
	if Mobility ~= nil and Mobility.Maintain ~= nil then
		Mobility.Maintain(p, tick)
	end
	if StreetFight ~= nil and StreetFight.IsOn ~= nil and StreetFight.IsOn() and StreetFight.Maintain ~= nil then
		StreetFight.Maintain(p, tick)
	elseif Brawl ~= nil and Brawl.Maintain ~= nil then
		Brawl.Maintain(p, tick)
	end
	if highActive and tick % 8 == 0 then
		Maintain.ApplyHighFx(p)
	end
end
