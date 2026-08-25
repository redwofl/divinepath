from PIL import Image
from collections import Counter

for name in ["p1.png", "lang_state.png"]:
    try:
        img = Image.open(name).convert("RGB")
    except Exception as e:
        print(f"{name}: {e}")
        continue
    w, h = img.size
    print(f"=== {name} {w}x{h} ===")
    # Bottom half (where bottom sheet would appear)
    bot = img.crop((0, h//2, w, h))
    c = Counter(bot.getdata())
    print("Bottom-half top colors:", c.most_common(5))
    # Check for the drag-handle bar (grey rounded rect near top of a sheet)
    # Check top 200px of bottom sheet area (y = h-700 to h-600)
    for label, y0, y1 in [("y=1600-1700", 1600, 1700), ("y=1700-1800", 1700, 1800), ("y=2000-2100", 2000, 2100)]:
        band = img.crop((0, y0, w, y1))
        bc = Counter(band.getdata())
        print(f"{label}:", bc.most_common(3))