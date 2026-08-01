local utils = require 'modules.utils.server'
local bridge = require 'modules.bridge.server'
local config = require 'config.server'
local boxPattern = '^restaurant_food_box_'

local allowedItems = {}
for _, item in pairs(config.boxes.allowedItems or { 'restaurant_food' }) do
    allowedItems[item] = true
end

local function isBox(inventory)
    return type(inventory) == 'string' and inventory:find(boxPattern) ~= nil
end

utils.registerHook('swapItems', function(payload)
    local fromBox = isBox(payload.fromInventory)
    local toBox = isBox(payload.toInventory)

    if not fromBox and not toBox then return true end
    if payload.fromInventory == payload.toInventory then return true end

    if toBox and not allowedItems[payload.fromSlot.name] then
        return false
    end

    if fromBox and type(payload.toSlot) == 'table' and not allowedItems[payload.toSlot.name] then
        return false
    end

    return true
end, { inventoryFilter = { boxPattern } })

RegisterNetEvent('mt_restaurants:server:pickupBox', function(restaurantId, boxId)
    local src = source
    local now = os.time()
    if cooldown[src] and now - cooldown[src] < 3 then return end
    cooldown[src] = now

    local job = bridge.getPlayerJob(src)

    local restaurants = utils.getRestaurants()
    local restaurant
    for _, rest in pairs(restaurants) do
        if rest.id == restaurantId then
            restaurant = rest
            break
        end
    end 
    if not restaurant then return end

    if not job or job.name ~= restaurant.job or not job.onduty then return end

    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local canPickup = false
    if restaurant.boxes and restaurant.boxes[tonumber(boxId)] then
        local boxData = restaurant.boxes[tonumber(boxId)]
        if type(boxData) == 'string' then boxData = json.decode(boxData) end
        local coords = boxData[1]
        if coords then
            local boxCoords = vector3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
            if #(playerCoords - boxCoords) < 7.0 then
                canPickup = true
            end
        end
    end
    if not canPickup then return end

    utils.addItem(src, 'restaurant_box', 1, {
        label = locale('inventory.boxlabel', restaurant.label),
        imageurl = restaurant.boxImage,
        boxId = 'restaurant_food_box_' .. restaurant.id .. '_' .. math.random(1, 999999)
    })

    utils.log(src, 'RestaurantsPickupBox', 'Picked up box for ' .. restaurant.label)
end)

AddEventHandler('one_inventory:onItemUsed', function(payload)
    local playerId, name, slotId = payload.source, payload.item, payload.slot
    if name == 'restaurant_box' then
        local item = utils.getSlot(playerId, slotId)
        if item then
            if not item.metadata.boxId then
                TriggerClientEvent('mt_restaurants:client:notify', playerId, 'error', locale('error.boxIDNotFound'))
                return
            end

            if not utils.openInventory(playerId, 'stash', item.metadata.boxId) then
                utils.registerStash(item.metadata.boxId, item.label, config.boxes.maxWeight, config.boxes.slots)
                utils.openInventory(playerId, 'stash', item.metadata.boxId)
            end
        end
    end
end)
