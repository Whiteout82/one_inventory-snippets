if GetResourceState('tgiann-inventory'):find('missing') then return end

Inventory = {
    getItemCount = function(playerId, itemName)
        return exports['tgiann-inventory']:GetItemCount(playerId, itemName)
    end,
    addPlayerItem = function(playerId, itemName, itemCount, metadata)
        exports['tgiann-inventory']:AddItem(playerId, itemName, itemCount, nil, metadata)
    end,
    removePlayerItem = function(playerId, itemName, itemCount, metadata)
        exports['tgiann-inventory']:RemoveItem(playerId, itemName, itemCount, nil, metadata)
    end,
    getInventoryItems = function(playerId)
        return exports["tgiann-inventory"]:GetPlayerItems(playerId)
    end,
    getItemSlot = function(playerId, slot)
        local itemSlot = exports['tgiann-inventory']:GetItemBySlot(playerId, slot)
        return itemSlot
    end,
}

lib.callback.register('xnr-selldrugs/inventory/getItemCount', function(source, itemName)
    return Inventory.getItemCount(source, itemName)
end)

RegisterNetEvent('xnr-selldrugs/inventory/openInventory', function(invType, data)
    exports['tgiann-inventory']:OpenInventory(source, "stash", data)
end)