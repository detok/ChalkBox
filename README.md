<div align="center">

# ✦ ChalkBox

### A quieter, smarter way to adventure in **World of Warcraft: Forever**

**Keep what matters. See what helps. Play without the clutter.**

[![Version](https://img.shields.io/github/v/release/detok/ChalkBox?include_prereleases&label=ChalkBox&color=DDAE61)](https://github.com/detok/ChalkBox/releases)
[![Tests and package](https://github.com/detok/ChalkBox/actions/workflows/release.yml/badge.svg)](https://github.com/detok/ChalkBox/actions/workflows/release.yml)
[![MIT](https://img.shields.io/badge/license-MIT-67C6B7.svg)](LICENSE)
[![Forever](https://img.shields.io/badge/WoW-Forever-203342.svg)](https://github.com/detok/ChalkBox)

### [⬇ Download ChalkBox 1.8.6](https://github.com/detok/ChalkBox/releases/download/v1.8.6/ChalkBox-1.8.6.zip)

[**All GitHub Releases**](https://github.com/detok/ChalkBox/releases) · [**Install Guide**](#-install-in-one-minute) · [**Features**](#-what-chalkbox-does) · [**Help & Bugs**](https://github.com/detok/ChalkBox/issues)

</div>

> [!IMPORTANT]
> **GitHub is ChalkBox's primary download home.** You can install it directly from GitHub Releases, without a CurseForge account or application. A CurseForge listing is being prepared as an **additional** distribution option, not a replacement for GitHub.

---

## 🧭 What is ChalkBox?

ChalkBox is a **single, self-contained WoW Forever utility addon** for the moments between the big fights: recognizing items worth checking before you sell, keeping quests visible, tracking progress, remembering camp benefits and sharing combat results with your party.

It adds **small, genuinely useful information** while keeping Blizzard's familiar UI wherever possible. No second recipe addon, no online service, no random windows for every task.

<div align="center">

**ONE ADDON** · **ONE ZIP** · **ONE SETTINGS MENU**

</div>

## ✨ What ChalkBox does

| Module | What you get | Why it matters |
| :--- | :--- | :--- |
| **📦 LootSense** | Contextual **KEEP**, **KNOWN RECIPE**, **POTENTIAL USE**, camping and profession hints | Understand *why* an item could matter before selling it |
| **🧪 ProfessionSense** | Learned-recipe reagent scans, quantities where the client allows, 2,511 bundled Forever recipes | No separate crafting database download |
| **📈 TrailBar** | Adaptive **18px** strip for XP, gold, **free bag slots, gear durability, rested XP, latency and Hunter pet health** | All the stats you actually want—without another window |
| **⚔️ Combat Meter** | Compact DPS/DMG/HPS/HEAL/TAKEN/INT, class icons, draggable window, PRINT/RESET | A readable optional meter using Blizzard's own data |
| **💬 Blizzard meter PRINT** | A new **PRINT top 3 to PARTY** entry in Blizzard's existing damage-meter gear menu | Keep the **native** meter and still share a concise fight report |
| **📜 QuestSense** | Smart / Nearby / All accepted-quest watch modes in the native tracker | Stay focused without inventing map pins or quest arrows |
| **⛺ Adventure Prep** | Camping aura/tent awareness, optional movable top-screen toast, class/pet reminders | Useful reminders with less nagging |
| **🛡️ QuietGuard** | Guild/duel invite protection; other restrictions optional | Less invite spam while keeping ordinary party play available |
| **🎭 Emota** | Opt-in contextual idle emotes and emote catalog | A little personality when *you* want it |
| **🎒 Bag position helper** | Optional 0–80-point downward offset for separate bags | Helps when large profession bags stack above the screen |

Every module has native in-game options. **No automated item selling, no fabricated quest locations, no automatic PARTY combat spam.**

---

## 🖥️ See it in action

**Authentic gameplay screenshots and polished banners are in production.** This first-pass README intentionally contains no mocked gameplay imagery.

Artwork specification and game-capture shot list: [CurseForge / GitHub media plan](curseforge/ARTWORK_TO_CREATE.md) · [Screenshot checklist](curseforge/artwork/SCREENSHOT_PLAN.md).

These screenshots will be added when we have verified captures of LootSense, TrailBar, Blizzard's meter gear-menu PRINT, QuestSense and the settings pages.

## 📦 LootSense: a reason to keep it

Some items belong to a quest. Some are ingredients in **recipes your character knows**. Some have real camp utility. And some have only a **potential recipe use** according to the bundled Forever catalog.

ChalkBox tries to explain the difference on the item's tooltip:

- **KEEP** — personal protected list or verified quest relevance
- **KNOWN RECIPE** — an observed learned recipe uses this reagent
- **POTENTIAL USE** — a recipe exists in the bundled catalog, but isn't verified as learned
- **PROFESSION: possible** — cautious ingredient-family match; double-check the crafting UI
- **No added line** — ChalkBox has no strong reason to annotate the item; **that does not mean safe to sell**

**There are 2,511 Forever recipes included in the ZIP.** The optional hints and character-specific learned-recipe scanner are deliberately distinguished. Open your crafting profession window once and use `/chalk loot scan` if you want to refresh its knowledge.

ChalkBox **never** sells, buys, deletes, trades or uses items for you.

## 📈 TrailBar: more information, same 18 pixels

**This is new in v1.8.6.** TrailBar now shows far more than XP and gold, yet stays the **same 18 pixels tall**. It's a customizable status dashboard—not a big floating window.

| Module | What you see | Mouseover detail | Default |
| --- | --- | --- | --- |
| **Level** | Level + XP % | Exact XP amounts | Always |
| **XP rate** | XP/hour | Session earnings | On |
| **To level** | ETA | Estimate methodology | On |
| **Bags** | **12 free** (example) | Total bag slots, general vs. profession-only free slots | **On** |
| **Gear** | **87%** (example) | Weighted equipped durability and lowest-condition item | **On** |
| **Rested** | **42%** (example) | Bonus XP and percent of one level; separate from camp buffs | **On** |
| **Pet** | **95%** or **Pet none** (Hunters) | Pet health when the client permits it; protected values show unavailable | On for Hunters |
| **Latency** | World ping in ms | Home and world latency separately | Off |
| **Session** | Time online | Session duration | On |
| **Gold** | Current gold + net change | Net gold per hour | On |

### Layouts that fit

In **Esc → Options → AddOns → ChalkBox → TrailBar Stats**, turn each module on or off. Or choose **Balanced** (recommended), **Minimal** (level, bag space, gold), or **All**. The bar automatically hides low-priority numbers when the screen is too narrow to fit them—**no overlapping labels** or overflowing off-screen. Widening your UI makes those enabled fields appear again. Hover items for useful detail.

Try `/chalk bar stats` to inspect enabled vs. currently visible modules. `/chalk bar stats all` turns everything on; `/chalk bar stat latency on` enables the world ping field. A metric whose Forever API is unavailable stays hidden rather than making up a number.

The strip still supports **top / bottom / hidden**, 18px **Reserve screen space** (default), and a tiny XP progress line. Use `/chalk bar status` for layout diagnostics.

If separate bags stack too high, **ChalkBox → TrailBar** also has a **Separate bags: move down** slider. It starts at zero, only affects individually opened bags, and doesn't replace Blizzard's containers or inventory sorting. Try `/chalk bags offset 30`.

## ⚔️ Combat: your choice of meter

### Prefer Blizzard's built-in damage meter?

Keep it. ChalkBox **v1.8.5** extends the native Forever damage meter's existing **gear menu** with **ChalkBox: PRINT top 3 to PARTY**. It follows the selected **native** meter statistic and fight (including saved sessions when available).

It sends **one manual, after-combat PARTY message**, only when you are actually in a normal party and Forever exposes non-secret numbers. No automatic reporting, no raid or public-chat fallback. Combat-protected values are never formatted or leaked.

Use `/chalk meter hide` to hide the *extra* ChalkBox window while leaving the Blizzard integration enabled. Use `/chalk meter native status` to check the integration.

### Prefer ChalkBox's compact window?

That's included too:

- Modes: **DPS / Damage / HPS / Healing / Damage Taken / Interrupts**
- Scope: **Fight / Last / Overall**
- Class-colored rows with genuine WoW class badges; optional spec art where available
- Drag, resize, **LOCK**, opacity **35–100%**, 5/8/12 row layouts
- **PRINT** to PARTY after combat
- **RESET** with confirmation; it clears *shared Blizzard session data*, not just ChalkBox

**Client note:** the built-in gear-menu addition, separate-bag offset and newest TrailBar native-data widgets have Lua tests, but still need real-world Forever-client confirmation. If your client blocks an action or secret value, ChalkBox reports that rather than guessing.

## 📜 Quests, camping and a little personality

**QuestSense** reads your real accepted quests and updates Blizzard's native tracker. Its **Smart** mode prioritizes current-zone and recently accepted quests then fills available watch slots. **Nearby only** and **All accepted** are also available. Manually watched quests are respected, and changes wait when the game is in a restricted state. This is **watch management**, not a Questie replacement or a route finder.

**Adventure Prep** checks supported **Camp Benefits**, **Welcoming Campfire**, Camp Tent/rested-XP indicators and relevant supplies. Optional top-screen notifications fade automatically. You can move the toast, set its opacity and lock it to avoid stealing game clicks. Test it with `/chalk prep test`.

**QuietGuard** helps against unwanted guild invitations and duels, with party/trade/channel filtering **off by default**. **Emota** offers optional randomized character emotes and an emote catalog; automatic idle behavior starts **disabled**.

---

## 🚀 Install in one minute

**Direct download:** [**ChalkBox 1.8.6 ZIP**](https://github.com/detok/ChalkBox/releases/download/v1.8.6/ChalkBox-1.8.6.zip)  
**Newer versions:** [**GitHub Releases**](https://github.com/detok/ChalkBox/releases)

1. Download **`ChalkBox-<version>.zip`** from GitHub Releases — *not* the GitHub “Source code” archives.
2. In Battle.net, select **WoW Forever → Show in Explorer/Finder**. Open that installation's `Interface/AddOns` folder.
3. Extract the included **ChalkBox** folder directly into **AddOns**. It should look like:

   ```text
   World of Warcraft/
     _forever_/
       Interface/
         AddOns/
           ChalkBox/
             ChalkBox.toc
             ChalkBox_Camelot.toc
             Core.lua
             ...other included addon files
   ```

4. Enable **ChalkBox** from the character-select AddOns screen, then log in. Type **`/chalk`** or **`/cb`**.

> [!TIP]
> If the addon doesn't appear, check for the common **double-folder** mistake: `AddOns/ChalkBox/ChalkBox/ChalkBox.toc`. The `.toc` must sit directly under `AddOns/ChalkBox/`.

Your settings live in WoW SavedVariables; you don't need to delete `WTF` when updating.

### First five minutes

1. **`/chalk`** → explore the native addon settings.
2. Open your crafting profession window, wait for the list, then **`/chalk loot scan`**; hover a useful reagent.
3. **`/chalk prep test`** → preview the Adventure Prep toast.
4. **`/chalk quests status`** → check accepted quests and watch state.
5. Use Blizzard's damage meter or the optional ChalkBox one. Hide the latter with **`/chalk meter hide`**.

[Full user guide](docs/USER_GUIDE.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Release notes](docs/RELEASE_NOTES.md)

## ⌨️ Commands

| Command | What it does |
| --- | --- |
| `/chalk` / `/cb` | Open all native settings |
| `/chalk keep [item]` / `forget [item]` | Protect or unprotect a specific item |
| `/chalk loot scan` / `status` | Refresh or diagnose profession/recipe data |
| `/chalk quests status` / `smart` | Inspect or change quest tracking |
| `/chalk bar top` / `bottom` / `off` | Place or hide the status strip |
| `/chalk bar stats all` / `balanced` / `minimal` | Set TrailBar information density |
| `/chalk bar stat gear off` / `latency on` | Control individual widgets |
| `/chalk bags offset 30` / `reset` | Reposition individual bag windows or restore default |
| `/chalk meter hide` / `show` | Toggle the extra ChalkBox combat meter |
| `/chalk meter print` | Manually report top-three compact-meter results to PARTY after combat |
| `/chalk meter native on` / `off` / `status` | Configure Blizzard's gear-menu PRINT feature |
| `/chalk meter reset` | Confirm before resetting all shared damage-meter sessions |
| `/chalk prep test` | Preview the reminder toast |
| `/chalk emota idle preview` | Preview a random Emota reaction |
| `/chalk help` | Command overview |

**More:** [Full command reference](curseforge/copy/COMMANDS.md).

<details>
<summary><strong>❓ FAQ and common questions</strong></summary>

**Do I need CurseForge?** No. GitHub Releases is a complete direct-download option, with the same installable addon.

**Does ChalkBox automatically sell things?** No. Item advice is deliberately advisory.

**Is it for WoW Classic or Retail?** The project is focused on **WoW Forever / Camelot**. Do not assume other WoW flavors are fully supported.

**Does the native DPS print always work?** It can refuse reports while fighting, in raids/solo, or when data remains protected. That is by design.

**Does it replace bags?** No. The separate-bag offset only changes a native layout anchor.

**Can empty Action Bar 2 buttons disappear?** Yes via **Blizzard Edit Mode → Action Bar 2 → Always Show Buttons: off**. This is a **game feature**, not part of ChalkBox.

**More questions:** [Complete FAQ](curseforge/copy/FAQ.md).

</details>

## 🛠️ Help, bugs and feedback

ChalkBox is a **public prerelease**. Its Lua 5.1 tests and installable ZIP are validated automatically, but real Forever-client integrations can vary by build and client restrictions.

If you find a bug, [**open a GitHub issue**](https://github.com/detok/ChalkBox/issues) with:

- ChalkBox version and Forever build
- Exact steps to reproduce
- Expected versus actual behavior
- Relevant Lua errors, tooltip/chat text or a screenshot with private details removed

Issues: https://github.com/detok/ChalkBox/issues

## 🔧 Developers and contributors

This repository contains the **installable `ChalkBox/` addon**, Lua tests, a reproducible Python ZIP packager and an optional **`curseforge/` publishing kit**. The latter is **documentation and marketing only**; it is not distributed inside the game addon.

```bash
# Verify Lua 5.1 syntax and run all module tests
find ChalkBox tests -name '*.lua' -print0 | xargs -0 luac5.1 -p
for test in tests/test_*.lua; do (cd ChalkBox && lua5.1 "../$test"); done

# Build/test the one installable ZIP
python3 scripts/test_packages.py
```

GitHub Actions runs checks on pull requests and main, publishing `ChalkBox-<version>.zip` when a new version first reaches `main`. Subsequent documentation-only commits **preserve** the existing release rather than rewriting its tag.

[Contributing](CONTRIBUTING.md) · [Development notes](docs/DEVELOPMENT.md) · [Recipe data provenance](docs/RECIPE_DATA.md) · [CurseForge publishing kit](curseforge/README.md) · [Changelog](CHANGELOG.md)

## ⚖️ Credits and license

**ChalkBox by Detok** · [MIT licensed](LICENSE).

Includes separately MIT-licensed **LibProfessionDB 1.9.1 by Pimptasty** (2,511 Forever recipes) and the public-domain **LibStub** loader, with original copyright/licenses preserved in the installable ZIP.

Full credits: [NOTICE.md](NOTICE.md).

**Privacy:** ChalkBox stores options and profession observations locally using WoW SavedVariables. It does not require a separate account or external service.

**Independent community addon. Not affiliated with Blizzard Entertainment or CurseForge.**

<div align="center">

---

**ChalkBox** · *A quieter, smarter way to adventure.*

[**⬇ Download**](https://github.com/detok/ChalkBox/releases) · [**💬 Report a bug**](https://github.com/detok/ChalkBox/issues) · [**📖 User guide**](docs/USER_GUIDE.md)

</div>
