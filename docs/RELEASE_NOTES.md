# ChalkBox 2.1.5 — Combat-safety hotfix

A priority fix for addon-blocked actions during combat, unexpected Bar disappearance and Emota protected-chat activity.

### Changes
- **The Bar:** Always an independent 18px top/bottom overlay. No `UIParent:ClearAllPoints`, `UIParent:SetPoint` or root resizing. Bar placement and session stats remain available; the old full-screen push-down/reserved strip is removed until we can implement it without Blizzard taint.
- **Emota:** Nothing is sent through the native emote API during combat, including mana reactions or manual previews. Out-of-combat cosmetic reactions continue to work. Automatic SIT/SLEEP/LAYDOWN/STAND posing is paused; manual previews remain available.
- **Bags:** The earlier vertical-offset hook was reanchoring Blizzard container frames that hold clickable items. This is suspended. Stock Blizzard bags work normally; existing offset preferences are retained but not applied and the slider is disabled.
- **Other modules:** Preserve the native DPS reports, auction scans, quest tracking, item insights, Drop Journal, and existing SavedVariables.

### Why
Blizzard's secure action system can propagate addon taint from global UI layout changes or protected container anchors into later combat interactions. These are concrete unsafe paths found in the addon; the exact user's blocked-function trace has not been captured. The safety release removes both paths rather than attempting to bypass protected actions.

### Install
Replace the old ChalkBox addon directory with `ChalkBox-2.1.5.zip` and type `/reload` or relaunch WoW. A full reload is necessary to clear taint from the previous session.

### Notes
Ordinary food/drink cannot be used *while combat is active* in standard WoW Classic; that restriction is game-side. However ChalkBox must not independently cause protected-action errors when using usable items. If a blocked-action error persists after updating and reloading, capture the exact blocked function name for targeted diagnosis.

Automated Lua 5.1 regression tests and ZIP validation run in GitHub Actions. Live testing on WoW Forever remains necessary.
