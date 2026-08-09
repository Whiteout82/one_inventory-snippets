if GetResourceState('jpr-inventory'):find('missing') then return end

Inventory = {
    openInventory = function(invType, data)
        TriggerServerEvent('xnr-selldrugs/inventory/openInventory', invType, data)
    end,
    getItemCount = function(itemName)
        return lib.callback.await('xnr-selldrugs/inventory/getItemCount', false, itemName)
    end,
}