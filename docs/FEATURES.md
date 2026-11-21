# What ChalkBox is supposed to do

This is the player-facing contract for ChalkBox on WoW Forever. It describes the addon as of 2.2.33.

ChalkBox is one optional companion. It reads the game and shows notes. It does not buy, sell, move items, press your buttons, or send combat chat. A price can be copied into the auction sell box only when you click Fill price, and you still press Post yourself. When the client hides a value, the addon says so or skips the action. Saved data is kept across updates.

## LootSense

**Supposed to:** On an item tooltip, say why it might matter. An accepted quest comes first, then a personal KEEP mark, then a recipe this character has actually learned, then a possible profession use. `/chalk keep` and `/chalk forget` manage the personal list. Quest protection stays on even if extra advice is turned off.

**Status:** Works. Combined bag windows do not get the purple future-quest dots. Separate Blizzard bags do. That limit is intentional so item buttons stay safe.

## Future quest notes

**Supposed to:** For a small hand-checked list of item IDs, show a purple "future quest" note with the possible quest, amount, and zone. It is reference only. It never replaces a live accepted quest.

**Status:** Works for the curated list. It is not a full quest database.

## Professions and Recipe Advisor

**Supposed to:** Tell a learned recipe apart from a catalog guess. `/chalk loot scan` rereads the open profession window. The bundled catalog is reference data, not proof the character knows the recipe.

**Status:** Works.

## Disenchant estimates

**Supposed to:** On eligible gear, show a modeled material outcome and, when a scan exists, compare it with asking prices. `/chalk de` explains one item. Nothing is disenchanted automatically.

**Status:** Works as an estimate. Forever-only odds that are not in the model stay labeled unknown.

## Discoveries and DropSense

**Supposed to:** Record what appeared in a loot window the player actually opened: item, area, and creature when the game identifies one. Outdoor coordinates are where the player opened the loot window, not a spawn point. The World Map journal and known flight paths show only that recorded evidence. The same corpse within two minutes is not counted twice. `/chalk drops chance` uses a chance the player types in.

**Status:** Works.

## AuctionSense

**Supposed to:** At an auctioneer, scan asking prices when the player asks. Browse scan is the normal path. Full scan is the heavier list and can take a long time, with about a 15-minute cooldown after a request is accepted. A failed or partial scan must not erase the last good snapshot. Prices are asks, not sales.

**Status:** Works. The Scan Market button stays clickable. Chat says when a scan starts, which page is being read, when prices are saved, and why a scan cannot start. `/chalk auction debug` prints the detected API and the throttle. A received page is kept if the next page is refused. The old auction list is used when the modern one is missing, with the page number in the position that client expects.

## Black Market

**Supposed to:** When the Black Market window is open, remember what is listed: the item, the current bid, the minimum bid and increment, how many bids, the time-left bucket, and the seller or quantity when the client provides them. That record stays in its own save. It is not an auction asking price, so it does not change valuations, Fill price, or Inventory Intelligence. The AuctionSense panel has a Black Market view for the current list and for items seen before. ChalkBox never bids and never presses a Black Market button.

**Status:** Works when `C_BlackMarket` and the Black Market events exist. `/chalk bmah` says so, or says the Black Market is not on this client. The storybook overview counts the separate list.

## Auction Insights

**Supposed to:** In the auction house, show bag vendor value and seller-mail receipts the addon has actually seen. It is not a lifetime sales ledger.

**Status:** Works. My Items can suggest a saved asking price. **Fill price** writes that number into Blizzard's sell boxes only when you click the button, and only when those boxes are not protected. ChalkBox never switches the auction tab and never presses Post. You click Post yourself. The auction cut and deposit are not included in the suggestion.

## Price charts

**Supposed to:** Plot up to seven saved low-ask points for an item that was already scanned. No scan is started by opening the chart. One point is not a trend.

**Status:** Works for saved points. It does not invent history.

## Inventory Intelligence

**Supposed to:** Optional advice from known recipes, bags, bank snapshots, and saved asking prices. It starts off. Old reserves, ignores, and recipe notes stay in the save. `/chalk intel on` turns it on. It does not buy, sell, craft, or post.

**Status:** Works, and it stays off until you enable it under AuctionSense → Inventory Intelligence.

## Bank value

**Supposed to:** After the player opens their character bank, remember the vendor total and show it on the bar as last seen. Warband, guild, and bag contents are not included. Missing prices are a lower bound, not zero.

**Status:** Works.

## QuestSense

**Supposed to:** Choose which accepted quests stay on Blizzard's tracker. Smart prefers nearby and recent quests, and in a recognized dungeon only quests that match that instance. Nearby is the current zone. All is log order up to the chosen limit. Manual watches are kept and restored. If a dungeon cannot be verified, the tracker is left as the player set it. While solo, group, elite, and dungeon quests are not added automatically.

**Status:** Works. It does not plan a leveling route.

## Quest compass

