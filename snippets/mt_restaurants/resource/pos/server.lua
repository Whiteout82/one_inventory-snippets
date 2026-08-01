local bridge = require 'modules.bridge.server'
local utils = require 'modules.utils.server'
local config = require 'config.server'
local clientConfig = require 'config.client'
local sharedConfig = require 'config.shared'
local ingredientsData = require 'data.ingredients'
local cooldown = {}
local orders = {}

local function getDegradationMultiplier(totalQuantity)
    if totalQuantity <= 2 then
        return 1.0
    else
        local rate = config.recipes and config.recipes.degradationPercentage or 0.2
        local effective = 2.0
        for i = 3, totalQuantity do
            effective = effective + math.max(0.0, 1.0 - (rate * (i - 2)))
        end
        return effective / totalQuantity
    end
end

local getCustomCraftRecipe = function(restaurantData, recipeId)
    if type(recipeId) ~= 'string' or recipeId:sub(1, 3) ~= 'cc_' then return nil end
    if not restaurantData.customCrafting then return nil end
    for ccId, ccZone in pairs(restaurantData.customCrafting) do
        local items = ccZone.items
        if type(items) == 'string' then items = json.decode(items) end
        if items then
            for _, itemObj in pairs(items) do
                local expectedId = string.format("cc_%s_%s_%s", restaurantData.id, ccId, itemObj.name)
                if expectedId == recipeId then
                    return {
                        id = recipeId,
                        price = itemObj.price or 0,
                        label = bridge.getItemLabel(itemObj.name) or itemObj.name,
                        image_url = string.format(clientConfig.inventoryImages, itemObj.name),
                        itemName = itemObj.name,
                        ingredients = itemObj.neededItems or {}
                    }
                end
            end
        end
    end
    return nil
end

local registerOrderStash = function(restaurantId, orderId, totalQuantity, validatedItems)
    local stashId = restaurantId .. '_order_stash_' .. orderId
    CreateThread(function()
        local totalWeight = 0
        local restaurants = utils.getRestaurants()
        local restaurantData = nil
        for _, restaurant in pairs(restaurants) do
            if tostring(restaurant.id) == tostring(restaurantId) then
                restaurantData = restaurant
                break
            end
        end

        local itemData = exports.one_inventory:GetItemDefinition('restaurant_food')
        local baseWeight = itemData and itemData.weight or 0

        if restaurantData and validatedItems and #validatedItems > 0 then
            local restaurantIngredientsIdx = tonumber(restaurantData.ingredients)
            local availableIngredients = ingredientsData[restaurantIngredientsIdx] and ingredientsData[restaurantIngredientsIdx].ingredients or {}

            for _, item in pairs(validatedItems) do
                if item.isCustomCraft then
                    local customItemData = exports.one_inventory:GetItemDefinition(item.itemName)
                    local customItemWeight = customItemData and customItemData.weight or 150
                    totalWeight = totalWeight + (customItemWeight * item.quantity)
                else
                    local recipeIngredients = {}
                    local rId = tonumber(item.recipeId)
                    if rId then
                        local recipe = MySQL.single.await('SELECT ingredients FROM restaurants_recipes WHERE id = ?', { rId })
                        if recipe and recipe.ingredients then
                            recipeIngredients = json.decode(recipe.ingredients) or {}
                        end
                    end

                    if #recipeIngredients > 0 then
                        local ingredientTotals = {}
                        for _, neededItem in pairs(recipeIngredients) do
                            ingredientTotals[neededItem.name] = (ingredientTotals[neededItem.name] or 0) + neededItem.quantity
                        end

                        local calories = 0
                        for _, ingredient in pairs(availableIngredients) do
                            for _, neededItem in pairs(recipeIngredients) do
                                if ingredient.item == neededItem.name then
                                    local multiplier = getDegradationMultiplier(ingredientTotals[neededItem.name])
                                    calories = calories + (ingredient.calories * neededItem.quantity * multiplier)
                                end
                            end
                        end

                        local itemWeight = baseWeight + (calories / 10)
                        totalWeight = totalWeight + (itemWeight * item.quantity)
                    end
                end
            end
        end

        local stashWeight = math.ceil(totalWeight)
        if stashWeight <= 0 then
            stashWeight = 100000
        end

        utils.registerStash(stashId, locale('inventory.orderStash', orderId) or ('Order ' .. orderId), stashWeight, totalQuantity)
    end)
    utils.registerHook('swapItems', function(payload)
        if payload.fromInventory == stashId then return true end
        
        if payload.toInventory == stashId then
            local item = payload.fromSlot
            local isAllowed = false
            local customItemData = nil
            for _, vItem in pairs(validatedItems) do
                if vItem.isCustomCraft and vItem.itemName == item.name then
                    isAllowed = true
                    customItemData = vItem
                    break
                end
            end

            if not isAllowed and item.name ~= 'restaurant_food' and item.name ~= 'restaurant_box' then return false end

            if isAllowed and customItemData then
                local orderedQuantity = customItemData.quantity
                local currentCount = utils.getItemCount(stashId, item.name) or 0
                if (currentCount + payload.count) > orderedQuantity then return false end
                return true
            end

            if item.name == 'restaurant_food' then
                if not item.metadata or (item.metadata.remainingBites and item.metadata.remainingBites < sharedConfig.bites) then return false end
                
                local recipeId = item.metadata.recipe
                local orderedQuantity = 0
                for _, vItem in pairs(validatedItems) do
                    if vItem.recipeId == recipeId then
                        orderedQuantity = vItem.quantity
                        break
                    end
                end
                
                if orderedQuantity == 0 then return false end
                
                local currentCount = utils.getItemCount(stashId, 'restaurant_food', { recipe = recipeId })
                if (currentCount + payload.count) > orderedQuantity then return false end
            end
            
            return true
        end
    end, { inventoryFilter = { stashId } })
