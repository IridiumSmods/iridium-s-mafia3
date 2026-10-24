include("menu/VehicleModelIDs.lua")
include("menu/ColorIDs.lua")
include("utils/utils.lua")

-----------
-- Utils --
-----------
local affectedveh = nil
local VehExplosionEnabled = false
local VehiclePrimaryColor = "1"
local VehicleSecondaryColor = "1"
local TirePrimaryColor = "1"
local TireSecondaryColor = "1"
local WindowTintColor = "1"
local VehicleLightState = false
local VehicleSirenState = false
local HandlingMult = "0"
local EngineStateValue = false
local DirtLevel = "0"
local RustLevel = "0"
local VehicleSPZText = "000000"
local DespawnImmunityValue = false
local DamageImmunityValue = "0"
local CarTuneValue = false
local FrontWheels = "wheel_civ04"
local RearWheels = "wheel_civ04"
local SteeringPlayAmmount = "0"
local SteeringOffsetValue = "0"
local WindowFrontLeft = false
local WindowFrontRight = false
local WindowBackLeft = false
local WindowBackRight = false
local TeleportEnabled = true
local RadioState = false
local BulletProofTiresValue = true
local trailer = {}
local HoodOpen = false
local TrunkOpen = false
local PrimaryColors = {0,0,0,0}
local SecondaryColors = {0,0,0,0}
local WindowTint = {0,0,0,20}
local ChromeValue = 0
local GlossValue = 100

local function IsPlayerInVehicle()
    if getp() == nil then
        return false
    end

    if getp():GetOwner() == nil then
        return false
    end

    return true
end

local function IsVehicleEngineRunning()
	if affectedveh == nil then
		return false
	end

	return affectedveh:IsEngineOn()
end

local function IsVehicleExplosiveDisabled()
	if affectedveh == nil then
		return false
	end

	return affectedveh:IsDisableExplosion()
end

local function SetAffectedVeh(value)
	affectedveh = value
end

local function CheckVehWindowAmmount()
	local Count = affectedveh:GetSeatCount()
	if tonumber(Count) < 3 then
		return false
	end
	
	if tonumber(Count) == 4 then
		return true
	end
end

local function CheckSightVehicle()
	local sight_vehicle = game.physics:GetActorInScreenCenter()
	if sight_vehicle ~= nil then
		local veh_type = sight_vehicle:GetType()
		if veh_type == enums.EntityType.CAR then
			return sight_vehicle
		end
	end
end

