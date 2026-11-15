<div align="center">

<img src="curseforge/artwork/chalkbox-github-header-1600x470.svg" alt="ChalkBox for WoW Forever" width="100%" />

# ChalkBox

**One addon. Better information. Less UI clutter.**

Quality-of-life tools for **World of Warcraft: Forever** — loot discoveries, quests, professions, auction prices, macros, a compact HUD, combat information and a little personality.

[**Releases (including prereleases)**](https://github.com/detok/ChalkBox/releases) · [**Install & first run**](docs/GETTING_STARTED.md) · [**Player handbook**](docs/USER_GUIDE.md) · [**Documentation home**](docs/README.md) · [**Report a problem**](https://github.com/detok/ChalkBox/issues/new/choose)

</div>

ChalkBox installs as **one `ChalkBox` folder**. Its bundled recipe data needs no separate download. Features are managed through Blizzard's native **Options → AddOns → ChalkBox** pages, or by typing `/chalk`.

> **Current release: 2.2.11 (GitHub prerelease).** ChalkBox targets WoW Forever. The code has automated Lua 5.1 tests, but client-specific UI behavior still needs real in-game verification. Retail and ordinary Classic compatibility are **not claimed**.

## See it in-game

![Discoveries beside the original WoW World Map](curseforge/screenshots/10-discoveries.jpg)

*Real WoW Forever captures from the project gallery. Some captures show earlier interface revisions; the release notes describe current changes.*

[Browse all gameplay screenshots](docs/SCREENSHOT_GALLERY.md)

## What's inside

| Tool | What you use it for |
| --- | --- |
| [**LootSense & Professions**](docs/USER_GUIDE.md#lootsense-and-professions) | See why an item is worth keeping: quest objectives and progress, your personal KEEP list, confirmed learned recipes and possible crafting uses. No automatic selling. |
| [**DropSense & Discoveries**](docs/USER_GUIDE.md#dropsense-and-discoveries) | Record loot you actually observe; browse zones, dungeons and identified creatures from the World Map. Outdoor items can include a handful of observed loot-window coordinates. Rates are personal observations, not official drop odds. |
| [**AuctionSense, AuctionInsights & DisenchantSense**](docs/USER_GUIDE.md#auction-tools-and-disenchanting) | Manually scan asking prices in the native Auction House, browse your own inventory values and observed mail receipts, and review clearly labeled disenchant estimates. No automated trading or disenchanting. |
| [**QuestSense**](docs/USER_GUIDE.md#questsense) | Maintain Blizzard's accepted-quest tracker in Smart, Nearby or All mode. Smart focuses on verified current-dungeon quests when supported, and restores other watches on exit. |
| [**MacroForge**](docs/USER_GUIDE.md#macroforge) | Build and save macros from learned spells, inspect the exact output, copy it or explicitly install a *new* macro outside combat. Never automates a rotation. |
| [**The Bar & Repair Learning**](docs/USER_GUIDE.md#the-bar-and-repair-learning) | A slim configurable display for XP, bags, durability, repair estimates, junk value, gold, ping and more. Right-click to edit and finish your custom layout. |
| [**Combat Meter & Adventure Journal**](docs/USER_GUIDE.md#combat-meter-and-session-journal) | Optional meter and manual reports, plus a framed, persistent per-character recap of observed sessions; a full event Chronicle is planned, not yet recording. |
| [**Adventure Prep, Emota & QuietGuard**](docs/USER_GUIDE.md#adventure-prep-emota-and-quietguard) | Camping reminders, optional idle emotes and opt-in invite blocking. |
| [**Appearance, Bags & Updates**](docs/USER_GUIDE.md#appearance-bags-and-updates) | Coordinate panel colors, move separate bags safely and check your installed version. |

## Install or upgrade

1. Open [GitHub Releases](https://github.com/detok/ChalkBox/releases) and select **ChalkBox-2.2.10.zip** (or the newest release appropriate for your client). **Do not** use GitHub's automatically generated Source code ZIP or the separate CurseForge media ZIP.
2. Extract the single **ChalkBox** directory to your game's `Interface/AddOns/` folder. Confirm the path ends in `Interface/AddOns/ChalkBox/ChalkBox.toc` — not `ChalkBox/ChalkBox/ChalkBox.toc`.
3. Start Forever, check the AddOns list, then type `/chalk`.
4. On an upgrade, replace only the addon folder. **Preserve WoW's SavedVariables** to keep your preferences, historical loot, market scans and layouts.

For the full installation, first-use and recovery walkthrough, see [Getting started](docs/GETTING_STARTED.md).

## Most-used commands

| Command | Result |
| --- | --- |
| `/chalk` or `/cb` | Main settings |
| `/chalk drops map` | Discoveries window |
| `/chalk macro` | MacroForge |
| `/chalk quests status` | QuestSense diagnostics and dungeon matching |
| `/chalk auction status` | Market-scan state |
| `/chalk bar edit` | Toggle the Bar layout editor |
| `/chalk meter show` | Open the optional meter |
| `/chalk session` | Current Session Journal |
| `/chalk update` | Installed version and release-link information |

[Complete verified command reference](docs/COMMANDS.md)

## What's new in 2.2.11?

**The Adventure Journal has a matching Blizzard outer frame, warm wood artwork, and legible inset panels—even when global theme opacity is zero.** The existing session data is preserved. The future full event Chronicle is [designed here](docs/ADVENTURE_CHRONICLE_DESIGN.md), but Today/Timeline/History and milestone recording are not shipped yet.

**Previously in 2.2.10:** Smart QuestSense recognizes your current party dungeon when the client provides dependable matching quest information. It temporarily narrows the native tracker to quests confirmed for *that instance* and restores your previous manual watches when you leave. If Forever supplies no reliable matches, ChalkBox conservatively preserves the tracker instead of inventing dungeon assignments. See [release notes](docs/RELEASE_NOTES.md) and the [full changelog](CHANGELOG.md).

## Documentation and support

**Players:** [Start here](docs/GETTING_STARTED.md) · [Handbook](docs/USER_GUIDE.md) · [Commands](docs/COMMANDS.md) · [Troubleshooting](docs/TROUBLESHOOTING.md)

**Maintainers:** [Documentation index](docs/README.md) · [Architecture](docs/ARCHITECTURE.md) · [Development](docs/DEVELOPMENT.md) · [Maintainer runbook](docs/MAINTAINER_RUNBOOK.md) · [Publishing](docs/RELEASE_PROCESS.md) · [Contributing](CONTRIBUTING.md)

**CurseForge:** [Publishing kit](curseforge/README.md) — listing text, genuine gameplay images and art are separate from the playable addon.

Report a bug via [GitHub Issues](https://github.com/detok/ChalkBox/issues/new/choose). Include the ChalkBox version, Forever client/build, module, steps to reproduce, expected/actual behavior and any Lua error; redact private chat and account information.

**Created and maintained by Detok Whitemaine.** Original ChalkBox code is [MIT-licensed](LICENSE); bundled third-party components retain their own license notices inside `ChalkBox/Libs/`. ChalkBox is an independent project and is not affiliated with or endorsed by Blizzard Entertainment.
