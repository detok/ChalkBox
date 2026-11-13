# ChalkBox FAQ

### What is ChalkBox?

An all-in-one quality-of-life addon focused on **WoW Forever**. It combines item/recipe hints, XP and gold tracking, accepted-quest watches, camping reminders, optional combat meters, invite protections and character emotes.

### Is it compatible with Retail or Classic?

**WoW Forever / Camelot** is the current supported target. Do not assume compatibility with other flavors. The package includes a Forever-specific `ChalkBox_Camelot.toc`.

### Does it need a second recipe addon?

No. The download includes a credited **2,511-recipe Forever catalog** and its supporting libraries. A catalog recipe is a *potential use*; learned-recipe claims come from the character's actual profession data.

### Does LootSense automatically sell or delete items?

No. It gives relevant tooltip advice and supports a personal keep list; unannotated items are not guaranteed safe to sell.

### Why does an item say POTENTIAL USE?

That comes from the bundled catalog and is **not proof** you learned the recipe. Open your profession UI and try `/chalk loot scan` and `/chalk loot status`.

### Does QuestSense include quest arrows, map pins or navigation?

No. It helps manage accepted-quest watches in Blizzard's built-in tracker. It doesn't invent route coordinates or accept/complete quests for you.

### Can I use Blizzard's damage meter instead of the ChalkBox window?

Yes. Type `/chalk meter hide` to hide ChalkBox's own meter. In compatible Forever clients, the Blizzard meter's gear menu gains **ChalkBox: PRINT top 3 to PARTY**.

### Why didn't PRINT send a message?

It is manual, available after combat in a **normal party**, and refuses reports when combat names/totals remain protected by the client. It never redirects to public chat or raids. Try `/chalk meter native status` and read the local error feedback.

### Does RESET affect Blizzard's meter history?

Yes. Reset in ChalkBox's compact meter requests confirmation before resetting **shared Blizzard combat sessions**. The native gear-menu PRINT does **not** reset anything.

### Does ChalkBox replace my bags or action bars?

No. The optional **0–80-point separate-bag offset** merely nudges Blizzard's regular bag layout; combined bags stay normal. Native Edit Mode's **Always Show Buttons** toggle for Action Bar 2 is a **WoW feature**, not a ChalkBox feature.

### Can TrailBar show free slots, gear durability, rested XP, latency and pet health?

**Yes—new in v1.8.6.** Open **ChalkBox → TrailBar Stats** to toggle nine optional widgets or choose Balanced / Minimal / All. Bag data includes specialized bag space, gear is weighted durability, and rested XP is a percent of one level. Hunter pet health shows unavailable instead of reading secret combat data. Some stats automatically hide on narrow screens and reappear when there is room.

### Why is one of my TrailBar stats hidden?

It's either disabled in settings, there isn't enough room for it at your current UI width, or the client hasn't provided readable data. Run `/chalk bar stats` to check enabled versus visible modules.

### Does a Camp Tent keep the Camp Benefits buff active?

No. Forever's Camp Tent can grant a rested-XP refill independently of ongoing camp buffs. ChalkBox handles those indicators separately where available and has a manual acknowledgement option.

### Does Emota randomly emote out of the box?

The automatic-emote master option defaults **off**. Enable it in settings and adjust which emotes are allowed.

### Does QuietGuard block my friends' party invites?

Party invites are **opt-in**; guild and duel protections are on by default. Check individual settings, which may also depend on Forever client APIs.

### Does ChalkBox need an account, external service or AI?

No. ChalkBox runs locally as a Lua addon and stores preferences in the game SavedVariables. It doesn't require a separate account or internet-based AI inference.

### Do I have to download it from CurseForge?

**No. GitHub is the primary direct download home:** https://github.com/detok/ChalkBox/releases. A CurseForge page is an additional discovery and installation option, not an exclusive download host.

### Where can I report a bug?

https://github.com/detok/ChalkBox/issues — include version, Forever build, reproduction steps, exact Lua error/tooltip text and relevant screenshot.

### Is the addon stable?

It is marked a **public prerelease**. Automated Lua 5.1 tests run on GitHub, and in-game behaviors relying on protected Forever APIs may need further testing.
