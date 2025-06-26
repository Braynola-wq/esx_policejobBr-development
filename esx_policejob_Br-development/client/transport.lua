local TransportPed
local Drivemode = 0
local TransportCar
local vehhash = "police"
local finaltarget = nil
local finalteleport = nil
Transported = false


local Locations = {
	["cs"] = {area = vector3(492.25, -1018.63, 28.06), teleport = vector4(479.42, -1026.02, 27.03, 17.57)}
}

RegisterCommand("transport",function(source, args)

	if(not args[1] or not tonumber(args[1])) then
		ESX.ShowNotification("Syntax: /transport [ID] [Location]")
		return
	end

	local target = tonumber(args[1])

	local location = args[2]
	local player = GetPlayerFromServerId(target)

	if(player == -1) then
		ESX.ShowNotification(".תקלה, לא נמצא העצור שרשמת")
		return
	end


	local targetPed = GetPlayerPed(player)
	if(not IsPedCuffed(targetPed)) then
		ESX.ShowNotification("השחקן שבחרת חייב להיות אזוק")
		return
	end

	local JobData = ESX.GetPlayerData().job

	if(JobData.name ~= "police") then
		ESX.ShowNotification("הפקודה הזאת נועדה למשטרה בלבד")
		return
	end

	if(JobData.grade <= 0) then
		ESX.ShowNotification("הפקודה הזאת נועדה לשוטרי סיור ומעלה")
		return
	end
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local targetcoords = GetEntityCoords(targetPed)

	if(Vdist(coords,targetcoords) > 10.0) then
		ESX.ShowNotification("המטרה רחוקה ממך יותר מדי")
		return
	end


	local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-30, 30), coords.y + math.random(-30, 30), coords.z, 0, 1, 0)
	if found then
		local text = "מזמין ניידת איסוף"
		TriggerEvent("gi-3dme:network:mecmd",text)
		RequestAnimDict("random@arrests");
		
		while not HasAnimDictLoaded("random@arrests") do
			Wait(5);
		end
		TaskPlayAnim(playerPed,"random@arrests","generic_radio_chatter", 8.0, 0.0, -1, 49, 0, 0, 0, 0);
		TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2.5, 'backup', 0.9)
		exports['progressBars']:startUI(1000, "מזמין ניידת")
		Wait(1000)
		StopAnimTask(playerPed, "random@arrests","generic_radio_chatter", -4.0)
		RemoveAnimDict("random@arrests")
		local carSpawn = vector4(spawnPos.x,spawnPos.y,spawnPos.z,spawnHeading)
		ESX.SEvent("esx:policejob:TransportID",target,location, carSpawn)
	else
		ESX.ShowNotification("לא הצלחנו למצוא את מקום לשגר את הניידת")
	end
end)


local function RelocateCar(vehicle)
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-20, 20), coords.y + math.random(-20, 20), coords.z, 0, 3, 0)
	if found then
		if(DoesEntityExist(vehicle)) then
			SetEntityCoords(vehicle,spawnPos)
			SetEntityHeading(vehicle,spawnHeading)
		end
	end
end

RegisterNetEvent("esx_policejob:Transport",function(target, carNet, pedNet)
	if(not target) then
		finaltarget = vector3(-655.12, -126.82, 37.73) -- תחנת משטרה א נ ג ורוום
		finalteleport = nil
	else

		local loc = Locations[target]
		if(loc) then
			finaltarget = loc.area
			finalteleport = loc.teleport
		else
			finalteleport = nil
		end
		-- finaltarget = target
	end
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	local vehicle = ESX.Game.VerifyEnt(carNet)
	
	if not DoesEntityExist(vehicle) then
		ESX.ShowRGBNotification("error",".תקלה, לא מצאנו את הניידת איסוף")
		return
	end
	local driver = ESX.Game.VerifyEnt(pedNet)
	if not DoesEntityExist(driver) then
		ESX.ShowRGBNotification("error","תקלה, לא מצאנו את הנהג של הניידת האיסוף לא בוצע")
		return
	end
	TriggerEvent("esx_policejob:RestartTimer")
	ESX.ShowHelpNotification("~b~Police~w~ Transport Vehicle Is On Its Way To ~r~Pick You Up~w~")

	TransportPed = driver
	Transported = true
	TransportCar = vehicle	
	local vehid = carNet
	SetNetworkIdCanMigrate(vehid,false)
	SetEntityAsMissionEntity(vehicle, true, false)
	SetVehicleHasBeenOwnedByPlayer(vehicle, true)
	SetVehicleNeedsToBeHotwired(vehicle, false)
	SetVehicleNumberPlateTextIndex(vehicle, 6)
	SetVehRadioStation(vehicle, 'OFF')

	local pedid = pedNet
	SetNetworkIdCanMigrate(pedid,false)
	SetBlockingOfNonTemporaryEvents(driver, true)
	SetEntityAsMissionEntity(driver, true, true)
	SetPedCanRagdollFromPlayerImpact(driver,false)
	SetDriverAbility(driver,1.0)
	SetPedArmour(driver,100)
	SetDriverAggressiveness(driver,1.0)
	SetVehicleDoorsLocked(vehicle, 2)
	SetVehicleSiren(vehicle,true)
	local plate = exports['okokVehicleShop']:GeneratePlate()
	SetVehicleNumberPlateText(vehicle,plate)
	ClearAreaOfVehicles(GetEntityCoords(vehicle), 5000, false, false, false, false, false);  
	SetVehicleOnGroundProperly(vehicle)
	Drivemode = 1
	TaskTransport(vehicle)

end)

