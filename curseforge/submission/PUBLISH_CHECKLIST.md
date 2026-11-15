# ChalkBox publisher checklist — 2.2.10

This is a **manual checklist**, not proof that Forever client behavior or a CurseForge project has been approved. The current source of truth for build/publishing mechanics is [Release process](../../docs/RELEASE_PROCESS.md).

## Build and verify

- [ ] Both `ChalkBox.toc` and `ChalkBox_Camelot.toc` declare **2.2.10**, with unchanged intended interface IDs and identical Lua load order.
- [ ] PR CI passes Lua 5.1 syntax, the complete module test suite, addon ZIP, media ZIP and current-changelog checks.
- [ ] The main-branch workflow has published the exact release/tag and both assets are present.
- [ ] Playable `ChalkBox-2.2.10.zip` has **one `ChalkBox/` root**. No source tests or screenshots are inside it.
- [ ] The separate `ChalkBox-CurseForge-Media-2.2.10.zip` contains listing copy, 6 SVGs, 9 PNGs and 10 real gameplay JPGs.
- [ ] No missing required bundled library notices. Do not assume a top-level NOTICE exists; use the verified licenses shipped in `ChalkBox/` and `ChalkBox/Libs/`.

## Current in-game smoke checks

- [ ] Native ChalkBox AddOns pages open without an unwanted black rectangle; all nested pages are reachable.
- [ ] Discoveries docks to the World Map, its dropdown/search/source list is clickable, map sync works, and the warm wood art and border are visible or fall back safely.
- [ ] DropSense captures actual loot windows; hover old/dungeon rows without invented coordinates and new outdoor rows with correct observed-player coordinates.
- [ ] LootSense shows valid KEEP/quest objective hints and distinguishes learned recipes from possible reference uses; no automatic inventory mutations.
- [ ] QuestSense **Smart** runs outdoors and focuses on verified dungeon-specific accepted quests inside a party instance; manual watches restore on exit. With no trustworthy matches the tracker is preserved.
- [ ] AuctionSense appears in the native AH, manual browse scan works or returns a clear error, and no missing listing average is fabricated. Old good scans survive failures.
- [ ] MacroForge scans learned active spells, displays a legible multi-line preview and warnings, supports copy and safe Install New, has the native/fallback outer frame and warm inset sections.
- [ ] The Bar shows the configured stats, right-click **Done editing** works, saved layouts persist, and safe top chrome shift/bag offsets avoid protected UI.
- [ ] Combat Meter starts hidden, reports supported data and only sends a manual PARTY report where allowed. Session Journal, camp toast, Emota opt-in and QuietGuard default-OFF settings still work.
- [ ] Test at the actual Forever client build and at least one smaller UI scale/window size.

## Publishing form

- [ ] Verify a **truly compatible game version/flavor** exists in the CurseForge portal. Do not mislabel unsupported Retail or Classic compatibility.
- [ ] Project byline: **Detok Whitemaine**; source/issues/license accurate, no Blizzard affiliation claim.
- [ ] Use [Project fields](../copy/PROJECT_FIELDS.md), [Description](../copy/PROJECT_DESCRIPTION.md), [FAQ](../copy/FAQ.md) and [Current file changelog](../copy/FILE_CHANGELOG_CURRENT.md).
- [ ] Upload the **addon ZIP**, not the media ZIP or GitHub-generated Source code ZIP.
- [ ] Upload square project avatar from `Artwork/PNG/Upload-Ready/Project-Icon-512.png`.
- [ ] Review every screenshot: the ten archived genuine-client JPGs represent earlier builds and may not reflect this release's newest window styling.
- [ ] Do not label `Artwork/PNG/Editorial-Only/` graphics as gameplay screenshots.
- [ ] Set release type honestly based on current-client QA; submit and **wait for actual moderation confirmation** before sharing a project link.

## GitHub and post-release

- [ ] The README's install/release links, [docs index](../../docs/README.md), commands and examples are accurate.
- [ ] New release notes and current CurseForge changelog agree with the TOC version.
- [ ] Historical `FILE_CHANGELOG_X.Y.Z.md` files remain archival; current kit includes `FILE_CHANGELOG_CURRENT.md`.
- [ ] Confirm the actual link to the approved CurseForge project before publishing it anywhere.
- [ ] Do not silently delete previous player SavedVariables; verify upgrade from an earlier installed version.

[Publisher launch kit](../launch-kit/START_HERE.md) · [Maintainer runbook](../../docs/MAINTAINER_RUNBOOK.md) · [QA/policy](QA_AND_POLICY.md)
