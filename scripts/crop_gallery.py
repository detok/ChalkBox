#!/usr/bin/env python3
"""Crop actual 2560x1440 WoW screenshots for the public ChalkBox gallery.

Pillow direct pixel crops only. No image generation, invented screenshots,
reconstructed UI, changed auction values, or modification of the addon.
Requires: pip install pillow
Usage: python scripts/crop_gallery.py cbssrcneedscroping.zip output/gallery
"""
from pathlib import Path
from PIL import Image, ImageFilter
import io
import json
import sys
import zipfile

# (public subfolder, slug, source time, crop in source x1/y1/x2/y2)
CROPS = [
    ("Gallery", "01-ChalkBox-Overview", "200729", (728,131,1840,803)),
    ("Gallery", "02-Discoveries-Map-Loot-Atlas", "200622", (17,134,1822,863)),
    ("Gallery", "03-Discoveries-Item-Market-Tooltip", "200625", (17,134,2203,863)),
    ("Gallery", "04-Discoveries-Zone-Filters", "200640", (17,134,1865,863)),
    ("Gallery", "05-MacroForge-Editor", "200656", (433,134,1213,814)),
    ("Gallery", "06-LootSense-Settings", "200735", (728,131,1840,803)),
    ("Gallery", "07-DropSense-Settings", "200741", (728,131,1840,803)),
    ("Gallery", "08-AuctionSense-Settings", "200743", (728,131,1840,803)),
    ("Gallery", "09-QuestSense-Navigation", "200747", (728,131,1840,803)),
    ("Gallery", "10-Adventure-Journal", "200753", (935,444,1649,1001)),
    ("Gallery", "11-The-Bar-Stat-Options", "200758", (728,131,1840,803)),
    ("Gallery", "12-Combat-Meter-Options", "200802", (728,131,1840,803)),
    ("Gallery", "13-Inventory-Market-Tooltip", "200845", (1950,282,2485,633)),
    ("Gallery", "14-Bags-Stacked", "200845", (2190,715,2435,1329)),
    ("Gallery", "15-The-Bar-Actual-HUD-Strip", "200845", (0,0,2560,27)),
    ("Gallery", "16-Global-Appearance", "200814", (728,131,1840,803)),
    ("Extras", "17-Discovery-Panel-Alternative", "200642", (1258,134,1865,863)),
    ("Extras", "18-LootSense-Appearance", "200739", (728,131,1840,803)),
    ("Extras", "19-QuestSense-Tracking", "200745", (728,131,1840,803)),
    ("Extras", "20-Session-Journal-Settings", "200749", (728,131,1840,803)),
    ("Extras", "21-The-Bar-Placement", "200755", (728,131,1840,803)),
    ("Extras", "22-The-Bar-Appearance", "200800", (728,131,1840,803)),
    ("Extras", "23-MacroForge-Settings", "200805", (728,131,1840,803)),
    ("Extras", "24-Adventure-Prep", "200809", (728,131,1840,803)),
    ("Extras", "25-Toast-Appearance", "200812", (728,131,1840,803)),
    ("Extras", "26-Emota-Settings", "200816", (728,131,1840,803)),
    ("Extras", "27-Emote-Catalog", "200821", (728,131,1840,803)),
    ("Extras", "28-QuietGuard-Settings", "200824", (728,131,1840,803)),
]
MAP_CROPS = {"200622", "200625", "200640"}
EXCLUDED_ORIGINALS = ("200818", "200826")  # translucent UI reveals names


def main(source_zip, output):
    output = Path(output)
    with zipfile.ZipFile(source_zip) as z:
        originals = {Path(name).stem[-6:]: name for name in z.namelist()
                     if name.lower().endswith(".jpg")}
        if len(originals) != 28:
            raise ValueError("Expected the original 28-screen capture archive")
        provenance = []
        for group, slug, suffix, bounds in CROPS:
            source_name = originals[suffix]
            source = Image.open(io.BytesIO(z.read(source_name))).convert("RGB")
            if source.size != (2560, 1440):
                raise ValueError("Unexpected screenshot dimensions " + source_name)
            result = source.crop(bounds)
            redactions = []
            if suffix in MAP_CROPS:
                # Hide bottom-map player-coordinate footer. This is an
                # ordinary Pillow Gaussian blur of existing pixels only.
                region = (79, 762, 334, 785)
                local = (region[0]-bounds[0], region[1]-bounds[1],
                         region[2]-bounds[0], region[3]-bounds[1])
                result.paste(result.crop(local).filter(
                    ImageFilter.GaussianBlur(radius=20)), local[:2])
                redactions.append(region)
            destination = output / group / (slug + ".jpg")
            destination.parent.mkdir(parents=True, exist_ok=True)
            result.save(destination, quality=93, subsampling=0, optimize=True)
            provenance.append({"file": str(destination.relative_to(output)),
                               "source": source_name, "crop_xyxy": bounds,
                               "redactions_xyxy": redactions})
    (output / "CROP_MANIFEST.json").write_text(
        json.dumps(provenance, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: crop_gallery.py INPUT.zip OUTPUT_DIR")
    main(sys.argv[1], sys.argv[2])
