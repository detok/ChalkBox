# ChalkBox 2.0.4 — Discoveries layering and smoother bags

## Discoveries journal
The standalone window now draws over Blizzard's Map & Quest Log as one complete panel. Its native backdrop, solid textured background and border remain visible with the shared theme, and its controls remain on the same foreground layer. This targets the floating-button display reported in WoW Forever after 2.0.3.

## Bag and HUD responsiveness
- Combine rapid bag-item redraw hooks and inventory events into fewer learned-reagent highlight passes.
- Avoid repeating learned-recipe searches for identical item stacks during a single bag pass.
- Coalesce bag and item-cache event bursts on the TrailBar.
- Cache optional full-bag vendor valuation briefly instead of rescanning it on every fast HUD event.

No SavedVariables reset, no loss of loot history, and no change to existing settings or module behavior outside these fixes.

## Testing and distribution
GitHub Actions runs the Lua 5.1 regression suite plus addon/media package validation. Please verify opening separate and combined bags, map overlays, Discoveries search/filtering, and UI scale changes in the real WoW Forever client.

Upload **ChalkBox-2.0.4.zip** as the game addon. The separate **ChalkBox-CurseForge-Media-2.0.4.zip** is for the listing's images and copy.

Repository: https://github.com/detok/ChalkBox
