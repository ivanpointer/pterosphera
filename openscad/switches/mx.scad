include <../common.scad>

// X = WIDTH = W
// Y = HEIGHT = H
// Z = DEPTH = D
// BB = BOUNDING BOX = B

// Generating switch sockets myself

// 16mm - wide spot
// 13.9mm - narrow x tall
// 0.05mm as non-accumulatung tolerance
// 5.3mm center tab
// 1mm from corner
// Means that distance between centers of two keys should be 19mm +/-0.05mm.
// And sum of distances between centers of 11 keys should be 190mm +/-0.05mm, not 190.5mm.

mx_switch_full_height = 19.2; // Measured from base to top of keycap (excluding the pins) - calibrated to a DSA row 3 keycap.
mx_switch_min_clearance = 4; // The minimum amount of clearance below the switches in the case to allow for room for the electronics.

// // Amoeba Mount
// Distance between center of screws
am_screw_dist = 18.8180;

am_screw_hole_top_R = 1.25; // The radius of the screw hole at the top
am_screw_hole_btm_R_ratio = 1.11; // The radius of the screw hole at the bottom (tapered for heat-insert)
am_screw_hole_thck = 1.1; // The thickness of the screw hole wall
am_screw_hole_D = 3.7; // The height of the insert,


// The width/height of the hole for a MX switch
mx_socket_WH = 13.9;

// The width/height of the perimiter of the socket, from which the hole is cut.
mx_socket_perim_WH = am_screw_dist;
mx_socket_perim_W = mx_socket_perim_WH;
mx_socket_perim_H = mx_socket_perim_WH;

// The total depth of the socket for a MX swith - the distance below the surface of the plate that the switch's bottom rests - I.E. where the PCB/hotswap socket sits.
mx_socket_total_D = 5;

// The depth of the top plate - the distance between the lip of the MX switch, and the clip that holds the MX switch in place.
mx_top_plate_D = 1.4;

// The distance from the top edge of the plate that the first cutout for the tabs for opening the switch (in place) are (such as for switches soldered into place).
mx_tabs_Y_mgn = 1;

// The height of the tab holes in the top plate for accessing the tabs to open the switch (such as for switches soldered into place).
mx_tab_H = 3;

// _mx_cutout_w = mx_socket_wh + (mx_cutout_from_edge * 2);
// _mx_cutout_h = (mx_socket_wh - (mx_cutout_from_edge * 2) - mx_center_tab_h) / 2;

// _mx_hole_clearance = 0.01;
// _mx_hole_depth = mx_top_plate_depth + (_mx_hole_clearance * 2);
// _mx_socket_depth = mx_socket_total_depth - mx_top_plate_depth; // work out the depth of the base portion of the socket by removing the plate portion

// The width of the hole for the MX switch clip - how far along the X axis the hole is.
mx_clip_hole_W = 5;

// The height of the hole for the MX switch clip - how far into the side of the socket the hole cuts
mx_clip_hole_H = 1.2;

// The depth of the hole for the MX switch clip - how far down the socket (under the plate) the hole extends.
mx_clip_hole_D = 2.5;
// _mx_clip_hole_y = mx_socket_wh + (mx_clip_hole_d * 2);

// less 0.2mm (the insert for the smallest is 3.9mm, the hole depth for it is 3.7mm)

// _am_screw_mount_r = am_screw_hole_r_top + am_screw_hole_thck; // The calculated radius of the screw mount
// _am_screw_mount_h = mx_socket_total_depth; // _mx_socket_depth; //am_screw_hole_dpth + am_screw_hole_thck; // The calculated height of the screw mount

// mx_socket_clearance_min = am_screw_dist - mx_socket_wh;
// _mx_socket_perim_wh = mx_socket_wh + mx_socket_clearance_min;
// _mx_socket_hole_x_ofst = (mx_socket_clearance_min / 2) - mx_cutout_from_edge;
// _mx_socket_hole_y_ofst = mx_socket_clearance_min / 2;

