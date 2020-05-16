ESX = nil
local IsMorgued, unmorgued, MorgueTime, morgueTimer, GraveyardLocation = false, false, 0, 0, Config.GraveyardLocation 

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
		Wait(1000)
		if IsMorgued then
			InvalidateIdleCam()
		end
	end 
end)

-- Disable most inputs when in Graveyard
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if IsMorgued then
			DisableAllControlActions(0)
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
			Citizen.Wait(0)
		end
		TriggerEvent('esx_ambulancejob:revive', GetPlayerFromServerId(playerPed))

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
    		TaskPlayAnim(playerPed, 'missarmenian2', 'corpse_search_exit_ped', 8.0, -8,-1, 2, 0, 0, 0, 0)
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

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.TriggerServerCallback('esx_morgue:checkMorgue', function(Morgued)
		if Morgued then
			ESX.Game.Teleport(PlayerPedId(), GraveyardLocation)
		end
	end)
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