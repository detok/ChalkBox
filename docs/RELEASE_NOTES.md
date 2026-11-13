# ChalkBox 2.0.2 — settings and release cleanup

This update is about presentation and predictable behavior. The existing modules and saved data are unchanged.

## Settings

The native AddOns settings are now grouped by module instead of displaying 18 unrelated pages in one long list.

- **The Bar** → Modules, Appearance
- **LootSense** → Appearance
- **Adventure Prep** → Toast Appearance
- **Emota** → Race Behavior, Emote Catalog
- Other tools retain their own module pages.

The ChalkBox home page is divided into **Discover & Track**, **Combat & HUD**, and **Personalize & Manage**. Each settings page now shares a consistent heading, accent divider and navigation back to the main ChalkBox page.

This is a navigation change, not a settings reset. Existing module flags, saved layouts, DropSense history, macro recipes and character preferences remain in place.

## Combat Meter

The optional compact meter now starts **hidden at login**, even if it was open when you logged out. Open it from the Combat Meter page or with **/chalk meter show**. It still supports DPS, damage, healing, interrupts, layout and opacity controls, and a manual party report.

## CurseForge preparation

The GitHub description, publishing copy, install guide, command reference, FAQs, release notes, submission checklist and screenshot plan have been updated for the full current feature set.

A separate **ChalkBox-CurseForge-Media-2.0.2.zip** is attached to the GitHub release. It contains all six original vector branding designs, nine PNG exports, the current CurseForge description and related files, and a concise publishing checklist. The 512px project icon meets CurseForge's minimum square PNG size. Promotional illustrations are labeled as such, not passed off as gameplay screenshots.

**Upload ChalkBox-2.0.2.zip as the game addon.** The CurseForge media kit is for project setup and artwork only.

## Testing

- Full Lua 5.1 module tests, including native settings hierarchy and hidden-meter startup.
- ZIP content, load order and reproducibility checks.
- Separate media-kit artwork, PNG signature and listing-content checks.

**In-client verification is still required** for nested Settings navigation and real frame positioning before promoting this as a fully tested public release.

Repository: https://github.com/detok/ChalkBox
