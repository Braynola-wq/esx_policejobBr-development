-- Variables
local CurrentStatusList = {}
local Casings = {}
local CurrentCasing = nil
local Blooddrops = {}
local CurrentBlooddrop = nil
local Fingerprints = {}
local CurrentFingerprint = 0
local shotAmount = 0

local StatusList = {
    ['fight'] = "Red hands",
    ['widepupils'] = "Wide Pupils",
    ['redeyes'] = 'Red Eyes',
    ['weedsmell'] = 'Smells like weed',
    ['gunpowder'] = 'אבקת שריפה בבגדים',
    ['chemicals'] = 'smells chemical',
    ['heavybreath'] = 'Breathes heavily',
    ['sweat'] = 'Sweats a lot',
    ['handbleed'] = 'Blood on hands',
    ['confused'] = 'Confused',
    ['alcohol'] = 'Smells like alcohol',
    ['heavyalcohol'] = 'Smells very much like alcohol',
    ['agitated'] = 'Agitated - Signs of Meth Use'
}


local WhitelistedWeapons = {
    `weapon_unarmed`,
    `weapon_snowball`,
    `weapon_stungun`,
    `weapon_pumpshotgun`,
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}

-- Functions
fontId = RegisterFontId('Rubik-Regular')
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 280
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function WhitelistedWeapon(weapon)
    for i = 1, #WhitelistedWeapons do
        if WhitelistedWeapons[i] == weapon then
            return true
        end
    end
    if(GetWeapontypeSlot(weapon) == 0) then return true end
    return false
end

local lastcasing = nil

local function DropBulletCasing(weapon, ped)
    local inrampage = exports['gi-grangeillegal']:InRampage()
    if(not inrampage) then
        local randX = math.random() + math.random(-1, 1)
        local randY = math.random() + math.random(-1, 1)
        local coords = GetOffsetFromEntityInWorldCoords(ped, randX, randY, 0)
        ESX.SEvent('evidence:server:CreateCasing', weapon, coords)
        Wait(300)
    end
end

local function DnaHash(s)
    local h = string.gsub(s, '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
    return h
end

-- Events
RegisterNetEvent('evidence:client:SetStatus', function(statusId, time)
    if time > 0 and StatusList[statusId] then
        if (CurrentStatusList == nil or CurrentStatusList[statusId] == nil) or
            (CurrentStatusList[statusId] and CurrentStatusList[statusId].time < 20) then
            CurrentStatusList[statusId] = {
                text = StatusList[statusId],
                time = time
            }
            ESX.ShowHDNotification("",CurrentStatusList[statusId].text, 'error')
        end
    elseif StatusList[statusId] then
        CurrentStatusList[statusId] = nil
    end
    ESX.SEvent('evidence:server:UpdateStatus', CurrentStatusList)
end)

RegisterNetEvent('evidence:client:AddBlooddrop', function(bloodId, id_number, bloodtype, coords)
    Blooddrops[bloodId] = {
        id_number = id_number,
        bloodtype = bloodtype,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        }
    }
end)

RegisterNetEvent('evidence:client:RemoveBlooddrop', function(bloodId)
    Blooddrops[bloodId] = nil
    CurrentBlooddrop = 0
end)

RegisterNetEvent('evidence:client:AddFingerPrint', function(fingerId, fingerprint, coords)
    Fingerprints[fingerId] = {
        fingerprint = fingerprint,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        }
    }
end)

RegisterNetEvent('evidence:client:RemoveFingerprint', function(fingerId)
    Fingerprints[fingerId] = nil
    CurrentFingerprint = 0
end)

RegisterNetEvent('evidence:client:ClearBlooddropsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local blooddropList = {}
    ESX.Game.Progress('clear_blooddrops', 'Blood Cleared', 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos -
                        vector3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) <
                    10.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            ESX.SEvent('evidence:server:ClearBlooddrops', blooddropList)
            ESX.ShowHDNotification("Police Evidence",'Clearing Blood...', 'success')
        end
    end, function() -- Cancel
        ESX.ShowHDNotification("Police Evidence",'Blood NOT cleared', 'error')
    end)
