local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
  }

local IsMorgued = false
local unmorgued = false
local MorgueTime = 0
local morgueTimer = 0
local GraveyardLocation = Config.GraveyardLocation

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerLoaded = true
	ESX.PlayerData = ESX.GetPlayerData()
end)

Citizen.CreateThread(function() 
	while true do
	  InvalidateIdleCam()
	  Wait(1000)
	end 
end)

-- Disable most inputs when in Graveyard
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if IsMorgued then
			DisableControlAction(0, 1, true) -- Disable pan
			DisableControlAction(0, 2, true) -- Disable tilt
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			DisableControlAction(0, Keys['W'], true) -- W
			DisableControlAction(0, Keys['A'], true) -- A
			DisableControlAction(0, 31, true) -- S (fault in Keys table!)
			DisableControlAction(0, 30, true) -- D (fault in Keys table!)

			DisableControlAction(0, Keys['R'], true) -- Reload
			DisableControlAction(0, Keys['SPACE'], true) -- Jump
			DisableControlAction(0, Keys['Q'], true) -- Cover
			DisableControlAction(0, Keys['TAB'], true) -- Select Weapon
			DisableControlAction(0, Keys['F'], true) -- Also 'enter'?

			DisableControlAction(0, Keys['F1'], true) -- Disable phone
			DisableControlAction(0, Keys['F2'], true) -- Inventory
			DisableControlAction(0, Keys['F3'], true) -- Animations
			DisableControlAction(0, Keys['F6'], true) -- Job
			DisableControlAction(0, Keys['Z'], true) -- Hands up
			DisableControlAction(0, Keys['N'], true) -- Speaking
			DisableControlAction(0, Keys['~'], true) -- hands up

			DisableControlAction(0, Keys['V'], true) -- Disable changing view
			DisableControlAction(0, Keys['C'], true) -- Disable looking behind
			DisableControlAction(0, Keys['X'], true) -- Disable clearing animation
			DisableControlAction(2, Keys['P'], true) -- Disable pause screen

			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle

			DisableControlAction(0, Keys['LEFTCTRL'], true) -- Disable going stealth

			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		else
			Citizen.Wait(500)
		end
	end
end)


RegisterNetEvent('esx_morgue:morgue')
AddEventHandler('esx_morgue:morgue', function(morgueTimer)
	if IsMorgued then 
		return
	end
	Citizen.CreateThread(function()
		DoScreenFadeOut(20000)

		while not IsScreenFadedOut() do
			Citizen.Wait(1000)
		end

		StopScreenEffect('DeathFailOut')
		DoScreenFadeIn(20000)

		MorgueTime = morgueTimer
		local playerPed = PlayerPedId()
		if DoesEntityExist(playerPed) then
		Citizen.CreateThread(function()	
			-- Clear player
			-- SetPedArmour(playerPed, 0)
			ClearPedBloodDamage(playerPed)
			ResetPedVisibleDamage(playerPed)
			ClearPedLastWeaponDamage(playerPed)
			
			ESX.Game.Teleport(playerPed, GraveyardLocation)
			IsMorgued = true
			loadanimdict('missarmenian2')
    		TaskPlayAnim(GetPlayerPed(-1), 'missarmenian2', 'corpse_search_exit_ped', 8.0, -8,-1, 2, 0, 0, 0, 0)
			unmorgued = false
			while MorgueTime > 0 and not unmorgued do
				playerPed = PlayerPedId()

				RemoveAllPedWeapons(playerPed, true)
				if IsPedInAnyVehicle(playerPed, false) then
					ClearPedTasksImmediately(playerPed)
				end

				if MorgueTime % 120 == 0 then
					TriggerServerEvent('esx_morgue:updateRemaining', MorgueTime)
				end

				Citizen.Wait(20000)

				-- Is the player trying to escape?
				if GetDistanceBetweenCoords(GetEntityCoords(playerPed), GraveyardLocation.x, GraveyardLocation.y, GraveyardLocation.z) > 10 then
					ESX.Game.Teleport(playerPed, GraveyardLocation)
					TriggerEvent('chat:addMessage', { 
						template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(58, 58, 52, 0.6); border-radius: 3px;"><i class="fas fa-cross"></i> <b>Morgue</b> {1}</div>',
						args = { _U('morgue'), _U('escape_attempt') }, color = { 79, 0, 4 } 
					})
				end
				Citizen.Wait(3494)
				
				MorgueTime = MorgueTime - 20
			end

			-- graveyard time served
			TriggerServerEvent('esx_morgue:unmorgueTime', -1)
			ESX.Game.Teleport(playerPed, Config.BornLocation)
			IsMorgued = false

			end)
		end
	end)
end)
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if MorgueTime > 0 and IsMorgued then
			if morgueTimer < 0 then
				morgueTimer = MorgueTime
			end

			draw2dText(_U('remaining_msg', ESX.Math.Round(morgueTimer)), { 0.4, 0.8 } )
			morgueTimer = morgueTimer - 0.01
		else
			Citizen.Wait(1000)
		end
	end
end)

RegisterNetEvent('esx_morgue:unmorgue')
AddEventHandler('esx_morgue:unmorgue', function(source)
	unmorgue = true
	MorgueTime = 0
	morgueTimer = 0
end)

-- When player respawns / joins
AddEventHandler('playerSpawned', function(spawn)
	if IsMorgued then
		ESX.Game.Teleport(PlayerPedId(), GraveyardLocation)
	else
		TriggerServerEvent('esx_morgue:checkMorgue')
	end
end)

-- When script starts
Citizen.CreateThread(function()
	Citizen.Wait(2000) -- wait for mysql-async to be ready, this should be enough time
	TriggerServerEvent('esx_morgue:checkMorgue')
end)

-- Create Blips
Citizen.CreateThread(function()
	local blip = AddBlipForCoord(Config.GraveyardBlip.x, Config.GraveyardBlip.y, Config.GraveyardBlip.z)
	SetBlipSprite (blip, 305)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.2)
	SetBlipColour (blip, 76)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(_U('blip_name'))
	EndTextCommandSetBlipName(blip)
end)

function draw2dText(text, pos)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextScale(0.45, 0.45)
	SetTextColour(255, 255, 255, 255)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()

	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(table.unpack(pos))
end

function loadanimdict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end