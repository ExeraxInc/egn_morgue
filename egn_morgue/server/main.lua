ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand('morgue', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	local target = ESX.GetPlayerFromId(args[2])
	if xPlayer.job.name == 'ambulance' then
		if args[1] and GetPlayerName(args[1]) ~= nil and tonumber(args[2]) then
			TriggerEvent('esx_morgue:sendToGraveyard', tonumber(args[1]), tonumber(args[2] * 60))
		else
			TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Invalid player ID or graveyard time!' } } )
		end
	else
		TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'inform', text = 'Insufficient Permissions', style = { ['background-color'] = '#fc030f', ['color'] = '#fff' } })
	end
end)

function GetCharacterName(source)
    local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
        ['@identifier'] = GetPlayerIdentifiers(source)[1]
    })

    if result[1] and result[1].firstname and result[1].lastname then
        if Config.OnlyFirstname then
            return result[1].firstname
        else
            return ('%s %s'):format(result[1].firstname, result[1].lastname)
        end
    else
        return GetPlayerName(source)
    end
end

function notification(text)
    TriggerClientEvent('egn_morgue:showNotification', source, text)
end

-- send to graveyard and register in database
RegisterServerEvent('esx_morgue:sendToGraveyard')
AddEventHandler('esx_morgue:sendToGraveyard', function(target, morgueTimer)
	local identifier = GetPlayerIdentifiers(target)[1]

	MySQL.Async.fetchAll('SELECT * FROM morgue WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE morgue SET morgue_time = @morgue_time WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@morgue_time'] = morgueTimer
			})
		else
			MySQL.Async.execute('INSERT INTO morgue (identifier, morgue_time) VALUES (@identifier, @morgue_time)', {
				['@identifier'] = identifier,
				['@morgue_time'] = morgueTimer
			})
		end
	end)

	TriggerClientEvent('esx_ambulancejob:revive', target)
	TriggerClientEvent('chat:addMessage', -1, {
		template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(58, 58, 52, 0.6); border-radius: 3px;"><i class="fas fa-cross"></i> <b>Morgue</b> {1}</div>',
		args = { _U('morgue'), _U('morgued_msg', GetCharacterName(target), ESX.Math.Round(morgueTimer / 60)) }, color = { 79, 0, 4 } 
	})
	TriggerClientEvent('esx_morgue:morgue', target, morgueTimer)
end)

-- should the player be in graveyard?
ESX.RegisterServerCallback('esx_morgue:checkMorgue', function(source, cb)
	local _source = source -- cannot parse source to client trigger for some weird reason
	local identifier = GetPlayerIdentifiers(_source)[1] -- get steam identifier

	MySQL.Async.fetchAll('SELECT * FROM morgue WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] ~= nil then
			TriggerClientEvent('chat:addMessage', {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(58, 58, 52, 0.6); border-radius: 3px;"><i class="fas fa-cross"></i> <b>Morgue</b> {1}</div>',
				args = { _U('morgue'), _U('morgued_msg', GetCharacterName(_source), ESX.Math.Round(result[1].morgue_time / 60)) }, color = { 79, 0, 4 } 
			})
			TriggerClientEvent('esx_morgue:morgue', _source, tonumber(result[1].morgue_time))
			cb(true)
		end
	end)
end)
-- unjail after time served
RegisterServerEvent('esx_morgue:unmorgueTime')
AddEventHandler('esx_morgue:unmorgueTime', function()
	unmorgue(source)
end)

-- keep jailtime updated
RegisterServerEvent('esx_morgue:updateRemaining')
AddEventHandler('esx_morgue:updateRemaining', function(morgueTimer)
	local identifier = GetPlayerIdentifiers(source)[1]
	MySQL.Async.fetchAll('SELECT * FROM morgue WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE morgue SET morgue_time = @morgue_time WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@morgue_time'] = morgueTimer
			})
		end
	end)
end)

function unmorgue(target)
	local identifier = GetPlayerIdentifiers(target)[1]
	MySQL.Async.fetchAll('SELECT * FROM morgue WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('DELETE from morgue WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})

			-- TriggerClientEvent('chat:addMessage', -1, { args = { _U('morgue'), _U('unmorgued', GetCharacterName(target)) }, color = { 79, 0, 4 } })
		end
	end)

	TriggerClientEvent('esx_morgue:unmorgue', target)
end