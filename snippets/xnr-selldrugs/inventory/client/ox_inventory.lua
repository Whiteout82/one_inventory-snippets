if GetResourceState('ox_inventory'):find('missing') then return end

Inventory = {
    openInventory = function(invType, data)
        exports['ox_inventory']:openInventory(invType, data)
    end,
    getItemCount = function(itemName)
        return exports['ox_inventory']:Search('count', itemName)
    end,
}