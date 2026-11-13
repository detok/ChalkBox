# ChalkBox 2.0 — GitHub landing page and owner setup

**Front-page README updated for a 2.0 developer-test release.** It is designed to make the addon understandable at a glance: brand → direct download → feature overview → practical details → real limits → install → support. GitHub Releases remains the primary install path.

## Live README structure

1. Original [ChalkBox header artwork](../artwork/chalkbox-github-header-1600x470.svg), 2.0 prerelease/test badge, Lua CI badge, MIT and Forever badges.
2. **Prominent versioned download** linking directly to the installable \`ChalkBox-2.0.0.zip\` asset.
3. One-addon positioning and **honest pre-release / map visibility** notice.
4. Current module catalog: Map Discoveries, DropSense, MacroForge, LootSense, professions, The Bar, repair learning, Session Journal, combat, quests, camp, theme, QuietGuard, Emota and bags.
5. Feature stories explained in plain language. No official drop-rate claims, no macro rotation automation, no claimed live-client screenshots.
6. Original feature-grid SVG clearly marked as **editorial artwork**.
7. Installation, first-five-minutes checklist, command table, compatibility, credits, and issue links.

## Owner-only metadata — still to be done in GitHub UI

These settings **cannot be changed by editing README.md**, and the connected GitHub editor doesn't expose a repository-metadata mutation. On https://github.com/detok/ChalkBox use **About → gear icon**:

- **Description:** \`The quiet WoW Forever companion: MacroForge, Map Discoveries, LootSense, The Bar, quest, combat, camp and session tools.\`
- **Website:** \`https://github.com/detok/ChalkBox/releases\`
- **Topics:** \`world-of-warcraft\`, \`wow-forever\`, \`wow-addon\`, \`macro-builder\`, \`lua\`, \`map\`, \`quality-of-life\`, \`quest-tracker\`
- Enable **Releases** and **Issues** in sidebar navigation.

Then go to **Settings → General → Social preview** and upload a PNG of the existing original [1200×630 banner](../artwork/chalkbox-banner-1200x630.svg) or branded social preview. GitHub does not automatically use the README hero as a social card. Do not upload any proprietary fonts.

## Green CI and branch protection

The workflow \`Lua tests and installable ZIP\` is the minimum merge gate. For optional branch protection, use **Settings → Rules → Rulesets** and require PRs + this observed check while avoiding accidental admin-only deadlocks in a solo project. The current integration cannot change repository rulesets.

## Media policy

The branding assets are real, original and committed. **Gameplay screenshots are still pending**. Capture them in the actual Forever client before adding a gallery. Use the [screenshot plan](../artwork/SCREENSHOT_PLAN.md). Never portray an illustration or mock map as a tested screen.

## Pre-2.0 public testing message

> ChalkBox 2.0.0 is ready to test on WoW Forever. The new build revises Map Discoveries loading and placement, brings MacroForge and automatic loot history together with The Bar and Session Journal, and keeps the whole install in one addon. Try it in the actual client; report map button visibility and macro spellbook behavior so the full public launch is grounded in real gameplay.

## Distribution rules

- GitHub **Releases asset** is the download; don't link to a source-code archive as an installation file.
- GitHub automatically marks these workflow releases **prerelease**. Keep that accurate until client validation is complete.
- CurseForge is optional future distribution; **no approved project URL exists yet**.
- Publishing documentation does not mean uploading to CurseForge.
