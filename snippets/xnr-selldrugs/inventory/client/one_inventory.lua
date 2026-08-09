if GetResourceState('one_inventory'):find('missing') then return end

Inventory = {
    openInventory = function(invType, data)
        return exports.one_inventory:OpenInventory(invType, data)
    end,
    getItemCount = function(itemName)
        return exports.one_inventory:GetItemCount(itemName)
    end,
}
