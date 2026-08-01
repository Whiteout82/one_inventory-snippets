# How to use okokShop with one_inventory

Use this snippet to connect **okokShop** to **one_inventory**.

## 1) Replace utility file

Copy this file from the snippet:

`snippets/okokShop/sv_utils.lua`

To your resource path:

`okokShop/sv_utils.lua`

Replace existing file when prompted.

## 2) Update image path in config

Open:

`okokShop/config.lua`

Set the image path directory to:

`one_inventory/web/images`

## 3) Restart resources

Restart your server (or restart **one_inventory** and **okokShop**).

## 4) Verify integration

Check console for utility/export errors and test shop purchases in-game.

If there are no errors, **okokShop** is now using **one_inventory**.

script by **okokscripts**: https://okok.tebex.io/
