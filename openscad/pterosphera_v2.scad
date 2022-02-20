include <BOSL2/std.scad>
include <switch_socket/switch_socket.scad>
use <trackball/trackball_socket.scad>

// TODO: (case): Add prorer dedicated "reset" button hole, instead of mounting in back hole.

col_extra_h_pcnt = 0.16; // extra vertical padding to the switches for the columns (percent in decimal form).
home_row = 3; // The row to align to
finger_col_mgn = 3; // The margin betwen each finger's set of columns (exclude on index finger)
finger_col_xtra_mgn = 0.7; // Extra margin to appli to problem fingers (ring, pinky)

// Finger measurements for more finite column placement (millimeters)
r_f_i_r = 48.2; // right finger, index, radius (the radius of the right index finger), etc:
r_f_m_r = 55;
r_f_r_r = 51.5;
r_f_p_r = 41.5;

r_f_i_y = 49.8; // right finger, index, distance from first knuckle joint - the y-offset from "zero" for starting the arc of the index finger, measured from the first knucle to the second knuckle (towards the tip).
r_f_m_y = 53.2;
r_f_r_y = 51;
r_f_p_y = 38.1;

// Column Data
index_cols = 2;
index_rows = 4;
index_arc = r_f_i_r + switch_full_height;

middle_cols = 1;
middle_rows = 5;
middle_arc = r_f_m_r + switch_full_height;

ring_cols = 1;
ring_rows = 5;
ring_arc = r_f_r_r + switch_full_height;

pinky_cols = 2;
pinky_rows = 4;
pinky_arc = r_f_p_r + switch_full_height;

// Modules
module hand_cols() {
    // Render each set of columns for the fingers
    translate([0, r_f_i_y, 0]) socket_cols_arc(index_cols, index_rows, index_arc);

    translate([(_mx_socket_perim_wh * index_cols + finger_col_xtra_mgn) + finger_col_mgn, 0, 0]) {
        translate([0, r_f_m_y, 0]) socket_cols_arc(middle_cols, middle_rows, middle_arc);

        translate([(_mx_socket_perim_wh * middle_cols) + finger_col_mgn + finger_col_xtra_mgn, 0, 0]) {
            translate([0, r_f_r_y, 0]) socket_cols_arc(ring_cols, ring_rows, ring_arc);

            translate([(_mx_socket_perim_wh * ring_cols) + finger_col_mgn + finger_col_xtra_mgn, 0, 0]) {
                translate([0, r_f_p_y, 0]) socket_cols_arc(pinky_cols, pinky_rows, pinky_arc);
            }
        }
    }
}

module socket_cols_arc(cc, rc, r) {
    for(i = [0 : cc - 1]) {
        translate([i * _mx_socket_perim_wh, 0, 0]) socket_col_arc(rc, r);
    }
}

module socket_col_arc(count, radius) {
    s_circ_p = (_mx_socket_perim_wh * (count-1)) - 0.1; // the portion of the circle that is taken up by the switches.
    t_circ_inner = 2*PI*radius; // the full circumference on the face of the socket
    t_circ_outer = 2*PI*(radius + mx_socket_total_depth); // the full outer circumference, on the bottom of the socket.
    outer_radius = t_circ_outer / (PI * 2); // the radius of the outer circle
    s_pct_p = s_circ_p / t_circ_outer; // the percentage of the circumference that the keys represent
    s_deg_p = s_pct_p * 180; // half of the degrees represented by the percentage of the keys around the circle

    deg_each = (s_deg_p * 2) / count;
    eh_b = (tan(deg_each) * mx_socket_total_depth);
    eh = (_mx_socket_perim_wh * col_extra_h_pcnt) + eh_b;

    s_circ = ((_mx_socket_perim_wh + (eh)) * (count-1)) + (eh * 1.1);

    s_pct = s_circ / t_circ_inner; // the percentage of the circumference that the keys represent
    s_deg = s_pct * (360 / count); // the degrees represented by each switch

    sc = count - home_row - 0.5 - 1; // The number of switches above our home row; -1 for OBOB, -0.5 to center on the home row switch
    ec = count - sc + 0.5 - 1; // The number of switches after our home row; -1 for OBOB, +0.5 to add the second half of the home row switch

    sa = sc * s_deg * -1; // the start point of the arc - swing back to align the home row; 0/360 is center
    ea = ec * s_deg; // the end point of the arc - swing forard for the rest of the switches

    translate([0, 0, radius]) rotate([0, 90, 0]) {
        if(debug_markers) {
            circle_inner = regular_ngon(n=64, or=radius);
            color("red") stroke(circle_inner,width=0.1,closed=true);
        }
        arc_of(r=radius,n=count,sa=sa,ea=ea) rotate([0, -90, 0]) translate([0, 0, 0]) mx_socket(true, eh);
    }
}

debug_markers = false;
hand_cols();

//socket_cols_arc(2, 3, pinky_arc);

 //translate([-20, 0, 0]) trackball_socket();
