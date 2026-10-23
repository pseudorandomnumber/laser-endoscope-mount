// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 pseudorandomnumber
//
// Endoscope camera mount for diode laser modules
// Pick a preset in the Customizer's dropdown at the top (stored in
// endoscope_mount.json), or adjust the values and save your own preset.
// Requires BOSL2: https://github.com/BelfrySCAD/BOSL2
// Units: mm
//
// Coordinate system (seen from the front of the machine):
//   the module's right face is the plane x=0, the module is at x<0,
//   its bottom face is z=0, front is -Y. The camera sits on the right (+X),
//   below the module, and looks down and inward toward the beam.

include <BOSL2/std.scad>

/* [Mount type] */
// How the mount attaches to the laser module
mount_style = "clip"; // [clip, bottom_screws, side_plate]

/* [Laser module] */
// Module width, left to right
mod_w = 68; // [20:0.1:150]
// Module depth, front to back
mod_d = 44; // [20:0.1:150]
// Corner radius of the module housing, seen from below
mod_r = 3; // [0:0.1:15]
// Distance from the module's right face to the laser beam
beam_x = 32; // [0:0.1:150]
// Distance from the module's bottom face down to the focus point
focus_dist = 30; // [0:0.1:100]

/* [Clip mount] */
// Wall thickness of the band around the module
clip_wall = 2.4; // [1.2:0.1:5]
// Gap between band and module (increase if too tight)
clip_clearance = 0.3; // [0:0.05:1.5]
// Height of the band (keep it below the side vents)
clip_h = 10; // [5:0.1:40]
// Lip under the module's bottom edge, sets the height (0 = no lip)
clip_lip = 1.5; // [0:0.1:5]
// M3 clamp screw with captive nut on the front
clip_screw = true;

/* [Bottom screw mount] */
// Distance between the two bottom screws, front to back
screw_spacing = 35; // [5:0.1:120]
// Distance from the module's right face to the screw centers
screw_inset = 5.5; // [2:0.1:40]
// Screw hole diameter (2.9 for M2.5, 3.4 for M3)
screw_d = 2.9; // [1.5:0.1:6]
// Bracket thickness (the screws must be this much longer)
bracket_t = 3; // [1.5:0.1:8]
// Pad diameter around each screw
pad_d = 6.5; // [4:0.1:15]
// Height of the rail that rises along the module's right face
side_lip_h = 8; // [0:0.1:40]

/* [Side plate mount] */
// Distance between the two mounting screw holes, center to center
hole_spacing = 20; // [5:0.1:80]
// Screw hole diameter (3.4 for M3)
hole_d = 3.4; // [1.5:0.1:8]
// Mounting plate width, front to back
plate_w = 30; // [10:0.1:80]
// Mounting plate height
plate_h = 16; // [6:0.1:60]
// Mounting plate thickness
plate_t = 4; // [2:0.1:10]
// Height of the plate's lower edge above the module's bottom face
plate_z = 0; // [0:0.1:80]

/* [Endoscope] */
// Endoscope outer diameter, measured (common: 3.9, 5.5, 7, 8)
scope_d = 7; // [2:0.1:15]
// Extra diameter for fit (increase if too tight)
scope_clearance = 0.2; // [0:0.05:1]
// Length of the clamp collar along the scope
clamp_len = 12; // [4:0.1:40]
// Collar wall thickness
clamp_wall = 2.2; // [1:0.1:5]
// Snap opening as fraction of scope diameter (smaller = tighter snap)
snap_ratio = 0.75; // [0.6:0.01:0.9]

/* [Camera position] */
// Distance from the module's right face out to the lens center
cam_offset = 14; // [0:0.1:80]
// Distance from the mount's underside down to the lowest point of the lens (0 = flush)
cam_drop = 0; // [-20:0.1:80]
// Point the camera at the focus point automatically
aim_at_focus = true;
// Manual tilt from vertical toward the beam (used when aim_at_focus is off)
cam_tilt = 45; // [0:1:90]

/* [Preview] */
// Show a ghost endoscope (F5 preview only)
show_scope = true;
// Show a ghost laser module, beam and focus point (F5 preview only)
show_module = true;
// Show labeled dimensions (F5 preview only)
show_dims = true;

