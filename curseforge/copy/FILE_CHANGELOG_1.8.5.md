# ChalkBox v1.8.5 — initial CurseForge file changelog

**Version:** `1.8.5`  
**File:** `ChalkBox-1.8.5.zip`  
**Game:** World of Warcraft: Forever  
**Suggested status:** Beta until in-game native menu and bag offset smoke tests pass.

## Highlights

- **Native Blizzard damage meter integration:** a **ChalkBox: PRINT top 3 to PARTY** entry in the existing Blizzard gear menu. It follows that window's selected statistic and fight history, when the client permits the data.
- **ChalkBox compact combat meter:** optional custom DPS/DMG/HPS/HEAL/TAKEN/INT window with class/spec art, adjustable opacity, move/lock/resize, manual PARTY PRINT and confirmed RESET.
- **Individual bag nudge:** optional **0–80 UI-point downward offset** in TrailBar settings; default 0, combined bags untouched.
- **LootSense accuracy:** First Aid recipe hints are validated against real recipe evidence, preventing stale incorrect First Aid claims for unrelated ingredients.
- **Local Forever profession catalog:** all 2,511 recipes included with LibProfessionDB credit and license.

## Also included

- 18px TrailBar with XP/session and gold metrics
- QuestSense's smart accepted-quest watch modes and diagnostics
- CampSense's aura and tent/rested-XP checks plus optional top-screen toast
- QuietGuard configurable invite protection
- Emota optional idle/personality reactions
- Native WoW AddOns configuration pages
- One self-contained Lua addon ZIP and automated Lua 5.1 tests

## Compatibility and cautions

ChalkBox targets **WoW Forever**. Use the native `ChalkBox_Camelot.toc` for that client. No automated item selling or quest completion. PARTY report is never automatic and refuses protected values, solo play, raids and in-combat requests.

Automated tests passed for this baseline, but protected Forever game APIs and third-party UI interactions can differ by build. Please file reproducible reports at https://github.com/detok/ChalkBox/issues.

**Publisher check:** replace this version-specific file changelog when preparing a newer upload. Do not claim CurseForge moderation approval until it happens.
