"""Builds the Talia icon fonts and their Dart bindings from SVG sources.

Sources are 24x24 monoline SVGs (tools/icons/src). Every shape is a stroke
unless it carries a class:

  class="fill"   kids-only tint layer, never part of the outline glyph
  class="accent" part of the outline glyph, and also of the accent layer
  class="nuqta"  the Talia nuqta: a <circle cx cy [r]> marker that becomes a
                 rhombus (adult) or a soft sparkle (kids); always an accent

Outputs (all generated, do not edit by hand):
  assets/fonts/TaliaIcons/TaliaIcons.ttf       adult outline set, 1.75 stroke
  assets/fonts/TaliaIcons/TaliaIconsKids.ttf   kids set, 2.5 stroke + sparkles
  lib/core/icons/talia_icon_data.dart          IconData constants + layer maps

Codepoints are append-only (tools/icons/codepoints.json) so a rebuild never
reshuffles existing icons. Requires: pip install fonttools skia-pathops

  python tools/icons/build_talia_icons.py [--preview out.png]
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path

ROOT = Path(__file__).resolve().parents[2]
ICONS = ROOT / 'tools' / 'icons'
FONT_DIR = ROOT / 'assets' / 'fonts' / 'TaliaIcons'
DART_OUT = ROOT / 'lib' / 'core' / 'icons' / 'talia_icon_data.dart'

UPM = 960
SCALE = UPM / 24
BASE_CP = 0xE000
ACCENT_OFFSET = 0x800
FILL_OFFSET = 0x1000

VARIANTS = {
    'adult': {'family': 'TaliaIcons', 'stroke': 1.75, 'nuqta': 'rhombus'},
    'kids': {'family': 'TaliaIconsKids', 'stroke': 2.5, 'nuqta': 'sparkle'},
}
DEFAULT_NUQTA_R = 1.7


def _num(el, key, default=0.0):
    return float(el.get(key, default))


def _shape_d(el) -> tuple[str, bool]:
    """Returns (path data, closed) for any supported SVG element."""
    tag = el.tag.split('}')[-1]
    if tag == 'path':
        d = el.get('d')
        return d, bool(re.search(r'[zZ]\s*$', d.strip()))
    if tag == 'circle':
        cx, cy, r = _num(el, 'cx'), _num(el, 'cy'), _num(el, 'r')
        return (f'M{cx - r} {cy}a{r} {r} 0 1 0 {2 * r} 0a{r} {r} 0 1 0 {-2 * r} 0z',
                True)
    if tag == 'ellipse':
        cx, cy = _num(el, 'cx'), _num(el, 'cy')
        rx, ry = _num(el, 'rx'), _num(el, 'ry')
        return (f'M{cx - rx} {cy}a{rx} {ry} 0 1 0 {2 * rx} 0'
                f'a{rx} {ry} 0 1 0 {-2 * rx} 0z', True)
    if tag == 'rect':
        x, y = _num(el, 'x'), _num(el, 'y')
        w, h = _num(el, 'width'), _num(el, 'height')
        rx = _num(el, 'rx', el.get('ry', 0))
        ry = _num(el, 'ry', rx)
        if rx == 0:
            return f'M{x} {y}h{w}v{h}h{-w}z', True
        return (f'M{x + rx} {y}h{w - 2 * rx}a{rx} {ry} 0 0 1 {rx} {ry}'
                f'v{h - 2 * ry}a{rx} {ry} 0 0 1 {-rx} {ry}h{-(w - 2 * rx)}'
                f'a{rx} {ry} 0 0 1 {-rx} {-ry}v{-(h - 2 * ry)}'
                f'a{rx} {ry} 0 0 1 {rx} {-ry}z', True)
    if tag == 'line':
        return (f"M{el.get('x1')} {el.get('y1')}L{el.get('x2')} {el.get('y2')}",
                False)
    if tag in ('polyline', 'polygon'):
        nums = re.split(r'[\s,]+', el.get('points').strip())
        pairs = [f'{nums[i]} {nums[i + 1]}' for i in range(0, len(nums), 2)]
        d = 'M' + 'L'.join(pairs)
        return (d + 'z', True) if tag == 'polygon' else (d, False)
    raise ValueError(f'unsupported element <{tag}>')


def _to_path(d: str) -> pathops.Path:
    p = pathops.Path()
    parse_path(d, p.getPen())
    return p


def _stroke(d: str, width: float) -> pathops.Path:
    p = _to_path(d)
    p.stroke(width, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4)
    p.convertConicsToQuads()
    return p


def _fill(d: str) -> pathops.Path:
    p = _to_path(d)
    p.convertConicsToQuads()
    return p


def _union(paths: list[pathops.Path]) -> pathops.Path:
    out = pathops.Path()
    for p in paths:
        out = pathops.op(out, p, pathops.PathOp.UNION)
    out.convertConicsToQuads()
    return out


def _nuqta_d(cx: float, cy: float, r: float, kind: str) -> str:
    if kind == 'rhombus':
        return f'M{cx} {cy - r}L{cx + r} {cy}L{cx} {cy + r}L{cx - r} {cy}z'
    s = r * 1.55
    return (f'M{cx} {cy - s}Q{cx} {cy} {cx + s} {cy}Q{cx} {cy} {cx} {cy + s}'
            f'Q{cx} {cy} {cx - s} {cy}Q{cx} {cy} {cx} {cy - s}z')


def build_layers(svg_path: Path, variant: dict, filled: bool):
    """Returns (outline, accent | None, fill | None) as pathops paths."""
    root = ET.parse(svg_path).getroot()
    shapes = [el for el in root.iter()
              if el.tag.split('}')[-1] in
              ('path', 'circle', 'ellipse', 'rect', 'line', 'polyline', 'polygon')]
    width = variant['stroke']
    outline, accent, fill = [], [], []
    solid, cuts = None, []
    solid_index = 0
    if filled:
        def area(el):
            b = _to_path(_shape_d(el)[0]).bounds
            return (b[2] - b[0]) * (b[3] - b[1])
        solid_index = max(range(len(shapes)), key=lambda k: area(shapes[k]))
    for i, el in enumerate(shapes):
        cls = (el.get('class') or '').split()
        if 'nuqta' in cls:
            r = _num(el, 'r', DEFAULT_NUQTA_R)
            p = _fill(_nuqta_d(_num(el, 'cx'), _num(el, 'cy'), r, variant['nuqta']))
            if variant['nuqta'] == 'sparkle':
                # round off the sparkle tips so it reads soft at kids sizes
                p = _union([p, _stroke(_nuqta_d(_num(el, 'cx'), _num(el, 'cy'), r,
                                                'sparkle'), 0.9)])
            outline.append(p)
            accent.append(p)
            continue
        d, closed = _shape_d(el)
        if 'fill' in cls:
            fill.append(_fill(d))
            continue
        stroked = _stroke(d, width)
        if filled:
            # the solid shape is filled even when its path is left open
            # (Lucide's heart); open cut-outs like a check stay strokes
            body = (_union([stroked, _fill(d)])
                    if closed or i == solid_index else stroked)
            if i == solid_index:
                solid = body
            else:
                cuts.append(body)
            continue
        outline.append(stroked)
        if 'accent' in cls:
            accent.append(stroked)
    if filled:
        out = solid
        for c in cuts:
            out = pathops.op(out, c, pathops.PathOp.DIFFERENCE)
        out.convertConicsToQuads()
        return out, None, None
    return (_union(outline), _union(accent) if accent else None,
            _union(fill) if fill else None)


def _glyph(path: pathops.Path):
    tt = TTGlyphPen(None)
    pen = TransformPen(Cu2QuPen(tt, max_err=0.5, all_quadratic=True),
                       (SCALE, 0, 0, -SCALE, 0, UPM))
    path.draw(pen)
    g = tt.glyph()
    g.recalcBounds(None)
    return g


def write_font(family: str, glyphs: dict[str, tuple[int, pathops.Path]], out: Path):
    order = ['.notdef'] + sorted(glyphs, key=lambda n: glyphs[n][0])
    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({cp: name for name, (cp, _) in glyphs.items()})
    ttglyphs = {'.notdef': TTGlyphPen(None).glyph()}
    for name, (_, p) in glyphs.items():
        ttglyphs[name] = _glyph(p)
    fb.setupGlyf(ttglyphs)
    fb.setupHorizontalMetrics(
        {n: (UPM, getattr(g, 'xMin', 0)) for n, g in ttglyphs.items()})
    fb.setupHorizontalHeader(ascent=UPM, descent=0)
    fb.setupNameTable({'familyName': family, 'styleName': 'Regular'})
    fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, sTypoLineGap=0,
                usWinAscent=UPM, usWinDescent=0)
    fb.setupPost()
    out.parent.mkdir(parents=True, exist_ok=True)
    fb.save(str(out))


def load_codepoints(names: list[str]) -> dict[str, int]:
    path = ICONS / 'codepoints.json'
    cps = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
    cps = {k: int(v, 16) for k, v in cps.items()}
    nxt = max(cps.values(), default=BASE_CP - 1) + 1
    for n in names:
        if n not in cps:
            cps[n] = nxt
            nxt += 1
    if nxt - BASE_CP > ACCENT_OFFSET:
        sys.exit('codepoint range exhausted')
    path.write_text(json.dumps({k: f'0x{v:04x}' for k, v in cps.items()},
                               indent=2) + '\n', encoding='utf-8')
    return cps


def dart_bindings(manifest, cps, layers) -> str:
    def data(cp, family, rtl):
        extra = ', matchTextDirection: true' if rtl else ''
        return f"IconData(0x{cp:04x}, fontFamily: '{family}'{extra})"

    names = list(manifest)
    lines = [
        '// GENERATED by tools/icons/build_talia_icons.py. Do not edit by hand:',
        '// change the SVG sources or manifest.json and rebuild.',
        '',
        "import 'package:flutter/widgets.dart';",
        '',
        '/// The Talia icon set: one monoline language (1.75 stroke on a 24 grid,',
        '/// round caps) with the gold nuqta marking Talia feature icons.',
        '///',
        '/// Use these everywhere instead of Material `Icons`. Render through',
        '/// `TaliaIcon` to get the gold nuqta on active icons and the kids variant',
        '/// inside a `TaliaIconScope.kids` subtree.',
        'abstract final class TaliaIcons {',
    ]
    for n in names:
        e = manifest[n]
        lines.append(f"  static const IconData {n} = "
                     f"{data(cps[n], 'TaliaIcons', e.get('rtl', False))};")
    lines += ['}', '',
              '/// Kids variant of [TaliaIcons]: same names and meanings, 2.5 stroke,',
              '/// the nuqta drawn as a soft sparkle.',
              'abstract final class TaliaKidsIcons {']
    for n in names:
        e = manifest[n]
        lines.append(f"  static const IconData {n} = "
                     f"{data(cps[n], 'TaliaIconsKids', e.get('rtl', False))};")
    lines.append('}')

    def layer_map(doc, var, kind, offset, family):
        out = ['', f'/// {doc}', f'const Map<int, IconData> {var} = <int, IconData>{{']
        for n in names:
            if layers[family][n][kind]:
                rtl = manifest[n].get('rtl', False)
                out.append(f'  0x{cps[n]:04x}: {data(cps[n] + offset, family, rtl)},')
        out.append('};')
        return out

    lines += layer_map('Gold nuqta/accent layer for adult icons, keyed by codepoint.',
                       'taliaAccentLayers', 'accent', ACCENT_OFFSET, 'TaliaIcons')
    lines += layer_map('Sparkle/accent layer for kids icons, keyed by codepoint.',
                       'taliaKidsAccentLayers', 'accent', ACCENT_OFFSET,
                       'TaliaIconsKids')
    lines += layer_map('Tint layer drawn under kids icons, keyed by codepoint.',
                       'taliaKidsFillLayers', 'fill', FILL_OFFSET, 'TaliaIconsKids')
    lines += ['', '/// Kids glyph for each adult glyph, keyed by codepoint.',
              'const Map<int, IconData> taliaKidsVariants = <int, IconData>{']
    for n in names:
        lines.append(f'  0x{cps[n]:04x}: TaliaKidsIcons.{n},')
    lines += ['};', '', '/// Every icon by name (gallery, tests).',
              'const Map<String, IconData> taliaIconsByName = <String, IconData>{']
    for n in names:
        lines.append(f"  '{n}': TaliaIcons.{n},")
    lines += ['};', '']
    return '\n'.join(lines)


def preview(out: Path):
    from PIL import Image, ImageDraw, ImageFont
    manifest = json.loads((ICONS / 'manifest.json').read_text(encoding='utf-8'))['icons']
    cps = {k: int(v, 16) for k, v in
           json.loads((ICONS / 'codepoints.json').read_text()).items()}
    names = list(manifest)
    cols, cell = 12, 84
    rows = (len(names) + cols - 1) // cols
    img = Image.new('RGB', (cols * cell, rows * cell * 2), '#FDFCF8')
    dr = ImageDraw.Draw(img)
    fonts = {v: ImageFont.truetype(str(FONT_DIR / f"{VARIANTS[v]['family']}.ttf"), 40)
             for v in VARIANTS}
    small = ImageFont.load_default()
    for i, n in enumerate(names):
        for vi, v in enumerate(VARIANTS):
            x = (i % cols) * cell
            y = (i // cols) * cell + vi * rows * cell
            cp = cps[n]
            ch = chr(cp)
            if v == 'kids':
                dr.text((x + 22, y + 10), chr(cp + FILL_OFFSET), font=fonts[v],
                        fill='#9FE1CB')
            dr.text((x + 22, y + 10), ch, font=fonts[v], fill='#0D5C53')
            dr.text((x + 22, y + 10), chr(cp + ACCENT_OFFSET), font=fonts[v],
                    fill='#F59E0B')
            dr.text((x + 4, y + 62), n[:13], font=small, fill='#6B5E4E')
    img.save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--preview', type=Path)
    args = ap.parse_args()
    manifest = json.loads((ICONS / 'manifest.json').read_text(encoding='utf-8'))['icons']
    cps = load_codepoints(list(manifest))
    layers = {}
    for vname, variant in VARIANTS.items():
        fam = variant['family']
        glyphs, layers[fam] = {}, {}
        for name, entry in manifest.items():
            kind, src = entry['src'].split(':')
            outline, accent, fill = build_layers(
                ICONS / 'src' / kind / f'{src}.svg', variant, entry.get('filled', False))
            cp = cps[name]
            glyphs[name] = (cp, outline)
            if accent is not None:
                glyphs[f'{name}.accent'] = (cp + ACCENT_OFFSET, accent)
            if fill is not None and vname == 'kids':
                glyphs[f'{name}.fill'] = (cp + FILL_OFFSET, fill)
            layers[fam][name] = {'accent': accent is not None,
                                 'fill': fill is not None and vname == 'kids'}
        write_font(fam, glyphs, FONT_DIR / f'{fam}.ttf')
    DART_OUT.parent.mkdir(parents=True, exist_ok=True)
    DART_OUT.write_text(dart_bindings(manifest, cps, layers), encoding='utf-8',
                        newline='\n')
    # keep the generated file identical to what `dart format` produces
    subprocess.run(['dart', 'format', str(DART_OUT)], check=True,
                   shell=sys.platform == 'win32', capture_output=True)
    print(f'{len(manifest)} icons -> {FONT_DIR} and {DART_OUT}')
    if args.preview:
        preview(args.preview)


if __name__ == '__main__':
    main()
