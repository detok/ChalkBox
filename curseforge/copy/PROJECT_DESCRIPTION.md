# ChalkBox

**One addon. Better information. Less UI clutter.**

ChalkBox brings loot insights, quests, market information, macros and handy adventure tools together in **World of Warcraft: Forever**. It works with the game's familiar windows instead of covering your screen in unrelated addons. Turn on the tools you want, keep the ones you don't use out of the way, and get back to playing.

**ChalkBox 2.2.22 is our first stable release.** Its full AuctionSense scan has completed in live Forever playtesting, and the auction data now works with the connected bag and item-information features. That's the milestone that brought the project out of beta.

## Everything in one addon

### LootSense & Professions — know why an item matters

See supported quest-item hints, accepted quest names and objective progress when the game supplies a reliable match. Keep a personal **KEEP** list, distinguish learned recipes from possible profession uses, and make decisions before selling valuable materials. ChalkBox doesn't sell, destroy or move inventory automatically.

### AuctionSense — market data inside the Auction House

The native **Market** tab puts the information right where you need it. **Scan Market** gathers available browse summaries; an optional manual **Full listings** scan gets detailed auction evidence when Forever responds. Completed full scans provide minimum and weighted-average asking prices, listing counts and quantities, with an honest progress display and a server-imposed cooldown. A failed or incomplete scan retains the last good snapshot.

The data also helps **AuctionInsights** appraise bags and can supply material prices to **DisenchantSense**. Supported seller-mail receipts appear separately under Sales & Stats. No unattended scans, bids, purchases or listings.

*These are asking prices, not proof that an auction sold. DisenchantSense estimates use reference outcome probabilities and available material asks—not guaranteed Forever disenchant results.*

### DropSense & Discoveries — remember what you found

ChalkBox records loot observed in readable loot windows. Explore that history from a searchable **Discoveries** side panel beside the World Map: zone, dungeon and source filters; recorded counts; and observed rates when there is enough trustworthy information. Recent outdoor loot-window positions can appear as map markers. They record where you opened the loot window, not guaranteed creature spawns.

### QuestSense & Navigation — keep your tracker useful

Keep Blizzard's accepted quest tracker focused with Smart, Nearby and All modes. Where the client provides reliable dungeon matching, Smart prioritizes accepted quests for that specific instance and restores manual watches afterward. Optional Navigation adds a small, movable arrow for supported quest waypoints. It doesn't invent routes or rewrite protected map controls.

### MacroForge — build it your way

Choose from learned abilities and macro templates, preview the generated text, save recipes and copy the result. Explicitly install a **new** native macro outside combat where supported. The Forge can dock beside Blizzard's macro editor on roomy screens; it doesn't overwrite your existing macros or automate combat rotations.

### The Bar, Combat Meter & Adventure Journal

Use **The Bar** for XP, time to level, money, bags, durability, repair estimates, latency and more. Edit its layout and opacity. The optional **Combat Meter** starts closed and offers supported data and manual reporting. The **Adventure Journal** preserves bounded summaries of your observed sessions.

### Small conveniences, designed to stay small

Camping and supply reminders, optional Emota personality, opt-in QuietGuard social filters, bag placement, color settings and installed-version information. The goal is a useful companion, not another wall of windows.

## Get started

1. Install **ChalkBox-2.2.22.zip** from [GitHub Releases](https://github.com/detok/ChalkBox/releases/tag/v2.2.22) or the matching approved CurseForge game file. Do not install GitHub's automatic source archive or the separate publisher-media ZIP.
2. Extract the single `ChalkBox/` folder into the Forever client's `Interface/AddOns/` directory.
3. Open **Options → AddOns → ChalkBox** or type `/chalk`. Preserve your existing SavedVariables on upgrades.

All major tools are part of the same addon. The bundled recipe data ships with ChalkBox; there is no separate companion installer.

## Support, feedback and source

Found a bug? Want to suggest a feature? You don't need to know Lua. Choose a [guided issue form](https://github.com/detok/ChalkBox/issues/new/choose) for bugs, setup questions, compatibility problems or ideas. Include your ChalkBox version (use `/chalk update`), your Forever client build if available, what happened and the steps to reproduce it. For AuctionSense issues, include `/chalk auction status`.

[Player handbook](https://github.com/detok/ChalkBox/blob/main/docs/USER_GUIDE.md) · [Commands](https://github.com/detok/ChalkBox/blob/main/docs/COMMANDS.md) · [Troubleshooting](https://github.com/detok/ChalkBox/blob/main/docs/TROUBLESHOOTING.md) · [Source code](https://github.com/detok/ChalkBox)

## Compatibility, license & credit

**Built for WoW Forever.** Retail and ordinary Classic compatibility are not claimed. Some features depend on the client's native API and may show “unknown” rather than guess. Drop rates are personal observations, auction prices are asks rather than sales, and disenchant probabilities are clearly labeled reference estimates.

Created and maintained by **Detok Whitemaine**. ChalkBox's original code is MIT-licensed, with separate notices retained for bundled third-party libraries. Independent community project; not affiliated with or endorsed by Blizzard Entertainment.