end)

RegisterNetEvent('evidence:client:AddCasing', function(casingId, weapon, coords, serie)
    Casings[casingId] = {
        type = joaat(weapon),
        actualwep = weapon,
        serie = serie and serie or 'Serial number not visible...',
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        }
    }
end)

RegisterNetEvent('evidence:client:RemoveCasing', function(casingId)
    Casings[casingId] = nil
    CurrentCasing = 0
end)

RegisterNetEvent('evidence:client:ClearCasingsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local casingList = {}
    ESX.Game.Progress('clear_casings', 'Removing bullet casings..', 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vector3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) <
                    10.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            ESX.SEvent('evidence:server:ClearCasings', casingList)
            ESX.ShowHDNotification("Police Evidence",'Bullet Casings Removed...', 'success')
        end
    end, function() -- Cancel
        ESX.ShowHDNotification("Police Evidence",'Bullet Casings NOT Removed', 'error')
    end)
end)

-- Threads

CreateThread(function()
    while true do
        Wait(10000)
        if ESX.IsPlayerLoaded() then
            if CurrentStatusList and next(CurrentStatusList) then
                for k, _ in pairs(CurrentStatusList) do
                    if CurrentStatusList[k].time > 0 then
                        CurrentStatusList[k].time = CurrentStatusList[k].time - 10
                    else
                        CurrentStatusList[k].time = 0
                    end
                end
                ESX.SEvent('evidence:server:UpdateStatus', CurrentStatusList)
            end
            if shotAmount > 0 then
                shotAmount = 0
            end
        end
    end
end)

CreateThread(function() -- Gunpowder Status when shooting
    while true do
        Wait(1)
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local weapon = GetSelectedPedWeapon(ped)
            if not WhitelistedWeapon(weapon) then
                shotAmount = shotAmount + 1
                if shotAmount > 5 and (CurrentStatusList == nil or CurrentStatusList['gunpowder'] == nil) then
                    if math.random(1, 10) <= 7 then
                        local inrampage = exports['gi-grangeillegal']:InRampage()
                        if(not inrampage) then
                            TriggerEvent('evidence:client:SetStatus', 'gunpowder', 200)
                        end
                    end
                end
                if (not Config.IgnoreSilencer or not IsPedCurrentWeaponSilenced(ped)) then
                    if(not lastcasing or (GetTimeDifference(GetGameTimer(), lastcasing) > 4500)) then
                        local currentWeapon = exports.ox_inventory:getCurrentWeapon()
                        if(currentWeapon) then
                            lastcasing = GetGameTimer()
                            DropBulletCasing(currentWeapon.slot, ped)
                        end
                    end
                end
            end
        end
    end
end)

local function SetStatus(name,state)
    CurrentStatusList[name] = state
    ESX.SEvent('evidence:server:UpdateStatus', CurrentStatusList)
end

exports("SetStatus",SetStatus)

local function PickUpAnim()
    local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 1.0, 1000, 51, 0.0, false, false, false)
    RemoveAnimDict(dict)
end

local function GetWepAmmoLabel(wep)
    local item = exports.ox_inventory:Items(wep)
    if(item and item.ammoname) then
        return Config.AmmoLabels[item.ammoname] or "ERROR"
    else
        return "ERROR"
    end
end

