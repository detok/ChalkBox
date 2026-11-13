# ChalkBox user guide

Welcome! ChalkBox is a single addon; all sections live in **Esc → Options → AddOns → ChalkBox**. Type `/chalk` to open the main page.

## First five minutes

1. Verify the addon appears on your character's AddOns screen.
2. Open your **profession windows** (e.g. Leatherworking, Cooking) once. ChalkBox observes recipes and materials as the client exposes them.
3. Hover over useful items in your bags. Quest protections, your personal keep list and learned-recipe uses take precedence over generic hints.
4. Type `/chalk prep test` to check the center-screen reminder.
5. Check **QuietGuard** if you want to accept guild/duel invitations. The guild/duel filters start on; other social declines start off.

## LootSense and ProfessionSense

**Our aim is to save useful things, not to tell you to hoard everything.**

- **KEEP**: A personally protected item or an item needed by a tracked quest. Create your own protection using `/chalk keep [item]` and remove it using `/chalk forget [item]`.
- **KNOWN RECIPE**: ChalkBox has observed a learned recipe using this reagent. If the client exposes a quantity, the tooltip can show `3/5 in bags`.
- **POTENTIAL USE**: A recipe was found in optional offline data, but it was **not** verified as learned by your character. This is a lead, not a promise.
- **CAMP REAGENT / TOOL**: An item has a verified Forever camping use (such as Light Leather, Simple Wood, Flint and Tinder).
- **PROFESSION: possible**: An item belongs to a family associated with one of your current crafts; check the actual recipes.
- **No extra line**: No strong information available. **Silence does not mean safe to sell.**

Hold **Shift** on a relevant item to see more learned recipe uses. Use `/chalk loot scan` after opening the profession window. Use `/chalk loot status` to confirm the **bundled** catalog was indexed. **All 2,511 Forever recipes are bundled now.** There is no second addon to download. The offline catalog helps discover possible uses, while the actual profession window is still the only proof your character knows a recipe. See [Recipe data](RECIPE_DATA.md).

ChalkBox does not click vendor buttons or automate selling. Always review items before deleting or selling them.

### New in v1.9 — native-looking Item Insight

LootSense no longer appends a long `LootSense: blah` tooltip line. It uses a small **CHALKBOX | ITEM INSIGHT** subsection with a short, clearly colored verdict and evidence on the next line. For instance, a **Used in a learned recipe** note includes the actual crafted item and observed amounts. **Possible crafting use** remains explicitly unconfirmed.

Go to **ChalkBox → LootSense Appearance** to toggle subtle green reagent insets in **Blizzard's own bag slots**. Highlights only appear for items used by recipes your **current character has really learned**. The bundled offline catalog, profession family guesses, potential recipes and unknown items **do not** trigger the green outline. Set marker opacity from **15–100%**, Refresh Bag Markers, or Scan Open Profession. The overlay does not change rarity borders, drag and drop, selling, or bag sorting.

If no item glows, open a crafting window until the recipe list loads, use `/chalk loot scan`, and then **Refresh Bag Markers**. If the client doesn't expose its native bag buttons, there is no safe visual overlay to paint; tooltips still work.


## CampSense (Adventure Prep)

Forever camping has special uses beyond classic's cooking fire. CampSense can identify common components such as **Simple Wood**, **Flint and Tinder**, and **Light Leather** (used in camp features). It also checks supported player auras, **plus the separate Camp Tent rested-XP system**:

| Aura reading | Behavior |
| --- | --- |
| **Camp Benefits** active | No repeat *camp* reminder |
| **Camp Benefits** at 10 minutes or less | A new camp may be useful soon |
| **Camp Benefits** missing | Suggest camping |
| **Welcoming Campfire** detected | Leaves you alone while you gather camping benefits |
| Aura API unavailable/restricted | Reports unknown, rather than assuming missing |
| **Boosted Rest** debuff (1229451) | The tent already credited you; no repeated tent reminder |
| Rested XP already at least **5% of a level** | Another Camp Tent refill won't help |
| Tent APIs unavailable | Tent state unknown; manually use `/chalk prep tent done` if necessary |

**Camp Tent is a one-time Rested XP top-up, not a continuing Camp Benefits buff.** Missing the latter never proves you didn't receive the tent refill. If Forever doesn't report the harmful Boosted Rest aura, click **Tent Used** in Adventure Prep to acknowledge it for one hour this session (`/chalk prep tent clear` removes that acknowledgment). On-screen notices appear near the **top** and fade after nine seconds. Use **Adventure Prep → Toast Appearance** to unlock the frame, **Preview / Move (25s)** and drag it, set opacity (35–100%), and then relock it. Locked toasts are click-through, so they won't steal combat clicks. Try `/chalk prep test`. In the **Adventure Prep** page, you can toggle the toast, supplies, buff checks and class reminders independently, or pick 20/45/90-minute general reminder spacing.

