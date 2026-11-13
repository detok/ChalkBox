# In-game screenshot capture plan

This is the shot list for the second pass and the source of truth for *what the real addon UI must visibly do*. The final media set can be designed around these captures, but it cannot invent screenshots of features that do not exist.

## Before capturing

- Use the actual current **WoW Forever** client and **ChalkBox v1.8.5 or later**.
- Hide unrelated custom UI panels and notifications. Temporarily disable other addons that obscure proof, but don't conceal conflicts when reporting a bug.
- Capture at a consistent display resolution when possible, preferably 1920×1080 or above.
- Avoid publicly visible party/real names, private whispers, guild drama, account information and location. Use harmless demo items/characters where possible.
- Set UI scale for readable text and don't crop tooltip labels off.
- Save a **raw unaltered original** separately; composites can add captions and arrows afterwards.
- No screenshot should claim battle values are readable while protected in combat.

## Capture matrix

| Priority | Screenshot | Set up in WoW Forever | What must be visible |
| --- | --- | --- | --- |
| **1** | **LootSense tooltip** | Open Leatherworking/Cooking, run `/chalk loot scan`, hover a reagent in a learned recipe | Real item link/tooltip with **CHALKBOX | ITEM INSIGHT** and learned recipe evidence, plus actual green inset on the ingredient bag slot |
| **1** | **TrailBar** | Enable bar top, gather a little session XP and gold | Readable 18px **charcoal** strip showing **Bags**, **Gear**, **Rest** and XP/gold, plus a second genuine shot in Edit Mode with tinted draggable regions, some native gameplay in background |
| **1** | **Blizzard meter PRINT** | Use Blizzard's meter after a genuine **party** fight, open its gear menu | **ChalkBox: PRINT top 3 to PARTY** option inside the real native menu; screenshot is usable only if the integration actually appears |
| **2** | **Compact ChalkBox meter** | Enable ChalkBox Combat Meter, select DPS and Last Fight, optionally class icons | Real class-icon rows, player names obscured as needed, header controls |
| **2** | **QuestSense** | Open ChalkBox QuestSense settings with an accepted quest list and native tracker nearby | Mode/limit/status evidence, no fake quest pointers |
| **2** | **Adventure Prep toast** | `/chalk prep test` or real supported notice | Toast near top, text and background visible and unblocked |
| **2** | **Separate bags** | Disable combined bags and open several large bags, set offset 0 then 30 | True before/after view of **vertical ±120** slider with Blizzard 0 centered, proving bag movement if the client confirms it |
| **2** | **Settings home** | `/chalk` | Real two-column ChalkBox native settings home and TrailBar Appearance page |
| **3** | **Emota/QuietGuard** | Open their actual settings; use Emota preview outside combat | Actual Emota Race Behavior page with the race dropdown and real-vs-planned status, plus genuine emote preview if possible |

## Suggested narrative order for CurseForge gallery

1. Product logo / title hero (new artwork, not a screenshot)
2. “Know what to keep” — LootSense
3. “All the useful numbers, barely any screen space” — TrailBar
4. “Your Blizzard meter, plus PARTY printing” — native meter integration
5. “Keep your quests organized” — QuestSense
6. “Camping reminders without the spam” — CampSense
7. “Customize the rest” — settings and compact meter
8. “Individual bags stay within view” — optional offset, only if validated

## Compositing directions

- Present capture in a neat, honest frame with a short label and no fake gameplay HUD.
- Use callout arrows/circles in **added editorial margins**, not a simulated WoW tooltip.
- Keep contrast sufficient for small thumbnail sizes.
- If a feature cannot be shown due to client restrictions, **replace that image with a general feature description** rather than generating a fictional “working” screenshot.
- Text overlays: one main label and no more than one short support line per image.

## Upload/approval gate

Artwork alone isn't enough to prove a gameplay feature. Compare each proposed caption with the actual capture and `../copy/FEATURE_PROOF.md` before marking the media file publishable.
