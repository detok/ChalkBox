# Changelog

All notable changes to the public ChalkBox addon are documented here.

## 1.5.1 — Public launch

- Established **detok/ChalkBox** as the one-and-only public home for the combined addon.
- Reorganized into a clean installable `ChalkBox/` folder, with a matching **single ZIP release**.
- Kept the original addon icon and all ChalkBox feature modules and Lua regression tests.
- Added open-source licensing, installation and user documentation, issue templates, and CI.
- Removed the old multi-addon collection build, standalone-source packages and standalone regression targets.
- No gameplay feature rewrite; the module baseline is v1.5.0. Optional third-party database compatibility remains a prerelease feature.

## 1.5.0 — Recipe-aware LootSense

- Tracked names and available reagent quantities from **learned** character recipes.
- Prioritized known-recipe evidence over broad profession-family hints.
- Added optional separately installed LibProfessionDB adapter for *potential* recipe uses.
- Added Shift-expanded known recipe detail and `/chalk loot status` diagnostics.

## 1.4.0 — Buff-aware camping

- Added Camp Benefits / Welcoming Campfire aura checks.
- Added a compact, timed center-screen toast and test button.
- Recognized additional Forever campsite ingredients, including Light Leather.

## 1.3.0 — More adventuring awareness

- Added QuietGuard social-invite controls and CampSense checklist.
- Added race/class context and resting-area behavior to Emota.

## 1.2.0 — Emota idle personality

- Randomized intermittent idle emotes, no-repeat rotation, and safe temporary poses.

## 1.1.1 — TrailBar layout

- Reserved screen space for TrailBar instead of placing it over gameplay UI.

> Earlier development happened in a private collection repository. The public repository contains **only ChalkBox**; it deliberately does not publish the historical standalone addons.
