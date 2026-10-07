// Coin Vault: slab tray for 90 x 60 mm copper slabs (5 oz).
// Slabs stand on their long edge, face to face, like files. A sliding bookend
// holds a part-full row upright. Not a stacking part: no posts, pins or lid.
// Axes: X = along a row (slab faces point along X), Y = across rows, Z = up.
// Prints as modelled, no supports.

/* [Part] */
part = "tray"; // [tray, bookend, preview]

/* [Slab] */
slab_long = 90;  // capsule outside size
slab_short = 60;
orientation = "portrait"; // [portrait:Portrait - stands on the 60 edge, 90 tall, landscape:Landscape - stands on the 90 edge, 60 tall]
slab_t = 8.0;    // capsule thickness: typical 5 oz slab capsules are 7-8 mm; 8 fits both
slab_g = 155.5;  // weight, for the echo only

/* [Layout] */
footprint = "match coin trays"; // [match coin trays:Match the 1 oz / 5 oz trays (233.1 x 150.7), fit:Sized from rows x per_row]
rows = 2;        // [1:1:3]
per_row = 0;     // [0:1:80] 0 = as many as fit (match: 26 at 8 mm)
row_clr = 2.0;   // minimum slack along a full row
clr_w = 1.2;     // clearance across the row

/* [Structure] */
floor_t = 3.0;   // only loaded while carried by the handles: 0.29 mm then (2.4 mm would be 0.52)
side_min = 2.0;  // long side walls (match mode: spare width goes into these, making thick rigid sides)
side_h = 25;     // low enough to push a slab up by its side edge
end_h = 55;      // end walls only stop the end slab tipping (this tray doesn't stack)
spine = 1.6;     // divider between rows
end_t = 2.4;     // end walls, carry the load when lifted by the handles
handle = 7;      // handle ledge depth, 45 deg gusset underneath (7 = the coin trays' post depth)
ledge_t = 3;
label_d = 0.6;
label_h = 12;
strut = 2.0;     // solid band above the floor before any opening
end_pattern = "hex"; // [hex, diamond, teardrop, xbrace, solid] end walls (see patterns.scad)
web = 3.0;       // minimum material between openings
cell = 16;       // nominal opening size

/* [Stacking] */
sits_on_coin_trays = true; // corner feet with sockets so this tray sits on a 1 oz / 5 oz tray (match footprint only)
foot_post = 9;   // the coin trays' corner post (square)
foot_h = 6.5;    // socket 3.5 deep + 3 mm roof
pin_h = 3;       // the coin trays' tapered pins...
pin_r0 = 2.6;
pin_r1 = 1.8;
sock_clr = 0.25; // ...and the same socket clearance the lid uses

/* [Bookend] */
book_t = 2.4;
foot_t = 1.0;
foot_slabs = 6;  // slabs that stand on the foot and hold it down

/* [Hidden] */
include <patterns.scad>
eps = 0.01;
slab_w = orientation == "portrait" ? slab_short : slab_long;   // edge it stands on
slab_h = orientation == "portrait" ? slab_long : slab_short;   // standing height
row_w = slab_w + clr_w;
// the coin trays' outline: 24 x 8.9 + 1.5 inside, 2 mm end walls, 7 mm posts; 2 rows of 72.57 + 1.6 + 2 x 2
FOOT_X = 24 * 8.9 + 1.5 + 2 * 2.0 + 2 * 7;
FOOT_Y = 2 * (71.37 + 1.2) + 1.6 + 2 * 2.0;
match = footprint == "match coin trays";
l_in = match ? FOOT_X - 2 * end_t - 2 * handle : per_row * slab_t + row_clr;
n_per_row = per_row > 0 ? per_row : floor((l_in - row_clr) / slab_t + 1e-6);
W = match ? FOOT_Y : rows * row_w + (rows - 1) * spine + 2 * side_min;
side = (W - rows * row_w - (rows - 1) * spine) / 2;
H = end_h;
assert(side >= side_min - 1e-6, "rows don't fit the coin-tray footprint");
assert(n_per_row * slab_t + row_clr <= l_in + 1e-6, "too many slabs for the row length");
X0 = 0;
X1 = l_in + 2 * end_t;

function row_y0(r) = side + r * (row_w + spine);
function row_yc(r) = row_y0(r) + row_w / 2;

module box(a, b) translate(a) cube(b - a);
module yz_extrude(x0, x1) multmatrix([[0, 0, 1, x0], [1, 0, 0, 0], [0, 1, 0, 0]]) linear_extrude(x1 - x0) children();

