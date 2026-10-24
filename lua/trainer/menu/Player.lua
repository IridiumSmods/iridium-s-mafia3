include("menu/Spawnprofiles.lua")
include("menu/HashDatabase.lua")
include("menu/Utils.lua")

---------
-- God --
---------
local function PlayerHasGod()
    if getp() ~= nil then
        return getp().invulnerability
    end

    return false
end

local function PlayerSetGod(on)
	if on then
        getp():SetDemigod(true)
        getp():EnableInjury(false)
		getp():SetMaxHealth()
        getp().invulnerability = true
	else
		getp():SetDemigod(false)
        getp():EnableInjury(true)
        getp().invulnerability = false
	end
end

------------------
-- Player Model --
------------------
local function ChangeModel(menu, text, name)
    if getp() == nil then
        return false
    end
    local player = getp()
	player:SwitchOverridePlayerSpawnProfile(name)
	player:SwitchDefaultPlayerSpawnProfile(name)
	player:SwitchPlayerSpawnProfile(name)
end

local function ChangeModelMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Change Model")
	menu:AddSearch("Search", "Start typing to filter")

	for k,v in pairsByKeys(M3DESpawnprofiles) do
		menu:AddButton(k, v, ChangeModel)
	end

	return menu
end

----------------------------
-- Player Model Visiblity --
----------------------------
local function ToggleModel()
	if getp():IsModelVisible() == true then
		getp():ShowModel(false)
	elseif getp():IsModelVisible() == false then
		getp():ShowModel(true)
	end
end

--------------------
-- Player Physics --
--------------------
local function CheckPhysState()
	local CurrPhysics = getp():GetPhysState()
	if CurrPhysics == 0 then
		return true
	elseif CurrPhysics == 2 then
		return false
	elseif CurrPhysics == 1 then
		return false
	else
		return true
	end
end

local function TogglePhysics()
    if CheckPhysState() == true then
		getp():SetPhysState(enums.PhysicsState.DISABLED)
	elseif CheckPhysState() == false then
		getp():SetPhysState(enums.PhysicsState.DYNAMIC)
	end
end

------------------
-- Unlock Input --
------------------
local function RestoreInput()
	getp():DisableInput("", false, unpack(data_input_presets.input_presets.safehouse.inputs_to_disable))
end

-------------------
-- Lock Controls --
-------------------
local function LockControls()
	if getp():AreControlsLocked() == false then
		getp():LockControls(true)
	elseif getp():AreControlsLocked() == true then
		getp():LockControls(false)
	end
end

----------------------
-- Cloth Simulation --
----------------------
local function ClothSimulation()
	local IsSimulated = getp():IsClothSimulated()
	if IsSimulated ==  true then
		getp():SimulateCloth(false, false)
	elseif IsSimulated == false then
		getp():SimulateCloth(true, true)
	end
end

----------------------
-- Inventory items --
----------------------
local function GiveRelays(count)
	local total_relay_count = DatastoreGet("player_relay_collectible_count", "CheckPointData")
	if not total_relay_count then
		total_relay_count = count
	else
		total_relay_count = total_relay_count + count
	end
	DatastoreSet("player_relay_collectible_count", total_relay_count, "CheckPointData")
	game.hud:SetNumRelayComponents(total_relay_count)
end

local function GivePlayerMoney()
	gamestructure:GetPlayerMoneyHub():AddMoney(tonumber(5000), script_enums.GameStructure.PlayerMoneyContainer.Wallet)
end

local function GivePlayerRelays()
	GiveRelays(5)
end

-----------
-- Other --
-----------
local function TeleportIntoSightVehicle()
	StartThread(function ()
		local player = getp()
		local veh = game.physics:GetActorInScreenCenter()
		if veh ~= nil then
			local currentveh = player:GetOwner()
			if currentveh ~= nil then
				player:LockControls(true)
				Wait(player:GetOffVehicle(false, false))
				player:LockControls(false)
			end
			passengers = veh:GetPassengers()
			if passengers ~= nil then
				passengers:GetOffVehicle(false, false)
				passengers:Deactivate()
				veh:SetEngineOn(true, true)
				player:LockControls(true)
				Wait(player:GetOnVehicle(veh, 1, false, "WALK"))
				player:LockControls(false)
			else
				veh:SetEngineOn(true, true)
				player:LockControls(true)
				Wait(player:GetOnVehicle(veh, 1, false, "WALK"))
				player:LockControls(false)
			end
			veh:SetDelivered(true)
			currentveh = player:GetOwner()
		end
	end)
end

