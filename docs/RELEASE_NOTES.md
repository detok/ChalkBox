# ChalkBox 1.9.2 — The Bar

## Repair cost module
- **Repair** appears in The Bar by default (and can be toggled under **The Bar Stats**).
- With a repair merchant open, shows a verified **exact repair-all cost**, when exposed by the Forever API.
- Elsewhere, shows a clearly marked **~ estimate**, scaled from a previous exact merchant quote and your currently missing equipped durability. Calibration is saved per character.
- Without a usable observed quote, or when changed equipment makes extrapolation unreliable, shows **Repair --**. Never guesses a made-up repair price.
- The hover detail explains exact vs approximate, worn item coverage, possible bag gear, and discounts. **No automatic repair or spending**.

## Right-click menus for The Bar
- Right-click individual modules outside Edit Mode: toggle their visibility, move them between sections, choose text alignment, adjust bar placement, edit/reset the layout, and open The Bar's native settings.
- Right-click unused Bar background for all module visibility controls, including restoring hidden widgets.
- Menus use Blizzard_Menu when present, with legacy EasyMenu fallback. Configuration controls are disabled in combat.
- In Edit Mode the original right-click alignment cycle remains; Bag Value left-click still flips Junk vs Total.

## Naming and compatibility
- TrailBar is now called **The Bar** in native UI and docs. Existing `/chalk bar` commands, old SavedVariables, existing on-disk Lua module names and layouts are **unchanged**.
- All other 1.9.1 and 1.9.0 features are preserved.
- Automated Lua 5.1 and installable ZIP validation; in-game look and menu testing is still recommended.