CreateThread(function()
    while true do
        local sleep = 300
        if CurrentCasing and CurrentCasing ~= 0 then
            local pos = GetEntityCoords(PlayerPedId())
            if #(pos - vector3(Casings[CurrentCasing].coords.x, Casings[CurrentCasing].coords.y, Casings[CurrentCasing].coords.z)) < 1.5 then
                sleep = 0
                DrawText3D(Casings[CurrentCasing].coords.x, Casings[CurrentCasing].coords.y, Casings[CurrentCasing].coords.z,  '[~g~G~s~] לימרת '..Casings[CurrentCasing].type)
                if IsControlJustReleased(0, 47) then
                    local s1, s2 = GetStreetNameAtCoord(Casings[CurrentCasing].coords.x, Casings[CurrentCasing].coords.y, Casings[CurrentCasing].coords.z)
                    local street1 = GetStreetNameFromHashKey(s1)
                    local street2 = GetStreetNameFromHashKey(s2)
                    local streetLabel = street1
                    if street2 then
                        streetLabel = streetLabel .. ' | ' .. street2
                    end

                    local info = {
                        label = "Bullet Casing",
                        type = 'casing',
                        street = streetLabel:gsub("%'", ''),
                        ammolabel = GetWepAmmoLabel(Casings[CurrentCasing].actualwep),
                        ammotype = Casings[CurrentCasing].type,
                        serie = Casings[CurrentCasing].serie
                    }
                    ESX.SEvent('evidence:server:AddCasingToInventory', CurrentCasing, info)
                    PickUpAnim()
                end
            end
        end

        if CurrentBlooddrop and CurrentBlooddrop ~= 0 then
            local pos = GetEntityCoords(PlayerPedId())
            if #(pos - vector3(Blooddrops[CurrentBlooddrop].coords.x, Blooddrops[CurrentBlooddrop].coords.y, Blooddrops[CurrentBlooddrop].coords.z)) < 1.5 then
                sleep = 0
                DrawText3D(Blooddrops[CurrentBlooddrop].coords.x, Blooddrops[CurrentBlooddrop].coords.y, Blooddrops[CurrentBlooddrop].coords.z, '[~g~G~s~] םד '..DnaHash(Blooddrops[CurrentBlooddrop].id_number))
                if IsControlJustReleased(0, 47) then
                    local s1, s2 = GetStreetNameAtCoord(Blooddrops[CurrentBlooddrop].coords.x, Blooddrops[CurrentBlooddrop].coords.y, Blooddrops[CurrentBlooddrop].coords.z)
                    local street1 = GetStreetNameFromHashKey(s1)
                    local street2 = GetStreetNameFromHashKey(s2)
                    local streetLabel = street1
                    if street2 then
                        streetLabel = streetLabel .. ' | ' .. street2
                    end
                    local info = {
                        label = "Blood",
                        type = 'blood',
                        street = streetLabel:gsub("%'", ''),
                        dnalabel = DnaHash(Blooddrops[CurrentBlooddrop].id_number),
                        bloodtype = Blooddrops[CurrentBlooddrop].bloodtype
                    }
                    ESX.SEvent('evidence:server:AddBlooddropToInventory', CurrentBlooddrop, info)
                    PickUpAnim()
                end
            end
        end

        if CurrentFingerprint and CurrentFingerprint ~= 0 then
            local pos = GetEntityCoords(PlayerPedId())
            if #(pos - vector3(Fingerprints[CurrentFingerprint].coords.x, Fingerprints[CurrentFingerprint].coords.y, Fingerprints[CurrentFingerprint].coords.z)) < 1.5 then
                sleep = 0
                DrawText3D(Fingerprints[CurrentFingerprint].coords.x, Fingerprints[CurrentFingerprint].coords.y, Fingerprints[CurrentFingerprint].coords.z, '[G] עבצא תעיבט')
                if IsControlJustReleased(0, 47) then
                    local s1, s2 = GetStreetNameAtCoord(Fingerprints[CurrentFingerprint].coords.x, Fingerprints[CurrentFingerprint].coords.y, Fingerprints[CurrentFingerprint].coords.z)
                    local street1 = GetStreetNameFromHashKey(s1)
                    local street2 = GetStreetNameFromHashKey(s2)
                    local streetLabel = street1
                    if street2 then
                        streetLabel = streetLabel .. ' | ' .. street2
                    end
                    local info = {
                        label = "Fingerprint",
                        type = 'fingerprint',
                        street = streetLabel:gsub("%'", ''),
                        fingerprint = Fingerprints[CurrentFingerprint].fingerprint
                    }
                    ESX.SEvent('evidence:server:AddFingerprintToInventory', CurrentFingerprint, info)
                    PickUpAnim()
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand("gsr",function(source,args)

    if ESX.PlayerData.job.name ~= 'police' then
        ESX.ShowHDNotification("","הפקודה הזאת היא לשוטרים בלבד","info")
        return
    end

    local ped = PlayerPedId()
    local targetid = tonumber(args[1])
    if not targetid then 
        ESX.ShowHDNotification("",'Syntax: /gsr [id]',"info")
        return 
    end
    local target = GetPlayerFromServerId(targetid)
    if target == -1 then 
        ESX.ShowHDNotification("","המטרה לא נמצאה","info")
        return 
    end

    local coords = GetEntityCoords(ped)
    local targetPed = GetPlayerPed(target)
    local targetCoords = GetEntityCoords(targetPed)

    if #(coords - targetCoords) < 2.0 then
        ESX.SEvent('evidence:server:getGunpowder',targetid)
    else
        ESX.ShowHDNotification("","המטרה רחוקה מדי","info")
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if CurrentStatusList ~= nil and CurrentStatusList['gunpowder'] ~= nil then
            local ped = PlayerPedId()
            if IsPedSwimmingUnderWater(ped) then
                ESX.ShowHDNotification("","האבקת שריפה נשטפה במים","info")
                CurrentStatusList['gunpowder'] = nil
                ESX.SEvent('evidence:server:UpdateStatus', CurrentStatusList)
            end
        end
                
    end
end)

AddEventHandler("evidence:client:CleanGunpowder",function()
    if CurrentStatusList ~= nil and CurrentStatusList['gunpowder'] ~= nil then
        ESX.ShowHDNotification("","האבקת שריפה התנקתה מהספריי","info")
        CurrentStatusList['gunpowder'] = nil
        ESX.SEvent('evidence:server:UpdateStatus', CurrentStatusList)
    end
end)

AddEventHandler("evidence:client:ClearGunpowder",function()
    if CurrentStatusList ~= nil and CurrentStatusList['gunpowder'] ~= nil then
        local cleanspray = ESX.GetInventoryItem("cleanvehicle")


        if(not cleanspray or cleanspray.count == 0) then
            ESX.ShowRGBNotification("error","אין עליך ספריי ניקיון")
            ClearPedTasksImmediately(PlayerPedId())
            return
        end

        ESX.Game.Progress('clean_gunpowder', 'מנקה את הגוף', 5000, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true
        }, {
            animDict = "move_m@_idles@shake_off", 
            anim = "shakeoff_1",
        }, {}, {}, function() -- Done
            local ped = PlayerPedId()
            SetPedSweat(ped,0.0)
            SetPedWetnessHeight(ped,30.0)
            ESX.ShowHDNotification("","האבקת שריפה התנקתה מהספריי","info")
            CurrentStatusList['gunpowder'] = nil
            ESX.SEvent('evidence:server:UpdateStatus', CurrentStatusList)
            TriggerServerEvent('esx_extraitems:removecleaner')
            StopAnimTask(ped,"move_m@_idles@shake_off","shakeoff_1",3.0)
        end, function() -- Cancel
            StopAnimTask(PlayerPedId(),"move_m@_idles@shake_off","shakeoff_1",3.0)
        end,"cleanvehicle")

    end
end)

