<div align="center">

<img src="curseforge/artwork/chalkbox-github-header-1600x470.svg" alt="ChalkBox — The Quiet Adventure Companion for WoW Forever" width="100%" />

# ✦ ChalkBox

### The quiet adventure companion for **World of Warcraft: Forever**

**Know what you have. Remember where you found it. Build better buttons. Get back to playing.**

[![ChalkBox prerelease](https://img.shields.io/badge/release-2.0.0%20preview-DDAE61?style=flat-square)](https://github.com/detok/ChalkBox/releases/tag/v2.0.0)
[![Lua tests & installable ZIP](https://github.com/detok/ChalkBox/actions/workflows/release.yml/badge.svg)](https://github.com/detok/ChalkBox/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-67C6B7?style=flat-square)](LICENSE)
[![Client: Forever](https://img.shields.io/badge/client-WoW%20Forever-203342?style=flat-square)](#compatibility)

### [⬇ DOWNLOAD CHALKBOX 2.0.0 — TEST BUILD](https://github.com/detok/ChalkBox/releases/download/v2.0.0/ChalkBox-2.0.0.zip)

[Install in a minute](#install-in-one-minute) · [Explore features](#the-toolkit) · [Quick commands](#quick-commands) · [Report a bug](https://github.com/detok/ChalkBox/issues/new/choose)

</div>

> [!IMPORTANT]
> **ChalkBox 2.0.0 is a Forever-client testing prerelease.** Automated Lua tests and ZIP packaging are verified by GitHub Actions. The World Map Discoveries button was revised for Forever's load-on-demand map, but **its appearance in real-client layouts still needs testing**. If you don't see it, use **/chalk drops map** to open the same journal and **/chalk drops map status** for diagnostics. Please report what you find.

---

## One addon. Your whole adventure.

ChalkBox makes the familiar WoW interface more informative without replacing it. It recognizes useful loot, builds your personal drop journal, remembers sessions, helps you prepare for camp, makes combat data easier to read, and now helps you **build real macros from your own spellbook**.

Everything installs in **one ChalkBox folder**, with the supporting profession data already included. There are no mandatory companion addons, cloud logins, AI services, automatic selling, or hidden combat rotation engines.

## The toolkit

| | Feature | What it actually does |
| :-- | :-- | :-- |
| 🗺️ | **Map Discoveries + DropSense** | Collect your own readable loot-window observations automatically. Browse discovered items by **outdoor zone**, **dungeon**, and identifiable creature source from an optional world-map button. |
| ✨ | **MacroForge** | A guided macro builder that uses **learned spells**. Make opener, burst/trinket, modifier, mouseover and manual-sequence macros; validate, copy or explicitly create a new native macro. |
| 📦 | **LootSense** | Native item insights for items marked KEEP, quests, learned recipe ingredients, potential crafting uses and camping utility. No false “safe to sell” verdict. |
| 🧪 | **ProfessionSense** | Scan the recipes your character learned; compare them with **2,511 bundled Forever recipes**. No second recipe database download. |
| 📈 | **The Bar** | An **18px**, repositionable status strip for XP, rate, ETA, bag space, durability, rested XP, latency, gold, pet status, optional bag vendor value and repair estimate. **Right-click** to customize. |
| 🔧 | **Repair Learning** | Reads real repair-all prices at merchants, remembers bounded examples per character, and labels away-from-vendor estimates with **~**. Never repairs or spends money. |
| 📖 | **Session Journal** | Review the current adventure and **up to 20 completed sessions**: observed XP, levels, net gold, completed quests, sampled loot, camp prompts and repair quotes. |
| ⚔️ | **Combat Meter + Blizzard PRINT** | An optional compact DPS/healing/interrupts meter with manual PARTY report, plus a separate **PRINT top 3** action in the native Forever meter's gear menu. |
| 📜 | **QuestSense** | Smart, Nearby or All-accepted quest-watch choices **inside Blizzard's tracker**; respects manual watches. No invented objective pins or route arrows. |
| ⛺ | **Adventure Prep** | Smarter Camp Benefits, camp supply, tent/rested-XP and supported Hunter pet reminders; a compact, optional toast that tries to say **what to do next**. |
| 🎨 | **Global Appearance** | Charcoal/Midnight/Slate/custom colors, accents and background strength shared across ChalkBox panels; individual controls remain available. |
| 🛡️ | **QuietGuard + Emota** | Optional invite filters and opt-in contextual character emotes with configurable racial flavor. |
| 🎒 | **Bag Position** | Adjust Blizzard's separate bag windows vertically with an intuitive signed offset. |

**All of this lives in the same addon and native settings menu.** If you don't want a feature, switch it off.

## Highlights

### Explore loot from the map you already use

DropSense can remember **every readable item** found in loot windows, then organize the evidence by zone and observed dungeon. Open the regular world map and look for **Discoveries** near the upper-left map area. The resulting browser can show outdoor drops, separately recorded dungeons and creature-source details.

It does **not** replace your map or quest pins. If the button isn't visible, **/chalk drops map** opens the browser directly—even when the map button could not attach. **/chalk drops map status** reports the map frame, button visibility and saved toggle so problems are diagnosable.

**About percentages:** a displayed rate is the fraction of *readable, identifiable single-creature loot windows* where that item appeared. ChalkBox cannot see every kill or every empty/unopened corpse, and it cannot read Forever's official server loot tables. Mixed-source loot gets collection counts, **not an invented monster drop chance**. Previous unsited DropSense records remain unsited after upgrading.

### Build a macro without learning the macro language first

**MacroForge** starts with your own learned spellbook and offers five practical approaches: **Engage**, **Burst + Trinkets**, **Modifier Keys**, **Manual Sequence**, and **Mouseover Utility**.

Choose learned abilities, select optional pet attack, Hunter Auto Shot or trinket slot attempts, and watch the generated macro and validation notes update. Save up to 16 character-specific **recipes** to revisit after a respec. **Select Text → Ctrl+C** lets you paste into the game's **/macro** window; **Install New** is an optional, explicit out-of-combat action that refuses to overwrite a same-named macro.

A macro cannot bypass the GCD, automatically react to procs, or execute a whole rotation from one click. MacroForge explains these restrictions instead of promising the impossible. [Read the MacroForge design and testing notes](docs/MACROFORGE_DESIGN.md).

### Make a slimmer, more useful HUD

**The Bar** stays 18 pixels tall. Customize its modules and layout with right-click menus or edit mode. View **Junk / Total** bag vendor resale on one stat; view an exact repair quote at a merchant or a carefully marked **~** estimate afterward, using observed repair history. Actual costs can vary with damaged bag gear and merchant discounts.

You can also keep Blizzard's own damage meter and use ChalkBox's one-click, **manual** top-three PARTY report. No automatic chat spam or invented combat statistics.

### Know which loot deserves a second look

LootSense prioritizes your personal protected items and quest evidence. It separates **learned recipe** uses from **potential recipe** uses in the bundled catalog, and can highlight actual learned-recipe reagents with a restrained green inset in native bag slots. It doesn't call an unannotated item “safe to sell,” and it never sells anything.

### A little help between fights

CampSense distinguishes tent/rested-XP readiness from separate Camp Benefits buffs. It looks at readable kit, wood and Flint and Tinder quantities before prompting, and keeps unchanged reminders quiet by default. The Session Journal remembers what ChalkBox actually observed, not fabricated activity.

---

## See the ChalkBox identity

![Original ChalkBox editorial feature artwork. This is not an in-game screenshot.](curseforge/artwork/chalkbox-feature-grid-1600x900.svg)

*Original branding illustration, **not a gameplay screenshot**.* Real screenshots of the Forever client are still on the [2.0 validation checklist](curseforge/artwork/SCREENSHOT_PLAN.md). We won't advertise a mock UI as a feature already verified in-game.

[Full hero illustration](curseforge/artwork/chalkbox-hero-1600x900.svg) · [Logo and brand guide](docs/BRANDING.md) · [Media assets](curseforge/artwork/ARTWORK_FOLDER.md)

## Install in one minute

1. Download the **ChalkBox-2.0.0.zip** asset from the [2.0 prerelease](https://github.com/detok/ChalkBox/releases/tag/v2.0.0). **Do not download GitHub's “Source code (zip)”** as the install.
2. Extract its single **ChalkBox** folder into your WoW Forever client's **Interface/AddOns** directory.
3. Confirm this path exists: **Interface/AddOns/ChalkBox/ChalkBox.toc** (no nested second ChalkBox folder).
4. Start or reload the game. Type **/chalk** to open the native settings.

The build includes both Forever TOC variants and all required bundled data. **You do not need to download anything else.**

## First five minutes

- **/chalk** — open all module settings. Choose global colors and the tools you want visible.
- **/chalk macro** — open MacroForge and generate your first spellbook-aware macro.
- **/chalk drops status** — check whether personal loot recording is enabled; **/chalk drops on** enables it. Open a loot window to begin collecting observations.
- **M → Discoveries** — inspect the selected zone's observed loot. If the map button is missing, use **/chalk drops map**, then **/chalk drops map status**.
- **/chalk session** — see the current adventure; **/chalk session last** opens the previous one.
- **/chalk prep test** — preview the camp reminder toast and adjust its position if necessary.

## Quick commands

| Command | Purpose |
| --- | --- |
| \`/chalk\` or \`/cb\` | Open ChalkBox options |
| \`/chalk macro\` | Open MacroForge |
| \`/chalk forge rescan\` | Rescan learned spells |
| \`/chalk drops map\` | Open Map Discoveries independently of its map button |
| \`/chalk drops map status\` | Explain map button attachment and visibility |
| \`/chalk drops map on\` / \`off\` | Toggle the map button without deleting history |
| \`/chalk drops on\` / \`off\` | Start or stop loot-window observations |
| \`/chalk drops chance 5 20\` | Example: probability of at least one drop across 20 independent attempts if your supplied chance is 5% |
| \`/chalk session\` / \`/chalk session last\` | Current or previous saved session |
| \`/chalk bar status\` | Inspect The Bar |
| \`/chalk bar stat repair on\` | Enable the repair module |
| \`/chalk bar repair status\` | Inspect learned repair observations |
| \`/chalk quests status\` | Explain current QuestSense choices |
| \`/chalk loot status\` | Inspect item advice and profession detection |
| \`/chalk prep\` | Review current camping state |
| \`/chalk meter status\` | Check Blizzard meter compatibility |

[Complete user guide](docs/USER_GUIDE.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Changes](CHANGELOG.md)

## Compatibility and limits

ChalkBox is built for **World of Warcraft: Forever**. It relies on modern Forever APIs when available and degrades gracefully when the client withholds data. **Retail/Classic Era support has not been verified.** Some functions (especially map placement, protected combat data and macro creation) still need real-client acceptance testing for 2.0.

The player remains in control: no automated combat rotation, no auto-selling or repairs, no automatic PARTY messages, no forged drop probabilities, no quest automation, no online data collection, no AI service.

> [!TIP]
> **Testing 2.0?** First open the world map and look for **Discoveries**. If it doesn't appear, type **/chalk drops map**, then **/chalk drops map status**, and attach the diagnostic output plus a map screenshot in a [GitHub issue](https://github.com/detok/ChalkBox/issues/new/choose). Also check MacroForge spell scanning and verify that saved history survives a relog.

## Contribute / get help

- **Found a bug?** [Open an issue](https://github.com/detok/ChalkBox/issues/new/choose) with your Forever client build, ChalkBox version, reproduction steps and any Lua error.
- **Have an idea?** [Request a feature](https://github.com/detok/ChalkBox/issues/new/choose).
- **Want to help?** See [CONTRIBUTING.md](CONTRIBUTING.md) and [development notes](docs/DEVELOPMENT.md).
- **Preparing a CurseForge page?** The [listing kit](curseforge/README.md) includes copy, artwork and an honest verification checklist. A public CurseForge listing is **not** being claimed here.

## Credit and license

ChalkBox is a community project by **Detok Whitemaine**, distributed under the [MIT License](LICENSE). Bundled profession data and libraries retain their own notices; see [NOTICE.md](NOTICE.md). Original ChalkBox brand art is distinct from Blizzard artwork.

**Not affiliated with, sponsored by, or endorsed by Blizzard Entertainment.** World of Warcraft and associated trademarks belong to their respective owners.

<div align="center">

**One addon. A better-informed adventure.**

[Download 2.0.0 prerelease](https://github.com/detok/ChalkBox/releases/tag/v2.0.0) · [Report an issue](https://github.com/detok/ChalkBox/issues/new/choose)

</div>
