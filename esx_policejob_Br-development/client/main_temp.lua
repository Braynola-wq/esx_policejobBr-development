ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

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
		elements[#elements+1] = {title = "ארון אחסון" , value = 'open_inventory', description = "!סטאש של המשטרה, לא לזרוק לפה זבל", icon = "fas fa-archive"}
		elements[#elements+1] = {title = "מחיקת ציוד משטרתי שעליך" , value = 'clear_inventory', description = "מוחק את כל הנשקים שעליך", icon = "fas fa-bomb"}
		elements[#elements+1] = {title = "מזבלת משטרה" , value = 'trash', description = "מחיקת דברים ספציפים שעליך", icon = "fas fa-trash-alt"}
		if(ESX.PlayerData.job.grade_name == "boss") then
			elements[#elements+1] = {title = "ניקוי ציוד סטאש" , value = 'stash_clearweapons', description = "מוחק את כל הנשקים + ציוד בסטאש", icon = "fas fa-skull-crossbones"}
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
        onSelect = async function(data)
            local action = data.value
            if(not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police") then return end

            if(action) then
                if(action == "open_inventory") then
                    exports.ox_inventory:openInventory('stash', 'Stash_Police')
                    HasAlreadyEnteredMarker = false
                elseif action == "clear_inventory" then
                    ESX.SEvent("esx_policejob:ClearINVWeapons")
                elseif action == "stash_clearweapons" then
                    if(ESX.PlayerData.job.grade_name == "boss") then
                        local confirm = await lib.alertDialog({
                            header = "האם אתה בטוח?",
                            content = "This will delete all weapons and equipment from the stash. This action cannot be undone.",
                            centered = true,
                            cancel = true,
                            labels = {
                                confirm = "מחק ציוד מהסטאש",
                                cancel = "לא"
                            }
                        })
                        HasAlreadyEnteredMarker = false
                        if(confirm == "confirm") then
                            ESX.SEvent("esx_policejob:ClearStashWeapons")
                        else
                            TriggerEvent('br_notify:show', "inform", "Police Armory","ביטלת את המחיקה", 5000)
                        end
                    else HasAlreadyEnteredMarker = false end
                elseif action == "trash" then OpenTrashMenu() end
            end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
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
		if(v.name ~= "cash" and v.name ~= "black_money") then
            table.insert(elements, {
                title = v.label.." - x"..v.count,
                value = {name = v.name, slot = v.slot, type = v.type, amount = v.count},
                description = "!!!!!!!לחיצה = מחיקה אין החזרים"
                -- icon = v.name -- ox_inventory might provide item icons, or use a default
            })
		end
	end

	if(#elements == 1) then
		TriggerEvent('br_notify:show', "error","Inventory Empty","האינוונטורי שלך ריק", 5000)
		OpenArmoryMenu()
		return
	end

    lib.registerContext({
        id = 'police_trash_menu',
        title = "ארון זבל",
        options = elements,
        onSelect = async function(data)
            local item = data.value
            if(item) then
                if(not ESX.PlayerData.job or ESX.PlayerData.job.name ~= "police") then return end
                if(item.type == "weapon") then
                    ESX.SEvent("esx_policejob:ClearSpecificItem",item,1)
                    Wait(200); OpenTrashMenu()
                else
                    local trashAmountInput = await lib.inputDialog("?כמה תרצה למחוק", {{ type = 'number', label = 'Amount', required = true, min = 1, default = 1, name = 'amount'}})
                    if trashAmountInput and trashAmountInput.amount then
                        local amountToTrash = tonumber(trashAmountInput.amount)
                        if(amountToTrash and amountToTrash > 0 and amountToTrash <= item.amount) then
                            ESX.SEvent("esx_policejob:ClearSpecificItem",item,amountToTrash)
                            Wait(200); OpenTrashMenu()
                        else
                            TriggerEvent('br_notify:show', "error","Error","אין לך את הכמות המבוקשת מהאייטם הזה או שהכמות שגויה", 5000)
                        end
                    end
                end
            end
        end,
        onClose = function() OpenArmoryMenu() end
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
		-- Assuming exports['esx_thief']:IsTCuffed() is a compatible external resource
		local playercuffed = exports['esx_thief'] and exports['esx_thief']:IsTCuffed() or false

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
		local playercuffed = exports['esx_thief'] and exports['esx_thief']:IsTCuffed() or false

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

local TowMissionActive = false -- Renamed from TowMission
local lastscan_tow -- For tow mission specific cooldowns if any, or can be removed if not needed

local function GetClosestTowSpot()
	local coords = GetEntityCoords(Cache.ped)
	local closestDist = -1
	local closestCoords = nil

	for k,v_spot in pairs(Config.TowSpot) do
		local dstcheck = #(coords - v_spot) -- Use Vdist if v_spot is vector3, otherwise ensure it is
		if closestDist == -1 or dstcheck < closestDist then
			closestDist = dstcheck
            closestCoords = v_spot
        end
    end
	return closestCoords
end

function OpenPoliceActionsMenu()
    if not ESX.PlayerData.job then return end
	local elements = {
        { title = 'תפריט משטרה', description = "Police Actions", disabled = true, icon = 'fas fa-cogs'},
		{ title = _U('citizen_interaction'),	value = 'citizen_interaction', description = "ניהול הקרציות", icon = 'fas fa-users-cog' },
		{ title = _U('vehicle_interaction'),	value = 'vehicle_interaction', description = ".עיקול רכבים, דוח על רכב וכו", icon = 'fas fa-car'},
		{ title = _U('object_spawner'),		value = 'object_spawner', description = "נועד לשגר אובייקטים", icon = 'fas fa-box-open'},
		{ title = "מרדפים",		value = 'chases', description = "פעולות שקשורות למרדפים", icon = 'fas fa-running'},
		{ title = "שליחה לכלא",               value = 'jail_menu', description = "לשלוח אדם לכלא ( להשתמש בזה רק בתוך מתחם הכלא )", icon = 'fas fa-user-lock'},
		{ title = "בקשת תגבורת",               value = 'backup_menu', description = "מסמן את מיקומך לשאר השוטרים", icon = 'fas fa-bullhorn'},
	}

	if(recentlyIN == true) then
		table.insert(elements, {title = '<span style="color:cyan;">לבוש כניסה לשרת</span>', value = 'clothes', description = "תפריט בגדים ( עובד רק 2 דקות מרגע הכניסה לשרת )", icon = 'fas fa-user-clock'})
	end

    local currentVehicle = GetVehiclePedIsIn(Cache.ped,false)
	if(not TowMissionActive and currentVehicle ~= 0 and Config.TowTrucks[GetEntityModel(currentVehicle)]) then
		table.insert(elements, {title = 'משימת גרירת רכב', value = 'tow_mission', icon = 'fas fa-truck-pickup'})
		table.insert(elements, {title = "שחרר את הרכב הנגרר", value = 'clear_tow', icon = 'fas fa-unlink'})
	end

    lib.registerContext({
        id = 'police_actions_menu',
        title = 'תפריט משטרה',
        options = elements,
        onSelect = async function(data)
            local value = data.value
            if value == "clothes" then OpenCloakroomMenu(true); recentlyIN = nil
            elseif value == 'jail_menu' then TriggerEvent("police:client:JailPlayer")
            elseif value == 'backup_menu' then
                if(not lastscan_callbackup or (GetTimeDifference(GetGameTimer(), lastscan_callbackup) > 30000)) then
                    lastscan_callbackup = GetGameTimer(); local text = "קורא לתגבורת"
                    TriggerEvent("gi-3dme:network:mecmd",text); RequestAnimDict("random@arrests")
                    while not HasAnimDictLoaded("random@arrests") do Wait(5) end
                    TaskPlayAnim(Cache.ped,"random@arrests","generic_radio_chatter",8.0,0.0,-1,49,0,0,0,0)
                    ESX.SEvent('InteractSound_SV:PlayWithinDistance',2.5,'backup',0.9)

                    local finished = await exports.ox_lib:progressBar({
                        duration = 1000, label = "קורא לתגבורת", useWhileDead = false, canCancel = true,
                        anim = { dict = "random@arrests", clip = "generic_radio_chatter" }
                    })
                    if finished then TriggerServerEvent('esx_policejob:server:RequestBackup') end
                    StopAnimTask(Cache.ped,"random@arrests","generic_radio_chatter",-4.0); RemoveAnimDict("random@arrests")
                else TriggerEvent('br_notify:show','error',"Backup",'יש להמתין חצי דקה בין כל בקשת תגבורת',5000) end
            elseif value == 'tow_mission' then
                local towtruck = GetVehiclePedIsIn(Cache.ped,false)
                if towtruck ~= 0 then
                    local model = GetEntityModel(towtruck)
                    if(Config.TowTrucks[model]) then
                        local towedcar = GetEntityAttachedToTowTruck(towtruck)
                        if(DoesEntityExist(towedcar)) then
                            if(GetVehicleClass(towedcar) ~= 18) then -- Not a police vehicle
                                if(not TowMissionActive) then
                                    TowMissionActive = true
                                    CreateThread(function()
                                        local towspot = GetClosestTowSpot()
                                        if not towspot then TriggerEvent('br_notify:show',"error","Tow Error","No tow spots configured or found.",5000); TowMissionActive = false; return end
                                        local blip = AddBlipForCoord(towspot.x, towspot.y, towspot.z) -- Assuming towspot is vector3
                                        SetBlipSprite(blip,68); SetBlipColour(blip,1); SetBlipScale(blip,1.0)
                                        BeginTextCommandSetBlipName('STRING'); AddTextComponentString("Tow Truck Mission"); EndTextCommandSetBlipName(blip)
                                        SetNewWaypoint(towspot.x,towspot.y)
                                        TriggerEvent('br_notify:show',"inform","Tow Mission","תוביל את הרכב לסימון במפה",7000)
                                        while TowMissionActive do
                                            local sleep = 1000; local ped = Cache.ped
                                            local currentTowtruckInner = GetVehiclePedIsIn(ped,false)
                                            if(DoesEntityExist(currentTowtruckInner)) then
                                                local currentModelInner = GetEntityModel(currentTowtruckInner)
                                                if(Config.TowTrucks[currentModelInner]) then
                                                    local currentTowedCarInner = GetEntityAttachedToTowTruck(currentTowtruckInner)
                                                    if(DoesEntityExist(currentTowedCarInner)) then
                                                        local coords_towed_inner = GetEntityCoords(currentTowedCarInner)
                                                        local dist_inner = #(coords_towed_inner - towspot)
                                                        if dist_inner < 50.0 then
                                                            sleep = 0
                                                            DrawMarker(9,towspot.x,towspot.y,towspot.z,0,0,0,0,90.0,90.0,2.8,2.8,3.8,255,255,255,255,false,0,2,true,"policemarker","policemarker",false)
                                                            if(dist_inner < 5.0) then
                                                                exports.ox_lib:showTextUI("[E] Pound Vehicle")
                                                                if(IsControlJustPressed(0,51)) then
                                                                    if(TowMissionActive) then
                                                                        TowMissionActive = false; exports.ox_lib:hideTextUI()
                                                                        Wait(30)
                                                                        if(varbar and ESX.PlayerData.job and ESX.PlayerData.job.name == "police") then
                                                                            local tries_tow = 0
                                                                            while not NetworkHasControlOfEntity(currentTowedCarInner) do
                                                                                Citizen.Wait(1); tries_tow = tries_tow + 1; NetworkRequestControlOfEntity(currentTowedCarInner)
                                                                                if(tries_tow > 1000) then TriggerEvent('br_notify:show',"error","Tow Error","המערכת נכשלה, נסה שוב",5000); TowMissionActive=false; return end
                                                                            end
                                                                            DetachVehicleFromAnyTowTruck(currentTowedCarInner)
                                                                            while IsVehicleAttachedToTowTruck(currentTowtruckInner,currentTowedCarInner) do Wait(50) end
                                                                            SetVehicleBrake(currentTowedCarInner,true); SetEntityVelocity(currentTowedCarInner,0.0,0.0,0.0)
                                                                            SetVehicleTowTruckArmPosition(currentTowtruckInner,1.0); Wait(500)
                                                                            ESX.SEvent("esx_policejob:poundvehicle",VehToNet(currentTowedCarInner),varbar)
                                                                        else TriggerEvent('br_notify:show',"error","Tow Error",".תקלה, נסה שוב",5000) end
                                                                    end
                                                                end
                                                            else exports.ox_lib:hideTextUI() end
                                                        else exports.ox_lib:hideTextUI() end
                                                    else TowMissionActive = false; exports.ox_lib:hideTextUI() end
                                                else TowMissionActive = false; exports.ox_lib:hideTextUI() end
                                            else TowMissionActive = false; exports.ox_lib:hideTextUI() end
                                            Wait(sleep)
                                        end
                                        if(DoesBlipExist(blip)) then RemoveBlip(blip) end
                                        exports.ox_lib:hideTextUI()
                                    end)
                                else TowMissionActive = false; TriggerEvent('br_notify:show',"info","Tow Mission",".עצרת את המשימת גרירה", 5000) end
                            else TriggerEvent('br_notify:show',"error","Tow Error",".אין אפשרות לבצע גרירה על רכב משטרתי",5000) end
                        else TriggerEvent('br_notify:show',"error","Tow Error",".לא נמצא רכב על הגרר",5000) end
                    end
                end
            elseif value == 'clear_tow' then
                local towtruck = GetVehiclePedIsIn(Cache.ped,false)
                if towtruck ~= 0 then
                    local model = GetEntityModel(towtruck)
                    if(Config.TowTrucks[model]) then
                        local towedcar = GetEntityAttachedToTowTruck(towtruck)
                        if(DoesEntityExist(towedcar)) then NetworkRequestControlOfEntity(towedcar); DetachVehicleFromAnyTowTruck(towedcar) end
                    end
                end
            elseif value == 'citizen_interaction' then OpenCitizenInteractionMenu()
            elseif value == 'vehicle_interaction' then OpenVehicleInteractionMenu()
            elseif value == 'object_spawner' then OpenObjectSpawnerMenu()
            elseif value == "chases" then OpenChasesMenu()
            end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
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
        { title = "עבודות שירות",	value = 'communityservice', description = "עבודות שירות ( עד 60 )", icon = 'fas fa-broom'},
        { title = _U('unpaid_bills'), value = 'unpaid_bills', description = "דוחות לא משולמים", icon = 'fas fa-file-invoice'},
    }

    if NearFingerScanner() then
        table.insert(elements,{title = "סריקת אצבע בכוח",value = 'finger_force', description = "כופה על שחקן לשים את האצבע על הסורק", icon = 'fas fa-fingerprint'})
    end

    if Config.EnableLicenses then
        table.insert(elements, { title = _U('license_check'), value = 'license', icon = 'fas fa-id-badge' })
    end
    table.insert(elements, {title = "דוח ניהולי", value = "custom_bill", icon = 'fas fa-file-signature'})

    if(ESX.PlayerData.job.grade_name == "boss") then
        table.insert(elements, {title = "בדיקת קנה", value = "barrel_check", description = "נועד לתפוס שוטרים שירו בתחנה, לא נועד לפשע כי יש אבקת שריפה היום.", icon = 'fas fa-fire-extinguisher'})
        table.insert(elements, {title = '<strong><span style="color:cyan;">בדיקת בתים</strong>', value = "house_check", icon = 'fas fa-house-user'})
    elseif(string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
        table.insert(elements, {title = "בדיקת קנה", value = "barrel_check", description = "נועד לתפוס שוטרים שירו בתחנה, לא נועד לפשע כי יש אבקת שריפה היום.", icon = 'fas fa-fire-extinguisher'})
    end

    lib.registerContext({
        id = 'police_citizen_interaction_menu',
        title = _U('citizen_interaction'),
        options = elements,
        onSelect = async function(data)
            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
            local actionValue = data.value

            if actionValue == 'house_check' then
                if(ESX.PlayerData.job.grade_name == "boss") then
                    local IDN_input = await lib.inputDialog("מספר תעודת זהות", {{type = 'input', label = "מספר תז", required = true, name = 'idn'}})
                    if IDN_input and IDN_input.idn then
                        local IDN = IDN_input.idn
                        local length = string.len(IDN)
                        if IDN == nil or length < 2 or length > 13 then TriggerEvent('br_notify:show', "error", "Input Error", "מספר תעודת זהות שגוי", 5000)
                        else OpenPropList(IDN) end
                    end
                end
                return
            end

            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                local targetServerId = GetPlayerServerId(closestPlayer)
                if actionValue == 'identity_card' then OpenIdentityCardMenu(closestPlayer)
                elseif actionValue == 'search' then OpenBodySearchMenu(closestPlayer)
                elseif actionValue == 'handcuff' then
                    if(handcuffing == true) then TriggerEvent('br_notify:show', 'error', "Cuffing", 'You Are Already Cuffing/Uncuffing', 5000); return end
                    local playerPed = Cache.ped; local playerheading = GetEntityHeading(playerPed); local playerlocation = GetEntityForwardVector(playerPed); local playerCoords = GetEntityCoords(playerPed)
                    ESX.SEvent('esx_policejob:requestarrest', targetServerId, playerheading, playerCoords, playerlocation)
                elseif actionValue == 'uncuff' then
                    if(handcuffing == true) then TriggerEvent('br_notify:show', 'error', "Cuffing", 'You Are Already Cuffing/Uncuffing', 5000); return end
                    local target,distance = ESX.Game.GetClosestPlayerCuffed()
                    if target ~= -1 and distance <= 3.0 then
                        local playerPed = Cache.ped; local playerheading = GetEntityHeading(playerPed); local playerlocation = GetEntityForwardVector(playerPed); local playerCoords = GetEntityCoords(playerPed)
                        ESX.SEvent('esx_policejob:requestrelease', GetPlayerServerId(target), playerheading, playerCoords, playerlocation)
                    else TriggerEvent('br_notify:show', "error", "Uncuff Error", "לא נמצא אף אחד אזוק בסביבתך", 5000) end
                elseif actionValue == 'drag' then
                    OnesyncEnableRemoteAttachmentSanitization(false); SetTimeout(200, function() OnesyncEnableRemoteAttachmentSanitization(true) end)
                    TriggerEvent("gi-3dme:network:mecmd","גורר"); ESX.SEvent('esx_policejob:drag', targetServerId)
                elseif actionValue == 'maskoff' then ESX.SEvent('esx_policejob:maskoff', targetServerId)
                elseif actionValue == 'put_in_vehicle' then
                    local target,distance = ESX.Game.GetClosestPlayerCuffed()
                    if target ~= -1 and distance <= 3.0 then TriggerEvent("gi-3dme:network:mecmd","מכניס לרכב"); ESX.SEvent('esx_policejob:putInVehicle', GetPlayerServerId(target))
                    else TriggerEvent('br_notify:show', "error", "Vehicle Error", "לא נמצא אף אחד אזוק בסביבתך", 5000) end
                elseif actionValue == 'out_the_vehicle' then
                    local target,distance = ESX.Game.GetClosestPlayerCuffed()
                    if target ~= -1 and distance <= 3.0 then TriggerEvent("gi-3dme:network:mecmd","מוציא מרכב"); ESX.SEvent('esx_policejob:OutVehicle', GetPlayerServerId(target))
                    else TriggerEvent('br_notify:show', "error", "Vehicle Error", "לא נמצא אף אחד אזוק בסביבתך", 5000) end
                elseif actionValue == 'fine' then OpenFineMenu(closestPlayer)
                elseif actionValue == 'license' then ShowPlayerLicense(closestPlayer)
                elseif actionValue == 'unpaid_bills' then OpenUnpaidBillsMenu(closestPlayer)
                elseif actionValue == 'communityservice' then ExecuteCommand("coms " .. targetServerId)
                elseif actionValue == 'barrel_check' then TriggerEvent('esx_policejob:CheckBarrel',targetServerId)
                elseif actionValue == 'custom_bill' then
                    local inputs = await lib.inputDialog("דוח ניהולי", {
                        { type = 'input', label = "סיבת דוח", required = true, name = "reason"},
                        { type = 'number', label = "כמות כסף", required = true, name = "amount"}
                    })
                    if inputs and inputs.reason and inputs.amount then
                        local reason, amount = inputs.reason, tonumber(inputs.amount)
                        if amount == nil then TriggerEvent('br_notify:show', "error", "Billing Error", "כמות שגויה", 5000)
                        elseif amount > 60000 then TriggerEvent('br_notify:show', "error", "Billing Error", 'הסכום המקסימלי הוא 60,000 שקל בלבד', 5000)
                        else
                            local targetPlayerForBill, targetDistanceForBill = ESX.Game.GetClosestPlayer()
                            if targetPlayerForBill == -1 or targetDistanceForBill > 3.0 then TriggerEvent('br_notify:show', 'error', "Billing Error", _U('no_players_nearby'), 5000)
                            else
                                TriggerServerEvent('okokBilling:createBill', GetPlayerServerId(targetPlayerForBill), "Police Department", reason, amount)
                                TriggerEvent('br_notify:show', 'success', "Billing", "Bill sent to okokBilling", 5000)
                            end
                        end
                    else TriggerEvent('br_notify:show', 'error', "Billing Error", 'יש לציין את סכום הדוח וסיבת הדוח', 5000) end
                elseif actionValue == 'finger_force' then ForceFingerprint() end
            else TriggerEvent('br_notify:show','error', "Error", _U('no_players_nearby'), 5000) end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
    })
    lib.showContext('police_citizen_interaction_menu')
end

function OpenVehicleInteractionMenu()
    if not ESX.PlayerData.job then return end
    local elements  = { {title = _U('vehicle_interaction'), description = "Vehicle Actions", disabled = true} }
    local playerPed = Cache.ped
    local vehicle = ESX.Game.GetVehicleInDirection()

    if DoesEntityExist(vehicle) then
        table.insert(elements, {title = _U('vehicle_info'), value = 'vehicle_infos', icon = 'fas fa-info-circle'})
        table.insert(elements, {title = _U('pick_lock'), value = 'hijack_vehicle', icon = 'fas fa-key'})
        table.insert(elements, {title = _U('impound'), value = 'impound', icon = 'fas fa-truck-loading'})
        table.insert(elements, {title = "הצמדת דוח לרכב", value = 'car_billing', icon = 'fas fa-sticky-note'})
        if(ESX.PlayerData.job.grade > 0) then
            table.insert(elements, {title = "להוציא מהרכב בכוח", value = 'carjack_vehicle', icon = 'fas fa-user-minus'})
        end
        if(ESX.PlayerData.job.grade_name == 'boss' or string.match(ESX.PlayerData.job.grade_label,"מפקד") or string.match(ESX.PlayerData.job.grade_label,"קצין")) then
            if(GetVehicleClass(vehicle) == 18) then
                table.insert(elements, {title = '<strong><span style="color:cyan;">בדיקת ניידת</strong>', value = "scanveh", icon = 'fas fa-search-location'})
            end
        end
    else
        if(IsPedInAnyVehicle(playerPed,false)) then
            local veh = GetVehiclePedIsIn(playerPed,false)
            if(DoesEntityExist(veh)) then
                if(ESX.PlayerData.job.grade_name == 'boss') then
                    if(GetVehicleClass(veh) ~= 18 and GetVehicleClass(veh) ~= 15) then
                        local plate = GetVehicleNumberPlateText(veh)
                        if(string.match(plate," ")) then
                            table.insert(elements, {title = '<strong><span style="color:red;">החרמת רכב</strong></span>', value = 'seize_vehicle', description = "מחרים את הרכב שאתם נמצאים בו", icon = 'fas fa-gavel'})
                        end
                    end
                end
            end
        else
            table.insert(elements, {title = "חיפוש קל לאופנוע", value = 'search_bike' , description = "דרך קלה לעקל אופנועים וכו", icon = 'fas fa-motorcycle'})
        end
    end
    table.insert(elements, {title = _U('search_database'), value = 'search_database', icon = 'fas fa-database'})
    if(ESX.PlayerData.job.grade_name == 'boss') then
        table.insert(elements, {title = '<strong><span style="color:red;">חיפוש בעלות רכבים</strong></span>', value = 'seize_list', icon = 'fas fa-file-invoice'})
    end
    table.insert(elements, {title = "הזמנת ניידת", value = 'call_nayedet', description = "מזמין ניידת בתשלום למיקומכם", icon = 'fas fa-car-on'})

    if #elements == 1 then -- Only title was added
        TriggerEvent('br_notify:show', 'inform', "Vehicle Actions", "No vehicle actions available.", 5000)
        HasAlreadyEnteredMarker = false
        return
    end

    lib.registerContext({
        id = 'police_vehicle_interaction_menu',
        title = _U('vehicle_interaction'),
        options = elements,
        onSelect = async function(data)
            local playerPed = Cache.ped
            local coords  = GetEntityCoords(playerPed)
            local currentVehicle = ESX.Game.GetVehicleInDirection()
            local action  = data.value

            if action == 'search_database' then LookupVehicle()
            elseif action == 'seize_list' then LookupVehicleSeize()
            elseif action == 'search_bike' then
                local targetVehicle = ESX.Game.GetClosestVehicle(coords, 4.0, 0, 71)
                if(DoesEntityExist(targetVehicle)) then
                    local model = GetEntityModel(targetVehicle)
                    if(GetVehicleClass(targetVehicle) == 8 or GetVehicleClass(targetVehicle) == 13 or IsThisModelABike(model)) then BikeInteraction2(targetVehicle)
                    else TriggerEvent('br_notify:show', 'error', "Vehicle Error", 'הרכב הכי קרוב אליך אינו אופנוע', 5000) end
                else TriggerEvent('br_notify:show', 'error', "Vehicle Error", 'לא נמצא שום רכב', 5000) end
            elseif action == 'seize_vehicle' then
                if(IsPedInAnyVehicle(playerPed,false)) then
                    local vehToSeize = GetVehiclePedIsIn(playerPed,false)
                    if(DoesEntityExist(vehToSeize)) then
                        if(ESX.PlayerData.job.grade_name == 'boss') then
                            if(GetVehicleClass(vehToSeize) ~= 18) then
                                local plate = GetVehicleNumberPlateText(vehToSeize)
                                if(string.match(plate," ")) then
                                    TaskLeaveVehicle(playerPed,vehToSeize,0)
                                    while IsPedInAnyVehicle(Cache.ped) do Citizen.Wait(500) end
                                    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)

                                    local finished = await exports.ox_lib:progressBar({
                                        duration = 7500, label = "מחרים רכב", useWhileDead = false, canCancel = true,
                                        disable = { car = true }, anim = { dict = "WORLD_HUMAN_CLIPBOARD", clip = "WORLD_HUMAN_CLIPBOARD" }
                                    })
                                    ClearPedTasksImmediately(Cache.ped)
                                    if finished then ESX.SEvent("esx_policejob:SeizeVehicle",plate); ImpoundVehicle(vehToSeize) end
                                else TriggerEvent('br_notify:show', 'error', "Seize Error", 'אין אפשרות להחרים רכב מסוג זה', 5000) end
                            end
                        end
                    end
                end
            elseif action == 'call_nayedet' then TriggerEvent('esx_policejob:callnayedet')
            elseif action == "scanveh" then
                if(DoesEntityExist(currentVehicle)) then
                    if(GetVehicleClass(currentVehicle) == 18) then
                        if(not lastscan or (GetTimeDifference(GetGameTimer(), lastscan) > 5000)) then
                            lastscan = GetGameTimer(); ESX.SEvent('esx_policejob:ScanVeh',ESX.Math.Trim(GetVehicleNumberPlateText(currentVehicle)))
                        else TriggerEvent('br_notify:show', "error", "Scan Error","נא להמתין 5 שניות בין כל סריקה", 5000) end
                    else TriggerEvent('br_notify:show', "error", "Scan Error","הרכב שנבחר אינו משטרתי", 5000) end
                end
            elseif DoesEntityExist(currentVehicle) then
                if action == 'vehicle_infos' then OpenVehicleInfosMenu(currentVehicle)
                elseif action == 'hijack_vehicle' then
                    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
                        local finished = await exports.ox_lib:progressBar({
                            duration = 15000, label = "פורץ את הרכב", useWhileDead = false, canCancel = true,
                            disable = { movement = true, carMovement = true, mouse = false, combat = true,},
                            anim = { dict = "WORLD_HUMAN_WELDING", clip = "WORLD_HUMAN_WELDING" }
                        })
                        ClearPedTasksImmediately(Cache.ped)
                        if finished then
                            if(DoesEntityExist(currentVehicle) and NetworkGetEntityIsNetworked(currentVehicle)) then
                                if(ESX.PlayerData.job.name ~= "police") then return end
                                local success = await lib.callback.await("esx_policejob:server:requestlockpick", false, VehToNet(currentVehicle))
                                if(success) then
                                    lib.requestNamedPtfxAsset("core"); SetPtfxAssetNextCall("core")
                                    local vehcoords = GetEntityCoords(currentVehicle)
                                    StartParticleFxLoopedAtCoord("ent_brk_metal_frag",vehcoords.x,vehcoords.y,vehcoords.z,0,0,0,2.0,0,0,0,0)
                                    RemoveNamedPtfxAsset("core"); SetVehicleDoorsLocked(currentVehicle,1)
                                    SetVehicleDoorsLockedForAllPlayers(currentVehicle, false)
                                    PlaySoundFromEntity(-1,"Drill_Pin_Break",currentVehicle,"DLC_HEIST_FLEECA_SOUNDSET",false,false)
                                    TriggerEvent('br_notify:show', "success","Success","!הרכב נפרץ בהצלחה", 5000)
                                end
                            else TriggerEvent('br_notify:show', "error","Error",".תקלה, נסה שוב", 5000) end
                        end
                    end
                elseif action == "carjack_vehicle" then
                     if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
                        if(GetPedInVehicleSeat(currentVehicle,-1) ~= 0) then
                            TriggerEvent('br_notify:show', 'info', "Carjack",'מתחיל הוצאה בכוח', 5000)
                            local success = await exports.ox_lib:skillCheck({ difficulté = 'easy', type = 'circle'}) -- Example
                            if success then TaskEnterVehicle(Cache.ped,currentVehicle,3000,-1,2.0,8,0)
                            else TriggerEvent('br_notify:show', 'error', "Carjack Failed", 'הוצאה נכשלה', 5000) end
                        else TriggerEvent('br_notify:show', 'info', "Carjack", 'לא נמצא אף אחד ברכב', 5000) end
                    end
                elseif action == 'impound' then
                    if currentTask.busy then return end; currentTask.busy = true -- Prevent re-trigger
                    local duration = 10000; local plate = GetVehicleNumberPlateText(currentVehicle)
                    if(not string.match(plate," ") or GetVehicleClass(currentVehicle) == 18) then duration = math.floor(duration / 2) end
                    DrawOutlineEntity(currentVehicle,true)
                    local finished = await exports.ox_lib:progressBar({
                        duration = duration, label = "מעקל את הרכב", useWhileDead = false, canCancel = true,
                        disable = { movement = true, carMovement = true, mouse = false, combat = true },
                        anim = { dict = "CODE_HUMAN_MEDIC_TEND_TO_DEAD", clip = "CODE_HUMAN_MEDIC_TEND_TO_DEAD" }
                    })
                    ClearPedTasksImmediately(playerPed); DrawOutlineEntity(currentVehicle,false); currentTask.busy = false
                    if finished then
                        local vcoords = GetEntityCoords(currentVehicle); local pcoords = GetEntityCoords(playerPed)
                        if(Vdist(pcoords,vcoords) < 6) then ImpoundVehicle(currentVehicle)
                        else TriggerEvent('br_notify:show', 'error', "Impound Error", _U('impound_canceled_moved'), 5000) end
                    end
                elseif(action == 'car_billing') then
                    local plate = GetVehicleNumberPlateText(currentVehicle)
                    local inputs = await lib.inputDialog(plate.." :רישום דוח לרכב", {
                        { type = 'input', label = "סיבה לדוח", required = true, name = "reason"},
                        { type = 'number', label = "כמה כסף", required = true, name = "amount"}
                    })
                    if(inputs and inputs.reason and inputs.amount) then
                        local reason, amount = inputs.reason, tonumber(inputs.amount)
                        if amount == nil then TriggerEvent('br_notify:show', "error", "Billing Error", "כמות שגויה", 5000)
                        elseif amount > 60000 then TriggerEvent('br_notify:show', "error", "Billing Error", 'הסכום המקסימלי הוא 60,000 שקל בלבד', 5000)
                        else
                            if not IsAnyVehicleNearPoint(GetEntityCoords(Cache.ped), 3.0) then TriggerEvent('br_notify:show', 'error', "Billing Error", _U('no_vehicles_nearby'), 5000)
                            else
                                local finished = await exports.ox_lib:progressBar({
                                    duration = 12000, label = "כותב את הדוח", useWhileDead = false, canCancel = true,
                                    disable = { movement = true, carMovement = true, mouse = false, combat = true},
                                    anim = { dict = "CODE_HUMAN_MEDIC_TIME_OF_DEATH", clip = "CODE_HUMAN_MEDIC_TIME_OF_DEATH" }
                                })
                                ClearPedTasksImmediately(Cache.ped)
                                if finished then
                                    TriggerServerEvent('okokBilling:createBillForPlate', plate, "Police Department", reason, amount)
                                    TriggerEvent('br_notify:show', "success", "Billing", "דוח נשלח", 5000)
                                end
                            end
                        end
                    end
                end
            else TriggerEvent('br_notify:show', 'error', "Vehicle Error", _U('no_vehicles_nearby'), 5000) end
        end,
        onClose = function() HasAlreadyEnteredMarker = false end
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
        onSelect = async function(data)
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
