# ChalkBox 2.0 — FAQ

## What is ChalkBox?
An all-in-one quality-of-life addon built for **World of Warcraft: Forever**. It includes loot insights, a personal map discoveries journal, MacroForge, The Bar, QuestSense, camping reminders, meter extras, optional personality and persistent session history.

## Is everything in one ZIP?
Yes. Extract one \`ChalkBox/\` folder into \`Interface/AddOns\`. Its profession recipe database and support libraries are already included.

## Do I need CurseForge to install it?
No. GitHub Releases offers the installable ZIP. A separate CurseForge project has not been claimed or approved.

## Is 2.0 a finished, fully tested public release?
**2.0.0 is a prerelease for Forever-client testing.** The Lua tests and ZIP packaging run in GitHub CI; placement of the updated map button and details of protected Forever APIs still need in-client acceptance tests.

## I don't see Discoveries on my map. Is it broken?
The button was changed for Forever's load-on-demand world map and upper-left canvas in 2.0. Open your regular world map once; if the button is still not visible, type **/chalk drops map**. If that opens the journal, type **/chalk drops map status** and include the output plus a screenshot in a GitHub bug report. Under **ChalkBox → DropSense**, ensure **Show Discoveries button** is enabled.

## Why doesn't the map show everything I previously looted?
DropSense only knows locations recorded **when it observed the loot window**. Older data collected before location tracking is preserved as unsited history. It cannot reconstruct past dungeons, zones or drop chances.

## Are the observed drop rates official?
No. The addon measures *appearance among readable loot windows* attributed to a known creature source. It cannot see every killed/unlootable mob or Blizzard's internal loot table, and mixed-source loot never produces a fabricated per-creature percentage. The built-in drop calculator uses a rate **you** supply.

## Does MacroForge let me run a whole rotation with one button?
No. Blizzard macros cannot bypass the GCD, automatically inspect procs/cooldowns for conditional casts or execute secure combat actions without appropriate player input. MacroForge teaches legitimate modifier branches, one-spell openers, trinket attempts and manual sequences.

## Does MacroForge change my macros automatically?
No. **Select Text** highlights generated macro text to Ctrl+C, then you paste in \`/macro\`. **Install New** is an optional explicit click outside combat that refuses to overwrite a same-named existing macro. Saved recipes are distinct from your native WoW macros.

## Why does the repair number sometimes show ~ or --?
The exact vendor repair-all quote is only available at a repair merchant. Away from one, ChalkBox can estimate from real quotes your character previously observed and labels it **~**. When there isn't a trustworthy calibration, it displays **--**. Damage inside bags and merchant discounts can make estimates differ.

## Will ChalkBox sell my trash or spend gold for me?
No. LootSense's **Junk/Total** bag value is a vendor resale *estimate*, not an action. CampSense and repairs are advisory. There are no automatic sells or purchases.

## Does QuestSense draw invented quest markers?
No. It manages supported watches in Blizzard's original quest tracker. It doesn't supply its own guessed quest coordinates or routes.

## Will the toast or combat meter constantly interrupt?
They are optional. The compact camping toast suppresses repeated unchanged alerts by default. Combat PARTY printing is manual. Native settings let you adjust display, opacity and position.

## Where is my saved history?
ChalkBox stores its own account/character SavedVariables using WoW's local addon persistence. Session history is per character; no cloud sync is used. Avoid deleting SavedVariables if you want to keep it.

## Where do I report a bug?
https://github.com/detok/ChalkBox/issues/new/choose — include ChalkBox version, Forever build, exact commands, Lua errors and screenshots where possible. Never share account credentials.
