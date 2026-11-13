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

## TrailBar

A slim top/bottom strip shows adventuring metrics. Screen-space reservation is **on** by default. Move the strip in **TrailBar** options. Run `/chalk bar status` to check whether the reserved space was applied, or `/chalk bar reserve off` to disable it if another UI conflicts. Some custom frames or Blizzard Edit Mode layouts may ignore the parent inset.

### Separate bag windows clipping off the top?

If you use **individual bags** rather than WoW Forever's combined bag, large bags can stack above the screen edge. ChalkBox can nudge Blizzard's native bag column down while keeping all item slots, art and sorting unchanged.

Open **ChalkBox → TrailBar** and move the **Separate bags: move down** slider from 0 (default) toward 30. It goes to 80; the number is in game UI points and can vary slightly in physical pixels with UI Scale. The change is saved between logins and applies when the bags open or Blizzard recalculates their layout. The combined bag window is deliberately unaffected.

You can also use `/chalk bags offset 30`, `/chalk bags reset` or `/chalk bags status`. If the settings slider is changed in combat, it will reapply the adjustment after combat. If you install a separate bag-mover addon, disable this ChalkBox adjustment (set 0) to avoid competing positions.

## QuietGuard

The default settings attempt to prevent **guild invite spam and duel requests**. **Party, trade and channel invitations are not filtered unless you opt in**, to avoid blocking friends and ordinary gameplay. An anti-invite client API may be limited by your game build. View the active choices via `/chalk guard`, and change them under **QuietGuard** in Options.

## Emota

The master automatic-emote option is **off until you enable it**. When enabled, it occasionally picks native emotes, avoids recent repeats, and checks safety conditions such as combat or movement. Race/class context includes a hunter/pet-aware option and gentler resting-area behavior. Each emote can be enabled/disabled from the **Emote Catalog**, and you can test one with `/chalk emota idle preview`.

## QuestSense (Forever smart quest tracking)

QuestSense now reads your **accepted quests** from WoW Forever's `C_QuestLog` API. It **does not** need Questie or a third-party quest database, and it doesn't replace your game quest log or built-in objective tracker.

Choose one of three modes under **Esc → Options → AddOns → ChalkBox → QuestSense**:

- **Smart** (default): rank accepted quests by new/current zone relevance where it exists, then use free watch slots on other accepted quests. This works even when Forever offers no readable map pins.
- **Nearby only**: be selective; only add quests whose log header or quest POI matches the current zone.
- **All accepted**: track in the order quests appear in your accepted quest log.

Set a cap of **5, 10, 15 or 20** ChalkBox-managed quest watches. The default is 10. **Manually watched quests are never removed** by this cap, and untracking an auto-added quest yourself suppresses it for that zone visit. ChalkBox won't edit watches during combat, with the world map or quest log open, or while inside a dungeon/raid; it retries safely.

Use **`/chalk quests status`** if you don't see results. It reports how many accepted quests were read, how many were eligible, how many are watched and how many ChalkBox itself added, with an explanation such as *world map open* or *quest log isn't ready*. Use `/chalk quests refresh` after closing the map.

**Location limits:** Forever can expose quest objectives without readable target coordinates. QuestSense handles *which quests to watch*, not magical navigation or locations. It never invents destinations, auto-accepts quests, or completes them for you.


