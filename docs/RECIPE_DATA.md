# Recipe data and redistribution

## One download, no dependencies

ChalkBox 1.6 bundles a local Forever-only snapshot of **LibProfessionDB 1.9.1**. WoW loads its static recipe records directly from `ChalkBox/Libs/LibProfessionDB-1.0/Data/`, before ChalkBox's own modules. The bundle includes **2,511 WoW Forever recipes** (ten professions, including the Forever additions), without the other game-flavour trees.

The original library was authored by **Pimptasty** and is available on [CurseForge](https://www.curseforge.com/wow/addons/libprofessiondb/files/9095167) under the **MIT license**. The specific Forever-only data files and library implementation used in this release were obtained from the [ComradeCraft vendored snapshot](https://github.com/JF10R/comradeCraft/tree/master/ComradeCraft/Libs/LibProfessionDB-1.0), which identifies itself as LibProfessionDB 1.9.1, and matched against the author's published API and data description.

Original source: `ComradeCraft/Libs/LibProfessionDB-1.0/LibProfessionDB-1.0.lua` at GitHub revision `cdf9be8d81713ddfb92fe44aef85e895b2893915`, with its Forever data files.

**License notice:** `ChalkBox/Libs/LibProfessionDB-1.0/LICENSE`, whose original Git blob SHA is `728b5b0047107a2cbd70176d70ac7840a23ecff1`. It states **Copyright (c) 2026 Pimptasty** and is included unchanged in this repository and the installable ZIP. The library's implementation blob SHA is `f88a046c61bb4e3a3fda5172f2265639ee921d1d`.

The versioning loader **LibStub** is authored by the WoW Ace community and its original source explicitly places it in the **public domain**. It ships at `ChalkBox/Libs/LibStub/LibStub.lua`.

**ChalkBox's original code** is copyright Detok and MIT-licensed separately. The ZIP includes both MIT notices.

The original full LibProfessionDB package lists Ace3 and VersionCheck as dependencies for its optional addon-version-check features. This embedded Forever-only database path uses the LibStub registration and data-loading functions directly and deliberately does **not** invoke those optional features, so those additional addons are not bundled or required.

## How relevance works

The library is a **static catalog**, not proof your character learned a recipe. `ProfessionSense` also records ingredient relationships from the player's actual open profession window and marks them **known** only when observed. The combined decision engine labels evidence:

1. Accepted quest or personally protected item — high priority.
2. **KNOWN RECIPE** — recipe learned by this character and successfully observed in the client's profession window.
3. **POTENTIAL USE** — database shows a recipe relevant to this character's professions, **not confirmed learned**.
4. **OTHER PROFESSION** — catalog use in a profession the character does not currently have; doesn't imply keep/hoard.
5. Verified camping use or broad profession-family hint, as available.

No result that only says "unknown" is ever converted to "safe to sell." Bag counts are from currently accessible character inventory APIs, not a promise about bank/alt stock.

## Coverage boundaries and sources

LibProfessionDB's Forever data originates primarily from Blizzard's game-client data. Some secondary information (trainer/source/hidden-recipe relationships) is borrowed from Classic and explicitly flagged in the original library; ChalkBox's current item relevance uses **recipe reagents**, not those uncertain source claims. Recipe names in the embedded core are resolved through your live client's spell/item APIs when possible; unavailable names are disclosed as such.

We do **not** scrape Wowhead at runtime, download datasets during play, or redistribute proprietary files. Please report any incorrect relation with the item ID, recipe spell ID and game build.
