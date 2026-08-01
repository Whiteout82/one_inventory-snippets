# How to use vms_housing with one_inventory

Use this snippet to connect **vms_housing** to **one_inventory**.

## 1) Copy inventory integration folder

From this repository, copy the folder:

`snippets/vms_housing/one_inventory/`

Into your **vms_housing** resource at:

`vms_housing/integration/[inventory]/`

## 2) Enable one_inventory in integration config

Open:

`vms_housing/config.integrations.lua`

Add **one_inventory** to `DetectActiveInventory`.

## 3) Restart resources

Restart your server (or restart **one_inventory** and **vms_housing**).

## 4) Verify integration

Check console for integration/export errors and test housing inventory interactions.

If there are no errors, **vms_housing** is now using **one_inventory**.

script by **vames**: https://www.vames-store.com/
