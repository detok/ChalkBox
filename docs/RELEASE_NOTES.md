# ChalkBox 2.2.5 — Know which quest needs that item

## LootSense: Quest name and progress
When a bag or loot item matches an *accepted* quest's item-collection objective, ChalkBox can show:

- **KEEP** — Needed for: Keeper of the Flame
- **1 / 5 collected**

If more than one accepted quest uses that item, the tooltip lists all matching quest names and counts. Completed objectives remain shown as complete until the quest is turned in or removed, preserving the existing do-not-sell safety. User KEEP protection still takes priority, but a known active quest can additionally be displayed.

This reads the quest title and objective progress from **Core.lua's existing quest cache**, created from the native Forever `C_QuestLog.GetQuestObjectives`. No new queries on hover or third-party database. The game's item-collection objective names must match the item's visible name; unusual objectives and quest-class items without an accepted matching objective safely show general quest protection **without guessing a quest title**.

Vendor BUY FOR QUEST and DO NOT SELL instructions, quest watch settings and all other tooltips remain unchanged.

## Discoveries: Native map-like backdrop
The World Map-owned Discoveries side panel uses Forever's own `gamepad-mapquestlog-bgtile-2k` tiled map background, darkened enough to keep small text readable. The original solid-color background is retained as a safe fallback when that native atlas is unavailable, including during theme changes. Nothing moves or recolors the underlying World Map itself. Discoveries area/source/sort dropdowns, saved selections, popup layering and map dock logic stay intact.

## Safety and tests
Two focused changes only: quest evidence in existing LootSense, and purely cosmetic panel artwork. No item-use methods, protected combat UI, AH displayMode calls, auction/DE engine changes, external API, SavedVariables migration, new windows, or automatic quest tracking.

Install `ChalkBox-2.2.5.zip` over the previous ChalkBox folder, preserve SavedVariables and type `/reload`. The full automated Lua 5.1/packaging suite must pass before publication. WoW Forever's in-client appearance and the localized quest objective names still require live verification.
