include("menu/WeaponIDs.lua")

-----------------
-- Give Weapon --
-----------------
local function GiveWeapon(menu, text, name)
	ammo_ammount = 500
	active_weapon  = getp():InventoryGetSelected()
	if active_weapon == "empty" then
		getp():InventoryAddWeapon(name, ammo_ammount)
		getp():InventorySelect(name, true)
	else
		getp():InventoryRemoveWeapon(active_weapon)
		getp():InventoryAddWeapon(name, ammo_ammount)
		getp():InventorySelect(name, true)
	end
end

local function GiveWeaponsMenu()
	local menu = UI.SimpleMenu()
	menu:SetTitle("Give Weapon")
	menu:AddSearch("Search", "Start typing to filter")

	for k,v in ipairs(WeaponIDs) do
		menu:AddButton(v, v, GiveWeapon)
	end

	return menu
end

--------------------
-- Unlimited ammo --
--------------------
local unlimitedAmmo = false
local function ToggleUnlimitedAmmo()
  unlimitedAmmo = not unlimitedAmmo
  getp():InventorySetUnlimitedAmmo(unlimitedAmmo)
end

local Old_Ammo = 1
function AutoReloadWeapons()
	if unlimitedAmmo then
		curr_weapon = getp():InventoryGetSelected()
		if curr_weapon ~= nil then
			if getp():DbgTesting_HelperFire_GetAmmoCountInEquipedWeapon() < Old_Ammo then
				getp():InventoryLoadWeapons()
			end
			Old_Ammo = getp():DbgTesting_HelperFire_GetAmmoCountInEquipedWeapon()
		end
	end
end

-------------
-- Weapons --
-------------
local function WeaponsMenu()
	local menu = UI.SimpleMenu()
    menu:SetTitle("Weapons")
    
    menu:AddButton("Give weapon", GiveWeaponsMenu)
    
    menu:AddButton("Give max ammo", "Max ammo to all weapons", function()
      getp():InventoryLoadWeapons()
    end)
    
    menu:AddButton("Give grenades", "Gives you 2 grenades", function()
      getp():InventoryAddGrenades(2)
    end)
    
    menu:AddButton("Give molotovs", "Gives you 2 molotovs", function()
      getp():InventoryAddAmmoByCategory(71, 2)
    end)
	
	menu:AddButton("Clear Inventory", "Remove all of your weapons", function()
	  getp():ClearInventory()
    end)
    
    local unlimited = menu:AddCheckbox("Toggle unlimited ammo", "Unlimited ammo to all weapons", ToggleUnlimitedAmmo)
    menu:OnUpdate(function()
		menu:SetChecked(unlimited, unlimitedAmmo)
	end)

	return menu
end

TrainerParts = TrainerParts or {}
TrainerParts.GiveWeaponMenu = GiveWeaponsMenu
TrainerParts.ToggleUnlimitedAmmo = ToggleUnlimitedAmmo
TrainerParts.UnlimitedAmmo = function() return unlimitedAmmo end