end

local getJobByRestaurantId = function(restaurantId)
    local restaurants = utils.getRestaurants()
    for _, restaurant in pairs(restaurants) do
        if tostring(restaurant.id) == tostring(restaurantId) then
            return restaurant.job
        end
    end
    return nil
end

lib.callback.register('mt_restaurants:server:getNearbyPlayers', function(source, range)
    local src = source
    local players = GetActivePlayers()
    local nearbyPlayers = {}
    local srcCoords = GetEntityCoords(GetPlayerPed(src))

    local playerIdentity = bridge.getPlayerIdentity(src)
    nearbyPlayers[#nearbyPlayers + 1] = {
        label = playerIdentity.name,
        value = src
    }

    for _, player in pairs(players) do
        if player ~= src then
            local playerCoords = GetEntityCoords(GetPlayerPed(player))
            local distance = #(playerCoords - srcCoords)

            if distance <= range then
                local playerIdentity = bridge.getPlayerIdentity(player)
                if playerIdentity then
                    nearbyPlayers[#nearbyPlayers + 1] = {
                        label = playerIdentity.name,
                        value = player
                    }
                end
            end
        end
    end

    return nearbyPlayers
end)

lib.callback.register('mt_restaurants:server:createOrder', function(source, data)
    local src = source
    local job = bridge.getPlayerJob(src)
    local restaurants = utils.getRestaurants()
    local restaurantId = nil
    local restaurantData = nil

    local now = os.time()
    if cooldown[src] and now - cooldown[src] < 3 then return false end
    cooldown[src] = now

    for _, restaurant in pairs(restaurants) do
        if tostring(restaurant.id) == tostring(data.restaurantId) then
            if data.selfOrdering or (job and restaurant.job == job.name) then
                restaurantId = tostring(restaurant.id)
                restaurantData = restaurant
                break
            end
        end
    end

    if not restaurantId then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.youAreNotAuthorizedTo4'), 'error')
        return false
    end

    if data.selfOrdering then
        local restaurant = nil
        for _, r in pairs(restaurants) do
            if r.id == restaurantId then
                restaurant = r
                break
            end
        end

        if restaurant then
            local dutyCount = bridge.getDutyCount(restaurant.job)
            if dutyCount <= 0 then
                TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.noduty'), 'error')
                return false
            end
        end
    end

    if not data.items or #data.items == 0 then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.orderMustContainAtLeast'), 'error')
        return false
    end

    local dbRecipeIds = {}
    local customCraftItems = {}

    for _, item in pairs(data.items) do
        local customRecipe = getCustomCraftRecipe(restaurantData, item.recipeId)
        if customRecipe then
            customCraftItems[item.recipeId] = customRecipe
        else
            if restaurantData.disableRecipes then
                TriggerClientEvent('mt_restaurants:client:notify', src, "Standard recipes are disabled for this restaurant", 'error')
                return false
            end
            table.insert(dbRecipeIds, tonumber(item.recipeId))
        end
    end

    local recipePrices = {}
    local recipeLabels = {}
    local recipeImages = {}

    if #dbRecipeIds > 0 then
        local recipes = MySQL.query.await('SELECT id, price, label, image_url FROM restaurants_recipes WHERE restaurant = ? AND id IN (' .. table.concat(dbRecipeIds, ',') .. ')', { restaurantId })
        if recipes then
            for _, recipe in pairs(recipes) do
                recipePrices[recipe.id] = recipe.price
                recipeLabels[recipe.id] = recipe.label
                recipeImages[recipe.id] = recipe.image_url
            end
        end
    end

    for id, customRecipe in pairs(customCraftItems) do
        recipePrices[id] = customRecipe.price
        recipeLabels[id] = customRecipe.label
        recipeImages[id] = customRecipe.image_url
    end

    local foundAny = false
    for _ in pairs(recipePrices) do
        foundAny = true
        break
    end

    if not foundAny then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.noValidRecipesFoundFor'), 'error')
        return false
    end

    local validatedItems = {}
    local calculatedTotal = 0

    for _, item in pairs(data.items) do
        local recipePrice = recipePrices[item.recipeId]
        if not recipePrice then
            TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.invalidRecipeId', tostring(item.recipeId)), 'error')
            return false
        end

        local recipeLabel = recipeLabels[item.recipeId] or 'Unknown Item'
        local recipeImage = recipeImages[item.recipeId] or ''

        local itemTotal = recipePrice * item.quantity
        calculatedTotal = calculatedTotal + itemTotal

        table.insert(validatedItems, {
            recipeId = item.recipeId,
            quantity = item.quantity,
            price = recipePrice,
            total = itemTotal,
            label = recipeLabel,
            image_url = recipeImage,
            isCustomCraft = customCraftItems[item.recipeId] ~= nil,
            itemName = customCraftItems[item.recipeId] and customCraftItems[item.recipeId].itemName or nil
        })
    end

    if data.discount and data.discount.type and data.discount.value then
        local discountAmount = 0
        if data.discount.type == 'percentage' then
            discountAmount = calculatedTotal * (data.discount.value / 100)
        elseif data.discount.type == 'amount' then
            discountAmount = data.discount.value
        end
        calculatedTotal = math.max(0, calculatedTotal - discountAmount)
    end

    if math.abs(data.total - calculatedTotal) > 0.01 then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.orderTotalMismatchDetectedPlease'), 'error')
        return false
    end

    local orderId
    repeat
        orderId = utils.generateOrderId()
    until not (orders[restaurantId] and orders[restaurantId][orderId])

    local customerIdentity = bridge.getPlayerIdentity(data.playerId)
    local customerName = customerIdentity and customerIdentity.name or 'Unknown'
    local citizenId = customerIdentity and customerIdentity.citizenid or 'Unknown'

    local creatorIdentity = bridge.getPlayerIdentity(src)
    
    local totalQuantity = 0
    for _, item in pairs(validatedItems) do
        totalQuantity = totalQuantity + item.quantity
    end

    local isFoodTruck = restaurantData and restaurantData.truckSpawnerPed and restaurantData.truckSpawnerPed.pedModel and restaurantData.truckSpawnerPed.pedModel ~= ''
    local orderType = 'pos'
    if data.selfOrdering then
        orderType = 'self_ordering'
    elseif data.isDriveThru then
        orderType = 'drive_thru'
    elseif isFoodTruck then
        orderType = 'foodtruck'
    end

    local orderData = {
        restaurantId = restaurantId,
        playerId = data.playerId,
        customerName = customerName,
        citizenId = citizenId,
        creatorCitizenId = creatorIdentity and creatorIdentity.citizenid,
        creatorName = creatorIdentity and creatorIdentity.name or 'Unknown',
        creatorId = src,
        items = validatedItems,
        total = calculatedTotal,
        totalQuantity = totalQuantity,
        discount = data.discount,
        state = 'pending',
        orderType = orderType,
        id = orderId
    }

    orders[restaurantId] = orders[restaurantId] or {}
    orders[restaurantId][orderId] = orderData

    local targetJob = getJobByRestaurantId(restaurantId)
    if targetJob then
        local staff = utils.getStaffOnDuty(targetJob)
        for _, staffId in pairs(staff) do
            TriggerClientEvent('mt_restaurants:client:updateActiveOrders', staffId, orderData)
        end
    end

    registerOrderStash(restaurantId, orderId, totalQuantity, validatedItems)

    if not data.selfOrdering and not data.isDriveThru and not isFoodTruck then
        TriggerClientEvent('mt_restaurants:client:addOrderTarget', data.playerId, orderId, restaurantData)
    elseif data.isDriveThru or isFoodTruck then
        TriggerClientEvent('mt_restaurants:client:displayReceipt', data.playerId, orders[restaurantId][orderId])
    end
    TriggerClientEvent('mt_restaurants:client:notify', src, locale('success.orderCreatedSuccessfully'), 'success')

    utils.log(src, 'RestaurantsCreateOrder', 'Created order ' .. orderId .. ' for ' .. restaurantData.label)
    return { success = true, orderId = orderId }
end)

