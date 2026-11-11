"""Turn lit renders into pixel art: hard alpha, then reduce to a limited
color count with no dithering so shading falls into clean pixel bands."""
from PIL import Image, ImageEnhance

def pixel_lit(im: Image.Image, colors: int = 40, outline=None) -> Image.Image:
    im = im.convert("RGBA")
    r, g, b, a = im.split()
    rgb = Image.merge("RGB", (r, g, b))
    rgb = ImageEnhance.Color(rgb).enhance(1.25)
    q = rgb.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    out = Image.merge("RGBA", (*q.split(), a))
    return out

def sprite_lit(im: Image.Image, colors: int = 24) -> Image.Image:
    """Character sprite: solid body with 1px dark outline, soft shadow kept
    as a single semi-transparent dark tone."""
    im = im.convert("RGBA")
    w, h = im.size
    src = im.load()
    body = Image.new("RGBA", im.size)
    shadow = Image.new("RGBA", im.size)
    bp, sp = body.load(), shadow.load()
    for y in range(h):
        for x in range(w):
            rr, gg, bb, aa = src[x, y]
            if aa > 200:
                bp[x, y] = (rr, gg, bb, 255)
            elif aa > 40:
                sp[x, y] = (10, 10, 18, 95)
    rgb = body.convert("RGB")
    q = ImageEnhance.Color(rgb).enhance(1.2).quantize(colors=colors, dither=Image.Dither.NONE).convert("RGB")
    body = Image.merge("RGBA", (*q.split(), body.getchannel("A")))
    bp = body.load()
    a = body.getchannel("A").load()
    out = shadow.copy()
    op = out.load()
    for y in range(h):
        for x in range(w):
            if a[x, y] == 0 and any(0 <= x+dx < w and 0 <= y+dy < h and a[x+dx, y+dy] == 255
                                    for dx, dy in ((1,0),(-1,0),(0,1),(0,-1))):
                op[x, y] = (18, 14, 26, 255)
    out.alpha_composite(body)
    return out
