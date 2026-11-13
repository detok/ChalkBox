# ChalkBox v1.8.6 — CurseForge release-file changelog

**Version:** `1.8.6`  
**File:** `ChalkBox-1.8.6.zip`  
**Game:** World of Warcraft: Forever (Camelot)  
**Suggested release state:** Beta until real client tests verify the rich stats and all native integrations.

## Major improvement: TrailBar v1.8.6

The compact 18px info strip **now truly includes**:
- **Bag space**: current free slots across your backpack and equipped bags, including skinning/profession bags. Tooltips distinguish general vs specialized free slots.
- **Equipment condition**: weighted overall durability, worst-equipped-item durability and low-condition warning.
- **Rested XP**: available rested bonus experience as a percent of one level.
- **Latency**: optional world ping, with home/world ms in the tooltip.
- **Hunter pet health**: active pet health when readable; never evaluates protected/secret combat values.

Existing level/XP, XP/hour, time-to-level, session time, gold and screen-space reservation are preserved. No extra floating windows.

## Configure your own dashboard

- New native **TrailBar Stats** page, with nine saved toggles.
- Quick profiles: **Balanced**, **Minimal**, **All**.
- Responsive layout hides low-priority stats when the screen is too narrow and brings them back when there is space.
- Commands: `/chalk bar stats`, `/chalk bar stats balanced|minimal|all`, `/chalk bar stat bags|gear|rested|latency|pet|rate|eta|time|gold on|off`.

## Existing tools are still included

- LootSense and ProfessionSense item advice with 2,511 bundled licensed Forever recipes
- QuestSense Smart/Nearby/All accepted-quest watches
- CampSense aura and tent awareness, movable reminder toast
- Emota contextual idle reactions and QuietGuard invite protection
- Optional compact DPS meter and PARTY print, with class icons, opacity, reset and lock controls
- Blizzard's native damage meter gear-menu top-three PARTY print integration
- Optional separate bag-window downward offset slider

## Important compatibility notes

ChalkBox targets **WoW Forever**. Missing client data does not become invented zero values, and pet health marked secret in combat isn't calculated. Any UI client/API differences should be reported with a screenshot and exact version. Native meter print is user-triggered, normal-party only and after combat.

**GitHub is the primary direct download home:** https://github.com/detok/ChalkBox/releases  
**Issues:** https://github.com/detok/ChalkBox/issues

Tested with Lua 5.1 mock/packaging automation; final in-game observation is still needed for the newest native metrics.
