# ChalkBox 1.9.1 — TrailBar Bag Resale Value

## Optional vendor bag valuation

- Adds **Bag vendor value** to **Esc → Options → AddOns → ChalkBox → TrailBar Stats** (off by default so existing layouts stay the same).
- Flip the same TrailBar module between **Value** (the vendor resale price of all equipped bag contents) and **Junk** (gray/poor-quality contents only).
- **Left-click the module** outside Edit Mode to toggle. The native settings page has a `Value: Total / Value: Junk` button, too.
- Slash controls: `/chalk bar stat bagvalue on`, `/chalk bar bagvalue junk|total|toggle`. The saved mode persists.
- Every item stack is multiplied by the actual game-provided vendor sell price, not an auction or estimated market price.
- Hover the stat to see both totals in exact gold/silver/copper, incomplete-price counts, and what is included.
- If an item has an uncached, unavailable or protected price, ChalkBox shows a truthful **minimum known value (`>=`)** rather than fabricating an exact total.
- Excludes bank items, worn equipment, and already-held gold. Makes **no inventory transactions**.

The 18px height, adaptive width fit, draggable layout and other modules from 1.9.0 are retained. Existing bar settings and layouts are migrated automatically by adding the new opt-in stat at the end of the right section. Real-client visual testing remains recommended.

## Version 1.9.0 features retained

Editable TrailBar, charcoal opacity, known-recipe reagent green bag markers, native Item Insight tooltips, signed separate-bag offset, native settings pages and Emota race behavior are unchanged.
