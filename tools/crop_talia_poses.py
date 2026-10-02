"""Crop the official Talia pose art into head-and-torso companion sprites.

The source art in ``assets/talia/`` is the owner-approved official Talia
character and must not be redrawn or altered; this script only crops and
downsizes it (alpha bbox -> top 56 % -> re-trim -> 360 px high, Lanczos).

Usage (from the repo root):
    python tools/crop_talia_poses.py idle wave happy reading_quran
    python tools/crop_talia_poses.py --avatar   # square kids-header avatar
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


AVATAR_SIZE = 256


def crop_avatar(name='happy'):
    """Square head-and-shoulders crop for the kids header avatar circle."""
    im = Image.open(os.path.join(SRC, f'talia_{name}.png')).convert('RGBA')
    l, t, r, b = _bbox(im)
    side = int((b - t) * 0.36)
    head = im.crop((l, t, r, t + int((b - t) * 0.12)))
    hl, _, hr, _ = _bbox(head)
    cx = l + (hl + hr) // 2
    top = t - int(side * 0.04)
    box = (cx - side // 2, top, cx + side // 2, top + side)
    out = os.path.join(DST, 'talia_avatar.png')
    im.crop(box).resize((AVATAR_SIZE, AVATAR_SIZE), Image.LANCZOS).save(
        out, optimize=True)
    return out


def main(names):
    if names == ['--avatar']:
        os.makedirs(DST, exist_ok=True)
        out = crop_avatar()
        print(f'{out} {AVATAR_SIZE}x{AVATAR_SIZE}')
        return 0
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
