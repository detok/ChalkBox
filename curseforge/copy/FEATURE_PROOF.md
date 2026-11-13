# Feature-claim audit — verify before publishing

**Baseline:** ChalkBox v1.9.0, prepared against the GitHub release source as of November 13, 2026. “Implemented” means code is present and automated tests exercise it where appropriate, **not** a guarantee of identical behavior in every Forever client.

| Feature | Code and source | Responsible public claim | Boundary |
| --- | --- | --- | --- |
| LootSense | `ChalkBox/LootSense.lua`, `ProfessionSense.lua`, `RecipeAdvisor.lua` | Native-styled multi-line Item Insight tooltip with verified vs potential item advice | Actual client tooltip render should still be checked in-game |
| Local recipe catalog | `ChalkBox/Libs/LibProfessionDB-1.0/`, `docs/RECIPE_DATA.md` | 2,511 bundled Forever recipes | Catalog existence does not prove that a character learned the recipe |
| Keep list | `LootSense.lua`, `ChalkBox_Settings.lua` | Protect items using names or links | Does not auto-sell, move, use or delete items |
| TrailBar | `TrailBar.lua`, `TrailBarStats.lua`, `TrailBarLayout.lua`, `ChalkBox_Settings.lua` | 18px rich stats + per-character three-zone edit/order, right-click alignment and charcoal opacity 0–100% | Layout hides low-priority fields when necessary; real-client drag/render tests pending |
| Screen reservation | `TrailBar.lua` | Optional UI space reservation | Some custom UIs may not respond to UI-parent insets |
| ChalkBox combat meter | `CombatMeter.lua` | Move/lock/resize/opacity, class/spec icons, DPS, damage, HPS, healing, taken, interrupts | Uses Forever's own `C_DamageMeter`; secret data is restricted |
| Compact meter PARTY report | `CombatMeter.lua` | User-initiated top-three PARTY report after combat | No report solo/in raid or with secret data |
| Blizzard native meter PRINT | `NativeMeterPrint.lua` | Adds PARTY print to native gear menu | Automated tests pass; **in-game Forever check still required** |
| QuestSense | `QuestSense.lua` | Smart/Nearby/All accepted watches on Blizzard quest tracker | No directions, route, quest arrow, auto-accept or quest completion |
| CampSense | `CampAura.lua`, `CampSense.lua`, `ReminderToast.lua` | Camp Benefits/tent state hints, movable top-screen toast | Client may not expose exact auras |
| Emota | `Emota.lua`, `PersonalityContext.lua` | Optional native emotes + selectable/weighted racial flavor and honestly marked placeholders | Automatic master defaults OFF; placeholder races have no custom behavior |
| QuietGuard | `QuietGuard.lua` | Guild/duel invite protections and opt-in other filters | Native preference APIs may vary |
| Bag nudge | `BagLayout.lua`, `ChalkBox_Settings.lua` | Signed vertical −120..+120 slider, original Blizzard anchor at center 0 | Lua tests passed; real-client control orientation/movement should be verified |
| Known recipe highlights | `BagReagents.lua`, `ProfessionSense.lua` | Subtle green inset on true learned-recipe ingredients in Blizzard's native bag slots | No offline-only or potential-use false positives; Blizzard bag frame visibility varies |
| Installation | `scripts/package.py`, `scripts/test_packages.py` | One installable ZIP containing ChalkBox and credited libraries | CurseForge project media should NOT be added to ZIP |

## Never claim these features yet

- Always-visible free bag slots, durability, latency or rested XP on every screen width (the bar adaptively hides fields and native APIs may be unavailable)
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
- [ ] Separate bags remain onscreen with signed offset -35 / 0 / +40; combined bags unchanged
- [ ] `/chalk quests status` correctly explains tracking and respects manual watches
- [ ] `/chalk prep test` shows toast, dragging/locking works
- [ ] Confirm no unrelated Lua errors with normal UI addons installed
- [ ] Take real screenshots after the relevant features are verified

**Use:** [Full CurseForge description](PROJECT_DESCRIPTION.md), [GitHub README](../../README.md), and [source changelog](../../CHANGELOG.md).
