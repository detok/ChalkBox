# ChalkBox 1.7.0 — Native Combat Meter 🎯

Your ChalkBox now includes a **compact, movable World of Warcraft Forever damage meter** right out of the box. No separate addon and no extra database download.

## What it does

- **DPS** (default), **Damage Done**, **HPS**, **Healing Done**, **Damage Taken**, and **Interrupts**, using Blizzard's own `C_DamageMeter` data.
- One-window design with a dark charcoal face, warm gold accent, clean class-colored progress bars, and a gold left-edge marker for your character.
- Quickly cycle **statistic** and **Fight / Last / Overall** using two buttons in the title bar.
- Drag the title bar anywhere on screen. Lock position, pick **5 / 8 / 12** visible rows, or switch between **85 / 100 / 115%** size from **Options → AddOns → ChalkBox → Combat Meter**.
- The window is visible by default; close it with **x** or type `/chalk meter` to toggle.
- Entirely event-driven refresh via `DAMAGE_METER_COMBAT_SESSION_UPDATED`, `DAMAGE_METER_CURRENT_SESSION_UPDATED`, and `DAMAGE_METER_RESET`; at most one scheduled UI refresh per 0.12 seconds, and no updates while hidden.
- No separate SavedVariables file. Window preferences live inside your existing `ChalkBoxDB`.

## Easy commands

```text
/chalk meter               toggle window
/chalk meter show          show
/chalk meter hide          hide
/chalk meter dps           DPS view
/chalk meter damage        total damage
/chalk meter hps           healing per second
/chalk meter healing       total healing
/chalk meter taken         damage taken
/chalk meter interrupts    interrupts
/chalk meter current       current fight
/chalk meter last          previous fight
/chalk meter overall       overall combat session
/chalk meter lock          stop accidental dragging
/chalk meter unlock        allow dragging
/chalk meter rows 5        compact display (also 8 or 12)
/chalk meter scale 115     larger text and bars (85, 100 or 115)
/chalk meter position reset
/chalk meter status
/chalk meter help
```

The **Reset Data...** button asks before clearing *all* Blizzard damage meter sessions (including Blizzard's own window and other addons that share it). In combat, resetting is blocked. `/chalk meter reset confirm` is available only when you're deliberately choosing to clear those shared sessions.

## Forever combat rules respected

Forever intentionally prevents addons from reading the traditional combat log. This module **never** registers `COMBAT_LOG_EVENT_UNFILTERED`, guesses pet ownership from GUIDs, or calculates its own in-combat DPS.

The **C_DamageMeter** API supplies rankings, DPS and totals. While combat is running, some fields may be **secret**. ChalkBox sends those straight to Blizzard's allowed text/status-bar display methods. It does not compare, sort, format in Lua, persist, or transmit protected amounts. **Pet attribution and source grouping are whatever the built-in Blizzard meter provides**, not an independent ChalkBox calculation.

If the client doesn't expose the native meter API, ChalkBox says so rather than showing invented numbers. Blizzard's own damage meter may also be visible; hide whichever view you don't want from the game's Edit Mode.

## Everything else stays

LootSense's **2,511 bundled Forever recipes**, CampSense buff reminders, TrailBar, Emota, QuestSense and QuietGuard are retained, unchanged in function. Only ChalkBox is in the ZIP, with the original MIT notices. Updating from 1.6.1 preserves settings.

## Verification

Lua 5.1 syntax/tests, native combat UI regression with mocked secret values that forbid Lua arithmetic, fight-stat switching, visibility/lock/scale, reset confirmation, and deterministic one-ZIP packaging.

**This is a public prerelease.** We have automated tests and source API verification, not a live Forever game-client session. If you see protected-value errors or a meter that does not populate, please send a screenshot and your client build through a [bug report](https://github.com/detok/ChalkBox/issues/new/choose). 
