# ChalkBox 1.9.3 — Repair Learning for The Bar

The Bar can now *learn from experience*. Rather than overwriting one calibration ratio, it records a bounded history of actual vendor repair quotes and uses these examples to estimate future costs.

## How it learns

- **At a repair-capable merchant**, when Forever exposes an exact repair-all quote, store one sample of quote (copper), equipped durability damage, number of repairable worn items, total maximum durability and optional equipped item IDs.
- **Prevent duplicates** from the five-second bar refresh and repeated identical vendor quotes. Limit storage to **32 distinct valid observations per character**.
- **Away from a merchant**, predict approximate copper cost from the samples that match the current equipment best, using a robust average of observed copper-per-durability rates. Favor the same identified gear, filter outliers and reject very dissimilar durability pools.
- **Learn from its misses:** compare the previous prediction against subsequent real merchant quotes and save the most recent percent difference for the tooltip.
- **Honest display:** exact quotes have no prefix; predictions remain prefixed with `~`. If no credible sample exists, display `Repair --`. An undamaged equipped set may show `Repair 0c` but gear inside bags is excluded from that statement.
- **Legacy-safe:** an existing 1.9.2 per-character rate remains available as an initial fallback until a real new observation is available.

## Controls

- Hover The Bar's **Repair** stat for the number of observed quotes, prediction source, confidence stage, and last checked error (when available).
- `/chalk bar repair status` — view this character's saved learning status.
- `/chalk bar repair reset` — clear this character's training examples, prediction errors and the old calibration.
- Existing right-click menu, move/hide controls and `/chalk bar stat repair on|off` work unchanged.

**Limitations:** real vendor repair bills may include equipment stored in bags, vendor-specific discounts, guild repairs and unexpected gear changes. These differences cannot be inferred perfectly from equipped durability alone. Estimates are not guarantees; no addon ever repairs or pays automatically.

The full Lua 5.1 tests and single-addon ZIP CI remain required. Live WoW Forever gameplay verification is still recommended.