function TaskTransport(vehicle)
	local left = false
	local lastcoords = GetEntityCoords(vehicle)
	local stuckcount = 0
	local walkto = false
	local pedcoords = GetEntityCoords(PlayerPedId())
	TaskVehicleDriveToCoord(TransportPed, vehicle, pedcoords.x, pedcoords.y, pedcoords.z, 10.0, 1, vehhash, 2883621, 0.1, 1)
	while Drivemode == 1 do
		Citizen.Wait(250)
		pedcoords = GetEntityCoords(PlayerPedId())
		local plycoords = GetEntityCoords(TransportPed)
		local dist = #(plycoords - pedcoords)

		local pedz = plycoords.z
		local playerz = pedcoords.z
		
		local heightdiff = math.abs(pedz - playerz)

		if(not DoesEntityExist(TransportPed) or not DoesEntityExist(TransportCar)) then
			Drivemode = 0
		end

		if(IsEntityDead(TransportPed)) then
			Drivemode = 0
		end

		if not NetworkHasControlOfEntity(TransportPed) then
			NetworkRequestControlOfEntity(TransportPed)
		end

		if not NetworkHasControlOfEntity(vehicle) then
			NetworkRequestControlOfEntity(vehicle)
		end

		if #(lastcoords - plycoords) < 2.0 then
			stuckcount = stuckcount + 1
			if(stuckcount >= 18) then
				stuckcount = 0
				RelocateCar(vehicle)
			end
		else
			stuckcount = 0
		end

		lastcoords = plycoords


		
		if dist <= 15.0 then
			if(not walkto) then
				if(heightdiff < 3.0) then
					walkto = true
					TaskGoToCoordAnyMeans(PlayerPedId(), plycoords.x, plycoords.y, plycoords.z, 1.0, 0, 0, 786603, 1.0)
				end
			end
			if(heightdiff < 5.0) then
				SetVehicleMaxSpeed(vehicle,5.5)
				TaskVehicleDriveToCoord(TransportPed, vehicle, pedcoords.x, pedcoords.y, pedcoords.z, 15.0, 1, vehhash, 787004, 0.1, 1)
				if dist <= 7.5 then
					ClearPedTasks(PlayerPedId())
					left = true
					TaskLeaveVehicle(TransportPed, vehicle, 14)
				else
					Citizen.Wait(250)
				end
			end
		else
			TaskVehicleDriveToCoord(TransportPed, vehicle, pedcoords.x, pedcoords.y, pedcoords.z, 50.0, 1, vehhash, 787004, 2.0, 1)
			Citizen.Wait(250)
		end

		
		while left do
			Citizen.Wait(250)
			local Xpedcoords = GetEntityCoords(PlayerPedId())
			local Ypedcoords = GetEntityCoords(TransportPed)
			local distPed = GetDistanceBetweenCoords(Xpedcoords, Ypedcoords, false)
			TaskGoToCoordAnyMeans(TransportPed, Xpedcoords.x, Xpedcoords.y, Xpedcoords.z, 2.0, 0, 0, 786603, 1.0)
			if distPed <= 2.3 then
				left = false
				Drivemode = 0
				DragToCar()
			end
		end
	end
end

