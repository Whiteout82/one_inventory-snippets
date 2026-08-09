if GetResourceState('ox_inventory'):find('missing') then return end

Inventory = {
    getItemCount = function(playerId, itemName)
        return exports['ox_inventory']:Search(playerId, 'count', itemName)
    end,
    addPlayerItem = function(playerId, itemName, itemCount, metadata)
        exports['ox_inventory']:AddItem(playerId, itemName, itemCount, metadata)
    end,
    removePlayerItem = function(playerId, itemName, itemCount, metadata)
        return exports['ox_inventory']:RemoveItem(playerId, itemName, itemCount, metadata)
    end,
    getInventoryItems = function(playerId)
        return exports['ox_inventory']:GetInventoryItems(playerId)
    end,
    getItemSlot = function(playerId, slot)
        return exports['ox_inventory']:GetSlot(playerId, slot)
    end,
}