label_z1 = H - ledge_t - handle - 3;
label_z0 = label_z1 - label_h;
end_v0 = floor_t + strut + 2;
end_v1 = label_z0 - strut;
module end_holes() wall_pattern_2d(end_pattern, side + web, W - side - web, end_v0, end_v1, web, cell);

// Handle ledge: flange flush at the top, 45 deg gusset below. 3D hull, not a 2D
// polygon (OpenSCAD's 2D grid snapping breaks coplanar faces).
module ledge(xw, sgn) {
    xi = xw - sgn * 1;
    hull() {
        box([min(xi, xw + sgn * handle), 0, H - ledge_t], [max(xi, xw + sgn * handle), W, H]);
        box([min(xi, xw), 0, H - ledge_t - handle - 1], [max(xi, xw), W, H]);
    }
}

// coin-tray post positions: posts stand handle (=7) proud of each end wall, flush with the long sides
feet = [for (x = [X0 - handle, X1 + handle - foot_post]) for (y = [0, W - foot_post]) [x, y]];
module socket()
    translate([0, 0, -eps]) cylinder(h = pin_h + 0.5 + eps, r1 = pin_r0 + sock_clr, r2 = pin_r1 + sock_clr - 0.1, $fn = 64);

module tray() {
    spines = [for (r = [1:1:rows - 1]) row_y0(r) - spine];
    stack = sits_on_coin_trays && match;
    difference() {
        union() {
            if (stack) for (f = feet) box([f[0], f[1], 0], [f[0] + foot_post, f[1] + foot_post, foot_h]);
            box([X0, 0, 0], [X1, W, floor_t]);
            box([X0, 0, 0], [X1, side, side_h]);
            box([X0, W - side, 0], [X1, W, side_h]);
            for (y = spines) box([X0, y, 0], [X1, y + spine, side_h]);
            box([X0, 0, 0], [X0 + end_t, W, H]);
            box([X1 - end_t, 0, 0], [X1, W, H]);
            ledge(X0, -1);
            ledge(X1, 1);
        }
        if (end_pattern != "solid") {
            yz_extrude(X0 - 1, X0 + end_t + 1) end_holes();
            yz_extrude(X1 - end_t - 1, X1 + 1) end_holes();
        }
        if (stack) for (f = feet) translate([f[0] + foot_post / 2, f[1] + foot_post / 2, 0]) socket();
        box([X0 - 1, side + 4, label_z0], [X0 + label_d, W - side - 4, label_z1]);
        box([X1 - label_d, side + 4, label_z0], [X1 + 1, W - side - 4, label_z1]);
    }
}

// Sliding bookend in use position: plate face at x = 0, slabs on +X standing on
// the flat foot. Their weight pins it down.
module bookend_in_place() {
    bw = row_w - 1.0;
    plate_h = 0.7 * slab_h;
    foot_l = foot_slabs * slab_t + book_t;
    difference() {
        union() {
            box([-book_t, -bw / 2, floor_t], [0, bw / 2, floor_t + plate_h]);
            box([-book_t, -bw / 2 + 4, floor_t], [foot_l, bw / 2 - 4, floor_t + foot_t]);
        }
        // finger hole to slide it along
        translate([-book_t - 1, 0, floor_t + 0.62 * plate_h])
            multmatrix([[0, 0, 1, 0], [0, 1, 0, 0], [-1, 0, 0, 0]]) cylinder(h = book_t + 2, r = 9, $fn = 64);
    }
}

// Print orientation: plate flat on the bed, foot standing up.
module bookend() multmatrix([[0, 1, 0, 0], [0, 0, 1, -floor_t], [1, 0, 0, book_t]]) bookend_in_place();

module slabs(n)
    for (r = [0:rows - 1], i = [0:n - 1])
        translate([X0 + end_t + 0.3 + i * slab_t, row_yc(r) - slab_w / 2, floor_t + 0.05])
            cube([slab_t - 0.1, slab_w, slab_h]);

echo(str("slab tray: ", rows, " x ", n_per_row, " = ", rows * n_per_row, " slabs, ~",
         rows * n_per_row * (slab_g + 25) / 1000, " kg full (incl. capsules), tray ", X1 - X0 + 2 * handle, " x ", W,
         " x ", H, ", side walls ", side_h, " tall x ", side, " thick"));

if (part == "tray") tray();
else if (part == "bookend") bookend();
else {
    color("Peru") tray();
    color("Chocolate") slabs(n_per_row);
}
