# ChalkBox 1.8.3 — LootSense material classification fix

**Fixes false First Aid profession labels, with the 1.8.2 DPS meter and everything else unchanged.**

## LootSense and ProfessionSense
- **Small Lustrous Pearl (item 5498)** is not a First Aid ingredient. It is used in Leatherworking, Tailoring and Blacksmithing recipes; a mistaken old saved scan must not label it First Aid.
- First Aid is no longer inferred from the generic **Cloth** item subclass. ChalkBox now checks potential First Aid reagent IDs against the bundled Forever recipe data before displaying a cached learned-material claim.
- Valid First Aid reagents (for example, Linen Cloth for Linen Bandage) remain recognized. Actual learned Leatherworking recipes involving the pearl still take precedence.
- If an item cache or client version provides no dependable item ID, ChalkBox avoids unverified First Aid claims rather than guessing.
- Run `/chalk loot scan` with your profession window open, then move your cursor off and back onto the item to refresh tooltip advice.

## Preserved from 1.8.2
- Native DPS meter class/spec icons, personal window size/position/opacity, movable toast, QuestSense, camp notices, Emota, QuietGuard and TrailBar.
- **PRINT** manually sends one top-three party summary after a fight, subject to Forever's protected-value restrictions. **RESET** remains on the meter with confirmation; `/chalk meter print` and `/chalk meter reset` still work.
- All 2,511 bundled Forever recipes, one installable ZIP, no external addon dependency.

## Install
Download only **ChalkBox-1.8.3.zip**, replace your `Interface/AddOns/ChalkBox` folder, then `/reload`.

**Public prerelease:** Lua 5.1 syntax, regression tests and packaging are checked automatically. The new tooltip behavior should still be confirmed in the actual Forever client.
