include <../switches/mx.scad>
include <../BOSL2/std.scad>
use <../lib/utils.scad>

finger_col_offset = mx_socket_total_D; // An additional offset between each finger's columns

// The margin beyond the backmost edge of the columns to build the top part of the case
case_top_margin = 5;
case_wall_thickness = 4;

// Render a single arced column of switches (sockets)
// Note: home row is counted from 0, so a value of 2 means that there would be two switches above the switch that is designated as "home row".
module switch_col_arc(a,na,bp,debug = false) {
    // Grab our arguments
    n = a[0];
    o = a[1];
    r = a[2];
    xof = a[3];
    yof = a[4];
    c = a[5];
    cc = a[6];

    // Colors for debugging
    clr = ["red","blue","green","purple", "cyan", "white"];

    // Render the switch plates, starting at the top and walking down the arc
    n_na = na[0] ? na[0] : 0;
    scount = n >= n_na ? n : n_na;
    for (i=[0:scount-1]) {
        dcolor(clr[i%len(clr)],debug) {
            // Build the switch surface (only if this col has this number of swtiches)
            if (i < n) {
                sp = switch_poly(i,o,r,xof,yof);
                hull() polyhedron(points = sp[0], faces = sp[1]);
            }

            // Attach the switch to the one adjacent
            if(len(na) > 0 && c == cc) {
                sj = join_poly(
                    [i < n - 1 ? i : n-1,o,r,xof,yof], // This one
                    [i < na[0] - 1 ? i : na[0] - 1,na[1],na[2],na[3],na[4]] // The next one
                );
                hull() polyhedron(points = sj[0], faces = sj[1]);
                * for(p=sj[0]) translate(p) sphere(2);
            };
        }
    }

    // Build out the top/back of the row
    switchColBack(a,na,bp,debug);
}

module switchColBack(a,na,bp,debug=false) {
    pts = concat_mx([ topEdgePoints(a), topEdgePoints(a,mx_socket_perim_W) ]);

    fcs = [
        [0,3,5,2],
        [1,4,5,2]
    ];
    color("yellow") hull() polyhedron(points = pts, faces = fcs);

    if(len(na) > 0) {
        jpts = concat_mx([ topEdgePoints(na,mx_socket_perim_W), topEdgePoints(a) ]);
        //for(p=[0:len(jpts)-1]) translate(jpts[p]) text3d(str(p), 2, 6);
        color("yellow") hull() polyhedron(points = jpts, faces = [
            [0,1,2],
            [3,4,5]
        ]);
    }

    backWallX = bp[1].x + case_top_margin;
    echo(backWallX);
}

function topEdgePoints(a,yo=0) = _topEdgePoints(sp(0,a[1],a[2],a[3],a[4]+yo,_TOP), sp(0,a[1],a[2],a[3],a[4]+yo,_BOTTOM));

function _topEdgePoints(t,b) = [ t, b, [ b.x, b.y, b.z + case_wall_thickness ] ];

_LEFT = 4001;
_RIGHT = 4002;
_TOP = 4003;
_BOTTOM = 4004;

// Generate all points for the column
function all_col_pts(n,o,r,xof,yof,i=0) = i < n -1 ? concat_mx([switch_points(i,o,r,xof,yof), all_col_pts(n,o,r,xof,yof,i+1)]) : switch_points(i,o,r,xof,yof);

function join_poly(s1,s2) = [
    concat_mx([
        switch_points_face(s1[0],s1[1],s1[2],s1[3],s1[4],_LEFT), switch_points_face(s2[0],s2[1],s2[2],s2[3],s2[4],_RIGHT)
    ]), // points
    [ [0,1,2,3], [4,5,6,7] ] // faces
];

function switch_poly(n,o,r,xof,yof) = [ // switch number, home-row index, finger radius, x-offset (length of first finger bone), y-offset (where the column starts)
    switch_points(n,o,r,xof,yof), // points
    [ [0,1,2,3], [4,5,6,7] ] // faces
];

function switch_points(n,o,r,xof,yof) = concat_mx([switch_points_face(n,o,r,xof,yof,_LEFT), switch_points_face(n,o,r,xof,yof,_RIGHT)]);

function switch_poly_face(n,o,r,xof,yof,face) = [ // switch number, home-row index, finger radius, x-offset (length of first finger bone), y-offset (where the column starts), which face to get (left,right)
    switch_points_face(n,o,r,xof,yof,face), [0,1,2,3]
];
function switch_points_face(n,o,r,xof,yof,face) = [ // switch number, home-row index, finger radius, x-offset, y-offset for left face, which face the points are for (left or right)
    sp(n,o,r,xof,syof(yof,face),_TOP), sp(n+1,o,r,xof,syof(yof,face),_TOP), sp(n+1,o,r,xof,syof(yof,face),_BOTTOM), sp(n,o,r,xof,syof(yof,face),_BOTTOM)
];
function syof(yof,face) = face == _LEFT ? yof : (face == _RIGHT ? yof + mx_socket_perim_W : 0);
function sp(n,o,r,xof,y,sfc) = [ (cos((sa(r)*-n) - sao(r,o)) * sar(r,sfc)) + xof, y, (sin((sa(r)*-n) - sao(r,o)) * sar(r,sfc)) ]; // Generate a switch point - switch number, home-row index, finger radius, x-offset, y coord, surface (top/bottom)
function sar(r,sfc) =
    sfc == _TOP ? r + mx_switch_full_height - mx_socket_total_D 
        : sfc == _BOTTOM ? r + mx_switch_full_height
            : 0;
function sao(r,o) = 90 - ((o - 0.5) * sa(r));
function sa(r) = asin(mx_socket_perim_H / r);
