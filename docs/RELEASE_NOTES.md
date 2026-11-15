# ChalkBox 2.2.18 — Item tooltip readability pass (Beta)

- Drop Journal now starts after a quiet separator; quantities use the shared blue count color.
- Observed creature-specific frequencies are shown as informational teal, never green "good" odds, with an explicit observed label. These are personal loot-window samples, not server probabilities.
- LootSense supporting descriptions use the shared neutral tooltip color; quest collection progress uses the shared blue count role.
- AuctionSense market tooltips gain a quiet separator and gold asking-price emphasis; price values and market freshness logic are unchanged.
- DropSense settings clarify the difference between loot-window samples, creature-specific observations, and user-provided hypothetical drop rates. Disabled secure-bag outlines are explicitly labeled inactive.
- No changes to classification, loot capture, quest matching, auction calculations, disenchant models, stored records, or Blizzard's native tooltip text.
- Updated architecture reference version.

## Verification
Run Lua 5.1 tests, packaging, and a real Forever tooltip check for quest items, collected progress, learned materials, drop-journal source rates, and duplicate-free re-hover. Keep the existing 2.2.17 candidate until acceptance.
