local shared = require 'config.shared'
local bridge = require 'modules.bridge.server'
local config = require 'config.server'
local utils = {}

utils.debug = function(message, type)
    if not shared.debug then return end

    if GetResourceState('ox_lib') == 'started' then
        if lib.print[type] then
            lib.print[type](message)
        else
            lib.print.info(message)
        end
    else
        print(message)
    end
end

utils.generateOrderId = function()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = {}
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        id[i] = string.sub(chars, rand, rand)
    end
    return table.concat(id)
end

local restaurantsCache = nil
local restaurantMapCache = nil

utils.refreshRestaurantsCache = function()
    local file = LoadResourceFile(cache.resource, 'restaurants.json')
    local restaurants = json.decode(file) or {}
    
    local ftFile = LoadResourceFile(cache.resource, 'foodtrucks.json')
    local foodtrucks = ftFile and json.decode(ftFile) or {}
    
    local merged = {}
    local map = {}
    for _, r in pairs(restaurants) do
        table.insert(merged, r)
        if r.id then map[tostring(r.id)] = r end
    end
    for _, ft in pairs(foodtrucks) do
        table.insert(merged, ft)
        if ft.id then map[tostring(ft.id)] = ft end
    end
    restaurantsCache = merged
    restaurantMapCache = map
    return merged
end

utils.getRestaurants = function()
    if restaurantsCache then return restaurantsCache end
    return utils.refreshRestaurantsCache()
end

utils.getRestaurantById = function(id)
    if not restaurantMapCache then
        utils.refreshRestaurantsCache()
    end
    return restaurantMapCache[tostring(id)]
end

utils.isNearRestaurant = function(source, restaurantData, category, stationId)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)

    local function checkDistance(coords)
        if coords.isOffset then
            local netId = GlobalState["foodtruck_netid_" .. restaurantData.id]
            if netId then
                local vehicle = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(vehicle) then
                    local vehCoords = GetEntityCoords(vehicle)
                    if #(playerCoords - vehCoords) < 15.0 then
                        return true
                    end
                end
            end
            return false
        else
            local targetCoords = vector3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
            if #(playerCoords - targetCoords) < 15.0 then
                return true
            end
            return false
        end
    end

    if category == 'prepare' then
        if not restaurantData.prepare or #restaurantData.prepare == 0 then return false end
        for _, prepare in pairs(restaurantData.prepare) do
            local loc = prepare.location
            if type(loc) == 'string' then loc = json.decode(loc) end
            local coords = loc[1] or loc
            if coords and checkDistance(coords) then
                return true
            end
        end
    elseif category == 'customCrafting' then
        if not restaurantData.customCrafting or #restaurantData.customCrafting == 0 then return false end
        for _, cc in pairs(restaurantData.customCrafting) do
            local loc = cc.location
            if type(loc) == 'string' then loc = json.decode(loc) end
            local coords = loc[1] or loc
            if coords and checkDistance(coords) then
                return true
            end
        end
    elseif category == 'management' then
        if not restaurantData.management or #restaurantData.management == 0 then return false end
        for _, point in pairs(restaurantData.management) do
            local loc = point
            if type(loc) == 'string' then loc = json.decode(loc) end
            local coords = loc[1] or loc
            if coords and checkDistance(coords) then
                return true
            end
        end
    elseif category == 'stations' then
        if not restaurantData.stations or #restaurantData.stations == 0 then return false end
        for _, station in pairs(restaurantData.stations) do
            if not stationId or tostring(station.id) == tostring(stationId) then
                local loc = station.location
                if type(loc) == 'string' then loc = json.decode(loc) end
                local coords = loc[1] or loc
                if coords and checkDistance(coords) then
                    return true
                end
            end
        end
    end

    return false
end

local degradeCache = {}

local hasDegrade = function(itemName)
    if degradeCache[itemName] ~= nil then return degradeCache[itemName] end

    local item = exports.one_inventory:GetItemDefinition(itemName)
    if not item then return false end

    degradeCache[itemName] = type(item.degrade) == 'number' and { degrade = item.degrade } or false
    return degradeCache[itemName]
end

