#!/usr/bin/env python3
"""Derives every macOS AppIcon render from the 1024px master.

The master (wtc-appicon-1024.png) is the definitive mark; this script only
scales it. Rerun after replacing the master:

    python3 design/appicon/make-appiconset.py
"""

import json
from pathlib import Path

from PIL import Image

HERE = Path(__file__).parent
MASTER = HERE / "wtc-appicon-1024.png"
APPICONSET = HERE / "../../WhatTheCap/Assets.xcassets/AppIcon.appiconset"

# (point size, scale) pairs macOS requires, per Apple's asset catalog format.
RENDERS = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]


def filename(size: int, scale: int) -> str:
    suffix = f"@{scale}x" if scale > 1 else ""
    return f"icon_{size}x{size}{suffix}.png"


def main() -> None:
    master = Image.open(MASTER).convert("RGBA")
    assert master.size == (1024, 1024), f"master must be 1024x1024, got {master.size}"

    out = APPICONSET.resolve()
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("icon_*.png"):
        old.unlink()

    images = []
    for size, scale in RENDERS:
        px = size * scale
        name = filename(size, scale)
        render = master if px == 1024 else master.resize((px, px), Image.LANCZOS)
        render.save(out / name)
        images.append({"filename": name, "idiom": "mac", "scale": f"{scale}x", "size": f"{size}x{size}"})
        print(f"{name}: {px}px")

    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (out / "Contents.json").write_text(json.dumps(contents, indent=2, sort_keys=True) + "\n")
    print(f"wrote {out / 'Contents.json'}")


if __name__ == "__main__":
    main()
