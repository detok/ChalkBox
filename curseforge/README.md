# ChalkBox — CurseForge launch kit (first pass)

**Status: editorial package prepared; artwork not created; CurseForge project not submitted.**

This directory contains the working content and production plan for a polished ChalkBox project on CurseForge. It is **not** part of the WoW addon installed by players. The installable release remains the existing `ChalkBox-<version>.zip` built by `scripts/package.py`.

## Start here

1. **[PROJECT_DESCRIPTION.md](copy/PROJECT_DESCRIPTION.md)** — the complete, paste-ready CurseForge project description. Markdown-mode is recommended; inspect the published preview.
2. **[PROJECT_FIELDS.md](copy/PROJECT_FIELDS.md)** — title, summary, flavor, categories, license and links for the project form.
3. **[ARTWORK_TO_CREATE.md](ARTWORK_TO_CREATE.md)** — the single master creative brief for the *next pass*. **No artwork or simulated game screenshots have been made.**
4. **[PUBLISH_CHECKLIST.md](submission/PUBLISH_CHECKLIST.md)** — ordered checklist from author account to reviewed public project, with release-file checks.

## Copy and reference documents

| File | Purpose |
| --- | --- |
| [SHORT_COPY.md](copy/SHORT_COPY.md) | Alternate summaries, opening pitches, promotional captions |
| [FEATURE_PROOF.md](copy/FEATURE_PROOF.md) | Feature/claim verification against the present source code, plus boundaries |
| [QUICK_START.md](copy/QUICK_START.md) | Installation and first five minutes for an end user |
| [FAQ.md](copy/FAQ.md) | Common questions and honest client limitations |
| [COMMANDS.md](copy/COMMANDS.md) | Compact, accurate command reference |
| [SUPPORT_AND_CREDITS.md](copy/SUPPORT_AND_CREDITS.md) | Bug-report template, MIT credit and library acknowledgements |
| [FILE_CHANGELOG_1.9.0.md](copy/FILE_CHANGELOG_1.9.0.md) | Text to use with the v1.9.0 file upload |
| [ARTWORK_TO_CREATE.md](ARTWORK_TO_CREATE.md) | Identity, design system, exact requested image concepts, priorities |
| [SCREENSHOT_PLAN.md](artwork/SCREENSHOT_PLAN.md) | Capture instructions and per-shot visual storyboards |
| [ARTWORK_FOLDER.md](artwork/ARTWORK_FOLDER.md) | Eventual asset directory naming/organization, no fake files |
| [PUBLISH_CHECKLIST.md](submission/PUBLISH_CHECKLIST.md) | CurseForge UI workflow and gates |
| [GITHUB_PRESENTATION.md](submission/GITHUB_PRESENTATION.md) | GitHub landing page, primary download links, About metadata, optional branch-protection steps |
| [QA_AND_POLICY.md](submission/QA_AND_POLICY.md) | Accuracy, moderation, file packaging and screenshot QA |

## Editorial source of truth

This kit was prepared against **ChalkBox v1.9.0** on the public GitHub `main` branch (2026-11-13), including its two TOCs, Lua modules, current documentation and release process.

- [Source repository](https://github.com/detok/ChalkBox)
- [Current source README](../README.md)
- [User guide](../docs/USER_GUIDE.md)
- [Changelog](../CHANGELOG.md)
- [Release notes](../docs/RELEASE_NOTES.md)
- [Third-party notices](../NOTICE.md)

**Important distinctions:** TrailBar has **drag-to-reorder sections, per-character saved module alignment and charcoal opacity**, alongside bag, gear, rested XP, optional latency, Hunter pet, XP and gold modules. Native action-bar empty-slot hiding is a WoW Edit Mode setting, **not a ChalkBox feature**. Blizzard's native-meter PRINT menu and the separate-bag offset are implemented, but still need real in-client confirmation. LootSense remains advisory, adds an in-game Item Insight section and outlines only truly learned-recipe ingredients; it never auto-sells.

## Publishing discipline

- **Do not** upload `curseforge/` or a GitHub source-code archive as the game addon. Use the versioned installation ZIP with a single top-level `ChalkBox/` directory.
- **Do not** paste GitHub Release download links into the CurseForge description; use CurseForge's own Files tab for downloads.
- Keep the listing free of fabricated screenshots, false endorsements, affiliation claims and features that have not shipped.
- Update version references, images and change log when a later release supersedes 1.9.0.
- Do not publish the listing as completed or claim CurseForge approval until the site actually approves it.
- This documentation-only commit should **not** change addon TOC versions or generate a new addon release.

## Next pass

The next request can simply be: **“Use `curseforge/ARTWORK_TO_CREATE.md` and `curseforge/artwork/SCREENSHOT_PLAN.md` to make the ChalkBox CurseForge artwork.”** Actual in-game screenshots should be supplied/captured from the real client; marketing backgrounds and icon art can be designed separately.
