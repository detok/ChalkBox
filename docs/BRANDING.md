# ChalkBox — visual identity

**The Quiet Adventure Companion**  
*A quieter, smarter way to adventure.*  
**Know more. Miss less. Keep playing.**

ChalkBox's visual identity treats the addon as a small, useful adventurer's kit: the open supply box conveys practical tools; the small four-point star conveys discovering useful context. These are original geometric designs, not Blizzard game artwork or simulated in-game UI.

## Design principles

1. **Small but useful** — every feature solves a real in-game inconvenience.
2. **Native first** — prefer Blizzard's existing panels, buttons, tooltips and tracker.
3. **Quiet by default** — information appears at the moment it matters; no unnecessary alerts.
4. **Honest evidence** — separate verified data, possible hints and unavailable signals.
5. **One addon, one download** — optional modules, no mandatory companion installation.
6. **Reversible** — easy controls, predictable saved settings, no forced gameplay actions.

## Palette

| Token | HEX | Role |
| --- | --- | --- |
| Night | `#11151B` | Brand backgrounds |
| Charcoal | `#141416` | In-game native surfaces |
| Slate | `#2B3139` | Supporting panels |
| Parchment | `#EFE3C4` | Main lettering |
| Antique gold | `#DDAE61` | Brand focus / highlight |
| Muted teal | `#67C6B7` | Positive / contextual insight |
| Coral | `#D88376` | Caution only |
| Quiet text | `#9CA8AE` | Supporting metadata |

Typography: a substantial readable serif for display wordmark, straightforward sans serif for explanations, generous spacing and large text-safe margins. The mark must remain recognizable at 64×64.

## Committed editable vector artwork

| File | Canvas | Use |
| --- | --- | --- |
| [Project icon](../curseforge/artwork/chalkbox-project-icon-512.svg) | 512×512 | App listing/avatar source |
| [Wordmark](../curseforge/artwork/chalkbox-wordmark.svg) | 1280×270 | Brand lockup, transparent |
| [GitHub header](../curseforge/artwork/chalkbox-github-header-1600x470.svg) | 1600×470 | README top image |
| [Hero](../curseforge/artwork/chalkbox-hero-1600x900.svg) | 1600×900 | Large marketing illustration |
| [Social banner](../curseforge/artwork/chalkbox-banner-1200x630.svg) | 1200×630 | Social/OG image source |
| [Feature overview](../curseforge/artwork/chalkbox-feature-grid-1600x900.svg) | 1600×900 | Editorial feature overview |

SVG originals are text-based, editable and independent of any font download. Export a flat PNG using Inkscape, Illustrator, Figma, browser screenshot, or `cairosvg`. The separate delivery ZIP also includes PNG exports at the named sizes, plus 64/128/256 icon reductions and a 1280×640 social preview.

## Rules for publishing

- **Do not portray generated panels or map graphics as live Forever screenshots.** Actual in-game screenshots still need to be captured from ChalkBox running in Forever.
- In particular, **MapSense / seamless maps are proposals, not shipped features**. Don't show them as already implemented.
- The brand art is not an official Blizzard logo or endorsement.
- Keep `curseforge/artwork/` outside the packaged `ChalkBox-<version>.zip`: branding is marketing collateral, not addon code.
- For CurseForge use the exported PNG artwork and check its live upload requirements. The listing and screenshots have **not** been uploaded.
- Do not overwrite the addon icon `ChalkBox/assets/Icon.tga` until the new identity has been tested in the client.

## Authentic gameplay media still needed

See [screenshot capture plan](../curseforge/artwork/SCREENSHOT_PLAN.md): a real LootSense tooltip, TrailBar, native meter PARTY print, quest tracker, settings, and the other client states. Add screenshots only after visual and functional review.
