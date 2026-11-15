#!/usr/bin/env python3
"""Render ChalkBox's optional 256px quest-arrow vector to WoW TGA.

Same standard-library PNG decoder and rsvg-convert used for the addon icon.
The SVG is the editable source; the TGA is rebuilt deterministically for
each playable ZIP, so no user-downloadable font or external dependency.
"""
from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from render_addon_icon import unpack_png

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "ChalkBox/assets/QuestArrowHD.svg"
OUTPUT = ROOT / "ChalkBox/assets/QuestArrowHD.tga"
SIZE = 256


def render_arrow() -> Path:
    tool = shutil.which("rsvg-convert")
    if not tool:
        raise RuntimeError("Install librsvg2-bin to render QuestSense HD arrow")
    png = subprocess.run(
        [tool, "--width", str(SIZE), "--height", str(SIZE), str(MASTER)],
        check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    ).stdout
    width, height, bgra = unpack_png(png)
    if (width, height) != (SIZE, SIZE):
        raise ValueError("QuestSense high-resolution arrow must be 256x256")
    header = bytearray(18)
    header[2] = 2
    header[12:14] = width.to_bytes(2, "little")
    header[14:16] = height.to_bytes(2, "little")
    header[16] = 32
    header[17] = 0x28  # 8-bit alpha, top-left origin
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(header + bgra)
    return OUTPUT


if __name__ == "__main__":
    print("Rendered", render_arrow())
