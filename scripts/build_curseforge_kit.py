#!/usr/bin/env python3
"""Build the separate CurseForge publishing kit; never bundle it with the addon."""
from __future__ import annotations
import re
import shutil
import subprocess
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "curseforge"
DIST = ROOT / "dist"
ART = {
    "chalkbox-project-icon-512.svg": ("Project-Icon-512.png", 512, 512, "Upload-Ready"),
    "chalkbox-wordmark.svg": ("ChalkBox-Wordmark-1280x270.png", 1280, 270, "Upload-Ready"),
    "chalkbox-banner-1200x630.svg": ("ChalkBox-Social-Banner-1200x630.png", 1200, 630, "Upload-Ready"),
    "chalkbox-github-header-1600x470.svg": ("ChalkBox-GitHub-Header-1600x470.png", 1600, 470, "Upload-Ready"),
    "chalkbox-hero-1600x900.svg": ("ChalkBox-Hero-1600x900.png", 1600, 900, "Editorial-Only"),
    "chalkbox-feature-grid-1600x900.svg": ("ChalkBox-Feature-Illustration-1600x900.png", 1600, 900, "Editorial-Only"),
}
COPY = [
    "copy/PROJECT_DESCRIPTION.md", "copy/PROJECT_FIELDS.md",
    "copy/SHORT_COPY.md", "copy/QUICK_START.md",
    "copy/COMMANDS.md", "copy/FAQ.md",
    "copy/FEATURE_PROOF.md", "copy/SUPPORT_AND_CREDITS.md",
    "copy/FILE_CHANGELOG_2.0.2.md", "submission/PUBLISH_CHECKLIST.md",
    "submission/QA_AND_POLICY.md", "submission/GITHUB_PRESENTATION.md",
    "artwork/SCREENSHOT_PLAN.md", "launch-kit/START_HERE.md",
]

def version() -> str:
    toc = (ROOT / "ChalkBox/ChalkBox.toc").read_text(encoding="utf-8")
    match = re.search(r"^## Version:\s*(\S+)", toc, re.M)
    if not match:
        raise ValueError("ChalkBox TOC version is missing")
    return match.group(1)

def entry(filename: str, data: bytes):
    info = ZipInfo(filename, date_time=(2026, 1, 1, 0, 0, 0))
    info.compress_type = ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    return info, data

def png_from_svg(svg: Path, width: int, height: int) -> bytes:
    binary = shutil.which("rsvg-convert")
    if not binary:
        raise RuntimeError("Install librsvg2-bin to render the brand PNGs")
    completed = subprocess.run([binary, "--width", str(width),
        "--height", str(height), str(svg)], check=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if not completed.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError(f"Bad PNG export from {svg.name}")
    return completed.stdout

def build() -> Path:
    v = version()
    DIST.mkdir(parents=True, exist_ok=True)
    output = DIST / f"ChalkBox-CurseForge-Media-{v}.zip"
    files = []
    prefix = "ChalkBox-CurseForge-Kit/"
    for svg_name, (png_name, width, height, category) in ART.items():
        source = SOURCE / "artwork" / svg_name
        if not source.is_file():
            raise FileNotFoundError(source)
        files.append(entry(prefix + "Artwork/SVG/" + svg_name,
            source.read_bytes()))
        files.append(entry(prefix + "Artwork/PNG/" + category + "/" +
            png_name, png_from_svg(source, width, height)))
    icon = SOURCE / "artwork/chalkbox-project-icon-512.svg"
    for size in (64, 128, 256):
        files.append(entry(prefix + f"Artwork/PNG/Extras/ChalkBox-Icon-{size}.png",
            png_from_svg(icon, size, size)))
    for item in COPY:
        source = SOURCE / item
        if not source.is_file():
            raise FileNotFoundError(source)
        files.append(entry(prefix + "Copy-and-Checklist/" + item,
            source.read_bytes()))
    readme = (
        f"CHALKBOX CURSEFORGE MEDIA KIT {v}\n\n"
        "This is the media kit, NOT the installable addon.\n"
        f"Upload ChalkBox-{v}.zip from GitHub Releases as the game file.\n"
        "Use Artwork/PNG/Upload-Ready/Project-Icon-512.png as the avatar.\n"
        "Listing copy and the checklist are in Copy-and-Checklist/.\n"
        "Editorial-Only graphics are illustrations, NOT gameplay screenshots.\n"
        "Real WoW Forever screenshots are not included.\n"
        "Verify the WoW Forever game flavor in the CurseForge upload form.\n"
        "Creator: Detok Whitemaine.\n"
        "Source: https://github.com/detok/ChalkBox\n"
    ).encode("utf-8")
    files.append(entry(prefix + "README.txt", readme))
    files.sort(key=lambda pair: pair[0].filename)
    with ZipFile(output, "w") as archive:
        for info, data in files:
            archive.writestr(info, data)
    print(f"Built {output.name} ({output.stat().st_size:,} bytes; "
          f"{len(files)} files)")
    return output

if __name__ == "__main__":
    build()
