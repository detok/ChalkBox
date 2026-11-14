#!/usr/bin/env python3
"""Check branding assets and listing documents inside the CurseForge media ZIP."""
from __future__ import annotations
from zipfile import ZipFile
from build_curseforge_kit import build, ART, COPY, SCREENSHOTS

PNG = b"\x89PNG\r\n\x1a\n"

def test():
    output = build()
    with ZipFile(output) as archive:
        names = archive.namelist()
        assert archive.testzip() is None, "Corrupt media ZIP"
        assert len(names) == 2 * len(ART) + 3 + len(COPY) + len(SCREENSHOTS) + 1
        assert len(set(names)) == len(names)
        assert sum(n.endswith(".svg") for n in names) == 6
        assert sum(n.endswith(".png") for n in names) == 9
        assert sum(n.endswith(".jpg") for n in names) == len(SCREENSHOTS)
        assert all(archive.read("ChalkBox-CurseForge-Kit/Screenshots/"+f)
            .startswith(b"\xff\xd8\xff") for f in SCREENSHOTS)
        assert any(name.endswith("/Screenshots/10-discoveries.jpg")
            for name in names)
        assert all(archive.read(name).startswith(PNG)
                   for name in names if name.endswith(".png"))
        assert any(name.endswith("/Project-Icon-512.png") for name in names)
        assert any(name.endswith("/FILE_CHANGELOG_2.0.8.md") for name in names)
        assert not any(name.lower().endswith((".ttf", ".otf", ".woff"))
                       for name in names)
        assert b"NOT the installable addon" in archive.read(
            "ChalkBox-CurseForge-Kit/README.txt")
        assert not any("MapSense" in name for name in names)
        assert b"Ten original cropped WoW Forever screenshots" in archive.read(
            "ChalkBox-CurseForge-Kit/README.txt")
    print("PASS: six SVG masters, nine PNGs, ten authentic gameplay JPGs, "
          "listing copy and checklists in the media kit")

if __name__ == "__main__":
    test()
