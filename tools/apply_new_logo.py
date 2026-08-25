"""Apply the new logo to the app's icon assets.

Reads 'new logo.png' (full-bleed square) and writes:
  - assets/icons/app_icon.png              (1024 launcher source)
  - assets/icons/app_icon_foreground.png   (logo scaled into the 66% safe
                                            zone on transparent for adaptive
                                            launchers)
  - assets/icons/splash_icon.png           (1024 splash source)
"""
from PIL import Image, ImageOps

SRC = "new logo.png"
SIZE = 1024

im = Image.open(SRC).convert("RGBA")

# 1) Launcher icon source: plain resize (full-bleed).
im.resize((SIZE, SIZE), Image.LANCZOS).save("assets/icons/app_icon.png")

# 2) Adaptive foreground: scale the whole logo down to the ~66% safe zone and
#    center it on a transparent canvas so no content gets cropped by the
#    adaptive mask.
SAFE = 0.66
inner = int(SIZE * SAFE)
scaled = im.resize((inner, inner), Image.LANCZOS)
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
fg.paste(scaled, ((SIZE - inner) // 2, (SIZE - inner) // 2), scaled)
fg.save("assets/icons/app_icon_foreground.png")

# 3) Splash icon source: plain resize.
im.resize((SIZE, SIZE), Image.LANCZOS).save("assets/icons/splash_icon.png")

# Average corner color -> adaptive icon background (blends with the gradient).
corners = [im.getpixel((x, y)) for x, y in
           [(5, 5), (SIZE - 6, 5), (5, SIZE - 6), (SIZE - 6, SIZE - 6)]]
avg = tuple(sum(c[i] for c in corners) // len(corners) for i in range(3))
print(f"adaptive bg: #{avg[0]:02X}{avg[1]:02X}{avg[2]:02X}")
print("Logo assets written OK")
