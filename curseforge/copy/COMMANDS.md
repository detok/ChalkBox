# ChalkBox 2.0 — command reference

Commands operate inside the **one ChalkBox addon**.

| Command | Action |
| --- | --- |
| `/chalk`, `/cb` | Open ChalkBox settings |
| `/chalk macro` | Open MacroForge wizard |
| `/chalk forge rescan` | Refresh learned spellbook abilities |
| `/chalk forge status` | Current MacroForge scan/saved-build status |
| `/chalk drops map` | Open Discoveries independent of map button |
| `/chalk drops map status` | Diagnose map frame/button/visibility |
| `/chalk drops map reset` | Return the dragged map button to its default location |
| `/chalk drops map on` / `off` | Show/hide map button |
| `/chalk drops on` / `off` | Start/stop personal loot-window recording |
| `/chalk drops status` | Inspect tracked items, sampled windows and mapped zones |
| `/chalk drops tooltip on` / `off` | Show/hide observed-loot notes in native loot-window tooltips |
| `/chalk drops chance 5 20` | Example probability calculator for a **user-supplied** 5% independent chance across 20 tries |
| `/chalk update` | Show locally installed ChalkBox version and a real GitHub Releases link |
| `/chalk session` | View this session |
| `/chalk session last` | View previous saved session |
| `/chalk loot status` | LootSense, profession knowledge and read API status |
| `/chalk loot scan` | Refresh learned-recipe knowledge after opening a crafting window |
| `/chalk keep [item]` / `forget [item]` | Add/remove a personal KEEP protection |
| `/chalk bar status` | Inspect The Bar |
| `/chalk bar stat bagvalue on` | Enable bag vendor resale module |
| `/chalk bar bagvalue junk` / `total` | Flip gray-junk vs all equipped bag contents |
| `/chalk bar stat repair on` / `off` | Repair module visibility |
| `/chalk bar repair status` | Inspect repair learning samples |
| `/chalk bar repair reset` | Clear **this character's** learned repair sample history |
| `/chalk quests status` | Show QuestSense status |
| `/chalk quests refresh` | Queue native quest-watch refresh |
| `/chalk prep` | Inspect camp state |
| `/chalk prep test` | Preview the camp reminder toast |
| `/chalk meter status` | Inspect meter availability |
| `/chalk meter print` | Manually print a supported combat summary to normal PARTY chat |
| `/chalk theme` | Global Appearance settings |
| `/chalk help` | In-game help |

**Note:** DropSense uses observed *loot windows*, not every kill. Server drop tables and exact per-mob loot chances are not exposed. MacroForge only designs macros: it does not automate rotations or bypass GCDs.
