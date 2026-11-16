# Contributing to ChalkBox

Thanks for helping improve a practical addon for **World of Warcraft: Forever**. You do not need to be an expert addon author. Verified client observations, useful screenshots and precise bug reports are valuable contributions.

Start with the [documentation home](docs/README.md), [architecture](docs/ARCHITECTURE.md), [developer guide](docs/DEVELOPMENT.md) and [maintainer runbook](docs/MAINTAINER_RUNBOOK.md).

## For players: reporting a problem

Start with the [support hub](SUPPORT.md) or use the [GitHub issue forms](https://github.com/detok/ChalkBox/issues/new/choose). Pick **Bug**, **Compatibility**, or **Help**; include the installed version from `/chalk update`, Forever client build if available, and steps to reproduce. For AuctionSense issues, paste `/chalk auction status` and say whether you used **Scan Market** or **Full listings**. You do not need to know Lua to make a helpful report.

Please search existing issues first, avoid posting identifying screenshots or private chat, and keep unrelated reports separate. Preserve your SavedVariables when troubleshooting. If an issue turns out to be a question instead of a defect, that's fine—good reports improve the project.

## Before changing code

1. Read the latest `main` and check [existing issues](https://github.com/detok/ChalkBox/issues). For a new module or major design change, open a feature request describing why it belongs in ChalkBox.
2. Create a **focused branch**, not a sweeping refactor. Identify the owning module, public UI, SavedVariables path and existing regression tests.
3. Explain what is directly observed in WoW Forever versus inferred or unknown. In particular, quest-map matches, drops, auction asks and recipe-catalog matches have different evidence strengths.
4. Include the exact Forever client/build when you report an API issue, client screenshot discrepancy or protected action warning.

## Pull request standard

Describe:

- **Problem and scope:** what player action breaks, what changes and what must remain unchanged.
- **Before/after:** a reproducible sequence, mock test or cropped in-client screenshot.
- **Affected source and state:** modules, saved preferences, new fields/migrations or compatibility hazards.
- **Testing:** specific Lua 5.1 mock regressions, full syntax/package checks and any in-game verification still pending.
- **Safety and constraints:** combat, quest/map, bank, auction cooldown, secret/protected APIs, default-off social behavior.
- **Documentation:** update the [user handbook](docs/USER_GUIDE.md), [commands](docs/COMMANDS.md), [troubleshooting](docs/TROUBLESHOOTING.md) or [release notes](docs/RELEASE_NOTES.md) as appropriate.

Use the repository's [PR template](.github/PULL_REQUEST_TEMPLATE.md). For bugs, compatibility problems, setup questions, and suggestions use the [issue forms](https://github.com/detok/ChalkBox/issues/new/choose).

## Run the full checks

```bash
find ChalkBox tests -name '*.lua' -print0 | xargs -0 luac5.1 -p
for test in tests/test_*.lua; do (cd ChalkBox && lua5.1 "../$test"); done
python3 scripts/test_packages.py
python3 scripts/test_curseforge_kit.py
```

Install `lua5.1`, Python 3 and `rsvg-convert` as explained in [Development](docs/DEVELOPMENT.md). **All tests must pass before merging.** Automated mocks never replace live-client QA for native UI and secret values.

## Safety and accuracy

- No automatic combat rotations, secure-frame manipulation, bidding/buying/selling, destructive inventory changes or unsolicited chat messages.
- No fabricated quest routes, dungeon quest mapping, drop odds, corpse positions, learned recipes, actual sale prices or disenchant guarantees.
- No large unlicensed data or copying another addon's protected code. Bundled libraries require their original redistribution license and notices.
- Do not clear previous player preferences or loot data on update. Bounded, optional new fields and explicit version-aware migrations are preferred.
- Guard native APIs and unreadable/secret values. The UI should display **unknown**, defer or preserve the current state when the game does not provide trustworthy data.
- Respect default-off QuietGuard filters and opt-in Emota behavior. Keep WoW's native AddOns settings transparent and protected interface behavior safe.

## Documentation and screenshots

Player help belongs under [`docs/`](docs/README.md), not a long chronological story in the main README. Existing screenshots are genuine game captures but can be from earlier releases; do not present a historical image as proof a current UI feature has been verified.

GitHub has an optional Wiki, but the **versioned repo docs are authoritative**. If you edit documentation without gameplay changes, do not bump the addon version solely for prose.

## License and credits

New original code is contributed under the project's [MIT license](LICENSE). Only submit code, text and art you may lawfully license. Bundled vendor libraries retain their separate license files, detailed in [Recipe data](docs/RECIPE_DATA.md). The addon is not endorsed by Blizzard.

[Documentation home](docs/README.md) · [Release procedure](docs/RELEASE_PROCESS.md)
