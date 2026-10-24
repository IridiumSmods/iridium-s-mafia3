local CameraOffsetXValue = 0
local CameraOffsetYValue = 0
local CameraOffsetZValue = 0
local CameraOffsetTransitionTimeIn = 1
local CameraOffsetTransitionTimeOut = 1
local CameraOffsetWaitTime = 1
local CameraFOVTransitionTimeIn = 1
local CameraFOVTransitionTimeOut = 1
local CameraFOVValue = 10
local CameraFOVWaitTime = 1
local CameraLookAtXValue = 0
local CameraLookAtYValue = 0
local CameraLookAtZValue = 1.7
local CameraChangeDirTransitionTime = 1
local CameraChangeDirWaitTime = 1
local CameraLookAtEntTarget = "none"
local CameraLookAtEntTransitionTime = 1
local CameraLookAtEntWaitTime = 1
local CameraLockToEntName = "none"
local CameraLockToEntTargetName = "none"
local CameraLockToEntTransitionTime = 1
local CameraLockToEntOffsetX = 0
local CameraLockToEntOffsetY = 0
local CameraLockToEntOffsetZ = 0
local freecam_enabled = false
local new_ent = nil
local angle = 90
local z_angle = 0
local distance_mult = 0.1
local rotation_mult = 0.25
local freecamsetting = false
local FCDOFEnabled = false

function FreecamUpdate()
	local player = getp()
	if freecam_enabled == true and player ~= nil then
		local aim_dir = game.game:GetActivePlayer():GetAimDiff(true)
		local new_dir = Math:newVector(0,0,0)
		local new_ent_pos = new_ent:GetPos()
		local key_pressed = game.game:GetActivePlayer():GetMoveDir(true)
		if aim_dir.y > 0 then
			z_angle = math.clamp((z_angle + (aim_dir.y*rotation_mult)),-4,4)
			new_dir = Math:newVector(math.cos(tonumber(angle)), math.sin(tonumber(angle)), z_angle)
			new_ent:SetDir(new_dir)
		elseif aim_dir.y < 0 then
			z_angle = math.clamp((z_angle + (aim_dir.y*rotation_mult)),-4,4)
			new_dir = Math:newVector(math.cos(tonumber(angle)), math.sin(tonumber(angle)), z_angle)
			new_ent:SetDir(new_dir)
		end
		if aim_dir.x > 0 then
			angle = angle - (aim_dir.x*rotation_mult)
			new_dir = Math:newVector(math.cos(tonumber(angle)), math.sin(tonumber(angle)), z_angle)
			new_ent:SetDir(new_dir)
		elseif aim_dir.x < 0 then
			angle = angle - (aim_dir.x*rotation_mult)
			new_dir = Math:newVector(math.cos(tonumber(angle)), math.sin(tonumber(angle)), z_angle)
			new_ent:SetDir(new_dir)
		end
		local cam_dir = game.cameramanager:GetPlayerCamera():GetDir()
		if key_pressed.y > 0 then
			--print("W is pressed")
			new_ent_pos.x = new_ent_pos.x + (cam_dir.x * distance_mult)
			new_ent_pos.y = new_ent_pos.y + (cam_dir.y * distance_mult)
			new_ent_pos.z = new_ent_pos.z + (cam_dir.z * distance_mult)
			new_ent:SetPos(new_ent_pos)
		elseif key_pressed.y < 0 then
			--print("S is pressed")
			new_ent_pos.x = new_ent_pos.x - (cam_dir.x * distance_mult)
			new_ent_pos.y = new_ent_pos.y - (cam_dir.y * distance_mult)
			new_ent_pos.z = new_ent_pos.z - (cam_dir.z * distance_mult)
			new_ent:SetPos(new_ent_pos)
		end
		if key_pressed.x > 0 then
			--print("D is pressed")
			new_ent_pos.x = new_ent_pos.x + (cam_dir.y * distance_mult)
			new_ent_pos.y = new_ent_pos.y - (cam_dir.x * distance_mult)
			new_ent:SetPos(new_ent_pos)
		elseif key_pressed.x < 0 then
			--print("A is pressed")
			new_ent_pos.x = new_ent_pos.x - (cam_dir.y * distance_mult)
			new_ent_pos.y = new_ent_pos.y + (cam_dir.x * distance_mult)
			new_ent:SetPos(new_ent_pos)
		end
	end
