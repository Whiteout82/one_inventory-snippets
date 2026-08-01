local bridge = {}
local ESX = exports['es_extended']:getSharedObject()
local ITEMS = exports.one_inventory:GetAllItemDefinitions()

local localOnDuty = false

bridge.checkIsJobBoss = function()
    local PlayerData = ESX.GetPlayerData()
    if not PlayerData or not PlayerData.job then return false end
    return PlayerData.job.grade_name == 'boss'
end

bridge.getPlayerJob = function()
    local job = ESX.GetPlayerData().job
    if not job then return end
    
    if localOnDuty or job.onDuty then
        job.onduty = true
        job.onDuty = true
    end
    
    return job
end

bridge.getItemLabel = function(item)
    return ITEMS[item] and ITEMS[item].label or item
end

bridge.openManagement = function()
    local job = ESX.GetPlayerData().job
    if not job or job.grade_name ~= 'boss' then return end

    TriggerEvent('esx_society:openBossMenu', job.name)
end

bridge.hasManagementScript = function()
    return GetResourceState('esx_society') == 'started'
end

bridge.toggleDuty = function(onduty)
    localOnDuty = onduty
    TriggerServerEvent('mt_restaurants:server:toggleDuty', onduty)
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
