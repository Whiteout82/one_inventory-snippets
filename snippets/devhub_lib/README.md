# How to use devhub_lib with one_inventory

Use this snippet to connect **devhub_lib** to **one_inventory**.

## 1) Copy inventory bridge folder

From this repository, copy the folder:

`snippets/devhub_lib/one_inventory/`

Into your **devhub_lib** resource at:

`devhub_lib/modules/inventories/`

## 2) Replace auto-detect file

Copy this file from the snippet:

`snippets/devhub_lib/core/shared/auto_detect.lua`

To your resource path:

`devhub_lib/core/shared/autoDetect.lua`

## 3) Restart resources

Restart your server (or restart **one_inventory** and **devhub_lib**).

## 4) Verify integration

Check console for bridge/export errors and test inventory-related features.

If there are no errors, **devhub_lib** is now using **one_inventory**.

script by **devhub_lib**: https://devhub.gg/