## Combat Meter — DPS, damage and more

The built-in ChalkBox Combat Meter is a **small window** that uses WoW Forever's native damage tracking. It's visible by default and does **not** need a second addon, internet access or a combat log.

**At a glance:** each row shows a genuine **WoW class icon**, a class-colored bar, the player name and a native damage/healing number. Your own row has a gold marker. Under **Combat Meter** settings, choose **Class** for familiar emblems (default), **Spec** for specialization artwork where the game provides an icon ID, or **Off** for extra name width. Unknown/pet sources get a neutral icon rather than a guessed player class. The two title-bar buttons cycle:
- Statistic: **DPS, Damage Done, HPS, Healing Done, Damage Taken, Interrupts**.
- Scope: **Fight, Last, Overall**.

You can also type `/chalk meter icons class`, `/chalk meter icons spec`, or `/chalk meter icons off`. Icons use textures already installed in WoW, with no additional downloads.

**Move and resize:** drag the title bar, then use the bottom-right grip to resize width and height. Click **LOCK** directly on the meter to protect its position, or click **UNLOCK** to move it again. Change transparency with the on-window **Opacity** slider (35–100%), or the native `/chalk → Combat Meter` slider. Show 5, 8 or 12 rows and choose 85, 100 or 115% UI scale in settings. There is no close X; use `/chalk meter hide`, `/chalk meter show` or the Combat Meter Show switch in options.

**Print a fight:** click **PRINT** after combat to send **one short top-three summary to normal party chat**. The current DPS/damage/healing mode and Fight/Last/Overall view determine what prints; when Current has no entries, it tries Last. It refuses to post while solo, in a raid, or while the game protects combat values. `/chalk meter print` does the same thing. It never auto-posts or redirects to SAY/RAID. Type `/chalk meter help` for commands.

**Reset is shared:** click the new **RESET** button directly on the meter (or Reset Data... in settings). You'll get a confirmation before clearing *all* Blizzard damage sessions, including those visible in other meters. It doesn't run during combat.

**Forever restriction:** ordinary combat-log data is inaccessible to addons. The C_DamageMeter data can be secret while fighting; ChalkBox displays these fields directly through game UI methods instead of trying to analyze/sort them. The game controls pet/source attribution and the meter may not be available on non-Forever clients. For deeper per-spell statistics, the game's own meter remains available.

### Print directly from Blizzard's built-in damage meter

**You do not need to use the ChalkBox meter window.** WoW Forever's own damage meter has a native settings/gear dropdown. With ChalkBox enabled, this menu gains **ChalkBox: PRINT top 3 to PARTY**.

Set the Blizzard meter to your preferred DPS/damage/healing statistic and Current/Overall/saved fight. After combat, choose **ChalkBox: PRINT top 3 to PARTY** in that window's gear menu. It prints one brief PARTY message using that exact window selection, not the ChalkBox window's selection. No message is sent while solo, in a raid, in combat, in Edit Mode, or if the client still protects the numbers or names.

To keep only Blizzard's meter, turn off **Show compact DPS meter window** under ChalkBox → Combat Meter or type `/chalk meter hide`. The built-in gear menu still works. Use `/chalk meter native off` to remove the extra gear-menu entry, `/chalk meter native on` to restore it, or `/chalk meter native status` to diagnose support. This feature relies on the Forever `MENU_DAMAGE_METER_WINDOW_SETTINGS` menu extension and will quietly do nothing when that API is missing.

## The Bar — customizable adventure dashboard (v1.9.2)

The same **18px** strip now supports XP, XP/hour, estimated time to level, session time, gold/net change, **free equipped-bag slots, equipment durability, rested XP, home/world latency and Hunter pet health**. No new floating bar or additional screen height.

### New in v1.9.2 — Repair and the right-click menu

**The Bar** is the new display name for TrailBar. Existing preferences and commands are unchanged. The **Repair** stat is enabled by default and occupies a small block on the right when screen space allows.

At a repair merchant, the addon displays the actual repair-all quote (`Repair 2g`). After it has observed one valid vendor quote while your equipment is damaged, it can display a **rough estimate** away from the merchant (`Repair ~2g`) based on subsequent equipped durability loss. The current repair quote can include damaged carried gear; the extrapolated estimate models *equipped* wear only. Prices and discounts can differ at the next merchant. If no valid sample exists or the gear durability pool changed substantially, the module says `Repair --`, not zero. Hover for the reason. **ChalkBox never automatically repairs anything.**

