#!/usr/bin/env python3
"""Render the CurseForge ChalkBox mark as a native 64px WoW TGA icon.

The SVG is the single branding source. Standard-library PNG decoding avoids
introducing Pillow or ImageMagick into the addon build.
Requires rsvg-convert (already installed for the publishing media kit).
"""
from __future__ import annotations

import shutil
import struct
import subprocess
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "curseforge/artwork/chalkbox-project-icon-512.svg"
OUTPUT = ROOT / "ChalkBox/assets/Icon.tga"
SIZE = 64


def unpack_png(png: bytes) -> tuple[int, int, bytes]:
    if not png.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("SVG renderer did not produce PNG")
    pos = 8
    width = height = channels = None
    idat = []
    while pos + 12 <= len(png):
        length = struct.unpack_from(">I", png, pos)[0]
        kind = png[pos + 4:pos + 8]
        data = png[pos + 8:pos + 8 + length]
        pos += length + 12
        if kind == b"IHDR":
            width, height, depth, color, compression, filtering, interlace = (
                struct.unpack(">IIBBBBB", data))
            if depth != 8 or color not in (2, 6) or compression or filtering or interlace:
                raise ValueError("Unsupported icon PNG pixel encoding")
            channels = 4 if color == 6 else 3
        elif kind == b"IDAT":
            idat.append(data)
        elif kind == b"IEND":
            break
    if not width or not height or not channels:
        raise ValueError("PNG missing image metadata")
    packed = zlib.decompress(b"".join(idat))
    stride = width * channels
    position = 0
    previous = bytearray(stride)
    result = bytearray()
    for _ in range(height):
        filter_type = packed[position]
        position += 1
        row = bytearray(packed[position:position + stride])
        position += stride
        if len(row) != stride or filter_type > 4:
            raise ValueError("Invalid PNG scanline")
        for i in range(stride):
            left = row[i - channels] if i >= channels else 0
            up = previous[i]
            upper_left = previous[i - channels] if i >= channels else 0
            if filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = up
            elif filter_type == 3:
                predictor = (left + up) // 2
            elif filter_type == 4:
                p = left + up - upper_left
                a, b, c = abs(p - left), abs(p - up), abs(p - upper_left)
                predictor = left if a <= b and a <= c else (up if b <= c else upper_left)
            else:
                predictor = 0
            row[i] = (row[i] + predictor) & 255
        for i in range(0, stride, channels):
            red, green, blue = row[i], row[i + 1], row[i + 2]
            alpha = row[i + 3] if channels == 4 else 255
            result.extend((blue, green, red, alpha))
        previous = row
    return width, height, bytes(result)


def render_icon() -> Path:
    renderer = shutil.which("rsvg-convert")
    if not renderer:
        raise RuntimeError("Install librsvg2-bin to render the addon icon")
    png = subprocess.run(
        [renderer, "--width", str(SIZE), "--height", str(SIZE), str(MASTER)],
        check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    ).stdout
    width, height, bgra = unpack_png(png)
    if (width, height) != (SIZE, SIZE):
        raise ValueError("ChalkBox icon must render at 64x64")
    # Uncompressed BGRA TGA, 32 bits, top-left origin, 8-bit alpha.
    header = bytearray(18)
    header[2] = 2
    header[12:14] = width.to_bytes(2, "little")
    header[14:16] = height.to_bytes(2, "little")
    header[16] = 32
    header[17] = 0x28
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(header + bgra)
    return OUTPUT


if __name__ == "__main__":
    print("Rendered", render_icon())
