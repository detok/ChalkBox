# Release and publishing runbook

**Development candidate: 2.2.22; verify released ZIPs at GitHub Releases before claiming publication.**

There are two different downloadable ZIPs. The playable addon ZIP and the CurseForge publishing/media ZIP are not interchangeable.

## Version and code review

For a **new playable release**:

1. Start a focused feature branch from the actual `main` head.
2. Update runtime changes and add mocked Lua tests, including failure paths and SavedVariables compatibility.
3. Bump the `## Version:` field in **both** `ChalkBox/ChalkBox.toc` and `ChalkBox/ChalkBox_Camelot.toc`. Keep their intentionally different Interface numbers and Lua module order.
4. Update [CHANGELOG](../CHANGELOG.md), `docs/RELEASE_NOTES.md`, affected user/developer docs and the **current CurseForge file-changelog copy**.
5. Run [Development checks](DEVELOPMENT.md), open a PR, and merge only if the Lua and package CI checks pass.

For a **docs-only update**, keep both TOC versions untouched. A commit to `main` may refresh the existing version's media ZIP but must not be presented as a new game update.

## Exact assets and their purposes

| Artifact | Where it comes from | What to do with it |
| --- | --- | --- |
| `ChalkBox-X.Y.Z.zip` | `scripts/package.py` / GitHub release | **Install** the single contained `ChalkBox/` folder in the game; upload as the addon file only if the portal supports the real Forever client flavor |
| `ChalkBox-CurseForge-Media-X.Y.Z.zip` | `scripts/build_curseforge_kit.py` | **Publisher assets only:** 6 source SVGs, 9 rendered PNGs, 10 real in-game JPGs, listing copy and checklists |
| `docs/RELEASE_NOTES.md` | Current PR author | Actual current version's release notes; also supplied to GitHub release |
| `curseforge/copy/FILE_CHANGELOG_CURRENT.md` | Current publisher | The current concise CurseForge per-file changelog, checked against the TOC version |
| Earlier `curseforge/copy/FILE_CHANGELOG_X.Y.Z.md` | Historical source files | Archive only, not the default current upload |
| `curseforge/screenshots/*.jpg` | Real recorded game screenshots | Gallery items; some may show older interface revisions and must be reviewed before claiming current appearance |

Never upload the media ZIP as the playable addon, or claim that GitHub's generated source archive is the packaged addon.

## Automated pipeline

`.github/workflows/release.yml` runs on pull requests, pushes to `main` and manual dispatch. Its single job:

1. Installs Lua 5.1 plus SVG conversion tooling.
2. Runs `luac5.1 -p` on Lua sources and the entire `tests/test_*.lua` suite.
3. Builds/verifies the deterministic, single-root addon ZIP via `scripts/test_packages.py`.
4. Renders/verifies the media ZIP via `scripts/test_curseforge_kit.py`.
5. Uploads both ZIPs as workflow artifacts.
6. **Only on `main` push:** checks `vX.Y.Z`. If a new tag, creates a **GitHub prerelease** with both ZIPs and `docs/RELEASE_NOTES.md`. If the tag already exists, preserves the game release asset and refreshes **only the media ZIP**.

A successful PR workflow is not proof a release is published: verify the **main push workflow** and the actual [GitHub Releases](https://github.com/detok/ChalkBox/releases) listing before giving users a download link.

## Local publisher commands

```bash
find ChalkBox tests -name '*.lua' -print0 | xargs -0 luac5.1 -p
for test in tests/test_*.lua; do (cd ChalkBox && lua5.1 "../$test"); done
python3 scripts/test_packages.py
python3 scripts/test_curseforge_kit.py
```

The SVG exporter requires `rsvg-convert` from `librsvg2-bin`. `scripts/package.py` also renders the in-game TGA icon. Test scripts enforce exact manifest content, vendor library licenses, asset presence, archive structure and deterministic output.

## CurseForge publication

Use [`curseforge/README.md`](../curseforge/README.md), [current project fields](../curseforge/copy/PROJECT_FIELDS.md), [description](../curseforge/copy/PROJECT_DESCRIPTION.md), and [publisher checklist](../curseforge/submission/PUBLISH_CHECKLIST.md).

Before publication:

- Verify that CurseForge offers a **client flavor/version truly compatible with WoW Forever**. Do not select Retail or standard Classic simply to bypass submission validation.
- Ensure actual screenshot uploads are real game captures, not SVG editorial concept art. Review whether their UI still matches the current release.
- Choose matching portal categories, retain MIT and bundled third-party license attribution, and check the release type based on real-client acceptance.
- Upload the **addon ZIP** to the addon files area. Use separate media kit art/listing assets in their correct portal fields.
- Do not claim a public CurseForge listing exists, or link one, until its real URL and moderation status are verified.

## Post-release checks

1. Verify that the release tag, both asset names and approximate file sizes appear.
2. Download and inspect the playable ZIP root `ChalkBox/` and the two matching TOC versions.
3. Confirm no old standalone addon folders, test sources or screenshot files slipped inside the addon ZIP.
4. Run the [maintainer in-game smoke checklist](MAINTAINER_RUNBOOK.md) for touched modules.
5. Update GitHub landing links and the in-repo docs only when they are actually stale; do not rewrite historical release tags.
6. If a live client bug is found, open an issue and fix it in a new reviewed release.

[Documentation home](README.md) · [Developer guide](DEVELOPMENT.md) · [CurseForge kit](../curseforge/README.md)
