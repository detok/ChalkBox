# QuestSense Smart — Forever API and tracker audit

Status: **draft integration for live Forever verification**. The last stable release remains ChalkBox 2.2.26. This does not introduce a separate quest tracker.

## Existing behavior reviewed

- `QuestSense.lua` collects accepted quests and original quest-log headers through `C_QuestLog.GetInfo`. It owns only watches it adds, and temporarily suspends manual watches for Nearby or a confirmed current dungeon.
- Before this branch, Smart mostly ranked map quest associations (+400), zone headers (+350), local POIs (+80), and recently accepted quests (+600), with original log index as the tie-breaker. The recently-accepted bonus could outrank a quest the player could do immediately.
- Nearby queried the top-level zone, which could miss actual micro-map quest evidence.
- `QuestTrackerMenu.lua` added a header-only right-click menu and did not alter individual objective rows.
- The native Forever `QuestObjectiveTrackerMixin:BuildQuestWatchInfos` builds the visible watched-quest array; its `UpdateSingle` renders each native quest row, with headers and objectives. `C_QuestLog.SortQuestWatches` exists but has no arbitrary-order parameter.

## Client evidence and policy

- Prefer `C_QuestLog.GetDistanceSqToQuest(questID)` for the actual current objective/turn-in, **only** if it returns public numeric square distance and confirms the same continent. This is a native distance, not NPC spawn prediction.
- For Nearby, merge accepted quest IDs from the player subzone and its current zone, plus valid native `GetNextWaypointForMap` coordinates. Optionally permit native distance evidence within a user-chosen short radius; default remains zone-only.
- Sort by real distance, zone, quest level, title or original log order. Explicitly selected/accepted quest watches remain protected by the existing owner/reconciliation logic.
- Apply optional native display sorting to the **instantiated QuestObjectiveTracker frame**, never just its original mixin prototype; do not remove/re-add quest watches to reorder them. Disable sorting in combat, and restore Blizzard's display order when switched off.
- Keep manual watches, saved muted/suspended state, verified dungeon matching, the navigation target and safe map/quest-log/combat deferrals.

## Source comparisons

- Blizzard's Forever `Blizzard_QuestObjectiveTracker.lua` `BuildQuestWatchInfos` and `UpdateSingle` specify how the native tracker builds and renders quest rows.
- Blizzard's Forever `QuestLogDocumentation.lua` lists `GetDistanceSqToQuest`, `GetNextWaypointForMap`, `SortQuestWatches`, and quest-log info fields.
- Questie `TrackerUtils.lua` and `DistanceUtils.lua` use area grouping and objective-distance comparisons but have a separate tracker and access to Questie's own quest database; ChalkBox intentionally does not copy that model.
- BetterTracker and Zone Names on Quest Tracker demonstrate zone headings on the Forever UI, but modifying native block layout and collapse state needs additional live-client safety validation. **This branch does not claim to create visual zone headers.** Zone order is available as a non-invasive sort now.

## Live acceptance gates

1. Open Smart with around 40 accepted quests. Nearest public quest objective in the selected current-zone group appears first when Native tracker order is enabled; remote/unlocated quests do not displace local ones.
2. Change zones, move farther than another objective, and wait for the 12-second scan. The native tracker reorders without a watch-count change or duplicates.
3. Switch sorting between nearest, zone, level, title and log from settings and the tracker-header context menu. Disable custom order and confirm Blizzard's original order returns.
4. Toggle Nearby zone-only, then a 500-yard radius; verify nearby native evidence is respected and remote quests are not fabricated.
5. Confirm manual watches, explicit unwatch, current-dungeon-only focus, quest navigator, combat lockdown, map-open deferral, and reload all retain their current safety.
6. Test with other objective-tracker addons disabled; code integration shares the native tracker method, so multiple simultaneous tracker-altering addons cannot be assumed compatible.

## Deferred zone headings

Native per-zone separators and collapse buttons require native block geometry integration, rather than sorting alone. Treat them as a distinct opt-in UI gate after the above behavior is validated in Forever. Do not replace the entire native tracker or overwrite native quest titles merely to simulate a heading.
