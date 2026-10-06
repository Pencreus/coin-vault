// Coin Vault: stackable trays for Air-Tite capsules: Y63 (5 oz rounds) and H39 (1 oz).
// Every capsule type shares one footprint and post pattern, so 1 oz and 5 oz trays
// stack together under the same lid.
// Capsules stand on edge, face to face, in a curved cradle. A sliding bookend
// holds a part-full row upright. Trays stack on corner posts with tapered pins,
// and each tray's floor is the lid of the one below.
// Axes: X = along a row, Y = across rows, Z = up. Prints as modelled, no supports.

/* [Part] */
part = "tray"; // [tray, lid, bookend, preview_stack]

/* [Capsule] */
capsule = "Y63"; // [Y63:Y63 - 5 oz rounds, H39:H39 - 1 oz rounds]

/* [Layout] */
footprint = "shared"; // [shared:Shared - stacks with every other tray, custom:Custom - sized from rows x per_row]
rows = 0;        // [0:1:6] 0 = as many as fit
per_row = 0;     // [0:1:45] 0 = as many as fit
row_clr = 1.5;   // minimum slack along a full row
clr_d = 1.2;     // row clearance, across the capsule diameter
top_clr = 3.0;   // gap above the capsule to the next tray's floor (sag margin)

/* [Structure] */
floor_t = 3.0;   // under the lowest point of the cradle. Do not thin: see sag_check.py
cradle_clr = 0.5;// cradle radius over the capsule radius
side = 2.0;      // long side walls
// side_h and cradle_h come from the capsule preset below
spine = 1.6;     // divider between rows
end_t = 2.0;     // end walls, full height
post = 9;        // square corner post
ledge_t = 3;     // handle ledge flange (45 deg gusset below)
label_d = 0.6;   // recessed label panel depth
lid_t = 5.0;     // flat slab; sockets are 3.5 deep, leaving a 1.5 mm roof over them

/* [Wall openings] */
end_pattern = "hex"; // [hex, diamond, teardrop, xbrace, solid] end walls (see patterns.scad)
web = 3.0;       // minimum material between openings
cell = 16;       // nominal opening size
wall_pattern = "solid"; // [solid, hex, diamond, teardrop, xbrace] long walls + spine. Openings here
                         // make a stacked tray sag ~2.6x more (sag_check.py) to save ~13 g: keep solid
strut = 2.0;     // solid band above the cradle before any opening
chord = 4;       // solid rail along the top of each wall
end_solid = 14;  // solid wall length next to each end (highest shear)
label_h = 14;    // label strip height, in the solid band under the ledge

/* [Bookend] */
book_t = 2.4;    // plate thickness
foot_t = 1.0;    // curved foot the capsules stand on

/* [Stacking pins] */
pin_h = 3;
pin_r0 = 2.6;
pin_r1 = 1.8;
sock_clr = 0.25;

/* [Hidden] */
include <patterns.scad>
$fn = 96;
eps = 0.01;

// Capsule presets. Air-Tite specs: Y63 = 71.37 OD x 8.9 closed; H39 = 44.45 OD x 5.4 closed.
//              cap_d  cap_t  side_h  cradle_h
PRESETS = [["Y63", 71.37, 8.9,  30,     8],
           ["H39", 44.45, 5.4,  19,     5]];
P = PRESETS[search([capsule], PRESETS)[0]];
cap_d = P[1];
cap_t = P[2];
side_h = P[3];   // ~42% of the capsule: low enough to grip a rim from the side
cradle_h = P[4];

// The shared footprint is the 5 oz tray's: 2 rows x 24 Y63 capsules.
FOOT_L_IN = 24 * 8.9 + 1.5;
FOOT_W = 2 * (71.37 + 1.2) + 1.6 + 2 * 2.0;
R = cap_d / 2;
Rc = R + cradle_clr;
fit_rows = floor((FOOT_W - 2 * side + spine) / (cap_d + clr_d + spine) + 1e-6);
fit_per_row = floor((FOOT_L_IN - row_clr) / cap_t + 1e-6);
n_rows = rows > 0 ? rows : fit_rows;
n_per_row = per_row > 0 ? per_row : fit_per_row;
shared = footprint == "shared";
// shared: spare width goes into row clearance (the cradle still centres each capsule)
row_w = shared ? (FOOT_W - 2 * side - (n_rows - 1) * spine) / n_rows : cap_d + clr_d;
l_in = shared ? FOOT_L_IN : n_per_row * cap_t + row_clr;
W = shared ? FOOT_W : n_rows * row_w + (n_rows - 1) * spine + 2 * side;
H = floor_t + cap_d + top_clr;
assert(!shared || (n_rows <= fit_rows && n_per_row <= fit_per_row), "too many capsules for the shared footprint");

