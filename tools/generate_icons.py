"""Generate DivinePath app icons: layered lotus motif + Om symbol in the center.

Design:
  - Full-bleed launcher icon: saffron-gold vertical gradient, soft glow,
    three layers of lotus petals (outer deep-gold -> inner cream) with a
    cream center disc bearing the Devanagari Om in deep saffron.
  - Adaptive foreground: lotus + Om inside the ~66% safe zone on transparent.
  - Splash icon: white lotus + Om on transparent (shown over dark #111827).
"""
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SIZE = 1024
FONT_PATH = "C:/Windows/Fonts/Nirmala.ttc"
OM = "\u0950"  # Devanagari Om

# Theme palette (AppColors)
SAFFRON = (245, 158, 11)        # #F59E0B
SAFFRON_LIGHT = (255, 184, 77)  # #FFB84D
SAFFRON_DARK = (217, 119, 6)    # #D97706
CREAM = (255, 248, 231)         # #FFF8E7
CREAM_LIGHT = (255, 253, 245)   # #FFFDF5
WHITE = (255, 255, 255)


def load_om_font(size):
    return ImageFont.truetype(FONT_PATH, size)


def bezier(p0, p1, p2, steps=36):
    """Sample a quadratic bezier curve."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        mt = 1 - t
        x = mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0]
        y = mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


def radial_gradient(size, top_color, bottom_color):
    img = Image.new("RGB", (size, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * t)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * t)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * t)
        d.line([(0, y), (size, y)], fill=(r, g, b))
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([size * 0.15, size * 0.12, size * 0.85, size * 0.88],
               fill=(255, 220, 130, 95))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    return Image.alpha_composite(img.convert("RGBA"), glow)


def draw_petal(canvas, cx, cy, L, B, W, angle_deg, fill, outline=None, ow=0):
    """Draw one lotus petal via two quadratic curves.

    Local frame: petal tip at (0, -L), base at (0, B), side bulges at (+-W, 0).
    angle_deg = 0 points the petal straight up; rotate to fan the petals.
    """
    d = ImageDraw.Draw(canvas)
    ang = math.radians(angle_deg)

    def R(p):
        x, y = p
        rx = x * math.cos(ang) - y * math.sin(ang)
        ry = x * math.sin(ang) + y * math.cos(ang)
        return (cx + rx, cy + ry)

    tip, base = (0, -L), (0, B)
    lc, rc = (-W, 0), (W, 0)
    left = bezier(R(tip), R(lc), R(base))
    right = bezier(R(base), R(rc), R(tip))
    pts = left + right[1:-1]
    if outline is not None and ow > 0:
        d.polygon(pts, fill=fill, outline=outline, width=ow)
    else:
        d.polygon(pts, fill=fill)


def draw_lotus(canvas, cx, cy, scale, color_outer, color_mid, color_inner,
               outline, ow):
    """Three fan layers of lotus petals centered at (cx, cy)."""
    s = scale
    # Outer layer: 8 petals fanned widely
    for i in range(8):
        a = i * 45.0
        draw_petal(canvas, cx, cy, 0.40 * s, 0.10 * s, 0.115 * s, a,
                   color_outer, outline, ow)
    # Middle layer: 6 petals, offset 30deg, shorter
    for i in range(6):
        a = i * 60.0 + 30.0
        draw_petal(canvas, cx, cy, 0.30 * s, 0.09 * s, 0.10 * s, a,
                   color_mid, outline, ow)
    # Inner layer: 5 upright petals (long enough to clear the center disc)
    for i in range(5):
        a = i * 72.0 + 18.0
        draw_petal(canvas, cx, cy, 0.24 * s, 0.08 * s, 0.088 * s, a,
                   color_inner, outline, ow)


def draw_om_centered(canvas, om_color, size_frac=0.30, y_offset_frac=0.0,
                     glow=True):
    om_size = int(SIZE * size_frac)
    font = load_om_font(om_size)
    tmp = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    td = ImageDraw.Draw(tmp)
    bbox = td.textbbox((0, 0), OM, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    cx = (SIZE - w) / 2 - bbox[0]
    cy = (SIZE - h) / 2 - bbox[1] + int(SIZE * y_offset_frac)
    td.text((cx, cy), OM, font=font, fill=om_color)
    if glow:
        alpha = tmp.split()[3]
        glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        glow_layer.putalpha(alpha.point(lambda a: min(255, int(a * 0.55))))
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(36))
        canvas = Image.alpha_composite(canvas, glow_layer)
    return Image.alpha_composite(canvas, tmp)


def make_app_icon():
    canvas = radial_gradient(SIZE, SAFFRON_LIGHT, SAFFRON_DARK)
    d = ImageDraw.Draw(canvas)
    # Decorative outer ring
    d.ellipse([SIZE * 0.06, SIZE * 0.06, SIZE * 0.94, SIZE * 0.94],
              outline=(255, 255, 255, 90), width=int(SIZE * 0.012))
    # Backing cream disc for the lotus
    d.ellipse([SIZE * 0.12, SIZE * 0.12, SIZE * 0.88, SIZE * 0.88],
              fill=(255, 248, 231, 250))
    # Lotus: outer petals deep gold, fading to cream at center
    draw_lotus(canvas, SIZE / 2, SIZE / 2 + SIZE * 0.02, SIZE * 0.78,
               color_outer=SAFFRON_DARK,
               color_mid=SAFFRON,
               color_inner=CREAM_LIGHT,
               outline=SAFFRON_DARK, ow=int(SIZE * 0.006))
    # Center disc (smaller so the inner petal layer stays visible)
    d.ellipse([SIZE * 0.38, SIZE * 0.38, SIZE * 0.62, SIZE * 0.62],
              fill=CREAM_LIGHT, outline=SAFFRON_DARK, width=int(SIZE * 0.008))
    canvas = draw_om_centered(canvas, SAFFRON_DARK, size_frac=0.20)
    return canvas


def make_foreground():
    """Adaptive foreground: lotus + Om in the ~66% safe zone, transparent bg."""
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    # Cream disc confined to the safe zone
    d.ellipse([SIZE * 0.17, SIZE * 0.17, SIZE * 0.83, SIZE * 0.83],
              fill=(255, 248, 231, 245))
    draw_lotus(canvas, SIZE / 2, SIZE / 2 + SIZE * 0.01, SIZE * 0.66,
               color_outer=SAFFRON_DARK,
               color_mid=SAFFRON,
               color_inner=CREAM_LIGHT,
               outline=SAFFRON_DARK, ow=int(SIZE * 0.006))
    d.ellipse([SIZE * 0.40, SIZE * 0.40, SIZE * 0.60, SIZE * 0.60],
              fill=CREAM_LIGHT, outline=SAFFRON_DARK, width=int(SIZE * 0.008))
    canvas = draw_om_centered(canvas, SAFFRON_DARK, size_frac=0.18, glow=False)
    return canvas


def make_splash_icon():
    """Splash: white lotus + Om on transparent (over dark splash bg)."""
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    # Soft gold halo disc
    d.ellipse([SIZE * 0.14, SIZE * 0.14, SIZE * 0.86, SIZE * 0.86],
              fill=(255, 184, 77, 55))
    draw_lotus(canvas, SIZE / 2, SIZE / 2 + SIZE * 0.01, SIZE * 0.74,
               color_outer=(255, 224, 170),
               color_mid=(255, 214, 140),
               color_inner=WHITE,
               outline=(255, 255, 255, 200), ow=int(SIZE * 0.007))
    d.ellipse([SIZE * 0.39, SIZE * 0.39, SIZE * 0.61, SIZE * 0.61],
              fill=(255, 250, 235, 235))
    canvas = draw_om_centered(canvas, SAFFRON_DARK, size_frac=0.19)
    return canvas


make_app_icon().save("assets/icons/app_icon.png")
make_foreground().save("assets/icons/app_icon_foreground.png")
make_splash_icon().save("assets/icons/splash_icon.png")
print("Lotus icons written OK")
