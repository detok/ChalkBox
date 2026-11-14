# ChalkBox 2.1.3 — Native meter reports and cleaner item tooltips

### Blizzard damage meter
- Open the Blizzard damage meter's **gear menu → Combat reports**.
- Print to **PARTY** or **SAY** from the selected native meter mode and session.
- Choose **Top 3 / Top 5 / Top 10** players to include.
- Optional **after-combat reports** are OFF by default. Customize channel (PARTY/SAY), stat (DPS/damage/healing), minimum fight duration (0/10/20/30 seconds) and cooldown (30/60/120 seconds).
- Reports post a single compact message. Protected or incomplete data, invalid party channels, repetitive summaries and too-frequent automatic messages are suppressed. No automated trading or combat actions.

### Tooltips
- Remove repeated **CHALKBOX | ITEM INSIGHT** branding from item tooltips: just the colored status and supporting evidence.
- Rename the loot annotation's heading to **Drop Journal**, without repeating the addon name.

### Install
Install `ChalkBox-2.1.3.zip` as the single ChalkBox addon folder, replacing the old folder but keeping SavedVariables. Type `/reload`, then open Blizzard's damage meter and use the gear menu. No new standalone meter is needed.

Automated CI covers Lua 5.1 syntax, module regressions and installable ZIP integrity. Check menu availability and chat permissions in a real WoW Forever client before assuming every option works on that server.