// bookend scales with the capsule
foot_l = max(24, 4.5 * cap_t);   // ~4.5 capsules stand on the foot and hold it down
foot_w = 0.62 * cap_d;
plate_h = 0.645 * cap_d;
out_ = post - end_t;          // how far posts stand proud of the end walls
X0 = 0;
X1 = l_in + 2 * end_t;

function row_y0(r) = side + r * (row_w + spine);
function row_yc(r) = row_y0(r) + row_w / 2;
corners = [for (x = [X0 - out_, X1 + out_ - post]) for (y = [0, W - post]) [x, y]];

module box(a, b) translate(a) cube(b - a);

// 2D (x, z) shape extruded along Y from y0 to y1. Exact matrix, no rotate().
module xz_extrude(y0, y1) multmatrix([[1, 0, 0, 0], [0, 0, 1, y0], [0, 1, 0, 0]]) linear_extrude(y1 - y0) children();
// 2D (y, z) shape extruded along X from x0 to x1.
module yz_extrude(x0, x1) multmatrix([[0, 0, 1, x0], [1, 0, 0, 0], [0, 1, 0, 0]]) linear_extrude(x1 - x0) children();

module pin() cylinder(h = pin_h, r1 = pin_r0, r2 = pin_r1);
module socket()
    translate([0, 0, -eps])
        cylinder(h = pin_h + 0.5 + eps, r1 = pin_r0 + sock_clr, r2 = pin_r1 + sock_clr - 0.1);

// ---- wall lattice: 2D holes in the (x, z) plane of a long wall ----
lat_x0 = X0 + end_t + end_solid;
lat_x1 = X1 - end_t - end_solid;
lat_z0 = floor_t + cradle_h + strut;   // bottom chord = cradle + one strut
lat_z1 = side_h - chord;

// End walls: openings between the posts, from the cradle up to a solid top band
// that carries the label strip and the handle ledge.
label_z1 = H - ledge_t - out_ - 3;
label_z0 = label_z1 - label_h;
end_v0 = floor_t + cradle_h + strut;
end_v1 = label_z0 - strut;
module end_holes() wall_pattern_2d(end_pattern, post + web, W - post - web, end_v0, end_v1, web, cell);

module lattice_cut(y0, y1)
    if (wall_pattern != "solid") xz_extrude(y0 - 1, y1 + 1) wall_pattern_2d(wall_pattern, lat_x0, lat_x1, lat_z0, lat_z1, web, cell);

// Cradle under one row: a block up to cradle_h with the capsule arc cut out.
// The capsule's lowest point lands at floor_t.
module cradle(yc)
    yz_extrude(X0 + end_t - eps, X1 - end_t + eps)
        difference() {
            translate([yc - row_w / 2 - eps, 0]) square([row_w + 2 * eps, floor_t + cradle_h]);
            translate([yc, floor_t + Rc]) circle(Rc, $fn = 192);
        }

module ledge(xw, sgn) {
    // 3 mm flange flush with the posts, 45 deg gusset underneath. Built with a 3D
    // hull, not a 2D polygon: OpenSCAD snaps 2D to a fixed grid, which leaves the
    // top a hair off the post tops and the STL comes out non-manifold.
    xi = xw - sgn * 1;    // 1 mm into the end wall
    y0 = post / 2; y1 = W - post / 2;
    hull() {
        box([min(xi, xw + sgn * out_), y0, H - ledge_t], [max(xi, xw + sgn * out_), y1, H]);
        box([min(xi, xw), y0, H - ledge_t - out_ - 1], [max(xi, xw), y1, H]);
    }
}

