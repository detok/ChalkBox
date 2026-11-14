# ChalkBox — publication checklist (2.1.1)

## Build and verify

- [ ] GitHub Actions passes Lua syntax, module tests, addon packaging and the media-kit artwork checks.
- [ ] Both TOCs declare version 2.1.1 and the addon ZIP contains one ChalkBox folder.
- [ ] Open WoW Forever after upgrading: the settings hierarchy expands as intended.
- [ ] Confirm the optional compact meter is hidden at login; show it manually.
- [ ] Verify opening the bank on a fresh character doesn't cause an addon-block warning; regular bag highlighting and offsets still work afterward.
- [ ] Confirm Discoveries map button, dragging, source filters and search.
- [ ] Verify the Area / Dungeon field opens a **direct, scrollable zone list** without nested menus, including when native menu APIs are unavailable.
- [ ] Verify the dropdown is **above** search, item rows, the world map and the journal border, receives row clicks, and closes with the journal.
- [ ] Confirm the in-game AddOns list shows the newer ChalkBox project mark from the packed TGA.
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
- [ ] Use **ChalkBox-2.1.1.zip** as the **game file**. Never upload the media kit ZIP as the playable addon.
- [ ] Paste [FILE_CHANGELOG_2.1.1.md](../copy/FILE_CHANGELOG_2.1.1.md) for the file changelog.
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

## AuctionSense 2.1.1 verification

- [ ] At an auctioneer, click **Scan Market** and verify the account-wide cooldown and scan progress.
- [ ] Confirm stack-normalized asking prices, quantity and listing counts against a few known AH lots.
- [ ] Confirm mixed gear variants, stale prices, per-faction separation and saved price history after a relog.
- [ ] Close the AH mid-scan; prior prices must survive and there must be no protected action warning.
- [ ] Confirm item tooltip toggle, clean searchable window and no unrequested scan, bid, purchase or posting.

## AuctionSense native-tab acceptance (2.1.1)

- [ ] With the AH open, verify AuctionSense appears alongside Blizzard's native tabs and the panel is clickable.
- [ ] Switch to Buy, Sell, Auctions and back; no panel remains over Blizzard's transaction interface.
- [ ] Click Scan Market and verify browse-results events, incrementally loaded item counts and an eventual saved snapshot.
- [ ] Verify incomplete browse data never creates an invented average ask or listing count.
- [ ] Test advanced Full listings request (15-minute server limit), no-response diagnostics and recovery without /reload.
- [ ] Verify no protected-action blocking, including when closing the AH and reopening bags.
