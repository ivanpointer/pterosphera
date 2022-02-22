include <../switches/mx.scad>
include <../BOSL2/std.scad>

// The offset for the bevel around the columns ( [X/Y, Z] )
case_col_offset = [ 8, 4 ];

module switch_col_arc(count, home_row, radius, debug = false) {
    _switch_col_arc_C(count, home_row, radius, debug);
}

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module _switch_col_arc_A(count, home_row, radius, debug = false) {
    // TODO: The arc angle (degrees) needs to be calculated from the radius coming in, not the radius plus the full key height - this is to ensure enough spacing for the head of the keycap...
    // TODO: The top of the plate needs to be offset by the height between the keycap and the plate, not the full height of the key, which sits below the top of the plate.

    // Render the arc of switch bases
    pts = switch_col_pts(count,home_row,radius,0);
    fcs = switch_base_faces(count);

    difference() {
        polyhedron(points = pts, faces = fcs);

        // DEBUG STUFF:
        // ------------

        // CUT OUT THE SOCKETS!!  (for a dry run, this is the wrong place/time to be cutting these out - the whole case has to be wrapped first...)
        socket_coords = _get_switch_points_and_angles(count,home_row,radius, mx_socket_perim_W / 2);
        echo(socket_coords);
        union() {
            for (c = socket_coords) {
                color("red")
                    translate([c.x, c.y, c.z])
                    yrot(c[3])
                    down((mx_socket_total_D / 2) - weld_mgn)
                        mx_hole(center = true);
            }
        }
    }

    // Render a reference point
    if (debug) color("black") sphere(1);

    // Number the points if in dev mode
    if (debug) {
        for (i = [0:len(pts)-1]) {
            color("blue") translate(pts[i]) text3d(str(i), 2, 4);
        }
    }
}

module _switch_col_arc_B(count, home_row, finger_radius, debug = false) {
    // A helper function for calculating the length of the triangle with a given angle (A) and hypotenuse (c)
    a = function(c,A) c * sin(A);

    // The angle we're working with, taken from the radius at the finger
    A = _col_a(finger_radius);

    // Then, project out to the surface of the switch socket, and work out the height at that distance.
    distance_to_top = finger_radius + (mx_switch_full_height - mx_socket_total_D);
    top_height = a(distance_to_top, A);

    // Finally, project the height of the base of the shape
    distance_to_bottom = distance_to_top + mx_socket_total_D;
    bottom_height = a(distance_to_bottom, A);

    // Work out the dimensions of the prismoid
    width = mx_socket_perim_W;
    btm = [width, bottom_height];
    top = [width, top_height];
    h = mx_socket_total_D;

    // Render
    xrot(A * (count - home_row)) _prismoid_arc(btm, top, h, A, count);
}

module _switch_col_arc_C(n,o,r,debug = false) {
    pts = col_arc_pts(n,o,r);
    pths = [[ for(i=[0:1]) for(j=[0:n]) i == 0 ? j : ((n + 1) * 2) - j - 1 ]];
    echo(pths);

    linear_extrude(mx_socket_perim_W) {
        polygon(points = pts, paths = pths);
    }

    for(p = pts) {
        color("purple") translate(p) sphere(1);
    }
}

module _prismoid_arc(btm, top, h, A, c, i = 0) {

    if (i < c) {
        prismoid(btm, top, h, anchor=BACK+BOTTOM);
        fwd(btm[1]) xrot(-A)
            _prismoid_arc(btm, top, h, A, c, i + 1);
    }

    children();
}

function _col_rt(r) = r + (mx_switch_full_height - mx_socket_total_D);
function _col_rb(r) = _col_rt(r) + mx_socket_total_D;
function _col_a(r) = asin(mx_socket_perim_H / r);
function _col_ao(c,h,r) =
    90 // Rotate over to the right quadrant
    + (_col_a(r) * c) // Rotate counter-clockwise for each switch
    + (_col_a(r) * (h - c + 0.5)); // Rotate forward to bring the home switch onto the bottom
