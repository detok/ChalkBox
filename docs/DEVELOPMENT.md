# Developing ChalkBox

**Current code baseline: 2.2.12 · Lua 5.1 · WoW Forever**

ChalkBox is a single self-contained addon. Most changes should be small, local and reversible. Mocked WoW APIs exercise code paths but do not establish complete real-client compatibility.

## Prerequisites

- Git and a GitHub account that can submit a pull request
- **Lua 5.1** and its matching `luac5.1` syntax checker
- **Python 3** for package builds and validation
- **`librsvg2-bin`** / `rsvg-convert` for branded TGA and media-kit PNGs

CI is defined in [`.github/workflows/release.yml`](../.github/workflows/release.yml). Do not assume a newer Lua runtime proves Lua 5.1 compatibility.

## Source tree and load order

```text
ChalkBox/                 Game-installable addon: Lua files, two TOCs, libs
tests/                    Mocked Lua 5.1 regression tests
scripts/                  Icon renderer and deterministic ZIP builders/tests
docs/                     Player guides, architecture, maintainer runbooks
curseforge/               Listing copy, art, screenshots, upload checklists
.github/workflows/        Pull request tests and main-branch publication
README.md                 Project landing page
CHANGELOG.md              Historical release history
CONTRIBUTING.md           Contribution expectations
```

`ChalkBox/ChalkBox.toc` and `ChalkBox/ChalkBox_Camelot.toc` must have **the same Lua load order and version**. Their interface IDs deliberately differ. `scripts/package.py` `FILES` must mirror that order exactly. Read [Architecture](ARCHITECTURE.md) for module ownership and persistence.

## Run all checks locally

From the repo root:

```bash
find ChalkBox tests -name '*.lua' -print0 | xargs -0 luac5.1 -p
for test in tests/test_*.lua; do
  echo "Running $test"
  (cd ChalkBox && lua5.1 "../$test")
done
python3 scripts/test_packages.py
python3 scripts/test_curseforge_kit.py
```

The addon package test builds exactly one deterministic `dist/ChalkBox-X.Y.Z.zip`, with one `ChalkBox/` root, licenses, icons, all required modules and bundled recipes, and no tests or screenshots. The **separate** media-kit test renders the PNG artwork and packages listing text and real screenshot JPGs; it is *not* an addon.

During development run the focused test first, for example:

```bash
(cd ChalkBox && lua5.1 ../tests/test_quest_sense.lua)
```

Then run **all tests** and package validation before merge.

## Change and review workflow

1. Read current `main` and the owning module before editing. Prefer a focused feature branch.
2. Identify evidence source, API restrictions, saved state and fallback behavior. Never guess player data when the API does not provide it.
3. Add Lua regression tests for success **and** realistic edge cases: nil/secret APIs, combat or UI deferral, multiple quests/items, unavailability, stale data, saved choices and restoring original behavior.
4. Keep changes local. UI changes must not silently alter a gameplay data path or interfere with Blizzard-owned controls.
5. Update [User handbook](USER_GUIDE.md), [Commands](COMMANDS.md) and relevant architecture/design docs for observable behavior. Include [release notes](RELEASE_NOTES.md) and [changelog](../CHANGELOG.md) for a versioned release.
6. Open a PR with a clear scope, test evidence, affected SavedVariables and **in-client checks still required**.
7. Merge only after CI passes. Release according to [Release process](RELEASE_PROCESS.md).

## Guardrails for WoW Forever

- Preserve Blizzard's native UI. No automated sales, purchases, bids, inventory mutations, disenchanting, combat rotations, protected-frame modification or unsanctioned chat.
- Handle missing and secret client values conservatively. Item/quest evidence must outrank uncertain profession hints.
- QuestSense cannot claim a current dungeon quest without a verified match. Preserve and restore manual quest watches, and defer edits when not safe.
- DropSense records *observed* loot, not all kills or server drop tables; outdoor location records are the player's position when opening loot.
- AH values are observed *asks*, not sales; DE expected values are estimates and Classic-reference odds, not guaranteed outcomes.
- MacroForge must use learned spells and explicit safe user actions. Never promise a proc-driven one-button rotation.
- The Bar must not reposition UIParent or secure action frames; bag adjustments defer near bank setup and combat.
- QuietGuard blocking defaults OFF and saved ON choices must be honored. Emota automatic actions remain optional.
- Preserve third-party license notices and pinned bundled recipe data.

## Docs-only PRs

A docs-only change should **not bump both TOC versions or alter gameplay files**. Verify navigation, descriptions and command examples against source. The media-kit build includes documentation-derived listing copy; an existing GitHub release tag is preserved and, on the main-branch workflow, the same tag's **media kit** may be refreshed without rewriting the playable addon asset.

## Checklist for a maintainable PR

- The issue / expected behavior can be reproduced or explained.
- No unrequested gameplay or SavedVariables migrations.
- Added / updated relevant mocked tests, plus full suite green.
- Failure behavior documented; no guessed or unsafe data.
- Manual client steps listed separately from automated verification.
- Player docs, release docs and publishing copy all agree.
- MIT/vendor license files remain intact.

[Architecture](ARCHITECTURE.md) · [Maintainer runbook](MAINTAINER_RUNBOOK.md) · [Release process](RELEASE_PROCESS.md) · [Contributing](../CONTRIBUTING.md)
