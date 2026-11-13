# CurseForge publication checklist — ChalkBox

**This is an author workflow, not proof of a completed CurseForge project.** GitHub is the **primary direct download, source and issue-tracking home**. CurseForge is an **additional discovery/distribution channel**.

## 1. Author-account preparation

- [ ] Sign in to the CurseForge author portal and verify your account/email
- [ ] Confirm that a project named **ChalkBox** is available and that you can submit it as its owner
- [ ] Review the [current project submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips) and [moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies)
- [ ] Select World of Warcraft → Addons → **Forever**, and the appropriate client version (initial plan: 1.60.1; recheck at submission)

## 2. Form setup

- [ ] Set **ChalkBox** as project title and fill the summary from [PROJECT_FIELDS.md](../copy/PROJECT_FIELDS.md)
- [ ] Select only current, relevant categories; don't advertise as a Retail/Classic release
- [ ] Choose MIT license and add the GitHub **source** and **issue tracker** links
- [ ] Paste [PROJECT_DESCRIPTION.md](../copy/PROJECT_DESCRIPTION.md) into the description editor; check Markdown preview on desktop/mobile
- [ ] Add genuine copyright/license notices and library attribution
- [ ] Leave project website/social/Discord/donation fields blank unless you own those verified URLs
- [ ] Provide required portal icon from art pass when available; don't submit a broken placeholder
- [ ] Keep **third-party download URLs OUT of the CurseForge description**. The project Files tab should host its own downloadable file

## 3. Verify code and build before uploading

- [ ] Choose a tested ChalkBox version and refresh all versioned marketing copy
- [ ] Verify both `.toc` versions and Forever-specific `ChalkBox_Camelot.toc`
- [ ] Confirm GitHub Actions passed **Lua tests and installable ZIP**
- [ ] Download the exact file from **https://github.com/detok/ChalkBox/releases** and verify filename, archive root and file contents
- [ ] Ensure the ZIP has exactly one top-level `ChalkBox/` directory (no nested folder, GitHub repo metadata or `curseforge/`)
- [ ] Confirm bundled `LibProfessionDB` MIT license and `ChalkBox/LICENSE` are inside the ZIP
- [ ] Assign this file to **Forever / 1.60.1** (or the then-current Forever version) and choose **Beta** until native menu/offset game-client testing is complete
- [ ] Enter version-appropriate release notes from [FILE_CHANGELOG_1.8.5.md](../copy/FILE_CHANGELOG_1.8.5.md)

## 4. Artwork and honesty gate

- [ ] Create files identified in [ARTWORK_TO_CREATE.md](../ARTWORK_TO_CREATE.md)
- [ ] Confirm accepted image dimensions and file-size limits in the **live portal**
- [ ] Check logo legibility at thumbnail size
- [ ] Supply **real in-game screenshots** for UI features in [SCREENSHOT_PLAN.md](../artwork/SCREENSHOT_PLAN.md)
- [ ] Do not publish screenshots that misrepresent or invent an unverified function
- [ ] Use a functional title, summary and instructions even if the portal gallery isn't ready

## 5. QA and submit

- [ ] Run [QA_AND_POLICY.md](QA_AND_POLICY.md) checks
- [ ] Review the final description for empty/broken images and links
- [ ] Verify the client installs and loads the uploaded ZIP successfully
- [ ] Submit the project for moderation
- [ ] Record the actual project URL/project ID when supplied
- [ ] Only after approval, add a small **optional CurseForge link** to GitHub's README
- [ ] Leave **Download from GitHub Releases** as the main prominent action on GitHub

## 6. After first approval

- [ ] Monitor comments/issues and resolve genuine problems
- [ ] Keep GitHub and CurseForge versions/changelogs synchronized as far as practical
- [ ] Don't announce that a file was accepted until the portal marks it approved
- [ ] Avoid making new GitHub source-only commits trigger fake version bumps: the release workflow already preserves existing version tags
- [ ] Ensure users always have a working **GitHub Releases** download path, regardless of CurseForge listing state

## Official help center references

- https://support.curseforge.com/support/solutions/articles/9000197241
- https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips
- https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies
- https://support.curseforge.com/support/solutions/articles/9000209856