----------------
-- Car Colors --
----------------
local function StringSplit(tbl, inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(tbl, str)
    end
	if tbl[1] == nil then
		tbl[1] = 0
	end
	if tbl[2] == nil then
		tbl[2] = 0
	end
	if tbl[3] == nil then
		tbl[3] = 0
	end
	if tbl[4] == nil then
		tbl[4] = 20
	end
end

local function ChoosePrimaryColor()
	UI.SimpleTextInput("Enter RGB values separated by spaces. Eg: 255 255 255", function(success, text)
		if success then
			PrimaryColors = {}
			StringSplit(PrimaryColors, text)
			if affectedveh ~= nil then
				affectedveh:OverrideMaterialParam("C060", (PrimaryColors[1]/255), (PrimaryColors[2]/255), (PrimaryColors[3]/255), 1)
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function ChooseSecondaryColor()
	UI.SimpleTextInput("Enter RGB values separated by spaces. Eg: 255 255 255", function(success, text)
		if success then
			SecondaryColors = {}
			StringSplit(SecondaryColors, text)
			if affectedveh ~= nil then
				affectedveh:OverrideMaterialParam("C061", (SecondaryColors[1]/255), (SecondaryColors[2]/255), (SecondaryColors[3]/255), 1)
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function ChooseWindowTint()
	UI.SimpleTextInput("Enter RGBA values separated by spaces. Eg: 255 255 255 255", function(success, text)
		if success then
			WindowTint = {}
			StringSplit(WindowTint, text)
			if affectedveh ~= nil then
				affectedveh:OverrideMaterialParam("C005", (WindowTint[1]/255), (WindowTint[2]/255), (WindowTint[3]/255), (WindowTint[4]/255))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function ChooseChromeAmmount()
	UI.SimpleTextInput("Enter chrome value 0-100", function(success, text)
		if success then
			if text == nil then
				ChromeValue = 0
			else
				ChromeValue = text
			end
			if affectedveh ~= nil then
				affectedveh:OverrideMaterialParam("D112", 1, (ChromeValue/100))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function ChooseGlossAmmount()
	UI.SimpleTextInput("Enter glossiness value 0-100", function(success, text)
		if success then
			if text == nil then
				GlossValue = 100
			else
				GlossValue = text
			end
			if affectedveh ~= nil then
				affectedveh:OverrideMaterialParam("D370", 0, (GlossValue/100))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

-------------------
-- Spawn Vehicle --
-------------------
local function SpawnBoat(name)
    StartThread(function ()
		SpawnPos = getp():GetPos()
		SpawnDir = game.cameramanager:GetPlayerCamera():GetDir()
		SpawnPos.x = SpawnPos.x + (SpawnDir.x * 10)
		SpawnPos.y = SpawnPos.y + (SpawnDir.y * 10)
		SpawnPos.z = SpawnPos.z + 0.8
        local so, id = game.traffic:ObtainSpecificBoat(name)
        Wait(so)
        local so = game.traffic:SpawnBoat(id, SpawnPos, SpawnDir)
        Wait(so)
		boat = game.traffic:GetSpawnedEntity(id)
		getp():LockControls(true)
		Wait(getp():GetOnVehicle(boat, 1, false, "WALK"))
		getp():LockControls(false)
        return
    end)
end

local function SpawnTrailer(Vehicle)
	StartThread(function ()
        local so, id = game.traffic:ObtainSpecificCar(Vehicle)
        Wait(so)
		SpawnPos = game.game:GetActivePlayer():GetPos()
		SpawnDir = game.game:GetActivePlayer():GetDir()
		SpawnPos.x = SpawnPos.x + (SpawnDir.x * 6)
		SpawnPos.y = SpawnPos.y + (SpawnDir.y * 6)
		
        local so = game.traffic:SpawnCar(id, SpawnPos, SpawnDir)
        Wait(so)

        veh = game.traffic:GetSpawnedEntity(id)
		trailerGUID = veh:GetGUID()
		table.remove(trailer, 1)
		table.insert(trailer, trailerGUID)
		print(trailer[1])
		
        return
    end)
end

local function SpawnCar(Vehicle)
	StartThread(function ()
        local so, id = game.traffic:ObtainSpecificCar(Vehicle)
        Wait(so)
		SpawnPos = game.game:GetActivePlayer():GetPos()
		SpawnDir = game.game:GetActivePlayer():GetDir()
		SpawnPos.x = SpawnPos.x + (SpawnDir.x * 3)
		SpawnPos.y = SpawnPos.y + (SpawnDir.y * 3)
		
        local so = game.traffic:SpawnCar(id, SpawnPos, SpawnDir)
        Wait(so)

        veh = game.traffic:GetSpawnedEntity(id)
		getp():MakeCarOwnership(veh)

		getp():LockControls(true)
		Wait(getp():GetOnVehicle(veh, 1, false, "WALK"))
		getp():LockControls(false)
        return
    end)
end

local function ChooseVehicle(menu, text, name)
	if name == "box_trailer" then
		SpawnTrailer(name)
	else
		SpawnCar(name)
	end
end

local function ChooseBoat(menu, text, name)
	SpawnBoat(name)
end

------------------------
-- Vehicle Properties --
------------------------
local function ResetCarDamage()
	local Current_Speed = affectedveh:GetSpeedFloat()
	affectedveh:Repair(true)
	affectedveh:SetSpeed(Current_Speed)
end

local function ResetMotorDamage()
	local Current_Speed = affectedveh:GetSpeedFloat()
	affectedveh:SetMotorDamage(0)
	affectedveh:SetSpeed(Current_Speed)
end

local function SetVehicleFuelMenu()
	UI.SimpleTextInput("Enter ammount (0-100)", function(success, text)
		if success then
			affectedveh:SetActualFuel(text)
		else
			print("Dialog was canceled")
		end
	end)
end

local function AttachTrailer()
	getp():GetOwner():ConnectTrailer(game.entitywrapper:GetEntityByGUID(trailer[1]))
end

local function ChooseWindowTintColor(menu, text, name)
	WindowTintColor = name
	if affectedveh ~= nil then
		affectedveh:SetWindowTint(tonumber(WindowTintColor))
	end
end

local function ChangeFrontWheels(menu, text, name)
	FrontWheels = name
	if affectedveh ~= nil then
		affectedveh:SetWheel(1, FrontWheels)
	end
end

local function ChangeRearWheels(menu, text, name)
	RearWheels = name
	if affectedveh ~= nil then
		affectedveh:SetWheel(2, RearWheels)
	end
end

local function ChooseTirePrimaryColorMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Tire Primary Color")
	menu:AddSearch("Search", "Start typing to filter")

	for k,v in pairsByKeys(ColorIDs) do
		menu:AddButton(k, v, ChooseTirePrimaryColor)
	end

	return menu
end

local function ChooseTireSecondaryColorMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Tire Secondary Color")
	menu:AddSearch("Search", "Start typing to filter")

	for k,v in pairsByKeys(ColorIDs) do
		menu:AddButton(k, v, ChooseTireSecondaryColor)
	end

	return menu
end

local function ChooseWindowTintColorMenu(menu, text, name)
	local menu = UI.SimpleMenu()
	menu:SetTitle("Vehicle Window Tint")

	menu:AddButton("Color 1", "1", ChooseWindowTintColor)
	menu:AddButton("Color 2", "2", ChooseWindowTintColor)
	menu:AddButton("Color 3", "3", ChooseWindowTintColor)
	menu:AddButton("Color 4", "4", ChooseWindowTintColor)
	menu:AddButton("Color 5", "5", ChooseWindowTintColor)
	menu:AddButton("Color 6", "6", ChooseWindowTintColor)
	menu:AddButton("Color 7", "7", ChooseWindowTintColor)
	menu:AddButton("Color 8", "8", ChooseWindowTintColor)
	menu:AddButton("Color 9", "9", ChooseWindowTintColor)
	menu:AddButton("Color 10", "10", ChooseWindowTintColor)

	return menu
end

local function BulletProofTiresMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Bulletproof Tires Settings")
	menu:AddButton("Bulletproof ON", function()
		BulletProofTiresValue = true
		if affectedveh ~= nil then
			affectedveh:SetWheelsProtected(BulletProofTiresValue)
		end
	end)
	menu:AddButton("Bulletproof OFF", function()
		BulletProofTiresValue = false
		if affectedveh ~= nil then
			affectedveh:SetWheelsProtected(BulletProofTiresValue)
		end
	end)

	return menu
end

local function ChooseVehicleLightStateMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Vehicle Light State")
	menu:AddButton("Lights ON", function()
		VehicleLightState = true
		if affectedveh ~= nil then
			affectedveh:SetLightState(true, VehicleLightState)
		end
	end)
	menu:AddButton("Lights OFF", function()
		VehicleLightState = false
		if affectedveh ~= nil then
			affectedveh:SetLightState(true, VehicleLightState)
		end
	end)

	return menu
end

local function ChooseVehicleSirenStateMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Vehicle Siren State")
	menu:AddButton("Siren ON", function()
		VehicleSirenState = true
		if affectedveh ~= nil then
			affectedveh:SetSirenOn(VehicleSirenState)
		end
	end)
	menu:AddButton("Siren OFF", function()
		VehicleSirenState = false
		if affectedveh ~= nil then
			affectedveh:SetSirenOn(VehicleSirenState)
		end
	end)

	return menu
end

local function SetVehicleHandlingMenu()
	UI.SimpleTextInput("Enter multiplier value (Use only integers)", function(success, text)
		if success then
			HandlingMult = text
			if affectedveh ~= nil then
				affectedveh:SetSlowMotionAssist(tonumber(HandlingMult))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function SetVehicleRustLevelMenu()
	UI.SimpleTextInput("Enter rust ammount value (Use only integers)", function(success, text)
		if success then
			RustLevel = text
			if affectedveh ~= nil then
				affectedveh:SetRust(tonumber(RustLevel))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function SetVehicleDirtLevelMenu()
	UI.SimpleTextInput("Enter dirt ammount value (Use only integers)", function(success, text)
		if success then
			DirtLevel = text
			if affectedveh ~= nil then
				affectedveh:SetDirty(tonumber(DirtLevel))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function SetVehicleSPZTextMenu()
	UI.SimpleTextInput("Enter custom text (max 5 characters)", function(success, text)
		if success then
			VehicleSPZText = text
			if affectedveh ~= nil then
				affectedveh:SetSPZText(VehicleSPZText, true)
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function SetSteeringPlayMenu()
	UI.SimpleTextInput("Enter steering play value (use only integers)", function(success, text)
		if success then
			SteeringPlayAmmount = text
			if affectedveh ~= nil then
				affectedveh:SetSteeringPlay(tonumber(SteeringPlayAmmount))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function SetSteeringOffsetMenu()
	UI.SimpleTextInput("Enter steering offset value (between -45 and 45)", function(success, text)
		if success then
			SteeringOffsetValue = text
			if affectedveh ~= nil then
				affectedveh:SetAddSteer(tonumber(SteeringOffsetValue))
			end
		else
			print("Dialog was canceled")
		end
	end)
end

local function ChooseExplosionImmunityMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Vehicle Explosion Immunity Menu")
	menu:AddButton("Enable Explosion", function()
		VehExplosionEnabled = false
		if affectedveh ~= nil then
			affectedveh:DisableExplosion(VehExplosionEnabled)
		end
	end)
	menu:AddButton("Disable Explosion", function()
		VehExplosionEnabled = true
		if affectedveh ~= nil then
			affectedveh:DisableExplosion(VehExplosionEnabled)
		end
	end)

	return menu
end

local function ToggleEngineState()
	affectedveh:SetEngineOn(affectedveh:GetEngineRotations() == 0, affectedveh:GetEngineRotations() == 0)
end

local function ChooseDespawnImmunityMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Despawn Immunity Menu")
	menu:AddButton("Immune", function()
		DespawnImmunityValue = true
		if affectedveh ~= nil then
			affectedveh:SetDespawnImmunity(DespawnImmunityValue)
		end
	end)
	menu:AddButton("Not Immune", function()
		DespawnImmunityValue = false
		if affectedveh ~= nil then
			affectedveh:SetDespawnImmunity(DespawnImmunityValue)
		end
	end)

	return menu
end

local function ChooseDamageImmunityMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Damage Immunity Menu")
	menu:AddButton("Immune", function()
		DamageImmunityValue = "10000000000000000000000"
		if affectedveh ~= nil then
			affectedveh:SetResistance(tonumber(DamageImmunityValue))
		end
	end)
	menu:AddButton("Not Immune", function()
		DamageImmunityValue = "0"
		if affectedveh ~= nil then
			affectedveh:SetResistance(tonumber(DamageImmunityValue))
		end
	end)

	return menu
end

local function ChooseFrontWheelsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Front Wheels")
	menu:AddSearch("Search", "Start typing to filter")

	for k,v in ipairs(WheelNames) do
		menu:AddButton(FirstLettersToUpper(string.gsub(v, "_", " ")), v, ChangeFrontWheels)
	end

	return menu
end

local function ChooseRearWheelsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Choose Rear Wheels")
	menu:AddSearch("Search", "Start typing to filter")

	for k,v in ipairs(WheelNames) do
		menu:AddButton(FirstLettersToUpper(string.gsub(v, "_", " ")), v, ChangeRearWheels)
	end

	return menu
end

local function FrontRightWindowMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Front Right Window")
	menu:AddButton("Open", function()
		WindowFrontRight = true
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(2, WindowFrontRight, false)
		end
	end)
	menu:AddButton("Closed", function()
		WindowFrontRight = false
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(2, WindowFrontRight, false)
		end
	end)

	return menu
end

local function FrontLeftWindowMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Front Left Window")
	menu:AddButton("Open", function()
		WindowFrontLeft = true
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(1, WindowFrontLeft, false)
		end
	end)
	menu:AddButton("Closed", function()
		WindowFrontLeft = false
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(1, WindowFrontLeft, false)
		end
	end)

	return menu
end

local function RearRightWindowMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Rear Right Window")
	menu:AddButton("Open", function()
		WindowBackRight = true
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(4, WindowBackRight, false)
		end
	end)
	menu:AddButton("Closed", function()
		WindowBackRight = false
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(4, WindowBackRight, false)
		end
	end)

	return menu
end

local function RearLeftWindowMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Rear Left Window")
	menu:AddButton("Open", function()
		WindowBackLeft = true
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(3, WindowBackLeft, false)
		end
	end)
	menu:AddButton("Closed", function()
		WindowBackLeft = false
		if affectedveh ~= nil then
			affectedveh:OpenSeatWindow(3, WindowBackLeft, false)
		end
	end)

	return menu
end

local function VehicleHood()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Hood")
	menu:AddButton("Open", function()
		HoodOpen = true
		if affectedveh ~= nil then
			affectedveh:OpenHood()
		end
	end)
	menu:AddButton("Closed", function()
		HoodOpen = false
		if affectedveh ~= nil then
			affectedveh:CloseHood()
		end
	end)

	return menu
end

local function VehicleTrunk()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Trunk")
	menu:AddButton("Open", function()
		TrunkOpen = true
		if affectedveh ~= nil then
			affectedveh:OpenTrunk()
		end
	end)
	menu:AddButton("Closed", function()
		TrunkOpen = false
		if affectedveh ~= nil then
			affectedveh:CloseTrunk()
		end
	end)

	return menu
end

local function SetRadioStateMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Set Radio State")
	menu:AddButton("Radio ON", function()
		RadioState = true
		if affectedveh ~= nil then
			game.radio:SetOn(affectedveh, RadioState)
		end
	end)
	menu:AddButton("Radio OFF", function()
		RadioState = false
		if affectedveh ~= nil then
			game.radio:SetOn(affectedveh, RadioState)
		end
	end)

	return menu
end

local function VehicleParts()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Vehicle Parts")
	menu:AddButton("Choose Front Wheels", ChooseFrontWheelsMenu)
	menu:AddButton("Choose Rear Wheels", ChooseRearWheelsMenu)
	menu:AddButton("Bulletproof Tires Settings", BulletProofTiresMenu)
	menu:AddButton("Set SPZ Text", SetVehicleSPZTextMenu)
	menu:AddButton("Hood", VehicleHood)
	menu:AddButton("Trunk", VehicleTrunk)
	menu:AddButton("Front Right Window", FrontRightWindowMenu)
	menu:AddButton("Front Left Window", FrontLeftWindowMenu)
	local RearLeftWindow = menu:AddButton("Rear left Window", RearLeftWindowMenu)
	local RearRightWindow = menu:AddButton("Rear Right Window", RearRightWindowMenu)

	menu:OnUpdate(function()
		menu:SetEntryEnabled(RearLeftWindow, CheckVehWindowAmmount())
		menu:SetEntryEnabled(RearRightWindow, CheckVehWindowAmmount())
	end)
	return menu
end

local function VehicleSpeedBoost()
	local currentspeed = getp():GetOwner():GetSpeedFloat()
	getp():GetOwner():SetSpeed((currentspeed + 10))
end

local function LaunchVehicleUp(veh)
	local vehRot = veh:GetRot()
	local dir = veh:GetDir() * Math:newVector(1,1,0)
	local tangentVec = Math:newVector(-dir.y, dir.x, 0)
	local pos = veh:GetPos()
	veh:SetPos(pos + Math:newVector(0,0,3))
	veh:SetDir(Math:newVector(((dir.y * tangentVec.z) - (dir.z * tangentVec.y)),((dir.x * tangentVec.z) - (dir.z * tangentVec.x)),((dir.x * tangentVec.y) - (dir.y * tangentVec.x))))
	veh:SetSpeed(400)
	veh:SetRot(vehRot)
end

local function VehicleColorsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Vehicle Colors")
	menu:AddButton("Primary Color", ChoosePrimaryColor)
	menu:AddButton("Secondary Color", ChooseSecondaryColor)
	menu:AddButton("Window Tint and Opacity", ChooseWindowTint)
	--menu:AddButton("Chrome Ammount", ChooseChromeAmmount)
	--menu:AddButton("Glossiness Ammount", ChooseGlossAmmount)
	return menu
end

local function LeaveVehicle()
	StartThread(function ()
        local so
		getp():LockControls(true)
		Wait(getp():GetOffVehicle(false, false))
		getp():LockControls(false)
        return
    end)
end

------------------------
-- Local Vehicle Info --
------------------------
local function LocalVehicleInfoMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle(getp():GetOwner():GetName())
	local Pos =  getp():GetOwner():GetPos()
	local Dir =  getp():GetOwner():GetDir()
	local rot = getp():GetOwner():GetRot()
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
	local VehSpeedInfo = menu:AddButton("Speed: " .. tostring(getp():GetOwner():GetSpeedFloat()))
	local VehGear = menu:AddButton("Gear: " .. tostring(getp():GetOwner():GetGear()))
	local VehDamage = menu:AddButton("Damage: " .. tostring(getp():GetOwner():GetDamage()))
	local VehMotorDamage = menu:AddButton("Motor Damage: " .. tostring(getp():GetOwner():GetMotorDamage()))
	local VehFuel = menu:AddButton("Fuel: " .. tostring(getp():GetOwner():GetActualFuel()) .. "/" .. tostring(getp():GetOwner():GetFuelTankCapacity()))
	local VehRust = menu:AddButton("Rust: " .. tostring(getp():GetOwner():GetRust() * 100))
	local VehDirt = menu:AddButton("Dirt: " .. tostring(getp():GetOwner():GetDirty() * 100))
	local VehFrontWheels = menu:AddButton("Front Wheels: " .. tostring(getp():GetOwner():GetWheel(1)))
	local VehRearWheels = menu:AddButton("Rear Wheels: " .. tostring(getp():GetOwner():GetWheel(2)))
	menu:OnUpdate(function()
		Pos =  getp():GetOwner():GetPos()
		Dir =  getp():GetOwner():GetDir()
		rot = getp():GetOwner():GetRot()
		menu:SetEntryText(PositionXMenu, "Position: " .. "X: " .. tostring(Pos.x))
		menu:SetEntryText(PositionYMenu, "Position: " .. "Y: " .. tostring(Pos.y))
		menu:SetEntryText(PositionZMenu, "Position: " .. "Z: " .. tostring(Pos.z))
		menu:SetEntryText(DirectionXMenu, "Direction: " .. "X: " .. tostring(Dir.x))
		menu:SetEntryText(DirectionYMenu, "Direction: " .. "Y: " .. tostring(Dir.y))
		menu:SetEntryText(DirectionZMenu, "Direction: " .. "Z: " .. tostring(Dir.z))
		menu:SetEntryText(VehSpeedInfo, "Speed: " .. tostring(getp():GetOwner():GetSpeedFloat()))
		menu:SetEntryText(VehGear, "Gear: " .. tostring(getp():GetOwner():GetGear()))
		menu:SetEntryText(VehDamage, "Damage: " .. tostring(getp():GetOwner():GetDamage()))
		menu:SetEntryText(VehMotorDamage, "Motor Damage: " .. tostring(getp():GetOwner():GetMotorDamage()))
		menu:SetEntryText(VehFrontWheels, "Front Wheels: " .. tostring(getp():GetOwner():GetWheel(1)))
		menu:SetEntryText(VehRearWheels, "Rear Wheels: " .. tostring(getp():GetOwner():GetWheel(2)))
		menu:SetEntryText(VehFuel, "Fuel: " .. tostring(getp():GetOwner():GetActualFuel()) .. "/" .. tostring(getp():GetOwner():GetFuelTankCapacity()))
		menu:SetEntryText(VehRust, "Rust: " .. tostring(getp():GetOwner():GetRust() * 100))
		menu:SetEntryText(VehDirt, "Dirt: " .. tostring(getp():GetOwner():GetDirty() * 100))
		menu:SetEntryText(RotXMenu, "Rotation: X: " .. tostring(rot.v.x))
		menu:SetEntryText(RotYMenu, "Rotation: Y: " .. tostring(rot.v.y))
		menu:SetEntryText(RotZMenu, "Rotation: Z: " .. tostring(rot.v.z))
		menu:SetEntryText(RotWMenu, "Rotation: W: " .. tostring(rot.s))
	end)
	return menu
end

-------------------
-- Local Vehicle --
-------------------
local function LocalVehicleMenu()
	local menu = UI.SimpleMenu()
	SetAffectedVeh(getp():GetOwner())
	menu:AddButton("Speed Boost", VehicleSpeedBoost)
	menu:AddButton("Vehicle Colors", VehicleColorsMenu)
	menu:AddButton("Vehicle Parts", VehicleParts)
	menu:AddButton("Vehicle Light State", ChooseVehicleLightStateMenu)
	menu:AddButton("Vehicle Siren State", ChooseVehicleSirenStateMenu)
	local EngineStateCheck = menu:AddCheckbox("Engine State", ToggleEngineState)
	menu:AddButton("Reset Damage", ResetCarDamage)
	menu:AddButton("Reset Engine Damage", ResetMotorDamage)
	menu:AddButton("Vehicle Explosion Immunity Menu", ChooseExplosionImmunityMenu)
	menu:AddButton("Despawn Immunity Menu", ChooseDespawnImmunityMenu)
	menu:AddButton("Damage Immunity Menu", ChooseDamageImmunityMenu)
	menu:AddButton("Set Fuel Ammount", SetVehicleFuelMenu)
	menu:AddButton("Set Rust Ammount", SetVehicleRustLevelMenu)
	menu:AddButton("Set Dirt Ammount", SetVehicleDirtLevelMenu)
	menu:AddButton("Set Steering Play Ammount", SetSteeringPlayMenu)
	menu:AddButton("Set Steering Offset Ammount", SetSteeringOffsetMenu)
	menu:AddButton("Set Vehicle Handling Multiplier", SetVehicleHandlingMenu)
	--menu:AddButton("Hook up Spawned Trailer", AttachTrailer)
	menu:AddButton("Vehicle Info", LocalVehicleInfoMenu)
	menu:AddButton("Launch Vehicle Up", function()
		LaunchVehicleUp(affectedveh)
	end)
	menu:AddButton("Leave Vehicle", LeaveVehicle)
	
	-- Update
	menu:OnUpdate(function()
		if affectedveh ~= nil then
			menu:SetChecked(EngineStateCheck, affectedveh:GetEngineRotations() > 0)
		end
	end)
	
	return menu
end

-------------
-- Vehicle --
-------------
local function SpawnVehicleMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Spawn Vehicle")
	menu:AddSearch("Search", "Start typing to filter")

	for k, v in ipairs(VehicleModelIDs) do
		menu:AddButton(FirstLettersToUpper(string.gsub(v, "_", " ")), v, ChooseVehicle)
	end

	return menu
end

local function SpawnBoatMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Spawn Boat")
	menu:AddSearch("Search", "Start typing to filter")

	for k, v in ipairs(BoatModelIDs) do
		menu:AddButton(FirstLettersToUpper(string.gsub(v, "_", " ")), v, ChooseBoat)
	end

	return menu
end


local function VehicleMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Vehicle")
	menu:AddButton("Spawn", "Spawn vehicle", SpawnVehicleMenu)
	menu:AddButton("Spawn Boat", SpawnBoatMenu)
	
	local localVehicleIdx = menu:AddButton("Local Vehicle", "Control the vehicle you're in", LocalVehicleMenu)

	menu:OnUpdate(function()
		menu:SetEntryEnabled(localVehicleIdx, IsPlayerInVehicle())
	end)

	return menu
end

table.insert(TrainerMenuItems, { "Vehicle", "Spawn vehicles, modify them ..", VehicleMenu })