function _col_angles(c,h,r) = [ _col_rt(r), _col_rb(r), _col_a(r), _col_ao(c,h,r) ];
function switch_col_pts(c,h,r,y) = _switch_col_join(
    _switch_col_pts_y(col_arc_pts(c,h,r), y),
    _switch_col_pts_y(col_arc_pts(c,h,r), y + mx_socket_perim_W)
);
function _switch_col_join(v1,v2) = [ for(v = [v1,v2]) for(p = v) p ];
function _switch_col_pts_y(vp,y) = [ for(v = vp) [ v[0], y, v[1] ] ];
function col_arc_pts(c,h,r) = _col_arc_join(
    _col_arc_join_xy(
        _arc_of_points_cos([],c+1,0,_col_a(r),_col_ao(c,h,r),_col_rt(r)),
        _arc_of_points_sin([],c+1,0,_col_a(r),_col_ao(c,h,r),_col_rt(r))
    ),_col_arc_join_xy(
        _arc_of_points_cos([],c+1,0,_col_a(r),_col_ao(c,h,r),_col_rb(r)),
        _arc_of_points_sin([],c+1,0,_col_a(r),_col_ao(c,h,r),_col_rb(r))
    )
);
function _col_arc_join(at,ab) = [ for(a = [at,ab]) for(p = a) p ];
function _col_arc_join_xy(vx,vy) = [ for(i = [0:len(vx)-1]) [ vx[i], vy[i] ] ];

function _arc_of_points_cos(v,n,i,a,ao,r,o=0) = i < n - 1 ? concat(_arc_of_points_cos_n(i,a,ao,r,o), _arc_of_points_cos(v,n,i + 1,a,ao,r,o)) : _arc_of_points_cos_n(i,a,ao,r,o);
function _arc_of_points_sin(v,n,i,a,ao,r,o=0) = i < n - 1 ? concat(_arc_of_points_sin_n(i,a,ao,r,o), _arc_of_points_sin(v,n,i + 1,a,ao,r,o)) : _arc_of_points_sin_n(i,a,ao,r,o);

function _arc_of_points_cos_n(i,a,ao,r,o=0) = (cos((a*(i+1)) - ao) * r) + o;
function _arc_of_points_sin_n(i,a,ao,r,o=0) = (sin((a*(i+1)) - ao) * r) + o;

function dist(p1,p2) = ((((p2.x - p1.x) ^ 2) + ((p2.y - p1.y) ^ 2)) ^ 0.5);

function switch_base_faces(c) = [ for(i = [0:c-1]) for(j = [0:5]) _switch_base_faces_gen()[j](i,c) ];

function _pt1(i,c) = i;
function _pt2(i,c) = i + 1;
function _pt3(i,c) = ((c+1) * 2) + i + 1;
function _pt4(i,c) = ((c+1) * 2) + i;

function _pt5(i,c) = (c+1) + i;
function _pt6(i,c) = (c+1) + i + 1;
function _pt7(i,c) = ((c+1) * 3) + i + 1;
function _pt8(i,c) = ((c+1) * 3) + i;

function _switch_base_faces_gen() = [
    function(i,c) [ _pt1(i,c), _pt2(i,c), _pt3(i,c), _pt4(i,c) ],
    function(i,c) [ _pt3(i,c), _pt4(i,c), _pt8(i,c), _pt7(i,c) ],
    function(i,c) [ _pt5(i,c), _pt6(i,c), _pt7(i,c), _pt8(i,c) ],
    function(i,c) [ _pt5(i,c), _pt6(i,c), _pt2(i,c), _pt1(i,c) ],
    function(i,c) [ _pt1(i,c), _pt4(i,c), _pt8(i,c), _pt5(i,c) ],
    function(i,c) [ _pt2(i,c), _pt3(i,c), _pt7(i,c), _pt6(i,c) ]
];

// Do the maths to work out the N points (and angles) on the bottom-left corner of the top face for each switch - it is from these that we'll place our socket holes for cutting...
function _get_switch_points_and_angles(c,h,r,y) = [
    for(i = [0:c-1]) [
        (_arc_of_points_cos_n(i,_col_a(r),_col_ao(c,h,r),_col_rt(r)) + _arc_of_points_cos_n(i+1,_col_a(r),_col_ao(c,h,r),_col_rt(r))) / 2,
        y,
        (_arc_of_points_sin_n(i,_col_a(r),_col_ao(c,h,r),_col_rt(r)) + _arc_of_points_sin_n(i+1,_col_a(r),_col_ao(c,h,r),_col_rt(r))) / 2,
        _col_a(r) * (h - i - 1)
    ]
];
