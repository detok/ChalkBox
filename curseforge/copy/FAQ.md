# Frequently asked questions

**Is this one addon or several?**  
One. Install a single ChalkBox folder. The recipe reference data is included.

**Which WoW client does it support?**  
ChalkBox is built for WoW Forever. Retail and Classic Era haven't been verified. Check the client version available in CurseForge before submitting a file.

**Can ChalkBox show official drop rates?**  
No. DropSense records items seen in readable loot windows. An observed percentage applies only to clearly identified creature sources with a usable sample. It isn't the server's drop table or a rate for every kill.

**Can I move the Discoveries button?**  
Yes. Drag it on the world map. Right-click to reset, or use /chalk drops map reset. If the button isn't visible, /chalk drops map opens the browser independently.

**Does MacroForge run my rotation?**  
No. It creates macros from learned spells. You still press the buttons, and WoW's normal cooldown and secure-action rules apply. Saved recipes can be regenerated after you change talents.

**Will MacroForge overwrite my existing macros?**  
No. Copy the generated text yourself, or explicitly choose Install New outside combat. If a macro with that name already exists, ChalkBox refuses to replace it.

**Why is the small DPS meter not visible after login?**  
It starts closed by design. Type /chalk meter show or open it from Combat Meter settings. It doesn't delete fight data when hidden.

**Will ChalkBox auto-sell junk or spend my gold?**  
No. Bag value and repair figures are informational. A repair estimate marked ~ isn't a merchant's exact quote.

**Where is my history?**  
WoW saves ChalkBox's data in its SavedVariables. Session Journal and DropSense history are per character. Keep those files when upgrading.

**Does the Updates page check GitHub in-game?**  
No. WoW Lua can't make a direct HTTPS request. It displays your installed version and a release link. The optional group version comparison detects only newer ChalkBox versions seen among group members.

**How do I adjust the settings?**  
Type /chalk. Module pages are grouped in the main menu. Expand The Bar, LootSense, Emota, or Adventure Prep for their additional pages.

**Where can I report a bug?**  
https://github.com/detok/ChalkBox/issues — include the ChalkBox version, your client build, reproduction steps and any Lua errors.
