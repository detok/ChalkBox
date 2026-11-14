# ChalkBox 2.1.6 — Coordinated UI layout repair

### Full-width Bar + top UI spacing
- Restore the Bar's original edge-to-edge 18px design (no artificial right-hand gap).
- A dedicated top-UI controller shifts **eligible unprotected, default-positioned Blizzard frames** 18px downward, including the minimap and buff groups where the client exposes safe anchors.
- Custom-positioned or protected frames are not moved. Adjustments are deferred during combat, restored when the option is turned off, and do not stack on reload or scale changes.
- The Bar **never** resizes or reanchors Blizzard's `UIParent`. The old root-reservation mechanism stays retired to protect combat and item actions.
- Options > The Bar > **Shift top UI below the Bar** is enabled by default and can be turned off if another UI addon manages those frames.

### AuctionSense / Market
- The tab is shortened to **Market** to fit alongside native Buy, Sell, and Auctions.
- The AuctionSense pane stays inside the Auction House's actual inner content area, above the native tabs and frame border.
- A compact header and controls free space for a **height-aware list**: 1–7 visible results per page, depending on your AH window size. Pager and disclaimer are anchored to the actual pane bottom.
- Market scans, prices, realm/faction separation, row hover details, and SavedVariables are unchanged.

### Kept from 2.1.5
- Emota does not call native emote functions during combat.
- Bag offset and the reagent outlines that modified protected item buttons remain paused. Item Insight and recipe data still work.
- Native DPS meter PARTY/SAY/after-combat reports are preserved.

### Install
Replace the ChalkBox addon folder with `ChalkBox-2.1.6.zip`. Preserve SavedVariables and type `/reload`.

This changes how optional Blizzard top frames are positioned and needs **in-client testing on WoW Forever**. Some protected or customized frames cannot safely be shifted by an addon.
