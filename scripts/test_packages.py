#!/usr/bin/env python3
"""Test the single-addon ZIP for completeness, safety and reproducibility."""
from __future__ import annotations

import hashlib
from pathlib import Path
from zipfile import ZipFile

from package import ROOT, SOURCE, DIST, FILES, build, version_of


def test() -> None:
    for required in ["README.md", "LICENSE", "CONTRIBUTING.md"]:
        assert (ROOT / required).is_file(), f"Public repo missing {required}"
    assert (SOURCE / "assets/Icon.tga").stat().st_size > 1000, "Missing addon icon"
    assert not (ROOT / "addons" / "DontSellThat").exists()
    assert not (ROOT / "addons" / "EmotaSpeak").exists()
    assert not (ROOT / "DontSellThat").exists()
    assert not (ROOT / "EmotaSpeak").exists()

    toc = (SOURCE / "ChalkBox.toc").read_text(encoding="utf-8")
    camelot = (SOURCE / "ChalkBox_Camelot.toc").read_text(encoding="utf-8")
    assert "## Title: ChalkBox" in toc and "## Title: ChalkBox" in camelot
    assert "## Interface: 11509" in toc
    assert "## Interface: 16001" in camelot
    assert "ChalkBoxDB" in toc and "ChalkBoxProfessionDB" in toc
    assert version_of(SOURCE / "ChalkBox.toc") == version_of(
        SOURCE / "ChalkBox_Camelot.toc")
    listed = [line.strip() for line in toc.splitlines()
              if line.strip() and not line.startswith("##")]
    expected_lua = {name for name in FILES if name.endswith(".lua")}
    assert set(listed) == expected_lua, "Manifest and packaging disagree"
    assert listed == [name for name in FILES if name.endswith(".lua")], (
        "TOC load order differs from tested package order"
    )
    output = build()
    assert output.name == f"ChalkBox-{version_of(SOURCE / 'ChalkBox.toc')}.zip"
    assert len(list(DIST.glob("*.zip"))) == 1, "Only one addon should be packaged"
    with ZipFile(output) as archive:
        expected = {f"ChalkBox/{name}" for name in FILES}
        assert set(archive.namelist()) == expected, "Wrong ZIP install tree"
        assert archive.testzip() is None, "Corrupt ZIP"
        for relative in FILES:
            assert archive.read(f"ChalkBox/{relative}") == (
                SOURCE / relative).read_bytes(), f"Source mismatch: {relative}"
        assert not any("DontSellThat" in x or "EmotaSpeak" in x
                       or "LibProfessionDB" in x for x in archive.namelist()), (
                           "Old standalone or third-party library bundled by mistake")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    second = build()
    assert hashlib.sha256(second.read_bytes()).hexdigest() == digest, (
        "Packaging should be reproducible"
    )
    print("PASS: single self-contained ChalkBox ZIP, icon, manifest order, "
          "client TOCs, no legacy addons or third-party bundle, reproducible bytes")


if __name__ == "__main__":
    test()
