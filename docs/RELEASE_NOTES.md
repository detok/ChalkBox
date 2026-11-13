# ChalkBox 1.8.2 — One-click party DPS report + RESET button

The DPS meter now has everything you need right on the window.

## PRINT → Party chat
- Click **PRINT** after a fight to send **one short message** to normal `PARTY` chat, summarizing the **top three** player results for the currently selected DPS / damage / healing / other mode and Fight / Last / Overall scope.
- Example: `CB DPS (Last): 1 Detok 555 | 2 Companion 423 | 3 Friend 318`.
- If **Fight** is empty, ChalkBox tries the previous completed fight.
- Uses Forever's modern **`C_ChatInfo.SendChatMessage(message, "PARTY")`** API, with the legacy function fallback only when the modern one isn't present.
- A solo player or raid member gets a local explanation; it **never** silently redirects to SAY, RAID, or instance chat.
- Doesn't read or format **secret combat values** while fighting or when they remain protected after combat. If the game still masks results, it shows a reason instead of posting an inaccurate message.
- Refuses rapid duplicate reports (three-second cooldown) and keeps messages within WoW's 255-character limit. **Never auto-posts**: only the button or `/chalk meter print` initiates a report.
- If the client restricts chat messages in an instance, the failure is reported locally without retry spam. Please include game build when reporting the failure.

## RESET → Confirmed clear
- A new visible **RESET** button sits next to PRINT, retaining the small no-branding/no-X meter header: **DPS | Fight | PRINT | RESET | LOCK**.
- RESET opens the **existing confirmation dialog**; confirming clears **all Blizzard-shared damage meter sessions**, not just the current ChalkBox display. It won't reset during combat.
- The original Settings **Reset Data...** and `/chalk meter reset` still work.

## Unchanged
Native class/spec icons, mode and session choices, opacity, lock/resize, Combat Meter settings, QuestSense, camp toasts, LootSense with 2,511 bundled Forever recipes, and every other ChalkBox module.

## Install
Download just **ChalkBox-1.8.2.zip**, replace your `Interface/AddOns/ChalkBox` folder, and `/reload`.

**Public prerelease:** Lua 5.1 tests cover modern + classic chat APIs, one-line formatting, protected data, solo/raid safeguards, click rate limiting, and on-window reset confirmation. Test the PARTY send in actual Forever gameplay; some instance chat restrictions must be verified on your specific client.
