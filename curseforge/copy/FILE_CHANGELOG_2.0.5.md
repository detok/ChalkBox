# ChalkBox 2.0.5

### Discoveries

- Fixed the actual cause of the incomplete Discoveries journal: eight section heading calls supplied text as a font style, producing invalid font arguments and stopping window initialization in the live client.
- All window sections now finish constructing with valid Blizzard font templates, numeric coordinates, and real label text.
- Applied explicit readable text colors and subtle shadows to the journal's labels, details and item rows.
- Added stronger regression coverage for bad font calls, missing headings and partially built windows, including the lazy-loaded world map.

### Preserved behavior

- Discoveries journal frame, background, dropdown filters, search and retained observations.
- Bag-performance improvements from 2.0.4: reduced highlight rescanning and vendor-value recalculation.
- Grouped settings, closed-by-default DPS meter, and all character settings and history.

This is a World of Warcraft: Forever test build. A real-client visual pass is still required before public promotion.
