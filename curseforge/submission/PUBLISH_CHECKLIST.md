# ChalkBox 2.0 — publication and test checklist

**Status: GitHub 2.0.0 prerelease, not a completed CurseForge launch.** This checklist is meant to prevent marketing from getting ahead of the real Forever client.

## A. Engineering gate

- [ ] Both Forever \`.toc\` files specify **2.0.0**, and \`scripts/package.py\` still bundles every required module.
- [ ] **Lua tests and installable ZIP** checks pass on the merge commit.
- [ ] Download \`ChalkBox-2.0.0.zip\` from a GitHub **release asset**, not “Source code (zip).”
- [ ] Check one top-level \`ChalkBox/\` folder, included \`LICENSE\`, full recipe library and no unbundled addon dependency.
- [ ] Verify existing SavedVariables persist across upgrade (DropSense, MacroForge, The Bar, repair history, sessions, KEEP).

## B. 2.0 in-client smoke test — required before full release

- [ ] Open WoW Forever, open the world map after a fresh login: **Discoveries** button visibly attaches near the upper-left map controls.
- [ ] Switch map zones, expand/collapse, windowed/fullscreen layouts and UI scales; button stays clickable without hiding native quest pins.
- [ ] If it doesn't appear, **/chalk drops map** opens standalone; **/chalk drops map status** explains map frame, attachment, visibility and toggle.
- [ ] Loot different creature types, a mixed-source window and (if possible) a dungeon: recorded counts are credible, no fake universal percentage.
- [ ] MacroForge lists genuinely learned spells and icons. Test opener, modifier and sequence previews, copy via Ctrl+C, optional explicit native macro creation, respec detection, save/reload.
- [ ] Inspect The Bar's right-click menus, repair/vendor values and readability at narrow screen widths.
- [ ] Camp toast preview, QuestSense native tracker, compact/native meter PRINT and Session Journal relog history.
- [ ] Capture any error, full Forever build, 2.0.0 version and screenshots; resolve crashes/reproducible client breakage before recommending public installation.

## C. GitHub presentation

- [ ] README hero, versioned direct download, module catalog, caveats and issue links all resolve after merge.
- [ ] GitHub owner updates **About** description, website and topics using [GITHUB_PRESENTATION](GITHUB_PRESENTATION.md).
- [ ] GitHub owner uploads a branded social preview PNG separately (README alone cannot set it).
- [ ] Add actual gameplay screenshots following [SCREENSHOT_PLAN](../artwork/SCREENSHOT_PLAN.md); do not reuse editorial illustrations as gameplay.
- [ ] Keep the **2.0 prerelease** label until player-tested.

## D. CurseForge author portal — only when ready

- [ ] Sign in and verify author account; check [official submission guidance](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips).
- [ ] Confirm project title **ChalkBox** is available and that **Forever** is a supported target flavor in the current portal.
- [ ] Choose truthful categories, MIT license, source, issue tracker, and text from [PROJECT_FIELDS](../copy/PROJECT_FIELDS.md) + [PROJECT_DESCRIPTION](../copy/PROJECT_DESCRIPTION.md).
- [ ] Export the original logo SVG to PNG accepted by the live portal. Do not use fabricated gameplay screenshots.
- [ ] Upload the tested ZIP only to the portal's Files area; follow moderation and version policies.
- [ ] Until approved, never claim a CurseForge listing, download count, badge or project URL.
- [ ] After approval, optionally add the *verified* CurseForge URL to GitHub while retaining GitHub Releases as the primary direct-download option.

Historical v1.9 file change logs remain archival; use [current 2.0 release notes](../../docs/RELEASE_NOTES.md) for the prerelease.
