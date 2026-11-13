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
    listed = [line.strip().replace("\\\\", "/") for line in toc.splitlines()
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
                       for x in archive.namelist()), (
                           "Old standalone addons must not reappear")
        assert archive.read("ChalkBox/Libs/LibProfessionDB-1.0/LICENSE").startswith(
            b"MIT License\\n\\nCopyright (c) 2026 Pimptasty"), "Original MIT author credit missing"
        assert len([name for name in archive.namelist()
                    if name.startswith("ChalkBox/Libs/LibProfessionDB-1.0/Data/")]) == 15, (
            "Incomplete Forever recipe data bundle")
        assert "ChalkBox/LICENSE" in archive.namelist()
        assert "ChalkBox/Libs/LibStub/LibStub.lua" in archive.namelist()
        def github_blob_sha(data: bytes) -> str:
            return hashlib.sha1(
                b"blob " + str(len(data)).encode() + b"\\0" + data
            ).hexdigest()
        assert github_blob_sha(archive.read(
            "ChalkBox/Libs/LibProfessionDB-1.0/LibProfessionDB-1.0.lua"
        )) == "f88a046c61bb4e3a3fda5172f2265639ee921d1d", (
            "Vendored library must match the MIT 1.9.1 source exactly")
        assert github_blob_sha(archive.read(
            "ChalkBox/Libs/LibProfessionDB-1.0/LICENSE"
        )) == "728b5b0047107a2cbd70176d70ac7840a23ecff1", (
            "Original MIT license must be preserved byte-for-byte")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    second = build()
    assert hashlib.sha256(second.read_bytes()).hexdigest() == digest, (
        "Packaging should be reproducible"
    )
    print("PASS: one ChalkBox ZIP with fully bundled Forever recipes, exact MIT "
          "license, no legacy addons, reproducible contents and manifest order")


if __name__ == "__main__":
    test()
