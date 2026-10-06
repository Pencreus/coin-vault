// Wall opening patterns for Coin Vault parts. Every pattern is a set of 2D holes
// in a (u, v) zone: u runs along the wall, v is up (the print's Z), so overhangs
// are judged against v. Shared by coin_vault.scad and slab_tray.scad.
//
//   xbrace   : diamonds + triangles (Warren truss). Triangle tops are flat bridges.
//   hex      : flat-top honeycomb. Tops are short bridges (one hex side).
//   diamond  : diamonds only, 45 deg everywhere, no bridges at all.
//   teardrop : round holes with a 45 deg point on top, no bridges.
//   solid    : nothing.

// X-brace (Warren) truss: a row of diamonds with triangles between them.
module pat_xbrace_row(u0, u1, v0, v1, web) {
    a = (v1 - v0) / 2;
    vc = v0 + a;
    p = 2 * a + web * sqrt(2);
    n = floor((u1 - u0 - 2 * a) / p) + 1;
    uc = (u0 + u1) / 2 - (n - 1) * p / 2;
    d = web / sqrt(2);
    for (i = [0:n - 1]) translate([uc + i * p, vc]) polygon([[a, 0], [0, a], [-a, 0], [0, -a]]);
    for (i = [0:n - 2]) let(um = uc + (i + 0.5) * p, w = a - d) {
        polygon([[um, vc + d], [um + w, vc + a], [um - w, vc + a]]);
        polygon([[um, vc - d], [um - w, vc - a], [um + w, vc - a]]);
    }
}

// Diamonds only: the web between neighbours is narrowest (= web) at mid-height.
module pat_diamond_row(u0, u1, v0, v1, web) {
    a = (v1 - v0) / 2;
    vc = v0 + a;
    p = 2 * a + web;
    n = floor((u1 - u0 - 2 * a) / p) + 1;
    uc = (u0 + u1) / 2 - (n - 1) * p / 2;
    for (i = [0:n - 1]) translate([uc + i * p, vc]) polygon([[a, 0], [0, a], [-a, 0], [0, -a]]);
}

// Rows stacked with a solid web between tiers, so struts stay short on tall walls.
module pat_tiers(u0, u1, v0, v1, web, cell, kind) {
    tiers = max(1, round((v1 - v0) / cell));
    th = (v1 - v0 - (tiers - 1) * web) / tiers;
    for (k = [0:tiers - 1]) let(t0 = v0 + k * (th + web)) {
        if (kind == "xbrace") pat_xbrace_row(u0, u1, t0, t0 + th, web);
        else pat_diamond_row(u0, u1, t0, t0 + th, web);
    }
}

// Staggered grid of a cell shape of half-width hw and half-height hh, only whole cells.
module pat_grid(u0, u1, v0, v1, hw, hh, dx, dz) {
    nx = floor((u1 - u0 - 2 * hw) / dx) + 1;
    us = (u0 + u1) / 2 - (nx - 1) * dx / 2;
    nz = floor((v1 - v0 - 2 * hh) / dz) + 1;          // rows that fit unstaggered
    vs = (v0 + v1) / 2 - (nz - 1) * dz / 2;
    stag = (v1 - v0) >= 2 * hh + dz / 2 + 0.01;       // room for an offset row?
    for (i = [0:nx - 1], j = [0:nz - 1])
        let(u = us + i * dx, v = vs + j * dz + (stag && i % 2 == 1 ? dz / 2 : 0))
            if (v - hh >= v0 - 0.01 && v + hh <= v1 + 0.01) translate([u, v]) children();
}

module hex_cell(r) circle(r, $fn = 6);       // vertex at +u: flat top and bottom
module teardrop_cell(r) hull() { circle(r, $fn = 48); translate([0, r * sqrt(2)]) square(0.01, center = true); }

module wall_pattern_2d(kind, u0, u1, v0, v1, web, cell) {
    if (kind == "xbrace" || kind == "diamond") pat_tiers(u0, u1, v0, v1, web, cell, kind);
    else if (kind == "hex") {
        r = min(cell / 2, (v1 - v0) / sqrt(3));
        R = r + web / sqrt(3);
        hh = sqrt(3) / 2 * r;
        stag = (v1 - v0) >= 2 * hh + sqrt(3) * R / 2;
        // honeycomb spacing when columns can stagger, else a single row side by side
        pat_grid(u0, u1, v0, v1, r, hh, stag ? 1.5 * R : 2 * r + web, sqrt(3) * R) hex_cell(r);
    }
    else if (kind == "teardrop") {
        r = min(cell / 2 * 0.8, (v1 - v0) / (1 + sqrt(2)));
        hh = r * (1 + sqrt(2)) / 2;                    // cell spans -r .. r*sqrt2 about its centre
        pat_grid(u0, u1, v0, v1, r, hh, 2 * r + web, 2 * hh + web)
            translate([0, -(r * sqrt(2) - r) / 2]) teardrop_cell(r);
    }
}
