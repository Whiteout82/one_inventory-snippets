local bridge = {}
local ITEMS = exports.one_inventory:GetAllItemDefinitions()

bridge.checkIsJobBoss = function()
    local PlayerData = QBX.PlayerData
    return PlayerData.job.isboss
end

bridge.getPlayerJob = function()
    return QBX.PlayerData.job
end

bridge.getItemLabel = function(item)
    return ITEMS[item] and ITEMS[item].label or item
end

bridge.openManagement = function()
    exports.qbx_management:OpenBossMenu("job")
end

bridge.hasManagementScript = function()
    return GetResourceState('qbx_management') == 'started'
end

bridge.toggleDuty = function(onduty)
    local job = QBX.PlayerData.job
    if not job then return end

    if not onduty and job.onduty then
        TriggerServerEvent("QBCore:ToggleDuty")
    elseif onduty and not job.onduty then
        TriggerServerEvent("QBCore:ToggleDuty")
    end
end

bridge.giveVehicleKey = function(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)

    if GetResourceState('qbx_vehiclekeys') == 'started' then
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
    elseif GetResourceState('Renewed-Vehiclekeys') == 'started' then
        exports['Renewed-Vehiclekeys']:addKey(plate) 
    end
end

bridge.removeVehicleKey = function(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)

    if GetResourceState('Renewed-Vehiclekeys') == 'started' then
        exports['Renewed-Vehiclekeys']:removeKey(plate)
    end
end

bridge.getItems = function()
    local list = {}
    local items = ITEMS
    if items then
        for k, v in pairs(items) do
            list[#list + 1] = {
                value = k,
                label = v.label or k
            }
        end
        table.sort(list, function(a, b) return a.label < b.label end)
    end
    return list
end

return bridge
