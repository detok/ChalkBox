# Troubleshooting

These steps are safe and require no SavedVariables deletion or client reset.

## ChalkBox doesn't appear in the AddOns list

Confirm your game directory contains:

```text
Interface/
  AddOns/
    ChalkBox/
      ChalkBox.toc
      ChalkBox_Camelot.toc
      Core.lua
      ...additional modules...
      assets/Icon.tga
```

Do not leave an extra folder such as `ChalkBox-1.6.1/ChalkBox/` between `AddOns` and the addon. Download the **`ChalkBox-*.zip`** asset from Releases instead of GitHub's **Source code** ZIP. Check whether your Forever build has disabled older addons and record its interface version.

## I don't see a CampSense popup

- Type **`/chalk prep test`**. The preview should show immediately (unless client security/UI restrictions prevent it).
- Open **`/chalk` → Adventure Prep** and make sure periodic reminders and **Show reminders on screen** are enabled.
- Type **`/chalk prep`**. ChalkBox should report the camp buff as **active, missing, expiring, gathering**, or **unknown**. If the aura is already active, suppressing a camp reminder is intentional.
- Routine reminders have a delay; the test command is the fastest way to confirm placement. Combat can suppress normal alerts.
- If the client blocks aura reads, ChalkBox will report **unknown**, not falsely say you're missing a buff.

## LootSense doesn't mention a material I can craft with

1. Open that character's actual **crafting profession window** and wait for its recipes to populate. Forever can populate recipes after the panel first appears.
2. Run **`/chalk loot scan`**, move the pointer off the material, and hover it again; an already-open tooltip won't necessarily refresh by itself.
3. Run **`/chalk loot status`**. It shows whether LootSense advice is **ON**, the detected profession, how many learned recipes it saw in the latest scan, the scanning API used, and the bundled database status. If advice is OFF, type **`/chalk loot on`**.
4. Remember: **known** recipe claims require a successful scan. The bundled offline recipe catalog cannot claim you learned something; only your profession scan can.
5. If one known recipe is missing or the quantity is incorrect, report the exact **item link, recipe name, profession and skill level**. A screenshot of the game tooltip and profession window is very helpful.

A missing annotation doesn't mean an item is safe to sell. Keep important items manually with `/chalk keep [item]`.

## Combat Meter is empty or not displaying

1. Type **`/chalk meter show`** or use **Options → AddOns → ChalkBox → Combat Meter → Show compact DPS meter window**.
2. Type **`/chalk meter status`**. It checks whether your client exposes Blizzard's native `C_DamageMeter`. This feature does **not** use the restricted combat log.
3. Attack a target and let the built-in damage recording register a fight. Try the **DPS >** title button, or `/chalk meter dps`.
4. Click **Fight >** to switch between current fight, last fight and overall data. If your current fight is empty, Last may contain the previous pull.
5. If the game has its own meter visible, that is expected. ChalkBox does not disable it; use Blizzard's UI settings to hide the duplicate.
6. If entries fail during combat but appear afterward, report your Forever client build and any Lua error. Combat values are protected and ChalkBox never calculates their contents in Lua.

To return to its default position: **`/chalk meter position reset`**. A hidden window doesn't update and adds no permanent meter polling.

## TrailBar overlays other UI

Run **`/chalk bar status`**. Try `/chalk bar reserve on`, change its top/bottom position, or `/chalk bar reserve off` if your custom UI needs the full viewport. Some addon or manually placed UI frames don't follow the screen reservation.

## Guild invite or duel blocked unexpectedly

Go to **Options → AddOns → ChalkBox → QuietGuard**. The guild/duel filters default to on. Temporarily disable these if you expect an invitation. Party and trade blocking are off by default.

## Emota isn't doing anything

Enable **automatic character reactions** in Options → Emota. It is **opt-in**, uses long randomized gaps, and avoids interruptions while moving or fighting. Try **`/chalk emota idle preview`** to force a manual preview. Avoid running the old standalone EmotaSpeak at the same time.

## Reporting a helpful bug

Use the [bug report form](https://github.com/detok/ChalkBox/issues/new/choose). Include:
- ChalkBox version (e.g. `1.5.1`)
- Game name, game client build and interface version
- Which module, exact command or item link
- Expected behavior vs actual behavior
- Any Lua error and reproduction steps

Never post personal account credentials, session tokens or private chat messages in a public issue.
