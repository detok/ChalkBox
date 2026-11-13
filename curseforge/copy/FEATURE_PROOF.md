# Feature inventory and testing notes

This is a factual reference for keeping the ChalkBox listing current. It isn't a promise that every UI configuration has been tested.

| Module | Shipped behavior | Important limit |
| --- | --- | --- |
| DropSense | Automatically records readable item appearances and quantities | Not every kill or a server drop table |
| Map Discoveries | Searchable outdoor/dungeon/source journal and movable map button | Some client/map-skin layouts may vary |
| LootSense | KEEP, quest and profession item context | Never sells items or guarantees an item is disposable |
| ProfessionSense | Learned recipe inspection plus bundled reference data | Learned data depends on readable professions |
| MacroForge | Learned-spell macro templates, validation, saved builds, copy/new install | Cannot run a rotation or bypass GCD |
| The Bar | Compact modular edge HUD with right-click arrangement | Less important stats can be hidden by limited space |
| Repair Learning | Exact vendor quotes and marked away-from-merchant estimates | Bag damage and discounts can affect estimates |
| Combat Meter | Optional manual window, reports, icon modes | Starts closed; protected API restrictions apply |
| Session Journal | Records the current and 20 prior sessions | No fabricated historical sessions |
| QuestSense | Native accepted-quest watches | No guessed pins or routes |
| Adventure Prep | Readable camp/rest and pet reminders | Tent/rested XP and Camp Benefits are different |
| Appearance | Shared theme and local opacity options | Doesn't recolor Blizzard's interface |
| Emota / QuietGuard / Bags | Optional emotes, invite protection and bag positioning | Per-client behavior must be checked |

## 2.0.2 acceptance checks

- Nested settings groups expand and direct links still reach their intended pages.
- Optional compact meter stays hidden across login and reload.
- Map Discoveries button is visible, draggable and resettable; menus and search remain responsive.
- MacroForge lists learned spells and doesn't overwrite a native macro.
- SavedVariables retain prior loot, macro, bar, repair and session history.
- The CurseForge media package contains six SVG originals and nine PNG exports.
- Genuine in-game screenshots are captured before public gallery submission.

The project is maintained by **Detok Whitemaine**. Source and bug reports: https://github.com/detok/ChalkBox.
