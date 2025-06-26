-- Server-side logic for Esx_policejob2

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Add server-side event handlers, functions, and callbacks here.
-- We will populate this file further as we refactor the client scripts
-- and identify server-side logic needed for ESX and ox_lib.

RegisterNetEvent('esx_policejob:confiscatePlayerItem')
AddEventHandler('esx_policejob:confiscatePlayerItem', function(target, itemType, itemName, amount)
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    local targetXPlayer = ESX.GetPlayerFromId(target)

    if sourceXPlayer.job.name == 'police' then
        if itemType == 'item_standard' then
            local targetItem = targetXPlayer.getInventoryItem(itemName)
            if targetItem and targetItem.count >= amount then
                targetXPlayer.removeInventoryItem(itemName, amount)
                sourceXPlayer.addInventoryItem(itemName, amount)
                -- Notify players
                TriggerClientEvent('br_notify:show', source, 'success', 'Confiscated', 'You confiscated ' .. amount .. 'x ' .. itemName .. ' from the suspect.', 5000)
                TriggerClientEvent('br_notify:show', target, 'error', 'Item Confiscated', 'An officer confiscated ' .. amount .. 'x ' .. itemName .. ' from you.', 5000)
            else
                TriggerClientEvent('br_notify:show', source, 'error', 'Error', 'Suspect does not have enough ' .. itemName .. '.', 5000)
            end
        elseif itemType == 'item_account' then
            -- Assuming 'item_account' refers to money accounts like 'black_money'
            if targetXPlayer.getAccount(itemName) >= amount then
                targetXPlayer.removeAccountMoney(itemName, amount)
                sourceXPlayer.addAccountMoney(itemName, amount) -- Or add to police society account: TriggerEvent('esx_addonaccount:getSharedAccount', 'society_police', function(account) account.addMoney(amount) end)
                TriggerClientEvent('br_notify:show', source, 'success', 'Confiscated', 'You confiscated $' .. amount .. ' ' .. itemName .. ' from the suspect.', 5000)
                TriggerClientEvent('br_notify:show', target, 'error', 'Money Confiscated', 'An officer confiscated $' .. amount .. ' ' .. itemName .. ' from you.', 5000)
            else
                TriggerClientEvent('br_notify:show', source, 'error', 'Error', 'Suspect does not have enough ' .. itemName .. '.', 5000)
            end
        elseif itemType == 'item_weapon' then
            if targetXPlayer.hasWeapon(itemName) then
                targetXPlayer.removeWeapon(itemName, amount) -- Amount here might represent ammo, or just remove the weapon if amount is 1
                sourceXPlayer.addWeapon(itemName, amount) -- Or add to police armory
                 TriggerClientEvent('br_notify:show', source, 'success', 'Confiscated', 'You confiscated ' .. ESX.GetWeaponLabel(itemName) .. ' from the suspect.', 5000)
                TriggerClientEvent('br_notify:show', target, 'error', 'Weapon Confiscated', 'An officer confiscated ' .. ESX.GetWeaponLabel(itemName) .. ' from you.', 5000)
            else
                TriggerClientEvent('br_notify:show', source, 'error', 'Error', 'Suspect does not have ' .. ESX.GetWeaponLabel(itemName) .. '.', 5000)
            end
        end
    else
        -- Handle error: source is not a police officer
        print('ESX_POLICEJOB: confiscatePlayerItem - Source player is not police: ' .. sourceXPlayer.identifier)
    end
end)

-- Example of a server callback that might be needed
ESX.RegisterServerCallback('esx_policejob:getFineList', function(source, cb, category)
    local fines = {}
    -- This should be populated from config.lua or a database
    -- For now, sending back an empty table or predefined fines.
    -- Example:
    -- if category == 'traffic_offences' then
    --     fines = {
    --         { label = 'Speeding', amount = 100 },
    --         { label = 'Illegal Parking', amount = 50 }
    --     }
    -- end
    cb(fines)
end)

ESX.RegisterServerCallback('esx_policejob:getVehicleInfos', function(source, cb, plate)
	local vehicleData = {}
	MySQL.Async.fetchAll('SELECT owner, vehicle FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		if result[1] then
			local ownerIdentifier = result[1].owner
            local vehicle = json.decode(result[1].vehicle) -- Assuming vehicle model/name is stored in a JSON string
            local ownerXPlayer = ESX.GetPlayerFromIdentifier(ownerIdentifier)

            if ownerXPlayer then
                 -- Player is online
                vehicleData = {
                    plate = plate,
                    ownerName = ownerXPlayer.getName(), -- Or GetCharacterName(ownerIdentifier) if using multicharacter
                    modelName = vehicle.model, -- This depends on how owned_vehicles stores vehicle info
                    -- Add more info as needed
                }
            else
                -- Player is offline, try to get character name from database if possible
                -- This part highly depends on your character system (e.g., users table)
                MySQL.Async.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier', { -- Adjust table/column names
                    ['@identifier'] = ownerIdentifier
                }, function(userResult)
                    if userResult[1] then
                        vehicleData = {
                            plate = plate,
                            ownerName = userResult[1].firstname .. ' ' .. userResult[1].lastname,
                            modelName = vehicle.model,
                            -- Add more info as needed
                        }
                    else
                        vehicleData = { plate = plate, ownerName = "Unknown/Offline", modelName = vehicle.model }
                    end
                    cb(vehicleData)
                end)
                return -- Important: return here because the callback is handled in the async user fetch
            end
		else
			vehicleData = { plate = plate, ownerName = "Unknown/No Record", modelName = "Unknown" }
		end
		cb(vehicleData)
	end)
