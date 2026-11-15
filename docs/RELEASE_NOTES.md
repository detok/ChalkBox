# ChalkBox 2.2.6 — UI defaults and readability

## The Bar
New installations match the approved 2048px reference strip: **left** Level/XP, XP/hr; **center** Session time, Time to level, Rested XP; **right** Bags, Gear, Repair estimate, Junk value, Gold/net, World latency. The optional Pet display is disabled until selected. This is a starting arrangement, not a forced migration: per-character saved placements/alignment and account-wide stat toggles are respected. Older existing Bars with no explicit resale mode keep Total, and freshly configured Bars start on Junk. Reset Layout intentionally restores the new positions.

## QuietGuard
All guild, duel, party, trade, and channel filtering is now **off by default on fresh installs**. A player can enable any option in Options > AddOns > ChalkBox > QuietGuard. Prior explicit ON selections stay ON across upgrades; changing the defaults does not rewrite Blizzard's own social settings.

## Native options polish
All ChalkBox settings pages receive a neutral, dark readability underlay, drawn only inside ChalkBox's own panel, so bright scenery and floating names cannot drown out option text. AuctionSense's scan-age explanatory line now has room before the DisenchantSense checkbox; the two footer hints are repositioned without affecting any controls.

## Compatibility
- No forced resets of SavedVariables or user choices; no settings-schema migration.
- No changes to scanning, trading, quest tracking, loot protection, map geometry, combat, or protected UI actions.
- New Lua 5.1 regressions cover fresh defaults, preserved opt-ins, restored arrangements, and AuctionSense text geometry.
- Client-side appearance still requires a visual check with the native WoW Forever Options window.

Install `ChalkBox-2.2.6.zip` over the existing addon folder, preserving SavedVariables, then type `/reload`.
