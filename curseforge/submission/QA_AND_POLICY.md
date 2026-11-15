# ChalkBox pre-submission quality and policy checks

**Current release: 2.2.10 · developed for WoW Forever**

This checklist is a publisher's guardrail. It does not authorize selecting a falsely compatible game flavor or claiming an unapproved CurseForge listing.

## Product claims

- [ ] Describe only shipped modules, based on [Feature proof](../copy/FEATURE_PROOF.md) and [User handbook](../../docs/USER_GUIDE.md).
- [ ] QuestSense is a **watch-list manager**, not an XP routing bot; dungeon Smart matching is conservative and requires verified instance evidence.
- [ ] DropSense personal loot-window rates are not official server odds; recorded outdoor locations are **player positions at loot open**, not guaranteed creature spawn points.
- [ ] AuctionSense reports manual **asks**, AuctionInsights captures only observed supported seller mail, and DE probabilities may rely on Classic-reference data. Never claim actual sale profit or guaranteed results.
- [ ] MacroForge compiles from learned spells but never performs a one-key rotation or a protected combat action without the player.
- [ ] QuietGuard defaults off for fresh installations; Emota automation is optional.
- [ ] The file changelog and project copy describe version **2.2.10**, not old 2.1.1 features alone.

## Package

- [ ] Upload `ChalkBox-2.2.10.zip` as the game addon only if the Forever client flavor is genuinely supported on the portal.
- [ ] Confirm exactly one root `ChalkBox/` with both TOCs and original license files; no screenshots/media-kit files in the game ZIP.
- [ ] The separate `ChalkBox-CurseForge-Media-2.2.10.zip` contains publishing assets; it is **not** a game file.
- [ ] CI Lua 5.1 regression, package validation, current changelog version and media ZIP checks passed.
- [ ] Changes were smoke-tested inside the real supported game build, with unresolved client risks disclosed.

## Screenshots, artwork and rights

- [ ] The 512px project avatar is an original brand graphic from `Artwork/PNG/Upload-Ready/`.
- [ ] All screenshots are actual captured WoW Forever gameplay. Some archived captures are from an older release; they should not be described as the current UI without checking.
- [ ] Distinguish `Editorial-Only` SVG/PNG illustrations from client screenshots.
- [ ] Crop or redact private chat, account names and other personal content.
- [ ] The original source MIT and each bundled vendor library's license remain intact.

## Portal and approval

- [ ] Check the current [CurseForge project submission guidance](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips) and [moderation rules](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies).
- [ ] Select a compatible game client version; don't use regular Retail/Classic categories as a workaround.
- [ ] Use **Detok Whitemaine** as the project author. No claim of Blizzard affiliation.
- [ ] Share the CurseForge project URL only after verifying it actually exists and is approved.

[Full publisher checklist](PUBLISH_CHECKLIST.md) · [Release process](../../docs/RELEASE_PROCESS.md)
