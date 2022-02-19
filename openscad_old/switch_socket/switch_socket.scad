// Generating switch sockets myself

// 16mm - wide spot
// 13.9mm - narrow x tall
// 0.05mm as non-accumulatung tolerance
// 5.3mm center tab
// 1mm from corner
// Means that distance between centers of two keys should be 19mm +/-0.05mm.
// And sum of distances between centers of 11 keys should be 190mm +/-0.05mm, not 190.5mm.

$fn = 36;

switch_full_height = 19.2; // Measured from base to top of keycap (excluding the pins) - calibrated to a DSA row 3 keycap.

mx_socket_color = "purple";
mx_socket_wh = 13.9;
mx_cutout_from_edge = 1;
mx_center_tab_h = 5.8;
mx_socket_total_depth = 5;

_mx_cutout_w = mx_socket_wh + (mx_cutout_from_edge * 2);
_mx_cutout_h = (mx_socket_wh - (mx_cutout_from_edge * 2) - mx_center_tab_h) / 2;

mx_top_plate_depth = 1.4;
_mx_hole_clearance = 0.01;
_mx_hole_depth = mx_top_plate_depth + (_mx_hole_clearance * 2);
_mx_socket_depth = mx_socket_total_depth - mx_top_plate_depth; // work out the depth of the base portion of the socket by removing the plate portion

mx_clip_hole_w = 5;
mx_clip_hole_h = 2.5;
mx_clip_hole_d = 1.2;
_mx_clip_hole_y = mx_socket_wh + (mx_clip_hole_d * 2);

// Amoeba Mount
am_screw_dist = 18.8180; // Distance between center of screws
am_screw_hole_r_top = 1.25; // The radius of the screw hole at the top
am_screw_hole_r_btm = am_screw_hole_r_top / 1.11; // The radius of the screw hole at the bottom (tapered for heat-insert)
am_screw_hole_thck = 1.1; // The thickness of the screw hole wall
am_screw_hole_dpth = 3.7; // The height of the insert, less 0.2mm (the insert for the smallest is 3.9mm, the hole depth for it is 3.7mm)
_am_screw_mount_r = am_screw_hole_r_top + am_screw_hole_thck; // The calculated radius of the screw mount
_am_screw_mount_h = mx_socket_total_depth; // _mx_socket_depth; //am_screw_hole_dpth + am_screw_hole_thck; // The calculated height of the screw mount

mx_socket_clearance_min = am_screw_dist - mx_socket_wh;
_mx_socket_perim_wh = mx_socket_wh + mx_socket_clearance_min;
_mx_socket_hole_x_ofst = (mx_socket_clearance_min / 2) - mx_cutout_from_edge;
_mx_socket_hole_y_ofst = mx_socket_clearance_min / 2;

module mx_socket(center, extra_height) {
    eh = extra_height ? extra_height : 0;
    ty = center ? (_mx_socket_perim_wh + eh) / -2 : 0;
    sh = _mx_socket_perim_wh + eh;
    translate([0, ty, 0]) union() {
        mx_plate(extra_height);
        difference() {
            union() {
                translate([0, 0, _mx_socket_depth * -1]) {
                    difference() {
                        cube([_mx_socket_perim_wh, sh, _mx_socket_depth]);
                        translate([_mx_socket_hole_x_ofst, _mx_socket_hole_y_ofst + (extra_height / 2), -0.1]) cube([_mx_cutout_w, mx_socket_wh, _mx_socket_depth + 0.2]);
                        color("red") translate([(_mx_socket_perim_wh / 2) - (mx_clip_hole_w / 2), (sh / 2) - (_mx_clip_hole_y / 2), (_mx_socket_depth - mx_clip_hole_h)]) cube([mx_clip_hole_w, _mx_clip_hole_y, mx_clip_hole_h + 0.1]);
                    }
                }
                am_mounts(false, false, eh);
            }
            am_mounts(true, true, eh);
        }
    }
}

module mx_hole_tab_h() {
    cube([_mx_cutout_w, _mx_cutout_h, _mx_hole_depth]);
}

module mx_plate_hole() {
    translate([0, 0, _mx_hole_clearance * -1]) union() {
        cube([mx_socket_wh, mx_socket_wh, _mx_hole_depth]);
        translate([mx_cutout_from_edge * -1, mx_cutout_from_edge, 0]) {
            mx_hole_tab_h();
            translate([0, mx_center_tab_h + _mx_cutout_h, 0]) {
                mx_hole_tab_h();
            }
        }
    }
}

module mx_plate(extra_height) {
    difference() {
        color(mx_socket_color) cube([_mx_socket_perim_wh, _mx_socket_perim_wh + extra_height, mx_top_plate_depth]);
        translate([(mx_socket_clearance_min / 2), (mx_socket_clearance_min / 2) + (extra_height / 2), 0]) {
            color(mx_socket_color) mx_plate_hole();
        }
    }
}


module am_screw_mount(render_holes, holes_only) {
    difference() {
        if (!holes_only) cylinder(r=_am_screw_mount_r, h=_am_screw_mount_h);
        if (render_holes) color("red") translate([0, 0, (_am_screw_mount_h - am_screw_hole_dpth) + 0.01]) cylinder(r1 = am_screw_hole_r_btm, r2 = am_screw_hole_r_top, h = am_screw_hole_dpth + 0.01);
    }
}

module am_mounts(render_holes, holes_only, extra_height) {
    rotate([180, 0, 0]) translate([(_mx_socket_perim_wh / 2) - (am_screw_dist / 2), (_mx_socket_perim_wh + extra_height) / -2, mx_top_plate_depth * -1]) {
        am_screw_mount(render_holes, holes_only);
        translate([am_screw_dist, 0, 0]) am_screw_mount(render_holes, holes_only);
    }
}