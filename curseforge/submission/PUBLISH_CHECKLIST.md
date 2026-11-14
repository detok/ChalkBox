# ChalkBox — publication checklist (2.0.11)

## Build and verify

- [ ] GitHub Actions passes Lua syntax, module tests, addon packaging and the media-kit artwork checks.
- [ ] Both TOCs declare version 2.0.11 and the addon ZIP contains one ChalkBox folder.
- [ ] Open WoW Forever after upgrading: the settings hierarchy expands as intended.
- [ ] Confirm the optional compact meter is hidden at login; show it manually.
- [ ] Verify opening the bank on a fresh character doesn't cause an addon-block warning; regular bag highlighting and offsets still work afterward.
- [ ] Confirm Discoveries map button, dragging, source filters and search.
- [ ] Verify the Area / Dungeon field opens a **direct, scrollable zone list** without nested menus, including when native menu APIs are unavailable.
- [ ] Test lists of at least 10 zones, map sync on/off, saved manual selection, and a creature-specific drop ratio such as 1/2=50%.
- [ ] Check MacroForge spellbook scan, generated text, explicit macro creation and saved recipes.
- [ ] Confirm the concise Bar hover tooltips, stat/background menus, color coding, movement, alignment and saved settings.
- [ ] Confirm The Bar, QuestSense, CampSense, LootSense and Session Journal still work.
- [ ] Verify Nearby-only auto-refresh, preserving/restoring manually selected remote quests, and no edits when the world map is open.

## CurseForge author setup

- [ ] Confirm the World of Warcraft **game flavor/version** offered by CurseForge is suitable for your tested Forever client. Don't mislabel Retail or Classic Era.
- [ ] Set the project name **ChalkBox** and creator credit **Detok Whitemaine**.
- [ ] Use the current [project fields](../copy/PROJECT_FIELDS.md), [description](../copy/PROJECT_DESCRIPTION.md) and [short summary](../copy/SHORT_COPY.md).
- [ ] Upload **Project-Icon-512.png** from the separate media kit as the avatar (512px square).
- [ ] Choose categories offered by the portal that match the addon.
- [ ] Use **ChalkBox-2.0.11.zip** as the **game file**. Never upload the media kit ZIP as the playable addon.
- [ ] Paste [FILE_CHANGELOG_2.0.11.md](../copy/FILE_CHANGELOG_2.0.11.md) for the file changelog.
- [x] Select and crop authentic in-game screenshots; the [real screenshot gallery](../screenshots/README.md) is bundled separately from editorial art.
- [ ] Upload the 10 JPG files from `Screenshots/` to the CurseForge project gallery.
- [ ] Verify the license, third-party acknowledgments, supported versions and project links.
- [ ] Submit to moderation; share the listing URL only once it exists and is approved.

## GitHub presentation

- [x] README points to the current release and both ZIPs and shows the real gameplay gallery.
- [ ] Repository About description and topics reflect the current feature set.
- [ ] Upload a branded social-preview PNG in GitHub Settings separately if desired.
- [ ] Leave unshipped features and concept screenshots out of release claims.

Official submission guidance: https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips
