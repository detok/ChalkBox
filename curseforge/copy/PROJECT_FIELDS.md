# CurseForge project creation — field-by-field copy

**Use these values in the CurseForge author console.** Treat dropdown wording as live-site dependent; verify the fields presented by the author portal before submitting.

| Field | First-pass value | Note |
| --- | --- | --- |
| Game | World of Warcraft | Select WoW, not another game's mod class |
| Class | Addons | Native WoW addon |
| Project name | **ChalkBox** | Confirm name availability in the create form |
| Summary | **WoW Forever utility addon with native loot insights, learned-recipe highlights, draggable XP dashboard, quests and DPS tools.** | One sentence, no unshipped claims |
| Primary category | **Miscellaneous** | Appropriate for a general-purpose utility addon; select only if available |
| Additional categories | **Tooltip**, **Quests & Leveling**, **Buffs & Debuffs**, **Bags & Inventory** | Up to four; confirm current CurseForge choices and relevance |
| Game flavor | **Forever** | Verified as a CurseForge WoW flavor |
| Game version | **1.60.1 (Forever)** | The currently listed Forever project version as of 2026-11-13; verify at upload |
| Project license | **MIT License** | Matches repository `LICENSE` |
| Project description | [PROJECT_DESCRIPTION.md](PROJECT_DESCRIPTION.md) | Paste in Markdown mode; preview once before saving |
| Logo | **Original SVG ready** | `../artwork/chalkbox-project-icon-512.svg`; use the 512px PNG export from the branding pack, then verify portal requirements before upload |
| File to upload | **ChalkBox-1.9.0.zip** (initial draft) | Pull the actual installable ZIP from current build/release; never the repository ZIP |
| Release type | **Beta** until verified in client; **Release** when confident | A CurseForge Release file is needed for ordinary default app sync |
| Source | https://github.com/detok/ChalkBox | Source link, **not** a third-party binary download |
| Issues | https://github.com/detok/ChalkBox/issues | Support/bug reports |
| Author credit | **Detok** | The repo author name; connect with the author account you own |
| Comments | **Enable** if you plan to moderate them | Otherwise direct players to the GitHub Issues tracker |
| Related projects | **None required** | Bundled LibProfessionDB and LibStub are already included |
| Donations/social links | **Optional, not supplied** | Never invent a link or ask for payment to unlock features |

## Compatibility and file notes

- The project ships **one installable folder** named `ChalkBox`.
- The addon includes `ChalkBox.toc` (`Interface: 11509`) and `ChalkBox_Camelot.toc` (`Interface: 16001`). The Camelot-specific TOC documents the intended Forever flavor.
- **Do not** tag other game flavors merely because a second TOC exists. Supported flavors need hands-on testing.
- Current first-pass version is **1.9.0**, published as a **public prerelease** on GitHub. Refresh version numbers and changelog before your actual CurseForge upload.
- The existing `ChalkBox/assets/Icon.tga` is the **in-game addon icon**, not a ready-to-upload CurseForge project avatar.
- CurseForge allows project Markdown or its WYSIWYG editor. Use Markdown for easier maintenance; copy directly from `PROJECT_DESCRIPTION.md`.
- Do not put a GitHub binary ZIP download link in the **public** CurseForge description. CurseForge policies disallow external file download links; use the Files tab instead.

## Verify before submitting

- [ ] Name availability and category list in the real project-creation form
- [ ] Forever flavor and compatible version available in file upload
- [ ] Correct license and third-party attribution
- [ ] Use supplied PNG export for the completed hero/icon; verify accepted dimensions
- [ ] No unsupported features in the final description
- [ ] Confirm that the file you upload is the version you describe

## Official references

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241)
- [Project submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)
- [Moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)
- [Multi-TOC for WoW addons](https://support.curseforge.com/support/solutions/articles/9000209856)
