# ChalkBox 2.2.24 — Forever release-candidate smoke test

**Build:** GitHub prerelease 2.2.24 (not the stable 2.2.22). Keep your old 2.2.22 ZIP for quick rollback. **Never reset or delete your SavedVariables for this test.**

## Start: install and login (2 minutes)

- Download `ChalkBox-2.2.24.zip` from GitHub Releases. It must extract to `Interface/AddOns/ChalkBox/ChalkBox.toc`, not a nested folder or publisher media ZIP.
- Confirm **Options → AddOns → ChalkBox → Updates** says **2.2.24**. Open two settings pages; the Blizzard Settings background should remain visible. No Lua errors, missing libraries, or duplicate addon entries.
- Keep automatic group combat reports **OFF** unless you deliberately choose to enable them. Normal game macros, AH buying/selling and native bags must continue working.

## A. The Bar / bag interaction (1 minute)

- Left-click **Bags NN free**. All native bags should open; click again to close. Right-click the same metric to open the original Bar context menu.
- Enter Bar **Edit layout**. Drag a stat, then left-click Bags: it should **not** toggle bags while editing. Right-click empty Bar space → **Done editing**. Confirm alignment and position are retained after `/reload`.
- Check Gold, XP/h, bag value mode, repair estimate, pet/latency labels. None should be suddenly hidden or miscalculated.

## B. Compact Combat Meter / chat (3 minutes)

- Type `/chalk meter show`. Expect a **small header with a Menu button**, no five-button strip. Right-click the header; same menu should open. Drag when unlocked; confirm it stays put when locked.
- Choose DPS / Current, hit a training target or a creature, then leave combat. The rows should grow to actual participants (one when solo, up to five for the default; optional 8/12 max for raids). No rows with stale names after fight changes.
- Set Background to 0% in options or with `/chalk meter opacity 0`: **names, class icons and numbers must remain readable**. Restore the background (e.g. 70%).
- In the gear menu set **Report size Top 3 or 5**; try a manual PARTY report only while grouped, out of combat. Check whether the game actually delivered it or opened a **copyable report**. If a send fails, copy the text with Ctrl+C and paste manually—ChalkBox must not secretly switch chat channels.
- Try **Print top N to SAY** only when you intentionally want nearby players to see it. Verify auto-report is still **OFF** by default. Never use a test macro that tries to bypass chat protection.
- Confirm **Reset** shows confirmation instead of erasing all fights on one click. Leave Reset unconfirmed unless you intend to lose all Blizzard meter sessions.
- Open Blizzard's **native** meter gear menu and confirm its own report settings remain present and synced with the compact meter.

## C. AuctionSense / chart lab (3 minutes)

- Visit an auctioneer. Auction House should open on Buy with **Buy highlighted**, not Market. Click **Market**, then click **Buy** once: the first click should highlight Buy. Repeat Market → Sell and Market → Auctions.
- Use the existing AuctionSense tab and your stored price snapshot. Do **not** launch a full-market scan solely for the chart test; the 15-minute server throttle still applies.
- Open **Options → AddOns → ChalkBox → AuctionSense → Charts (Experimental)**. Search an actual item name or numeric ID from the saved market. If it has at least two recorded scans, the line/texture chart should show real prices with correctly spaced timestamps. Hover a point; it should identify the actual low ask per unit.
- If only one observation exists, there is **no historical trend to draw yet**. If none exists, expect an honest missing-data message. Confirm the graph has not initiated a scan or changed an item's recorded price.
- With a bank or native AH Sell page open, ensure item drag/drop, trade controls, and bank/bag layout still work exactly like 2.2.22.

## D. Important unaffected features (2–3 minutes)

- Open the World Map → DropSense / Discoveries; the map button, zone dropdown, and background must remain usable.
- Open `/macro` → MacroForge; verify the native footer button, side-by-side docking and safe undock behavior. No macro should be created without **Install New**.
- Open QuestSense → optional navigation; do a short Auto / Next check. Confirm Blizzard's accepted quest watch list and quest tracker right-click menu still behave.
- Check Adventure Journal, LootSense tooltips, Emota idle/jokes settings and camp reminder access. No regressions or surprising automatic actions.

## Report only what matters

If something looks wrong, capture **one screenshot**, the **exact Lua error** if any, where you clicked, and whether it happens after `/reload`. For the experimental chart, tell us whether it drew a **line**, **columns**, or **nothing**.

The automations and all live-client behaviors above cannot be verified by mock Lua tests alone. **Do not mark 2.2.24 stable until these checks succeed in Forever.**

## Rollback

Close the game and reinstall **[2.2.22 stable](https://github.com/detok/ChalkBox/releases/tag/v2.2.22)** by replacing only the addon files. Preserve existing WoW SavedVariables. The 2.2.24 candidate does not migrate or rewrite the underlying AuctionSense/SessionJournal data schemas.
