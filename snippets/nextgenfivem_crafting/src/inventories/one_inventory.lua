local function init()
    while GetResourceState('one_inventory') ~= 'started' do
        Wait(100)
    end

    if FW.name == 'esx' or FW.name == 'esx-legacy' then
        ESX = ESX or exports['es_extended']:getSharedObject()

        ESX.RegisterUsableItem(PortableBenchOptions.item, function(src, name, item)
            TriggerEvent('nextgenfivem_crafting:usePortableBench', src, {
                item = item.name,
                slot = item.slot,
            })

            return true
        end)
    elseif FW.name == 'qbcore' then
        QBCore = QBCore or exports['qb-core']:GetCoreObject()

        QBCore.Functions.CreateUseableItem(PortableBenchOptions.item, function(src, item)
            TriggerEvent('nextgenfivem_crafting:usePortableBench', src, {
                item = item.name,
                slot = item.slot,
            })

            return true
        end)
    elseif FW.name == 'qbox' then
        exports.qbx_core:CreateUseableItem(PortableBenchOptions.item, function(src, item)
            TriggerEvent('nextgenfivem_crafting:usePortableBench', src, {
                item = item.name,
                slot = item.slot,
            })

            return true
        end)
    elseif FW.name == 'oxcore' then
        exports(PortableBenchOptions.item, function(event, item, inventory, slot, data)
            if event == 'usedItem' then
                TriggerEvent('nextgenfivem_crafting:usePortableBench', inventory.id, {
                    item = item,
                    slot = slot,
                })
            end
        end)
    else
        Log.error('Unsupported framework for one_inventory')
    end

    -- For One Inventory, we need to use RegisterItemButton for useable items
    exports.one_inventory:RegisterItemButton(PortableBenchOptions.item, 'Use', function(payload)
        local src = payload.source
        TriggerEvent('nextgenfivem_crafting:usePortableBench', src, {
            item = payload.item,
            slot = payload.slot,
        })
    end)

    -- Check for custom-named portable benches with benchType metadata
    RegisterNetEvent('one_inventory:itemUsed', function(src, name, slot, metadata)
        if name == PortableBenchOptions.item then return end

        if metadata and metadata.benchType then
            TriggerEvent('nextgenfivem_crafting:usePortableBench', src, {
                item = name,
                slot = slot,
            })
            return
        end

        local format = PortableBenchOptions.format or '%s_crafting_bench'
        local pattern = format:gsub('%%s', '.*')
        if name:match(pattern) or string.endsWith(name, '_' .. PortableBenchOptions.item) then
            TriggerEvent('nextgenfivem_crafting:usePortableBench', src, {
                item = name,
                slot = slot,
            })
        end
    end)
end

local items = nil

local function getItems()
    if not items then
        items = {}

        local oneItems = exports.one_inventory:GetAllItemDefinitions()
        if oneItems then
            for k, v in pairs(oneItems) do
                if k and v and type(v) == "table" then
                    local label = v.label or k
                    local description = v.description or ""
                    local weight = v.weight or 0
                    local image = v.image or (k .. ".png")
                    local unique = v.unique or false

                    table.insert(items, {
                        name = k,
                        label = label,
                        description = description,
                        weight = weight,
                        image = (image:match('^%w+://') and image) or ('nui://one_inventory/web/images/' .. image),
                        unique = unique
                    })
                else
                    Log.error('Invalid item data in one_inventory: ' .. k, v)
                end
            end
        else
            Log.error('Failed to retrieve items from one_inventory')
        end
    end

    return items
end

local function getPlayerItemsCount(src)
    local items = exports.one_inventory:GetInventoryItems(src)

    if not items then
        return false
    end

    local result = {}

    for _, v in pairs(items) do
        if not result[v.name] then
            result[v.name] = v.count
        else
            result[v.name] = result[v.name] + v.count
        end
    end

    return result
end

local function getPlayerInventory(src)
    local inventory = exports.one_inventory:GetInventory(src)

    if not inventory then
        return false
    end

    local items = {}

    for _, v in pairs(inventory.slots or {}) do
        table.insert(items, {
            item = v.name,
            slot = v.slot,
            quantity = v.count,
            metadata = v.metadata,
        })
    end

    return items
end

local function addPlayerItem(src, item, amount, metadata, options)
    if options then
        metadata = metadata or {}

        if options.description then
            metadata.description = options.description
        end

        if options.label then
            metadata.label = options.label
        end
    end

    -- Check if player can carry the item
    if not exports.one_inventory:CanCarryItem(src, item, amount) then
        return false
    end

    -- Check if item is unique and we need to add one by one
    local itemDef = exports.one_inventory:GetItemDefinition(item)
    if amount > 1 and itemDef and itemDef.unique then
        for i = 1, amount do
            if not exports.one_inventory:AddItem(src, item, 1, metadata) then
                return false
            end
        end
        return true
    end

    return exports.one_inventory:AddItem(src, item, amount, metadata)
end

local function removePlayerItem(src, item, amount)
    -- Check if player has enough of the item
    local count = exports.one_inventory:GetItemCount(src, item) or 0
    if count < amount then
        return false
    end

    return exports.one_inventory:RemoveItem(src, item, amount)
end

local function getSpecificPlayerItem(src, data)
    local slot = exports.one_inventory:GetSlot(src, data.slot)

    if slot then
        return {
            item = slot.name,
            metadata = slot.metadata,
        }
    end

    return false
end

local function removeSpecificPlayerItem(src, data, amount)
    return exports.one_inventory:RemoveItem(src, data.item, amount, nil, data.slot)
end

local function setMetadata(src, data, metadata)
    exports.one_inventory:SetItemMetadata(src, data.slot, metadata)
    return true
end

local function canCarryItems(src, items)
    local totalWeight = 0

    for _, v in pairs(items) do
        local name, amount = v.name, v.amount or 1

        local itemDef = exports.one_inventory:GetItemDefinition(name)
        if itemDef then
            totalWeight = totalWeight + (itemDef.weight or 0) * amount
        end
    end

    return exports.one_inventory:CanCarryWeight(src, totalWeight)
end

local function getItemDefinition(item)
    return exports.one_inventory:GetItemDefinition(item)
end

local function searchInventory(src, searchType, item, metadata)
    return exports.one_inventory:SearchInventory(src, searchType, item, metadata)
end

local function getSlot(src, slot)
    return exports.one_inventory:GetSlot(src, slot)
end

local function getSlotsWithItem(src, item, metadata)
    return exports.one_inventory:GetSlotsWithItem(src, item, metadata)
end

return {
    init = init,
    getItems = getItems,
    getPlayerItemsCount = getPlayerItemsCount,
    getPlayerInventory = getPlayerInventory,
    addPlayerItem = addPlayerItem,
    removePlayerItem = removePlayerItem,
    getSpecificPlayerItem = getSpecificPlayerItem,
    removeSpecificPlayerItem = removeSpecificPlayerItem,
    setMetadata = setMetadata,
    canCarryItems = canCarryItems,
    getItemDefinition = getItemDefinition,
    searchInventory = searchInventory,
    getSlot = getSlot,
    getSlotsWithItem = getSlotsWithItem,
}