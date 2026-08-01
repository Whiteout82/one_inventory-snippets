# How to use rcore_prison with one_inventory

Use this snippet to connect **rcore_prison** to **one_inventory**.

## 1) Replace inventory items file

Copy this file from the snippet:

`snippets/rcore_prison/inventory_items.lua`

To your resource path:

`rcore_prison/inventory_items.lua`

## 2) Copy server inventory bridge file

Copy the snippet inventory bridge file into:

`rcore_prison/modules/bridge/server/inventory/`

Replace existing file when prompted.

## 3) Restart resources

Restart your server (or restart **one_inventory** and **rcore_prison**).

## 4) Verify integration

Check console for bridge/export errors and test prison inventory flows.

If there are no errors, **rcore_prison** is now using **one_inventory**.

script by **rcore**: https://store.rcore.cz/
