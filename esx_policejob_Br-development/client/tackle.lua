local isTackling				= false
local isGettingTackled			= false

local tackleLib					= 'missmic2ig_11'
local tackleAnim 				= 'mic_2_ig_11_intro_goon'
local tackleVictimAnim			= 'mic_2_ig_11_intro_p_one'

local lastTackleTime			= 0
local isRagdoll					= false

RegisterNetEvent('esx_policejob:resetTackle')
AddEventHandler('esx_policejob:resetTackle', function()
	if(isTackling) then
		isTackling = false
	end
end)

RegisterNetEvent('esx_policejob:getTackled')
AddEventHandler('esx_policejob:getTackled', function(target)
	isGettingTackled = true

	local playerPed = PlayerPedId()
	local targetPed = GetPlayerPed(GetPlayerFromServerId(target))

	RequestAnimDict(tackleLib)

	while not HasAnimDictLoaded(tackleLib) do
		Wait(10)
	end

	AttachEntityToEntity(PlayerPedId(), targetPed, 11816, 0.25, 0.5, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
	TaskPlayAnim(playerPed, tackleLib, tackleVictimAnim, 8.0, -8.0, 3000, 0, 0, false, false, false)
	RemoveAnimDict(tackleLib)
	Wait(3000)
	DetachEntity(PlayerPedId(), true, false)

	isRagdoll = true
	CreateThread(function()
		while isRagdoll do
			Wait(0)
			SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
		end
	end)
	Wait(3000)
	isRagdoll = false

	isGettingTackled = false
end)

RegisterNetEvent('esx_policejob:playTackle')
AddEventHandler('esx_policejob:playTackle', function()
	local playerPed = PlayerPedId()

	RequestAnimDict(tackleLib)

	while not HasAnimDictLoaded(tackleLib) do
		Wait(10)
	end

	TaskPlayAnim(playerPed, tackleLib, tackleAnim, 8.0, -8.0, 3000, 0, 0, false, false, false)
	RemoveAnimDict(tackleLib)
	Citizen.Wait(3000)

	isTackling = false

end)

-- Main thread
CreateThread(function()
	while true do
		local sleep = 1000
		if(ESX.PlayerData.job) then
			if(ESX.PlayerData.job.name == 'police' or ESX.PlayerData.job.name == "security") then
				sleep = 0
				if IsControlPressed(0, 21) and IsControlPressed(0, 74) and not isTackling and GetGameTimer() - lastTackleTime > 10 * 1000 then
					Wait(10)
					local closestPlayer, distance = ESX.Game.GetClosestPlayer()

					local playerPed = PlayerPedId()
					local targetPed = GetPlayerPed(closestPlayer)

					if distance ~= -1 and distance <= 3.0 and not isTackling and not isGettingTackled and not IsPedInAnyVehicle(playerPed) and not IsPedInAnyVehicle(targetPed) and not IsPedClimbing(playerPed) then
						local serverid = GetPlayerServerId(closestPlayer)
						if(serverid ~= -1) then
							if(not IsPedDeadOrDying(targetPed) and not Player(serverid).state.down) then
								isTackling = true
								lastTackleTime = GetGameTimer()
								OnesyncEnableRemoteAttachmentSanitization(false)
								SetTimeout(200, function()
									OnesyncEnableRemoteAttachmentSanitization(true)
								end)
								TriggerServerEvent('esx_policejob:tryTackle', serverid)
							end
						end
					end
				end
			end
		end
		Wait(sleep)
	end
end)