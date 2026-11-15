# ChalkBox 2.2.17 — Playtest polish: smaller classic arrow and native MacroForge workflow

## QuestSense navigation

- **Original WoW** is now the default arrow appearance for **newly initialized** navigator settings. This is the older `Interface\\Minimap\\MinimapArrow` look. Characters that already selected HD or Blizzard Navigation keep their saved choice; no existing preference is overwritten.
- Arrow size defaults to **48 pixels** (previously 64), with a new **32–72 px** slider in **Options → AddOns → ChalkBox → QuestSense → Navigation**. It adjusts the arrow and the small distance label together, with 4-pixel steps, without changing GPS math, target selection, corpse tracking, lock state or saved position. The choice is saved per character.
- All three familiar arrow styles remain: **Original WoW**, **Blizzard Navigation**, and **ChalkBox HD**. Use `/chalk nav size 32` through `/chalk nav size 72` if desired.

## MacroForge opens where you expect it

**The MacroForge button inside ChalkBox's AddOns settings now opens the native macro editor workflow**, not another window behind the open Settings panel:

1. Close only Blizzard's settings panel, not every game window.
2. Safely open Blizzard's existing `/macro` window when the client provides it.
3. Open our full existing MacroForge workbench alongside the native editor at the largest readable scale that fits. No native macro list/editor/buttons are modified.

A **small MacroForge button is now anchored inside the bottom button row** of Blizzard's standard macro window, after **Delete** and before **New / Exit**. The button is only attached when the client exposes those actual native controls and their spacing permits it. This replaces the easy-to-miss tab above the frame.

If Forever exposes an alternate macro layout, Blizzard's native window is left untouched and the ordinary `/chalk macro` standalone workbench remains. If the screen is too narrow for two complete windows, Forge also falls back to standalone instead of pushing the macro editor offscreen. The docked window hides when the native editor closes.

**Safety:** No automatic macro creation, replacement, or editing; native macro content and saved Forge recipes remain intact. Docking is explicit, outside combat for native UI actions.

## Verification

Mocked Lua 5.1 regressions cover classic default, size persistence and clamping, distance placement, locking/dragging, live native footer placement, settings-to-macro UI transition, safe missing-layout fallback, and existing MacroForge editing behavior. Native button positions and actual frame sizes still need confirmation from the Forever client—particularly the footer screenshot and resolution/UI-scale combinations.

This release remains **Beta** pending that visual check. Replace the existing addon folder with `ChalkBox-2.2.17.zip`, keep SavedVariables and use `/reload`.
