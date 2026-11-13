# ChalkBox 2.0.4

### Discoveries
- Fixed the standalone Discoveries journal's floating-controls appearance by placing its entire window above the Blizzard Map & Quest Log.
- Added a native framed backdrop and a reliable solid background texture. The journal remains legible with custom theme settings.
- Preserved the map button, zone/dungeon switching, source filters, sorting and recorded loot history.

### Bags and TrailBar
- Combined rapid bag-item redraws into fewer ingredient-highlight passes.
- Reused learned-recipe lookups for matching stacks during a single pass.
- Debounced inventory and item-cache events and reduced repeated full-bag vendor-value scans.

### Compatibility
- No SavedVariables reset or changes to character data.
- Retains the 2.0.2 grouped settings and closed-by-default DPS meter.
- Client-specific presentation and bag responsiveness should be confirmed in WoW Forever.

The separate CurseForge media kit contains original branding and listing copy. Upload ChalkBox-2.0.4.zip as the addon, not the media kit.
