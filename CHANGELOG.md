# Changelog

All notable changes to the public ChalkBox addon are documented here.

## 1.8.6 — Adaptive rich-stat TrailBar

- **Actually implemented** new TrailBar readings: equipped bag free/total slots (ordinary vs specialized in tooltip), weighted equipment durability and lowest-condition warning, rested bonus XP as % of one level, optional home/world latency and optional Hunter pet health.
- Guard all readings against missing Forever APIs, protected/secret combat values and invalid data. Never infer pet health or count unavailable items as free.
- Add **TrailBar Stats** to native ChalkBox options, with nine switches and working Balanced, Minimal and All presets. Defaults feature bags, gear and rested XP; latency starts off.
- Rebuild the 18px widget layout to fit left/center/right groups without overlap and hide lower-priority fields on narrow displays without changing saved choices.
- Add `/chalk bar stat <module> on|off`, `/chalk bar stats <preset>` and `/chalk bar stats` diagnostics.
- Retain the existing XP progress line, money, session time, UIParent screen-space reservation, separate-bag offset, DPS features and all other ChalkBox modules.
- Extend Lua 5.1 regression tests for native readings, specialty bag counts, weighted durability, rested XP, secret Hunter health, native settings, profiles and adaptive layout.
- Refresh GitHub README, user guide and CurseForge listing draft for the real release.

## 1.8.5 — Blizzard damage-meter PRINT integration

- Add **ChalkBox: PRINT top 3 to PARTY** to the gear/settings menu of Blizzard Forever's built-in damage meter, using its supported `MENU_DAMAGE_METER_WINDOW_SETTINGS` extension point.
- Report the selected **native window's** damage/DPS/healing/interrupt statistics and selected current, overall, or saved fight; fall back to the last fight if the current session is empty and the client supports that lookup.
- Keep privacy and combat safeguards: manually initiated, never in combat or Edit Mode, never solo or in a raid, no handling secret combat values, no chat redirection and a three-second repeat guard.
- Add `/chalk meter native on|off|status` to enable or disable the built-in gear-menu entry (enabled by default).
- Keep ChalkBox's separate meter unchanged and optional: `/chalk meter hide` lets you use only the Blizzard meter while retaining the native-print integration.
- Add Lua 5.1 coverage for native gear-menu extension, currently selected stat/session, historical fights, protected data, and chat restrictions.
- Preserve LootSense, the separate-bag slider, Action Bar behavior and all other ChalkBox features.

## 1.8.4 — Separate-bag position control

- Add a default-off **0–80-point vertical offset** for Blizzard's individual bag windows (including profession bags), with a 30-point starting suggestion for bags clipping off the top.
- Show an adjustable slider under native **ChalkBox → TrailBar** settings, plus `/chalk bags offset 30`, `/chalk bags reset`, and `/chalk bags status`.
- Securely post-hook Blizzard's `UpdateContainerFrameAnchors()` so the whole open bag stack moves together, without replacing item slots, inventory or sorting.
- Respect the original combined-bags position, never shift in combat, and reapply after combat rather than causing protected-frame errors.
- Regression tests cover no stacking on repeated layout, saved slider behavior, slash commands, combat deferral and stock reset.
- Preserve TrailBar's existing 18px display, DPS meter, QuestSense, LootSense and all other features.

## 1.8.3 — LootSense First Aid material accuracy

- Prevent broad Cloth item-subclass guesses from being labeled as First Aid materials; First Aid now needs recipe evidence.
- Validate saved First Aid ingredient and learned-recipe claims against the bundled Forever First Aid recipe data, filtering stale or mismatched profession scan records.
- Preserve Leatherworking recipes using Small Lustrous Pearl and correctly recognize actual First Aid ingredients such as Linen Cloth.
- Add a targeted Lua 5.1 regression test for mismatched saved pearl data and valid Leatherworking and First Aid cases.
- All DPS meter, party PRINT, RESET, custom layout, QuestSense, camping and other ChalkBox features remain unchanged.

## 1.8.2 — One-line party DPS report and on-window reset

- PRINT sends a **single, manual top-three summary to PARTY chat** after combat, for the meter's selected statistic and fight scope; fallback to last fight when current is empty.
- Uses Forever's modern `C_ChatInfo.SendChatMessage` API (legacy fallback for Classic), respects protected combat values, refuses solo/raid misdelivery, avoids duplicate clicks and respects 255-character chat limit.
- Adds an on-window **RESET** button between PRINT and LOCK; calls the existing confirmation before clearing shared Blizzard meter data, never during combat.
- Keeps the compact class-icon header, opacity, lock/resize, QuestSense and the one-ZIP distribution.
- Expanded Lua 5.1 tests cover chat restrictions and actual group targeting without leaking protected data.

## 1.8.1 — Native class and specialization icons for the DPS meter

