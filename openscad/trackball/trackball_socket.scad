use <../BOSL/transforms.scad>

// General Settings
sphere_res = 144; //36; // Resolution for the spheres
cyl_res = sphere_res / 2; // Resolution for the cylinders
tb_render = false; // Render the trackball
sm_render = true; // Render the sensor mount
skt_render = true; // Render the socket
btus_render = false; // Render the BTUs
tp_render = true; // render the top plate

// Trackball Settings
tb_color = "black";
tb_dia = 34;

_tb_rad = tb_dia / 2;

// Socket Settings
skt_color = "purple";
skt_clearance = 2;
skt_wall_thick = 3.5;

_skt_hole_dia = tb_dia + (skt_clearance * 2);
_skt_dia = _skt_hole_dia + (skt_wall_thick * 2);

// Top Plate
tp_color = "pink";
tp_thickness = 5; // The thickness of the top plate
tp_clearance = 0.6; // The clearence for the ball in the top plate
_tp_hole_r_top = exp(ln(exp(ln(tb_dia / 2)*2) - exp(ln(tp_thickness)*2))*0.5) + tp_clearance; // Calculate the positional radius for the hole in the top plate based on its distance from center, and the given clearance.
_tp_hole_r_btm = (tb_dia / 2) + (tp_clearance * 2);
echo("Top Plate Hole Radius (top, bottom)", _tp_hole_r_top, _tp_hole_r_btm);

// Sensor Mount
sm_color = "blue";
sm_scrw_dist = 24; // Distance between centers on screw mounts
sm_scrw_dia_top = 3.1; // Top dia for screw insert hole
sm_scrw_dia_btm = 2.8; // Bottom dia for screw insert hole
sm_scrw_mgn = 1.1; // The margin around the screw holes
sm_scrw_dpth = 3.7; // Depth of the hole for the screw insert
sm_scrw_cap_dia = sm_scrw_mgn + sm_scrw_dia_btm; // Diameter of the cap on top of the screw holes for the sensor module

sm_base_h = 21; // The height of the sensor mount base
sm_skt_dia = 9; // The diameter of the hole for the sensor lens
sm_base_d = 1.5; // The fixed depth of the mount base; important as the lens distance from the ball is touchy
sm_skt_z_ofst = 2.6; // The offset for the sensor module, pushing up into the socket, working with the above
sm_rot_z = 0; // Rotate the sensor mount across the Z axis

_sm_base_w = sm_scrw_dist + ((sm_scrw_dia_top + sm_scrw_mgn) * 2); // The width of the sensor mount base

// BTU
btu_color = "white"; // The color of rendered BTUs
btu_hle_tol = 0.25; // The tolerance around the BTU for the holes
btu_base_dia = 12.7; // The diameter of the stem of the BTU
btu_base_dpth = 8; // The depth of the stem of the BTU
btu_head_dia = 14.5; // The diameter of the head portion of the BTU
btu_head_dpth = 1; // The depth of the head portion of the BTU
btu_ball_dia = 8.4; // The diameter of the ball in the BTU
btu_ball_z_offset = -0.2; // The z-offset of the BTU ball off the head
btu_z_mult = 1.3;

btu_count = 3;
btu_tilt = -55;
btu_ring_z = 6.3;

_btu_base_dia = btu_base_dia + (btu_hle_tol * 2);
_btu_base_dpth = btu_base_dpth + btu_hle_tol;

_btu_head_dia = btu_head_dia + (btu_hle_tol * 2);
_btu_head_dpth = btu_head_dpth + btu_hle_tol;
_btu_ball_z_offset = btu_ball_dia * btu_ball_z_offset;
_btu_head_top = _btu_base_dpth + _btu_head_dpth;
_btu_ball_height = (btu_ball_dia / 2) - _btu_ball_z_offset;

btu_ring_r = (_skt_hole_dia / 2) + _btu_ball_height - 1;

// Trackball Render
if (tb_render) {
    translate([0, 0, (tb_dia / 2) + skt_wall_thick + skt_clearance]) {
        color(tb_color) sphere(d = tb_dia, $fn=sphere_res);
    }
}

// Socket Render
module socket_base() {
    translate([0, 0, _skt_dia / 2]) difference() {
        color(skt_color) sphere(d = _skt_dia, $fn=sphere_res); // Socket
        sphere(d = _skt_hole_dia, $fn=sphere_res); // Socket hole
        translate([0, 0, _skt_dia]) cube(_skt_dia * 2, center=true); // Cut off top half
    }
}

