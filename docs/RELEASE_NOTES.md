# ChalkBox 2.2.13 — Minimal QuestSense Arrow

The QuestSense Navigator is now **just a small floating arrow**—no opaque background, border, mini window, title label, distance row or permanently displayed buttons.

**Right-click the arrow** for **Auto (follow tracked)**, **Next quest**, and **Hide arrow**. **Left-drag** to move it unless you have locked its position under **Options → AddOns → ChalkBox → QuestSense → Navigation**.

**Hover** over the arrow to see the quest name, straight-line distance in yards, or a clear reason GPS is unavailable. When Forever cannot provide a safe direction (including instances), the arrow fades to neutral gray rather than showing a misleading heading.

Your existing navigation state, chosen quest, saved position and settings remain unchanged. Auto still respects Blizzard's super-tracked quest when it has usable coordinates and otherwise picks the nearest known local waypoint. QuestSense's separate Smart / Nearby / All tracking continues unchanged. ChalkBox never sets map pins, overwrites super-tracking or changes watch choices through navigation.

`/chalk nav on` brings the arrow back after Hide. The existing `/chalk nav` commands and settings controls remain available.

**Testing:** Lua 5.1 mocked tests cover the no-box frame, hover tooltip, native and legacy right-click menus, moving, lock and reset, missing waypoint state, all navigation target priorities and saved-state compatibility. Live Forever UI appearance should still be inspected before promoting from Beta.

Install `ChalkBox-2.2.13.zip` over the existing ChalkBox folder, preserve SavedVariables and type `/reload`.
