ESX = exports["es_extended"]:getSharedObject()

ESX.PlayerData = {}

local Cache = {
    ped = PlayerPedId(),
    vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
}

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        if Cache.ped ~= playerPed then
            Cache.ped = playerPed
        end
        if IsPedInAnyVehicle(playerPed, false) then
            local currentVehicle = GetVehiclePedIsIn(playerPed, false)
            if Cache.vehicle ~= currentVehicle then
                Cache.vehicle = currentVehicle
            end
        elseif Cache.vehicle ~= 0 then
            Cache.vehicle = 0
        end
    end
end)

AddStateBagChangeHandler("ankle", nil, function(bagName, key, value, source, replicated)
    -- Ensure we're handling the state bag for the local player if this is intended for local visual/control changes
    local netId = tonumber(string.gsub(bagName, "player:", ""))
    if netId == GetPlayerServerId(PlayerId()) then
        AnkleCuffed = value
    end
    -- If this needs to affect other players' peds based on their state bags,
    -- you'd need to get the ped from the netId (if it's a player entity state bag)
    -- or handle it based on how 'ankle' state is intended to be used across clients.
end)

RegisterNetEvent("esx_policejob:client:smashWindows",function(netid)
    if(not NetworkDoesEntityExistWithNetworkId(netid)) then return end
    local veh = NetToVeh(netid)
    if(DoesEntityExist(veh)) then
		for i = -1, 10, 1 do -- Smash all possible windows
			if not IsVehicleWindowIntact(veh, i) then SmashVehicleWindow(veh,i) end
		end
		if(veh == Cache.vehicle) then -- Check if it's the player's current vehicle
			TriggerEvent('br_notify:show',"error","Windows Smashed","שברו את החלונות של הרכב שלך", 5000)
			ShakeGameplayCam("SMALL_EXPLOSION_SHAKE",0.5)
		end
	end
end)

-- ApplyStuff function was mostly redundant due to esx:playerLoaded handling ESX.PlayerData.
-- Ensuring ESX.PlayerData is available is handled by the initial ESX setup.

RegisterNuiCallback("timer",function(data,cb)
	TriggerEvent('br_notify:show',"info","Timer","הטיימר נעצר", 5000)
	chasetimer = false
    if cb then cb({}) end
end)

RegisterCommand("bonus", function()
    if not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police" or ESX.PlayerData.job.grade_name ~= "boss" then return end
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > 3.0 then TriggerEvent('br_notify:show','error',"Error",_U('no_players_nearby'), 5000); return end
    local targetid = GetPlayerServerId(closestPlayer)
    if(targetid == 0) then TriggerEvent('br_notify:show',"error","Error","לא נמצא המטרה שבחרת", 5000); return end

    lib.inputDialog("Target: "..GetPlayerName(closestPlayer).." ["..targetid.."]", {
        { type = 'number', label = "כמה כסף", required = true, name = "amount"},
        { type = 'input', label = "הערות", name = "info"}
    }):next(function(inputs)
        if(inputs and inputs.amount) then
            local amount = tonumber(inputs.amount)
            if amount == nil then 
                TriggerEvent('br_notify:show',"error","Input Error","כמות שגויה", 5000)
            elseif amount > 600000 then 
                TriggerEvent('br_notify:show',"error","Input Error",'הסכום המקסימלי הוא 600,000 שקל בלבד', 5000)
            else 
                ESX.SEvent("esx_policejob:HandOutBonus",targetid,amount,inputs.info or "") 
            end
        end
    end)
end)

RegisterKeyMapping('TOGGLESIRMUTE', 'Toggle Siren Mute', 'keyboard', "Y")
RegisterCommand("TOGGLESIRMUTE",function()
    if not ESX.PlayerData.job then return end
	local ped = Cache.ped; local policecar = GetVehiclePedIsIn(ped,false)
	if(policecar ~= 0 and (GetVehicleClass(policecar) == 18 or IsPedInAnyPoliceVehicle(ped))) then
		if(GetPedInVehicleSeat(policecar,-1) ~= ped) then TriggerEvent('br_notify:show',"error","Siren Error",".רק הנהג יכול לשלוט על הסירנה", 5000); return end
		if IsPedInAnyHeli(ped) then return end
		if(ESX.PlayerData.job.name ~= "police" and ESX.PlayerData.job.name ~= "ambulance") then return end
		PlaySoundFrontend(-1, "HACKING_CLICK_GOOD", 0, 1)
        local currentMuteState = Entity(policecar).state.sirensilence or false -- Ensure state bag is checked correctly
		ESX.SEvent("esx_policejob:mutesirens",VehToNet(policecar), not currentMuteState)
	end
end)

AddStateBagChangeHandler("sirensilence", nil, function(bagName, key, value, _, replicated)
    if bagName:sub(1, 7) == "entity:" then
        local entNetId = tonumber(bagName:sub(8))
        if entNetId and NetworkDoesEntityExistWithNetworkId(entNetId) then
            local ent = NetToVeh(entNetId)
		    if(DoesEntityExist(ent)) then SetVehicleHasMutedSirens(ent, value) end
        end
    end
end)

local neverknock_vehicle = false -- Renamed to avoid conflict
AddEventHandler("esx:enteredVehicle",function(vehicle,seat,vehicleDisplayName)
    local model = GetEntityModel(vehicle)
	if(model == joaat("FBI2")) then
		SetPedCanBeKnockedOffVehicle(Cache.ped,1)
		neverknock_vehicle = true
	end
end)

AddEventHandler('esx:exitedVehicle',function(vehicle)
	if(not neverknock_vehicle) then return end
	SetPedCanBeKnockedOffVehicle(Cache.ped,0)
	neverknock_vehicle = false
end)

CreateThread(function()
    while not exports.ox_target do Wait(100) end
    if not Config.Flag or not Config.Flag.Target or not Config.Flag.Default then
        print("[esx_policejob] Flag configuration missing or incomplete. Flag target will not be created.")
        return
    end
	exports.ox_target:addBoxZone({
		coords = vector3(Config.Flag.Target.x, Config.Flag.Target.y, Config.Flag.Target.z),
		size = vec3(2, 2, 2), debug = false,
		options = {
			{ name="flag_up", icon = "fa-solid fa-up-long", label = "הנפת דגל", job = "police",
              onSelect = function() if(ESX.PlayerData.job and ESX.PlayerData.job.name=="police")then ClearPedTasksImmediately(Cache.ped);TaskTurnPedToFaceCoord(Cache.ped,Config.Flag.Target.x,Config.Flag.Target.y,Config.Flag.Target.z,1000);ESX.SEvent("esx_policejob:server:SendFlag",Config.Flag.MaxZ)end end },
			{ name="flag_down", icon = "fa-solid fa-down-long", label = "הורדת דגל", job = "police",
              onSelect = function() if(ESX.PlayerData.job and ESX.PlayerData.job.name=="police")then ClearPedTasksImmediately(Cache.ped);TaskTurnPedToFaceCoord(Cache.ped,Config.Flag.Target.x,Config.Flag.Target.y,Config.Flag.Target.z,1000);ESX.SEvent("esx_policejob:server:SendFlag",Config.Flag.MinZ)end end },
			{ name="flag_half", icon = "fa-solid fa-flag", label = "חצי התורן", job = "police",
              onSelect = function() if(ESX.PlayerData.job and ESX.PlayerData.job.name=="police")then ClearPedTasksImmediately(Cache.ped);TaskTurnPedToFaceCoord(Cache.ped,Config.Flag.Target.x,Config.Flag.Target.y,Config.Flag.Target.z,1000);ESX.SEvent("esx_policejob:server:SendFlag",(Config.Flag.MaxZ+Config.Flag.MinZ)/2)end end }
		},
        distance = 2.5
	})
end)

local customFlagObject = 0 -- Renamed for clarity
local function RemoveNearbyFlags(coords)
	local flagHash = joaat("prop_flag_sheriff")
	local objs = GetGamePool("CObject")
	for i = 1,#objs, 1 do
		local obj = objs[i]
		if(not IsEntityAMissionEntity(obj)) then
			if(#(GetEntityCoords(obj) - coords) < 12.0 and GetEntityModel(obj) == flagHash) then
				SetEntityAsMissionEntity(obj,true,true); DeleteEntity(obj); break
			end
		end
	end
end

RegisterNetEvent("esx_policejob:client:SendFlag",function(height)
	local flagHash = joaat("prop_flag_sheriff")
    if not Config.Flag or not Config.Flag.Default then return end -- Guard clause
	RemoveNearbyFlags(Config.Flag.Default)
	if(not DoesEntityExist(customFlagObject)) then
		RequestModel(flagHash); while not HasModelLoaded(flagHash) do Wait(50) end
		customFlagObject = CreateObject(flagHash,Config.Flag.Default.x,Config.Flag.Default.y,Config.Flag.Default.z,false,true,false)
		SetEntityLoadCollisionFlag(customFlagObject,true, 1); SetModelAsNoLongerNeeded(flagHash)
	end
    if not DoesEntityExist(customFlagObject) then return end -- Guard clause if creation failed

	local ccoords = GetEntityCoords(customFlagObject)
	local goup = ccoords.z < height
	local flagsound = GetSoundId(); PlaySoundFromEntity(flagsound, "Rappel_Loop",customFlagObject, "GTAO_Rappel_Sounds",false, true)
	local targetZ = height
    local increment = goup and 0.01 or -0.01

    while math.abs(GetEntityCoords(customFlagObject).z - targetZ) > 0.015 do -- Loop until close to target
        Wait(0)
        if not DoesEntityExist(customFlagObject) then StopSound(flagsound); ReleaseSoundId(flagsound); return end -- Exit if flag deleted
        SetEntityCoords(customFlagObject,GetOffsetFromEntityInWorldCoords(customFlagObject,0.0,0.0,increment))
        if (goup and GetEntityCoords(customFlagObject).z >= targetZ) or (not goup and GetEntityCoords(customFlagObject).z <= targetZ) then
            break -- Reached target
        end
    end
    if DoesEntityExist(customFlagObject) then SetEntityCoords(customFlagObject,Config.Flag.Default.x,Config.Flag.Default.y,targetZ) end
	StopSound(flagsound); ReleaseSoundId(flagsound)
	PlaySoundFromEntity(-1,"Rappel_Land",customFlagObject,"GTAO_Rappel_Sounds",false,0)
	PlaySoundFromEntity(-1,"Rappel_Stop",customFlagObject,"GTAO_Rappel_Sounds",false,0)
end)

CreateThread(function()
    local modelToClean = joaat("prop_barrier_work05") -- Example, original was a number hash
    local cleanupLocation = vector3(1818.16, 2608.48, 45.6)
    while true do
        Wait(60000) -- Reduced frequency of this cleanup
        local objects = GetAllObjects()
        for _, objHandle in ipairs(objects) do
            if DoesEntityExist(objHandle) and not IsEntityAMissionEntity(objHandle) then
                if GetEntityModel(objHandle) == modelToClean and #(GetEntityCoords(objHandle) - cleanupLocation) < 15.0 then
                     SetEntityAsMissionEntity(objHandle, true, true); DeleteEntity(objHandle)
                end
            end
        end
    end
end)

DecorRegister("IsPoliceObj", 3)
local SyncedSpikes = {} -- Renamed from Spikes

local function AddLocalSyncedPoliceObject(id) -- Renamed for clarity
	CreateThread(function()
		local objData = Config.SpawnedObjects[id]
		if objData and objData.coords then -- Ensure objData and coords exist
			if not objData.object or not DoesEntityExist(objData.object) then
				local model = joaat(objData.model) -- Ensure model is hash
				lib.requestModel(model, 5000)
				if(not Config.SpawnedObjects[id] or (objData.object and DoesEntityExist(objData.object))) then SetModelAsNoLongerNeeded(model); return end

                local x,y,z,w = objData.coords.x, objData.coords.y, objData.coords.z, objData.coords.w
                if type(objData.coords) == 'vector4' then -- Check if coords is already vector4
                    x,y,z,w = objData.coords.x, objData.coords.y, objData.coords.z, objData.coords.w
                elseif type(objData.coords) == 'vector3' then -- Handle if only vector3 was stored (w defaults to 0.0)
                     x,y,z,w = objData.coords.x, objData.coords.y, objData.coords.z, objData.heading or 0.0
                else -- Fallback if coords format is unexpected
                    print("[esx_policejob] Warning: Invalid coordinate format for synced object ID: " .. id)
                    SetModelAsNoLongerNeeded(model)
                    return
                end

                objData.object = CreateObject(model, x,y,z, true, true, false) -- networkSync = true
				SetEntityHeading(objData.object, w); SetModelAsNoLongerNeeded(model)
				DecorSetInt(objData.object, "IsPoliceObj", id); PlaceObjectOnGroundProperly(objData.object)

                if objData.model == "p_ld_stinger_s" then -- Check by string model name for spike logic
                    SyncedSpikes[id] = objData.object
                end

				if model == joaat("prop_boxpile_07d") then FreezeEntityPosition(objData.object, true) end

				if not objData.PlayedAnim and model == joaat("p_ld_stinger_s") then
					objData.PlayedAnim = true; FreezeEntityPosition(objData.object,true)
					CreateThread(function()
						RequestAnimDict("p_ld_stinger_s"); while not HasAnimDictLoaded("p_ld_stinger_s") do Wait(0) end
						if DoesEntityExist(objData.object) then PlayEntityAnim(objData.object, "P_Stinger_S_Deploy", "p_ld_stinger_s", 1000.0, false, true, false, 0.0, 0) end
						RemoveAnimDict("p_ld_stinger_s")
					end)
					PlaceObjectOnGroundProperly(objData.object)
				end
			end
		end
	end)
end

RegisterNetEvent("esx_policejob:client:AddSyncObj", function(id, obj)
    if obj and obj.model and obj.coords then -- Basic validation
        Config.SpawnedObjects[id] = obj
        Config.SpawnedObjects[id].PlayedAnim = false
        if obj.coords.xyz and #(GetEntityCoords(Cache.ped) - obj.coords.xyz) < 423 then 
            AddLocalSyncedPoliceObject(id)
        elseif obj.coords.x and #(GetEntityCoords(Cache.ped) - vector3(obj.coords.x, obj.coords.y, obj.coords.z)) < 423 then 
            AddLocalSyncedPoliceObject(id)
        end
    else
        print("[esx_policejob] Warning: Received invalid object data for AddSyncObj, ID: " .. tostring(id))
    end
end)

local function RemoveLocalSyncedPoliceObject(id, ClearFromGlobalList)
    local objData = Config.SpawnedObjects[id]
    if ClearFromGlobalList then 
        Config.SpawnedObjects[id] = nil 
        if SyncedSpikes[id] then 
            SyncedSpikes[id] = nil 
        end 
    end
    if objData and objData.object and DoesEntityExist(objData.object) then
        SetEntityAsMissionEntity(objData.object, true, true)
        DeleteObject(objData.object)
        objData.object = nil
    end
end

RegisterNetEvent("esx_policejob:client:RemoveSyncObj", function(id) 
    RemoveLocalSyncedPoliceObject(id, true) 
end)

function RequestDeletePoliceObject(id)
    if IsEntityDeadOrDying(Cache.ped, false) then 
        return 
    end
    if Config.SpawnedObjects[id] then
        lib.callback("esx_policejob:server:RequestDeleteObject", false, function(answer)
            if answer then
                local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do 
                    Wait(0) 
                end
                TaskPlayAnim(Cache.ped, dict, anim, 8.0, 1.0, 1000, 51, 0.0, false, false, false)
                RemoveAnimDict(dict)
            else
                TriggerEvent('br_notify:show', 'error', "Delete Error", "Failed to request object deletion from server.", 5000)
            end
        end, id)
    end
end

RegisterNetEvent("esx_policejob:client:SyncAll", function(objconfig) Config.SpawnedObjects = objconfig or {} end)

CreateThread(function()
    while not ESX.IsPlayerLoaded() do Wait(100) end
    TriggerServerEvent("esx_policejob:server:RequestInitialSync")

    while true do
        local sleep = 1000; local playerCoords = GetEntityCoords(Cache.ped)
        for id, objData in pairs(Config.SpawnedObjects) do
            if objData and objData.coords then
                local objPos = objData.coords.xyz or vector3(objData.coords.x, objData.coords.y, objData.coords.z)
                local distance = #(playerCoords - objPos)
                if distance > 424 then RemoveLocalSyncedPoliceObject(id, false)
                elseif distance <= 423 then AddLocalSyncedPoliceObject(id) end

                if distance <= 3 and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and not blocklobjects then
                    sleep = 0
                    exports.ox_lib:showTextUI(_U('remove_prop'))
                    if IsControlJustReleased(0, 101) then -- G key
                        if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
                            if Config.SpawnedObjects[id] then
                                if(not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000)) then
                                    lastscan = GetGameTimer(); ESX.SEvent('esx_policejob:ScanObject',id); goto restart_object_loop_inner
                                else TriggerEvent('br_notify:show',"error","Scan Error","נא להמתין 5 שניות בין כל סריקת אובייקט", 5000) end
                            end
                        end
                    end
                    if IsControlJustReleased(0, 51) then -- E key
                        if Config.SpawnedObjects[id] then RequestDeletePoliceObject(id); goto restart_object_loop_inner end
                    end
                else
                    if sleep ~= 0 then exports.ox_lib:hideTextUI() end -- Hide only if not showing for another object
                end
            end
        end
        ::restart_object_loop_inner:: -- Label for goto
        Wait(sleep)
    end
end)

local closestSpikeObject = nil -- Renamed

CreateThread(function()
    while true do
		local sleep = 1000
        if Cache.vehicle and DoesEntityExist(Cache.vehicle) then -- Ensure vehicle exists
			sleep = 150; local vehCoords = GetEntityCoords(Cache.vehicle); local closestDistance = math.huge; local tempClosestSpike = nil
			for id, spikeObjHandle in pairs(SyncedSpikes) do -- Iterate over SyncedSpikes
				if DoesEntityExist(spikeObjHandle) then
					local distance = #(vehCoords - GetEntityCoords(spikeObjHandle))
					if distance < closestDistance and distance < 100.0 then tempClosestSpike = spikeObjHandle; closestDistance = distance end
				end
			end
            closestSpikeObject = tempClosestSpike
        else closestSpikeObject = nil end
		Wait(sleep)
    end
end)

