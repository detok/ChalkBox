# ChalkBox 2.2.15 — AuctionSense, Quest Tracking, Discoveries & HD Arrow

## Full Scan now accepts valid listings before their names are cached

**Scan Market (browse)** requests the server's regular paginated browsing summaries, usually lighter and without a full-listing cooldown. **Full listings (replicate)** asks the server for a complete set of individual auction records, letting ChalkBox calculate actual observed listing counts, stack quantities, lowest buyout per item and a quantity-weighted *asking-price* average. The game's successful full-request throttle is approximately **15 minutes account-wide**.

Previously, ChalkBox rejected individual full-scan listings when `hasAllInfo` was false—even if the item ID, stack count and buyout were already valid. That could discard usable prices, then abort a valid snapshot. Version 2.2.15 keeps **verified numeric listing data** in that situation, labels uncached item names as `Item #ID`, and reports how many rows lacked complete names.

The reader still rejects invalid IDs, quantities and buyouts, never mistakes bid-only prices for buyouts, never synthesizes actual sale prices, and preserves the last complete market on a failed or interrupted scan. Full Scan can still be legitimately refused or time out when the **server throttles** the replicate request (including if another addon made the last successful request); ChalkBox now explains this separately and leaves the working Browse Scan available.

## Your selected quest stays in Blizzard's tracker

When **QuestSense Navigation** is enabled and following an accepted quest, QuestSense adds that quest to **Blizzard's existing quest-watch list** if it is not already watched. This is a manual-style watch, not an extra ChalkBox objective tracker: it is not counted as one of ChalkBox's auto-managed quests, will not delete other manual watches to free space, and remains visible across Nearby filtering while explicitly followed. It defers protected watch changes while combat or map/quest-log UI are open, and will report a full watch-list limit rather than dropping another user's selection.

Quest selection and super-tracking are **not** changed by ChalkBox. Navigation remains off by default. Hiding the arrow does not remove your watched quest.

## Discoveries — transient loot-location pulse

While the World Map is displaying a zone with your recorded outdoor loot observations, **hover a Discoveries item** to pulse a small gold dot at the **latest observed player position when the loot window opened**. The dot exists only while hovering: it disappears on mouse-out, page/filter changes, or map changes. It is anchored to Blizzard's visible map canvas and does not create permanent pins or change the map location.

No marker appears for dungeon loot, old records without coordinates, or a different area than the visible map. This is a personal observation—not a guaranteed creature spawn/death coordinate.

## A cleaner arrow with optional HD rendering

The floating arrow remains minimal. A **small distance in yards now sits underneath it**, while hover still shows full quest and GPS status. In **QuestSense → Navigation**, choose between **Sharp HD Arrow** (new 256-pixel original north-up TGA derived from editable vector art) and **Classic Arrow** (the original Blizzard navigation atlas, with fallback). The arrow's direction, Auto / Next / Hide right-click menu, drag lock, saved position and corpus/quest targeting stay the same. No new dependency or secondary addon is required.

## Compatibility and verification

- Lua 5.1 regression tests cover partial full-listing metadata, price preservation, native selected-quest watches, deferred safe updates, a disappearing map-canvas pulse, arrow style switching and distance display.
- Package tests verify the 256-pixel alpha TGA and both exact, reproducible release ZIPs.
- **Live Forever checks remain necessary** for the server's replicate throttle behavior, the map canvas geometry while zooming, and the new arrow graphic on different UI scales. This is a Beta build.

Install `ChalkBox-2.2.15.zip` over your addon files, keep SavedVariables, then `/reload`.
