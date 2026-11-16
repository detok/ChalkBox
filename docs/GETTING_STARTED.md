# Getting started with ChalkBox

**For WoW Forever · 2.2.21 draft documentation; choose a published asset from GitHub Releases**

ChalkBox is one addon folder. It contains the runtime modules and their bundled static recipe reference files. There is no second AddOn to install, no account to connect, and no third-party service to configure.

## 1. Choose the correct download

From [GitHub Releases](https://github.com/detok/ChalkBox/releases), select the **`ChalkBox-X.Y.Z.zip`** asset for the version you intend to use. Choose the newest tested addon ZIP actually listed there for your Forever client. The 2.2.21 auction fix is a draft until released.

Do **not** download the auto-generated `Source code (zip)` archive. The **`ChalkBox-CurseForge-Media-X.Y.Z.zip`** asset is artwork and publishing copy; it is **not** the addon.

## 2. Install

1. Close the game if replacing an existing version.
2. Open your Forever installation's `Interface/AddOns/` directory.
3. Extract the archive so that `Interface/AddOns/ChalkBox/ChalkBox.toc` exists. The folder name is **ChalkBox**, without extra version numbers.
4. Verify the addon appears in the game's AddOns list. Then log in and type `/chalk`.

If ChalkBox is missing, check for the common double-nested folder `Interface/AddOns/ChalkBox/ChalkBox/` and make sure you are editing the right Forever installation.

## 3. First-use tour

- Open **Options → AddOns → ChalkBox** (or `/chalk`). Pages are grouped by purpose; some options appear under expandable child pages.
- Open **LootSense** and hover items to see supported quest, personal KEEP and profession information. Use `/chalk keep [item]` for a manually protected item.
- Open **DropSense**, then open the World Map and select **Discoveries**, or type `/chalk drops map`. Only loot seen since recording was enabled has observed history.
- Open **QuestSense**. Its optional **Navigation** child page controls a movable compass and Original WoW / Blizzard Navigation / ChalkBox HD artwork based on real quest waypoints. It's OFF by default; use `/chalk nav on` to try it. **Smart** automatically manages accepted quest watches; in a recognized party dungeon it focuses on quests actually matched to that instance. **Nearby only** uses conservative zone evidence. **All accepted** follows quest log order up to the available watch limit.
- Open **The Bar** to select stats and appearance. Fresh defaults mirror the slim top layout. Right-click empty Bar space to enter Edit Mode; after arranging it, right-click empty space again for **Done editing**. Existing layouts survive upgrades.
- Type `/chalk macro` to build a macro from learned abilities. Read the preview and warnings; **Select Text** enables Ctrl+C. **Install New** is explicit, out-of-combat and refuses to replace an existing named macro.
- The compact **Combat Meter** intentionally starts closed. Open it with `/chalk meter show` if desired.
- **Adventure Journal** opens with `/chalk session` and now has a full outer frame and readable map-derived wood background. Full event Timeline and History views are a future development stage, not yet recording.
- **QuietGuard** filters are all **off by default on fresh installs**. Activate only the social requests you want to decline.

The [full handbook](USER_GUIDE.md) explains the auction, disenchant, session, camp, emote, bag and update tools too.

## 4. Upgrade without losing history

A normal update replaces **only the addon files** under `Interface/AddOns/ChalkBox/`. Do not delete or reset WoW's `SavedVariables` when upgrading. Your existing quest watches, loot observations, layout preferences, personal KEEP selections and other stored preferences should remain intact.

If a visible change is not appearing after installing, type `/reload`, verify the version shown in **ChalkBox → Updates**, then verify you did not install into a second game directory.

## 5. Understand the limitations

- **DropSense** observes readable loot windows, not every kill and not the server's actual drop table. Outside instances it can record the **player's position at loot-window opening**, not the creature's guaranteed spawn or death position.
- **AuctionSense** captures asking prices **only after a manual scan**. Listings do not establish real sales or profits, and Forever can throttle queries.
- **MacroForge** generates macros but cannot trigger combat abilities automatically, bypass cooldowns or run a one-press rotation.
- **QuestSense** cannot invent a dungeon quest assignment, precise travel distance or hidden quest data; it preserves watches if evidence is missing.
- **QuietGuard and Emota** are configurable or opt-in, so their automatic behavior should never surprise a new player.
- **Updates** cannot fetch GitHub over HTTP inside WoW; it provides a release link and optional group-member version comparisons.

## 6. Need help?

Run the matching diagnostic, such as `/chalk quests status`, `/chalk drops map status`, `/chalk auction status`, `/chalk loot status` or `/chalk bar status`. See [Troubleshooting](TROUBLESHOOTING.md) or file a [GitHub bug report](https://github.com/detok/ChalkBox/issues/new/choose) with version, client build, steps and the exact error. Never include passwords, account identifiers or private chat.

[Documentation home](README.md) · [User handbook](USER_GUIDE.md) · [Complete commands](COMMANDS.md)