/* [Hidden] */
$fn = 64;
eps = 0.01;
dim_color = "Crimson";
beam_color = "DodgerBlue";
dim_text = 2.2;
ghost_h = 40;           // height of the ghost module
side_gap = 0.3;         // gap between brackets and the module's right face
nut_af = 5.5;           // M3 nut across flats
nut_t = 2.6;            // M3 nut thickness
boss_t = 6;             // clamp screw boss thickness

bore_d   = scope_d + scope_clearance;
collar_d = bore_d + 2 * clamp_wall;

// underside of the mount, the reference for cam_drop
mount_bottom = mount_style == "clip" ? -clip_lip
             : mount_style == "bottom_screws" ? -bracket_t
             : plate_z;

// lens center height for a given tilt: the lowest point of the tilted
// lens sits cam_drop below the mount's underside
function lens_z(t) = mount_bottom - cam_drop + scope_d / 2 * sin(t);
function aim(t) = atan2(cam_offset + beam_x, lens_z(t) + focus_dist);

// lens height and aim depend on each other, a few fixed-point steps converge
tilt     = aim_at_focus ? aim(aim(aim(aim(aim(45))))) : cam_tilt;
lens_pos = [cam_offset, 0, lens_z(tilt)];
cam_pos  = lens_pos + clamp_len / 2 * [sin(tilt), 0, cos(tilt)];   // collar center
focus_pt = [-beam_x, 0, -focus_dist];

clip_in  = [mod_w, mod_d] + 2 * [clip_clearance, clip_clearance];
clip_out = clip_in + 2 * [clip_wall, clip_wall];
clip_r   = mod_r + clip_clearance;       // inner corner radius
clip_x   = clip_clearance + clip_wall;   // band's right outer face

// ---------- camera collar ----------

module at_camera() {
    translate(cam_pos) yrot(tilt) children();
}

module collar() {
    at_camera() zcyl(d = collar_d, h = clamp_len);
}

module scope_cut() {
    at_camera() {
        // the bore runs on past the collar so the scope body and cable can exit
        down(clamp_len / 2 + 1) zcyl(d = bore_d, h = clamp_len + 80, anchor = BOTTOM);
        // snap opening on the outer side
        cuboid([collar_d, bore_d * snap_ratio, clamp_len + 2], anchor = LEFT);
    }
}

// space the module itself occupies, nothing may intrude; only as tall as
// needed, a huge cutter costs depth precision in the F5 preview
module module_keepout(c = 0) {
    h = max(clip_h, side_lip_h, plate_z + plate_h) + 1;
    translate([-mod_w / 2, 0, 0])
        cuboid([mod_w + 2 * c, mod_d + 2 * c, h], rounding = mod_r + c,
               edges = "Z", anchor = BOTTOM);
}

// ---------- clip ----------

module clip_body() {
    translate([-mod_w / 2, 0, -clip_lip])
        cuboid([clip_out.x, clip_out.y, clip_h + clip_lip],
               rounding = clip_r + clip_wall, edges = "Z", anchor = BOTTOM);
    if (clip_screw)
        translate([-mod_w / 2, -clip_out.y / 2 + eps, -clip_lip])
            cuboid([nut_af + 5, boss_t, clip_h + clip_lip],
                   rounding = 1, edges = [FRONT + LEFT, FRONT + RIGHT], anchor = BACK + BOTTOM);
}

module clip_cuts() {
    module_keepout(clip_clearance);
    // bottom opening inside the lip
    translate([-mod_w / 2, 0, 0])
        cuboid([clip_in.x - 2 * clip_lip, clip_in.y - 2 * clip_lip, 3 * clip_lip + 2],
               rounding = max(clip_r - clip_lip, 0), edges = "Z", anchor = CENTER);
    if (clip_screw) {
        zm = (clip_h - clip_lip) / 2;
        y_nut = -clip_out.y / 2 - boss_t / 2;
        translate([-mod_w / 2, y_nut, zm]) ycyl(d = 3.3, h = boss_t + 2 * clip_wall + 2);
        // captive nut, inserted from the top
        translate([-mod_w / 2, y_nut, zm]) {
            xrot(90) zrot(30) cylinder(d = (nut_af + 0.3) / cos(30), h = nut_t + 0.3, center = true, $fn = 6);
            cuboid([nut_af + 0.3, nut_t + 0.3, clip_h], anchor = BOTTOM);
        }
    }
}