CreateThread(function()
    while true do
        local sleep = 2000
        if ESX.IsPlayerLoaded() and ESX.PlayerData.job and ESX.PlayerData.job.name == "police" then
            local ped = PlayerPedId()
            if IsPlayerFreeAiming(PlayerId()) and GetSelectedPedWeapon(ped) == `WEAPON_FLASHLIGHT` then
                sleep = 0
                local pos = GetEntityCoords(ped, true)

                if next(Casings) then
                    for k, v in pairs(Casings) do
                        if #(pos - vector3(v.coords.x, v.coords.y, v.coords.z)) < 1.5 then
                            CurrentCasing = k
                        end
                    end
                end

                if next(Blooddrops) then
                    for k, v in pairs(Blooddrops) do
                        if #(pos - vector3(v.coords.x, v.coords.y, v.coords.z)) < 1.5 then
                            CurrentBlooddrop = k
                        end
                    end
                end

                if next(Fingerprints) then
                    for k, v in pairs(Fingerprints) do
                        if #(pos - vector3(v.coords.x, v.coords.y, v.coords.z)) < 1.5 then
                            CurrentFingerprint = k
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)


local function openFingerprintUI()
    SendNUIMessage({
        type = 'fingerprintOpen'
    })
    inFingerprint = true
    SetNuiFocus(true, true)