**Supposed to:** An optional arrow for an accepted quest that already has a real map point. It starts off. It does not guess inside a dungeon, and it does not move the player's map pin. While dead, the corpse is preferred when the client gives its position.

**Status:** Works when a waypoint exists. No waypoint means no arrow, which is the intended fallback.

## MacroForge

**Supposed to:** Build a macro from spells the character has learned. The player copies it or explicitly installs a new macro outside combat. It will not overwrite a macro or press it.

**Status:** Works. A rotation that skips cooldowns is not possible inside WoW's macro rules.

## The Bar

**Supposed to:** A thin strip of level, experience, bags, gold, repair, and similar stats. The player can show, hide, move, and resize each stat. Widths and order are saved per character and not reset on update. Icons stay off until turned on. On a notched Mac, the center of the bar can split around the camera cutout when the client reports one, or when the player sets a gap. Repair numbers with a tilde are estimates from real repair quotes.

**Status:** Works. The resize grip drags. Text stays inside the stat. A display with no notch and no saved gap is unchanged. The bar does not move the minimap, buffs, or unit frames. `/chalk taintcheck` reports whether the client blocked an action.

## Bag position

**Supposed to:** Nudge separate bag windows up or down by a saved amount between 120 pixels either way. Combined bags, the bank, and protected frames are not moved. Combat waits.

**Status:** Works. Logging in does not force the bags to move. The saved nudge is applied when Blizzard lays the bags out, and only if that bag frame is not protected.

## Combat meter

**Supposed to:** A personal window for damage, healing, and a few other combat totals. It starts closed. When Blizzard's own meter returns readable rows, those numbers are shown. When that feed is missing, locked, or empty, the window counts the player's own damage and their pet from the combat log, with the player's own fight timer. Other people are not included. The window keeps the size the player dragged. Pets are labeled as pets. Nothing is printed to chat.

**Status:** Works in 2.2.30. The old "no numbers, and clicks say the addon failed" report is what the personal fallback and the locked-value guards are for. Chat reports stay retired.

## Session journal

**Supposed to:** A per-character summary of this login and up to 20 finished ones: time, experience, gold change, quests turned in, sampled loot, camp reminders, and repair quotes. Only events the addon actually saw. Opening it must not freeze the clock during a long quiet stretch. The drop list should be the highest counts, not whichever items happened to appear first. An old or newer save must not be deleted just because the version number is unfamiliar.

**Status:** Works. `/chalk session` opens this summary. `/chalk journal` opens the storybook.

## Adventure Chronicle

**Supposed to:** From this update forward, remember levels, quest turn-ins, deaths, party-dungeon visits, and rare drops the client actually identifies. Older session summaries are not rewritten into a fake timeline. Recording can be turned off without deleting what was saved.

**Status:** Works. Settings → Session Journal → Adventure Chronicle, or `/chalk chronicle`. Today, Timeline, and History are in that window.

## Storybook

**Supposed to:** One movable, resizable window that reads the other modules and tells the story back: an overview, a timeline, milestones, and personal bests. It does not change their saved data. It does not rebuild the page during combat. It remembers where you put it.

**Status:** Works. `/chalk journal` opens it. So does Settings → Adventure Chronicle → Open storybook, and a left-click on the level stat on the Bar. `/chalk session` is still the older session summary.

## Adventure prep

**Supposed to:** A checklist and optional toast for food, buffs, tent use, and hunter pet care. Acknowledging a tent does not create a real buff.

**Status:** Works.

## Emota

**Supposed to:** Optional idle ideas, off unless the player turns automatic behavior on. Nothing during combat. The client only allows the character to emote from a real click or keypress, so ChalkBox suggests one and waits.

**Status:** Works. Standing still can suggest an emote in chat. `/chalk emota play`, or **Play suggestion** in settings, performs it. Wave, Test Joke, and Surprise Me still play immediately because they are clicks. Automatic timers never call the emote.

## QuietGuard

**Supposed to:** Optional filters for duels, guild, party, trade, and channel invites. All five start off. A saved "on" stays on.

**Status:** Works.

## Appearance

**Supposed to:** ChalkBox's own panel colors. Blizzard's tooltips, map, and menus keep their colors.

**Status:** Works. Missing art falls back to a plain frame.

## Updates

**Supposed to:** Show the installed version and a GitHub release link. It does not download an update from inside the game. Group members running ChalkBox can be compared when that information is visible.

**Status:** Works.

## Data transfer

**Supposed to:** A file the player copies between computers, containing auction asks, seller receipts, this character's discoveries, and known flights. Export prepares it. Import merges it. Settings, layouts, and cooldowns stay out of the file. Repeating an import must not inflate counts. A smaller file must not lower a higher local count. A backup is written before the merge.

**Status:** Works in 2.2.30. The older second loot ledger is no longer used, because it could shrink discoveries. The backup is `transferBackup` on the account and character saves.

## Screen shift

**Supposed to:** Optionally move a few unprotected Blizzard frames at the top of the screen down by the bar's height. The main game frame and action bars are not moved.

**Status:** Works. It waits through combat.
