include <mx.scad>
include <../BOSL2/std.scad>

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module switch_col_arc(count, home_row, radius) {

    col_R = radius + mx_switch_full_height;
    a = asin(mx_socket_perim_H / col_R);
    ao = 90 + (a * (count - (home_row - 1))) + (a / 2);

    // Gen the points on the top
    apx = _arc_of_points_cos([],count+1,0,a,ao,col_R);
    apz = _arc_of_points_sin([],count+1,0,a,ao,col_R);

    // Gen the points on the bottom

    col_R2 = col_R + mx_socket_total_D;
    apx2 = _arc_of_points_cos([],count+1,0,a,ao,col_R2);
    apz2 = _arc_of_points_sin([],count+1,0,a,ao,col_R2);

    mxx = [apx, apx2];
    mxz = [apz, apz2];
    mxy = [0, mx_socket_perim_W];

    pt1 = function(i) i;
    pt2 = function(i) i + 1;
    pt3 = function(i) ((count + 1) * 2) + i + 1;
    pt4 = function(i) ((count + 1) * 2) + i;

    pt5 = function(i) (count + 1) + i;
    pt6 = function(i) (count + 1) + i + 1;
    pt7 = function(i) ((count + 1) * 3) + i + 1;
    pt8 = function(i) ((count + 1) * 3) + i;

    face_funk = [
        function(i) [ pt1(i), pt2(i), pt3(i), pt4(i) ],
        function(i) [ pt3(i), pt4(i), pt8(i), pt7(i) ],
        function(i) [ pt5(i), pt6(i), pt7(i), pt8(i) ],
        function(i) [ pt5(i), pt6(i), pt2(i), pt1(i) ],
        function(i) [ pt1(i), pt4(i), pt8(i), pt5(i) ],
        function(i) [ pt2(i), pt3(i), pt7(i), pt6(i) ]
    ];

    points = [
        for (i = [0:1])
            for (j = [0:1])
                for (k = [0:count])
                    [mxx[j][k], mxy[i], mxz[j][k]] ];
    faces = [
        for (i = [0:count-1])
            for (j = [0:5])
                face_funk[j](i)
    ];

    color("black") sphere(1);

    polyhedron(points = points, faces = faces);
}

function _arc_of_points_cos(v,n,i,a,ao,r,o=0) = i < n - 1 ? concat(_arc_of_points_cos_n(v[i],i,a,ao,r,o), _arc_of_points_cos(v,n,i + 1,a,ao,r,o)) : _arc_of_points_cos_n(v[i],i,a,ao,r,o);
function _arc_of_points_sin(v,n,i,a,ao,r,o=0) = i < n - 1 ? concat(_arc_of_points_sin_n(v[i],i,a,ao,r,o), _arc_of_points_sin(v,n,i + 1,a,ao,r,o)) : _arc_of_points_sin_n(v[i],i,a,ao,r,o);

function _arc_of_points_cos_n(p,i,a,ao,r,o=0) = (cos((a*(i+1)) - ao) * r) + o;
function _arc_of_points_sin_n(p,i,a,ao,r,o=0) = (sin((a*(i+1)) - ao) * r) + o;

function dist(p1,p2) = ((((p2.x - p1.x) ^ 2) + ((p2.y - p1.y) ^ 2)) ^ 0.5);
