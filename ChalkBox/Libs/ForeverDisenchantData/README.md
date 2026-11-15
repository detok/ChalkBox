# Offline WoW Forever disenchant reference (MIT)

These four files are distributed inside the **single ChalkBox addon**, not as a
standalone installed addon. They are used only as read-only lookup data by
`ChalkBox/DisenchantSense.lua`:

- `Materials.lua`: Forever `ItemDisenchantLoot` client-derived class,
  quality, and item-level brackets, with material odds and quantities based
  on the vMaNGOS Classic database and cross-checks against CMaNGOS.
- `NoDisenchant.lua`: items with the Forever client `ItemSparse`
  `ITEM_FLAG_NO_DISENCHANT` flag (0x8000).
- `OwnLoot.lua`: items marked `ITEM_FLAG2_DISENCHANT_TO_LOOT_TABLE`, whose
  special disenchants must **not** be valued with ordinary material brackets.
- `LICENSE`: unmodified upstream MIT license (copyright 2026 APGM82).

Source: https://github.com/APGM82/DisenchantForever
Pinned upstream main commit: `ab223e6750b8e1aa24b76f66437deee461c27b47`
Vendored from `DisenchantForever/Materials.lua`,
`DisenchantForever/NoDisenchant.lua`, `DisenchantForever/OwnLoot.lua`,
and `LICENSE` without modifying the source files.

**Important:** The source notes the bracket extraction from Forever client
1.60.1.70425 and the exception lists from 1.60.1.70888; those are distinct
client builds. The source's material yield percentages and quantities are
Classic-derived estimates, not measured results on Forever's live servers.
The 5–15 blue item-level bracket's reward is explicitly unconfirmed.
This dataset is versioned, so new client builds should be checked for changes.

No source addon code for UI, inventory manipulation, cast automation, auction
integration or network access is copied. ChalkBox only evaluates the source's
static tables using its existing AuctionSense snapshots.
