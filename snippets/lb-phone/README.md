# How to use lb-phone with one_inventory

Use this snippet to connect **lb-phone** to **one_inventory**.

## 1) Add unique phone handlers

Copy the snippet files into these resource folders:

- `lb-phone/client/custom/uniquePhones/`
- `lb-phone/server/custom/uniquePhones/`

## 2) Replace framework integration files

Copy the snippet framework files into:

- `lb-phone/client/custom/frameworks/`
- `lb-phone/server/custom/frameworks/`

Replace existing files when prompted.

## 3) Set inventory config

In your lb-phone config, set:

- `Config.Item.Inventory = "one_inventory"`
- `Config.Item.Require = true`

## 4) Restart resources

Restart your server (or restart **one_inventory** and **lb-phone**).

## 5) Verify integration

Check console for framework/export errors and test phone item behavior in-game.

If there are no errors, **lb-phone** is now using **one_inventory**.

script by **lbscripts**: https://lbscripts.com/
