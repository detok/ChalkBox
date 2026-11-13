# ChalkBox 1.8.0 — QuestSense rebuild + top-screen toast controls

## QuestSense: rebuilt for WoW Forever

The earlier QuestSense could silently do nothing because it depended on current-map quest POIs or exact zone heading matches. Forever sometimes exposes **accepted quests and objectives but no usable map pins**. We've rewritten QuestSense around the live **`C_QuestLog.GetNumQuestLogEntries` / `C_QuestLog.GetInfo`** accepted-quest list, with `C_QuestLog.AddQuestWatch` and `RemoveQuestWatch` applied to Blizzard's **native tracker** only when safe.

**Three clear modes in Options → AddOns → ChalkBox → QuestSense:**
- **Smart (recommended, default):** Prioritizes newly accepted and current-zone quests when client map data exists, then fills remaining auto-watch slots from your accepted log. Even when map APIs are missing, this mode *still tracks quests*.
- **Nearby only:** Only tracks quests confirmed by an exact zone header or matching current-zone map POI. No unverified guesses.
- **All accepted:** Fills watch slots in quest-log order, regardless of location.

Pick how many **ChalkBox-managed watches** are allowed: **5, 10, 15, or 20** (default 10). This respects the game's native watch cap and never removes your manually tracked quests. If you untrack an auto-managed quest manually, it stays muted until you change zones or explicitly refresh.

**Safety and reliability:**
- No dependency on quest map pins to function in default Smart mode.
- Preserves manually watched quests, the selected/super-tracked quest, and any custom tracker you use.
- Defers **all watch-list edits during combat, while World Map or Quest Log is open, and during dangerous instance contexts**. Tries again after the window closes or when it's safe.
- Waits for quest-log data instead of wiping all watches if the log is briefly empty during login.
- Reacts to quest acceptance, turn-ins, quest-log updates, watch changes, zone changes and combat ending.
- Checks the actual watched quest IDs after every write rather than trusting the misleading `AddQuestWatch` return flag.
- **Tracking Diagnostics** and `/chalk quests status` report the current mode, zone, accepted count, candidates, watch count, auto-managed count, API readiness, and why an update was deferred or rejected. Refresh button is now **Refresh Quests**.
- Commands: `/chalk quests smart`, `zone`, `all`, `limit 5|10|15|20`, `on`, `off`, `refresh`, `status`.

**What it does not do:** invent objectives, quest coordinates, or turn-in directions. This is a dependable watcher for accepted quests, not a replacement for Questie or a quest-location database.

## Adventure Prep toast: position and transparency

- **Top of screen by default**, below the top edge instead of centered over your character.
- New native **Adventure Prep → Toast Appearance** settings page: **Lock/Unlock**, **Transparency 35–100%**, **Preview / Move (25s)**, and **Reset to Top**.
- Locked by default: fully click-through, no lost mouse actions. When unlocked, click Preview and drag the visible toast anywhere; your position is saved in existing `ChalkBoxDB.camp.toastOptions`.
- Relock in the options page when you're satisfied. Regular notices still last **nine seconds**, and the 25-second preview allows comfortable repositioning.
- Existing on-screen reminder, actual Camp Benefits, Camp Tent rested-XP / Boosted Rest, toast cooldown and class/pet reminders are unchanged.

## Combat Meter

Removed the unwanted **X close button**. The header now only has **DPS / Fight / PRINT / LOCK**. The window can still be shown/hidden in native Combat Meter settings or with `/chalk meter show|hide`; opacity, resizing, local fight printing and saved lock state remain.

## Install

Download **ChalkBox-1.8.0.zip**, replace the existing `Interface/AddOns/ChalkBox/` folder, then `/reload`. Everything—including the MIT-licensed 2,511 Forever recipes—is still in **one ZIP**. Existing SavedVariables and manually watched quests are preserved.

First test **`/chalk quests status`**, then **`/chalk quests refresh`** with the map closed. Try accepting a quest and look for its entry in Blizzard's native tracker. For toast placement, go to **Adventure Prep → Toast Appearance**, unlock, preview, drag and lock.

**Public prerelease:** Lua 5.1 automated regression and ZIP tests cover current/legacy/absent map APIs, native watch methods, tracker-mutation guards, saved toast placement/opacity and the no-X meter. A real WoW Forever session is still needed to verify the live UI, event timing and interaction with other quest-tracker addons. Report the exact diagnostic output and client build if something differs.