end)

-- Jail related events (example structure, needs actual logic)
RegisterNetEvent('esx_policejob:jailPlayer')
AddEventHandler('esx_policejob:jailPlayer', function(target, jailTime)
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    if sourceXPlayer.job.name == 'police' then
        TriggerClientEvent('esx_jail:sendToJail', target, jailTime * 60) -- Assuming esx_jail expects seconds
        TriggerClientEvent('br_notify:show', source, 'success', 'Jailed', 'Suspect has been jailed for ' .. jailTime .. ' minutes.', 5000)
        TriggerClientEvent('br_notify:show', target, 'error', 'Jailed', 'You have been jailed for ' .. jailTime .. ' minutes.', 5000)
    end
end)

RegisterNetEvent('esx_policejob:unJailPlayer')
AddEventHandler('esx_policejob:unJailPlayer', function(target)
    local sourceXPlayer = ESX.GetPlayerFromId(source)
    if sourceXPlayer.job.name == 'police' then
        TriggerClientEvent('esx_jail:unjailQuest', target) -- This event might differ based on your jail script
        TriggerClientEvent('br_notify:show', source, 'success', 'Unjailed', 'Suspect has been released from jail.', 5000)
        TriggerClientEvent('br_notify:show', target, 'info', 'Unjailed', 'You have been released from jail by an officer.', 5000)
    end
end)

print('[esx_policejob] Server script loaded.')
-- More functionality will be added as we refactor client scripts.
-- For example, handling fines, impounding vehicles, etc.
-- It's important to understand what server interactions are needed by the client logic.
-- This often involves replacing QBCore callbacks/events with ESX equivalents.

-- Placeholder for okokBilling integration (example: sending a bill)
-- This function would be called from client or other server events
function SendBill(targetId, authorName, label, amount)
    -- This depends on how okokBilling is structured.
    -- It might be an event or an export.
    -- Example if it's an event:
    -- TriggerServerEvent('okokBilling:createBill', targetId, authorName, label, amount)
    -- Or if it's an export:
    -- exports.okokBilling:createBill(targetId, authorName, label, amount)
    print(string.format("Attempting to send bill to %s from %s for %s: $%s (okokBilling integration needed)", targetId, authorName, label, amount))
end

-- Community service command trigger
RegisterCommand('coms', function(source, args, rawCommand)
    local src = source
    -- Logic for community service
    -- This could involve:
    -- 1. Setting player metadata (e.g., player.set('community_service_active', true))
    -- 2. Triggering a client event to start a task/minigame
    -- 3. Notifying the player
    TriggerClientEvent('br_notify:show', src, 'info', 'Community Service', 'You have started community service.', 5000)
    -- Example: Trigger a client event that handles the actual service (e.g., go to location, perform animation)
    TriggerClientEvent('esx_policejob:startCommunityService', src)
end, false) -- false to allow anyone to use it if it's meant to be triggered by an interaction, true if only specific permission

-- Add more server logic as needed during refactoring
-- Consider what QBCore server events/callbacks were used and find/create ESX equivalents.
-- For example, player search, vehicle interactions, etc.
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

MySQL.ready(function()
    print("MySQL is ready. esx_policejob server script initialized.")
end)

-- Ensure you have 'mysql-async' in your server dependencies.
-- Example of fetching fines from a database table (replace with your actual table and columns)
-- This is just a placeholder to show how you might load configurable data.
local fineTypes = {}

function LoadFineTypes()
    MySQL.Async.fetchAll('SELECT * FROM fine_types', {}, function(result)
        for i=1, #result, 1 do
            table.insert(fineTypes, {
                label = result[i].label,
                amount = result[i].amount,
                category = result[i].category -- Assuming you have a category column
            })
        end
        print('[esx_policejob] Loaded ' .. #fineTypes .. ' fine types.')
    end)
end

-- Call this on resource start or when MySQL is ready
-- AddEventHandler('onMySQLReady', function() LoadFineTypes() end) -- if using an event for mysql ready
-- Or if MySQL.ready is the standard:
-- MySQL.ready(function()
--    LoadFineTypes()
-- end)

ESX.RegisterServerCallback('esx_policejob:getFineList', function(source, cb, category)
    local categorizedFines = {}
    -- If fineTypes is loaded from DB:
    -- for _, fine in ipairs(fineTypes) do
    --     if fine.category == category then
    --         table.insert(categorizedFines, fine)
    --     end
    -- end
    -- cb(categorizedFines)

    -- For now, using placeholder fines from config.lua structure (converted to ESX)
    if Config.FineTypes[category] then
        cb(Config.FineTypes[category])
    else
        cb({})
    end
end)

-- More server-side handlers will be added here based on client script requirements.
-- For example, functions for cuffing, putting in vehicle, etc., might need server validation
-- or interaction with other resources (e.g., for animations if not handled client-side).
print("ESX Police Job - Server Script Initialized")
