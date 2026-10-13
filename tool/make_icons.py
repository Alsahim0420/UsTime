"""Regenerates the web icons (favicon + PWA icons): a white heart on the
app's pink-to-lavender gradient. Run: python3 tool/make_icons.py"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

WEB = Path(__file__).resolve().parent.parent / "web"
# Same stops as AppColors.hero in lib/theme.dart.
STOPS = [(0xF3, 0xA6, 0xC8), (0xB8, 0x93, 0xE6), (0x9A, 0x86, 0xE0)]
BASE = 1024


def gradient(size):
    """Diagonal gradient, top-left to bottom-right."""
    ramp = Image.new("RGB", (256, 1))
    for i in range(256):
        t = i / 255 * (len(STOPS) - 1)
        k = min(int(t), len(STOPS) - 2)
        f = t - k
        ramp.putpixel(
            (i, 0),
            tuple(round(a + (b - a) * f) for a, b in zip(STOPS[k], STOPS[k + 1])),
        )
    mask = Image.new("L", (size, size))
    mask.putdata(
        [round((x + y) / (2 * (size - 1)) * 255) for y in range(size) for x in range(size)]
    )
    return Image.merge("RGB", [mask.point(list(ramp.getchannel(c).getdata())) for c in "RGB"])


def heart(size, scale):
    """White heart mask centered in a size x size canvas."""
    pts = []
    for i in range(720):
        t = i / 720 * 2 * math.pi
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((x, -y))
    unit = size * scale / 34
    cy = size / 2 - 2.5 * unit  # the curve sits slightly below its origin
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(
        [(size / 2 + x * unit, cy + y * unit) for x, y in pts], fill=255
    )
    return mask


def icon(rounded, heart_scale):
    image = gradient(BASE).convert("RGBA")
    white = Image.new("RGBA", (BASE, BASE), (255, 255, 255, 255))
    image.paste(white, mask=heart(BASE, heart_scale))
    if rounded:
        shape = Image.new("L", (BASE, BASE), 0)
        ImageDraw.Draw(shape).rounded_rectangle(
            (0, 0, BASE - 1, BASE - 1), radius=int(BASE * 0.24), fill=255
        )
        image.putalpha(shape)
    return image


def save(image, name, size):
    image.resize((size, size), Image.LANCZOS).save(WEB / name, optimize=True)


standard = icon(rounded=True, heart_scale=0.56)
# Maskable icons get cropped by the OS, so they are full-bleed with a
# smaller heart inside the safe zone.
maskable = icon(rounded=False, heart_scale=0.44)

save(standard, "favicon.png", 64)
save(standard, "icons/Icon-192.png", 192)
save(standard, "icons/Icon-512.png", 512)
save(maskable, "icons/Icon-maskable-192.png", 192)
save(maskable, "icons/Icon-maskable-512.png", 512)
