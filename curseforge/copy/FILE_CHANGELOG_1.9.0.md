# ChalkBox v1.9.0 — CurseForge release file changelog

**Version:** `1.9.0`  
**File:** `ChalkBox-1.9.0.zip`  
**Flavor:** World of Warcraft: Forever / Camelot  
**Suggested file status:** Beta (in-game polish features require visual smoke testing).

## The Polish Update

### TrailBar 1.9: completely personal layout
- Drag and drop any info module between **left, center and right** zones or reorder within a section.
- **Right-click while editing** to cycle module text alignment. Positions and alignment save per character.
- Real **Edit Bar**, **Done Editing** and **Reset Layout** buttons under TrailBar Appearance.
- Neutral Blizzard-style charcoal background with **0–100% opacity**; the 18px text and XP underline remain readable at zero.
- All previous rich stats stay: XP, bag capacity, equipped durability, rested XP, optional latency and Hunter pet health.

### LootSense looks native
- Multi-line **CHALKBOX | ITEM INSIGHT** display replaces verbose `LootSense:` prefix, distinguishing verified learned recipes from potential uses.
- Optional understated green insets highlight **ingredients of recipes you actually know** within Blizzard's bag icons.
- New **LootSense Appearance** page for enabled/disabled state, outline strength, rescan/refresh.
- Does **not** mark catalog-only recipes, automate items, replace rarity colors or change bag behavior.

### Better Emota configuration
- Emota Race Behavior page, race chooser and **Off / Subtle / Default / Expressive** racial emote weighting.
- Existing weighted race profiles are real; future choices are clearly marked planned and have no invented functionality.
- Existing automatic-emote controls and combat/idle safety remain intact.

### Intuitive separate-bag movement
- **Vertical −120 to +120 UI-point** position control, with **Blizzard's original anchor at the midpoint (0)**.
- Up means raise bags; down means lower bags. Reset Bags restores stock. Combined bags remain unchanged.

### Native settings polish
- A cleaner ChalkBox landing menu, dedicated TrailBar Appearance, LootSense Appearance and Race Behavior categories, and existing options preserved.

## Compatibility and limits

ChalkBox remains **WoW Forever-focused**. It ships a single Lua 5.1 addon folder and a fully bundled, properly attributed 2,511-recipe catalog. Blizzard-native bag/button APIs and protected values vary by client; if a feature cannot safely update, it leaves the native UI unchanged. New editing visuals and dropdown behaviors need in-game verification.

**Source and primary download hub:** https://github.com/detok/ChalkBox  
**Bug reports:** https://github.com/detok/ChalkBox/issues  
**Install guide:** use `Interface/AddOns/ChalkBox/ChalkBox_Camelot.toc` inside the extracted folder.

CurseForge files and the direct GitHub release are distribution alternatives; no CurseForge app is required for the GitHub download.
