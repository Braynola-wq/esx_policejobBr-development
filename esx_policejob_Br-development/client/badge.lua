local plateModel = `prop_fib_badge` -- Using backticks for model hash for consistency
local animDict = "missfbi_s4mop"
local animName = "swipe_card"

RegisterCommand('pdbadge', function()
    StartBadgeAnim() -- Renamed function for clarity
end, false) -- false: allow everyone to use it, but logic inside checks job

function StartBadgeAnim()
    if not ESX.PlayerData.job then
        TriggerEvent('br_notify:show', 'error', "Error", "Job data not loaded.", 5000)
        return
    end

	local playerPed = Cache.ped -- Use cached ped
	local jobname = ESX.PlayerData.job.name

	if jobname ~= "offpolice" and jobname ~= 'police' and jobname ~= 'ambulance' and jobname ~= 'offambulance' and jobname ~= "lawyer" then
		TriggerEvent('br_notify:show', 'error', "Permission Denied", "רק שוטרים/מדא/עורכי דין יכולים להשתמש בפקודה הזאת", 5000)
		return
	end

    -- Replace LocalPlayer.state.down with a more robust check, e.g., from a status or health script.
    -- For now, only checking IsEntityDeadOrDying.
	if IsEntityDeadOrDying(playerPed) then
		TriggerEvent('br_notify:show', 'error', "Error", "אתה מת ולא יכול להציג תעודה", 5000)
		return
	end

    if IsPedCuffed(playerPed) then
        TriggerEvent('br_notify:show', 'error', "Error", "You cannot show your badge while cuffed.", 5000)
        return
    end

    RequestModel(plateModel)
    while not HasModelLoaded(plateModel) do
        Wait(0)
    end
	ClearPedSecondaryTask(playerPed)
	RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

	SetPedCurrentWeaponVisible(playerPed, false, true, true, true)
    local plyCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, -5.0) -- Spawn below ground then attach
    local platespawned = CreateObject(plateModel, plyCoords.x, plyCoords.y, plyCoords.z, true, true, false) -- networkSync = true, dynamic = false

    Wait(100) -- Allow object to spawn

    local meText = ""
    if jobname == "police" or jobname == "offpolice" then
        meText = "👮 מציג תעודת שוטר 👮"
    elseif jobname == "ambulance" or jobname == "offambulance" then
        meText = "👨‍⚕️ מציג תעודת פרמדיק 👨‍⚕️"
    elseif jobname == "lawyer" then
        meText = "👨‍🎓 מציג תעודת עורך דין 👨‍🎓"
    end

    if meText ~= "" then
        -- ExecuteCommand("me " .. meText) -- 'me' command might be QBCore specific or from another chat resource
        TriggerEvent("gi-3dme:network:mecmd", meText) -- Keep if gi-3dme is used
    end

	PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_CLOTHESSHOP_SOUNDSET", true)
    local netid = ObjToNet(platespawned)
    -- SetNetworkIdExistsOnAllMachines(netid, true) -- Not typically needed for client-created attached objects
    -- SetNetworkIdCanMigrate(netid, false) -- Usually true for client objects unless specific reason

    TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, 50, 0, false, false, false) -- Adjusted speed and flags

    Wait(800) -- Time for anim to reach badge display point

    local boneIndex = GetPedBoneIndex(playerPed, 28422) -- SKEL_R_Hand
    AttachEntityToEntity(platespawned, playerPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)

    Wait(3000) -- Display duration

    ClearPedSecondaryTask(playerPed)
	SetPedCurrentWeaponVisible(playerPed, true, true, true, true)

    if DoesEntityExist(platespawned) then -- Check if object still exists before detaching/deleting
        DetachEntity(platespawned, true, true)
        DeleteEntity(platespawned)
    end
    SetModelAsNoLongerNeeded(plateModel)
    RemoveAnimDict(animDict) -- Clean up anim dict
end

RegisterNetEvent("esx_policejob:CivIDAnim",function()
    CivIdAnim() -- Renamed function
end)

function CivIdAnim() -- Renamed for clarity
	local playerPed = Cache.ped

	if IsEntityDeadOrDying(playerPed) or IsPedInAnyVehicle(playerPed,false) or IsPedCuffed(playerPed) then
		return
	end

    RequestModel(plateModel)
    while not HasModelLoaded(plateModel) do
        Wait(0)
    end
	ClearPedSecondaryTask(playerPed)
	RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end

	SetPedCurrentWeaponVisible(playerPed, false, true, true, true)
    local plyCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, -5.0)
    local platespawned = CreateObject(plateModel, plyCoords.x, plyCoords.y, plyCoords.z, true, true, false)

    Wait(100)
    -- No network operations needed for a purely visual client-side effect if it's just for the local player.
    -- If other players need to see this specific animation and prop, server events would be better.

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 50, 0, false, false, false) -- Original speeds
    -- SetEntityAnimSpeed(playerPed, animDict, animName, 5.0) -- This might make it too fast with 8.0 play speed

    Wait(800)
    local boneIndex = GetPedBoneIndex(playerPed, 28422)
    AttachEntityToEntity(platespawned, playerPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)

    Wait(3000)

    ClearPedSecondaryTask(playerPed)
	SetPedCurrentWeaponVisible(playerPed, true, true, true, true)
    if DoesEntityExist(platespawned) then
        DetachEntity(platespawned, true, true)
        DeleteEntity(platespawned)
    end
    SetModelAsNoLongerNeeded(plateModel)
    RemoveAnimDict(animDict)
end