RegisterNetEvent('mt_restaurants:server:injectNpcOrder', function(orderData)
    local restaurantId = tostring(orderData.restaurantId)
    local orderId = orderData.id

    orders[restaurantId] = orders[restaurantId] or {}
    orders[restaurantId][orderId] = orderData

    local targetJob = getJobByRestaurantId(restaurantId)
    if targetJob then
        local staff = utils.getStaffOnDuty(targetJob)
        for _, staffId in pairs(staff) do
            TriggerClientEvent('mt_restaurants:client:updateActiveOrders', staffId, orderData)
        end
        utils.notifyStaff(targetJob, locale('info.orderReceived') or 'New Order Received', 'success')
    end

    registerOrderStash(restaurantId, orderId, orderData.totalQuantity, orderData.items)
end)

lib.callback.register('mt_restaurants:server:getActiveOrders', function(source)
    local src = source
    local job = bridge.getPlayerJob(src)
    if not job or not job.onduty then return {} end

    local activeOrdersList = {}
    local restaurants = utils.getRestaurants()
    
    for restId, restaurantOrders in pairs(orders) do
        local isStaff = false
        for _, rest in pairs(restaurants) do
            if tostring(rest.id) == tostring(restId) and rest.job == job.name then
                isStaff = true
                break
            end
        end

        if isStaff then
            for orderId, orderData in pairs(restaurantOrders) do
                local activeStates = { paid = true, preparing = true, prepared = true }
                if activeStates[orderData.state] then
                    table.insert(activeOrdersList, orderData)
                end
            end
        end
    end
    return activeOrdersList
end)

