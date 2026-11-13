# Recipe data, attribution and how we avoid false item advice

## Two separate kinds of evidence

**1. Character-verified recipes (built into ChalkBox).** ProfessionSense observes the actual profession screens available to your character and can remember an ingredient, recipe name and quantity if the client exposes them. This is the **only** source allowed to label an item as needed for a **known recipe**.

**2. Offline possible recipes (optional).** `RecipeAdvisor.lua` optionally calls the public API of [LibProfessionDB](https://www.curseforge.com/wow/addons/libprofessiondb) by **Pmptasty**. This can give broader Forever recipe candidates: recipes you haven't learned yet, and recipes owned by other professions. They are labeled **POTENTIAL USE** or **OTHER PROFESSION**, never as known.

## Licensing

ChalkBox contains a first-party API adapter but **no copied LibProfessionDB source, content dataset or dependencies**. Install the upstream addon independently according to its own instructions and license. If we decide to bundle third-party recipe data in a future release, we must first audit the exact files, version, dependencies, license notices and provenance, and preserve all required credits.

ChalkBox does not scrape Wowhead, download recipe tables from websites during play or attempt to bypass WoW addon API restrictions.

## Coverage and limits

- The current adapter is a **prerelease** feature: its exact compatibility with the upstream runtime and your Forever build still requires in-game validation.
- Recipe window scans can be incomplete if a profession isn't opened, a recipe is hidden, or a WoW API is unavailable.
- Some addon APIs expose item IDs, others only item names; ChalkBox chooses the most reliable available key.
- Bag counts exclude inaccessible storage and can differ from what an account bank/alt owns.
- You should never see **SAFE TO SELL** based solely on the absence of an index match.

Report bad recipe facts or API differences with game/version and concrete item/recipe IDs. Details: [Troubleshooting](TROUBLESHOOTING.md).
