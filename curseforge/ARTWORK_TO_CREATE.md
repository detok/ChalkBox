# ChalkBox visual identity and artwork production brief

> **FOR THE NEXT PASS. This is a specification, not completed artwork.**  
> No new images have been created in this first pass. Do not mark any item “Done” until the actual file exists, is visually reviewed and is checked into `curseforge/artwork/`.

## Art direction — recognizable and distinct

**Product:** ChalkBox  
**Tagline:** A quieter, smarter way to adventure.  
**Style:** readable, confident, slightly playful, refined fantasy-utility aesthetics. Think a crafted adventurer's information kit, **not** a fake screenshot or a copy of another WoW addon logo.  
**Core message:** Intelligent *context*, not visual noise. A small box with the details you need.

### Suggested identity

- **Logo symbol:** custom chalk-drawn treasure/utility box or small open satchel inside a simple geometric frame. An optional soft four-point waypoint star can evoke “insight”; do not use Blizzard trademarks, official WoW iconography, or a copied class crest as the primary brand mark.
- **Wordmark:** `ChalkBox` in a bold, highly legible face. Avoid thin script or medieval lettering that is unreadable at 200px.
- **Color palette (starting point):**
  - Midnight navy `#101B27` — backgrounds
  - Deep blue-gray `#203342` — panels and outlines
  - Warm parchment `#EFE3C4` — primary text
  - Antique gold `#DDAE61` — focus/accent
  - Muted teal `#67C6B7` — information/positive
  - Signal coral `#D88376` — rare caution
- **Look:** crisp lines, subtle parchment grain only in large decorative art, no tiny unreadable texture. Keep UI screenshots real and distinct from marketing illustration.
- **Typography:** a clean readable display/serif or sturdy geometric headline, paired with a neutral sans body. Artwork should contain very few words.
- **Avoid:** offensive/playful slurs, copyrighted fantasy character illustration, third-party logos without authorization, AI-generated fake in-game panels, screenshots that promise unimplemented features.

## Priority assets (all to be produced in second pass)

Dimensions below are recommended **working canvases**, not assertions about CurseForge’s current mandatory upload sizes. Check the actual author form's accepted formats, resolution, crop and file-size rules before final export.

| Priority | Filename to create | Working canvas | Composition / content | Intended placement |
| --- | --- | --- | --- | --- |
| P0 | `chalkbox-project-icon-512.png` | 512×512 square | Symbol-only chalk-box logo, high contrast, minimal detail; readable at 64px | CurseForge icon/avatar and GitHub identity reference |
| P0 | `chalkbox-hero-1600x900.png` | 1600×900 landscape | Main headline “ChalkBox”, tagline, tasteful motif, empty clean area for real game screenshot insert later | GitHub README hero / CurseForge gallery |
| P0 | `chalkbox-banner-1200x630.png` | 1200×630 landscape | Cropped marketing banner; product + very short value proposition | Social/OG thumbnail, README promotional image |
| P1 | `chalkbox-feature-grid-1600x900.png` | 1600×900 landscape | Editorial overview of LootSense/TrailBar/QuestSense/CampSense/Combat Meter with short module labels | CurseForge gallery after screenshots available |
| P1 | `chalkbox-trailbar-explainer-1600x900.png` | 1600×900 landscape | **Real screenshot** cropped to show level, XP rate, gold; arrows/callouts only outside native pixels | Product screenshots/gallery |
| P1 | `chalkbox-lootsense-example-1600x900.png` | 1600×900 landscape | **Real in-game tooltip**, captured showing known vs possible uses | Product screenshots/gallery |
| P1 | `chalkbox-native-meter-print-1600x900.png` | 1600×900 landscape | **Real built-in damage meter menu**, with ChalkBox party print option visible and sensitive names hidden | Key differentiator screenshot |
| P2 | `chalkbox-combat-meter-1600x900.png` | 1600×900 landscape | **Real ChalkBox compact meter**, class icons, modes and PRINT/RESET controls | Gallery |
| P2 | `chalkbox-questsense-1600x900.png` | 1600×900 landscape | **Real native quest tracker** beside ChalkBox QuestSense settings | Gallery |
| P2 | `chalkbox-adventure-prep-1600x900.png` | 1600×900 landscape | **Real toast**, visually unobtrusive and readable | Gallery |
| P2 | `chalkbox-bag-offset-1600x900.png` | 1600×900 landscape | **Real** separate bags shown fully onscreen; slider set at 30, before/after only if accurate | Gallery |
| P2 | `chalkbox-settings-1600x900.png` | 1600×900 landscape | **Real** native ChalkBox AddOns settings categories | Gallery |

### Minimum launch art set

1. Logo/avatar.
2. Hero/wordmark image.
3. Three authentic feature screenshots: **LootSense**, **TrailBar**, **native damage meter PRINT**.
4. Optionally a clean features mosaic, built by compositing the real screenshots (no invented UI).
5. Additional modules as the game capture allows.

## Design and export rules

- Keep source exports editable in your working design tool; store flattened `.png` in this folder. Avoid submitting layered/proprietary working files to the addon ZIP.
- Product symbol must work at 64×64; build the square source at 512×512 and export 256×256 if the portal demands it.
- Headlines should remain readable after scaling to mobile. Plan a generous text-safe area.
- Screenshots must be **the actual running ChalkBox/Forever UI**. The image-generation pass may create the logo, background ornament, frames and tasteful infographic furniture, but **must not fabricate in-client functionality**.
- Hide/blur character names, chat handles, party identities and private fields unless you own/consent to publishing them.
- Keep text length short enough for preview thumbnails.
- Don't upload media containing embedded binaries/scripts.
- If any image includes Blizzard-owned game screenshots or textures, use them only as accurate context and avoid implying official endorsement. Observe the platform's media/copyright policies.

## Next-pass workflow for artwork

**Phase 1 — brand creation:** Create symbol-only logo, wordmark, hero and banner, checking palette, readability and consistency.  
**Phase 2 — truthful screenshots:** User captures the 6–8 described game states (or supplies current screenshots) using `SCREENSHOT_PLAN.md`.  
**Phase 3 — composite:** Produce polished side-by-side callouts that use real captured UI, not invented gameplay.  
**Phase 4 — review:** Inspect every asset at full size and thumbnail size, validate crop and dimensions, capture filename, and commit to `curseforge/artwork/`.  
**Phase 5 — integration:** Add images to GitHub README and CurseForge Markdown/media gallery where supported; do not hotlink unapproved assets.

## Prompt to use next time

> Use `detok/ChalkBox/curseforge/ARTWORK_TO_CREATE.md` and `curseforge/artwork/SCREENSHOT_PLAN.md` as the official visual brief. First create the branded logo, hero and banner, using ChalkBox’s color palette and tone. Do not redesign or fabricate the game interface. Leave screenshot-derived promotional assets pending until real in-game screenshots are supplied; then make composites and integrate them into both the GitHub README and CurseForge gallery.

## Status matrix

| Asset group | Status |
| --- | --- |
| Logo / icon | Not created |
| Hero / banner | Not created |
| Real Forever screenshots | Not supplied |
| Feature composites | Not created |
| GitHub image integration | Pending assets |
| CurseForge image upload | Pending project creation and moderation |
