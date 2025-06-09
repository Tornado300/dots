
import cairo
import math

# ── 1) CONFIG ────────────────────────────────────────────────────────────────

OUTPUT_FILE = "pill_distance_gradient.png"

# Surface size (just for demo)
SURFACE_W, SURFACE_H = 400, 200

# “Full‐size” pill dimensions:
PILL_W, PILL_H = 300, 60

# Colors: edge_color (at distance = 0) → inside_color (distance = max_dist)
EDGE_COLOR   = (0.1, 0.2, 0.5)   # dark blue
INSIDE_COLOR = (0.9, 0.9, 1.0)   # very light blue

# How many “rings” we’ll draw.  More steps → smoother, but slower.
STEPS = 80


# ── 2) CREATE SURFACE + CONTEXT ─────────────────────────────────────────────

surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, SURFACE_W, SURFACE_H)
ctx = cairo.Context(surface)

# Optional: paint a light gray background for contrast
ctx.set_source_rgb(0.96, 0.96, 0.96)
ctx.paint()


# ── 3) PILL‐PATH HELPER ──────────────────────────────────────────────────────

def draw_pill_path(ctx, x, y, width, height):
    """
    Adds a “pill” (i.e. rectangle of size width×height with semicircles
    on the left/right ends) to the current path.  It does NOT fill/stroke—
    it just calls new_path() and builds the outline.
    """
    r = height / 2.0

    ctx.new_path()
    # 1) Left semicircle, from π/2 (down) → 3π/2 (up), CCW
    ctx.arc(x + r, y + r, r, math.pi/2, 3*math.pi/2)

    # 2) Top edge: from left‐circle’s top up to right‐circle’s top
    ctx.line_to(x + width - r, y)

    # 3) Right semicircle, from 3π/2 (up) → π/2 (down), CCW
    ctx.arc(x + width - r, y + r, r, 3*math.pi/2, math.pi/2)

    # 4) Bottom edge: from right‐circle’s bottom back to left‐circle’s bottom
    ctx.line_to(x + r, y + height)

    ctx.close_path()


# ── 4) DRAW CONCENTRIC PILLS ──────────────────────────────────────────────────

# Compute where to center the full‐size pill so it’s dead‐center on our surface:
origin_x = (SURFACE_W - PILL_W) / 2.0
origin_y = (SURFACE_H - PILL_H) / 2.0

# Maximum inset = half of pill height (that’s where the “distance” from boundary = PILL_H/2).
max_inset = PILL_H / 2.0

for i in range(STEPS + 1):
    t = i / STEPS
    # t = 0.0 → outer edge; t = 1.0 → inner-most point (pill’s vertical midline)
    #
    # We invert it so that:
    #   when i=0 → fraction = 0.0  → inset = 0    → color = EDGE_COLOR
    #   when i=STEPS → fraction = 1.0 → inset = max_inset → color = INSIDE_COLOR
    fraction = t

    # 4a) Compute how much to inset this step (linearly from 0 → max_inset)
    inset = fraction * max_inset

    # 4b) Interpolate the color: 
    #     C = EDGE_COLOR*(1-fraction) + INSIDE_COLOR*(fraction)
    r_c = (EDGE_COLOR[0]   * (1 - fraction) + INSIDE_COLOR[0]   * fraction)
    g_c = (EDGE_COLOR[1]   * (1 - fraction) + INSIDE_COLOR[1]   * fraction)
    b_c = (EDGE_COLOR[2]   * (1 - fraction) + INSIDE_COLOR[2]   * fraction)

    # 4c) Compute this pill’s bounding box:
    x = origin_x + inset
    y = origin_y + inset
    w = PILL_W  - 2 * inset
    h = PILL_H  - 2 * inset

    # Skip “negative” or extremely flat pills if offset > PILL_H/2
    if w <= 0 or h <= 0:
        continue

    # 4d) Draw and fill:
    draw_pill_path(ctx, x, y, w, h)
    ctx.set_source_rgb(r_c, g_c, b_c)
    ctx.fill()


# ── 5) SAVE ─────────────────────────────────────────────────────────────────

surface.write_to_png(OUTPUT_FILE)
print(f"Saved → {OUTPUT_FILE}")