**Right-click** a module outside Edit Mode to open a Blizzard-style menu: hide/show the selected stat, move it between the three sections, select text alignment, enter/finish Edit Mode, reset positions, move or hide The Bar, and open settings. **Right-click an empty part of The Bar** to restore hidden modules using the general menu. In Edit Mode, right-click retains the original quick alignment cycle. Left-clicking Bag Value still switches **Junk / Total**.

Quick command: `/chalk bar stat repair on|off`. Settings live at **ChalkBox → The Bar Stats / The Bar Appearance**.

### Bag value: Junk vs. Total (v1.9.1)

Enable **Bag vendor value** in TrailBar Stats (off by default to keep existing layouts familiar). The compact stat shows **Value** for all equipped bag contents at vendor sell prices, or **Junk** for poor/gray-quality items only. Left-click the module outside Edit Mode to switch instantly; the native settings page also has a **Value: Total / Value: Junk** toggle. The preference saves across sessions.

The tooltip shows the exact gold/silver/copper for both categories, tracks stack counts and excludes bank inventory, equipped gear and your current gold. If any item's information is not yet cached, `>=` indicates only the known minimum—never an invented exact number. After item data loads, the stat updates. **No items are sold.** Slash options: `/chalk bar bagvalue junk`, `/chalk bar bagvalue total`, `/chalk bar bagvalue toggle`.

### The new stats

- **Bags:** `Bags 12 free` (example). Tooltip separates **general-purpose free slots** from **profession/specialized free slots**, since a skinning or herb bag can't hold everything. The count is for your backpack and equipped bags, not the bank.
- **Gear:** `Gear 87%` (example). A **weighted average** of equipped repairable item durability, with the lowest-condition equipped item in the tooltip. Warns with a colored number when any equipped item is very low.
- **Rested:** `Rest 42%` (example) means the available rested bonus equals **42% of one level's XP**, not that your camp buff is at 42%. Tooltip has the bonus XP value.
- **World latency:** `World 63ms` (example), with home/world latency in the tooltip. Off by default to keep the bar slim.
- **Pet:** `Pet 95%` or `Pet none` for Hunters; if the Forever client marks pet health secret (especially in combat), it shows `Pet --` without attempting to calculate it. Hidden for non-Hunters.

Values use **Forever's real APIs** and are never invented. If the client lacks the relevant API, that widget automatically stays hidden. The bar refreshes at least every five seconds and on bag, equipment and rest events where the client provides them.

### Change the layout

Open **Esc → Options → AddOns → ChalkBox → TrailBar Stats**. Eleven switches independently control XP/hour, level ETA, session time, gold, bags, gear, rested XP, latency, Hunter pet status optional vendor bag value and repair quotes/estimates. Level/XP always remains visible.

Choose one of three quick profiles:

| Profile | Default selections |
| --- | --- |
| **Balanced** (default) | All former stats + bags, gear, rested XP and Hunter pet; latency off |
| **Minimal** | Level/XP, free bag slots and gold |
| **All** | Enable every supported module, including world latency |

The strip **automatically hides lower-priority widgets** when the UI width gets too small, while preserving your saved choices. Increasing the display width brings the fields back. This avoids text overlapping on narrow screens. Use `/chalk bar stats` to compare enabled vs. currently shown modules.

Commands: `/chalk bar stats balanced`, `/chalk bar stats all`, `/chalk bar stats minimal`, and `/chalk bar stat bags|gear|rested|pet|latency|rate|eta|time|gold|bagvalue|repair on|off`. Existing bar placement, reserved screen space, session reset and diagnostics commands remain unchanged.

### New in v1.9 — Edit Mode and transparency

Open **Esc → Options → AddOns → ChalkBox → TrailBar Appearance**. The bar now uses a Blizzard-like **neutral charcoal** background. Move **Background opacity** anywhere from **0%** (just the text and XP underline) to **100%** (fully opaque); the slider does not fade the actual numbers. `/chalk bar opacity 0` also works.

Choose **Edit Bar** to turn on soft amber highlight regions behind the text. The bar is divided conceptually into **Left / Center / Right** thirds. Grab and **drag a module left or right** to place it in another zone; drag past another module to change the order within that zone. **Right-click a stat while editing** to cycle its *text alignment* left, center or right inside its own block. Click **Done Editing** to relock and prevent accidental changes. The **Reset Layout** button puts all twelve stats back in their default zones/order.

