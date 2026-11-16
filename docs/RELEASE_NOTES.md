# ChalkBox 2.2.24 — Release Candidate (GitHub Prerelease)

**WoW Forever playtest build. Not yet a stable release.** The verified **2.2.22 stable** remains available and unchanged. This candidate combines the 2.2.23 combat chat protection with subsequent usability fixes and has passed automated checks; real Forever UI behavior still needs a live test.

## What's improved

- **Combat Meter:** one small **Menu** button; right-click its header for the same controls. Adjust statistic, Current / Last / Overall, icon style, row cap, background opacity, and lock; reset still requires explicit confirmation.
- **Unified fight reports:** compact reports use the **same validated native report engine** as Blizzard's meter. Manual **Top 3 / 5 / 10 → PARTY or SAY**, optional auto-report settings (default OFF), duration and cooldown are shared. When the game refuses manual addon chat, the manual copy dialog offers Ctrl+C. Never bypass chat protections, invent protected values, send to a surprise alternate channel, or claim API acceptance equals delivery.
- **Compact layout:** fresh default maximum is five participants; with fewer contributors, empty rows collapse. 8/12 and manual-sized caps remain available for raids. Saved row/opacity preferences are retained, including manually resized intermediate row counts.
- **The Bar:** left-click **Bags NN free** to invoke Blizzard's normal open/close-all-bags action outside combat and layout edit mode. Right-click menus and bag-value click behavior remain unchanged.
- **Backgrounds:** Combat Meter opacity adjusts only the backdrop/row surfaces, like The Bar. Names, numbers, class icons and damage-bar values remain legible, and the same global theme palette is respected.
- **AuctionSense:** Market highlights only when selected; the first native Buy/Sell/Auctions click should restore the proper native highlight, without replacing Blizzard's auction mode or trading controls.
- **Auction charts lab (experimental):** tucked under **Options → AddOns → ChalkBox → AuctionSense → Charts (Experimental)**. Search a saved item and plot its **last seven authentic low asking-price observations**, with actual scan times and hover values. Uses native Line drawing if available; native texture columns otherwise. No extra scans, new historical storage, weekly compression, automatic trading, inferred sales prices or fake trend data.

## Install for the playtest

1. Get **ChalkBox-2.2.24.zip** from this release's Assets (not the media ZIP and not GitHub's auto-generated source archive).
2. Close WoW Forever. Replace only your existing `Interface/AddOns/ChalkBox/` addon directory with the single `ChalkBox/` folder from the ZIP. **Do not delete SavedVariables.**
3. Enter the game, check ChalkBox → Updates displays **2.2.24**, then test using [the release-candidate checklist](https://github.com/detok/ChalkBox/blob/main/docs/RELEASE_CANDIDATE_TEST_2.2.24.md).

**Known limits:** Every Lua test and the publishing/ZIP checks can pass without verifying Forever's protected UI at runtime. The experimental chart's native Line renderer and the chat-report copy dialog require your real-client test. A chart requires actual previously saved scans; a single observation is not a trend.

**Release channel:** Prerelease/beta, **not** CurseForge stable. Keep 2.2.22 for rollback if any game error appears.
