# Feature-claim audit — verify before publishing

**Baseline:** ChalkBox v1.8.5, GitHub `main` as of November 13, 2026. “Implemented” means code is present and automated tests exercise it where appropriate, **not** a guarantee of identical behavior in every Forever client.

| Feature | Code and source | Responsible public claim | Boundary |
| --- | --- | --- | --- |
| LootSense | `ChalkBox/LootSense.lua`, `ProfessionSense.lua`, `RecipeAdvisor.lua` | Contextual protection, crafting, camping and quest item hints | Client item and learned-recipe data can be incomplete |
| Local recipe catalog | `ChalkBox/Libs/LibProfessionDB-1.0/`, `docs/RECIPE_DATA.md` | 2,511 bundled Forever recipes | Catalog existence does not prove that a character learned the recipe |
| Keep list | `LootSense.lua`, `ChalkBox_Settings.lua` | Protect items using names or links | Does not auto-sell, move, use or delete items |
| TrailBar | `TrailBar.lua` | 18px strip: level/XP, XP/hour, level ETA, time and gold | No free bag-slot count, durability, latency or rested XP in TrailBar |
| Screen reservation | `TrailBar.lua` | Optional UI space reservation | Some custom UIs may not respond to UI-parent insets |
| ChalkBox combat meter | `CombatMeter.lua` | Move/lock/resize/opacity, class/spec icons, DPS, damage, HPS, healing, taken, interrupts | Uses Forever's own `C_DamageMeter`; secret data is restricted |
| Compact meter PARTY report | `CombatMeter.lua` | User-initiated top-three PARTY report after combat | No report solo/in raid or with secret data |
| Blizzard native meter PRINT | `NativeMeterPrint.lua` | Adds PARTY print to native gear menu | Automated tests pass; **in-game Forever check still required** |
| QuestSense | `QuestSense.lua` | Smart/Nearby/All accepted watches on Blizzard quest tracker | No directions, route, quest arrow, auto-accept or quest completion |
| CampSense | `CampAura.lua`, `CampSense.lua`, `ReminderToast.lua` | Camp Benefits/tent state hints, movable top-screen toast | Client may not expose exact auras |
| Emota | `Emota.lua`, `PersonalityContext.lua` | Optional randomized native emotes | Auto-emote master defaults OFF |
| QuietGuard | `QuietGuard.lua` | Guild/duel invite protections and opt-in other filters | Native preference APIs may vary |
| Bag nudge | `BagLayout.lua`, `ChalkBox_Settings.lua` | Separate bag vertical-offset slider, 0–80 points; default 0 | Lua tests passed; in-client layout/third-party mover interaction to verify |
| Installation | `scripts/package.py`, `scripts/test_packages.py` | One installable ZIP containing ChalkBox and credited libraries | CurseForge project media should NOT be added to ZIP |

## Never claim these features yet

- Free bag slots, gear durability, latency or rested XP **in TrailBar**
- Action-bar icon styling or hiding empty Action Bar 2 buttons **as a ChalkBox feature** (WoW has a native Edit Mode “Always Show Buttons” toggle)
- Automatic selling/sorting, quest navigation, hidden-object discovery, automatic combat reporting, AI features or guaranteed accuracy
- Native meter print proven on every Forever build; it has only automated mock coverage so far
- Universal Retail, Classic, or non-Forever support
- Performance benchmarks, official endorsement or CurseForge approval

## In-client launch smoke tests

- [ ] `/chalk` opens all relevant settings pages; changing a toggle persists after reload
- [ ] Tooltip differentiates real **KNOWN RECIPE** from **POTENTIAL USE**
- [ ] Profession scan works using `/chalk loot scan`
- [ ] Blizzard meter gear menu has **ChalkBox: PRINT top 3 to PARTY** after a real party fight
- [ ] Blocking behavior works during combat, solo and when client restricts data
- [ ] Separate bags remain onscreen with offset 0 vs 30; combined bags unchanged
- [ ] `/chalk quests status` correctly explains tracking and respects manual watches
- [ ] `/chalk prep test` shows toast, dragging/locking works
- [ ] Confirm no unrelated Lua errors with normal UI addons installed
- [ ] Take real screenshots after the relevant features are verified

**Use:** [Full CurseForge description](PROJECT_DESCRIPTION.md), [GitHub README](../../README.md), and [source changelog](../../CHANGELOG.md).
