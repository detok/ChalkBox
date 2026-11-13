# ChalkBox 2.0.5 — Discoveries journal text and layout

The Discoveries journal now finishes building all of its controls and text in WoW Forever. Eight section headings were being sent to a function using the wrong argument order, passing a heading as a font style and a style name as an x-coordinate. This could interrupt construction halfway through, leaving a frame with only the first few buttons visible.

- Corrected the heading call sites, with a dedicated function that assigns the label text, proper Blizzard font template and valid numeric coordinates.
- Set explicit, readable text colors and subtle shadows for Discoveries text.
- Added stricter Lua regression tests that fail on invalid font names, wrong coordinates, missing section labels, or a partially initialized journal.
- Preserved the higher-layer journal background and bag performance improvements from 2.0.4.
- No changes to stored loot discoveries, macro recipes, profile preferences or other saved data.

**Testing:** Automated Lua 5.1 tests and addon packaging run in GitHub Actions. A final visual check in the actual WoW Forever client is still required. Open the world map, click Discoveries and confirm the entire journal—including headings, item rows, dropdowns and footer—is visible.

The playable game download is **ChalkBox-2.0.5.zip**. **ChalkBox-CurseForge-Media-2.0.5.zip** is only for CurseForge listing art and documentation.

Repository: https://github.com/detok/ChalkBox
