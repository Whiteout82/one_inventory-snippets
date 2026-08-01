# How to use mt_restaurants with one_inventory

Use this snippet to connect **mt_restaurants** to **one_inventory**.

## 1) Copy the bridge files

From this repository, open:

`snippets/mt_restaurants/modules/bridge/`

Copy the full contents of that folder into your **mt_restaurants** resource at:

`modules/bridge/`

Replace existing files when prompted.

## 2) Make sure dependencies are running

Before starting **mt_restaurants**, make sure these resources are started:

- **one_inventory**
- Your framework (**es_extended**, **qb-core**, or **qbx_core**)

The bridge auto-detects your framework and loads the correct implementation.

## 3) Restart resources

Restart your server (or at minimum restart these resources in order):

1. **one_inventory**
2. Your framework
3. **mt_restaurants**

## 4) Verify integration

Check server/client console for bridge or export errors.

If there are no errors and inventory actions work in-game, **mt_restaurants** is now using **one_inventory**.
