# How to use tk_policejob with one_inventory

Use this snippet to connect **tk_policejob** to **one_inventory**.

## 1) Replace client framework files

Copy snippet files into:

`tk_policejob/client/frameworks/`

Replace `esx.lua` and `qb.lua`.

## 2) Replace client main file

Copy snippet file into:

`tk_policejob/client/main_editable.lua`

## 3) Replace server framework files

Copy snippet files into:

`tk_policejob/server/frameworks/`

Replace `esx.lua` and `qb.lua`.

## 4) Replace server main file

Copy snippet file into:

`tk_policejob/server/main_editable.lua`

## 5) Check weapon name casing in config

Make sure weapon names match one_inventory item names (lowercase style), for example:

- `weapon_flashlight`
- not `WEAPON_FLASHLIGHT`

## 6) Restart resources

Restart your server (or restart **one_inventory** and **tk_policejob**).

## 7) Verify integration

Check console for framework/export errors and test police shop/stash behavior in-game.

If there are no errors, **tk_policejob** is now using **one_inventory**.

script by **tkscripts**: https://tkscripts.com/