end

local function CreateEntityFreecam()
	if freecamsetting == false then
		if freecam_enabled == false then
			new_ent = game.game:CreateCleanEntity(game.game:GetActivePlayer():GetPos(), 0, false, false, true)
			new_ent:SetPos(game.cameramanager:GetPlayerCamera():GetPos())
			local new_dir = Math:newVector(math.cos(tonumber(angle)), math.sin(tonumber(angle)), z_angle)
			new_ent:SetDir(new_dir)
			local entWrapComp = new_ent:GetComponent("C_EntityWrapperComponent")
			entWrapComp:SetGameEntityType(enums.EntityType.ENTITY_DUMMY)
			new_ent:AddComponent("C_CameraComponent")
			game.cameramanager:GetPlayerCamera():ScriptLock(new_ent, 0)
			print(tostring(new_ent:GetGUID()), new_ent:GetPos())
			game.game:GetActivePlayer():LockControls(true)
			freecam_enabled = true
			game.game:ModifyGameTime(0.00005,1)
		elseif freecam_enabled == true then
			game.cameramanager:GetPlayerCamera():ScriptUnlock(1)
			game.cameramanager:GetPlayerCamera():ScriptForcedOffsetStop()
			game.game:GetActivePlayer():LockControls(false)
			new_ent = nil
			freecam_enabled = false
			game.game:ModifyGameTime(1,1)
		end
	elseif freecamsetting == true then
		if freecam_enabled == false then
			new_ent = game.game:GetActivePlayer()
			new_ent:SetPhysState(enums.PhysicsState.DISABLED)
			new_ent:SetPos(game.cameramanager:GetPlayerCamera():GetPos())
			local new_dir = Math:newVector(math.cos(tonumber(angle)), math.sin(tonumber(angle)), z_angle)
			new_ent:SetDir(new_dir)
			game.cameramanager:GetPlayerCamera():ScriptLock(new_ent, 0)
			game.game:GetActivePlayer():LockControls(true)
			freecam_enabled = true
		elseif freecam_enabled == true then
			game.cameramanager:GetPlayerCamera():ScriptUnlock(1)
			game.cameramanager:GetPlayerCamera():ScriptForcedOffsetStop()
			game.game:GetActivePlayer():LockControls(false)
			new_ent = nil
			freecam_enabled = false
		end
	end
end

local function ToggleFreecamType()
	if freecamsetting == false then
		freecamsetting = true
	elseif freecamsetting == true then
		freecamsetting = false
	end
end

