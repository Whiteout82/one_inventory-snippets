# How to use kartik_mdtv2 with one_inventory

Use this snippet to connect **kartik_mdt v2** to **one_inventory**.

## 1) Copy client bridge file

Copy this file from the snippet:

`snippets/kartik_mdtv2/inventory/client/one_inventory.lua`

To your resource path:

`kartik-mdt/bridge/inventory/client/one_inventory.lua`

## 2) Copy server bridge file

Copy this file from the snippet:

`snippets/kartik_mdtv2/inventory/server/one_inventory.lua`

To your resource path:

`kartik-mdt/bridge/inventory/server/one_inventory.lua`

## 3) Restart resources

Restart **kartik_mdt** (or restart the full server).

## 4) Verify integration

Check console for bridge/export errors and test inventory interactions in MDT flows.

If there are no errors, **kartik_mdt v2** is now using **one_inventory**.

script by **kartik scripts**: https://kartik-scripts.tebex.io
