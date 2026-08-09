if GetResourceState('ps-inventory'):find('missing') then return end

local QBCore = exports['qb-core']:GetCoreObject()
Inventory = {
    getItemCount = function(playerId, itemName)
        local itemData = exports['ps-inventory']:GetItemByName(playerId, itemName)
        if itemData then
            return itemData.count
        end

        return 0
    end,
    addPlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        exports['ps-inventory']:AddItem(playerId, itemName, itemCount, slot, metadata)
    end,
    removePlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        exports['ps-inventory']:RemoveItem(playerId, itemName, itemCount, slot, metadata)
    end,
    getInventoryItems = function(playerId)
        local Player = QBCore.Functions.GetPlayer(playerId)
        local items = Player.PlayerData.items
        for i = 1, #items do
            items[i].metadata = items[i].info
        end
        return Player.PlayerData.items
    end,
    getItemSlot = function(playerId, slot)
        local itemSlot = exports['ps-inventory']:GetItemBySlot(playerId, slot)
        itemSlot.metadata = itemSlot.info
        return itemSlot
    end,
}

lib.callback.register('xnr-selldrugs/inventory/getItemCount', function(source, itemName)
    return Inventory.getItemCount(source, itemName)
end)

RegisterNetEvent('xnr-selldrugs/inventory/openInventory', function(invType, data)
    exports['ps-inventory']:OpenInventory(source, data)
end)
