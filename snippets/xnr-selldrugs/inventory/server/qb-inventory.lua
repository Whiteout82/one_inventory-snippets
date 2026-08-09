if GetResourceState('qb-inventory'):find('missing') then return end

local QBCore = exports['qb-core']:GetCoreObject()
Inventory = {
    getItemCount = function(playerId, itemName)
        return exports['qb-inventory']:GetItemCount(playerId, itemName)
    end,
    addPlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        return exports['qb-inventory']:AddItem(playerId, itemName, itemCount, slot, metadata)
    end,
    removePlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        return exports['qb-inventory']:RemoveItem(playerId, itemName, itemCount, slot, metadata)
    end,
    getInventoryItems = function(playerId)
        local Player = QBCore.Functions.GetPlayer(playerId)
        local items = Player.PlayerData.items
        for i = 1, #items do
            if items[i] and items[i].metadata then
                items[i].metadata = items[i].info
            end
        end
        return Player.PlayerData.items
    end,
    getItemSlot = function(playerId, slot)
        local itemSlot = exports['qb-inventory']:GetItemBySlot(playerId, slot)
        itemSlot.metadata = itemSlot.info
        return itemSlot
    end,
}

lib.callback.register('xnr-selldrugs/inventory/getItemCount', function(source, itemName)
    return Inventory.getItemCount(source, itemName)
end)

RegisterNetEvent('xnr-selldrugs/inventory/openInventory', function(invType, data)
    exports['qb-inventory']:OpenInventory(source, data)
end)