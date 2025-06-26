-- Server-side script for evidence system
-- This file was created to satisfy the fxmanifest.lua entry.
-- Add necessary server-side logic for evidence handling here.

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Example: Register server events that client/evidence.lua might trigger
-- RegisterNetEvent('evidence:server:CreateCasing')
-- AddEventHandler('evidence:server:CreateCasing', function(weapon, coords)
--     -- Logic to handle casing creation, possibly sync with other clients
--     -- TriggerClientEvent('evidence:client:AddCasing', -1, newCasingId, weapon, coords, serialNumber)
-- end)

-- Add other handlers for:
-- evidence:server:UpdateStatus
-- evidence:server:ClearBlooddrops
-- evidence:server:AddCasingToInventory
-- evidence:server:AddBlooddropToInventory
-- evidence:server:AddFingerprintToInventory
-- evidence:server:ClearCasings
-- police:server:showFingerprintId
-- police:server:showFingerprint
-- police:server:forceFingerprint
-- evidence:server:CreateBloodDrop

print('[esx_policejob] server/evidence.lua loaded.')
