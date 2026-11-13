# Development

ChalkBox is a self-contained WoW Lua 5.1 addon with no network/backend services. We test with Lua 5.1 mocks and verify a deterministic ZIP.

## Source tree

```text
ChalkBox/                 runtime folder; copied into Interface/AddOns
  ChalkBox.toc            Classic-era interface
  ChalkBox_Camelot.toc    Forever/Camelot interface
  Core.lua                quest/vendor awareness
  ProfessionSense.lua     learned recipes and quantities from the client
  RecipeAdvisor.lua       evidence-based adapter over bundled Forever recipe data
  Libs/LibStub/            public-domain LibStub loader
  Libs/LibProfessionDB-1.0/ MIT LibProfessionDB + original license + Forever data
  CampAura.lua            Camp Benefits aura detection
  CampSense.lua           preparation reminders and material guidance
  ReminderToast.lua       compact onscreen notice
  LootSense.lua           item tooltip classification and slash commands
  QuestSense.lua          native quest tracking
  TrailBar.lua            XP/hour and reserved screen layout
  QuietGuard.lua          native nuisance-invite filters
  PersonalityContext.lua  class/race/resting-area emote weights
  Emota.lua               native idle emotes and event reactions
  ChalkBox_Settings.lua   native Options pages
  assets/Icon.tga
tests/                    Lua 5.1 module regression suite
scripts/package.py        builds one installable ZIP
scripts/test_packages.py  validates exact ZIP contents
.github/workflows/         CI on PRs, prereleases on new main versions
```

## Local validation

Install `lua5.1` and Python 3, then:

```bash
find ChalkBox tests -name '*.lua' -print0 | xargs -0 luac5.1 -p
for test in tests/test_*.lua; do (cd ChalkBox && lua5.1 "../$test"); done
python3 scripts/test_packages.py
```

This creates exactly one `dist/ChalkBox-X.Y.Z.zip`. The ZIP root is `ChalkBox/`; it includes no test files, Python files or legacy standalone addons. It **does include** the properly MIT-licensed Forever-only database and license notice.

## Change and release policy

1. Branch from `main`, keep changes focused, and run every test.
2. For runtime changes, update/add a mock regression test and explain manual in-game checks in the PR.
3. Bump `## Version:` in **both** TOCs (keep the Classic/Forever interface IDs unchanged).
4. Update `CHANGELOG.md`, `docs/RELEASE_NOTES.md` and user docs when behavior changes.
5. Submit a PR. After CI passes and it's merged to `main`, the release workflow publishes **one prerelease asset** on a *new* `vX.Y.Z` tag. It never rewrites a previously published release tag.

## WoW API guardrails

- No automated trades, sells, inventory moves, protected actions or unsanctioned chat.
- Use safe API/feature detection and guard against secret values.
- Quest and explicitly protected items always outrank general profession speculation.
- Treat unavailable data as **unknown** rather than falsely concluding safety.
- No arbitrary runtime internet requests or scraping. Third-party data must have a verified redistribution license, intact notices and a pinned upstream source.
- Keep native Settings UI and the 18px TrailBar behavior intact unless intentionally changing them.
- Make social and automatic emotes opt-in or clearly controllable.

See [Contributing](../CONTRIBUTING.md) and [Recipe data](RECIPE_DATA.md).
