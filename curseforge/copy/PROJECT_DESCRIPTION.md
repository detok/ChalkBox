# ChalkBox

**A handful of good ideas, all in one addon for WoW Forever.**

ChalkBox started as a way to get better information out of the game without adding a dozen separate windows. It now covers loot, professions, quests, combat, camping, macros and a little bit of character personality. You can turn each part on or off and arrange the pieces to suit your UI.

## Loot worth remembering

**DropSense** keeps a personal record of items ChalkBox sees in loot windows. Open the world map and click **Discoveries** to browse what you've found in an outdoor zone or dungeon. The browser has item search, creature-source filtering, sorting and a readable list of your observations. You can drag the Discoveries map button to a better spot.

Those percentages aren't official drop rates. They're the frequency with which an item appeared in **readable loot windows from an identified source**. ChalkBox doesn't see every kill, and it doesn't guess a percentage for mixed or unknown sources.

**LootSense** helps you figure out why an item matters before you get rid of it. It recognizes your manually protected KEEP items, supported quest relevance, known profession ingredients and potential crafting uses. **ProfessionSense** can inspect recipes you've learned and use the bundled Forever recipe reference to add context. Neither system sells or destroys items.

## Better buttons with MacroForge

MacroForge builds macros from spells currently in your character's spellbook. Choose an opener, a burst/trinket setup, modifier keys, a mouseover action or a manual cast sequence. The builder shows the exact macro text, flags missing abilities, and helps avoid overly long macros.

Copy the result into WoW's macro editor, or explicitly create a new character macro outside combat. MacroForge won't overwrite an existing macro. It **doesn't run combat rotations, react to procs by itself or bypass the global cooldown**.

## The Bar, combat and progress

**The Bar** is an optional 18-pixel strip for the information you want to see: level and XP, rate and ETA, bag space, gold, durability, rested XP, pet status and other selected stats. It has right-click layout controls and optional bag resale value.

At a repair merchant, ChalkBox can read an exact repair quote. Away from the merchant it uses past observed quotes to make an estimate; estimated costs are marked with a tilde.

The optional **Combat Meter** displays DPS, damage, healing and other supported Blizzard combat figures. It starts **closed when you log in**. Open it when you want it, and use the manual PARTY report only when you choose. ChalkBox also has a separate manual PRINT action for Blizzard's native meter when available.

**Session Journal** records the current adventure and up to 20 previous sessions, including observed XP, quests, gold changes, sampled loot and other events. It doesn't invent past sessions or unsupported data.

## Smaller improvements

- **QuestSense:** accepted-quest watch management within Blizzard's own tracker.
- **Adventure Prep:** practical reminders for known camping supplies, tent/rested-XP status, buffs and supported class or pet care.
- **Global Appearance:** a shared color palette and background controls for ChalkBox windows.
- **Emota:** optional contextual character emotes.
- **QuietGuard:** configurable invite filtering.
- **Bag Position:** adjust the placement of the game's separate bag windows.
- **Updates:** installed version and a link to GitHub Releases, plus optional comparison with other ChalkBox users in your group.

## Settings and installation

The options live under **Options → AddOns → ChalkBox**, or type **/chalk**. Modules have their own pages, with related controls nested underneath: for example **The Bar → Modules / Appearance**, **Adventure Prep → Toast Appearance**, and **Emota → Race Behavior / Emote Catalog**.

Install the **ChalkBox** folder in your Forever client's **Interface/AddOns** folder. Everything needed is included, including the profession recipe data. Keep your SavedVariables when upgrading.

## Compatibility

ChalkBox is developed for **WoW Forever**. Retail and Classic Era have not been tested. Some data depends on what the Forever client exposes. This 2.0.2 package is a **test build** while the new settings hierarchy and startup behavior are checked in-game.

Source and issue tracker: https://github.com/detok/ChalkBox

**Created and maintained by Detok Whitemaine.** MIT-licensed, with original third-party notices retained. Independent community software; not affiliated with Blizzard Entertainment.