------------
-- Noclip --
------------
local NoclipSpeed = 0.2
local VehicleNoclipSpeed = 0.3

function StartNoclipThread()
	StartThread(function()
		local player = getp()
		
		while DatastoreGet("Noclip") do
			local key_pressed = player:GetMoveDir(true)
			local cam_dir = game.cameramanager:GetPlayerCamera():GetDir()
			local owner = player:GetOwner()
			
			if owner == nil then
				local player_pos = player:GetPos()
				player:SetPhysState(enums.PhysicsState.DISABLED)
				if key_pressed.y > 0 then
					-- W is pressed
					player_pos.x = player_pos.x + (cam_dir.x * NoclipSpeed)
					player_pos.y = player_pos.y + (cam_dir.y * NoclipSpeed)
					player_pos.z = player_pos.z + (cam_dir.z * NoclipSpeed)
					player:SetPos(player_pos)
				elseif key_pressed.y < 0 then
					-- S is pressed
					player_pos.x = player_pos.x - (cam_dir.x * NoclipSpeed)
					player_pos.y = player_pos.y - (cam_dir.y * NoclipSpeed)
					player_pos.z = player_pos.z - (cam_dir.z * NoclipSpeed)
					player:SetPos(player_pos)
				end
				if key_pressed.x > 0 then
					-- D is pressed
					player_pos.x = player_pos.x + (cam_dir.y * NoclipSpeed)
					player_pos.y = player_pos.y - (cam_dir.x * NoclipSpeed)
					player:SetPos(player_pos)
				elseif key_pressed.x < 0 then
					-- A is pressed
					player_pos.x = player_pos.x - (cam_dir.y * NoclipSpeed)
					player_pos.y = player_pos.y + (cam_dir.x * NoclipSpeed)
					player:SetPos(player_pos)
				end
			else
				owner:Lock()
				local owner_pos = owner:GetPos()
				if key_pressed.y > 0 then
					-- W is pressed
					owner_pos.x = owner_pos.x + (cam_dir.x * VehicleNoclipSpeed)
					owner_pos.y = owner_pos.y + (cam_dir.y * VehicleNoclipSpeed)
					owner_pos.z = owner_pos.z + (cam_dir.z * VehicleNoclipSpeed)
					owner:SetPos(owner_pos)
				elseif key_pressed.y < 0 then
					-- S is pressed
					owner_pos.x = owner_pos.x - (cam_dir.x * VehicleNoclipSpeed)
					owner_pos.y = owner_pos.y - (cam_dir.y * VehicleNoclipSpeed)
					owner_pos.z = owner_pos.z - (cam_dir.z * VehicleNoclipSpeed)
					owner:SetPos(owner_pos)
				end
				if key_pressed.x > 0 then
					-- D is pressed
					owner_pos.x = owner_pos.x + (cam_dir.y * VehicleNoclipSpeed)
					owner_pos.y = owner_pos.y - (cam_dir.x * VehicleNoclipSpeed)
					owner:SetPos(owner_pos)
				elseif key_pressed.x < 0 then
					-- A is pressed
					owner_pos.x = owner_pos.x - (cam_dir.y * VehicleNoclipSpeed)
					owner_pos.y = owner_pos.y + (cam_dir.x * VehicleNoclipSpeed)
					owner:SetPos(owner_pos)
				end
			end
			
			Sleep(1)
		end
		
		if player:GetOwner() == nil then
			player:SetPhysState(enums.PhysicsState.DYNAMIC)
		else
			player:GetOwner():Unlock()
		end
	end)
end

function ToggleNoclip()
	if DatastoreGet("Noclip") == false or DatastoreGet("Noclip") == nil then
		DatastoreSet("Noclip", true)
		StartNoclipThread()
	elseif DatastoreGet("Noclip") then
		DatastoreSet("Noclip", false)
	end
end

-----------------
-- Player Info --
-----------------
local function GetSpawnprofileHash()
	local player = getp()
	local component = player:GetComponent("C_TagComponent")
	local Container = component.m_TagContainer
	local ContainerTbl = table.c2lua(Container)
	for k,v in ipairs(ContainerTbl) do
		if HashDatabase[tostring(v.First.m_HashName)] == "Spawnprofile" then
			local SecondTbl = table.c2lua(v.Second.m_TagValues)
			return tostring(SecondTbl[1].m_Value.m_HashName)
		end
	end
	
	return ""
end

local allhashes = {}

