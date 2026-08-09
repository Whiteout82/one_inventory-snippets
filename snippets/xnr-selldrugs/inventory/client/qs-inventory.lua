if GetResourceState('qs-inventory'):find('missing') then return end

Inventory = {
    openInventory = function(invType, data, items)
        TriggerServerEvent('xnr-selldrugs/inventory/registerStash', data, 50, 10000)
    end,
    getItemCount = function(itemName)
        return exports['qs-inventory']:Search(itemName)
    end,
}