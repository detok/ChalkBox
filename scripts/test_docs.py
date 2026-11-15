#!/usr/bin/env python3
"""Check local Markdown navigation and current public documentation versions.

No network access, third-party modules or GitHub API credentials needed.
Historical release-specific changelog files are intentionally not rewritten.
"""
from __future__ import annotations

import re
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
RELEASE = ROOT / "ChalkBox" / "ChalkBox.toc"
VERSION_RE = re.compile(r"^## Version:\s*(\S+)", re.MULTILINE)
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
HTML_PATH = re.compile(r"(?:src|href)\s*=\s*['\"]([^'\"]+)['\"]")


def current_version() -> str:
    contents = RELEASE.read_text(encoding="utf-8")
    match = VERSION_RE.search(contents)
    assert match, "Runtime TOC must have a version"
    version = match.group(1)
    second = (ROOT / "ChalkBox" / "ChalkBox_Camelot.toc").read_text(
        encoding="utf-8"
    )
    assert f"## Version: {version}" in second, "TOC versions differ"
    return version


def sources() -> list[Path]:
    files = [ROOT / "README.md", ROOT / "CONTRIBUTING.md"]
    files.extend(sorted((ROOT / "docs").glob("*.md")))
    files.append(ROOT / "curseforge" / "README.md")
    files.extend(
        p for p in sorted((ROOT / "curseforge" / "copy").glob("*.md"))
        if not p.name.startswith("FILE_CHANGELOG_")
        or p.name == "FILE_CHANGELOG_CURRENT.md"
    )
    for folder in ("submission", "launch-kit", "screenshots", "artwork"):
        files.extend(sorted((ROOT / "curseforge" / folder).glob("*.md")))
    return files


def check_links(file: Path, text: str) -> tuple[int, list[str]]:
    refs = MARKDOWN_LINK.findall(text) + HTML_PATH.findall(text)
    errors = []
    count = 0
    for raw in refs:
        target = raw.strip().split(" ", 1)[0].strip("<>").strip("\"'")
        if not target or target.startswith(("#", "/", "//")):
            continue
        if target.startswith(("http://", "https://", "mailto:", "data:")):
            continue
        local = unquote(target.split("#", 1)[0].split("?", 1)[0])
        if not local:
            continue
        count += 1
        path = (file.parent / local).resolve()
        if not path.is_relative_to(ROOT.resolve()):
            errors.append(f"{file.relative_to(ROOT)}: escapes repository: {raw}")
        elif not path.exists():
            errors.append(f"{file.relative_to(ROOT)}: missing {raw}")
    return count, errors


def main() -> None:
    version = current_version()
    failures = []
    count = 0
    files = sources()
    for path in files:
        assert path.exists(), f"Missing handbook path: {path.relative_to(ROOT)}"
        text = path.read_text(encoding="utf-8")
        total, errors = check_links(path, text)
        count += total
        failures.extend(errors)

    # Current *publisher* copy must not silently lag behind the addon version.
    current = (ROOT / "curseforge/copy/FILE_CHANGELOG_CURRENT.md"
        ).read_text(encoding="utf-8")
    if not current.startswith(f"# ChalkBox {version}"):
        failures.append("Current CurseForge file changelog doesn't match TOC version")
    for relative in (
        "README.md",
        "docs/README.md",
        "docs/GETTING_STARTED.md",
        "docs/USER_GUIDE.md",
        "docs/RELEASE_NOTES.md",
        "curseforge/README.md",
        "curseforge/copy/QUICK_START.md",
        "curseforge/copy/PROJECT_FIELDS.md",
        "curseforge/launch-kit/START_HERE.md",
    ):
        content = (ROOT / relative).read_text(encoding="utf-8")
        if version not in content:
            failures.append(f"{relative}: missing current {version} release context")

    if failures:
        for error in failures:
            print("DOC ERROR: " + error)
        raise SystemExit(f"{len(failures)} documentation check(s) failed")
    assert count >= 45, "Not enough local links checked; review documentation index"
    print(f"PASS: {len(files)} public Markdown files, {count} local links, "
          f"current version {version}, and both TOC versions")


if __name__ == "__main__":
    main()