local function TagsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Player Tags")
	local player = getp()
	local component = player:GetComponent("C_TagComponent")
	local Container = component.m_TagContainer
	local ContainerTbl = table.c2lua(Container)
	local i = 1
	allhashes = {}
	for k,v in ipairs(ContainerTbl) do
		--getp():RemoveTag(tostring(v.First.m_HashName))
		if HashDatabase[tostring(v.First.m_HashName)] == nil then
			menu:AddButton(string.format("%03d", i) .. ". " .. tostring(v.First.m_HashName),PrintAllHashes)
			table.insert(allhashes, string.format("%03d", i) .. ". " .. tostring(v.First.m_HashName))
		else
			menu:AddButton(string.format("%03d", i) .. ". " .. HashDatabase[tostring(v.First.m_HashName)],PrintAllHashes)
			table.insert(allhashes, string.format("%03d", i) .. ". " .. HashDatabase[tostring(v.First.m_HashName)])
		end
		local SecondTbl = table.c2lua(v.Second.m_TagValues)
		local ii = 1
		for k,v in pairs(SecondTbl) do
			if HashDatabase[tostring(v.m_Value.m_HashName)] == nil then
				menu:AddButton(string.format("%03d", i) .. ". - " .. ii .. ". " .. tostring(v.m_Value.m_HashName),PrintAllHashes)
				table.insert(allhashes, "     " .. tostring(v.m_Value.m_HashName))
			else
				menu:AddButton(string.format("%03d", i) .. ". - " .. ii .. ". " .. HashDatabase[tostring(v.m_Value.m_HashName)],PrintAllHashes)
				table.insert(allhashes, "     " .. HashDatabase[tostring(v.m_Value.m_HashName)])
			end
			ii = ii + 1
		end
		table.insert(allhashes, " ")
		i = i + 1
	end
	return menu
end

