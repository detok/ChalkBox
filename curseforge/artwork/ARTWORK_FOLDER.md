# Artwork directory — planned assets, no images yet

This directory intentionally contains **Markdown instructions only** during the first pass. There are **no placeholder PNGs**, generated image files or fabricated World of Warcraft UI screenshots.

Read the master brief [ARTWORK_TO_CREATE.md](../ARTWORK_TO_CREATE.md), then use the matching shot list in [SCREENSHOT_PLAN.md](SCREENSHOT_PLAN.md).

## Planned files

```text
curseforge/
  artwork/
    ARTWORK_FOLDER.md                    # this file
    SCREENSHOT_PLAN.md
    chalkbox-project-icon-512.png       # not created
    chalkbox-hero-1600x900.png          # not created
    chalkbox-banner-1200x630.png        # not created
    chalkbox-feature-grid-1600x900.png  # not created
    chalkbox-trailbar-explainer-1600x900.png    # not created
    chalkbox-lootsense-example-1600x900.png    # not created
    chalkbox-native-meter-print-1600x900.png   # not created
    chalkbox-combat-meter-1600x900.png         # not created
    chalkbox-questsense-1600x900.png           # not created
    chalkbox-adventure-prep-1600x900.png       # not created
    chalkbox-bag-offset-1600x900.png           # not created
    chalkbox-settings-1600x900.png             # not created
```

**Important:** These are proposed working dimensions and naming conventions. Before publishing, verify CurseForge's current media restrictions and crop behavior in the author portal.

## File conventions

- Export finished, reviewed promotional assets to PNG or another supported portal format; keep consistent dimensions within each gallery.
- Use the brand colors, typography and creative approach in the master brief.
- Keep source screenshot pixels from actual WoW Forever gameplay. Do not mock game menus, damage values, party names or inventory contents and present them as screenshots.
- Store no unverified image placeholders here. Only add completed files.
- Never add this directory to `scripts/package.py`: it is **marketing collateral**, not addon code.
- After art creation, reference actual GitHub raw files from `README.md` or relative repository paths, and upload appropriate images to the eventual CurseForge project.

## Capture hand-off

The user may supply authentic screenshots for the second pass. If no screenshots are available, create **logo and decorative hero/banner only**, and leave all gameplay features as text until verified captures exist.
