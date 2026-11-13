# ChalkBox — The Quiet Adventure Companion for WoW Forever

**One addon. Real information. Less busywork. More time adventuring.**

ChalkBox is a modular collection of quality-of-life tools for **World of Warcraft: Forever**. It adds context to loot, remembers your discoveries, turns your spellbook into useful macros, helps you prepare for camp, and provides a compact dashboard—without replacing Blizzard's familiar interface.

The package includes everything it needs. **No secondary addons, cloud accounts or AI services are required.** Choose the features you want under **Options → AddOns → ChalkBox**.

## What makes ChalkBox different?

### Map Discoveries + automatic DropSense

ChalkBox records items it can read in your loot windows and builds a **personal field guide** over time. Open the existing world map and use the optional **Discoveries** button to browse outdoor loot, separately recorded dungeons and identifiable creature sources.

A percentage is **your own observed loot-window frequency** for a known creature source, never an official or all-kills drop rate. Uncertain, mixed-source or unavailable observations show collection counts without fabricated odds. Server loot tables are not exposed to the addon.

**World map button missing?** Type **/chalk drops map** to open the browser directly. **/chalk drops map status** diagnoses whether it attached and is visible. The 2.0 map-position fix is being verified in the Forever client.

### MacroForge — build macros from your actual spellbook

MacroForge is a guided tool for building usable macros without memorizing macro syntax. Choose a purpose—**Engage, Burst + Trinkets, Modifier Keys, Manual Sequence, or Mouseover Utility**—and select abilities your character knows.

Generate copy-ready macro text, see the 255-byte safety limit, and read why a castsequence might stall or two GCD-locked spells won't execute in the same press. Save up to 16 build recipes per character. Optionally create a new character-specific WoW macro with an **explicit, out-of-combat click**; existing macro names aren't overwritten.

MacroForge **does not** automate rotations, detect procs for secure conditionals, or bypass WoW's GCD.

### LootSense + ProfessionSense — know why loot matters

- Prioritize items you marked **KEEP** and supported quest relevance.
- Recognize reagents actually observed in **learned recipes**, distinct from **potential recipe uses** in the bundled catalog.
- Add subtle, optional native bag highlights only when a learned recipe truly uses an ingredient.
- Consult **2,511 included Forever recipes** without installing a second recipe database.
- Flag practical camp supplies when the client can identify them.

No misleading **safe-to-sell** guarantees. No automatic selling, buying, destroying or using items.

### The Bar — your adventure at a glance

A thin, customizable **18-pixel** status strip shows your level, XP rate/ETA, free bag space, gear durability, rested XP, optional Hunter pet/latency, session time, gold, optional Junk/Total **vendor resale value**, and learned repair estimate.

**Right-click a module** to hide or move it and open relevant settings. The Bar can follow the top or bottom of your screen and intelligently fits the space available.

Repair cost is exact only while a repair-capable merchant exposes the real bill. Elsewhere it displays a **~ estimate** learned from prior observed quotes; if unreliable, it shows an unavailable state rather than inventing a price.

### Session Journal, combat and preparation

- **Session Journal:** current and up to **20 previous adventures** with observed XP, levels, net gold, quests, sampled loot regions, camp prompts and repair quotes.
- **Combat Meter:** compact DPS, damage, healing and interruptions view; manual PARTY result printing. You can instead keep Blizzard's native meter and use ChalkBox's separate **PRINT top 3 to PARTY** gear-menu entry when supported.
- **QuestSense:** Smart/Nearby/All accepted-quest watch modes in Blizzard's native tracker.
- **Adventure Prep:** smarter camping, tent/rested-XP and class/pet reminders, with a compact movable notification. It avoids repeating unchanged warnings by default.
- **Global Appearance:** shared charcoal/midnight/slate/custom color and accent choices, with background opacity separate from text.
- **QuietGuard, Emota and Bag Position:** optional invite filtering, contextual character personality and separate-bag adjustments.

## Getting started

1. Install the file from **Files** into your Forever **Interface/AddOns** folder, leaving one top-level **ChalkBox** directory.
2. Open **/chalk** for settings.
3. Try **/chalk macro** for MacroForge, **/chalk drops map** for Discoveries, or **/chalk session** for your adventure recap.
4. Loot as you normally do; enable DropSense sampling if you previously switched it off.

**ChalkBox 2.0.0 is a prerelease for client testing.** Lua regression tests and single-addon ZIP packaging run in GitHub CI; native Forever map layouts and some client-restricted APIs still need player testing. Please include your Forever build and an error or screenshot when reporting bugs.

ChalkBox is independent community software. **Not affiliated with Blizzard Entertainment.** Distributed under MIT with retained third-party library notices.

*Editorial illustrations are not in-game screenshots. Genuine client screenshots will follow real-client verification.*