local function PlayerInfoMenu()
	local SpawnprofileHash = GetSpawnprofileHash()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Player Info")
	local Pos =  getp():GetPos()
	local Dir =  getp():GetDir()
	local rot = getp():GetRot()
	local BigSlotWepType = type(getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.BIG_WEP))
	local BigSlotWep = ""
	local SmallSlotWepType = type(getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.SMAL_WEP))
	local SmallSlotWep = ""
	if BigSlotWepType == "function" then
		BigSlotWep = "None"
	else
		BigSlotWep = getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.BIG_WEP)
	end
	if SmallSlotWepType == "function" then
		SmallSlotWep = "None"
	else
		SmallSlotWep = getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.SMAL_WEP)
	end
	local PositionXMenu = menu:AddButton("Position: " .. "X: " .. tostring(Pos.x), function()
		print("Position: " .. "X: " .. tostring(Pos.x) .. " Y: " .. tostring(Pos.y) .. " Z: " .. tostring(Pos.z))
	end)
	local PositionYMenu = menu:AddButton("Position: " .. "Y: " .. tostring(Pos.y), function()
		print("Position: " .. "X: " .. tostring(Pos.x) .. " Y: " .. tostring(Pos.y) .. " Z: " .. tostring(Pos.z))
	end)
	local PositionZMenu = menu:AddButton("Position: " .. "Z: " .. tostring(Pos.z), function()
		print("Position: " .. "X: " .. tostring(Pos.x) .. " Y: " .. tostring(Pos.y) .. " Z: " .. tostring(Pos.z))
	end)
	local DirectionXMenu = menu:AddButton("Direction: " .. "X: " .. tostring(Dir.x), function()
		print("Direction: " .. "X: " .. tostring(Dir.x) .. " Y: " .. tostring(Dir.y) .. " Z: " .. tostring(Dir.z))
	end)
	local DirectionYMenu = menu:AddButton("Direction: " .. "Y: " .. tostring(Dir.y), function()
		print("Direction: " .. "X: " .. tostring(Dir.x) .. " Y: " .. tostring(Dir.y) .. " Z: " .. tostring(Dir.z))
	end)
	local DirectionZMenu = menu:AddButton("Direction: " .. "Z: " .. tostring(Dir.z), function()
		print("Direction: " .. "X: " .. tostring(Dir.x) .. " Y: " .. tostring(Dir.y) .. " Z: " .. tostring(Dir.z))
	end)
	local RotXMenu = menu:AddButton("Rotation: X: " .. tostring(rot.v.x), function()
		print("Rotation: " .. "X: " .. tostring(rot.v.x) .. " Y: " .. tostring(rot.v.y) .. " Z: " .. tostring(rot.v.z) .. " W: " .. tostring(rot.s))
	end)
	local RotYMenu = menu:AddButton("Rotation: Y: " .. tostring(rot.v.y), function()
		print("Rotation: " .. "X: " .. tostring(rot.v.x) .. " Y: " .. tostring(rot.v.y) .. " Z: " .. tostring(rot.v.z) .. " W: " .. tostring(rot.s))
	end)
	local RotZMenu = menu:AddButton("Rotation: Z: " .. tostring(rot.v.z), function()
		print("Rotation: " .. "X: " .. tostring(rot.v.x) .. " Y: " .. tostring(rot.v.y) .. " Z: " .. tostring(rot.v.z) .. " W: " .. tostring(rot.s))
	end)
	local RotWMenu = menu:AddButton("Rotation: W: " .. tostring(rot.s), function()
		print("Rotation: " .. "X: " .. tostring(rot.v.x) .. " Y: " .. tostring(rot.v.y) .. " Z: " .. tostring(rot.v.z) .. " W: " .. tostring(rot.s))
	end)
	local Owner = menu:AddButton("Owner: " .. tostring(getp():GetOwner()))
	--for k,v in pairsByKeys(VoiceIDs) do
	--	if tostring(getp():GetVoice()) == v then
	--		menu:AddButton("Voice: " .. k)
	--	end
	--end
	menu:AddButton("Voice Hash: " .. tostring(getp():GetVoice()), function()
		print("Voice Hash: " .. tostring(getp():GetVoice()))
	end)
	menu:AddButton("Spawnprofile: " .. SpawnprofileHash, function()
		print("Spawnprofile: " .. SpawnprofileHash)
	end)
	local BigWep = menu:AddButton("Weapon In Big Slot: " .. BigSlotWep, function()
		print("Weapon In Big Slot: " .. BigSlotWep)
	end)
	local SmallWep = menu:AddButton("Weapon In Small Slot: " .. SmallSlotWep, function()
		print("Weapon In Small Slot: " .. SmallSlotWep)
	end)
	local HasGodmodeMenu = menu:AddButton("Godmode: " .. tostring(PlayerHasGod()))
	--local NoclipEnabledMenu = menu:AddButton("Noclip: " .. tostring(ScriptHook.HasLocalPlayerNoclip()))
	local ControlLocked = menu:AddButton("Controls Locked: " .. tostring(getp():AreControlsLocked()))
	local ModelVisible = menu:AddButton("Model Visibile: " .. tostring(getp():IsModelVisible()))
	local ClothSimulated = menu:AddButton("Cloth Simulated: " .. tostring(getp():IsClothSimulated()))
	local PhysicsActiveMenu = menu:AddButton("Physics Active: " .. tostring(CheckPhysState()))
	menu:AddButton("Player Tags", TagsMenu)
	menu:OnUpdate(function()
		BigSlotWepType = type(getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.BIG_WEP))
		if BigSlotWepType == "function" then
			BigSlotWep = "None"
		else
			BigSlotWep = getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.BIG_WEP)
		end
		SmallSlotWepType = type(getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.SMAL_WEP))
		if SmallSlotWepType == "function" then
			SmallSlotWep = "None"
		else
			SmallSlotWep = getp():GetInventoryWeaponsInSlotType(enums.InventorySlotType.SMAL_WEP)
		end
		Pos =  getp():GetPos()
		Dir =  getp():GetDir()
		rot = getp():GetRot()
		menu:SetEntryText(PositionXMenu, "Position: " .. "X: " .. tostring(Pos.x))
		menu:SetEntryText(PositionYMenu, "Position: " .. "Y: " .. tostring(Pos.y))
		menu:SetEntryText(PositionZMenu, "Position: " .. "Z: " .. tostring(Pos.z))
		menu:SetEntryText(DirectionXMenu, "Direction: " .. "X: " .. tostring(Dir.x))
		menu:SetEntryText(DirectionYMenu, "Direction: " .. "Y: " .. tostring(Dir.y))
		menu:SetEntryText(DirectionZMenu, "Direction: " .. "Z: " .. tostring(Dir.z))
		menu:SetEntryText(HasGodmodeMenu, "Godmode: " .. tostring(PlayerHasGod()))
		--menu:SetEntryText(NoclipEnabledMenu, "Noclip: " .. tostring(ScriptHook.HasLocalPlayerNoclip()))
		menu:SetEntryText(ControlLocked, "Controls Locked: " .. tostring(getp():AreControlsLocked()))
		menu:SetEntryText(ModelVisible, "Model Visibile: " .. tostring(getp():IsModelVisible()))
		menu:SetEntryText(ClothSimulated, "Cloth Simulated: " .. tostring(getp():IsClothSimulated()))
		menu:SetEntryText(PhysicsActiveMenu, "Physics Active: " .. tostring(CheckPhysState()))
		menu:SetEntryText(Owner, "Owner: " .. tostring(getp():GetOwner()))
		menu:SetEntryText(BigWep, "Weapon In Big Slot: " .. BigSlotWep)
		menu:SetEntryText(SmallWep, "Weapon In Small Slot: " .. SmallSlotWep)
		menu:SetEntryText(RotXMenu, "Rotation: X: " .. tostring(rot.v.x))
		menu:SetEntryText(RotYMenu, "Rotation: Y: " .. tostring(rot.v.y))
		menu:SetEntryText(RotZMenu, "Rotation: Z: " .. tostring(rot.v.z))
		menu:SetEntryText(RotWMenu, "Rotation: W: " .. tostring(rot.s))
	end)
	return menu
