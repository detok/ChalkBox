#!/usr/bin/env python3
"""Build one deterministic, immediately installable ChalkBox ZIP."""
from __future__ import annotations

import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "ChalkBox"
DIST = ROOT / "dist"
FILES = (
    "ChalkBox.toc",
    "ChalkBox_Camelot.toc",
    "LICENSE",
    "Libs/LibProfessionDB-1.0/LICENSE",
    "Libs/LibStub/LibStub.lua",
    "Libs/LibProfessionDB-1.0/LibProfessionDB-1.0.lua",
    "Libs/LibProfessionDB-1.0/Data/Alchemy.lua",
    "Libs/LibProfessionDB-1.0/Data/Blacksmithing.lua",
    "Libs/LibProfessionDB-1.0/Data/Cooking.lua",
    "Libs/LibProfessionDB-1.0/Data/Enchanting.lua",
    "Libs/LibProfessionDB-1.0/Data/Engineering.lua",
    "Libs/LibProfessionDB-1.0/Data/Firstaid.lua",
    "Libs/LibProfessionDB-1.0/Data/Fishing.lua",
    "Libs/LibProfessionDB-1.0/Data/Leatherworking.lua",
    "Libs/LibProfessionDB-1.0/Data/Mining.lua",
    "Libs/LibProfessionDB-1.0/Data/Tailoring.lua",
    "Libs/LibProfessionDB-1.0/Data/RecipeItems.lua",
    "Libs/LibProfessionDB-1.0/Data/HiddenRecipes.lua",
    "Libs/LibProfessionDB-1.0/Data/AcquireMethods.lua",
    "Libs/LibProfessionDB-1.0/Data/Sources.lua",
    "Libs/LibProfessionDB-1.0/Data/SourceNames.lua",
    "Core.lua",
    "ProfessionSense.lua",
    "RecipeAdvisor.lua",
    "CampAura.lua",
    "ReminderToast.lua",
    "CampSense.lua",
    "LootSense.lua",
    "QuietGuard.lua",
    "PersonalityContext.lua",
    "Emota.lua",
    "QuestSense.lua",
    "TrailBar.lua",
    "CombatMeter.lua",
    "ChalkBox_Settings.lua",
    "assets/Icon.tga",
)


def version_of(path: Path) -> str:
    match = re.search(r"^## Version:\s*(\S+)\s*$",
                      path.read_text(encoding="utf-8"), flags=re.MULTILINE)
    if not match:
        raise ValueError(f"No version declared in {path}")
    return match.group(1)


def build() -> Path:
    versions = {version_of(SOURCE / name) for name in FILES if name.endswith(".toc")}
    if len(versions) != 1:
        raise ValueError(f"TOC versions differ: {versions}")
    version = versions.pop()
    DIST.mkdir(parents=True, exist_ok=True)
    for stale in DIST.glob("ChalkBox-*.zip"):
        stale.unlink()
    output = DIST / f"ChalkBox-{version}.zip"
    with ZipFile(output, "w", compression=ZIP_DEFLATED) as archive:
        for relative in FILES:
            source = SOURCE / relative
            if not source.is_file():
                raise FileNotFoundError(source)
            info = ZipInfo(f"ChalkBox/{relative}", date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, source.read_bytes())
    print(f"Built {output.name} ({output.stat().st_size:,} bytes)")
    return output


if __name__ == "__main__":
    build()