lib.callback.register('mt_restaurants:server:isRestaurantJob', function(source)
    local src = source
    local job = bridge.getPlayerJob(src)
    if not job then return false end

    local restaurants = utils.getRestaurants()
    for _, restaurant in pairs(restaurants) do
        if restaurant.job == job.name then
            return true
        end
    end

    return false
end)

lib.callback.register('mt_restaurants:server:getRestaurantOrders', function(source, restaurantId)
    local src = source
    local job = bridge.getPlayerJob(src)
    local restaurants = utils.getRestaurants()
    local authorized = false
    local restIdStr = tostring(restaurantId)

    for _, restaurant in pairs(restaurants) do
        if job and restaurant.job == job.name and tostring(restaurant.id) == restIdStr then
            authorized = true
            break
        end
    end

    if not authorized then return {} end

    local restaurantOrders = orders[restIdStr] or {}
    local orderList = {}
    for orderId, orderData in pairs(restaurantOrders) do
        local activeStates = { paid = true, preparing = true, prepared = true }
        if activeStates[orderData.state] then
            local playerIdentity = bridge.getPlayerIdentity(tonumber(orderData.playerId))
            local customerName = (playerIdentity and playerIdentity.name) or 'Unknown Customer'

            local enrichedItems = {}
            for _, item in pairs(orderData.items) do
                if item.isCustomCraft or (type(item.recipeId) == 'string' and item.recipeId:sub(1, 3) == 'cc_') then
                    table.insert(enrichedItems, {
                        recipeId = item.recipeId,
                        quantity = item.quantity,
                        price = item.price,
                        total = item.total,
                        label = item.label,
                        image_url = item.image_url
                    })
                else
                    local recipe = MySQL.query.await('SELECT label, image_url FROM restaurants_recipes WHERE id = ?', { item.recipeId })
                    if recipe and recipe[1] then
                        table.insert(enrichedItems, {
                            recipeId = item.recipeId,
                            quantity = item.quantity,
                            price = item.price,
                            total = item.total,
                            label = recipe[1].label,
                            image_url = recipe[1].image_url
                        })
                    end
                end
            end

            table.insert(orderList, {
                id = orderId,
                customerName = customerName,
                customerId = orderData.playerId,
                total = orderData.total,
                discount = orderData.discount,
                state = orderData.state,
                items = enrichedItems,
                restaurantId = orderData.restaurantId
            })
        end
    end

    return orderList
end)

