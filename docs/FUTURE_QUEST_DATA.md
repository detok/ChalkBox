# ChalkBox Future Quest Items — reviewed reference facts

This is **ChalkBox-owned source code containing a small, manually researched
list of individual quest/item facts**. We did **not** import pfQuest,
QuestieDB, VMaNGOS, CMaNGOS, a third-party Lua table, or an exported quest
database. Do not bulk-copy data from any of those projects when expanding it.

Only include a record after checking the exact item ID, quest ID and required
quantity against public quest/item descriptions. Keep individual source URLs
in this document so a maintainer can review the factual claim. The list is not
an exhaustive Classic or Forever quest database.

## First reviewed entries (November 17, 2026)

| Quest ID | Quest | Items (ID x quantity) | Individual public references |
|---|---|---|---|
| 117 | Thunderbrew | Hops 1274 x 5 | [Forever Hops](https://wowforever.gg/en/atlas/knowledge/items/hops-i1274/), [Classic quest](https://www.wowhead.com/classic/quest=117/thunderbrew) |
| 38 | Westfall Stew | Stringy Vulture Meat 729 x 3, Murloc Eye 730 x 3, Goretusk Snout 731 x 3, Okra 732 x 3 | [Forever quest](https://db.icy-veins.com/wow-forever/quests/38), [item 729](https://foreverupgrades.com/item.html?id=729), [730](https://wowforever.gg/en/atlas/knowledge/items/murloc-eye-i730/), [731](https://wowforever.gg/en/atlas/knowledge/items/goretusk-snout-i731/), [732](https://wowforever.gg/en/atlas/knowledge/items/okra-i732/) |
| 418 | Thelsamar Blood Sausages | Boar Intestines 3172 x 3, Bear Meat 3173 x 3, Spider Ichor 3174 x 3 | [Forever quest](https://db.icy-veins.com/wow-forever/quests/418), [3172](https://legacyofwarcraft.com/db/forever/item/3172.html), [3173](https://legacyofwarcraft.com/db/classic/item/3173.html), [3174](https://legacyofwarcraft.com/db/classic/item/3174.html) |
| 92 | Redridge Goulash | Tough Condor Meat 1080 x 5, Crisp Spider Meat 1081 x 5, Great Goretusk Snout 2296 x 5 | [Forever quest](https://db.icy-veins.com/wow-forever/quests/92), [1080](https://legacyofwarcraft.com/db/forever/item/1080.html), [1081](https://legacyofwarcraft.com/db/forever/item/1081.html), [2296](https://wowforever.gg/en/atlas/knowledge/items/great-goretusk-snout-i2296/) |
| 416 | Rat Catching | Tunnel Rat Ear 3110 x 12 | [Forever quest](https://db.icy-veins.com/wow-forever/quests/416), [item](https://www.wowhead.com/classic/item=3110/tunnel-rat-ear) |
| 91920 | Wild Eyes (Horde) | Murloc Eye 730 x 3 | [Forever custom quest](https://wowforever.gg/en/atlas/knowledge/quests/wild-eyes-q91920/) |
| 92110 | My First Real Potion (Alliance) | Murloc Eye 730 x 3 | [Forever custom quest](https://wowforever.gg/en/atlas/knowledge/quests/my-first-real-potion-q92110/) |

**Coverage:** 12 distinct item IDs and 7 quest IDs (14 item→quest uses).
Counts and associations are **historical/public reference facts**, not
proof that this character can accept the quest right now. Forever may
modify classic objectives, availability and quest chains. A live accepted
quest always takes precedence.

## Runtime behavior

- A direct lookup by exact numerical item ID, never by approximate item
  name, loose prefix or tooltip text. A missing record means **unknown**.
- Reports a potential future quest only when that same quest is not known
  to be active, and nonrepeatable quests are not known to be completed.
  Missing native quest status is not fabricated.
- Live Forever quest titles override names in these reference entries.
  A character's faction filters incompatible references where known.
- Existing Core.lua accepted-quest item names, progress, KEEP warnings
  and Blizzard's native gold quest overlays are **untouched**.
- LootSense adds a distinct purple **FUTURE QUEST** note with quantity and
  zone. Its note is informational; it never changes item/vendor actions.
- FutureQuestGlow.lua draws **separate**, mouse-transparent overlays
  anchored to UIParent coordinates; it does not parent textures to, hook,
  move or change protected bag buttons. The initial implementation targets
  **Blizzard's separate bag windows**, suppresses markers in combat and
  does not claim compatibility with combined bags or bag replacements yet.
- Do not expand the UI implementation into general reagent highlighting:
  BagReagents.lua's older taint-prone functionality remains intentionally
  disabled. Existing stored preferences are preserved.

## Adding an item

1. Find a public Forever or Classic quest page describing the **individual**
   quest requirement, with the quest ID and exact required count.
2. Independently verify the item's numeric ID from an item page.
3. Prefer direct Forever evidence; if only Classic reference exists, keep it
   labeled as such, not as a confirmed Forever quest.
4. Check faction, repeatable status and whether the same item satisfies
   multiple quests. Don't assume all quests are Alliance or completed.
5. Add only the factual item/quest relationship to FutureQuestItems.lua.
   Record both source pages here. Avoid importing third-party data tables.
6. Add/extend Lua tests. Check that live accepted quests still show original
   tooltip progress **without** a future-quest label.
7. Test in WoW Forever before merging or publishing; report any mismatched
   quest ID, item ID, repeatability or bag layout.

No new third-party code or binary assets have been added by this feature.