// inset by eps so its faces don't coincide with the band's (preview flicker)
module clip_anchor() {
    translate([clip_x - clip_wall + eps, 0, -clip_lip + eps])
        cuboid([clip_wall - 2 * eps, collar_d, clip_h + clip_lip - 2 * eps],
               anchor = LEFT + BOTTOM);
}

// ---------- bottom screws ----------

screw_ys = [-screw_spacing / 2, screw_spacing / 2];

module bottom_body() {
    // rail outside the right face
    translate([side_gap, 0, -bracket_t])
        cuboid([bracket_t, screw_spacing + pad_d, bracket_t + side_lip_h],
               anchor = LEFT + BOTTOM);
    // a pad under each screw, bridged to the rail
    for (y = screw_ys)
        hull() {
            translate([-screw_inset, y, -bracket_t])
                zcyl(d = pad_d, h = bracket_t, anchor = BOTTOM);
            translate([side_gap, y, -bracket_t])
                cuboid([bracket_t, pad_d, bracket_t], anchor = LEFT + BOTTOM);
        }
}

module bottom_cuts() {
    for (y = screw_ys)
        translate([-screw_inset, y, 0]) zcyl(d = screw_d, h = 4 * bracket_t + 2);
}

// inset by eps so its faces don't coincide with the rail's (preview flicker)
module bottom_anchor() {
    translate([side_gap + eps, 0, -bracket_t + eps])
        cuboid([bracket_t - 2 * eps, collar_d, bracket_t + side_lip_h - 2 * eps],
               anchor = LEFT + BOTTOM);
}

// ---------- side plate ----------

module plate_body() {
    translate([0, 0, plate_z])
        cuboid([plate_t, plate_w, plate_h], rounding = 1.5, edges = "X",
               anchor = LEFT + BOTTOM);
}

module plate_cuts() {
    for (y = [-hole_spacing / 2, hole_spacing / 2])
        translate([0, y, plate_z + plate_h / 2]) xcyl(d = hole_d, h = 3 * plate_t);
}

module plate_anchor() {
    translate([0, 0, plate_z])
        cuboid([plate_t, collar_d, eps], anchor = LEFT + BOTTOM);
}

// ---------- assembly ----------

module mount() {
    difference() {
        union() {
            if (mount_style == "clip")         clip_body();
            if (mount_style == "bottom_screws") bottom_body();
            if (mount_style == "side_plate")   plate_body();
            hull() {
                if (mount_style == "clip")         clip_anchor();
                if (mount_style == "bottom_screws") bottom_anchor();
                if (mount_style == "side_plate")   plate_anchor();
                collar();
            }
        }
        if (mount_style == "clip")         clip_cuts();
        if (mount_style == "bottom_screws") bottom_cuts();
        if (mount_style == "side_plate")   plate_cuts();
        module_keepout();
        scope_cut();
    }
}

// ---------- preview helpers ----------

module dim_line(p1, p2, w = 0.25) {
    v = p2 - p1;
    if (norm(v) > 0.01)
        move(p1) rot(from = UP, to = v)
            cyl(d = w, h = norm(v), anchor = BOTTOM, $fn = 8);
}

module dim_arrow(p1, p2) {
    if (norm(p2 - p1) > 0.01) {
        v = unit(p2 - p1);
        dim_line(p1, p2);
        for (e = [[p1, v], [p2, -v]])
            move(e[0]) rot(from = UP, to = e[1])
                cyl(d1 = 0, d2 = 1.2, h = 2, anchor = BOTTOM, $fn = 12);
    }
}

// all labels face -Y so they read well in the default view
module label(pos, txt, halign = "center", valign = "bottom") {
    move(pos) xrot(90) linear_extrude(0.2)
        text(txt, size = dim_text, halign = halign, valign = valign);
}