lib.callback.register('mt_restaurants:server:getOrderData', function(source, orderId)
    local src = source

    for _, restaurantOrders in pairs(orders) do
        if restaurantOrders[orderId] then
            local orderData = restaurantOrders[orderId]
            if tonumber(orderData.playerId) ~= src then return nil end

            local enrichedItems = {}
            for _, item in pairs(orderData.items) do
                if item.isCustomCraft or (type(item.recipeId) == 'string' and item.recipeId:sub(1, 3) == 'cc_') then
                    table.insert(enrichedItems, {
                        recipeId = item.recipeId,
                        quantity = item.quantity,
                        price = item.price,
                        total = item.total,
                        label = item.label,
                        image_url = item.image_url
                    })
                else
                    local recipe = MySQL.query.await('SELECT label, image_url FROM restaurants_recipes WHERE id = ?', { item.recipeId })
                    if recipe and recipe[1] then
                        table.insert(enrichedItems, {
                            recipeId = item.recipeId,
                            quantity = item.quantity,
                            price = item.price,
                            total = item.total,
                            label = recipe[1].label,
                            image_url = recipe[1].image_url
                        })
                    end
                end
            end

            return {
                id = orderData.id,
                items = enrichedItems,
                total = orderData.total,
                discount = orderData.discount,
                state = orderData.state,
                restaurantId = orderData.restaurantId
            }
        end
    end

    return nil
end)

