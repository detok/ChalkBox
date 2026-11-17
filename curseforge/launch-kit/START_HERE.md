# ChalkBox 2.2.22 — stable-release publisher's kit

**Two distinct files:**

- **Installable game addon:** [ChalkBox-2.2.22.zip](https://github.com/detok/ChalkBox/releases/download/v2.2.22/ChalkBox-2.2.22.zip). Contains one `ChalkBox/` folder; upload this as the playable CurseForge file.
- **Publisher materials:** [ChalkBox-CurseForge-Media-2.2.22.zip](https://github.com/detok/ChalkBox/releases/download/v2.2.22/ChalkBox-CurseForge-Media-2.2.22.zip). Contains the art, gallery captures, site text and checklists; **not installable**.

## What goes where

| Location on the site | What to use in the media ZIP |
| --- | --- |
| Project icon / avatar | `Artwork/PNG/Upload-Ready/Project-Icon-512.png` |
| Promotional/social banner, where supported | `Artwork/PNG/Upload-Ready/ChalkBox-Social-Banner-1200x630.png` |
| Full project description | `Copy-and-Checklist/copy/PROJECT_DESCRIPTION.md` |
| Short summary / settings | `Copy-and-Checklist/copy/PROJECT_FIELDS.md` and `SHORT_COPY.md` |
| Per-file release changelog | `Copy-and-Checklist/copy/FILE_CHANGELOG_CURRENT.md` |
| Gameplay gallery | Genuine captures under `Screenshots/`; consult `screenshots/README.md` for age and ordering |
| Support/help URL | https://github.com/detok/ChalkBox/issues/new/choose |
| GitHub social preview | `Artwork/PNG/Upload-Ready/ChalkBox-Social-Banner-1200x630.png` (upload in GitHub Settings) |

**Editorial-Only artwork is not a game screenshot.** The ten original gallery images were recorded on an earlier build. Keep authentic historical captures only if they still represent the current module; prioritize fresh AuctionSense full-scan and bag-integration screenshots.

## Release steps

1. Ensure the intended ZIP on CurseForge is **2.2.22** and update Release Type to **Release** in the author portal. No new file is required solely to change its type, if the portal allows editing the existing upload.
2. Copy the current project description and short summary into the project page. Leave the old canonical links in place only if they still point to current materials.
3. Upload the square project avatar. Use banner art only where an actual banner or social-image field exists.
4. Add genuine current-client game captures to the gallery. Do not label editorial artwork as actual gameplay.
5. Verify supported WoW Forever game flavor, license, version, dependency, and file status before saving.
6. Verify that public visitors can access the project page, playable download, GitHub issues and support docs.

No installer source files are modified in this publisher kit. Preserve user SavedVariables on all upgrades.


**2.2.25 GitHub beta:** Adds saved bank vendor value and a frameless bank readout, adjustable Trail Bar module widths, safe ranked PARTY/SAY combat reports, learned flight-master markers, map-pin navigation and a read-only AuctionSense chart. [Read the current 2.2.25 release notes](https://github.com/detok/ChalkBox/blob/main/docs/RELEASE_NOTES.md). **2.2.22 remains the last fully accepted stable version** until the combined beta passes a live-client smoke test.
