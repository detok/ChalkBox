# Contributing to ChalkBox

Thanks for helping make the addon more useful to everyday WoW Forever players.

**Great contributions:** precise bug reports, screenshots showing incorrect tooltip advice, checked client API compatibility, new automated Lua tests, clear documentation, and small code changes that make items or buffs easier to understand.

## Before writing code

1. Check [existing issues](https://github.com/detok/ChalkBox/issues). For a larger new module, open a feature request first.
2. Fork the repository and create a focused branch.
3. Avoid changing many modules at once. Preserve working TrailBar, CampSense, QuestSense and Emota behaviors unless your PR explicitly changes them.
4. Run the tests in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
5. Submit a PR describing the problem, solution, client build tested, and any known limitations.

## Item and recipe facts

Item hints must have trustworthy provenance (in-game evidence, verified item/recipe ID or appropriate licensed database). Do not copy large third-party websites into ChalkBox. Distinguish **learned by this character** from **can potentially be crafted**. Never convert **unknown** into an unconditional **safe to sell** recommendation.

## Code and safety

- Use Lua 5.1 compatible syntax.
- Guard optional WoW APIs and inaccessible/secret values.
- Keep addon SavedVariables backwards-compatible.
- No automated protected gameplay actions, unsolicited chat spam or invasive data collection.
- Don't bundle third-party code/assets without verifying its license and including notices.

All contributed code is submitted under the project's [MIT license](LICENSE). By submitting a contribution, you confirm you have the right to provide it under that license.

You don't need to be a professional addon developer. Concrete in-game examples and reproducible bug reports are extremely valuable.
