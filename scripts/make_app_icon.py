#!/usr/bin/env python3
"""Generate a cool 1024x1024 app icon for GraphStudio.

A violet -> blue -> cyan diagonal gradient with a glowing, upward-trending
line chart, translucent bars, and a subtle grid. iOS masks this square to the
system app-icon shape automatically.
"""
from PIL import Image, ImageDraw, ImageFilter

S = 1024  # final icon size
SS = 2048  # supersample size for crisp chart shapes

# --- Diagonal 3-stop gradient background: violet -> blue -> cyan ---
stops = [
    (0.00, (124, 58, 237)),   # violet  #7C3AED
    (0.50, (37, 99, 235)),    # blue    #2563EB
    (1.00, (6, 182, 212)),    # cyan    #06B6D4
]


def lerp(a, b, t):
    return a + (b - a) * t


def color_at(t):
    t = max(0.0, min(1.0, t))
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]
        t1, c1 = stops[i + 1]
        if t0 <= t <= t1:
            f = (t - t0) / (t1 - t0)
            return (int(lerp(c0[0], c1[0], f)),
                    int(lerp(c0[1], c1[1], f)),
                    int(lerp(c0[2], c1[2], f)))
    return stops[-1][1]


base = Image.new("RGB", (S, S))
px = base.load()
maxv = 2 * (S - 1)
for y in range(S):
    for x in range(S):
        px[x, y] = color_at((x + y) / maxv)

# --- Chart shapes rendered at 2x for crisp edges ---
ov = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
d = ImageDraw.Draw(ov)


def sx(x):
    return int(x * SS)


def sy(y):
    return int(y * SS)


# Plot rect (fractions of the canvas)
L = 0.15
R = 0.90
T = 0.22
B = 0.78

# Subtle grid: horizontal divisions + vertical guides
grid = (255, 255, 255, 30)
for i in range(5):
    gy = int(sy(T) + (sy(B) - sy(T)) * i / 4)
    d.line([(sx(L), gy), (sx(R), gy)], fill=grid, width=2)
for i in range(5):
    gx = int(sx(L) + (sx(R) - sx(L)) * i / 4)
    d.line([(gx, sy(T)), (gx, sy(B))], fill=grid, width=2)

# Baseline
d.line([(sx(L), sy(B)), (sx(R), sy(B))], fill=(255, 255, 255, 90), width=4)

# Upward-trending data (normalized 0..1 within the plot band)
vals = [0.14, 0.30, 0.24, 0.52, 0.44, 0.70, 0.62, 0.95]
n = len(vals)
xs = [L + (R - L) * i / (n - 1) for i in range(n)]
# y is a fraction of the canvas: top of the band is T, baseline is B.
yfrac = [B - (B - T) * v for v in vals]
pts = [(int(sx(xs[i])), int(sy(yfrac[i]))) for i in range(n)]

# Translucent bars (behind the line)
bar_layer = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
bd = ImageDraw.Draw(bar_layer)
bw = int((R - L) / n * 0.42 * SS)
for i in range(n):
    x0 = int(sx(xs[i]) - bw / 2)
    y0 = int(sy(B - (B - T) * vals[i] * 0.55))
    bd.rounded_rectangle([x0, y0, x0 + bw, int(sy(B))],
                         radius=int(0.02 * SS), fill=(255, 255, 255, 46))
ov = Image.alpha_composite(ov, bar_layer)

# Area fill under the line
area_layer = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
ad = ImageDraw.Draw(area_layer)
area_poly = pts + [(int(sx(R)), int(sy(B))), (int(sx(L)), int(sy(B)))]
ad.polygon(area_poly, fill=(255, 255, 255, 60))
ov = Image.alpha_composite(ov, area_layer)

# Glow behind the line
glow_layer = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow_layer)
gd.line(pts, fill=(255, 255, 255, 220), width=int(0.05 * SS), joint="curve")
glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=int(0.02 * SS)))
ov = Image.alpha_composite(ov, glow_layer)

# Crisp line
d = ImageDraw.Draw(ov)
d.line(pts, fill=(255, 255, 255, 255), width=int(0.018 * SS), joint="curve")

# Data points: white dots with a soft dark ring
ring = int(0.014 * SS)
for x, y in pts:
    d.ellipse([x - ring, y - ring, x + ring, y + ring], fill=(0, 0, 0, 60))
    r = int(0.011 * SS)
    d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 255))

# Downscale the supersampled overlay and composite onto the gradient
ov = ov.resize((S, S), Image.LANCZOS)
final = Image.alpha_composite(base.convert("RGBA"), ov).convert("RGB")

out = "/Users/gizem/.cline/data/workspaces/chat/GraphStudio/GraphStudio/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
final.save(out, "PNG")
print("wrote", out, final.size)
