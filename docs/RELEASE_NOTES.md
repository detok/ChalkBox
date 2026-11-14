# ChalkBox 2.1.8 — Bag position restored

### What happened
The 2.1.5 safety update disabled the separate-bag correction but kept saved `bagOffsetY`. As a result, previously lowered bags began opening at Blizzard's higher default position. The earlier slider was disabled without a verified stack trace showing it caused the reported combat item-use error.

### Restored
- **Options → AddOns → ChalkBox → The Bar → Separate Bag Position:** real horizontal offset slider with a live position readout.
- **Left (−120)** moves separate bags upward. **Right (+120)** lowers the bag column. **0** uses Blizzard's default. **Reset Bags** is functional.
- Existing saved offsets are respected again upon login, including negative values.
- Reuses the original native bag-layout hook and first-column correction, recalculating relative to Blizzard's latest anchor instead of stacking repeated offsets.
- Keeps out-of-combat and bank-open safeguards. No item button clicks, item use, or protected combat actions are invoked by this control.

### Still protected
- Emota does not dispatch native emotes during combat.
- Green reagent decorations that modified item buttons remain suspended.
- Full-width 18px Bar, Blizzard portrait ZZZ layering, selective top-UI spacing, native DPS meter reports and AuctionSense remain unchanged.

### Important
A Blizzard message blaming ChalkBox for a protected action is not proof that the bag offset caused it. There is no verified blocked-function stack trace yet. If it happens again, please capture the exact **blocked function name**; the underlying cause needs to be diagnosed directly.

### Install
Replace the old ChalkBox addon folder with `ChalkBox-2.1.8.zip`; preserve SavedVariables and type `/reload`. The Lua 5.1 tests and build are automated; visual and combat-safety confirmation requires WoW Forever.