end

local function NoclipMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Noclip")

	local NoclipCheck = menu:AddCheckbox("Noclip", ToggleNoclip)

	-- Noclip Speed
	local speedIdx = menu:AddList("Noclip Speed", function(_,_,_,_, idx, speed)
		NoclipSpeed = speed / 10
	end)

	for _,v in pairs({ 1, 2, 3, 5, 10, 15, 20, 25, 50, 75, 100 }) do
		menu:AddListEntry(speedIdx, tostring(v))
	end
	
	menu:SelectListEntryByValue(speedIdx, tostring(NoclipSpeed * 10))

	-- Vehicle Noclip Speed
	local vehSpeedIdx = menu:AddList("Vehicle Noclip Speed", function(_,_,_,_, idx, speed)
		VehicleNoclipSpeed = speed / 10
	end)

	for _,v in pairs({ 1, 2, 3, 5, 10, 15, 20, 25, 50, 75, 100 }) do
		menu:AddListEntry(vehSpeedIdx, tostring(v))
	end
	
	menu:SelectListEntryByValue(vehSpeedIdx, tostring(VehicleNoclipSpeed * 10))

	-- Update
	menu:OnUpdate(function()
		if getp() ~= nil then
			menu:SetChecked(NoclipCheck, DatastoreGet("Noclip") == true)
		end
	end)

	return menu
end

local function PlayerMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Player")

	-- Items
	menu:AddButton("Noclip", NoclipMenu)

	local godIdx = menu:AddCheckbox("God Mode", "Toggle invincibility", function()
		PlayerSetGod(not PlayerHasGod())
	end)
	
	local ControlLock = menu:AddCheckbox("Lock Controls", LockControls)
	local model_vis = menu:AddCheckbox("Toggle Model Visibility", ToggleModel)
	local ClothSim = menu:AddCheckbox("Toggle Cloth Simulation", ClothSimulation)
	local PhysicsActive = menu:AddCheckbox("Toggle Physics", TogglePhysics)
	menu:AddButton("Change Model", ChangeModelMenu)
	menu:AddButton("Unlock Input", RestoreInput)
	--menu:AddButton("Set Into Closest Vehicle", TeleportIntoClosestVehicle)
	menu:AddButton("Give Money", GivePlayerMoney)
	menu:AddButton("Give Relays", GivePlayerRelays)
	menu:AddButton("Teleport into aimed vehicle", TeleportIntoSightVehicle)
	menu:AddButton("Player Info", PlayerInfoMenu)

	-- Update
	menu:OnUpdate(function()
		if getp() ~= nil then
			menu:SetChecked(godIdx, PlayerHasGod())
			menu:SetChecked(ControlLock, getp():AreControlsLocked())
			menu:SetChecked(model_vis, getp():IsModelVisible())
			menu:SetChecked(ClothSim, getp():IsClothSimulated())
			menu:SetChecked(PhysicsActive, CheckPhysState())
		end
	end)

	return menu
end

-- The safe_trainer hub owns the root menu and places these where they belong.
TrainerParts = TrainerParts or {}
TrainerParts.ChangeModelMenu = ChangeModelMenu
TrainerParts.NoclipMenu = NoclipMenu
TrainerParts.PlayerInfoMenu = PlayerInfoMenu
TrainerParts.TeleportIntoAimedVehicle = TeleportIntoSightVehicle
TrainerParts.RestoreInput = RestoreInput
TrainerParts.GiveMoney = GivePlayerMoney
TrainerParts.GiveRelays = GivePlayerRelays
TrainerParts.ToggleControlsLock = LockControls
TrainerParts.ToggleModelVisibility = ToggleModel
TrainerParts.ToggleCloth = ClothSimulation
TrainerParts.TogglePhysics = TogglePhysics
TrainerParts.PhysicsActive = CheckPhysState