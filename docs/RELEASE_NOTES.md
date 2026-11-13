# ChalkBox 1.6.1 — Forever learned-profession scan fix

This release fixes the problem where opening a profession window **didn't change LootSense's material tooltips**.

## What was broken

- On Forever, the modern `C_TradeSkillUI` profession window may work even when classic `GetProfessions` and skill-list APIs do not report your professions. Our scanner rejected the modern data unless an older API first confirmed the profession.
- We listened for `TRADE_SKILL_SHOW` but not `TRADE_SKILL_LIST_UPDATE` or `TRADE_SKILL_DATA_SOURCE_CHANGED`. Forever can load or switch its recipe list *after* the window opens.
- Some game builds expose an incomplete modern `GetRecipeSchematic`. We didn't fall back to the alternative reagent API unless the schematic function was entirely missing.
- Tooltip advice could fail if the item metadata cache hadn't finished loading, even when the tooltip's own link already identified the item.

## The fixes

- Modern profession windows can now establish an observed profession without first satisfying classic API gates. Legacy support is preserved.
- Added modern list/data-source update events and a 0.4-second deferred rescan to capture late-loading recipes.
- Reads **learned** recipes only, including recipe names, reagent IDs and quantities; falls back to supported modern reagent getters when the schematic isn't usable.
- Uses a valid item name/link to look up known and potential crafting uses even if `GetItemInfo` is temporarily empty.
- Shows **which scanning method worked, the active profession, and learned recipe counts** through `/chalk loot status`.
- `/chalk loot scan` reports the immediate result. Re-hover an item after scanning so its tooltip is redrawn.
- All 2,511 Forever recipes remain bundled locally with the original **Pimptasty / LibProfessionDB MIT license** and no extra download.
- No automatic selling, destroying, crafting or item use. Existing CampSense, TrailBar, Emota, QuestSense and QuietGuard are unchanged.

## Test in WoW Forever

1. Install the single `ChalkBox-1.6.1.zip` and `/reload`. Your SavedVariables remain intact.
2. Open a crafting profession (e.g. Leatherworking) until its recipe list finishes loading.
3. Run **`/chalk loot status`** while the profession window is open. Check that it shows `LootSense advice: ON`, the profession name, a scan source such as `modern C_TradeSkillUI`, and a nonzero learned recipe count for professions with craftable recipes.
4. Run **`/chalk loot scan`** if necessary. Move your cursor away and re-hover a reagent used in a recipe you know. The tooltip should say **KNOWN RECIPE** with a name and count where available, rather than only **POTENTIAL USE**.
5. If the count is zero, report the exact output from `/chalk loot status` and your game build as a bug at https://github.com/detok/ChalkBox/issues.

## Automated verification

Lua 5.1 syntax, the complete existing suite, a new modern-only Forever profession test (empty initial list, delayed update, alternative reagent source, and profession switching), and cold-item-cache tooltip tests; deterministic single-ZIP packaging and original license hashes.

**Prerelease:** Tested against mocked API behavior and the real bundled recipe data. Verify these game-client interactions in a live Forever session.
