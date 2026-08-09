if GetResourceState('one_inventory'):find('missing') then return end

Inventory = {
    getItemCount = function(playerId, itemName)
        return exports.one_inventory:GetItemCount(playerId, itemName) or 0
    end,
    addPlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        return exports.one_inventory:AddItem(playerId, itemName, itemCount, metadata, slot)
    end,
    removePlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        return exports.one_inventory:RemoveItem(playerId, itemName, itemCount, metadata, slot)
    end,
    getInventoryItems = function(playerId)
        return exports.one_inventory:GetInventoryItems(playerId)
    end,
    clearInventory = function(inventory, keep)
        return exports.one_inventory:ClearInventory(inventory, keep)
    end,
    getItemSlot = function(playerId, slot)
        return exports.one_inventory:GetSlot(playerId, slot)
    end,
}

lib.callback.register('xnr-selldrugs/inventory/getItemCount', function(source, itemName)
    return Inventory.getItemCount(source, itemName)
end)
