# ChalkBox

**A quieter, smarter adventuring companion for World of Warcraft Forever.**

[![Build](https://github.com/detok/ChalkBox/actions/workflows/release.yml/badge.svg)](https://github.com/detok/ChalkBox/actions/workflows/release.yml)
[![Release](https://img.shields.io/github/v/release/detok/ChalkBox?include_prereleases&label=version)](https://github.com/detok/ChalkBox/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

ChalkBox helps you **avoid wasting useful items**, keep up with your camping buffs, and spend less time watching UI clutter. It combines item advice, XP tracking, quest assistance and a little character personality in **one addon, one ZIP, one settings menu**.

> **Status:** Public prerelease. Built primarily for **WoW Forever / Camelot**. We test Lua 5.1 behavior automatically, but game-specific behavior still needs community testing. Please [report problems](../../issues) with your client build and steps to reproduce.

## Install in about a minute

1. Open **[GitHub Releases](https://github.com/detok/ChalkBox/releases)** and download the newest **`ChalkBox-<version>.zip`** (not *Source code*).
2. Extract the ZIP into your WoW client's `Interface/AddOns` directory. The final path must be **`Interface/AddOns/ChalkBox/ChalkBox.toc`**.
3. Enable **ChalkBox** on the character-selection AddOns screen. Launch the game or type `/reload` if you updated it.
4. Type **`/chalk`** or open **Esc → Options → AddOns → ChalkBox**.

**Only install the ChalkBox ZIP.** It includes the icon, both compatible `.toc` files, and all first-party modules. You do **not** need the old standalone Don't Sell That or EmotaSpeak addons.

## Why use ChalkBox?

| Module | What it helps with |
| --- | --- |
| **LootSense** | Warns about quest items, player-protected items and materials used in **recipes your character knows**. Explains real camping uses; never auto-sells or deletes. |
| **ProfessionSense** | Records relevant learned recipe ingredients when you open profession windows. Where the client provides them, keeps recipe names and quantities. |
| **CampSense** | Checks the **Camp Benefits** aura, reminds you when it is missing/expiring, and shows a small **center-screen toast**. Also tracks camp tools and class/pet preparedness. |
| **TrailBar** | Slim 18px bar for XP/hour, time to level, gold and time, with real screen-space reservation. |
| **QuestSense** | Helps manage native tracking for accepted quests in the area without replacing your quest log. |
| **QuietGuard** | Tries to decline unsolicited guild invites and duels; optional filters for other invitations. |
| **Emota** | Occasional native emote personality with race/class flavor, resting-area context and hunter-pet awareness. |

### LootSense: avoid selling something useful

An item can be important because it belongs to an active quest, is in your personal keep list, or is a reagent in a **learned recipe**. ChalkBox prefers those *proven* uses over generic speculation. Example, when supported by your character's profession scan and live inventory:

```text
LootSense: KNOWN RECIPE: Camp Tent (Leatherworking) - 3/5 in bags
```

Open your crafting profession windows once after installing. `/chalk loot scan` refreshes scans, and `/chalk loot status` explains what's available. Hold **Shift** over an ingredient for more learned recipe uses, when detected.

An optional separately installed **[LibProfessionDB](https://www.curseforge.com/wow/addons/libprofessiondb)** can supply a broader *potential-use* catalog. **ChalkBox does not bundle its third-party files**, and compatibility with that optional library still needs live-client verification. It must never say *known recipe* unless your character's own data supports it. See [recipe data and licensing](docs/RECIPE_DATA.md).

**ChalkBox will never declare an unknown item safe to sell.** It doesn't automate selling, trading, deleting, purchasing or item use.

### Camping reminders you can actually see

Use **`/chalk prep test`** to preview the central reminder instantly. **`/chalk prep`** prints your available camp tools and known buff state. The addon checks for Forever's **Camp Benefits** aura and tries not to bother you while you are already receiving **Welcoming Campfire** benefits. The toast automatically fades after nine seconds; turn it off in **Adventure Prep** if you prefer chat-only reminders.

### Useful commands

| Command | Action |
| --- | --- |
| `/chalk` or `/cb` | Open ChalkBox settings |
| `/chalk loot status` | Check recipe/profession detection |
| `/chalk loot scan` | Rescan currently available learned recipes |
| `/chalk keep [item]` | Protect an item by name or shift-clicked link |
| `/chalk forget [item]` | Remove a personal protection |
| `/chalk prep` | Print camping and buff checklist |
| `/chalk prep test` | Display a test toast |
| `/chalk guard` | See social invite protections |
| `/chalk bar status` | Check TrailBar placement and reserved space |
| `/chalk emota idle preview` | Test a random idle emote |

More guidance: [User guide](docs/USER_GUIDE.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Changelog](CHANGELOG.md).

## For developers and contributors

ChalkBox is pure Lua 5.1 plus a small Python packaging script. It's **not a runtime AI service**; the item advice is evidence-based, local and readable.

```bash
# Syntax and all module regression tests (Lua 5.1 required):
find ChalkBox tests -name '*.lua' -print0 | xargs -0 luac5.1 -p
for test in tests/test_*.lua; do (cd ChalkBox && lua5.1 "../$test"); done

# Build and verify one reproducible installable ZIP:
python3 scripts/test_packages.py
```

GitHub Actions runs these checks on pull requests, then publishes the single-addon ZIP when a new version reaches `main`. See [Contributing](CONTRIBUTING.md) and [Development](docs/DEVELOPMENT.md).

**Privacy:** ChalkBox stores settings and observed profession information in WoW SavedVariables, not on a web server. Its modules do not make external network requests.

## License and acknowledgements

**MIT-licensed** — see [LICENSE](LICENSE). Created by **Detok**. Thanks to the WoW Forever community for testing and feedback. ChalkBox's optional recipe-library adapter credits **Pmptasty / LibProfessionDB**; no copy of that project or its database is included here. More at [NOTICE](NOTICE.md).

If something looks wrong in your game, please [open a bug report](../../issues/new/choose). Include your WoW client build, ChalkBox version and the exact tooltip or message you saw.