module trackball_socket() {
    union() {
        difference() {
            union() {
                socket_base();
                if (tp_render) top_plate();
            }
            if (sm_render) sensor_mount(false);
            btus();
        }
        if (sm_render) sensor_mount(true);
    }
}

if (skt_render) trackball_socket();

module top_plate() {
    color(tp_color) translate([0, 0, (_skt_dia / 2) - 0.1]) {
        difference() {
            cylinder(d = _skt_dia, h = tp_thickness, $fn = sphere_res);
            translate([0, 0, -0.5]) cylinder(r2 = _tp_hole_r_top, r1 = _tp_hole_r_btm, h = tp_thickness + 1, $fn = sphere_res);
        }
    }
}

// Sensor Mount
echo("Sensor Mount Depth: ", sm_base_d);

module sensor_mount(for_render) {
    rotate([180, 0, sm_rot_z]) yrot(a = -10, cp = [0, 0, (_skt_dia / -2)]) translate([_sm_base_w / -2, sm_base_h / -2, (sm_base_d + sm_skt_z_ofst) * -1]) {
        if (for_render) {
            difference() {
                union() {
                    sm_base(true);
                    sm_scrw_caps();
                }
                trns_scrw_holes() sm_scrw_hles();
                sm_skt_hle();
            }
        } else {
            union() {
                sm_base(false);
                trns_scrw_holes() sm_scrw_hles();
                sm_skt_hle();
            }
        }
    }
}

module sm_base(for_render) {
    d = for_render ? sm_base_d : sm_base_d + sm_skt_z_ofst;
    color(sm_color) cube([_sm_base_w, sm_base_h, d]);
}

module sm_scrw_hles() {
    sm_scrw_hle();
    trns_scrw_hole() {
        sm_scrw_hle();
    }
}

module sm_scrw_hle() {
    cylinder(r1 = sm_scrw_dia_top / 2, r2 = sm_scrw_dia_btm / 2, h = sm_scrw_dpth, $fn=cyl_res);
}

module sm_scrw_caps() {
    trns_scrw_holes() {
        sm_scrw_cap();
        trns_scrw_hole() {
            sm_scrw_cap();
        }
    }
}

module sm_scrw_cap() {
    color(sm_color) translate([0, 0, (sm_scrw_mgn * -1) - 0.001]) cylinder(d = sm_scrw_cap_dia, h=(sm_scrw_dpth + sm_scrw_mgn), $fn=cyl_res);
}

module trns_scrw_holes() {
    translate([(sm_scrw_dia_top / 2) + sm_scrw_mgn, (sm_base_h / 2), (sm_base_d - sm_scrw_dpth) + 0.001]) children();
}

module trns_scrw_hole() {
    translate([sm_scrw_dist + sm_scrw_dia_top, 0, 0]) children();
}

module sm_skt_hle() {
    ho = 0.001;
    translate([_sm_base_w / 2, sm_base_h / 2, ho * -1]) {
        cylinder(r = (sm_skt_dia / 2), h = (sm_base_d + sm_skt_z_ofst) + ho, $fn = cyl_res);
    }
}

// For testing purposes
if (sm_render) sensor_mount(true);

// BTUs
if (btus_render) btus(true);

module btus(for_render) {
    union() {
        translate([0, 0, btu_ring_z]) zring(n=btu_count, r=btu_ring_r)
            yrot(btu_tilt) btu(for_render);
    }
}

module btu(for_render) {
    union() {
        btu_base();
        translate([0, 0, _btu_base_dpth  - 0.001]) {
            btu_head(for_render);
            if (for_render) {
                translate([0, 0, _btu_ball_z_offset + _btu_head_dpth]) {
                    btu_ball();
                }
            }
        }
    }
}

module btu_base() {
    color(btu_color) cylinder(d = _btu_base_dia, h = _btu_base_dpth, $fn = cyl_res);
}

module btu_head(for_render) {
    h = for_render ? _btu_base_dpth : _btu_base_dpth + _btu_ball_height;
    color(btu_color) cylinder(d = _btu_head_dia, h = h, $fn = cyl_res);
}

module btu_ball() {
    color(btu_color) sphere(d = btu_ball_dia, $fn = sphere_res);
}

// top_plate();
