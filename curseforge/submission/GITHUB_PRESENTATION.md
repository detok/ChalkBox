# GitHub repository presentation — ChalkBox

The front-page `README.md` has been redesigned to be the **primary public product landing page** and **direct GitHub Releases download hub**. The CurseForge listing is an optional additional place to discover ChalkBox.

## Front-page structure

1. Product name, tagline and badges (build, license, version, Forever)
2. **Direct GitHub download** prominently at the top — versioned current ZIP
3. Feature grid and honest scope (no invented gameplay)
4. Product deep dives: native-styled LootSense/known recipe highlights, configurable TrailBar editor, native/compact combat meters, QuestSense, Emota racial behavior and camping
5. Screenshots area — deliberately text-only **until genuine assets exist**
6. Direct install steps; explicit `_forever_/Interface/AddOns/ChalkBox/`
7. Commands and expandable FAQ
8. Issues/support, developers, MIT/third-party credit

## GitHub About panel settings (owner actions)

These aren't changed by the readme; edit from the repository home page **About → gear icon** as repository owner.

- **Description:** `A quieter WoW Forever companion: LootSense, TrailBar, QuestSense, camping reminders, native DPS tools & UI helpers.`
- **Website:** `https://github.com/detok/ChalkBox/releases` (until a distinct site exists)
- **Suggested topics:** `world-of-warcraft`, `wow-forever`, `wow-addon`, `lua`, `quest-tracker`, `professions`, `quality-of-life`, `ui`
- Check **Releases** and **Issues** as active sidebar features.
- Add no CurseForge URL until the project actually exists and is approved.
- Later, when approved, place the CurseForge link *after* GitHub Releases in the readme as an alternate installer.

## Recommended GitHub safety rules

**Current status when first planned:** `main` was unprotected. Repo settings must be applied by an owner or GitHub integration with administrative ruleset permissions; the current connected actions only allow repository file editing and PRs, **not** ruleset modification.

Go to **Settings → Rules → Rulesets → New branch ruleset**, target **main**, set:
- Block deletions
- Block force pushes / non-fast-forward changes
- Require pull request before merging (approvals 0 while solo-maintained)
- Require status checks; choose the observed CI job **`Lua tests and installable ZIP`** once available in GitHub's status-check picker
- Require conversation resolution (optional, recommended)
- Avoid making owner/admin bypass completely unrestricted if you want this protection to be meaningful

**Important:** A ruleset can prevent a PR from merging if a required check's name or workflow is wrong. Verify one green pull-request test under new rules before tightening more. A solo-maintainer workflow can use zero required peer approvals.

The automated main workflow still **publishes versioned GitHub Releases**, preserving a tag if it already exists. Protecting `main` does not mean users have to download from CurseForge.

## Future artwork integration (next pass)

Place genuine files in `curseforge/artwork/` following `../ARTWORK_TO_CREATE.md`.

- Put the finished **hero** under the top intro/badges in the README, using a relative image link.
- Add screenshot triptych/carousel alternatives under **See it in action**, starting with **LootSense**, **TrailBar**, **Blizzard meter PRINT**.
- Keep alt text descriptive and mobile layout legible.
- Do not remove direct GitHub download links when adding images.
- Do not link to `sandbox:/` images or invented image paths; only commit and reference real files.

## Release-document rules

The primary direct download currently points to **ChalkBox 1.9.0**. When a newer version is published, update the versioned top README link. The **[Releases index](https://github.com/detok/ChalkBox/releases)** is always available. Do **not** rely on GitHub's `/releases/latest` route for a repository whose releases are all marked **prerelease**; that route can skip prereleases.