module tray() {
    spines = [for (r = [1:1:n_rows - 1]) row_y0(r) - spine];
    difference() {
        union() {
            box([X0, 0, 0], [X1, W, floor_t]);
            for (r = [0:n_rows - 1]) cradle(row_yc(r));
            box([X0, 0, 0], [X1, side, side_h]);
            box([X0, W - side, 0], [X1, W, side_h]);
            for (y = spines) box([X0, y, 0], [X1, y + spine, side_h]);
            box([X0, 0, 0], [X0 + end_t, W, H]);
            box([X1 - end_t, 0, 0], [X1, W, H]);
            for (c = corners) {
                box([c[0], c[1], 0], [c[0] + post, c[1] + post, H]);
                translate([c[0] + post / 2, c[1] + post / 2, H - eps]) pin();
            }
            ledge(X0, -1);
            ledge(X1, 1);
        }
        for (c = corners) translate([c[0] + post / 2, c[1] + post / 2, 0]) socket();
        lattice_cut(0, side);
        lattice_cut(W - side, W);
        for (y = spines) lattice_cut(y, y + spine);
        if (end_pattern != "solid") {
            yz_extrude(X0 - 1, X0 + end_t + 1) end_holes();
            yz_extrude(X1 - end_t - 1, X1 + 1) end_holes();
        }
        // recessed label strips on the outer end-wall faces
        lz0 = label_z0; lz1 = label_z1;
        ly0 = post + 3; ly1 = W - post - 3;
        box([X0 - 1, ly0, lz0], [X0 + label_d, ly1, lz1]);
        box([X1 - label_d, ly0, lz0], [X1 + 1, ly1, lz1]);
    }
}

// Flat cap for the top of a stack: one solid slab, flat on both faces, with the
// stacking sockets in its underside. Prints as modelled, on its underside.
module lid() {
    difference() {
        box([X0 - out_, 0, 0], [X1 + out_, W, lid_t]);
        for (c = corners) translate([c[0] + post / 2, c[1] + post / 2, 0]) socket();
    }
}

// Sliding bookend, modelled in use position (row centre at y = 0, plate face at
// x = 0, capsules on +X standing on the foot). Their weight pins the foot down.
module bookend_in_place() {
    difference() {
        union() {
            // plate: the capsule silhouette, cut off at plate_h
            yz_extrude(-book_t, 0) intersection() {
                translate([0, floor_t + Rc]) circle(Rc - 0.6, $fn = 192);
                translate([-row_w / 2, 0]) square([row_w, floor_t + plate_h]);
            }
            // curved foot lying in the cradle
            yz_extrude(-book_t, foot_l) intersection() {
                difference() {
                    translate([0, floor_t + Rc]) circle(Rc - 0.15, $fn = 192);
                    translate([0, floor_t + Rc]) circle(Rc - 0.15 - foot_t, $fn = 192);
                }
                translate([-foot_w / 2, 0]) square([foot_w, floor_t + cradle_h]);
            }
        }
        // finger hole to slide it along
        yz_extrude(-book_t - 1, 1) translate([0, floor_t + 0.42 * cap_d]) circle(max(6.5, 0.126 * cap_d));
    }
}

// Print orientation: plate flat on the bed, foot standing up.
module bookend() multmatrix([[0, 1, 0, 0], [0, 0, 1, -floor_t], [1, 0, 0, book_t]]) bookend_in_place();

module capsules(n)
    for (r = [0:n_rows - 1], i = [0:n - 1])
        translate([X0 + end_t + i * cap_t + 0.05, row_yc(r), floor_t + R + 0.05])
            multmatrix([[0, 0, 1, 0], [0, 1, 0, 0], [-1, 0, 0, 0]]) cylinder(h = cap_t - 0.1, r = R);

echo(str(capsule, ": ", n_rows, " rows x ", n_per_row, " = ", n_rows * n_per_row, " capsules, tray ", X1 - X0 + 2 * out_, " x ", W, " x ", H));
if (part == "tray") tray();
else if (part == "lid") lid();
else if (part == "bookend") bookend();
else if (part == "capsules_full") capsules(n_per_row);   // render helper, not printed
else {
    for (k = [0:2]) translate([0, 0, k * H]) {
        color("Peru") tray();
        color("LightSteelBlue", 0.6) capsules(k == 2 ? round(n_per_row * 0.6) : n_per_row);
    }
    // a part-full top tray, held up by its bookends
    for (r = [0:n_rows - 1])
        color("DarkSlateGray") translate([X0 + end_t + round(n_per_row * 0.6) * cap_t + 0.3, row_yc(r), 2 * H])
            mirror([1, 0, 0]) bookend_in_place();
    color("DimGray") translate([0, 0, 3 * H]) lid();
}
