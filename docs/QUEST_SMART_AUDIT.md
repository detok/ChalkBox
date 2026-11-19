# QuestSense Smart — Forever API and tracker audit

Status: **2.2.28-quest-beta live Forever verification**. The latest stable release remains ChalkBox 2.2.26. No separate or protected tracker replaces Blizzard's UI.

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
- Native quest-tracker method replacement is disabled after a `SetPassThroughButtons()` protected-action report. Keep selection ranking and Nearby improvements while leaving Blizzard tracker methods untouched.
- Keep manual watches, saved muted/suspended state, verified dungeon matching, the navigation target and safe map/quest-log/combat deferrals.

## Source comparisons

- Blizzard's Forever `Blizzard_QuestObjectiveTracker.lua` `BuildQuestWatchInfos` and `UpdateSingle` specify how the native tracker builds and renders quest rows.
- Blizzard's Forever `QuestLogDocumentation.lua` lists `GetDistanceSqToQuest`, `GetNextWaypointForMap`, `SortQuestWatches`, and quest-log info fields.
- Questie `TrackerUtils.lua` and `DistanceUtils.lua` use area grouping and objective-distance comparisons but have a separate tracker and access to Questie's own quest database; ChalkBox intentionally does not copy that model.
- BetterTracker and Zone Names on Quest Tracker demonstrate zone headings on the Forever UI, but modifying native block layout and collapse state needs additional live-client safety validation. **This branch does not claim to create visual zone headers.** Zone order is available as a non-invasive sort now.

## Live acceptance gates

1. With at least ten accepted local quests, switch Nearby to 5 then 10. Check its diagnostic local/eligible counts and verify no remote quest enters solely to fill slots.
2. Compare **Closest First** and **Lowest Level First** in Smart; these select watches only and intentionally do not modify Blizzard's visual row sorting.
3. Accept a new eligible quest with a full automatic selection; it should be retained while the older, lower-priority automatic choice is displaced.
4. Complete a quest; the default selection puts unfinished objectives first and keeps completed quests last, unless the user opts into Completed First.
5. Confirm manual watches, explicit unwatch, current-dungeon-only focus, Quest Navigator, combat/map-open safety, party toggles and reloading all retain their behavior.
6. Test with other quest addons disabled first. Where fewer than five/ten eligible local objectives can be verified, the remaining slots intentionally stay empty.

## Deferred zone headings

Native per-zone separators and collapse buttons require native block geometry integration, rather than sorting alone. Treat them as a distinct opt-in UI gate after the above behavior is validated in Forever. Do not replace the entire native tracker or overwrite native quest titles merely to simulate a heading.
