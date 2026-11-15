# ChalkBox maintainer runbook

**Working operational checklist · current baseline 2.2.15**

This is how to investigate a report, make a change without breaking established behavior, verify it, and prepare it for release. It complements [Architecture](ARCHITECTURE.md), [Development](DEVELOPMENT.md) and [Publishing](RELEASE_PROCESS.md).

## Triage an incoming bug

1. **Collect evidence:** version shown in ChalkBox → Updates; game build and client flavor; zone/instance; what the player clicked; expected vs actual; any Lua error and a cropped screenshot. Do not ask for credentials, account IDs or private chat.
2. **Identify the owner:** locate the corresponding file(s) using [Architecture](ARCHITECTURE.md). Read the actual `main` version, not a stale memory of the implementation.
3. **Reproduce safely:** use the current user command (see [Commands](COMMANDS.md)) and the smallest relevant `tests/test_*.lua`. A screenshot proves appearance, but not what hidden client data an API returned.
4. **Check common restrictions:** combat lockdown, world map / bank open, missing map atlas, unavailable secret API values, delayed event, stale SavedVariables, AH cooldown, no learned spells, no observed loot, missing dungeon POIs.
5. **Write a focused hypothesis and failing regression** before changing the public behavior. If Forever's exact response is uncertain, plan a manual test and mark it as unverified.
6. **Make the smallest compatible fix**, run every test and verify the package. Add player-readable diagnostics rather than silently suppressing unknown states.
7. **Open a PR** with files changed, evidence, versions, tests, and which in-game behaviors are still untested.

## Do not regress these established behaviors

| Area | Regression contract | In-game smoke test |
| --- | --- | --- |
| Native settings | Blizzard's normal Settings background remains visible; ChalkBox pages have no opaque rectangular black layer | Open multiple ChalkBox pages over a bright in-game background |
| Discoveries | Map-docked panel above the map, usable dropdown/source selection, map button and readable wood styling; no fake rates or coordinates | Open World Map; choose area/source; hover items with and without recorded locations |
| MacroForge | Seven framed groups, a native or fallback outer frame, multiline scrollable preview, bounded warnings, preserved copy and save/install safeguards | Open UI at two scales, scroll long text, save/load, install new outside combat only |
| Quest navigation | Defaults OFF, read-only accepted quest waypoints, no quest-watch/super-track/pin writes; position and manual choice per character | Enable, Auto/Next/manual, verify native quest-watch selected-target pinning, map-canvas hover pulse and Sharp HD/Classic 256px texture toggle; test real WoW north/south world-X and west/east world-Y cardinals, selected/super-tracked quest precedence, stable Auto fallback, ghost corpse/parent map/resurrection, right-click native/legacy menu, hover tooltip, missing instance GPS and saved position, unload and relog |
| QuestSense | Manual watches are preserved; Smart dungeon-only mode requires verified match; no-data fallback does not clear watches | Test outside, then in a known dungeon, then after exiting; `/chalk quests status` |
| The Bar | Saved per-character layout persists, right-click **Done editing** available, widths do not break protected game UI | Move stats, exit via context menu, relog, resize client |
| QuietGuard | Fresh filters OFF; saved ON choices preserved; Blizzard-native filtering may differ | Check defaults and opt-ins on a test profile; no automatic blocking when off |
| DropSense | Dedup loot windows; rates only for identified sources; bounded locations; no instance position inference | Loot two different outdoor mobs; open same corpse again; view map tooltip |
| Auction / DE | No scan without a user request, no trade action, old good scan survives failure, price asks ≠ actual sales | Open AH tab and close/reopen, test cooldown/failure; inspect tooltip disclaimers |
| Bank / bags | Avoid protected item-button changes or shifting bags during first-bank initialization | Open bank first time after login; close and test separate bag offset |
| Combat meter | Starts closed, protected values handled safely, manual print gated | Start/stop combat, inspect session, test manual print after combat |
| Adventure Journal | The independent window always has a readable native/fallback outer frame, warm wood background and two inset sections, even at zero global opacity; v1 session data preserved | Open current and older sessions with opacity zero, retry native atlas, change theme live; see [Chronicle design](ADVENTURE_CHRONICLE_DESIGN.md) |
| Session, camp, Emota | Session history bounded; tent use ≠ Camp Benefits; automatic emotes optional and avoid combat | Relog, camp/tent acknowledgment, idle preview and combat |

## Versioning and release decision

- **Gameplay behavior changed:** bump `## Version:` in *both* TOCs, update [changelog](../CHANGELOG.md), [release notes](RELEASE_NOTES.md), relevant docs and publishing copy; then follow [Release process](RELEASE_PROCESS.md).
- **Documentation only:** no version bump. The PR still needs link checks and both ZIP tests. Do not claim a new playable version has shipped just because docs were merged.
- **UI only:** still needs a version bump when players will install a changed addon ZIP; tests cannot guarantee color, z-order, scale or client-specific atlas presentation.
- **Failure or incomplete CI:** do not merge. If the GitHub CI does not trigger, diagnose event/workflow status; do not treat "mergeable" as "tested."
- **Live-client discrepancy:** keep the observation as an issue and distinguish it from what passed in mocked tests.

## Releasing and communicating

Check the successful PR-head CI, merge to `main`, then confirm the push workflow and actual GitHub release **asset names**. On an existing tag the workflow may refresh the media kit only; it does not rebuild an old game asset in place.

A useful release announcement should state exactly what changed, the preserved preferences and limitations, how to install, what to test in-game, and a link to the release and PR. Avoid promises of automatic gameplay or verified Forever APIs when untested.

## Managing documentation

README is an overview, [User handbook](USER_GUIDE.md) is the current workflow, [Commands](COMMANDS.md) is the canonical slash reference, [Troubleshooting](TROUBLESHOOTING.md) handles support, and [Release notes](RELEASE_NOTES.md) describe the current tagged build. Historical notes belong in [Changelog](../CHANGELOG.md); do not pile chronological release summaries into the landing page.

GitHub has a repository Wiki, but these **versioned docs are authoritative**. A wiki landing page can link to them, but avoid maintaining competing feature descriptions that drift.

[Documentation home](README.md) · [Contributor guide](../CONTRIBUTING.md) · [Publishing](RELEASE_PROCESS.md)
