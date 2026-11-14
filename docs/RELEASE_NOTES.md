# ChalkBox 2.0.6 — The Bar menu refresh

The Bar's right-click controls are now shorter, grouped by purpose, and color-coded.

- Right-click a visible stat for only its own controls: **Show/Hide**, **Move**, **Align**, and **Bar settings**. Bag value and repair keep their own context actions.
- Right-click empty Bar space for global **Modules**, **Position**, **Edit layout**, **Reset layout**, **Stat settings**, and **Appearance**.
- Gold headings and selected positions; cyan navigation; green enabled; gray disabled; amber reset/hide. Shorter option labels and action messages.
- Tested both modern Blizzard context menus and the older EasyMenu fallback.
- Preserves all current metrics, saved layout and alignment, existing module settings, and the 2.0.4 bag-opening performance improvements.
- Keeps the Discoveries 2.0.5 fixes intact.

**Installation:** Replace the existing `ChalkBox` addon folder with the one inside **ChalkBox-2.0.6.zip**, then `/reload`. Do not delete SavedVariables.

**Verification:** The Lua 5.1 and packaging regression suite runs on GitHub Actions. Please verify the appearance of both right-click menus in the actual WoW Forever client.

**ChalkBox-CurseForge-Media-2.0.6.zip** is the separate listing-art and screenshot bundle, not the installable addon.

Built for WoW Forever; unverified on Retail and Classic Era. Maintained by Detok Whitemaine.
