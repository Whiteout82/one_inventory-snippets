local bridge = {}
local ITEMS = exports.one_inventory:GetAllItemDefinitions()

bridge.getAccountMoney = function(job)
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:GetAccountMoney(job) or 0
    end
    return exports['Renewed-Banking']:getAccountMoney(job)
end

bridge.removeAccountMoney = function(job, amount)
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:RemoveAccountMoney(job, amount, 'Restaurant Withdrawal')
    end
    return exports['Renewed-Banking']:removeAccountMoney(job, amount)
end

bridge.addAccountMoney = function(job, amount)
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:AddAccountMoney(job, amount, 'Restaurant Deposit')
    end
    return exports['Renewed-Banking']:addAccountMoney(job, amount)
end

bridge.checkIsJobCreated = function(job)
    job = exports.qbx_core:GetJob(job)
    return job ~= nil
end

bridge.createNewJob = function(job, jobData)
    exports.qbx_core:CreateJobs({
        [job] = jobData
    })
end

bridge.getPlayerJob = function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    return player.PlayerData.job
end

bridge.checkIsJobBoss = function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end
    return player.PlayerData.job.isboss
end

bridge.getItemLabel = function(item)
    return ITEMS[item] and ITEMS[item].label or item
end

bridge.removeMoney = function(src, amount, moneyType)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    local type = moneyType or 'cash'
    local currentMoney = player.PlayerData.money[type] or 0
    if currentMoney < amount then return false end

    player.Functions.RemoveMoney(type, amount)
    return true
end

bridge.addMoney = function(src, amount)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    player.Functions.AddMoney('cash', amount)
    return true
end

bridge.addNeeds = function(src, needs)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local thirst = Player.PlayerData.metadata.thirst + needs.thirst
    local hunger = Player.PlayerData.metadata.hunger + needs.hunger
    local newThirst = thirst <= 100 and thirst or 100
    local newHunger = hunger <= 100 and hunger or 100

    Player.Functions.SetMetaData('thirst', newThirst)
    Player.Functions.SetMetaData('hunger', newHunger)
    TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, newThirst)
end

bridge.relieveStress = function(src, amount)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local currentStress = Player.PlayerData.metadata.stress or 0
    local newStress = currentStress - amount
    if newStress < 0 then newStress = 0 end
    Player.Functions.SetMetaData('stress', newStress)
    TriggerClientEvent('hud:client:RelieveStress', src, amount)
    TriggerClientEvent('hud:client:UpdateStress', src, newStress)
end

bridge.getPlayerIdentity = function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end

    return {
        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        citizenid = player.PlayerData.citizenid
    }
end

bridge.getDutyCount = function(job)
    return exports.qbx_core:GetDutyCountJob(job)
end

bridge.isAdmin = function(src)
    if exports.qbx_core:HasPermission(src, 'admin') or exports.qbx_core:HasPermission(src, 'god') then
        return true
    end

    if IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'admin') then
        return true
    end

    return false
end

bridge.init = function(restaurants)

end

local playerJobs = {}

bridge.onPlayerLoaded = function(cb)
    AddEventHandler('qbx:playerLoaded', function(src, player)
        local jobName = player.PlayerData.job.name
        playerJobs[src] = jobName
        cb(src, jobName)
    end)
end

bridge.onPlayerDropped = function(cb)
    AddEventHandler('qbx:playerDropped', function(src)
        local jobName = playerJobs[src]
        if jobName then
            cb(src, jobName)
            playerJobs[src] = nil
        end
    end)
end

bridge.onJobUpdate = function(cb)
    AddEventHandler('qbx:setJob', function(src, job)
        if job then
            playerJobs[src] = job.name
            cb(src, job.name)
        end
    end)
end

bridge.onDutyUpdate = function(cb)
    AddEventHandler('qbx:setDuty', function(src, onDuty)
        local job = bridge.getPlayerJob(src)
        if job then
            cb(src, onDuty, job.name)
        end
    end)
end

return bridge
