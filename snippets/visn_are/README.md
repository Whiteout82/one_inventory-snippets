# How to use visn_are with one_inventory

Use this snippet to connect **visn_are** to **one_inventory**.

## 1) Set inventory type in server config

Open:

`visn_are/script/configuration/server_config.lua`

Set:

`m_customInventory.inventory_type = "one_inventory"`

## 2) Replace helper files

Copy the snippet helper files into:

`visn_are/script/helpers/`

Replace existing files when prompted.

## 3) Restart resources

Restart your server (or restart **one_inventory** and **visn_are**).

## 4) Verify integration

Check console for helper/export errors and test inventory interactions in-game.

If there are no errors, **visn_are** is now using **one_inventory**.

script by **veryinsanee**: https://store.veryinsanee.space/