local getInventoryType = function(invId)
    if not invId then return 'normal' end
    local invStr = tostring(invId)
    if string.find(invStr, '^offlineshop_restaurants_') then
        return 'offline_shop'
    elseif string.find(invStr, '^restaurant_stash_') or string.find(invStr, '_order_stash_') or string.find(invStr, '_icemachine') or string.find(invStr, '^restaurant_food_box_') or string.find(invStr, '^stash_') then
        return 'stash'
    else
        return 'normal'
    end
end

local adjustMetadata = function(itemName, metadata, fromType, toType)
    local degradeable = hasDegrade(itemName)
    if not degradeable then return metadata end

    if not metadata then
        metadata = {}
    elseif type(metadata) ~= 'table' then
        return metadata
    elseif metadata.durability == false or metadata.frozenDurability == false then
        return metadata
    end

    local originalDegrade = degradeable.degrade
    local currentTime = os.time()
    local secondsLeft = 0

    if fromType == 'offline_shop' then
        secondsLeft = metadata.frozenDurability or (originalDegrade * 60)
    else
        local currentDurability = metadata.durability
        if not currentDurability or currentDurability == 0 then
            secondsLeft = originalDegrade * 60
        elseif currentDurability <= 100 then
            secondsLeft = metadata.frozenDurability or ((currentDurability / 100) * (originalDegrade * 60))
        else
            local totalSecondsLeft = currentDurability - currentTime
            if totalSecondsLeft <= 0 then return metadata end

            if fromType == 'stash' then
                secondsLeft = totalSecondsLeft / config.stashesDegradeMultiplier
            else
                secondsLeft = totalSecondsLeft
            end
        end
    end

    local newMeta = {}
    if metadata then
        for k, v in pairs(metadata) do
            newMeta[k] = v
        end
    end

    if toType == 'offline_shop' then
        newMeta.frozenDurability = math.floor(secondsLeft)
        newMeta.degrade = nil
        local percent = (secondsLeft / (originalDegrade * 60)) * 100
        newMeta.durability = math.max(0, math.min(100, math.floor(percent)))
    elseif toType == 'stash' then
        newMeta.frozenDurability = nil
        newMeta.degrade = originalDegrade * config.stashesDegradeMultiplier
        newMeta.durability = math.floor(currentTime + (secondsLeft * config.stashesDegradeMultiplier))
    else
        newMeta.frozenDurability = nil
        newMeta.degrade = originalDegrade
        newMeta.durability = math.floor(currentTime + secondsLeft)
    end

    return newMeta
end

-- Maps ox_inventory-style hook names used throughout this resource to their one_inventory equivalents
local hookNameMap = {
    swapItems = 'beforeItemSwap',
    openInventory = 'beforeInventoryOpen',
}

local invPrefixes = { 'stash', 'trunk', 'glovebox', 'container', 'drop', 'dumpster', 'player' }