end
local inFingerprint = false
local FingerPrintSessionId = nil


--NUI Callbacks
RegisterNUICallback('closeFingerprint', function(_, cb)
    SetNuiFocus(false, false)
    inFingerprint = false
    cb('ok')
end)

local lastFinger = false
RegisterNUICallback('doFingerScan', function(_, cb)
    if not ESX.Game.IsWearingGloves() then
        if not lastFinger then
            TriggerServerEvent('police:server:showFingerprintId', FingerPrintSessionId)
            lastFinger = true
            SetTimeout(3500, function()
                lastFinger = false
            end)
        else
            ESX.ShowHDNotification("Police Evidence","נא להמתין בין כל לחיצה על הסורק אצבע", "error")
        end
    else
        ESX.ShowHDNotification("Police Evidence","אתה לא יכול לשים את האצבע על הסורק כי אתה לובש כפפות","error")
    end
    cb('ok')
end)

RegisterNetEvent('police:client:showFingerprint', function(playerId)
    openFingerprintUI()
    FingerPrintSessionId = playerId
end)

RegisterNetEvent('police:client:showFingerprintId', function(fid)
    SendNUIMessage({
        type = 'updateFingerprintId',
        fingerprintId = fid
    })
    PlaySound(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', 0, 0, 1)
end)

RegisterNetEvent('esx_policejob:client:scanFingerPrint', function()
    local player, distance = ESX.Game.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        if ESX.PlayerData.job.name == 'police' then
            TriggerServerEvent('police:server:showFingerprint', playerId)
        else
            ESX.ShowHDNotification("Police Evidence","אתה לא שוטר", 'error')
        end
    else
        ESX.ShowHDNotification("Police Evidence","לא נמצא אף אחד באיזור שלך", 'error')
    end
end)

function ForceFingerprint()
    if not NearFingerScanner() then
        ESX.ShowRGBNotification("error","אתה לא נמצא ליד סורק")
        return
    end
    local player, distance = ESX.Game.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        if ESX.PlayerData.job.name == 'police' then
            if not ESX.Game.IsWearingGloves(GetPlayerPed(player)) then
                openFingerprintUI()
                TriggerServerEvent('police:server:forceFingerprint', playerId)
            else
                ESX.ShowHDNotification("Police Evidence","השחקן לובש כפפות לכן אי אפשר לסרוק לו את האצבע","error")
            end
        else
            ESX.ShowHDNotification("Police Evidence","אתה לא שוטר", 'error')
        end
    else
        ESX.ShowHDNotification("Police Evidence","לא נמצא אף אחד באיזור שלך", 'error')
    end
end


RegisterNetEvent("police:client:forceFingerprint",function(src)
    if src then
        FingerPrintSessionId = src
        openFingerprintUI()
        TriggerServerEvent('police:server:showFingerprintId', src)
    end
end)


function NearFingerScanner()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, v in pairs(Config.FingerScanners) do
        if #(coords - v) < 10.0 then 
            return true
        end
    end

    for k,value in pairs(Config.PoliceStations) do
		if(value.Archive) then
            for i=1, #value.Archive, 1 do
                if #(coords - value.Archive[i]) < 10.0 then
                    return true
                end
            end
        end
    end
    return false
end



-- local fingerprintZones = {}
-- for _, v in pairs(Config.FingerScanners) do
--     fingerprintZones[#fingerprintZones + 1] = BoxZone:Create(
--         vector3(vector3(v.x, v.y, v.z)), 2, 1, {
--             name = 'box_zone',
--             debugPoly = false,
--             minZ = v.z - 1,
--             maxZ = v.z + 1,
--         })
-- end

-- local fingerprintCombo = ComboZone:Create(fingerprintZones, { name = 'fingerprintCombo', debugPoly = false })
-- fingerprintCombo:onPlayerInOut(function(isPointInside)
--     if isPointInside then
--         inFingerprint = true
--         if ESX.PlayerData.job.name == 'police' then
--             ESX.TextUI("[E] לסרוק את האצבע", "darkblue","left")
--             fingerprint()
--         end
--     else
--         inFingerprint = false
--         ESX.HideUI()
--     end
-- end)
-- Fingerprint
for k, v in pairs(Config.FingerScanners) do
    exports.ox_target:addBoxZone({
        coords = vec3(v.x, v.y, v.z),
        size = vec3(0.5, 0.5, 0.5), -- Adjust size as needed
        rotation = 0, -- Adjust rotation if needed
        debug = false, -- Set to true for debug poly
        options = {
            {
                name = 'police_fingerprint_' .. k,
                event = 'esx_policejob:client:scanFingerPrint',
                icon = 'fas fa-fingerprint',
                label = 'טביעת אצבע',
                groups = 'police', -- Restrict to police job
                distance = 1.5
            }
        }
    })
end


if Config.UseBlood then
    local lastblood

    AddEventHandler('gameEventTriggered', function (name, data)
        
        if name == 'CEventNetworkEntityDamage' then

            local victim = data[1]
            local attacker = data[2]

            if victim == attacker or not IsEntityAPed(victim) or not IsEntityAPed(attacker) then
                return
            end
            local weapon = data[7]
            local weptype = GetWeaponDamageType(weapon)
            if(weptype ~= 3 and weptype ~= 2 and weptype ~= 5) then
                return
            end

            if weapon == `WEAPON_UNARMED` then return end

            
            -- local attackerid = NetworkGetPlayerIndexFromPed(attacker)
            local victimid = NetworkGetPlayerIndexFromPed(victim)
            -- if(attackerid == -1 or victimid == -1) then
            if(victimid == -1) then
                return
            end
                
            -- if(IsPedAPlayer(attacker)) then
            if(victimid == PlayerId()) then
                if GetPedArmour(PlayerPedId()) <= 0 then
                    if math.random(0,100) <= Config.BloodChance then
                        if(not lastblood or (GetTimeDifference(GetGameTimer(), lastblood) > 10000)) then
                            lastblood = GetGameTimer()
                            local inrampage = exports['gi-grangeillegal']:InRampage()
                            if(not inrampage) then
                                local randX = math.random() + math.random(-1, 1)
                                local randY = math.random() + math.random(-1, 1)
                                local coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), randX, randY, 0)
                                TriggerServerEvent('evidence:server:CreateBloodDrop', ESX.PlayerData.id_number, ESX.PlayerData.bloodtype, coords)
                            end
                        end
                    end
                end
            end
            

        end
    end)
