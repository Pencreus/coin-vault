"""Conservative sag check for a stacked Coin Vault tray (supported only at its end walls).

Usage: sag_check.py [Y63|H39|NICKEL|HALF|RECT|SLAB] ['{"floor_t": 2.4, ...}']

Assumptions (all chosen to over-predict sag):
  - load: every slot full, coin + capsule weight, uniform along the rows
  - long walls solid; X-brace diagonals would be ignored for bending if enabled
  - cradle interior = sparse infill counted at 5% of solid stiffness
  - PLA E = 2600 MPa short term; long-term creep modulus = E/3
"""
import numpy as np, sys, json
args = sys.argv[1:]
CAP = args.pop(0) if args and not args[0].startswith("{") else "Y63"
OV = json.loads(args[0]) if args else {}

# --- presets (match coin_vault.scad) ---
PRESETS = {
    #       cap_d  cap_t  side_h cradle_h  coin+capsule g
    "Y63": (71.37, 8.9,   30.0,  8.0,      155.5 + 25),   # 5 oz copper
    "H39": (44.45, 5.4,   19.0,  5.0,      31.1 + 6),     # 1 oz copper
    "NICKEL": (25.5, 6.0,   11.0,  4.0,      5.0 + 3),      # Buffalo nickel in a generic capsule
    "HALF":   (35.3, 6.0,   15.0,  5.0,      12.5 + 4),     # half dollar in a generic capsule
    # rectangular, portrait: cap_d = standing height, 6th value = width across the row (flat floor + locating channel)
    "RECT":   (57.5, 7.0,   24.0,  3.0,      15.0 + 10, 35.7),
    "SLAB":   (93.3, 8.0,   30.0,  3.0,      155.5 + 25, 62.5),   # 5 oz slab (heavier than the 5 mm / 1 oz slab)
}
_P = PRESETS[CAP]; cap_d, cap_t, side_h, cradle_h, coin_g = _P[:5]; cap_w = _P[5] if len(_P) > 5 else None
# shared footprint: every capsule type uses the 5 oz tray's outline so trays mix in a stack
FOOT_L_IN, FOOT_W = 24 * 8.9 + 1.5, 2 * (71.37 + 1.2) + 1.6 + 2 * 2.0
side, spine, clr_d, row_clr = 2.0, 1.6, 1.2, 1.5
rows = int((FOOT_W - 2 * side + spine) // ((cap_w or cap_d) + clr_d + spine) + 1e-9)
per_row = int((FOOT_L_IN - row_clr) // cap_t)

R = cap_d / 2; Rc = R + 0.5
floor_t = 5.0 if CAP == "SLAB" else 4.0   # matches coin_vault.scad (the bookend track cuts 2 mm of it away again)
strut, chord = 2.0, 4.0
side_h = OV.get("side_h", side_h); chord = OV.get("chord", chord); cradle_h = OV.get("cradle_h", cradle_h)
floor_t = OV.get("floor_t", floor_t)
# long outer walls grow inward to side_cap as far as the capsules allow (coin_vault.scad: hw_r / side_w)
r_ = cap_d / 2; dz_ = floor_t + r_ - side_h
hw = cap_w / 2 if cap_w else (r_ if dz_ <= 0 else (0 if dz_ >= r_ else (r_ ** 2 - dz_ ** 2) ** 0.5))
row_min = 2 * (hw + 0.6)
side_w = max(side, min(OV.get("side_cap", 4.0), (FOOT_W - (rows - 1) * spine - rows * row_min) / 2))
row_w = (FOOT_W - 2 * side_w - (rows - 1) * spine) / rows     # spare width goes to row clearance
lattice = OV.get("lattice", False)
lat_z0, lat_z1 = (floor_t + cradle_h + strut, side_h - chord) if lattice else (side_h, side_h)
W = FOOT_W
end_t = 2.0
L_in = FOOT_L_IN
span = L_in + end_t                        # end-wall centre to centre
n_coins = rows * per_row
print(f"{CAP}: {rows} rows x {per_row} = {n_coins} capsules, row width {row_w:.2f}, long walls {side_w:.1f} mm, floor_t {floor_t}")
BOT, TOP, PERIM = 0.6, 1.0, 0.84           # bottom skin, top skin, 2 perimeters

def row_y0(r): return side_w + r * (row_w + spine)

h = 0.02
ys = np.arange(0, W, h) + h / 2
zs = np.arange(0, side_h, h) + h / 2
Y, Z = np.meshgrid(ys, zs)
wgt = np.zeros_like(Y)

# walls: solid below the lattice and in the top chord, nothing in between
def wall(y0, y1):
    m = (Y >= y0) & (Y < y1) & ((Z < lat_z0) | (Z >= lat_z1))
    wgt[m] = 1.0
wall(0, side_w); wall(W - side_w, W)
for r in range(1, rows):
    y = row_y0(r) - spine; wall(y, y + spine)

# cradles
for r in range(rows):
    yc = row_y0(r) + row_w / 2
    inrow = (Y >= row_y0(r)) & (Y < row_y0(r) + row_w)
    dist_arc = (np.abs(Y - yc) - (cap_w + clr_d) / 2) if cap_w else np.sqrt((Y - yc) ** 2 + (Z - (floor_t + Rc)) ** 2) - Rc   # >0 = material side
    solid = inrow & (Z < floor_t + cradle_h) & (dist_arc > 0)
    skin = solid & ((Z < BOT) | (dist_arc < TOP) | (Z > floor_t + cradle_h - TOP)
                    | (Y < row_y0(r) + PERIM) | (Y > row_y0(r) + row_w - PERIM))
    wgt[solid] = np.maximum(wgt[solid], 0.05)
    wgt[skin] = 1.0

dA = h * h
A = (wgt * dA).sum()
zbar = (wgt * Z * dA).sum() / A
I = (wgt * (Z - zbar) ** 2 * dA).sum()
c_top, c_bot = side_h - zbar, zbar

load_N = n_coins * coin_g / 1000 * 9.81
q = load_N / span
E, E_long = 2600.0, 2600.0 / 3
M = q * span ** 2 / 8
d_bend = 5 * q * span ** 4 / (384 * E * I)

# shear: truss diagonals (2 per panel at 45 deg) in 3 walls, plus the cradle skins
A_d = strut * np.array([side_w, side_w, spine])
S_truss = (2 * E * A_d * np.sin(np.pi/4) ** 2 * np.cos(np.pi/4)).sum()
d_shear = q * span ** 2 / (8 * S_truss) if lattice else 0.0    # ignores the cradle's own shear area: conservative

print(f"load {load_N:.0f} N over {span:.0f} mm span, section EI uses I = {I/1e3:.1f} x10^3 mm^4 (neutral axis z={zbar:.2f})")
for lab, e in (("short term", E), ("long term (creep, E/3)", E_long)):
    db = d_bend * E / e; ds = d_shear * E / e
    print(f"  {lab:24s} bending {db:.3f} mm + truss shear {ds:.3f} mm = {db+ds:.3f} mm")
print(f"  peak bending stress: top chord {M*c_top/I:.2f} MPa (compression), cradle bottom {M*c_bot/I:.2f} MPa (tension)")

# --- local: the 1.2 mm strip at the bottom centre of the cradle, across the row ---
# Treat it as a simply supported strip across the row with a central line load.
# It thickens with the arc: t(y) = floor_t + (Rc - sqrt(Rc^2 - y^2)), skins only.
q_row = load_N / rows / L_in               # N per mm along the row
yy = np.linspace(-row_w / 2, row_w / 2, 4001); dy = yy[1] - yy[0]
t = (floor_t + cradle_h * (np.abs(yy) > (cap_w + clr_d) / 2)) if cap_w else floor_t + (Rc - np.sqrt(np.maximum(Rc ** 2 - yy ** 2, 0)))
t = np.minimum(t, floor_t + cradle_h)
t = t - 1.0 * (np.abs(yy) < 6.0) - 1.0 * (np.abs(yy) < 3.0)      # bookend track: 12 mm x 1 mm step + 6 mm x 1 mm step
# sandwich: bottom skin + top skin (solid where t < BOT+TOP), core at 5%
core = np.maximum(t - BOT - TOP, 0)
def I_strip(ti, ci):
    if ci <= 0: return ti ** 3 / 12
    sk_b, sk_t = BOT, TOP
    zc = (sk_b * sk_b / 2 + sk_t * (ti - sk_t / 2) + 0.05 * ci * (sk_b + ci / 2)) / (sk_b + sk_t + 0.05 * ci)
    return (sk_b ** 3 / 12 + sk_b * (zc - sk_b / 2) ** 2 + sk_t ** 3 / 12 + sk_t * (ti - sk_t / 2 - zc) ** 2
            + 0.05 * (ci ** 3 / 12 + ci * (sk_b + ci / 2 - zc) ** 2))
Is = np.array([I_strip(a, b) for a, b in zip(t, core)])
P = q_row                                  # per mm of row length
Mloc = np.where(yy < 0, P / 2 * (yy + row_w / 2), P / 2 * (row_w / 2 - yy))
# unit-load method: deflection at centre = integral M*m/(EI)
m = Mloc / P
d_loc = (Mloc * m / (E_long * Is)).sum() * dy
sig_loc = (Mloc * (t / 2) / Is).max()
print(f"local cradle strip across the row (long term): centre deflection {d_loc:.3f} mm, peak stress {sig_loc:.2f} MPa")
print(f"worst case (global + local, long term): {d_bend*E/E_long + d_shear*E/E_long + d_loc:.2f} mm vs clearance 3.0 mm (1.85 mm over a bookend foot)")


# --- stack load on the bottom tray's corner posts (end-wall lattice ignored) ---
n_stack = 6
H_tray = floor_t + cap_d + 3.0
per_tray = load_N + 0.25 * 9.81                      # coins + ~250 g of tray
P_post = (n_stack - 1) * per_tray / 4
ring = 4 * 9 * PERIM - 4 * PERIM ** 2                # 2 perimeters, 9 mm square post
I_ring = (9 ** 4 - (9 - 2 * PERIM) ** 4) / 12
P_euler = np.pi ** 2 * E_long * I_ring / H_tray ** 2  # pinned-pinned, creep modulus
print(f"{n_stack}-tray stack: {P_post:.0f} N per bottom post, {P_post/ring:.1f} MPa in the perimeters, "
      f"buckling capacity {P_euler:.0f} N long term (x{P_euler/P_post:.1f})")