function DragToCar()
	--TriggerEvent('esx_policejob:DisableDrag')
	--Wait(1000)
	if not NetworkHasControlOfEntity(TransportPed) then
		NetworkRequestControlOfEntity(TransportPed)
	end
	AttachEntityToEntity(PlayerPedId(), TransportPed, 11816, 0.80, 0.80, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

	local dragging = true

	Citizen.SetTimeout(10000,function()
		if(dragging) then
			dragging = false
			DetachEntity(PlayerPedId(), true, false)
			SetPedIntoVehicle(PlayerPedId(),TransportCar,1)
			TriggerEvent('gi-speedo:forcebelt')
			DriveToPoliceStation()
		end
	end)

	while dragging do
		Wait(500)

		local ped = PlayerPedId()
		if not NetworkHasControlOfEntity(TransportPed) then
			NetworkRequestControlOfEntity(TransportPed)
		end

		if(not DoesEntityExist(TransportPed) or not DoesEntityExist(TransportCar)) then
			DetachEntity(ped, true, false)
			dragging = false
		end

		if(IsEntityDead(TransportPed) or not IsPedCuffed(ped)) then
			DetachEntity(ped, true, false)
			dragging = false
		end


		if(GetEntityAttachedTo(ped) ~= TransportPed) then
			AttachEntityToEntity(ped, TransportPed, 11816, 0.80, 0.80, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
		end

		--AttachEntityToEntity(PlayerPedId(), TransportPed, 11816, 0.80, 0.80, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

		local carcoords = GetEntityCoords(TransportCar)
		local tcoords = GetEntityCoords(TransportPed)
		TaskGoToCoordAnyMeans(TransportPed, carcoords.x, carcoords.y, carcoords.z, 1.0, 0, 0, 786603, 1.0)

		if(Vdist(carcoords,tcoords) < 3.0) then
			dragging = false
			DetachEntity(ped, true, false)
			SetPedIntoVehicle(ped,TransportCar,1)
			TriggerEvent('gi-speedo:forcebelt')
			DriveToPoliceStation()
			return
		end
	end

	Transported = false
	TaskWanderStandard(TransportPed, 10.0, 10)

	TransportPed = 0
	ESX.Game.DeleteVehicle(TransportCar)
end

function DriveToPoliceStation()

	SetPedIntoVehicle(TransportPed,TransportCar,-1)
	SetVehicleMaxSpeed(TransportCar,0.0)
	Wait(500)
	local goingtopolice = true


	TaskVehicleDriveToCoordLongrange(TransportPed, TransportCar, finaltarget.x, finaltarget.y, finaltarget.z, 50.0, 787004, 5.0)
	TaskSetBlockingOfNonTemporaryEvents(TransportPed,true)
	local lastcoords = GetEntityCoords(TransportCar)
	local stuckcount = 0

	while goingtopolice do
		Wait(500)
		local pedcoords = GetEntityCoords(PlayerPedId())
		if #(lastcoords - pedcoords) < 2.0 then

			stuckcount = stuckcount + 1
			if(stuckcount >= 13) then
				stuckcount = 0
				RelocateCar(TransportCar)
			end
		else
			stuckcount = 0
		end

		lastcoords = pedcoords

		--TaskVehicleDriveToCoord(TransportPed, TransportCar, finaltarget.x, finaltarget.y, finaltarget.z, 30.0, 1, vehhash, 2883621, 5.0, 1)
		TaskVehicleDriveToCoordLongrange(TransportPed, TransportCar, finaltarget.x, finaltarget.y, finaltarget.z, 60.0, 787004, 5.0)

		if(not DoesEntityExist(TransportPed) or not DoesEntityExist(TransportCar)) then
			goingtopolice = false
			TriggerEvent("dispatch:TransportEscape")
		end

		if(IsEntityDead(TransportPed) or not IsPedCuffed(PlayerPedId())) then
			goingtopolice = false
			TriggerEvent("dispatch:TransportEscape")
		end

		if not NetworkHasControlOfEntity(TransportPed) then
			NetworkRequestControlOfEntity(TransportPed)
		end

		if not NetworkHasControlOfEntity(TransportCar) then
			NetworkRequestControlOfEntity(TransportCar)
		end
		
		
		local dist = #(finaltarget - pedcoords)
		if dist <= 35.0 then
			goingtopolice = false
			DoScreenFadeOut(800)
			BringVehicleToHalt(TransportCar, 2.5, 1, false)
			while not IsScreenFadedOut() do
				Wait(250)
			end
			if(not finalteleport) then
				SetEntityCoords(PlayerPedId(),-592.9, -126.31, 33.69)
				SetEntityHeading(PlayerPedId(), 38.21)
			else
				SetEntityCoords(PlayerPedId(),finalteleport.x,finalteleport.y,finalteleport.z)
				SetEntityHeading(PlayerPedId(), finalteleport.w)
			end
			DoScreenFadeIn(800)

			ESX.Game.DeleteVehicle(TransportPed)
			ESX.Game.DeleteVehicle(TransportCar)
			TransportCar = nil
			TransportPed = nil
			Transported = false
			Drivemode = 0
			TriggerEvent('InteractSound_CL:PlayOnOne', 'cell', 1.0)
			while not IsScreenFadedIn() do
				Wait(250)
			end
			ESX.ShowHelpNotification("You Have Been ~r~Dropped Off~w~ At The ~b~Police Station~w~")
			TriggerEvent("dispatch:TransportEnd")
			break
		end
	end

	Transported = false

end