end

local function GetItemFromSlot(slot)
	local inventory = ESX.GetPlayerData().inventory
	for k,v in pairs(inventory) do
		if(v.slot == slot) then
			return v
		end
	end
	return nil
end

AddEventHandler("esx_policejob:client:copyevidence",function(slot)
    local item = GetItemFromSlot(slot)
    if(item) then
        local bagtype = item.metadata.type
        if(bagtype == "casing") then
            if(item.metadata.serial) then
                TriggerEvent("CopyToClipBoard",item.metadata.serial)
            elseif(item.metadata.serie) then
                TriggerEvent("CopyToClipBoard",item.metadata.serie)
            end
        elseif(bagtype == "blood" or bagtype == "dna") then
            if(item.metadata.dnalabel) then
                TriggerEvent("CopyToClipBoard",item.metadata.dnalabel)
            end
        elseif(bagtype == "fingerprint") then
            if(item.metadata.fingerprint) then
                TriggerEvent("CopyToClipBoard",item.metadata.fingerprint)
            end
        end
    end
end)

exports.ox_inventory:displayMetadata({
    type = 'type',
    street = "Street",
    dnalabel = 'dnalabel',
    bloodtype = "bloodtype",
    ammotype = 'ammotype',
    ammolabel = 'ammolabel',
    serial = "Serial",
    serie = "Serial",
    fingerprint = "Fingerprint"
})