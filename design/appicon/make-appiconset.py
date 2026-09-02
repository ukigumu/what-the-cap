#!/usr/bin/env python3
"""Derives every macOS AppIcon render from the 1024px master using sips.

The master (wtc-appicon-1024.png) is the definitive mark; this script only
scales it. Rerun after replacing the master:

    python3 design/appicon/make-appiconset.py
"""

import json
import shutil
import subprocess
from pathlib import Path

HERE = Path(__file__).parent
MASTER = HERE / "wtc-appicon-1024.png"
APPICONSET = (HERE / "../../WhatTheCap/Assets.xcassets/AppIcon.appiconset").resolve()

RENDERS = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]


def filename(size: int, scale: int) -> str:
    suffix = f"@{scale}x" if scale > 1 else ""
    return f"icon_{size}x{size}{suffix}.png"


def resize(src: Path, dest: Path, px: int) -> None:
    shutil.copyfile(src, dest)
    if px != 1024:
        subprocess.run(["sips", "-z", str(px), str(px), str(dest)], check=True, capture_output=True)


def main() -> None:
    assert MASTER.is_file(), f"missing {MASTER}"
    APPICONSET.mkdir(parents=True, exist_ok=True)
    for old in APPICONSET.glob("icon_*.png"):
        old.unlink()

    images = []
    for size, scale in RENDERS:
        px = size * scale
        name = filename(size, scale)
        dest = APPICONSET / name
        resize(MASTER, dest, px)
        images.append({"filename": name, "idiom": "mac", "scale": f"{scale}x", "size": f"{size}x{size}"})
        print(f"{name}: {px}px")

    (APPICONSET / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    print(f"wrote {APPICONSET / 'Contents.json'}")


if __name__ == "__main__":
    main()