lib.callback.register('mt_restaurants:server:payOrder', function(source, data)
    local src = source
    local orderId = data.orderId
    local moneyType = data.moneyType or 'cash'
    local orderData = nil
    local restaurantId = nil

    for restId, restaurantOrders in pairs(orders) do
        if restaurantOrders[orderId] then
            orderData = restaurantOrders[orderId]
            restaurantId = tostring(restId)
            break
        end
    end

    if not orderData then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.orderNotFound'), 'error')
        return false
    end

    if tonumber(orderData.playerId) ~= src then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.thisOrderIsNotFor'), 'error')
        return false
    end

    if orderData.state ~= 'pending' then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.thisOrderHasAlreadyBeen'), 'error')
        return false
    end

    local tip = tonumber(data.tip) or 0
    if tip < 0 then tip = 0 end

    local totalAmount = orderData.total + tip
    local success = bridge.removeMoney(src, totalAmount, moneyType)
    if not success then
        TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.insufficientFunds'), 'error')
        return false
    end

    orderData.state = 'paid'
    orders[restaurantId][orderId] = orderData

    local targetJob = getJobByRestaurantId(restaurantId)
    if targetJob then
        local staff = utils.getStaffOnDuty(targetJob)
        for _, staffId in pairs(staff) do
            TriggerClientEvent('mt_restaurants:client:updateActiveOrders', staffId, orderData)
        end
    end

    TriggerClientEvent('mt_restaurants:client:notify', src, locale('success.orderPaid'), 'success')

    local restaurants = utils.getRestaurants()
    local targetJob = nil
    local restaurantData = nil
    for _, restaurant in pairs(restaurants) do
        if tostring(restaurant.id) == restaurantId then
            targetJob = restaurant.job
            restaurantData = restaurant
            break
        end
    end

    local commission = config.commissions.pos
    if orderData.orderType == 'self_ordering' then
        commission = 0
    end
    
    local commissionAmount = math.floor(orderData.total * commission)
    local restaurantAmount = orderData.total - commissionAmount

    if targetJob then
        bridge.addAccountMoney(targetJob, restaurantAmount)
    end

    local creatorNotified = false
    local commissionSent = false
    if commissionAmount > 0 and orderData.creatorId and (orderData.orderType == 'pos' or orderData.orderType == 'drive_thru' or orderData.orderType == 'foodtruck') then
        bridge.addMoney(orderData.creatorId, commissionAmount)
        commissionSent = true
    end

    if tip > 0 and orderData.creatorId then
        bridge.addMoney(orderData.creatorId, tip)
        if commissionSent then
            TriggerClientEvent('mt_restaurants:client:notify', orderData.creatorId, locale('success.receivedCommissionAndTip', commissionAmount, tip, orderId), 'success')
            creatorNotified = true
        else
            TriggerClientEvent('mt_restaurants:client:notify', orderData.creatorId, locale('success.receivedTip', tip, orderId), 'success')
            creatorNotified = true
        end
    elseif commissionSent then
        TriggerClientEvent('mt_restaurants:client:notify', orderData.creatorId, locale('success.receivedCommission', commissionAmount, orderId), 'success')
        creatorNotified = true
    end

    if targetJob then
        utils.notifyStaff(targetJob, locale('info.orderReceived'), 'success', creatorNotified and orderData.creatorId or nil)
    end

    if restaurantData then
        utils.log(src, 'RestaurantsUpdateOrderState', 'Paid order ' .. orderId .. ' for ' .. restaurantData.label)
    end
    return true
end)

