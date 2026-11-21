# ChalkBox documentation


**Stable 2.2.33:** Login block fix and separate Black Market listings. See [features](FEATURES.md).

**Stable 2.2.32:** Scan button, chronicle, intelligence, and storybook. See [features](FEATURES.md).

**Stable 2.2.31:** See [what each feature is supposed to do](FEATURES.md).

**Stable 2.2.30:** Combat meter fallback, bar resize, auction scans, and a simpler data transfer. Saved data is kept.

**Previous 2.2.29:** Original AuctionSense Market/scanning interface restored. The experimental Intelligence Lab is paused; its saved data is preserved. ChalkBox Combat Meter reporting is completely removed, while the local meter display remains.

This is the **versioned documentation home** for ChalkBox. GitHub has a Wiki feature, but keeping the primary instructions here means user guides, tests and the actual Lua implementation can be reviewed in the same pull request. Release documentation lives with the code it describes.

**Stable release: 2.2.29 · World of Warcraft: Forever · [Download the official playable ZIP](https://github.com/detok/ChalkBox/releases/latest). Retail and ordinary Classic are unverified.

## Player guides

| Start here | What you'll find |
| --- | --- |
| [Installation and first run](GETTING_STARTED.md) | Correct ZIP, directory, configuration and safe updates |
| [Full user handbook](USER_GUIDE.md) | Practical workflows and limits for every module |
| [Command reference](COMMANDS.md) | Actual `/chalk` and `/cb` commands, grouped by module |
| [Troubleshooting](TROUBLESHOOTING.md) | Common failures, diagnostics and what to include in reports |
| [Screenshot gallery](SCREENSHOT_GALLERY.md) | Real game captures and their version limitations |
| [Latest release notes](RELEASE_NOTES.md) | What changed in the current build |
| [Historical changelog](../CHANGELOG.md) | Individual changes across earlier versions |

## Developer and maintainer guides

| Reference | Purpose |
| --- | --- |
| [Full Adventure Chronicle design](ADVENTURE_CHRONICLE_DESIGN.md) | Future verified event ledger, Today/Timeline/History plan; Gate A visuals only shipped in 2.2.17 |
| [QuestSense navigation](QUEST_NAVIGATION.md) | Optional arrow, target priorities, controls, API and test boundaries |
| [Architecture and state](ARCHITECTURE.md) | Module boundaries, local SavedVariables and API safety |
| [Development and tests](DEVELOPMENT.md) | Lua 5.1 environment, manifest order and test commands |
| [Maintainer runbook](MAINTAINER_RUNBOOK.md) | Reproduce issues, approve changes, review gameplay and UI |
| [Releases and CurseForge](RELEASE_PROCESS.md) | GitHub Actions, addon ZIP vs. media kit, prereleases and publication |
| [Release-readiness audit](RELEASE_READINESS_AUDIT.md) | Full 2.2.25 module/link audit, open risks, and live-client go/no-go checklist |
| [Contributing](../CONTRIBUTING.md) | PR standards, test expectations, licensing and screenshots |
| [Recipe database and licensing](RECIPE_DATA.md) | Bundled Forever recipe provenance and proof levels |
| [AuctionSense design notes](AUCTIONSENSE_DESIGN.md) | Technical background; read code for current behavior |
| [MacroForge design notes](MACROFORGE_DESIGN.md) | Secure macro constraints, with historical design rationale |
| [Branding](BRANDING.md) | Assets and visual identity |

## Finding the right source of truth

- **What the addon currently does:** shipped `ChalkBox/*.lua` modules and their automated tests.
- **How players should use it:** the [user handbook](USER_GUIDE.md) and [commands](COMMANDS.md).
- **How a change reached players:** [release notes](RELEASE_NOTES.md), [changelog](../CHANGELOG.md), tagged GitHub releases.
- **How to package and publish:** [release process](RELEASE_PROCESS.md), CI workflow and build scripts.
- **What may be planned but not shipped:** design documents. They are not promises of game behavior.

A feature is not considered documented merely because it appears in a historical changelog. Update the relevant user workflow, technical reference and release notes whenever behavior changes.

[Back to project README](../README.md) · [Report an issue](https://github.com/detok/ChalkBox/issues/new/choose)



**Developer beta:** ChalkBox 2.2.27 is a QuestSense Smart experiment; 2.2.26 remains the supported stable release. [Beta notes](https://github.com/detok/ChalkBox/blob/feature/smart-quest-native-priorities/docs/RELEASE_NOTES.md).
