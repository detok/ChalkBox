# ChalkBox 2.2.14 — Quest Navigation Improvements

- **Corrected quest arrow heading** using the client's world-coordinate orientation and a proper north-up navigation arrow.
- **Follow your active quest:** the arrow prioritizes the quest you select in the quest log or Blizzard's actively tracked quest. Switching quests updates navigation. If a selected quest has no known waypoint, it won't quietly switch to another.
- **Find your corpse:** after death, the arrow tries to direct you to your own body using the game's real corpse map marker, then returns to your quest after resurrection.
- **Stabler navigation:** Auto avoids unnecessary switching between equally close quests, respects current-map waypoints and steadies the arrow when you reach a destination.
- Same **minimal floating arrow** with right-click Auto / Next / Hide and quest/distance tooltip. All saved positions and preferences stay intact.

Quest locations and corpse positions depend on the Forever client exposing valid data. Missing directions are explicitly indicated rather than guessed.

Playable addon: **ChalkBox-2.2.14.zip** — https://github.com/detok/ChalkBox/releases/tag/v2.2.14

Full changes: https://github.com/detok/ChalkBox/blob/main/CHANGELOG.md
