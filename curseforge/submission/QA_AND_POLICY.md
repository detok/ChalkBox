# ChalkBox — pre-submission checks

This checklist is for a publisher preparing the addon for the CurseForge author portal.

## Product and wording

- [ ] The title and summary clearly describe ChalkBox's **real, shipped modules**.
- [ ] The description mentions the WoW Forever target client without claiming an official Blizzard relationship.
- [ ] The feature list matches the code. No MapSense continuous map engine, AI combat bot, official drop tables or guaranteed vendor estimates are advertised.
- [ ] The current file changelog matches version **2.0.2** and real changes.
- [ ] **Detok Whitemaine** appears only as the creator credit, not as fake endorsements or testimonials.

## Installable file

- [ ] Upload **ChalkBox-2.0.2.zip**, not the separate CurseForge media kit or the GitHub source archive.
- [ ] The ZIP has exactly one top-level **ChalkBox** folder and both Forever TOC manifests.
- [ ] Lua tests and packaging tests passed. The addon loads and saved settings persist after a real client test.
- [ ] Original bundled licenses are intact (including the separate LibProfessionDB MIT notice).
- [ ] The optional compact meter starts closed; nested settings pages remain reachable.

## Visual material

- [ ] The project avatar is the original **Project-Icon-512.png**, a 512px square PNG.
- [ ] The hero and feature overview artwork are labeled as illustrations.
- [ ] Actual gameplay images come from the running WoW Forever client.
- [ ] Screenshots do not expose private whispers, account details or personal information.
- [ ] Graphic dimensions and supported file types are checked against the live submission page.

## Platform compatibility

- [ ] Confirm that CurseForge offers a **supported game version/flavor** compatible with the actual Forever client before uploading. Don't select Retail or Classic Era merely to get past the form.
- [ ] Keep the MIT license, source repository and issue tracker links accurate.
- [ ] Follow the current [CurseForge submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips) and [moderation policy](https://support.curseforge.com/support/solutions/articles/9000197279-moderation-policies).
- [ ] Treat the project as **unpublished** until the author portal has approved it.

## After approval

- [ ] Verify the CurseForge download and listed client version.
- [ ] Add the genuine listing URL to GitHub.
- [ ] Replace any temporary test-release wording once client acceptance testing is complete.
