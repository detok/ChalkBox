# Actual ChalkBox 2.2.22 screenshots — privacy-cropped gallery

**Source:** the player's authentic `cbssrcneedscroping.zip`, containing 28 gameplay JPEGs at 2560×1440. Screenshots are **cropped from original pixels**, not AI-redrawn. No UI text, icon, statistic or market price was invented.

The reproducible recipe is [scripts/crop_gallery.py](../../scripts/crop_gallery.py). Input JPEGs deliberately remain **outside this public repository** because the unedited full-screen captures include player names, pet labels, chat and other identifying UI.

## Review and selection

The crop pack contains **16 primary gallery images plus 12 extras** derived from 26 original screenshots. Each crop identifies its source image and pixel rectangle. Two originals, `200818` (race behavior) and `200826` (updates), were excluded: unrelated player or pet names bleed through the translucent options frame. Crop rather than fabricate a replacement screenshot.

| Upload priority | Original screen | What it demonstrates |
| --- | --- | --- |
| 1 | 200729 | ChalkBox central module dashboard |
| 2 | 200622 | Discoveries + map with actual observed drops |
| 3 | 200625 | Observed loot and real Market low/average/listing prices in a tooltip |
| 4 | 200656 | MacroForge editor (only our window; the player's named macro tab is cropped out) |
| 5 | 200845 | Inventory item showing auction + profession context |
| 6 | 200845 | Actual top ChalkBox status bar, isolated from the player frame |
| 7 | 200735 | LootSense |
| 8 | 200743 | AuctionSense settings (not the actual auction listing screen) |
| 9 | 200747 | QuestSense navigation |
| 10 | 200753 | Adventure Journal recap |
| 11 | 200758 | The Bar options |
| 12 | 200802 | Combat Meter options |

The remaining images document Discoveries filters, DropSense, bags, global appearance and optional module configurations. Do not present all settings pages as unique major features; use the 8–12 clearest images for the CurseForge gallery.

## Privacy and authenticity

- Screenshot crops exclude player unit frames, chat, character and pet names, minimaps, and the screen's unrelated world UI.
- The player-coordinate footer inside the map is obscured with a small Pillow blur of the **existing original pixels**. No generated scenery or altered numeric market values.
- A slim bar-only crop exists for The Bar; a separate bag-plus-market-tooltip crop demonstrates item integration.
- Full, original screenshot files should **not be uploaded publicly**.
- The 200845 item tooltip shows **auction asking prices**, not recorded sales.
- No screenshot in this batch shows the actual populated AuctionSense **Market tab** inside the auction house. 200743 is only the settings page; capture that live view separately if it will be a key promotional claim.

## Rebuild without AI

```bash
python -m pip install pillow
python scripts/crop_gallery.py cbssrcneedscroping.zip cropped
```

The private source archive is required and is intentionally not checked into Git. Only publish images from the `Gallery/` and `Extras/` directories after confirming any remaining translucent-game-text privacy risks. The ready-made cropped ZIP was delivered separately in the ChatGPT conversation; it is **not** a gameplay addon installer.

## GitHub versus CurseForge artifacts

The GitHub connector used for the review supports text/source changes but does not expose an upload-a-binary-release-asset action. The actual 6.5 MB screenshot ZIP therefore must be manually attached to the [existing 2.2.22 GitHub release](https://github.com/detok/ChalkBox/releases/tag/v2.2.22) if desired; **do not overwrite the tested playable addon ZIP**. The plain-text crop recipe and review are version-controlled here so future updates can be recreated exactly.

