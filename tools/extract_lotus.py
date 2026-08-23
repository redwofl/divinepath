"""Extract the white lotus from 'new logo.png' onto a transparent background.

The logo is a full-bleed orange gradient square with a white lotus in the
center. For Android adaptive icons and the native splash we want ONLY the
lotus (transparent elsewhere) so it sits cleanly on the platform background
(orange gradient for the icon, dark for the splash) without visible box
edges -- the "sticker" look.

Writes:
  - assets/icons/app_icon_foreground.png  (1024x1024, lotus in the safe zone)
  - assets/icons/splash_icon.png          (1024x1024, lotus for dark splash)
"""
from PIL import Image

SRC = "new logo.png"
SIZE = 1024

im = Image.open(SRC).convert("RGBA")
w, h = im.size

# ---- Extract the lotus ----
# The orange background is saturated (R high, G mid, B ~ 0). The lotus is
# white/cream (R ~= G ~= B, high). Use a "whiteness" metric: how close the
# pixel is to neutral white, modulated by luminance. Orange fails because
# its channels diverge; cream lotus passes because they converge.
px = im.load()

def whiteness(x, y):
    r, g, b, _ = px[x, y]
    mx, mn = max(r, g, b), min(r, g, b)
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    # 1.0 for neutral bright pixels, 0 for saturated/dark ones.
    neutral = 1.0 - (mx - mn) / 255.0 if mx > 0 else 0.0
    return min(neutral, lum / 235.0)

alpha = Image.new("L", (w, h), 0)
apx = alpha.load()
for y in range(h):
    for x in range(w):
        v = whiteness(x, y)
        # Smooth ramp: fully opaque when clearly lotus, 0 when clearly orange.
        t = (v - 0.57) / 0.25
        t = max(0.0, min(1.0, t))
        apx[x, y] = int(round(255 * t))

lotus = im.copy()
lotus.putalpha(alpha)

# ---- Center & size the lotus on a 1024 canvas ----
bbox = lotus.getbbox()
print(f"lotus bbox in source: {bbox}")

# Scale the lotus so its width fills ~62% of the canvas (inside the adaptive
# safe zone of 66/108 = 61%) and keep the aspect ratio.
target_w = int(SIZE * 0.62)
scale = target_w / (bbox[2] - bbox[0])
scaled = lotus.crop(bbox).resize(
    (int((bbox[2] - bbox[0]) * scale), int((bbox[3] - bbox[1]) * scale)),
    Image.LANCZOS,
)

def place(target_frac):
    """Center the scaled lotus on a SIZE canvas, occupying target_frac."""
    tw = int(SIZE * target_frac)
    s = tw / scaled.width
    art = scaled.resize((int(scaled.width * s), int(scaled.height * s)), Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ox = (SIZE - art.width) // 2
    oy = (SIZE - art.height) // 2
    canvas.paste(art, (ox, oy), art)
    return canvas

# Adaptive foreground: lotus inside the safe zone (~62% of canvas).
place(0.62).save("assets/icons/app_icon_foreground.png")
print("wrote assets/icons/app_icon_foreground.png")

# Splash icon: lotus a touch larger is fine (no mask), ~55% for balance.
place(0.55).save("assets/icons/splash_icon.png")
print("wrote assets/icons/splash_icon.png")
