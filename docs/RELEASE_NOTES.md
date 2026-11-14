# ChalkBox 2.0.10 — First bank visit compatibility

Some players encountered a ChalkBox blocked-action warning when opening the bank for the first time on a new character. The warning disappeared after `/reload`.

### Changes
- **Bank UI isolation:** ChalkBox no longer scans or attaches profession reagent overlays to bank item buttons. Only equipped backpack/character bags receive these visuals.
- **Safe first open:** All ingredient highlighting scans and new bag UI hooks are deferred while the bank is visible or handling `BANKFRAME_OPENED`.
- **No protected anchor movement:** ChalkBox's optional separate-bag offset avoids any container reanchoring during first-time bank UI initialization, and refuses bank container IDs.
- **Automatic recovery:** After `BANKFRAME_CLOSED`, normal player bag highlights and the saved layout offset can update again.
- **Regression coverage:** Simulates fresh bank opening, Blizzard's container enumeration including protected bank items, bank closing, and normal bag behavior afterward.

These are preventive protections against a likely source of the bank blocked-action warning. They passed automated Lua 5.1 and packaging checks, but **the precise cause of the user's live-client error is not confirmed** without a captured blocked-function report or stack trace. A real first-time-bank-open test is still necessary.

### Preserved
WoW's native bank and item actions; all SavedVariables and bank contents; Discoveries, QuestSense, The Bar, LootSense and other features.

**Install:** Replace your ChalkBox addon folder with **ChalkBox-2.0.10.zip** and type `/reload`. Keep your character's SavedVariables.

**ChalkBox-CurseForge-Media-2.0.10.zip** contains promotional art and publication copy, not the installable addon. Built for WoW Forever; other WoW versions remain unverified.