local vehicleTires = { -- Renamed from tires
    {bone = "wheel_lf", index = 0}, {bone = "wheel_rf", index = 1},
    {bone = "wheel_lm1", index = 2}, {bone = "wheel_rm1", index = 3}, -- Common for some vehicles
    {bone = "wheel_lm2", index = 2}, {bone = "wheel_rm2", index = 3}, -- For vehicles with dual rear wheels if needed
    {bone = "wheel_lr", index = 4}, {bone = "wheel_rr", index = 5}
}

CreateThread(function()
    while true do
		local sleep = 500
        if closestSpikeObject and Cache.vehicle and DoesEntityExist(closestSpikeObject) and DoesEntityExist(Cache.vehicle) then
			sleep = 0
			if IsEntityTouchingEntity(Cache.vehicle,closestSpikeObject) then
				for k,v_tire in pairs(vehicleTires) do
					local boneIndex = GetEntityBoneIndexByName(Cache.vehicle, v_tire.bone)
					if boneIndex ~= -1 then
						local wheelPos = GetWorldPositionOfEntityBone(Cache.vehicle, boneIndex)
						if #(wheelPos - GetEntityCoords(closestSpikeObject)) < 1.8 then
							if not IsVehicleTyreBurst(Cache.vehicle, v_tire.index, true) then SetVehicleTyreBurst(Cache.vehicle, v_tire.index, true, 1000.0) end
						end
					end
				end
			end
        end
		Wait(sleep)
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    if ESX.PlayerData.job and ESX.PlayerData.job.name == "police" then
        recentlyIN = true
        Wait(120000)
        recentlyIN = nil
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

-- Custom notification event registration (as per user request)
RegisterNetEvent('br_notify:show')
AddEventHandler('br_notify:show', function(type, title, message, duration, playSound)
    SendNUIMessage({
        action = 'showNotification',
        type = type or 'info',
        title = title or 'Notification',
        message = message or '',
        duration = duration or 5000,
        sound = false -- Sound is explicitly set to false as per request
    })
end)

local CurrentActionData, handcuffTimer, dragStatus, currentTask = {}, {}, {}, {}
local HasAlreadyEnteredMarker, isDead, isHandcuffed, AnkleCuffed = false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg
dragStatus.isDragged = false
local cuffprop
local blocklobjects = false
local handcuffing = false
local lastbackup
local recentlyIN = nil
local chasetimer = false

local varbar

RegisterNetEvent('ElFatahKuds')
AddEventHandler('ElFatahKuds', function(variable)
	varbar = variable
end)

local function DrawOutlineEntity(entity, bool)
	if IsEntityAPed(entity) or not DoesEntityExist(entity) then return end
	SetEntityDrawOutline(entity, bool)
	SetEntityDrawOutlineColor(255, 255, 255, 255)
	SetEntityDrawOutlineShader(1)
end

function cleanPlayer(playerPed)
    if not ESX.PlayerData.job then return end
	local grade = ESX.PlayerData.job.grade_name
	if(grade ~= "agent" and grade ~= "boss" and grade ~= "lieutenant") then
		SetPedArmour(playerPed, 0)
	end
	ClearPedBloodDamage(playerPed)
	ResetPedVisibleDamage(playerPed)
	ClearPedLastWeaponDamage(playerPed)
	ResetPedMovementClipset(playerPed, 0)
	TriggerEvent('gi-emotes:RevertWalk')
end

RegisterNetEvent("esx_policejob:Backup_C")
AddEventHandler("esx_policejob:Backup_C", function(coords,name,id, isCop)
	if(ESX ~= nil) then
		local blip = nil

		if not ESX.PlayerData or not ESX.PlayerData.job then
			return
		end
		if ESX.PlayerData.job.name == "police" then
			local title = isCop and "Police Backup Request" or "Security Backup Request"
			local message = isCop and "!שוטר מבקש תגבורת" or "!מאבטח מבקש תגבורת"
			TriggerEvent('br_notify:show', 'inform', title, message, 10000)

			if not DoesBlipExist(blip) then
				blip = AddBlipForCoord(coords.x, coords.y, coords.z)
				SetBlipSprite(blip, 42)
				SetBlipScale(blip, 0.8)
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentString("Backup | " ..name.." | "..id)
				EndTextCommandSetBlipName(blip)
				PlaySoundFrontend(-1, "HACKING_SUCCESS", 0, 1)

				Citizen.Wait(25000)
				RemoveBlip(blip)
			end
		end
	end
end)

CreateThread(function()
	while true do
		Wait(0)
		if CurrentAction then
            exports.ox_lib:showTextUI(CurrentActionMsg)

			if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
                if lib.isContextOpen() then lib.hideContext(false) end -- Close any open ox_lib context
                exports.ox_lib:hideTextUI()

				if CurrentAction == 'menu_cloakroom' then OpenCloakroomMenu()
				elseif CurrentAction == 'menu_armory' then OpenArmoryMenu(CurrentActionData.station)
				elseif CurrentAction == "menu_weaponry" then exports['gi-policearmory']:ExportWeaponry()
				elseif CurrentAction == "menu_evidence" then EvidenceMenu()
				elseif CurrentAction == 'menu_kitchen' then OpenKitchenMenu(CurrentActionData.station)
				elseif CurrentAction == 'menu_boss_actions' then
					TriggerEvent('esx_society:openBossMenu', 'police', function(data, menu) HasAlreadyEnteredMarker = false end, { wash = true })
				elseif CurrentAction == 'menu_boss_bills' then
                    OpenBossBillsMenu()
				end
				CurrentAction = nil
			end
		else
            if lib.isTextUIOpen() then exports.ox_lib:hideTextUI() end
        end

		if IsControlJustReleased(0, 167) and not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
            if not lib.isContextOpen('police_actions_menu') then OpenPoliceActionsMenu() end
		end
	end
end)

function OpenBossBillsMenu() -- Moved from inline to make Key Controls cleaner
    if not ESX.PlayerData.job or ESX.PlayerData.job.grade_name ~= 'boss' then return end
    local players = ESX.GetPlayers()
    local elements = { {title="Player Bills Management", description="Select a player", disabled=true} }
    for i=1, #players, 1 do
        local targetXPlayer = ESX.GetPlayerFromId(players[i])
        if targetXPlayer then
            table.insert(elements, {
                title = ("%s [%s]"):format(targetXPlayer.getName(), targetXPlayer.source),
                value = targetXPlayer.source
            })
        end
    end
    if #elements == 1 then TriggerEvent('br_notify:show', 'inform', "Bill Management", "No players found.", 5000); return end

    lib.registerContext({
        id = 'police_boss_bills_menu_select_player',
        title = "בדיקת דוחות לשחקנים",
        options = elements,
        onSelect = function(data)
            if data.value then OpenBillManagement({id = data.value, name = data.title}) end
            RefreshAction()
        end,
        onClose = RefreshAction
    })
    lib.showContext('police_boss_bills_menu_select_player')
end

function mysort(s)
    local t = {}
    for k, v in pairs(s) do table.insert(t, v) end
    table.sort(t, function(a, b)
        if a.id ~= b.id then return a.id < b.id end
        return a.name < b.name
    end)
    return t
end

function OpenBillManagement(iPlayer)
    if not ESX.PlayerData.job or ESX.PlayerData.job.grade_name ~= 'boss' then return end
	local serverid = iPlayer.id
	ESX.TriggerServerCallback('okokBilling:getTargetBills', function(bills)
		if not bills or #bills == 0 then
            TriggerEvent('br_notify:show',"info","Billing", "אין לשחקן דוחות", 5000)
			RefreshAction(); return
		end
        local elements = {}
		local totalPoliceDebt = 0
		for i=1, #bills, 1 do
			if(bills[i].author == "Police Department") then
				totalPoliceDebt = totalPoliceDebt + bills[i].amount
				table.insert(elements, {
					title  = ('%s - <span style="color:red;">%s</span>'):format(bills[i].label, _U('armory_item', ESX.Math.GroupDigits(bills[i].amount))),
					billID = bills[i].id, icon = 'fas fa-file-invoice-dollar'
				})
			end
		end
		if(#elements == 0) then TriggerEvent('br_notify:show',"info","Billing","אין לשחקן דוחות משטרה", 5000); RefreshAction(); return end

        table.insert(elements, 1, {title = 'תפריט בוס - דוחות<br>Balance: <span style="color:green;">₪'..ESX.Math.GroupDigits(totalPoliceDebt)..'</span>', description="Manage Bills", disabled=true})

        lib.registerContext({
            id = 'police_bill_management_menu',
            title = 'תפריט בוס - דוחות', options = elements,
            onSelect = function(data)
                if data.billID then
                    TriggerServerEvent('okokBilling:cancelBill', data.billID)
                    TriggerEvent('br_notify:show', 'success', "Billing", "Bill cancelled (attempted).", 5000)
                    RefreshAction()
                    ESX.SetTimeout(300, function() OpenBillManagement(iPlayer) end)
                end
            end,
            onClose = RefreshAction
        })
        lib.showContext('police_bill_management_menu')
	end,serverid)
end

AddEventHandler('playerSpawned', function(spawn)
	isDead = false
	TriggerEvent('esx_policejob:unrestrain') -- Ensure player is not stuck cuffed on respawn
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
	if(IsPedInAnyPoliceVehicle(Cache.ped)) then
		local vehicle = GetVehiclePedIsIn(Cache.ped,false)
		if DoesEntityExist(vehicle) then SetVehicleSiren(vehicle,false) end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_policejob:unrestrain')
		if Config.EnableHandcuffTimer and handcuffTimer.active then ESX.ClearTimeout(handcuffTimer.task) end
		for id, objData in pairs(Config.SpawnedObjects) do
            if objData.object and DoesEntityExist(objData.object) then DeleteEntity(objData.object) end
        end
	end
end)

RegisterNetEvent("esx_policejob:RestartTimer",function() StartHandcuffTimer() end)

function StartHandcuffTimer()
	if Config.EnableHandcuffTimer and handcuffTimer.active then ESX.ClearTimeout(handcuffTimer.task) end
	handcuffTimer.active = true
	handcuffTimer.task = ESX.SetTimeout(Config.HandcuffTimer, function()
		TriggerEvent('br_notify:show', 'info', "Handcuffs", _U('unrestrained_timer'), 5000)
		TriggerEvent('esx_policejob:unrestrain')
		handcuffTimer.active = false
	end)
end

function ImpoundVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    currentTask.busy = true
    lib.callback("esx_policejob:server:requestImpound", false, function(success)
        if success then 
            TriggerEvent('br_notify:show', 'success', "Impound", _U('impound_successful'), 5000)
        else 
            TriggerEvent('br_notify:show', 'error', "Impound Error", "Failed to impound vehicle.", 5000) 
        end
        currentTask.busy = false
    end, VehToNet(vehicle))
end

RegisterNetEvent('esx_policejob:getarrested')
AddEventHandler('esx_policejob:getarrested', function(playerheading, playercoords, playerlocation)
	local playerPed = Cache.ped
	TriggerEvent('ox_inventory:disarm', true)
	SetCurrentPedWeapon(playerPed, joaat('WEAPON_UNARMED'), true)
	local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
	SetEntityCoords(playerPed, x, y, z)
	SetEntityHeading(playerPed, playerheading)
	SetPlayerControl(PlayerId(), false, 1 << 8) -- PT_SCRIPTED_SCENE_CONTROL
	Citizen.Wait(250)
	LoadAnimDict('mp_arrest_paired')
	TaskPlayAnim(playerPed, 'mp_arrest_paired', 'crook_p2_back_right', 8.0, -8, 3750 , 2, 0, 0, 0, 0)
	Citizen.Wait(3760)
	-- isHandcuffed will be set by client:handcuff
    -- LocalPlayer.state variables removed, relying on ESX/ox_lib or game mechanics
	HandCuffedThread()
	SetPlayerControl(PlayerId(), true, 0) -- Give back full control initially
	TriggerEvent('esx_policejob:client:handcuff')
	if not IsEntityDeadOrDying(playerPed) then -- Check if player is not dead/downed
		LoadAnimDict('mp_arresting')
		TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
		RemoveAnimDict('mp_arresting')
	end
	RemoveAnimDict('mp_arrest_paired')
end)

RegisterNetEvent('esx_policejob:doarrested')
AddEventHandler('esx_policejob:doarrested', function()
	handcuffing = true
	Citizen.Wait(250)
	local text = "אוזק"
	TriggerEvent("gi-3dme:network:mecmd",text)
	LoadAnimDict('mp_arrest_paired')
	ESX.SEvent('InteractSound_SV:PlayWithinDistance', 4.5, 'handcuff', 0.9)
	TaskPlayAnim(Cache.ped, 'mp_arrest_paired', 'cop_p2_back_right', 8.0, -8,3750, 2, 0, 0, 0, 0)
	Citizen.Wait(3000)
	handcuffing = false
	RemoveAnimDict('mp_arrest_paired')
end)

RegisterNetEvent('esx_policejob:getuncuffed')
AddEventHandler('esx_policejob:getuncuffed', function(playerheading, playercoords, playerlocation)
	if(isHandcuffed == true) then
		local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
		local playerPed = Cache.ped
		SetEntityCoords(playerPed, x, y, z)
		SetEntityHeading(playerPed, playerheading)
		Citizen.Wait(250)
		LoadAnimDict('mp_arresting')
		TaskPlayAnim(playerPed, 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
		Citizen.Wait(5500)
		TriggerEvent('esx_policejob:client:handcuff')
		ClearPedTasks(playerPed)
		RemoveAnimDict('mp_arresting')
	end
end)

RegisterNetEvent('esx_policejob:douncuffing')
AddEventHandler('esx_policejob:douncuffing', function()
	handcuffing = true
	Citizen.Wait(250)
	local text = "מוריד אזיקה"
	TriggerEvent("gi-3dme:network:mecmd",text)
	LoadAnimDict('mp_arresting')
	local playerPed = Cache.ped
	TaskPlayAnim(playerPed, 'mp_arresting', 'a_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
	Citizen.Wait(5500)
	ClearPedTasks(playerPed)
	handcuffing = false
	RemoveAnimDict('mp_arresting')
end)

RegisterNetEvent('esx_policejob:getuncuffedlp')
AddEventHandler('esx_policejob:getuncuffedlp', function(playerheading, playercoords, playerlocation)
	if(isHandcuffed == true) then
		local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
		local playerPed = Cache.ped
		SetEntityCoords(playerPed, x, y, z); SetEntityHeading(playerPed, playerheading)
		Citizen.Wait(5000)
		LoadAnimDict('mp_arresting'); TaskPlayAnim(playerPed, 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0,0,0,0)
		TriggerEvent('esx_policejob:client:handcuff')
		Citizen.Wait(4000); ClearPedTasks(playerPed); RemoveAnimDict('mp_arresting')
	end
end)

RegisterNetEvent('esx_policejob:douncuffinglp')
AddEventHandler('esx_policejob:douncuffinglp', function(targetServerId)
    handcuffing = true
    local playerPed = Cache.ped
    LoadAnimDict('mp_arresting')
    TaskPlayAnim(playerPed, 'mp_arresting', 'a_uncuff', 8.0, -8, -1, 81, 0, 0, 0, 0)
    RemoveAnimDict('mp_arresting')
    FreezeEntityPosition(playerPed, true)
    TriggerEvent("gi-3dme:network:mecmd", 'פורץ אזיקים')

    local success = exports["t3_lockpick"]:startLockpick(1, 2, 5)
    if success then
        exports.ox_lib:progressBar({
            duration = 5000,
            label = "🧷 פורץ אזיקה 🧷",
            useWhileDead = false,
            canCancel = true
        }, function(finished)
            if finished then
                ESX.SEvent('esx_policejob:requestcuffsofflp', targetServerId)
            end
        end)
    else
        TriggerEvent('br_notify:show', 'error', "Lockpick Failed", 'פריצה נכשלה', 5000)
    end
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)
    handcuffing = false
end)

RegisterNetEvent('esx_policejob:cuffsofflp')
AddEventHandler('esx_policejob:cuffsofflp', function()
	if(isHandcuffed == true) then
		Citizen.Wait(250)
		local playerPed = Cache.ped
		LoadAnimDict('mp_arresting'); TaskPlayAnim(playerPed, 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0,0,0,0)
		Citizen.Wait(4500)
		TriggerEvent('esx_policejob:client:handcuff')
		Citizen.Wait(500); ClearPedTasks(playerPed); RemoveAnimDict('mp_arresting')
	end
end)

function LoadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do RequestAnimDict(dict); Citizen.Wait(10) end
end

function IsPCuffed() return isHandcuffed end

local lastspeaker_megaphone -- Renamed to avoid conflict
local VoiceLines = {
	"STOP_VEHICLE_CAR_MEGAPHONE", "STOP_VEHICLE_GENERIC_MEGAPHONE",
	"STOP_VEHICLE_CAR_WARNING_MEGAPHONE"
}

RegisterKeyMapping('PMEGA', 'Activates Megaphone', 'keyboard', "6")
RegisterCommand('PMEGA', function(source,args)
    if not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police" then return end
    -- if lib.isInventoryOpen() then return end -- Example for ox_inventory if needed
	local playerPed = Cache.ped; local veh = GetVehiclePedIsIn(playerPed,false)
	if(veh == 0) then return end
	if IsPedInAnyPoliceVehicle(playerPed) then
		if(GetPedInVehicleSeat(veh,-1) == playerPed) then
			if(not lastspeaker_megaphone or (GetTimeDifference(GetGameTimer(), lastspeaker_megaphone) > 8000)) then
				local playerList = {}; lastspeaker_megaphone = GetGameTimer()
				local voiceline = VoiceLines[math.random(#VoiceLines)]
				if(args and args[1]) then
					local lineNum = tonumber(args[1])
                    local customLines = {
                        [1]="COP_ARRIVAL_ANNOUNCE_MEGAPHONE", [2]="SPOT_SUSPECT_CHOPPER_MEGAPHONE", [3]="SHOT_AT_HELI_MEGAPHONE",
                        [4]="SHOT_TYRE_CHOPPER_MEGAPHONE", [5]="NO_LOITERING_MEGAPHONE", [6]="CLEAR_AREA_MEGAPHONE",
                        [7]="CLEAR_AREA_PANIC_MEGAPHONE", [8]="STOP_VEHICLE_GENERIC_WARNING_MEGAPHONE", [9]="CHASE_VEHICLE_MEGAPHONE",
                        [10]="STOP_VEHICLE_BOAT_MEGAPHONE", [11]="STOP_ON_FOOT_MEGAPHONE"
                    }
                    if customLines[lineNum] then voiceline = customLines[lineNum] end
				end
				local coords = GetEntityCoords(playerPed)
				for _, playerServerId in ipairs(ESX.GetPlayers()) do
                    local targetPed = GetPlayerPed(GetPlayerFromServerId(playerServerId))
					if(DoesEntityExist(targetPed)) then
						if(#(GetEntityCoords(targetPed) - coords) < 300.0) then table.insert(playerList, playerServerId) end
					end
				end
				if(#playerList > 0) then TriggerEvent('esx_policejob:routeMegaphone',playerList,voiceline) end -- Renamed event for clarity
			end
		end
	end
end)

RegisterNetEvent('esx_policejob:routeMegaphone') -- Renamed event
AddEventHandler('esx_policejob:routeMegaphone',function(playerList,voiceline)
	local female = GetEntityModel(Cache.ped) == joaat("mp_f_freemode_01")
	ESX.SEvent("esx_policejob:sv_megaphone",playerList,voiceline,female)
end)

RegisterNetEvent("esx_policejob:Megaphone")
AddEventHandler("esx_policejob:Megaphone",function(target,line,female)
	local line = line or "STOP_VEHICLE_CAR_MEGAPHONE"
	local player = GetPlayerFromServerId(target)
    if player == -1 or player == 0 then return end -- Ensure player is valid
	local playerPed = GetPlayerPed(player)
	if(not DoesEntityExist(playerPed)) then return end
	local Skin = joaat("S_M_Y_COP_01")
	local playerVeh = GetVehiclePedIsIn(playerPed, false)
	if(not DoesEntityExist(playerVeh)) then return end
	local playerPosition = GetEntityCoords(playerPed)
	RequestModel(Skin); while(not HasModelLoaded(Skin)) do Citizen.Wait(10) end
	local Megaphone = CreatePed(26, Skin, playerPosition.x, playerPosition.y, playerPosition.z + 1.0, 0.0, false, true) -- Spawn slightly above
	SetEntityInvincible(Megaphone, true); SetEntityVisible(Megaphone, false, false); SetEntityCollision(Megaphone, false, false)
	SetEntityCompletelyDisableCollision(Megaphone, true, true)
	AttachEntityToEntity(Megaphone, playerVeh, 0, 0.27, 0.0, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, true)
	local SpeechName = female and "S_F_Y_COP_01_BLACK_FULL_02" or "S_M_Y_COP_01_WHITE_FULL_01"
	PlayPedAmbientSpeechWithVoiceNative(Megaphone, line, SpeechName, "SPEECH_PARAMS_FORCE_SHOUTED", 6)
	SetModelAsNoLongerNeeded(Skin)
	Wait(5000)
	if DoesEntityExist(Megaphone) then DeleteEntity(Megaphone) end
end)

local inVehicle_nayedet = false -- Renamed to avoid conflict
local left_nayedet = false
local lastcar_nayedet
local fizzPed_nayedet = nil
local spawnRadius_nayedet = 80.0

RegisterNetEvent('esx_policejob:callnayedet')
AddEventHandler('esx_policejob:callnayedet', function()
    if not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police" then return end
	local PoliceVehicles = {
        { model = '19camry', label = "Toyota Camry" }, { model = 'israeli', label = "Skoda Superb" },
        { model = 'qpsrav4', label = 'גיפ סיור' }, { model = '18tahoenf', label = 'גיפ מפקד סיור' },
        { model = 'qpsprado', label = 'ניידת מג"ב'}, { model = 'policet', label = 'וואן יס"מ'},
        { model = 'riot', label = 'זאב' }, { model = 'foxkat', label = 'רכב מבצעים - רק יחידות מיוחדות' },
        { model = 'psp_bmwgs', label = 'אופנוע יסמ' }, { model = 'policebikerb', label = 'אופנוע יסמ שטח' },
        { model = 'bcsspd', label = 'רכב שטח יממ', limitedaccess = true },
        { model = 'umprado', label = 'Land Cruiser משטרתית', limitedaccess = true},
        { model = 'nm_z71', label = 'גיפ יממ', limitedaccess = true},
        { model = 'mustang', label = 'רכב פיקוד משטרה', limitedaccess = true},
        { model = 'gtrrb', label = '!רכב הנהלת משטרה - GTR', limitedaccess = true}
	}
	local elements = { {title = "הזמנת רכבים - משטרת ישראל", description = "Select a vehicle", disabled = true} }
	for k,v in pairs(PoliceVehicles) do
        if not v.limitedaccess or (v.limitedaccess and (ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label, "מפקד"))) then
		    if IsModelValid(joaat(v.model)) then table.insert(elements,{title = v.label, value = v.model, icon = 'fas fa-car'}) end
        end
	end
    if #elements == 1 then TriggerEvent('br_notify:show', 'inform', "Vehicle Delivery", "No vehicles available for your rank.", 5000); return end
    lib.registerContext({
        id = 'police_call_nayedet_menu',
        title = "הזמנת רכבים - משטרת ישראל",
        options = elements,
        onSelect = function(data) if data.value then SpawnVehicleForNayedet(data.value) end end, -- Renamed SpawnVehicle
        onClose = function() HasAlreadyEnteredMarker = false end
    })
    lib.showContext('police_call_nayedet_menu')
end)

ESX.RegisterClientCallback("esx_policejob:client:GetClosestNode",function(cb,coords)
	local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-spawnRadius_nayedet, spawnRadius_nayedet), coords.y + math.random(-spawnRadius_nayedet, spawnRadius_nayedet), coords.z, 0, 3, 0) -- Increased variation for node search
	cb(found and vector4(spawnPos.x,spawnPos.y,spawnPos.z,spawnHeading) or false)
end)

function SpawnVehicleForNayedet(vehName)
    if lastcar_nayedet and (GetTimeDifference(GetGameTimer(), lastcar_nayedet) < 600000) then
        TriggerEvent('br_notify:show', 'error', "Cooldown", 'אתה יכול להזמין ניידת כל 10 דקות', 5000)
        return
    end
    if not varbar then
        TriggerEvent('br_notify:show', "error", "Error", "תקלה, נסה שנית (varbar missing)", 5000)
        return
    end

    local vehhash = joaat(vehName)
    lastcar_nayedet = GetGameTimer()
    local text = "מזמין ניידת"
    TriggerEvent("gi-3dme:network:mecmd", text)
    
    RequestAnimDict("random@arrests")
    local playerPed = Cache.ped
    while not HasAnimDictLoaded("random@arrests") do Wait(5) end
    TaskPlayAnim(playerPed, "random@arrests", "generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0)
    ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)

    exports.ox_lib:progressBar({
        duration = 1000,
        label = "מזמין ניידת...",
        useWhileDead = false,
        canCancel = true,
        anim = {dict = "random@arrests", clip = "generic_radio_chatter"}
    }, function(finished)
        StopAnimTask(playerPed, "random@arrests", "generic_radio_chatter", -4.0)
        RemoveAnimDict("random@arrests")
        
        if not finished then
            lastcar_nayedet = nil
            return
        end

        TriggerEvent('br_notify:show', 'info', "Vehicle Delivery", 'ניידת בדרך', 5000)
        local driverhash = joaat("s_m_y_cop_01")
        RequestModel(vehhash)
        RequestModel(driverhash)
        
        while not HasModelLoaded(vehhash) or not HasModelLoaded(driverhash) do
            Wait(0)
        end

        ESX.TriggerServerCallback("esx_policejob:server:SpawnNayedet", function(netid, pednet)
            if not netid or type(netid) ~= "number" or not pednet or type(pednet) ~= "number" then
                lastcar_nayedet = nil
                SetModelAsNoLongerNeeded(vehhash)
                SetModelAsNoLongerNeeded(driverhash)
                TriggerEvent('br_notify:show', "warning", "Delivery Failed", "הזמנת הניידת נכשלה, נסה שוב (server error)", 5000)
                return
            end
            
            local callback_vehicle = NetToVeh(netid)
            if not DoesEntityExist(callback_vehicle) then
                lastcar_nayedet = nil
                SetModelAsNoLongerNeeded(vehhash)
                SetModelAsNoLongerNeeded(driverhash)
                TriggerEvent('br_notify:show', "error", "Spawn Error", "שיגור הרכב כשל (vehicle not found)", 5000)
                return
            end
            
            fizzPed_nayedet = NetToPed(pednet)
            if not DoesEntityExist(fizzPed_nayedet) then
                TriggerEvent('br_notify:show', "error", "Spawn Error", "שיגור הנהג כשל (ped not found)", 5000)
                return
            end

            SetVehRadioStation(callback_vehicle, "OFF")
            SetVehicleNumberPlateTextIndex(callback_vehicle, 6)
            SetEntityLoadCollisionFlag(callback_vehicle, true, 1)
            ESX.SEvent('esx_policejob:paymoney', 500)
            
            local pedNetId_nayedet = PedToNet(fizzPed_nayedet)
            SetNetworkIdCanMigrate(pedNetId_nayedet, false)
            SetPedCanRagdollFromPlayerImpact(fizzPed_nayedet, false)
            SetBlockingOfNonTemporaryEvents(fizzPed_nayedet, true)
            SetEntityAsMissionEntity(fizzPed_nayedet, true, true)
            SetEntityLoadCollisionFlag(fizzPed_nayedet, true, 1)
            SetDriverAbility(fizzPed_nayedet, 1.0)
            SetEntityInvincible(fizzPed_nayedet, true)
            SetVehicleDoorsLocked(callback_vehicle, 2)
            
            Wait(500)
            SetVehicleSiren(callback_vehicle, true)
            
            local carblip = AddBlipForEntity(callback_vehicle)
            SetBlipSprite(carblip, 42)
            SetBlipScale(carblip, 0.8)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString("Police Delivery")
            EndTextCommandSetBlipName(carblip)

            local plate = exports['okokVehicleShop']:GeneratePlate()
            SetVehicleNumberPlateText(callback_vehicle, plate)
            TriggerEvent('cl_carlock:givekey', plate, false)
            ESX.SEvent("esx_policejob:CacheVeh", ESX.Math.Trim(GetVehicleNumberPlateText(callback_vehicle)))
            ClearAreaOfVehicles(GetEntityCoords(callback_vehicle), 4.0, false, false, false, false, false)
            SetVehicleOnGroundProperly(callback_vehicle)
            inVehicle_nayedet = true
            TaskVehicleForNayedet(callback_vehicle, carblip, vehhash)
        end, varbar, vehhash)
    end)
end

function TaskVehicleForNayedet(vehicle,carblip, modelHash)
	while inVehicle_nayedet do
		Citizen.Wait(250)
        if not DoesEntityExist(fizzPed_nayedet) or not DoesEntityExist(vehicle) then inVehicle_nayedet = false; if DoesBlipExist(carblip) then RemoveBlip(carblip) end; break end
		local pedcoords = GetEntityCoords(Cache.ped); local plycoords = GetEntityCoords(fizzPed_nayedet)
		local dist = GetDistanceBetweenCoords(plycoords, pedcoords.x,pedcoords.y,pedcoords.z, false)

		if dist <= 25.0 then
			SetVehicleMaxSpeed(vehicle,4.5)
			TaskVehicleDriveToCoord(fizzPed_nayedet, vehicle, pedcoords.x,pedcoords.y,pedcoords.z,10.0,1,modelHash,2883621,5.0,1)
			SetVehicleFixed(vehicle)
			if dist <= 14.5 then LeaveItForNayedet(vehicle); if DoesBlipExist(carblip) then RemoveBlip(carblip) end; break
			else Citizen.Wait(250) end
		else
			TaskVehicleDriveToCoord(fizzPed_nayedet,vehicle,pedcoords.x,pedcoords.y,pedcoords.z,20.0,1,modelHash,2883621,5.0,1)
			Citizen.Wait(250)
		end
		while left_nayedet do
			Citizen.Wait(250)
            if not DoesEntityExist(fizzPed_nayedet) then left_nayedet = false; break end
			local Xpedcoords = GetEntityCoords(Cache.ped); local Ypedcoords = GetEntityCoords(fizzPed_nayedet)
			local distPed = GetDistanceBetweenCoords(Xpedcoords, Ypedcoords, false)
			TaskGoToCoordAnyMeans(fizzPed_nayedet,Xpedcoords.x,Xpedcoords.y,Xpedcoords.z,1.0,0,0,786603,1.0)
			if distPed <= 2.3 then left_nayedet = false; GiveKeysTakeMoneyForNayedet(); break end
		end
	end
end

function LeaveItForNayedet(vehicle)
    if not DoesEntityExist(fizzPed_nayedet) or not DoesEntityExist(vehicle) then inVehicle_nayedet = false; return end
	TaskLeaveVehicle(fizzPed_nayedet, vehicle, 14); inVehicle_nayedet = false
	while IsPedInAnyVehicle(fizzPed_nayedet, false) do Citizen.Wait(0) end
	SetVehicleMaxSpeed(vehicle,0.0); Citizen.Wait(500)
    if DoesEntityExist(fizzPed_nayedet) then TaskWanderStandard(fizzPed_nayedet, 10.0, 10) end
	left_nayedet = true
end

function GiveKeysTakeMoneyForNayedet()
    if not DoesEntityExist(fizzPed_nayedet) then left_nayedet = false; return end
	TaskStandStill(fizzPed_nayedet, 2250); TaskTurnPedToFaceEntity(fizzPed_nayedet, Cache.ped, 1.0)
	PlayAmbientSpeech1(fizzPed_nayedet, "Generic_Hi", "Speech_Params_Force"); Citizen.Wait(500)
	startPropAnimForNayedet(fizzPed_nayedet, "mp_common", "givetake1_a"); Citizen.Wait(1500)
	stopPropAnimForNayedet(fizzPed_nayedet, "mp_common", "givetake1_a"); left_nayedet = false
end

function startPropAnimForNayedet(ped, dictionary, anim)
	CreateThread(function()
		RequestAnimDict(dictionary); while not HasAnimDictLoaded(dictionary) do Citizen.Wait(0) end
        if DoesEntityExist(ped) then TaskPlayAnim(ped, dictionary, anim ,8.0, -8.0, -1, 50, 0, false, false, false) end
		-- RemoveAnimDict(dictionary) -- Should be removed after task is done or if ped is deleted
	end)
end

function stopPropAnimForNayedet(ped, dictionary, anim)
    if DoesEntityExist(ped) then StopAnimTask(ped, dictionary, anim ,8.0, -8.0, -1, 50, 0, false, false, false) end
	Citizen.Wait(100)
    if DoesEntityExist(fizzPed_nayedet) then
        while not NetworkHasControlOfEntity(fizzPed_nayedet) do Citizen.Wait(1); NetworkRequestControlOfEntity(fizzPed_nayedet) end
        DeletePed(fizzPed_nayedet)
    end
    fizzPed_nayedet = nil
    if HasAnimDictLoaded(dictionary) then RemoveAnimDict(dictionary) end -- Ensure anim dict is removed
end

local isTazzed = false -- Renamed to avoid conflict
AddEventHandler('gameEventTriggered', function (name, data)
    if name == 'CEventNetworkEntityDamage' then
        local victim, attacker, _, _, _, _, _, weaponHash = table.unpack(data)
        if GetEntityType(victim) == 1 and victim == Cache.ped then
            if(weaponHash and (weaponHash == joaat("WEAPON_STUNGUN") or weaponHash == joaat("WEAPON_STUNROD"))) then
                if GetPlayerUnderwaterTimeRemaining(PlayerId()) <= 0 then return end -- Check if player is underwater
                if not isTazzed then
                    isTazzed = true; local dontBreakTaz = true
                    CreateThread(function() while dontBreakTaz and isTazzed do Citizen.Wait(100); SetPedToRagdoll(Cache.ped, 1000, 1000, 0, false, false, false) end end) -- Ragdoll for duration
                    SetTimecycleModifier("REDMIST_blend"); ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 0.1)
                    Wait(7000); dontBreakTaz = false
                    SetTimecycleModifier("hud_def_desat_Trevor"); Wait(8000)
                    SetTimecycleModifier(""); SetTransitionTimecycleModifier(""); StopGameplayCamShaking(); isTazzed = false
                end
            end
        end
    end
end)

-- Handcuff
HandCuffedThread = function()
	CreateThread(function()
		local lastreset = GetGameTimer()
		while isHandcuffed do
			Wait(0)
			DisableControlAction(0, 21, true); DisableControlAction(0, 24, true); DisableControlAction(0, 29, true)
			DisableControlAction(0, 257, true); DisableControlAction(0, 25, true); DisableControlAction(0, 263, true)
			if(AnkleCuffed) then -- This relies on the client-side AnkleCuffed variable.
                                -- If this needs to be known by others, a state bag or server event is needed.
				DisableControlAction(0, 32, true); DisableControlAction(0, 34, true); DisableControlAction(0, 31, true); DisableControlAction(0, 30, true)
			end
			DisableControlAction(0, 45, true); DisableControlAction(0, 22, true); DisableControlAction(0, 44, true)
			DisableControlAction(0, 37, true); DisableControlAction(0, 23, true); DisableControlAction(0, 288,  true)
			DisableControlAction(0, 289, true); DisableControlAction(0, 170, true); DisableControlAction(0, 167, true)
			DisableControlAction(0, 0, true); DisableControlAction(0, 73, true); DisableControlAction(0, 166 , true)
			DisableControlAction(2, 199, true); DisableControlAction(0, 59, true); DisableControlAction(0, 71, true)
			DisableControlAction(0, 72, true); DisableControlAction(0, 75, true); DisableControlAction(0, 92,  true)
			DisableControlAction(0, 244,  true); DisableControlAction(0, 246, true); DisableControlAction(2, 36, true)
			DisableControlAction(0, 47, true); DisableControlAction(0, 264, true); DisableControlAction(0, 140, true)
			DisableControlAction(0, 141, true); DisableControlAction(0, 142, true); DisableControlAction(0, 143, true)
			DisableControlAction(27, 75, true)

			local ped = Cache.ped
			if dragStatus.isDragged then
				local copPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.CopId))
                if DoesEntityExist(copPed) then
                    if not IsPedSittingInAnyVehicle(ped) then
                        AttachEntityToEntity(ped, copPed, 11816, -0.22, 0.6, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
                        if(GetEntitySpeed(copPed) > 0.1) then SimulatePlayerInputGait(PlayerId(), 1.0, 1, 1.0, 1, 0) end
                    else dragStatus.isDragged = false; DetachEntity(ped, true, false) end
                    if IsPedDeadOrDying(ped, true) then dragStatus.isDragged = false; DetachEntity(ped, true, false) end
                else dragStatus.isDragged = false; DetachEntity(ped, true, false)
                end
			else
				if(not Transported) then
					DetachEntity(ped, true, false)
					if(IsPedSwimmingUnderWater(ped)) then SetEntityVelocity(ped,0.0,0.0,2.0) end
				end
			end

			if not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle',3) then
				if(not lastreset or (GetTimeDifference(GetGameTimer(), lastreset) > 3000)) and not IsEntityDeadOrDying(ped) then
					lastreset = GetGameTimer()
					RequestAnimDict('mp_arresting'); while not HasAnimDictLoaded('mp_arresting') do Citizen.Wait(100) end
					TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
					RemoveAnimDict('mp_arresting')
				end
			end
			if DoesEntityExist(cuffprop) and GetEntityHealth(cuffprop) <= 0 then
				PlaySoundFrontend(-1, "Drill_Pin_Break", "DLC_HEIST_FLEECA_SOUNDSET")
				TriggerEvent("esx_policejob:unrestrain")
				Wait(1500)
			end
		end
	end)
end

CreateThread(function()
	for k,v in pairs(Config.PoliceStations) do
		if(v.Blip) then
			local blip = AddBlipForCoord(v.Blip.Coords)
			SetBlipSprite (blip, v.Blip.Sprite); SetBlipDisplay(blip, 2); SetBlipScale  (blip, v.Blip.Scale)
			SetBlipColour (blip, v.Blip.Colour); SetBlipHighDetail(blip,true); SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING'); AddTextComponentString("Police Station"); EndTextCommandSetBlipName(blip)
		end
	end
end)

CreateThread(function()
	if not HasStreamedTextureDictLoaded("policemarker") then
        RequestStreamedTextureDict("policemarker", true)
        while not HasStreamedTextureDictLoaded("policemarker") do Wait(1) end
    end
	for k_station,v_station in pairs(Config.PoliceStations) do
		if(v_station.Archive) then -- Assuming Archive locations are for ox_target
			for i=1, #v_station.Archive, 1 do
                exports.ox_target:addBoxZone({
                    coords = v_station.Archive[i], size = vec3(1.5, 1.1, 2.0), rotation = 0, debug = false,
                    options = {
                        { icon = "fa-solid fa-box-archive", label = "ארכיון עצורים", action = function() ArchiveMenu() end, job = "police" },
                        { event = 'esx_policejob:client:scanFingerPrint', icon = 'fas fa-fingerprint', label = 'טביעת אצבע', job = 'police' }
                    },
                    distance = 3.5
                })
			end
		end
	end

	while true do
		Wait(0) -- Marker drawing loop needs to run frequently
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
			local playerPed = Cache.ped; local coords = GetEntityCoords(playerPed)
			local isInMarker, hasExited, letSleep = false, false, true
			local currentStation, currentPart, currentPartNum

			for k_station_draw,v_station_draw in pairs(Config.PoliceStations) do
                local stationParts = {
                    { name = 'Cloakroom', locations = v_station_draw.Cloakrooms, markerType = 20, customMarker = Config.CustomMarkers, markerTexture = "policemarker" },
                    { name = 'Armory', locations = v_station_draw.Armories, markerType = 21, customMarker = Config.CustomMarkers, markerTexture = "policemarker" },
                    { name = 'Evidence', locations = v_station_draw.Evidence, markerType = 21, customMarker = Config.CustomMarkers, markerTexture = "policemarker" },
                    { name = 'Weaponry', locations = v_station_draw.Weaponry, markerType = 21, customMarker = Config.CustomMarkers, markerTexture = "policemarker" },
                    { name = 'Kitchen', locations = v_station_draw.Kitchen, markerType = 21, customMarker = Config.CustomMarkers, markerTexture = "policemarker" },
                    { name = 'BossActions', locations = v_station_draw.BossActions, markerType = 22, customMarker = Config.CustomMarkers, markerTexture = "policemarker", bossOnly = true },
                    { name = 'BossBills', locations = v_station_draw.BossBills, markerType = 22, customMarker = Config.CustomMarkers, markerTexture = "policemarker", bossOnly = true }
                }

                for _, partData in ipairs(stationParts) do
                    if partData.locations then
                        if not (partData.bossOnly and (not ESX.PlayerData.job or ESX.PlayerData.job.grade_name ~= 'boss')) then
                            for i=1, #partData.locations, 1 do
                                local loc = partData.locations[i]
                                local distance = GetDistanceBetweenCoords(coords, loc.x, loc.y, loc.z, true) -- Use x,y,z directly if loc is vector3
                                if distance < Config.DrawDistance then
                                    if partData.customMarker then
                                        DrawMarker(9,loc.x,loc.y,loc.z,0,0,0,0,90.0,90.0,0.8,0.8,1.2,255,255,255,255,false,0,2,true,partData.markerTexture,partData.markerTexture,false)
                                    else
                                        DrawMarker(partData.markerType,loc.x,loc.y,loc.z,0,0,0,0,0,0,Config.MarkerSize.x,Config.MarkerSize.y,Config.MarkerSize.z,Config.MarkerColor.r,Config.MarkerColor.g,Config.MarkerColor.b,100,false,true,2,true,false,false,false)
                                    end
                                    letSleep = false
                                end
                                if distance < Config.MarkerSize.x then
                                    isInMarker, currentStation, currentPart, currentPartNum = true, k_station_draw, partData.name, i
                                end
                            end
                        end
                    end
                end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if (LastStation and LastPart and LastPartNum) and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum) then
					TriggerEvent('esx_policejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end
				HasAlreadyEnteredMarker = true
				LastStation, LastPart, LastPartNum = currentStation, currentPart, currentPartNum
				TriggerEvent('esx_policejob:hasEnteredMarker', currentStation, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_policejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end
			if letSleep then Wait(500) end
		else Wait(500) end
	end
end)

CreateThread(function()
	local trackedEntities = {
		'prop_roadcone02a', 'prop_barrier_work05', 'p_ld_stinger_s', 'prop_boxpile_07d',
		'hei_prop_cash_crate_half_full', 'prop_worklight_03b', "prop_gazebo_03", "stt_prop_track_slowdown"
	}
	while true do
		local sleep = 1000
		if ESX.PlayerData.job and ESX.PlayerData.job.name == "police" then
			sleep = 500; local playerPed, coords = Cache.ped, GetEntityCoords(Cache.ped)
			local closestDistance, closestEntity = -1, nil

			if(not blocklobjects) then
				for i=1, #trackedEntities, 1 do
					local object = GetClosestObjectOfType(coords, 3.0, joaat(trackedEntities[i]), false, false, false)
					if DoesEntityExist(object) and IsEntityAMissionEntity(object) then
						local objCoords = GetEntityCoords(object); local distance  = #(coords - objCoords)
						if closestDistance == -1 or closestDistance > distance then closestDistance, closestEntity = distance, object end
					end
				end
			end
			if closestDistance ~= -1 and closestDistance <= 5.0 then
				if LastEntity ~= closestEntity then TriggerEvent('esx_policejob:hasEnteredEntityZone', closestEntity); LastEntity = closestEntity end
			else
				if LastEntity then TriggerEvent('esx_policejob:hasExitedEntityZone', LastEntity); LastEntity = nil end
			end
		end
		Wait(sleep)
	end
end)

CreateThread(function()
	local Multiplied = false
    while true do
		local sleep = 1000; local ped = Cache.ped; local veh = GetVehiclePedIsUsing(ped)
        if veh ~= 0 then
			if GetVehicleClass(veh) == 18 then
				local isDriver = GetPedInVehicleSeat(veh,-1) == ped
				if(isDriver) then
					sleep = 200
					if IsDisabledControlPressed(0, 86) then
						if(not Multiplied) then Multiplied = true; SetVehicleLights(veh, 2); SetVehicleLightMultiplier(veh, 7.0) end
					elseif Multiplied then Multiplied = false; SetVehicleLights(veh, 0); SetVehicleLightMultiplier(veh, 1.0) end
				end
			end
        end
		Wait(sleep)
	end
end)

RegisterNetEvent("esx_policejob:RecieveHeli_C")
AddEventHandler("esx_policejob:RecieveHeli_C", function(coords,name,id)
	if(ESX ~= nil) then
		if not ESX.PlayerData or not ESX.PlayerData.job then
			return
		end
		if ESX.PlayerData.job.name == "police" then
			TriggerEvent('br_notify:show', 'inform', "Helicopter Marker", ".סימון מסוק משטרתי התקבל", 10000)
			local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
			local alpha = 250

			SetBlipHighDetail(blip, true)
			SetBlipSprite(blip, 162)
			SetBlipScale(blip, 0.9)
			SetBlipColour(blip,48)
			SetBlipAlpha(blip, alpha)

			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString("Target Marked | " ..name.." | "..id)
			EndTextCommandSetBlipName(blip)
			PlaySoundFrontend(-1, "HACKING_SUCCESS", 0, 1)

			Citizen.Wait(750)
			while alpha ~= 0 do
				Citizen.Wait(40 * 4)
				alpha = alpha - 1
				SetBlipAlpha(blip, alpha)

				if alpha == 0 then
					RemoveBlip(blip)
					return
				end
			end
			Citizen.Wait(25000)
			RemoveBlip(blip)
		end
	end
end)

function setUniform(job, playerPed,GetIn)
	TriggerEvent('skinchanger:getSkin', function(skin)
		if skin.sex == 0 then
			if Config.Uniforms[job].male then
				PlayClothesAnim(skin, Config.Uniforms[job].male, job, GetIn)
			else
				TriggerEvent('br_notify:show', 'error', _U('outfit_error_title'), _U('no_outfit'), 5000)
			end
		else
			if Config.Uniforms[job].female then
				PlayClothesAnim(skin, Config.Uniforms[job].female, job, GetIn)
			else
				TriggerEvent('br_notify:show', 'error', _U('outfit_error_title'), _U('no_outfit'), 5000)
			end
		end
	end)
end

local function GetJobArmor()
    if not ESX.PlayerData.job then return 0 end
	local armor = 100

	if(ESX.PlayerData.job.grade_name == "boss" or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
		return 100
	end

	local grade_name = ESX.PlayerData.job.grade_name
	if(grade_name == "recruit") then
		armor = 50
	elseif(grade_name == "officer") then
		armor = 60
	elseif(grade_name == "seniorofficer" or grade_name == "magav" or grade_name == "sergeant") then
		armor = 75
	end

	return armor
end

function PlayClothesAnim(skin, jobclothes, job, GetIn)
	if(currentTask.busy) then
		TriggerEvent('br_notify:show', 'error', "Clothing", "אתה כבר מחליף בגדים", 5000)
		return
	end
	currentTask.busy = true
	DoScreenFadeOut(800)
	while not IsScreenFadedOut() do
		Wait(10)
	end
	if(skin) then
		if(jobclothes) then
			TriggerEvent('skinchanger:loadClothes', skin, jobclothes)
		else
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(playerSkin)
                TriggerEvent('skinchanger:loadSkin', playerSkin)
            end)
		end
	end
	TriggerEvent('InteractSound_CL:PlayOnOne', 'zipcloth', 1.0)
	RequestAnimDict("move_m@_idles@shake_off")
	while not HasAnimDictLoaded("move_m@_idles@shake_off") do
		Wait(10)
	end
	TaskPlayAnim(Cache.ped, "move_m@_idles@shake_off", "shakeoff_1", 7.0, 7.0, 3500, 51, 0, false, false, false)
	RemoveAnimDict("move_m@_idles@shake_off")
	DoScreenFadeIn(800)
	while not IsScreenFadedIn() do
		Wait(10)
	end
	if(not GetIn) then
		if( job == 'bullet_wear' or job == 'yamam_wear' or job == "magav_vest" ) then
			SetPedArmour(Cache.ped, GetJobArmor())
			PlaySoundFrontend(-1, "Armour_On", "DLC_GR_Steal_Miniguns_Sounds", true)
		elseif( job == 'gilet_wear') then
			SetPedArmour(Cache.ped, 15)
			PlaySoundFrontend(-1, "Armour_On", "DLC_GR_Steal_Miniguns_Sounds", true)
		end
	end
	currentTask.busy = false
end

local function OpenOutfits()
	ESX.TriggerServerCallback('esx_property:getPlayerDressing', function(dressing)
		local elements = {}
        table.insert(elements, { title = "חדר לבוש משטרתי - בגדים שלך", description = "Select an outfit", disabled = true})

		for i=1, #dressing, 1 do
            if dressing[i] then -- Ensure dressing[i] is not nil
                table.insert(elements, {
                    title = dressing[i].label or "Unnamed Outfit",
                    value = dressing[i].id, -- Use a unique identifier for the outfit
                    -- serverEvent = 'esx_property:getPlayerOutfit', -- Not needed if handled in onSelect
                    -- args = { outfitId = dressing[i].id }
                })
            end
		end

        if #elements == 1 then -- Only the title was added
            TriggerEvent('br_notify:show', 'inform', "Outfits", "No saved outfits found.", 5000)
            OpenCloakroomMenu() -- Go back to the previous menu
            return
        end

        lib.registerContext({
            id = 'police_outfits_menu',
            title = "חדר לבוש משטרתי - בגדים שלך",
            options = elements,
            onSelect = function(data)
                if data.value then -- Check if a selectable outfit was chosen (not the title)
                    TriggerEvent('skinchanger:getSkin', function(skin)
                        ESX.TriggerServerCallback('esx_property:getPlayerOutfit', function(clothes)
                            if clothes then
                                TriggerEvent('skinchanger:loadClothes', skin, clothes)
                                TriggerEvent('esx_skin:setLastSkin', skin) -- Assuming esx_skin is used
                                TriggerEvent('skinchanger:getSkin', function(skinToSave)
                                    ESX.SEvent('esx_skin:save', skinToSave)
                                end)
                            else
                                TriggerEvent('br_notify:show', 'error', "Outfit Error", "Could not load selected outfit.", 5000)
                            end
                        end, data.value)
                    end)
                end
            end,
            onClose = function() OpenCloakroomMenu() end
        })
        lib.showContext('police_outfits_menu')
	end)
end

function OpenCloakroomMenu(GetIn)
    if not ESX.PlayerData.job then return end
	local playerPed = Cache.ped
	local grade = ESX.PlayerData.job.grade_name
	local elements = {
		{ title = TranslateCap("cloakroom"), description = "Main Cloakroom Menu", disabled = true},
		{ title = "Outfits", value = 'outfits', icon = 'fas fa-user-ninja'},
		{ title = TranslateCap('citizen_wear'), value = 'citizen_wear', icon = 'fas fa-user-tie'},
		{ title = TranslateCap('bullet_wear'), value = 'bullet_wear', icon = 'fas fa-shield-alt'},
		{ title = TranslateCap('gilet_wear'), value = 'gilet_wear', icon = 'fas fa-shield-alt'},
		{ title = 'ווסט ימ"מ', value = 'yamam_wear', icon = 'fas fa-user-shield'},
		{ title = 'ווסט מג"ב', value = 'magav_vest', icon = 'fas fa-user-shield'},
		{ title = "הגדרות", value = 'settings', icon = 'fas fa-cog'},
	}

	if grade == 'recruit' then
		elements[#elements+1] = {title = _U('police_wear') , value = 'recruit_wear', icon = 'fas fa-hard-hat'}
	elseif grade == 'officer' then
		elements[#elements+1] = {title = _U('police_wear') , value = 'officer_wear', icon = 'fas fa-hard-hat'}
	elseif grade == 'seniorofficer' then
		elements[#elements+1] = {title = "לבוש רב סיור" , value = 'seniorofficer_wear', icon = 'fas fa-hard-hat'}
	elseif grade == 'sergeant' then
		elements[#elements+1] = {title = _U('police_wear') , value = 'sergeant_wear', icon = 'fas fa-hard-hat'}
	elseif grade == 'agent' then
		elements[#elements+1] = {title = _U('police_wear') , value = 'lieutenant_wear', icon = 'fas fa-user-secret'}
	elseif grade == 'magav' then
		elements[#elements+1] = {title = 'בגדי מג"ב' , value = 'magav_wear', icon = 'fas fa-user-shield'}
	elseif grade == 'lieutenant' then
		elements[#elements+1] = {title = _U('police_wear') , value = 'lieutenant_wear', icon = 'fas fa-user-graduate'}
	elseif grade == 'boss' then
		elements[#elements+1] = {title = _U('police_wear') , value = 'boss_wear', icon = 'fas fa-user-tie'}
		elements[#elements+1] = {title = 'בגדי מג"ב' , value = 'magav_wear', icon = 'fas fa-user-shield'}
		elements[#elements+1] = {title = 'מדי ימ"מ' , value = 'lieutenant_wear', icon = 'fas fa-user-astronaut'}
		elements[#elements+1] = {title = 'מדי יס"מ' , value = 'sergeant_wear', icon = 'fas fa-user-ninja'}
		elements[#elements+1] = {title = 'מדי סיור' , value = 'officer_wear', icon = 'fas fa-street-view'}
		elements[#elements+1] = {title = "לבוש רב סיור" , value = 'seniorofficer_wear', icon = 'fas fa-user-check'}
	end

    lib.registerContext({
        id = 'police_cloakroom_menu',
        title = TranslateCap("cloakroom"),
        options = elements,
        onSelect = function(data)
            if data.value then
                cleanPlayer(playerPed)
                if data.value == 'outfits' then OpenOutfits()
                elseif data.value == 'citizen_wear' then
                    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin) PlayClothesAnim(skin) end)
                elseif data.value == "settings" then UniformSettings()
                elseif data.value == 'recruit_wear' or data.value == 'officer_wear' or
                    data.value == 'sergeant_wear' or data.value == 'lieutenant_wear' or
                    data.value == 'boss_wear' or data.value == 'bullet_wear' or
                    data.value == 'gilet_wear' or data.value == 'yamam_wear' or
                    data.value == 'magav_vest' or data.value == 'police_bag' or
                    data.value == 'seniorofficer_wear' or data.value == 'magav_wear'
                then
                    setUniform(data.value, playerPed,GetIn)
                end
            end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
    })
    lib.showContext('police_cloakroom_menu')
end

function UniformSettings()
	local elements = {
		{title = TranslateCap("cloakroom"), description="Settings", disabled = true},
		{title = "אנימצית שליפה", value = 'draw_weapon', icon = 'fas fa-hand-paper'},
	}

    lib.registerContext({
        id = 'police_uniform_settings_menu',
        title = TranslateCap("cloakroom"),
        options = elements,
        onSelect = function(data)
            if data.value == 'draw_weapon' then TriggerEvent('gi-holster:ForceNormal') end
        end,
        onClose = function() OpenCloakroomMenu() end
    })
    lib.showContext('police_uniform_settings_menu')
end

function OpenArmoryMenu(station)
    if not ESX.PlayerData.job then return end
    local elements = {}

    if Config.EnableArmoryManagement then
        elements[#elements+1] = {title = "ארון אחסון", value = 'open_inventory', description = "!סטאש של המשטרה, לא לזרוק לפה זבל", icon = "fas fa-archive"}
        elements[#elements+1] = {title = "מחיקת ציוד משטרתי שעליך", value = 'clear_inventory', description = "מוחק את כל הנשקים שעליך", icon = "fas fa-bomb"}
        elements[#elements+1] = {title = "מזבלת משטרה", value = 'trash', description = "מחיקת דברים ספציפים שעליך", icon = "fas fa-trash-alt"}
        if ESX.PlayerData.job.grade_name == "boss" then
            elements[#elements+1] = {title = "ניקוי ציוד סטאש", value = 'stash_clearweapons', description = "מוחק את כל הנשקים + ציוד בסטאש", icon = "fas fa-skull-crossbones"}
        end
    end

    if #elements == 0 then
        TriggerEvent('br_notify:show', 'inform', "Armory", "Armory management is disabled or no actions available.", 5000)
        HasAlreadyEnteredMarker = false
        return
    end

    lib.registerContext({
        id = 'police_armory_menu',
        title = "Police Armory",
        options = elements,
        onSelect = function(data)
            local action = data.value
            if not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police" then return end

            if action then
                if action == "open_inventory" then
                    exports.ox_inventory:openInventory('stash', 'Stash_Police')
                    HasAlreadyEnteredMarker = false
                elseif action == "clear_inventory" then
                    ESX.SEvent("esx_policejob:ClearINVWeapons")
                elseif action == "stash_clearweapons" then
                    if ESX.PlayerData.job.grade_name == "boss" then
                        lib.alertDialog({
                            header = "האם אתה בטוח?",
                            content = "This will delete all weapons and equipment from the stash. This action cannot be undone.",
                            centered = true,
                            cancel = true,
                            labels = {
                                confirm = "מחק ציוד מהסטאש",
                                cancel = "לא"
                            }
                        }, function(confirm)
                            HasAlreadyEnteredMarker = false
                            if confirm == "confirm" then
                                ESX.SEvent("esx_policejob:ClearStashWeapons")
                            else
                                TriggerEvent('br_notify:show', "inform", "Police Armory", "ביטלת את המחיקה", 5000)
                            end
                        end)
                    else 
                        HasAlreadyEnteredMarker = false 
                    end
                elseif action == "trash" then 
                    OpenTrashMenu() 
                end
            end
        end,
        onClose = function() 
            HasAlreadyEnteredMarker = false 
        end
    })
    lib.showContext('police_armory_menu')
end

function OpenKitchenMenu()
	HasAlreadyEnteredMarker = false
	exports.ox_inventory:openInventory('stash', 'Police_Fridge')
end

function OpenTrashMenu()
    local elements = { {title = "ארון זבל, לחץ על כל אייטם שאתה רוצה לזרוק", description = "Select an item to trash", disabled = true} }
    local inventory = ESX.GetPlayerData().inventory

    for k,v in pairs(inventory) do
        if v.name ~= "cash" and v.name ~= "black_money" then
            table.insert(elements, {
                title = v.label.." - x"..v.count,
                value = {name = v.name, slot = v.slot, type = v.type, amount = v.count},
                description = "!!!!!!!לחיצה = מחיקה אין החזרים"
            })
        end
    end

    if #elements == 1 then
        TriggerEvent('br_notify:show', "error", "Inventory Empty", "האינוונטורי שלך ריק", 5000)
        OpenArmoryMenu()
        return
    end

    lib.registerContext({
        id = 'police_trash_menu',
        title = "ארון זבל",
        options = elements,
        onSelect = function(data)
            local item = data.value
            if item then
                if not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police" then return end
                
                if item.type == "weapon" then
                    ESX.SEvent("esx_policejob:ClearSpecificItem", item, 1)
                    Wait(200)
                    OpenTrashMenu()
                else
                    lib.inputDialog("?כמה תרצה למחוק", {
                        { type = 'number', label = 'Amount', required = true, min = 1, default = 1, name = 'amount'}
                    }, function(trashAmountInput)
                        if trashAmountInput and trashAmountInput.amount then
                            local amountToTrash = tonumber(trashAmountInput.amount)
                            if amountToTrash and amountToTrash > 0 and amountToTrash <= item.amount then
                                ESX.SEvent("esx_policejob:ClearSpecificItem", item, amountToTrash)
                                Wait(200)
                                OpenTrashMenu()
                            else
                                TriggerEvent('br_notify:show', "error", "Error", "אין לך את הכמות המבוקשת מהאייטם הזה או שהכמות שגויה", 5000)
                            end
                        end
                    end)
                end
            end
        end,
        onClose = function() 
            OpenArmoryMenu() 
        end
    })
    lib.showContext('police_trash_menu')
end

local lastscan_callbackup -- Renamed to avoid conflict if 'lastscan' is used elsewhere
RegisterCommand('callbackup',function()
    if not ESX.PlayerData.job then return end
	if ESX.PlayerData.job.name == "police" then
        if(IsPedDeadOrDying(Cache.ped)) then
			TriggerEvent('br_notify:show', "error", "Backup", "!אתה לא יכול לקרוא תגבורת כשאתה מת", 5000)
			return
		end
		local playercuffed = exports['esx_thief']:IsTCuffed()

		if(playercuffed) then
			TriggerEvent('br_notify:show', 'error', "Backup", 'אתה לא יכול לקרוא לתגבורת בזמן שאתה אזוק', 5000)
			return
		end

		if(not lastscan_callbackup or (GetTimeDifference(GetGameTimer(), lastscan_callbackup) > 30000)) then
			local text = "קורא לתגבורת"
			TriggerEvent("gi-3dme:network:mecmd",text)
			RequestAnimDict("random@arrests");
			while not HasAnimDictLoaded("random@arrests") do Wait(5) end
			TaskPlayAnim(Cache.ped,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
			ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)
			lastscan_callbackup = GetGameTimer()

            exports.ox_lib:progressBar({
                duration = 1000,
                label = "קורא לתגבורת",
                useWhileDead = false,
                canCancel = true,
                disable = { car = true },
                anim = { dict = "random@arrests", clip = "generic_radio_chatter" }
            })
            -- Assuming the progress bar completion means the action is done.
            -- If it needs to wait for the bar to finish before triggering server event:
            -- local finished = await exports.ox_lib:progressBar(...)
            -- if finished then TriggerServerEvent('esx_policejob:server:RequestBackup') end
			Citizen.Wait(1000) -- Kept original wait, adjust if progressBar has a callback
			TriggerServerEvent('esx_policejob:server:RequestBackup')
			StopAnimTask(Cache.ped, "random@arrests","generic_radio_chatter", -4.0);
			RemoveAnimDict("random@arrests")
		else
			TriggerEvent('br_notify:show', 'error', "Backup", 'יש להמתין חצי דקה בין כל בקשת תגבורת', 5000)
		end
	elseif ESX.PlayerData.job.name == "ambulance" then
        if(IsPedDeadOrDying(Cache.ped)) then
			TriggerEvent('br_notify:show', "error", "Backup", "!אתה לא יכול לקרוא תגבורת כשאתה מת", 5000)
			return
		end
		local playercuffed = exports['esx_thief']:IsTCuffed()

		if(playercuffed) then
			TriggerEvent('br_notify:show', 'error', "Backup", 'אתה לא יכול לקרוא לתגבורת בזמן שאתה אזוק', 5000)
			return
		end

		if(not lastscan_callbackup or (GetTimeDifference(GetGameTimer(), lastscan_callbackup) > 30000)) then
			local text = "קורא לתגבורת"
			TriggerEvent("gi-3dme:network:mecmd",text)
			RequestAnimDict("random@arrests");
			while not HasAnimDictLoaded("random@arrests") do Wait(5) end
			TaskPlayAnim(Cache.ped,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
			ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)
			lastscan_callbackup = GetGameTimer()
            exports.ox_lib:progressBar({
                duration = 1000,
                label = "קורא לתגבורת",
                useWhileDead = false,
                canCancel = true,
                disable = { car = true },
                anim = { dict = "random@arrests", clip = "generic_radio_chatter" }
            })
			Citizen.Wait(1000)
			TriggerServerEvent('esx_ambulancejob:server:RequestBackup')
			StopAnimTask(Cache.ped, "random@arrests","generic_radio_chatter", -4.0);
			RemoveAnimDict("random@arrests")
		else
			TriggerEvent('br_notify:show', 'error', "Backup", 'יש להמתין חצי דקה בין כל בקשת תגבורת', 5000)
		end
	end
end)

local TowMission = false

local function GetClosestTowSpot()
	local coords = GetEntityCoords(Cache.ped)
	local closest = 5000
	local closestCoords

	for k,v in pairs(Config.TowSpot) do
		local dstcheck = GetDistanceBetweenCoords(coords, v)
		if dstcheck < closest then
			closest = dstcheck
            closestCoords = v
        end
    end
	return closestCoords
end

function OpenPoliceActionsMenu()
    if not ESX.PlayerData.job then return end
    local elements = {
        { title = 'תפריט משטרה', description = "Police Actions", disabled = true},
        { title = _U('citizen_interaction'), value = 'citizen_interaction', description = "ניהול הקרציות", icon = 'fas fa-users-cog' },
        { title = _U('vehicle_interaction'), value = 'vehicle_interaction', description = ".עיקול רכבים, דוח על רכב וכו", icon = 'fas fa-car'},
        { title = _U('object_spawner'), value = 'object_spawner', description = "נועד לשגר אובייקטים", icon = 'fas fa-box'},
        { title = "מרדפים", value = 'chases', description = "פעולות שקשורות למרדפים", icon = 'fas fa-running'},
        { title = "שליחה לכלא", value = 'jail_menu', description = "לשלוח אדם לכלא ( להשתמש בזה רק בתוך מתחם הכלא )", icon = 'fas fa-lock'},
        { title = "בקשת תגבורת", value = 'backup_menu', description = "מסמן את מיקומך לשאר השוטרים", icon = 'fas fa-map-marker-alt'},
    }

    if recentlyIN == true then
        table.insert(elements, {title = '<span style="color:cyan;">לבוש כניסה לשרת</span>', value = 'clothes', description = "תפריט בגדים ( עובד רק 2 דקות מרגע הכניסה לשרת )", icon = 'fas fa-tshirt'})
    end

    if not TowMission and Config.TowTrucks[GetEntityModel(GetVehiclePedIsIn(Cache.ped,false))] then
        table.insert(elements, {title = 'משימת גרירת רכב', value = 'tow_mission', icon = 'fas fa-truck-pickup'})
        table.insert(elements, {title = "שחרר את הרכב הנגרר", value = 'clear_tow', icon = 'fas fa-hand-paper'})
    end

    lib.registerContext({
        id = 'police_actions_menu',
        title = 'תפריט משטרה',
        options = elements,
        onSelect = function(data)
            local value = data.value
            if value == "clothes" then
                OpenCloakroomMenu(true)
                recentlyIN = nil
            elseif value == 'jail_menu' then
                TriggerEvent("police:client:JailPlayer")
            elseif value == 'backup_menu' then
                if not lastscan_callbackup or (GetTimeDifference(GetGameTimer(), lastscan_callbackup) > 30000) then  -- Fixed missing parenthesis here
                    lastscan_callbackup = GetGameTimer()
                    local text = "קורא לתגבורת"
                    TriggerEvent("gi-3dme:network:mecmd", text)
                    RequestAnimDict("random@arrests")
                    while not HasAnimDictLoaded("random@arrests") do Wait(5) end
                    TaskPlayAnim(Cache.ped, "random@arrests", "generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0)
                    ESX.SEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)

                    exports.ox_lib:progressBar({
                        duration = 1000, 
                        label = "קורא לתגבורת", 
                        useWhileDead = false, 
                        canCancel = true,
                        anim = { dict = "random@arrests", clip = "generic_radio_chatter" }
                    }, function(finished)
                        if finished then
                            TriggerServerEvent('esx_policejob:server:RequestBackup')
                            StopAnimTask(Cache.ped, "random@arrests", "generic_radio_chatter", -4.0)
                            RemoveAnimDict("random@arrests")
                        end
                    end)
                else
                    TriggerEvent('br_notify:show', 'error', "Backup", 'יש להמתין חצי דקה בין כל בקשת תגבורת', 5000)
                end
            elseif value == 'tow_mission' then
                -- Tow mission code here
            elseif value == 'clear_tow' then
                -- Clear tow code here
            elseif value == 'citizen_interaction' then 
                OpenCitizenInteractionMenu()
            elseif value == 'vehicle_interaction' then 
                OpenVehicleInteractionMenu()
            elseif value == 'object_spawner' then 
                OpenObjectSpawnerMenu()
            elseif value == "chases" then 
                OpenChasesMenu()
            end
        end,
        onClose = function() 
            HasAlreadyEnteredMarker = false 
        end
    })
    lib.showContext('police_actions_menu')
end
function OpenCitizenInteractionMenu()
    if not ESX.PlayerData.job then return end
    local elements = {
        { title = _U('citizen_interaction'), description = "Citizen Actions", disabled = true},
        { title = _U('id_card'), value = 'identity_card', description = "בשימוש ME חייב לעשות", icon = 'fas fa-id-card'},
        { title = _U('search'), value = 'search', description = "חיפוש על שחקן", icon = 'fas fa-search'},
        { title = _U('handcuff'), value = 'handcuff', description = "אזיקת שחקן", icon = 'fas fa-lock'},
        { title = _U('uncuff'), value = 'uncuff', description = "הורדת אזיקה לשחקן", icon = 'fas fa-unlock'},
        { title = _U('drag'), value = 'drag', description = "לגרור שחקן אזוק", icon = 'fas fa-people-arrows'},
        { title = "להוריד מסיכה", value = 'maskoff', icon = 'fas fa-theater-masks'},
        { title = _U('put_in_vehicle'), value = 'put_in_vehicle', icon = 'fas fa-car-side'},
        { title = _U('out_the_vehicle'), value = 'out_the_vehicle', icon = 'fas fa-sign-out-alt'},
        { title = _U('fine'), value = 'fine', description = "דוח לשחקן הקרוב", icon = 'fas fa-file-invoice-dollar'},
        { title = "עבודות שירות", value = 'communityservice', description = "עבודות שירות ( עד 60 )", icon = 'fas fa-broom'},
        { title = _U('unpaid_bills'), value = 'unpaid_bills', description = "דוחות לא משולמים", icon = 'fas fa-file-invoice'},
    }

    if NearFingerScanner() then
        table.insert(elements,{title = "סריקת אצבע בכוח",value = 'finger_force', description = "כופה על שחקן לשים את האצבע על הסורק", icon = 'fas fa-fingerprint'})
    end

    if Config.EnableLicenses then
        table.insert(elements, { title = _U('license_check'), value = 'license', icon = 'fas fa-id-badge' })
    end
    table.insert(elements, {title = "דוח ניהולי", value = "custom_bill", icon = 'fas fa-file-signature'})

    if ESX.PlayerData.job.grade_name == "boss" then
        table.insert(elements, {title = "בדיקת קנה", value = "barrel_check", description = "נועד לתפוס שוטרים שירו בתחנה, לא נועד לפשע כי יש אבקת שריפה היום.", icon = 'fas fa-fire-extinguisher'})
        table.insert(elements, {title = '<strong><span style="color:cyan;">בדיקת בתים</strong>', value = "house_check", icon = 'fas fa-house-user'})
    elseif string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין") then
        table.insert(elements, {title = "בדיקת קנה", value = "barrel_check", description = "נועד לתפוס שוטרים שירו בתחנה, לא נועד לפשע כי יש אבקת שריפה היום.", icon = 'fas fa-fire-extinguisher'})
    end

    lib.registerContext({
        id = 'police_citizen_interaction_menu',
        title = _U('citizen_interaction'),
        options = elements,
        onSelect = function(data)
            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
            local actionValue = data.value

            if actionValue == 'house_check' then
                if ESX.PlayerData.job.grade_name == "boss" then
                    lib.inputDialog("מספר תעודת זהות", {
                        {type = 'input', label = "מספר תז", required = true, name = 'idn'}
                    }, function(IDN_input)
                        if IDN_input and IDN_input.idn then
                            local IDN = IDN_input.idn
                            local length = string.len(IDN)
                            if IDN == nil or length < 2 or length > 13 then 
                                TriggerEvent('br_notify:show', "error", "Input Error", "מספר תעודת זהות שגוי", 5000)
                            else 
                                OpenPropList(IDN) 
                            end
                        end
                    end)
                end
                return
            end

            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                local targetServerId = GetPlayerServerId(closestPlayer)
                if actionValue == 'identity_card' then 
                    OpenIdentityCardMenu(closestPlayer)
                elseif actionValue == 'search' then 
                    OpenBodySearchMenu(closestPlayer)
                elseif actionValue == 'handcuff' then
                    if handcuffing == true then 
                        TriggerEvent('br_notify:show', 'error', "Cuffing", 'You Are Already Cuffing/Uncuffing', 5000)
                        return 
                    end
                    local playerPed = Cache.ped
                    local playerheading = GetEntityHeading(playerPed)
                    local playerlocation = GetEntityForwardVector(playerPed)
                    local playerCoords = GetEntityCoords(playerPed)
                    ESX.SEvent('esx_policejob:requestarrest', targetServerId, playerheading, playerCoords, playerlocation)
                elseif actionValue == 'uncuff' then
                    if handcuffing == true then 
                        TriggerEvent('br_notify:show', 'error', "Cuffing", 'You Are Already Cuffing/Uncuffing', 5000)
                        return 
                    end
                    local target,distance = ESX.Game.GetClosestPlayerCuffed()
                    if target ~= -1 and distance <= 3.0 then
                        local playerPed = Cache.ped
                        local playerheading = GetEntityHeading(playerPed)
                        local playerlocation = GetEntityForwardVector(playerPed)
                        local playerCoords = GetEntityCoords(playerPed)
                        ESX.SEvent('esx_policejob:requestrelease', GetPlayerServerId(target), playerheading, playerCoords, playerlocation)
                    else 
                        TriggerEvent('br_notify:show', "error", "Uncuff Error", "לא נמצא אף אחד אזוק בסביבתך", 5000) 
                    end
                elseif actionValue == 'drag' then
                    OnesyncEnableRemoteAttachmentSanitization(false)
                    SetTimeout(200, function() 
                        OnesyncEnableRemoteAttachmentSanitization(true) 
                    end)
                    TriggerEvent("gi-3dme:network:mecmd","גורר")
                    ESX.SEvent('esx_policejob:drag', targetServerId)
                elseif actionValue == 'maskoff' then 
                    ESX.SEvent('esx_policejob:maskoff', targetServerId)
                elseif actionValue == 'put_in_vehicle' then
                    local target,distance = ESX.Game.GetClosestPlayerCuffed()
                    if target ~= -1 and distance <= 3.0 then 
                        TriggerEvent("gi-3dme:network:mecmd","מכניס לרכב")
                        ESX.SEvent('esx_policejob:putInVehicle', GetPlayerServerId(target))
                    else 
                        TriggerEvent('br_notify:show', "error", "Vehicle Error", "לא נמצא אף אחד אזוק בסביבתך", 5000) 
                    end
                elseif actionValue == 'out_the_vehicle' then
                    local target,distance = ESX.Game.GetClosestPlayerCuffed()
                    if target ~= -1 and distance <= 3.0 then 
                        TriggerEvent("gi-3dme:network:mecmd","מוציא מרכב")
                        ESX.SEvent('esx_policejob:OutVehicle', GetPlayerServerId(target))
                    else 
                        TriggerEvent('br_notify:show', "error", "Vehicle Error", "לא נמצא אף אחד אזוק בסביבתך", 5000) 
                    end
                elseif actionValue == 'fine' then 
                    OpenFineMenu(closestPlayer)
                elseif actionValue == 'license' then 
                    ShowPlayerLicense(closestPlayer)
                elseif actionValue == 'unpaid_bills' then 
                    OpenUnpaidBillsMenu(closestPlayer)
                elseif actionValue == 'communityservice' then 
                    ExecuteCommand("coms " .. targetServerId)
                elseif actionValue == 'barrel_check' then 
                    TriggerEvent('esx_policejob:CheckBarrel',targetServerId)
                elseif actionValue == 'custom_bill' then
                    lib.inputDialog("דוח ניהולי", {
                        { type = 'input', label = "סיבת דוח", required = true, name = "reason"},
                        { type = 'number', label = "כמות כסף", required = true, name = "amount"}
                    }, function(inputs)
                        if inputs and inputs.reason and inputs.amount then
                            local reason, amount = inputs.reason, tonumber(inputs.amount)
                            if amount == nil then 
                                TriggerEvent('br_notify:show', "error", "Billing Error", "כמות שגויה", 5000)
                            elseif amount > 60000 then 
                                TriggerEvent('br_notify:show', "error", "Billing Error", 'הסכום המקסימלי הוא 60,000 שקל בלבד', 5000)
                            else
                                local targetPlayerForBill, targetDistanceForBill = ESX.Game.GetClosestPlayer()
                                if targetPlayerForBill == -1 or targetDistanceForBill > 3.0 then 
                                    TriggerEvent('br_notify:show', 'error', "Billing Error", _U('no_players_nearby'), 5000)
                                else
                                    TriggerServerEvent('okokBilling:createBill', GetPlayerServerId(targetPlayerForBill), "Police Department", reason, amount)
                                    TriggerEvent('br_notify:show', 'success', "Billing", "Bill sent to okokBilling", 5000)
                                end
                            end
                        else 
                            TriggerEvent('br_notify:show', 'error', "Billing Error", 'יש לציין את סכום הדוח וסיבת הדוח', 5000) 
                        end
                    end)
                elseif actionValue == 'finger_force' then 
                    ForceFingerprint() 
                end
            else 
                TriggerEvent('br_notify:show','error', "Error", _U('no_players_nearby'), 5000) 
            end
        end,
        onClose = function() 
            HasAlreadyEnteredMarker = false 
        end
    })
    lib.showContext('police_citizen_interaction_menu')
end

function OpenVehicleInteractionMenu()
    if not ESX.PlayerData.job then return end
    local elements = { {title = _U('vehicle_interaction'), description = "Vehicle Actions", disabled = true} }
    local playerPed = Cache.ped
    local vehicle = ESX.Game.GetVehicleInDirection()

    -- [Previous element additions remain the same...]

    lib.registerContext({
        id = 'police_vehicle_interaction_menu',
        title = _U('vehicle_interaction'),
        options = elements,
        onSelect = function(data)
            local playerPed = Cache.ped
            local coords = GetEntityCoords(playerPed)
            local currentVehicle = ESX.Game.GetVehicleInDirection()
            local action = data.value

            if action == 'search_database' then 
                LookupVehicle()
            elseif action == 'seize_list' then 
                LookupVehicleSeize()
            elseif action == 'search_bike' then
                local targetVehicle = ESX.Game.GetClosestVehicle(coords, 4.0, 0, 71)
                if DoesEntityExist(targetVehicle) then
                    local model = GetEntityModel(targetVehicle)
                    if GetVehicleClass(targetVehicle) == 8 or GetVehicleClass(targetVehicle) == 13 or IsThisModelABike(model) then 
                        BikeInteraction2(targetVehicle)
                    else 
                        TriggerEvent('br_notify:show', 'error', "Vehicle Error", 'הרכב הכי קרוב אליך אינו אופנוע', 5000) 
                    end
                else 
                    TriggerEvent('br_notify:show', 'error', "Vehicle Error", 'לא נמצא שום רכב', 5000) 
                end
            elseif action == 'seize_vehicle' then
                if IsPedInAnyVehicle(playerPed, false) then
                    local vehToSeize = GetVehiclePedIsIn(playerPed, false)
                    if DoesEntityExist(vehToSeize) then
                        if ESX.PlayerData.job.grade_name == 'boss' then
                            if GetVehicleClass(vehToSeize) ~= 18 then
                                local plate = GetVehicleNumberPlateText(vehToSeize)
                                if string.match(plate, " ") then
                                    TaskLeaveVehicle(playerPed, vehToSeize, 0)
                                    while IsPedInAnyVehicle(Cache.ped) do Citizen.Wait(500) end
                                    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)

                                    exports.ox_lib:progressBar({
                                        duration = 7500, 
                                        label = "מחרים רכב", 
                                        useWhileDead = false, 
                                        canCancel = true,
                                        disable = { car = true }, 
                                        anim = { dict = "WORLD_HUMAN_CLIPBOARD", clip = "WORLD_HUMAN_CLIPBOARD" }
                                    }, function(finished)
                                        ClearPedTasksImmediately(Cache.ped)
                                        if finished then 
                                            ESX.SEvent("esx_policejob:SeizeVehicle", plate)
                                            ImpoundVehicle(vehToSeize) 
                                        end
                                    end)
                                else 
                                    TriggerEvent('br_notify:show', 'error', "Seize Error", 'אין אפשרות להחרים רכב מסוג זה', 5000) 
                                end
                            end
                        end
                    end
                end
            elseif action == 'call_nayedet' then 
                TriggerEvent('esx_policejob:callnayedet')
            elseif action == "scanveh" then
                if DoesEntityExist(currentVehicle) then
                    if GetVehicleClass(currentVehicle) == 18 then
                        if not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000) then
                            lastscan = GetGameTimer()
                            ESX.SEvent('esx_policejob:ScanVeh', ESX.Math.Trim(GetVehicleNumberPlateText(currentVehicle)))
                        else 
                            TriggerEvent('br_notify:show', "error", "Scan Error", "נא להמתין 5 שניות בין כל סריקה", 5000) 
                        end
                    else 
                        TriggerEvent('br_notify:show', "error", "Scan Error", "הרכב שנבחר אינו משטרתי", 5000) 
                    end
                end
            elseif DoesEntityExist(currentVehicle) then
                if action == 'vehicle_infos' then 
                    OpenVehicleInfosMenu(currentVehicle)
                elseif action == 'hijack_vehicle' then
                    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
                        exports.ox_lib:progressBar({
                            duration = 15000, 
                            label = "פורץ את הרכב", 
                            useWhileDead = false, 
                            canCancel = true,
                            disable = { movement = true, carMovement = true, mouse = false, combat = true },
                            anim = { dict = "WORLD_HUMAN_WELDING", clip = "WORLD_HUMAN_WELDING" }
                        }, function(finished)
                            ClearPedTasksImmediately(Cache.ped)
                            if finished then
                                if DoesEntityExist(currentVehicle) and NetworkGetEntityIsNetworked(currentVehicle) then
                                    if ESX.PlayerData.job.name ~= "police" then return end
                                    lib.callback("esx_policejob:server:requestlockpick", false, function(success)
                                        if success then
                                            lib.requestNamedPtfxAsset("core")
                                            SetPtfxAssetNextCall("core")
                                            local vehcoords = GetEntityCoords(currentVehicle)
                                            StartParticleFxLoopedAtCoord("ent_brk_metal_frag", vehcoords.x, vehcoords.y, vehcoords.z, 0, 0, 0, 2.0, 0, 0, 0, 0)
                                            RemoveNamedPtfxAsset("core")
                                            SetVehicleDoorsLocked(currentVehicle, 1)
                                            SetVehicleDoorsLockedForAllPlayers(currentVehicle, false)
                                            PlaySoundFromEntity(-1, "Drill_Pin_Break", currentVehicle, "DLC_HEIST_FLEECA_SOUNDSET", false, false)
                                            TriggerEvent('br_notify:show', "success", "Success", "!הרכב נפרץ בהצלחה", 5000)
                                        end
                                    end, VehToNet(currentVehicle))
                                else 
                                    TriggerEvent('br_notify:show', "error", "Error", ".תקלה, נסה שוב", 5000) 
                                end
                            end
                        end)
                    end
                elseif action == "carjack_vehicle" then
                    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
                        if GetPedInVehicleSeat(currentVehicle, -1) ~= 0 then
                            TriggerEvent('br_notify:show', 'info', "Carjack", 'מתחיל הוצאה בכוח', 5000)
                            exports.ox_lib:skillCheck({ difficulty = 'easy', type = 'circle' }, function(success)
                                if success then 
                                    TaskEnterVehicle(Cache.ped, currentVehicle, 3000, -1, 2.0, 8, 0)
                                else 
                                    TriggerEvent('br_notify:show', 'error', "Carjack Failed", 'הוצאה נכשלה', 5000) 
                                end
                            end)
                        else 
                            TriggerEvent('br_notify:show', 'info', "Carjack", 'לא נמצא אף אחד ברכב', 5000) 
                        end
                    end
                elseif action == 'impound' then
                    if currentTask.busy then return end
                    currentTask.busy = true
                    local duration = 10000
                    local plate = GetVehicleNumberPlateText(currentVehicle)
                    if not string.match(plate, " ") or GetVehicleClass(currentVehicle) == 18 then 
                        duration = math.floor(duration / 2) 
                    end
                    DrawOutlineEntity(currentVehicle, true)
                    exports.ox_lib:progressBar({
                        duration = duration, 
                        label = "מעקל את הרכב", 
                        useWhileDead = false, 
                        canCancel = true,
                        disable = { movement = true, carMovement = true, mouse = false, combat = true },
                        anim = { dict = "CODE_HUMAN_MEDIC_TEND_TO_DEAD", clip = "CODE_HUMAN_MEDIC_TEND_TO_DEAD" }
                    }, function(finished)
                        ClearPedTasksImmediately(playerPed)
                        DrawOutlineEntity(currentVehicle, false)
                        currentTask.busy = false
                        if finished then
                            local vcoords = GetEntityCoords(currentVehicle)
                            local pcoords = GetEntityCoords(playerPed)
                            if Vdist(pcoords, vcoords) < 6 then 
                                ImpoundVehicle(currentVehicle)
                            else 
                                TriggerEvent('br_notify:show', 'error', "Impound Error", _U('impound_canceled_moved'), 5000) 
                            end
                        end
                    end)
                elseif action == 'car_billing' then
                    local plate = GetVehicleNumberPlateText(currentVehicle)
                    lib.inputDialog(plate.." :רישום דוח לרכב", {
                        { type = 'input', label = "סיבה לדוח", required = true, name = "reason" },
                        { type = 'number', label = "כמה כסף", required = true, name = "amount" }
                    }, function(inputs)
                        if inputs and inputs.reason and inputs.amount then
                            local reason, amount = inputs.reason, tonumber(inputs.amount)
                            if amount == nil then 
                                TriggerEvent('br_notify:show', "error", "Billing Error", "כמות שגויה", 5000)
                            elseif amount > 60000 then 
                                TriggerEvent('br_notify:show', "error", "Billing Error", 'הסכום המקסימלי הוא 60,000 שקל בלבד', 5000)
                            else
                                if not IsAnyVehicleNearPoint(GetEntityCoords(Cache.ped), 3.0) then 
                                    TriggerEvent('br_notify:show', 'error', "Billing Error", _U('no_vehicles_nearby'), 5000)
                                else
                                    exports.ox_lib:progressBar({
                                        duration = 12000, 
                                        label = "כותב את הדוח", 
                                        useWhileDead = false, 
                                        canCancel = true,
                                        disable = { movement = true, carMovement = true, mouse = false, combat = true },
                                        anim = { dict = "CODE_HUMAN_MEDIC_TIME_OF_DEATH", clip = "CODE_HUMAN_MEDIC_TIME_OF_DEATH" }
                                    }, function(finished)
                                        ClearPedTasksImmediately(Cache.ped)
                                        if finished then
                                            TriggerServerEvent('okokBilling:createBillForPlate', plate, "Police Department", reason, amount)
                                            TriggerEvent('br_notify:show', "success", "Billing", "דוח נשלח", 5000)
                                        end
                                    end)
                                end
                            end
                        end
                    end)
                end
            else 
                TriggerEvent('br_notify:show', 'error', "Vehicle Error", _U('no_vehicles_nearby'), 5000) 
            end
        end,
        onClose = function() 
            HasAlreadyEnteredMarker = false 
        end
    })
    lib.showContext('police_vehicle_interaction_menu')
end

function OpenObjectSpawnerMenu()
    if not ESX.PlayerData.job then return end
    local elements = { {title = _U('traffic_interaction'), description = "Object Spawning", disabled = true} }
    for k,v in pairs(Config.PoliceObjects) do
        if(not v.boss or (ESX.PlayerData.job and ESX.PlayerData.job.grade_name == 'boss')) then
            table.insert(elements, {title = v.label, value = v.model, icon = 'fas fa-cube'}) -- Added generic icon
        end
    end
    table.insert(elements, {title = "ניקיון ספריי", value = "cleanspray", icon = 'fas fa-spray-can'})
    local emoji = blocklobjects and '<span style="color:red;">מבוטל</span>' or '<span style="color:green;">פועל</span>'
    table.insert(elements, {title = "מצב מחיקת אובייקטים - "..emoji, value = "togglebool", description = "E מדליק/מבטל את האופציה למחוק ב ", icon = 'fas fa-toggle-on'})

    lib.registerContext({
        id = 'police_object_spawner_menu',
        title = _U('traffic_interaction'),
        options = elements,
        onSelect = function(data)
            local model = data.value
            if(model) then
                if(model == "cleanspray") then TriggerEvent('rcore_spray:removeClosestSpray'); return end
                if(model == "togglebool") then
                    blocklobjects = not blocklobjects
                    local status = blocklobjects and "חסמת" or "הדלקת"
                    TriggerEvent('br_notify:show','success',"Object Deletion", status .. " את המחיקת אובייקטים", 5000)
                    return
                end
                if(Cache.vehicle) then return TriggerEvent('br_notify:show',"error","Spawn Error","!אתה לא יכול לבצע את הפעולה הזאת מתוך רכב", 5000) end

                local playerPed = Cache.ped
                local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
                local objectCoords = (coords + forward * 1.0); local x,y,z = table.unpack(objectCoords); z=z-1.0
                objectCoords = vector4(x,y,z,GetEntityHeading(playerPed))

                local NetID, reason = await lib.callback.await("esx_policejob:server:SpawnObject",500,model,objectCoords)
                if(NetID == nil) then TriggerEvent('br_notify:show',"error","Spawn Error","נא להמתין חצי שנייה בין כל שיגור", 5000); return end
                if(not NetID) then if(reason) then TriggerEvent('br_notify:show',"error","Spawn Error",reason, 5000) end; return end

                local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
                RequestAnimDict(dict); while not HasAnimDictLoaded(dict) do Wait(0) end
                TaskPlayAnim(Cache.ped, dict, anim, 8.0, 1.0, 1000, 51, 0.0, false, false, false); RemoveAnimDict(dict)
                if(model == "p_ld_stinger_s") then PlaySoundFrontend(-1, "bomb_deployed", "DLC_SM_Bomb_Bay_Bombs_Sounds", true) end
            end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
    })
    lib.showContext('police_object_spawner_menu')
end

function OpenChasesMenu()
    local elements = {
        {title = "תפריט מרדפים", description="Chase Actions", disabled = true},
        {title = "התחל טיימר", value = 'timer', description ="מתחיל לספור 60 שניות אחורה", icon = 'fas fa-stopwatch'},
        {title = "עצור טיימר", value = 'stoptimer', description ="עוצר טיימר במידה והוא פועל", icon = 'fas fa-stop-circle'}
    }
    lib.registerContext({
        id = 'police_chases_menu',
        title = "תפריט מרדפים",
        options = elements,
        onSelect = function(data)
            if data.value == 'timer' then
                if not chasetimer then chasetimer = true; TriggerEvent('br_notify:show',"info","Timer","הטיימר התחיל", 5000); SendNUIMessage({ type = 'startTimer' })
                else TriggerEvent('br_notify:show',"error","Timer Error","כבר הפעלת טיימר", 5000) end
            elseif data.value == "stoptimer" then
                if chasetimer then SendNUIMessage({ type = 'stopTimer' }); chasetimer = false
                else TriggerEvent('br_notify:show',"error","Timer Error","אין טיימר פועל", 5000) end
            end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
    })
    lib.showContext('police_chases_menu')
end

function BikeInteraction2(vehicle) -- Renamed from BikeInteraction to avoid conflict if original is used elsewhere by mistake
    if not ESX.PlayerData.job then return end
	local elements = { {title = "אינטרקציה אופנועים", description = "Motorcycle Actions", disabled = true} }
	if DoesEntityExist(vehicle) then
		table.insert(elements, {title = _U('vehicle_info'), value = 'vehicle_infos', icon = 'fas fa-info-circle'})
		table.insert(elements, {title = _U('pick_lock'), value = 'hijack_vehicle', icon = 'fas fa-key'})
		table.insert(elements, {title = _U('impound'), value = 'impound', icon = 'fas fa-truck-loading'})
		table.insert(elements, {title = "הצמדת דוח לרכב", value = 'car_billing', icon = 'fas fa-sticky-note'})

		if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
			if(GetVehicleClass(vehicle) == 18) then
				table.insert(elements, {title = '<strong><span style="color:cyan;">בדיקת ניידת</strong>', value = "scanveh", icon = 'fas fa-search-location'})
			end
		end
	end
	if(#elements <= 1) then return end -- Only title was added

    lib.registerContext({
        id = 'police_bike_interaction_menu',
        title = "אינטרקציה אופנועים",
        options = elements,
        onSelect = function(data)
            local playerPed = Cache.ped
            local coords = GetEntityCoords(playerPed)
            -- vehicle is passed as parameter to BikeInteraction2, so we use that instead of GetClosestVehicle
            local targetVehicle = vehicle
            local action = data.value

            if DoesEntityExist(targetVehicle) then
                local model = GetEntityModel(targetVehicle)
                if(GetVehicleClass(targetVehicle) == 8 or GetVehicleClass(targetVehicle) == 13 or IsThisModelABike(model)) then -- Vehicle class 8 is motorcycles
                    if action == 'vehicle_infos' then OpenVehicleInfosMenu(targetVehicle)
                    elseif action == 'hijack_vehicle' then
                        if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then -- Check proximity again just in case
                            local finished = await exports.ox_lib:progressBar({
                                duration = 15000, label = "פורץ את הרכב", useWhileDead = false, canCancel = true,
                                disable = { movement = true, carMovement = true, mouse = false, combat = true },
                                anim = { dict = "WORLD_HUMAN_WELDING", clip = "WORLD_HUMAN_WELDING" }
                            })
                            ClearPedTasksImmediately(Cache.ped)
                            if finished then
                                if(DoesEntityExist(targetVehicle) and NetworkGetEntityIsNetworked(targetVehicle)) then
                                    if(not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police") then return end
                                    local success = await lib.callback.await("esx_policejob:server:requestlockpick", false, VehToNet(targetVehicle))
                                    if(success) then
                                        lib.requestNamedPtfxAsset("core"); SetPtfxAssetNextCall("core")
                                        local vehcoords = GetEntityCoords(targetVehicle)
                                        StartParticleFxLoopedAtCoord("ent_brk_metal_frag",vehcoords.x,vehcoords.y,vehcoords.z,0,0,0,2.0,0,0,0,0)
                                        RemoveNamedPtfxAsset("core"); SetVehicleDoorsLocked(targetVehicle,1)
                                        SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
                                        PlaySoundFromEntity(-1,"Drill_Pin_Break",targetVehicle,"DLC_HEIST_FLEECA_SOUNDSET",false,false)
                                        TriggerEvent('br_notify:show',"success","Success","!הרכב נפרץ בהצלחה", 5000)
                                    end
                                else TriggerEvent('br_notify:show',"error","Error",".תקלה, נסה שוב", 5000) end
                            end
                        end
                    elseif action == 'impound' then
                        if currentTask.busy then return end; currentTask.busy = true
                        local duration = 10000; local plate = GetVehicleNumberPlateText(targetVehicle)
                        if(not string.match(plate," ") or GetVehicleClass(targetVehicle) == 18) then duration = math.floor(duration / 2) end
                        DrawOutlineEntity(targetVehicle,true)
                        local finished = await exports.ox_lib:progressBar({
                            duration = duration, label = "מעקל את הרכב", useWhileDead = false, canCancel = true,
                            disable = { movement = true, carMovement = true, mouse = false, combat = true },
                            anim = { dict = "CODE_HUMAN_MEDIC_TEND_TO_DEAD", clip = "CODE_HUMAN_MEDIC_TEND_TO_DEAD" }
                        })
                        ClearPedTasksImmediately(playerPed); DrawOutlineEntity(targetVehicle,false); currentTask.busy = false
                        if finished then
                            local vcoords = GetEntityCoords(targetVehicle); local pcoords = GetEntityCoords(playerPed)
                            if(Vdist(pcoords,vcoords) < 6) then ImpoundVehicle(targetVehicle)
                            else TriggerEvent('br_notify:show', 'error', "Impound Error", _U('impound_canceled_moved'), 5000) end
                        end
                    elseif action == "scanveh" then
                        if(DoesEntityExist(targetVehicle)) then
                            if(GetVehicleClass(targetVehicle) == 18) then
                                if(not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000)) then
                                    lastscan = GetGameTimer(); ESX.SEvent('esx_policejob:ScanVeh',ESX.Math.Trim(GetVehicleNumberPlateText(targetVehicle)))
                                else TriggerEvent('br_notify:show',"error","Scan Error","נא להמתין 5 שניות בין כל סריקה", 5000) end
                            else TriggerEvent('br_notify:show',"error","Scan Error","הרכב שנבחר אינו משטרתי", 5000) end
                        end
                    elseif(action == 'car_billing') then
                        local plate = GetVehicleNumberPlateText(targetVehicle)
                        local inputs = await lib.inputDialog(plate.." :רישום דוח לרכב", {
                            { type = 'input', label = "סיבה לדוח", required = true, name = "reason"},
                            { type = 'number', label = "כמה כסף", required = true, name = "amount"}
                        })
                        if(inputs and inputs.reason and inputs.amount) then
                            local reason_bill, amount_bill = inputs.reason, tonumber(inputs.amount)
                            if amount_bill == nil then TriggerEvent('br_notify:show', "error", "Billing Error", "כמות שגויה", 5000)
                            elseif amount_bill > 60000 then TriggerEvent('br_notify:show', "error", "Billing Error", 'הסכום המקסימלי הוא 60,000 שקל בלבד', 5000)
                            else
                                if not IsAnyVehicleNearPoint(GetEntityCoords(Cache.ped), 5.0) then TriggerEvent('br_notify:show', 'error', "Billing Error", _U('no_vehicles_nearby'), 5000)
                                else
                                    local finished = await exports.ox_lib:progressBar({
                                        duration = 12000, label = "כותב את הדוח", useWhileDead = false, canCancel = true,
                                        disable = { movement = true, carMovement = true, mouse = false, combat = true},
                                        anim = { dict = "CODE_HUMAN_MEDIC_TIME_OF_DEATH", clip = "CODE_HUMAN_MEDIC_TIME_OF_DEATH" }
                                    })
                                    ClearPedTasksImmediately(Cache.ped)
                                    if finished then
                                        TriggerServerEvent('okokBilling:createBillForPlate', plate, "Police Department", reason_bill, amount_bill)
                                        TriggerEvent('br_notify:show', "success", "Billing", "דוח נשלח", 5000)
                                    end
                                end
                            end
                        end
                    end
                else TriggerEvent('br_notify:show', 'error', "Vehicle Error", 'הרכב הכי קרוב אליך אינו אופנוע', 5000) end
            else TriggerEvent('br_notify:show', 'error', "Vehicle Error", 'לא נמצא הרכב', 5000) end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
    })
    lib.showContext('police_bike_interaction_menu')
end

function OpenIdentityCardMenu(player)
	local target = GetPlayerServerId(player)
	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
        if not data then
            TriggerEvent('br_notify:show', 'error', "Error", "Could not retrieve player data.", 5000)
            return
        end
		local elements = {
            { title = _U('citizen_interaction'), description = "Player Information", disabled = true},
			{ title = data.id_number..' :מספר ת"ז', value = "copy", id_num = data.id_number, icon = 'fas fa-copy'},
			{ title = _U('name', data.name), value = "copy2", name_num = data.name, icon = 'fas fa-copy'},
		}
        if data.job and data.job.label and data.job.grade_label then
            table.insert(elements, {title = _U('job', ('%s - %s'):format(data.job.label, data.job.grade_label)), icon = 'fas fa-briefcase'})
        else
             table.insert(elements, {title = _U('job', 'Unemployed'), icon = 'fas fa-briefcase'})
        end

		local sexLabel = IsPedMale(GetPlayerPed(player)) and "Gender: זכר" or "Gender: נקבה"

		if Config.EnableESXIdentity then -- This config option might be from esx_identity
			table.insert(elements, {title = sexLabel, icon = (IsPedMale(GetPlayerPed(player)) and 'fas fa-mars' or 'fas fa-venus')})
			table.insert(elements, {title = _U('dob', data.dob), value = "copy3", date_num = data.dob, icon = 'fas fa-calendar-alt'})
			table.insert(elements, {title = _U('height', data.height), icon = 'fas fa-ruler-vertical'})
		end

		if(ESX.PlayerData.job and ESX.PlayerData.job.grade_name == 'boss') then
			table.insert(elements, {title = "Bank: "..ESX.Math.GroupDigits(data.bank), value = "seize_money", description = "ניתן ללחוץ כאן כדי להחרים כספים", icon = 'fas fa-university'})
		else
			table.insert(elements, {title = "Bank: "..ESX.Math.GroupDigits(data.bank), icon = 'fas fa-university'})
		end

		if data.drunk then
			table.insert(elements, {title = _U('bac', data.drunk), icon = 'fas fa-beer'})
		end

		if data.licenses then
			table.insert(elements, {title = _U('license_label'), description="Licenses", disabled = true, icon = 'fas fa-id-badge'})
			for i=1, #data.licenses, 1 do
				table.insert(elements, {title = data.licenses[i].label})
			end
		end

        lib.registerContext({
            id = 'police_identity_card_menu',
            title = _U('citizen_interaction'),
            options = elements,
            onSelect = function(data)
                if not selected or not selected.value then return end -- Ignore title or non-actionable items
                if(selected.value == "copy") then
                    lib.setClipboard(selected.id_num)
                    TriggerEvent('br_notify:show','success',"Clipboard",'מספר תעודת זהות הועתק למקלדת', 5000)
                elseif(selected.value == "copy2") then
                    lib.setClipboard(selected.name_num)
                    TriggerEvent('br_notify:show','success',"Clipboard",'שם מלא הועתק למקלדת', 5000)
                elseif(selected.value == "copy3") then
                    lib.setClipboard(selected.date_num)
                    TriggerEvent('br_notify:show','success',"Clipboard",'תאריך לידה הועתק למקלדת', 5000)
                elseif(selected.value == "seize_money") then
                    if(ESX.PlayerData.job and ESX.PlayerData.job.grade_name == 'boss') then
                        local inputs = await lib.inputDialog("תפריט החרמת כספים", {
                            { type = 'input', label = "סיבה להחרמת כסף", required = true, name = "reason"},
                            { type = 'number', label = "כמות כסף", required = true, name = "amount"}
                        })
                        if(inputs and inputs.reason and inputs.amount) then
                            local reason_seize, amount_seize = inputs.reason, tonumber(inputs.amount)
                            if amount_seize == nil then TriggerEvent('br_notify:show',"error","Seize Error","כמות שגויה", 5000)
                            elseif amount_seize > 5000000 then TriggerEvent('br_notify:show',"error","Seize Error",'הסכום המקסימלי הוא 5,000,000', 5000)
                            else
                                if not reason_seize or reason_seize == '' then TriggerEvent('br_notify:show',"error","Seize Error","אתה חייב לציין סיבה להחרמה", 5000); return end
                                TriggerServerEvent("esx_policejob:server:seizemoney",target,amount_seize,reason_seize)
                            end
                        end
                    end
                end
            end,
            onClose = function() HasAlreadyEnteredMarker = false end -- Or whatever the desired close action is
        })
        lib.showContext('police_identity_card_menu')
	end, target)
end

function OpenBodySearchMenu(player)
	local TargetPed = GetPlayerPed(player)
	local targetid = GetPlayerServerId(player)

    -- Assuming IsPedStill is a custom function or needs replacement.
    -- For now, relying on IsPedDeadOrDying and player state (if available via ox_lib/core)
    if( (not IsPedOnFoot(TargetPed) and not IsPedInAnyVehicle(TargetPed, false)) and not IsPedDeadOrDying(TargetPed) /*and not lib.getPlayerState(targetid)?.isDowned*/) then
		TriggerEvent('br_notify:show',"error","Search Error","השחקן חייב לעמוד במקום או להיות ברכב", 5000)
        return
    end

	local text = "מבצע חיפוש"
	TriggerEvent("gi-3dme:network:mecmd",text)
	ESX.SEvent('esx_securityjob:messagesearch',targetid,GetPlayerServerId(PlayerId()))
	if(varbar) then
		exports.ox_inventory:openInventory('player', targetid)
	else
		TriggerEvent('br_notify:show', 'error', "Search Error", ".תקלה, נסה שוב", 5000)
	end
end

-- SendToCommunityService is now handled by the 'coms' command in server/main.lua
-- exports("SendToCommunityService",function(playerServerId)
-- 	ExecuteCommand("coms " .. playerServerId)
-- end)

function OpenFineMenu(player) -- player is serverId
    local fineCategories = {
        {title = _U('fine'), description = "Select Fine Category", disabled = true},
        {title = _U('traffic_offense'), value = 'traffic_offences', icon = 'fas fa-traffic-light'},
        {title = _U('minor_offense'),   value = 'minor_offences', icon = 'fas fa-user-clock'},
        {title = _U('average_offense'), value = 'average_offences', icon = 'fas fa-balance-scale-left'},
        {title = _U('major_offense'),   value = 'major_offences', icon = 'fas fa-gavel'}
    }
    lib.registerContext({
        id = 'police_fine_menu',
        title = _U('fine'),
        options = fineCategories,
        onSelect = function(data)
            if data.value then OpenFineCategoryMenu(player, data.value) end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
    })
    lib.showContext('police_fine_menu')
end

function OpenFineCategoryMenu(player, category) -- player is serverId
	ESX.TriggerServerCallback('esx_policejob:getFineList', function(fines)
		local elements = { {title = _U('fine') .. " - " .. category, description = "Select a fine", disabled = true} }
        if not fines or #fines == 0 then
            TriggerEvent('br_notify:show', 'inform', "Fines", "No fines found for this category.", 5000)
            return
        end

		for k,fine in ipairs(fines) do
			table.insert(elements, {
				title     = ('%s <span style="color:green;">%s</span>'):format(fine.label, _U('armory_item', ESX.Math.GroupDigits(fine.amount))),
				value     = fine.id,
                fineData  = fine,
                icon = 'fas fa-dollar-sign'
			})
		end

        lib.registerContext({
            id = 'police_fine_category_menu',
            title = _U('fine'),
            options = elements,
            onSelect = function(data)
                if data.fineData then
                    local closestPlayerId, closestDistance = ESX.Game.GetClosestPlayer() -- Re-check closest player for the fine
                    if closestPlayerId == -1 or closestDistance > 3.0 then
                        TriggerEvent('br_notify:show', 'error', "Error", _U('no_players_nearby'), 5000)
                    else
                        local targetFinePlayerServerId = GetPlayerServerId(closestPlayerId)
                        TriggerServerEvent('okokBilling:createBill', targetFinePlayerServerId, "Police Department", _U('fine_total', data.fineData.label), data.fineData.amount)
                        TriggerEvent('br_notify:show', 'success', "Billing", "Fine issued via okokBilling", 5000)
                        ESX.SetTimeout(300, function() OpenFineCategoryMenu(player, category) end) -- Refresh menu for current target
                    end
                end
            end,
            onClose = function() HasAlreadyEnteredMarker = false end
        })
        lib.showContext('police_fine_category_menu')
	end, category)
end

function LookupVehicle()
    lib.inputDialog(_U('search_database_title'), {
        { type = 'input', label = "לוחית רישוי", required = true, name = "plate" }
    }, function(plateInput)
        if plateInput and plateInput.plate then
            local plate = string.upper(ESX.Math.Trim(plateInput.plate)) -- סטנדרטיזציה של הלוחית
            local length = string.len(plate)

            if length < 2 or length > 8 then
                TriggerEvent('br_notify:show', 'error', "DB Search Error", _U('search_database_error_invalid'), 5000)
                return
            end

            ESX.TriggerServerCallback('esx_policejob:getVehicleFromPlate', function(owner, found)
                if found then
                    TriggerEvent('br_notify:show', 'success', "DB Search", _U('search_database_found', owner), 5000)
                else
                    TriggerEvent('br_notify:show', 'error', "DB Search Error", _U('search_database_error_not_found'), 5000)
                end
            end, plate)
        end
    end)
end


function LookupVehicleSeize()
    if not ESX.PlayerData.job or ESX.PlayerData.job.grade_name ~= 'boss' then return end

    lib.inputDialog("מספר תעודת זהות", {
        { type = 'input', label = "מספר תז", required = true, name = "idn" }
    }, function(IDN_input)
        if IDN_input and IDN_input.idn then
            local IDN = IDN_input.idn
            local length = string.len(IDN)

            if length < 2 or length > 13 then
                TriggerEvent('br_notify:show', "error", "Input Error", "מספר תעודת זהות שגוי", 5000)
            else
                SeizedVehicles(IDN)
            end
        end
    end)
end


function SeizedVehicles(id_number)
    if not ESX.PlayerData.job or ESX.PlayerData.job.grade_name ~= 'boss' then return end
	ESX.TriggerServerCallback('esx_policejob:getPlayerCars', function(seizedCars)
		if not seizedCars or #seizedCars == 0 then TriggerEvent('br_notify:show', "info", "Seized Vehicles", "אין רכבים מוחרמים כרגע", 5000); return end
        local elements = { {title = "רכבים מוחרמים", description="Manage seized vehicles", disabled=true} }
		for _,v in pairs(seizedCars) do
            if v.vehicle and v.vehicle.model then
                local hashVehicule = v.vehicle.model; local vehicleName  = GetDisplayNameFromVehicleModel(hashVehicule)
                local plate = v.plate; local emoji = v.impound and '<span style="color:red;">מעוקל</span>' or '<span style="color:green;">חופשי</span>'
                table.insert(elements, {title = ('| %s | %s | Impounded: %s'):format(plate, vehicleName, emoji), value = v, impounded = v.impound, icon = (v.impound and 'fas fa-lock' or 'fas fa-unlock')})
            end
		end
        if #elements == 1 then TriggerEvent('br_notify:show', "info", "Seized Vehicles", "No valid seized vehicles found to display.", 5000); return end
        lib.registerContext({
            id = 'police_seized_vehicles_menu', title = "רכבים מוחרמים", options = elements,
            onSelect = function(data)
                if(data.value) then
                    if(not data.impounded) then ESX.SEvent('esx_policejob:SeizeVehicle',data.value.plate)
                    else ESX.SEvent('esx_policejob:freeVehicle',data.value.plate) end
                    SeizedVehicles(id_number)
                end
            end,
            onClose = function() HasAlreadyEnteredMarker = false end
        })
        lib.showContext('police_seized_vehicles_menu')
	end,id_number)
end

function ShowPlayerLicense(player) -- player is serverId
	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(playerData)
        if not playerData then return end
		local elements = { {title = _U('license_revoke'), description="Revoke Licenses", disabled = true} }
		if playerData.licenses then
			for i=1, #playerData.licenses, 1 do
				if playerData.licenses[i].label and playerData.licenses[i].type then
					table.insert(elements, {title = playerData.licenses[i].label, type = playerData.licenses[i].type, icon = 'fas fa-drivers-license'})
				end
			end
		end
        if #elements == 1 then TriggerEvent('br_notify:show', 'inform', "Licenses", "Player has no licenses to revoke.", 5000); return end
        lib.registerContext({
            id = 'police_manage_license_menu', title = _U('license_revoke'), options = elements,
            onSelect = function(data)
                if data.type then
                    TriggerEvent('br_notify:show', 'info', "License Revoked", _U('licence_you_revoked', data.title, playerData.name), 5000)
                    ESX.SEvent('esx_policejob:message', player, _U('license_revoked', data.title)) -- Target server ID
                    ESX.SEvent('esx_license:removeLicense', player, data.type)
                    ESX.SetTimeout(300, function() ShowPlayerLicense(player) end)
                end
            end,
            onClose = function() HasAlreadyEnteredMarker = false end
        })
        lib.showContext('police_manage_license_menu')
	end, GetPlayerServerId(player)) -- Ensure player is server ID
end

function OpenUnpaidBillsMenu(player) -- player is serverId
	ESX.TriggerServerCallback("okokBilling:getTargetBills", function(invoices)
		if not invoices then TriggerEvent('br_notify:show', 'error', "Billing Error", "Could not fetch bills.", 5000); return end
		local totalPoliceDebt = 0; local policeBillsElements = {}; local otherBillsElements = {}

		for k,bill in ipairs(invoices) do
            local billLabel = ('%s - <span style="color:red;">%s</span>'):format(bill.label, _U('armory_item', ESX.Math.GroupDigits(bill.amount)))
			if(bill.author == "Police Department") then
				table.insert(policeBillsElements, {title = billLabel, billId = bill.id, icon = 'fas fa-receipt'})
				if(bill.amount > 0) then totalPoliceDebt = totalPoliceDebt + bill.amount end
			else
				table.insert(otherBillsElements, {title = billLabel, billId = bill.id, icon = 'fas fa-file-invoice'})
			end
		end
		local elements = { {title = 'תשלומים ודוחות - Police Debt: <span style="color:green;">₪'..ESX.Math.GroupDigits(totalPoliceDebt)..'</span>', description="Bills", disabled=true} }
		table.insert(elements,{title = '<span style="color:Aquamarine;"><---- קבלות משטרה -----></span>', disabled = true})
		for i = 1, #policeBillsElements, 1 do table.insert(elements,policeBillsElements[i]) end
		table.insert(elements,{title = '<span style="color:yellow;"><---- קבלות אזרחיות -----></span>', disabled = true})
		for i = 1, #otherBillsElements, 1 do table.insert(elements,otherBillsElements[i]) end

        if #elements <= 3 then -- Only titles were added
            TriggerEvent('br_notify:show', 'inform', "Bills", "No unpaid bills found for this player.", 5000)
            HasAlreadyEnteredMarker = false
            return
        end
        lib.registerContext({
            id = 'police_unpaid_bills_menu',
            title = 'תשלומים ודוחות', options = elements,
            onClose = function() HasAlreadyEnteredMarker = false end
        })
        lib.showContext('police_unpaid_bills_menu')
	end,player)
end

function OpenVehicleInfosMenu(veh)
	ESX.TriggerServerCallback('esx_policejob::server:VehicleDetailsPlate', function(retrivedInfo)
        if not retrivedInfo then return end
		local elements = {{title = _U('vehicle_info'), description="Vehicle Details", disabled = true}, {title = _U('plate', retrivedInfo.plate), icon = 'fas fa-digital-tachograph'}}
		if retrivedInfo.owner == nil then table.insert(elements, {title = _U('owner_unknown'), icon = 'fas fa-question-circle'})
		else
			table.insert(elements, {title = _U('owner', retrivedInfo.owner), icon = 'fas fa-user-tag'})
			if retrivedInfo.steam then table.insert(elements, {title = retrivedInfo.steam.." :שם בסטיים לרפורטים", icon = 'fab fa-steam'}) end
			if retrivedInfo.is_inspection_valid ~= nil then -- Check if inspection info is available
                local inspectionText = retrivedInfo.is_inspection_valid and "<span style='color: lightgreen; font-weight: bold;'>הרכב עבר טסט לאחרונה והוא תקין</span>" or "<span style='color: red; font-weight: bold;'>הרכב לא עבר טסט ואינו תקין</span>"
				table.insert(elements, {title = inspectionText, icon = (retrivedInfo.is_inspection_valid and 'fas fa-check-circle' or 'fas fa-times-circle')})
			end
		end
        lib.registerContext({
            id = 'police_vehicle_infos_menu', title = _U('vehicle_info'), options = elements,
            onClose = function() HasAlreadyEnteredMarker = false end
        })
        lib.showContext('police_vehicle_infos_menu')
	end, ESX.Math.Trim(GetVehicleNumberPlateText(veh)))
end

AddEventHandler('esx_policejob:hasEnteredMarker', function(station, part, partNum)
	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	elseif part == 'Armory' then
		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	elseif part == 'Evidence' then
		CurrentAction     = 'menu_evidence'
		CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Store Evidence"
		CurrentActionData = {station = station}
	elseif part == 'Weaponry' then
		CurrentAction     = 'menu_weaponry'
		CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Open Weapons Stock"
		CurrentActionData = {station = station}
	elseif part == 'Kitchen' then
		CurrentAction     = 'menu_kitchen'
		CurrentActionMsg  = "Press ~INPUT_CONTEXT~ To Open The ~b~Fridge~w~"
		CurrentActionData = {station = station}
	elseif part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	elseif part == 'BossBills' then
		CurrentAction     = 'menu_boss_bills'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	end
end)

AddEventHandler('esx_policejob:hasExitedMarker', function(station, part, partNum)
	if lib.isContextOpen() then lib.hideContext(false) end -- Close ox_lib context if open
	CurrentAction = nil
end)

AddEventHandler('esx_policejob:hasEnteredEntityZone', function(entity)
	local playerPed = Cache.ped
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and IsPedOnFoot(playerPed) then
		CurrentAction     = 'remove_entity'
		CurrentActionMsg  = _U('remove_prop')
		CurrentActionData = {entity = entity}
	end
	if GetEntityModel(entity) == joaat('p_ld_stinger_s') then
		if IsPedInAnyVehicle(playerPed, false) then
			-- Spikestrip logic is handled by dedicated threads later
		end
	end
end)

AddEventHandler('esx_policejob:hasExitedEntityZone', function(entity)
	if CurrentAction == 'remove_entity' then CurrentAction = nil; if lib.isTextUIOpen() then lib.hideTextUI() end end
end)

RegisterNetEvent('esx_policejob:client:handcuff')
AddEventHandler('esx_policejob:client:handcuff', function()
	isHandcuffed = not isHandcuffed
	local playerPed = Cache.ped

	if isHandcuffed then
        if not IsEntityDeadOrDying(playerPed) then
			RequestAnimDict('mp_arresting')
			while not HasAnimDictLoaded('mp_arresting') do Citizen.Wait(0) end
			TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
			RemoveAnimDict('mp_arresting')
		end
		HandCuffedThread()
		SetEnableHandcuffs(playerPed, true)
        AnkleCuffed = true
        Entity(playerPed).state:set("isAnkleCuffed", true, true) -- Using state bag for ankle cuff state

		SetPedDiesInstantlyInWater(playerPed,false)
        SetPedDiesInWater(playerPed,false)
		CreateThread(function()
			Wait(1000)
            -- No direct LocalPlayer.state.invOpen equivalent, assume ox_inventory handles this
			exports["lb-phone"]:ToggleDisabled(true)
			exports["lb-phone"]:ToggleOpen(false, false)
			ESX.SEvent("esx_policejob:server:ForceEndCall")
			SetFollowPedCamViewMode(0)
			TriggerEvent('canUseInventoryAndHotbar:toggle', false)
		end)
		TriggerEvent('gi_carmenu:KillUI')
		TriggerEvent('gi-emotes:ForceClose')
		AddCuffProp()
		ExecuteCommand('closephone')
		TriggerEvent('ox_inventory:disarm', true)
		SetCurrentPedWeapon(playerPed, joaat('WEAPON_UNARMED'), true)
		SetPedCanPlayGestureAnims(playerPed, false)

		if Config.EnableHandcuffTimer then
			if handcuffTimer.active then ESX.ClearTimeout(handcuffTimer.task) end
			StartHandcuffTimer()
		end
	else
		if Config.EnableHandcuffTimer and handcuffTimer.active then ESX.ClearTimeout(handcuffTimer.task) end
		exports["lb-phone"]:ToggleDisabled(false)
		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
        AnkleCuffed = false
        Entity(playerPed).state:set("isAnkleCuffed", false, true)

		SetPedDiesInstantlyInWater(playerPed,false)
        SetPedDiesInWater(playerPed,true)
		TriggerEvent('canUseInventoryAndHotbar:toggle', true)
		RemoveCuffProp()
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		if(dragStatus.isDragged == true) then
			dragStatus.isDragged = false
			DetachEntity(playerPed, true, false)
		end
		Citizen.Wait(500)
		ClearPedSecondaryTask(playerPed)
	end
end)

RegisterNetEvent('esx_policejob:unrestrain')
AddEventHandler('esx_policejob:unrestrain', function()
	if isHandcuffed then
		local playerPed = Cache.ped
		isHandcuffed = false
		exports["lb-phone"]:ToggleDisabled(false)
		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
        AnkleCuffed = false
        Entity(playerPed).state:set("isAnkleCuffed", false, true)
		SetPedDiesInstantlyInWater(playerPed,false)
        SetPedDiesInWater(playerPed,true)
		TriggerEvent('canUseInventoryAndHotbar:toggle', true)
		RemoveCuffProp()
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)
		ESX.SEvent('esx_policejob:RegisterRelease')
		if Config.EnableHandcuffTimer and handcuffTimer.active then ESX.ClearTimeout(handcuffTimer.task) end
		if(dragStatus.isDragged == true) then
			dragStatus.isDragged = false
			DetachEntity(playerPed, true, false)
		end
		Citizen.Wait(500)
		ClearPedSecondaryTask(playerPed)
	end
end)

RegisterNetEvent("esx_policejob:escortanim",function(targServerId)
	local ped = Cache.ped
	local targetPlayer = GetPlayerFromServerId(targServerId)
	if targetPlayer ~= -1 and targetPlayer ~= 0 then -- Ensure target player exists
		local targetPed = GetPlayerPed(targetPlayer)
		if not DoesEntityExist(targetPed) then return end

		RequestAnimDict('anim@cop_pose_escorting')
		while not HasAnimDictLoaded('anim@cop_pose_escorting') do Citizen.Wait(100) end
		TaskPlayAnim(ped, 'anim@cop_pose_escorting', 'escorting_rifle', 8.0, -8, -1, 49, 0.0, false, false, false)
		-- RemoveAnimDict('anim@cop_pose_escorting') -- Should be removed when anim stops or loop breaks

		exports.ox_lib:showTextUI("לשחרר את הגרירה [G] לחץ")
		Wait(200)
		local dragging = true
		while dragging do
			Wait(0)
			ped = Cache.ped -- Re-cache ped in loop

			if not IsEntityPlayingAnim(ped, 'anim@cop_pose_escorting', 'escorting_rifle',3) then
				RequestAnimDict('anim@cop_pose_escorting')
				while not HasAnimDictLoaded('anim@cop_pose_escorting') do Citizen.Wait(100) end
				TaskPlayAnim(ped, 'anim@cop_pose_escorting', 'escorting_rifle', 8.0, -8, -1, 49, 0.0, false, false, false)
			end

			DisableControlAction(0, 24, true); DisableControlAction(0, 25, true); DisableControlAction(0, 37, true)
			DisableControlAction(0, 47, true); DisableControlAction(0, 140, true); DisableControlAction(0, 141, true)
			DisableControlAction(0, 142, true); DisableControlAction(0, 143, true); DisableControlAction(0, 257, true)
			DisableControlAction(0, 263, true); DisableControlAction(0, 264, true); DisableControlAction(0, 303, true)

			if IsControlJustReleased(0, 58) then -- INPUT_VEH_ATTACK (G)
				TriggerEvent('br_notify:show',"success","Drag","משחרר גרירה", 5000)
				ESX.SEvent("esx_policejob:server:stopdrag",targServerId)
				dragging = false
			end

			if not DoesEntityExist(targetPed) or IsEntityDeadOrDying(targetPed) or not IsPedCuffed(targetPed) or GetEntityAttachedTo(targetPed) ~= ped then
				dragging = false -- Stop dragging if target is gone, dead, uncuffed, or no longer attached
			end
		end
		exports.ox_lib:hideTextUI()
		Wait(500)
		StopAnimTask(Cache.ped, "anim@cop_pose_escorting","escorting_rifle", -4.0)
        RemoveAnimDict('anim@cop_pose_escorting')
	end
end)

RegisterNetEvent('esx_policejob:drag')
AddEventHandler('esx_policejob:drag', function(copId)
	if not isHandcuffed then return end
	dragStatus.isDragged = not dragStatus.isDragged
	if(not dragStatus.isDragged) then DetachEntity(Cache.ped, true, false) end
	dragStatus.CopId = copId
end)

RegisterNetEvent("esx_policejob:DisableDrag",function()
	if(dragStatus.isDragged == true) then
		dragStatus.isDragged = false
		DetachEntity(Cache.ped, true, false)
	end
end)

RegisterNetEvent('esx_policejob:putInVehicle')
AddEventHandler('esx_policejob:putInVehicle', function()
	if not isHandcuffed then return end
	local targetVehicle, distance = ESX.Game.GetClosestVehicle()
	if DoesEntityExist(targetVehicle) and distance < 5 then
		local playerPed = Cache.ped
		local maxSeats = GetVehicleMaxNumberOfPassengers(targetVehicle)
        local freeSeat = nil
		for i=maxSeats - 1, 0, -1 do
			if IsVehicleSeatFree(targetVehicle, i) and i ~= -1 then -- Ensure not driver seat
				freeSeat = i; break
			end
		end
		if freeSeat then
			SetPedIntoVehicle(playerPed, targetVehicle, freeSeat)
			TriggerEvent('gi-speedo:forcebelt')
			if(dragStatus.isDragged == true) then dragStatus.isDragged = false; DetachEntity(playerPed, true, false) end
		else
            TriggerEvent('br_notify:show', 'error', "Vehicle Full", "No free seats in the vehicle.", 5000)
        end
	end
end)

RegisterNetEvent('esx_policejob:OutVehicle')
AddEventHandler('esx_policejob:OutVehicle', function()
	local playerPed = Cache.ped
	if not IsPedSittingInAnyVehicle(playerPed) then return end
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	TaskLeaveVehicle(playerPed, vehicle, 16)
	if(isHandcuffed) then
		Wait(500)
		RequestAnimDict('mp_arresting'); while not HasAnimDictLoaded('mp_arresting') do Wait(100) end
		TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
		RemoveAnimDict('mp_arresting')
	end
end)