module ghosts() {
    if (show_module) {
        %translate([-mod_w / 2, 0, 0])
            cuboid([mod_w, mod_d, ghost_h], rounding = mod_r, edges = "Z", anchor = BOTTOM);
        color(beam_color) {
            dim_line([-beam_x, 0, 0], focus_pt, 0.5);
            move(focus_pt) sphere(d = 1.6, $fn = 16);
            dim_line(lens_pos, focus_pt, 0.15);
        }
    }
    if (show_scope)
        %at_camera() down(clamp_len / 2) zcyl(d = scope_d, h = 60, anchor = BOTTOM, $fn = 32);
}

module dims() {
    front = mount_style == "clip" ? clip_out.y / 2 + (clip_screw ? boss_t : 0)
          : mount_style == "side_plate" ? max(mod_d, plate_w) / 2
          : max(mod_d, screw_spacing + pad_d) / 2;
    yf = -front - 3;                     // dimension plane in front of everything
    lens_low = lens_pos + scope_d / 2 * [cos(tilt), 0, -sin(tilt)];  // lowest point of the lens
    z_off = min(lens_low.z, mount_bottom) - collar_d / 2 - 4;      // cam_offset line
    x_drop = cam_pos.x + collar_d / 2 + clamp_len / 2 + 4;         // cam_drop line
    z_beam = min(-focus_dist, z_off) - 6;

    // module
    for (x = [-mod_w, 0])
        dim_line([x, yf, ghost_h], [x, yf, ghost_h + 4], 0.12);
    dim_arrow([-mod_w, yf, ghost_h + 3], [0, yf, ghost_h + 3]);
    label([-mod_w / 2, yf, ghost_h + 3.6], str("mod_w = ", mod_w));
    dim_arrow([-mod_w - 3, -mod_d / 2, ghost_h], [-mod_w - 3, mod_d / 2, ghost_h]);
    label([-mod_w - 4, -mod_d / 2, ghost_h], str("mod_d = ", mod_d), "right", "center");

    // beam and focus
    dim_line([0, yf, 0], [0, yf, z_beam - 1], 0.12);
    dim_line([-beam_x, yf, -focus_dist], [-beam_x, yf, z_beam - 1], 0.12);
    dim_arrow([-beam_x, yf, z_beam], [0, yf, z_beam]);
    label([-beam_x / 2, yf, z_beam - 0.8], str("beam_x = ", beam_x), "center", "top");
    xfl = -mod_w - 4;                    // focus_dist line, left of the module
    dim_line([-beam_x, yf, -focus_dist], [xfl - 1, yf, -focus_dist], 0.12);
    dim_line([-mod_w, yf, 0], [xfl - 1, yf, 0], 0.12);
    dim_arrow([xfl, yf, 0], [xfl, yf, -focus_dist]);
    label([xfl - 1, yf, -focus_dist / 2], str("focus_dist = ", focus_dist), "right", "center");

    // camera position
    dim_line([lens_pos.x, yf, lens_pos.z], [lens_pos.x, yf, z_off - 1], 0.12);
    dim_arrow([0, yf, z_off], [lens_pos.x, yf, z_off]);
    label([lens_pos.x / 2, yf, z_off - 0.8], str("cam_offset = ", cam_offset), "center", "top");

    dim_line([0, yf, mount_bottom], [x_drop + 1, yf, mount_bottom], 0.12);
    dim_line([lens_low.x, yf, lens_low.z], [x_drop + 1, yf, lens_low.z], 0.12);
    dim_arrow([x_drop, yf, mount_bottom], [x_drop, yf, lens_low.z]);
    label([x_drop + 1.5, yf, (mount_bottom + lens_low.z) / 2], str("cam_drop = ", cam_drop), "left", "center");

    label([x_drop + 1.5, yf, min(mount_bottom, lens_low.z) - 2.5],
          str("cam_tilt = ", round(tilt * 10) / 10, "°", aim_at_focus ? " (auto)" : ""),
          "left", "top");

