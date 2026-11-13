# MacroForge — character-aware macro wizard

## Product promise

**Learn what your buttons really do. Build macros from the spells you already have.**

MacroForge ships inside ChalkBox; no extra addon, service, LLM or runtime dependency. It is an optional native settings page and a dedicated movable creation window. **It is not a GCD bypass or combat automation engine.**

The core design avoids overpromising "one-button rotations." It makes the legitimate macro language approachable for players at every level, and clear enough for serious macro users to trust.

## Implemented in v1.12

- Read class and **currently learned active spellbook abilities** using modern Forever \`C_SpellBook\` and \`C_Spell\`, with safe older-client fallback.
- Omit **future, passive and off-spec** entries. Use localized game spell names and icons when provided; detect stale saved choices after a respec.
- Guided templates: **Engage Target**, **Burst + Trinkets**, **Modifier Keys**, **Manual Sequence**, and **Mouseover Utility**. Every option is selectable; presets merely propose known spells.
- Character-specific Hunter opener preferences (Hunter's Mark, Serpent Sting, Rapid Fire, Auto Shot, pet attack); other classes receive relevant starting priorities where known. Unknown classes still get a spellbook-based wizard.
- Assign up to four modifier-key spells or three manual sequence spells. Optional Shift/Alt/Ctrl, target/mouseover conditions, trinket 13/14 attempts and Hunter Auto Shot.
- **No automatic proc or cooldown conditionals**: WoW's secure macro conditionals cannot choose a spell because its cooldown finished or a particular proc appeared.
- Cautious warnings: modifier semantics, sequence stall risk, multiple GCD attempts, trinket cooldown/passive effects, missing equipped trinkets and unsupported spells.
- **255-byte conservative limit**, clear validation errors and no implicit truncation. The current character's spells are revalidated every time a saved recipe is generated or installed.
- Save up to **16 named macro recipes** per character; load and regenerate without storing a stale, blindly executable macro string. Saved configurations live in existing character SavedVariables.
- **Select Text → Ctrl+C** highlights the exact macro in a selectable editbox. Addons cannot directly set the operating system clipboard: WoW still requires Ctrl+C and pasting into \`/macro\`.
- **Install New** may create a new character-specific native macro **only on an explicit click outside combat**, when the client exposes the required macro API. It checks for existing names, refuses to overwrite them, and reports full-slot or API errors. It never silently edits or deletes a native macro.
- Full \`/chalk macro\` or \`/chalk forge\` shortcut. No minimap clutter or combat overhead.

## Rules by template

| Mode | Generates | Caveat |
| --- | --- | --- |
| Engage | \`/petattack [harm,nodead]\` (optional), a chosen \`/cast\`, optional \`/cast !Auto Shot\` | Pet and shot lines are separate attempts |
| Burst | Optional \`/use [combat] 13\`, \`/use [combat] 14\`, and exactly one \`/cast\` | Slots do not guarantee activation; shared cooldowns apply |
| Modifiers | A **single** \`/cast\` conditional with explicit Shift/Alt/Ctrl and default \`[nomod]\` | The player chooses which branch |
| Sequence | \`/castsequence reset=target/6 ...\` | One successful step/press; cannot skip failed or cooling-down spells |
| Mouseover | Explicit friendly mouseover or hostile mouseover fallback | Never automatically guesses healing vs damage effects |

No sequence automatically changes at a specified millisecond interval or based on target health. No API bypass, hidden secure frame, auto-spellcast, external rotation service or injection of arbitrary Lua commands.

## Implementation

- \`MacroForge.lua\` — scan learned spells, class preferences, compiler, validator, duplicate-name guard, native install, saved recipes.
- \`MacroForgeUI.lua\` — lazy-loaded, themed, movable spell-selection and build window with read-only generated preview, selection/copy instruction, library and explicit install.
- \`ChalkBox_Settings.lua\` — a small **MacroForge** category to open the builder and rescan.
- \`LootSense.lua\` — \`/chalk macro\`, \`/chalk macros\`, \`/chalk forge\` shortcuts.
- Event-driven spellbook cache invalidation on \`SPELLS_CHANGED\`, \`PLAYER_TALENT_UPDATE\` and \`ACTIVE_TALENT_GROUP_CHANGED\`.

## Manual in-client acceptance checklist

- [ ] Spellbook scan sees the current class, correct ranks, real icons and Forever-only abilities (e.g., Storm Form where actually learned).
- [ ] Unlearned, passive, future and inactive/off-spec spells do **not** appear as cast choices.
- [ ] Hunter: pick mark, sting, Rapid Fire; verify Shift, Alt and sequence behaviors with a target dummy and ordinary keypresses.
- [ ] A trinket without on-use effect displays a warning, with no false promise of activation.
- [ ] Full macro can be selected with Ctrl+C and pasted into native \`/macro\` without editing or truncation.
- [ ] Optional **Install New** creates one character-only macro; never overwrites an existing macro and refuses during combat.
- [ ] Save recipe, relog, load; retrain/respec and verify an unlearned selection is flagged rather than cast.
- [ ] Window title, buttons, spell rows, preview, saved builds and tooltip warnings remain readable at 75–125% UI scale and smaller screens.
- [ ] No regression to The Bar, QuestSense, Combat Meter, CampSense, DropSense, loot protections or native game UI.

**Release posture:** GitHub prerelease for testing. Do not claim this is a full "one button kill" rotation system or promote it as CurseForge production ready before the live client QA above is completed.