-- Resolves a plain identifier (player id / stash name) into the string|number format one_inventory expects
local function resolveInv(inv)
    if type(inv) ~= 'string' then return inv end
    if tonumber(inv) then return inv end
    for _, prefix in ipairs(invPrefixes) do
        if inv:sub(1, #prefix + 1) == (prefix .. ':') then
            return inv
        end
    end
    return 'stash:' .. inv
end

-- Strips the one_inventory `stash:` / `trunk:` / ... prefix so downstream code can keep comparing raw names
local function stripInvPrefix(inv)
    if type(inv) ~= 'string' then return inv end
    for _, prefix in ipairs(invPrefixes) do
        local stripped = inv:match('^' .. prefix .. ':(.+)$')
        if stripped then return stripped end
    end
    return inv
end

local handleDurabilityLogic = function(payload)
    if not payload.fromInventory or not payload.toInventory then return end

    local fromType = getInventoryType(payload.fromInventory)
    local toType = getInventoryType(payload.toInventory)

    if fromType == toType then return end

    local toSlotId = type(payload.toSlot) == "number" and payload.toSlot or (payload.toSlot and payload.toSlot.slot)
    if toSlotId and payload.fromSlot then
        local itemName1 = payload.fromSlot.name
        local newMeta1 = adjustMetadata(itemName1, payload.fromSlot.metadata, fromType, toType)
        if newMeta1 then
            Citizen.SetTimeout(100, function()
                local slotData = exports.one_inventory:GetSlot(payload.toInventory, toSlotId)
                if slotData and slotData.name == itemName1 then
                    exports.one_inventory:SetItemMetadata(payload.toInventory, toSlotId, newMeta1)
                end
            end)
        end
    end

    if type(payload.toSlot) == "table" and payload.toSlot.name and payload.fromSlot then
        local fromSlotId = type(payload.fromSlot) == "number" and payload.fromSlot or (payload.fromSlot and payload.fromSlot.slot)
        if fromSlotId then
            local itemName2 = payload.toSlot.name
            local newMeta2 = adjustMetadata(itemName2, payload.toSlot.metadata, toType, fromType)
            if newMeta2 then
                Citizen.SetTimeout(100, function()
                    local slotData = exports.one_inventory:GetSlot(payload.fromInventory, fromSlotId)
                    if slotData and slotData.name == itemName2 then
                        exports.one_inventory:SetItemMetadata(payload.fromInventory, fromSlotId, newMeta2)
                    end
                end)
            end
        end
    end
end

exports.one_inventory:RegisterHook('beforeItemSwap', function(payload)
    handleDurabilityLogic(payload)
    return true
end, {})

utils.addItem = function(inventory, item, quantity, metadata)
    local fromType = 'normal'
    if metadata then
        if metadata.frozenDurability then
            fromType = 'offline_shop'
        elseif metadata.degrade and hasDegrade(item) then
            local originalDegrade = hasDegrade(item).degrade
            if metadata.degrade > originalDegrade then
                fromType = 'stash'
            end
        end
    end

    local toType = getInventoryType(inventory)
    local adjustedMetadata = adjustMetadata(item, metadata, fromType, toType)

    return exports.one_inventory:AddItem(resolveInv(inventory), item, quantity, adjustedMetadata or {})
end

utils.removeItem = function(inventory, item, quantity, slot)
    return exports.one_inventory:RemoveItem(resolveInv(inventory), item, quantity, nil, slot)
end

utils.registerStash = function(stash, label, weight, slots)
    if string.find(tostring(stash), '_order_stash_') then
        local orderConfig = config.orderStash or { slots = 20, maxWeight = 30000 }
        weight = orderConfig.maxWeight
        slots = orderConfig.slots
    end
    local inv = resolveInv(stash)
    if not exports.one_inventory:GetInventory(inv) then
        -- a real (non-zero) AddItem/RemoveItem pair reliably auto-creates the stash;
        -- SetItem(..., 0) is a no-op change and doesn't always materialise the inventory
        exports.one_inventory:AddItem(inv, 'restaurant_food', 1)
        exports.one_inventory:RemoveItem(inv, 'restaurant_food', 1)
    end
    exports.one_inventory:SetInventoryMaxWeight(inv, weight)
    exports.one_inventory:SetInventorySlotCount(inv, slots)
    return true
end

utils.canCarryItem = function(inventory, item, quantity, metadata)
    return exports.one_inventory:CanCarryItem(resolveInv(inventory), item, quantity)
end

utils.getItemCount = function(inventory, item, metadata)
    return exports.one_inventory:GetItemCount(resolveInv(inventory), item, metadata)
end

utils.getSlot = function(inventory, slot)
    return exports.one_inventory:GetSlot(resolveInv(inventory), slot)
end

local authorizedInventories = {}

utils.openInventory = function(playerId, invType, data)
    local openData = data
    if invType == 'stash' then
        -- id must stay unprefixed here: OpenInventory's stash.id is the raw name, and
        -- slots/maxWeight auto-create OR live-resize the stash, so no pre-existence check is needed
        openData = { id = data }
        local dataStr = tostring(data)
        if string.find(dataStr, '_order_stash_') then
            local orderConfig = config.orderStash or { slots = 20, maxWeight = 30000 }
            openData.slots = orderConfig.slots
            openData.maxWeight = orderConfig.maxWeight
        elseif string.find(dataStr, '^restaurant_food_box_') then
            local boxConfig = config.boxes or { slots = 10, maxWeight = 10000 }
            openData.slots = boxConfig.slots
            openData.maxWeight = boxConfig.maxWeight
        end
    end

    authorizedInventories[playerId] = tostring(data)
    return exports.one_inventory:OpenInventory(playerId, invType, openData)
end

exports.one_inventory:RegisterHook('beforeInventoryOpen', function(payload)
    if not payload.inventoryId then return false end
    
    local lowerId = string.lower(tostring(payload.inventoryId))
    if string.find(lowerId, 'restaurant_') or string.find(lowerId, '_order_stash_') or string.find(lowerId, '_icemachine') or string.find(lowerId, 'offlineshop_restaurants_') then
        local isPhysicalStash = string.find(lowerId, 'restaurant_stash_')
        local isOfflineShop = string.find(lowerId, 'offlineshop_restaurants_')

        if isPhysicalStash or isOfflineShop then
            local restaurantId = nil
            if isPhysicalStash then
                restaurantId = payload.inventoryId:match('restaurant_stash_([^_]+)_')
            else
                restaurantId = payload.inventoryId:match('offlineshop_restaurants_(.+)')
            end

            if restaurantId then
                local restaurant = utils.getRestaurantById(restaurantId)

                if restaurant then
                    local xPlayer = bridge.getPlayerJob(payload.source)
                    if not xPlayer or xPlayer.name ~= restaurant.job then
                        utils.debug(('Player %s attempted to open stash %s without the correct job (%s)'):format(payload.source, payload.inventoryId, restaurant.job), 'error')
                        return false
                    end
                end
            end
        end

        local expectedToken = authorizedInventories[payload.source]
        if expectedToken == tostring(payload.inventoryId) then
            authorizedInventories[payload.source] = nil
            return true
        end
        return false
    end
end, {})

utils.registerHook = function(hook, callback, filter)
    local mappedHook = hookNameMap[hook] or hook

    local mappedFilter = filter
    if filter and filter.inventoryFilter then
        mappedFilter = {}
        for k, v in pairs(filter) do mappedFilter[k] = v end
        local patterns = {}
        for _, pattern in ipairs(filter.inventoryFilter) do
            -- drop leading anchors so the pattern still matches once one_inventory prefixes the id (stash:, trunk:, ...)
            patterns[#patterns + 1] = pattern:gsub('^%^', '')
        end
        mappedFilter.inventoryFilter = patterns
    end

    return exports.one_inventory:RegisterHook(mappedHook, function(payload)
        if payload.fromInventory then payload.fromInventory = stripInvPrefix(payload.fromInventory) end
        if payload.toInventory then payload.toInventory = stripInvPrefix(payload.toInventory) end
        return callback(payload)
    end, mappedFilter)
end

utils.notifyStaff = function(job, message, type, excludePlayer)
    local players = GetActivePlayers()
    for _, player in pairs(players) do
        if not excludePlayer or tonumber(player) ~= tonumber(excludePlayer) then
            local playerJob = bridge.getPlayerJob(player)
            if playerJob and playerJob.name == job and (playerJob.onduty or playerJob.onDuty) then
                TriggerClientEvent('mt_restaurants:client:notify', player, message, type or 'info')
            end
        end
    end
end

utils.getStaffOnDuty = function(job)
    local staff = {}
    local players = GetActivePlayers()
    for _, player in pairs(players) do
        local playerJob = bridge.getPlayerJob(player)
        if playerJob and playerJob.name == job and (playerJob.onduty or playerJob.onDuty) then
            table.insert(staff, tonumber(player))
        end
    end
    return staff
end

utils.getInventoryItems = function(inventory, includeSlots)
    return exports.one_inventory:GetInventoryItems(resolveInv(inventory))
end

utils.setItemMetadata = function(inventory, slot, metadata)
    return exports.one_inventory:SetItemMetadata(resolveInv(inventory), slot, metadata)
end

utils.log = function(src, event, message)
    lib.logger(src, event, message)
end

return utils
