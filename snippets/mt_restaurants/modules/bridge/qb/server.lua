local bridge = {}
local QBCore = exports['qb-core']:GetCoreObject()
local ITEMS = exports.one_inventory:GetAllItemDefinitions()

bridge.getAccountMoney = function(job)
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:GetAccountMoney(job) or 0
    end
    return exports['qb-banking']:GetAccountBalance(job)
end

bridge.removeAccountMoney = function(job, amount)
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:RemoveAccountMoney(job, amount, 'Restaurant Withdrawal')
    end
    return exports['qb-banking']:RemoveMoney(job, amount)
end

bridge.addAccountMoney = function(job, amount)
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:AddAccountMoney(job, amount, 'Restaurant Deposit')
    end
    return exports['qb-banking']:AddMoney(job, amount)
end

bridge.checkIsJobCreated = function(job)
    return QBCore.Shared.Jobs[job] ~= nil
end

bridge.createNewJob = function(job, jobData)
    exports['qb-core']:AddJob(job, jobData)
end

bridge.getPlayerJob = function(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return nil end
    return player.PlayerData.job
end

bridge.checkIsJobBoss = function(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end
    return player.PlayerData.job.isboss
end

bridge.getItemLabel = function(item)
    return ITEMS[item] and ITEMS[item].label or item
end

bridge.removeMoney = function(src, amount, moneyType)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end

    local type = moneyType or 'cash'
    local currentMoney = player.PlayerData.money[type] or 0
    if currentMoney < amount then return false end

    player.Functions.RemoveMoney(type, amount)
    return true
end

bridge.addMoney = function(src, amount)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end

    player.Functions.AddMoney('cash', amount)
    return true
end

bridge.addNeeds = function(src, needs)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local thirst = Player.PlayerData.metadata.thirst + needs.thirst
    local hunger = Player.PlayerData.metadata.hunger + needs.hunger
    local newThirst = thirst <= 100 and thirst or 100
    local newHunger = hunger <= 100 and hunger or 100

    Player.Functions.SetMetaData('thirst', newThirst)
    Player.Functions.SetMetaData('hunger', newHunger)
    TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, newThirst)
end

bridge.getPlayerIdentity = function(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return nil end

    return {
        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        citizenid = player.PlayerData.citizenid
    }
end

bridge.getDutyCount = function(job)
    return QBCore.Functions.GetDutyCount(job)
end

bridge.isAdmin = function(src)
    if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') then
        return true
    end

    if IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'admin') then
        return true
    end
    return false
end

bridge.init = function(restaurants)

end

bridge.onPlayerLoaded = function(cb)
    RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
        local src = source
        local player = bridge.getPlayerJob(src)
        if player then
            cb(src, player.name)
        end
    end)
end

bridge.onPlayerDropped = function(cb)
    AddEventHandler('playerDropped', function()
        local src = source
        local player = bridge.getPlayerJob(src)
        if player then
            cb(src, player.name)
        end
    end)
end

bridge.onJobUpdate = function(cb)
    RegisterNetEvent('QBCore:Server:OnJobUpdate', function(src, job)
        if job then
            cb(src, job.name)
        end
    end)
end

bridge.onDutyUpdate = function(cb)
    RegisterNetEvent('QBCore:Server:OnDutyUpdate', function(src, onDuty, job)
        if job then
            cb(src, onDuty, job.name or job)
        end
    end)
end

return bridge
