# ChalkBox — CurseForge publishing assets

**ChalkBox 2.2.21 is an unpublished Forever AuctionSense full-scan repair candidate. Do not upload it until tests and in-client verification pass; earlier downloadable links below are retained as reference.**

This folder is for publishing **the separate addon ZIP and supporting listing materials**. It does not replace the installed ChalkBox addon, and it must not be distributed as a game-addon bundle.

## Which file is which?

| Artifact | Use |
| --- | --- |
| [ChalkBox-2.2.17.zip](https://github.com/detok/ChalkBox/releases/download/v2.2.17/ChalkBox-2.2.17.zip) | **Actual game addon**; one `ChalkBox/` directory |
| [ChalkBox-CurseForge-Media-2.2.17.zip](https://github.com/detok/ChalkBox/releases/download/v2.2.17/ChalkBox-CurseForge-Media-2.2.17.zip) | **Publisher media kit only**; PNG/SVG art, authentic game JPGs, listing copy and checklists |

Do not upload the media ZIP as the addon, or the automatic GitHub source ZIP as a game file.

## Publisher's starting point

- [Start here](launch-kit/START_HERE.md): mapping media assets to actual submission fields
- [Current project description](copy/PROJECT_DESCRIPTION.md) and [short copy](copy/SHORT_COPY.md)
- [Current file changelog](copy/FILE_CHANGELOG_CURRENT.md), not historical `FILE_CHANGELOG_*.md` archives
- [Project fields](copy/PROJECT_FIELDS.md) and [publish checklist](submission/PUBLISH_CHECKLIST.md)
- [FAQ](copy/FAQ.md), [command reference](copy/COMMANDS.md) and [proof/limitations](copy/FEATURE_PROOF.md)
- [Artwork master files](artwork/) and [genuine client screenshots](screenshots/README.md)
- [Official in-repo release process](../docs/RELEASE_PROCESS.md) and [maintainer QA](../docs/MAINTAINER_RUNBOOK.md)

The media kit includes six original SVG design files, nine rendered PNGs and ten genuine captured WoW Forever JPGs. **Editorial-Only** illustrations are *not* gameplay screenshots. Some existing game captures depict earlier UI revisions; review them before asserting that a current release looks exactly the same.

## Compatibility and credits

ChalkBox targets **WoW Forever**. Verify the live CurseForge portal's supported version/flavor options before uploading a game file. Do not label an unsupported Retro/Classic/Retail selection as verified simply to pass the form.

**Created and maintained by Detok Whitemaine.** Original source under [MIT](../LICENSE); bundled third-party licenses remain in the runtime library directories. [Source](https://github.com/detok/ChalkBox) · [Issues](https://github.com/detok/ChalkBox/issues). Independent community project, not endorsed by Blizzard.

## Keep the kit current

On each new runtime release, update `copy/FILE_CHANGELOG_CURRENT.md` with a heading matching both TOC versions and revise the public listing copy when features change. `scripts/test_curseforge_kit.py` checks the packaged current changelog's version. It is safe to retain historical per-version changelog files as archives, but **never use them as the current upload**.
