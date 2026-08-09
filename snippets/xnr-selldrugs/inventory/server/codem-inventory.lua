if GetResourceState('codem-inventory'):find('missing') then return end

local ESX, QBCore = nil, nil
if Config.Framework == 'ESX' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'QB' then
    QBCore = exports['qb-core']:GetCoreObject()
end

Inventory = {
    getItemCount = function(playerId, itemName)
        return exports['codem-inventory']:GetItemsTotalAmount(playerId, itemName)
    end,
    addPlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        exports['codem-inventory']:AddItem(playerId, itemName, itemCount, slot, metadata)
    end,
    removePlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        exports['codem-inventory']:RemoveItem(playerId, itemName, itemCount, slot, metadata) -- metadata = slot
    end,
    getInventoryItems = function(playerId)
        return exports['codem-inventory']:GetInventory(playerId)
    end,
    getItemSlot = function(playerId, slot)
        local itemSlot = exports['codem-inventory']:GetItemBySlot(playerId, slot)
        if itemSlot.info then
            itemSlot.metadata = itemSlot.info
        end
        return itemSlot
    end,
}

lib.callback.register('xnr-selldrugs/inventory/getItemCount', function(source, itemName)
    return Inventory.getItemCount(source, itemName)
end)