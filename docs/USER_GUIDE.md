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

**Camp Tent is a one-time Rested XP top-up, not a continuing Camp Benefits buff.** Missing the latter never proves you didn't receive the tent refill. If Forever doesn't report the harmful Boosted Rest aura, click **Tent Used** in Adventure Prep to acknowledge it for one hour this session (`/chalk prep tent clear` removes that acknowledgment). On-screen notices use a small, nine-second toast that does not capture mouse input. Try `/chalk prep test`. In the **Adventure Prep** page, you can toggle the toast, supplies, buff checks and class reminders independently, or pick 20/45/90-minute general reminder spacing.

## Combat Meter — DPS, damage and more

The built-in ChalkBox Combat Meter is a **small window** that uses WoW Forever's native damage tracking. It's visible by default and does **not** need a second addon, internet access or a combat log.

**At a glance:** each row shows a class-colored bar, the player name and a native damage/healing number. Your own row has a gold marker. The two title-bar buttons cycle:
- Statistic: **DPS, Damage Done, HPS, Healing Done, Damage Taken, Interrupts**.
- Scope: **Fight, Last, Overall**.

**Move and resize:** drag the title bar, then use the bottom-right grip to resize width and height. Click **LOCK** directly on the meter to protect its position, or click **UNLOCK** to move it again. Change transparency with the on-window **Opacity** slider (35–100%), or the native `/chalk → Combat Meter` slider. Show 5, 8 or 12 rows and choose 85, 100 or 115% UI scale in settings. Click **X** to hide; `/chalk meter` shows it again.

**Print a fight:** click **PRINT** after combat to display the selected DPS/damage/healing ranking in *your own local chat*. The mode and Fight/Last/Overall selection determine what prints. If Current is empty, ChalkBox attempts the last fight. Protected in-combat information isn't converted to Lua strings or broadcast; if unavailable, ChalkBox explains why instead. `/chalk meter print` does the same thing. `/chalk meter help` lists quick commands.

**Reset is shared:** the Reset Data button confirms before calling Blizzard's reset API, because clearing sessions affects the built-in meter and other addons that use the same data. It does not run during combat.

**Forever restriction:** ordinary combat-log data is inaccessible to addons. The C_DamageMeter data can be secret while fighting; ChalkBox displays these fields directly through game UI methods instead of trying to analyze/sort them. The game controls pet/source attribution and the meter may not be available on non-Forever clients. For deeper per-spell statistics, the game's own meter remains available.

## TrailBar

A slim top/bottom strip shows adventuring metrics. Screen-space reservation is **on** by default. Move the strip in **TrailBar** options. Run `/chalk bar status` to check whether the reserved space was applied, or `/chalk bar reserve off` to disable it if another UI conflicts. Some custom frames or Blizzard Edit Mode layouts may ignore the parent inset.

## QuietGuard

The default settings attempt to prevent **guild invite spam and duel requests**. **Party, trade and channel invitations are not filtered unless you opt in**, to avoid blocking friends and ordinary gameplay. An anti-invite client API may be limited by your game build. View the active choices via `/chalk guard`, and change them under **QuietGuard** in Options.

## Emota

The master automatic-emote option is **off until you enable it**. When enabled, it occasionally picks native emotes, avoids recent repeats, and checks safety conditions such as combat or movement. Race/class context includes a hunter/pet-aware option and gentler resting-area behavior. Each emote can be enabled/disabled from the **Emote Catalog**, and you can test one with `/chalk emota idle preview`.

## QuestSense

QuestSense can automatically follow accepted quests relevant to your current area using the game's native quest tracking. You can turn it off from Options or with `/chalk quests off`. It does not add quests, abandon quests, or complete anything for you.

Need help? [Troubleshooting](TROUBLESHOOTING.md) or [report a bug](https://github.com/detok/ChalkBox/issues/new/choose).