// Modules 
module mx_socket(center = false) {
    center_if(f_am_screw_sheaths_W(), mx_socket_perim_WH, mx_socket_total_D, center)
        right((f_am_screw_sheaths_W() - mx_socket_perim_WH) / 2) {
        difference() {
            union() {
                // Render the first bit of the socket
                difference() {
                    // Render the main socket border
                    dcolor("purple") cube([mx_socket_perim_WH, mx_socket_perim_WH, mx_socket_total_D]);

                    // Cut out the center hole
                    dcolor("red") right((mx_socket_perim_WH - mx_hole_W()) / 2)
                        back((mx_socket_perim_WH - mx_hole_H()) / 2)
                        down(weld_mgn)
                        mx_hole();
                }

                // Add in the sheath for the amoeba screw holes
                dcolor("white") back((mx_socket_perim_WH /2) - f_am_screw_sheath_R())
                    right((mx_socket_perim_WH - f_am_screw_sheaths_W()) / 2)
                    am_screw_sheaths();
            }

            // Cut out the amoeba screw holes
            down(weld_mgn)
                back((mx_socket_perim_WH / 2) - am_screw_hole_top_R)
                left( ((am_screw_dist + (am_screw_hole_top_R * 2)) - mx_socket_perim_WH) / 2 )
                    dcolor("red") am_holes();
        }
    }
}

module mx_hole(center = false) {
    // The highest parts of the model - needed for conditionally centering
    base_W = mx_hole_base_W();
    base_H = mx_hole_base_H();
    base_D = mx_hole_base_D();
    clip_hole_H = base_H + (mx_clip_hole_H * 2);

    // Orient the model
    union() center_if(base_W, clip_hole_H, mx_socket_total_D, center) {
        // Shift everything to make clearance for the clip hole and screw holes
        back(mx_clip_hole_H) {
            // Cut out the base 
            cube([base_W, base_H, base_D]);

            // Cut out the clip hole
            up(base_D - mx_clip_hole_D) right((base_W - mx_clip_hole_W) / 2) fwd(mx_clip_hole_H) cube([mx_clip_hole_W, clip_hole_H, mx_clip_hole_D]);

            // Cut out the top plate
            plate_D = mx_top_plate_D + (weld_mgn * 2);
            up(base_D - weld_mgn) {
                // Cut out the center
                right(mx_tabs_Y_mgn) cube([mx_socket_WH, mx_socket_WH, plate_D]);

                // Cut out the tabs
                tabs_H = (base_H - (mx_tabs_Y_mgn * 2));
                back(mx_tabs_Y_mgn) {
                    cube([base_W, mx_tab_H, plate_D]);
                    back(tabs_H - mx_tab_H) cube([base_W, mx_tab_H, plate_D]);
                }
            }
        }
    }
}

module am_screw_sheaths(center = false) {
    // Work out the sheath dimensions
    sheath_R = f_am_screw_sheath_R();
    sheath_Dia = sheath_R * 2;
    sheath_D = mx_socket_total_D;

    // Center the model if told to
    center_if(am_screw_dist + sheath_Dia, sheath_Dia, sheath_D)
        back(sheath_R) right(sheath_R) {
            // The first sheath
            cylinder(r = sheath_R, h = sheath_D);

            // The second sheath
            right(am_screw_dist) cylinder(r = sheath_R, h = sheath_D);
    }
}

function f_am_screw_sheath_R() = am_screw_hole_top_R + am_screw_hole_thck;
function f_am_screw_sheaths_W() = am_screw_dist + (f_am_screw_sheath_R() * 2);

module am_holes(center = false) {
    center_if(am_screw_dist, am_screw_hole_top_R * 2, am_screw_hole_D, center)
        back(am_screw_hole_top_R) right(am_screw_hole_top_R) {
            am_screw_hole();
            right(am_screw_dist) am_screw_hole();
        }
}

module am_screw_hole() {
    cylinder(r1 = am_screw_hole_top_R, r2 = am_screw_hole_top_R / am_screw_hole_btm_R_ratio, h = am_screw_hole_D + weld_mgn);
}

function mx_hole_plate_D() = mx_top_plate_D + weld_mgn;
function mx_hole_W() = mx_hole_base_W();
function mx_hole_base_W() = mx_socket_WH + (mx_tabs_Y_mgn * 2);
function mx_hole_H() = mx_hole_base_H() + (mx_clip_hole_H * 2);
function mx_hole_base_H() = mx_socket_WH;
function mx_hole_base_D() = mx_socket_total_D - mx_top_plate_D + weld_mgn;

function mx_socket_bounding_box() = [mx_socket_perim_W, mx_socket_perim_H, mx_socket_total_D];
