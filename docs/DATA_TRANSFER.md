# Move AuctionSense and Discoveries between computers

ChalkBox ships one installable ZIP with two addon folders: `ChalkBox` and
`ChalkBoxTransfer`. Keep **both** folders enabled. The second one is a
small SavedVariables file bridge, not a second UI or gameplay addon.

## Export on computer A

1. In WoW, open **Options → AddOns → ChalkBox → Data Transfer**.
2. Click **Export Data**.
3. Type `/reload` or log out. WoW cannot write arbitrary files while running;
   it writes the transfer file during logout/reload.
4. Exit WoW completely.
5. Copy the single file
   `WTF/Account/<ACCOUNT>/SavedVariables/ChalkBoxTransfer.lua`
   to your other computer (same `WTF/Account/<ACCOUNT>/SavedVariables/`
   location). Back up any transfer file already there before replacing it.

## Import on computer B

1. Ensure WoW was **closed** when you copied the file.
2. Launch WoW and log in to the **same realm and character**.
3. Open **ChalkBox → Data Transfer** and click **Import & Merge**.
4. Continue playing normally. To move your new observations back, click
   **Export Data** on B, `/reload`, close WoW, copy the **same transfer file**
   back to A, then click **Import & Merge** on A.

## What merges

- AuctionSense last scanned market snapshots, including bounded low-ask history.
  The more recent market snapshot is authoritative; older scan samples are
  preserved for items in both snapshots.
- Verified auction seller-invoice receipts. Stable invoice signatures prevent
  reimporting the same sale twice. New receipts are added up to the journal cap.
- This character's DropSense observed loot/area/source counters. For every
  count, the higher number is kept. Importing the same file again does not
  raise it a second time, and a smaller file cannot lower what you already have.
  Map positions are combined without pretending to be creature death locations.
- This character's confirmed flight discoveries.

The file **does not** contain character UI settings, layouts, quest watches,
auction posting settings, bag data, session statistics, or account credentials.

Drops and flight paths are deliberately limited to the same character and
realm. Account-wide market scans and sale invoices can still merge when
importing on a different character.

## Limits and cautions

- The file is not created until you reload or exit after export.
- The Import button reads the file **already loaded at login**. You cannot
  copy a new file into the folder while WoW is running and expect an immediate
  import.
- This is a **merge**, not a replacement. Before anything is changed, ChalkBox
  stores a backup in `ChalkBoxDB.transferBackup` and
  `ChalkBoxZoneDB.transferBackup` (and keeps the previous backup one step
  back). The same export may be imported repeatedly without double-counting
  sales or discovery counters.
- Unknown item variants are not converted into confirmed sales.
- WoW may truncate saved market history and sales to their normal retention
  limits. Import cannot recover older data that was already pruned.
- Only accept a transfer file from your own installation. SavedVariables are
  executable Lua data; never run untrusted files sent by strangers.

The new transfer system is experimental until verified on the WoW Forever
client with both computers. Keep a backup of the original `WTF` folder before
your first import.
