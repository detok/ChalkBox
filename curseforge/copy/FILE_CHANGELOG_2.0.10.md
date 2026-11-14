# ChalkBox 2.0.10 — Bank first-open compatibility

### Fixed and improved
- Prevented the bag highlighter from inspecting or drawing on Blizzard bank item buttons.
- Suspended bag highlighting and new bag-related hook setup while the bank is open, especially during first-time bank UI initialization.
- Prevented the separate-bag layout feature from moving protected bank frames or anchors while the bank is open.
- Resumed the player's normal bag highlights and saved bag offset after closing the bank.
- Added regression scenarios for a new character's first bank visit.

### Unchanged
Discoveries, QuestSense, The Bar, loot history, saved settings and native bank handling.

This is a preventive compatibility fix for a reported first-bank blocked-action warning; the live-client error requires confirmation. WoW Forever beta/test release. Other client flavors unverified.
