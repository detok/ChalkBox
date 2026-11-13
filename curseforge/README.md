# ChalkBox — 2.0 GitHub + CurseForge launch kit

**Status: GitHub 2.0 prerelease prepared for in-client testing. The CurseForge project has not been submitted or approved; authentic gameplay screenshots are still pending.**

This folder is a **public editorial and publishing workspace**, not part of the installable WoW addon. The game release remains the single versioned `ChalkBox-2.0.0.zip` asset from [GitHub Releases](https://github.com/detok/ChalkBox/releases/tag/v2.0.0). Do not upload the repository source-code ZIP or this `curseforge/` folder as an addon.

## The product story

**ChalkBox is the quiet adventure companion for WoW Forever.** One addon brings together **MacroForge**, **automatic DropSense + Map Discoveries**, **LootSense + ProfessionSense**, **The Bar + Repair Learning**, **Session Journal**, **QuestSense**, camping, combat-meter tools, a shared theme and optional quality-of-life modules.

The story is useful information and player control—not speculative official drop percentages, AI combat or replacing Blizzard's whole interface.

## Editorial assets

| Document | Why it exists |
| --- | --- |
| [PROJECT_DESCRIPTION](copy/PROJECT_DESCRIPTION.md) | Polished listing body, ready to adapt for the CurseForge editor |
| [PROJECT_FIELDS](copy/PROJECT_FIELDS.md) | Proposed public project metadata, short summary and safe source links |
| [SHORT_COPY](copy/SHORT_COPY.md) | Headlines, captions, launch preview and GitHub About text |
| [QUICK_START](copy/QUICK_START.md) | Player-friendly first five minutes |
| [COMMANDS](copy/COMMANDS.md) | Current 2.0 command reference |
| [FAQ](copy/FAQ.md) | Concise answers and important technical limitations |
| [FEATURE_PROOF](copy/FEATURE_PROOF.md) | Claim-to-code matrix and honest live-client QA boundaries |
| [SUPPORT_AND_CREDITS](copy/SUPPORT_AND_CREDITS.md) | Support and licenses |
| [BRANDING](../docs/BRANDING.md) | Original ChalkBox visual identity and six committed SVG assets |
| [SCREENSHOT_PLAN](artwork/SCREENSHOT_PLAN.md) | Real-client capture plan—no fake UI screenshots |
| [PUBLISH_CHECKLIST](submission/PUBLISH_CHECKLIST.md) | Account, file, policy, screenshot and launch steps |
| [GITHUB_PRESENTATION](submission/GITHUB_PRESENTATION.md) | Front-page structure and **manual GitHub About** tasks |
| [QA_AND_POLICY](submission/QA_AND_POLICY.md) | Publishing guardrails |

Older version-specific `FILE_CHANGELOG_1.x.md` files are **archival**, not copy for 2.0.

## Artwork truth

Six original branding SVGs are already committed under [artwork](artwork/). Flat PNGs can be exported from these sources for a hosting portal if required. **Do not claim the brand's feature illustration is a real WoW screenshot.** The `ChalkBox/assets/Icon.tga` in the addon remains unchanged until verified in-client.

## Release gate

1. Both TOCs say **2.0.0** and the release ZIP contains one `ChalkBox/` folder.
2. GitHub's **Lua tests and installable ZIP** workflow is green on the merged commit.
3. The World Map Discoveries late-loading fix is tested **in the actual Forever client**, including the command fallback and diagnostics.
4. MacroForge spellbook, generated macro copy, save/reload and optional native installation are tested in client.
5. Real feature screenshots are captured before adding a gallery.
6. Only then prepare the CurseForge author upload/approval; until approved, keep primary downloads on GitHub.

**No separate dependency, fake screenshot, fake rate, or claimed CurseForge listing.**
