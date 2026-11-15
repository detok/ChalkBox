# ChalkBox

**One practical addon for WoW Forever. Loot knowledge, quests, macros and small interface improvements without a pile of separate addons.**

ChalkBox integrates with the game's existing windows and lets you enable the tools you need. The focus is clarity and evidence: tell you what was actually observed, don't invent missing client information and leave protected gameplay actions to you.

## What you can use

### LootSense, professions and personal protections

See why an item deserves attention. ChalkBox highlights supported accepted quest items and, when objectives can be matched reliably, can show the **quest name and collected/required progress**. Add an item to your personal KEEP list yourself. Learned recipe uses are distinguished from possible relationships in the bundled Forever profession recipe catalog. Neither module moves or sells your items.

### DropSense and Discoveries

DropSense records items found in readable loot windows. Open the World Map's **Discoveries** side panel to browse saved zones, dungeons and known creature sources, filter/sort items and review *personal observed* loot-window rates. These are not official server drop probabilities and do not count every unlooted kill.

While hovering an item in Discoveries, the latest recorded outdoor loot position can briefly pulse as a dot on that zone's visible World Map. Outdoor loot can store up to six recent distinct **player positions at loot-window opening** per item/area and per verified creature source, with the recent coordinates shown on hover. They are not guaranteed spawn or death locations; old/dungeon records get no fabricated points.

### QuestSense Smart / Nearby / All + Navigation

QuestSense organizes Blizzard's own accepted-quest tracker without replacing it. Right-click Blizzard's quest-tracker header for a small ChalkBox menu with QuestSense Settings, Off, Smart, Nearby and Navigation On/Off where the native UI supports a safe header hook. **Smart** prioritizes relevant quests outdoors and, in a party dungeon when the client exposes reliable matching evidence, focuses on quests for the **specific current dungeon**. Previously selected manual watches return when you leave. If the instance's quest evidence is missing, it keeps the existing tracker rather than guessing. **Nearby only** filters conservatively by current zone; **All accepted** uses log order within watch limits.

**NEW: QuestSense Navigation** is an optional, compact outdoor compass following *real accepted quest waypoints* from Forever's API. Auto follows your selected Blizzard quest or current super-tracked quest, then uses a stable known local fallback only when nothing is selected; right-click the arrow for **Auto / Next / Hide**, see yards below the arrow, hover for quest details, choose Original WoW, Blizzard Navigation or ChalkBox HD arrow rendering and a 32–72px size slider in settings (fresh default: Original WoW, 48px), and drag it to move, and lock it under settings. Direction and straight-line distance appear only when world coordinates and facing are supported. When dead or ghosted, the arrow prioritizes the actual corpse map marker if available and returns to your quest after resurrection. The arrow can add its selected quest to Blizzard's native watch list to keep it visible, but never removes other manual watches or replaces a player's map pin. No guessed quest routes or automatic gameplay. Navigation starts OFF for new characters.

### AuctionSense, AuctionInsights and DisenchantSense

Open the native Auction House's **AuctionSense** tab and deliberately start a browse asking-price scan. Optional full listings are server-limited. Review observed asking prices, available quantities, scan age and market context. **AuctionInsights** presents read-only inventory appraisal and supported seller-mail receipts in the native AH experience. **DisenchantSense** uses clearly labeled Forever/Classic-reference estimates and available asks. Asking prices are **not actual sales**; no trading or disenchanting is automatic.

### MacroForge

Build macros from the spells actually learned on your character. Templates include Engage, Burst/Trinkets, Modifier Keys, Manual Sequence and Mouseover. Work in a framed spellbook interface with a multiline preview, warnings and saved character recipes. Copy the exact text yourself, or explicitly choose **Install New** outside combat to make a *new* native macro without overwriting an existing one. MacroForge also adds a small button beside Delete/New/Exit in Blizzard's native `/macro` editor, when the native controls leave space. Opening Forge from ChalkBox settings now closes Options and opens the native macro editor before docking when supported. On spacious displays, the full ChalkBox workbench docks beside the original macro editor; on small displays, it remains standalone without replacing or moving Blizzard's UI. MacroForge cannot automate rotations, react to procs or bypass the global cooldown. Its optional separate AddOn Compartment shortcut starts off.

### The Bar, combat and session tools

**The Bar** is a slim customizable screen-edge summary for level/XP, XP rate, time to level, rested XP, bags, durability, repair estimates, junk value, gold and latency. Edit its layout by right-clicking; **Done editing** is available from the empty-Bar context menu. Layout choices are preserved on upgrade. Repair Learning differentiates real vendor repair quotes from `~` estimates.

The optional **Combat Meter** starts closed and can show supported native combat data; manual post-fight party reporting is gated by client rules. **Session Journal** keeps the current and up to 20 previous per-character observed session summaries. In 2.2.11, the Adventure Journal gains a full warm wood frame and legible inset sections, while individual-event Chronicle recording remains a future feature.

### Adventure Prep, Emota, QuietGuard, appearance and updates

Adventure Prep gives practical camping, tent/rest and pet/supply reminders without pretending tent use proves a separate camp buff. Emota offers opt-in character idles and emotes. QuietGuard's duel, guild, party, trade and channel filtering defaults **off** for new installs, preserving prior saved choices. Global Appearance and bag positioning help integrate the UI. Updates shows the installed version and GitHub Releases link; WoW does not fetch GitHub over HTTP.

## Install and settings

Download the **ChalkBox-X.Y.Z.zip** game asset from [GitHub Releases](https://github.com/detok/ChalkBox/releases). Extract its single `ChalkBox` folder to your client's `Interface/AddOns/` directory. Keep WoW's SavedVariables when updating. Open **Options → AddOns → ChalkBox** or type `/chalk`.

[Player handbook](https://github.com/detok/ChalkBox/blob/main/docs/USER_GUIDE.md) · [Commands](https://github.com/detok/ChalkBox/blob/main/docs/COMMANDS.md) · [Source and issues](https://github.com/detok/ChalkBox)

## Compatibility and credits

Developed for **World of Warcraft: Forever**. Retail and standard Classic Era have not been verified. Features depend on client API support; live Forever client QA is separate from automated Lua tests. Independent community addon, not affiliated with Blizzard.

**Created and maintained by Detok Whitemaine.** MIT-licensed original code with bundled third-party license notices.
