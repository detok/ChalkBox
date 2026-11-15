# ChalkBox 2.2.3 — More accurate disenchant guidance, completely offline

This is a **data-correction release** for DisenchantSense. It retains the familiar LootSense item tooltip, AuctionSense Market hover and single-addon installation.

### What changed
- Now uses the **Forever client's item-class, rarity and item-level disenchant brackets**, taken from an openly MIT-licensed reference. These are offline files inside ChalkBox—no web API, account, subscription, companion executable or second addon.
- Ships the source's **NO_DISENCHANT** list and **special disenchant-loot** list; affected items do **not** get misleading general material valuations.
- Adds low-level green weapons, supported rare and epic brackets, and corrected crystal/shard transitions. When available, uses the effective item level from the game client, not the required character level.
- The 5–15 **blue** bracket's output is not confirmed by the source; it is flagged **Unconfirmed** and never assigned a speculative expected value or trading recommendation.

### What remains an estimate
The **Forever bracket** is client-derived; dust/essence/shard **probabilities and quantities** are from VMaNGOS Classic and cross-checked with CMaNGOS. They may differ on Forever servers. The values are expected *gross asking values* from your AuctionSense scans, **not realized sales or profit**. Missing, stale or mixed material prices still block an expected total and a financial comparison.

### Controls
Hover green, blue or supported epic equipment. Hold **Shift** for outcome breakdowns. At an auctioneer, use **Market → Scan Market** to collect asking prices. Type `/chalk de [item link]` for the model's chat breakdown, `/chalk de off` to hide, or change the existing **AuctionSense → Show disenchant estimates** checkbox.

### Copyright / provenance
The reference is MIT-licensed by APGM82. Bundled files and unmodified MIT terms are in `ChalkBox/Libs/ForeverDisenchantData/`; the bundled README contains the pinned Git commit and source build details: https://github.com/APGM82/DisenchantForever.

### Safety
No item usage, no casting, no bag button changes, no automatic auction transactions, no network access, no mutation of Blizzard's auction display mode, no SavedVariables migration. Existing AuctionSense, map-owned Discoveries, bag offset, Emota, macro builder and damage meter remain untouched.

### Test release
Lua 5.1 syntax, all existing+new regression tests, full ZIP integrity and media kit are checked by GitHub Actions. Actual rendered tooltips and any Forever-server-specific output still need in-game verification. Do not destroy valuable items solely from estimated market prices.

Install `ChalkBox-2.2.3.zip` over the existing addon, preserve SavedVariables and `/reload`.
