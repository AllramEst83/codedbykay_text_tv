"""Builds the Android launcher icons from icons/original/app_icon.png.

Run from the repo root: python tool/make_app_icon.py  (needs Pillow)

- Legacy icons (API 24-25): the artwork itself, mipmap-*/ic_launcher.png.
- Adaptive icon (API 26+): a solid black background colour plus a foreground
  layer, mipmap-*/ic_launcher_foreground.png. The artwork is centred by its
  bounding box and scaled so its corners sit inside the ~72 dp circle that
  Android masks to (the canvas is 108 dp).
"""

from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'icons' / 'original' / 'app_icon.png'
RES = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'

DENSITIES = {  # name: legacy px (48 dp), foreground px (108 dp)
    'mdpi': (48, 108),
    'hdpi': (72, 162),
    'xhdpi': (96, 216),
    'xxhdpi': (144, 324),
    'xxxhdpi': (192, 432),
}
FIT_DP = 72 / 108  # diameter of the circle the artwork's corners must fit in


def artwork(image: Image.Image) -> Image.Image:
    """The artwork with black turned transparent (the background is black).

    Alpha follows the brightest channel, so saturated blue still counts.
    """
    rgba = image.convert('RGBA')
    r, g, b, _ = rgba.split()
    peak = ImageChops.lighter(ImageChops.lighter(r, g), b)
    rgba.putalpha(peak.point(lambda v: min(255, v * 8)))
    return rgba


def foreground(source: Image.Image, size: int) -> Image.Image:
    art = artwork(source)
    box = art.getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
    assert box is not None, 'icon has no visible artwork'
    art = art.crop(box)
    diagonal = (art.width**2 + art.height**2) ** 0.5
    scale = size * FIT_DP / diagonal
    art = art.resize(
        (round(art.width * scale), round(art.height * scale)),
        Image.NEAREST if scale >= 1 else Image.LANCZOS,
    )
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    canvas.paste(
        art, ((size - art.width) // 2, (size - art.height) // 2), art
    )
    return canvas


def main() -> None:
    source = Image.open(SOURCE)
    for name, (legacy, fg) in DENSITIES.items():
        folder = RES / f'mipmap-{name}'
        folder.mkdir(parents=True, exist_ok=True)
        source.convert('RGB').resize((legacy, legacy), Image.LANCZOS).save(
            folder / 'ic_launcher.png'
        )
        foreground(source, fg).save(folder / 'ic_launcher_foreground.png')

    (RES / 'values').mkdir(parents=True, exist_ok=True)
    (RES / 'values' / 'colors.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#000000</color>\n'
        '</resources>\n',
        encoding='utf-8',
    )
    adaptive = RES / 'mipmap-anydpi-v26'
    adaptive.mkdir(parents=True, exist_ok=True)
    (adaptive / 'ic_launcher.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n',
        encoding='utf-8',
    )


if __name__ == '__main__':
    main()
