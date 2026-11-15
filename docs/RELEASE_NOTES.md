# ChalkBox 2.2.16 — QuestSense Tracker Menu and MacroForge beside /macro

## QuestSense, straight from Blizzard's tracker

**Right-click the header of Blizzard's built-in quest tracker** to open a small, optional ChalkBox context menu when that native header accepts mouse hooks.

- **QuestSense Settings:** opens ChalkBox → QuestSense under Blizzard's AddOns options.
- **Off:** disables QuestSense's automatic watch management (without wiping your own manual watch selections).
- **Smart:** enables Smart tracking, including supported dungeon quest focus.
- **Nearby:** enables the current-zone-only quest mode.
- **Navigation On/Off:** toggles the existing small quest arrow without changing Blizzard's super-tracked selection.

The menu is attached with a non-destructive **HookScript**, only on Blizzard's real tracker header (or its existing parent tracker where a header isn't exposed). Quest-row actions, left-clicks and Blizzard's own menus are not replaced. Existing modern `MenuUtil` and legacy `EasyMenu` are used when available. If a client has neither, it safely opens the regular QuestSense settings instead. Some Forever UI versions or third-party replacement trackers may not expose a safe hook; use `/chalk quests` or the existing AddOns settings in that case.

## Three arrow appearances, one navigation system

Under **Options → AddOns → ChalkBox → QuestSense → Navigation**, choose:

- **Original WoW:** `Interface\\Minimap\\MinimapArrow`, the first ChalkBox arrow appearance.
- **Blizzard Navigation:** the newer `Navigation-Tracked-Arrow` atlas, with the original minimap glyph as a compatibility fallback.
- **ChalkBox HD:** the bundled original 256px transparent TGA version.

The previous `classic` and `hd` character preferences are preserved. `/chalk nav original`, `/chalk nav classic`, or `/chalk nav hd` switch the same graphic from chat. Arrow rotation, proximity color changes, yards below the arrow, corpse/quest priorities, positioning and right-click Auto / Next / Hide behavior are unchanged.

## MacroForge in Blizzard's own macro editor

When the native `/macro` window (`MacroFrame`) is available, ChalkBox adds a modest **MacroForge** tab just above its frame. Click to open the existing fully featured MacroForge workbench as an **adjacent sidecar** when screen width permits. Click again to close it. Closing Blizzard's macro editor also closes only a docked Forge workbench.

**No native macro list, editor, selection, character/account tab, icon, or Save button is modified.** This integration simply opens the existing ChalkBox workbench. Macro installation remains a separate explicit action, outside combat, and never overwrites an existing macro. The standalone `/chalk macro` command still works.

If the macro editor is not exposed on that client, or the screen is too narrow for both full windows, nothing is forced to move or shrink: the normal standalone Forge still works. The addon does not replace the native macro UI or require any other addon.

## Testing and limitations

- Lua 5.1 regression tests cover header-only native hooks, modern/legacy/no-menu clients, Off/Smart/Nearby and navigation commands, three arrow styles, MacroFrame load-on-demand attachment and dock/undock/close behavior.
- Retain all SavedVariables and existing quest watches, native macros and MacroForge saved builds.
- **Actual Forever-client confirmation is still required** for exact tracker header accessibility and available on-screen docking space. Keep this a Beta build until that is confirmed.

Install `ChalkBox-2.2.16.zip` over your previous addon folder, preserve SavedVariables, and type `/reload`.
