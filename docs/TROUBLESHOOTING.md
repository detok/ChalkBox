# Troubleshooting ChalkBox

**Current baseline: 2.2.17 · World of Warcraft: Forever**

This page covers issues you can diagnose safely without deleting SavedVariables, reinstalling unrelated addons or modifying Blizzard's protected interface.

**First:** confirm the installed version under **ChalkBox → Updates**, type `/reload` after replacing addon files, and make sure the installed path is `Interface/AddOns/ChalkBox/ChalkBox.toc` (not a duplicate nested ChalkBox folder). Then run the module's `status` command from [Commands](COMMANDS.md).

## Quick diagnosis

| Problem | First thing to check |
| --- | --- |
| Addon missing from the AddOns list | Wrong game directory, double-nested extracted folder or incomplete download — use the **addon** ZIP, not Source code or media ZIP |
| ChalkBox settings look strange | Confirm version 2.2.17; native Settings pages should **not** have a solid black sheet over Blizzard's background |
| Discoveries button or journal missing | Open the native World Map; run `/chalk drops map` and `/chalk drops map status` |
| Discoveries shows no items | Run `/chalk drops status`; only **observed, readable** loot windows are saved; choose a zone/dungeon with prior observations |
| No coordinates for an item | Only later outdoor loot-window observations with usable map coordinates get location samples; dungeon and older rows have no invented positions |
| Map-derived wood texture missing | Native atlas may be unavailable on this client; reopen the window after `/reload`, note exact client build and attach a screenshot |
| QuestSense tracks unexpected quests | Verify Smart / Nearby / All mode, `/chalk quests status`, whether the map/quest log/combat is preventing updates |
| QuestSense tracker menu absent | It is attached only if the native Blizzard header/tracker allows a safe mouse hook; custom replacement trackers may not. Use Options → AddOns → ChalkBox → QuestSense, or `/chalk quests` |
| MacroForge tab missing in `/macro` | The integration requires an exposed native `MacroFrame` with Delete/New/Exit footer buttons and enough room between them. It intentionally leaves other layouts untouched. Opening Forge from ChalkBox settings closes Options and attempts the native /macro dock. `/chalk macro` always opens standalone; cramped screens intentionally skip side docking |
| Quest compass missing or not pointing | It starts OFF. Enable under QuestSense → Navigation or `/chalk nav on`; right-click the bare arrow for Auto / Next / Hide, or hover for its quest and yard distance. Inspect `/chalk nav status`; missing waypoints, dungeons and different regions with unavailable world coordinates deliberately suppress the direction. **Your corpse** takes priority while a ghost if Forever exposes its position; if your quest selection changes, Auto follows it and retains that quest even when its waypoint temporarily disappears |
| Dungeon quests aren't filtered | Enter a **party** instance with accepted quests; Smart needs trustworthy instance/quest map or matching dungeon-header information |
| MacroForge has no spells | Open the character's actual active spellbook, click **Rescan Spellbook** or use `/chalk forge rescan` |
| Macro text is weird or too long | Review the generated preview and warnings; `/castsequence` and multiple `/cast` lines cannot bypass cooldown/GCD requirements |
| Full Scan fails but Browse Scan works | Full Scan uses a heavier account-wide replicate API with a roughly 15-minute successful-request cooldown; another addon can consume it. Version 2.2.17 accepts valid numeric listings before item names cache. Run `/chalk auction status` for the specific refusal or timeout; continue using Browse Scan meanwhile |
| AuctionSense scan does nothing | Visit an auctioneer and open the **AuctionSense** tab; request a scan manually, check server cooldown and `/chalk auction status` |
| DE estimate is absent | Not all gear/brackets or AH materials have reliable outcome or price data; try `/chalk de [item]` |
| Bar hides or overlaps something | Check Bar status, top chrome shift, screen width and existing saved per-character layout |
| Adventure Journal is transparent or borderless | Open `/chalk session`; version 2.2.17 has a native border and opaque fallback even with global opacity 0. If art is missing, note the client build and retry after reopen; v1 session data should remain intact |
| Compact Combat Meter empty | It **starts hidden**; use `/chalk meter show`. Native data can be unavailable or protected |
| QuietGuard blocks an invite unexpectedly | Check saved ON filters and **Blizzard's own built-in social settings** |
| Emota appears inactive | Automatic emotes require opt-in; idle pacing is intentionally slow and no automated emotes run in combat |

## Installation, updates and SaveVariables

