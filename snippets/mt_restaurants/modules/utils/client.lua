local utils = {}
local shared = require 'config.shared'

utils.debug = function(message, type)
    if not shared.debug then return end

    if GetResourceState('ox_lib') == 'started' then
        lib.print[type](message)
    else
        print(message)
    end
end

utils.loadModel = function(model)  
    if type(model) == "string" then model = joaat(model) end
    if not IsModelValid(model) then return end
    RequestModel(model)
    local timeout = 1000
    while not HasModelLoaded(model) and timeout > 0 do
        Wait(10)
        timeout = timeout - 1
    end
end

utils.notify = function(message, type, duration)
    lib.notify({ description = message, type = type or 'info', position = 'top', duration = duration or 5000 })
end
RegisterNetEvent('mt_restaurants:client:notify', utils.notify)

utils.createBlip = function(coords, sprite, display, scale, color, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, display)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, scale and (scale + 0.0) or 1.0)
    SetBlipColour(blip, color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

utils.getPolyZoneCenter = function(points)
    if type(points) == 'string' then
        points = json.decode(points)
    end
    local centerX, centerY = 0, 0
    local numPoints = #points

    for _, point in pairs(points) do
        centerX = centerX + point.x
        centerY = centerY + point.y
    end

    return vec3(centerX / numPoints, centerY / numPoints, points[1].z)
end

utils.sphereTarget = function(data)
    if data.options then
        for i = 1, #data.options do
            data.options[i].distance = 2.5
        end
    end
    return exports.ox_target:addSphereZone(data)
end

utils.entityTarget = function(entity, options)
    if options then
        for i = 1, #options do
            options[i].distance = 2.5
        end
    end
    return exports.ox_target:addLocalEntity(entity, options)
end

utils.removeZoneTarget = function(target)
    exports.ox_target:removeZone(target)
end

utils.openStash = function(inventory)
    TriggerServerEvent('mt_restaurants:server:openStash', inventory)
end

utils.getItemCount = function(item)
    return exports.one_inventory:GetItemCount(item)
end

utils.progressbar = function(label, duration, disable, anim, prop)
    return lib.progressBar({
        label = label,
        duration = duration,
        useWhileDead = false,
        canCancel = true,
        disable = disable,
        anim = anim,
        prop = prop
    })
end

utils.playTabletAnimation = function()
    lib.requestAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')
    lib.requestModel('prop_cs_tablet')

    local tablet = CreateObject('prop_cs_tablet', 0.0, 0.0, 0.0, true, true, true)
    AttachEntityToEntity(tablet, cache.ped, 28422, -0.05, 0.0, 0.0, 0.0, -90.0, 0.0, true, true, false, true, 1, true)
    TaskPlayAnim(cache.ped, 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a', 'idle_a', 8.0, -8.0, -1, 49, 0, false, false, false)

    return tablet
end

utils.stopTabletAnimation = function(tablet)
    ClearPedTasks(cache.ped)

    if DoesEntityExist(tablet) then
        DeleteEntity(tablet)
    end

    RemoveAnimDict('amb@code_human_in_bus_passenger_idles@female@tablet@idle_a')
    SetModelAsNoLongerNeeded('prop_cs_tablet')
end

utils.openInventory = function(invType, data)
    exports.one_inventory:OpenInventory(invType, data)
end

utils.playNotepadAnimation = function()
    local ped = cache.ped
    local dict = 'missheistdockssetup1clipboard@base'
    local anim = 'base'
    local notepadModel = 'prop_notepad_01'
    local pencilModel = 'prop_pencil_01'

    lib.requestAnimDict(dict)
    lib.requestModel(notepadModel)
    lib.requestModel(pencilModel)

    local notepad = CreateObject(notepadModel, 0.0, 0.0, 0.0, true, true, true)
    AttachEntityToEntity(notepad, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.02, 0.05, 10.0, 0.0, 0.0, true, true, false, true, 1, true)

    local pencil = CreateObject(pencilModel, 0.0, 0.0, 0.0, true, true, true)
    AttachEntityToEntity(pencil, ped, GetPedBoneIndex(ped, 58866), 0.11, -0.02, 0.001, -120.0, 0.0, 0.0, true, true, false, true, 1, true)

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

    return { notepad = notepad, pencil = pencil }
end

utils.stopNotepadAnimation = function(props)
    local ped = cache.ped or PlayerPedId()
    ClearPedTasks(ped)

    if props then
        if DoesEntityExist(props.notepad) then DeleteEntity(props.notepad) end
        if DoesEntityExist(props.pencil) then DeleteEntity(props.pencil) end
    end

    RemoveAnimDict('missheistdockssetup1clipboard@base')
    SetModelAsNoLongerNeeded('prop_notepad_01')
    SetModelAsNoLongerNeeded('prop_pencil_01')
end

utils.spawnProp = function(model, coords, heading, frozen)
    utils.loadModel(model)
    local prop = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    SetEntityHeading(prop, heading or 0.0)
    
    if frozen ~= false then
        FreezeEntityPosition(prop, true)
        SetEntityInvincible(prop, true)
        SetEntityCanBeDamaged(prop, false)
    end
    
    return prop
end

utils.spawnPed = function(coords, model, anim, network)
    utils.loadModel(model)
    local ped = CreatePed(4, GetHashKey(model), coords.x, coords.y, coords.z, coords.w, false, network ~= false)
    SetEntityHeading(ped, (tonumber(coords.w) or 0.0) + 0.0)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if anim.scenario then
        TaskStartScenarioInPlace(ped, anim.scenario, 0, true)
    elseif anim.dict and anim.clip then
        lib.requestAnimDict(anim.dict)
        TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, 0.0, -1, 1, 0.0, false, false, false)
    end
    return ped
end

utils.displayMetadata = function(data)
    exports.one_inventory:ShowItemMetadata(data)
end

utils.dropEvidence = function(evidence)
    if GetResourceState('kartik-evidence') == 'started' then
        exports['kartik-evidence']:DropEvidence(evidence)
    end
end 

return utils
