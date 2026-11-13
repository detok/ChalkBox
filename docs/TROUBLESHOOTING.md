# Troubleshooting

## 2.0.2: Settings navigation or Combat Meter

**Nested pages:** Open Options → AddOns → ChalkBox. Select a module (for example, The Bar), then select its nested Modules or Appearance page. The home page has shortcuts to the primary modules. Saved options have not been reset or renamed.

**DPS meter starts closed:** This is intentional. Use /chalk meter show or the Combat Meter settings page to open it. Hiding it doesn't reset Blizzard's recorded sessions.

**Settings page won't open:** Try /chalk, then the parent page. Some Forever Settings builds do not automatically expand the parent when a nested page is opened directly; ChalkBox now opens its parent first.

**CurseForge file confusion:** The playable file is ChalkBox-2.0.2.zip. ChalkBox-CurseForge-Media-2.0.2.zip contains artwork and listing copy; it is not an installable addon.


These steps are safe and require no SavedVariables deletion or client reset.

## 2.0.1 — Discoveries button is visible, but the window or position isn't right

Open Discoveries and use the **Area/Dungeon**, **Creature Source**, and **Sort By** dropdowns. Use search to narrow results. To move the **map button**, click and drag it to a comfortable location; ChalkBox saves that position per character. **Right-click to reset**, or click **Reset Map Button** under DropSense settings, or run `/chalk drops map reset`.

If a dropdown appears underneath Blizzard's map or clips at a particular UI scale, send the exact Forever client build, UI scale and a real screenshot. The original standalone **/chalk drops map** remains available.

**Missing item rate?** A percentage is only calculated from readable loot windows attributed to a **known specific creature**. Without that denominator, ChalkBox displays actual items/quantities instead of a fake zone-wide probability.

## Updates button doesn't show a GitHub version

WoW addon Lua cannot make HTTPS requests. `/chalk update` prints the *installed* version and the GitHub Releases link for your browser. The optional, default-off peer comparison can only tell whether a grouped ChalkBox user has a newer version; it **isn't a server check**. To get real automatic update downloads, use a compatible addon manager once ChalkBox has a verified listing.

## 2.0 — Discoveries button doesn't appear on the world map

The 2.0 prerelease fixes a **Forever-specific late-loading map-frame and placement issue**. Try this sequence:

1. Open WoW's regular world map once. Look near the **upper-left map canvas**, below the native map pin controls.
2. Open **Options → AddOns → ChalkBox → DropSense**. Ensure **Show Discoveries button on World Map** is checked. This toggle does not control whether loot sampling is recording.
3. Type **/chalk drops map**. This opens the same **standalone Discoveries browser** even if the map button couldn't attach. The browser can use your current player zone when the map is not loaded.
4. Type **/chalk drops map status**. Copy both status lines: whether `WorldMapFrame` exists, whether the button attached, whether it is shown, the saved toggle, the anchor type, the selected map ID and tracking status.
5. If a map skin such as Leatrix Maps or Simple Map is running, try windowed and fullscreen map modes. Record **the names of your other map addons** rather than deleting all preferences.
6. Include a **real screenshot** of the whole map and the status output with your Forever client build when [reporting an issue](https://github.com/detok/ChalkBox/issues/new/choose).

**Map button invisible is different from an empty loot journal.** The journal only shows loot **recorded after zone-aware tracking was enabled**. Older records cannot gain invented locations. Type **/chalk drops status** to check recording and sampled area counts. The game cannot expose every kill or official server loot-table rate.

## 2.0 — MacroForge shows no spells or generated macro won't work

1. Type **/chalk macro**; if the window opens but your abilities are absent, open your native spellbook and click **Rescan** or use **/chalk forge rescan**.
2. Check **/chalk forge status** for the current class and number of readable active spells.
3. If you respecced, load a saved recipe and replace any explicitly flagged **unlearned spell**; MacroForge does not make old spell IDs magically castable.
4. The native Blizzard macro engine won't cast multiple global-cooldown spells on one press. **/castsequence** advances on successful casts and can stall. Trinket slots 13/14 may be passive or cooling down.
5. Click **Select Text**, press **Ctrl+C**, paste into the normal **/macro** interface. Only use **Install New** outside combat when you explicitly want a new character-specific macro; it won't overwrite an existing name.
6. Report client build, chosen template, selected spells, generated macro, displayed warning/error and expected result. Do not share private macros containing secrets or personal account details.

## QuestSense doesn't show any quests

1. Make sure **QuestSense → Auto-track accepted quests** is enabled. Start with **Smart (recommended)**; **Nearby only** intentionally excludes quests without matching map or zone data.
2. Close your **world map and quest log**, and exit combat. Editing watches while those windows are open can create taint or fail silently on Forever.
3. Type `/chalk quests status`. You'll see accepted quests, eligible candidates, native watch count, ChalkBox-owned watch count and whether an API is missing or an update was deferred.
4. Run `/chalk quests refresh` and look at `/chalk quests status` again. If a quest was just accepted, it should be picked up even when its map objectives aren't exposed.
5. Check whether another UI addon has **hidden Blizzard's native tracker**. QuestSense manages native quest watches; it does not force a different quest-tracker window on-screen.
6. If still broken, send the entire status output and your WoW Forever build number. That distinguishes a data-read problem, a blocked watch write, a watch limit, and a tracker-display problem.

## Adventure Prep toast is in the wrong place

Under **Adventure Prep → Toast Appearance**, uncheck Lock, click **Preview / Move (25s)**, drag the visible toast, then recheck Lock. Use the transparency slider (35–100%). **Reset to Top** restores the default. Locked toasts don't intercept mouse clicks; normal reminders last nine seconds.

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

## Class icons don't appear, or all players show the same icon

Under **Options → AddOns → ChalkBox → Combat Meter**, choose **Class** (the default). The source class must be supplied by Blizzard's native `C_DamageMeter.classFilename` data. If no class is supplied, ChalkBox deliberately shows a neutral question mark.

**Spec** uses Blizzard's `specIconID` when available; otherwise it falls back to the correct class. For traditional class emblems try `/chalk meter icons class`. If the icons aren't wanted, `/chalk meter icons off` returns the name column to its original width.

If an emblem looks wrong, report the **ChalkBox version, Forever client build, visible player class, and a screenshot**. Do not assume icons can identify every pet or unclassified damage source.

## Combat Meter is empty or not displaying

1. Type **`/chalk meter show`** or use **Options → AddOns → ChalkBox → Combat Meter → Show compact DPS meter window**.
2. Type **`/chalk meter status`**. It checks whether your client exposes Blizzard's native `C_DamageMeter`. This feature does **not** use the restricted combat log.
3. Attack a target and let the built-in damage recording register a fight. Try the **DPS >** title button, or `/chalk meter dps`.
4. Click **Fight >** to switch between current fight, last fight and overall data. If your current fight is empty, Last may contain the previous pull.
5. If the game has its own meter visible, that is expected. ChalkBox does not disable it; use Blizzard's UI settings to hide the duplicate.
6. If entries fail during combat but appear afterward, report your Forever client build and any Lua error. Combat values are protected and ChalkBox never calculates their contents in Lua.

To return to its default position: **`/chalk meter position reset`**. A hidden window doesn't update and adds no permanent meter polling.

## My Camp Tent worked but ChalkBox still says no Camp Benefits

This is normal: the **Camp Tent** tops up **Rested XP**, while **Camp Benefits** represents separate stat buffs. Run **`/chalk prep`** to see two different results: **Camp Benefits** (stat buffs) and **Camp Tent** (Boosted Rest lockout or rested-XP threshold). Boosted Rest is a **harmful debuff**, spell **1229451**, lasting about an hour. If it is active, ChalkBox should not prompt you to use a tent again.

If your client hides the debuff or rested-XP API, ChalkBox reports tent state **unknown**. Click **Tent Used** in Adventure Prep or type `/chalk prep tent done` to acknowledge tent use for one hour in this session; `/chalk prep tent clear` reverses it.

## Combat Meter will not print my fight

- **PRINT** sends **one short top-three ranking to normal PARTY chat** when clicked. It never sends automatically or broadcasts to RAID/SAY.
- You must be in a normal **party**, not solo or a raid, and click **after combat**. Forever may still mark results as protected until the game releases them.
- If **Fight** is empty, try **Last** in the window. The Print command also tries Last when current session has no data.
- `/chalk meter status` verifies the native meter is available.
- If the client still considers values secret or blocks party chat (e.g., in a restricted instance), ChalkBox refuses to send and shows a local diagnostic instead. Try `/chalk meter print` after combat and note the exact response.

## TrailBar overlays other UI

Run **`/chalk bar status`**. Try `/chalk bar reserve on`, change its top/bottom position, or `/chalk bar reserve off` if your custom UI needs the full viewport. Some addon or manually placed UI frames don't follow the screen reservation.

## Guild invite or duel blocked unexpectedly

Go to **Options → AddOns → ChalkBox → QuietGuard**. The guild/duel filters default to on. Temporarily disable these if you expect an invitation. Party and trade blocking are off by default.

## Emota isn't doing anything

Enable **automatic character reactions** in Options → Emota. It is **opt-in**, uses long randomized gaps, and avoids interruptions while moving or fighting. Try **`/chalk emota idle preview`** to force a manual preview. Avoid running the old standalone EmotaSpeak at the same time.

## Reporting a helpful bug

Use the [bug report form](https://github.com/detok/ChalkBox/issues/new/choose). Include:
- ChalkBox version (e.g. `2.0.0`)
- Game name, game client build and interface version
- Which module, exact command or item link
- Expected behavior vs actual behavior
- Any Lua error and reproduction steps

Never post personal account credentials, session tokens or private chat messages in a public issue.