Get the game ZIP from [GitHub Releases](https://github.com/detok/ChalkBox/releases). It should extract into exactly one `ChalkBox/` directory. The additional CurseForge Media ZIP is publishing material, **not** a working addon.

If a change isn't showing, compare the TOC version installed with the version in **ChalkBox → Updates**. Close the game when replacing files, relaunch and type `/reload`. Do **not** delete WoW's SavedVariables as your first troubleshooting step: those hold personal KEEP selections, character loot history, Bar arrangements, session history and market observations. If you truly need to isolate corrupt state, back up the files first and report the suspected key.

## Discoveries: map docking, lists and artwork

Use `/chalk drops map` to open the journal even when the map button is hard to see. `/chalk drops map status` prints attachment and map-button diagnostics. `/chalk drops map reset` restores the draggable button.

The **Area / Dungeon** dropdown displays recorded places, not every unvisited location in the game. The Creature dropdown requires identified source records. An ambiguous source does not produce a creature-specific rate. Choosing **Follow world map** (or enabling map sync) returns the journal to the map's current selection.

If a popup appears behind the map or the body doesn't render, report whether the labels, buttons and item rows are individually visible, whether the whole panel has a border, and which UI scale / game client you are using. Do not substitute a random third-party art path for a native atlas that isn't available.

**Outdoor location feature:** Only loot events since 2.2.8 with a usable C_Map position receive location samples. A coordinate describes where the *player opened the loot window*, not precisely where the creature died. Up to six distinct sites are kept; hover shows up to three. It is normal for old/dungeon items to have no coordinates.

## QuestSense: Smart, Nearby and dungeons

Run `/chalk quests status`. The output includes selected mode, accepted/candidate/watched counts, last update reason and (for a recognized dungeon) dungeon name and matched count.

- **Smart outdoors:** Prioritizes accepted quests with map/header relevance and recently accepted quests. It doesn't calculate optimal leveling routes.
- **Smart in a party dungeon:** Only confirmed quests for that *specific instance* are automatically selected. Previous manually tracked nonmatching quests are temporarily suspended and restored on exit. Generic Dungeon tags cannot prove which instance a quest belongs to.
- **No confirmed dungeon matches:** ChalkBox intentionally **preserves your current tracker** rather than hiding every quest. This is safer than guessing, especially for Forever custom quests.
- **Nearby only:** Temporarily hides remote watches and restores manually selected ones when they become relevant. It doesn't infer precise walking distance.
- **World Map, Quest Log or combat open:** Watch-list edits can be deferred. Close the window or leave combat, then use `/chalk quests refresh`.

If you manually uncheck a quest, QuestSense should not immediately force it back. Capture the status output and exact mode if it does.

## AuctionSense, AuctionInsights and disenchanting

**AuctionSense** runs at the native Auction House only. The standard **Scan Market** is a manual browse asking-price scan. **Full listings** is a separate request limited by server readiness/cooldown (often approximately 15 minutes). A failed or incomplete scan should not replace a previously complete snapshot with fabricated zero prices.

Prices are **asks**, not confirmed sales. Average asking price or listing counts can be unavailable for browse-only summaries. Mixed equipment variants, old scans or missing material prices limit value accuracy. **Sales & Stats** only summarizes observed supported mail receipts; it cannot reconstruct your full trading history.

If a new item shows no disenchant estimate, use `/chalk de [item]` to read the reason, including missing modeled bracket or unpriced outcomes. ChalkBox never disenchants an item automatically.

## MacroForge, Bar and native UI

MacroForge's generated preview is a **multiline scrolling editor**; it displays the macro before you copy or choose **Install New**. A macro cannot automatically select cooldown-ready spells or perform a rotation for one button press. Saved Builds are character-specific. If the optional second **AddOn Compartment** entry stays visible after disabling it, use `/reload`; a reliable native unregister method is not available on every build.

For The Bar, right-click empty bar space to enter Edit Mode and again to select **Done editing**. Right-clicking a stat while editing controls alignment. A **Reset Layout** uses current fresh-install defaults and intentionally changes the customized arrangement, so it should be a deliberate choice. Some stats hide at narrow widths; a user-saved arrangement is not silently replaced on upgrade.

If Blizzard bank panels or bag buttons report a blocked action, note the exact error and whether it occurred at **first bank open**. ChalkBox intentionally defers separate-bag repositioning during bank initialization and avoids modifying protected item buttons. `/chalk bags status` shows pending offsets.

## Combat Meter and camp reminders

The compact meter starts closed. You must explicitly show it. Fight values may remain protected or unavailable; PRINT to PARTY is a manual action gated by safe client data and party context. For a blank Fight session try Last; see `/chalk meter status`.

A **Camp Tent's rested-XP benefit** is not the same as a verified **Camp Benefits** aura. If the UI cannot establish tent use, `/chalk prep tent done` acknowledges it for one hour **in the session only** and grants no real game effect. Toast position, opacity and lock are adjustable under **Adventure Prep → Toast Appearance**.

## Emota, QuietGuard and the Updates page

Automatic Emota behavior is optional, uses randomized idle delays and intentionally avoids combat; try `/chalk emota idle preview` for a deliberate demonstration. Native emote APIs can report success differently from what the game visually animates.

QuietGuard's guild, duel, party, trade and channel filters default OFF on **new installs**, but older explicitly enabled filters persist. Blizzard may also be blocking social actions. Check both before assuming ChalkBox caused the issue.

The **Updates** page cannot fetch current GitHub releases over HTTPS from WoW. It shows the installed version and a copyable link and can compare versions seen from other ChalkBox group members. An empty peer result does not mean there is no new release.

## Report a useful bug

Use [GitHub's bug report form](https://github.com/detok/ChalkBox/issues/new/choose). Include the installed ChalkBox version, Forever client/build, relevant zone/instance, clear reproduction steps, expected and actual result, `status` output and the exact Lua error stack if one exists. Cropped screenshots help; redact private chat and account details.

For earlier version-specific fixes, see the [historical changelog](../CHANGELOG.md). The current user-facing behavior is documented in the [player handbook](USER_GUIDE.md).

[Documentation home](README.md) · [Commands](COMMANDS.md) · [Maintainer runbook](MAINTAINER_RUNBOOK.md)