Layout and text alignment are stored **per character** in SavedVariables. Your Hunter does not have to use the same order as another character. Stat visibility switches and overall bar style remain in regular addon settings. When screens are too narrow, responsive priority hiding still applies *temporarily*, without altering the saved order.

Useful commands: `/chalk bar edit on|off`, `/chalk bar layout`, `/chalk bar layout reset`, `/chalk bar move gear center 1`, `/chalk bar align bags right`. Edit Mode deliberately refuses to start in combat.

### Existing screen layout and bag shift

Screen-space reservation is **on** by default. Move the strip in **TrailBar** options. Run `/chalk bar status` to check whether the reserved space was applied, or `/chalk bar reserve off` to disable it if another UI conflicts. Some custom frames or Blizzard Edit Mode layouts may ignore the parent inset.

### Separate bag windows clipping off the top?

If you use **individual bags** rather than WoW Forever's combined bag, large bags can stack above the screen edge. ChalkBox can nudge Blizzard's native bag column down while keeping all item slots, art and sorting unchanged.

Open **ChalkBox → TrailBar**. In v1.9 there is a **vertical slider from −120 to +120 UI points**, with **Blizzard's original placement at the middle (0)**. The top of the slider raises bags, the bottom lowers them. **Reset Bags** instantly returns to 0; the value on the side says **up/down** instead of leaving you to guess.

You can also type `/chalk bags offset 30` to lower bags, `/chalk bags offset -35` to raise them, `/chalk bags reset` to restore stock or `/chalk bags status` to inspect the hook. Actual pixel movement may vary with UI Scale. The change persists between sessions and applies when bags open or Blizzard reanchors them. Combined bags remain untouched. In combat, changes are deferred. If another addon owns bag positions, reset to 0 to avoid competing anchors.

## QuietGuard

The default settings attempt to prevent **guild invite spam and duel requests**. **Party, trade and channel invitations are not filtered unless you opt in**, to avoid blocking friends and ordinary gameplay. An anti-invite client API may be limited by your game build. View the active choices via `/chalk guard`, and change them under **QuietGuard** in Options.

## Emota and Race Behavior

The master automatic-emote option is **off until you enable it**. When enabled, it occasionally picks native emotes, avoids recent repeats, and checks safety conditions such as combat or movement. Race/class context includes a hunter/pet-aware option and gentler resting-area behavior. Each emote can be enabled/disabled from the **Emote Catalog**, and you can test one with `/chalk emota idle preview`.

**New in v1.9:** open **ChalkBox → Emota Race Behavior** (or click **Races** from the Emota page). Use the supported native race dropdown, or Previous/Next and My Race buttons, to inspect each race's weighted flavor. **Live behavior** races show their signature emotes. **Planned** ones are explicitly placeholders with no unique behavior yet.

For a live race, select **Off / Subtle / Default / Expressive**. This changes only the *weighting of racial idle personality*, not the default anti-spam timer, class/pet influences, or the character's actual race. Default retains exactly the pre-1.9 racial flavor. Selecting a different race in the chooser is for inspection and configuring its future behavior, **not** a way to make your current character act as another race.

## QuestSense (Forever smart quest tracking)

QuestSense now reads your **accepted quests** from WoW Forever's `C_QuestLog` API. It **does not** need Questie or a third-party quest database, and it doesn't replace your game quest log or built-in objective tracker.

Choose one of three modes under **Esc → Options → AddOns → ChalkBox → QuestSense**:

- **Smart** (default): rank accepted quests by new/current zone relevance where it exists, then use free watch slots on other accepted quests. This works even when Forever offers no readable map pins.
- **Nearby only**: be selective; only add quests whose log header or quest POI matches the current zone.
- **All accepted**: track in the order quests appear in your accepted quest log.

Set a cap of **5, 10, 15 or 20** ChalkBox-managed quest watches. The default is 10. **Manually watched quests are never removed** by this cap, and untracking an auto-added quest yourself suppresses it for that zone visit. ChalkBox won't edit watches during combat, with the world map or quest log open, or while inside a dungeon/raid; it retries safely.

Use **`/chalk quests status`** if you don't see results. It reports how many accepted quests were read, how many were eligible, how many are watched and how many ChalkBox itself added, with an explanation such as *world map open* or *quest log isn't ready*. Use `/chalk quests refresh` after closing the map.

**Location limits:** Forever can expose quest objectives without readable target coordinates. QuestSense handles *which quests to watch*, not magical navigation or locations. It never invents destinations, auto-accepts quests, or completes them for you.


