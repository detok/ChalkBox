# ChalkBox 2.2.34 — install and first use

**Stable 2.2.34:** Download `ChalkBox-2.2.34.zip`.

# ChalkBox 2.2.33 — install and first use

**Stable 2.2.33:** Download `ChalkBox-2.2.33.zip`.

# ChalkBox 2.2.32 — install and first use

**Stable 2.2.32:** Download `ChalkBox-2.2.32.zip`.

# ChalkBox 2.2.31 — install and first use

**Stable 2.2.31:** Download `ChalkBox-2.2.31.zip`.

# ChalkBox 2.2.30 — install and first use

**Stable 2.2.30:** Download `ChalkBox-2.2.30.zip`. SavedVariables are kept.

# ChalkBox 2.2.29 — install and first use


**Stable 2.2.29:** Local Combat Meter retained; all ChalkBox DPS reporting disabled. See [release details](../../docs/RELEASE_NOTES.md).

**Stable release:** Download the playable 2.2.29 addon ZIP from GitHub Releases, not an old test archive.

1. Download the **`ChalkBox-2.2.29.zip`** game asset from [GitHub Releases](https://github.com/detok/ChalkBox/releases/tag/v2.2.29). **Not** the media kit or GitHub Source code ZIP.
2. Extract its single `ChalkBox/` folder into your actual Forever client `Interface/AddOns/`. Confirm `Interface/AddOns/ChalkBox/ChalkBox.toc` exists.
3. Launch the game and type **`/chalk`** to open the native settings pages.
4. **LootSense:** Hover items. Quest items may identify the accepted quest and collection progress when reliably matched. Use `/chalk keep [item]` for a personally protected item; learned recipe hints are distinct from potential uses.
5. **DropSense / Discoveries:** Enable recording; open the World Map and click **Discoveries** (or `/chalk drops map`). Browse outdoor/dungeon history, source-specific observations and optional recent outdoor loot-window coordinates.
6. **QuestSense:** Choose **Smart**. Outdoors it prioritizes accepted quest watches; in a supported party dungeon it focuses on quests verified for *that instance* and restores your manual watches after leaving. No verified match means **preserve** rather than guess. Diagnostics: `/chalk quests status`.
7. **MacroForge:** Type `/chalk macro`. Select a template, known spells and options, read the warnings, then **Select Text → Ctrl+C**. **Install New** is an explicit action outside combat and will not overwrite an existing macro.
8. **AuctionSense:** Visit an auctioneer, open the native AH's AuctionSense tab and deliberately run **Scan Market**. These are observed **asking** prices, not sales. Full listings can be server-throttled. Optional DE estimates remain read-only.
9. **The Bar:** Configure the slim HUD. Right-click empty space for Edit layout, drag metrics, then right-click again for **Done editing**. Existing customizations persist across upgrades.
10. **Adventure Journal:** `/chalk session` now shows a framed wood recap of current or previous observed sessions. Full individual-event Chronicle recording is not yet live.
11. **Combat Meter:** Starts closed. Use `/chalk meter show` only if you want it. **Session Journal** opens with `/chalk session`. Adventure Prep, Emota and QuietGuard have individual preference pages; QuietGuard's new-install filters are **off**.

**Updating:** replace the addon folder but do **not** delete WoW's SavedVariables. After replacing files, use `/reload`.

**Need help?** [Player handbook](https://github.com/detok/ChalkBox/blob/main/docs/USER_GUIDE.md) · [Commands](https://github.com/detok/ChalkBox/blob/main/docs/COMMANDS.md) · [Troubleshooting](https://github.com/detok/ChalkBox/blob/main/docs/TROUBLESHOOTING.md) · [Issues](https://github.com/detok/ChalkBox/issues)

Some current-looking screenshots were captured on older versions; check real-client appearance before publishing gallery claims.


**Stable 2.2.29:** Restored AuctionSense Market and scanning. Combat Meter reports are removed; all other core tools remain.


**Developer beta:** ChalkBox 2.2.27 is a QuestSense Smart experiment; 2.2.29 remains the supported stable release. [Beta notes](https://github.com/detok/ChalkBox/blob/feature/smart-quest-native-priorities/docs/RELEASE_NOTES.md).
