# ChalkBox 1.12.0 — MacroForge developer preview

MacroForge is a native **macro design and teaching tool**, integrated as a new ChalkBox settings page with a dedicated build window. No extra addon, no runtime AI and no combat automation.

## Build from your actual character
- Scans learned, active, non-passive abilities through Forever's modern `C_SpellBook` and `C_Spell` interfaces, with graceful fallback for older clients.
- Re-scan on respec/spellbook changes and refuse unlearned spells from previously saved configurations.
- Guided templates: **Engage Target**, **Burst + Trinkets**, **Modifier Keys**, **Manual Sequence**, and **Mouseover Utility**.
- Suggest class-appropriate known abilities. Hunter presets prefer Hunter's Mark, Serpent Sting, Rapid Fire, Auto Shot and pet attack where learned.

## Build safely and confidently
- Select spell roles from a searchable spell list, with real spell icons where available.
- Configure optional pet attack, Auto Shot, on-use trinket slot attempts (13/14), mouseover targeting and Shift/Alt/Ctrl branches.
- Show exact generated macro text, readable limitations and a conservative **255-byte** validation limit. Unreadable/unknown spells never compile.
- Explanations note global cooldown restrictions, unsupported proc/cooldown decisions, trinket uncertainty and `/castsequence` stall risk.
- Save up to **16 recipes per character**. Saving does not alter native WoW macros.
- **Select Text** highlights the macro for the player's **Ctrl+C**; WoW addons cannot copy directly to the OS clipboard.
- **Install New** is a separate, explicit out-of-combat action that creates a new character-specific macro if APIs/space permit, without overwriting any existing macro name. It never silently edits an existing native macro.

## Entry points and compatibility
- **ChalkBox → MacroForge → Open MacroForge**
- `/chalk macro` or `/chalk forge` (also `/chalk forge rescan` and `/chalk forge status`)
- Existing The Bar, CampSense, DropSense, Session Journal, meter, loot protections and per-character saved data remain compatible.
- One ChalkBox folder and a single release ZIP.

## QA gate
Automated Lua 5.1 tests and deterministic addon ZIP checks cover compilation, validation, modern spellbook scanning, templates, save/respec, native overwrite and combat guards, plus standalone UI behavior. **A real-client pass is required** to verify current Forever spellbook data, spell icons, native macro creation, and window layout at various UI scales. Treat this release as a developer preview, not a claim that every class/template has been play-tested.

See [MacroForge design notes](MACROFORGE_DESIGN.md).