local function CameraLockToEntOffsetXMenu()
	UI.SimpleTextInput("Enter X Offset Value (use only integers)", function(success, LockToEntXOffset_Input)
		if success then
			CameraLockToEntOffsetX = LockToEntXOffset_Input
			CameraLockToEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLockToEntOffsetYMenu()
	UI.SimpleTextInput("Enter Y Offset Value (use only integers)", function(success, LockToEntYOffset_Input)
		if success then
			CameraLockToEntOffsetY = LockToEntYOffset_Input
			CameraLockToEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLockToEntOffsetZMenu()
	UI.SimpleTextInput("Enter Z Offset Value (use only integers)", function(success, LockToEntZOffset_Input)
		if success then
			CameraLockToEntOffsetZ = LockToEntZOffset_Input
			CameraLockToEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLockToEntNameMenu()
	UI.SimpleTextInput("Enter Entity Name", function(success, LockToEntName_Input)
		if success then
			CameraLockToEntName = LockToEntName_Input
			CameraLockToEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLockToTargetEntNameMenu()
	UI.SimpleTextInput("Enter Target Entity Name", function(success, LockToEntTargetName_Input)
		if success then
			CameraLockToEntTargetName = LockToEntTargetName_Input
			CameraLockToEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLockToEntTransitionTimeMenu()
	UI.SimpleTextInput("Enter Transition Time value (Use only integers)", function(success, LockToEntTransitionTime_Input)
		if success then
			CameraLockToEntTransitionTime = LockToEntTransitionTime_Input
			CameraLockToEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLockToEnt()
	game.cameramanager:GetPlayerCamera():ScriptLockTargetOffset(game.entitywrapper:GetEntityByName(CameraLockToEntName), game.entitywrapper:GetEntityByName(CameraLockToEntTargetName), Math:newVector(0,0,0), CameraLockToEntTransitionTime)
end

local function CameraChangeFOV()
	game.cameramanager:GetPlayerCamera():ScriptForcedFOVStart(game.game:ToHashName("text"), game.game:ToHashName("text"), CameraFOVTransitionTimeIn, CameraFOVTransitionTimeOut, CameraFOVValue, CameraFOVWaitTime, true, true)
end

local function CameraFOVTransitionTimeInMenu()
	UI.SimpleTextInput("Enter Transition Time In value (Use only integers)", function(success, TransitionTimeInFOV_Input)
		if success then
			CameraFOVTransitionTimeIn = TransitionTimeInFOV_Input
			CameraChangeFOVMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraFOVTransitionTimeOutMenu()
	UI.SimpleTextInput("Enter Transition Time Out value (Use only integers)", function(success, TransitionTimeOutFOV_Input)
		if success then
			CameraFOVTransitionTimeOut = TransitionTimeOutFOV_Input
			CameraChangeFOVMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraFOVValueMenu()
	UI.SimpleTextInput("Enter FOV value (Use only integers)", function(success, FOV_Input)
		if success then
			CameraFOVValue = FOV_Input
			CameraChangeFOVMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraFOVWaitTimeMenu()
	UI.SimpleTextInput("Enter Wait Time value (Use only integers)", function(success, FOVWait_Input)
		if success then
			CameraFOVWaitTime = FOVWait_Input
			CameraChangeFOVMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraChangeDirXValueMenu()
	UI.SimpleTextInput("Enter X value (Use only integers)", function(success, CDirX_Input)
		if success then
			CameraLookAtXValue = CDirX_Input
			CameraChangeDirMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraChangeDirYValueMenu()
	UI.SimpleTextInput("Enter Y value (Use only integers)", function(success, CDirY_Input)
		if success then
			CameraLookAtYValue = CDirY_Input
			CameraChangeDirMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraChangeDirZValueMenu()
	UI.SimpleTextInput("Enter Z value (Use only integers)", function(success, CDirZ_Input)
		if success then
			CameraLookAtZValue = CDirZ_Input
			CameraChangeDirMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraChangeDirTransitionTimeMenu()
	UI.SimpleTextInput("Enter Transition Time value (Use only integers)", function(success, CDirTransitionTime_Input)
		if success then
			CameraChangeDirTransitionTime = CDirTransitionTime_Input
			CameraChangeDirMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraChangeDirWaitTimeMenu()
	UI.SimpleTextInput("Enter Wait Time value (Use only integers)", function(success, CDirWait_Input)
		if success then
			CameraChangeDirWaitTime = CDirWait_Input
			CameraChangeDirMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraChangeDir()
	LookAtVector = game.game:GetActivePlayer():GetPos()
	LookAtVector.x = LookAtVector.x + CameraLookAtXValue
	LookAtVector.y = LookAtVector.y + CameraLookAtYValue
	LookAtVector.z = LookAtVector.z + CameraLookAtZValue
	game.cameramanager:GetPlayerCamera():ScriptPointAtVec(LookAtVector, CameraChangeDirTransitionTime, 1, CameraChangeDirWaitTime)
end

local function CameraLookAtEntWaitTimeMenu()
	UI.SimpleTextInput("Enter Wait Time value (Use only integers)", function(success, CLookAtEntWait_Input)
		if success then
			CameraLookAtEntWaitTime = CLookAtEntWait_Input
			CameraLookAtEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLookAtEntTransitionTimeMenu()
	UI.SimpleTextInput("Enter Transition Time value (Use only integers)", function(success, CLookAtEntTransitionTime_Input)
		if success then
			CameraLookAtEntTransitionTime = CLookAtEntTransitionTime_Input
			CameraLookAtEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLookAtEntNameMenu()
	UI.SimpleTextInput("Enter entity name", function(success, CLookAtEntName_Input)
		if success then
			CameraLookAtEntTarget = CLookAtEntName_Input
			CameraLookAtEntMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraLookAtEnt()
	game.cameramanager:GetPlayerCamera():ScriptPointAtEnt(game.entitywrapper:GetEntityByName(CameraLookAtEntTarget), CameraLookAtEntTransitionTime, 1, CameraLookAtEntWaitTime)
end

local function CameraResetPos()
	game.cameramanager:GetPlayerCamera():ScriptUnlock(1)
	game.cameramanager:GetPlayerCamera():ScriptForcedOffsetStop()
	game.cameramanager:GetPlayerCamera():ScriptForcedFOVStop()
end

local function CameraOffset()
	game.cameramanager:GetPlayerCamera():ScriptForcedOffsetStart(game.game:ToHashName("text"), game.game:ToHashName("text"), Math:newVector(CameraOffsetXValue, CameraOffsetYValue, CameraOffsetZValue), CameraOffsetTransitionTimeOut, CameraOffsetTransitionTimeIn, CameraOffsetWaitTime, true)
end

local function CameraXOffsetValueMenu()
	UI.SimpleTextInput("Enter X offset value (Use only integers)", function(success, XOffset_Input)
		if success then
			CameraOffsetXValue = XOffset_Input
			CameraOffsetMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraYOffsetValueMenu()
	UI.SimpleTextInput("Enter Y offset value (Use only integers)", function(success, YOffset_Input)
		if success then
			CameraOffsetYValue = YOffset_Input
			CameraOffsetMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraZOffsetValueMenu()
	UI.SimpleTextInput("Enter Z offset value (Use only integers)", function(success, ZOffset_Input)
		if success then
			CameraOffsetZValue = ZOffset_Input
			CameraOffsetMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraTransitionTimeInValueMenu()
	UI.SimpleTextInput("Enter Transition Time In value (Use only integers)", function(success, TransitionTimeIn_Input)
		if success then
			CameraOffsetTransitionTimeIn = TransitionTimeIn_Input
			CameraOffsetMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraTransitionTimeOutValueMenu()
	UI.SimpleTextInput("Enter Transition Time Out (Use only integers)", function(success, TransitionTimeOut_Input)
		if success then
			CameraOffsetTransitionTimeOut = TransitionTimeOut_Input
			CameraOffsetMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

local function CameraWaitTimeValueMenu()
	UI.SimpleTextInput("Enter Wait time value (Use only integers)", function(success, WaitTime_Input)
		if success then
			CameraOffsetWaitTime = WaitTime_Input
			CameraOffsetMenu():Toggle()
		else
			print("Dialog was canceled")
		end
	end)
end

function CameraOffsetMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera Offset Controls")
	
	menu:AddButton("Camera Offset X Value", CameraXOffsetValueMenu)
	menu:AddButton("Camera Offset Y Value", CameraYOffsetValueMenu)
	menu:AddButton("Camera Offset Z Value", CameraZOffsetValueMenu)
	menu:AddButton("Camera Offset Transition Time In Value", CameraTransitionTimeOutValueMenu)
	menu:AddButton("Camera Offset Transition Time Out Value", CameraTransitionTimeInValueMenu)
	menu:AddButton("Camera Offset Wait Time Value", CameraWaitTimeValueMenu)
	menu:AddButton("Offset Camera", CameraOffset)
	
	return menu
end

function CameraChangeFOVMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera FOV Controls")
	
	menu:AddButton("Camera FOV Value", CameraFOVValueMenu)
	menu:AddButton("Camera Wait Time Value", CameraFOVWaitTimeMenu)
	menu:AddButton("Camera FOV Transition Time In Value", CameraFOVTransitionTimeInMenu)
	menu:AddButton("Camera FOV Transition Time Out Value", CameraFOVTransitionTimeOutMenu)
	menu:AddButton("Change Camera FOV", CameraChangeFOV)
	
	return menu
end

function CameraChangeDirMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera Direction Controls")
	
	menu:AddButton("Camera Look At X Value", CameraChangeDirXValueMenu)
	menu:AddButton("Camera Look At Y Value", CameraChangeDirYValueMenu)
	menu:AddButton("Camera Look At Z Value", CameraChangeDirZValueMenu)
	menu:AddButton("Camera Wait Time Value", CameraChangeDirWaitTimeMenu)
	menu:AddButton("Camera Transition Time Value", CameraChangeDirTransitionTimeMenu)
	menu:AddButton("Change Camera Direction", CameraChangeDir)
	
	return menu
end

function CameraLookAtEntMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera Look at Entity Controls")
	
	menu:AddButton("Camera Target Entity Name", CameraLookAtEntNameMenu)
	menu:AddButton("Camera Transition Time Value", CameraLookAtEntTransitionTimeMenu)
	menu:AddButton("Camera Wait Time Value", CameraLookAtEntWaitTimeMenu)
	menu:AddButton("Look at Entity", CameraLookAtEnt)
	
	return menu
end

local function CameraLockToEntOffsetMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera Target Offset Menu")
	
	menu:AddButton("Camera Target X Offset", CameraLockToEntOffsetXMenu)
	menu:AddButton("Camera Target Y Offset", CameraLockToEntOffsetYMenu)
	menu:AddButton("Camera Target Z Offset", CameraLockToEntOffsetZMenu)
	
	return menu
end

function CameraLockToEntMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera Look at Entity Controls")
	
	menu:AddButton("Camera Entity Name", CameraLockToEntNameMenu)
	menu:AddButton("Camera Target Entity Name", CameraLockToTargetEntNameMenu)
	menu:AddButton("Camera Target Offset Menu", CameraLockToEntOffsetMenu)
	menu:AddButton("Camera Transition Time Value", CameraLockToEntTransitionTimeMenu)
	menu:AddButton("Lock to Entity", CameraLockToEnt)
	
	return menu
end

local function FCFocusDistanceMenu()
	UI.SimpleTextInput("Enter Focus Distance value (Use only integers)", function(success, FCFocusDistance)
		if success then
			new_ent:GetComponent("C_CameraComponent"):SetFocusDistance(tonumber(FCFocusDistance))
			game.cameramanager:GetPlayerCamera():ScriptUnlock(0)
			game.cameramanager:GetPlayerCamera():ScriptLock(new_ent, 0)
		else
			print("Dialog was canceled")
		end
	end)
end

local function FCFOVMenu()
	UI.SimpleTextInput("Enter FOV value (0.01 - 110)", function(success, FCFOVValue)
		if success then
			new_ent:GetComponent("C_CameraComponent"):SetFOV(tonumber(FCFOVValue)*(1.5707964/60))
			game.cameramanager:GetPlayerCamera():ScriptUnlock(0)
			game.cameramanager:GetPlayerCamera():ScriptLock(new_ent, 0)
		else
			print("Dialog was canceled")
		end
	end)
end

local function FCSpeedMenu()
	UI.SimpleTextInput("Enter Speed value (Use only integers)", function(success, FCSpeedValue)
		if success then
			distance_mult = tonumber(FCSpeedValue)
		else
			print("Dialog was canceled")
		end
	end)
end

local function FCRotSpeedMenu()
	UI.SimpleTextInput("Enter Speed value (Use only integers)", function(success, FCRotSpeedValue)
		if success then
			rotation_mult = tonumber(FCRotSpeedValue)
		else
			print("Dialog was canceled")
		end
	end)
end

function FreecamSettingsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Freecam Settings")
	
	menu:AddButton("Set Speed", FCSpeedMenu)
	menu:AddButton("Set Rotation Speed", FCRotSpeedMenu)
	local DOFMenu = menu:AddCheckbox("Toggle Depth of Field", function()
		FCDOFEnabled = not (FCDOFEnabled)
		new_ent:GetComponent("C_CameraComponent"):SetDOFEnabled(FCDOFEnabled)
		game.cameramanager:GetPlayerCamera():ScriptUnlock(0)
		game.cameramanager:GetPlayerCamera():ScriptLock(new_ent, 0)
	end)
	menu:AddButton("Set Focus Distance", FCFocusDistanceMenu)
	menu:AddButton("Set FOV", FCFOVMenu)
	
	menu:OnUpdate(function()
		menu:SetChecked(DOFMenu, FCDOFEnabled)
	end)
	
	return menu
end

local function CameraInfoMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera Info")
	local camera = game.cameramanager:GetPlayerMainCamera(0)
	local Pos =  camera:GetPos()
	local Dir =  camera:GetDir()
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
	menu:AddButton("Free Camera Enabled: " .. tostring(freecam_enabled))
	menu:OnUpdate(function()
		Pos =  camera:GetPos()
		Dir =  camera:GetDir()
		menu:SetEntryText(PositionXMenu, "Position: " .. "X: " .. tostring(Pos.x))
		menu:SetEntryText(PositionYMenu, "Position: " .. "Y: " .. tostring(Pos.y))
		menu:SetEntryText(PositionZMenu, "Position: " .. "Z: " .. tostring(Pos.z))
		menu:SetEntryText(DirectionXMenu, "Direction: " .. "X: " .. tostring(Dir.x))
		menu:SetEntryText(DirectionYMenu, "Direction: " .. "Y: " .. tostring(Dir.y))
		menu:SetEntryText(DirectionZMenu, "Direction: " .. "Z: " .. tostring(Dir.z))
	end)
	return menu
end

-- HUD
local function CameraControlsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Camera Controls")
	
	local FreecamMenu = menu:AddCheckbox("Toggle Freecam", CreateEntityFreecam)
	local FreecamType = menu:AddCheckbox("Toggle Freecam Type", ToggleFreecamType)
	local FreecamSettings = menu:AddButton("Freecam Settings", FreecamSettingsMenu)
	menu:AddButton("Camera Offset Menu", CameraOffsetMenu)
	menu:AddButton("Camera FOV Menu", CameraChangeFOVMenu)
	menu:AddButton("Camera Direction Menu", CameraChangeDirMenu)
    menu:AddButton("Camera Look At Entity Menu", CameraLookAtEntMenu)
	menu:AddButton("Camera Lock To Entity Menu", CameraLockToEntMenu)
	menu:AddButton("Reset Camera", CameraResetPos)
	menu:AddButton("Camera Info", CameraInfoMenu)
	
	menu:OnUpdate(function()
		menu:SetChecked(FreecamMenu, freecam_enabled)
		menu:SetChecked(FreecamType, freecamsetting)
		menu:SetEntryEnabled(FreecamSettings, freecam_enabled)
	end)
	
	return menu
end
table.insert(TrainerMenuItems, { "Camera Controls", "Manage ingame camera", CameraControlsMenu })