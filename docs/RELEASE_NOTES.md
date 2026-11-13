# ChalkBox 1.5.1 — Public standalone launch 🎉

**ChalkBox now has its own public GitHub project.** This release packages exactly **one** addon: `ChalkBox-1.5.1.zip`.

## What's included

- **LootSense** — warns about quest items, personal keep-list items, learned-recipe materials and verified Forever camping reagents. It does not sell or delete anything.
- **CampSense** — checks actual Camp Benefits when the client permits aura reads, and shows a visible, fading center-screen reminder when a camping benefit appears missing or nearly expired.
- **TrailBar** — 18px screen-reserved XP/hour, level ETA and gold tracker.
- **Emota** — intermittent character personality with race/class and resting-area context.
- **QuietGuard** — configurable nuisance invites and duel suppression.
- **QuestSense** — optional native zone-quest watch helpers.

## What's different about the public repository

- One clean addon folder, **no** Don’t Sell That or EmotaSpeak ZIPs.
- Reproducible packaging, GitHub Actions Lua 5.1 tests, public issue templates, MIT license, contribution and troubleshooting guides.
- The addon artwork and saved settings are carried forward; updating from 1.5.0 is an ordinary folder replacement.
- The optional LibProfessionDB adapter **does not redistribute** its external database and cannot verify that every recipe is known without an actual profession scan.

## Install

1. Download **ChalkBox-1.5.1.zip** below. Do not download GitHub's automatic *Source code* ZIP.
2. Unzip to `World of Warcraft/_classic_era_/Interface/AddOns/` or your Forever install's equivalent folder. Result: `Interface/AddOns/ChalkBox/ChalkBox.toc`.
3. Enable ChalkBox and use `/reload`.
4. Type `/chalk` to open settings, or `/chalk prep test` to check that on-screen reminders work.

**Public prerelease:** Automated Lua 5.1 tests and ZIP validation run on every PR and release. Forever-specific native APIs and the optional third-party recipe adapter still rely on community in-game feedback. Please [report a bug](https://github.com/detok/ChalkBox/issues/new/choose) if something behaves differently in your client.

Source code and documentation: [github.com/detok/ChalkBox](https://github.com/detok/ChalkBox).
