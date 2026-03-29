#!/usr/bin/env python3
"""Generate Bons Comptes app icon: € and $ back to back on gradient background."""

from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
OUT_DIR = "Bons Comptes/Assets.xcassets/AppIcon.appiconset"

def create_icon(size=SIZE):
    img = Image.new('RGB', (size, size), (108, 92, 231))
    draw = ImageDraw.Draw(img)

    # Gradient background: purple (#6C5CE7) to deep purple (#4834D4)
    for y in range(size):
        for x in range(size):
            f = (y / size + x / size) / 2
            r = int(108 + (72 - 108) * f)
            g = int(92 + (52 - 92) * f)
            b = int(231 + (212 - 231) * f)
            img.putpixel((x, y), (r, g, b, 255))

    # Find a bold font
    font_paths = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]

    font = None
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                font = ImageFont.truetype(fp, int(size * 0.44))
                break
            except Exception:
                continue
    if font is None:
        font = ImageFont.load_default()

    # Measure € and $
    bbox_e = draw.textbbox((0, 0), "€", font=font)
    ew, eh = bbox_e[2] - bbox_e[0], bbox_e[3] - bbox_e[1]
    bbox_d = draw.textbbox((0, 0), "$", font=font)
    dw, dh = bbox_d[2] - bbox_d[0], bbox_d[3] - bbox_d[1]

    gap = int(size * 0.01)
    total_w = ew + gap + dw

    # Draw € (white) on the left
    ex = (size - total_w) // 2 - bbox_e[0]
    ey = (size - eh) // 2 - bbox_e[1]
    draw.text((ex, ey), "€", fill=(255, 255, 255, 255), font=font)

    # Draw $ (teal #00CEC9) on the right
    dx = (size - total_w) // 2 + ew + gap - bbox_d[0]
    dy = (size - dh) // 2 - bbox_d[1]
    draw.text((dx, dy), "$", fill=(0, 206, 201, 255), font=font)

    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    icon = create_icon(SIZE)

    # iOS universal 1024x1024
    icon.save(os.path.join(OUT_DIR, "icon_1024.png"), "PNG")
    print("Created icon_1024.png")

    # Mac sizes
    mac_sizes = [16, 32, 128, 256, 512]
    for s in mac_sizes:
        resized = icon.resize((s, s), Image.LANCZOS)
        resized.save(os.path.join(OUT_DIR, f"icon_{s}.png"), "PNG")
        print(f"Created icon_{s}.png")
        # @2x
        s2 = s * 2
        if s2 <= 1024:
            resized2 = icon.resize((s2, s2), Image.LANCZOS)
            resized2.save(os.path.join(OUT_DIR, f"icon_{s}@2x.png"), "PNG")
            print(f"Created icon_{s}@2x.png")

    print("Done!")


if __name__ == "__main__":
    main()
