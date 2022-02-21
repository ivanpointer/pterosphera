include <../switches/mx.scad>
include <../BOSL2/std.scad>

// The clearance underneath the socket - for generating the walls.
switch_socket_clearance = mx_socket_perim_WH;

// How thick the walls of the case should be.
case_wall_thickness = 4;


module switch_col_arc(count, home_row, radius, debug = false) {
    _switch_col_arc(count, home_row, radius, debug);
}

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module _switch_col_arc(count, home_row, radius, debug = false) {

    // Render a reference point
    if (debug) color("black") sphere(1);

    // Label the numbers if in dev mode
    if (debug) {
        for (i = [0:len(points)-1]) {
            color("blue") translate(points[i]) text3d(str(i), 3, 6);
        }
    }
    
    // Render the arc of switch bases
    pts = switch_col_pts(count,home_row,radius,0);
    fcs = switch_base_faces(count);
    polyhedron(points = pts, faces = fcs);
}

function _col_rt(r) = r + mx_switch_full_height;
function _col_rb(r) = _col_rt(r) + mx_socket_total_D;
function _col_a(r) = asin(mx_socket_perim_H / _col_rt(r));
function _col_ao(c,h,r) = 90 + (_col_a(r) * (c - (h - 1))) + (_col_a(r) / 2);
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