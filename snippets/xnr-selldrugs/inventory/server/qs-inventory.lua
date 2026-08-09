if GetResourceState('qs-inventory'):find('missing') then return end

Inventory = {
    getItemCount = function(playerId, itemName)
        return exports['qs-inventory']:GetItemTotalAmount(playerId, itemName)
    end,
    addPlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        exports['qs-inventory']:AddItem(playerId, itemName, itemCount, slot, metadata)
    end,
    removePlayerItem = function(playerId, itemName, itemCount, metadata, slot)
        exports['qs-inventory']:RemoveItem(playerId, itemName, itemCount, slot, metadata)
    end,
    getInventoryItems = function(playerId)
        local items = exports['qs-inventory']:GetInventory(playerId) or {}
        for i = 1, #items, 1 do
            if items[i] and items[i].info then
                items[i].metadata = items[i].info
            end
        end
        return items
    end,
    clearInventory = function(inventory, keep)
        exports['qs-inventory']:ClearInventory(inventory)
    end,
    getItemSlot = function(playerId, slot)
        local itemSlot = nil
        local inventory = exports['qs-inventory']:GetInventory(playerId)
        for k, v in pairs(inventory) do
            if v.slot == slot then
                itemSlot = v
                break
            end
        end

        return itemSlot
    end,
}

RegisterNetEvent('xnr-selldrugs/inventory/registerStash', function(stashId, slots, weight)
    exports['qs-inventory']:RegisterStash(source, stashId, slots, weight)
end)

RegisterNetEvent('xnr-selldrugs/inventory/removeItem', function(itemName, itemCount)
    Inventory.removePlayerItem(source, itemName, itemCount)
end)
