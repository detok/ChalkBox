# ChalkBox 1.6.0 — One-download Forever recipe intelligence

This is our first **truly self-contained** recipe-aware LootSense release. **There is only one install: ChalkBox-1.6.0.zip.** No other addons, setup tools, game web APIs or additional downloads are needed.

## 2,511 Forever recipes, included

ChalkBox now embeds **LibProfessionDB 1.9.1's Forever-only recipe core (2,511 spells across ten professions)** and the public-domain **LibStub** loader. No Classic/TBC/Retail data trees or unrelated Ace3/LibVersionCheck features are bundled. The game reads the database locally; your tooltip works without an internet connection.

**Attribution and licenses:** the embedded library and its data are (c) 2026 **Pimptasty**, under MIT. The original license is packaged unchanged at `ChalkBox/Libs/LibProfessionDB-1.0/LICENSE`. LibStub is explicitly public domain. ChalkBox's own modules remain MIT (c) 2026 Detok. Source and verification details: [RECIPE_DATA.md](RECIPE_DATA.md). No scraping or copy of proprietary Wowhead files.

## Smarter, safer LootSense

- **Known recipe:** only when the character's actual learned profession list confirms it. Shows recipe name, profession and ingredient requirement (if available).
- **Potential use:** a validated Forever catalog entry exists but it's **not confirmed learned**. Ingredients relevant to your own profession are prioritized.
- **Other profession:** not a claim you personally need the material.
- The game can resolve recipe names from spell IDs; if the spell is not available, it tries the crafted item name. A numeric fallback is honestly labeled instead of inventing a name.
- An ingredient that you already have enough of says how much is in bags and how much one craft takes, rather than endlessly repeating a shortage indicator.
- Quest and manually protected items take priority. Verified camp reagents and utilities remain supported.
- Unknown does not mean **safe to sell**. No automated selling, destroying, item movement, crafting, auction searches or unsolicited chat.

## All existing modules retained

CampSense checks actual Camp Benefits and shows the nine-second onscreen reminder; TrailBar, QuietGuard, Emota, QuestSense and your existing settings all remain. The existing ChalkBox addon folder replaces the old one without changing your SavedVariables.

## Install / confirm

1. Download **ChalkBox-1.6.0.zip** from this release, not GitHub's automatically generated source ZIP.
2. Extract the `ChalkBox/` folder into your game client's `Interface/AddOns/`.
3. Launch or `/reload`, then type **`/chalk loot status`**. The offline recipe catalog should say **bundled**, with roughly 2,511 indexed recipes.
4. Open each profession window once to identify recipes your character actually knows. Type `/chalk loot scan` if needed.
5. Hover a reagent such as Light Leather to see specific **potential** and **known** uses. Test CampSense with `/chalk prep test`.

## Validation

The automated release pipeline checks Lua 5.1 syntax, the entire ChalkBox suite, a live load of the **actual bundled 2,511-recipe dataset**, ZIP integrity, deterministic packaging and original MIT license/source checks.

Still a **prerelease** until tested in a real WoW Forever game session, especially localized recipe-name lookups and UI restrictions. Please [report a problem](https://github.com/detok/ChalkBox/issues/new/choose) if a specific recipe or tooltip appears incorrectly.