lib.callback.register('mt_restaurants:server:updateOrderState', function(source, orderId, newState)
    local src = source
    local orderData = nil
    local restaurantId = nil

    for restId, restaurantOrders in pairs(orders) do
        if restaurantOrders[orderId] then
            orderData = restaurantOrders[orderId]
            restaurantId = tostring(restId)
            break
        end
    end

    if not orderData then return false end

    local job = bridge.getPlayerJob(src)
    local authorized = false
    local restaurants = utils.getRestaurants()
    for _, rest in pairs(restaurants) do
        if job and tostring(rest.id) == restaurantId and rest.job == job.name then
            authorized = true
            break
        end
    end
    if not authorized and not bridge.isAdmin(src) then return false end

    if newState == 'delivered' then
        local stashId = restaurantId .. '_order_stash_' .. orderId
        local stashItems = utils.getInventoryItems(stashId, false)
        
        for _, orderedItem in pairs(orderData.items) do
            local foundQuantity = 0
            if stashItems then
                for _, stashItem in pairs(stashItems) do
                    if orderedItem.isCustomCraft or (type(orderedItem.recipeId) == 'string' and orderedItem.recipeId:sub(1, 3) == 'cc_') then
                        if stashItem.name == orderedItem.itemName then
                            foundQuantity = foundQuantity + stashItem.count
                        elseif stashItem.name == 'restaurant_box' and stashItem.metadata and stashItem.metadata.boxId then
                            local boxItems = utils.getInventoryItems(stashItem.metadata.boxId, false)
                            if boxItems then
                                for _, boxItem in pairs(boxItems) do
                                    if boxItem.name == orderedItem.itemName then
                                        foundQuantity = foundQuantity + boxItem.count
                                    end
                                end
                            end
                        end
                    else
                        if stashItem.name == 'restaurant_food' and stashItem.metadata and stashItem.metadata.recipe == orderedItem.recipeId then
                            foundQuantity = foundQuantity + stashItem.count
                        elseif stashItem.name == 'restaurant_box' and stashItem.metadata and stashItem.metadata.boxId then
                            local boxItems = utils.getInventoryItems(stashItem.metadata.boxId, false)
                            if boxItems then
                                for _, boxItem in pairs(boxItems) do
                                    if boxItem.name == 'restaurant_food' and boxItem.metadata and boxItem.metadata.recipe == orderedItem.recipeId then
                                        foundQuantity = foundQuantity + boxItem.count
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            if foundQuantity < orderedItem.quantity then
                TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.noDeliverItems'), 'error')
                return false
            end
        end

        local restaurants = utils.getRestaurants()
        local restaurantData = nil
        for _, restaurant in pairs(restaurants) do
            if tostring(restaurant.id) == restaurantId then
                restaurantData = restaurant
                break
            end
        end

        if restaurantData then
            local simplifiedOrderData = {
                id = orderData.id,
                restaurantId = orderData.restaurantId,
                total = orderData.total,
                totalQuantity = orderData.totalQuantity,
                customerName = orderData.customerName,
                citizenId = orderData.citizenId,
                creatorName = orderData.creatorName,
                creatorCitizenId = orderData.creatorCitizenId,
                orderType = orderData.orderType or 'pos',
                state = 'delivered'
            }

            MySQL.insert('INSERT INTO restaurants_orders (restaurant, orderData, status, orderType, createdAt, updatedAt) VALUES (?, ?, ?, ?, NOW(), NOW())', {
                restaurantId,
                json.encode(simplifiedOrderData),
                'delivered',
                orderData.orderType or 'pos'
            })

            if orderData.orderType == 'self_ordering' then
                local commissionAmount = math.floor(orderData.total * config.commissions.pos)
                if commissionAmount > 0 then
                    bridge.removeAccountMoney(restaurantData.job, commissionAmount)
                    bridge.addMoney(src, commissionAmount)
                end
            end

            if orderData.orderType == 'drive_thru' or orderData.orderType == 'foodtruck' then
                 local failedItems = false
                 for _, item in pairs(stashItems) do
                     local added = utils.addItem(tonumber(orderData.playerId), item.name, item.count, item.metadata)
                     if added then
                        utils.removeItem(stashId, item.name, item.count, nil, item.metadata)
                     else
                        failedItems = true
                     end
                 end

                 if failedItems then
                    TriggerClientEvent('mt_restaurants:client:notify', src, locale('error.inventoryFull'), 'error')
                 else
                    TriggerClientEvent('mt_restaurants:client:notify', tonumber(orderData.playerId), locale('success.orderReceived'), 'success')
                 end
            elseif orderData.orderType == 'npc_order' then
                 for _, item in pairs(stashItems) do
                     utils.removeItem(stashId, item.name, item.count, nil, item.metadata)
                 end
                 local commissionAmount = math.floor(orderData.total * config.commissions.pos)
                 local restaurantAmount = orderData.total - commissionAmount
                 if commissionAmount > 0 then
                     bridge.addMoney(src, commissionAmount)
                     TriggerClientEvent('mt_restaurants:client:notify', src, locale('success.receivedCommission', commissionAmount, orderData.id) or ('Received $'..commissionAmount..' commission!'))
                 end
                 bridge.addAccountMoney(restaurantData.job, restaurantAmount)
                 TriggerClientEvent('mt_restaurants:client:npcOrderDelivered', -1, orderData.restaurantId, orderData.npcIndex, orderData.id)
                 TriggerEvent('mt_restaurants:server:npcOrderCompleted', orderData.restaurantId, orderData.npcIndex)
            else
                TriggerClientEvent('mt_restaurants:client:orderDelivered', tonumber(orderData.playerId), orderData, restaurantData)
            end
        end
    end

    if newState == 'cancelled' then
        if orderData.orderType == 'npc_order' then
            TriggerEvent('mt_restaurants:server:npcOrderCompleted', orderData.restaurantId, orderData.npcIndex)
        end
        local paidStates = { paid = true, preparing = true, prepared = true }
        if paidStates[orderData.state] then
            local targetJob = getJobByRestaurantId(restaurantId)
            if targetJob then
                local commission = config.commissions.pos
                if orderData.orderType == 'self_ordering' then
                    commission = 0
                end
                
                local commissionAmount = math.floor(orderData.total * commission)
                local restaurantAmount = orderData.total - commissionAmount

                if commissionAmount > 0 and orderData.creatorId and (orderData.orderType == 'pos' or orderData.orderType == 'drive_thru' or orderData.orderType == 'foodtruck') then
                    local removed = bridge.removeMoney(orderData.creatorId, commissionAmount, 'cash')
                    if removed then
                        TriggerClientEvent('mt_restaurants:client:notify', orderData.creatorId, locale('info.commissionRemoved', commissionAmount, orderId), 'inform')
                    end
                end

                bridge.removeAccountMoney(targetJob, restaurantAmount)
                if orderData.orderType ~= 'npc_order' then
                    bridge.addMoney(tonumber(orderData.playerId), orderData.total)
                    TriggerClientEvent('mt_restaurants:client:notify', tonumber(orderData.playerId), locale('success.orderRefunded', orderData.total) or string.format("Your order #%s was cancelled and you were refunded $%s.", orderId, orderData.total), 'success')
                end
            end
        end
    end

    orderData.state = newState
    orders[restaurantId][orderId] = orderData

    local targetJob = getJobByRestaurantId(restaurantId)
    if targetJob then
        local staff = utils.getStaffOnDuty(targetJob)
        for _, staffId in pairs(staff) do
            TriggerClientEvent('mt_restaurants:client:updateActiveOrders', staffId, orderData)
        end
    end

    return true
end)