- Show compact genuine WoW **class emblems** beside combatant names, default on, using Blizzard's class sheet and `C_DamageMeter.classFilename`.
- Offer **Class / Spec / Off** choices from the native Combat Meter options and `/chalk meter icons class|spec|off`.
- Spec mode uses Blizzard's `specIconID` fileID when supplied, with an accurate class fallback. Unknown/pet sources use a neutral question mark instead of inventing a player class.
- Icons fit inside the existing compact resizable rows; hiding them restores name width. Empty rows clear their icon to prevent stale player identification.
- Protected player names and combat numbers remain untouched. Zero external files/dependencies, still one ZIP with all other modules preserved.
- Extend mock tests for atlas coordinates, native fileID handling, unknown sources, icon toggles, row cleanup and settings integration.

## 1.8.0 — Forever QuestSense rebuilt, movable top toast, cleaner DPS meter

- Replaced zone-POI-dependent QuestSense with a **C_QuestLog accepted-quest** watch manager that works even when Forever map pins aren't available.
- Smart (default), Nearby only and All accepted tracking modes, with optional 5/10/15/20 auto-watch limits.
- Respects manual watches/untracking, protects state while world map/quest log/combat is open, retries after unsafe periods, and surfaces useful diagnostics.
- Moved Adventure Prep toast to screen top by default; new Toast Appearance native page provides position lock, 35–100% opacity, 25-second move preview and Reset to Top. Locked notices remain click-through.
- Removed the DPS meter X button while preserving show/hide through settings and slash commands.
- Added regression coverage for absent map APIs, map/combat deferrals, muted manual watches, GUI toast drag/alpha settings, and no-X meter control.
- Kept the single ZIP and 2,511 bundled MIT Forever recipes.

## 1.7.1 — Boosted Rest Camp Tent detection and personalized DPS meter

- Detect Camp Tent's **Boosted Rest (1229451) harmful debuff** and sufficient Rested XP independently of ordinary Camp Benefits; suppress false reminders and show separate status.
- Add a one-hour, session-only **Tent Used** acknowledgment in Adventure Prep when aura detection isn't available.
- Remove the DPS meter's CHALKBOX header logo and unnecessary bottom explanation.
- Add direct on-window **LOCK/UNLOCK**, **PRINT**, opacity slider, and bottom-right drag-to-resize grip with saved width/row count.
- Print native fight numbers only to local chat **after combat**, refusing protected results instead of leaking or inventing data.
- Add opacity slider in native settings and `/chalk meter opacity N` commands; keep all other addon modules unchanged.
- Add new tests for harmful-aura detection, rested-XP thresholds, protected fight printing and drag/opacity/lock behavior.

## 1.7.0 — Built-in native DPS and combat meter

- Added a compact, class-colored, draggable ChalkBox combat meter with an obvious marker for your own character.
- Modes: DPS, Damage Done, HPS, Healing Done, Damage Taken and Interrupts. Sessions: Current Fight, Last Fight and Overall.
- Added show/hide, lock, 5/8/12 rows, 85/100/115% scaling, position reset and deliberate reset confirmation in native AddOns settings.
- Uses Blizzard's native `C_DamageMeter` API and event-driven updates. Secret values are passed directly to protected-safe text/status bar UI setters, never processed in Lua.
- Preserved working LootSense with 2,511 bundled Forever recipes, CampSense, TrailBar, QuestSense, QuietGuard and Emota.
- New Lua 5.1 tests cover native combat API, protected values, modes, visibility and resetting; one ChalkBox ZIP still ships.

## 1.6.1 — Forever profession scan and tooltip fixes

- Let `C_TradeSkillUI` establish an active owned profession when legacy profession APIs are unavailable, instead of blocking recipe scans.
- Listen to `TRADE_SKILL_LIST_UPDATE` and `TRADE_SKILL_DATA_SOURCE_CHANGED`, plus a short delayed scan, so recipes loading after the panel opens are captured.
- Fall back to alternate reagent APIs when a modern recipe schematic is missing or empty.
- Continue LootSense tooltip advice when `GetItemInfo` has not cached an item yet.
- Add actionable `/chalk loot status` diagnostics for enabled state, active profession, scanner backend, and learned-recipe count.
- Preserve one-ZIP bundle, exact MIT notices, and all other gameplay modules.

## 1.6.0 — Complete offline Forever recipes in one download

- **Bundled the MIT-licensed LibProfessionDB 1.9.1 Forever-only database** (2,511 recipes), with original Pimptasty copyright/license and the public-domain LibStub loader.
- Replaced the optional external database install with a truly self-contained ChalkBox ZIP.
- Fixed recipe matching against static entries lacking localized recipe names. Names resolve from the client spell API first, then crafted-item names, with an honest ID fallback.
- Made offline recipe indexing deterministic, improved tooltip advice when you already have enough materials, and retained the distinction between **known recipe** and **potential use**.
- Added an integration test loading all 2,511 real bundled recipes and archive/license checks.
- Original standalone addons are still excluded; CampSense, TrailBar, QuietGuard, Emota and QuestSense unchanged.

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
