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

Hold **Shift** on a relevant item to see more learned recipe uses. Use `/chalk loot scan` after opening the profession window. Use `/chalk loot status` to check whether the external catalog was indexed. The optional third-party recipe library is not required for your learned recipe scanner or camping hints; see [Recipe data](RECIPE_DATA.md).

ChalkBox does not click vendor buttons or automate selling. Always review items before deleting or selling them.

## CampSense (Adventure Prep)

Forever camping has special uses beyond classic's cooking fire. CampSense can identify common components such as **Simple Wood**, **Flint and Tinder**, and **Light Leather** (used in camp features). It also checks supported player auras:

| Aura reading | Behavior |
| --- | --- |
| **Camp Benefits** active | No repeat *camp* reminder |
| **Camp Benefits** at 10 minutes or less | A new camp may be useful soon |
| **Camp Benefits** missing | Suggest camping |
| **Welcoming Campfire** detected | Leaves you alone while you gather camping benefits |
| Aura API unavailable/restricted | Reports unknown, rather than assuming missing |

On-screen notices use a small, nine-second toast that does not capture mouse input. Try `/chalk prep test`. In the **Adventure Prep** page, you can toggle the toast, supplies, buff checks and class reminders independently, or pick 20/45/90-minute general reminder spacing.

## TrailBar

A slim top/bottom strip shows adventuring metrics. Screen-space reservation is **on** by default. Move the strip in **TrailBar** options. Run `/chalk bar status` to check whether the reserved space was applied, or `/chalk bar reserve off` to disable it if another UI conflicts. Some custom frames or Blizzard Edit Mode layouts may ignore the parent inset.

## QuietGuard

The default settings attempt to prevent **guild invite spam and duel requests**. **Party, trade and channel invitations are not filtered unless you opt in**, to avoid blocking friends and ordinary gameplay. An anti-invite client API may be limited by your game build. View the active choices via `/chalk guard`, and change them under **QuietGuard** in Options.

## Emota

The master automatic-emote option is **off until you enable it**. When enabled, it occasionally picks native emotes, avoids recent repeats, and checks safety conditions such as combat or movement. Race/class context includes a hunter/pet-aware option and gentler resting-area behavior. Each emote can be enabled/disabled from the **Emote Catalog**, and you can test one with `/chalk emota idle preview`.

## QuestSense

QuestSense can automatically follow accepted quests relevant to your current area using the game's native quest tracking. You can turn it off from Options or with `/chalk quests off`. It does not add quests, abandon quests, or complete anything for you.

Need help? [Troubleshooting](TROUBLESHOOTING.md) or [report a bug](https://github.com/detok/ChalkBox/issues/new/choose).