lib.callback.register('mt_restaurants:server:isOrderStashEmpty', function(source, orderId, restaurantId)
    local stashId = tostring(restaurantId) .. '_order_stash_' .. orderId
    local items = utils.getInventoryItems(stashId, false)
    return not items or #items == 0
end)

RegisterNetEvent('mt_restaurants:server:openOrderStash', function(restaurantId, orderId)
    local src = source
    local job = bridge.getPlayerJob(src)
    local restaurants = utils.getRestaurants()
    local restIdStr = tostring(restaurantId)

    local now = os.time()
    if cooldown[src] and now - cooldown[src] < 3 then return false end
    cooldown[src] = now

    local restaurantData = nil
    for _, restaurant in pairs(restaurants) do
        if tostring(restaurant.id) == restIdStr then
            restaurantData = restaurant
            break
        end
    end

    if not restaurantData then return end

    if not orders[restIdStr] or not orders[restIdStr][orderId] then return end
    if tonumber(orders[restIdStr][orderId].playerId) ~= src and (not job or restaurantData.job ~= job.name) then return end

    local stashId = restIdStr .. '_order_stash_' .. orderId
    utils.openInventory(src, 'stash', stashId)
end)

bridge.onDutyUpdate(function(src, onDuty, jobName)
    if onDuty then
        local activeOrdersList = {}
        local restaurants = utils.getRestaurants()
        for restId, restaurantOrders in pairs(orders) do
            local isStaff = false
            for _, rest in pairs(restaurants) do
                if tostring(rest.id) == tostring(restId) and rest.job == jobName then
                    isStaff = true
                    break
                end
            end

            if isStaff then
                for orderId, orderData in pairs(restaurantOrders) do
                    local activeStates = { paid = true, preparing = true, prepared = true }
                    if activeStates[orderData.state] then
                        table.insert(activeOrdersList, orderData)
                    end
                end
            end
        end

        for _, orderData in pairs(activeOrdersList) do
            TriggerClientEvent('mt_restaurants:client:updateActiveOrders', src, orderData)
        end
    end
end)
