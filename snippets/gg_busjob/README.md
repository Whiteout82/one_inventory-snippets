# How to use gg_busjob with one_inventory

Use this snippet to connect **gg_busjob** to **one_inventory**.

## 1) Copy inventory bridge folder

From this repository, copy the folder:

`snippets/gg_busjob/one_inventory/`

Into your **gg_busjob** resource at:

`gg_busjob/core/bridge/inventory/`

## 2) Set inventory in config

Open:

`gg_busjob/utility.lua`

Set:

`inventory = 'one_inventory'`

## 3) Restart resources

Restart your server (or restart **one_inventory** and **gg_busjob**).

## 4) Verify integration

Check console for bridge/export errors and test inventory actions in-game.

If there are no errors, **gg_busjob** is now using **one_inventory**.

script by **ggstudio**: https://www.ggstudio.store/
