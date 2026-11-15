# ChalkBox 2.2.7 — MacroForge workbench polish

## MacroForge — cleaner, easier to follow
The familiar two-column MacroForge wizard now sits over the same native World Map atlas used by Discoveries, under a readable dark theme glaze. If the atlas is unavailable on a Forever build, it safely falls back to solid charcoal. Thin inset frames organize the purpose templates, spell assignments, spellbook, options, macro preview, saved builds and macro naming without replacing the native controls.

The macro preview is now a true multiline edit box in a clipped, scrollable framed area. Long generated text grows inside the scroll child rather than escaping a single-line InputBox border. Ctrl+C / Select Text / explicit Install New still use the original macro pipeline. The active assignment remains highlighted. The saved-build warning text now has a bounded, wrapped space with a gap before the macro-name section.

## The Bar — finish editing from right-click
Right-click empty Bar space while the editor is active to choose **Done editing**. Right-click a stat during Edit Mode still cycles its text alignment. All existing drag positions, alignment and Bar preferences remain unchanged.

## MacroForge shortcut under AddOns
Under **Options → AddOns → ChalkBox → MacroForge**, there is an opt-in **Show MacroForge in AddOn Compartment** checkbox (OFF by default). On supported clients, this adds a separate MacroForge shortcut next to the existing ChalkBox entry in the minimap AddOns dropdown. The launcher opens the existing editor only on click. If the native registration API is unavailable, the preference is saved without unsafe menu manipulation. Blizzard does not expose a dependable public unregister method, so turning the shortcut off after registering it requires `/reload`.

## Safety and verification
- Macro generation, learned-spell scanning, user recipes, installed macros, GCD/combat restrictions, quests and auction logic are unchanged.
- No native World Map frames, protected Blizzard menus or saved character preferences are modified. Only the opt-in `ChalkBoxDB.macroCompartment` Boolean is new.
- Automated Lua 5.1 UI tests cover framed sections, active selection, long preview scrolling, bounded warnings, map-art fallback, compartment opt-in, Bar editor exit and original copy/install actions.
- Visual alignment and AddOn Compartment availability still require a live WoW Forever client check.

Install `ChalkBox-2.2.7.zip` over the existing ChalkBox folder, preserve SavedVariables, and type `/reload`.
