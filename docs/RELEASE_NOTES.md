# ChalkBox 2.2.28-quest-beta — QuestSense reliability beta

**Prerelease for World of Warcraft: Forever.** This ZIP integrates the already-merged AuctionSense Intelligence, data transfer, toolbar icons/tooltips, Mac notch, and map fixes. The latest stable release remains 2.2.26.

## QuestSense

- **Simple Smart priority:** Choose **Closest First** or **Lowest Level First**. Completed quests move below unfinished objectives by default; the original Completed First preference remains opt-in.
- **Nearby fills what it can verify:** Include relevant accepted quests from the zone map, player and sibling micro-maps, and native quest-specific waypoint maps. Confirmed remote quests are excluded; the optional native distance radius remains available.
- **5 or 10 total watch budget:** Count existing manual watches in the selected budget before adding automatic watches. Existing manual overflow is protected rather than silently discarded.
- **Fresh accepted quests:** A newly accepted, eligible quest wins an automatic slot, then stays watched as a manual selection until the player untracks or turns it in.
- **Solo safety:** Elite/dungeon/raid quests are excluded automatically without a party, even in All mode where supported by the client's quest metadata.
- **Diagnostics:** `/chalk quests status` shows verified local candidates, eligible candidates and any unfilled slots.
- **Native tracker safety:** No protected Blizzard objective-tracker replacement. Closest/Level sorting determines *which* quests are selected; Blizzard controls visible row order.

## Retained from 2.2.27

- Experimental read-only AuctionSense Inventory Intelligence (off by default), complete data-transfer companion, visual bar icons and semantic tooltip styling, safe Mac notch handling, and other unified fixes.

## Install

Download the GitHub prerelease's **ChalkBox-2.2.28-quest-beta.zip**. Extract both `ChalkBox/` and optional `ChalkBoxTransfer/` into `Interface/AddOns/`, preserving your SavedVariables. `/chalk` opens the settings.

**Live testing still required:** Blizzard/Forever quest map evidence varies by zone. Nearby intentionally leaves slots empty when it cannot prove enough eligible local quests, rather than guessing or showing remote objectives.
