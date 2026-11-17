# ChalkBox — frequently asked questions

**Is this a single addon?**  
Yes. The playable ZIP contains one `ChalkBox` folder and all bundled runtime recipe data. The CurseForge media ZIP contains artwork and documentation, not an addon.

**Which game version?**  
Developed for **WoW Forever**. Retail / regular Classic support has not been verified. Check your client's actual interface and CurseForge's compatible game version choices.

**Does ChalkBox sell items, buy auctions or run combat automatically?**  
No. LootSense is advisory, AuctionSense scans only when you ask, DE estimates are read-only, and MacroForge cannot automate a rotation or bypass Blizzard's GCD/key-press restrictions.

**How does ChalkBox identify which quest needs an item?**  
It first reads the current character's accepted quest objectives and displays the actual quest title and progress. If that doesn't identify the item, ChalkBox has a bundled, offline MIT Classic quest-item reference that may name the related quest. Reference results are labeled accordingly and may differ in Forever. Neither Questie nor QuestieDB needs to be installed. If no exact link exists in either source, the item is marked as quest-class without guessing which quest it belongs to.

**What does Smart QuestSense choose?**  
It manages which *accepted quests* appear in Blizzard's tracker. It does not optimize leveling routes. In a party dungeon with verified quest-match data, it focuses on quests for that **specific instance**. If no match is reliable, it preserves the tracker rather than hide everything.

**Can Discoveries show where an item dropped?**  
For newer **outdoor loot observations**, it can show the player's recorded position when the loot window opened, up to six recent distinct sites. This is not a guaranteed NPC spawn/death location, and old/dungeon observations have no invented coordinates.

**Are the drop percentages official?**  
No. They are personal observed loot-window rates for identified sources. Unlooted kills and uncertain-source drops cannot produce an official drop chance.

**Do AuctionSense prices mean items sold?**  
No, they are current or historical **asking prices**, not confirmed transactions. The AH may throttle scans. AuctionInsights' observed seller mail also does not establish a complete lifetime ledger.

**Does MacroForge overwrite macros?**  
No. You copy the generated text yourself or explicitly choose Install New outside combat. Duplicate-name checks refuse to overwrite native macros. Saved recipes are character-specific.

**Why is the Combat Meter not open after login?**  
It starts closed on purpose. Use `/chalk meter show` or the settings page. Client combat data can be protected.

**Do the QuietGuard filters block invites by default?**  
No. All five start off on fresh installations. Saved ON choices remain on after upgrades. Blizzard's own social blocking settings are independent.

**Can it check GitHub live from the game?**  
Not directly. The Updates page shows the installed version and a copyable releases URL, plus optional comparison with versions observed among other ChalkBox group members.

**How do I update without losing settings?**  
Replace `Interface/AddOns/ChalkBox/` with the newer game ZIP contents; **keep SavedVariables**. Use `/reload`.

**Where are the commands and support docs?**  
[Commands](https://github.com/detok/ChalkBox/blob/main/docs/COMMANDS.md) · [Handbook](https://github.com/detok/ChalkBox/blob/main/docs/USER_GUIDE.md) · [Troubleshooting](https://github.com/detok/ChalkBox/blob/main/docs/TROUBLESHOOTING.md) · [GitHub issues](https://github.com/detok/ChalkBox/issues).