    // endoscope, across the ghost scope beyond the collar, labels above it
    M = move(cam_pos) * yrot(tilt);
    zl = clamp_len / 2 + 10;
    for (x = [-scope_d / 2, scope_d / 2])
        dim_line(apply(M, [x, 0, zl - 1]), apply(M, [x, 0, zl + 1]), 0.12);
    dim_arrow(apply(M, [-scope_d / 2, 0, zl]), apply(M, [scope_d / 2, 0, zl]));
    dim_line(apply(M, [-scope_d / 2, 0, zl]), apply(M, [-scope_d / 2 - 4, 0, zl]), 0.12);
    pl = apply(M, [-scope_d / 2 - 4.5, 0, zl]);
    yl = -collar_d / 2 - 1;              // just in front of the scope
    label([pl.x, yl, pl.z], str("scope_d = ", scope_d), "center", "bottom");
    label([pl.x, yl, pl.z + 3.5], str("clamp_len = ", clamp_len), "center", "bottom");

    // style specific
    if (mount_style == "clip") {
        xl = -mod_w / 2 - clip_out.x / 2;
        dim_line([xl, yf, clip_h], [xl - 4, yf, clip_h], 0.12);
        dim_line([xl, yf, -clip_lip], [xl - 4, yf, -clip_lip], 0.12);
        dim_arrow([xl - 3, yf, -clip_lip], [xl - 3, yf, clip_h]);
        label([xl - 4, yf, (clip_h - clip_lip) / 2], str("clip_h = ", clip_h), "right", "center");
        label([xl - 4, yf, -clip_lip - 1],
              str("clip_wall = ", clip_wall, ", clip_lip = ", clip_lip), "right", "top");
    }
    if (mount_style == "bottom_screws") {
        zs = -bracket_t - 2;
        dim_line([-screw_inset, yf, -bracket_t], [-screw_inset, yf, zs - 1], 0.12);
        dim_arrow([-screw_inset, yf, zs], [0, yf, zs]);
        label([-screw_inset - 1, yf, zs], str("screw_inset = ", screw_inset), "right", "center");
        dim_arrow([-screw_inset, -screw_spacing / 2, -bracket_t - 0.5],
                  [-screw_inset, screw_spacing / 2, -bracket_t - 0.5]);
        label([-screw_inset - 1, yf, zs - 4.5], str("screw_spacing = ", screw_spacing), "right", "center");
        label([-screw_inset - 1, yf, zs - 9],
              str("screw_d = ", screw_d, ", bracket_t = ", bracket_t), "right", "center");
        xr = side_gap + bracket_t;
        dim_line([xr, yf, side_lip_h], [xr + 4, yf, side_lip_h], 0.12);
        dim_arrow([xr + 3, yf, 0], [xr + 3, yf, side_lip_h]);
        label([-1, yf, side_lip_h / 2], str("side_lip_h = ", side_lip_h), "right", "center");
    }
    if (mount_style == "side_plate") {
        xo = plate_t + 0.3;
        z1 = plate_z + plate_h;
        for (y = [-hole_spacing / 2, hole_spacing / 2])
            dim_line([xo, y, plate_z + plate_h / 2], [xo, y, z1 + 4], 0.12);
        dim_arrow([xo, -hole_spacing / 2, z1 + 3], [xo, hole_spacing / 2, z1 + 3]);
        label([xo + 1, hole_spacing / 2, z1 + 3], str("hole_spacing = ", hole_spacing), "left", "center");
        for (y = [-plate_w / 2, plate_w / 2])
            dim_line([xo, y, z1], [xo, y, z1 + 10], 0.12);
        dim_arrow([xo, -plate_w / 2, z1 + 9], [xo, plate_w / 2, z1 + 9]);
        label([xo + 1, plate_w / 2, z1 + 9], str("plate_w = ", plate_w), "left", "center");
        dim_arrow([xo, -plate_w / 2 - 3, plate_z], [xo, -plate_w / 2 - 3, z1]);
        label([-1, -plate_w / 2 - 3, plate_z + plate_h / 2], str("plate_h = ", plate_h), "right", "center");
        label([-1, -plate_w / 2 - 3, plate_z + plate_h / 2 - 4],
              str("hole_d = ", hole_d, ", plate_t = ", plate_t), "right", "center");
    }
}

mount();

if ($preview) ghosts();

if ($preview && show_dims)
    color(dim_color) dims();
