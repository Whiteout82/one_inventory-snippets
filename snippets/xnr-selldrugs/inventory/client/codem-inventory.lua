if GetResourceState('codem-inventory'):find('missing') then return end

Inventory = {
    openInventory = function(invType, data)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", data, {
            maxweight = 250000,
            slots = 100,
        })
    end,
    getItemCount = function(itemName)
        return lib.callback.await('xnr-selldrugs/inventory/getItemCount', false, itemName)
    end,
}