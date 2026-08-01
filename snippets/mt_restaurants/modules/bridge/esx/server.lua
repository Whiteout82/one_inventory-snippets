local bridge = {}
local ESX = exports['es_extended']:getSharedObject()
local ITEMS = exports.one_inventory:GetAllItemDefinitions()

bridge.getAccountMoney = function(job)
    local account = 'society_' .. job
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:GetAccountMoney(account) or 0
    end

    local p = promise.new()
    TriggerEvent('esx_addonaccount:getSharedAccount', account, function(acc)
        if acc then
            p:resolve(acc.money)
        else
            p:resolve(0)
        end
    end)
    return Citizen.Await(p)
end

bridge.removeAccountMoney = function(job, amount)
    local account = 'society_' .. job
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:RemoveAccountMoney(account, amount, 'Restaurant Withdrawal')
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', account, function(acc)
        if acc then
            acc.removeMoney(amount)
        end
    end)
    return true
end

bridge.addAccountMoney = function(job, amount)
    local account = 'society_' .. job
    if GetResourceState('kartik-banking') == 'started' then
        return exports['kartik-banking']:AddAccountMoney(account, amount, 'Restaurant Deposit')
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', account, function(acc)
        if acc then
            acc.addMoney(amount)
        end
    end)
    return true
end

bridge.checkIsJobCreated = function(job)
    return ESX.DoesJobExist(job, 0)
end

bridge.createNewJob = function(job, jobData)
    local jobExists = MySQL.single.await('SELECT name FROM jobs WHERE name = ?', { job })
    if not jobExists then
        MySQL.insert('INSERT INTO jobs (name, label) VALUES (?, ?)', { job, jobData.label })
    end

    for grade, data in pairs(jobData.grades) do
        local gradeExists = MySQL.single.await('SELECT grade FROM job_grades WHERE job_name = ? AND grade = ?', { job, grade })
        if not gradeExists then
            MySQL.insert('INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                job, grade, data.gradename:lower(), data.name, data.payment or 0, '{}', '{}'
            })
        end
    end

    local accountName = 'society_' .. job
    MySQL.query('INSERT IGNORE INTO addon_account (name, label, shared) VALUES (?, ?, ?)', {
        accountName, jobData.label, 1
    })

    MySQL.query('INSERT IGNORE INTO addon_account_data (account_name, money) VALUES (?, ?)', {
        accountName, 0
    })

    ESX.RefreshJobs()
    return true
end

bridge.getPlayerJob = function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    local job = xPlayer.getJob()
    if job.onDuty then job.onduty = true end 
    return job
end

bridge.checkIsJobBoss = function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local job = xPlayer.getJob()
    return job and (job.grade_name == 'boss' or job.isboss)
end

RegisterNetEvent('mt_restaurants:server:toggleDuty', function(goOnDuty)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob()
    if not job then return end

    if goOnDuty then
        if not job.onDuty then
            xPlayer.setJob(job.name, job.grade, true)
            TriggerClientEvent('mt_restaurants:client:notify', src, locale('info.youAreNowOnDuty'), 'info')
            GlobalState[('mt_restaurants:dutyCount:%s'):format(job.name)] = bridge.getDutyCount(job.name)
        end
    else
        if job.onDuty then
            xPlayer.setJob(job.name, job.grade, false)
            TriggerClientEvent('mt_restaurants:client:notify', src, locale('info.youAreNowOffDuty'), 'info')
            GlobalState[('mt_restaurants:dutyCount:%s'):format(job.name)] = bridge.getDutyCount(job.name)
        end
    end
end)

bridge.getItemLabel = function(item)
    return ITEMS[item] and ITEMS[item].label or item
end

bridge.removeMoney = function(src, amount, moneyType)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local type = moneyType or 'money'
    if type == 'cash' then type = 'money' end

    if xPlayer.getAccount(type).money < amount then return false end

    xPlayer.removeAccountMoney(type, amount)
    return true
end

bridge.addMoney = function(src, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    xPlayer.addAccountMoney('money', amount)
    return true
end

bridge.addNeeds = function(src, needs)
    if needs.thirst then
        TriggerClientEvent('esx_status:add', src, 'thirst', needs.thirst * 10000)
    end
    if needs.hunger then
        TriggerClientEvent('esx_status:add', src, 'hunger', needs.hunger * 10000)
    end
end

bridge.relieveStress = function(src, amount)
    TriggerClientEvent('esx_status:remove', src, 'stress', amount * 10000)
    TriggerClientEvent('hud:client:RelieveStress', src, amount)
end

bridge.getPlayerIdentity = function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end

    return {
        name = xPlayer.getName(),
        citizenid = xPlayer.getIdentifier()
    }
end

bridge.getDutyCount = function(job)
    local count = 0
    local xPlayers = ESX.GetExtendedPlayers('job', job)

    for _, xPlayer in pairs(xPlayers or {}) do
        local pJob = xPlayer.getJob()
        if pJob.onDuty or pJob.onduty or xPlayer.get('onDuty') then
            count = count + 1
        end
    end

    return count
end

bridge.isAdmin = function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local group = xPlayer.getGroup()
    if group == 'admin' or group == 'superadmin' then
        return true
    end

    if IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'admin') then
        return true
    end

    return false
end

bridge.onPlayerLoaded = function(cb)
    AddEventHandler('esx:playerLoaded', function(src, xPlayer)
        if xPlayer then
            cb(src, xPlayer.getJob().name)
        end
    end)
end

bridge.onPlayerDropped = function(cb)
    AddEventHandler('esx:playerDropped', function(src, xPlayer)
        local pJob = xPlayer and xPlayer.getJob and xPlayer.getJob()
        local jobName = pJob and pJob.name
        
        if jobName then
            cb(src, jobName)
        end
    end)
end

bridge.onJobUpdate = function(cb)
    AddEventHandler('esx:setJob', function(src, job, lastJob)
        if job then
            cb(src, job.name, lastJob and lastJob.name)
        end
    end)
end

bridge.init = function(restaurants)
    for _, restaurant in pairs(restaurants) do
        TriggerEvent('esx_society:registerSociety', restaurant.job, restaurant.label, 'society_' .. restaurant.job, 'society_' .. restaurant.job, 'society_' .. restaurant.job, { wash = false })
    end
end

bridge.onDutyUpdate = function(cb)
    AddEventHandler('esx:setJob', function(src, job, lastJob)
        if job then
            cb(src, job.onDuty or job.onduty, job.name)
        end
    end)
end

return bridge
