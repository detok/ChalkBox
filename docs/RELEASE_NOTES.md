# ChalkBox 1.9.0 — The Polish Update

The goal of v1.9.0 is to make ChalkBox feel more like an intentional part of World of Warcraft Forever: **a movable, configurable TrailBar, darker Blizzard-like presentation, in-game LootSense tooltips, learned-recipe ingredient highlights, richer menus, and race behavior controls.**

## TrailBar Edit Mode: your information, your layout

- Open **Esc → Options → AddOns → ChalkBox → TrailBar Appearance**, then click **Edit Bar**.
- **Drag** individual stats to reorder them within the bar or into its left, center or right third. The app stores the module's new order and section **per character**.
- **Right-click a module during edit mode** to cycle its own text alignment: left, center, right.
- Click **Done Editing** to relock, or **Reset Layout** to restore the original module positions.
- The layout engine still hides lower-priority enabled stats if a small screen cannot fit them; saved orders aren't lost. The slim strip stays **18px tall**.
- Commands: `/chalk bar edit on|off`, `/chalk bar layout`, `/chalk bar layout reset`, `/chalk bar move bags center 2`, `/chalk bar align gold right`.

## Blizzard-inspired background with real transparency

- Replaced the bluish TrailBar background with neutral near-black charcoal, matching the tone of Blizzard's standard interface more closely.
- New **Background opacity 0–100%** slider under **TrailBar Appearance**. At 0%, the bar background disappears and readable information/XP underline remains. Your stat text is **not** faded by the slider.
- Quick command: `/chalk bar opacity 0` through `/chalk bar opacity 100`.
- The default remains comfortably dark rather than opaque.

## LootSense feels at home in the item tooltip

- Removed the robotic `LootSense: ...` prefix. Item advice now appears as a restrained, native-text multi-line **CHALKBOX | ITEM INSIGHT** section.
- Separates short statuses such as **Used in a learned recipe**, **Keep this item** and **Possible crafting use** from the evidence. Existing quest, camp and learned-recipe checks are unchanged.
- Preserves the critical distinction between **KNOWN** and **POTENTIAL** recipes.

## Highlight ingredients from recipes you really know

- Subtle emerald insets surround reagent icons in Blizzard's real inventory/bag frames **only** when a current character-learned recipe uses that item.
- A recipe found only in the bundled 2,511-recipe database **never** earns a green highlight.
- **LootSense Appearance** native settings: enable/disable markers, independent marker opacity (15–100%), Refresh Bag Markers, and Scan Open Profession.
- No item button replacements, inventory sorting, clicks, selling or automation. Works with standard individual and compatible combined bag frames where the client exposes them.

## Better configuration across ChalkBox

- The ChalkBox settings landing page is reorganized into clean, two-column navigation with dedicated categories for **TrailBar Stats**, **TrailBar Appearance**, **LootSense Appearance**, **Emota Race Behavior** and existing tools.
- All existing module options, TrailBar stats presets, Combat Meter/party PRINT, QuestSense and camp toast controls remain.

## Emota Race Behavior

- New **Emota → Races** page with a race chooser (native dropdown when provided, Previous/Next fallback) and **Off / Subtle / Default / Expressive** racial flavor intensity.
- Dwarf, Human, Night Elf, Gnome, Orc, Troll, Tauren, Undead, Blood Elf, Draenei, Worgen, Goblin, Pandaren and Earthen use **existing real weighted flavor**. Default stays exactly as before.
- Additional race names are **visibly labeled planned**. They have no invented special actions or pretend functionality.
- Selecting another race is a preview/configuration choice; only your character's actual race affects its live emotes. Automatic Emota reactions remain opt-in and retain anti-spam safety rules.

## Intuitive vertical separate-bag placement

- Replaced the unintuitive 0–80 horizontal slider with a **vertical -120 through +120 UI-point slider**.
- The **midpoint (0)** is Blizzard's own bag position; moving the thumb **up** raises the separate bag stack, **down** lowers it.
- Label shows signed displacement and direction. **Reset Bags** restores 0.
- Existing combined-bag exclusion, automatic reanchoring and combat deferral remain.
- The slash command now accepts negative values: `/chalk bags offset -35` (up), `offset 40` (down), `reset` (stock).

## Testing, compatibility and acknowledgements

- Lua 5.1 CI now covers the native bag-marker refresh system, learned-recipe-only classification, protected item handling, editable per-character bar layout/dragging, zero-to-full background opacity, native settings, race behavior intensities and the signed bag position.
- Still a **WoW Forever public prerelease**: client-specific native UI hooks, drag feedback and race dropdown rendering should be smoke-tested in-game.
- Maintains the single installer `ChalkBox-1.9.0.zip`, 2,511 embedded credited recipes and third-party licenses; no external services required.

**Direct GitHub releases:** https://github.com/detok/ChalkBox/releases  
**Bug reports:** https://github.com/detok/ChalkBox/issues  
**In-game settings:** `/chalk` or `/cb`
