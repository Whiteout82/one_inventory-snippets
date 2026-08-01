# How to use luxu_admin with one_inventory

Use this snippet to connect **luxu_admin** to **one_inventory**.

## 1) Update inventory config

Open:

`luxu_admin/config/config.json`

Set inventory to **one_inventory** and disable auto-detect:

- `"auto_detect": false`
- `"name": "one_inventory"`
- `"images_url": "https://cfx-nui-one_inventory/web/images/%s.png"`

## 2) Replace bridge server files

Copy snippet files into:

- `luxu_admin/bridge/server/inventory.lua`
- `luxu_admin/bridge/server/player.lua`

## 3) Update shared inventory image mapping

Open:

`luxu_admin/bridge/shared/inventory.lua`

Ensure **one_inventory** exists in the `images` table with:

`https://cfx-nui-one_inventory/web/images/%s.png`

## 4) Restart resources

Restart your server (or restart **one_inventory** and **luxu_admin**).

## 5) Verify integration

Check console for bridge/export errors and test admin inventory features.

If there are no errors, **luxu_admin** is now using **one_inventory**.

script by **luxu**: https://luxu.gg/
