# ChalkBox 1.10.0 — The Adventure Companion

This release combines a global visual identity with more precise camping advice, opt-in loot-window drop observations and a persistent Session Journal. It is still **one addon, one download**.

## Global Appearance

- New **ChalkBox → Global Appearance** native settings page: Charcoal / Midnight / Slate / Custom backgrounds, Gold / Teal / Neutral accents, shared background-strength slider, custom RGB channels.
- Applies to The Bar, compact CampSense toast, Combat Meter background, buttons and rows, and new Session Journal window. Does not change Blizzard UI or gear rarity.
- Keeps existing per-module opacity controls: the shared strength multiplies background opacity, so local preferences are not erased.

## Adventure Prep & CampSense

- Reduced blue 490×85 alert to a compact 430×72 charcoal toast with short action titles and independently adjustable *background* opacity. Text stays legible.
- Prioritize actual Camp Benefits status, Boosted Rest/tent readiness, basic camp kit quantities, wood/flint and supported Hunter pet happiness; no false missing-Flint warning while ready-to-use kits are available.
- Fix previously unused **confirmed missing Camp Benefits** reminder branch.
- Silence unchanged alerts by default; optionally repeat unresolved notices after the chosen 20/45/90-minute interval.
- Keep tent/rested XP completely separate from the Camp Benefits aura; never claim a missing buff means the tent failed.
- Existing manual checklist, draggable/lockable toast and preview remain.

## DropSense (opt-in, local-only)

- New **ChalkBox → DropSense** settings: enable sampling, optional notes *only in native loot-window item tooltips*, watch/unwatch up to 32 item IDs or links, and a percent/attempt probability calculator.
- Sample read-only loot windows, count observed hits and item stacks, and save per-character observations across sessions. Tooltip shows successes, windows sampled and a Wilson 95% interval.
- Drop percentages are **frequency across loot windows ChalkBox actually observed**, not confirmed mob-specific or server drop rates. Not all loot windows represent equivalent opportunities.
- `/chalk drops on|off`, `watch [item]`, `unwatch <id>`, `status`, `reference <id> <percent>` and `chance <percent> <attempts>`.
- A player-provided reference percentage is clearly labeled as such; **there is no pretend official Forever drop table**. Server loot tables are not exposed to ordinary addon APIs.
- Does not count unseen kills, automate looting, or rely on external downloads.

## Session Journal

- New **ChalkBox → Session Journal** page and independent native-styled window with Current / Older / Newer buttons.
- Tracks event-confirmed XP gained, levels, net gold, quest turn-ins, optional sampled loot windows/items, camping reminders and actual repair merchant quotes. Shows a compact top-observed-items summary when available.
- Keeps the last 20 finished sessions per character and starts a fresh session on next login; previous adventures remain readable.
- `/chalk session` and `/chalk session last` open the recap window.
- No invented kill count, auction prices, combat data or unsupported history. Drop details require explicitly enabling DropSense.

## LootSense fine controls

- Keep the existing master on/off and independent verified-reagent markers.
- Under **LootSense Appearance**, independently show/hide learned crafting uses, potential/unverified use hints and camping ingredient notes. Quest/personal KEEP protections remain prioritized when item advice is on.

## Compatibility & tests

- Existing The Bar layouts and single-character repair-learning history remain in the same saved variable keys.
- No separate app, addon, map assets, server sync, authentication or automatic transactions.
- Lua 5.1 regression coverage added for themes, individual toggles, sampled loot windows and deduplication, probability calculations, session persistence/window, and improved camp decision logic. Github CI validates single-addon ZIP packaging.
- Actual Forever-client visuals, loot-window tooltip owners and long-play persistence should still be verified in-game.
