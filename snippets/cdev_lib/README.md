# How to use cdev_lib with one_inventory

Use this snippet to connect **cdev_lib** to **one_inventory**.

## 1) Replace server API file

Copy this file from the snippet:

`snippets/cdev_lib/public/server/api.lua`

To your resource path:

`cdev_lib/public/server/api.lua`

## 2) Replace auto-detect file

Copy this file from the snippet:

`snippets/cdev_lib/shared/auto_detect.lua`

To your resource path:

`cdev_lib/shared/auto_detect.lua`

## 3) Restart resources

Restart your server (or restart **one_inventory** and **cdev_lib**).

## 4) Verify integration

Check console for API/bridge errors and test inventory-related features.

If there are no errors, **cdev_lib** is now using **one_inventory**.

script by **cDev**: https://fivem.cdev.shop/
