# ChalkBox integration baseline — 2026-11-17

## Source of truth
- **Default branch: `main`**. Compare the actual code and addon manifests before deciding a PR implements missing functionality.
- Keep both `ChalkBox.toc` and `ChalkBox_Camelot.toc` in sync; no version bump is included in this consolidation.
- Do not merge old stacked branches over the current implementation merely to close PRs.

## Consolidated into main
- PR #95: focused Discoveries opening / Combat Meter settings fixes and release-readiness audit.
- PR #97 (supersedes #94 and #96): native MapCanvas marker renderer and loot-map normalization, with compatibility fallback.
- PR #93: curated, specifically sourced future-quest hints and purple bag overlays.
- PR #85's Nav Beacon map-waypoint implementation was already present in `main`; code and tests matched by Git blob SHA, so PR #85 was closed without a duplicate merge.
- Historic Market, Bank Value, Discoveries and integration drafts (#78, #79, #84, #86–#90) were closed as superseded; active code is in `main`.

## Excluded
- PR #92's imported quest-reference database was **not** merged because upstream redistribution rights are unresolved. Do not copy its bundled dataset into a release.
- PR #96's earlier repeated manual-drawing fix was superseded by the native pin architecture. Do not reinstall or merge it over current `main`.

## Acceptance before stable release
1. Install a ZIP built from the current main tree, preserving existing SavedVariables; verify no duplicate addon folder or stale install.
2. On WoW Forever, inspect Booty Bay and other **learned** flight-path icons on continent and zoomed zone maps. Check visible icon, tooltip, panning, reopen, `/reload`, and map Filter checkbox. Run `/chalk drops flights status` if missing.
3. Verify Discoveries loot hover map marker on a zone and subzone, normal loot recording, and Discoveries panel opening with the World Map initially closed.
4. Check future quest hints in bags, accepted quest text remains unchanged, combat-safe overlays, and combined-bag limitations.
5. Verify Nav Beacon Follow Map Pin, removal, moving waypoints and corpse priority.
6. Verify Market scanning, Bank Value, Trail Bar, Combat Meter, settings navigation, and existing saved state.
7. Run Lua regression tests, Lua 5.1 syntax verification, deterministic addon ZIP and CurseForge packaging. Record results on the release candidate.
8. Do not promote to stable, tag a new version, or publish to CurseForge until the client checks and licensing review are complete.

## Operating rule
One authoritative main, one release candidate at a time, no claims of a live-client fix based solely on mocked tests. Keep future work as focused PRs against `main` and retire merged or superseded PRs promptly.
