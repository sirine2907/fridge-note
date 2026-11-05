"""Joins the frames from tool/record_demo.cjs into docs/demo.gif.

Run: python tool/make_demo_gif.py   (needs Pillow)
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FRAMES = ROOT / "build" / "demo_frames"
OUT = ROOT / "docs" / "demo.gif"

SPEED = 1.4  # play a bit faster than real time
WIDTH = 320  # README shows it at 300 px

frames = json.loads((FRAMES / "frames.json").read_text())

# Keep a frame only when something changed, and remember when it was taken.
kept = []
for frame in frames:
    image = Image.open(FRAMES / frame["file"]).convert("RGB")
    image = image.resize((WIDTH, round(image.height * WIDTH / image.width)), Image.LANCZOS)
    if kept and image.tobytes() == kept[-1][0].tobytes():
        continue
    kept.append((image, frame["t"]))

images = [image for image, _ in kept]
# Each frame stays until the next different one, a bit faster than real time.
durations = [max(40, round((kept[i + 1][1] - kept[i][1]) / SPEED)) for i in range(len(kept) - 1)]
# Hold the last frame a moment before the GIF loops.
durations.append(1800)

palette_images = [im.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE) for im in images]
palette_images[0].save(
    OUT,
    save_all=True,
    append_images=palette_images[1:],
    duration=durations,
    loop=0,
    optimize=True,
    disposal=1,
)
print(f"{len(images)} frames -> {OUT} ({OUT.stat().st_size // 1024} KB)")
