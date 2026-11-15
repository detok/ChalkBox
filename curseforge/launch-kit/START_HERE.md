# ChalkBox 2.2.11 — publisher's launch kit

**This is the separate `ChalkBox-CurseForge-Media-2.2.11.zip`. It is NOT a playable addon.**

The playable archive is **`ChalkBox-2.2.11.zip`**, available from [GitHub Releases](https://github.com/detok/ChalkBox/releases/tag/v2.2.11). Inside it is one game-installable `ChalkBox/` directory.

## Where each media-kit file goes

| Publishing purpose | Source inside media ZIP |
| --- | --- |
| Square project avatar | `Artwork/PNG/Upload-Ready/Project-Icon-512.png` |
| Header and social artwork | `Artwork/PNG/Upload-Ready/ChalkBox-Social-Banner-1200x630.png` |
| Full page copy | `Copy-and-Checklist/copy/PROJECT_DESCRIPTION.md` |
| Short listing / metadata | `Copy-and-Checklist/copy/PROJECT_FIELDS.md` and `SHORT_COPY.md` |
| **Current file changelog** | `Copy-and-Checklist/copy/FILE_CHANGELOG_CURRENT.md` |
| Player command reference | `Copy-and-Checklist/copy/COMMANDS.md` — generated from the canonical repo handbook |
| Genuine game captures | `Screenshots/` — ten actual WoW Forever JPGs |
| Complete publisher QA checklist | `Copy-and-Checklist/submission/PUBLISH_CHECKLIST.md` |

Editorial SVG and PNG hero/feature illustrations are **not** screenshots. The existing gameplay images are genuine, but were captured on an earlier UI release; review them before claiming they show the current appearance.

## Before publishing

1. Verify that the actual CurseForge portal offers a supported **game flavor and client version compatible with WoW Forever**. Never select Retail/Classic merely to pass the form.
2. Confirm CI and the local addon/media package tests are green, both TOC versions match and the playable ZIP has one `ChalkBox/` root.
3. Perform in-client smoke tests for the changed modules. Smart QuestSense in a dungeon and the current wood-framed UI have client-specific behaviors not proven by mocked Lua tests alone.
4. Update the current file changelog to match the current TOC version. Historical `FILE_CHANGELOG_X.Y.Z.md` pages are archives.
5. Review the screen captures, credits and licenses; remove sensitive chat and identifiable account information.
6. Upload the playable addon ZIP as a **game file**, and use the separate media contents in appropriate art/description fields.
7. Share a CurseForge URL **only after the listing exists and approval is verified**.

[Full release process](https://github.com/detok/ChalkBox/blob/main/docs/RELEASE_PROCESS.md) · [Publisher checklist](../submission/PUBLISH_CHECKLIST.md) · [Source](https://github.com/detok/ChalkBox)
