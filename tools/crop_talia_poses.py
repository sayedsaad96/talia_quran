"""Crop the official Talia pose art into head-and-torso companion sprites.

The source art in ``assets/talia/`` is the owner-approved official Talia
character and must not be redrawn or altered; this script only crops and
downsizes it (alpha bbox -> top 56 % -> re-trim -> 360 px high, Lanczos).

Usage (from the repo root):
    python tools/crop_talia_poses.py idle wave happy reading_quran
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'assets', 'talia')
DST = os.path.join(ROOT, 'assets', 'images', 'talia')
HEIGHT = 360


def _bbox(img):
    return img.getchannel('A').point(lambda a: 255 if a > 16 else 0).getbbox()


def crop_pose(name):
    im = Image.open(os.path.join(SRC, f'talia_{name}.png')).convert('RGBA')
    l, t, r, b = _bbox(im)
    h = int((b - t) * 0.56)
    crop = im.crop((l, t, r, t + h))
    crop = crop.crop(_bbox(crop))
    w = round(crop.width * HEIGHT / crop.height)
    out = os.path.join(DST, f'talia_{name}.png')
    crop.resize((w, HEIGHT), Image.LANCZOS).save(out, optimize=True)
    return out, w


def main(names):
    if not names:
        print(__doc__)
        return 1
    os.makedirs(DST, exist_ok=True)
    for n in names:
        out, w = crop_pose(n)
        print(f'{out} {w}x{HEIGHT} {os.path.getsize(out) / 1024:.1f} KB')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
