# ChalkBox 2.2.34 — Stable Update

- Emota suggests an emote and waits for a click or `/chalk emota play`. Automatic emotes no longer cause the blocked-action popup.

# ChalkBox 2.2.33 — Stable Update

- The login blocked-action message is fixed. Blizzard frames are left alone.
- Black Market listings are recorded separately from auction prices. `/chalk bmah`.

# ChalkBox 2.2.32 — Stable Update

- Auction Scan Market always reports start, progress, success, or the reason it cannot run.
- Adventure Chronicle, Inventory Intelligence (off until enabled), Fill price, and the storybook (`/chalk journal`) are included.
- Saved data from older versions is kept.

# ChalkBox 2.2.31 — Stable Update

- Includes the 2.2.30 meter, bar, auction scan, and data-transfer fixes.
- Session journal time and drop totals stay accurate, and an unfamiliar journal save is not replaced.
- `docs/FEATURES.md` states what each feature is supposed to do. Inventory Intelligence and the full Adventure Chronicle stay paused.

# ChalkBox 2.2.30 — Stable Update

- **Combat meter:** Status explains an empty window. Locked numbers no longer crash it. The dragged size stays. Pets are labeled as pets. If Blizzard's meter is missing, locked, or empty, your own combat log supplies your damage and your pet.
- **The Bar:** Resize grips drag, text stays inside each stat, and icons stay off until you turn them on. Saved layouts and widths are kept.
- **Auctions:** Scans keep prices they already received, and use the classic auction list when the modern one is unavailable. Protected auction tabs are not hooked.
- **Bags and quests:** Protected bag frames and the whole quest tracker are not modified.
- **Data transfer:** Moving saved auctions and discoveries keeps the higher counts and stores a backup first.

All existing saved settings and recorded personal data are preserved. The installable file is `ChalkBox-2.2.30.zip`; the separate media kit is not an addon.
